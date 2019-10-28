
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
## <fullname>AWS Organizations</fullname>
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

  OpenApiRestCall_590365 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_590365](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_590365): Option[Scheme] {.used.} =
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
  Call_AcceptHandshake_590704 = ref object of OpenApiRestCall_590365
proc url_AcceptHandshake_590706(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AcceptHandshake_590705(path: JsonNode; query: JsonNode;
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
  var valid_590831 = header.getOrDefault("X-Amz-Target")
  valid_590831 = validateParameter(valid_590831, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.AcceptHandshake"))
  if valid_590831 != nil:
    section.add "X-Amz-Target", valid_590831
  var valid_590832 = header.getOrDefault("X-Amz-Signature")
  valid_590832 = validateParameter(valid_590832, JString, required = false,
                                 default = nil)
  if valid_590832 != nil:
    section.add "X-Amz-Signature", valid_590832
  var valid_590833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590833 = validateParameter(valid_590833, JString, required = false,
                                 default = nil)
  if valid_590833 != nil:
    section.add "X-Amz-Content-Sha256", valid_590833
  var valid_590834 = header.getOrDefault("X-Amz-Date")
  valid_590834 = validateParameter(valid_590834, JString, required = false,
                                 default = nil)
  if valid_590834 != nil:
    section.add "X-Amz-Date", valid_590834
  var valid_590835 = header.getOrDefault("X-Amz-Credential")
  valid_590835 = validateParameter(valid_590835, JString, required = false,
                                 default = nil)
  if valid_590835 != nil:
    section.add "X-Amz-Credential", valid_590835
  var valid_590836 = header.getOrDefault("X-Amz-Security-Token")
  valid_590836 = validateParameter(valid_590836, JString, required = false,
                                 default = nil)
  if valid_590836 != nil:
    section.add "X-Amz-Security-Token", valid_590836
  var valid_590837 = header.getOrDefault("X-Amz-Algorithm")
  valid_590837 = validateParameter(valid_590837, JString, required = false,
                                 default = nil)
  if valid_590837 != nil:
    section.add "X-Amz-Algorithm", valid_590837
  var valid_590838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590838 = validateParameter(valid_590838, JString, required = false,
                                 default = nil)
  if valid_590838 != nil:
    section.add "X-Amz-SignedHeaders", valid_590838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590862: Call_AcceptHandshake_590704; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends a response to the originator of a handshake agreeing to the action proposed by the handshake request. </p> <p>This operation can be called only by the following principals when they also have the relevant IAM permissions:</p> <ul> <li> <p> <b>Invitation to join</b> or <b>Approve all features request</b> handshakes: only a principal from the member account. </p> <p>The user who calls the API for an invitation to join must have the <code>organizations:AcceptHandshake</code> permission. If you enabled all features in the organization, the user must also have the <code>iam:CreateServiceLinkedRole</code> permission so that AWS Organizations can create the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integration_services.html#orgs_integration_service-linked-roles">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide</i>.</p> </li> <li> <p> <b>Enable all features final confirmation</b> handshake: only a principal from the master account.</p> <p>For more information about invitations, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_invites.html">Inviting an AWS Account to Join Your Organization</a> in the <i>AWS Organizations User Guide.</i> For more information about requests to enable all features in the organization, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">Enabling All Features in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>After you accept a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
  ## 
  let valid = call_590862.validator(path, query, header, formData, body)
  let scheme = call_590862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590862.url(scheme.get, call_590862.host, call_590862.base,
                         call_590862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590862, url, valid)

proc call*(call_590933: Call_AcceptHandshake_590704; body: JsonNode): Recallable =
  ## acceptHandshake
  ## <p>Sends a response to the originator of a handshake agreeing to the action proposed by the handshake request. </p> <p>This operation can be called only by the following principals when they also have the relevant IAM permissions:</p> <ul> <li> <p> <b>Invitation to join</b> or <b>Approve all features request</b> handshakes: only a principal from the member account. </p> <p>The user who calls the API for an invitation to join must have the <code>organizations:AcceptHandshake</code> permission. If you enabled all features in the organization, the user must also have the <code>iam:CreateServiceLinkedRole</code> permission so that AWS Organizations can create the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integration_services.html#orgs_integration_service-linked-roles">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide</i>.</p> </li> <li> <p> <b>Enable all features final confirmation</b> handshake: only a principal from the master account.</p> <p>For more information about invitations, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_invites.html">Inviting an AWS Account to Join Your Organization</a> in the <i>AWS Organizations User Guide.</i> For more information about requests to enable all features in the organization, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">Enabling All Features in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>After you accept a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
  ##   body: JObject (required)
  var body_590934 = newJObject()
  if body != nil:
    body_590934 = body
  result = call_590933.call(nil, nil, nil, nil, body_590934)

var acceptHandshake* = Call_AcceptHandshake_590704(name: "acceptHandshake",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.AcceptHandshake",
    validator: validate_AcceptHandshake_590705, base: "/", url: url_AcceptHandshake_590706,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachPolicy_590973 = ref object of OpenApiRestCall_590365
proc url_AttachPolicy_590975(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AttachPolicy_590974(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_590976 = header.getOrDefault("X-Amz-Target")
  valid_590976 = validateParameter(valid_590976, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.AttachPolicy"))
  if valid_590976 != nil:
    section.add "X-Amz-Target", valid_590976
  var valid_590977 = header.getOrDefault("X-Amz-Signature")
  valid_590977 = validateParameter(valid_590977, JString, required = false,
                                 default = nil)
  if valid_590977 != nil:
    section.add "X-Amz-Signature", valid_590977
  var valid_590978 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590978 = validateParameter(valid_590978, JString, required = false,
                                 default = nil)
  if valid_590978 != nil:
    section.add "X-Amz-Content-Sha256", valid_590978
  var valid_590979 = header.getOrDefault("X-Amz-Date")
  valid_590979 = validateParameter(valid_590979, JString, required = false,
                                 default = nil)
  if valid_590979 != nil:
    section.add "X-Amz-Date", valid_590979
  var valid_590980 = header.getOrDefault("X-Amz-Credential")
  valid_590980 = validateParameter(valid_590980, JString, required = false,
                                 default = nil)
  if valid_590980 != nil:
    section.add "X-Amz-Credential", valid_590980
  var valid_590981 = header.getOrDefault("X-Amz-Security-Token")
  valid_590981 = validateParameter(valid_590981, JString, required = false,
                                 default = nil)
  if valid_590981 != nil:
    section.add "X-Amz-Security-Token", valid_590981
  var valid_590982 = header.getOrDefault("X-Amz-Algorithm")
  valid_590982 = validateParameter(valid_590982, JString, required = false,
                                 default = nil)
  if valid_590982 != nil:
    section.add "X-Amz-Algorithm", valid_590982
  var valid_590983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590983 = validateParameter(valid_590983, JString, required = false,
                                 default = nil)
  if valid_590983 != nil:
    section.add "X-Amz-SignedHeaders", valid_590983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590985: Call_AttachPolicy_590973; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches a policy to a root, an organizational unit (OU), or an individual account. How the policy affects accounts depends on the type of policy:</p> <ul> <li> <p> <b>Service control policy (SCP)</b> - An SCP specifies what permissions can be delegated to users in affected member accounts. The scope of influence for a policy depends on what you attach the policy to:</p> <ul> <li> <p>If you attach an SCP to a root, it affects all accounts in the organization.</p> </li> <li> <p>If you attach an SCP to an OU, it affects all accounts in that OU and in any child OUs.</p> </li> <li> <p>If you attach the policy directly to an account, it affects only that account.</p> </li> </ul> <p>SCPs are JSON policies that specify the maximum permissions for an organization or organizational unit (OU). You can attach one SCP to a higher level root or OU, and a different SCP to a child OU or to an account. The child policy can further restrict only the permissions that pass through the parent filter and are available to the child. An SCP that is attached to a child can't grant a permission that the parent hasn't already granted. For example, imagine that the parent SCP allows permissions A, B, C, D, and E. The child SCP allows C, D, E, F, and G. The result is that the accounts affected by the child SCP are allowed to use only C, D, and E. They can't use A or B because the child OU filtered them out. They also can't use F and G because the parent OU filtered them out. They can't be granted back by the child SCP; child SCPs can only filter the permissions they receive from the parent SCP.</p> <p>AWS Organizations attaches a default SCP named <code>"FullAWSAccess</code> to every root, OU, and account. This default SCP allows all services and actions, enabling any new child OU or account to inherit the permissions of the parent root or OU. If you detach the default policy, you must replace it with a policy that specifies the permissions that you want to allow in that OU or account.</p> <p>For more information about how AWS Organizations policies permissions work, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scp.html">Using Service Control Policies</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_590985.validator(path, query, header, formData, body)
  let scheme = call_590985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590985.url(scheme.get, call_590985.host, call_590985.base,
                         call_590985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590985, url, valid)

proc call*(call_590986: Call_AttachPolicy_590973; body: JsonNode): Recallable =
  ## attachPolicy
  ## <p>Attaches a policy to a root, an organizational unit (OU), or an individual account. How the policy affects accounts depends on the type of policy:</p> <ul> <li> <p> <b>Service control policy (SCP)</b> - An SCP specifies what permissions can be delegated to users in affected member accounts. The scope of influence for a policy depends on what you attach the policy to:</p> <ul> <li> <p>If you attach an SCP to a root, it affects all accounts in the organization.</p> </li> <li> <p>If you attach an SCP to an OU, it affects all accounts in that OU and in any child OUs.</p> </li> <li> <p>If you attach the policy directly to an account, it affects only that account.</p> </li> </ul> <p>SCPs are JSON policies that specify the maximum permissions for an organization or organizational unit (OU). You can attach one SCP to a higher level root or OU, and a different SCP to a child OU or to an account. The child policy can further restrict only the permissions that pass through the parent filter and are available to the child. An SCP that is attached to a child can't grant a permission that the parent hasn't already granted. For example, imagine that the parent SCP allows permissions A, B, C, D, and E. The child SCP allows C, D, E, F, and G. The result is that the accounts affected by the child SCP are allowed to use only C, D, and E. They can't use A or B because the child OU filtered them out. They also can't use F and G because the parent OU filtered them out. They can't be granted back by the child SCP; child SCPs can only filter the permissions they receive from the parent SCP.</p> <p>AWS Organizations attaches a default SCP named <code>"FullAWSAccess</code> to every root, OU, and account. This default SCP allows all services and actions, enabling any new child OU or account to inherit the permissions of the parent root or OU. If you detach the default policy, you must replace it with a policy that specifies the permissions that you want to allow in that OU or account.</p> <p>For more information about how AWS Organizations policies permissions work, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scp.html">Using Service Control Policies</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_590987 = newJObject()
  if body != nil:
    body_590987 = body
  result = call_590986.call(nil, nil, nil, nil, body_590987)

var attachPolicy* = Call_AttachPolicy_590973(name: "attachPolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.AttachPolicy",
    validator: validate_AttachPolicy_590974, base: "/", url: url_AttachPolicy_590975,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelHandshake_590988 = ref object of OpenApiRestCall_590365
proc url_CancelHandshake_590990(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelHandshake_590989(path: JsonNode; query: JsonNode;
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
  var valid_590991 = header.getOrDefault("X-Amz-Target")
  valid_590991 = validateParameter(valid_590991, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CancelHandshake"))
  if valid_590991 != nil:
    section.add "X-Amz-Target", valid_590991
  var valid_590992 = header.getOrDefault("X-Amz-Signature")
  valid_590992 = validateParameter(valid_590992, JString, required = false,
                                 default = nil)
  if valid_590992 != nil:
    section.add "X-Amz-Signature", valid_590992
  var valid_590993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590993 = validateParameter(valid_590993, JString, required = false,
                                 default = nil)
  if valid_590993 != nil:
    section.add "X-Amz-Content-Sha256", valid_590993
  var valid_590994 = header.getOrDefault("X-Amz-Date")
  valid_590994 = validateParameter(valid_590994, JString, required = false,
                                 default = nil)
  if valid_590994 != nil:
    section.add "X-Amz-Date", valid_590994
  var valid_590995 = header.getOrDefault("X-Amz-Credential")
  valid_590995 = validateParameter(valid_590995, JString, required = false,
                                 default = nil)
  if valid_590995 != nil:
    section.add "X-Amz-Credential", valid_590995
  var valid_590996 = header.getOrDefault("X-Amz-Security-Token")
  valid_590996 = validateParameter(valid_590996, JString, required = false,
                                 default = nil)
  if valid_590996 != nil:
    section.add "X-Amz-Security-Token", valid_590996
  var valid_590997 = header.getOrDefault("X-Amz-Algorithm")
  valid_590997 = validateParameter(valid_590997, JString, required = false,
                                 default = nil)
  if valid_590997 != nil:
    section.add "X-Amz-Algorithm", valid_590997
  var valid_590998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590998 = validateParameter(valid_590998, JString, required = false,
                                 default = nil)
  if valid_590998 != nil:
    section.add "X-Amz-SignedHeaders", valid_590998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591000: Call_CancelHandshake_590988; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Cancels a handshake. Canceling a handshake sets the handshake state to <code>CANCELED</code>. </p> <p>This operation can be called only from the account that originated the handshake. The recipient of the handshake can't cancel it, but can use <a>DeclineHandshake</a> instead. After a handshake is canceled, the recipient can no longer respond to that handshake.</p> <p>After you cancel a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
  ## 
  let valid = call_591000.validator(path, query, header, formData, body)
  let scheme = call_591000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591000.url(scheme.get, call_591000.host, call_591000.base,
                         call_591000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591000, url, valid)

proc call*(call_591001: Call_CancelHandshake_590988; body: JsonNode): Recallable =
  ## cancelHandshake
  ## <p>Cancels a handshake. Canceling a handshake sets the handshake state to <code>CANCELED</code>. </p> <p>This operation can be called only from the account that originated the handshake. The recipient of the handshake can't cancel it, but can use <a>DeclineHandshake</a> instead. After a handshake is canceled, the recipient can no longer respond to that handshake.</p> <p>After you cancel a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
  ##   body: JObject (required)
  var body_591002 = newJObject()
  if body != nil:
    body_591002 = body
  result = call_591001.call(nil, nil, nil, nil, body_591002)

var cancelHandshake* = Call_CancelHandshake_590988(name: "cancelHandshake",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CancelHandshake",
    validator: validate_CancelHandshake_590989, base: "/", url: url_CancelHandshake_590990,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAccount_591003 = ref object of OpenApiRestCall_590365
proc url_CreateAccount_591005(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateAccount_591004(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591006 = header.getOrDefault("X-Amz-Target")
  valid_591006 = validateParameter(valid_591006, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CreateAccount"))
  if valid_591006 != nil:
    section.add "X-Amz-Target", valid_591006
  var valid_591007 = header.getOrDefault("X-Amz-Signature")
  valid_591007 = validateParameter(valid_591007, JString, required = false,
                                 default = nil)
  if valid_591007 != nil:
    section.add "X-Amz-Signature", valid_591007
  var valid_591008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591008 = validateParameter(valid_591008, JString, required = false,
                                 default = nil)
  if valid_591008 != nil:
    section.add "X-Amz-Content-Sha256", valid_591008
  var valid_591009 = header.getOrDefault("X-Amz-Date")
  valid_591009 = validateParameter(valid_591009, JString, required = false,
                                 default = nil)
  if valid_591009 != nil:
    section.add "X-Amz-Date", valid_591009
  var valid_591010 = header.getOrDefault("X-Amz-Credential")
  valid_591010 = validateParameter(valid_591010, JString, required = false,
                                 default = nil)
  if valid_591010 != nil:
    section.add "X-Amz-Credential", valid_591010
  var valid_591011 = header.getOrDefault("X-Amz-Security-Token")
  valid_591011 = validateParameter(valid_591011, JString, required = false,
                                 default = nil)
  if valid_591011 != nil:
    section.add "X-Amz-Security-Token", valid_591011
  var valid_591012 = header.getOrDefault("X-Amz-Algorithm")
  valid_591012 = validateParameter(valid_591012, JString, required = false,
                                 default = nil)
  if valid_591012 != nil:
    section.add "X-Amz-Algorithm", valid_591012
  var valid_591013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591013 = validateParameter(valid_591013, JString, required = false,
                                 default = nil)
  if valid_591013 != nil:
    section.add "X-Amz-SignedHeaders", valid_591013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591015: Call_CreateAccount_591003; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS account that is automatically a member of the organization whose credentials made the request. This is an asynchronous request that AWS performs in the background. Because <code>CreateAccount</code> operates asynchronously, it can return a successful completion message even though account initialization might still be in progress. You might need to wait a few minutes before you can successfully access the account. To check the status of the request, do one of the following:</p> <ul> <li> <p>Use the <code>OperationId</code> response element from this operation to provide as a parameter to the <a>DescribeCreateAccountStatus</a> operation.</p> </li> <li> <p>Check the AWS CloudTrail log for the <code>CreateAccountResult</code> event. For information on using AWS CloudTrail with AWS Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_monitoring.html">Monitoring the Activity in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p/> <p>The user who calls the API to create an account must have the <code>organizations:CreateAccount</code> permission. If you enabled all features in the organization, AWS Organizations creates the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html#orgs_integrate_services-using_slrs">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide</i>.</p> <p>AWS Organizations preconfigures the new member account with a role (named <code>OrganizationAccountAccessRole</code> by default) that grants users in the master account administrator permissions in the new member account. Principals in the master account can assume the role. AWS Organizations clones the company name and address information for the new account from the organization's master account.</p> <p>This operation can be called only from the organization's master account.</p> <p>For more information about creating accounts, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_create.html">Creating an AWS Account in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <ul> <li> <p>When you create an account in an organization using the AWS Organizations console, API, or CLI commands, the information required for the account to operate as a standalone account, such as a payment method and signing the end user license agreement (EULA) is <i>not</i> automatically collected. If you must remove an account from your organization later, you can do so only after you provide the missing information. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization as a member account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> <li> <p>If you get an exception that indicates that you exceeded your account limits for the organization, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>If you get an exception that indicates that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>Using <code>CreateAccount</code> to create multiple temporary accounts isn't recommended. You can only close an account from the Billing and Cost Management Console, and you must be signed in as the root user. For information on the requirements and process for closing an account, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html">Closing an AWS Account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> </ul> </important> <note> <p>When you create a member account with this operation, you can choose whether to create the account with the <b>IAM User and Role Access to Billing Information</b> switch enabled. If you enable it, IAM users and roles that have appropriate permissions can view billing information for the account. If you disable it, only the account root user can access billing information. For information about how to disable this switch for an account, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html">Granting Access to Your Billing Information and Tools</a>.</p> </note>
  ## 
  let valid = call_591015.validator(path, query, header, formData, body)
  let scheme = call_591015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591015.url(scheme.get, call_591015.host, call_591015.base,
                         call_591015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591015, url, valid)

proc call*(call_591016: Call_CreateAccount_591003; body: JsonNode): Recallable =
  ## createAccount
  ## <p>Creates an AWS account that is automatically a member of the organization whose credentials made the request. This is an asynchronous request that AWS performs in the background. Because <code>CreateAccount</code> operates asynchronously, it can return a successful completion message even though account initialization might still be in progress. You might need to wait a few minutes before you can successfully access the account. To check the status of the request, do one of the following:</p> <ul> <li> <p>Use the <code>OperationId</code> response element from this operation to provide as a parameter to the <a>DescribeCreateAccountStatus</a> operation.</p> </li> <li> <p>Check the AWS CloudTrail log for the <code>CreateAccountResult</code> event. For information on using AWS CloudTrail with AWS Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_monitoring.html">Monitoring the Activity in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p/> <p>The user who calls the API to create an account must have the <code>organizations:CreateAccount</code> permission. If you enabled all features in the organization, AWS Organizations creates the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html#orgs_integrate_services-using_slrs">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide</i>.</p> <p>AWS Organizations preconfigures the new member account with a role (named <code>OrganizationAccountAccessRole</code> by default) that grants users in the master account administrator permissions in the new member account. Principals in the master account can assume the role. AWS Organizations clones the company name and address information for the new account from the organization's master account.</p> <p>This operation can be called only from the organization's master account.</p> <p>For more information about creating accounts, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_create.html">Creating an AWS Account in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <ul> <li> <p>When you create an account in an organization using the AWS Organizations console, API, or CLI commands, the information required for the account to operate as a standalone account, such as a payment method and signing the end user license agreement (EULA) is <i>not</i> automatically collected. If you must remove an account from your organization later, you can do so only after you provide the missing information. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization as a member account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> <li> <p>If you get an exception that indicates that you exceeded your account limits for the organization, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>If you get an exception that indicates that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>Using <code>CreateAccount</code> to create multiple temporary accounts isn't recommended. You can only close an account from the Billing and Cost Management Console, and you must be signed in as the root user. For information on the requirements and process for closing an account, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html">Closing an AWS Account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> </ul> </important> <note> <p>When you create a member account with this operation, you can choose whether to create the account with the <b>IAM User and Role Access to Billing Information</b> switch enabled. If you enable it, IAM users and roles that have appropriate permissions can view billing information for the account. If you disable it, only the account root user can access billing information. For information about how to disable this switch for an account, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html">Granting Access to Your Billing Information and Tools</a>.</p> </note>
  ##   body: JObject (required)
  var body_591017 = newJObject()
  if body != nil:
    body_591017 = body
  result = call_591016.call(nil, nil, nil, nil, body_591017)

var createAccount* = Call_CreateAccount_591003(name: "createAccount",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CreateAccount",
    validator: validate_CreateAccount_591004, base: "/", url: url_CreateAccount_591005,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGovCloudAccount_591018 = ref object of OpenApiRestCall_590365
proc url_CreateGovCloudAccount_591020(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateGovCloudAccount_591019(path: JsonNode; query: JsonNode;
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
  var valid_591021 = header.getOrDefault("X-Amz-Target")
  valid_591021 = validateParameter(valid_591021, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CreateGovCloudAccount"))
  if valid_591021 != nil:
    section.add "X-Amz-Target", valid_591021
  var valid_591022 = header.getOrDefault("X-Amz-Signature")
  valid_591022 = validateParameter(valid_591022, JString, required = false,
                                 default = nil)
  if valid_591022 != nil:
    section.add "X-Amz-Signature", valid_591022
  var valid_591023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591023 = validateParameter(valid_591023, JString, required = false,
                                 default = nil)
  if valid_591023 != nil:
    section.add "X-Amz-Content-Sha256", valid_591023
  var valid_591024 = header.getOrDefault("X-Amz-Date")
  valid_591024 = validateParameter(valid_591024, JString, required = false,
                                 default = nil)
  if valid_591024 != nil:
    section.add "X-Amz-Date", valid_591024
  var valid_591025 = header.getOrDefault("X-Amz-Credential")
  valid_591025 = validateParameter(valid_591025, JString, required = false,
                                 default = nil)
  if valid_591025 != nil:
    section.add "X-Amz-Credential", valid_591025
  var valid_591026 = header.getOrDefault("X-Amz-Security-Token")
  valid_591026 = validateParameter(valid_591026, JString, required = false,
                                 default = nil)
  if valid_591026 != nil:
    section.add "X-Amz-Security-Token", valid_591026
  var valid_591027 = header.getOrDefault("X-Amz-Algorithm")
  valid_591027 = validateParameter(valid_591027, JString, required = false,
                                 default = nil)
  if valid_591027 != nil:
    section.add "X-Amz-Algorithm", valid_591027
  var valid_591028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591028 = validateParameter(valid_591028, JString, required = false,
                                 default = nil)
  if valid_591028 != nil:
    section.add "X-Amz-SignedHeaders", valid_591028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591030: Call_CreateGovCloudAccount_591018; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This action is available if all of the following are true:</p> <ul> <li> <p>You're authorized to create accounts in the AWS GovCloud (US) Region. For more information on the AWS GovCloud (US) Region, see the <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/welcome.html"> <i>AWS GovCloud User Guide</i>.</a> </p> </li> <li> <p>You already have an account in the AWS GovCloud (US) Region that is associated with your master account in the commercial Region. </p> </li> <li> <p>You call this action from the master account of your organization in the commercial Region.</p> </li> <li> <p>You have the <code>organizations:CreateGovCloudAccount</code> permission. AWS Organizations creates the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html#orgs_integrate_services-using_slrs">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>AWS automatically enables AWS CloudTrail for AWS GovCloud (US) accounts, but you should also do the following:</p> <ul> <li> <p>Verify that AWS CloudTrail is enabled to store logs.</p> </li> <li> <p>Create an S3 bucket for AWS CloudTrail log storage.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/verifying-cloudtrail.html">Verifying AWS CloudTrail Is Enabled</a> in the <i>AWS GovCloud User Guide</i>. </p> </li> </ul> <p>You call this action from the master account of your organization in the commercial Region to create a standalone AWS account in the AWS GovCloud (US) Region. After the account is created, the master account of an organization in the AWS GovCloud (US) Region can invite it to that organization. For more information on inviting standalone accounts in the AWS GovCloud (US) to join an organization, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-organizations.html">AWS Organizations</a> in the <i>AWS GovCloud User Guide.</i> </p> <p>Calling <code>CreateGovCloudAccount</code> is an asynchronous request that AWS performs in the background. Because <code>CreateGovCloudAccount</code> operates asynchronously, it can return a successful completion message even though account initialization might still be in progress. You might need to wait a few minutes before you can successfully access the account. To check the status of the request, do one of the following:</p> <ul> <li> <p>Use the <code>OperationId</code> response element from this operation to provide as a parameter to the <a>DescribeCreateAccountStatus</a> operation.</p> </li> <li> <p>Check the AWS CloudTrail log for the <code>CreateAccountResult</code> event. For information on using AWS CloudTrail with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_monitoring.html">Monitoring the Activity in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p/> <p>When you call the <code>CreateGovCloudAccount</code> action, you create two accounts: a standalone account in the AWS GovCloud (US) Region and an associated account in the commercial Region for billing and support purposes. The account in the commercial Region is automatically a member of the organization whose credentials made the request. Both accounts are associated with the same email address.</p> <p>A role is created in the new account in the commercial Region that allows the master account in the organization in the commercial Region to assume it. An AWS GovCloud (US) account is then created and associated with the commercial account that you just created. A role is created in the new AWS GovCloud (US) account that can be assumed by the AWS GovCloud (US) account that is associated with the master account of the commercial organization. For more information and to view a diagram that explains how account access works, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-organizations.html">AWS Organizations</a> in the <i>AWS GovCloud User Guide.</i> </p> <p>For more information about creating accounts, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_create.html">Creating an AWS Account in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <ul> <li> <p>When you create an account in an organization using the AWS Organizations console, API, or CLI commands, the information required for the account to operate as a standalone account, such as a payment method and signing the end user license agreement (EULA) is <i>not</i> automatically collected. If you must remove an account from your organization later, you can do so only after you provide the missing information. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization as a member account</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>If you get an exception that indicates that you exceeded your account limits for the organization, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>If you get an exception that indicates that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>Using <code>CreateGovCloudAccount</code> to create multiple temporary accounts isn't recommended. You can only close an account from the AWS Billing and Cost Management console, and you must be signed in as the root user. For information on the requirements and process for closing an account, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html">Closing an AWS Account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> </ul> </important> <note> <p>When you create a member account with this operation, you can choose whether to create the account with the <b>IAM User and Role Access to Billing Information</b> switch enabled. If you enable it, IAM users and roles that have appropriate permissions can view billing information for the account. If you disable it, only the account root user can access billing information. For information about how to disable this switch for an account, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html">Granting Access to Your Billing Information and Tools</a>.</p> </note>
  ## 
  let valid = call_591030.validator(path, query, header, formData, body)
  let scheme = call_591030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591030.url(scheme.get, call_591030.host, call_591030.base,
                         call_591030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591030, url, valid)

proc call*(call_591031: Call_CreateGovCloudAccount_591018; body: JsonNode): Recallable =
  ## createGovCloudAccount
  ## <p>This action is available if all of the following are true:</p> <ul> <li> <p>You're authorized to create accounts in the AWS GovCloud (US) Region. For more information on the AWS GovCloud (US) Region, see the <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/welcome.html"> <i>AWS GovCloud User Guide</i>.</a> </p> </li> <li> <p>You already have an account in the AWS GovCloud (US) Region that is associated with your master account in the commercial Region. </p> </li> <li> <p>You call this action from the master account of your organization in the commercial Region.</p> </li> <li> <p>You have the <code>organizations:CreateGovCloudAccount</code> permission. AWS Organizations creates the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html#orgs_integrate_services-using_slrs">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>AWS automatically enables AWS CloudTrail for AWS GovCloud (US) accounts, but you should also do the following:</p> <ul> <li> <p>Verify that AWS CloudTrail is enabled to store logs.</p> </li> <li> <p>Create an S3 bucket for AWS CloudTrail log storage.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/verifying-cloudtrail.html">Verifying AWS CloudTrail Is Enabled</a> in the <i>AWS GovCloud User Guide</i>. </p> </li> </ul> <p>You call this action from the master account of your organization in the commercial Region to create a standalone AWS account in the AWS GovCloud (US) Region. After the account is created, the master account of an organization in the AWS GovCloud (US) Region can invite it to that organization. For more information on inviting standalone accounts in the AWS GovCloud (US) to join an organization, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-organizations.html">AWS Organizations</a> in the <i>AWS GovCloud User Guide.</i> </p> <p>Calling <code>CreateGovCloudAccount</code> is an asynchronous request that AWS performs in the background. Because <code>CreateGovCloudAccount</code> operates asynchronously, it can return a successful completion message even though account initialization might still be in progress. You might need to wait a few minutes before you can successfully access the account. To check the status of the request, do one of the following:</p> <ul> <li> <p>Use the <code>OperationId</code> response element from this operation to provide as a parameter to the <a>DescribeCreateAccountStatus</a> operation.</p> </li> <li> <p>Check the AWS CloudTrail log for the <code>CreateAccountResult</code> event. For information on using AWS CloudTrail with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_monitoring.html">Monitoring the Activity in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p/> <p>When you call the <code>CreateGovCloudAccount</code> action, you create two accounts: a standalone account in the AWS GovCloud (US) Region and an associated account in the commercial Region for billing and support purposes. The account in the commercial Region is automatically a member of the organization whose credentials made the request. Both accounts are associated with the same email address.</p> <p>A role is created in the new account in the commercial Region that allows the master account in the organization in the commercial Region to assume it. An AWS GovCloud (US) account is then created and associated with the commercial account that you just created. A role is created in the new AWS GovCloud (US) account that can be assumed by the AWS GovCloud (US) account that is associated with the master account of the commercial organization. For more information and to view a diagram that explains how account access works, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-organizations.html">AWS Organizations</a> in the <i>AWS GovCloud User Guide.</i> </p> <p>For more information about creating accounts, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_create.html">Creating an AWS Account in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <ul> <li> <p>When you create an account in an organization using the AWS Organizations console, API, or CLI commands, the information required for the account to operate as a standalone account, such as a payment method and signing the end user license agreement (EULA) is <i>not</i> automatically collected. If you must remove an account from your organization later, you can do so only after you provide the missing information. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization as a member account</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>If you get an exception that indicates that you exceeded your account limits for the organization, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>If you get an exception that indicates that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>Using <code>CreateGovCloudAccount</code> to create multiple temporary accounts isn't recommended. You can only close an account from the AWS Billing and Cost Management console, and you must be signed in as the root user. For information on the requirements and process for closing an account, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html">Closing an AWS Account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> </ul> </important> <note> <p>When you create a member account with this operation, you can choose whether to create the account with the <b>IAM User and Role Access to Billing Information</b> switch enabled. If you enable it, IAM users and roles that have appropriate permissions can view billing information for the account. If you disable it, only the account root user can access billing information. For information about how to disable this switch for an account, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html">Granting Access to Your Billing Information and Tools</a>.</p> </note>
  ##   body: JObject (required)
  var body_591032 = newJObject()
  if body != nil:
    body_591032 = body
  result = call_591031.call(nil, nil, nil, nil, body_591032)

var createGovCloudAccount* = Call_CreateGovCloudAccount_591018(
    name: "createGovCloudAccount", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CreateGovCloudAccount",
    validator: validate_CreateGovCloudAccount_591019, base: "/",
    url: url_CreateGovCloudAccount_591020, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateOrganization_591033 = ref object of OpenApiRestCall_590365
proc url_CreateOrganization_591035(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateOrganization_591034(path: JsonNode; query: JsonNode;
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
  var valid_591036 = header.getOrDefault("X-Amz-Target")
  valid_591036 = validateParameter(valid_591036, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CreateOrganization"))
  if valid_591036 != nil:
    section.add "X-Amz-Target", valid_591036
  var valid_591037 = header.getOrDefault("X-Amz-Signature")
  valid_591037 = validateParameter(valid_591037, JString, required = false,
                                 default = nil)
  if valid_591037 != nil:
    section.add "X-Amz-Signature", valid_591037
  var valid_591038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591038 = validateParameter(valid_591038, JString, required = false,
                                 default = nil)
  if valid_591038 != nil:
    section.add "X-Amz-Content-Sha256", valid_591038
  var valid_591039 = header.getOrDefault("X-Amz-Date")
  valid_591039 = validateParameter(valid_591039, JString, required = false,
                                 default = nil)
  if valid_591039 != nil:
    section.add "X-Amz-Date", valid_591039
  var valid_591040 = header.getOrDefault("X-Amz-Credential")
  valid_591040 = validateParameter(valid_591040, JString, required = false,
                                 default = nil)
  if valid_591040 != nil:
    section.add "X-Amz-Credential", valid_591040
  var valid_591041 = header.getOrDefault("X-Amz-Security-Token")
  valid_591041 = validateParameter(valid_591041, JString, required = false,
                                 default = nil)
  if valid_591041 != nil:
    section.add "X-Amz-Security-Token", valid_591041
  var valid_591042 = header.getOrDefault("X-Amz-Algorithm")
  valid_591042 = validateParameter(valid_591042, JString, required = false,
                                 default = nil)
  if valid_591042 != nil:
    section.add "X-Amz-Algorithm", valid_591042
  var valid_591043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591043 = validateParameter(valid_591043, JString, required = false,
                                 default = nil)
  if valid_591043 != nil:
    section.add "X-Amz-SignedHeaders", valid_591043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591045: Call_CreateOrganization_591033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS organization. The account whose user is calling the <code>CreateOrganization</code> operation automatically becomes the <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/orgs_getting-started_concepts.html#account">master account</a> of the new organization.</p> <p>This operation must be called using credentials from the account that is to become the new organization's master account. The principal must also have the relevant IAM permissions.</p> <p>By default (or if you set the <code>FeatureSet</code> parameter to <code>ALL</code>), the new organization is created with all features enabled and service control policies automatically enabled in the root. If you instead choose to create the organization supporting only the consolidated billing features by setting the <code>FeatureSet</code> parameter to <code>CONSOLIDATED_BILLING"</code>, no policy types are enabled by default, and you can't use organization policies.</p>
  ## 
  let valid = call_591045.validator(path, query, header, formData, body)
  let scheme = call_591045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591045.url(scheme.get, call_591045.host, call_591045.base,
                         call_591045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591045, url, valid)

proc call*(call_591046: Call_CreateOrganization_591033; body: JsonNode): Recallable =
  ## createOrganization
  ## <p>Creates an AWS organization. The account whose user is calling the <code>CreateOrganization</code> operation automatically becomes the <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/orgs_getting-started_concepts.html#account">master account</a> of the new organization.</p> <p>This operation must be called using credentials from the account that is to become the new organization's master account. The principal must also have the relevant IAM permissions.</p> <p>By default (or if you set the <code>FeatureSet</code> parameter to <code>ALL</code>), the new organization is created with all features enabled and service control policies automatically enabled in the root. If you instead choose to create the organization supporting only the consolidated billing features by setting the <code>FeatureSet</code> parameter to <code>CONSOLIDATED_BILLING"</code>, no policy types are enabled by default, and you can't use organization policies.</p>
  ##   body: JObject (required)
  var body_591047 = newJObject()
  if body != nil:
    body_591047 = body
  result = call_591046.call(nil, nil, nil, nil, body_591047)

var createOrganization* = Call_CreateOrganization_591033(
    name: "createOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CreateOrganization",
    validator: validate_CreateOrganization_591034, base: "/",
    url: url_CreateOrganization_591035, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateOrganizationalUnit_591048 = ref object of OpenApiRestCall_590365
proc url_CreateOrganizationalUnit_591050(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateOrganizationalUnit_591049(path: JsonNode; query: JsonNode;
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
  var valid_591051 = header.getOrDefault("X-Amz-Target")
  valid_591051 = validateParameter(valid_591051, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CreateOrganizationalUnit"))
  if valid_591051 != nil:
    section.add "X-Amz-Target", valid_591051
  var valid_591052 = header.getOrDefault("X-Amz-Signature")
  valid_591052 = validateParameter(valid_591052, JString, required = false,
                                 default = nil)
  if valid_591052 != nil:
    section.add "X-Amz-Signature", valid_591052
  var valid_591053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591053 = validateParameter(valid_591053, JString, required = false,
                                 default = nil)
  if valid_591053 != nil:
    section.add "X-Amz-Content-Sha256", valid_591053
  var valid_591054 = header.getOrDefault("X-Amz-Date")
  valid_591054 = validateParameter(valid_591054, JString, required = false,
                                 default = nil)
  if valid_591054 != nil:
    section.add "X-Amz-Date", valid_591054
  var valid_591055 = header.getOrDefault("X-Amz-Credential")
  valid_591055 = validateParameter(valid_591055, JString, required = false,
                                 default = nil)
  if valid_591055 != nil:
    section.add "X-Amz-Credential", valid_591055
  var valid_591056 = header.getOrDefault("X-Amz-Security-Token")
  valid_591056 = validateParameter(valid_591056, JString, required = false,
                                 default = nil)
  if valid_591056 != nil:
    section.add "X-Amz-Security-Token", valid_591056
  var valid_591057 = header.getOrDefault("X-Amz-Algorithm")
  valid_591057 = validateParameter(valid_591057, JString, required = false,
                                 default = nil)
  if valid_591057 != nil:
    section.add "X-Amz-Algorithm", valid_591057
  var valid_591058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591058 = validateParameter(valid_591058, JString, required = false,
                                 default = nil)
  if valid_591058 != nil:
    section.add "X-Amz-SignedHeaders", valid_591058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591060: Call_CreateOrganizationalUnit_591048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an organizational unit (OU) within a root or parent OU. An OU is a container for accounts that enables you to organize your accounts to apply policies according to your business requirements. The number of levels deep that you can nest OUs is dependent upon the policy types enabled for that root. For service control policies, the limit is five. </p> <p>For more information about OUs, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_ous.html">Managing Organizational Units</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_591060.validator(path, query, header, formData, body)
  let scheme = call_591060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591060.url(scheme.get, call_591060.host, call_591060.base,
                         call_591060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591060, url, valid)

proc call*(call_591061: Call_CreateOrganizationalUnit_591048; body: JsonNode): Recallable =
  ## createOrganizationalUnit
  ## <p>Creates an organizational unit (OU) within a root or parent OU. An OU is a container for accounts that enables you to organize your accounts to apply policies according to your business requirements. The number of levels deep that you can nest OUs is dependent upon the policy types enabled for that root. For service control policies, the limit is five. </p> <p>For more information about OUs, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_ous.html">Managing Organizational Units</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_591062 = newJObject()
  if body != nil:
    body_591062 = body
  result = call_591061.call(nil, nil, nil, nil, body_591062)

var createOrganizationalUnit* = Call_CreateOrganizationalUnit_591048(
    name: "createOrganizationalUnit", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CreateOrganizationalUnit",
    validator: validate_CreateOrganizationalUnit_591049, base: "/",
    url: url_CreateOrganizationalUnit_591050, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePolicy_591063 = ref object of OpenApiRestCall_590365
proc url_CreatePolicy_591065(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePolicy_591064(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591066 = header.getOrDefault("X-Amz-Target")
  valid_591066 = validateParameter(valid_591066, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CreatePolicy"))
  if valid_591066 != nil:
    section.add "X-Amz-Target", valid_591066
  var valid_591067 = header.getOrDefault("X-Amz-Signature")
  valid_591067 = validateParameter(valid_591067, JString, required = false,
                                 default = nil)
  if valid_591067 != nil:
    section.add "X-Amz-Signature", valid_591067
  var valid_591068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591068 = validateParameter(valid_591068, JString, required = false,
                                 default = nil)
  if valid_591068 != nil:
    section.add "X-Amz-Content-Sha256", valid_591068
  var valid_591069 = header.getOrDefault("X-Amz-Date")
  valid_591069 = validateParameter(valid_591069, JString, required = false,
                                 default = nil)
  if valid_591069 != nil:
    section.add "X-Amz-Date", valid_591069
  var valid_591070 = header.getOrDefault("X-Amz-Credential")
  valid_591070 = validateParameter(valid_591070, JString, required = false,
                                 default = nil)
  if valid_591070 != nil:
    section.add "X-Amz-Credential", valid_591070
  var valid_591071 = header.getOrDefault("X-Amz-Security-Token")
  valid_591071 = validateParameter(valid_591071, JString, required = false,
                                 default = nil)
  if valid_591071 != nil:
    section.add "X-Amz-Security-Token", valid_591071
  var valid_591072 = header.getOrDefault("X-Amz-Algorithm")
  valid_591072 = validateParameter(valid_591072, JString, required = false,
                                 default = nil)
  if valid_591072 != nil:
    section.add "X-Amz-Algorithm", valid_591072
  var valid_591073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591073 = validateParameter(valid_591073, JString, required = false,
                                 default = nil)
  if valid_591073 != nil:
    section.add "X-Amz-SignedHeaders", valid_591073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591075: Call_CreatePolicy_591063; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a policy of a specified type that you can attach to a root, an organizational unit (OU), or an individual AWS account.</p> <p>For more information about policies and their use, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies.html">Managing Organization Policies</a>.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_591075.validator(path, query, header, formData, body)
  let scheme = call_591075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591075.url(scheme.get, call_591075.host, call_591075.base,
                         call_591075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591075, url, valid)

proc call*(call_591076: Call_CreatePolicy_591063; body: JsonNode): Recallable =
  ## createPolicy
  ## <p>Creates a policy of a specified type that you can attach to a root, an organizational unit (OU), or an individual AWS account.</p> <p>For more information about policies and their use, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies.html">Managing Organization Policies</a>.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_591077 = newJObject()
  if body != nil:
    body_591077 = body
  result = call_591076.call(nil, nil, nil, nil, body_591077)

var createPolicy* = Call_CreatePolicy_591063(name: "createPolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CreatePolicy",
    validator: validate_CreatePolicy_591064, base: "/", url: url_CreatePolicy_591065,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeclineHandshake_591078 = ref object of OpenApiRestCall_590365
proc url_DeclineHandshake_591080(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeclineHandshake_591079(path: JsonNode; query: JsonNode;
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
  var valid_591081 = header.getOrDefault("X-Amz-Target")
  valid_591081 = validateParameter(valid_591081, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DeclineHandshake"))
  if valid_591081 != nil:
    section.add "X-Amz-Target", valid_591081
  var valid_591082 = header.getOrDefault("X-Amz-Signature")
  valid_591082 = validateParameter(valid_591082, JString, required = false,
                                 default = nil)
  if valid_591082 != nil:
    section.add "X-Amz-Signature", valid_591082
  var valid_591083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591083 = validateParameter(valid_591083, JString, required = false,
                                 default = nil)
  if valid_591083 != nil:
    section.add "X-Amz-Content-Sha256", valid_591083
  var valid_591084 = header.getOrDefault("X-Amz-Date")
  valid_591084 = validateParameter(valid_591084, JString, required = false,
                                 default = nil)
  if valid_591084 != nil:
    section.add "X-Amz-Date", valid_591084
  var valid_591085 = header.getOrDefault("X-Amz-Credential")
  valid_591085 = validateParameter(valid_591085, JString, required = false,
                                 default = nil)
  if valid_591085 != nil:
    section.add "X-Amz-Credential", valid_591085
  var valid_591086 = header.getOrDefault("X-Amz-Security-Token")
  valid_591086 = validateParameter(valid_591086, JString, required = false,
                                 default = nil)
  if valid_591086 != nil:
    section.add "X-Amz-Security-Token", valid_591086
  var valid_591087 = header.getOrDefault("X-Amz-Algorithm")
  valid_591087 = validateParameter(valid_591087, JString, required = false,
                                 default = nil)
  if valid_591087 != nil:
    section.add "X-Amz-Algorithm", valid_591087
  var valid_591088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591088 = validateParameter(valid_591088, JString, required = false,
                                 default = nil)
  if valid_591088 != nil:
    section.add "X-Amz-SignedHeaders", valid_591088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591090: Call_DeclineHandshake_591078; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Declines a handshake request. This sets the handshake state to <code>DECLINED</code> and effectively deactivates the request.</p> <p>This operation can be called only from the account that received the handshake. The originator of the handshake can use <a>CancelHandshake</a> instead. The originator can't reactivate a declined request, but can reinitiate the process with a new handshake request.</p> <p>After you decline a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
  ## 
  let valid = call_591090.validator(path, query, header, formData, body)
  let scheme = call_591090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591090.url(scheme.get, call_591090.host, call_591090.base,
                         call_591090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591090, url, valid)

proc call*(call_591091: Call_DeclineHandshake_591078; body: JsonNode): Recallable =
  ## declineHandshake
  ## <p>Declines a handshake request. This sets the handshake state to <code>DECLINED</code> and effectively deactivates the request.</p> <p>This operation can be called only from the account that received the handshake. The originator of the handshake can use <a>CancelHandshake</a> instead. The originator can't reactivate a declined request, but can reinitiate the process with a new handshake request.</p> <p>After you decline a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
  ##   body: JObject (required)
  var body_591092 = newJObject()
  if body != nil:
    body_591092 = body
  result = call_591091.call(nil, nil, nil, nil, body_591092)

var declineHandshake* = Call_DeclineHandshake_591078(name: "declineHandshake",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DeclineHandshake",
    validator: validate_DeclineHandshake_591079, base: "/",
    url: url_DeclineHandshake_591080, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteOrganization_591093 = ref object of OpenApiRestCall_590365
proc url_DeleteOrganization_591095(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteOrganization_591094(path: JsonNode; query: JsonNode;
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
  var valid_591096 = header.getOrDefault("X-Amz-Target")
  valid_591096 = validateParameter(valid_591096, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DeleteOrganization"))
  if valid_591096 != nil:
    section.add "X-Amz-Target", valid_591096
  var valid_591097 = header.getOrDefault("X-Amz-Signature")
  valid_591097 = validateParameter(valid_591097, JString, required = false,
                                 default = nil)
  if valid_591097 != nil:
    section.add "X-Amz-Signature", valid_591097
  var valid_591098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591098 = validateParameter(valid_591098, JString, required = false,
                                 default = nil)
  if valid_591098 != nil:
    section.add "X-Amz-Content-Sha256", valid_591098
  var valid_591099 = header.getOrDefault("X-Amz-Date")
  valid_591099 = validateParameter(valid_591099, JString, required = false,
                                 default = nil)
  if valid_591099 != nil:
    section.add "X-Amz-Date", valid_591099
  var valid_591100 = header.getOrDefault("X-Amz-Credential")
  valid_591100 = validateParameter(valid_591100, JString, required = false,
                                 default = nil)
  if valid_591100 != nil:
    section.add "X-Amz-Credential", valid_591100
  var valid_591101 = header.getOrDefault("X-Amz-Security-Token")
  valid_591101 = validateParameter(valid_591101, JString, required = false,
                                 default = nil)
  if valid_591101 != nil:
    section.add "X-Amz-Security-Token", valid_591101
  var valid_591102 = header.getOrDefault("X-Amz-Algorithm")
  valid_591102 = validateParameter(valid_591102, JString, required = false,
                                 default = nil)
  if valid_591102 != nil:
    section.add "X-Amz-Algorithm", valid_591102
  var valid_591103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591103 = validateParameter(valid_591103, JString, required = false,
                                 default = nil)
  if valid_591103 != nil:
    section.add "X-Amz-SignedHeaders", valid_591103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591104: Call_DeleteOrganization_591093; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the organization. You can delete an organization only by using credentials from the master account. The organization must be empty of member accounts.
  ## 
  let valid = call_591104.validator(path, query, header, formData, body)
  let scheme = call_591104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591104.url(scheme.get, call_591104.host, call_591104.base,
                         call_591104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591104, url, valid)

proc call*(call_591105: Call_DeleteOrganization_591093): Recallable =
  ## deleteOrganization
  ## Deletes the organization. You can delete an organization only by using credentials from the master account. The organization must be empty of member accounts.
  result = call_591105.call(nil, nil, nil, nil, nil)

var deleteOrganization* = Call_DeleteOrganization_591093(
    name: "deleteOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DeleteOrganization",
    validator: validate_DeleteOrganization_591094, base: "/",
    url: url_DeleteOrganization_591095, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteOrganizationalUnit_591106 = ref object of OpenApiRestCall_590365
proc url_DeleteOrganizationalUnit_591108(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteOrganizationalUnit_591107(path: JsonNode; query: JsonNode;
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
  var valid_591109 = header.getOrDefault("X-Amz-Target")
  valid_591109 = validateParameter(valid_591109, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DeleteOrganizationalUnit"))
  if valid_591109 != nil:
    section.add "X-Amz-Target", valid_591109
  var valid_591110 = header.getOrDefault("X-Amz-Signature")
  valid_591110 = validateParameter(valid_591110, JString, required = false,
                                 default = nil)
  if valid_591110 != nil:
    section.add "X-Amz-Signature", valid_591110
  var valid_591111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591111 = validateParameter(valid_591111, JString, required = false,
                                 default = nil)
  if valid_591111 != nil:
    section.add "X-Amz-Content-Sha256", valid_591111
  var valid_591112 = header.getOrDefault("X-Amz-Date")
  valid_591112 = validateParameter(valid_591112, JString, required = false,
                                 default = nil)
  if valid_591112 != nil:
    section.add "X-Amz-Date", valid_591112
  var valid_591113 = header.getOrDefault("X-Amz-Credential")
  valid_591113 = validateParameter(valid_591113, JString, required = false,
                                 default = nil)
  if valid_591113 != nil:
    section.add "X-Amz-Credential", valid_591113
  var valid_591114 = header.getOrDefault("X-Amz-Security-Token")
  valid_591114 = validateParameter(valid_591114, JString, required = false,
                                 default = nil)
  if valid_591114 != nil:
    section.add "X-Amz-Security-Token", valid_591114
  var valid_591115 = header.getOrDefault("X-Amz-Algorithm")
  valid_591115 = validateParameter(valid_591115, JString, required = false,
                                 default = nil)
  if valid_591115 != nil:
    section.add "X-Amz-Algorithm", valid_591115
  var valid_591116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591116 = validateParameter(valid_591116, JString, required = false,
                                 default = nil)
  if valid_591116 != nil:
    section.add "X-Amz-SignedHeaders", valid_591116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591118: Call_DeleteOrganizationalUnit_591106; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an organizational unit (OU) from a root or another OU. You must first remove all accounts and child OUs from the OU that you want to delete.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_591118.validator(path, query, header, formData, body)
  let scheme = call_591118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591118.url(scheme.get, call_591118.host, call_591118.base,
                         call_591118.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591118, url, valid)

proc call*(call_591119: Call_DeleteOrganizationalUnit_591106; body: JsonNode): Recallable =
  ## deleteOrganizationalUnit
  ## <p>Deletes an organizational unit (OU) from a root or another OU. You must first remove all accounts and child OUs from the OU that you want to delete.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_591120 = newJObject()
  if body != nil:
    body_591120 = body
  result = call_591119.call(nil, nil, nil, nil, body_591120)

var deleteOrganizationalUnit* = Call_DeleteOrganizationalUnit_591106(
    name: "deleteOrganizationalUnit", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DeleteOrganizationalUnit",
    validator: validate_DeleteOrganizationalUnit_591107, base: "/",
    url: url_DeleteOrganizationalUnit_591108, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePolicy_591121 = ref object of OpenApiRestCall_590365
proc url_DeletePolicy_591123(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeletePolicy_591122(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591124 = header.getOrDefault("X-Amz-Target")
  valid_591124 = validateParameter(valid_591124, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DeletePolicy"))
  if valid_591124 != nil:
    section.add "X-Amz-Target", valid_591124
  var valid_591125 = header.getOrDefault("X-Amz-Signature")
  valid_591125 = validateParameter(valid_591125, JString, required = false,
                                 default = nil)
  if valid_591125 != nil:
    section.add "X-Amz-Signature", valid_591125
  var valid_591126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591126 = validateParameter(valid_591126, JString, required = false,
                                 default = nil)
  if valid_591126 != nil:
    section.add "X-Amz-Content-Sha256", valid_591126
  var valid_591127 = header.getOrDefault("X-Amz-Date")
  valid_591127 = validateParameter(valid_591127, JString, required = false,
                                 default = nil)
  if valid_591127 != nil:
    section.add "X-Amz-Date", valid_591127
  var valid_591128 = header.getOrDefault("X-Amz-Credential")
  valid_591128 = validateParameter(valid_591128, JString, required = false,
                                 default = nil)
  if valid_591128 != nil:
    section.add "X-Amz-Credential", valid_591128
  var valid_591129 = header.getOrDefault("X-Amz-Security-Token")
  valid_591129 = validateParameter(valid_591129, JString, required = false,
                                 default = nil)
  if valid_591129 != nil:
    section.add "X-Amz-Security-Token", valid_591129
  var valid_591130 = header.getOrDefault("X-Amz-Algorithm")
  valid_591130 = validateParameter(valid_591130, JString, required = false,
                                 default = nil)
  if valid_591130 != nil:
    section.add "X-Amz-Algorithm", valid_591130
  var valid_591131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591131 = validateParameter(valid_591131, JString, required = false,
                                 default = nil)
  if valid_591131 != nil:
    section.add "X-Amz-SignedHeaders", valid_591131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591133: Call_DeletePolicy_591121; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified policy from your organization. Before you perform this operation, you must first detach the policy from all organizational units (OUs), roots, and accounts.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_591133.validator(path, query, header, formData, body)
  let scheme = call_591133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591133.url(scheme.get, call_591133.host, call_591133.base,
                         call_591133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591133, url, valid)

proc call*(call_591134: Call_DeletePolicy_591121; body: JsonNode): Recallable =
  ## deletePolicy
  ## <p>Deletes the specified policy from your organization. Before you perform this operation, you must first detach the policy from all organizational units (OUs), roots, and accounts.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_591135 = newJObject()
  if body != nil:
    body_591135 = body
  result = call_591134.call(nil, nil, nil, nil, body_591135)

var deletePolicy* = Call_DeletePolicy_591121(name: "deletePolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DeletePolicy",
    validator: validate_DeletePolicy_591122, base: "/", url: url_DeletePolicy_591123,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccount_591136 = ref object of OpenApiRestCall_590365
proc url_DescribeAccount_591138(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAccount_591137(path: JsonNode; query: JsonNode;
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
  var valid_591139 = header.getOrDefault("X-Amz-Target")
  valid_591139 = validateParameter(valid_591139, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribeAccount"))
  if valid_591139 != nil:
    section.add "X-Amz-Target", valid_591139
  var valid_591140 = header.getOrDefault("X-Amz-Signature")
  valid_591140 = validateParameter(valid_591140, JString, required = false,
                                 default = nil)
  if valid_591140 != nil:
    section.add "X-Amz-Signature", valid_591140
  var valid_591141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591141 = validateParameter(valid_591141, JString, required = false,
                                 default = nil)
  if valid_591141 != nil:
    section.add "X-Amz-Content-Sha256", valid_591141
  var valid_591142 = header.getOrDefault("X-Amz-Date")
  valid_591142 = validateParameter(valid_591142, JString, required = false,
                                 default = nil)
  if valid_591142 != nil:
    section.add "X-Amz-Date", valid_591142
  var valid_591143 = header.getOrDefault("X-Amz-Credential")
  valid_591143 = validateParameter(valid_591143, JString, required = false,
                                 default = nil)
  if valid_591143 != nil:
    section.add "X-Amz-Credential", valid_591143
  var valid_591144 = header.getOrDefault("X-Amz-Security-Token")
  valid_591144 = validateParameter(valid_591144, JString, required = false,
                                 default = nil)
  if valid_591144 != nil:
    section.add "X-Amz-Security-Token", valid_591144
  var valid_591145 = header.getOrDefault("X-Amz-Algorithm")
  valid_591145 = validateParameter(valid_591145, JString, required = false,
                                 default = nil)
  if valid_591145 != nil:
    section.add "X-Amz-Algorithm", valid_591145
  var valid_591146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591146 = validateParameter(valid_591146, JString, required = false,
                                 default = nil)
  if valid_591146 != nil:
    section.add "X-Amz-SignedHeaders", valid_591146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591148: Call_DescribeAccount_591136; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves AWS Organizations-related information about the specified account.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_591148.validator(path, query, header, formData, body)
  let scheme = call_591148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591148.url(scheme.get, call_591148.host, call_591148.base,
                         call_591148.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591148, url, valid)

proc call*(call_591149: Call_DescribeAccount_591136; body: JsonNode): Recallable =
  ## describeAccount
  ## <p>Retrieves AWS Organizations-related information about the specified account.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_591150 = newJObject()
  if body != nil:
    body_591150 = body
  result = call_591149.call(nil, nil, nil, nil, body_591150)

var describeAccount* = Call_DescribeAccount_591136(name: "describeAccount",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribeAccount",
    validator: validate_DescribeAccount_591137, base: "/", url: url_DescribeAccount_591138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCreateAccountStatus_591151 = ref object of OpenApiRestCall_590365
proc url_DescribeCreateAccountStatus_591153(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeCreateAccountStatus_591152(path: JsonNode; query: JsonNode;
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
  var valid_591154 = header.getOrDefault("X-Amz-Target")
  valid_591154 = validateParameter(valid_591154, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribeCreateAccountStatus"))
  if valid_591154 != nil:
    section.add "X-Amz-Target", valid_591154
  var valid_591155 = header.getOrDefault("X-Amz-Signature")
  valid_591155 = validateParameter(valid_591155, JString, required = false,
                                 default = nil)
  if valid_591155 != nil:
    section.add "X-Amz-Signature", valid_591155
  var valid_591156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591156 = validateParameter(valid_591156, JString, required = false,
                                 default = nil)
  if valid_591156 != nil:
    section.add "X-Amz-Content-Sha256", valid_591156
  var valid_591157 = header.getOrDefault("X-Amz-Date")
  valid_591157 = validateParameter(valid_591157, JString, required = false,
                                 default = nil)
  if valid_591157 != nil:
    section.add "X-Amz-Date", valid_591157
  var valid_591158 = header.getOrDefault("X-Amz-Credential")
  valid_591158 = validateParameter(valid_591158, JString, required = false,
                                 default = nil)
  if valid_591158 != nil:
    section.add "X-Amz-Credential", valid_591158
  var valid_591159 = header.getOrDefault("X-Amz-Security-Token")
  valid_591159 = validateParameter(valid_591159, JString, required = false,
                                 default = nil)
  if valid_591159 != nil:
    section.add "X-Amz-Security-Token", valid_591159
  var valid_591160 = header.getOrDefault("X-Amz-Algorithm")
  valid_591160 = validateParameter(valid_591160, JString, required = false,
                                 default = nil)
  if valid_591160 != nil:
    section.add "X-Amz-Algorithm", valid_591160
  var valid_591161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591161 = validateParameter(valid_591161, JString, required = false,
                                 default = nil)
  if valid_591161 != nil:
    section.add "X-Amz-SignedHeaders", valid_591161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591163: Call_DescribeCreateAccountStatus_591151; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the current status of an asynchronous request to create an account.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_591163.validator(path, query, header, formData, body)
  let scheme = call_591163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591163.url(scheme.get, call_591163.host, call_591163.base,
                         call_591163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591163, url, valid)

proc call*(call_591164: Call_DescribeCreateAccountStatus_591151; body: JsonNode): Recallable =
  ## describeCreateAccountStatus
  ## <p>Retrieves the current status of an asynchronous request to create an account.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_591165 = newJObject()
  if body != nil:
    body_591165 = body
  result = call_591164.call(nil, nil, nil, nil, body_591165)

var describeCreateAccountStatus* = Call_DescribeCreateAccountStatus_591151(
    name: "describeCreateAccountStatus", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribeCreateAccountStatus",
    validator: validate_DescribeCreateAccountStatus_591152, base: "/",
    url: url_DescribeCreateAccountStatus_591153,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHandshake_591166 = ref object of OpenApiRestCall_590365
proc url_DescribeHandshake_591168(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeHandshake_591167(path: JsonNode; query: JsonNode;
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
  var valid_591169 = header.getOrDefault("X-Amz-Target")
  valid_591169 = validateParameter(valid_591169, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribeHandshake"))
  if valid_591169 != nil:
    section.add "X-Amz-Target", valid_591169
  var valid_591170 = header.getOrDefault("X-Amz-Signature")
  valid_591170 = validateParameter(valid_591170, JString, required = false,
                                 default = nil)
  if valid_591170 != nil:
    section.add "X-Amz-Signature", valid_591170
  var valid_591171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591171 = validateParameter(valid_591171, JString, required = false,
                                 default = nil)
  if valid_591171 != nil:
    section.add "X-Amz-Content-Sha256", valid_591171
  var valid_591172 = header.getOrDefault("X-Amz-Date")
  valid_591172 = validateParameter(valid_591172, JString, required = false,
                                 default = nil)
  if valid_591172 != nil:
    section.add "X-Amz-Date", valid_591172
  var valid_591173 = header.getOrDefault("X-Amz-Credential")
  valid_591173 = validateParameter(valid_591173, JString, required = false,
                                 default = nil)
  if valid_591173 != nil:
    section.add "X-Amz-Credential", valid_591173
  var valid_591174 = header.getOrDefault("X-Amz-Security-Token")
  valid_591174 = validateParameter(valid_591174, JString, required = false,
                                 default = nil)
  if valid_591174 != nil:
    section.add "X-Amz-Security-Token", valid_591174
  var valid_591175 = header.getOrDefault("X-Amz-Algorithm")
  valid_591175 = validateParameter(valid_591175, JString, required = false,
                                 default = nil)
  if valid_591175 != nil:
    section.add "X-Amz-Algorithm", valid_591175
  var valid_591176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591176 = validateParameter(valid_591176, JString, required = false,
                                 default = nil)
  if valid_591176 != nil:
    section.add "X-Amz-SignedHeaders", valid_591176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591178: Call_DescribeHandshake_591166; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about a previously requested handshake. The handshake ID comes from the response to the original <a>InviteAccountToOrganization</a> operation that generated the handshake.</p> <p>You can access handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> for only 30 days after they change to that state. They're then deleted and no longer accessible.</p> <p>This operation can be called from any account in the organization.</p>
  ## 
  let valid = call_591178.validator(path, query, header, formData, body)
  let scheme = call_591178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591178.url(scheme.get, call_591178.host, call_591178.base,
                         call_591178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591178, url, valid)

proc call*(call_591179: Call_DescribeHandshake_591166; body: JsonNode): Recallable =
  ## describeHandshake
  ## <p>Retrieves information about a previously requested handshake. The handshake ID comes from the response to the original <a>InviteAccountToOrganization</a> operation that generated the handshake.</p> <p>You can access handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> for only 30 days after they change to that state. They're then deleted and no longer accessible.</p> <p>This operation can be called from any account in the organization.</p>
  ##   body: JObject (required)
  var body_591180 = newJObject()
  if body != nil:
    body_591180 = body
  result = call_591179.call(nil, nil, nil, nil, body_591180)

var describeHandshake* = Call_DescribeHandshake_591166(name: "describeHandshake",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribeHandshake",
    validator: validate_DescribeHandshake_591167, base: "/",
    url: url_DescribeHandshake_591168, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOrganization_591181 = ref object of OpenApiRestCall_590365
proc url_DescribeOrganization_591183(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeOrganization_591182(path: JsonNode; query: JsonNode;
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
  var valid_591184 = header.getOrDefault("X-Amz-Target")
  valid_591184 = validateParameter(valid_591184, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribeOrganization"))
  if valid_591184 != nil:
    section.add "X-Amz-Target", valid_591184
  var valid_591185 = header.getOrDefault("X-Amz-Signature")
  valid_591185 = validateParameter(valid_591185, JString, required = false,
                                 default = nil)
  if valid_591185 != nil:
    section.add "X-Amz-Signature", valid_591185
  var valid_591186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591186 = validateParameter(valid_591186, JString, required = false,
                                 default = nil)
  if valid_591186 != nil:
    section.add "X-Amz-Content-Sha256", valid_591186
  var valid_591187 = header.getOrDefault("X-Amz-Date")
  valid_591187 = validateParameter(valid_591187, JString, required = false,
                                 default = nil)
  if valid_591187 != nil:
    section.add "X-Amz-Date", valid_591187
  var valid_591188 = header.getOrDefault("X-Amz-Credential")
  valid_591188 = validateParameter(valid_591188, JString, required = false,
                                 default = nil)
  if valid_591188 != nil:
    section.add "X-Amz-Credential", valid_591188
  var valid_591189 = header.getOrDefault("X-Amz-Security-Token")
  valid_591189 = validateParameter(valid_591189, JString, required = false,
                                 default = nil)
  if valid_591189 != nil:
    section.add "X-Amz-Security-Token", valid_591189
  var valid_591190 = header.getOrDefault("X-Amz-Algorithm")
  valid_591190 = validateParameter(valid_591190, JString, required = false,
                                 default = nil)
  if valid_591190 != nil:
    section.add "X-Amz-Algorithm", valid_591190
  var valid_591191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591191 = validateParameter(valid_591191, JString, required = false,
                                 default = nil)
  if valid_591191 != nil:
    section.add "X-Amz-SignedHeaders", valid_591191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591192: Call_DescribeOrganization_591181; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about the organization that the user's account belongs to.</p> <p>This operation can be called from any account in the organization.</p> <note> <p>Even if a policy type is shown as available in the organization, you can disable it separately at the root level with <a>DisablePolicyType</a>. Use <a>ListRoots</a> to see the status of policy types for a specified root.</p> </note>
  ## 
  let valid = call_591192.validator(path, query, header, formData, body)
  let scheme = call_591192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591192.url(scheme.get, call_591192.host, call_591192.base,
                         call_591192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591192, url, valid)

proc call*(call_591193: Call_DescribeOrganization_591181): Recallable =
  ## describeOrganization
  ## <p>Retrieves information about the organization that the user's account belongs to.</p> <p>This operation can be called from any account in the organization.</p> <note> <p>Even if a policy type is shown as available in the organization, you can disable it separately at the root level with <a>DisablePolicyType</a>. Use <a>ListRoots</a> to see the status of policy types for a specified root.</p> </note>
  result = call_591193.call(nil, nil, nil, nil, nil)

var describeOrganization* = Call_DescribeOrganization_591181(
    name: "describeOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribeOrganization",
    validator: validate_DescribeOrganization_591182, base: "/",
    url: url_DescribeOrganization_591183, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOrganizationalUnit_591194 = ref object of OpenApiRestCall_590365
proc url_DescribeOrganizationalUnit_591196(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeOrganizationalUnit_591195(path: JsonNode; query: JsonNode;
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
  var valid_591197 = header.getOrDefault("X-Amz-Target")
  valid_591197 = validateParameter(valid_591197, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribeOrganizationalUnit"))
  if valid_591197 != nil:
    section.add "X-Amz-Target", valid_591197
  var valid_591198 = header.getOrDefault("X-Amz-Signature")
  valid_591198 = validateParameter(valid_591198, JString, required = false,
                                 default = nil)
  if valid_591198 != nil:
    section.add "X-Amz-Signature", valid_591198
  var valid_591199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591199 = validateParameter(valid_591199, JString, required = false,
                                 default = nil)
  if valid_591199 != nil:
    section.add "X-Amz-Content-Sha256", valid_591199
  var valid_591200 = header.getOrDefault("X-Amz-Date")
  valid_591200 = validateParameter(valid_591200, JString, required = false,
                                 default = nil)
  if valid_591200 != nil:
    section.add "X-Amz-Date", valid_591200
  var valid_591201 = header.getOrDefault("X-Amz-Credential")
  valid_591201 = validateParameter(valid_591201, JString, required = false,
                                 default = nil)
  if valid_591201 != nil:
    section.add "X-Amz-Credential", valid_591201
  var valid_591202 = header.getOrDefault("X-Amz-Security-Token")
  valid_591202 = validateParameter(valid_591202, JString, required = false,
                                 default = nil)
  if valid_591202 != nil:
    section.add "X-Amz-Security-Token", valid_591202
  var valid_591203 = header.getOrDefault("X-Amz-Algorithm")
  valid_591203 = validateParameter(valid_591203, JString, required = false,
                                 default = nil)
  if valid_591203 != nil:
    section.add "X-Amz-Algorithm", valid_591203
  var valid_591204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591204 = validateParameter(valid_591204, JString, required = false,
                                 default = nil)
  if valid_591204 != nil:
    section.add "X-Amz-SignedHeaders", valid_591204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591206: Call_DescribeOrganizationalUnit_591194; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about an organizational unit (OU).</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_591206.validator(path, query, header, formData, body)
  let scheme = call_591206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591206.url(scheme.get, call_591206.host, call_591206.base,
                         call_591206.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591206, url, valid)

proc call*(call_591207: Call_DescribeOrganizationalUnit_591194; body: JsonNode): Recallable =
  ## describeOrganizationalUnit
  ## <p>Retrieves information about an organizational unit (OU).</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_591208 = newJObject()
  if body != nil:
    body_591208 = body
  result = call_591207.call(nil, nil, nil, nil, body_591208)

var describeOrganizationalUnit* = Call_DescribeOrganizationalUnit_591194(
    name: "describeOrganizationalUnit", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribeOrganizationalUnit",
    validator: validate_DescribeOrganizationalUnit_591195, base: "/",
    url: url_DescribeOrganizationalUnit_591196,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePolicy_591209 = ref object of OpenApiRestCall_590365
proc url_DescribePolicy_591211(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribePolicy_591210(path: JsonNode; query: JsonNode;
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
  var valid_591212 = header.getOrDefault("X-Amz-Target")
  valid_591212 = validateParameter(valid_591212, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribePolicy"))
  if valid_591212 != nil:
    section.add "X-Amz-Target", valid_591212
  var valid_591213 = header.getOrDefault("X-Amz-Signature")
  valid_591213 = validateParameter(valid_591213, JString, required = false,
                                 default = nil)
  if valid_591213 != nil:
    section.add "X-Amz-Signature", valid_591213
  var valid_591214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591214 = validateParameter(valid_591214, JString, required = false,
                                 default = nil)
  if valid_591214 != nil:
    section.add "X-Amz-Content-Sha256", valid_591214
  var valid_591215 = header.getOrDefault("X-Amz-Date")
  valid_591215 = validateParameter(valid_591215, JString, required = false,
                                 default = nil)
  if valid_591215 != nil:
    section.add "X-Amz-Date", valid_591215
  var valid_591216 = header.getOrDefault("X-Amz-Credential")
  valid_591216 = validateParameter(valid_591216, JString, required = false,
                                 default = nil)
  if valid_591216 != nil:
    section.add "X-Amz-Credential", valid_591216
  var valid_591217 = header.getOrDefault("X-Amz-Security-Token")
  valid_591217 = validateParameter(valid_591217, JString, required = false,
                                 default = nil)
  if valid_591217 != nil:
    section.add "X-Amz-Security-Token", valid_591217
  var valid_591218 = header.getOrDefault("X-Amz-Algorithm")
  valid_591218 = validateParameter(valid_591218, JString, required = false,
                                 default = nil)
  if valid_591218 != nil:
    section.add "X-Amz-Algorithm", valid_591218
  var valid_591219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591219 = validateParameter(valid_591219, JString, required = false,
                                 default = nil)
  if valid_591219 != nil:
    section.add "X-Amz-SignedHeaders", valid_591219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591221: Call_DescribePolicy_591209; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about a policy.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_591221.validator(path, query, header, formData, body)
  let scheme = call_591221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591221.url(scheme.get, call_591221.host, call_591221.base,
                         call_591221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591221, url, valid)

proc call*(call_591222: Call_DescribePolicy_591209; body: JsonNode): Recallable =
  ## describePolicy
  ## <p>Retrieves information about a policy.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_591223 = newJObject()
  if body != nil:
    body_591223 = body
  result = call_591222.call(nil, nil, nil, nil, body_591223)

var describePolicy* = Call_DescribePolicy_591209(name: "describePolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribePolicy",
    validator: validate_DescribePolicy_591210, base: "/", url: url_DescribePolicy_591211,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachPolicy_591224 = ref object of OpenApiRestCall_590365
proc url_DetachPolicy_591226(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DetachPolicy_591225(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591227 = header.getOrDefault("X-Amz-Target")
  valid_591227 = validateParameter(valid_591227, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DetachPolicy"))
  if valid_591227 != nil:
    section.add "X-Amz-Target", valid_591227
  var valid_591228 = header.getOrDefault("X-Amz-Signature")
  valid_591228 = validateParameter(valid_591228, JString, required = false,
                                 default = nil)
  if valid_591228 != nil:
    section.add "X-Amz-Signature", valid_591228
  var valid_591229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591229 = validateParameter(valid_591229, JString, required = false,
                                 default = nil)
  if valid_591229 != nil:
    section.add "X-Amz-Content-Sha256", valid_591229
  var valid_591230 = header.getOrDefault("X-Amz-Date")
  valid_591230 = validateParameter(valid_591230, JString, required = false,
                                 default = nil)
  if valid_591230 != nil:
    section.add "X-Amz-Date", valid_591230
  var valid_591231 = header.getOrDefault("X-Amz-Credential")
  valid_591231 = validateParameter(valid_591231, JString, required = false,
                                 default = nil)
  if valid_591231 != nil:
    section.add "X-Amz-Credential", valid_591231
  var valid_591232 = header.getOrDefault("X-Amz-Security-Token")
  valid_591232 = validateParameter(valid_591232, JString, required = false,
                                 default = nil)
  if valid_591232 != nil:
    section.add "X-Amz-Security-Token", valid_591232
  var valid_591233 = header.getOrDefault("X-Amz-Algorithm")
  valid_591233 = validateParameter(valid_591233, JString, required = false,
                                 default = nil)
  if valid_591233 != nil:
    section.add "X-Amz-Algorithm", valid_591233
  var valid_591234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591234 = validateParameter(valid_591234, JString, required = false,
                                 default = nil)
  if valid_591234 != nil:
    section.add "X-Amz-SignedHeaders", valid_591234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591236: Call_DetachPolicy_591224; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detaches a policy from a target root, organizational unit (OU), or account. If the policy being detached is a service control policy (SCP), the changes to permissions for IAM users and roles in affected accounts are immediate.</p> <p> <b>Note:</b> Every root, OU, and account must have at least one SCP attached. If you want to replace the default <code>FullAWSAccess</code> policy with one that limits the permissions that can be delegated, you must attach the replacement policy before you can remove the default one. This is the authorization strategy of <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html#orgs_policies_whitelist">whitelisting</a>. If you instead attach a second SCP and leave the <code>FullAWSAccess</code> SCP still attached, and specify <code>"Effect": "Deny"</code> in the second SCP to override the <code>"Effect": "Allow"</code> in the <code>FullAWSAccess</code> policy (or any other attached SCP), you're using the authorization strategy of <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html#orgs_policies_blacklist">blacklisting</a> . </p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_591236.validator(path, query, header, formData, body)
  let scheme = call_591236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591236.url(scheme.get, call_591236.host, call_591236.base,
                         call_591236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591236, url, valid)

proc call*(call_591237: Call_DetachPolicy_591224; body: JsonNode): Recallable =
  ## detachPolicy
  ## <p>Detaches a policy from a target root, organizational unit (OU), or account. If the policy being detached is a service control policy (SCP), the changes to permissions for IAM users and roles in affected accounts are immediate.</p> <p> <b>Note:</b> Every root, OU, and account must have at least one SCP attached. If you want to replace the default <code>FullAWSAccess</code> policy with one that limits the permissions that can be delegated, you must attach the replacement policy before you can remove the default one. This is the authorization strategy of <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html#orgs_policies_whitelist">whitelisting</a>. If you instead attach a second SCP and leave the <code>FullAWSAccess</code> SCP still attached, and specify <code>"Effect": "Deny"</code> in the second SCP to override the <code>"Effect": "Allow"</code> in the <code>FullAWSAccess</code> policy (or any other attached SCP), you're using the authorization strategy of <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html#orgs_policies_blacklist">blacklisting</a> . </p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_591238 = newJObject()
  if body != nil:
    body_591238 = body
  result = call_591237.call(nil, nil, nil, nil, body_591238)

var detachPolicy* = Call_DetachPolicy_591224(name: "detachPolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DetachPolicy",
    validator: validate_DetachPolicy_591225, base: "/", url: url_DetachPolicy_591226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableAWSServiceAccess_591239 = ref object of OpenApiRestCall_590365
proc url_DisableAWSServiceAccess_591241(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisableAWSServiceAccess_591240(path: JsonNode; query: JsonNode;
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
  var valid_591242 = header.getOrDefault("X-Amz-Target")
  valid_591242 = validateParameter(valid_591242, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DisableAWSServiceAccess"))
  if valid_591242 != nil:
    section.add "X-Amz-Target", valid_591242
  var valid_591243 = header.getOrDefault("X-Amz-Signature")
  valid_591243 = validateParameter(valid_591243, JString, required = false,
                                 default = nil)
  if valid_591243 != nil:
    section.add "X-Amz-Signature", valid_591243
  var valid_591244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591244 = validateParameter(valid_591244, JString, required = false,
                                 default = nil)
  if valid_591244 != nil:
    section.add "X-Amz-Content-Sha256", valid_591244
  var valid_591245 = header.getOrDefault("X-Amz-Date")
  valid_591245 = validateParameter(valid_591245, JString, required = false,
                                 default = nil)
  if valid_591245 != nil:
    section.add "X-Amz-Date", valid_591245
  var valid_591246 = header.getOrDefault("X-Amz-Credential")
  valid_591246 = validateParameter(valid_591246, JString, required = false,
                                 default = nil)
  if valid_591246 != nil:
    section.add "X-Amz-Credential", valid_591246
  var valid_591247 = header.getOrDefault("X-Amz-Security-Token")
  valid_591247 = validateParameter(valid_591247, JString, required = false,
                                 default = nil)
  if valid_591247 != nil:
    section.add "X-Amz-Security-Token", valid_591247
  var valid_591248 = header.getOrDefault("X-Amz-Algorithm")
  valid_591248 = validateParameter(valid_591248, JString, required = false,
                                 default = nil)
  if valid_591248 != nil:
    section.add "X-Amz-Algorithm", valid_591248
  var valid_591249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591249 = validateParameter(valid_591249, JString, required = false,
                                 default = nil)
  if valid_591249 != nil:
    section.add "X-Amz-SignedHeaders", valid_591249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591251: Call_DisableAWSServiceAccess_591239; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables the integration of an AWS service (the service that is specified by <code>ServicePrincipal</code>) with AWS Organizations. When you disable integration, the specified service no longer can create a <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html">service-linked role</a> in <i>new</i> accounts in your organization. This means the service can't perform operations on your behalf on any new accounts in your organization. The service can still perform operations in older accounts until the service completes its clean-up from AWS Organizations.</p> <p/> <important> <p>We recommend that you disable integration between AWS Organizations and the specified AWS service by using the console or commands that are provided by the specified service. Doing so ensures that the other service is aware that it can clean up any resources that are required only for the integration. How the service cleans up its resources in the organization's accounts depends on that service. For more information, see the documentation for the other AWS service.</p> </important> <p>After you perform the <code>DisableAWSServiceAccess</code> operation, the specified service can no longer perform operations in your organization's accounts unless the operations are explicitly permitted by the IAM policies that are attached to your roles. </p> <p>For more information about integrating other services with AWS Organizations, including the list of services that work with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_591251.validator(path, query, header, formData, body)
  let scheme = call_591251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591251.url(scheme.get, call_591251.host, call_591251.base,
                         call_591251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591251, url, valid)

proc call*(call_591252: Call_DisableAWSServiceAccess_591239; body: JsonNode): Recallable =
  ## disableAWSServiceAccess
  ## <p>Disables the integration of an AWS service (the service that is specified by <code>ServicePrincipal</code>) with AWS Organizations. When you disable integration, the specified service no longer can create a <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html">service-linked role</a> in <i>new</i> accounts in your organization. This means the service can't perform operations on your behalf on any new accounts in your organization. The service can still perform operations in older accounts until the service completes its clean-up from AWS Organizations.</p> <p/> <important> <p>We recommend that you disable integration between AWS Organizations and the specified AWS service by using the console or commands that are provided by the specified service. Doing so ensures that the other service is aware that it can clean up any resources that are required only for the integration. How the service cleans up its resources in the organization's accounts depends on that service. For more information, see the documentation for the other AWS service.</p> </important> <p>After you perform the <code>DisableAWSServiceAccess</code> operation, the specified service can no longer perform operations in your organization's accounts unless the operations are explicitly permitted by the IAM policies that are attached to your roles. </p> <p>For more information about integrating other services with AWS Organizations, including the list of services that work with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_591253 = newJObject()
  if body != nil:
    body_591253 = body
  result = call_591252.call(nil, nil, nil, nil, body_591253)

var disableAWSServiceAccess* = Call_DisableAWSServiceAccess_591239(
    name: "disableAWSServiceAccess", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DisableAWSServiceAccess",
    validator: validate_DisableAWSServiceAccess_591240, base: "/",
    url: url_DisableAWSServiceAccess_591241, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisablePolicyType_591254 = ref object of OpenApiRestCall_590365
proc url_DisablePolicyType_591256(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisablePolicyType_591255(path: JsonNode; query: JsonNode;
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
  var valid_591257 = header.getOrDefault("X-Amz-Target")
  valid_591257 = validateParameter(valid_591257, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DisablePolicyType"))
  if valid_591257 != nil:
    section.add "X-Amz-Target", valid_591257
  var valid_591258 = header.getOrDefault("X-Amz-Signature")
  valid_591258 = validateParameter(valid_591258, JString, required = false,
                                 default = nil)
  if valid_591258 != nil:
    section.add "X-Amz-Signature", valid_591258
  var valid_591259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591259 = validateParameter(valid_591259, JString, required = false,
                                 default = nil)
  if valid_591259 != nil:
    section.add "X-Amz-Content-Sha256", valid_591259
  var valid_591260 = header.getOrDefault("X-Amz-Date")
  valid_591260 = validateParameter(valid_591260, JString, required = false,
                                 default = nil)
  if valid_591260 != nil:
    section.add "X-Amz-Date", valid_591260
  var valid_591261 = header.getOrDefault("X-Amz-Credential")
  valid_591261 = validateParameter(valid_591261, JString, required = false,
                                 default = nil)
  if valid_591261 != nil:
    section.add "X-Amz-Credential", valid_591261
  var valid_591262 = header.getOrDefault("X-Amz-Security-Token")
  valid_591262 = validateParameter(valid_591262, JString, required = false,
                                 default = nil)
  if valid_591262 != nil:
    section.add "X-Amz-Security-Token", valid_591262
  var valid_591263 = header.getOrDefault("X-Amz-Algorithm")
  valid_591263 = validateParameter(valid_591263, JString, required = false,
                                 default = nil)
  if valid_591263 != nil:
    section.add "X-Amz-Algorithm", valid_591263
  var valid_591264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591264 = validateParameter(valid_591264, JString, required = false,
                                 default = nil)
  if valid_591264 != nil:
    section.add "X-Amz-SignedHeaders", valid_591264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591266: Call_DisablePolicyType_591254; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables an organizational control policy type in a root. A policy of a certain type can be attached to entities in a root only if that type is enabled in the root. After you perform this operation, you no longer can attach policies of the specified type to that root or to any organizational unit (OU) or account in that root. You can undo this by using the <a>EnablePolicyType</a> operation.</p> <p>This is an asynchronous request that AWS performs in the background. If you disable a policy for a root, it still appears enabled for the organization if <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">all features</a> are enabled for the organization. AWS recommends that you first use <a>ListRoots</a> to see the status of policy types for a specified root, and then use this operation. </p> <p>This operation can be called only from the organization's master account.</p> <p> To view the status of available policy types in the organization, use <a>DescribeOrganization</a>.</p>
  ## 
  let valid = call_591266.validator(path, query, header, formData, body)
  let scheme = call_591266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591266.url(scheme.get, call_591266.host, call_591266.base,
                         call_591266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591266, url, valid)

proc call*(call_591267: Call_DisablePolicyType_591254; body: JsonNode): Recallable =
  ## disablePolicyType
  ## <p>Disables an organizational control policy type in a root. A policy of a certain type can be attached to entities in a root only if that type is enabled in the root. After you perform this operation, you no longer can attach policies of the specified type to that root or to any organizational unit (OU) or account in that root. You can undo this by using the <a>EnablePolicyType</a> operation.</p> <p>This is an asynchronous request that AWS performs in the background. If you disable a policy for a root, it still appears enabled for the organization if <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">all features</a> are enabled for the organization. AWS recommends that you first use <a>ListRoots</a> to see the status of policy types for a specified root, and then use this operation. </p> <p>This operation can be called only from the organization's master account.</p> <p> To view the status of available policy types in the organization, use <a>DescribeOrganization</a>.</p>
  ##   body: JObject (required)
  var body_591268 = newJObject()
  if body != nil:
    body_591268 = body
  result = call_591267.call(nil, nil, nil, nil, body_591268)

var disablePolicyType* = Call_DisablePolicyType_591254(name: "disablePolicyType",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DisablePolicyType",
    validator: validate_DisablePolicyType_591255, base: "/",
    url: url_DisablePolicyType_591256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableAWSServiceAccess_591269 = ref object of OpenApiRestCall_590365
proc url_EnableAWSServiceAccess_591271(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_EnableAWSServiceAccess_591270(path: JsonNode; query: JsonNode;
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
  var valid_591272 = header.getOrDefault("X-Amz-Target")
  valid_591272 = validateParameter(valid_591272, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.EnableAWSServiceAccess"))
  if valid_591272 != nil:
    section.add "X-Amz-Target", valid_591272
  var valid_591273 = header.getOrDefault("X-Amz-Signature")
  valid_591273 = validateParameter(valid_591273, JString, required = false,
                                 default = nil)
  if valid_591273 != nil:
    section.add "X-Amz-Signature", valid_591273
  var valid_591274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591274 = validateParameter(valid_591274, JString, required = false,
                                 default = nil)
  if valid_591274 != nil:
    section.add "X-Amz-Content-Sha256", valid_591274
  var valid_591275 = header.getOrDefault("X-Amz-Date")
  valid_591275 = validateParameter(valid_591275, JString, required = false,
                                 default = nil)
  if valid_591275 != nil:
    section.add "X-Amz-Date", valid_591275
  var valid_591276 = header.getOrDefault("X-Amz-Credential")
  valid_591276 = validateParameter(valid_591276, JString, required = false,
                                 default = nil)
  if valid_591276 != nil:
    section.add "X-Amz-Credential", valid_591276
  var valid_591277 = header.getOrDefault("X-Amz-Security-Token")
  valid_591277 = validateParameter(valid_591277, JString, required = false,
                                 default = nil)
  if valid_591277 != nil:
    section.add "X-Amz-Security-Token", valid_591277
  var valid_591278 = header.getOrDefault("X-Amz-Algorithm")
  valid_591278 = validateParameter(valid_591278, JString, required = false,
                                 default = nil)
  if valid_591278 != nil:
    section.add "X-Amz-Algorithm", valid_591278
  var valid_591279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591279 = validateParameter(valid_591279, JString, required = false,
                                 default = nil)
  if valid_591279 != nil:
    section.add "X-Amz-SignedHeaders", valid_591279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591281: Call_EnableAWSServiceAccess_591269; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the integration of an AWS service (the service that is specified by <code>ServicePrincipal</code>) with AWS Organizations. When you enable integration, you allow the specified service to create a <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html">service-linked role</a> in all the accounts in your organization. This allows the service to perform operations on your behalf in your organization and its accounts.</p> <important> <p>We recommend that you enable integration between AWS Organizations and the specified AWS service by using the console or commands that are provided by the specified service. Doing so ensures that the service is aware that it can create the resources that are required for the integration. How the service creates those resources in the organization's accounts depends on that service. For more information, see the documentation for the other AWS service.</p> </important> <p>For more information about enabling services to integrate with AWS Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account and only if the organization has <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">enabled all features</a>.</p>
  ## 
  let valid = call_591281.validator(path, query, header, formData, body)
  let scheme = call_591281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591281.url(scheme.get, call_591281.host, call_591281.base,
                         call_591281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591281, url, valid)

proc call*(call_591282: Call_EnableAWSServiceAccess_591269; body: JsonNode): Recallable =
  ## enableAWSServiceAccess
  ## <p>Enables the integration of an AWS service (the service that is specified by <code>ServicePrincipal</code>) with AWS Organizations. When you enable integration, you allow the specified service to create a <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html">service-linked role</a> in all the accounts in your organization. This allows the service to perform operations on your behalf in your organization and its accounts.</p> <important> <p>We recommend that you enable integration between AWS Organizations and the specified AWS service by using the console or commands that are provided by the specified service. Doing so ensures that the service is aware that it can create the resources that are required for the integration. How the service creates those resources in the organization's accounts depends on that service. For more information, see the documentation for the other AWS service.</p> </important> <p>For more information about enabling services to integrate with AWS Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account and only if the organization has <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">enabled all features</a>.</p>
  ##   body: JObject (required)
  var body_591283 = newJObject()
  if body != nil:
    body_591283 = body
  result = call_591282.call(nil, nil, nil, nil, body_591283)

var enableAWSServiceAccess* = Call_EnableAWSServiceAccess_591269(
    name: "enableAWSServiceAccess", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.EnableAWSServiceAccess",
    validator: validate_EnableAWSServiceAccess_591270, base: "/",
    url: url_EnableAWSServiceAccess_591271, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableAllFeatures_591284 = ref object of OpenApiRestCall_590365
proc url_EnableAllFeatures_591286(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_EnableAllFeatures_591285(path: JsonNode; query: JsonNode;
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
  var valid_591287 = header.getOrDefault("X-Amz-Target")
  valid_591287 = validateParameter(valid_591287, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.EnableAllFeatures"))
  if valid_591287 != nil:
    section.add "X-Amz-Target", valid_591287
  var valid_591288 = header.getOrDefault("X-Amz-Signature")
  valid_591288 = validateParameter(valid_591288, JString, required = false,
                                 default = nil)
  if valid_591288 != nil:
    section.add "X-Amz-Signature", valid_591288
  var valid_591289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591289 = validateParameter(valid_591289, JString, required = false,
                                 default = nil)
  if valid_591289 != nil:
    section.add "X-Amz-Content-Sha256", valid_591289
  var valid_591290 = header.getOrDefault("X-Amz-Date")
  valid_591290 = validateParameter(valid_591290, JString, required = false,
                                 default = nil)
  if valid_591290 != nil:
    section.add "X-Amz-Date", valid_591290
  var valid_591291 = header.getOrDefault("X-Amz-Credential")
  valid_591291 = validateParameter(valid_591291, JString, required = false,
                                 default = nil)
  if valid_591291 != nil:
    section.add "X-Amz-Credential", valid_591291
  var valid_591292 = header.getOrDefault("X-Amz-Security-Token")
  valid_591292 = validateParameter(valid_591292, JString, required = false,
                                 default = nil)
  if valid_591292 != nil:
    section.add "X-Amz-Security-Token", valid_591292
  var valid_591293 = header.getOrDefault("X-Amz-Algorithm")
  valid_591293 = validateParameter(valid_591293, JString, required = false,
                                 default = nil)
  if valid_591293 != nil:
    section.add "X-Amz-Algorithm", valid_591293
  var valid_591294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591294 = validateParameter(valid_591294, JString, required = false,
                                 default = nil)
  if valid_591294 != nil:
    section.add "X-Amz-SignedHeaders", valid_591294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591296: Call_EnableAllFeatures_591284; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables all features in an organization. This enables the use of organization policies that can restrict the services and actions that can be called in each account. Until you enable all features, you have access only to consolidated billing, and you can't use any of the advanced account administration features that AWS Organizations supports. For more information, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">Enabling All Features in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <p>This operation is required only for organizations that were created explicitly with only the consolidated billing features enabled. Calling this operation sends a handshake to every invited account in the organization. The feature set change can be finalized and the additional features enabled only after all administrators in the invited accounts approve the change by accepting the handshake.</p> </important> <p>After you enable all features, you can separately enable or disable individual policy types in a root using <a>EnablePolicyType</a> and <a>DisablePolicyType</a>. To see the status of policy types in a root, use <a>ListRoots</a>.</p> <p>After all invited member accounts accept the handshake, you finalize the feature set change by accepting the handshake that contains <code>"Action": "ENABLE_ALL_FEATURES"</code>. This completes the change.</p> <p>After you enable all features in your organization, the master account in the organization can apply policies on all member accounts. These policies can restrict what users and even administrators in those accounts can do. The master account can apply policies that prevent accounts from leaving the organization. Ensure that your account administrators are aware of this.</p> <p>This operation can be called only from the organization's master account. </p>
  ## 
  let valid = call_591296.validator(path, query, header, formData, body)
  let scheme = call_591296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591296.url(scheme.get, call_591296.host, call_591296.base,
                         call_591296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591296, url, valid)

proc call*(call_591297: Call_EnableAllFeatures_591284; body: JsonNode): Recallable =
  ## enableAllFeatures
  ## <p>Enables all features in an organization. This enables the use of organization policies that can restrict the services and actions that can be called in each account. Until you enable all features, you have access only to consolidated billing, and you can't use any of the advanced account administration features that AWS Organizations supports. For more information, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">Enabling All Features in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <p>This operation is required only for organizations that were created explicitly with only the consolidated billing features enabled. Calling this operation sends a handshake to every invited account in the organization. The feature set change can be finalized and the additional features enabled only after all administrators in the invited accounts approve the change by accepting the handshake.</p> </important> <p>After you enable all features, you can separately enable or disable individual policy types in a root using <a>EnablePolicyType</a> and <a>DisablePolicyType</a>. To see the status of policy types in a root, use <a>ListRoots</a>.</p> <p>After all invited member accounts accept the handshake, you finalize the feature set change by accepting the handshake that contains <code>"Action": "ENABLE_ALL_FEATURES"</code>. This completes the change.</p> <p>After you enable all features in your organization, the master account in the organization can apply policies on all member accounts. These policies can restrict what users and even administrators in those accounts can do. The master account can apply policies that prevent accounts from leaving the organization. Ensure that your account administrators are aware of this.</p> <p>This operation can be called only from the organization's master account. </p>
  ##   body: JObject (required)
  var body_591298 = newJObject()
  if body != nil:
    body_591298 = body
  result = call_591297.call(nil, nil, nil, nil, body_591298)

var enableAllFeatures* = Call_EnableAllFeatures_591284(name: "enableAllFeatures",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.EnableAllFeatures",
    validator: validate_EnableAllFeatures_591285, base: "/",
    url: url_EnableAllFeatures_591286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnablePolicyType_591299 = ref object of OpenApiRestCall_590365
proc url_EnablePolicyType_591301(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_EnablePolicyType_591300(path: JsonNode; query: JsonNode;
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
  var valid_591302 = header.getOrDefault("X-Amz-Target")
  valid_591302 = validateParameter(valid_591302, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.EnablePolicyType"))
  if valid_591302 != nil:
    section.add "X-Amz-Target", valid_591302
  var valid_591303 = header.getOrDefault("X-Amz-Signature")
  valid_591303 = validateParameter(valid_591303, JString, required = false,
                                 default = nil)
  if valid_591303 != nil:
    section.add "X-Amz-Signature", valid_591303
  var valid_591304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591304 = validateParameter(valid_591304, JString, required = false,
                                 default = nil)
  if valid_591304 != nil:
    section.add "X-Amz-Content-Sha256", valid_591304
  var valid_591305 = header.getOrDefault("X-Amz-Date")
  valid_591305 = validateParameter(valid_591305, JString, required = false,
                                 default = nil)
  if valid_591305 != nil:
    section.add "X-Amz-Date", valid_591305
  var valid_591306 = header.getOrDefault("X-Amz-Credential")
  valid_591306 = validateParameter(valid_591306, JString, required = false,
                                 default = nil)
  if valid_591306 != nil:
    section.add "X-Amz-Credential", valid_591306
  var valid_591307 = header.getOrDefault("X-Amz-Security-Token")
  valid_591307 = validateParameter(valid_591307, JString, required = false,
                                 default = nil)
  if valid_591307 != nil:
    section.add "X-Amz-Security-Token", valid_591307
  var valid_591308 = header.getOrDefault("X-Amz-Algorithm")
  valid_591308 = validateParameter(valid_591308, JString, required = false,
                                 default = nil)
  if valid_591308 != nil:
    section.add "X-Amz-Algorithm", valid_591308
  var valid_591309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591309 = validateParameter(valid_591309, JString, required = false,
                                 default = nil)
  if valid_591309 != nil:
    section.add "X-Amz-SignedHeaders", valid_591309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591311: Call_EnablePolicyType_591299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables a policy type in a root. After you enable a policy type in a root, you can attach policies of that type to the root, any organizational unit (OU), or account in that root. You can undo this by using the <a>DisablePolicyType</a> operation.</p> <p>This is an asynchronous request that AWS performs in the background. AWS recommends that you first use <a>ListRoots</a> to see the status of policy types for a specified root, and then use this operation. </p> <p>This operation can be called only from the organization's master account.</p> <p>You can enable a policy type in a root only if that policy type is available in the organization. To view the status of available policy types in the organization, use <a>DescribeOrganization</a>.</p>
  ## 
  let valid = call_591311.validator(path, query, header, formData, body)
  let scheme = call_591311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591311.url(scheme.get, call_591311.host, call_591311.base,
                         call_591311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591311, url, valid)

proc call*(call_591312: Call_EnablePolicyType_591299; body: JsonNode): Recallable =
  ## enablePolicyType
  ## <p>Enables a policy type in a root. After you enable a policy type in a root, you can attach policies of that type to the root, any organizational unit (OU), or account in that root. You can undo this by using the <a>DisablePolicyType</a> operation.</p> <p>This is an asynchronous request that AWS performs in the background. AWS recommends that you first use <a>ListRoots</a> to see the status of policy types for a specified root, and then use this operation. </p> <p>This operation can be called only from the organization's master account.</p> <p>You can enable a policy type in a root only if that policy type is available in the organization. To view the status of available policy types in the organization, use <a>DescribeOrganization</a>.</p>
  ##   body: JObject (required)
  var body_591313 = newJObject()
  if body != nil:
    body_591313 = body
  result = call_591312.call(nil, nil, nil, nil, body_591313)

var enablePolicyType* = Call_EnablePolicyType_591299(name: "enablePolicyType",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.EnablePolicyType",
    validator: validate_EnablePolicyType_591300, base: "/",
    url: url_EnablePolicyType_591301, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteAccountToOrganization_591314 = ref object of OpenApiRestCall_590365
proc url_InviteAccountToOrganization_591316(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_InviteAccountToOrganization_591315(path: JsonNode; query: JsonNode;
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
  var valid_591317 = header.getOrDefault("X-Amz-Target")
  valid_591317 = validateParameter(valid_591317, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.InviteAccountToOrganization"))
  if valid_591317 != nil:
    section.add "X-Amz-Target", valid_591317
  var valid_591318 = header.getOrDefault("X-Amz-Signature")
  valid_591318 = validateParameter(valid_591318, JString, required = false,
                                 default = nil)
  if valid_591318 != nil:
    section.add "X-Amz-Signature", valid_591318
  var valid_591319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591319 = validateParameter(valid_591319, JString, required = false,
                                 default = nil)
  if valid_591319 != nil:
    section.add "X-Amz-Content-Sha256", valid_591319
  var valid_591320 = header.getOrDefault("X-Amz-Date")
  valid_591320 = validateParameter(valid_591320, JString, required = false,
                                 default = nil)
  if valid_591320 != nil:
    section.add "X-Amz-Date", valid_591320
  var valid_591321 = header.getOrDefault("X-Amz-Credential")
  valid_591321 = validateParameter(valid_591321, JString, required = false,
                                 default = nil)
  if valid_591321 != nil:
    section.add "X-Amz-Credential", valid_591321
  var valid_591322 = header.getOrDefault("X-Amz-Security-Token")
  valid_591322 = validateParameter(valid_591322, JString, required = false,
                                 default = nil)
  if valid_591322 != nil:
    section.add "X-Amz-Security-Token", valid_591322
  var valid_591323 = header.getOrDefault("X-Amz-Algorithm")
  valid_591323 = validateParameter(valid_591323, JString, required = false,
                                 default = nil)
  if valid_591323 != nil:
    section.add "X-Amz-Algorithm", valid_591323
  var valid_591324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591324 = validateParameter(valid_591324, JString, required = false,
                                 default = nil)
  if valid_591324 != nil:
    section.add "X-Amz-SignedHeaders", valid_591324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591326: Call_InviteAccountToOrganization_591314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends an invitation to another account to join your organization as a member account. AWS Organizations sends email on your behalf to the email address that is associated with the other account's owner. The invitation is implemented as a <a>Handshake</a> whose details are in the response.</p> <important> <ul> <li> <p>You can invite AWS accounts only from the same seller as the master account. For example, if your organization's master account was created by Amazon Internet Services Pvt. Ltd (AISPL), an AWS seller in India, you can invite only other AISPL accounts to your organization. You can't combine accounts from AISPL and AWS or from any other AWS seller. For more information, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/useconsolidatedbilliing-India.html">Consolidated Billing in India</a>.</p> </li> <li> <p>If you receive an exception that indicates that you exceeded your account limits for the organization or that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists after an hour, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> </ul> </important> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_591326.validator(path, query, header, formData, body)
  let scheme = call_591326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591326.url(scheme.get, call_591326.host, call_591326.base,
                         call_591326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591326, url, valid)

proc call*(call_591327: Call_InviteAccountToOrganization_591314; body: JsonNode): Recallable =
  ## inviteAccountToOrganization
  ## <p>Sends an invitation to another account to join your organization as a member account. AWS Organizations sends email on your behalf to the email address that is associated with the other account's owner. The invitation is implemented as a <a>Handshake</a> whose details are in the response.</p> <important> <ul> <li> <p>You can invite AWS accounts only from the same seller as the master account. For example, if your organization's master account was created by Amazon Internet Services Pvt. Ltd (AISPL), an AWS seller in India, you can invite only other AISPL accounts to your organization. You can't combine accounts from AISPL and AWS or from any other AWS seller. For more information, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/useconsolidatedbilliing-India.html">Consolidated Billing in India</a>.</p> </li> <li> <p>If you receive an exception that indicates that you exceeded your account limits for the organization or that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists after an hour, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> </ul> </important> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_591328 = newJObject()
  if body != nil:
    body_591328 = body
  result = call_591327.call(nil, nil, nil, nil, body_591328)

var inviteAccountToOrganization* = Call_InviteAccountToOrganization_591314(
    name: "inviteAccountToOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.InviteAccountToOrganization",
    validator: validate_InviteAccountToOrganization_591315, base: "/",
    url: url_InviteAccountToOrganization_591316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_LeaveOrganization_591329 = ref object of OpenApiRestCall_590365
proc url_LeaveOrganization_591331(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_LeaveOrganization_591330(path: JsonNode; query: JsonNode;
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
  var valid_591332 = header.getOrDefault("X-Amz-Target")
  valid_591332 = validateParameter(valid_591332, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.LeaveOrganization"))
  if valid_591332 != nil:
    section.add "X-Amz-Target", valid_591332
  var valid_591333 = header.getOrDefault("X-Amz-Signature")
  valid_591333 = validateParameter(valid_591333, JString, required = false,
                                 default = nil)
  if valid_591333 != nil:
    section.add "X-Amz-Signature", valid_591333
  var valid_591334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591334 = validateParameter(valid_591334, JString, required = false,
                                 default = nil)
  if valid_591334 != nil:
    section.add "X-Amz-Content-Sha256", valid_591334
  var valid_591335 = header.getOrDefault("X-Amz-Date")
  valid_591335 = validateParameter(valid_591335, JString, required = false,
                                 default = nil)
  if valid_591335 != nil:
    section.add "X-Amz-Date", valid_591335
  var valid_591336 = header.getOrDefault("X-Amz-Credential")
  valid_591336 = validateParameter(valid_591336, JString, required = false,
                                 default = nil)
  if valid_591336 != nil:
    section.add "X-Amz-Credential", valid_591336
  var valid_591337 = header.getOrDefault("X-Amz-Security-Token")
  valid_591337 = validateParameter(valid_591337, JString, required = false,
                                 default = nil)
  if valid_591337 != nil:
    section.add "X-Amz-Security-Token", valid_591337
  var valid_591338 = header.getOrDefault("X-Amz-Algorithm")
  valid_591338 = validateParameter(valid_591338, JString, required = false,
                                 default = nil)
  if valid_591338 != nil:
    section.add "X-Amz-Algorithm", valid_591338
  var valid_591339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591339 = validateParameter(valid_591339, JString, required = false,
                                 default = nil)
  if valid_591339 != nil:
    section.add "X-Amz-SignedHeaders", valid_591339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591340: Call_LeaveOrganization_591329; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a member account from its parent organization. This version of the operation is performed by the account that wants to leave. To remove a member account as a user in the master account, use <a>RemoveAccountFromOrganization</a> instead.</p> <p>This operation can be called only from a member account in the organization.</p> <important> <ul> <li> <p>The master account in an organization with all features enabled can set service control policies (SCPs) that can restrict what administrators of member accounts can do, including preventing them from successfully calling <code>LeaveOrganization</code> and leaving the organization. </p> </li> <li> <p>You can leave an organization as a member account only if the account is configured with the information required to operate as a standalone account. When you create an account in an organization using the AWS Organizations console, API, or CLI commands, the information required of standalone accounts is <i>not</i> automatically collected. For each account that you want to make standalone, you must accept the end user license agreement (EULA), choose a support plan, provide and verify the required contact information, and provide a current payment method. AWS uses the payment method to charge for any billable (not free tier) AWS activity that occurs while the account isn't attached to an organization. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization when all required account information has not yet been provided</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>You can leave an organization only after you enable IAM user access to billing in your account. For more information, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html#ControllingAccessWebsite-Activate">Activating Access to the Billing and Cost Management Console</a> in the <i>AWS Billing and Cost Management User Guide.</i> </p> </li> </ul> </important>
  ## 
  let valid = call_591340.validator(path, query, header, formData, body)
  let scheme = call_591340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591340.url(scheme.get, call_591340.host, call_591340.base,
                         call_591340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591340, url, valid)

proc call*(call_591341: Call_LeaveOrganization_591329): Recallable =
  ## leaveOrganization
  ## <p>Removes a member account from its parent organization. This version of the operation is performed by the account that wants to leave. To remove a member account as a user in the master account, use <a>RemoveAccountFromOrganization</a> instead.</p> <p>This operation can be called only from a member account in the organization.</p> <important> <ul> <li> <p>The master account in an organization with all features enabled can set service control policies (SCPs) that can restrict what administrators of member accounts can do, including preventing them from successfully calling <code>LeaveOrganization</code> and leaving the organization. </p> </li> <li> <p>You can leave an organization as a member account only if the account is configured with the information required to operate as a standalone account. When you create an account in an organization using the AWS Organizations console, API, or CLI commands, the information required of standalone accounts is <i>not</i> automatically collected. For each account that you want to make standalone, you must accept the end user license agreement (EULA), choose a support plan, provide and verify the required contact information, and provide a current payment method. AWS uses the payment method to charge for any billable (not free tier) AWS activity that occurs while the account isn't attached to an organization. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization when all required account information has not yet been provided</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>You can leave an organization only after you enable IAM user access to billing in your account. For more information, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html#ControllingAccessWebsite-Activate">Activating Access to the Billing and Cost Management Console</a> in the <i>AWS Billing and Cost Management User Guide.</i> </p> </li> </ul> </important>
  result = call_591341.call(nil, nil, nil, nil, nil)

var leaveOrganization* = Call_LeaveOrganization_591329(name: "leaveOrganization",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.LeaveOrganization",
    validator: validate_LeaveOrganization_591330, base: "/",
    url: url_LeaveOrganization_591331, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAWSServiceAccessForOrganization_591342 = ref object of OpenApiRestCall_590365
proc url_ListAWSServiceAccessForOrganization_591344(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAWSServiceAccessForOrganization_591343(path: JsonNode;
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
  var valid_591345 = query.getOrDefault("MaxResults")
  valid_591345 = validateParameter(valid_591345, JString, required = false,
                                 default = nil)
  if valid_591345 != nil:
    section.add "MaxResults", valid_591345
  var valid_591346 = query.getOrDefault("NextToken")
  valid_591346 = validateParameter(valid_591346, JString, required = false,
                                 default = nil)
  if valid_591346 != nil:
    section.add "NextToken", valid_591346
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
  var valid_591347 = header.getOrDefault("X-Amz-Target")
  valid_591347 = validateParameter(valid_591347, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListAWSServiceAccessForOrganization"))
  if valid_591347 != nil:
    section.add "X-Amz-Target", valid_591347
  var valid_591348 = header.getOrDefault("X-Amz-Signature")
  valid_591348 = validateParameter(valid_591348, JString, required = false,
                                 default = nil)
  if valid_591348 != nil:
    section.add "X-Amz-Signature", valid_591348
  var valid_591349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591349 = validateParameter(valid_591349, JString, required = false,
                                 default = nil)
  if valid_591349 != nil:
    section.add "X-Amz-Content-Sha256", valid_591349
  var valid_591350 = header.getOrDefault("X-Amz-Date")
  valid_591350 = validateParameter(valid_591350, JString, required = false,
                                 default = nil)
  if valid_591350 != nil:
    section.add "X-Amz-Date", valid_591350
  var valid_591351 = header.getOrDefault("X-Amz-Credential")
  valid_591351 = validateParameter(valid_591351, JString, required = false,
                                 default = nil)
  if valid_591351 != nil:
    section.add "X-Amz-Credential", valid_591351
  var valid_591352 = header.getOrDefault("X-Amz-Security-Token")
  valid_591352 = validateParameter(valid_591352, JString, required = false,
                                 default = nil)
  if valid_591352 != nil:
    section.add "X-Amz-Security-Token", valid_591352
  var valid_591353 = header.getOrDefault("X-Amz-Algorithm")
  valid_591353 = validateParameter(valid_591353, JString, required = false,
                                 default = nil)
  if valid_591353 != nil:
    section.add "X-Amz-Algorithm", valid_591353
  var valid_591354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591354 = validateParameter(valid_591354, JString, required = false,
                                 default = nil)
  if valid_591354 != nil:
    section.add "X-Amz-SignedHeaders", valid_591354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591356: Call_ListAWSServiceAccessForOrganization_591342;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of the AWS services that you enabled to integrate with your organization. After a service on this list creates the resources that it requires for the integration, it can perform operations on your organization and its accounts.</p> <p>For more information about integrating other services with AWS Organizations, including the list of services that currently work with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_591356.validator(path, query, header, formData, body)
  let scheme = call_591356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591356.url(scheme.get, call_591356.host, call_591356.base,
                         call_591356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591356, url, valid)

proc call*(call_591357: Call_ListAWSServiceAccessForOrganization_591342;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAWSServiceAccessForOrganization
  ## <p>Returns a list of the AWS services that you enabled to integrate with your organization. After a service on this list creates the resources that it requires for the integration, it can perform operations on your organization and its accounts.</p> <p>For more information about integrating other services with AWS Organizations, including the list of services that currently work with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591358 = newJObject()
  var body_591359 = newJObject()
  add(query_591358, "MaxResults", newJString(MaxResults))
  add(query_591358, "NextToken", newJString(NextToken))
  if body != nil:
    body_591359 = body
  result = call_591357.call(nil, query_591358, nil, nil, body_591359)

var listAWSServiceAccessForOrganization* = Call_ListAWSServiceAccessForOrganization_591342(
    name: "listAWSServiceAccessForOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListAWSServiceAccessForOrganization",
    validator: validate_ListAWSServiceAccessForOrganization_591343, base: "/",
    url: url_ListAWSServiceAccessForOrganization_591344,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccounts_591361 = ref object of OpenApiRestCall_590365
proc url_ListAccounts_591363(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAccounts_591362(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591364 = query.getOrDefault("MaxResults")
  valid_591364 = validateParameter(valid_591364, JString, required = false,
                                 default = nil)
  if valid_591364 != nil:
    section.add "MaxResults", valid_591364
  var valid_591365 = query.getOrDefault("NextToken")
  valid_591365 = validateParameter(valid_591365, JString, required = false,
                                 default = nil)
  if valid_591365 != nil:
    section.add "NextToken", valid_591365
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
  var valid_591366 = header.getOrDefault("X-Amz-Target")
  valid_591366 = validateParameter(valid_591366, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListAccounts"))
  if valid_591366 != nil:
    section.add "X-Amz-Target", valid_591366
  var valid_591367 = header.getOrDefault("X-Amz-Signature")
  valid_591367 = validateParameter(valid_591367, JString, required = false,
                                 default = nil)
  if valid_591367 != nil:
    section.add "X-Amz-Signature", valid_591367
  var valid_591368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591368 = validateParameter(valid_591368, JString, required = false,
                                 default = nil)
  if valid_591368 != nil:
    section.add "X-Amz-Content-Sha256", valid_591368
  var valid_591369 = header.getOrDefault("X-Amz-Date")
  valid_591369 = validateParameter(valid_591369, JString, required = false,
                                 default = nil)
  if valid_591369 != nil:
    section.add "X-Amz-Date", valid_591369
  var valid_591370 = header.getOrDefault("X-Amz-Credential")
  valid_591370 = validateParameter(valid_591370, JString, required = false,
                                 default = nil)
  if valid_591370 != nil:
    section.add "X-Amz-Credential", valid_591370
  var valid_591371 = header.getOrDefault("X-Amz-Security-Token")
  valid_591371 = validateParameter(valid_591371, JString, required = false,
                                 default = nil)
  if valid_591371 != nil:
    section.add "X-Amz-Security-Token", valid_591371
  var valid_591372 = header.getOrDefault("X-Amz-Algorithm")
  valid_591372 = validateParameter(valid_591372, JString, required = false,
                                 default = nil)
  if valid_591372 != nil:
    section.add "X-Amz-Algorithm", valid_591372
  var valid_591373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591373 = validateParameter(valid_591373, JString, required = false,
                                 default = nil)
  if valid_591373 != nil:
    section.add "X-Amz-SignedHeaders", valid_591373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591375: Call_ListAccounts_591361; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all the accounts in the organization. To request only the accounts in a specified root or organizational unit (OU), use the <a>ListAccountsForParent</a> operation instead.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_591375.validator(path, query, header, formData, body)
  let scheme = call_591375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591375.url(scheme.get, call_591375.host, call_591375.base,
                         call_591375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591375, url, valid)

proc call*(call_591376: Call_ListAccounts_591361; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAccounts
  ## <p>Lists all the accounts in the organization. To request only the accounts in a specified root or organizational unit (OU), use the <a>ListAccountsForParent</a> operation instead.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591377 = newJObject()
  var body_591378 = newJObject()
  add(query_591377, "MaxResults", newJString(MaxResults))
  add(query_591377, "NextToken", newJString(NextToken))
  if body != nil:
    body_591378 = body
  result = call_591376.call(nil, query_591377, nil, nil, body_591378)

var listAccounts* = Call_ListAccounts_591361(name: "listAccounts",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListAccounts",
    validator: validate_ListAccounts_591362, base: "/", url: url_ListAccounts_591363,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccountsForParent_591379 = ref object of OpenApiRestCall_590365
proc url_ListAccountsForParent_591381(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAccountsForParent_591380(path: JsonNode; query: JsonNode;
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
  var valid_591382 = query.getOrDefault("MaxResults")
  valid_591382 = validateParameter(valid_591382, JString, required = false,
                                 default = nil)
  if valid_591382 != nil:
    section.add "MaxResults", valid_591382
  var valid_591383 = query.getOrDefault("NextToken")
  valid_591383 = validateParameter(valid_591383, JString, required = false,
                                 default = nil)
  if valid_591383 != nil:
    section.add "NextToken", valid_591383
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
  var valid_591384 = header.getOrDefault("X-Amz-Target")
  valid_591384 = validateParameter(valid_591384, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListAccountsForParent"))
  if valid_591384 != nil:
    section.add "X-Amz-Target", valid_591384
  var valid_591385 = header.getOrDefault("X-Amz-Signature")
  valid_591385 = validateParameter(valid_591385, JString, required = false,
                                 default = nil)
  if valid_591385 != nil:
    section.add "X-Amz-Signature", valid_591385
  var valid_591386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591386 = validateParameter(valid_591386, JString, required = false,
                                 default = nil)
  if valid_591386 != nil:
    section.add "X-Amz-Content-Sha256", valid_591386
  var valid_591387 = header.getOrDefault("X-Amz-Date")
  valid_591387 = validateParameter(valid_591387, JString, required = false,
                                 default = nil)
  if valid_591387 != nil:
    section.add "X-Amz-Date", valid_591387
  var valid_591388 = header.getOrDefault("X-Amz-Credential")
  valid_591388 = validateParameter(valid_591388, JString, required = false,
                                 default = nil)
  if valid_591388 != nil:
    section.add "X-Amz-Credential", valid_591388
  var valid_591389 = header.getOrDefault("X-Amz-Security-Token")
  valid_591389 = validateParameter(valid_591389, JString, required = false,
                                 default = nil)
  if valid_591389 != nil:
    section.add "X-Amz-Security-Token", valid_591389
  var valid_591390 = header.getOrDefault("X-Amz-Algorithm")
  valid_591390 = validateParameter(valid_591390, JString, required = false,
                                 default = nil)
  if valid_591390 != nil:
    section.add "X-Amz-Algorithm", valid_591390
  var valid_591391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591391 = validateParameter(valid_591391, JString, required = false,
                                 default = nil)
  if valid_591391 != nil:
    section.add "X-Amz-SignedHeaders", valid_591391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591393: Call_ListAccountsForParent_591379; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the accounts in an organization that are contained by the specified target root or organizational unit (OU). If you specify the root, you get a list of all the accounts that aren't in any OU. If you specify an OU, you get a list of all the accounts in only that OU and not in any child OUs. To get a list of all accounts in the organization, use the <a>ListAccounts</a> operation.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_591393.validator(path, query, header, formData, body)
  let scheme = call_591393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591393.url(scheme.get, call_591393.host, call_591393.base,
                         call_591393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591393, url, valid)

proc call*(call_591394: Call_ListAccountsForParent_591379; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAccountsForParent
  ## <p>Lists the accounts in an organization that are contained by the specified target root or organizational unit (OU). If you specify the root, you get a list of all the accounts that aren't in any OU. If you specify an OU, you get a list of all the accounts in only that OU and not in any child OUs. To get a list of all accounts in the organization, use the <a>ListAccounts</a> operation.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591395 = newJObject()
  var body_591396 = newJObject()
  add(query_591395, "MaxResults", newJString(MaxResults))
  add(query_591395, "NextToken", newJString(NextToken))
  if body != nil:
    body_591396 = body
  result = call_591394.call(nil, query_591395, nil, nil, body_591396)

var listAccountsForParent* = Call_ListAccountsForParent_591379(
    name: "listAccountsForParent", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListAccountsForParent",
    validator: validate_ListAccountsForParent_591380, base: "/",
    url: url_ListAccountsForParent_591381, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChildren_591397 = ref object of OpenApiRestCall_590365
proc url_ListChildren_591399(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListChildren_591398(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591400 = query.getOrDefault("MaxResults")
  valid_591400 = validateParameter(valid_591400, JString, required = false,
                                 default = nil)
  if valid_591400 != nil:
    section.add "MaxResults", valid_591400
  var valid_591401 = query.getOrDefault("NextToken")
  valid_591401 = validateParameter(valid_591401, JString, required = false,
                                 default = nil)
  if valid_591401 != nil:
    section.add "NextToken", valid_591401
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
  var valid_591402 = header.getOrDefault("X-Amz-Target")
  valid_591402 = validateParameter(valid_591402, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListChildren"))
  if valid_591402 != nil:
    section.add "X-Amz-Target", valid_591402
  var valid_591403 = header.getOrDefault("X-Amz-Signature")
  valid_591403 = validateParameter(valid_591403, JString, required = false,
                                 default = nil)
  if valid_591403 != nil:
    section.add "X-Amz-Signature", valid_591403
  var valid_591404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591404 = validateParameter(valid_591404, JString, required = false,
                                 default = nil)
  if valid_591404 != nil:
    section.add "X-Amz-Content-Sha256", valid_591404
  var valid_591405 = header.getOrDefault("X-Amz-Date")
  valid_591405 = validateParameter(valid_591405, JString, required = false,
                                 default = nil)
  if valid_591405 != nil:
    section.add "X-Amz-Date", valid_591405
  var valid_591406 = header.getOrDefault("X-Amz-Credential")
  valid_591406 = validateParameter(valid_591406, JString, required = false,
                                 default = nil)
  if valid_591406 != nil:
    section.add "X-Amz-Credential", valid_591406
  var valid_591407 = header.getOrDefault("X-Amz-Security-Token")
  valid_591407 = validateParameter(valid_591407, JString, required = false,
                                 default = nil)
  if valid_591407 != nil:
    section.add "X-Amz-Security-Token", valid_591407
  var valid_591408 = header.getOrDefault("X-Amz-Algorithm")
  valid_591408 = validateParameter(valid_591408, JString, required = false,
                                 default = nil)
  if valid_591408 != nil:
    section.add "X-Amz-Algorithm", valid_591408
  var valid_591409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591409 = validateParameter(valid_591409, JString, required = false,
                                 default = nil)
  if valid_591409 != nil:
    section.add "X-Amz-SignedHeaders", valid_591409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591411: Call_ListChildren_591397; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all of the organizational units (OUs) or accounts that are contained in the specified parent OU or root. This operation, along with <a>ListParents</a> enables you to traverse the tree structure that makes up this root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_591411.validator(path, query, header, formData, body)
  let scheme = call_591411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591411.url(scheme.get, call_591411.host, call_591411.base,
                         call_591411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591411, url, valid)

proc call*(call_591412: Call_ListChildren_591397; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listChildren
  ## <p>Lists all of the organizational units (OUs) or accounts that are contained in the specified parent OU or root. This operation, along with <a>ListParents</a> enables you to traverse the tree structure that makes up this root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591413 = newJObject()
  var body_591414 = newJObject()
  add(query_591413, "MaxResults", newJString(MaxResults))
  add(query_591413, "NextToken", newJString(NextToken))
  if body != nil:
    body_591414 = body
  result = call_591412.call(nil, query_591413, nil, nil, body_591414)

var listChildren* = Call_ListChildren_591397(name: "listChildren",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListChildren",
    validator: validate_ListChildren_591398, base: "/", url: url_ListChildren_591399,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCreateAccountStatus_591415 = ref object of OpenApiRestCall_590365
proc url_ListCreateAccountStatus_591417(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListCreateAccountStatus_591416(path: JsonNode; query: JsonNode;
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
  var valid_591418 = query.getOrDefault("MaxResults")
  valid_591418 = validateParameter(valid_591418, JString, required = false,
                                 default = nil)
  if valid_591418 != nil:
    section.add "MaxResults", valid_591418
  var valid_591419 = query.getOrDefault("NextToken")
  valid_591419 = validateParameter(valid_591419, JString, required = false,
                                 default = nil)
  if valid_591419 != nil:
    section.add "NextToken", valid_591419
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
  var valid_591420 = header.getOrDefault("X-Amz-Target")
  valid_591420 = validateParameter(valid_591420, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListCreateAccountStatus"))
  if valid_591420 != nil:
    section.add "X-Amz-Target", valid_591420
  var valid_591421 = header.getOrDefault("X-Amz-Signature")
  valid_591421 = validateParameter(valid_591421, JString, required = false,
                                 default = nil)
  if valid_591421 != nil:
    section.add "X-Amz-Signature", valid_591421
  var valid_591422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591422 = validateParameter(valid_591422, JString, required = false,
                                 default = nil)
  if valid_591422 != nil:
    section.add "X-Amz-Content-Sha256", valid_591422
  var valid_591423 = header.getOrDefault("X-Amz-Date")
  valid_591423 = validateParameter(valid_591423, JString, required = false,
                                 default = nil)
  if valid_591423 != nil:
    section.add "X-Amz-Date", valid_591423
  var valid_591424 = header.getOrDefault("X-Amz-Credential")
  valid_591424 = validateParameter(valid_591424, JString, required = false,
                                 default = nil)
  if valid_591424 != nil:
    section.add "X-Amz-Credential", valid_591424
  var valid_591425 = header.getOrDefault("X-Amz-Security-Token")
  valid_591425 = validateParameter(valid_591425, JString, required = false,
                                 default = nil)
  if valid_591425 != nil:
    section.add "X-Amz-Security-Token", valid_591425
  var valid_591426 = header.getOrDefault("X-Amz-Algorithm")
  valid_591426 = validateParameter(valid_591426, JString, required = false,
                                 default = nil)
  if valid_591426 != nil:
    section.add "X-Amz-Algorithm", valid_591426
  var valid_591427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591427 = validateParameter(valid_591427, JString, required = false,
                                 default = nil)
  if valid_591427 != nil:
    section.add "X-Amz-SignedHeaders", valid_591427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591429: Call_ListCreateAccountStatus_591415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the account creation requests that match the specified status that is currently being tracked for the organization.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_591429.validator(path, query, header, formData, body)
  let scheme = call_591429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591429.url(scheme.get, call_591429.host, call_591429.base,
                         call_591429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591429, url, valid)

proc call*(call_591430: Call_ListCreateAccountStatus_591415; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCreateAccountStatus
  ## <p>Lists the account creation requests that match the specified status that is currently being tracked for the organization.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591431 = newJObject()
  var body_591432 = newJObject()
  add(query_591431, "MaxResults", newJString(MaxResults))
  add(query_591431, "NextToken", newJString(NextToken))
  if body != nil:
    body_591432 = body
  result = call_591430.call(nil, query_591431, nil, nil, body_591432)

var listCreateAccountStatus* = Call_ListCreateAccountStatus_591415(
    name: "listCreateAccountStatus", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListCreateAccountStatus",
    validator: validate_ListCreateAccountStatus_591416, base: "/",
    url: url_ListCreateAccountStatus_591417, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHandshakesForAccount_591433 = ref object of OpenApiRestCall_590365
proc url_ListHandshakesForAccount_591435(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListHandshakesForAccount_591434(path: JsonNode; query: JsonNode;
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
  var valid_591436 = query.getOrDefault("MaxResults")
  valid_591436 = validateParameter(valid_591436, JString, required = false,
                                 default = nil)
  if valid_591436 != nil:
    section.add "MaxResults", valid_591436
  var valid_591437 = query.getOrDefault("NextToken")
  valid_591437 = validateParameter(valid_591437, JString, required = false,
                                 default = nil)
  if valid_591437 != nil:
    section.add "NextToken", valid_591437
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
  var valid_591438 = header.getOrDefault("X-Amz-Target")
  valid_591438 = validateParameter(valid_591438, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListHandshakesForAccount"))
  if valid_591438 != nil:
    section.add "X-Amz-Target", valid_591438
  var valid_591439 = header.getOrDefault("X-Amz-Signature")
  valid_591439 = validateParameter(valid_591439, JString, required = false,
                                 default = nil)
  if valid_591439 != nil:
    section.add "X-Amz-Signature", valid_591439
  var valid_591440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591440 = validateParameter(valid_591440, JString, required = false,
                                 default = nil)
  if valid_591440 != nil:
    section.add "X-Amz-Content-Sha256", valid_591440
  var valid_591441 = header.getOrDefault("X-Amz-Date")
  valid_591441 = validateParameter(valid_591441, JString, required = false,
                                 default = nil)
  if valid_591441 != nil:
    section.add "X-Amz-Date", valid_591441
  var valid_591442 = header.getOrDefault("X-Amz-Credential")
  valid_591442 = validateParameter(valid_591442, JString, required = false,
                                 default = nil)
  if valid_591442 != nil:
    section.add "X-Amz-Credential", valid_591442
  var valid_591443 = header.getOrDefault("X-Amz-Security-Token")
  valid_591443 = validateParameter(valid_591443, JString, required = false,
                                 default = nil)
  if valid_591443 != nil:
    section.add "X-Amz-Security-Token", valid_591443
  var valid_591444 = header.getOrDefault("X-Amz-Algorithm")
  valid_591444 = validateParameter(valid_591444, JString, required = false,
                                 default = nil)
  if valid_591444 != nil:
    section.add "X-Amz-Algorithm", valid_591444
  var valid_591445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591445 = validateParameter(valid_591445, JString, required = false,
                                 default = nil)
  if valid_591445 != nil:
    section.add "X-Amz-SignedHeaders", valid_591445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591447: Call_ListHandshakesForAccount_591433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the current handshakes that are associated with the account of the requesting user.</p> <p>Handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> appear in the results of this API for only 30 days after changing to that state. After that, they're deleted and no longer accessible.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called from any account in the organization.</p>
  ## 
  let valid = call_591447.validator(path, query, header, formData, body)
  let scheme = call_591447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591447.url(scheme.get, call_591447.host, call_591447.base,
                         call_591447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591447, url, valid)

proc call*(call_591448: Call_ListHandshakesForAccount_591433; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listHandshakesForAccount
  ## <p>Lists the current handshakes that are associated with the account of the requesting user.</p> <p>Handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> appear in the results of this API for only 30 days after changing to that state. After that, they're deleted and no longer accessible.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called from any account in the organization.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591449 = newJObject()
  var body_591450 = newJObject()
  add(query_591449, "MaxResults", newJString(MaxResults))
  add(query_591449, "NextToken", newJString(NextToken))
  if body != nil:
    body_591450 = body
  result = call_591448.call(nil, query_591449, nil, nil, body_591450)

var listHandshakesForAccount* = Call_ListHandshakesForAccount_591433(
    name: "listHandshakesForAccount", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListHandshakesForAccount",
    validator: validate_ListHandshakesForAccount_591434, base: "/",
    url: url_ListHandshakesForAccount_591435, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHandshakesForOrganization_591451 = ref object of OpenApiRestCall_590365
proc url_ListHandshakesForOrganization_591453(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListHandshakesForOrganization_591452(path: JsonNode; query: JsonNode;
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
  var valid_591454 = query.getOrDefault("MaxResults")
  valid_591454 = validateParameter(valid_591454, JString, required = false,
                                 default = nil)
  if valid_591454 != nil:
    section.add "MaxResults", valid_591454
  var valid_591455 = query.getOrDefault("NextToken")
  valid_591455 = validateParameter(valid_591455, JString, required = false,
                                 default = nil)
  if valid_591455 != nil:
    section.add "NextToken", valid_591455
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
  var valid_591456 = header.getOrDefault("X-Amz-Target")
  valid_591456 = validateParameter(valid_591456, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListHandshakesForOrganization"))
  if valid_591456 != nil:
    section.add "X-Amz-Target", valid_591456
  var valid_591457 = header.getOrDefault("X-Amz-Signature")
  valid_591457 = validateParameter(valid_591457, JString, required = false,
                                 default = nil)
  if valid_591457 != nil:
    section.add "X-Amz-Signature", valid_591457
  var valid_591458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591458 = validateParameter(valid_591458, JString, required = false,
                                 default = nil)
  if valid_591458 != nil:
    section.add "X-Amz-Content-Sha256", valid_591458
  var valid_591459 = header.getOrDefault("X-Amz-Date")
  valid_591459 = validateParameter(valid_591459, JString, required = false,
                                 default = nil)
  if valid_591459 != nil:
    section.add "X-Amz-Date", valid_591459
  var valid_591460 = header.getOrDefault("X-Amz-Credential")
  valid_591460 = validateParameter(valid_591460, JString, required = false,
                                 default = nil)
  if valid_591460 != nil:
    section.add "X-Amz-Credential", valid_591460
  var valid_591461 = header.getOrDefault("X-Amz-Security-Token")
  valid_591461 = validateParameter(valid_591461, JString, required = false,
                                 default = nil)
  if valid_591461 != nil:
    section.add "X-Amz-Security-Token", valid_591461
  var valid_591462 = header.getOrDefault("X-Amz-Algorithm")
  valid_591462 = validateParameter(valid_591462, JString, required = false,
                                 default = nil)
  if valid_591462 != nil:
    section.add "X-Amz-Algorithm", valid_591462
  var valid_591463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591463 = validateParameter(valid_591463, JString, required = false,
                                 default = nil)
  if valid_591463 != nil:
    section.add "X-Amz-SignedHeaders", valid_591463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591465: Call_ListHandshakesForOrganization_591451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the handshakes that are associated with the organization that the requesting user is part of. The <code>ListHandshakesForOrganization</code> operation returns a list of handshake structures. Each structure contains details and status about a handshake.</p> <p>Handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> appear in the results of this API for only 30 days after changing to that state. After that, they're deleted and no longer accessible.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_591465.validator(path, query, header, formData, body)
  let scheme = call_591465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591465.url(scheme.get, call_591465.host, call_591465.base,
                         call_591465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591465, url, valid)

proc call*(call_591466: Call_ListHandshakesForOrganization_591451; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listHandshakesForOrganization
  ## <p>Lists the handshakes that are associated with the organization that the requesting user is part of. The <code>ListHandshakesForOrganization</code> operation returns a list of handshake structures. Each structure contains details and status about a handshake.</p> <p>Handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> appear in the results of this API for only 30 days after changing to that state. After that, they're deleted and no longer accessible.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591467 = newJObject()
  var body_591468 = newJObject()
  add(query_591467, "MaxResults", newJString(MaxResults))
  add(query_591467, "NextToken", newJString(NextToken))
  if body != nil:
    body_591468 = body
  result = call_591466.call(nil, query_591467, nil, nil, body_591468)

var listHandshakesForOrganization* = Call_ListHandshakesForOrganization_591451(
    name: "listHandshakesForOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListHandshakesForOrganization",
    validator: validate_ListHandshakesForOrganization_591452, base: "/",
    url: url_ListHandshakesForOrganization_591453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOrganizationalUnitsForParent_591469 = ref object of OpenApiRestCall_590365
proc url_ListOrganizationalUnitsForParent_591471(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListOrganizationalUnitsForParent_591470(path: JsonNode;
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
  var valid_591472 = query.getOrDefault("MaxResults")
  valid_591472 = validateParameter(valid_591472, JString, required = false,
                                 default = nil)
  if valid_591472 != nil:
    section.add "MaxResults", valid_591472
  var valid_591473 = query.getOrDefault("NextToken")
  valid_591473 = validateParameter(valid_591473, JString, required = false,
                                 default = nil)
  if valid_591473 != nil:
    section.add "NextToken", valid_591473
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
  var valid_591474 = header.getOrDefault("X-Amz-Target")
  valid_591474 = validateParameter(valid_591474, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListOrganizationalUnitsForParent"))
  if valid_591474 != nil:
    section.add "X-Amz-Target", valid_591474
  var valid_591475 = header.getOrDefault("X-Amz-Signature")
  valid_591475 = validateParameter(valid_591475, JString, required = false,
                                 default = nil)
  if valid_591475 != nil:
    section.add "X-Amz-Signature", valid_591475
  var valid_591476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591476 = validateParameter(valid_591476, JString, required = false,
                                 default = nil)
  if valid_591476 != nil:
    section.add "X-Amz-Content-Sha256", valid_591476
  var valid_591477 = header.getOrDefault("X-Amz-Date")
  valid_591477 = validateParameter(valid_591477, JString, required = false,
                                 default = nil)
  if valid_591477 != nil:
    section.add "X-Amz-Date", valid_591477
  var valid_591478 = header.getOrDefault("X-Amz-Credential")
  valid_591478 = validateParameter(valid_591478, JString, required = false,
                                 default = nil)
  if valid_591478 != nil:
    section.add "X-Amz-Credential", valid_591478
  var valid_591479 = header.getOrDefault("X-Amz-Security-Token")
  valid_591479 = validateParameter(valid_591479, JString, required = false,
                                 default = nil)
  if valid_591479 != nil:
    section.add "X-Amz-Security-Token", valid_591479
  var valid_591480 = header.getOrDefault("X-Amz-Algorithm")
  valid_591480 = validateParameter(valid_591480, JString, required = false,
                                 default = nil)
  if valid_591480 != nil:
    section.add "X-Amz-Algorithm", valid_591480
  var valid_591481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591481 = validateParameter(valid_591481, JString, required = false,
                                 default = nil)
  if valid_591481 != nil:
    section.add "X-Amz-SignedHeaders", valid_591481
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591483: Call_ListOrganizationalUnitsForParent_591469;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the organizational units (OUs) in a parent organizational unit or root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_591483.validator(path, query, header, formData, body)
  let scheme = call_591483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591483.url(scheme.get, call_591483.host, call_591483.base,
                         call_591483.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591483, url, valid)

proc call*(call_591484: Call_ListOrganizationalUnitsForParent_591469;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listOrganizationalUnitsForParent
  ## <p>Lists the organizational units (OUs) in a parent organizational unit or root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591485 = newJObject()
  var body_591486 = newJObject()
  add(query_591485, "MaxResults", newJString(MaxResults))
  add(query_591485, "NextToken", newJString(NextToken))
  if body != nil:
    body_591486 = body
  result = call_591484.call(nil, query_591485, nil, nil, body_591486)

var listOrganizationalUnitsForParent* = Call_ListOrganizationalUnitsForParent_591469(
    name: "listOrganizationalUnitsForParent", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListOrganizationalUnitsForParent",
    validator: validate_ListOrganizationalUnitsForParent_591470, base: "/",
    url: url_ListOrganizationalUnitsForParent_591471,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListParents_591487 = ref object of OpenApiRestCall_590365
proc url_ListParents_591489(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListParents_591488(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591490 = query.getOrDefault("MaxResults")
  valid_591490 = validateParameter(valid_591490, JString, required = false,
                                 default = nil)
  if valid_591490 != nil:
    section.add "MaxResults", valid_591490
  var valid_591491 = query.getOrDefault("NextToken")
  valid_591491 = validateParameter(valid_591491, JString, required = false,
                                 default = nil)
  if valid_591491 != nil:
    section.add "NextToken", valid_591491
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
  var valid_591492 = header.getOrDefault("X-Amz-Target")
  valid_591492 = validateParameter(valid_591492, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListParents"))
  if valid_591492 != nil:
    section.add "X-Amz-Target", valid_591492
  var valid_591493 = header.getOrDefault("X-Amz-Signature")
  valid_591493 = validateParameter(valid_591493, JString, required = false,
                                 default = nil)
  if valid_591493 != nil:
    section.add "X-Amz-Signature", valid_591493
  var valid_591494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591494 = validateParameter(valid_591494, JString, required = false,
                                 default = nil)
  if valid_591494 != nil:
    section.add "X-Amz-Content-Sha256", valid_591494
  var valid_591495 = header.getOrDefault("X-Amz-Date")
  valid_591495 = validateParameter(valid_591495, JString, required = false,
                                 default = nil)
  if valid_591495 != nil:
    section.add "X-Amz-Date", valid_591495
  var valid_591496 = header.getOrDefault("X-Amz-Credential")
  valid_591496 = validateParameter(valid_591496, JString, required = false,
                                 default = nil)
  if valid_591496 != nil:
    section.add "X-Amz-Credential", valid_591496
  var valid_591497 = header.getOrDefault("X-Amz-Security-Token")
  valid_591497 = validateParameter(valid_591497, JString, required = false,
                                 default = nil)
  if valid_591497 != nil:
    section.add "X-Amz-Security-Token", valid_591497
  var valid_591498 = header.getOrDefault("X-Amz-Algorithm")
  valid_591498 = validateParameter(valid_591498, JString, required = false,
                                 default = nil)
  if valid_591498 != nil:
    section.add "X-Amz-Algorithm", valid_591498
  var valid_591499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591499 = validateParameter(valid_591499, JString, required = false,
                                 default = nil)
  if valid_591499 != nil:
    section.add "X-Amz-SignedHeaders", valid_591499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591501: Call_ListParents_591487; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the root or organizational units (OUs) that serve as the immediate parent of the specified child OU or account. This operation, along with <a>ListChildren</a> enables you to traverse the tree structure that makes up this root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p> <note> <p>In the current release, a child can have only a single parent. </p> </note>
  ## 
  let valid = call_591501.validator(path, query, header, formData, body)
  let scheme = call_591501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591501.url(scheme.get, call_591501.host, call_591501.base,
                         call_591501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591501, url, valid)

proc call*(call_591502: Call_ListParents_591487; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listParents
  ## <p>Lists the root or organizational units (OUs) that serve as the immediate parent of the specified child OU or account. This operation, along with <a>ListChildren</a> enables you to traverse the tree structure that makes up this root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p> <note> <p>In the current release, a child can have only a single parent. </p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591503 = newJObject()
  var body_591504 = newJObject()
  add(query_591503, "MaxResults", newJString(MaxResults))
  add(query_591503, "NextToken", newJString(NextToken))
  if body != nil:
    body_591504 = body
  result = call_591502.call(nil, query_591503, nil, nil, body_591504)

var listParents* = Call_ListParents_591487(name: "listParents",
                                        meth: HttpMethod.HttpPost,
                                        host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListParents",
                                        validator: validate_ListParents_591488,
                                        base: "/", url: url_ListParents_591489,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPolicies_591505 = ref object of OpenApiRestCall_590365
proc url_ListPolicies_591507(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPolicies_591506(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591508 = query.getOrDefault("MaxResults")
  valid_591508 = validateParameter(valid_591508, JString, required = false,
                                 default = nil)
  if valid_591508 != nil:
    section.add "MaxResults", valid_591508
  var valid_591509 = query.getOrDefault("NextToken")
  valid_591509 = validateParameter(valid_591509, JString, required = false,
                                 default = nil)
  if valid_591509 != nil:
    section.add "NextToken", valid_591509
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
  var valid_591510 = header.getOrDefault("X-Amz-Target")
  valid_591510 = validateParameter(valid_591510, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListPolicies"))
  if valid_591510 != nil:
    section.add "X-Amz-Target", valid_591510
  var valid_591511 = header.getOrDefault("X-Amz-Signature")
  valid_591511 = validateParameter(valid_591511, JString, required = false,
                                 default = nil)
  if valid_591511 != nil:
    section.add "X-Amz-Signature", valid_591511
  var valid_591512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591512 = validateParameter(valid_591512, JString, required = false,
                                 default = nil)
  if valid_591512 != nil:
    section.add "X-Amz-Content-Sha256", valid_591512
  var valid_591513 = header.getOrDefault("X-Amz-Date")
  valid_591513 = validateParameter(valid_591513, JString, required = false,
                                 default = nil)
  if valid_591513 != nil:
    section.add "X-Amz-Date", valid_591513
  var valid_591514 = header.getOrDefault("X-Amz-Credential")
  valid_591514 = validateParameter(valid_591514, JString, required = false,
                                 default = nil)
  if valid_591514 != nil:
    section.add "X-Amz-Credential", valid_591514
  var valid_591515 = header.getOrDefault("X-Amz-Security-Token")
  valid_591515 = validateParameter(valid_591515, JString, required = false,
                                 default = nil)
  if valid_591515 != nil:
    section.add "X-Amz-Security-Token", valid_591515
  var valid_591516 = header.getOrDefault("X-Amz-Algorithm")
  valid_591516 = validateParameter(valid_591516, JString, required = false,
                                 default = nil)
  if valid_591516 != nil:
    section.add "X-Amz-Algorithm", valid_591516
  var valid_591517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591517 = validateParameter(valid_591517, JString, required = false,
                                 default = nil)
  if valid_591517 != nil:
    section.add "X-Amz-SignedHeaders", valid_591517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591519: Call_ListPolicies_591505; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the list of all policies in an organization of a specified type.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_591519.validator(path, query, header, formData, body)
  let scheme = call_591519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591519.url(scheme.get, call_591519.host, call_591519.base,
                         call_591519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591519, url, valid)

proc call*(call_591520: Call_ListPolicies_591505; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listPolicies
  ## <p>Retrieves the list of all policies in an organization of a specified type.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591521 = newJObject()
  var body_591522 = newJObject()
  add(query_591521, "MaxResults", newJString(MaxResults))
  add(query_591521, "NextToken", newJString(NextToken))
  if body != nil:
    body_591522 = body
  result = call_591520.call(nil, query_591521, nil, nil, body_591522)

var listPolicies* = Call_ListPolicies_591505(name: "listPolicies",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListPolicies",
    validator: validate_ListPolicies_591506, base: "/", url: url_ListPolicies_591507,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPoliciesForTarget_591523 = ref object of OpenApiRestCall_590365
proc url_ListPoliciesForTarget_591525(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPoliciesForTarget_591524(path: JsonNode; query: JsonNode;
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
  var valid_591526 = query.getOrDefault("MaxResults")
  valid_591526 = validateParameter(valid_591526, JString, required = false,
                                 default = nil)
  if valid_591526 != nil:
    section.add "MaxResults", valid_591526
  var valid_591527 = query.getOrDefault("NextToken")
  valid_591527 = validateParameter(valid_591527, JString, required = false,
                                 default = nil)
  if valid_591527 != nil:
    section.add "NextToken", valid_591527
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
  var valid_591528 = header.getOrDefault("X-Amz-Target")
  valid_591528 = validateParameter(valid_591528, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListPoliciesForTarget"))
  if valid_591528 != nil:
    section.add "X-Amz-Target", valid_591528
  var valid_591529 = header.getOrDefault("X-Amz-Signature")
  valid_591529 = validateParameter(valid_591529, JString, required = false,
                                 default = nil)
  if valid_591529 != nil:
    section.add "X-Amz-Signature", valid_591529
  var valid_591530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591530 = validateParameter(valid_591530, JString, required = false,
                                 default = nil)
  if valid_591530 != nil:
    section.add "X-Amz-Content-Sha256", valid_591530
  var valid_591531 = header.getOrDefault("X-Amz-Date")
  valid_591531 = validateParameter(valid_591531, JString, required = false,
                                 default = nil)
  if valid_591531 != nil:
    section.add "X-Amz-Date", valid_591531
  var valid_591532 = header.getOrDefault("X-Amz-Credential")
  valid_591532 = validateParameter(valid_591532, JString, required = false,
                                 default = nil)
  if valid_591532 != nil:
    section.add "X-Amz-Credential", valid_591532
  var valid_591533 = header.getOrDefault("X-Amz-Security-Token")
  valid_591533 = validateParameter(valid_591533, JString, required = false,
                                 default = nil)
  if valid_591533 != nil:
    section.add "X-Amz-Security-Token", valid_591533
  var valid_591534 = header.getOrDefault("X-Amz-Algorithm")
  valid_591534 = validateParameter(valid_591534, JString, required = false,
                                 default = nil)
  if valid_591534 != nil:
    section.add "X-Amz-Algorithm", valid_591534
  var valid_591535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591535 = validateParameter(valid_591535, JString, required = false,
                                 default = nil)
  if valid_591535 != nil:
    section.add "X-Amz-SignedHeaders", valid_591535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591537: Call_ListPoliciesForTarget_591523; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the policies that are directly attached to the specified target root, organizational unit (OU), or account. You must specify the policy type that you want included in the returned list.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_591537.validator(path, query, header, formData, body)
  let scheme = call_591537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591537.url(scheme.get, call_591537.host, call_591537.base,
                         call_591537.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591537, url, valid)

proc call*(call_591538: Call_ListPoliciesForTarget_591523; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listPoliciesForTarget
  ## <p>Lists the policies that are directly attached to the specified target root, organizational unit (OU), or account. You must specify the policy type that you want included in the returned list.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591539 = newJObject()
  var body_591540 = newJObject()
  add(query_591539, "MaxResults", newJString(MaxResults))
  add(query_591539, "NextToken", newJString(NextToken))
  if body != nil:
    body_591540 = body
  result = call_591538.call(nil, query_591539, nil, nil, body_591540)

var listPoliciesForTarget* = Call_ListPoliciesForTarget_591523(
    name: "listPoliciesForTarget", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListPoliciesForTarget",
    validator: validate_ListPoliciesForTarget_591524, base: "/",
    url: url_ListPoliciesForTarget_591525, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoots_591541 = ref object of OpenApiRestCall_590365
proc url_ListRoots_591543(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListRoots_591542(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591544 = query.getOrDefault("MaxResults")
  valid_591544 = validateParameter(valid_591544, JString, required = false,
                                 default = nil)
  if valid_591544 != nil:
    section.add "MaxResults", valid_591544
  var valid_591545 = query.getOrDefault("NextToken")
  valid_591545 = validateParameter(valid_591545, JString, required = false,
                                 default = nil)
  if valid_591545 != nil:
    section.add "NextToken", valid_591545
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
  var valid_591546 = header.getOrDefault("X-Amz-Target")
  valid_591546 = validateParameter(valid_591546, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListRoots"))
  if valid_591546 != nil:
    section.add "X-Amz-Target", valid_591546
  var valid_591547 = header.getOrDefault("X-Amz-Signature")
  valid_591547 = validateParameter(valid_591547, JString, required = false,
                                 default = nil)
  if valid_591547 != nil:
    section.add "X-Amz-Signature", valid_591547
  var valid_591548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591548 = validateParameter(valid_591548, JString, required = false,
                                 default = nil)
  if valid_591548 != nil:
    section.add "X-Amz-Content-Sha256", valid_591548
  var valid_591549 = header.getOrDefault("X-Amz-Date")
  valid_591549 = validateParameter(valid_591549, JString, required = false,
                                 default = nil)
  if valid_591549 != nil:
    section.add "X-Amz-Date", valid_591549
  var valid_591550 = header.getOrDefault("X-Amz-Credential")
  valid_591550 = validateParameter(valid_591550, JString, required = false,
                                 default = nil)
  if valid_591550 != nil:
    section.add "X-Amz-Credential", valid_591550
  var valid_591551 = header.getOrDefault("X-Amz-Security-Token")
  valid_591551 = validateParameter(valid_591551, JString, required = false,
                                 default = nil)
  if valid_591551 != nil:
    section.add "X-Amz-Security-Token", valid_591551
  var valid_591552 = header.getOrDefault("X-Amz-Algorithm")
  valid_591552 = validateParameter(valid_591552, JString, required = false,
                                 default = nil)
  if valid_591552 != nil:
    section.add "X-Amz-Algorithm", valid_591552
  var valid_591553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591553 = validateParameter(valid_591553, JString, required = false,
                                 default = nil)
  if valid_591553 != nil:
    section.add "X-Amz-SignedHeaders", valid_591553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591555: Call_ListRoots_591541; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the roots that are defined in the current organization.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p> <note> <p>Policy types can be enabled and disabled in roots. This is distinct from whether they're available in the organization. When you enable all features, you make policy types available for use in that organization. Individual policy types can then be enabled and disabled in a root. To see the availability of a policy type in an organization, use <a>DescribeOrganization</a>.</p> </note>
  ## 
  let valid = call_591555.validator(path, query, header, formData, body)
  let scheme = call_591555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591555.url(scheme.get, call_591555.host, call_591555.base,
                         call_591555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591555, url, valid)

proc call*(call_591556: Call_ListRoots_591541; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listRoots
  ## <p>Lists the roots that are defined in the current organization.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p> <note> <p>Policy types can be enabled and disabled in roots. This is distinct from whether they're available in the organization. When you enable all features, you make policy types available for use in that organization. Individual policy types can then be enabled and disabled in a root. To see the availability of a policy type in an organization, use <a>DescribeOrganization</a>.</p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591557 = newJObject()
  var body_591558 = newJObject()
  add(query_591557, "MaxResults", newJString(MaxResults))
  add(query_591557, "NextToken", newJString(NextToken))
  if body != nil:
    body_591558 = body
  result = call_591556.call(nil, query_591557, nil, nil, body_591558)

var listRoots* = Call_ListRoots_591541(name: "listRoots", meth: HttpMethod.HttpPost,
                                    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListRoots",
                                    validator: validate_ListRoots_591542,
                                    base: "/", url: url_ListRoots_591543,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_591559 = ref object of OpenApiRestCall_590365
proc url_ListTagsForResource_591561(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_591560(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Lists tags for the specified resource. </p> <p>Currently, you can list tags on an account in AWS Organizations.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_591562 = query.getOrDefault("NextToken")
  valid_591562 = validateParameter(valid_591562, JString, required = false,
                                 default = nil)
  if valid_591562 != nil:
    section.add "NextToken", valid_591562
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
  var valid_591563 = header.getOrDefault("X-Amz-Target")
  valid_591563 = validateParameter(valid_591563, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListTagsForResource"))
  if valid_591563 != nil:
    section.add "X-Amz-Target", valid_591563
  var valid_591564 = header.getOrDefault("X-Amz-Signature")
  valid_591564 = validateParameter(valid_591564, JString, required = false,
                                 default = nil)
  if valid_591564 != nil:
    section.add "X-Amz-Signature", valid_591564
  var valid_591565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591565 = validateParameter(valid_591565, JString, required = false,
                                 default = nil)
  if valid_591565 != nil:
    section.add "X-Amz-Content-Sha256", valid_591565
  var valid_591566 = header.getOrDefault("X-Amz-Date")
  valid_591566 = validateParameter(valid_591566, JString, required = false,
                                 default = nil)
  if valid_591566 != nil:
    section.add "X-Amz-Date", valid_591566
  var valid_591567 = header.getOrDefault("X-Amz-Credential")
  valid_591567 = validateParameter(valid_591567, JString, required = false,
                                 default = nil)
  if valid_591567 != nil:
    section.add "X-Amz-Credential", valid_591567
  var valid_591568 = header.getOrDefault("X-Amz-Security-Token")
  valid_591568 = validateParameter(valid_591568, JString, required = false,
                                 default = nil)
  if valid_591568 != nil:
    section.add "X-Amz-Security-Token", valid_591568
  var valid_591569 = header.getOrDefault("X-Amz-Algorithm")
  valid_591569 = validateParameter(valid_591569, JString, required = false,
                                 default = nil)
  if valid_591569 != nil:
    section.add "X-Amz-Algorithm", valid_591569
  var valid_591570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591570 = validateParameter(valid_591570, JString, required = false,
                                 default = nil)
  if valid_591570 != nil:
    section.add "X-Amz-SignedHeaders", valid_591570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591572: Call_ListTagsForResource_591559; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists tags for the specified resource. </p> <p>Currently, you can list tags on an account in AWS Organizations.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_591572.validator(path, query, header, formData, body)
  let scheme = call_591572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591572.url(scheme.get, call_591572.host, call_591572.base,
                         call_591572.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591572, url, valid)

proc call*(call_591573: Call_ListTagsForResource_591559; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## listTagsForResource
  ## <p>Lists tags for the specified resource. </p> <p>Currently, you can list tags on an account in AWS Organizations.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591574 = newJObject()
  var body_591575 = newJObject()
  add(query_591574, "NextToken", newJString(NextToken))
  if body != nil:
    body_591575 = body
  result = call_591573.call(nil, query_591574, nil, nil, body_591575)

var listTagsForResource* = Call_ListTagsForResource_591559(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListTagsForResource",
    validator: validate_ListTagsForResource_591560, base: "/",
    url: url_ListTagsForResource_591561, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTargetsForPolicy_591576 = ref object of OpenApiRestCall_590365
proc url_ListTargetsForPolicy_591578(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTargetsForPolicy_591577(path: JsonNode; query: JsonNode;
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
  var valid_591579 = query.getOrDefault("MaxResults")
  valid_591579 = validateParameter(valid_591579, JString, required = false,
                                 default = nil)
  if valid_591579 != nil:
    section.add "MaxResults", valid_591579
  var valid_591580 = query.getOrDefault("NextToken")
  valid_591580 = validateParameter(valid_591580, JString, required = false,
                                 default = nil)
  if valid_591580 != nil:
    section.add "NextToken", valid_591580
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
  var valid_591581 = header.getOrDefault("X-Amz-Target")
  valid_591581 = validateParameter(valid_591581, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListTargetsForPolicy"))
  if valid_591581 != nil:
    section.add "X-Amz-Target", valid_591581
  var valid_591582 = header.getOrDefault("X-Amz-Signature")
  valid_591582 = validateParameter(valid_591582, JString, required = false,
                                 default = nil)
  if valid_591582 != nil:
    section.add "X-Amz-Signature", valid_591582
  var valid_591583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591583 = validateParameter(valid_591583, JString, required = false,
                                 default = nil)
  if valid_591583 != nil:
    section.add "X-Amz-Content-Sha256", valid_591583
  var valid_591584 = header.getOrDefault("X-Amz-Date")
  valid_591584 = validateParameter(valid_591584, JString, required = false,
                                 default = nil)
  if valid_591584 != nil:
    section.add "X-Amz-Date", valid_591584
  var valid_591585 = header.getOrDefault("X-Amz-Credential")
  valid_591585 = validateParameter(valid_591585, JString, required = false,
                                 default = nil)
  if valid_591585 != nil:
    section.add "X-Amz-Credential", valid_591585
  var valid_591586 = header.getOrDefault("X-Amz-Security-Token")
  valid_591586 = validateParameter(valid_591586, JString, required = false,
                                 default = nil)
  if valid_591586 != nil:
    section.add "X-Amz-Security-Token", valid_591586
  var valid_591587 = header.getOrDefault("X-Amz-Algorithm")
  valid_591587 = validateParameter(valid_591587, JString, required = false,
                                 default = nil)
  if valid_591587 != nil:
    section.add "X-Amz-Algorithm", valid_591587
  var valid_591588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591588 = validateParameter(valid_591588, JString, required = false,
                                 default = nil)
  if valid_591588 != nil:
    section.add "X-Amz-SignedHeaders", valid_591588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591590: Call_ListTargetsForPolicy_591576; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all the roots, organizational units (OUs), and accounts that the specified policy is attached to.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_591590.validator(path, query, header, formData, body)
  let scheme = call_591590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591590.url(scheme.get, call_591590.host, call_591590.base,
                         call_591590.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591590, url, valid)

proc call*(call_591591: Call_ListTargetsForPolicy_591576; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTargetsForPolicy
  ## <p>Lists all the roots, organizational units (OUs), and accounts that the specified policy is attached to.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591592 = newJObject()
  var body_591593 = newJObject()
  add(query_591592, "MaxResults", newJString(MaxResults))
  add(query_591592, "NextToken", newJString(NextToken))
  if body != nil:
    body_591593 = body
  result = call_591591.call(nil, query_591592, nil, nil, body_591593)

var listTargetsForPolicy* = Call_ListTargetsForPolicy_591576(
    name: "listTargetsForPolicy", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListTargetsForPolicy",
    validator: validate_ListTargetsForPolicy_591577, base: "/",
    url: url_ListTargetsForPolicy_591578, schemes: {Scheme.Https, Scheme.Http})
type
  Call_MoveAccount_591594 = ref object of OpenApiRestCall_590365
proc url_MoveAccount_591596(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_MoveAccount_591595(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591597 = header.getOrDefault("X-Amz-Target")
  valid_591597 = validateParameter(valid_591597, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.MoveAccount"))
  if valid_591597 != nil:
    section.add "X-Amz-Target", valid_591597
  var valid_591598 = header.getOrDefault("X-Amz-Signature")
  valid_591598 = validateParameter(valid_591598, JString, required = false,
                                 default = nil)
  if valid_591598 != nil:
    section.add "X-Amz-Signature", valid_591598
  var valid_591599 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591599 = validateParameter(valid_591599, JString, required = false,
                                 default = nil)
  if valid_591599 != nil:
    section.add "X-Amz-Content-Sha256", valid_591599
  var valid_591600 = header.getOrDefault("X-Amz-Date")
  valid_591600 = validateParameter(valid_591600, JString, required = false,
                                 default = nil)
  if valid_591600 != nil:
    section.add "X-Amz-Date", valid_591600
  var valid_591601 = header.getOrDefault("X-Amz-Credential")
  valid_591601 = validateParameter(valid_591601, JString, required = false,
                                 default = nil)
  if valid_591601 != nil:
    section.add "X-Amz-Credential", valid_591601
  var valid_591602 = header.getOrDefault("X-Amz-Security-Token")
  valid_591602 = validateParameter(valid_591602, JString, required = false,
                                 default = nil)
  if valid_591602 != nil:
    section.add "X-Amz-Security-Token", valid_591602
  var valid_591603 = header.getOrDefault("X-Amz-Algorithm")
  valid_591603 = validateParameter(valid_591603, JString, required = false,
                                 default = nil)
  if valid_591603 != nil:
    section.add "X-Amz-Algorithm", valid_591603
  var valid_591604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591604 = validateParameter(valid_591604, JString, required = false,
                                 default = nil)
  if valid_591604 != nil:
    section.add "X-Amz-SignedHeaders", valid_591604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591606: Call_MoveAccount_591594; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Moves an account from its current source parent root or organizational unit (OU) to the specified destination parent root or OU.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_591606.validator(path, query, header, formData, body)
  let scheme = call_591606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591606.url(scheme.get, call_591606.host, call_591606.base,
                         call_591606.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591606, url, valid)

proc call*(call_591607: Call_MoveAccount_591594; body: JsonNode): Recallable =
  ## moveAccount
  ## <p>Moves an account from its current source parent root or organizational unit (OU) to the specified destination parent root or OU.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_591608 = newJObject()
  if body != nil:
    body_591608 = body
  result = call_591607.call(nil, nil, nil, nil, body_591608)

var moveAccount* = Call_MoveAccount_591594(name: "moveAccount",
                                        meth: HttpMethod.HttpPost,
                                        host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.MoveAccount",
                                        validator: validate_MoveAccount_591595,
                                        base: "/", url: url_MoveAccount_591596,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAccountFromOrganization_591609 = ref object of OpenApiRestCall_590365
proc url_RemoveAccountFromOrganization_591611(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RemoveAccountFromOrganization_591610(path: JsonNode; query: JsonNode;
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
  var valid_591612 = header.getOrDefault("X-Amz-Target")
  valid_591612 = validateParameter(valid_591612, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.RemoveAccountFromOrganization"))
  if valid_591612 != nil:
    section.add "X-Amz-Target", valid_591612
  var valid_591613 = header.getOrDefault("X-Amz-Signature")
  valid_591613 = validateParameter(valid_591613, JString, required = false,
                                 default = nil)
  if valid_591613 != nil:
    section.add "X-Amz-Signature", valid_591613
  var valid_591614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591614 = validateParameter(valid_591614, JString, required = false,
                                 default = nil)
  if valid_591614 != nil:
    section.add "X-Amz-Content-Sha256", valid_591614
  var valid_591615 = header.getOrDefault("X-Amz-Date")
  valid_591615 = validateParameter(valid_591615, JString, required = false,
                                 default = nil)
  if valid_591615 != nil:
    section.add "X-Amz-Date", valid_591615
  var valid_591616 = header.getOrDefault("X-Amz-Credential")
  valid_591616 = validateParameter(valid_591616, JString, required = false,
                                 default = nil)
  if valid_591616 != nil:
    section.add "X-Amz-Credential", valid_591616
  var valid_591617 = header.getOrDefault("X-Amz-Security-Token")
  valid_591617 = validateParameter(valid_591617, JString, required = false,
                                 default = nil)
  if valid_591617 != nil:
    section.add "X-Amz-Security-Token", valid_591617
  var valid_591618 = header.getOrDefault("X-Amz-Algorithm")
  valid_591618 = validateParameter(valid_591618, JString, required = false,
                                 default = nil)
  if valid_591618 != nil:
    section.add "X-Amz-Algorithm", valid_591618
  var valid_591619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591619 = validateParameter(valid_591619, JString, required = false,
                                 default = nil)
  if valid_591619 != nil:
    section.add "X-Amz-SignedHeaders", valid_591619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591621: Call_RemoveAccountFromOrganization_591609; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified account from the organization.</p> <p>The removed account becomes a standalone account that isn't a member of any organization. It's no longer subject to any policies and is responsible for its own bill payments. The organization's master account is no longer charged for any expenses accrued by the member account after it's removed from the organization.</p> <p>This operation can be called only from the organization's master account. Member accounts can remove themselves with <a>LeaveOrganization</a> instead.</p> <important> <p>You can remove an account from your organization only if the account is configured with the information required to operate as a standalone account. When you create an account in an organization using the AWS Organizations console, API, or CLI commands, the information required of standalone accounts is <i>not</i> automatically collected. For an account that you want to make standalone, you must accept the end user license agreement (EULA), choose a support plan, provide and verify the required contact information, and provide a current payment method. AWS uses the payment method to charge for any billable (not free tier) AWS activity that occurs while the account isn't attached to an organization. To remove an account that doesn't yet have this information, you must sign in as the member account and follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization when all required account information has not yet been provided</a> in the <i>AWS Organizations User Guide.</i> </p> </important>
  ## 
  let valid = call_591621.validator(path, query, header, formData, body)
  let scheme = call_591621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591621.url(scheme.get, call_591621.host, call_591621.base,
                         call_591621.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591621, url, valid)

proc call*(call_591622: Call_RemoveAccountFromOrganization_591609; body: JsonNode): Recallable =
  ## removeAccountFromOrganization
  ## <p>Removes the specified account from the organization.</p> <p>The removed account becomes a standalone account that isn't a member of any organization. It's no longer subject to any policies and is responsible for its own bill payments. The organization's master account is no longer charged for any expenses accrued by the member account after it's removed from the organization.</p> <p>This operation can be called only from the organization's master account. Member accounts can remove themselves with <a>LeaveOrganization</a> instead.</p> <important> <p>You can remove an account from your organization only if the account is configured with the information required to operate as a standalone account. When you create an account in an organization using the AWS Organizations console, API, or CLI commands, the information required of standalone accounts is <i>not</i> automatically collected. For an account that you want to make standalone, you must accept the end user license agreement (EULA), choose a support plan, provide and verify the required contact information, and provide a current payment method. AWS uses the payment method to charge for any billable (not free tier) AWS activity that occurs while the account isn't attached to an organization. To remove an account that doesn't yet have this information, you must sign in as the member account and follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization when all required account information has not yet been provided</a> in the <i>AWS Organizations User Guide.</i> </p> </important>
  ##   body: JObject (required)
  var body_591623 = newJObject()
  if body != nil:
    body_591623 = body
  result = call_591622.call(nil, nil, nil, nil, body_591623)

var removeAccountFromOrganization* = Call_RemoveAccountFromOrganization_591609(
    name: "removeAccountFromOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.RemoveAccountFromOrganization",
    validator: validate_RemoveAccountFromOrganization_591610, base: "/",
    url: url_RemoveAccountFromOrganization_591611,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_591624 = ref object of OpenApiRestCall_590365
proc url_TagResource_591626(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_591625(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds one or more tags to the specified resource.</p> <p>Currently, you can tag and untag accounts in AWS Organizations.</p> <p>This operation can be called only from the organization's master account.</p>
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
  var valid_591627 = header.getOrDefault("X-Amz-Target")
  valid_591627 = validateParameter(valid_591627, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.TagResource"))
  if valid_591627 != nil:
    section.add "X-Amz-Target", valid_591627
  var valid_591628 = header.getOrDefault("X-Amz-Signature")
  valid_591628 = validateParameter(valid_591628, JString, required = false,
                                 default = nil)
  if valid_591628 != nil:
    section.add "X-Amz-Signature", valid_591628
  var valid_591629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591629 = validateParameter(valid_591629, JString, required = false,
                                 default = nil)
  if valid_591629 != nil:
    section.add "X-Amz-Content-Sha256", valid_591629
  var valid_591630 = header.getOrDefault("X-Amz-Date")
  valid_591630 = validateParameter(valid_591630, JString, required = false,
                                 default = nil)
  if valid_591630 != nil:
    section.add "X-Amz-Date", valid_591630
  var valid_591631 = header.getOrDefault("X-Amz-Credential")
  valid_591631 = validateParameter(valid_591631, JString, required = false,
                                 default = nil)
  if valid_591631 != nil:
    section.add "X-Amz-Credential", valid_591631
  var valid_591632 = header.getOrDefault("X-Amz-Security-Token")
  valid_591632 = validateParameter(valid_591632, JString, required = false,
                                 default = nil)
  if valid_591632 != nil:
    section.add "X-Amz-Security-Token", valid_591632
  var valid_591633 = header.getOrDefault("X-Amz-Algorithm")
  valid_591633 = validateParameter(valid_591633, JString, required = false,
                                 default = nil)
  if valid_591633 != nil:
    section.add "X-Amz-Algorithm", valid_591633
  var valid_591634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591634 = validateParameter(valid_591634, JString, required = false,
                                 default = nil)
  if valid_591634 != nil:
    section.add "X-Amz-SignedHeaders", valid_591634
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591636: Call_TagResource_591624; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more tags to the specified resource.</p> <p>Currently, you can tag and untag accounts in AWS Organizations.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_591636.validator(path, query, header, formData, body)
  let scheme = call_591636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591636.url(scheme.get, call_591636.host, call_591636.base,
                         call_591636.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591636, url, valid)

proc call*(call_591637: Call_TagResource_591624; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds one or more tags to the specified resource.</p> <p>Currently, you can tag and untag accounts in AWS Organizations.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_591638 = newJObject()
  if body != nil:
    body_591638 = body
  result = call_591637.call(nil, nil, nil, nil, body_591638)

var tagResource* = Call_TagResource_591624(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.TagResource",
                                        validator: validate_TagResource_591625,
                                        base: "/", url: url_TagResource_591626,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_591639 = ref object of OpenApiRestCall_590365
proc url_UntagResource_591641(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_591640(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes a tag from the specified resource. </p> <p>Currently, you can tag and untag accounts in AWS Organizations.</p> <p>This operation can be called only from the organization's master account.</p>
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
  var valid_591642 = header.getOrDefault("X-Amz-Target")
  valid_591642 = validateParameter(valid_591642, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.UntagResource"))
  if valid_591642 != nil:
    section.add "X-Amz-Target", valid_591642
  var valid_591643 = header.getOrDefault("X-Amz-Signature")
  valid_591643 = validateParameter(valid_591643, JString, required = false,
                                 default = nil)
  if valid_591643 != nil:
    section.add "X-Amz-Signature", valid_591643
  var valid_591644 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591644 = validateParameter(valid_591644, JString, required = false,
                                 default = nil)
  if valid_591644 != nil:
    section.add "X-Amz-Content-Sha256", valid_591644
  var valid_591645 = header.getOrDefault("X-Amz-Date")
  valid_591645 = validateParameter(valid_591645, JString, required = false,
                                 default = nil)
  if valid_591645 != nil:
    section.add "X-Amz-Date", valid_591645
  var valid_591646 = header.getOrDefault("X-Amz-Credential")
  valid_591646 = validateParameter(valid_591646, JString, required = false,
                                 default = nil)
  if valid_591646 != nil:
    section.add "X-Amz-Credential", valid_591646
  var valid_591647 = header.getOrDefault("X-Amz-Security-Token")
  valid_591647 = validateParameter(valid_591647, JString, required = false,
                                 default = nil)
  if valid_591647 != nil:
    section.add "X-Amz-Security-Token", valid_591647
  var valid_591648 = header.getOrDefault("X-Amz-Algorithm")
  valid_591648 = validateParameter(valid_591648, JString, required = false,
                                 default = nil)
  if valid_591648 != nil:
    section.add "X-Amz-Algorithm", valid_591648
  var valid_591649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591649 = validateParameter(valid_591649, JString, required = false,
                                 default = nil)
  if valid_591649 != nil:
    section.add "X-Amz-SignedHeaders", valid_591649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591651: Call_UntagResource_591639; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a tag from the specified resource. </p> <p>Currently, you can tag and untag accounts in AWS Organizations.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_591651.validator(path, query, header, formData, body)
  let scheme = call_591651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591651.url(scheme.get, call_591651.host, call_591651.base,
                         call_591651.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591651, url, valid)

proc call*(call_591652: Call_UntagResource_591639; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Removes a tag from the specified resource. </p> <p>Currently, you can tag and untag accounts in AWS Organizations.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_591653 = newJObject()
  if body != nil:
    body_591653 = body
  result = call_591652.call(nil, nil, nil, nil, body_591653)

var untagResource* = Call_UntagResource_591639(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.UntagResource",
    validator: validate_UntagResource_591640, base: "/", url: url_UntagResource_591641,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateOrganizationalUnit_591654 = ref object of OpenApiRestCall_590365
proc url_UpdateOrganizationalUnit_591656(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateOrganizationalUnit_591655(path: JsonNode; query: JsonNode;
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
  var valid_591657 = header.getOrDefault("X-Amz-Target")
  valid_591657 = validateParameter(valid_591657, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.UpdateOrganizationalUnit"))
  if valid_591657 != nil:
    section.add "X-Amz-Target", valid_591657
  var valid_591658 = header.getOrDefault("X-Amz-Signature")
  valid_591658 = validateParameter(valid_591658, JString, required = false,
                                 default = nil)
  if valid_591658 != nil:
    section.add "X-Amz-Signature", valid_591658
  var valid_591659 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591659 = validateParameter(valid_591659, JString, required = false,
                                 default = nil)
  if valid_591659 != nil:
    section.add "X-Amz-Content-Sha256", valid_591659
  var valid_591660 = header.getOrDefault("X-Amz-Date")
  valid_591660 = validateParameter(valid_591660, JString, required = false,
                                 default = nil)
  if valid_591660 != nil:
    section.add "X-Amz-Date", valid_591660
  var valid_591661 = header.getOrDefault("X-Amz-Credential")
  valid_591661 = validateParameter(valid_591661, JString, required = false,
                                 default = nil)
  if valid_591661 != nil:
    section.add "X-Amz-Credential", valid_591661
  var valid_591662 = header.getOrDefault("X-Amz-Security-Token")
  valid_591662 = validateParameter(valid_591662, JString, required = false,
                                 default = nil)
  if valid_591662 != nil:
    section.add "X-Amz-Security-Token", valid_591662
  var valid_591663 = header.getOrDefault("X-Amz-Algorithm")
  valid_591663 = validateParameter(valid_591663, JString, required = false,
                                 default = nil)
  if valid_591663 != nil:
    section.add "X-Amz-Algorithm", valid_591663
  var valid_591664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591664 = validateParameter(valid_591664, JString, required = false,
                                 default = nil)
  if valid_591664 != nil:
    section.add "X-Amz-SignedHeaders", valid_591664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591666: Call_UpdateOrganizationalUnit_591654; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Renames the specified organizational unit (OU). The ID and ARN don't change. The child OUs and accounts remain in place, and any attached policies of the OU remain attached. </p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_591666.validator(path, query, header, formData, body)
  let scheme = call_591666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591666.url(scheme.get, call_591666.host, call_591666.base,
                         call_591666.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591666, url, valid)

proc call*(call_591667: Call_UpdateOrganizationalUnit_591654; body: JsonNode): Recallable =
  ## updateOrganizationalUnit
  ## <p>Renames the specified organizational unit (OU). The ID and ARN don't change. The child OUs and accounts remain in place, and any attached policies of the OU remain attached. </p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_591668 = newJObject()
  if body != nil:
    body_591668 = body
  result = call_591667.call(nil, nil, nil, nil, body_591668)

var updateOrganizationalUnit* = Call_UpdateOrganizationalUnit_591654(
    name: "updateOrganizationalUnit", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.UpdateOrganizationalUnit",
    validator: validate_UpdateOrganizationalUnit_591655, base: "/",
    url: url_UpdateOrganizationalUnit_591656, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePolicy_591669 = ref object of OpenApiRestCall_590365
proc url_UpdatePolicy_591671(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdatePolicy_591670(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591672 = header.getOrDefault("X-Amz-Target")
  valid_591672 = validateParameter(valid_591672, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.UpdatePolicy"))
  if valid_591672 != nil:
    section.add "X-Amz-Target", valid_591672
  var valid_591673 = header.getOrDefault("X-Amz-Signature")
  valid_591673 = validateParameter(valid_591673, JString, required = false,
                                 default = nil)
  if valid_591673 != nil:
    section.add "X-Amz-Signature", valid_591673
  var valid_591674 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591674 = validateParameter(valid_591674, JString, required = false,
                                 default = nil)
  if valid_591674 != nil:
    section.add "X-Amz-Content-Sha256", valid_591674
  var valid_591675 = header.getOrDefault("X-Amz-Date")
  valid_591675 = validateParameter(valid_591675, JString, required = false,
                                 default = nil)
  if valid_591675 != nil:
    section.add "X-Amz-Date", valid_591675
  var valid_591676 = header.getOrDefault("X-Amz-Credential")
  valid_591676 = validateParameter(valid_591676, JString, required = false,
                                 default = nil)
  if valid_591676 != nil:
    section.add "X-Amz-Credential", valid_591676
  var valid_591677 = header.getOrDefault("X-Amz-Security-Token")
  valid_591677 = validateParameter(valid_591677, JString, required = false,
                                 default = nil)
  if valid_591677 != nil:
    section.add "X-Amz-Security-Token", valid_591677
  var valid_591678 = header.getOrDefault("X-Amz-Algorithm")
  valid_591678 = validateParameter(valid_591678, JString, required = false,
                                 default = nil)
  if valid_591678 != nil:
    section.add "X-Amz-Algorithm", valid_591678
  var valid_591679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591679 = validateParameter(valid_591679, JString, required = false,
                                 default = nil)
  if valid_591679 != nil:
    section.add "X-Amz-SignedHeaders", valid_591679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591681: Call_UpdatePolicy_591669; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing policy with a new name, description, or content. If you don't supply any parameter, that value remains unchanged. You can't change a policy's type.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_591681.validator(path, query, header, formData, body)
  let scheme = call_591681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591681.url(scheme.get, call_591681.host, call_591681.base,
                         call_591681.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591681, url, valid)

proc call*(call_591682: Call_UpdatePolicy_591669; body: JsonNode): Recallable =
  ## updatePolicy
  ## <p>Updates an existing policy with a new name, description, or content. If you don't supply any parameter, that value remains unchanged. You can't change a policy's type.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_591683 = newJObject()
  if body != nil:
    body_591683 = body
  result = call_591682.call(nil, nil, nil, nil, body_591683)

var updatePolicy* = Call_UpdatePolicy_591669(name: "updatePolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.UpdatePolicy",
    validator: validate_UpdatePolicy_591670, base: "/", url: url_UpdatePolicy_591671,
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
