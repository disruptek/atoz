
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_602434 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602434](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602434): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AcceptHandshake_602771 = ref object of OpenApiRestCall_602434
proc url_AcceptHandshake_602773(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AcceptHandshake_602772(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602885 = header.getOrDefault("X-Amz-Date")
  valid_602885 = validateParameter(valid_602885, JString, required = false,
                                 default = nil)
  if valid_602885 != nil:
    section.add "X-Amz-Date", valid_602885
  var valid_602886 = header.getOrDefault("X-Amz-Security-Token")
  valid_602886 = validateParameter(valid_602886, JString, required = false,
                                 default = nil)
  if valid_602886 != nil:
    section.add "X-Amz-Security-Token", valid_602886
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602900 = header.getOrDefault("X-Amz-Target")
  valid_602900 = validateParameter(valid_602900, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.AcceptHandshake"))
  if valid_602900 != nil:
    section.add "X-Amz-Target", valid_602900
  var valid_602901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602901 = validateParameter(valid_602901, JString, required = false,
                                 default = nil)
  if valid_602901 != nil:
    section.add "X-Amz-Content-Sha256", valid_602901
  var valid_602902 = header.getOrDefault("X-Amz-Algorithm")
  valid_602902 = validateParameter(valid_602902, JString, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "X-Amz-Algorithm", valid_602902
  var valid_602903 = header.getOrDefault("X-Amz-Signature")
  valid_602903 = validateParameter(valid_602903, JString, required = false,
                                 default = nil)
  if valid_602903 != nil:
    section.add "X-Amz-Signature", valid_602903
  var valid_602904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "X-Amz-SignedHeaders", valid_602904
  var valid_602905 = header.getOrDefault("X-Amz-Credential")
  valid_602905 = validateParameter(valid_602905, JString, required = false,
                                 default = nil)
  if valid_602905 != nil:
    section.add "X-Amz-Credential", valid_602905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602929: Call_AcceptHandshake_602771; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends a response to the originator of a handshake agreeing to the action proposed by the handshake request. </p> <p>This operation can be called only by the following principals when they also have the relevant IAM permissions:</p> <ul> <li> <p> <b>Invitation to join</b> or <b>Approve all features request</b> handshakes: only a principal from the member account. </p> <p>The user who calls the API for an invitation to join must have the <code>organizations:AcceptHandshake</code> permission. If you enabled all features in the organization, the user must also have the <code>iam:CreateServiceLinkedRole</code> permission so that AWS Organizations can create the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integration_services.html#orgs_integration_service-linked-roles">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide</i>.</p> </li> <li> <p> <b>Enable all features final confirmation</b> handshake: only a principal from the master account.</p> <p>For more information about invitations, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_invites.html">Inviting an AWS Account to Join Your Organization</a> in the <i>AWS Organizations User Guide.</i> For more information about requests to enable all features in the organization, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">Enabling All Features in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>After you accept a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
  ## 
  let valid = call_602929.validator(path, query, header, formData, body)
  let scheme = call_602929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602929.url(scheme.get, call_602929.host, call_602929.base,
                         call_602929.route, valid.getOrDefault("path"))
  result = hook(call_602929, url, valid)

proc call*(call_603000: Call_AcceptHandshake_602771; body: JsonNode): Recallable =
  ## acceptHandshake
  ## <p>Sends a response to the originator of a handshake agreeing to the action proposed by the handshake request. </p> <p>This operation can be called only by the following principals when they also have the relevant IAM permissions:</p> <ul> <li> <p> <b>Invitation to join</b> or <b>Approve all features request</b> handshakes: only a principal from the member account. </p> <p>The user who calls the API for an invitation to join must have the <code>organizations:AcceptHandshake</code> permission. If you enabled all features in the organization, the user must also have the <code>iam:CreateServiceLinkedRole</code> permission so that AWS Organizations can create the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integration_services.html#orgs_integration_service-linked-roles">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide</i>.</p> </li> <li> <p> <b>Enable all features final confirmation</b> handshake: only a principal from the master account.</p> <p>For more information about invitations, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_invites.html">Inviting an AWS Account to Join Your Organization</a> in the <i>AWS Organizations User Guide.</i> For more information about requests to enable all features in the organization, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">Enabling All Features in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>After you accept a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
  ##   body: JObject (required)
  var body_603001 = newJObject()
  if body != nil:
    body_603001 = body
  result = call_603000.call(nil, nil, nil, nil, body_603001)

var acceptHandshake* = Call_AcceptHandshake_602771(name: "acceptHandshake",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.AcceptHandshake",
    validator: validate_AcceptHandshake_602772, base: "/", url: url_AcceptHandshake_602773,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachPolicy_603040 = ref object of OpenApiRestCall_602434
proc url_AttachPolicy_603042(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AttachPolicy_603041(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603043 = header.getOrDefault("X-Amz-Date")
  valid_603043 = validateParameter(valid_603043, JString, required = false,
                                 default = nil)
  if valid_603043 != nil:
    section.add "X-Amz-Date", valid_603043
  var valid_603044 = header.getOrDefault("X-Amz-Security-Token")
  valid_603044 = validateParameter(valid_603044, JString, required = false,
                                 default = nil)
  if valid_603044 != nil:
    section.add "X-Amz-Security-Token", valid_603044
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603045 = header.getOrDefault("X-Amz-Target")
  valid_603045 = validateParameter(valid_603045, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.AttachPolicy"))
  if valid_603045 != nil:
    section.add "X-Amz-Target", valid_603045
  var valid_603046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "X-Amz-Content-Sha256", valid_603046
  var valid_603047 = header.getOrDefault("X-Amz-Algorithm")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "X-Amz-Algorithm", valid_603047
  var valid_603048 = header.getOrDefault("X-Amz-Signature")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-Signature", valid_603048
  var valid_603049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "X-Amz-SignedHeaders", valid_603049
  var valid_603050 = header.getOrDefault("X-Amz-Credential")
  valid_603050 = validateParameter(valid_603050, JString, required = false,
                                 default = nil)
  if valid_603050 != nil:
    section.add "X-Amz-Credential", valid_603050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603052: Call_AttachPolicy_603040; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches a policy to a root, an organizational unit (OU), or an individual account. How the policy affects accounts depends on the type of policy:</p> <ul> <li> <p> <b>Service control policy (SCP)</b> - An SCP specifies what permissions can be delegated to users in affected member accounts. The scope of influence for a policy depends on what you attach the policy to:</p> <ul> <li> <p>If you attach an SCP to a root, it affects all accounts in the organization.</p> </li> <li> <p>If you attach an SCP to an OU, it affects all accounts in that OU and in any child OUs.</p> </li> <li> <p>If you attach the policy directly to an account, it affects only that account.</p> </li> </ul> <p>SCPs are JSON policies that specify the maximum permissions for an organization or organizational unit (OU). You can attach one SCP to a higher level root or OU, and a different SCP to a child OU or to an account. The child policy can further restrict only the permissions that pass through the parent filter and are available to the child. An SCP that is attached to a child can't grant a permission that the parent hasn't already granted. For example, imagine that the parent SCP allows permissions A, B, C, D, and E. The child SCP allows C, D, E, F, and G. The result is that the accounts affected by the child SCP are allowed to use only C, D, and E. They can't use A or B because the child OU filtered them out. They also can't use F and G because the parent OU filtered them out. They can't be granted back by the child SCP; child SCPs can only filter the permissions they receive from the parent SCP.</p> <p>AWS Organizations attaches a default SCP named <code>"FullAWSAccess</code> to every root, OU, and account. This default SCP allows all services and actions, enabling any new child OU or account to inherit the permissions of the parent root or OU. If you detach the default policy, you must replace it with a policy that specifies the permissions that you want to allow in that OU or account.</p> <p>For more information about how AWS Organizations policies permissions work, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scp.html">Using Service Control Policies</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_603052.validator(path, query, header, formData, body)
  let scheme = call_603052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603052.url(scheme.get, call_603052.host, call_603052.base,
                         call_603052.route, valid.getOrDefault("path"))
  result = hook(call_603052, url, valid)

proc call*(call_603053: Call_AttachPolicy_603040; body: JsonNode): Recallable =
  ## attachPolicy
  ## <p>Attaches a policy to a root, an organizational unit (OU), or an individual account. How the policy affects accounts depends on the type of policy:</p> <ul> <li> <p> <b>Service control policy (SCP)</b> - An SCP specifies what permissions can be delegated to users in affected member accounts. The scope of influence for a policy depends on what you attach the policy to:</p> <ul> <li> <p>If you attach an SCP to a root, it affects all accounts in the organization.</p> </li> <li> <p>If you attach an SCP to an OU, it affects all accounts in that OU and in any child OUs.</p> </li> <li> <p>If you attach the policy directly to an account, it affects only that account.</p> </li> </ul> <p>SCPs are JSON policies that specify the maximum permissions for an organization or organizational unit (OU). You can attach one SCP to a higher level root or OU, and a different SCP to a child OU or to an account. The child policy can further restrict only the permissions that pass through the parent filter and are available to the child. An SCP that is attached to a child can't grant a permission that the parent hasn't already granted. For example, imagine that the parent SCP allows permissions A, B, C, D, and E. The child SCP allows C, D, E, F, and G. The result is that the accounts affected by the child SCP are allowed to use only C, D, and E. They can't use A or B because the child OU filtered them out. They also can't use F and G because the parent OU filtered them out. They can't be granted back by the child SCP; child SCPs can only filter the permissions they receive from the parent SCP.</p> <p>AWS Organizations attaches a default SCP named <code>"FullAWSAccess</code> to every root, OU, and account. This default SCP allows all services and actions, enabling any new child OU or account to inherit the permissions of the parent root or OU. If you detach the default policy, you must replace it with a policy that specifies the permissions that you want to allow in that OU or account.</p> <p>For more information about how AWS Organizations policies permissions work, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scp.html">Using Service Control Policies</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_603054 = newJObject()
  if body != nil:
    body_603054 = body
  result = call_603053.call(nil, nil, nil, nil, body_603054)

var attachPolicy* = Call_AttachPolicy_603040(name: "attachPolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.AttachPolicy",
    validator: validate_AttachPolicy_603041, base: "/", url: url_AttachPolicy_603042,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelHandshake_603055 = ref object of OpenApiRestCall_602434
proc url_CancelHandshake_603057(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CancelHandshake_603056(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603058 = header.getOrDefault("X-Amz-Date")
  valid_603058 = validateParameter(valid_603058, JString, required = false,
                                 default = nil)
  if valid_603058 != nil:
    section.add "X-Amz-Date", valid_603058
  var valid_603059 = header.getOrDefault("X-Amz-Security-Token")
  valid_603059 = validateParameter(valid_603059, JString, required = false,
                                 default = nil)
  if valid_603059 != nil:
    section.add "X-Amz-Security-Token", valid_603059
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603060 = header.getOrDefault("X-Amz-Target")
  valid_603060 = validateParameter(valid_603060, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CancelHandshake"))
  if valid_603060 != nil:
    section.add "X-Amz-Target", valid_603060
  var valid_603061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603061 = validateParameter(valid_603061, JString, required = false,
                                 default = nil)
  if valid_603061 != nil:
    section.add "X-Amz-Content-Sha256", valid_603061
  var valid_603062 = header.getOrDefault("X-Amz-Algorithm")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "X-Amz-Algorithm", valid_603062
  var valid_603063 = header.getOrDefault("X-Amz-Signature")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-Signature", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-SignedHeaders", valid_603064
  var valid_603065 = header.getOrDefault("X-Amz-Credential")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "X-Amz-Credential", valid_603065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603067: Call_CancelHandshake_603055; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Cancels a handshake. Canceling a handshake sets the handshake state to <code>CANCELED</code>. </p> <p>This operation can be called only from the account that originated the handshake. The recipient of the handshake can't cancel it, but can use <a>DeclineHandshake</a> instead. After a handshake is canceled, the recipient can no longer respond to that handshake.</p> <p>After you cancel a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
  ## 
  let valid = call_603067.validator(path, query, header, formData, body)
  let scheme = call_603067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603067.url(scheme.get, call_603067.host, call_603067.base,
                         call_603067.route, valid.getOrDefault("path"))
  result = hook(call_603067, url, valid)

proc call*(call_603068: Call_CancelHandshake_603055; body: JsonNode): Recallable =
  ## cancelHandshake
  ## <p>Cancels a handshake. Canceling a handshake sets the handshake state to <code>CANCELED</code>. </p> <p>This operation can be called only from the account that originated the handshake. The recipient of the handshake can't cancel it, but can use <a>DeclineHandshake</a> instead. After a handshake is canceled, the recipient can no longer respond to that handshake.</p> <p>After you cancel a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
  ##   body: JObject (required)
  var body_603069 = newJObject()
  if body != nil:
    body_603069 = body
  result = call_603068.call(nil, nil, nil, nil, body_603069)

var cancelHandshake* = Call_CancelHandshake_603055(name: "cancelHandshake",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CancelHandshake",
    validator: validate_CancelHandshake_603056, base: "/", url: url_CancelHandshake_603057,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAccount_603070 = ref object of OpenApiRestCall_602434
proc url_CreateAccount_603072(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateAccount_603071(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603073 = header.getOrDefault("X-Amz-Date")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-Date", valid_603073
  var valid_603074 = header.getOrDefault("X-Amz-Security-Token")
  valid_603074 = validateParameter(valid_603074, JString, required = false,
                                 default = nil)
  if valid_603074 != nil:
    section.add "X-Amz-Security-Token", valid_603074
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603075 = header.getOrDefault("X-Amz-Target")
  valid_603075 = validateParameter(valid_603075, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CreateAccount"))
  if valid_603075 != nil:
    section.add "X-Amz-Target", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Content-Sha256", valid_603076
  var valid_603077 = header.getOrDefault("X-Amz-Algorithm")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "X-Amz-Algorithm", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Signature")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Signature", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-SignedHeaders", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Credential")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Credential", valid_603080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603082: Call_CreateAccount_603070; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS account that is automatically a member of the organization whose credentials made the request. This is an asynchronous request that AWS performs in the background. Because <code>CreateAccount</code> operates asynchronously, it can return a successful completion message even though account initialization might still be in progress. You might need to wait a few minutes before you can successfully access the account. To check the status of the request, do one of the following:</p> <ul> <li> <p>Use the <code>OperationId</code> response element from this operation to provide as a parameter to the <a>DescribeCreateAccountStatus</a> operation.</p> </li> <li> <p>Check the AWS CloudTrail log for the <code>CreateAccountResult</code> event. For information on using AWS CloudTrail with AWS Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_monitoring.html">Monitoring the Activity in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p/> <p>The user who calls the API to create an account must have the <code>organizations:CreateAccount</code> permission. If you enabled all features in the organization, AWS Organizations creates the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html#orgs_integrate_services-using_slrs">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide</i>.</p> <p>AWS Organizations preconfigures the new member account with a role (named <code>OrganizationAccountAccessRole</code> by default) that grants users in the master account administrator permissions in the new member account. Principals in the master account can assume the role. AWS Organizations clones the company name and address information for the new account from the organization's master account.</p> <p>This operation can be called only from the organization's master account.</p> <p>For more information about creating accounts, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_create.html">Creating an AWS Account in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <ul> <li> <p>When you create an account in an organization using the AWS Organizations console, API, or CLI commands, the information required for the account to operate as a standalone account, such as a payment method and signing the end user license agreement (EULA) is <i>not</i> automatically collected. If you must remove an account from your organization later, you can do so only after you provide the missing information. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization as a member account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> <li> <p>If you get an exception that indicates that you exceeded your account limits for the organization, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>If you get an exception that indicates that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>Using <code>CreateAccount</code> to create multiple temporary accounts isn't recommended. You can only close an account from the Billing and Cost Management Console, and you must be signed in as the root user. For information on the requirements and process for closing an account, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html">Closing an AWS Account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> </ul> </important> <note> <p>When you create a member account with this operation, you can choose whether to create the account with the <b>IAM User and Role Access to Billing Information</b> switch enabled. If you enable it, IAM users and roles that have appropriate permissions can view billing information for the account. If you disable it, only the account root user can access billing information. For information about how to disable this switch for an account, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html">Granting Access to Your Billing Information and Tools</a>.</p> </note>
  ## 
  let valid = call_603082.validator(path, query, header, formData, body)
  let scheme = call_603082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603082.url(scheme.get, call_603082.host, call_603082.base,
                         call_603082.route, valid.getOrDefault("path"))
  result = hook(call_603082, url, valid)

proc call*(call_603083: Call_CreateAccount_603070; body: JsonNode): Recallable =
  ## createAccount
  ## <p>Creates an AWS account that is automatically a member of the organization whose credentials made the request. This is an asynchronous request that AWS performs in the background. Because <code>CreateAccount</code> operates asynchronously, it can return a successful completion message even though account initialization might still be in progress. You might need to wait a few minutes before you can successfully access the account. To check the status of the request, do one of the following:</p> <ul> <li> <p>Use the <code>OperationId</code> response element from this operation to provide as a parameter to the <a>DescribeCreateAccountStatus</a> operation.</p> </li> <li> <p>Check the AWS CloudTrail log for the <code>CreateAccountResult</code> event. For information on using AWS CloudTrail with AWS Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_monitoring.html">Monitoring the Activity in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p/> <p>The user who calls the API to create an account must have the <code>organizations:CreateAccount</code> permission. If you enabled all features in the organization, AWS Organizations creates the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html#orgs_integrate_services-using_slrs">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide</i>.</p> <p>AWS Organizations preconfigures the new member account with a role (named <code>OrganizationAccountAccessRole</code> by default) that grants users in the master account administrator permissions in the new member account. Principals in the master account can assume the role. AWS Organizations clones the company name and address information for the new account from the organization's master account.</p> <p>This operation can be called only from the organization's master account.</p> <p>For more information about creating accounts, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_create.html">Creating an AWS Account in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <ul> <li> <p>When you create an account in an organization using the AWS Organizations console, API, or CLI commands, the information required for the account to operate as a standalone account, such as a payment method and signing the end user license agreement (EULA) is <i>not</i> automatically collected. If you must remove an account from your organization later, you can do so only after you provide the missing information. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization as a member account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> <li> <p>If you get an exception that indicates that you exceeded your account limits for the organization, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>If you get an exception that indicates that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>Using <code>CreateAccount</code> to create multiple temporary accounts isn't recommended. You can only close an account from the Billing and Cost Management Console, and you must be signed in as the root user. For information on the requirements and process for closing an account, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html">Closing an AWS Account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> </ul> </important> <note> <p>When you create a member account with this operation, you can choose whether to create the account with the <b>IAM User and Role Access to Billing Information</b> switch enabled. If you enable it, IAM users and roles that have appropriate permissions can view billing information for the account. If you disable it, only the account root user can access billing information. For information about how to disable this switch for an account, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html">Granting Access to Your Billing Information and Tools</a>.</p> </note>
  ##   body: JObject (required)
  var body_603084 = newJObject()
  if body != nil:
    body_603084 = body
  result = call_603083.call(nil, nil, nil, nil, body_603084)

var createAccount* = Call_CreateAccount_603070(name: "createAccount",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CreateAccount",
    validator: validate_CreateAccount_603071, base: "/", url: url_CreateAccount_603072,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGovCloudAccount_603085 = ref object of OpenApiRestCall_602434
proc url_CreateGovCloudAccount_603087(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateGovCloudAccount_603086(path: JsonNode; query: JsonNode;
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
      "AWSOrganizationsV20161128.CreateGovCloudAccount"))
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

proc call*(call_603097: Call_CreateGovCloudAccount_603085; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This action is available if all of the following are true:</p> <ul> <li> <p>You're authorized to create accounts in the AWS GovCloud (US) Region. For more information on the AWS GovCloud (US) Region, see the <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/welcome.html"> <i>AWS GovCloud User Guide</i>.</a> </p> </li> <li> <p>You already have an account in the AWS GovCloud (US) Region that is associated with your master account in the commercial Region. </p> </li> <li> <p>You call this action from the master account of your organization in the commercial Region.</p> </li> <li> <p>You have the <code>organizations:CreateGovCloudAccount</code> permission. AWS Organizations creates the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html#orgs_integrate_services-using_slrs">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>AWS automatically enables AWS CloudTrail for AWS GovCloud (US) accounts, but you should also do the following:</p> <ul> <li> <p>Verify that AWS CloudTrail is enabled to store logs.</p> </li> <li> <p>Create an S3 bucket for AWS CloudTrail log storage.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/verifying-cloudtrail.html">Verifying AWS CloudTrail Is Enabled</a> in the <i>AWS GovCloud User Guide</i>. </p> </li> </ul> <p>You call this action from the master account of your organization in the commercial Region to create a standalone AWS account in the AWS GovCloud (US) Region. After the account is created, the master account of an organization in the AWS GovCloud (US) Region can invite it to that organization. For more information on inviting standalone accounts in the AWS GovCloud (US) to join an organization, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-organizations.html">AWS Organizations</a> in the <i>AWS GovCloud User Guide.</i> </p> <p>Calling <code>CreateGovCloudAccount</code> is an asynchronous request that AWS performs in the background. Because <code>CreateGovCloudAccount</code> operates asynchronously, it can return a successful completion message even though account initialization might still be in progress. You might need to wait a few minutes before you can successfully access the account. To check the status of the request, do one of the following:</p> <ul> <li> <p>Use the <code>OperationId</code> response element from this operation to provide as a parameter to the <a>DescribeCreateAccountStatus</a> operation.</p> </li> <li> <p>Check the AWS CloudTrail log for the <code>CreateAccountResult</code> event. For information on using AWS CloudTrail with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_monitoring.html">Monitoring the Activity in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p/> <p>When you call the <code>CreateGovCloudAccount</code> action, you create two accounts: a standalone account in the AWS GovCloud (US) Region and an associated account in the commercial Region for billing and support purposes. The account in the commercial Region is automatically a member of the organization whose credentials made the request. Both accounts are associated with the same email address.</p> <p>A role is created in the new account in the commercial Region that allows the master account in the organization in the commercial Region to assume it. An AWS GovCloud (US) account is then created and associated with the commercial account that you just created. A role is created in the new AWS GovCloud (US) account that can be assumed by the AWS GovCloud (US) account that is associated with the master account of the commercial organization. For more information and to view a diagram that explains how account access works, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-organizations.html">AWS Organizations</a> in the <i>AWS GovCloud User Guide.</i> </p> <p>For more information about creating accounts, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_create.html">Creating an AWS Account in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <ul> <li> <p>When you create an account in an organization using the AWS Organizations console, API, or CLI commands, the information required for the account to operate as a standalone account, such as a payment method and signing the end user license agreement (EULA) is <i>not</i> automatically collected. If you must remove an account from your organization later, you can do so only after you provide the missing information. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization as a member account</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>If you get an exception that indicates that you exceeded your account limits for the organization, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>If you get an exception that indicates that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>Using <code>CreateGovCloudAccount</code> to create multiple temporary accounts isn't recommended. You can only close an account from the AWS Billing and Cost Management console, and you must be signed in as the root user. For information on the requirements and process for closing an account, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html">Closing an AWS Account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> </ul> </important> <note> <p>When you create a member account with this operation, you can choose whether to create the account with the <b>IAM User and Role Access to Billing Information</b> switch enabled. If you enable it, IAM users and roles that have appropriate permissions can view billing information for the account. If you disable it, only the account root user can access billing information. For information about how to disable this switch for an account, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html">Granting Access to Your Billing Information and Tools</a>.</p> </note>
  ## 
  let valid = call_603097.validator(path, query, header, formData, body)
  let scheme = call_603097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603097.url(scheme.get, call_603097.host, call_603097.base,
                         call_603097.route, valid.getOrDefault("path"))
  result = hook(call_603097, url, valid)

proc call*(call_603098: Call_CreateGovCloudAccount_603085; body: JsonNode): Recallable =
  ## createGovCloudAccount
  ## <p>This action is available if all of the following are true:</p> <ul> <li> <p>You're authorized to create accounts in the AWS GovCloud (US) Region. For more information on the AWS GovCloud (US) Region, see the <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/welcome.html"> <i>AWS GovCloud User Guide</i>.</a> </p> </li> <li> <p>You already have an account in the AWS GovCloud (US) Region that is associated with your master account in the commercial Region. </p> </li> <li> <p>You call this action from the master account of your organization in the commercial Region.</p> </li> <li> <p>You have the <code>organizations:CreateGovCloudAccount</code> permission. AWS Organizations creates the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html#orgs_integrate_services-using_slrs">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>AWS automatically enables AWS CloudTrail for AWS GovCloud (US) accounts, but you should also do the following:</p> <ul> <li> <p>Verify that AWS CloudTrail is enabled to store logs.</p> </li> <li> <p>Create an S3 bucket for AWS CloudTrail log storage.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/verifying-cloudtrail.html">Verifying AWS CloudTrail Is Enabled</a> in the <i>AWS GovCloud User Guide</i>. </p> </li> </ul> <p>You call this action from the master account of your organization in the commercial Region to create a standalone AWS account in the AWS GovCloud (US) Region. After the account is created, the master account of an organization in the AWS GovCloud (US) Region can invite it to that organization. For more information on inviting standalone accounts in the AWS GovCloud (US) to join an organization, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-organizations.html">AWS Organizations</a> in the <i>AWS GovCloud User Guide.</i> </p> <p>Calling <code>CreateGovCloudAccount</code> is an asynchronous request that AWS performs in the background. Because <code>CreateGovCloudAccount</code> operates asynchronously, it can return a successful completion message even though account initialization might still be in progress. You might need to wait a few minutes before you can successfully access the account. To check the status of the request, do one of the following:</p> <ul> <li> <p>Use the <code>OperationId</code> response element from this operation to provide as a parameter to the <a>DescribeCreateAccountStatus</a> operation.</p> </li> <li> <p>Check the AWS CloudTrail log for the <code>CreateAccountResult</code> event. For information on using AWS CloudTrail with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_monitoring.html">Monitoring the Activity in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p/> <p>When you call the <code>CreateGovCloudAccount</code> action, you create two accounts: a standalone account in the AWS GovCloud (US) Region and an associated account in the commercial Region for billing and support purposes. The account in the commercial Region is automatically a member of the organization whose credentials made the request. Both accounts are associated with the same email address.</p> <p>A role is created in the new account in the commercial Region that allows the master account in the organization in the commercial Region to assume it. An AWS GovCloud (US) account is then created and associated with the commercial account that you just created. A role is created in the new AWS GovCloud (US) account that can be assumed by the AWS GovCloud (US) account that is associated with the master account of the commercial organization. For more information and to view a diagram that explains how account access works, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-organizations.html">AWS Organizations</a> in the <i>AWS GovCloud User Guide.</i> </p> <p>For more information about creating accounts, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_create.html">Creating an AWS Account in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <ul> <li> <p>When you create an account in an organization using the AWS Organizations console, API, or CLI commands, the information required for the account to operate as a standalone account, such as a payment method and signing the end user license agreement (EULA) is <i>not</i> automatically collected. If you must remove an account from your organization later, you can do so only after you provide the missing information. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization as a member account</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>If you get an exception that indicates that you exceeded your account limits for the organization, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>If you get an exception that indicates that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>Using <code>CreateGovCloudAccount</code> to create multiple temporary accounts isn't recommended. You can only close an account from the AWS Billing and Cost Management console, and you must be signed in as the root user. For information on the requirements and process for closing an account, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html">Closing an AWS Account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> </ul> </important> <note> <p>When you create a member account with this operation, you can choose whether to create the account with the <b>IAM User and Role Access to Billing Information</b> switch enabled. If you enable it, IAM users and roles that have appropriate permissions can view billing information for the account. If you disable it, only the account root user can access billing information. For information about how to disable this switch for an account, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html">Granting Access to Your Billing Information and Tools</a>.</p> </note>
  ##   body: JObject (required)
  var body_603099 = newJObject()
  if body != nil:
    body_603099 = body
  result = call_603098.call(nil, nil, nil, nil, body_603099)

var createGovCloudAccount* = Call_CreateGovCloudAccount_603085(
    name: "createGovCloudAccount", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CreateGovCloudAccount",
    validator: validate_CreateGovCloudAccount_603086, base: "/",
    url: url_CreateGovCloudAccount_603087, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateOrganization_603100 = ref object of OpenApiRestCall_602434
proc url_CreateOrganization_603102(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateOrganization_603101(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603103 = header.getOrDefault("X-Amz-Date")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Date", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-Security-Token")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Security-Token", valid_603104
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603105 = header.getOrDefault("X-Amz-Target")
  valid_603105 = validateParameter(valid_603105, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CreateOrganization"))
  if valid_603105 != nil:
    section.add "X-Amz-Target", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Content-Sha256", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-Algorithm")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-Algorithm", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Signature")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Signature", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-SignedHeaders", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Credential")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Credential", valid_603110
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603112: Call_CreateOrganization_603100; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS organization. The account whose user is calling the <code>CreateOrganization</code> operation automatically becomes the <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/orgs_getting-started_concepts.html#account">master account</a> of the new organization.</p> <p>This operation must be called using credentials from the account that is to become the new organization's master account. The principal must also have the relevant IAM permissions.</p> <p>By default (or if you set the <code>FeatureSet</code> parameter to <code>ALL</code>), the new organization is created with all features enabled and service control policies automatically enabled in the root. If you instead choose to create the organization supporting only the consolidated billing features by setting the <code>FeatureSet</code> parameter to <code>CONSOLIDATED_BILLING"</code>, no policy types are enabled by default, and you can't use organization policies.</p>
  ## 
  let valid = call_603112.validator(path, query, header, formData, body)
  let scheme = call_603112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603112.url(scheme.get, call_603112.host, call_603112.base,
                         call_603112.route, valid.getOrDefault("path"))
  result = hook(call_603112, url, valid)

proc call*(call_603113: Call_CreateOrganization_603100; body: JsonNode): Recallable =
  ## createOrganization
  ## <p>Creates an AWS organization. The account whose user is calling the <code>CreateOrganization</code> operation automatically becomes the <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/orgs_getting-started_concepts.html#account">master account</a> of the new organization.</p> <p>This operation must be called using credentials from the account that is to become the new organization's master account. The principal must also have the relevant IAM permissions.</p> <p>By default (or if you set the <code>FeatureSet</code> parameter to <code>ALL</code>), the new organization is created with all features enabled and service control policies automatically enabled in the root. If you instead choose to create the organization supporting only the consolidated billing features by setting the <code>FeatureSet</code> parameter to <code>CONSOLIDATED_BILLING"</code>, no policy types are enabled by default, and you can't use organization policies.</p>
  ##   body: JObject (required)
  var body_603114 = newJObject()
  if body != nil:
    body_603114 = body
  result = call_603113.call(nil, nil, nil, nil, body_603114)

var createOrganization* = Call_CreateOrganization_603100(
    name: "createOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CreateOrganization",
    validator: validate_CreateOrganization_603101, base: "/",
    url: url_CreateOrganization_603102, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateOrganizationalUnit_603115 = ref object of OpenApiRestCall_602434
proc url_CreateOrganizationalUnit_603117(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateOrganizationalUnit_603116(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603118 = header.getOrDefault("X-Amz-Date")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Date", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-Security-Token")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Security-Token", valid_603119
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603120 = header.getOrDefault("X-Amz-Target")
  valid_603120 = validateParameter(valid_603120, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CreateOrganizationalUnit"))
  if valid_603120 != nil:
    section.add "X-Amz-Target", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Content-Sha256", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Algorithm")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Algorithm", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Signature")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Signature", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-SignedHeaders", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Credential")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Credential", valid_603125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603127: Call_CreateOrganizationalUnit_603115; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an organizational unit (OU) within a root or parent OU. An OU is a container for accounts that enables you to organize your accounts to apply policies according to your business requirements. The number of levels deep that you can nest OUs is dependent upon the policy types enabled for that root. For service control policies, the limit is five. </p> <p>For more information about OUs, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_ous.html">Managing Organizational Units</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_603127.validator(path, query, header, formData, body)
  let scheme = call_603127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603127.url(scheme.get, call_603127.host, call_603127.base,
                         call_603127.route, valid.getOrDefault("path"))
  result = hook(call_603127, url, valid)

proc call*(call_603128: Call_CreateOrganizationalUnit_603115; body: JsonNode): Recallable =
  ## createOrganizationalUnit
  ## <p>Creates an organizational unit (OU) within a root or parent OU. An OU is a container for accounts that enables you to organize your accounts to apply policies according to your business requirements. The number of levels deep that you can nest OUs is dependent upon the policy types enabled for that root. For service control policies, the limit is five. </p> <p>For more information about OUs, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_ous.html">Managing Organizational Units</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_603129 = newJObject()
  if body != nil:
    body_603129 = body
  result = call_603128.call(nil, nil, nil, nil, body_603129)

var createOrganizationalUnit* = Call_CreateOrganizationalUnit_603115(
    name: "createOrganizationalUnit", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CreateOrganizationalUnit",
    validator: validate_CreateOrganizationalUnit_603116, base: "/",
    url: url_CreateOrganizationalUnit_603117, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePolicy_603130 = ref object of OpenApiRestCall_602434
proc url_CreatePolicy_603132(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreatePolicy_603131(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603133 = header.getOrDefault("X-Amz-Date")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Date", valid_603133
  var valid_603134 = header.getOrDefault("X-Amz-Security-Token")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "X-Amz-Security-Token", valid_603134
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603135 = header.getOrDefault("X-Amz-Target")
  valid_603135 = validateParameter(valid_603135, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CreatePolicy"))
  if valid_603135 != nil:
    section.add "X-Amz-Target", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Content-Sha256", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Algorithm")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Algorithm", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Signature")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Signature", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-SignedHeaders", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Credential")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Credential", valid_603140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603142: Call_CreatePolicy_603130; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a policy of a specified type that you can attach to a root, an organizational unit (OU), or an individual AWS account.</p> <p>For more information about policies and their use, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies.html">Managing Organization Policies</a>.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_603142.validator(path, query, header, formData, body)
  let scheme = call_603142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603142.url(scheme.get, call_603142.host, call_603142.base,
                         call_603142.route, valid.getOrDefault("path"))
  result = hook(call_603142, url, valid)

proc call*(call_603143: Call_CreatePolicy_603130; body: JsonNode): Recallable =
  ## createPolicy
  ## <p>Creates a policy of a specified type that you can attach to a root, an organizational unit (OU), or an individual AWS account.</p> <p>For more information about policies and their use, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies.html">Managing Organization Policies</a>.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_603144 = newJObject()
  if body != nil:
    body_603144 = body
  result = call_603143.call(nil, nil, nil, nil, body_603144)

var createPolicy* = Call_CreatePolicy_603130(name: "createPolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CreatePolicy",
    validator: validate_CreatePolicy_603131, base: "/", url: url_CreatePolicy_603132,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeclineHandshake_603145 = ref object of OpenApiRestCall_602434
proc url_DeclineHandshake_603147(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeclineHandshake_603146(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603148 = header.getOrDefault("X-Amz-Date")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-Date", valid_603148
  var valid_603149 = header.getOrDefault("X-Amz-Security-Token")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "X-Amz-Security-Token", valid_603149
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603150 = header.getOrDefault("X-Amz-Target")
  valid_603150 = validateParameter(valid_603150, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DeclineHandshake"))
  if valid_603150 != nil:
    section.add "X-Amz-Target", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Content-Sha256", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Algorithm")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Algorithm", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Signature")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Signature", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-SignedHeaders", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Credential")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Credential", valid_603155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603157: Call_DeclineHandshake_603145; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Declines a handshake request. This sets the handshake state to <code>DECLINED</code> and effectively deactivates the request.</p> <p>This operation can be called only from the account that received the handshake. The originator of the handshake can use <a>CancelHandshake</a> instead. The originator can't reactivate a declined request, but can reinitiate the process with a new handshake request.</p> <p>After you decline a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
  ## 
  let valid = call_603157.validator(path, query, header, formData, body)
  let scheme = call_603157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603157.url(scheme.get, call_603157.host, call_603157.base,
                         call_603157.route, valid.getOrDefault("path"))
  result = hook(call_603157, url, valid)

proc call*(call_603158: Call_DeclineHandshake_603145; body: JsonNode): Recallable =
  ## declineHandshake
  ## <p>Declines a handshake request. This sets the handshake state to <code>DECLINED</code> and effectively deactivates the request.</p> <p>This operation can be called only from the account that received the handshake. The originator of the handshake can use <a>CancelHandshake</a> instead. The originator can't reactivate a declined request, but can reinitiate the process with a new handshake request.</p> <p>After you decline a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
  ##   body: JObject (required)
  var body_603159 = newJObject()
  if body != nil:
    body_603159 = body
  result = call_603158.call(nil, nil, nil, nil, body_603159)

var declineHandshake* = Call_DeclineHandshake_603145(name: "declineHandshake",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DeclineHandshake",
    validator: validate_DeclineHandshake_603146, base: "/",
    url: url_DeclineHandshake_603147, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteOrganization_603160 = ref object of OpenApiRestCall_602434
proc url_DeleteOrganization_603162(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteOrganization_603161(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603163 = header.getOrDefault("X-Amz-Date")
  valid_603163 = validateParameter(valid_603163, JString, required = false,
                                 default = nil)
  if valid_603163 != nil:
    section.add "X-Amz-Date", valid_603163
  var valid_603164 = header.getOrDefault("X-Amz-Security-Token")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "X-Amz-Security-Token", valid_603164
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603165 = header.getOrDefault("X-Amz-Target")
  valid_603165 = validateParameter(valid_603165, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DeleteOrganization"))
  if valid_603165 != nil:
    section.add "X-Amz-Target", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Content-Sha256", valid_603166
  var valid_603167 = header.getOrDefault("X-Amz-Algorithm")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "X-Amz-Algorithm", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-Signature")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Signature", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-SignedHeaders", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Credential")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Credential", valid_603170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603171: Call_DeleteOrganization_603160; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the organization. You can delete an organization only by using credentials from the master account. The organization must be empty of member accounts.
  ## 
  let valid = call_603171.validator(path, query, header, formData, body)
  let scheme = call_603171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603171.url(scheme.get, call_603171.host, call_603171.base,
                         call_603171.route, valid.getOrDefault("path"))
  result = hook(call_603171, url, valid)

proc call*(call_603172: Call_DeleteOrganization_603160): Recallable =
  ## deleteOrganization
  ## Deletes the organization. You can delete an organization only by using credentials from the master account. The organization must be empty of member accounts.
  result = call_603172.call(nil, nil, nil, nil, nil)

var deleteOrganization* = Call_DeleteOrganization_603160(
    name: "deleteOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DeleteOrganization",
    validator: validate_DeleteOrganization_603161, base: "/",
    url: url_DeleteOrganization_603162, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteOrganizationalUnit_603173 = ref object of OpenApiRestCall_602434
proc url_DeleteOrganizationalUnit_603175(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteOrganizationalUnit_603174(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603176 = header.getOrDefault("X-Amz-Date")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-Date", valid_603176
  var valid_603177 = header.getOrDefault("X-Amz-Security-Token")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-Security-Token", valid_603177
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603178 = header.getOrDefault("X-Amz-Target")
  valid_603178 = validateParameter(valid_603178, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DeleteOrganizationalUnit"))
  if valid_603178 != nil:
    section.add "X-Amz-Target", valid_603178
  var valid_603179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603179 = validateParameter(valid_603179, JString, required = false,
                                 default = nil)
  if valid_603179 != nil:
    section.add "X-Amz-Content-Sha256", valid_603179
  var valid_603180 = header.getOrDefault("X-Amz-Algorithm")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Algorithm", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Signature")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Signature", valid_603181
  var valid_603182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "X-Amz-SignedHeaders", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Credential")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Credential", valid_603183
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603185: Call_DeleteOrganizationalUnit_603173; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an organizational unit (OU) from a root or another OU. You must first remove all accounts and child OUs from the OU that you want to delete.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_603185.validator(path, query, header, formData, body)
  let scheme = call_603185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603185.url(scheme.get, call_603185.host, call_603185.base,
                         call_603185.route, valid.getOrDefault("path"))
  result = hook(call_603185, url, valid)

proc call*(call_603186: Call_DeleteOrganizationalUnit_603173; body: JsonNode): Recallable =
  ## deleteOrganizationalUnit
  ## <p>Deletes an organizational unit (OU) from a root or another OU. You must first remove all accounts and child OUs from the OU that you want to delete.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_603187 = newJObject()
  if body != nil:
    body_603187 = body
  result = call_603186.call(nil, nil, nil, nil, body_603187)

var deleteOrganizationalUnit* = Call_DeleteOrganizationalUnit_603173(
    name: "deleteOrganizationalUnit", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DeleteOrganizationalUnit",
    validator: validate_DeleteOrganizationalUnit_603174, base: "/",
    url: url_DeleteOrganizationalUnit_603175, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePolicy_603188 = ref object of OpenApiRestCall_602434
proc url_DeletePolicy_603190(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeletePolicy_603189(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603191 = header.getOrDefault("X-Amz-Date")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-Date", valid_603191
  var valid_603192 = header.getOrDefault("X-Amz-Security-Token")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Security-Token", valid_603192
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603193 = header.getOrDefault("X-Amz-Target")
  valid_603193 = validateParameter(valid_603193, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DeletePolicy"))
  if valid_603193 != nil:
    section.add "X-Amz-Target", valid_603193
  var valid_603194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "X-Amz-Content-Sha256", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-Algorithm")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Algorithm", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Signature")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Signature", valid_603196
  var valid_603197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-SignedHeaders", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Credential")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Credential", valid_603198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603200: Call_DeletePolicy_603188; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified policy from your organization. Before you perform this operation, you must first detach the policy from all organizational units (OUs), roots, and accounts.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_603200.validator(path, query, header, formData, body)
  let scheme = call_603200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603200.url(scheme.get, call_603200.host, call_603200.base,
                         call_603200.route, valid.getOrDefault("path"))
  result = hook(call_603200, url, valid)

proc call*(call_603201: Call_DeletePolicy_603188; body: JsonNode): Recallable =
  ## deletePolicy
  ## <p>Deletes the specified policy from your organization. Before you perform this operation, you must first detach the policy from all organizational units (OUs), roots, and accounts.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_603202 = newJObject()
  if body != nil:
    body_603202 = body
  result = call_603201.call(nil, nil, nil, nil, body_603202)

var deletePolicy* = Call_DeletePolicy_603188(name: "deletePolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DeletePolicy",
    validator: validate_DeletePolicy_603189, base: "/", url: url_DeletePolicy_603190,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccount_603203 = ref object of OpenApiRestCall_602434
proc url_DescribeAccount_603205(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeAccount_603204(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603206 = header.getOrDefault("X-Amz-Date")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Date", valid_603206
  var valid_603207 = header.getOrDefault("X-Amz-Security-Token")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-Security-Token", valid_603207
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603208 = header.getOrDefault("X-Amz-Target")
  valid_603208 = validateParameter(valid_603208, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribeAccount"))
  if valid_603208 != nil:
    section.add "X-Amz-Target", valid_603208
  var valid_603209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "X-Amz-Content-Sha256", valid_603209
  var valid_603210 = header.getOrDefault("X-Amz-Algorithm")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Algorithm", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Signature")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Signature", valid_603211
  var valid_603212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "X-Amz-SignedHeaders", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-Credential")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-Credential", valid_603213
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603215: Call_DescribeAccount_603203; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves AWS Organizations-related information about the specified account.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_603215.validator(path, query, header, formData, body)
  let scheme = call_603215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603215.url(scheme.get, call_603215.host, call_603215.base,
                         call_603215.route, valid.getOrDefault("path"))
  result = hook(call_603215, url, valid)

proc call*(call_603216: Call_DescribeAccount_603203; body: JsonNode): Recallable =
  ## describeAccount
  ## <p>Retrieves AWS Organizations-related information about the specified account.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_603217 = newJObject()
  if body != nil:
    body_603217 = body
  result = call_603216.call(nil, nil, nil, nil, body_603217)

var describeAccount* = Call_DescribeAccount_603203(name: "describeAccount",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribeAccount",
    validator: validate_DescribeAccount_603204, base: "/", url: url_DescribeAccount_603205,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCreateAccountStatus_603218 = ref object of OpenApiRestCall_602434
proc url_DescribeCreateAccountStatus_603220(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeCreateAccountStatus_603219(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603221 = header.getOrDefault("X-Amz-Date")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-Date", valid_603221
  var valid_603222 = header.getOrDefault("X-Amz-Security-Token")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Security-Token", valid_603222
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603223 = header.getOrDefault("X-Amz-Target")
  valid_603223 = validateParameter(valid_603223, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribeCreateAccountStatus"))
  if valid_603223 != nil:
    section.add "X-Amz-Target", valid_603223
  var valid_603224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "X-Amz-Content-Sha256", valid_603224
  var valid_603225 = header.getOrDefault("X-Amz-Algorithm")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Algorithm", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Signature")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Signature", valid_603226
  var valid_603227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-SignedHeaders", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Credential")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Credential", valid_603228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603230: Call_DescribeCreateAccountStatus_603218; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the current status of an asynchronous request to create an account.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_603230.validator(path, query, header, formData, body)
  let scheme = call_603230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603230.url(scheme.get, call_603230.host, call_603230.base,
                         call_603230.route, valid.getOrDefault("path"))
  result = hook(call_603230, url, valid)

proc call*(call_603231: Call_DescribeCreateAccountStatus_603218; body: JsonNode): Recallable =
  ## describeCreateAccountStatus
  ## <p>Retrieves the current status of an asynchronous request to create an account.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_603232 = newJObject()
  if body != nil:
    body_603232 = body
  result = call_603231.call(nil, nil, nil, nil, body_603232)

var describeCreateAccountStatus* = Call_DescribeCreateAccountStatus_603218(
    name: "describeCreateAccountStatus", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribeCreateAccountStatus",
    validator: validate_DescribeCreateAccountStatus_603219, base: "/",
    url: url_DescribeCreateAccountStatus_603220,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHandshake_603233 = ref object of OpenApiRestCall_602434
proc url_DescribeHandshake_603235(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeHandshake_603234(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603236 = header.getOrDefault("X-Amz-Date")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-Date", valid_603236
  var valid_603237 = header.getOrDefault("X-Amz-Security-Token")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-Security-Token", valid_603237
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603238 = header.getOrDefault("X-Amz-Target")
  valid_603238 = validateParameter(valid_603238, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribeHandshake"))
  if valid_603238 != nil:
    section.add "X-Amz-Target", valid_603238
  var valid_603239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-Content-Sha256", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Algorithm")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Algorithm", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Signature")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Signature", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-SignedHeaders", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Credential")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Credential", valid_603243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603245: Call_DescribeHandshake_603233; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about a previously requested handshake. The handshake ID comes from the response to the original <a>InviteAccountToOrganization</a> operation that generated the handshake.</p> <p>You can access handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> for only 30 days after they change to that state. They're then deleted and no longer accessible.</p> <p>This operation can be called from any account in the organization.</p>
  ## 
  let valid = call_603245.validator(path, query, header, formData, body)
  let scheme = call_603245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603245.url(scheme.get, call_603245.host, call_603245.base,
                         call_603245.route, valid.getOrDefault("path"))
  result = hook(call_603245, url, valid)

proc call*(call_603246: Call_DescribeHandshake_603233; body: JsonNode): Recallable =
  ## describeHandshake
  ## <p>Retrieves information about a previously requested handshake. The handshake ID comes from the response to the original <a>InviteAccountToOrganization</a> operation that generated the handshake.</p> <p>You can access handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> for only 30 days after they change to that state. They're then deleted and no longer accessible.</p> <p>This operation can be called from any account in the organization.</p>
  ##   body: JObject (required)
  var body_603247 = newJObject()
  if body != nil:
    body_603247 = body
  result = call_603246.call(nil, nil, nil, nil, body_603247)

var describeHandshake* = Call_DescribeHandshake_603233(name: "describeHandshake",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribeHandshake",
    validator: validate_DescribeHandshake_603234, base: "/",
    url: url_DescribeHandshake_603235, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOrganization_603248 = ref object of OpenApiRestCall_602434
proc url_DescribeOrganization_603250(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeOrganization_603249(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603251 = header.getOrDefault("X-Amz-Date")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "X-Amz-Date", valid_603251
  var valid_603252 = header.getOrDefault("X-Amz-Security-Token")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "X-Amz-Security-Token", valid_603252
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603253 = header.getOrDefault("X-Amz-Target")
  valid_603253 = validateParameter(valid_603253, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribeOrganization"))
  if valid_603253 != nil:
    section.add "X-Amz-Target", valid_603253
  var valid_603254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-Content-Sha256", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-Algorithm")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Algorithm", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Signature")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Signature", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-SignedHeaders", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Credential")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Credential", valid_603258
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603259: Call_DescribeOrganization_603248; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about the organization that the user's account belongs to.</p> <p>This operation can be called from any account in the organization.</p> <note> <p>Even if a policy type is shown as available in the organization, you can disable it separately at the root level with <a>DisablePolicyType</a>. Use <a>ListRoots</a> to see the status of policy types for a specified root.</p> </note>
  ## 
  let valid = call_603259.validator(path, query, header, formData, body)
  let scheme = call_603259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603259.url(scheme.get, call_603259.host, call_603259.base,
                         call_603259.route, valid.getOrDefault("path"))
  result = hook(call_603259, url, valid)

proc call*(call_603260: Call_DescribeOrganization_603248): Recallable =
  ## describeOrganization
  ## <p>Retrieves information about the organization that the user's account belongs to.</p> <p>This operation can be called from any account in the organization.</p> <note> <p>Even if a policy type is shown as available in the organization, you can disable it separately at the root level with <a>DisablePolicyType</a>. Use <a>ListRoots</a> to see the status of policy types for a specified root.</p> </note>
  result = call_603260.call(nil, nil, nil, nil, nil)

var describeOrganization* = Call_DescribeOrganization_603248(
    name: "describeOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribeOrganization",
    validator: validate_DescribeOrganization_603249, base: "/",
    url: url_DescribeOrganization_603250, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOrganizationalUnit_603261 = ref object of OpenApiRestCall_602434
proc url_DescribeOrganizationalUnit_603263(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeOrganizationalUnit_603262(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603264 = header.getOrDefault("X-Amz-Date")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-Date", valid_603264
  var valid_603265 = header.getOrDefault("X-Amz-Security-Token")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-Security-Token", valid_603265
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603266 = header.getOrDefault("X-Amz-Target")
  valid_603266 = validateParameter(valid_603266, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribeOrganizationalUnit"))
  if valid_603266 != nil:
    section.add "X-Amz-Target", valid_603266
  var valid_603267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Content-Sha256", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-Algorithm")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Algorithm", valid_603268
  var valid_603269 = header.getOrDefault("X-Amz-Signature")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "X-Amz-Signature", valid_603269
  var valid_603270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-SignedHeaders", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Credential")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Credential", valid_603271
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603273: Call_DescribeOrganizationalUnit_603261; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about an organizational unit (OU).</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_603273.validator(path, query, header, formData, body)
  let scheme = call_603273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603273.url(scheme.get, call_603273.host, call_603273.base,
                         call_603273.route, valid.getOrDefault("path"))
  result = hook(call_603273, url, valid)

proc call*(call_603274: Call_DescribeOrganizationalUnit_603261; body: JsonNode): Recallable =
  ## describeOrganizationalUnit
  ## <p>Retrieves information about an organizational unit (OU).</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_603275 = newJObject()
  if body != nil:
    body_603275 = body
  result = call_603274.call(nil, nil, nil, nil, body_603275)

var describeOrganizationalUnit* = Call_DescribeOrganizationalUnit_603261(
    name: "describeOrganizationalUnit", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribeOrganizationalUnit",
    validator: validate_DescribeOrganizationalUnit_603262, base: "/",
    url: url_DescribeOrganizationalUnit_603263,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePolicy_603276 = ref object of OpenApiRestCall_602434
proc url_DescribePolicy_603278(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribePolicy_603277(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603279 = header.getOrDefault("X-Amz-Date")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-Date", valid_603279
  var valid_603280 = header.getOrDefault("X-Amz-Security-Token")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "X-Amz-Security-Token", valid_603280
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603281 = header.getOrDefault("X-Amz-Target")
  valid_603281 = validateParameter(valid_603281, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribePolicy"))
  if valid_603281 != nil:
    section.add "X-Amz-Target", valid_603281
  var valid_603282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Content-Sha256", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-Algorithm")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-Algorithm", valid_603283
  var valid_603284 = header.getOrDefault("X-Amz-Signature")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "X-Amz-Signature", valid_603284
  var valid_603285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-SignedHeaders", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Credential")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Credential", valid_603286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603288: Call_DescribePolicy_603276; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about a policy.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_603288.validator(path, query, header, formData, body)
  let scheme = call_603288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603288.url(scheme.get, call_603288.host, call_603288.base,
                         call_603288.route, valid.getOrDefault("path"))
  result = hook(call_603288, url, valid)

proc call*(call_603289: Call_DescribePolicy_603276; body: JsonNode): Recallable =
  ## describePolicy
  ## <p>Retrieves information about a policy.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_603290 = newJObject()
  if body != nil:
    body_603290 = body
  result = call_603289.call(nil, nil, nil, nil, body_603290)

var describePolicy* = Call_DescribePolicy_603276(name: "describePolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribePolicy",
    validator: validate_DescribePolicy_603277, base: "/", url: url_DescribePolicy_603278,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachPolicy_603291 = ref object of OpenApiRestCall_602434
proc url_DetachPolicy_603293(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DetachPolicy_603292(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603294 = header.getOrDefault("X-Amz-Date")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-Date", valid_603294
  var valid_603295 = header.getOrDefault("X-Amz-Security-Token")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "X-Amz-Security-Token", valid_603295
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603296 = header.getOrDefault("X-Amz-Target")
  valid_603296 = validateParameter(valid_603296, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DetachPolicy"))
  if valid_603296 != nil:
    section.add "X-Amz-Target", valid_603296
  var valid_603297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-Content-Sha256", valid_603297
  var valid_603298 = header.getOrDefault("X-Amz-Algorithm")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-Algorithm", valid_603298
  var valid_603299 = header.getOrDefault("X-Amz-Signature")
  valid_603299 = validateParameter(valid_603299, JString, required = false,
                                 default = nil)
  if valid_603299 != nil:
    section.add "X-Amz-Signature", valid_603299
  var valid_603300 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-SignedHeaders", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Credential")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Credential", valid_603301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603303: Call_DetachPolicy_603291; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detaches a policy from a target root, organizational unit (OU), or account. If the policy being detached is a service control policy (SCP), the changes to permissions for IAM users and roles in affected accounts are immediate.</p> <p> <b>Note:</b> Every root, OU, and account must have at least one SCP attached. If you want to replace the default <code>FullAWSAccess</code> policy with one that limits the permissions that can be delegated, you must attach the replacement policy before you can remove the default one. This is the authorization strategy of <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html#orgs_policies_whitelist">whitelisting</a>. If you instead attach a second SCP and leave the <code>FullAWSAccess</code> SCP still attached, and specify <code>"Effect": "Deny"</code> in the second SCP to override the <code>"Effect": "Allow"</code> in the <code>FullAWSAccess</code> policy (or any other attached SCP), you're using the authorization strategy of <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html#orgs_policies_blacklist">blacklisting</a> . </p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_603303.validator(path, query, header, formData, body)
  let scheme = call_603303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603303.url(scheme.get, call_603303.host, call_603303.base,
                         call_603303.route, valid.getOrDefault("path"))
  result = hook(call_603303, url, valid)

proc call*(call_603304: Call_DetachPolicy_603291; body: JsonNode): Recallable =
  ## detachPolicy
  ## <p>Detaches a policy from a target root, organizational unit (OU), or account. If the policy being detached is a service control policy (SCP), the changes to permissions for IAM users and roles in affected accounts are immediate.</p> <p> <b>Note:</b> Every root, OU, and account must have at least one SCP attached. If you want to replace the default <code>FullAWSAccess</code> policy with one that limits the permissions that can be delegated, you must attach the replacement policy before you can remove the default one. This is the authorization strategy of <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html#orgs_policies_whitelist">whitelisting</a>. If you instead attach a second SCP and leave the <code>FullAWSAccess</code> SCP still attached, and specify <code>"Effect": "Deny"</code> in the second SCP to override the <code>"Effect": "Allow"</code> in the <code>FullAWSAccess</code> policy (or any other attached SCP), you're using the authorization strategy of <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html#orgs_policies_blacklist">blacklisting</a> . </p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_603305 = newJObject()
  if body != nil:
    body_603305 = body
  result = call_603304.call(nil, nil, nil, nil, body_603305)

var detachPolicy* = Call_DetachPolicy_603291(name: "detachPolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DetachPolicy",
    validator: validate_DetachPolicy_603292, base: "/", url: url_DetachPolicy_603293,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableAWSServiceAccess_603306 = ref object of OpenApiRestCall_602434
proc url_DisableAWSServiceAccess_603308(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisableAWSServiceAccess_603307(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603309 = header.getOrDefault("X-Amz-Date")
  valid_603309 = validateParameter(valid_603309, JString, required = false,
                                 default = nil)
  if valid_603309 != nil:
    section.add "X-Amz-Date", valid_603309
  var valid_603310 = header.getOrDefault("X-Amz-Security-Token")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "X-Amz-Security-Token", valid_603310
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603311 = header.getOrDefault("X-Amz-Target")
  valid_603311 = validateParameter(valid_603311, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DisableAWSServiceAccess"))
  if valid_603311 != nil:
    section.add "X-Amz-Target", valid_603311
  var valid_603312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "X-Amz-Content-Sha256", valid_603312
  var valid_603313 = header.getOrDefault("X-Amz-Algorithm")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "X-Amz-Algorithm", valid_603313
  var valid_603314 = header.getOrDefault("X-Amz-Signature")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "X-Amz-Signature", valid_603314
  var valid_603315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-SignedHeaders", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Credential")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Credential", valid_603316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603318: Call_DisableAWSServiceAccess_603306; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables the integration of an AWS service (the service that is specified by <code>ServicePrincipal</code>) with AWS Organizations. When you disable integration, the specified service no longer can create a <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html">service-linked role</a> in <i>new</i> accounts in your organization. This means the service can't perform operations on your behalf on any new accounts in your organization. The service can still perform operations in older accounts until the service completes its clean-up from AWS Organizations.</p> <p/> <important> <p>We recommend that you disable integration between AWS Organizations and the specified AWS service by using the console or commands that are provided by the specified service. Doing so ensures that the other service is aware that it can clean up any resources that are required only for the integration. How the service cleans up its resources in the organization's accounts depends on that service. For more information, see the documentation for the other AWS service.</p> </important> <p>After you perform the <code>DisableAWSServiceAccess</code> operation, the specified service can no longer perform operations in your organization's accounts unless the operations are explicitly permitted by the IAM policies that are attached to your roles. </p> <p>For more information about integrating other services with AWS Organizations, including the list of services that work with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_603318.validator(path, query, header, formData, body)
  let scheme = call_603318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603318.url(scheme.get, call_603318.host, call_603318.base,
                         call_603318.route, valid.getOrDefault("path"))
  result = hook(call_603318, url, valid)

proc call*(call_603319: Call_DisableAWSServiceAccess_603306; body: JsonNode): Recallable =
  ## disableAWSServiceAccess
  ## <p>Disables the integration of an AWS service (the service that is specified by <code>ServicePrincipal</code>) with AWS Organizations. When you disable integration, the specified service no longer can create a <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html">service-linked role</a> in <i>new</i> accounts in your organization. This means the service can't perform operations on your behalf on any new accounts in your organization. The service can still perform operations in older accounts until the service completes its clean-up from AWS Organizations.</p> <p/> <important> <p>We recommend that you disable integration between AWS Organizations and the specified AWS service by using the console or commands that are provided by the specified service. Doing so ensures that the other service is aware that it can clean up any resources that are required only for the integration. How the service cleans up its resources in the organization's accounts depends on that service. For more information, see the documentation for the other AWS service.</p> </important> <p>After you perform the <code>DisableAWSServiceAccess</code> operation, the specified service can no longer perform operations in your organization's accounts unless the operations are explicitly permitted by the IAM policies that are attached to your roles. </p> <p>For more information about integrating other services with AWS Organizations, including the list of services that work with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_603320 = newJObject()
  if body != nil:
    body_603320 = body
  result = call_603319.call(nil, nil, nil, nil, body_603320)

var disableAWSServiceAccess* = Call_DisableAWSServiceAccess_603306(
    name: "disableAWSServiceAccess", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DisableAWSServiceAccess",
    validator: validate_DisableAWSServiceAccess_603307, base: "/",
    url: url_DisableAWSServiceAccess_603308, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisablePolicyType_603321 = ref object of OpenApiRestCall_602434
proc url_DisablePolicyType_603323(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisablePolicyType_603322(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603324 = header.getOrDefault("X-Amz-Date")
  valid_603324 = validateParameter(valid_603324, JString, required = false,
                                 default = nil)
  if valid_603324 != nil:
    section.add "X-Amz-Date", valid_603324
  var valid_603325 = header.getOrDefault("X-Amz-Security-Token")
  valid_603325 = validateParameter(valid_603325, JString, required = false,
                                 default = nil)
  if valid_603325 != nil:
    section.add "X-Amz-Security-Token", valid_603325
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603326 = header.getOrDefault("X-Amz-Target")
  valid_603326 = validateParameter(valid_603326, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DisablePolicyType"))
  if valid_603326 != nil:
    section.add "X-Amz-Target", valid_603326
  var valid_603327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "X-Amz-Content-Sha256", valid_603327
  var valid_603328 = header.getOrDefault("X-Amz-Algorithm")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "X-Amz-Algorithm", valid_603328
  var valid_603329 = header.getOrDefault("X-Amz-Signature")
  valid_603329 = validateParameter(valid_603329, JString, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "X-Amz-Signature", valid_603329
  var valid_603330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-SignedHeaders", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Credential")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Credential", valid_603331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603333: Call_DisablePolicyType_603321; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables an organizational control policy type in a root. A policy of a certain type can be attached to entities in a root only if that type is enabled in the root. After you perform this operation, you no longer can attach policies of the specified type to that root or to any organizational unit (OU) or account in that root. You can undo this by using the <a>EnablePolicyType</a> operation.</p> <p>This is an asynchronous request that AWS performs in the background. If you disable a policy for a root, it still appears enabled for the organization if <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">all features</a> are enabled for the organization. AWS recommends that you first use <a>ListRoots</a> to see the status of policy types for a specified root, and then use this operation. </p> <p>This operation can be called only from the organization's master account.</p> <p> To view the status of available policy types in the organization, use <a>DescribeOrganization</a>.</p>
  ## 
  let valid = call_603333.validator(path, query, header, formData, body)
  let scheme = call_603333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603333.url(scheme.get, call_603333.host, call_603333.base,
                         call_603333.route, valid.getOrDefault("path"))
  result = hook(call_603333, url, valid)

proc call*(call_603334: Call_DisablePolicyType_603321; body: JsonNode): Recallable =
  ## disablePolicyType
  ## <p>Disables an organizational control policy type in a root. A policy of a certain type can be attached to entities in a root only if that type is enabled in the root. After you perform this operation, you no longer can attach policies of the specified type to that root or to any organizational unit (OU) or account in that root. You can undo this by using the <a>EnablePolicyType</a> operation.</p> <p>This is an asynchronous request that AWS performs in the background. If you disable a policy for a root, it still appears enabled for the organization if <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">all features</a> are enabled for the organization. AWS recommends that you first use <a>ListRoots</a> to see the status of policy types for a specified root, and then use this operation. </p> <p>This operation can be called only from the organization's master account.</p> <p> To view the status of available policy types in the organization, use <a>DescribeOrganization</a>.</p>
  ##   body: JObject (required)
  var body_603335 = newJObject()
  if body != nil:
    body_603335 = body
  result = call_603334.call(nil, nil, nil, nil, body_603335)

var disablePolicyType* = Call_DisablePolicyType_603321(name: "disablePolicyType",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DisablePolicyType",
    validator: validate_DisablePolicyType_603322, base: "/",
    url: url_DisablePolicyType_603323, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableAWSServiceAccess_603336 = ref object of OpenApiRestCall_602434
proc url_EnableAWSServiceAccess_603338(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_EnableAWSServiceAccess_603337(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603339 = header.getOrDefault("X-Amz-Date")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "X-Amz-Date", valid_603339
  var valid_603340 = header.getOrDefault("X-Amz-Security-Token")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "X-Amz-Security-Token", valid_603340
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603341 = header.getOrDefault("X-Amz-Target")
  valid_603341 = validateParameter(valid_603341, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.EnableAWSServiceAccess"))
  if valid_603341 != nil:
    section.add "X-Amz-Target", valid_603341
  var valid_603342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603342 = validateParameter(valid_603342, JString, required = false,
                                 default = nil)
  if valid_603342 != nil:
    section.add "X-Amz-Content-Sha256", valid_603342
  var valid_603343 = header.getOrDefault("X-Amz-Algorithm")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "X-Amz-Algorithm", valid_603343
  var valid_603344 = header.getOrDefault("X-Amz-Signature")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "X-Amz-Signature", valid_603344
  var valid_603345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-SignedHeaders", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-Credential")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Credential", valid_603346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603348: Call_EnableAWSServiceAccess_603336; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the integration of an AWS service (the service that is specified by <code>ServicePrincipal</code>) with AWS Organizations. When you enable integration, you allow the specified service to create a <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html">service-linked role</a> in all the accounts in your organization. This allows the service to perform operations on your behalf in your organization and its accounts.</p> <important> <p>We recommend that you enable integration between AWS Organizations and the specified AWS service by using the console or commands that are provided by the specified service. Doing so ensures that the service is aware that it can create the resources that are required for the integration. How the service creates those resources in the organization's accounts depends on that service. For more information, see the documentation for the other AWS service.</p> </important> <p>For more information about enabling services to integrate with AWS Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account and only if the organization has <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">enabled all features</a>.</p>
  ## 
  let valid = call_603348.validator(path, query, header, formData, body)
  let scheme = call_603348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603348.url(scheme.get, call_603348.host, call_603348.base,
                         call_603348.route, valid.getOrDefault("path"))
  result = hook(call_603348, url, valid)

proc call*(call_603349: Call_EnableAWSServiceAccess_603336; body: JsonNode): Recallable =
  ## enableAWSServiceAccess
  ## <p>Enables the integration of an AWS service (the service that is specified by <code>ServicePrincipal</code>) with AWS Organizations. When you enable integration, you allow the specified service to create a <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html">service-linked role</a> in all the accounts in your organization. This allows the service to perform operations on your behalf in your organization and its accounts.</p> <important> <p>We recommend that you enable integration between AWS Organizations and the specified AWS service by using the console or commands that are provided by the specified service. Doing so ensures that the service is aware that it can create the resources that are required for the integration. How the service creates those resources in the organization's accounts depends on that service. For more information, see the documentation for the other AWS service.</p> </important> <p>For more information about enabling services to integrate with AWS Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account and only if the organization has <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">enabled all features</a>.</p>
  ##   body: JObject (required)
  var body_603350 = newJObject()
  if body != nil:
    body_603350 = body
  result = call_603349.call(nil, nil, nil, nil, body_603350)

var enableAWSServiceAccess* = Call_EnableAWSServiceAccess_603336(
    name: "enableAWSServiceAccess", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.EnableAWSServiceAccess",
    validator: validate_EnableAWSServiceAccess_603337, base: "/",
    url: url_EnableAWSServiceAccess_603338, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableAllFeatures_603351 = ref object of OpenApiRestCall_602434
proc url_EnableAllFeatures_603353(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_EnableAllFeatures_603352(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603354 = header.getOrDefault("X-Amz-Date")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "X-Amz-Date", valid_603354
  var valid_603355 = header.getOrDefault("X-Amz-Security-Token")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "X-Amz-Security-Token", valid_603355
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603356 = header.getOrDefault("X-Amz-Target")
  valid_603356 = validateParameter(valid_603356, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.EnableAllFeatures"))
  if valid_603356 != nil:
    section.add "X-Amz-Target", valid_603356
  var valid_603357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603357 = validateParameter(valid_603357, JString, required = false,
                                 default = nil)
  if valid_603357 != nil:
    section.add "X-Amz-Content-Sha256", valid_603357
  var valid_603358 = header.getOrDefault("X-Amz-Algorithm")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-Algorithm", valid_603358
  var valid_603359 = header.getOrDefault("X-Amz-Signature")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-Signature", valid_603359
  var valid_603360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-SignedHeaders", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Credential")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Credential", valid_603361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603363: Call_EnableAllFeatures_603351; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables all features in an organization. This enables the use of organization policies that can restrict the services and actions that can be called in each account. Until you enable all features, you have access only to consolidated billing, and you can't use any of the advanced account administration features that AWS Organizations supports. For more information, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">Enabling All Features in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <p>This operation is required only for organizations that were created explicitly with only the consolidated billing features enabled. Calling this operation sends a handshake to every invited account in the organization. The feature set change can be finalized and the additional features enabled only after all administrators in the invited accounts approve the change by accepting the handshake.</p> </important> <p>After you enable all features, you can separately enable or disable individual policy types in a root using <a>EnablePolicyType</a> and <a>DisablePolicyType</a>. To see the status of policy types in a root, use <a>ListRoots</a>.</p> <p>After all invited member accounts accept the handshake, you finalize the feature set change by accepting the handshake that contains <code>"Action": "ENABLE_ALL_FEATURES"</code>. This completes the change.</p> <p>After you enable all features in your organization, the master account in the organization can apply policies on all member accounts. These policies can restrict what users and even administrators in those accounts can do. The master account can apply policies that prevent accounts from leaving the organization. Ensure that your account administrators are aware of this.</p> <p>This operation can be called only from the organization's master account. </p>
  ## 
  let valid = call_603363.validator(path, query, header, formData, body)
  let scheme = call_603363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603363.url(scheme.get, call_603363.host, call_603363.base,
                         call_603363.route, valid.getOrDefault("path"))
  result = hook(call_603363, url, valid)

proc call*(call_603364: Call_EnableAllFeatures_603351; body: JsonNode): Recallable =
  ## enableAllFeatures
  ## <p>Enables all features in an organization. This enables the use of organization policies that can restrict the services and actions that can be called in each account. Until you enable all features, you have access only to consolidated billing, and you can't use any of the advanced account administration features that AWS Organizations supports. For more information, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">Enabling All Features in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <p>This operation is required only for organizations that were created explicitly with only the consolidated billing features enabled. Calling this operation sends a handshake to every invited account in the organization. The feature set change can be finalized and the additional features enabled only after all administrators in the invited accounts approve the change by accepting the handshake.</p> </important> <p>After you enable all features, you can separately enable or disable individual policy types in a root using <a>EnablePolicyType</a> and <a>DisablePolicyType</a>. To see the status of policy types in a root, use <a>ListRoots</a>.</p> <p>After all invited member accounts accept the handshake, you finalize the feature set change by accepting the handshake that contains <code>"Action": "ENABLE_ALL_FEATURES"</code>. This completes the change.</p> <p>After you enable all features in your organization, the master account in the organization can apply policies on all member accounts. These policies can restrict what users and even administrators in those accounts can do. The master account can apply policies that prevent accounts from leaving the organization. Ensure that your account administrators are aware of this.</p> <p>This operation can be called only from the organization's master account. </p>
  ##   body: JObject (required)
  var body_603365 = newJObject()
  if body != nil:
    body_603365 = body
  result = call_603364.call(nil, nil, nil, nil, body_603365)

var enableAllFeatures* = Call_EnableAllFeatures_603351(name: "enableAllFeatures",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.EnableAllFeatures",
    validator: validate_EnableAllFeatures_603352, base: "/",
    url: url_EnableAllFeatures_603353, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnablePolicyType_603366 = ref object of OpenApiRestCall_602434
proc url_EnablePolicyType_603368(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_EnablePolicyType_603367(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603369 = header.getOrDefault("X-Amz-Date")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "X-Amz-Date", valid_603369
  var valid_603370 = header.getOrDefault("X-Amz-Security-Token")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-Security-Token", valid_603370
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603371 = header.getOrDefault("X-Amz-Target")
  valid_603371 = validateParameter(valid_603371, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.EnablePolicyType"))
  if valid_603371 != nil:
    section.add "X-Amz-Target", valid_603371
  var valid_603372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603372 = validateParameter(valid_603372, JString, required = false,
                                 default = nil)
  if valid_603372 != nil:
    section.add "X-Amz-Content-Sha256", valid_603372
  var valid_603373 = header.getOrDefault("X-Amz-Algorithm")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-Algorithm", valid_603373
  var valid_603374 = header.getOrDefault("X-Amz-Signature")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "X-Amz-Signature", valid_603374
  var valid_603375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-SignedHeaders", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Credential")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Credential", valid_603376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603378: Call_EnablePolicyType_603366; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables a policy type in a root. After you enable a policy type in a root, you can attach policies of that type to the root, any organizational unit (OU), or account in that root. You can undo this by using the <a>DisablePolicyType</a> operation.</p> <p>This is an asynchronous request that AWS performs in the background. AWS recommends that you first use <a>ListRoots</a> to see the status of policy types for a specified root, and then use this operation. </p> <p>This operation can be called only from the organization's master account.</p> <p>You can enable a policy type in a root only if that policy type is available in the organization. To view the status of available policy types in the organization, use <a>DescribeOrganization</a>.</p>
  ## 
  let valid = call_603378.validator(path, query, header, formData, body)
  let scheme = call_603378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603378.url(scheme.get, call_603378.host, call_603378.base,
                         call_603378.route, valid.getOrDefault("path"))
  result = hook(call_603378, url, valid)

proc call*(call_603379: Call_EnablePolicyType_603366; body: JsonNode): Recallable =
  ## enablePolicyType
  ## <p>Enables a policy type in a root. After you enable a policy type in a root, you can attach policies of that type to the root, any organizational unit (OU), or account in that root. You can undo this by using the <a>DisablePolicyType</a> operation.</p> <p>This is an asynchronous request that AWS performs in the background. AWS recommends that you first use <a>ListRoots</a> to see the status of policy types for a specified root, and then use this operation. </p> <p>This operation can be called only from the organization's master account.</p> <p>You can enable a policy type in a root only if that policy type is available in the organization. To view the status of available policy types in the organization, use <a>DescribeOrganization</a>.</p>
  ##   body: JObject (required)
  var body_603380 = newJObject()
  if body != nil:
    body_603380 = body
  result = call_603379.call(nil, nil, nil, nil, body_603380)

var enablePolicyType* = Call_EnablePolicyType_603366(name: "enablePolicyType",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.EnablePolicyType",
    validator: validate_EnablePolicyType_603367, base: "/",
    url: url_EnablePolicyType_603368, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteAccountToOrganization_603381 = ref object of OpenApiRestCall_602434
proc url_InviteAccountToOrganization_603383(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_InviteAccountToOrganization_603382(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603384 = header.getOrDefault("X-Amz-Date")
  valid_603384 = validateParameter(valid_603384, JString, required = false,
                                 default = nil)
  if valid_603384 != nil:
    section.add "X-Amz-Date", valid_603384
  var valid_603385 = header.getOrDefault("X-Amz-Security-Token")
  valid_603385 = validateParameter(valid_603385, JString, required = false,
                                 default = nil)
  if valid_603385 != nil:
    section.add "X-Amz-Security-Token", valid_603385
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603386 = header.getOrDefault("X-Amz-Target")
  valid_603386 = validateParameter(valid_603386, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.InviteAccountToOrganization"))
  if valid_603386 != nil:
    section.add "X-Amz-Target", valid_603386
  var valid_603387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603387 = validateParameter(valid_603387, JString, required = false,
                                 default = nil)
  if valid_603387 != nil:
    section.add "X-Amz-Content-Sha256", valid_603387
  var valid_603388 = header.getOrDefault("X-Amz-Algorithm")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "X-Amz-Algorithm", valid_603388
  var valid_603389 = header.getOrDefault("X-Amz-Signature")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "X-Amz-Signature", valid_603389
  var valid_603390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-SignedHeaders", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Credential")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Credential", valid_603391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603393: Call_InviteAccountToOrganization_603381; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends an invitation to another account to join your organization as a member account. AWS Organizations sends email on your behalf to the email address that is associated with the other account's owner. The invitation is implemented as a <a>Handshake</a> whose details are in the response.</p> <important> <ul> <li> <p>You can invite AWS accounts only from the same seller as the master account. For example, if your organization's master account was created by Amazon Internet Services Pvt. Ltd (AISPL), an AWS seller in India, you can invite only other AISPL accounts to your organization. You can't combine accounts from AISPL and AWS or from any other AWS seller. For more information, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/useconsolidatedbilliing-India.html">Consolidated Billing in India</a>.</p> </li> <li> <p>If you receive an exception that indicates that you exceeded your account limits for the organization or that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists after an hour, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> </ul> </important> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_603393.validator(path, query, header, formData, body)
  let scheme = call_603393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603393.url(scheme.get, call_603393.host, call_603393.base,
                         call_603393.route, valid.getOrDefault("path"))
  result = hook(call_603393, url, valid)

proc call*(call_603394: Call_InviteAccountToOrganization_603381; body: JsonNode): Recallable =
  ## inviteAccountToOrganization
  ## <p>Sends an invitation to another account to join your organization as a member account. AWS Organizations sends email on your behalf to the email address that is associated with the other account's owner. The invitation is implemented as a <a>Handshake</a> whose details are in the response.</p> <important> <ul> <li> <p>You can invite AWS accounts only from the same seller as the master account. For example, if your organization's master account was created by Amazon Internet Services Pvt. Ltd (AISPL), an AWS seller in India, you can invite only other AISPL accounts to your organization. You can't combine accounts from AISPL and AWS or from any other AWS seller. For more information, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/useconsolidatedbilliing-India.html">Consolidated Billing in India</a>.</p> </li> <li> <p>If you receive an exception that indicates that you exceeded your account limits for the organization or that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists after an hour, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> </ul> </important> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_603395 = newJObject()
  if body != nil:
    body_603395 = body
  result = call_603394.call(nil, nil, nil, nil, body_603395)

var inviteAccountToOrganization* = Call_InviteAccountToOrganization_603381(
    name: "inviteAccountToOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.InviteAccountToOrganization",
    validator: validate_InviteAccountToOrganization_603382, base: "/",
    url: url_InviteAccountToOrganization_603383,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_LeaveOrganization_603396 = ref object of OpenApiRestCall_602434
proc url_LeaveOrganization_603398(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_LeaveOrganization_603397(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603399 = header.getOrDefault("X-Amz-Date")
  valid_603399 = validateParameter(valid_603399, JString, required = false,
                                 default = nil)
  if valid_603399 != nil:
    section.add "X-Amz-Date", valid_603399
  var valid_603400 = header.getOrDefault("X-Amz-Security-Token")
  valid_603400 = validateParameter(valid_603400, JString, required = false,
                                 default = nil)
  if valid_603400 != nil:
    section.add "X-Amz-Security-Token", valid_603400
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603401 = header.getOrDefault("X-Amz-Target")
  valid_603401 = validateParameter(valid_603401, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.LeaveOrganization"))
  if valid_603401 != nil:
    section.add "X-Amz-Target", valid_603401
  var valid_603402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603402 = validateParameter(valid_603402, JString, required = false,
                                 default = nil)
  if valid_603402 != nil:
    section.add "X-Amz-Content-Sha256", valid_603402
  var valid_603403 = header.getOrDefault("X-Amz-Algorithm")
  valid_603403 = validateParameter(valid_603403, JString, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "X-Amz-Algorithm", valid_603403
  var valid_603404 = header.getOrDefault("X-Amz-Signature")
  valid_603404 = validateParameter(valid_603404, JString, required = false,
                                 default = nil)
  if valid_603404 != nil:
    section.add "X-Amz-Signature", valid_603404
  var valid_603405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "X-Amz-SignedHeaders", valid_603405
  var valid_603406 = header.getOrDefault("X-Amz-Credential")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Credential", valid_603406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603407: Call_LeaveOrganization_603396; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a member account from its parent organization. This version of the operation is performed by the account that wants to leave. To remove a member account as a user in the master account, use <a>RemoveAccountFromOrganization</a> instead.</p> <p>This operation can be called only from a member account in the organization.</p> <important> <ul> <li> <p>The master account in an organization with all features enabled can set service control policies (SCPs) that can restrict what administrators of member accounts can do, including preventing them from successfully calling <code>LeaveOrganization</code> and leaving the organization. </p> </li> <li> <p>You can leave an organization as a member account only if the account is configured with the information required to operate as a standalone account. When you create an account in an organization using the AWS Organizations console, API, or CLI commands, the information required of standalone accounts is <i>not</i> automatically collected. For each account that you want to make standalone, you must accept the end user license agreement (EULA), choose a support plan, provide and verify the required contact information, and provide a current payment method. AWS uses the payment method to charge for any billable (not free tier) AWS activity that occurs while the account isn't attached to an organization. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization when all required account information has not yet been provided</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>You can leave an organization only after you enable IAM user access to billing in your account. For more information, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html#ControllingAccessWebsite-Activate">Activating Access to the Billing and Cost Management Console</a> in the <i>AWS Billing and Cost Management User Guide.</i> </p> </li> </ul> </important>
  ## 
  let valid = call_603407.validator(path, query, header, formData, body)
  let scheme = call_603407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603407.url(scheme.get, call_603407.host, call_603407.base,
                         call_603407.route, valid.getOrDefault("path"))
  result = hook(call_603407, url, valid)

proc call*(call_603408: Call_LeaveOrganization_603396): Recallable =
  ## leaveOrganization
  ## <p>Removes a member account from its parent organization. This version of the operation is performed by the account that wants to leave. To remove a member account as a user in the master account, use <a>RemoveAccountFromOrganization</a> instead.</p> <p>This operation can be called only from a member account in the organization.</p> <important> <ul> <li> <p>The master account in an organization with all features enabled can set service control policies (SCPs) that can restrict what administrators of member accounts can do, including preventing them from successfully calling <code>LeaveOrganization</code> and leaving the organization. </p> </li> <li> <p>You can leave an organization as a member account only if the account is configured with the information required to operate as a standalone account. When you create an account in an organization using the AWS Organizations console, API, or CLI commands, the information required of standalone accounts is <i>not</i> automatically collected. For each account that you want to make standalone, you must accept the end user license agreement (EULA), choose a support plan, provide and verify the required contact information, and provide a current payment method. AWS uses the payment method to charge for any billable (not free tier) AWS activity that occurs while the account isn't attached to an organization. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization when all required account information has not yet been provided</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>You can leave an organization only after you enable IAM user access to billing in your account. For more information, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html#ControllingAccessWebsite-Activate">Activating Access to the Billing and Cost Management Console</a> in the <i>AWS Billing and Cost Management User Guide.</i> </p> </li> </ul> </important>
  result = call_603408.call(nil, nil, nil, nil, nil)

var leaveOrganization* = Call_LeaveOrganization_603396(name: "leaveOrganization",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.LeaveOrganization",
    validator: validate_LeaveOrganization_603397, base: "/",
    url: url_LeaveOrganization_603398, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAWSServiceAccessForOrganization_603409 = ref object of OpenApiRestCall_602434
proc url_ListAWSServiceAccessForOrganization_603411(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAWSServiceAccessForOrganization_603410(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of the AWS services that you enabled to integrate with your organization. After a service on this list creates the resources that it requires for the integration, it can perform operations on your organization and its accounts.</p> <p>For more information about integrating other services with AWS Organizations, including the list of services that currently work with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603412 = query.getOrDefault("NextToken")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "NextToken", valid_603412
  var valid_603413 = query.getOrDefault("MaxResults")
  valid_603413 = validateParameter(valid_603413, JString, required = false,
                                 default = nil)
  if valid_603413 != nil:
    section.add "MaxResults", valid_603413
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
  var valid_603414 = header.getOrDefault("X-Amz-Date")
  valid_603414 = validateParameter(valid_603414, JString, required = false,
                                 default = nil)
  if valid_603414 != nil:
    section.add "X-Amz-Date", valid_603414
  var valid_603415 = header.getOrDefault("X-Amz-Security-Token")
  valid_603415 = validateParameter(valid_603415, JString, required = false,
                                 default = nil)
  if valid_603415 != nil:
    section.add "X-Amz-Security-Token", valid_603415
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603416 = header.getOrDefault("X-Amz-Target")
  valid_603416 = validateParameter(valid_603416, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListAWSServiceAccessForOrganization"))
  if valid_603416 != nil:
    section.add "X-Amz-Target", valid_603416
  var valid_603417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603417 = validateParameter(valid_603417, JString, required = false,
                                 default = nil)
  if valid_603417 != nil:
    section.add "X-Amz-Content-Sha256", valid_603417
  var valid_603418 = header.getOrDefault("X-Amz-Algorithm")
  valid_603418 = validateParameter(valid_603418, JString, required = false,
                                 default = nil)
  if valid_603418 != nil:
    section.add "X-Amz-Algorithm", valid_603418
  var valid_603419 = header.getOrDefault("X-Amz-Signature")
  valid_603419 = validateParameter(valid_603419, JString, required = false,
                                 default = nil)
  if valid_603419 != nil:
    section.add "X-Amz-Signature", valid_603419
  var valid_603420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "X-Amz-SignedHeaders", valid_603420
  var valid_603421 = header.getOrDefault("X-Amz-Credential")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Credential", valid_603421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603423: Call_ListAWSServiceAccessForOrganization_603409;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of the AWS services that you enabled to integrate with your organization. After a service on this list creates the resources that it requires for the integration, it can perform operations on your organization and its accounts.</p> <p>For more information about integrating other services with AWS Organizations, including the list of services that currently work with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_603423.validator(path, query, header, formData, body)
  let scheme = call_603423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603423.url(scheme.get, call_603423.host, call_603423.base,
                         call_603423.route, valid.getOrDefault("path"))
  result = hook(call_603423, url, valid)

proc call*(call_603424: Call_ListAWSServiceAccessForOrganization_603409;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAWSServiceAccessForOrganization
  ## <p>Returns a list of the AWS services that you enabled to integrate with your organization. After a service on this list creates the resources that it requires for the integration, it can perform operations on your organization and its accounts.</p> <p>For more information about integrating other services with AWS Organizations, including the list of services that currently work with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603425 = newJObject()
  var body_603426 = newJObject()
  add(query_603425, "NextToken", newJString(NextToken))
  if body != nil:
    body_603426 = body
  add(query_603425, "MaxResults", newJString(MaxResults))
  result = call_603424.call(nil, query_603425, nil, nil, body_603426)

var listAWSServiceAccessForOrganization* = Call_ListAWSServiceAccessForOrganization_603409(
    name: "listAWSServiceAccessForOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListAWSServiceAccessForOrganization",
    validator: validate_ListAWSServiceAccessForOrganization_603410, base: "/",
    url: url_ListAWSServiceAccessForOrganization_603411,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccounts_603428 = ref object of OpenApiRestCall_602434
proc url_ListAccounts_603430(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAccounts_603429(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists all the accounts in the organization. To request only the accounts in a specified root or organizational unit (OU), use the <a>ListAccountsForParent</a> operation instead.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603431 = query.getOrDefault("NextToken")
  valid_603431 = validateParameter(valid_603431, JString, required = false,
                                 default = nil)
  if valid_603431 != nil:
    section.add "NextToken", valid_603431
  var valid_603432 = query.getOrDefault("MaxResults")
  valid_603432 = validateParameter(valid_603432, JString, required = false,
                                 default = nil)
  if valid_603432 != nil:
    section.add "MaxResults", valid_603432
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
  var valid_603433 = header.getOrDefault("X-Amz-Date")
  valid_603433 = validateParameter(valid_603433, JString, required = false,
                                 default = nil)
  if valid_603433 != nil:
    section.add "X-Amz-Date", valid_603433
  var valid_603434 = header.getOrDefault("X-Amz-Security-Token")
  valid_603434 = validateParameter(valid_603434, JString, required = false,
                                 default = nil)
  if valid_603434 != nil:
    section.add "X-Amz-Security-Token", valid_603434
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603435 = header.getOrDefault("X-Amz-Target")
  valid_603435 = validateParameter(valid_603435, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListAccounts"))
  if valid_603435 != nil:
    section.add "X-Amz-Target", valid_603435
  var valid_603436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Content-Sha256", valid_603436
  var valid_603437 = header.getOrDefault("X-Amz-Algorithm")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amz-Algorithm", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-Signature")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Signature", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-SignedHeaders", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Credential")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Credential", valid_603440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603442: Call_ListAccounts_603428; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all the accounts in the organization. To request only the accounts in a specified root or organizational unit (OU), use the <a>ListAccountsForParent</a> operation instead.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_603442.validator(path, query, header, formData, body)
  let scheme = call_603442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603442.url(scheme.get, call_603442.host, call_603442.base,
                         call_603442.route, valid.getOrDefault("path"))
  result = hook(call_603442, url, valid)

proc call*(call_603443: Call_ListAccounts_603428; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAccounts
  ## <p>Lists all the accounts in the organization. To request only the accounts in a specified root or organizational unit (OU), use the <a>ListAccountsForParent</a> operation instead.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603444 = newJObject()
  var body_603445 = newJObject()
  add(query_603444, "NextToken", newJString(NextToken))
  if body != nil:
    body_603445 = body
  add(query_603444, "MaxResults", newJString(MaxResults))
  result = call_603443.call(nil, query_603444, nil, nil, body_603445)

var listAccounts* = Call_ListAccounts_603428(name: "listAccounts",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListAccounts",
    validator: validate_ListAccounts_603429, base: "/", url: url_ListAccounts_603430,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccountsForParent_603446 = ref object of OpenApiRestCall_602434
proc url_ListAccountsForParent_603448(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAccountsForParent_603447(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the accounts in an organization that are contained by the specified target root or organizational unit (OU). If you specify the root, you get a list of all the accounts that aren't in any OU. If you specify an OU, you get a list of all the accounts in only that OU and not in any child OUs. To get a list of all accounts in the organization, use the <a>ListAccounts</a> operation.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603449 = query.getOrDefault("NextToken")
  valid_603449 = validateParameter(valid_603449, JString, required = false,
                                 default = nil)
  if valid_603449 != nil:
    section.add "NextToken", valid_603449
  var valid_603450 = query.getOrDefault("MaxResults")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "MaxResults", valid_603450
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
  var valid_603451 = header.getOrDefault("X-Amz-Date")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Date", valid_603451
  var valid_603452 = header.getOrDefault("X-Amz-Security-Token")
  valid_603452 = validateParameter(valid_603452, JString, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "X-Amz-Security-Token", valid_603452
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603453 = header.getOrDefault("X-Amz-Target")
  valid_603453 = validateParameter(valid_603453, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListAccountsForParent"))
  if valid_603453 != nil:
    section.add "X-Amz-Target", valid_603453
  var valid_603454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Content-Sha256", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-Algorithm")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Algorithm", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-Signature")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-Signature", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-SignedHeaders", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-Credential")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-Credential", valid_603458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603460: Call_ListAccountsForParent_603446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the accounts in an organization that are contained by the specified target root or organizational unit (OU). If you specify the root, you get a list of all the accounts that aren't in any OU. If you specify an OU, you get a list of all the accounts in only that OU and not in any child OUs. To get a list of all accounts in the organization, use the <a>ListAccounts</a> operation.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_603460.validator(path, query, header, formData, body)
  let scheme = call_603460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603460.url(scheme.get, call_603460.host, call_603460.base,
                         call_603460.route, valid.getOrDefault("path"))
  result = hook(call_603460, url, valid)

proc call*(call_603461: Call_ListAccountsForParent_603446; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAccountsForParent
  ## <p>Lists the accounts in an organization that are contained by the specified target root or organizational unit (OU). If you specify the root, you get a list of all the accounts that aren't in any OU. If you specify an OU, you get a list of all the accounts in only that OU and not in any child OUs. To get a list of all accounts in the organization, use the <a>ListAccounts</a> operation.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603462 = newJObject()
  var body_603463 = newJObject()
  add(query_603462, "NextToken", newJString(NextToken))
  if body != nil:
    body_603463 = body
  add(query_603462, "MaxResults", newJString(MaxResults))
  result = call_603461.call(nil, query_603462, nil, nil, body_603463)

var listAccountsForParent* = Call_ListAccountsForParent_603446(
    name: "listAccountsForParent", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListAccountsForParent",
    validator: validate_ListAccountsForParent_603447, base: "/",
    url: url_ListAccountsForParent_603448, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChildren_603464 = ref object of OpenApiRestCall_602434
proc url_ListChildren_603466(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListChildren_603465(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists all of the organizational units (OUs) or accounts that are contained in the specified parent OU or root. This operation, along with <a>ListParents</a> enables you to traverse the tree structure that makes up this root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603467 = query.getOrDefault("NextToken")
  valid_603467 = validateParameter(valid_603467, JString, required = false,
                                 default = nil)
  if valid_603467 != nil:
    section.add "NextToken", valid_603467
  var valid_603468 = query.getOrDefault("MaxResults")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "MaxResults", valid_603468
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
  var valid_603469 = header.getOrDefault("X-Amz-Date")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-Date", valid_603469
  var valid_603470 = header.getOrDefault("X-Amz-Security-Token")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Security-Token", valid_603470
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603471 = header.getOrDefault("X-Amz-Target")
  valid_603471 = validateParameter(valid_603471, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListChildren"))
  if valid_603471 != nil:
    section.add "X-Amz-Target", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Content-Sha256", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-Algorithm")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-Algorithm", valid_603473
  var valid_603474 = header.getOrDefault("X-Amz-Signature")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "X-Amz-Signature", valid_603474
  var valid_603475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "X-Amz-SignedHeaders", valid_603475
  var valid_603476 = header.getOrDefault("X-Amz-Credential")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "X-Amz-Credential", valid_603476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603478: Call_ListChildren_603464; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all of the organizational units (OUs) or accounts that are contained in the specified parent OU or root. This operation, along with <a>ListParents</a> enables you to traverse the tree structure that makes up this root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_603478.validator(path, query, header, formData, body)
  let scheme = call_603478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603478.url(scheme.get, call_603478.host, call_603478.base,
                         call_603478.route, valid.getOrDefault("path"))
  result = hook(call_603478, url, valid)

proc call*(call_603479: Call_ListChildren_603464; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listChildren
  ## <p>Lists all of the organizational units (OUs) or accounts that are contained in the specified parent OU or root. This operation, along with <a>ListParents</a> enables you to traverse the tree structure that makes up this root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603480 = newJObject()
  var body_603481 = newJObject()
  add(query_603480, "NextToken", newJString(NextToken))
  if body != nil:
    body_603481 = body
  add(query_603480, "MaxResults", newJString(MaxResults))
  result = call_603479.call(nil, query_603480, nil, nil, body_603481)

var listChildren* = Call_ListChildren_603464(name: "listChildren",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListChildren",
    validator: validate_ListChildren_603465, base: "/", url: url_ListChildren_603466,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCreateAccountStatus_603482 = ref object of OpenApiRestCall_602434
proc url_ListCreateAccountStatus_603484(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListCreateAccountStatus_603483(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the account creation requests that match the specified status that is currently being tracked for the organization.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603485 = query.getOrDefault("NextToken")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "NextToken", valid_603485
  var valid_603486 = query.getOrDefault("MaxResults")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "MaxResults", valid_603486
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
  var valid_603487 = header.getOrDefault("X-Amz-Date")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Date", valid_603487
  var valid_603488 = header.getOrDefault("X-Amz-Security-Token")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "X-Amz-Security-Token", valid_603488
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603489 = header.getOrDefault("X-Amz-Target")
  valid_603489 = validateParameter(valid_603489, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListCreateAccountStatus"))
  if valid_603489 != nil:
    section.add "X-Amz-Target", valid_603489
  var valid_603490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603490 = validateParameter(valid_603490, JString, required = false,
                                 default = nil)
  if valid_603490 != nil:
    section.add "X-Amz-Content-Sha256", valid_603490
  var valid_603491 = header.getOrDefault("X-Amz-Algorithm")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "X-Amz-Algorithm", valid_603491
  var valid_603492 = header.getOrDefault("X-Amz-Signature")
  valid_603492 = validateParameter(valid_603492, JString, required = false,
                                 default = nil)
  if valid_603492 != nil:
    section.add "X-Amz-Signature", valid_603492
  var valid_603493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603493 = validateParameter(valid_603493, JString, required = false,
                                 default = nil)
  if valid_603493 != nil:
    section.add "X-Amz-SignedHeaders", valid_603493
  var valid_603494 = header.getOrDefault("X-Amz-Credential")
  valid_603494 = validateParameter(valid_603494, JString, required = false,
                                 default = nil)
  if valid_603494 != nil:
    section.add "X-Amz-Credential", valid_603494
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603496: Call_ListCreateAccountStatus_603482; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the account creation requests that match the specified status that is currently being tracked for the organization.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_603496.validator(path, query, header, formData, body)
  let scheme = call_603496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603496.url(scheme.get, call_603496.host, call_603496.base,
                         call_603496.route, valid.getOrDefault("path"))
  result = hook(call_603496, url, valid)

proc call*(call_603497: Call_ListCreateAccountStatus_603482; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listCreateAccountStatus
  ## <p>Lists the account creation requests that match the specified status that is currently being tracked for the organization.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603498 = newJObject()
  var body_603499 = newJObject()
  add(query_603498, "NextToken", newJString(NextToken))
  if body != nil:
    body_603499 = body
  add(query_603498, "MaxResults", newJString(MaxResults))
  result = call_603497.call(nil, query_603498, nil, nil, body_603499)

var listCreateAccountStatus* = Call_ListCreateAccountStatus_603482(
    name: "listCreateAccountStatus", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListCreateAccountStatus",
    validator: validate_ListCreateAccountStatus_603483, base: "/",
    url: url_ListCreateAccountStatus_603484, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHandshakesForAccount_603500 = ref object of OpenApiRestCall_602434
proc url_ListHandshakesForAccount_603502(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListHandshakesForAccount_603501(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the current handshakes that are associated with the account of the requesting user.</p> <p>Handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> appear in the results of this API for only 30 days after changing to that state. After that, they're deleted and no longer accessible.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called from any account in the organization.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603503 = query.getOrDefault("NextToken")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "NextToken", valid_603503
  var valid_603504 = query.getOrDefault("MaxResults")
  valid_603504 = validateParameter(valid_603504, JString, required = false,
                                 default = nil)
  if valid_603504 != nil:
    section.add "MaxResults", valid_603504
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
  var valid_603505 = header.getOrDefault("X-Amz-Date")
  valid_603505 = validateParameter(valid_603505, JString, required = false,
                                 default = nil)
  if valid_603505 != nil:
    section.add "X-Amz-Date", valid_603505
  var valid_603506 = header.getOrDefault("X-Amz-Security-Token")
  valid_603506 = validateParameter(valid_603506, JString, required = false,
                                 default = nil)
  if valid_603506 != nil:
    section.add "X-Amz-Security-Token", valid_603506
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603507 = header.getOrDefault("X-Amz-Target")
  valid_603507 = validateParameter(valid_603507, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListHandshakesForAccount"))
  if valid_603507 != nil:
    section.add "X-Amz-Target", valid_603507
  var valid_603508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603508 = validateParameter(valid_603508, JString, required = false,
                                 default = nil)
  if valid_603508 != nil:
    section.add "X-Amz-Content-Sha256", valid_603508
  var valid_603509 = header.getOrDefault("X-Amz-Algorithm")
  valid_603509 = validateParameter(valid_603509, JString, required = false,
                                 default = nil)
  if valid_603509 != nil:
    section.add "X-Amz-Algorithm", valid_603509
  var valid_603510 = header.getOrDefault("X-Amz-Signature")
  valid_603510 = validateParameter(valid_603510, JString, required = false,
                                 default = nil)
  if valid_603510 != nil:
    section.add "X-Amz-Signature", valid_603510
  var valid_603511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-SignedHeaders", valid_603511
  var valid_603512 = header.getOrDefault("X-Amz-Credential")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "X-Amz-Credential", valid_603512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603514: Call_ListHandshakesForAccount_603500; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the current handshakes that are associated with the account of the requesting user.</p> <p>Handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> appear in the results of this API for only 30 days after changing to that state. After that, they're deleted and no longer accessible.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called from any account in the organization.</p>
  ## 
  let valid = call_603514.validator(path, query, header, formData, body)
  let scheme = call_603514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603514.url(scheme.get, call_603514.host, call_603514.base,
                         call_603514.route, valid.getOrDefault("path"))
  result = hook(call_603514, url, valid)

proc call*(call_603515: Call_ListHandshakesForAccount_603500; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listHandshakesForAccount
  ## <p>Lists the current handshakes that are associated with the account of the requesting user.</p> <p>Handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> appear in the results of this API for only 30 days after changing to that state. After that, they're deleted and no longer accessible.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called from any account in the organization.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603516 = newJObject()
  var body_603517 = newJObject()
  add(query_603516, "NextToken", newJString(NextToken))
  if body != nil:
    body_603517 = body
  add(query_603516, "MaxResults", newJString(MaxResults))
  result = call_603515.call(nil, query_603516, nil, nil, body_603517)

var listHandshakesForAccount* = Call_ListHandshakesForAccount_603500(
    name: "listHandshakesForAccount", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListHandshakesForAccount",
    validator: validate_ListHandshakesForAccount_603501, base: "/",
    url: url_ListHandshakesForAccount_603502, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHandshakesForOrganization_603518 = ref object of OpenApiRestCall_602434
proc url_ListHandshakesForOrganization_603520(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListHandshakesForOrganization_603519(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the handshakes that are associated with the organization that the requesting user is part of. The <code>ListHandshakesForOrganization</code> operation returns a list of handshake structures. Each structure contains details and status about a handshake.</p> <p>Handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> appear in the results of this API for only 30 days after changing to that state. After that, they're deleted and no longer accessible.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603521 = query.getOrDefault("NextToken")
  valid_603521 = validateParameter(valid_603521, JString, required = false,
                                 default = nil)
  if valid_603521 != nil:
    section.add "NextToken", valid_603521
  var valid_603522 = query.getOrDefault("MaxResults")
  valid_603522 = validateParameter(valid_603522, JString, required = false,
                                 default = nil)
  if valid_603522 != nil:
    section.add "MaxResults", valid_603522
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
  var valid_603523 = header.getOrDefault("X-Amz-Date")
  valid_603523 = validateParameter(valid_603523, JString, required = false,
                                 default = nil)
  if valid_603523 != nil:
    section.add "X-Amz-Date", valid_603523
  var valid_603524 = header.getOrDefault("X-Amz-Security-Token")
  valid_603524 = validateParameter(valid_603524, JString, required = false,
                                 default = nil)
  if valid_603524 != nil:
    section.add "X-Amz-Security-Token", valid_603524
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603525 = header.getOrDefault("X-Amz-Target")
  valid_603525 = validateParameter(valid_603525, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListHandshakesForOrganization"))
  if valid_603525 != nil:
    section.add "X-Amz-Target", valid_603525
  var valid_603526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603526 = validateParameter(valid_603526, JString, required = false,
                                 default = nil)
  if valid_603526 != nil:
    section.add "X-Amz-Content-Sha256", valid_603526
  var valid_603527 = header.getOrDefault("X-Amz-Algorithm")
  valid_603527 = validateParameter(valid_603527, JString, required = false,
                                 default = nil)
  if valid_603527 != nil:
    section.add "X-Amz-Algorithm", valid_603527
  var valid_603528 = header.getOrDefault("X-Amz-Signature")
  valid_603528 = validateParameter(valid_603528, JString, required = false,
                                 default = nil)
  if valid_603528 != nil:
    section.add "X-Amz-Signature", valid_603528
  var valid_603529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-SignedHeaders", valid_603529
  var valid_603530 = header.getOrDefault("X-Amz-Credential")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Credential", valid_603530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603532: Call_ListHandshakesForOrganization_603518; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the handshakes that are associated with the organization that the requesting user is part of. The <code>ListHandshakesForOrganization</code> operation returns a list of handshake structures. Each structure contains details and status about a handshake.</p> <p>Handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> appear in the results of this API for only 30 days after changing to that state. After that, they're deleted and no longer accessible.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_603532.validator(path, query, header, formData, body)
  let scheme = call_603532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603532.url(scheme.get, call_603532.host, call_603532.base,
                         call_603532.route, valid.getOrDefault("path"))
  result = hook(call_603532, url, valid)

proc call*(call_603533: Call_ListHandshakesForOrganization_603518; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listHandshakesForOrganization
  ## <p>Lists the handshakes that are associated with the organization that the requesting user is part of. The <code>ListHandshakesForOrganization</code> operation returns a list of handshake structures. Each structure contains details and status about a handshake.</p> <p>Handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> appear in the results of this API for only 30 days after changing to that state. After that, they're deleted and no longer accessible.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603534 = newJObject()
  var body_603535 = newJObject()
  add(query_603534, "NextToken", newJString(NextToken))
  if body != nil:
    body_603535 = body
  add(query_603534, "MaxResults", newJString(MaxResults))
  result = call_603533.call(nil, query_603534, nil, nil, body_603535)

var listHandshakesForOrganization* = Call_ListHandshakesForOrganization_603518(
    name: "listHandshakesForOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListHandshakesForOrganization",
    validator: validate_ListHandshakesForOrganization_603519, base: "/",
    url: url_ListHandshakesForOrganization_603520,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOrganizationalUnitsForParent_603536 = ref object of OpenApiRestCall_602434
proc url_ListOrganizationalUnitsForParent_603538(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListOrganizationalUnitsForParent_603537(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the organizational units (OUs) in a parent organizational unit or root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603539 = query.getOrDefault("NextToken")
  valid_603539 = validateParameter(valid_603539, JString, required = false,
                                 default = nil)
  if valid_603539 != nil:
    section.add "NextToken", valid_603539
  var valid_603540 = query.getOrDefault("MaxResults")
  valid_603540 = validateParameter(valid_603540, JString, required = false,
                                 default = nil)
  if valid_603540 != nil:
    section.add "MaxResults", valid_603540
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
  var valid_603541 = header.getOrDefault("X-Amz-Date")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Date", valid_603541
  var valid_603542 = header.getOrDefault("X-Amz-Security-Token")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "X-Amz-Security-Token", valid_603542
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603543 = header.getOrDefault("X-Amz-Target")
  valid_603543 = validateParameter(valid_603543, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListOrganizationalUnitsForParent"))
  if valid_603543 != nil:
    section.add "X-Amz-Target", valid_603543
  var valid_603544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-Content-Sha256", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Algorithm")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Algorithm", valid_603545
  var valid_603546 = header.getOrDefault("X-Amz-Signature")
  valid_603546 = validateParameter(valid_603546, JString, required = false,
                                 default = nil)
  if valid_603546 != nil:
    section.add "X-Amz-Signature", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-SignedHeaders", valid_603547
  var valid_603548 = header.getOrDefault("X-Amz-Credential")
  valid_603548 = validateParameter(valid_603548, JString, required = false,
                                 default = nil)
  if valid_603548 != nil:
    section.add "X-Amz-Credential", valid_603548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603550: Call_ListOrganizationalUnitsForParent_603536;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the organizational units (OUs) in a parent organizational unit or root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_603550.validator(path, query, header, formData, body)
  let scheme = call_603550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603550.url(scheme.get, call_603550.host, call_603550.base,
                         call_603550.route, valid.getOrDefault("path"))
  result = hook(call_603550, url, valid)

proc call*(call_603551: Call_ListOrganizationalUnitsForParent_603536;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listOrganizationalUnitsForParent
  ## <p>Lists the organizational units (OUs) in a parent organizational unit or root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603552 = newJObject()
  var body_603553 = newJObject()
  add(query_603552, "NextToken", newJString(NextToken))
  if body != nil:
    body_603553 = body
  add(query_603552, "MaxResults", newJString(MaxResults))
  result = call_603551.call(nil, query_603552, nil, nil, body_603553)

var listOrganizationalUnitsForParent* = Call_ListOrganizationalUnitsForParent_603536(
    name: "listOrganizationalUnitsForParent", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListOrganizationalUnitsForParent",
    validator: validate_ListOrganizationalUnitsForParent_603537, base: "/",
    url: url_ListOrganizationalUnitsForParent_603538,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListParents_603554 = ref object of OpenApiRestCall_602434
proc url_ListParents_603556(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListParents_603555(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the root or organizational units (OUs) that serve as the immediate parent of the specified child OU or account. This operation, along with <a>ListChildren</a> enables you to traverse the tree structure that makes up this root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p> <note> <p>In the current release, a child can have only a single parent. </p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603557 = query.getOrDefault("NextToken")
  valid_603557 = validateParameter(valid_603557, JString, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "NextToken", valid_603557
  var valid_603558 = query.getOrDefault("MaxResults")
  valid_603558 = validateParameter(valid_603558, JString, required = false,
                                 default = nil)
  if valid_603558 != nil:
    section.add "MaxResults", valid_603558
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
  var valid_603559 = header.getOrDefault("X-Amz-Date")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "X-Amz-Date", valid_603559
  var valid_603560 = header.getOrDefault("X-Amz-Security-Token")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "X-Amz-Security-Token", valid_603560
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603561 = header.getOrDefault("X-Amz-Target")
  valid_603561 = validateParameter(valid_603561, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListParents"))
  if valid_603561 != nil:
    section.add "X-Amz-Target", valid_603561
  var valid_603562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-Content-Sha256", valid_603562
  var valid_603563 = header.getOrDefault("X-Amz-Algorithm")
  valid_603563 = validateParameter(valid_603563, JString, required = false,
                                 default = nil)
  if valid_603563 != nil:
    section.add "X-Amz-Algorithm", valid_603563
  var valid_603564 = header.getOrDefault("X-Amz-Signature")
  valid_603564 = validateParameter(valid_603564, JString, required = false,
                                 default = nil)
  if valid_603564 != nil:
    section.add "X-Amz-Signature", valid_603564
  var valid_603565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "X-Amz-SignedHeaders", valid_603565
  var valid_603566 = header.getOrDefault("X-Amz-Credential")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "X-Amz-Credential", valid_603566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603568: Call_ListParents_603554; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the root or organizational units (OUs) that serve as the immediate parent of the specified child OU or account. This operation, along with <a>ListChildren</a> enables you to traverse the tree structure that makes up this root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p> <note> <p>In the current release, a child can have only a single parent. </p> </note>
  ## 
  let valid = call_603568.validator(path, query, header, formData, body)
  let scheme = call_603568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603568.url(scheme.get, call_603568.host, call_603568.base,
                         call_603568.route, valid.getOrDefault("path"))
  result = hook(call_603568, url, valid)

proc call*(call_603569: Call_ListParents_603554; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listParents
  ## <p>Lists the root or organizational units (OUs) that serve as the immediate parent of the specified child OU or account. This operation, along with <a>ListChildren</a> enables you to traverse the tree structure that makes up this root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p> <note> <p>In the current release, a child can have only a single parent. </p> </note>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603570 = newJObject()
  var body_603571 = newJObject()
  add(query_603570, "NextToken", newJString(NextToken))
  if body != nil:
    body_603571 = body
  add(query_603570, "MaxResults", newJString(MaxResults))
  result = call_603569.call(nil, query_603570, nil, nil, body_603571)

var listParents* = Call_ListParents_603554(name: "listParents",
                                        meth: HttpMethod.HttpPost,
                                        host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListParents",
                                        validator: validate_ListParents_603555,
                                        base: "/", url: url_ListParents_603556,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPolicies_603572 = ref object of OpenApiRestCall_602434
proc url_ListPolicies_603574(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListPolicies_603573(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the list of all policies in an organization of a specified type.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603575 = query.getOrDefault("NextToken")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "NextToken", valid_603575
  var valid_603576 = query.getOrDefault("MaxResults")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "MaxResults", valid_603576
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
  var valid_603577 = header.getOrDefault("X-Amz-Date")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-Date", valid_603577
  var valid_603578 = header.getOrDefault("X-Amz-Security-Token")
  valid_603578 = validateParameter(valid_603578, JString, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "X-Amz-Security-Token", valid_603578
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603579 = header.getOrDefault("X-Amz-Target")
  valid_603579 = validateParameter(valid_603579, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListPolicies"))
  if valid_603579 != nil:
    section.add "X-Amz-Target", valid_603579
  var valid_603580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603580 = validateParameter(valid_603580, JString, required = false,
                                 default = nil)
  if valid_603580 != nil:
    section.add "X-Amz-Content-Sha256", valid_603580
  var valid_603581 = header.getOrDefault("X-Amz-Algorithm")
  valid_603581 = validateParameter(valid_603581, JString, required = false,
                                 default = nil)
  if valid_603581 != nil:
    section.add "X-Amz-Algorithm", valid_603581
  var valid_603582 = header.getOrDefault("X-Amz-Signature")
  valid_603582 = validateParameter(valid_603582, JString, required = false,
                                 default = nil)
  if valid_603582 != nil:
    section.add "X-Amz-Signature", valid_603582
  var valid_603583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603583 = validateParameter(valid_603583, JString, required = false,
                                 default = nil)
  if valid_603583 != nil:
    section.add "X-Amz-SignedHeaders", valid_603583
  var valid_603584 = header.getOrDefault("X-Amz-Credential")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "X-Amz-Credential", valid_603584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603586: Call_ListPolicies_603572; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the list of all policies in an organization of a specified type.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_603586.validator(path, query, header, formData, body)
  let scheme = call_603586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603586.url(scheme.get, call_603586.host, call_603586.base,
                         call_603586.route, valid.getOrDefault("path"))
  result = hook(call_603586, url, valid)

proc call*(call_603587: Call_ListPolicies_603572; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listPolicies
  ## <p>Retrieves the list of all policies in an organization of a specified type.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603588 = newJObject()
  var body_603589 = newJObject()
  add(query_603588, "NextToken", newJString(NextToken))
  if body != nil:
    body_603589 = body
  add(query_603588, "MaxResults", newJString(MaxResults))
  result = call_603587.call(nil, query_603588, nil, nil, body_603589)

var listPolicies* = Call_ListPolicies_603572(name: "listPolicies",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListPolicies",
    validator: validate_ListPolicies_603573, base: "/", url: url_ListPolicies_603574,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPoliciesForTarget_603590 = ref object of OpenApiRestCall_602434
proc url_ListPoliciesForTarget_603592(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListPoliciesForTarget_603591(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the policies that are directly attached to the specified target root, organizational unit (OU), or account. You must specify the policy type that you want included in the returned list.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603593 = query.getOrDefault("NextToken")
  valid_603593 = validateParameter(valid_603593, JString, required = false,
                                 default = nil)
  if valid_603593 != nil:
    section.add "NextToken", valid_603593
  var valid_603594 = query.getOrDefault("MaxResults")
  valid_603594 = validateParameter(valid_603594, JString, required = false,
                                 default = nil)
  if valid_603594 != nil:
    section.add "MaxResults", valid_603594
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
  var valid_603595 = header.getOrDefault("X-Amz-Date")
  valid_603595 = validateParameter(valid_603595, JString, required = false,
                                 default = nil)
  if valid_603595 != nil:
    section.add "X-Amz-Date", valid_603595
  var valid_603596 = header.getOrDefault("X-Amz-Security-Token")
  valid_603596 = validateParameter(valid_603596, JString, required = false,
                                 default = nil)
  if valid_603596 != nil:
    section.add "X-Amz-Security-Token", valid_603596
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603597 = header.getOrDefault("X-Amz-Target")
  valid_603597 = validateParameter(valid_603597, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListPoliciesForTarget"))
  if valid_603597 != nil:
    section.add "X-Amz-Target", valid_603597
  var valid_603598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603598 = validateParameter(valid_603598, JString, required = false,
                                 default = nil)
  if valid_603598 != nil:
    section.add "X-Amz-Content-Sha256", valid_603598
  var valid_603599 = header.getOrDefault("X-Amz-Algorithm")
  valid_603599 = validateParameter(valid_603599, JString, required = false,
                                 default = nil)
  if valid_603599 != nil:
    section.add "X-Amz-Algorithm", valid_603599
  var valid_603600 = header.getOrDefault("X-Amz-Signature")
  valid_603600 = validateParameter(valid_603600, JString, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "X-Amz-Signature", valid_603600
  var valid_603601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-SignedHeaders", valid_603601
  var valid_603602 = header.getOrDefault("X-Amz-Credential")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "X-Amz-Credential", valid_603602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603604: Call_ListPoliciesForTarget_603590; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the policies that are directly attached to the specified target root, organizational unit (OU), or account. You must specify the policy type that you want included in the returned list.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_603604.validator(path, query, header, formData, body)
  let scheme = call_603604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603604.url(scheme.get, call_603604.host, call_603604.base,
                         call_603604.route, valid.getOrDefault("path"))
  result = hook(call_603604, url, valid)

proc call*(call_603605: Call_ListPoliciesForTarget_603590; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listPoliciesForTarget
  ## <p>Lists the policies that are directly attached to the specified target root, organizational unit (OU), or account. You must specify the policy type that you want included in the returned list.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603606 = newJObject()
  var body_603607 = newJObject()
  add(query_603606, "NextToken", newJString(NextToken))
  if body != nil:
    body_603607 = body
  add(query_603606, "MaxResults", newJString(MaxResults))
  result = call_603605.call(nil, query_603606, nil, nil, body_603607)

var listPoliciesForTarget* = Call_ListPoliciesForTarget_603590(
    name: "listPoliciesForTarget", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListPoliciesForTarget",
    validator: validate_ListPoliciesForTarget_603591, base: "/",
    url: url_ListPoliciesForTarget_603592, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoots_603608 = ref object of OpenApiRestCall_602434
proc url_ListRoots_603610(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListRoots_603609(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the roots that are defined in the current organization.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p> <note> <p>Policy types can be enabled and disabled in roots. This is distinct from whether they're available in the organization. When you enable all features, you make policy types available for use in that organization. Individual policy types can then be enabled and disabled in a root. To see the availability of a policy type in an organization, use <a>DescribeOrganization</a>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603611 = query.getOrDefault("NextToken")
  valid_603611 = validateParameter(valid_603611, JString, required = false,
                                 default = nil)
  if valid_603611 != nil:
    section.add "NextToken", valid_603611
  var valid_603612 = query.getOrDefault("MaxResults")
  valid_603612 = validateParameter(valid_603612, JString, required = false,
                                 default = nil)
  if valid_603612 != nil:
    section.add "MaxResults", valid_603612
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
  var valid_603613 = header.getOrDefault("X-Amz-Date")
  valid_603613 = validateParameter(valid_603613, JString, required = false,
                                 default = nil)
  if valid_603613 != nil:
    section.add "X-Amz-Date", valid_603613
  var valid_603614 = header.getOrDefault("X-Amz-Security-Token")
  valid_603614 = validateParameter(valid_603614, JString, required = false,
                                 default = nil)
  if valid_603614 != nil:
    section.add "X-Amz-Security-Token", valid_603614
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603615 = header.getOrDefault("X-Amz-Target")
  valid_603615 = validateParameter(valid_603615, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListRoots"))
  if valid_603615 != nil:
    section.add "X-Amz-Target", valid_603615
  var valid_603616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603616 = validateParameter(valid_603616, JString, required = false,
                                 default = nil)
  if valid_603616 != nil:
    section.add "X-Amz-Content-Sha256", valid_603616
  var valid_603617 = header.getOrDefault("X-Amz-Algorithm")
  valid_603617 = validateParameter(valid_603617, JString, required = false,
                                 default = nil)
  if valid_603617 != nil:
    section.add "X-Amz-Algorithm", valid_603617
  var valid_603618 = header.getOrDefault("X-Amz-Signature")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "X-Amz-Signature", valid_603618
  var valid_603619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-SignedHeaders", valid_603619
  var valid_603620 = header.getOrDefault("X-Amz-Credential")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-Credential", valid_603620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603622: Call_ListRoots_603608; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the roots that are defined in the current organization.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p> <note> <p>Policy types can be enabled and disabled in roots. This is distinct from whether they're available in the organization. When you enable all features, you make policy types available for use in that organization. Individual policy types can then be enabled and disabled in a root. To see the availability of a policy type in an organization, use <a>DescribeOrganization</a>.</p> </note>
  ## 
  let valid = call_603622.validator(path, query, header, formData, body)
  let scheme = call_603622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603622.url(scheme.get, call_603622.host, call_603622.base,
                         call_603622.route, valid.getOrDefault("path"))
  result = hook(call_603622, url, valid)

proc call*(call_603623: Call_ListRoots_603608; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listRoots
  ## <p>Lists the roots that are defined in the current organization.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p> <note> <p>Policy types can be enabled and disabled in roots. This is distinct from whether they're available in the organization. When you enable all features, you make policy types available for use in that organization. Individual policy types can then be enabled and disabled in a root. To see the availability of a policy type in an organization, use <a>DescribeOrganization</a>.</p> </note>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603624 = newJObject()
  var body_603625 = newJObject()
  add(query_603624, "NextToken", newJString(NextToken))
  if body != nil:
    body_603625 = body
  add(query_603624, "MaxResults", newJString(MaxResults))
  result = call_603623.call(nil, query_603624, nil, nil, body_603625)

var listRoots* = Call_ListRoots_603608(name: "listRoots", meth: HttpMethod.HttpPost,
                                    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListRoots",
                                    validator: validate_ListRoots_603609,
                                    base: "/", url: url_ListRoots_603610,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_603626 = ref object of OpenApiRestCall_602434
proc url_ListTagsForResource_603628(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource_603627(path: JsonNode; query: JsonNode;
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
  var valid_603629 = query.getOrDefault("NextToken")
  valid_603629 = validateParameter(valid_603629, JString, required = false,
                                 default = nil)
  if valid_603629 != nil:
    section.add "NextToken", valid_603629
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
  var valid_603630 = header.getOrDefault("X-Amz-Date")
  valid_603630 = validateParameter(valid_603630, JString, required = false,
                                 default = nil)
  if valid_603630 != nil:
    section.add "X-Amz-Date", valid_603630
  var valid_603631 = header.getOrDefault("X-Amz-Security-Token")
  valid_603631 = validateParameter(valid_603631, JString, required = false,
                                 default = nil)
  if valid_603631 != nil:
    section.add "X-Amz-Security-Token", valid_603631
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603632 = header.getOrDefault("X-Amz-Target")
  valid_603632 = validateParameter(valid_603632, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListTagsForResource"))
  if valid_603632 != nil:
    section.add "X-Amz-Target", valid_603632
  var valid_603633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603633 = validateParameter(valid_603633, JString, required = false,
                                 default = nil)
  if valid_603633 != nil:
    section.add "X-Amz-Content-Sha256", valid_603633
  var valid_603634 = header.getOrDefault("X-Amz-Algorithm")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-Algorithm", valid_603634
  var valid_603635 = header.getOrDefault("X-Amz-Signature")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "X-Amz-Signature", valid_603635
  var valid_603636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603636 = validateParameter(valid_603636, JString, required = false,
                                 default = nil)
  if valid_603636 != nil:
    section.add "X-Amz-SignedHeaders", valid_603636
  var valid_603637 = header.getOrDefault("X-Amz-Credential")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "X-Amz-Credential", valid_603637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603639: Call_ListTagsForResource_603626; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists tags for the specified resource. </p> <p>Currently, you can list tags on an account in AWS Organizations.</p>
  ## 
  let valid = call_603639.validator(path, query, header, formData, body)
  let scheme = call_603639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603639.url(scheme.get, call_603639.host, call_603639.base,
                         call_603639.route, valid.getOrDefault("path"))
  result = hook(call_603639, url, valid)

proc call*(call_603640: Call_ListTagsForResource_603626; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## listTagsForResource
  ## <p>Lists tags for the specified resource. </p> <p>Currently, you can list tags on an account in AWS Organizations.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603641 = newJObject()
  var body_603642 = newJObject()
  add(query_603641, "NextToken", newJString(NextToken))
  if body != nil:
    body_603642 = body
  result = call_603640.call(nil, query_603641, nil, nil, body_603642)

var listTagsForResource* = Call_ListTagsForResource_603626(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListTagsForResource",
    validator: validate_ListTagsForResource_603627, base: "/",
    url: url_ListTagsForResource_603628, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTargetsForPolicy_603643 = ref object of OpenApiRestCall_602434
proc url_ListTargetsForPolicy_603645(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTargetsForPolicy_603644(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists all the roots, organizational units (OUs), and accounts that the specified policy is attached to.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603646 = query.getOrDefault("NextToken")
  valid_603646 = validateParameter(valid_603646, JString, required = false,
                                 default = nil)
  if valid_603646 != nil:
    section.add "NextToken", valid_603646
  var valid_603647 = query.getOrDefault("MaxResults")
  valid_603647 = validateParameter(valid_603647, JString, required = false,
                                 default = nil)
  if valid_603647 != nil:
    section.add "MaxResults", valid_603647
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
  var valid_603648 = header.getOrDefault("X-Amz-Date")
  valid_603648 = validateParameter(valid_603648, JString, required = false,
                                 default = nil)
  if valid_603648 != nil:
    section.add "X-Amz-Date", valid_603648
  var valid_603649 = header.getOrDefault("X-Amz-Security-Token")
  valid_603649 = validateParameter(valid_603649, JString, required = false,
                                 default = nil)
  if valid_603649 != nil:
    section.add "X-Amz-Security-Token", valid_603649
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603650 = header.getOrDefault("X-Amz-Target")
  valid_603650 = validateParameter(valid_603650, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListTargetsForPolicy"))
  if valid_603650 != nil:
    section.add "X-Amz-Target", valid_603650
  var valid_603651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603651 = validateParameter(valid_603651, JString, required = false,
                                 default = nil)
  if valid_603651 != nil:
    section.add "X-Amz-Content-Sha256", valid_603651
  var valid_603652 = header.getOrDefault("X-Amz-Algorithm")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "X-Amz-Algorithm", valid_603652
  var valid_603653 = header.getOrDefault("X-Amz-Signature")
  valid_603653 = validateParameter(valid_603653, JString, required = false,
                                 default = nil)
  if valid_603653 != nil:
    section.add "X-Amz-Signature", valid_603653
  var valid_603654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603654 = validateParameter(valid_603654, JString, required = false,
                                 default = nil)
  if valid_603654 != nil:
    section.add "X-Amz-SignedHeaders", valid_603654
  var valid_603655 = header.getOrDefault("X-Amz-Credential")
  valid_603655 = validateParameter(valid_603655, JString, required = false,
                                 default = nil)
  if valid_603655 != nil:
    section.add "X-Amz-Credential", valid_603655
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603657: Call_ListTargetsForPolicy_603643; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all the roots, organizational units (OUs), and accounts that the specified policy is attached to.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_603657.validator(path, query, header, formData, body)
  let scheme = call_603657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603657.url(scheme.get, call_603657.host, call_603657.base,
                         call_603657.route, valid.getOrDefault("path"))
  result = hook(call_603657, url, valid)

proc call*(call_603658: Call_ListTargetsForPolicy_603643; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTargetsForPolicy
  ## <p>Lists all the roots, organizational units (OUs), and accounts that the specified policy is attached to.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603659 = newJObject()
  var body_603660 = newJObject()
  add(query_603659, "NextToken", newJString(NextToken))
  if body != nil:
    body_603660 = body
  add(query_603659, "MaxResults", newJString(MaxResults))
  result = call_603658.call(nil, query_603659, nil, nil, body_603660)

var listTargetsForPolicy* = Call_ListTargetsForPolicy_603643(
    name: "listTargetsForPolicy", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListTargetsForPolicy",
    validator: validate_ListTargetsForPolicy_603644, base: "/",
    url: url_ListTargetsForPolicy_603645, schemes: {Scheme.Https, Scheme.Http})
type
  Call_MoveAccount_603661 = ref object of OpenApiRestCall_602434
proc url_MoveAccount_603663(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_MoveAccount_603662(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603664 = header.getOrDefault("X-Amz-Date")
  valid_603664 = validateParameter(valid_603664, JString, required = false,
                                 default = nil)
  if valid_603664 != nil:
    section.add "X-Amz-Date", valid_603664
  var valid_603665 = header.getOrDefault("X-Amz-Security-Token")
  valid_603665 = validateParameter(valid_603665, JString, required = false,
                                 default = nil)
  if valid_603665 != nil:
    section.add "X-Amz-Security-Token", valid_603665
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603666 = header.getOrDefault("X-Amz-Target")
  valid_603666 = validateParameter(valid_603666, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.MoveAccount"))
  if valid_603666 != nil:
    section.add "X-Amz-Target", valid_603666
  var valid_603667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603667 = validateParameter(valid_603667, JString, required = false,
                                 default = nil)
  if valid_603667 != nil:
    section.add "X-Amz-Content-Sha256", valid_603667
  var valid_603668 = header.getOrDefault("X-Amz-Algorithm")
  valid_603668 = validateParameter(valid_603668, JString, required = false,
                                 default = nil)
  if valid_603668 != nil:
    section.add "X-Amz-Algorithm", valid_603668
  var valid_603669 = header.getOrDefault("X-Amz-Signature")
  valid_603669 = validateParameter(valid_603669, JString, required = false,
                                 default = nil)
  if valid_603669 != nil:
    section.add "X-Amz-Signature", valid_603669
  var valid_603670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603670 = validateParameter(valid_603670, JString, required = false,
                                 default = nil)
  if valid_603670 != nil:
    section.add "X-Amz-SignedHeaders", valid_603670
  var valid_603671 = header.getOrDefault("X-Amz-Credential")
  valid_603671 = validateParameter(valid_603671, JString, required = false,
                                 default = nil)
  if valid_603671 != nil:
    section.add "X-Amz-Credential", valid_603671
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603673: Call_MoveAccount_603661; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Moves an account from its current source parent root or organizational unit (OU) to the specified destination parent root or OU.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_603673.validator(path, query, header, formData, body)
  let scheme = call_603673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603673.url(scheme.get, call_603673.host, call_603673.base,
                         call_603673.route, valid.getOrDefault("path"))
  result = hook(call_603673, url, valid)

proc call*(call_603674: Call_MoveAccount_603661; body: JsonNode): Recallable =
  ## moveAccount
  ## <p>Moves an account from its current source parent root or organizational unit (OU) to the specified destination parent root or OU.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_603675 = newJObject()
  if body != nil:
    body_603675 = body
  result = call_603674.call(nil, nil, nil, nil, body_603675)

var moveAccount* = Call_MoveAccount_603661(name: "moveAccount",
                                        meth: HttpMethod.HttpPost,
                                        host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.MoveAccount",
                                        validator: validate_MoveAccount_603662,
                                        base: "/", url: url_MoveAccount_603663,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAccountFromOrganization_603676 = ref object of OpenApiRestCall_602434
proc url_RemoveAccountFromOrganization_603678(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RemoveAccountFromOrganization_603677(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603679 = header.getOrDefault("X-Amz-Date")
  valid_603679 = validateParameter(valid_603679, JString, required = false,
                                 default = nil)
  if valid_603679 != nil:
    section.add "X-Amz-Date", valid_603679
  var valid_603680 = header.getOrDefault("X-Amz-Security-Token")
  valid_603680 = validateParameter(valid_603680, JString, required = false,
                                 default = nil)
  if valid_603680 != nil:
    section.add "X-Amz-Security-Token", valid_603680
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603681 = header.getOrDefault("X-Amz-Target")
  valid_603681 = validateParameter(valid_603681, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.RemoveAccountFromOrganization"))
  if valid_603681 != nil:
    section.add "X-Amz-Target", valid_603681
  var valid_603682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603682 = validateParameter(valid_603682, JString, required = false,
                                 default = nil)
  if valid_603682 != nil:
    section.add "X-Amz-Content-Sha256", valid_603682
  var valid_603683 = header.getOrDefault("X-Amz-Algorithm")
  valid_603683 = validateParameter(valid_603683, JString, required = false,
                                 default = nil)
  if valid_603683 != nil:
    section.add "X-Amz-Algorithm", valid_603683
  var valid_603684 = header.getOrDefault("X-Amz-Signature")
  valid_603684 = validateParameter(valid_603684, JString, required = false,
                                 default = nil)
  if valid_603684 != nil:
    section.add "X-Amz-Signature", valid_603684
  var valid_603685 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603685 = validateParameter(valid_603685, JString, required = false,
                                 default = nil)
  if valid_603685 != nil:
    section.add "X-Amz-SignedHeaders", valid_603685
  var valid_603686 = header.getOrDefault("X-Amz-Credential")
  valid_603686 = validateParameter(valid_603686, JString, required = false,
                                 default = nil)
  if valid_603686 != nil:
    section.add "X-Amz-Credential", valid_603686
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603688: Call_RemoveAccountFromOrganization_603676; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified account from the organization.</p> <p>The removed account becomes a standalone account that isn't a member of any organization. It's no longer subject to any policies and is responsible for its own bill payments. The organization's master account is no longer charged for any expenses accrued by the member account after it's removed from the organization.</p> <p>This operation can be called only from the organization's master account. Member accounts can remove themselves with <a>LeaveOrganization</a> instead.</p> <important> <p>You can remove an account from your organization only if the account is configured with the information required to operate as a standalone account. When you create an account in an organization using the AWS Organizations console, API, or CLI commands, the information required of standalone accounts is <i>not</i> automatically collected. For an account that you want to make standalone, you must accept the end user license agreement (EULA), choose a support plan, provide and verify the required contact information, and provide a current payment method. AWS uses the payment method to charge for any billable (not free tier) AWS activity that occurs while the account isn't attached to an organization. To remove an account that doesn't yet have this information, you must sign in as the member account and follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization when all required account information has not yet been provided</a> in the <i>AWS Organizations User Guide.</i> </p> </important>
  ## 
  let valid = call_603688.validator(path, query, header, formData, body)
  let scheme = call_603688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603688.url(scheme.get, call_603688.host, call_603688.base,
                         call_603688.route, valid.getOrDefault("path"))
  result = hook(call_603688, url, valid)

proc call*(call_603689: Call_RemoveAccountFromOrganization_603676; body: JsonNode): Recallable =
  ## removeAccountFromOrganization
  ## <p>Removes the specified account from the organization.</p> <p>The removed account becomes a standalone account that isn't a member of any organization. It's no longer subject to any policies and is responsible for its own bill payments. The organization's master account is no longer charged for any expenses accrued by the member account after it's removed from the organization.</p> <p>This operation can be called only from the organization's master account. Member accounts can remove themselves with <a>LeaveOrganization</a> instead.</p> <important> <p>You can remove an account from your organization only if the account is configured with the information required to operate as a standalone account. When you create an account in an organization using the AWS Organizations console, API, or CLI commands, the information required of standalone accounts is <i>not</i> automatically collected. For an account that you want to make standalone, you must accept the end user license agreement (EULA), choose a support plan, provide and verify the required contact information, and provide a current payment method. AWS uses the payment method to charge for any billable (not free tier) AWS activity that occurs while the account isn't attached to an organization. To remove an account that doesn't yet have this information, you must sign in as the member account and follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization when all required account information has not yet been provided</a> in the <i>AWS Organizations User Guide.</i> </p> </important>
  ##   body: JObject (required)
  var body_603690 = newJObject()
  if body != nil:
    body_603690 = body
  result = call_603689.call(nil, nil, nil, nil, body_603690)

var removeAccountFromOrganization* = Call_RemoveAccountFromOrganization_603676(
    name: "removeAccountFromOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.RemoveAccountFromOrganization",
    validator: validate_RemoveAccountFromOrganization_603677, base: "/",
    url: url_RemoveAccountFromOrganization_603678,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603691 = ref object of OpenApiRestCall_602434
proc url_TagResource_603693(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_603692(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603694 = header.getOrDefault("X-Amz-Date")
  valid_603694 = validateParameter(valid_603694, JString, required = false,
                                 default = nil)
  if valid_603694 != nil:
    section.add "X-Amz-Date", valid_603694
  var valid_603695 = header.getOrDefault("X-Amz-Security-Token")
  valid_603695 = validateParameter(valid_603695, JString, required = false,
                                 default = nil)
  if valid_603695 != nil:
    section.add "X-Amz-Security-Token", valid_603695
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603696 = header.getOrDefault("X-Amz-Target")
  valid_603696 = validateParameter(valid_603696, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.TagResource"))
  if valid_603696 != nil:
    section.add "X-Amz-Target", valid_603696
  var valid_603697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603697 = validateParameter(valid_603697, JString, required = false,
                                 default = nil)
  if valid_603697 != nil:
    section.add "X-Amz-Content-Sha256", valid_603697
  var valid_603698 = header.getOrDefault("X-Amz-Algorithm")
  valid_603698 = validateParameter(valid_603698, JString, required = false,
                                 default = nil)
  if valid_603698 != nil:
    section.add "X-Amz-Algorithm", valid_603698
  var valid_603699 = header.getOrDefault("X-Amz-Signature")
  valid_603699 = validateParameter(valid_603699, JString, required = false,
                                 default = nil)
  if valid_603699 != nil:
    section.add "X-Amz-Signature", valid_603699
  var valid_603700 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603700 = validateParameter(valid_603700, JString, required = false,
                                 default = nil)
  if valid_603700 != nil:
    section.add "X-Amz-SignedHeaders", valid_603700
  var valid_603701 = header.getOrDefault("X-Amz-Credential")
  valid_603701 = validateParameter(valid_603701, JString, required = false,
                                 default = nil)
  if valid_603701 != nil:
    section.add "X-Amz-Credential", valid_603701
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603703: Call_TagResource_603691; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more tags to the specified resource.</p> <p>Currently, you can tag and untag accounts in AWS Organizations.</p>
  ## 
  let valid = call_603703.validator(path, query, header, formData, body)
  let scheme = call_603703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603703.url(scheme.get, call_603703.host, call_603703.base,
                         call_603703.route, valid.getOrDefault("path"))
  result = hook(call_603703, url, valid)

proc call*(call_603704: Call_TagResource_603691; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds one or more tags to the specified resource.</p> <p>Currently, you can tag and untag accounts in AWS Organizations.</p>
  ##   body: JObject (required)
  var body_603705 = newJObject()
  if body != nil:
    body_603705 = body
  result = call_603704.call(nil, nil, nil, nil, body_603705)

var tagResource* = Call_TagResource_603691(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.TagResource",
                                        validator: validate_TagResource_603692,
                                        base: "/", url: url_TagResource_603693,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603706 = ref object of OpenApiRestCall_602434
proc url_UntagResource_603708(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_603707(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603709 = header.getOrDefault("X-Amz-Date")
  valid_603709 = validateParameter(valid_603709, JString, required = false,
                                 default = nil)
  if valid_603709 != nil:
    section.add "X-Amz-Date", valid_603709
  var valid_603710 = header.getOrDefault("X-Amz-Security-Token")
  valid_603710 = validateParameter(valid_603710, JString, required = false,
                                 default = nil)
  if valid_603710 != nil:
    section.add "X-Amz-Security-Token", valid_603710
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603711 = header.getOrDefault("X-Amz-Target")
  valid_603711 = validateParameter(valid_603711, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.UntagResource"))
  if valid_603711 != nil:
    section.add "X-Amz-Target", valid_603711
  var valid_603712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603712 = validateParameter(valid_603712, JString, required = false,
                                 default = nil)
  if valid_603712 != nil:
    section.add "X-Amz-Content-Sha256", valid_603712
  var valid_603713 = header.getOrDefault("X-Amz-Algorithm")
  valid_603713 = validateParameter(valid_603713, JString, required = false,
                                 default = nil)
  if valid_603713 != nil:
    section.add "X-Amz-Algorithm", valid_603713
  var valid_603714 = header.getOrDefault("X-Amz-Signature")
  valid_603714 = validateParameter(valid_603714, JString, required = false,
                                 default = nil)
  if valid_603714 != nil:
    section.add "X-Amz-Signature", valid_603714
  var valid_603715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603715 = validateParameter(valid_603715, JString, required = false,
                                 default = nil)
  if valid_603715 != nil:
    section.add "X-Amz-SignedHeaders", valid_603715
  var valid_603716 = header.getOrDefault("X-Amz-Credential")
  valid_603716 = validateParameter(valid_603716, JString, required = false,
                                 default = nil)
  if valid_603716 != nil:
    section.add "X-Amz-Credential", valid_603716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603718: Call_UntagResource_603706; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a tag from the specified resource. </p> <p>Currently, you can tag and untag accounts in AWS Organizations.</p>
  ## 
  let valid = call_603718.validator(path, query, header, formData, body)
  let scheme = call_603718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603718.url(scheme.get, call_603718.host, call_603718.base,
                         call_603718.route, valid.getOrDefault("path"))
  result = hook(call_603718, url, valid)

proc call*(call_603719: Call_UntagResource_603706; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Removes a tag from the specified resource. </p> <p>Currently, you can tag and untag accounts in AWS Organizations.</p>
  ##   body: JObject (required)
  var body_603720 = newJObject()
  if body != nil:
    body_603720 = body
  result = call_603719.call(nil, nil, nil, nil, body_603720)

var untagResource* = Call_UntagResource_603706(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.UntagResource",
    validator: validate_UntagResource_603707, base: "/", url: url_UntagResource_603708,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateOrganizationalUnit_603721 = ref object of OpenApiRestCall_602434
proc url_UpdateOrganizationalUnit_603723(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateOrganizationalUnit_603722(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603724 = header.getOrDefault("X-Amz-Date")
  valid_603724 = validateParameter(valid_603724, JString, required = false,
                                 default = nil)
  if valid_603724 != nil:
    section.add "X-Amz-Date", valid_603724
  var valid_603725 = header.getOrDefault("X-Amz-Security-Token")
  valid_603725 = validateParameter(valid_603725, JString, required = false,
                                 default = nil)
  if valid_603725 != nil:
    section.add "X-Amz-Security-Token", valid_603725
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603726 = header.getOrDefault("X-Amz-Target")
  valid_603726 = validateParameter(valid_603726, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.UpdateOrganizationalUnit"))
  if valid_603726 != nil:
    section.add "X-Amz-Target", valid_603726
  var valid_603727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603727 = validateParameter(valid_603727, JString, required = false,
                                 default = nil)
  if valid_603727 != nil:
    section.add "X-Amz-Content-Sha256", valid_603727
  var valid_603728 = header.getOrDefault("X-Amz-Algorithm")
  valid_603728 = validateParameter(valid_603728, JString, required = false,
                                 default = nil)
  if valid_603728 != nil:
    section.add "X-Amz-Algorithm", valid_603728
  var valid_603729 = header.getOrDefault("X-Amz-Signature")
  valid_603729 = validateParameter(valid_603729, JString, required = false,
                                 default = nil)
  if valid_603729 != nil:
    section.add "X-Amz-Signature", valid_603729
  var valid_603730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603730 = validateParameter(valid_603730, JString, required = false,
                                 default = nil)
  if valid_603730 != nil:
    section.add "X-Amz-SignedHeaders", valid_603730
  var valid_603731 = header.getOrDefault("X-Amz-Credential")
  valid_603731 = validateParameter(valid_603731, JString, required = false,
                                 default = nil)
  if valid_603731 != nil:
    section.add "X-Amz-Credential", valid_603731
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603733: Call_UpdateOrganizationalUnit_603721; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Renames the specified organizational unit (OU). The ID and ARN don't change. The child OUs and accounts remain in place, and any attached policies of the OU remain attached. </p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_603733.validator(path, query, header, formData, body)
  let scheme = call_603733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603733.url(scheme.get, call_603733.host, call_603733.base,
                         call_603733.route, valid.getOrDefault("path"))
  result = hook(call_603733, url, valid)

proc call*(call_603734: Call_UpdateOrganizationalUnit_603721; body: JsonNode): Recallable =
  ## updateOrganizationalUnit
  ## <p>Renames the specified organizational unit (OU). The ID and ARN don't change. The child OUs and accounts remain in place, and any attached policies of the OU remain attached. </p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_603735 = newJObject()
  if body != nil:
    body_603735 = body
  result = call_603734.call(nil, nil, nil, nil, body_603735)

var updateOrganizationalUnit* = Call_UpdateOrganizationalUnit_603721(
    name: "updateOrganizationalUnit", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.UpdateOrganizationalUnit",
    validator: validate_UpdateOrganizationalUnit_603722, base: "/",
    url: url_UpdateOrganizationalUnit_603723, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePolicy_603736 = ref object of OpenApiRestCall_602434
proc url_UpdatePolicy_603738(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdatePolicy_603737(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603739 = header.getOrDefault("X-Amz-Date")
  valid_603739 = validateParameter(valid_603739, JString, required = false,
                                 default = nil)
  if valid_603739 != nil:
    section.add "X-Amz-Date", valid_603739
  var valid_603740 = header.getOrDefault("X-Amz-Security-Token")
  valid_603740 = validateParameter(valid_603740, JString, required = false,
                                 default = nil)
  if valid_603740 != nil:
    section.add "X-Amz-Security-Token", valid_603740
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603741 = header.getOrDefault("X-Amz-Target")
  valid_603741 = validateParameter(valid_603741, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.UpdatePolicy"))
  if valid_603741 != nil:
    section.add "X-Amz-Target", valid_603741
  var valid_603742 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603742 = validateParameter(valid_603742, JString, required = false,
                                 default = nil)
  if valid_603742 != nil:
    section.add "X-Amz-Content-Sha256", valid_603742
  var valid_603743 = header.getOrDefault("X-Amz-Algorithm")
  valid_603743 = validateParameter(valid_603743, JString, required = false,
                                 default = nil)
  if valid_603743 != nil:
    section.add "X-Amz-Algorithm", valid_603743
  var valid_603744 = header.getOrDefault("X-Amz-Signature")
  valid_603744 = validateParameter(valid_603744, JString, required = false,
                                 default = nil)
  if valid_603744 != nil:
    section.add "X-Amz-Signature", valid_603744
  var valid_603745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603745 = validateParameter(valid_603745, JString, required = false,
                                 default = nil)
  if valid_603745 != nil:
    section.add "X-Amz-SignedHeaders", valid_603745
  var valid_603746 = header.getOrDefault("X-Amz-Credential")
  valid_603746 = validateParameter(valid_603746, JString, required = false,
                                 default = nil)
  if valid_603746 != nil:
    section.add "X-Amz-Credential", valid_603746
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603748: Call_UpdatePolicy_603736; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing policy with a new name, description, or content. If you don't supply any parameter, that value remains unchanged. You can't change a policy's type.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_603748.validator(path, query, header, formData, body)
  let scheme = call_603748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603748.url(scheme.get, call_603748.host, call_603748.base,
                         call_603748.route, valid.getOrDefault("path"))
  result = hook(call_603748, url, valid)

proc call*(call_603749: Call_UpdatePolicy_603736; body: JsonNode): Recallable =
  ## updatePolicy
  ## <p>Updates an existing policy with a new name, description, or content. If you don't supply any parameter, that value remains unchanged. You can't change a policy's type.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_603750 = newJObject()
  if body != nil:
    body_603750 = body
  result = call_603749.call(nil, nil, nil, nil, body_603750)

var updatePolicy* = Call_UpdatePolicy_603736(name: "updatePolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.UpdatePolicy",
    validator: validate_UpdatePolicy_603737, base: "/", url: url_UpdatePolicy_603738,
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
