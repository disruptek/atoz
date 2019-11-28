
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_599369 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599369](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599369): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AcceptHandshake_599706 = ref object of OpenApiRestCall_599369
proc url_AcceptHandshake_599708(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AcceptHandshake_599707(path: JsonNode; query: JsonNode;
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
  var valid_599820 = header.getOrDefault("X-Amz-Date")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "X-Amz-Date", valid_599820
  var valid_599821 = header.getOrDefault("X-Amz-Security-Token")
  valid_599821 = validateParameter(valid_599821, JString, required = false,
                                 default = nil)
  if valid_599821 != nil:
    section.add "X-Amz-Security-Token", valid_599821
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599835 = header.getOrDefault("X-Amz-Target")
  valid_599835 = validateParameter(valid_599835, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.AcceptHandshake"))
  if valid_599835 != nil:
    section.add "X-Amz-Target", valid_599835
  var valid_599836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Content-Sha256", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Algorithm")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Algorithm", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-Signature")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-Signature", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-SignedHeaders", valid_599839
  var valid_599840 = header.getOrDefault("X-Amz-Credential")
  valid_599840 = validateParameter(valid_599840, JString, required = false,
                                 default = nil)
  if valid_599840 != nil:
    section.add "X-Amz-Credential", valid_599840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599864: Call_AcceptHandshake_599706; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends a response to the originator of a handshake agreeing to the action proposed by the handshake request. </p> <p>This operation can be called only by the following principals when they also have the relevant IAM permissions:</p> <ul> <li> <p> <b>Invitation to join</b> or <b>Approve all features request</b> handshakes: only a principal from the member account. </p> <p>The user who calls the API for an invitation to join must have the <code>organizations:AcceptHandshake</code> permission. If you enabled all features in the organization, the user must also have the <code>iam:CreateServiceLinkedRole</code> permission so that AWS Organizations can create the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integration_services.html#orgs_integration_service-linked-roles">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide</i>.</p> </li> <li> <p> <b>Enable all features final confirmation</b> handshake: only a principal from the master account.</p> <p>For more information about invitations, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_invites.html">Inviting an AWS Account to Join Your Organization</a> in the <i>AWS Organizations User Guide.</i> For more information about requests to enable all features in the organization, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">Enabling All Features in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>After you accept a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
  ## 
  let valid = call_599864.validator(path, query, header, formData, body)
  let scheme = call_599864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599864.url(scheme.get, call_599864.host, call_599864.base,
                         call_599864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599864, url, valid)

proc call*(call_599935: Call_AcceptHandshake_599706; body: JsonNode): Recallable =
  ## acceptHandshake
  ## <p>Sends a response to the originator of a handshake agreeing to the action proposed by the handshake request. </p> <p>This operation can be called only by the following principals when they also have the relevant IAM permissions:</p> <ul> <li> <p> <b>Invitation to join</b> or <b>Approve all features request</b> handshakes: only a principal from the member account. </p> <p>The user who calls the API for an invitation to join must have the <code>organizations:AcceptHandshake</code> permission. If you enabled all features in the organization, the user must also have the <code>iam:CreateServiceLinkedRole</code> permission so that AWS Organizations can create the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integration_services.html#orgs_integration_service-linked-roles">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide</i>.</p> </li> <li> <p> <b>Enable all features final confirmation</b> handshake: only a principal from the master account.</p> <p>For more information about invitations, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_invites.html">Inviting an AWS Account to Join Your Organization</a> in the <i>AWS Organizations User Guide.</i> For more information about requests to enable all features in the organization, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">Enabling All Features in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>After you accept a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
  ##   body: JObject (required)
  var body_599936 = newJObject()
  if body != nil:
    body_599936 = body
  result = call_599935.call(nil, nil, nil, nil, body_599936)

var acceptHandshake* = Call_AcceptHandshake_599706(name: "acceptHandshake",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.AcceptHandshake",
    validator: validate_AcceptHandshake_599707, base: "/", url: url_AcceptHandshake_599708,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachPolicy_599975 = ref object of OpenApiRestCall_599369
proc url_AttachPolicy_599977(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AttachPolicy_599976(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Attaches a policy to a root, an organizational unit (OU), or an individual account.</p> <p>How the policy affects accounts depends on the type of policy:</p> <ul> <li> <p>For more information about attaching SCPs, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html">How SCPs Work</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>For information about attaching tag policies, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies-inheritance.html">How Policy Inheritance Works</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>This operation can be called only from the organization's master account.</p>
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
  var valid_599978 = header.getOrDefault("X-Amz-Date")
  valid_599978 = validateParameter(valid_599978, JString, required = false,
                                 default = nil)
  if valid_599978 != nil:
    section.add "X-Amz-Date", valid_599978
  var valid_599979 = header.getOrDefault("X-Amz-Security-Token")
  valid_599979 = validateParameter(valid_599979, JString, required = false,
                                 default = nil)
  if valid_599979 != nil:
    section.add "X-Amz-Security-Token", valid_599979
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599980 = header.getOrDefault("X-Amz-Target")
  valid_599980 = validateParameter(valid_599980, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.AttachPolicy"))
  if valid_599980 != nil:
    section.add "X-Amz-Target", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Content-Sha256", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Algorithm")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Algorithm", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-Signature")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Signature", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-SignedHeaders", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-Credential")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Credential", valid_599985
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599987: Call_AttachPolicy_599975; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches a policy to a root, an organizational unit (OU), or an individual account.</p> <p>How the policy affects accounts depends on the type of policy:</p> <ul> <li> <p>For more information about attaching SCPs, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html">How SCPs Work</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>For information about attaching tag policies, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies-inheritance.html">How Policy Inheritance Works</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_599987.validator(path, query, header, formData, body)
  let scheme = call_599987.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599987.url(scheme.get, call_599987.host, call_599987.base,
                         call_599987.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599987, url, valid)

proc call*(call_599988: Call_AttachPolicy_599975; body: JsonNode): Recallable =
  ## attachPolicy
  ## <p>Attaches a policy to a root, an organizational unit (OU), or an individual account.</p> <p>How the policy affects accounts depends on the type of policy:</p> <ul> <li> <p>For more information about attaching SCPs, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html">How SCPs Work</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>For information about attaching tag policies, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies-inheritance.html">How Policy Inheritance Works</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_599989 = newJObject()
  if body != nil:
    body_599989 = body
  result = call_599988.call(nil, nil, nil, nil, body_599989)

var attachPolicy* = Call_AttachPolicy_599975(name: "attachPolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.AttachPolicy",
    validator: validate_AttachPolicy_599976, base: "/", url: url_AttachPolicy_599977,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelHandshake_599990 = ref object of OpenApiRestCall_599369
proc url_CancelHandshake_599992(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelHandshake_599991(path: JsonNode; query: JsonNode;
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
  var valid_599993 = header.getOrDefault("X-Amz-Date")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Date", valid_599993
  var valid_599994 = header.getOrDefault("X-Amz-Security-Token")
  valid_599994 = validateParameter(valid_599994, JString, required = false,
                                 default = nil)
  if valid_599994 != nil:
    section.add "X-Amz-Security-Token", valid_599994
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599995 = header.getOrDefault("X-Amz-Target")
  valid_599995 = validateParameter(valid_599995, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CancelHandshake"))
  if valid_599995 != nil:
    section.add "X-Amz-Target", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Content-Sha256", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Algorithm")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Algorithm", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-Signature")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-Signature", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-SignedHeaders", valid_599999
  var valid_600000 = header.getOrDefault("X-Amz-Credential")
  valid_600000 = validateParameter(valid_600000, JString, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "X-Amz-Credential", valid_600000
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600002: Call_CancelHandshake_599990; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Cancels a handshake. Canceling a handshake sets the handshake state to <code>CANCELED</code>. </p> <p>This operation can be called only from the account that originated the handshake. The recipient of the handshake can't cancel it, but can use <a>DeclineHandshake</a> instead. After a handshake is canceled, the recipient can no longer respond to that handshake.</p> <p>After you cancel a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
  ## 
  let valid = call_600002.validator(path, query, header, formData, body)
  let scheme = call_600002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600002.url(scheme.get, call_600002.host, call_600002.base,
                         call_600002.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600002, url, valid)

proc call*(call_600003: Call_CancelHandshake_599990; body: JsonNode): Recallable =
  ## cancelHandshake
  ## <p>Cancels a handshake. Canceling a handshake sets the handshake state to <code>CANCELED</code>. </p> <p>This operation can be called only from the account that originated the handshake. The recipient of the handshake can't cancel it, but can use <a>DeclineHandshake</a> instead. After a handshake is canceled, the recipient can no longer respond to that handshake.</p> <p>After you cancel a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
  ##   body: JObject (required)
  var body_600004 = newJObject()
  if body != nil:
    body_600004 = body
  result = call_600003.call(nil, nil, nil, nil, body_600004)

var cancelHandshake* = Call_CancelHandshake_599990(name: "cancelHandshake",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CancelHandshake",
    validator: validate_CancelHandshake_599991, base: "/", url: url_CancelHandshake_599992,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAccount_600005 = ref object of OpenApiRestCall_599369
proc url_CreateAccount_600007(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAccount_600006(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an AWS account that is automatically a member of the organization whose credentials made the request. This is an asynchronous request that AWS performs in the background. Because <code>CreateAccount</code> operates asynchronously, it can return a successful completion message even though account initialization might still be in progress. You might need to wait a few minutes before you can successfully access the account. To check the status of the request, do one of the following:</p> <ul> <li> <p>Use the <code>OperationId</code> response element from this operation to provide as a parameter to the <a>DescribeCreateAccountStatus</a> operation.</p> </li> <li> <p>Check the AWS CloudTrail log for the <code>CreateAccountResult</code> event. For information on using AWS CloudTrail with AWS Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_monitoring.html">Monitoring the Activity in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p/> <p>The user who calls the API to create an account must have the <code>organizations:CreateAccount</code> permission. If you enabled all features in the organization, AWS Organizations creates the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html#orgs_integrate_services-using_slrs">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide</i>.</p> <p>AWS Organizations preconfigures the new member account with a role (named <code>OrganizationAccountAccessRole</code> by default) that grants users in the master account administrator permissions in the new member account. Principals in the master account can assume the role. AWS Organizations clones the company name and address information for the new account from the organization's master account.</p> <p>This operation can be called only from the organization's master account.</p> <p>For more information about creating accounts, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_create.html">Creating an AWS Account in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <ul> <li> <p>When you create an account in an organization, the information required for the account to operate as a standalone account is <i>not</i> automatically collected. For example, information about the payment method and signing the end user license agreement (EULA) is not collected. If you must remove an account from your organization later, you can do so only after you provide the missing information. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization as a member account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> <li> <p>If you get an exception that indicates that you exceeded your account limits for the organization, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>If you get an exception that indicates that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>Using <code>CreateAccount</code> to create multiple temporary accounts isn't recommended. You can only close an account from the Billing and Cost Management Console, and you must be signed in as the root user. For information on the requirements and process for closing an account, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html">Closing an AWS Account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> </ul> </important> <note> <p>When you create a member account with this operation, you can choose whether to create the account with the <b>IAM User and Role Access to Billing Information</b> switch enabled. If you enable it, IAM users and roles that have appropriate permissions can view billing information for the account. If you disable it, only the account root user can access billing information. For information about how to disable this switch for an account, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html">Granting Access to Your Billing Information and Tools</a>.</p> </note>
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
  var valid_600008 = header.getOrDefault("X-Amz-Date")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Date", valid_600008
  var valid_600009 = header.getOrDefault("X-Amz-Security-Token")
  valid_600009 = validateParameter(valid_600009, JString, required = false,
                                 default = nil)
  if valid_600009 != nil:
    section.add "X-Amz-Security-Token", valid_600009
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600010 = header.getOrDefault("X-Amz-Target")
  valid_600010 = validateParameter(valid_600010, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CreateAccount"))
  if valid_600010 != nil:
    section.add "X-Amz-Target", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Content-Sha256", valid_600011
  var valid_600012 = header.getOrDefault("X-Amz-Algorithm")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-Algorithm", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-Signature")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-Signature", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-SignedHeaders", valid_600014
  var valid_600015 = header.getOrDefault("X-Amz-Credential")
  valid_600015 = validateParameter(valid_600015, JString, required = false,
                                 default = nil)
  if valid_600015 != nil:
    section.add "X-Amz-Credential", valid_600015
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600017: Call_CreateAccount_600005; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS account that is automatically a member of the organization whose credentials made the request. This is an asynchronous request that AWS performs in the background. Because <code>CreateAccount</code> operates asynchronously, it can return a successful completion message even though account initialization might still be in progress. You might need to wait a few minutes before you can successfully access the account. To check the status of the request, do one of the following:</p> <ul> <li> <p>Use the <code>OperationId</code> response element from this operation to provide as a parameter to the <a>DescribeCreateAccountStatus</a> operation.</p> </li> <li> <p>Check the AWS CloudTrail log for the <code>CreateAccountResult</code> event. For information on using AWS CloudTrail with AWS Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_monitoring.html">Monitoring the Activity in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p/> <p>The user who calls the API to create an account must have the <code>organizations:CreateAccount</code> permission. If you enabled all features in the organization, AWS Organizations creates the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html#orgs_integrate_services-using_slrs">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide</i>.</p> <p>AWS Organizations preconfigures the new member account with a role (named <code>OrganizationAccountAccessRole</code> by default) that grants users in the master account administrator permissions in the new member account. Principals in the master account can assume the role. AWS Organizations clones the company name and address information for the new account from the organization's master account.</p> <p>This operation can be called only from the organization's master account.</p> <p>For more information about creating accounts, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_create.html">Creating an AWS Account in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <ul> <li> <p>When you create an account in an organization, the information required for the account to operate as a standalone account is <i>not</i> automatically collected. For example, information about the payment method and signing the end user license agreement (EULA) is not collected. If you must remove an account from your organization later, you can do so only after you provide the missing information. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization as a member account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> <li> <p>If you get an exception that indicates that you exceeded your account limits for the organization, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>If you get an exception that indicates that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>Using <code>CreateAccount</code> to create multiple temporary accounts isn't recommended. You can only close an account from the Billing and Cost Management Console, and you must be signed in as the root user. For information on the requirements and process for closing an account, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html">Closing an AWS Account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> </ul> </important> <note> <p>When you create a member account with this operation, you can choose whether to create the account with the <b>IAM User and Role Access to Billing Information</b> switch enabled. If you enable it, IAM users and roles that have appropriate permissions can view billing information for the account. If you disable it, only the account root user can access billing information. For information about how to disable this switch for an account, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html">Granting Access to Your Billing Information and Tools</a>.</p> </note>
  ## 
  let valid = call_600017.validator(path, query, header, formData, body)
  let scheme = call_600017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600017.url(scheme.get, call_600017.host, call_600017.base,
                         call_600017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600017, url, valid)

proc call*(call_600018: Call_CreateAccount_600005; body: JsonNode): Recallable =
  ## createAccount
  ## <p>Creates an AWS account that is automatically a member of the organization whose credentials made the request. This is an asynchronous request that AWS performs in the background. Because <code>CreateAccount</code> operates asynchronously, it can return a successful completion message even though account initialization might still be in progress. You might need to wait a few minutes before you can successfully access the account. To check the status of the request, do one of the following:</p> <ul> <li> <p>Use the <code>OperationId</code> response element from this operation to provide as a parameter to the <a>DescribeCreateAccountStatus</a> operation.</p> </li> <li> <p>Check the AWS CloudTrail log for the <code>CreateAccountResult</code> event. For information on using AWS CloudTrail with AWS Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_monitoring.html">Monitoring the Activity in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p/> <p>The user who calls the API to create an account must have the <code>organizations:CreateAccount</code> permission. If you enabled all features in the organization, AWS Organizations creates the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html#orgs_integrate_services-using_slrs">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide</i>.</p> <p>AWS Organizations preconfigures the new member account with a role (named <code>OrganizationAccountAccessRole</code> by default) that grants users in the master account administrator permissions in the new member account. Principals in the master account can assume the role. AWS Organizations clones the company name and address information for the new account from the organization's master account.</p> <p>This operation can be called only from the organization's master account.</p> <p>For more information about creating accounts, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_create.html">Creating an AWS Account in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <ul> <li> <p>When you create an account in an organization, the information required for the account to operate as a standalone account is <i>not</i> automatically collected. For example, information about the payment method and signing the end user license agreement (EULA) is not collected. If you must remove an account from your organization later, you can do so only after you provide the missing information. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization as a member account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> <li> <p>If you get an exception that indicates that you exceeded your account limits for the organization, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>If you get an exception that indicates that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>Using <code>CreateAccount</code> to create multiple temporary accounts isn't recommended. You can only close an account from the Billing and Cost Management Console, and you must be signed in as the root user. For information on the requirements and process for closing an account, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html">Closing an AWS Account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> </ul> </important> <note> <p>When you create a member account with this operation, you can choose whether to create the account with the <b>IAM User and Role Access to Billing Information</b> switch enabled. If you enable it, IAM users and roles that have appropriate permissions can view billing information for the account. If you disable it, only the account root user can access billing information. For information about how to disable this switch for an account, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html">Granting Access to Your Billing Information and Tools</a>.</p> </note>
  ##   body: JObject (required)
  var body_600019 = newJObject()
  if body != nil:
    body_600019 = body
  result = call_600018.call(nil, nil, nil, nil, body_600019)

var createAccount* = Call_CreateAccount_600005(name: "createAccount",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CreateAccount",
    validator: validate_CreateAccount_600006, base: "/", url: url_CreateAccount_600007,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGovCloudAccount_600020 = ref object of OpenApiRestCall_599369
proc url_CreateGovCloudAccount_600022(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateGovCloudAccount_600021(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>This action is available if all of the following are true:</p> <ul> <li> <p>You're authorized to create accounts in the AWS GovCloud (US) Region. For more information on the AWS GovCloud (US) Region, see the <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/welcome.html"> <i>AWS GovCloud User Guide</i>.</a> </p> </li> <li> <p>You already have an account in the AWS GovCloud (US) Region that is associated with your master account in the commercial Region. </p> </li> <li> <p>You call this action from the master account of your organization in the commercial Region.</p> </li> <li> <p>You have the <code>organizations:CreateGovCloudAccount</code> permission. AWS Organizations creates the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html#orgs_integrate_services-using_slrs">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>AWS automatically enables AWS CloudTrail for AWS GovCloud (US) accounts, but you should also do the following:</p> <ul> <li> <p>Verify that AWS CloudTrail is enabled to store logs.</p> </li> <li> <p>Create an S3 bucket for AWS CloudTrail log storage.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/verifying-cloudtrail.html">Verifying AWS CloudTrail Is Enabled</a> in the <i>AWS GovCloud User Guide</i>. </p> </li> </ul> <p>You call this action from the master account of your organization in the commercial Region to create a standalone AWS account in the AWS GovCloud (US) Region. After the account is created, the master account of an organization in the AWS GovCloud (US) Region can invite it to that organization. For more information on inviting standalone accounts in the AWS GovCloud (US) to join an organization, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-organizations.html">AWS Organizations</a> in the <i>AWS GovCloud User Guide.</i> </p> <p>Calling <code>CreateGovCloudAccount</code> is an asynchronous request that AWS performs in the background. Because <code>CreateGovCloudAccount</code> operates asynchronously, it can return a successful completion message even though account initialization might still be in progress. You might need to wait a few minutes before you can successfully access the account. To check the status of the request, do one of the following:</p> <ul> <li> <p>Use the <code>OperationId</code> response element from this operation to provide as a parameter to the <a>DescribeCreateAccountStatus</a> operation.</p> </li> <li> <p>Check the AWS CloudTrail log for the <code>CreateAccountResult</code> event. For information on using AWS CloudTrail with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_monitoring.html">Monitoring the Activity in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p/> <p>When you call the <code>CreateGovCloudAccount</code> action, you create two accounts: a standalone account in the AWS GovCloud (US) Region and an associated account in the commercial Region for billing and support purposes. The account in the commercial Region is automatically a member of the organization whose credentials made the request. Both accounts are associated with the same email address.</p> <p>A role is created in the new account in the commercial Region that allows the master account in the organization in the commercial Region to assume it. An AWS GovCloud (US) account is then created and associated with the commercial account that you just created. A role is created in the new AWS GovCloud (US) account. This role can be assumed by the AWS GovCloud (US) account that is associated with the master account of the commercial organization. For more information and to view a diagram that explains how account access works, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-organizations.html">AWS Organizations</a> in the <i>AWS GovCloud User Guide.</i> </p> <p>For more information about creating accounts, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_create.html">Creating an AWS Account in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <ul> <li> <p>You can create an account in an organization using the AWS Organizations console, API, or CLI commands. When you do, the information required for the account to operate as a standalone account, such as a payment method, is <i>not</i> automatically collected. If you must remove an account from your organization later, you can do so only after you provide the missing information. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization as a member account</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>If you get an exception that indicates that you exceeded your account limits for the organization, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>If you get an exception that indicates that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>Using <code>CreateGovCloudAccount</code> to create multiple temporary accounts isn't recommended. You can only close an account from the AWS Billing and Cost Management console, and you must be signed in as the root user. For information on the requirements and process for closing an account, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html">Closing an AWS Account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> </ul> </important> <note> <p>When you create a member account with this operation, you can choose whether to create the account with the <b>IAM User and Role Access to Billing Information</b> switch enabled. If you enable it, IAM users and roles that have appropriate permissions can view billing information for the account. If you disable it, only the account root user can access billing information. For information about how to disable this switch for an account, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html">Granting Access to Your Billing Information and Tools</a>.</p> </note>
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
  var valid_600023 = header.getOrDefault("X-Amz-Date")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Date", valid_600023
  var valid_600024 = header.getOrDefault("X-Amz-Security-Token")
  valid_600024 = validateParameter(valid_600024, JString, required = false,
                                 default = nil)
  if valid_600024 != nil:
    section.add "X-Amz-Security-Token", valid_600024
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600025 = header.getOrDefault("X-Amz-Target")
  valid_600025 = validateParameter(valid_600025, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CreateGovCloudAccount"))
  if valid_600025 != nil:
    section.add "X-Amz-Target", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Content-Sha256", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Algorithm")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Algorithm", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-Signature")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-Signature", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-SignedHeaders", valid_600029
  var valid_600030 = header.getOrDefault("X-Amz-Credential")
  valid_600030 = validateParameter(valid_600030, JString, required = false,
                                 default = nil)
  if valid_600030 != nil:
    section.add "X-Amz-Credential", valid_600030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600032: Call_CreateGovCloudAccount_600020; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This action is available if all of the following are true:</p> <ul> <li> <p>You're authorized to create accounts in the AWS GovCloud (US) Region. For more information on the AWS GovCloud (US) Region, see the <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/welcome.html"> <i>AWS GovCloud User Guide</i>.</a> </p> </li> <li> <p>You already have an account in the AWS GovCloud (US) Region that is associated with your master account in the commercial Region. </p> </li> <li> <p>You call this action from the master account of your organization in the commercial Region.</p> </li> <li> <p>You have the <code>organizations:CreateGovCloudAccount</code> permission. AWS Organizations creates the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html#orgs_integrate_services-using_slrs">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>AWS automatically enables AWS CloudTrail for AWS GovCloud (US) accounts, but you should also do the following:</p> <ul> <li> <p>Verify that AWS CloudTrail is enabled to store logs.</p> </li> <li> <p>Create an S3 bucket for AWS CloudTrail log storage.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/verifying-cloudtrail.html">Verifying AWS CloudTrail Is Enabled</a> in the <i>AWS GovCloud User Guide</i>. </p> </li> </ul> <p>You call this action from the master account of your organization in the commercial Region to create a standalone AWS account in the AWS GovCloud (US) Region. After the account is created, the master account of an organization in the AWS GovCloud (US) Region can invite it to that organization. For more information on inviting standalone accounts in the AWS GovCloud (US) to join an organization, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-organizations.html">AWS Organizations</a> in the <i>AWS GovCloud User Guide.</i> </p> <p>Calling <code>CreateGovCloudAccount</code> is an asynchronous request that AWS performs in the background. Because <code>CreateGovCloudAccount</code> operates asynchronously, it can return a successful completion message even though account initialization might still be in progress. You might need to wait a few minutes before you can successfully access the account. To check the status of the request, do one of the following:</p> <ul> <li> <p>Use the <code>OperationId</code> response element from this operation to provide as a parameter to the <a>DescribeCreateAccountStatus</a> operation.</p> </li> <li> <p>Check the AWS CloudTrail log for the <code>CreateAccountResult</code> event. For information on using AWS CloudTrail with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_monitoring.html">Monitoring the Activity in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p/> <p>When you call the <code>CreateGovCloudAccount</code> action, you create two accounts: a standalone account in the AWS GovCloud (US) Region and an associated account in the commercial Region for billing and support purposes. The account in the commercial Region is automatically a member of the organization whose credentials made the request. Both accounts are associated with the same email address.</p> <p>A role is created in the new account in the commercial Region that allows the master account in the organization in the commercial Region to assume it. An AWS GovCloud (US) account is then created and associated with the commercial account that you just created. A role is created in the new AWS GovCloud (US) account. This role can be assumed by the AWS GovCloud (US) account that is associated with the master account of the commercial organization. For more information and to view a diagram that explains how account access works, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-organizations.html">AWS Organizations</a> in the <i>AWS GovCloud User Guide.</i> </p> <p>For more information about creating accounts, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_create.html">Creating an AWS Account in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <ul> <li> <p>You can create an account in an organization using the AWS Organizations console, API, or CLI commands. When you do, the information required for the account to operate as a standalone account, such as a payment method, is <i>not</i> automatically collected. If you must remove an account from your organization later, you can do so only after you provide the missing information. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization as a member account</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>If you get an exception that indicates that you exceeded your account limits for the organization, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>If you get an exception that indicates that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>Using <code>CreateGovCloudAccount</code> to create multiple temporary accounts isn't recommended. You can only close an account from the AWS Billing and Cost Management console, and you must be signed in as the root user. For information on the requirements and process for closing an account, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html">Closing an AWS Account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> </ul> </important> <note> <p>When you create a member account with this operation, you can choose whether to create the account with the <b>IAM User and Role Access to Billing Information</b> switch enabled. If you enable it, IAM users and roles that have appropriate permissions can view billing information for the account. If you disable it, only the account root user can access billing information. For information about how to disable this switch for an account, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html">Granting Access to Your Billing Information and Tools</a>.</p> </note>
  ## 
  let valid = call_600032.validator(path, query, header, formData, body)
  let scheme = call_600032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600032.url(scheme.get, call_600032.host, call_600032.base,
                         call_600032.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600032, url, valid)

proc call*(call_600033: Call_CreateGovCloudAccount_600020; body: JsonNode): Recallable =
  ## createGovCloudAccount
  ## <p>This action is available if all of the following are true:</p> <ul> <li> <p>You're authorized to create accounts in the AWS GovCloud (US) Region. For more information on the AWS GovCloud (US) Region, see the <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/welcome.html"> <i>AWS GovCloud User Guide</i>.</a> </p> </li> <li> <p>You already have an account in the AWS GovCloud (US) Region that is associated with your master account in the commercial Region. </p> </li> <li> <p>You call this action from the master account of your organization in the commercial Region.</p> </li> <li> <p>You have the <code>organizations:CreateGovCloudAccount</code> permission. AWS Organizations creates the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html#orgs_integrate_services-using_slrs">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>AWS automatically enables AWS CloudTrail for AWS GovCloud (US) accounts, but you should also do the following:</p> <ul> <li> <p>Verify that AWS CloudTrail is enabled to store logs.</p> </li> <li> <p>Create an S3 bucket for AWS CloudTrail log storage.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/verifying-cloudtrail.html">Verifying AWS CloudTrail Is Enabled</a> in the <i>AWS GovCloud User Guide</i>. </p> </li> </ul> <p>You call this action from the master account of your organization in the commercial Region to create a standalone AWS account in the AWS GovCloud (US) Region. After the account is created, the master account of an organization in the AWS GovCloud (US) Region can invite it to that organization. For more information on inviting standalone accounts in the AWS GovCloud (US) to join an organization, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-organizations.html">AWS Organizations</a> in the <i>AWS GovCloud User Guide.</i> </p> <p>Calling <code>CreateGovCloudAccount</code> is an asynchronous request that AWS performs in the background. Because <code>CreateGovCloudAccount</code> operates asynchronously, it can return a successful completion message even though account initialization might still be in progress. You might need to wait a few minutes before you can successfully access the account. To check the status of the request, do one of the following:</p> <ul> <li> <p>Use the <code>OperationId</code> response element from this operation to provide as a parameter to the <a>DescribeCreateAccountStatus</a> operation.</p> </li> <li> <p>Check the AWS CloudTrail log for the <code>CreateAccountResult</code> event. For information on using AWS CloudTrail with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_monitoring.html">Monitoring the Activity in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p/> <p>When you call the <code>CreateGovCloudAccount</code> action, you create two accounts: a standalone account in the AWS GovCloud (US) Region and an associated account in the commercial Region for billing and support purposes. The account in the commercial Region is automatically a member of the organization whose credentials made the request. Both accounts are associated with the same email address.</p> <p>A role is created in the new account in the commercial Region that allows the master account in the organization in the commercial Region to assume it. An AWS GovCloud (US) account is then created and associated with the commercial account that you just created. A role is created in the new AWS GovCloud (US) account. This role can be assumed by the AWS GovCloud (US) account that is associated with the master account of the commercial organization. For more information and to view a diagram that explains how account access works, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-organizations.html">AWS Organizations</a> in the <i>AWS GovCloud User Guide.</i> </p> <p>For more information about creating accounts, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_create.html">Creating an AWS Account in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <ul> <li> <p>You can create an account in an organization using the AWS Organizations console, API, or CLI commands. When you do, the information required for the account to operate as a standalone account, such as a payment method, is <i>not</i> automatically collected. If you must remove an account from your organization later, you can do so only after you provide the missing information. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization as a member account</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>If you get an exception that indicates that you exceeded your account limits for the organization, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>If you get an exception that indicates that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>Using <code>CreateGovCloudAccount</code> to create multiple temporary accounts isn't recommended. You can only close an account from the AWS Billing and Cost Management console, and you must be signed in as the root user. For information on the requirements and process for closing an account, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html">Closing an AWS Account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> </ul> </important> <note> <p>When you create a member account with this operation, you can choose whether to create the account with the <b>IAM User and Role Access to Billing Information</b> switch enabled. If you enable it, IAM users and roles that have appropriate permissions can view billing information for the account. If you disable it, only the account root user can access billing information. For information about how to disable this switch for an account, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html">Granting Access to Your Billing Information and Tools</a>.</p> </note>
  ##   body: JObject (required)
  var body_600034 = newJObject()
  if body != nil:
    body_600034 = body
  result = call_600033.call(nil, nil, nil, nil, body_600034)

var createGovCloudAccount* = Call_CreateGovCloudAccount_600020(
    name: "createGovCloudAccount", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CreateGovCloudAccount",
    validator: validate_CreateGovCloudAccount_600021, base: "/",
    url: url_CreateGovCloudAccount_600022, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateOrganization_600035 = ref object of OpenApiRestCall_599369
proc url_CreateOrganization_600037(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateOrganization_600036(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Creates an AWS organization. The account whose user is calling the <code>CreateOrganization</code> operation automatically becomes the <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/orgs_getting-started_concepts.html#account">master account</a> of the new organization.</p> <p>This operation must be called using credentials from the account that is to become the new organization's master account. The principal must also have the relevant IAM permissions.</p> <p>By default (or if you set the <code>FeatureSet</code> parameter to <code>ALL</code>), the new organization is created with all features enabled. In addition, service control policies are automatically enabled in the root. If you instead create the organization supporting only the consolidated billing features, no policy types are enabled by default, and you can't use organization policies.</p>
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
  var valid_600038 = header.getOrDefault("X-Amz-Date")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Date", valid_600038
  var valid_600039 = header.getOrDefault("X-Amz-Security-Token")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "X-Amz-Security-Token", valid_600039
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600040 = header.getOrDefault("X-Amz-Target")
  valid_600040 = validateParameter(valid_600040, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CreateOrganization"))
  if valid_600040 != nil:
    section.add "X-Amz-Target", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Content-Sha256", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Algorithm")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Algorithm", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-Signature")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-Signature", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-SignedHeaders", valid_600044
  var valid_600045 = header.getOrDefault("X-Amz-Credential")
  valid_600045 = validateParameter(valid_600045, JString, required = false,
                                 default = nil)
  if valid_600045 != nil:
    section.add "X-Amz-Credential", valid_600045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600047: Call_CreateOrganization_600035; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS organization. The account whose user is calling the <code>CreateOrganization</code> operation automatically becomes the <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/orgs_getting-started_concepts.html#account">master account</a> of the new organization.</p> <p>This operation must be called using credentials from the account that is to become the new organization's master account. The principal must also have the relevant IAM permissions.</p> <p>By default (or if you set the <code>FeatureSet</code> parameter to <code>ALL</code>), the new organization is created with all features enabled. In addition, service control policies are automatically enabled in the root. If you instead create the organization supporting only the consolidated billing features, no policy types are enabled by default, and you can't use organization policies.</p>
  ## 
  let valid = call_600047.validator(path, query, header, formData, body)
  let scheme = call_600047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600047.url(scheme.get, call_600047.host, call_600047.base,
                         call_600047.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600047, url, valid)

proc call*(call_600048: Call_CreateOrganization_600035; body: JsonNode): Recallable =
  ## createOrganization
  ## <p>Creates an AWS organization. The account whose user is calling the <code>CreateOrganization</code> operation automatically becomes the <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/orgs_getting-started_concepts.html#account">master account</a> of the new organization.</p> <p>This operation must be called using credentials from the account that is to become the new organization's master account. The principal must also have the relevant IAM permissions.</p> <p>By default (or if you set the <code>FeatureSet</code> parameter to <code>ALL</code>), the new organization is created with all features enabled. In addition, service control policies are automatically enabled in the root. If you instead create the organization supporting only the consolidated billing features, no policy types are enabled by default, and you can't use organization policies.</p>
  ##   body: JObject (required)
  var body_600049 = newJObject()
  if body != nil:
    body_600049 = body
  result = call_600048.call(nil, nil, nil, nil, body_600049)

var createOrganization* = Call_CreateOrganization_600035(
    name: "createOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CreateOrganization",
    validator: validate_CreateOrganization_600036, base: "/",
    url: url_CreateOrganization_600037, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateOrganizationalUnit_600050 = ref object of OpenApiRestCall_599369
proc url_CreateOrganizationalUnit_600052(protocol: Scheme; host: string;
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

proc validate_CreateOrganizationalUnit_600051(path: JsonNode; query: JsonNode;
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
  var valid_600053 = header.getOrDefault("X-Amz-Date")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Date", valid_600053
  var valid_600054 = header.getOrDefault("X-Amz-Security-Token")
  valid_600054 = validateParameter(valid_600054, JString, required = false,
                                 default = nil)
  if valid_600054 != nil:
    section.add "X-Amz-Security-Token", valid_600054
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600055 = header.getOrDefault("X-Amz-Target")
  valid_600055 = validateParameter(valid_600055, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CreateOrganizationalUnit"))
  if valid_600055 != nil:
    section.add "X-Amz-Target", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Content-Sha256", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Algorithm")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Algorithm", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-Signature")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-Signature", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-SignedHeaders", valid_600059
  var valid_600060 = header.getOrDefault("X-Amz-Credential")
  valid_600060 = validateParameter(valid_600060, JString, required = false,
                                 default = nil)
  if valid_600060 != nil:
    section.add "X-Amz-Credential", valid_600060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600062: Call_CreateOrganizationalUnit_600050; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an organizational unit (OU) within a root or parent OU. An OU is a container for accounts that enables you to organize your accounts to apply policies according to your business requirements. The number of levels deep that you can nest OUs is dependent upon the policy types enabled for that root. For service control policies, the limit is five. </p> <p>For more information about OUs, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_ous.html">Managing Organizational Units</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_600062.validator(path, query, header, formData, body)
  let scheme = call_600062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600062.url(scheme.get, call_600062.host, call_600062.base,
                         call_600062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600062, url, valid)

proc call*(call_600063: Call_CreateOrganizationalUnit_600050; body: JsonNode): Recallable =
  ## createOrganizationalUnit
  ## <p>Creates an organizational unit (OU) within a root or parent OU. An OU is a container for accounts that enables you to organize your accounts to apply policies according to your business requirements. The number of levels deep that you can nest OUs is dependent upon the policy types enabled for that root. For service control policies, the limit is five. </p> <p>For more information about OUs, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_ous.html">Managing Organizational Units</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_600064 = newJObject()
  if body != nil:
    body_600064 = body
  result = call_600063.call(nil, nil, nil, nil, body_600064)

var createOrganizationalUnit* = Call_CreateOrganizationalUnit_600050(
    name: "createOrganizationalUnit", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CreateOrganizationalUnit",
    validator: validate_CreateOrganizationalUnit_600051, base: "/",
    url: url_CreateOrganizationalUnit_600052, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePolicy_600065 = ref object of OpenApiRestCall_599369
proc url_CreatePolicy_600067(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePolicy_600066(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600068 = header.getOrDefault("X-Amz-Date")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Date", valid_600068
  var valid_600069 = header.getOrDefault("X-Amz-Security-Token")
  valid_600069 = validateParameter(valid_600069, JString, required = false,
                                 default = nil)
  if valid_600069 != nil:
    section.add "X-Amz-Security-Token", valid_600069
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600070 = header.getOrDefault("X-Amz-Target")
  valid_600070 = validateParameter(valid_600070, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CreatePolicy"))
  if valid_600070 != nil:
    section.add "X-Amz-Target", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Content-Sha256", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-Algorithm")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Algorithm", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-Signature")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-Signature", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-SignedHeaders", valid_600074
  var valid_600075 = header.getOrDefault("X-Amz-Credential")
  valid_600075 = validateParameter(valid_600075, JString, required = false,
                                 default = nil)
  if valid_600075 != nil:
    section.add "X-Amz-Credential", valid_600075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600077: Call_CreatePolicy_600065; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a policy of a specified type that you can attach to a root, an organizational unit (OU), or an individual AWS account.</p> <p>For more information about policies and their use, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies.html">Managing Organization Policies</a>.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_600077.validator(path, query, header, formData, body)
  let scheme = call_600077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600077.url(scheme.get, call_600077.host, call_600077.base,
                         call_600077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600077, url, valid)

proc call*(call_600078: Call_CreatePolicy_600065; body: JsonNode): Recallable =
  ## createPolicy
  ## <p>Creates a policy of a specified type that you can attach to a root, an organizational unit (OU), or an individual AWS account.</p> <p>For more information about policies and their use, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies.html">Managing Organization Policies</a>.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_600079 = newJObject()
  if body != nil:
    body_600079 = body
  result = call_600078.call(nil, nil, nil, nil, body_600079)

var createPolicy* = Call_CreatePolicy_600065(name: "createPolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CreatePolicy",
    validator: validate_CreatePolicy_600066, base: "/", url: url_CreatePolicy_600067,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeclineHandshake_600080 = ref object of OpenApiRestCall_599369
proc url_DeclineHandshake_600082(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeclineHandshake_600081(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Declines a handshake request. This sets the handshake state to <code>DECLINED</code> and effectively deactivates the request.</p> <p>This operation can be called only from the account that received the handshake. The originator of the handshake can use <a>CancelHandshake</a> instead. The originator can't reactivate a declined request, but can reinitiate the process with a new handshake request.</p> <p>After you decline a handshake, it continues to appear in the results of relevant API operations for only 30 days. After that, it's deleted.</p>
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
  var valid_600083 = header.getOrDefault("X-Amz-Date")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Date", valid_600083
  var valid_600084 = header.getOrDefault("X-Amz-Security-Token")
  valid_600084 = validateParameter(valid_600084, JString, required = false,
                                 default = nil)
  if valid_600084 != nil:
    section.add "X-Amz-Security-Token", valid_600084
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600085 = header.getOrDefault("X-Amz-Target")
  valid_600085 = validateParameter(valid_600085, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DeclineHandshake"))
  if valid_600085 != nil:
    section.add "X-Amz-Target", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-Content-Sha256", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Algorithm")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Algorithm", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-Signature")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-Signature", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-SignedHeaders", valid_600089
  var valid_600090 = header.getOrDefault("X-Amz-Credential")
  valid_600090 = validateParameter(valid_600090, JString, required = false,
                                 default = nil)
  if valid_600090 != nil:
    section.add "X-Amz-Credential", valid_600090
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600092: Call_DeclineHandshake_600080; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Declines a handshake request. This sets the handshake state to <code>DECLINED</code> and effectively deactivates the request.</p> <p>This operation can be called only from the account that received the handshake. The originator of the handshake can use <a>CancelHandshake</a> instead. The originator can't reactivate a declined request, but can reinitiate the process with a new handshake request.</p> <p>After you decline a handshake, it continues to appear in the results of relevant API operations for only 30 days. After that, it's deleted.</p>
  ## 
  let valid = call_600092.validator(path, query, header, formData, body)
  let scheme = call_600092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600092.url(scheme.get, call_600092.host, call_600092.base,
                         call_600092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600092, url, valid)

proc call*(call_600093: Call_DeclineHandshake_600080; body: JsonNode): Recallable =
  ## declineHandshake
  ## <p>Declines a handshake request. This sets the handshake state to <code>DECLINED</code> and effectively deactivates the request.</p> <p>This operation can be called only from the account that received the handshake. The originator of the handshake can use <a>CancelHandshake</a> instead. The originator can't reactivate a declined request, but can reinitiate the process with a new handshake request.</p> <p>After you decline a handshake, it continues to appear in the results of relevant API operations for only 30 days. After that, it's deleted.</p>
  ##   body: JObject (required)
  var body_600094 = newJObject()
  if body != nil:
    body_600094 = body
  result = call_600093.call(nil, nil, nil, nil, body_600094)

var declineHandshake* = Call_DeclineHandshake_600080(name: "declineHandshake",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DeclineHandshake",
    validator: validate_DeclineHandshake_600081, base: "/",
    url: url_DeclineHandshake_600082, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteOrganization_600095 = ref object of OpenApiRestCall_599369
proc url_DeleteOrganization_600097(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteOrganization_600096(path: JsonNode; query: JsonNode;
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
  var valid_600098 = header.getOrDefault("X-Amz-Date")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "X-Amz-Date", valid_600098
  var valid_600099 = header.getOrDefault("X-Amz-Security-Token")
  valid_600099 = validateParameter(valid_600099, JString, required = false,
                                 default = nil)
  if valid_600099 != nil:
    section.add "X-Amz-Security-Token", valid_600099
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600100 = header.getOrDefault("X-Amz-Target")
  valid_600100 = validateParameter(valid_600100, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DeleteOrganization"))
  if valid_600100 != nil:
    section.add "X-Amz-Target", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Content-Sha256", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Algorithm")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Algorithm", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-Signature")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-Signature", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-SignedHeaders", valid_600104
  var valid_600105 = header.getOrDefault("X-Amz-Credential")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "X-Amz-Credential", valid_600105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600106: Call_DeleteOrganization_600095; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the organization. You can delete an organization only by using credentials from the master account. The organization must be empty of member accounts.
  ## 
  let valid = call_600106.validator(path, query, header, formData, body)
  let scheme = call_600106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600106.url(scheme.get, call_600106.host, call_600106.base,
                         call_600106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600106, url, valid)

proc call*(call_600107: Call_DeleteOrganization_600095): Recallable =
  ## deleteOrganization
  ## Deletes the organization. You can delete an organization only by using credentials from the master account. The organization must be empty of member accounts.
  result = call_600107.call(nil, nil, nil, nil, nil)

var deleteOrganization* = Call_DeleteOrganization_600095(
    name: "deleteOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DeleteOrganization",
    validator: validate_DeleteOrganization_600096, base: "/",
    url: url_DeleteOrganization_600097, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteOrganizationalUnit_600108 = ref object of OpenApiRestCall_599369
proc url_DeleteOrganizationalUnit_600110(protocol: Scheme; host: string;
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

proc validate_DeleteOrganizationalUnit_600109(path: JsonNode; query: JsonNode;
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
  var valid_600111 = header.getOrDefault("X-Amz-Date")
  valid_600111 = validateParameter(valid_600111, JString, required = false,
                                 default = nil)
  if valid_600111 != nil:
    section.add "X-Amz-Date", valid_600111
  var valid_600112 = header.getOrDefault("X-Amz-Security-Token")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-Security-Token", valid_600112
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600113 = header.getOrDefault("X-Amz-Target")
  valid_600113 = validateParameter(valid_600113, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DeleteOrganizationalUnit"))
  if valid_600113 != nil:
    section.add "X-Amz-Target", valid_600113
  var valid_600114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600114 = validateParameter(valid_600114, JString, required = false,
                                 default = nil)
  if valid_600114 != nil:
    section.add "X-Amz-Content-Sha256", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-Algorithm")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-Algorithm", valid_600115
  var valid_600116 = header.getOrDefault("X-Amz-Signature")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Signature", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-SignedHeaders", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-Credential")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-Credential", valid_600118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600120: Call_DeleteOrganizationalUnit_600108; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an organizational unit (OU) from a root or another OU. You must first remove all accounts and child OUs from the OU that you want to delete.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_600120.validator(path, query, header, formData, body)
  let scheme = call_600120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600120.url(scheme.get, call_600120.host, call_600120.base,
                         call_600120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600120, url, valid)

proc call*(call_600121: Call_DeleteOrganizationalUnit_600108; body: JsonNode): Recallable =
  ## deleteOrganizationalUnit
  ## <p>Deletes an organizational unit (OU) from a root or another OU. You must first remove all accounts and child OUs from the OU that you want to delete.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_600122 = newJObject()
  if body != nil:
    body_600122 = body
  result = call_600121.call(nil, nil, nil, nil, body_600122)

var deleteOrganizationalUnit* = Call_DeleteOrganizationalUnit_600108(
    name: "deleteOrganizationalUnit", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DeleteOrganizationalUnit",
    validator: validate_DeleteOrganizationalUnit_600109, base: "/",
    url: url_DeleteOrganizationalUnit_600110, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePolicy_600123 = ref object of OpenApiRestCall_599369
proc url_DeletePolicy_600125(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePolicy_600124(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600126 = header.getOrDefault("X-Amz-Date")
  valid_600126 = validateParameter(valid_600126, JString, required = false,
                                 default = nil)
  if valid_600126 != nil:
    section.add "X-Amz-Date", valid_600126
  var valid_600127 = header.getOrDefault("X-Amz-Security-Token")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Security-Token", valid_600127
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600128 = header.getOrDefault("X-Amz-Target")
  valid_600128 = validateParameter(valid_600128, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DeletePolicy"))
  if valid_600128 != nil:
    section.add "X-Amz-Target", valid_600128
  var valid_600129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600129 = validateParameter(valid_600129, JString, required = false,
                                 default = nil)
  if valid_600129 != nil:
    section.add "X-Amz-Content-Sha256", valid_600129
  var valid_600130 = header.getOrDefault("X-Amz-Algorithm")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Algorithm", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Signature")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Signature", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-SignedHeaders", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-Credential")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-Credential", valid_600133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600135: Call_DeletePolicy_600123; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified policy from your organization. Before you perform this operation, you must first detach the policy from all organizational units (OUs), roots, and accounts.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_600135.validator(path, query, header, formData, body)
  let scheme = call_600135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600135.url(scheme.get, call_600135.host, call_600135.base,
                         call_600135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600135, url, valid)

proc call*(call_600136: Call_DeletePolicy_600123; body: JsonNode): Recallable =
  ## deletePolicy
  ## <p>Deletes the specified policy from your organization. Before you perform this operation, you must first detach the policy from all organizational units (OUs), roots, and accounts.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_600137 = newJObject()
  if body != nil:
    body_600137 = body
  result = call_600136.call(nil, nil, nil, nil, body_600137)

var deletePolicy* = Call_DeletePolicy_600123(name: "deletePolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DeletePolicy",
    validator: validate_DeletePolicy_600124, base: "/", url: url_DeletePolicy_600125,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccount_600138 = ref object of OpenApiRestCall_599369
proc url_DescribeAccount_600140(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAccount_600139(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Retrieves AWS Organizations related information about the specified account.</p> <p>This operation can be called only from the organization's master account.</p>
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
  var valid_600141 = header.getOrDefault("X-Amz-Date")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "X-Amz-Date", valid_600141
  var valid_600142 = header.getOrDefault("X-Amz-Security-Token")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Security-Token", valid_600142
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600143 = header.getOrDefault("X-Amz-Target")
  valid_600143 = validateParameter(valid_600143, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribeAccount"))
  if valid_600143 != nil:
    section.add "X-Amz-Target", valid_600143
  var valid_600144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600144 = validateParameter(valid_600144, JString, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "X-Amz-Content-Sha256", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-Algorithm")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Algorithm", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Signature")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Signature", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-SignedHeaders", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-Credential")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-Credential", valid_600148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600150: Call_DescribeAccount_600138; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves AWS Organizations related information about the specified account.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_600150.validator(path, query, header, formData, body)
  let scheme = call_600150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600150.url(scheme.get, call_600150.host, call_600150.base,
                         call_600150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600150, url, valid)

proc call*(call_600151: Call_DescribeAccount_600138; body: JsonNode): Recallable =
  ## describeAccount
  ## <p>Retrieves AWS Organizations related information about the specified account.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_600152 = newJObject()
  if body != nil:
    body_600152 = body
  result = call_600151.call(nil, nil, nil, nil, body_600152)

var describeAccount* = Call_DescribeAccount_600138(name: "describeAccount",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribeAccount",
    validator: validate_DescribeAccount_600139, base: "/", url: url_DescribeAccount_600140,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCreateAccountStatus_600153 = ref object of OpenApiRestCall_599369
proc url_DescribeCreateAccountStatus_600155(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCreateAccountStatus_600154(path: JsonNode; query: JsonNode;
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
  var valid_600156 = header.getOrDefault("X-Amz-Date")
  valid_600156 = validateParameter(valid_600156, JString, required = false,
                                 default = nil)
  if valid_600156 != nil:
    section.add "X-Amz-Date", valid_600156
  var valid_600157 = header.getOrDefault("X-Amz-Security-Token")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Security-Token", valid_600157
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600158 = header.getOrDefault("X-Amz-Target")
  valid_600158 = validateParameter(valid_600158, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribeCreateAccountStatus"))
  if valid_600158 != nil:
    section.add "X-Amz-Target", valid_600158
  var valid_600159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "X-Amz-Content-Sha256", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-Algorithm")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-Algorithm", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Signature")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Signature", valid_600161
  var valid_600162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-SignedHeaders", valid_600162
  var valid_600163 = header.getOrDefault("X-Amz-Credential")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-Credential", valid_600163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600165: Call_DescribeCreateAccountStatus_600153; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the current status of an asynchronous request to create an account.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_600165.validator(path, query, header, formData, body)
  let scheme = call_600165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600165.url(scheme.get, call_600165.host, call_600165.base,
                         call_600165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600165, url, valid)

proc call*(call_600166: Call_DescribeCreateAccountStatus_600153; body: JsonNode): Recallable =
  ## describeCreateAccountStatus
  ## <p>Retrieves the current status of an asynchronous request to create an account.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_600167 = newJObject()
  if body != nil:
    body_600167 = body
  result = call_600166.call(nil, nil, nil, nil, body_600167)

var describeCreateAccountStatus* = Call_DescribeCreateAccountStatus_600153(
    name: "describeCreateAccountStatus", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribeCreateAccountStatus",
    validator: validate_DescribeCreateAccountStatus_600154, base: "/",
    url: url_DescribeCreateAccountStatus_600155,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEffectivePolicy_600168 = ref object of OpenApiRestCall_599369
proc url_DescribeEffectivePolicy_600170(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeEffectivePolicy_600169(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the contents of the effective tag policy for the account. The effective tag policy is the aggregation of any tag policies the account inherits, plus any policy directly that is attached to the account. </p> <p>This action returns information on tag policies only.</p> <p>For more information on policy inheritance, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies-inheritance.html">How Policy Inheritance Works</a> in the <i>AWS Organizations User Guide</i>.</p> <p>This operation can be called from any account in the organization.</p>
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
  var valid_600171 = header.getOrDefault("X-Amz-Date")
  valid_600171 = validateParameter(valid_600171, JString, required = false,
                                 default = nil)
  if valid_600171 != nil:
    section.add "X-Amz-Date", valid_600171
  var valid_600172 = header.getOrDefault("X-Amz-Security-Token")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-Security-Token", valid_600172
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600173 = header.getOrDefault("X-Amz-Target")
  valid_600173 = validateParameter(valid_600173, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribeEffectivePolicy"))
  if valid_600173 != nil:
    section.add "X-Amz-Target", valid_600173
  var valid_600174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "X-Amz-Content-Sha256", valid_600174
  var valid_600175 = header.getOrDefault("X-Amz-Algorithm")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-Algorithm", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-Signature")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-Signature", valid_600176
  var valid_600177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "X-Amz-SignedHeaders", valid_600177
  var valid_600178 = header.getOrDefault("X-Amz-Credential")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "X-Amz-Credential", valid_600178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600180: Call_DescribeEffectivePolicy_600168; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the contents of the effective tag policy for the account. The effective tag policy is the aggregation of any tag policies the account inherits, plus any policy directly that is attached to the account. </p> <p>This action returns information on tag policies only.</p> <p>For more information on policy inheritance, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies-inheritance.html">How Policy Inheritance Works</a> in the <i>AWS Organizations User Guide</i>.</p> <p>This operation can be called from any account in the organization.</p>
  ## 
  let valid = call_600180.validator(path, query, header, formData, body)
  let scheme = call_600180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600180.url(scheme.get, call_600180.host, call_600180.base,
                         call_600180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600180, url, valid)

proc call*(call_600181: Call_DescribeEffectivePolicy_600168; body: JsonNode): Recallable =
  ## describeEffectivePolicy
  ## <p>Returns the contents of the effective tag policy for the account. The effective tag policy is the aggregation of any tag policies the account inherits, plus any policy directly that is attached to the account. </p> <p>This action returns information on tag policies only.</p> <p>For more information on policy inheritance, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies-inheritance.html">How Policy Inheritance Works</a> in the <i>AWS Organizations User Guide</i>.</p> <p>This operation can be called from any account in the organization.</p>
  ##   body: JObject (required)
  var body_600182 = newJObject()
  if body != nil:
    body_600182 = body
  result = call_600181.call(nil, nil, nil, nil, body_600182)

var describeEffectivePolicy* = Call_DescribeEffectivePolicy_600168(
    name: "describeEffectivePolicy", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribeEffectivePolicy",
    validator: validate_DescribeEffectivePolicy_600169, base: "/",
    url: url_DescribeEffectivePolicy_600170, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHandshake_600183 = ref object of OpenApiRestCall_599369
proc url_DescribeHandshake_600185(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeHandshake_600184(path: JsonNode; query: JsonNode;
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
  var valid_600186 = header.getOrDefault("X-Amz-Date")
  valid_600186 = validateParameter(valid_600186, JString, required = false,
                                 default = nil)
  if valid_600186 != nil:
    section.add "X-Amz-Date", valid_600186
  var valid_600187 = header.getOrDefault("X-Amz-Security-Token")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "X-Amz-Security-Token", valid_600187
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600188 = header.getOrDefault("X-Amz-Target")
  valid_600188 = validateParameter(valid_600188, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribeHandshake"))
  if valid_600188 != nil:
    section.add "X-Amz-Target", valid_600188
  var valid_600189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-Content-Sha256", valid_600189
  var valid_600190 = header.getOrDefault("X-Amz-Algorithm")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-Algorithm", valid_600190
  var valid_600191 = header.getOrDefault("X-Amz-Signature")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "X-Amz-Signature", valid_600191
  var valid_600192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "X-Amz-SignedHeaders", valid_600192
  var valid_600193 = header.getOrDefault("X-Amz-Credential")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-Credential", valid_600193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600195: Call_DescribeHandshake_600183; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about a previously requested handshake. The handshake ID comes from the response to the original <a>InviteAccountToOrganization</a> operation that generated the handshake.</p> <p>You can access handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> for only 30 days after they change to that state. They're then deleted and no longer accessible.</p> <p>This operation can be called from any account in the organization.</p>
  ## 
  let valid = call_600195.validator(path, query, header, formData, body)
  let scheme = call_600195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600195.url(scheme.get, call_600195.host, call_600195.base,
                         call_600195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600195, url, valid)

proc call*(call_600196: Call_DescribeHandshake_600183; body: JsonNode): Recallable =
  ## describeHandshake
  ## <p>Retrieves information about a previously requested handshake. The handshake ID comes from the response to the original <a>InviteAccountToOrganization</a> operation that generated the handshake.</p> <p>You can access handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> for only 30 days after they change to that state. They're then deleted and no longer accessible.</p> <p>This operation can be called from any account in the organization.</p>
  ##   body: JObject (required)
  var body_600197 = newJObject()
  if body != nil:
    body_600197 = body
  result = call_600196.call(nil, nil, nil, nil, body_600197)

var describeHandshake* = Call_DescribeHandshake_600183(name: "describeHandshake",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribeHandshake",
    validator: validate_DescribeHandshake_600184, base: "/",
    url: url_DescribeHandshake_600185, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOrganization_600198 = ref object of OpenApiRestCall_599369
proc url_DescribeOrganization_600200(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeOrganization_600199(path: JsonNode; query: JsonNode;
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
  var valid_600201 = header.getOrDefault("X-Amz-Date")
  valid_600201 = validateParameter(valid_600201, JString, required = false,
                                 default = nil)
  if valid_600201 != nil:
    section.add "X-Amz-Date", valid_600201
  var valid_600202 = header.getOrDefault("X-Amz-Security-Token")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "X-Amz-Security-Token", valid_600202
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600203 = header.getOrDefault("X-Amz-Target")
  valid_600203 = validateParameter(valid_600203, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribeOrganization"))
  if valid_600203 != nil:
    section.add "X-Amz-Target", valid_600203
  var valid_600204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "X-Amz-Content-Sha256", valid_600204
  var valid_600205 = header.getOrDefault("X-Amz-Algorithm")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-Algorithm", valid_600205
  var valid_600206 = header.getOrDefault("X-Amz-Signature")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "X-Amz-Signature", valid_600206
  var valid_600207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "X-Amz-SignedHeaders", valid_600207
  var valid_600208 = header.getOrDefault("X-Amz-Credential")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "X-Amz-Credential", valid_600208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600209: Call_DescribeOrganization_600198; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about the organization that the user's account belongs to.</p> <p>This operation can be called from any account in the organization.</p> <note> <p>Even if a policy type is shown as available in the organization, you can disable it separately at the root level with <a>DisablePolicyType</a>. Use <a>ListRoots</a> to see the status of policy types for a specified root.</p> </note>
  ## 
  let valid = call_600209.validator(path, query, header, formData, body)
  let scheme = call_600209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600209.url(scheme.get, call_600209.host, call_600209.base,
                         call_600209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600209, url, valid)

proc call*(call_600210: Call_DescribeOrganization_600198): Recallable =
  ## describeOrganization
  ## <p>Retrieves information about the organization that the user's account belongs to.</p> <p>This operation can be called from any account in the organization.</p> <note> <p>Even if a policy type is shown as available in the organization, you can disable it separately at the root level with <a>DisablePolicyType</a>. Use <a>ListRoots</a> to see the status of policy types for a specified root.</p> </note>
  result = call_600210.call(nil, nil, nil, nil, nil)

var describeOrganization* = Call_DescribeOrganization_600198(
    name: "describeOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribeOrganization",
    validator: validate_DescribeOrganization_600199, base: "/",
    url: url_DescribeOrganization_600200, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOrganizationalUnit_600211 = ref object of OpenApiRestCall_599369
proc url_DescribeOrganizationalUnit_600213(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeOrganizationalUnit_600212(path: JsonNode; query: JsonNode;
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
  var valid_600214 = header.getOrDefault("X-Amz-Date")
  valid_600214 = validateParameter(valid_600214, JString, required = false,
                                 default = nil)
  if valid_600214 != nil:
    section.add "X-Amz-Date", valid_600214
  var valid_600215 = header.getOrDefault("X-Amz-Security-Token")
  valid_600215 = validateParameter(valid_600215, JString, required = false,
                                 default = nil)
  if valid_600215 != nil:
    section.add "X-Amz-Security-Token", valid_600215
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600216 = header.getOrDefault("X-Amz-Target")
  valid_600216 = validateParameter(valid_600216, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribeOrganizationalUnit"))
  if valid_600216 != nil:
    section.add "X-Amz-Target", valid_600216
  var valid_600217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "X-Amz-Content-Sha256", valid_600217
  var valid_600218 = header.getOrDefault("X-Amz-Algorithm")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-Algorithm", valid_600218
  var valid_600219 = header.getOrDefault("X-Amz-Signature")
  valid_600219 = validateParameter(valid_600219, JString, required = false,
                                 default = nil)
  if valid_600219 != nil:
    section.add "X-Amz-Signature", valid_600219
  var valid_600220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600220 = validateParameter(valid_600220, JString, required = false,
                                 default = nil)
  if valid_600220 != nil:
    section.add "X-Amz-SignedHeaders", valid_600220
  var valid_600221 = header.getOrDefault("X-Amz-Credential")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "X-Amz-Credential", valid_600221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600223: Call_DescribeOrganizationalUnit_600211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about an organizational unit (OU).</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_600223.validator(path, query, header, formData, body)
  let scheme = call_600223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600223.url(scheme.get, call_600223.host, call_600223.base,
                         call_600223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600223, url, valid)

proc call*(call_600224: Call_DescribeOrganizationalUnit_600211; body: JsonNode): Recallable =
  ## describeOrganizationalUnit
  ## <p>Retrieves information about an organizational unit (OU).</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_600225 = newJObject()
  if body != nil:
    body_600225 = body
  result = call_600224.call(nil, nil, nil, nil, body_600225)

var describeOrganizationalUnit* = Call_DescribeOrganizationalUnit_600211(
    name: "describeOrganizationalUnit", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribeOrganizationalUnit",
    validator: validate_DescribeOrganizationalUnit_600212, base: "/",
    url: url_DescribeOrganizationalUnit_600213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePolicy_600226 = ref object of OpenApiRestCall_599369
proc url_DescribePolicy_600228(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePolicy_600227(path: JsonNode; query: JsonNode;
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
  var valid_600229 = header.getOrDefault("X-Amz-Date")
  valid_600229 = validateParameter(valid_600229, JString, required = false,
                                 default = nil)
  if valid_600229 != nil:
    section.add "X-Amz-Date", valid_600229
  var valid_600230 = header.getOrDefault("X-Amz-Security-Token")
  valid_600230 = validateParameter(valid_600230, JString, required = false,
                                 default = nil)
  if valid_600230 != nil:
    section.add "X-Amz-Security-Token", valid_600230
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600231 = header.getOrDefault("X-Amz-Target")
  valid_600231 = validateParameter(valid_600231, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribePolicy"))
  if valid_600231 != nil:
    section.add "X-Amz-Target", valid_600231
  var valid_600232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "X-Amz-Content-Sha256", valid_600232
  var valid_600233 = header.getOrDefault("X-Amz-Algorithm")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-Algorithm", valid_600233
  var valid_600234 = header.getOrDefault("X-Amz-Signature")
  valid_600234 = validateParameter(valid_600234, JString, required = false,
                                 default = nil)
  if valid_600234 != nil:
    section.add "X-Amz-Signature", valid_600234
  var valid_600235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600235 = validateParameter(valid_600235, JString, required = false,
                                 default = nil)
  if valid_600235 != nil:
    section.add "X-Amz-SignedHeaders", valid_600235
  var valid_600236 = header.getOrDefault("X-Amz-Credential")
  valid_600236 = validateParameter(valid_600236, JString, required = false,
                                 default = nil)
  if valid_600236 != nil:
    section.add "X-Amz-Credential", valid_600236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600238: Call_DescribePolicy_600226; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about a policy.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_600238.validator(path, query, header, formData, body)
  let scheme = call_600238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600238.url(scheme.get, call_600238.host, call_600238.base,
                         call_600238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600238, url, valid)

proc call*(call_600239: Call_DescribePolicy_600226; body: JsonNode): Recallable =
  ## describePolicy
  ## <p>Retrieves information about a policy.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_600240 = newJObject()
  if body != nil:
    body_600240 = body
  result = call_600239.call(nil, nil, nil, nil, body_600240)

var describePolicy* = Call_DescribePolicy_600226(name: "describePolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribePolicy",
    validator: validate_DescribePolicy_600227, base: "/", url: url_DescribePolicy_600228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachPolicy_600241 = ref object of OpenApiRestCall_599369
proc url_DetachPolicy_600243(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetachPolicy_600242(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Detaches a policy from a target root, organizational unit (OU), or account. If the policy being detached is a service control policy (SCP), the changes to permissions for IAM users and roles in affected accounts are immediate.</p> <p> <b>Note:</b> Every root, OU, and account must have at least one SCP attached. You can replace the default <code>FullAWSAccess</code> policy with one that limits the permissions that can be delegated. To do that, you must attach the replacement policy before you can remove the default one. This is the authorization strategy of using an <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html#orgs_policies_whitelist">allow list</a>. You could instead attach a second SCP and leave the <code>FullAWSAccess</code> SCP still attached. You could then specify <code>"Effect": "Deny"</code> in the second SCP to override the <code>"Effect": "Allow"</code> in the <code>FullAWSAccess</code> policy (or any other attached SCP). If you take these steps, you're using the authorization strategy of a <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html#orgs_policies_blacklist">deny list</a>. </p> <p>This operation can be called only from the organization's master account.</p>
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
  var valid_600244 = header.getOrDefault("X-Amz-Date")
  valid_600244 = validateParameter(valid_600244, JString, required = false,
                                 default = nil)
  if valid_600244 != nil:
    section.add "X-Amz-Date", valid_600244
  var valid_600245 = header.getOrDefault("X-Amz-Security-Token")
  valid_600245 = validateParameter(valid_600245, JString, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "X-Amz-Security-Token", valid_600245
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600246 = header.getOrDefault("X-Amz-Target")
  valid_600246 = validateParameter(valid_600246, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DetachPolicy"))
  if valid_600246 != nil:
    section.add "X-Amz-Target", valid_600246
  var valid_600247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "X-Amz-Content-Sha256", valid_600247
  var valid_600248 = header.getOrDefault("X-Amz-Algorithm")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "X-Amz-Algorithm", valid_600248
  var valid_600249 = header.getOrDefault("X-Amz-Signature")
  valid_600249 = validateParameter(valid_600249, JString, required = false,
                                 default = nil)
  if valid_600249 != nil:
    section.add "X-Amz-Signature", valid_600249
  var valid_600250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600250 = validateParameter(valid_600250, JString, required = false,
                                 default = nil)
  if valid_600250 != nil:
    section.add "X-Amz-SignedHeaders", valid_600250
  var valid_600251 = header.getOrDefault("X-Amz-Credential")
  valid_600251 = validateParameter(valid_600251, JString, required = false,
                                 default = nil)
  if valid_600251 != nil:
    section.add "X-Amz-Credential", valid_600251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600253: Call_DetachPolicy_600241; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detaches a policy from a target root, organizational unit (OU), or account. If the policy being detached is a service control policy (SCP), the changes to permissions for IAM users and roles in affected accounts are immediate.</p> <p> <b>Note:</b> Every root, OU, and account must have at least one SCP attached. You can replace the default <code>FullAWSAccess</code> policy with one that limits the permissions that can be delegated. To do that, you must attach the replacement policy before you can remove the default one. This is the authorization strategy of using an <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html#orgs_policies_whitelist">allow list</a>. You could instead attach a second SCP and leave the <code>FullAWSAccess</code> SCP still attached. You could then specify <code>"Effect": "Deny"</code> in the second SCP to override the <code>"Effect": "Allow"</code> in the <code>FullAWSAccess</code> policy (or any other attached SCP). If you take these steps, you're using the authorization strategy of a <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html#orgs_policies_blacklist">deny list</a>. </p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_600253.validator(path, query, header, formData, body)
  let scheme = call_600253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600253.url(scheme.get, call_600253.host, call_600253.base,
                         call_600253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600253, url, valid)

proc call*(call_600254: Call_DetachPolicy_600241; body: JsonNode): Recallable =
  ## detachPolicy
  ## <p>Detaches a policy from a target root, organizational unit (OU), or account. If the policy being detached is a service control policy (SCP), the changes to permissions for IAM users and roles in affected accounts are immediate.</p> <p> <b>Note:</b> Every root, OU, and account must have at least one SCP attached. You can replace the default <code>FullAWSAccess</code> policy with one that limits the permissions that can be delegated. To do that, you must attach the replacement policy before you can remove the default one. This is the authorization strategy of using an <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html#orgs_policies_whitelist">allow list</a>. You could instead attach a second SCP and leave the <code>FullAWSAccess</code> SCP still attached. You could then specify <code>"Effect": "Deny"</code> in the second SCP to override the <code>"Effect": "Allow"</code> in the <code>FullAWSAccess</code> policy (or any other attached SCP). If you take these steps, you're using the authorization strategy of a <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html#orgs_policies_blacklist">deny list</a>. </p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_600255 = newJObject()
  if body != nil:
    body_600255 = body
  result = call_600254.call(nil, nil, nil, nil, body_600255)

var detachPolicy* = Call_DetachPolicy_600241(name: "detachPolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DetachPolicy",
    validator: validate_DetachPolicy_600242, base: "/", url: url_DetachPolicy_600243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableAWSServiceAccess_600256 = ref object of OpenApiRestCall_599369
proc url_DisableAWSServiceAccess_600258(protocol: Scheme; host: string; base: string;
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

proc validate_DisableAWSServiceAccess_600257(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Disables the integration of an AWS service (the service that is specified by <code>ServicePrincipal</code>) with AWS Organizations. When you disable integration, the specified service no longer can create a <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html">service-linked role</a> in <i>new</i> accounts in your organization. This means the service can't perform operations on your behalf on any new accounts in your organization. The service can still perform operations in older accounts until the service completes its clean-up from AWS Organizations.</p> <p/> <important> <p>We recommend that you disable integration between AWS Organizations and the specified AWS service by using the console or commands that are provided by the specified service. Doing so ensures that the other service is aware that it can clean up any resources that are required only for the integration. How the service cleans up its resources in the organization's accounts depends on that service. For more information, see the documentation for the other AWS service.</p> </important> <p>After you perform the <code>DisableAWSServiceAccess</code> operation, the specified service can no longer perform operations in your organization's accounts. The only exception is when the operations are explicitly permitted by IAM policies that are attached to your roles. </p> <p>For more information about integrating other services with AWS Organizations, including the list of services that work with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
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
  var valid_600259 = header.getOrDefault("X-Amz-Date")
  valid_600259 = validateParameter(valid_600259, JString, required = false,
                                 default = nil)
  if valid_600259 != nil:
    section.add "X-Amz-Date", valid_600259
  var valid_600260 = header.getOrDefault("X-Amz-Security-Token")
  valid_600260 = validateParameter(valid_600260, JString, required = false,
                                 default = nil)
  if valid_600260 != nil:
    section.add "X-Amz-Security-Token", valid_600260
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600261 = header.getOrDefault("X-Amz-Target")
  valid_600261 = validateParameter(valid_600261, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DisableAWSServiceAccess"))
  if valid_600261 != nil:
    section.add "X-Amz-Target", valid_600261
  var valid_600262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "X-Amz-Content-Sha256", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-Algorithm")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Algorithm", valid_600263
  var valid_600264 = header.getOrDefault("X-Amz-Signature")
  valid_600264 = validateParameter(valid_600264, JString, required = false,
                                 default = nil)
  if valid_600264 != nil:
    section.add "X-Amz-Signature", valid_600264
  var valid_600265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600265 = validateParameter(valid_600265, JString, required = false,
                                 default = nil)
  if valid_600265 != nil:
    section.add "X-Amz-SignedHeaders", valid_600265
  var valid_600266 = header.getOrDefault("X-Amz-Credential")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "X-Amz-Credential", valid_600266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600268: Call_DisableAWSServiceAccess_600256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables the integration of an AWS service (the service that is specified by <code>ServicePrincipal</code>) with AWS Organizations. When you disable integration, the specified service no longer can create a <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html">service-linked role</a> in <i>new</i> accounts in your organization. This means the service can't perform operations on your behalf on any new accounts in your organization. The service can still perform operations in older accounts until the service completes its clean-up from AWS Organizations.</p> <p/> <important> <p>We recommend that you disable integration between AWS Organizations and the specified AWS service by using the console or commands that are provided by the specified service. Doing so ensures that the other service is aware that it can clean up any resources that are required only for the integration. How the service cleans up its resources in the organization's accounts depends on that service. For more information, see the documentation for the other AWS service.</p> </important> <p>After you perform the <code>DisableAWSServiceAccess</code> operation, the specified service can no longer perform operations in your organization's accounts. The only exception is when the operations are explicitly permitted by IAM policies that are attached to your roles. </p> <p>For more information about integrating other services with AWS Organizations, including the list of services that work with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_600268.validator(path, query, header, formData, body)
  let scheme = call_600268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600268.url(scheme.get, call_600268.host, call_600268.base,
                         call_600268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600268, url, valid)

proc call*(call_600269: Call_DisableAWSServiceAccess_600256; body: JsonNode): Recallable =
  ## disableAWSServiceAccess
  ## <p>Disables the integration of an AWS service (the service that is specified by <code>ServicePrincipal</code>) with AWS Organizations. When you disable integration, the specified service no longer can create a <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html">service-linked role</a> in <i>new</i> accounts in your organization. This means the service can't perform operations on your behalf on any new accounts in your organization. The service can still perform operations in older accounts until the service completes its clean-up from AWS Organizations.</p> <p/> <important> <p>We recommend that you disable integration between AWS Organizations and the specified AWS service by using the console or commands that are provided by the specified service. Doing so ensures that the other service is aware that it can clean up any resources that are required only for the integration. How the service cleans up its resources in the organization's accounts depends on that service. For more information, see the documentation for the other AWS service.</p> </important> <p>After you perform the <code>DisableAWSServiceAccess</code> operation, the specified service can no longer perform operations in your organization's accounts. The only exception is when the operations are explicitly permitted by IAM policies that are attached to your roles. </p> <p>For more information about integrating other services with AWS Organizations, including the list of services that work with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_600270 = newJObject()
  if body != nil:
    body_600270 = body
  result = call_600269.call(nil, nil, nil, nil, body_600270)

var disableAWSServiceAccess* = Call_DisableAWSServiceAccess_600256(
    name: "disableAWSServiceAccess", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DisableAWSServiceAccess",
    validator: validate_DisableAWSServiceAccess_600257, base: "/",
    url: url_DisableAWSServiceAccess_600258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisablePolicyType_600271 = ref object of OpenApiRestCall_599369
proc url_DisablePolicyType_600273(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisablePolicyType_600272(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Disables an organizational control policy type in a root and detaches all policies of that type from the organization root, OUs, and accounts. A policy of a certain type can be attached to entities in a root only if that type is enabled in the root. After you perform this operation, you no longer can attach policies of the specified type to that root or to any organizational unit (OU) or account in that root. You can undo this by using the <a>EnablePolicyType</a> operation.</p> <p>This is an asynchronous request that AWS performs in the background. If you disable a policy for a root, it still appears enabled for the organization if <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">all features</a> are enabled for the organization. AWS recommends that you first use <a>ListRoots</a> to see the status of policy types for a specified root, and then use this operation. </p> <p>This operation can be called only from the organization's master account.</p> <p> To view the status of available policy types in the organization, use <a>DescribeOrganization</a>.</p>
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
  var valid_600274 = header.getOrDefault("X-Amz-Date")
  valid_600274 = validateParameter(valid_600274, JString, required = false,
                                 default = nil)
  if valid_600274 != nil:
    section.add "X-Amz-Date", valid_600274
  var valid_600275 = header.getOrDefault("X-Amz-Security-Token")
  valid_600275 = validateParameter(valid_600275, JString, required = false,
                                 default = nil)
  if valid_600275 != nil:
    section.add "X-Amz-Security-Token", valid_600275
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600276 = header.getOrDefault("X-Amz-Target")
  valid_600276 = validateParameter(valid_600276, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DisablePolicyType"))
  if valid_600276 != nil:
    section.add "X-Amz-Target", valid_600276
  var valid_600277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "X-Amz-Content-Sha256", valid_600277
  var valid_600278 = header.getOrDefault("X-Amz-Algorithm")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Algorithm", valid_600278
  var valid_600279 = header.getOrDefault("X-Amz-Signature")
  valid_600279 = validateParameter(valid_600279, JString, required = false,
                                 default = nil)
  if valid_600279 != nil:
    section.add "X-Amz-Signature", valid_600279
  var valid_600280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600280 = validateParameter(valid_600280, JString, required = false,
                                 default = nil)
  if valid_600280 != nil:
    section.add "X-Amz-SignedHeaders", valid_600280
  var valid_600281 = header.getOrDefault("X-Amz-Credential")
  valid_600281 = validateParameter(valid_600281, JString, required = false,
                                 default = nil)
  if valid_600281 != nil:
    section.add "X-Amz-Credential", valid_600281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600283: Call_DisablePolicyType_600271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables an organizational control policy type in a root and detaches all policies of that type from the organization root, OUs, and accounts. A policy of a certain type can be attached to entities in a root only if that type is enabled in the root. After you perform this operation, you no longer can attach policies of the specified type to that root or to any organizational unit (OU) or account in that root. You can undo this by using the <a>EnablePolicyType</a> operation.</p> <p>This is an asynchronous request that AWS performs in the background. If you disable a policy for a root, it still appears enabled for the organization if <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">all features</a> are enabled for the organization. AWS recommends that you first use <a>ListRoots</a> to see the status of policy types for a specified root, and then use this operation. </p> <p>This operation can be called only from the organization's master account.</p> <p> To view the status of available policy types in the organization, use <a>DescribeOrganization</a>.</p>
  ## 
  let valid = call_600283.validator(path, query, header, formData, body)
  let scheme = call_600283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600283.url(scheme.get, call_600283.host, call_600283.base,
                         call_600283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600283, url, valid)

proc call*(call_600284: Call_DisablePolicyType_600271; body: JsonNode): Recallable =
  ## disablePolicyType
  ## <p>Disables an organizational control policy type in a root and detaches all policies of that type from the organization root, OUs, and accounts. A policy of a certain type can be attached to entities in a root only if that type is enabled in the root. After you perform this operation, you no longer can attach policies of the specified type to that root or to any organizational unit (OU) or account in that root. You can undo this by using the <a>EnablePolicyType</a> operation.</p> <p>This is an asynchronous request that AWS performs in the background. If you disable a policy for a root, it still appears enabled for the organization if <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">all features</a> are enabled for the organization. AWS recommends that you first use <a>ListRoots</a> to see the status of policy types for a specified root, and then use this operation. </p> <p>This operation can be called only from the organization's master account.</p> <p> To view the status of available policy types in the organization, use <a>DescribeOrganization</a>.</p>
  ##   body: JObject (required)
  var body_600285 = newJObject()
  if body != nil:
    body_600285 = body
  result = call_600284.call(nil, nil, nil, nil, body_600285)

var disablePolicyType* = Call_DisablePolicyType_600271(name: "disablePolicyType",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DisablePolicyType",
    validator: validate_DisablePolicyType_600272, base: "/",
    url: url_DisablePolicyType_600273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableAWSServiceAccess_600286 = ref object of OpenApiRestCall_599369
proc url_EnableAWSServiceAccess_600288(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableAWSServiceAccess_600287(path: JsonNode; query: JsonNode;
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
  var valid_600289 = header.getOrDefault("X-Amz-Date")
  valid_600289 = validateParameter(valid_600289, JString, required = false,
                                 default = nil)
  if valid_600289 != nil:
    section.add "X-Amz-Date", valid_600289
  var valid_600290 = header.getOrDefault("X-Amz-Security-Token")
  valid_600290 = validateParameter(valid_600290, JString, required = false,
                                 default = nil)
  if valid_600290 != nil:
    section.add "X-Amz-Security-Token", valid_600290
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600291 = header.getOrDefault("X-Amz-Target")
  valid_600291 = validateParameter(valid_600291, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.EnableAWSServiceAccess"))
  if valid_600291 != nil:
    section.add "X-Amz-Target", valid_600291
  var valid_600292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600292 = validateParameter(valid_600292, JString, required = false,
                                 default = nil)
  if valid_600292 != nil:
    section.add "X-Amz-Content-Sha256", valid_600292
  var valid_600293 = header.getOrDefault("X-Amz-Algorithm")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Algorithm", valid_600293
  var valid_600294 = header.getOrDefault("X-Amz-Signature")
  valid_600294 = validateParameter(valid_600294, JString, required = false,
                                 default = nil)
  if valid_600294 != nil:
    section.add "X-Amz-Signature", valid_600294
  var valid_600295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600295 = validateParameter(valid_600295, JString, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "X-Amz-SignedHeaders", valid_600295
  var valid_600296 = header.getOrDefault("X-Amz-Credential")
  valid_600296 = validateParameter(valid_600296, JString, required = false,
                                 default = nil)
  if valid_600296 != nil:
    section.add "X-Amz-Credential", valid_600296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600298: Call_EnableAWSServiceAccess_600286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the integration of an AWS service (the service that is specified by <code>ServicePrincipal</code>) with AWS Organizations. When you enable integration, you allow the specified service to create a <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html">service-linked role</a> in all the accounts in your organization. This allows the service to perform operations on your behalf in your organization and its accounts.</p> <important> <p>We recommend that you enable integration between AWS Organizations and the specified AWS service by using the console or commands that are provided by the specified service. Doing so ensures that the service is aware that it can create the resources that are required for the integration. How the service creates those resources in the organization's accounts depends on that service. For more information, see the documentation for the other AWS service.</p> </important> <p>For more information about enabling services to integrate with AWS Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account and only if the organization has <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">enabled all features</a>.</p>
  ## 
  let valid = call_600298.validator(path, query, header, formData, body)
  let scheme = call_600298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600298.url(scheme.get, call_600298.host, call_600298.base,
                         call_600298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600298, url, valid)

proc call*(call_600299: Call_EnableAWSServiceAccess_600286; body: JsonNode): Recallable =
  ## enableAWSServiceAccess
  ## <p>Enables the integration of an AWS service (the service that is specified by <code>ServicePrincipal</code>) with AWS Organizations. When you enable integration, you allow the specified service to create a <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html">service-linked role</a> in all the accounts in your organization. This allows the service to perform operations on your behalf in your organization and its accounts.</p> <important> <p>We recommend that you enable integration between AWS Organizations and the specified AWS service by using the console or commands that are provided by the specified service. Doing so ensures that the service is aware that it can create the resources that are required for the integration. How the service creates those resources in the organization's accounts depends on that service. For more information, see the documentation for the other AWS service.</p> </important> <p>For more information about enabling services to integrate with AWS Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account and only if the organization has <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">enabled all features</a>.</p>
  ##   body: JObject (required)
  var body_600300 = newJObject()
  if body != nil:
    body_600300 = body
  result = call_600299.call(nil, nil, nil, nil, body_600300)

var enableAWSServiceAccess* = Call_EnableAWSServiceAccess_600286(
    name: "enableAWSServiceAccess", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.EnableAWSServiceAccess",
    validator: validate_EnableAWSServiceAccess_600287, base: "/",
    url: url_EnableAWSServiceAccess_600288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableAllFeatures_600301 = ref object of OpenApiRestCall_599369
proc url_EnableAllFeatures_600303(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableAllFeatures_600302(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Enables all features in an organization. This enables the use of organization policies that can restrict the services and actions that can be called in each account. Until you enable all features, you have access only to consolidated billing. You can't use any of the advanced account administration features that AWS Organizations supports. For more information, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">Enabling All Features in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <p>This operation is required only for organizations that were created explicitly with only the consolidated billing features enabled. Calling this operation sends a handshake to every invited account in the organization. The feature set change can be finalized and the additional features enabled only after all administrators in the invited accounts approve the change. Accepting the handshake approves the change.</p> </important> <p>After you enable all features, you can separately enable or disable individual policy types in a root using <a>EnablePolicyType</a> and <a>DisablePolicyType</a>. To see the status of policy types in a root, use <a>ListRoots</a>.</p> <p>After all invited member accounts accept the handshake, you finalize the feature set change by accepting the handshake that contains <code>"Action": "ENABLE_ALL_FEATURES"</code>. This completes the change.</p> <p>After you enable all features in your organization, the master account in the organization can apply policies on all member accounts. These policies can restrict what users and even administrators in those accounts can do. The master account can apply policies that prevent accounts from leaving the organization. Ensure that your account administrators are aware of this.</p> <p>This operation can be called only from the organization's master account. </p>
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
  var valid_600304 = header.getOrDefault("X-Amz-Date")
  valid_600304 = validateParameter(valid_600304, JString, required = false,
                                 default = nil)
  if valid_600304 != nil:
    section.add "X-Amz-Date", valid_600304
  var valid_600305 = header.getOrDefault("X-Amz-Security-Token")
  valid_600305 = validateParameter(valid_600305, JString, required = false,
                                 default = nil)
  if valid_600305 != nil:
    section.add "X-Amz-Security-Token", valid_600305
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600306 = header.getOrDefault("X-Amz-Target")
  valid_600306 = validateParameter(valid_600306, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.EnableAllFeatures"))
  if valid_600306 != nil:
    section.add "X-Amz-Target", valid_600306
  var valid_600307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600307 = validateParameter(valid_600307, JString, required = false,
                                 default = nil)
  if valid_600307 != nil:
    section.add "X-Amz-Content-Sha256", valid_600307
  var valid_600308 = header.getOrDefault("X-Amz-Algorithm")
  valid_600308 = validateParameter(valid_600308, JString, required = false,
                                 default = nil)
  if valid_600308 != nil:
    section.add "X-Amz-Algorithm", valid_600308
  var valid_600309 = header.getOrDefault("X-Amz-Signature")
  valid_600309 = validateParameter(valid_600309, JString, required = false,
                                 default = nil)
  if valid_600309 != nil:
    section.add "X-Amz-Signature", valid_600309
  var valid_600310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600310 = validateParameter(valid_600310, JString, required = false,
                                 default = nil)
  if valid_600310 != nil:
    section.add "X-Amz-SignedHeaders", valid_600310
  var valid_600311 = header.getOrDefault("X-Amz-Credential")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "X-Amz-Credential", valid_600311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600313: Call_EnableAllFeatures_600301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables all features in an organization. This enables the use of organization policies that can restrict the services and actions that can be called in each account. Until you enable all features, you have access only to consolidated billing. You can't use any of the advanced account administration features that AWS Organizations supports. For more information, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">Enabling All Features in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <p>This operation is required only for organizations that were created explicitly with only the consolidated billing features enabled. Calling this operation sends a handshake to every invited account in the organization. The feature set change can be finalized and the additional features enabled only after all administrators in the invited accounts approve the change. Accepting the handshake approves the change.</p> </important> <p>After you enable all features, you can separately enable or disable individual policy types in a root using <a>EnablePolicyType</a> and <a>DisablePolicyType</a>. To see the status of policy types in a root, use <a>ListRoots</a>.</p> <p>After all invited member accounts accept the handshake, you finalize the feature set change by accepting the handshake that contains <code>"Action": "ENABLE_ALL_FEATURES"</code>. This completes the change.</p> <p>After you enable all features in your organization, the master account in the organization can apply policies on all member accounts. These policies can restrict what users and even administrators in those accounts can do. The master account can apply policies that prevent accounts from leaving the organization. Ensure that your account administrators are aware of this.</p> <p>This operation can be called only from the organization's master account. </p>
  ## 
  let valid = call_600313.validator(path, query, header, formData, body)
  let scheme = call_600313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600313.url(scheme.get, call_600313.host, call_600313.base,
                         call_600313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600313, url, valid)

proc call*(call_600314: Call_EnableAllFeatures_600301; body: JsonNode): Recallable =
  ## enableAllFeatures
  ## <p>Enables all features in an organization. This enables the use of organization policies that can restrict the services and actions that can be called in each account. Until you enable all features, you have access only to consolidated billing. You can't use any of the advanced account administration features that AWS Organizations supports. For more information, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">Enabling All Features in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <p>This operation is required only for organizations that were created explicitly with only the consolidated billing features enabled. Calling this operation sends a handshake to every invited account in the organization. The feature set change can be finalized and the additional features enabled only after all administrators in the invited accounts approve the change. Accepting the handshake approves the change.</p> </important> <p>After you enable all features, you can separately enable or disable individual policy types in a root using <a>EnablePolicyType</a> and <a>DisablePolicyType</a>. To see the status of policy types in a root, use <a>ListRoots</a>.</p> <p>After all invited member accounts accept the handshake, you finalize the feature set change by accepting the handshake that contains <code>"Action": "ENABLE_ALL_FEATURES"</code>. This completes the change.</p> <p>After you enable all features in your organization, the master account in the organization can apply policies on all member accounts. These policies can restrict what users and even administrators in those accounts can do. The master account can apply policies that prevent accounts from leaving the organization. Ensure that your account administrators are aware of this.</p> <p>This operation can be called only from the organization's master account. </p>
  ##   body: JObject (required)
  var body_600315 = newJObject()
  if body != nil:
    body_600315 = body
  result = call_600314.call(nil, nil, nil, nil, body_600315)

var enableAllFeatures* = Call_EnableAllFeatures_600301(name: "enableAllFeatures",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.EnableAllFeatures",
    validator: validate_EnableAllFeatures_600302, base: "/",
    url: url_EnableAllFeatures_600303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnablePolicyType_600316 = ref object of OpenApiRestCall_599369
proc url_EnablePolicyType_600318(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnablePolicyType_600317(path: JsonNode; query: JsonNode;
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
  var valid_600319 = header.getOrDefault("X-Amz-Date")
  valid_600319 = validateParameter(valid_600319, JString, required = false,
                                 default = nil)
  if valid_600319 != nil:
    section.add "X-Amz-Date", valid_600319
  var valid_600320 = header.getOrDefault("X-Amz-Security-Token")
  valid_600320 = validateParameter(valid_600320, JString, required = false,
                                 default = nil)
  if valid_600320 != nil:
    section.add "X-Amz-Security-Token", valid_600320
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600321 = header.getOrDefault("X-Amz-Target")
  valid_600321 = validateParameter(valid_600321, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.EnablePolicyType"))
  if valid_600321 != nil:
    section.add "X-Amz-Target", valid_600321
  var valid_600322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600322 = validateParameter(valid_600322, JString, required = false,
                                 default = nil)
  if valid_600322 != nil:
    section.add "X-Amz-Content-Sha256", valid_600322
  var valid_600323 = header.getOrDefault("X-Amz-Algorithm")
  valid_600323 = validateParameter(valid_600323, JString, required = false,
                                 default = nil)
  if valid_600323 != nil:
    section.add "X-Amz-Algorithm", valid_600323
  var valid_600324 = header.getOrDefault("X-Amz-Signature")
  valid_600324 = validateParameter(valid_600324, JString, required = false,
                                 default = nil)
  if valid_600324 != nil:
    section.add "X-Amz-Signature", valid_600324
  var valid_600325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600325 = validateParameter(valid_600325, JString, required = false,
                                 default = nil)
  if valid_600325 != nil:
    section.add "X-Amz-SignedHeaders", valid_600325
  var valid_600326 = header.getOrDefault("X-Amz-Credential")
  valid_600326 = validateParameter(valid_600326, JString, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "X-Amz-Credential", valid_600326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600328: Call_EnablePolicyType_600316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables a policy type in a root. After you enable a policy type in a root, you can attach policies of that type to the root, any organizational unit (OU), or account in that root. You can undo this by using the <a>DisablePolicyType</a> operation.</p> <p>This is an asynchronous request that AWS performs in the background. AWS recommends that you first use <a>ListRoots</a> to see the status of policy types for a specified root, and then use this operation. </p> <p>This operation can be called only from the organization's master account.</p> <p>You can enable a policy type in a root only if that policy type is available in the organization. To view the status of available policy types in the organization, use <a>DescribeOrganization</a>.</p>
  ## 
  let valid = call_600328.validator(path, query, header, formData, body)
  let scheme = call_600328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600328.url(scheme.get, call_600328.host, call_600328.base,
                         call_600328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600328, url, valid)

proc call*(call_600329: Call_EnablePolicyType_600316; body: JsonNode): Recallable =
  ## enablePolicyType
  ## <p>Enables a policy type in a root. After you enable a policy type in a root, you can attach policies of that type to the root, any organizational unit (OU), or account in that root. You can undo this by using the <a>DisablePolicyType</a> operation.</p> <p>This is an asynchronous request that AWS performs in the background. AWS recommends that you first use <a>ListRoots</a> to see the status of policy types for a specified root, and then use this operation. </p> <p>This operation can be called only from the organization's master account.</p> <p>You can enable a policy type in a root only if that policy type is available in the organization. To view the status of available policy types in the organization, use <a>DescribeOrganization</a>.</p>
  ##   body: JObject (required)
  var body_600330 = newJObject()
  if body != nil:
    body_600330 = body
  result = call_600329.call(nil, nil, nil, nil, body_600330)

var enablePolicyType* = Call_EnablePolicyType_600316(name: "enablePolicyType",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.EnablePolicyType",
    validator: validate_EnablePolicyType_600317, base: "/",
    url: url_EnablePolicyType_600318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteAccountToOrganization_600331 = ref object of OpenApiRestCall_599369
proc url_InviteAccountToOrganization_600333(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_InviteAccountToOrganization_600332(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sends an invitation to another account to join your organization as a member account. AWS Organizations sends email on your behalf to the email address that is associated with the other account's owner. The invitation is implemented as a <a>Handshake</a> whose details are in the response.</p> <important> <ul> <li> <p>You can invite AWS accounts only from the same seller as the master account. For example, assume that your organization's master account was created by Amazon Internet Services Pvt. Ltd (AISPL), an AWS seller in India. You can invite only other AISPL accounts to your organization. You can't combine accounts from AISPL and AWS or from any other AWS seller. For more information, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/useconsolidatedbilliing-India.html">Consolidated Billing in India</a>.</p> </li> <li> <p>You might receive an exception that indicates that you exceeded your account limits for the organization or that the operation failed because your organization is still initializing. If so, wait one hour and then try again. If the error persists after an hour, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> </ul> </important> <p>This operation can be called only from the organization's master account.</p>
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
  var valid_600334 = header.getOrDefault("X-Amz-Date")
  valid_600334 = validateParameter(valid_600334, JString, required = false,
                                 default = nil)
  if valid_600334 != nil:
    section.add "X-Amz-Date", valid_600334
  var valid_600335 = header.getOrDefault("X-Amz-Security-Token")
  valid_600335 = validateParameter(valid_600335, JString, required = false,
                                 default = nil)
  if valid_600335 != nil:
    section.add "X-Amz-Security-Token", valid_600335
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600336 = header.getOrDefault("X-Amz-Target")
  valid_600336 = validateParameter(valid_600336, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.InviteAccountToOrganization"))
  if valid_600336 != nil:
    section.add "X-Amz-Target", valid_600336
  var valid_600337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600337 = validateParameter(valid_600337, JString, required = false,
                                 default = nil)
  if valid_600337 != nil:
    section.add "X-Amz-Content-Sha256", valid_600337
  var valid_600338 = header.getOrDefault("X-Amz-Algorithm")
  valid_600338 = validateParameter(valid_600338, JString, required = false,
                                 default = nil)
  if valid_600338 != nil:
    section.add "X-Amz-Algorithm", valid_600338
  var valid_600339 = header.getOrDefault("X-Amz-Signature")
  valid_600339 = validateParameter(valid_600339, JString, required = false,
                                 default = nil)
  if valid_600339 != nil:
    section.add "X-Amz-Signature", valid_600339
  var valid_600340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600340 = validateParameter(valid_600340, JString, required = false,
                                 default = nil)
  if valid_600340 != nil:
    section.add "X-Amz-SignedHeaders", valid_600340
  var valid_600341 = header.getOrDefault("X-Amz-Credential")
  valid_600341 = validateParameter(valid_600341, JString, required = false,
                                 default = nil)
  if valid_600341 != nil:
    section.add "X-Amz-Credential", valid_600341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600343: Call_InviteAccountToOrganization_600331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends an invitation to another account to join your organization as a member account. AWS Organizations sends email on your behalf to the email address that is associated with the other account's owner. The invitation is implemented as a <a>Handshake</a> whose details are in the response.</p> <important> <ul> <li> <p>You can invite AWS accounts only from the same seller as the master account. For example, assume that your organization's master account was created by Amazon Internet Services Pvt. Ltd (AISPL), an AWS seller in India. You can invite only other AISPL accounts to your organization. You can't combine accounts from AISPL and AWS or from any other AWS seller. For more information, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/useconsolidatedbilliing-India.html">Consolidated Billing in India</a>.</p> </li> <li> <p>You might receive an exception that indicates that you exceeded your account limits for the organization or that the operation failed because your organization is still initializing. If so, wait one hour and then try again. If the error persists after an hour, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> </ul> </important> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_600343.validator(path, query, header, formData, body)
  let scheme = call_600343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600343.url(scheme.get, call_600343.host, call_600343.base,
                         call_600343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600343, url, valid)

proc call*(call_600344: Call_InviteAccountToOrganization_600331; body: JsonNode): Recallable =
  ## inviteAccountToOrganization
  ## <p>Sends an invitation to another account to join your organization as a member account. AWS Organizations sends email on your behalf to the email address that is associated with the other account's owner. The invitation is implemented as a <a>Handshake</a> whose details are in the response.</p> <important> <ul> <li> <p>You can invite AWS accounts only from the same seller as the master account. For example, assume that your organization's master account was created by Amazon Internet Services Pvt. Ltd (AISPL), an AWS seller in India. You can invite only other AISPL accounts to your organization. You can't combine accounts from AISPL and AWS or from any other AWS seller. For more information, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/useconsolidatedbilliing-India.html">Consolidated Billing in India</a>.</p> </li> <li> <p>You might receive an exception that indicates that you exceeded your account limits for the organization or that the operation failed because your organization is still initializing. If so, wait one hour and then try again. If the error persists after an hour, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> </ul> </important> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_600345 = newJObject()
  if body != nil:
    body_600345 = body
  result = call_600344.call(nil, nil, nil, nil, body_600345)

var inviteAccountToOrganization* = Call_InviteAccountToOrganization_600331(
    name: "inviteAccountToOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.InviteAccountToOrganization",
    validator: validate_InviteAccountToOrganization_600332, base: "/",
    url: url_InviteAccountToOrganization_600333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_LeaveOrganization_600346 = ref object of OpenApiRestCall_599369
proc url_LeaveOrganization_600348(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_LeaveOrganization_600347(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Removes a member account from its parent organization. This version of the operation is performed by the account that wants to leave. To remove a member account as a user in the master account, use <a>RemoveAccountFromOrganization</a> instead.</p> <p>This operation can be called only from a member account in the organization.</p> <important> <ul> <li> <p>The master account in an organization with all features enabled can set service control policies (SCPs) that can restrict what administrators of member accounts can do. These restrictions can include preventing member accounts from successfully calling <code>LeaveOrganization</code>. </p> </li> <li> <p>You can leave an organization as a member account only if the account is configured with the information required to operate as a standalone account. When you create an account in an organization using the AWS Organizations console, API, or CLI, the information required of standalone accounts is <i>not</i> automatically collected. For each account that you want to make standalone, you must accept the end user license agreement (EULA). You must also choose a support plan, provide and verify the required contact information, and provide a current payment method. AWS uses the payment method to charge for any billable (not free tier) AWS activity that occurs while the account isn't attached to an organization. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization when all required account information has not yet been provided</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>You can leave an organization only after you enable IAM user access to billing in your account. For more information, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html#ControllingAccessWebsite-Activate">Activating Access to the Billing and Cost Management Console</a> in the <i>AWS Billing and Cost Management User Guide.</i> </p> </li> </ul> </important>
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
  var valid_600349 = header.getOrDefault("X-Amz-Date")
  valid_600349 = validateParameter(valid_600349, JString, required = false,
                                 default = nil)
  if valid_600349 != nil:
    section.add "X-Amz-Date", valid_600349
  var valid_600350 = header.getOrDefault("X-Amz-Security-Token")
  valid_600350 = validateParameter(valid_600350, JString, required = false,
                                 default = nil)
  if valid_600350 != nil:
    section.add "X-Amz-Security-Token", valid_600350
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600351 = header.getOrDefault("X-Amz-Target")
  valid_600351 = validateParameter(valid_600351, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.LeaveOrganization"))
  if valid_600351 != nil:
    section.add "X-Amz-Target", valid_600351
  var valid_600352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600352 = validateParameter(valid_600352, JString, required = false,
                                 default = nil)
  if valid_600352 != nil:
    section.add "X-Amz-Content-Sha256", valid_600352
  var valid_600353 = header.getOrDefault("X-Amz-Algorithm")
  valid_600353 = validateParameter(valid_600353, JString, required = false,
                                 default = nil)
  if valid_600353 != nil:
    section.add "X-Amz-Algorithm", valid_600353
  var valid_600354 = header.getOrDefault("X-Amz-Signature")
  valid_600354 = validateParameter(valid_600354, JString, required = false,
                                 default = nil)
  if valid_600354 != nil:
    section.add "X-Amz-Signature", valid_600354
  var valid_600355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600355 = validateParameter(valid_600355, JString, required = false,
                                 default = nil)
  if valid_600355 != nil:
    section.add "X-Amz-SignedHeaders", valid_600355
  var valid_600356 = header.getOrDefault("X-Amz-Credential")
  valid_600356 = validateParameter(valid_600356, JString, required = false,
                                 default = nil)
  if valid_600356 != nil:
    section.add "X-Amz-Credential", valid_600356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600357: Call_LeaveOrganization_600346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a member account from its parent organization. This version of the operation is performed by the account that wants to leave. To remove a member account as a user in the master account, use <a>RemoveAccountFromOrganization</a> instead.</p> <p>This operation can be called only from a member account in the organization.</p> <important> <ul> <li> <p>The master account in an organization with all features enabled can set service control policies (SCPs) that can restrict what administrators of member accounts can do. These restrictions can include preventing member accounts from successfully calling <code>LeaveOrganization</code>. </p> </li> <li> <p>You can leave an organization as a member account only if the account is configured with the information required to operate as a standalone account. When you create an account in an organization using the AWS Organizations console, API, or CLI, the information required of standalone accounts is <i>not</i> automatically collected. For each account that you want to make standalone, you must accept the end user license agreement (EULA). You must also choose a support plan, provide and verify the required contact information, and provide a current payment method. AWS uses the payment method to charge for any billable (not free tier) AWS activity that occurs while the account isn't attached to an organization. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization when all required account information has not yet been provided</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>You can leave an organization only after you enable IAM user access to billing in your account. For more information, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html#ControllingAccessWebsite-Activate">Activating Access to the Billing and Cost Management Console</a> in the <i>AWS Billing and Cost Management User Guide.</i> </p> </li> </ul> </important>
  ## 
  let valid = call_600357.validator(path, query, header, formData, body)
  let scheme = call_600357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600357.url(scheme.get, call_600357.host, call_600357.base,
                         call_600357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600357, url, valid)

proc call*(call_600358: Call_LeaveOrganization_600346): Recallable =
  ## leaveOrganization
  ## <p>Removes a member account from its parent organization. This version of the operation is performed by the account that wants to leave. To remove a member account as a user in the master account, use <a>RemoveAccountFromOrganization</a> instead.</p> <p>This operation can be called only from a member account in the organization.</p> <important> <ul> <li> <p>The master account in an organization with all features enabled can set service control policies (SCPs) that can restrict what administrators of member accounts can do. These restrictions can include preventing member accounts from successfully calling <code>LeaveOrganization</code>. </p> </li> <li> <p>You can leave an organization as a member account only if the account is configured with the information required to operate as a standalone account. When you create an account in an organization using the AWS Organizations console, API, or CLI, the information required of standalone accounts is <i>not</i> automatically collected. For each account that you want to make standalone, you must accept the end user license agreement (EULA). You must also choose a support plan, provide and verify the required contact information, and provide a current payment method. AWS uses the payment method to charge for any billable (not free tier) AWS activity that occurs while the account isn't attached to an organization. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization when all required account information has not yet been provided</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>You can leave an organization only after you enable IAM user access to billing in your account. For more information, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html#ControllingAccessWebsite-Activate">Activating Access to the Billing and Cost Management Console</a> in the <i>AWS Billing and Cost Management User Guide.</i> </p> </li> </ul> </important>
  result = call_600358.call(nil, nil, nil, nil, nil)

var leaveOrganization* = Call_LeaveOrganization_600346(name: "leaveOrganization",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.LeaveOrganization",
    validator: validate_LeaveOrganization_600347, base: "/",
    url: url_LeaveOrganization_600348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAWSServiceAccessForOrganization_600359 = ref object of OpenApiRestCall_599369
proc url_ListAWSServiceAccessForOrganization_600361(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAWSServiceAccessForOrganization_600360(path: JsonNode;
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
  var valid_600362 = query.getOrDefault("NextToken")
  valid_600362 = validateParameter(valid_600362, JString, required = false,
                                 default = nil)
  if valid_600362 != nil:
    section.add "NextToken", valid_600362
  var valid_600363 = query.getOrDefault("MaxResults")
  valid_600363 = validateParameter(valid_600363, JString, required = false,
                                 default = nil)
  if valid_600363 != nil:
    section.add "MaxResults", valid_600363
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
  var valid_600364 = header.getOrDefault("X-Amz-Date")
  valid_600364 = validateParameter(valid_600364, JString, required = false,
                                 default = nil)
  if valid_600364 != nil:
    section.add "X-Amz-Date", valid_600364
  var valid_600365 = header.getOrDefault("X-Amz-Security-Token")
  valid_600365 = validateParameter(valid_600365, JString, required = false,
                                 default = nil)
  if valid_600365 != nil:
    section.add "X-Amz-Security-Token", valid_600365
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600366 = header.getOrDefault("X-Amz-Target")
  valid_600366 = validateParameter(valid_600366, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListAWSServiceAccessForOrganization"))
  if valid_600366 != nil:
    section.add "X-Amz-Target", valid_600366
  var valid_600367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600367 = validateParameter(valid_600367, JString, required = false,
                                 default = nil)
  if valid_600367 != nil:
    section.add "X-Amz-Content-Sha256", valid_600367
  var valid_600368 = header.getOrDefault("X-Amz-Algorithm")
  valid_600368 = validateParameter(valid_600368, JString, required = false,
                                 default = nil)
  if valid_600368 != nil:
    section.add "X-Amz-Algorithm", valid_600368
  var valid_600369 = header.getOrDefault("X-Amz-Signature")
  valid_600369 = validateParameter(valid_600369, JString, required = false,
                                 default = nil)
  if valid_600369 != nil:
    section.add "X-Amz-Signature", valid_600369
  var valid_600370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600370 = validateParameter(valid_600370, JString, required = false,
                                 default = nil)
  if valid_600370 != nil:
    section.add "X-Amz-SignedHeaders", valid_600370
  var valid_600371 = header.getOrDefault("X-Amz-Credential")
  valid_600371 = validateParameter(valid_600371, JString, required = false,
                                 default = nil)
  if valid_600371 != nil:
    section.add "X-Amz-Credential", valid_600371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600373: Call_ListAWSServiceAccessForOrganization_600359;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of the AWS services that you enabled to integrate with your organization. After a service on this list creates the resources that it requires for the integration, it can perform operations on your organization and its accounts.</p> <p>For more information about integrating other services with AWS Organizations, including the list of services that currently work with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_600373.validator(path, query, header, formData, body)
  let scheme = call_600373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600373.url(scheme.get, call_600373.host, call_600373.base,
                         call_600373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600373, url, valid)

proc call*(call_600374: Call_ListAWSServiceAccessForOrganization_600359;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAWSServiceAccessForOrganization
  ## <p>Returns a list of the AWS services that you enabled to integrate with your organization. After a service on this list creates the resources that it requires for the integration, it can perform operations on your organization and its accounts.</p> <p>For more information about integrating other services with AWS Organizations, including the list of services that currently work with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600375 = newJObject()
  var body_600376 = newJObject()
  add(query_600375, "NextToken", newJString(NextToken))
  if body != nil:
    body_600376 = body
  add(query_600375, "MaxResults", newJString(MaxResults))
  result = call_600374.call(nil, query_600375, nil, nil, body_600376)

var listAWSServiceAccessForOrganization* = Call_ListAWSServiceAccessForOrganization_600359(
    name: "listAWSServiceAccessForOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListAWSServiceAccessForOrganization",
    validator: validate_ListAWSServiceAccessForOrganization_600360, base: "/",
    url: url_ListAWSServiceAccessForOrganization_600361,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccounts_600378 = ref object of OpenApiRestCall_599369
proc url_ListAccounts_600380(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAccounts_600379(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600381 = query.getOrDefault("NextToken")
  valid_600381 = validateParameter(valid_600381, JString, required = false,
                                 default = nil)
  if valid_600381 != nil:
    section.add "NextToken", valid_600381
  var valid_600382 = query.getOrDefault("MaxResults")
  valid_600382 = validateParameter(valid_600382, JString, required = false,
                                 default = nil)
  if valid_600382 != nil:
    section.add "MaxResults", valid_600382
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
  var valid_600383 = header.getOrDefault("X-Amz-Date")
  valid_600383 = validateParameter(valid_600383, JString, required = false,
                                 default = nil)
  if valid_600383 != nil:
    section.add "X-Amz-Date", valid_600383
  var valid_600384 = header.getOrDefault("X-Amz-Security-Token")
  valid_600384 = validateParameter(valid_600384, JString, required = false,
                                 default = nil)
  if valid_600384 != nil:
    section.add "X-Amz-Security-Token", valid_600384
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600385 = header.getOrDefault("X-Amz-Target")
  valid_600385 = validateParameter(valid_600385, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListAccounts"))
  if valid_600385 != nil:
    section.add "X-Amz-Target", valid_600385
  var valid_600386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600386 = validateParameter(valid_600386, JString, required = false,
                                 default = nil)
  if valid_600386 != nil:
    section.add "X-Amz-Content-Sha256", valid_600386
  var valid_600387 = header.getOrDefault("X-Amz-Algorithm")
  valid_600387 = validateParameter(valid_600387, JString, required = false,
                                 default = nil)
  if valid_600387 != nil:
    section.add "X-Amz-Algorithm", valid_600387
  var valid_600388 = header.getOrDefault("X-Amz-Signature")
  valid_600388 = validateParameter(valid_600388, JString, required = false,
                                 default = nil)
  if valid_600388 != nil:
    section.add "X-Amz-Signature", valid_600388
  var valid_600389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600389 = validateParameter(valid_600389, JString, required = false,
                                 default = nil)
  if valid_600389 != nil:
    section.add "X-Amz-SignedHeaders", valid_600389
  var valid_600390 = header.getOrDefault("X-Amz-Credential")
  valid_600390 = validateParameter(valid_600390, JString, required = false,
                                 default = nil)
  if valid_600390 != nil:
    section.add "X-Amz-Credential", valid_600390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600392: Call_ListAccounts_600378; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all the accounts in the organization. To request only the accounts in a specified root or organizational unit (OU), use the <a>ListAccountsForParent</a> operation instead.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_600392.validator(path, query, header, formData, body)
  let scheme = call_600392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600392.url(scheme.get, call_600392.host, call_600392.base,
                         call_600392.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600392, url, valid)

proc call*(call_600393: Call_ListAccounts_600378; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAccounts
  ## <p>Lists all the accounts in the organization. To request only the accounts in a specified root or organizational unit (OU), use the <a>ListAccountsForParent</a> operation instead.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600394 = newJObject()
  var body_600395 = newJObject()
  add(query_600394, "NextToken", newJString(NextToken))
  if body != nil:
    body_600395 = body
  add(query_600394, "MaxResults", newJString(MaxResults))
  result = call_600393.call(nil, query_600394, nil, nil, body_600395)

var listAccounts* = Call_ListAccounts_600378(name: "listAccounts",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListAccounts",
    validator: validate_ListAccounts_600379, base: "/", url: url_ListAccounts_600380,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccountsForParent_600396 = ref object of OpenApiRestCall_599369
proc url_ListAccountsForParent_600398(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAccountsForParent_600397(path: JsonNode; query: JsonNode;
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
  var valid_600399 = query.getOrDefault("NextToken")
  valid_600399 = validateParameter(valid_600399, JString, required = false,
                                 default = nil)
  if valid_600399 != nil:
    section.add "NextToken", valid_600399
  var valid_600400 = query.getOrDefault("MaxResults")
  valid_600400 = validateParameter(valid_600400, JString, required = false,
                                 default = nil)
  if valid_600400 != nil:
    section.add "MaxResults", valid_600400
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
  var valid_600401 = header.getOrDefault("X-Amz-Date")
  valid_600401 = validateParameter(valid_600401, JString, required = false,
                                 default = nil)
  if valid_600401 != nil:
    section.add "X-Amz-Date", valid_600401
  var valid_600402 = header.getOrDefault("X-Amz-Security-Token")
  valid_600402 = validateParameter(valid_600402, JString, required = false,
                                 default = nil)
  if valid_600402 != nil:
    section.add "X-Amz-Security-Token", valid_600402
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600403 = header.getOrDefault("X-Amz-Target")
  valid_600403 = validateParameter(valid_600403, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListAccountsForParent"))
  if valid_600403 != nil:
    section.add "X-Amz-Target", valid_600403
  var valid_600404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600404 = validateParameter(valid_600404, JString, required = false,
                                 default = nil)
  if valid_600404 != nil:
    section.add "X-Amz-Content-Sha256", valid_600404
  var valid_600405 = header.getOrDefault("X-Amz-Algorithm")
  valid_600405 = validateParameter(valid_600405, JString, required = false,
                                 default = nil)
  if valid_600405 != nil:
    section.add "X-Amz-Algorithm", valid_600405
  var valid_600406 = header.getOrDefault("X-Amz-Signature")
  valid_600406 = validateParameter(valid_600406, JString, required = false,
                                 default = nil)
  if valid_600406 != nil:
    section.add "X-Amz-Signature", valid_600406
  var valid_600407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600407 = validateParameter(valid_600407, JString, required = false,
                                 default = nil)
  if valid_600407 != nil:
    section.add "X-Amz-SignedHeaders", valid_600407
  var valid_600408 = header.getOrDefault("X-Amz-Credential")
  valid_600408 = validateParameter(valid_600408, JString, required = false,
                                 default = nil)
  if valid_600408 != nil:
    section.add "X-Amz-Credential", valid_600408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600410: Call_ListAccountsForParent_600396; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the accounts in an organization that are contained by the specified target root or organizational unit (OU). If you specify the root, you get a list of all the accounts that aren't in any OU. If you specify an OU, you get a list of all the accounts in only that OU and not in any child OUs. To get a list of all accounts in the organization, use the <a>ListAccounts</a> operation.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_600410.validator(path, query, header, formData, body)
  let scheme = call_600410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600410.url(scheme.get, call_600410.host, call_600410.base,
                         call_600410.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600410, url, valid)

proc call*(call_600411: Call_ListAccountsForParent_600396; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAccountsForParent
  ## <p>Lists the accounts in an organization that are contained by the specified target root or organizational unit (OU). If you specify the root, you get a list of all the accounts that aren't in any OU. If you specify an OU, you get a list of all the accounts in only that OU and not in any child OUs. To get a list of all accounts in the organization, use the <a>ListAccounts</a> operation.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600412 = newJObject()
  var body_600413 = newJObject()
  add(query_600412, "NextToken", newJString(NextToken))
  if body != nil:
    body_600413 = body
  add(query_600412, "MaxResults", newJString(MaxResults))
  result = call_600411.call(nil, query_600412, nil, nil, body_600413)

var listAccountsForParent* = Call_ListAccountsForParent_600396(
    name: "listAccountsForParent", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListAccountsForParent",
    validator: validate_ListAccountsForParent_600397, base: "/",
    url: url_ListAccountsForParent_600398, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChildren_600414 = ref object of OpenApiRestCall_599369
proc url_ListChildren_600416(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListChildren_600415(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600417 = query.getOrDefault("NextToken")
  valid_600417 = validateParameter(valid_600417, JString, required = false,
                                 default = nil)
  if valid_600417 != nil:
    section.add "NextToken", valid_600417
  var valid_600418 = query.getOrDefault("MaxResults")
  valid_600418 = validateParameter(valid_600418, JString, required = false,
                                 default = nil)
  if valid_600418 != nil:
    section.add "MaxResults", valid_600418
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
  var valid_600419 = header.getOrDefault("X-Amz-Date")
  valid_600419 = validateParameter(valid_600419, JString, required = false,
                                 default = nil)
  if valid_600419 != nil:
    section.add "X-Amz-Date", valid_600419
  var valid_600420 = header.getOrDefault("X-Amz-Security-Token")
  valid_600420 = validateParameter(valid_600420, JString, required = false,
                                 default = nil)
  if valid_600420 != nil:
    section.add "X-Amz-Security-Token", valid_600420
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600421 = header.getOrDefault("X-Amz-Target")
  valid_600421 = validateParameter(valid_600421, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListChildren"))
  if valid_600421 != nil:
    section.add "X-Amz-Target", valid_600421
  var valid_600422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600422 = validateParameter(valid_600422, JString, required = false,
                                 default = nil)
  if valid_600422 != nil:
    section.add "X-Amz-Content-Sha256", valid_600422
  var valid_600423 = header.getOrDefault("X-Amz-Algorithm")
  valid_600423 = validateParameter(valid_600423, JString, required = false,
                                 default = nil)
  if valid_600423 != nil:
    section.add "X-Amz-Algorithm", valid_600423
  var valid_600424 = header.getOrDefault("X-Amz-Signature")
  valid_600424 = validateParameter(valid_600424, JString, required = false,
                                 default = nil)
  if valid_600424 != nil:
    section.add "X-Amz-Signature", valid_600424
  var valid_600425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600425 = validateParameter(valid_600425, JString, required = false,
                                 default = nil)
  if valid_600425 != nil:
    section.add "X-Amz-SignedHeaders", valid_600425
  var valid_600426 = header.getOrDefault("X-Amz-Credential")
  valid_600426 = validateParameter(valid_600426, JString, required = false,
                                 default = nil)
  if valid_600426 != nil:
    section.add "X-Amz-Credential", valid_600426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600428: Call_ListChildren_600414; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all of the organizational units (OUs) or accounts that are contained in the specified parent OU or root. This operation, along with <a>ListParents</a> enables you to traverse the tree structure that makes up this root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_600428.validator(path, query, header, formData, body)
  let scheme = call_600428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600428.url(scheme.get, call_600428.host, call_600428.base,
                         call_600428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600428, url, valid)

proc call*(call_600429: Call_ListChildren_600414; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listChildren
  ## <p>Lists all of the organizational units (OUs) or accounts that are contained in the specified parent OU or root. This operation, along with <a>ListParents</a> enables you to traverse the tree structure that makes up this root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600430 = newJObject()
  var body_600431 = newJObject()
  add(query_600430, "NextToken", newJString(NextToken))
  if body != nil:
    body_600431 = body
  add(query_600430, "MaxResults", newJString(MaxResults))
  result = call_600429.call(nil, query_600430, nil, nil, body_600431)

var listChildren* = Call_ListChildren_600414(name: "listChildren",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListChildren",
    validator: validate_ListChildren_600415, base: "/", url: url_ListChildren_600416,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCreateAccountStatus_600432 = ref object of OpenApiRestCall_599369
proc url_ListCreateAccountStatus_600434(protocol: Scheme; host: string; base: string;
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

proc validate_ListCreateAccountStatus_600433(path: JsonNode; query: JsonNode;
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
  var valid_600435 = query.getOrDefault("NextToken")
  valid_600435 = validateParameter(valid_600435, JString, required = false,
                                 default = nil)
  if valid_600435 != nil:
    section.add "NextToken", valid_600435
  var valid_600436 = query.getOrDefault("MaxResults")
  valid_600436 = validateParameter(valid_600436, JString, required = false,
                                 default = nil)
  if valid_600436 != nil:
    section.add "MaxResults", valid_600436
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
  var valid_600437 = header.getOrDefault("X-Amz-Date")
  valid_600437 = validateParameter(valid_600437, JString, required = false,
                                 default = nil)
  if valid_600437 != nil:
    section.add "X-Amz-Date", valid_600437
  var valid_600438 = header.getOrDefault("X-Amz-Security-Token")
  valid_600438 = validateParameter(valid_600438, JString, required = false,
                                 default = nil)
  if valid_600438 != nil:
    section.add "X-Amz-Security-Token", valid_600438
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600439 = header.getOrDefault("X-Amz-Target")
  valid_600439 = validateParameter(valid_600439, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListCreateAccountStatus"))
  if valid_600439 != nil:
    section.add "X-Amz-Target", valid_600439
  var valid_600440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600440 = validateParameter(valid_600440, JString, required = false,
                                 default = nil)
  if valid_600440 != nil:
    section.add "X-Amz-Content-Sha256", valid_600440
  var valid_600441 = header.getOrDefault("X-Amz-Algorithm")
  valid_600441 = validateParameter(valid_600441, JString, required = false,
                                 default = nil)
  if valid_600441 != nil:
    section.add "X-Amz-Algorithm", valid_600441
  var valid_600442 = header.getOrDefault("X-Amz-Signature")
  valid_600442 = validateParameter(valid_600442, JString, required = false,
                                 default = nil)
  if valid_600442 != nil:
    section.add "X-Amz-Signature", valid_600442
  var valid_600443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600443 = validateParameter(valid_600443, JString, required = false,
                                 default = nil)
  if valid_600443 != nil:
    section.add "X-Amz-SignedHeaders", valid_600443
  var valid_600444 = header.getOrDefault("X-Amz-Credential")
  valid_600444 = validateParameter(valid_600444, JString, required = false,
                                 default = nil)
  if valid_600444 != nil:
    section.add "X-Amz-Credential", valid_600444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600446: Call_ListCreateAccountStatus_600432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the account creation requests that match the specified status that is currently being tracked for the organization.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_600446.validator(path, query, header, formData, body)
  let scheme = call_600446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600446.url(scheme.get, call_600446.host, call_600446.base,
                         call_600446.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600446, url, valid)

proc call*(call_600447: Call_ListCreateAccountStatus_600432; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listCreateAccountStatus
  ## <p>Lists the account creation requests that match the specified status that is currently being tracked for the organization.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600448 = newJObject()
  var body_600449 = newJObject()
  add(query_600448, "NextToken", newJString(NextToken))
  if body != nil:
    body_600449 = body
  add(query_600448, "MaxResults", newJString(MaxResults))
  result = call_600447.call(nil, query_600448, nil, nil, body_600449)

var listCreateAccountStatus* = Call_ListCreateAccountStatus_600432(
    name: "listCreateAccountStatus", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListCreateAccountStatus",
    validator: validate_ListCreateAccountStatus_600433, base: "/",
    url: url_ListCreateAccountStatus_600434, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHandshakesForAccount_600450 = ref object of OpenApiRestCall_599369
proc url_ListHandshakesForAccount_600452(protocol: Scheme; host: string;
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

proc validate_ListHandshakesForAccount_600451(path: JsonNode; query: JsonNode;
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
  var valid_600453 = query.getOrDefault("NextToken")
  valid_600453 = validateParameter(valid_600453, JString, required = false,
                                 default = nil)
  if valid_600453 != nil:
    section.add "NextToken", valid_600453
  var valid_600454 = query.getOrDefault("MaxResults")
  valid_600454 = validateParameter(valid_600454, JString, required = false,
                                 default = nil)
  if valid_600454 != nil:
    section.add "MaxResults", valid_600454
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
  var valid_600455 = header.getOrDefault("X-Amz-Date")
  valid_600455 = validateParameter(valid_600455, JString, required = false,
                                 default = nil)
  if valid_600455 != nil:
    section.add "X-Amz-Date", valid_600455
  var valid_600456 = header.getOrDefault("X-Amz-Security-Token")
  valid_600456 = validateParameter(valid_600456, JString, required = false,
                                 default = nil)
  if valid_600456 != nil:
    section.add "X-Amz-Security-Token", valid_600456
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600457 = header.getOrDefault("X-Amz-Target")
  valid_600457 = validateParameter(valid_600457, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListHandshakesForAccount"))
  if valid_600457 != nil:
    section.add "X-Amz-Target", valid_600457
  var valid_600458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600458 = validateParameter(valid_600458, JString, required = false,
                                 default = nil)
  if valid_600458 != nil:
    section.add "X-Amz-Content-Sha256", valid_600458
  var valid_600459 = header.getOrDefault("X-Amz-Algorithm")
  valid_600459 = validateParameter(valid_600459, JString, required = false,
                                 default = nil)
  if valid_600459 != nil:
    section.add "X-Amz-Algorithm", valid_600459
  var valid_600460 = header.getOrDefault("X-Amz-Signature")
  valid_600460 = validateParameter(valid_600460, JString, required = false,
                                 default = nil)
  if valid_600460 != nil:
    section.add "X-Amz-Signature", valid_600460
  var valid_600461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600461 = validateParameter(valid_600461, JString, required = false,
                                 default = nil)
  if valid_600461 != nil:
    section.add "X-Amz-SignedHeaders", valid_600461
  var valid_600462 = header.getOrDefault("X-Amz-Credential")
  valid_600462 = validateParameter(valid_600462, JString, required = false,
                                 default = nil)
  if valid_600462 != nil:
    section.add "X-Amz-Credential", valid_600462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600464: Call_ListHandshakesForAccount_600450; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the current handshakes that are associated with the account of the requesting user.</p> <p>Handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> appear in the results of this API for only 30 days after changing to that state. After that, they're deleted and no longer accessible.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called from any account in the organization.</p>
  ## 
  let valid = call_600464.validator(path, query, header, formData, body)
  let scheme = call_600464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600464.url(scheme.get, call_600464.host, call_600464.base,
                         call_600464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600464, url, valid)

proc call*(call_600465: Call_ListHandshakesForAccount_600450; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listHandshakesForAccount
  ## <p>Lists the current handshakes that are associated with the account of the requesting user.</p> <p>Handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> appear in the results of this API for only 30 days after changing to that state. After that, they're deleted and no longer accessible.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called from any account in the organization.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600466 = newJObject()
  var body_600467 = newJObject()
  add(query_600466, "NextToken", newJString(NextToken))
  if body != nil:
    body_600467 = body
  add(query_600466, "MaxResults", newJString(MaxResults))
  result = call_600465.call(nil, query_600466, nil, nil, body_600467)

var listHandshakesForAccount* = Call_ListHandshakesForAccount_600450(
    name: "listHandshakesForAccount", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListHandshakesForAccount",
    validator: validate_ListHandshakesForAccount_600451, base: "/",
    url: url_ListHandshakesForAccount_600452, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHandshakesForOrganization_600468 = ref object of OpenApiRestCall_599369
proc url_ListHandshakesForOrganization_600470(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListHandshakesForOrganization_600469(path: JsonNode; query: JsonNode;
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
  var valid_600471 = query.getOrDefault("NextToken")
  valid_600471 = validateParameter(valid_600471, JString, required = false,
                                 default = nil)
  if valid_600471 != nil:
    section.add "NextToken", valid_600471
  var valid_600472 = query.getOrDefault("MaxResults")
  valid_600472 = validateParameter(valid_600472, JString, required = false,
                                 default = nil)
  if valid_600472 != nil:
    section.add "MaxResults", valid_600472
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
  var valid_600473 = header.getOrDefault("X-Amz-Date")
  valid_600473 = validateParameter(valid_600473, JString, required = false,
                                 default = nil)
  if valid_600473 != nil:
    section.add "X-Amz-Date", valid_600473
  var valid_600474 = header.getOrDefault("X-Amz-Security-Token")
  valid_600474 = validateParameter(valid_600474, JString, required = false,
                                 default = nil)
  if valid_600474 != nil:
    section.add "X-Amz-Security-Token", valid_600474
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600475 = header.getOrDefault("X-Amz-Target")
  valid_600475 = validateParameter(valid_600475, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListHandshakesForOrganization"))
  if valid_600475 != nil:
    section.add "X-Amz-Target", valid_600475
  var valid_600476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600476 = validateParameter(valid_600476, JString, required = false,
                                 default = nil)
  if valid_600476 != nil:
    section.add "X-Amz-Content-Sha256", valid_600476
  var valid_600477 = header.getOrDefault("X-Amz-Algorithm")
  valid_600477 = validateParameter(valid_600477, JString, required = false,
                                 default = nil)
  if valid_600477 != nil:
    section.add "X-Amz-Algorithm", valid_600477
  var valid_600478 = header.getOrDefault("X-Amz-Signature")
  valid_600478 = validateParameter(valid_600478, JString, required = false,
                                 default = nil)
  if valid_600478 != nil:
    section.add "X-Amz-Signature", valid_600478
  var valid_600479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600479 = validateParameter(valid_600479, JString, required = false,
                                 default = nil)
  if valid_600479 != nil:
    section.add "X-Amz-SignedHeaders", valid_600479
  var valid_600480 = header.getOrDefault("X-Amz-Credential")
  valid_600480 = validateParameter(valid_600480, JString, required = false,
                                 default = nil)
  if valid_600480 != nil:
    section.add "X-Amz-Credential", valid_600480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600482: Call_ListHandshakesForOrganization_600468; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the handshakes that are associated with the organization that the requesting user is part of. The <code>ListHandshakesForOrganization</code> operation returns a list of handshake structures. Each structure contains details and status about a handshake.</p> <p>Handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> appear in the results of this API for only 30 days after changing to that state. After that, they're deleted and no longer accessible.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_600482.validator(path, query, header, formData, body)
  let scheme = call_600482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600482.url(scheme.get, call_600482.host, call_600482.base,
                         call_600482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600482, url, valid)

proc call*(call_600483: Call_ListHandshakesForOrganization_600468; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listHandshakesForOrganization
  ## <p>Lists the handshakes that are associated with the organization that the requesting user is part of. The <code>ListHandshakesForOrganization</code> operation returns a list of handshake structures. Each structure contains details and status about a handshake.</p> <p>Handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> appear in the results of this API for only 30 days after changing to that state. After that, they're deleted and no longer accessible.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600484 = newJObject()
  var body_600485 = newJObject()
  add(query_600484, "NextToken", newJString(NextToken))
  if body != nil:
    body_600485 = body
  add(query_600484, "MaxResults", newJString(MaxResults))
  result = call_600483.call(nil, query_600484, nil, nil, body_600485)

var listHandshakesForOrganization* = Call_ListHandshakesForOrganization_600468(
    name: "listHandshakesForOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListHandshakesForOrganization",
    validator: validate_ListHandshakesForOrganization_600469, base: "/",
    url: url_ListHandshakesForOrganization_600470,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOrganizationalUnitsForParent_600486 = ref object of OpenApiRestCall_599369
proc url_ListOrganizationalUnitsForParent_600488(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOrganizationalUnitsForParent_600487(path: JsonNode;
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
  var valid_600489 = query.getOrDefault("NextToken")
  valid_600489 = validateParameter(valid_600489, JString, required = false,
                                 default = nil)
  if valid_600489 != nil:
    section.add "NextToken", valid_600489
  var valid_600490 = query.getOrDefault("MaxResults")
  valid_600490 = validateParameter(valid_600490, JString, required = false,
                                 default = nil)
  if valid_600490 != nil:
    section.add "MaxResults", valid_600490
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
  var valid_600491 = header.getOrDefault("X-Amz-Date")
  valid_600491 = validateParameter(valid_600491, JString, required = false,
                                 default = nil)
  if valid_600491 != nil:
    section.add "X-Amz-Date", valid_600491
  var valid_600492 = header.getOrDefault("X-Amz-Security-Token")
  valid_600492 = validateParameter(valid_600492, JString, required = false,
                                 default = nil)
  if valid_600492 != nil:
    section.add "X-Amz-Security-Token", valid_600492
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600493 = header.getOrDefault("X-Amz-Target")
  valid_600493 = validateParameter(valid_600493, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListOrganizationalUnitsForParent"))
  if valid_600493 != nil:
    section.add "X-Amz-Target", valid_600493
  var valid_600494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600494 = validateParameter(valid_600494, JString, required = false,
                                 default = nil)
  if valid_600494 != nil:
    section.add "X-Amz-Content-Sha256", valid_600494
  var valid_600495 = header.getOrDefault("X-Amz-Algorithm")
  valid_600495 = validateParameter(valid_600495, JString, required = false,
                                 default = nil)
  if valid_600495 != nil:
    section.add "X-Amz-Algorithm", valid_600495
  var valid_600496 = header.getOrDefault("X-Amz-Signature")
  valid_600496 = validateParameter(valid_600496, JString, required = false,
                                 default = nil)
  if valid_600496 != nil:
    section.add "X-Amz-Signature", valid_600496
  var valid_600497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600497 = validateParameter(valid_600497, JString, required = false,
                                 default = nil)
  if valid_600497 != nil:
    section.add "X-Amz-SignedHeaders", valid_600497
  var valid_600498 = header.getOrDefault("X-Amz-Credential")
  valid_600498 = validateParameter(valid_600498, JString, required = false,
                                 default = nil)
  if valid_600498 != nil:
    section.add "X-Amz-Credential", valid_600498
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600500: Call_ListOrganizationalUnitsForParent_600486;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the organizational units (OUs) in a parent organizational unit or root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_600500.validator(path, query, header, formData, body)
  let scheme = call_600500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600500.url(scheme.get, call_600500.host, call_600500.base,
                         call_600500.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600500, url, valid)

proc call*(call_600501: Call_ListOrganizationalUnitsForParent_600486;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listOrganizationalUnitsForParent
  ## <p>Lists the organizational units (OUs) in a parent organizational unit or root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600502 = newJObject()
  var body_600503 = newJObject()
  add(query_600502, "NextToken", newJString(NextToken))
  if body != nil:
    body_600503 = body
  add(query_600502, "MaxResults", newJString(MaxResults))
  result = call_600501.call(nil, query_600502, nil, nil, body_600503)

var listOrganizationalUnitsForParent* = Call_ListOrganizationalUnitsForParent_600486(
    name: "listOrganizationalUnitsForParent", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListOrganizationalUnitsForParent",
    validator: validate_ListOrganizationalUnitsForParent_600487, base: "/",
    url: url_ListOrganizationalUnitsForParent_600488,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListParents_600504 = ref object of OpenApiRestCall_599369
proc url_ListParents_600506(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListParents_600505(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600507 = query.getOrDefault("NextToken")
  valid_600507 = validateParameter(valid_600507, JString, required = false,
                                 default = nil)
  if valid_600507 != nil:
    section.add "NextToken", valid_600507
  var valid_600508 = query.getOrDefault("MaxResults")
  valid_600508 = validateParameter(valid_600508, JString, required = false,
                                 default = nil)
  if valid_600508 != nil:
    section.add "MaxResults", valid_600508
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
  var valid_600509 = header.getOrDefault("X-Amz-Date")
  valid_600509 = validateParameter(valid_600509, JString, required = false,
                                 default = nil)
  if valid_600509 != nil:
    section.add "X-Amz-Date", valid_600509
  var valid_600510 = header.getOrDefault("X-Amz-Security-Token")
  valid_600510 = validateParameter(valid_600510, JString, required = false,
                                 default = nil)
  if valid_600510 != nil:
    section.add "X-Amz-Security-Token", valid_600510
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600511 = header.getOrDefault("X-Amz-Target")
  valid_600511 = validateParameter(valid_600511, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListParents"))
  if valid_600511 != nil:
    section.add "X-Amz-Target", valid_600511
  var valid_600512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600512 = validateParameter(valid_600512, JString, required = false,
                                 default = nil)
  if valid_600512 != nil:
    section.add "X-Amz-Content-Sha256", valid_600512
  var valid_600513 = header.getOrDefault("X-Amz-Algorithm")
  valid_600513 = validateParameter(valid_600513, JString, required = false,
                                 default = nil)
  if valid_600513 != nil:
    section.add "X-Amz-Algorithm", valid_600513
  var valid_600514 = header.getOrDefault("X-Amz-Signature")
  valid_600514 = validateParameter(valid_600514, JString, required = false,
                                 default = nil)
  if valid_600514 != nil:
    section.add "X-Amz-Signature", valid_600514
  var valid_600515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600515 = validateParameter(valid_600515, JString, required = false,
                                 default = nil)
  if valid_600515 != nil:
    section.add "X-Amz-SignedHeaders", valid_600515
  var valid_600516 = header.getOrDefault("X-Amz-Credential")
  valid_600516 = validateParameter(valid_600516, JString, required = false,
                                 default = nil)
  if valid_600516 != nil:
    section.add "X-Amz-Credential", valid_600516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600518: Call_ListParents_600504; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the root or organizational units (OUs) that serve as the immediate parent of the specified child OU or account. This operation, along with <a>ListChildren</a> enables you to traverse the tree structure that makes up this root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p> <note> <p>In the current release, a child can have only a single parent. </p> </note>
  ## 
  let valid = call_600518.validator(path, query, header, formData, body)
  let scheme = call_600518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600518.url(scheme.get, call_600518.host, call_600518.base,
                         call_600518.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600518, url, valid)

proc call*(call_600519: Call_ListParents_600504; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listParents
  ## <p>Lists the root or organizational units (OUs) that serve as the immediate parent of the specified child OU or account. This operation, along with <a>ListChildren</a> enables you to traverse the tree structure that makes up this root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p> <note> <p>In the current release, a child can have only a single parent. </p> </note>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600520 = newJObject()
  var body_600521 = newJObject()
  add(query_600520, "NextToken", newJString(NextToken))
  if body != nil:
    body_600521 = body
  add(query_600520, "MaxResults", newJString(MaxResults))
  result = call_600519.call(nil, query_600520, nil, nil, body_600521)

var listParents* = Call_ListParents_600504(name: "listParents",
                                        meth: HttpMethod.HttpPost,
                                        host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListParents",
                                        validator: validate_ListParents_600505,
                                        base: "/", url: url_ListParents_600506,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPolicies_600522 = ref object of OpenApiRestCall_599369
proc url_ListPolicies_600524(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPolicies_600523(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600525 = query.getOrDefault("NextToken")
  valid_600525 = validateParameter(valid_600525, JString, required = false,
                                 default = nil)
  if valid_600525 != nil:
    section.add "NextToken", valid_600525
  var valid_600526 = query.getOrDefault("MaxResults")
  valid_600526 = validateParameter(valid_600526, JString, required = false,
                                 default = nil)
  if valid_600526 != nil:
    section.add "MaxResults", valid_600526
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
  var valid_600527 = header.getOrDefault("X-Amz-Date")
  valid_600527 = validateParameter(valid_600527, JString, required = false,
                                 default = nil)
  if valid_600527 != nil:
    section.add "X-Amz-Date", valid_600527
  var valid_600528 = header.getOrDefault("X-Amz-Security-Token")
  valid_600528 = validateParameter(valid_600528, JString, required = false,
                                 default = nil)
  if valid_600528 != nil:
    section.add "X-Amz-Security-Token", valid_600528
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600529 = header.getOrDefault("X-Amz-Target")
  valid_600529 = validateParameter(valid_600529, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListPolicies"))
  if valid_600529 != nil:
    section.add "X-Amz-Target", valid_600529
  var valid_600530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600530 = validateParameter(valid_600530, JString, required = false,
                                 default = nil)
  if valid_600530 != nil:
    section.add "X-Amz-Content-Sha256", valid_600530
  var valid_600531 = header.getOrDefault("X-Amz-Algorithm")
  valid_600531 = validateParameter(valid_600531, JString, required = false,
                                 default = nil)
  if valid_600531 != nil:
    section.add "X-Amz-Algorithm", valid_600531
  var valid_600532 = header.getOrDefault("X-Amz-Signature")
  valid_600532 = validateParameter(valid_600532, JString, required = false,
                                 default = nil)
  if valid_600532 != nil:
    section.add "X-Amz-Signature", valid_600532
  var valid_600533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600533 = validateParameter(valid_600533, JString, required = false,
                                 default = nil)
  if valid_600533 != nil:
    section.add "X-Amz-SignedHeaders", valid_600533
  var valid_600534 = header.getOrDefault("X-Amz-Credential")
  valid_600534 = validateParameter(valid_600534, JString, required = false,
                                 default = nil)
  if valid_600534 != nil:
    section.add "X-Amz-Credential", valid_600534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600536: Call_ListPolicies_600522; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the list of all policies in an organization of a specified type.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_600536.validator(path, query, header, formData, body)
  let scheme = call_600536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600536.url(scheme.get, call_600536.host, call_600536.base,
                         call_600536.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600536, url, valid)

proc call*(call_600537: Call_ListPolicies_600522; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listPolicies
  ## <p>Retrieves the list of all policies in an organization of a specified type.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600538 = newJObject()
  var body_600539 = newJObject()
  add(query_600538, "NextToken", newJString(NextToken))
  if body != nil:
    body_600539 = body
  add(query_600538, "MaxResults", newJString(MaxResults))
  result = call_600537.call(nil, query_600538, nil, nil, body_600539)

var listPolicies* = Call_ListPolicies_600522(name: "listPolicies",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListPolicies",
    validator: validate_ListPolicies_600523, base: "/", url: url_ListPolicies_600524,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPoliciesForTarget_600540 = ref object of OpenApiRestCall_599369
proc url_ListPoliciesForTarget_600542(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPoliciesForTarget_600541(path: JsonNode; query: JsonNode;
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
  var valid_600543 = query.getOrDefault("NextToken")
  valid_600543 = validateParameter(valid_600543, JString, required = false,
                                 default = nil)
  if valid_600543 != nil:
    section.add "NextToken", valid_600543
  var valid_600544 = query.getOrDefault("MaxResults")
  valid_600544 = validateParameter(valid_600544, JString, required = false,
                                 default = nil)
  if valid_600544 != nil:
    section.add "MaxResults", valid_600544
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
      "AWSOrganizationsV20161128.ListPoliciesForTarget"))
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

proc call*(call_600554: Call_ListPoliciesForTarget_600540; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the policies that are directly attached to the specified target root, organizational unit (OU), or account. You must specify the policy type that you want included in the returned list.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_600554.validator(path, query, header, formData, body)
  let scheme = call_600554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600554.url(scheme.get, call_600554.host, call_600554.base,
                         call_600554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600554, url, valid)

proc call*(call_600555: Call_ListPoliciesForTarget_600540; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listPoliciesForTarget
  ## <p>Lists the policies that are directly attached to the specified target root, organizational unit (OU), or account. You must specify the policy type that you want included in the returned list.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600556 = newJObject()
  var body_600557 = newJObject()
  add(query_600556, "NextToken", newJString(NextToken))
  if body != nil:
    body_600557 = body
  add(query_600556, "MaxResults", newJString(MaxResults))
  result = call_600555.call(nil, query_600556, nil, nil, body_600557)

var listPoliciesForTarget* = Call_ListPoliciesForTarget_600540(
    name: "listPoliciesForTarget", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListPoliciesForTarget",
    validator: validate_ListPoliciesForTarget_600541, base: "/",
    url: url_ListPoliciesForTarget_600542, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoots_600558 = ref object of OpenApiRestCall_599369
proc url_ListRoots_600560(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRoots_600559(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600561 = query.getOrDefault("NextToken")
  valid_600561 = validateParameter(valid_600561, JString, required = false,
                                 default = nil)
  if valid_600561 != nil:
    section.add "NextToken", valid_600561
  var valid_600562 = query.getOrDefault("MaxResults")
  valid_600562 = validateParameter(valid_600562, JString, required = false,
                                 default = nil)
  if valid_600562 != nil:
    section.add "MaxResults", valid_600562
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
  var valid_600563 = header.getOrDefault("X-Amz-Date")
  valid_600563 = validateParameter(valid_600563, JString, required = false,
                                 default = nil)
  if valid_600563 != nil:
    section.add "X-Amz-Date", valid_600563
  var valid_600564 = header.getOrDefault("X-Amz-Security-Token")
  valid_600564 = validateParameter(valid_600564, JString, required = false,
                                 default = nil)
  if valid_600564 != nil:
    section.add "X-Amz-Security-Token", valid_600564
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600565 = header.getOrDefault("X-Amz-Target")
  valid_600565 = validateParameter(valid_600565, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListRoots"))
  if valid_600565 != nil:
    section.add "X-Amz-Target", valid_600565
  var valid_600566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600566 = validateParameter(valid_600566, JString, required = false,
                                 default = nil)
  if valid_600566 != nil:
    section.add "X-Amz-Content-Sha256", valid_600566
  var valid_600567 = header.getOrDefault("X-Amz-Algorithm")
  valid_600567 = validateParameter(valid_600567, JString, required = false,
                                 default = nil)
  if valid_600567 != nil:
    section.add "X-Amz-Algorithm", valid_600567
  var valid_600568 = header.getOrDefault("X-Amz-Signature")
  valid_600568 = validateParameter(valid_600568, JString, required = false,
                                 default = nil)
  if valid_600568 != nil:
    section.add "X-Amz-Signature", valid_600568
  var valid_600569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600569 = validateParameter(valid_600569, JString, required = false,
                                 default = nil)
  if valid_600569 != nil:
    section.add "X-Amz-SignedHeaders", valid_600569
  var valid_600570 = header.getOrDefault("X-Amz-Credential")
  valid_600570 = validateParameter(valid_600570, JString, required = false,
                                 default = nil)
  if valid_600570 != nil:
    section.add "X-Amz-Credential", valid_600570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600572: Call_ListRoots_600558; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the roots that are defined in the current organization.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p> <note> <p>Policy types can be enabled and disabled in roots. This is distinct from whether they're available in the organization. When you enable all features, you make policy types available for use in that organization. Individual policy types can then be enabled and disabled in a root. To see the availability of a policy type in an organization, use <a>DescribeOrganization</a>.</p> </note>
  ## 
  let valid = call_600572.validator(path, query, header, formData, body)
  let scheme = call_600572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600572.url(scheme.get, call_600572.host, call_600572.base,
                         call_600572.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600572, url, valid)

proc call*(call_600573: Call_ListRoots_600558; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listRoots
  ## <p>Lists the roots that are defined in the current organization.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p> <note> <p>Policy types can be enabled and disabled in roots. This is distinct from whether they're available in the organization. When you enable all features, you make policy types available for use in that organization. Individual policy types can then be enabled and disabled in a root. To see the availability of a policy type in an organization, use <a>DescribeOrganization</a>.</p> </note>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600574 = newJObject()
  var body_600575 = newJObject()
  add(query_600574, "NextToken", newJString(NextToken))
  if body != nil:
    body_600575 = body
  add(query_600574, "MaxResults", newJString(MaxResults))
  result = call_600573.call(nil, query_600574, nil, nil, body_600575)

var listRoots* = Call_ListRoots_600558(name: "listRoots", meth: HttpMethod.HttpPost,
                                    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListRoots",
                                    validator: validate_ListRoots_600559,
                                    base: "/", url: url_ListRoots_600560,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600576 = ref object of OpenApiRestCall_599369
proc url_ListTagsForResource_600578(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_600577(path: JsonNode; query: JsonNode;
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
  var valid_600579 = query.getOrDefault("NextToken")
  valid_600579 = validateParameter(valid_600579, JString, required = false,
                                 default = nil)
  if valid_600579 != nil:
    section.add "NextToken", valid_600579
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
  var valid_600580 = header.getOrDefault("X-Amz-Date")
  valid_600580 = validateParameter(valid_600580, JString, required = false,
                                 default = nil)
  if valid_600580 != nil:
    section.add "X-Amz-Date", valid_600580
  var valid_600581 = header.getOrDefault("X-Amz-Security-Token")
  valid_600581 = validateParameter(valid_600581, JString, required = false,
                                 default = nil)
  if valid_600581 != nil:
    section.add "X-Amz-Security-Token", valid_600581
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600582 = header.getOrDefault("X-Amz-Target")
  valid_600582 = validateParameter(valid_600582, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListTagsForResource"))
  if valid_600582 != nil:
    section.add "X-Amz-Target", valid_600582
  var valid_600583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600583 = validateParameter(valid_600583, JString, required = false,
                                 default = nil)
  if valid_600583 != nil:
    section.add "X-Amz-Content-Sha256", valid_600583
  var valid_600584 = header.getOrDefault("X-Amz-Algorithm")
  valid_600584 = validateParameter(valid_600584, JString, required = false,
                                 default = nil)
  if valid_600584 != nil:
    section.add "X-Amz-Algorithm", valid_600584
  var valid_600585 = header.getOrDefault("X-Amz-Signature")
  valid_600585 = validateParameter(valid_600585, JString, required = false,
                                 default = nil)
  if valid_600585 != nil:
    section.add "X-Amz-Signature", valid_600585
  var valid_600586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600586 = validateParameter(valid_600586, JString, required = false,
                                 default = nil)
  if valid_600586 != nil:
    section.add "X-Amz-SignedHeaders", valid_600586
  var valid_600587 = header.getOrDefault("X-Amz-Credential")
  valid_600587 = validateParameter(valid_600587, JString, required = false,
                                 default = nil)
  if valid_600587 != nil:
    section.add "X-Amz-Credential", valid_600587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600589: Call_ListTagsForResource_600576; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists tags for the specified resource. </p> <p>Currently, you can list tags on an account in AWS Organizations.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_600589.validator(path, query, header, formData, body)
  let scheme = call_600589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600589.url(scheme.get, call_600589.host, call_600589.base,
                         call_600589.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600589, url, valid)

proc call*(call_600590: Call_ListTagsForResource_600576; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## listTagsForResource
  ## <p>Lists tags for the specified resource. </p> <p>Currently, you can list tags on an account in AWS Organizations.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600591 = newJObject()
  var body_600592 = newJObject()
  add(query_600591, "NextToken", newJString(NextToken))
  if body != nil:
    body_600592 = body
  result = call_600590.call(nil, query_600591, nil, nil, body_600592)

var listTagsForResource* = Call_ListTagsForResource_600576(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListTagsForResource",
    validator: validate_ListTagsForResource_600577, base: "/",
    url: url_ListTagsForResource_600578, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTargetsForPolicy_600593 = ref object of OpenApiRestCall_599369
proc url_ListTargetsForPolicy_600595(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTargetsForPolicy_600594(path: JsonNode; query: JsonNode;
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
  var valid_600596 = query.getOrDefault("NextToken")
  valid_600596 = validateParameter(valid_600596, JString, required = false,
                                 default = nil)
  if valid_600596 != nil:
    section.add "NextToken", valid_600596
  var valid_600597 = query.getOrDefault("MaxResults")
  valid_600597 = validateParameter(valid_600597, JString, required = false,
                                 default = nil)
  if valid_600597 != nil:
    section.add "MaxResults", valid_600597
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
  var valid_600598 = header.getOrDefault("X-Amz-Date")
  valid_600598 = validateParameter(valid_600598, JString, required = false,
                                 default = nil)
  if valid_600598 != nil:
    section.add "X-Amz-Date", valid_600598
  var valid_600599 = header.getOrDefault("X-Amz-Security-Token")
  valid_600599 = validateParameter(valid_600599, JString, required = false,
                                 default = nil)
  if valid_600599 != nil:
    section.add "X-Amz-Security-Token", valid_600599
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600600 = header.getOrDefault("X-Amz-Target")
  valid_600600 = validateParameter(valid_600600, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListTargetsForPolicy"))
  if valid_600600 != nil:
    section.add "X-Amz-Target", valid_600600
  var valid_600601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600601 = validateParameter(valid_600601, JString, required = false,
                                 default = nil)
  if valid_600601 != nil:
    section.add "X-Amz-Content-Sha256", valid_600601
  var valid_600602 = header.getOrDefault("X-Amz-Algorithm")
  valid_600602 = validateParameter(valid_600602, JString, required = false,
                                 default = nil)
  if valid_600602 != nil:
    section.add "X-Amz-Algorithm", valid_600602
  var valid_600603 = header.getOrDefault("X-Amz-Signature")
  valid_600603 = validateParameter(valid_600603, JString, required = false,
                                 default = nil)
  if valid_600603 != nil:
    section.add "X-Amz-Signature", valid_600603
  var valid_600604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600604 = validateParameter(valid_600604, JString, required = false,
                                 default = nil)
  if valid_600604 != nil:
    section.add "X-Amz-SignedHeaders", valid_600604
  var valid_600605 = header.getOrDefault("X-Amz-Credential")
  valid_600605 = validateParameter(valid_600605, JString, required = false,
                                 default = nil)
  if valid_600605 != nil:
    section.add "X-Amz-Credential", valid_600605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600607: Call_ListTargetsForPolicy_600593; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all the roots, organizational units (OUs), and accounts that the specified policy is attached to.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_600607.validator(path, query, header, formData, body)
  let scheme = call_600607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600607.url(scheme.get, call_600607.host, call_600607.base,
                         call_600607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600607, url, valid)

proc call*(call_600608: Call_ListTargetsForPolicy_600593; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTargetsForPolicy
  ## <p>Lists all the roots, organizational units (OUs), and accounts that the specified policy is attached to.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600609 = newJObject()
  var body_600610 = newJObject()
  add(query_600609, "NextToken", newJString(NextToken))
  if body != nil:
    body_600610 = body
  add(query_600609, "MaxResults", newJString(MaxResults))
  result = call_600608.call(nil, query_600609, nil, nil, body_600610)

var listTargetsForPolicy* = Call_ListTargetsForPolicy_600593(
    name: "listTargetsForPolicy", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListTargetsForPolicy",
    validator: validate_ListTargetsForPolicy_600594, base: "/",
    url: url_ListTargetsForPolicy_600595, schemes: {Scheme.Https, Scheme.Http})
type
  Call_MoveAccount_600611 = ref object of OpenApiRestCall_599369
proc url_MoveAccount_600613(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_MoveAccount_600612(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600614 = header.getOrDefault("X-Amz-Date")
  valid_600614 = validateParameter(valid_600614, JString, required = false,
                                 default = nil)
  if valid_600614 != nil:
    section.add "X-Amz-Date", valid_600614
  var valid_600615 = header.getOrDefault("X-Amz-Security-Token")
  valid_600615 = validateParameter(valid_600615, JString, required = false,
                                 default = nil)
  if valid_600615 != nil:
    section.add "X-Amz-Security-Token", valid_600615
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600616 = header.getOrDefault("X-Amz-Target")
  valid_600616 = validateParameter(valid_600616, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.MoveAccount"))
  if valid_600616 != nil:
    section.add "X-Amz-Target", valid_600616
  var valid_600617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600617 = validateParameter(valid_600617, JString, required = false,
                                 default = nil)
  if valid_600617 != nil:
    section.add "X-Amz-Content-Sha256", valid_600617
  var valid_600618 = header.getOrDefault("X-Amz-Algorithm")
  valid_600618 = validateParameter(valid_600618, JString, required = false,
                                 default = nil)
  if valid_600618 != nil:
    section.add "X-Amz-Algorithm", valid_600618
  var valid_600619 = header.getOrDefault("X-Amz-Signature")
  valid_600619 = validateParameter(valid_600619, JString, required = false,
                                 default = nil)
  if valid_600619 != nil:
    section.add "X-Amz-Signature", valid_600619
  var valid_600620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600620 = validateParameter(valid_600620, JString, required = false,
                                 default = nil)
  if valid_600620 != nil:
    section.add "X-Amz-SignedHeaders", valid_600620
  var valid_600621 = header.getOrDefault("X-Amz-Credential")
  valid_600621 = validateParameter(valid_600621, JString, required = false,
                                 default = nil)
  if valid_600621 != nil:
    section.add "X-Amz-Credential", valid_600621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600623: Call_MoveAccount_600611; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Moves an account from its current source parent root or organizational unit (OU) to the specified destination parent root or OU.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_600623.validator(path, query, header, formData, body)
  let scheme = call_600623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600623.url(scheme.get, call_600623.host, call_600623.base,
                         call_600623.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600623, url, valid)

proc call*(call_600624: Call_MoveAccount_600611; body: JsonNode): Recallable =
  ## moveAccount
  ## <p>Moves an account from its current source parent root or organizational unit (OU) to the specified destination parent root or OU.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_600625 = newJObject()
  if body != nil:
    body_600625 = body
  result = call_600624.call(nil, nil, nil, nil, body_600625)

var moveAccount* = Call_MoveAccount_600611(name: "moveAccount",
                                        meth: HttpMethod.HttpPost,
                                        host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.MoveAccount",
                                        validator: validate_MoveAccount_600612,
                                        base: "/", url: url_MoveAccount_600613,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAccountFromOrganization_600626 = ref object of OpenApiRestCall_599369
proc url_RemoveAccountFromOrganization_600628(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RemoveAccountFromOrganization_600627(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes the specified account from the organization.</p> <p>The removed account becomes a standalone account that isn't a member of any organization. It's no longer subject to any policies and is responsible for its own bill payments. The organization's master account is no longer charged for any expenses accrued by the member account after it's removed from the organization.</p> <p>This operation can be called only from the organization's master account. Member accounts can remove themselves with <a>LeaveOrganization</a> instead.</p> <important> <p>You can remove an account from your organization only if the account is configured with the information required to operate as a standalone account. When you create an account in an organization using the AWS Organizations console, API, or CLI, the information required of standalone accounts is <i>not</i> automatically collected. For an account that you want to make standalone, you must accept the end user license agreement (EULA). You must also choose a support plan, provide and verify the required contact information, and provide a current payment method. AWS uses the payment method to charge for any billable (not free tier) AWS activity that occurs while the account isn't attached to an organization. To remove an account that doesn't yet have this information, you must sign in as the member account. Then follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization when all required account information has not yet been provided</a> in the <i>AWS Organizations User Guide.</i> </p> </important>
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
  var valid_600629 = header.getOrDefault("X-Amz-Date")
  valid_600629 = validateParameter(valid_600629, JString, required = false,
                                 default = nil)
  if valid_600629 != nil:
    section.add "X-Amz-Date", valid_600629
  var valid_600630 = header.getOrDefault("X-Amz-Security-Token")
  valid_600630 = validateParameter(valid_600630, JString, required = false,
                                 default = nil)
  if valid_600630 != nil:
    section.add "X-Amz-Security-Token", valid_600630
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600631 = header.getOrDefault("X-Amz-Target")
  valid_600631 = validateParameter(valid_600631, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.RemoveAccountFromOrganization"))
  if valid_600631 != nil:
    section.add "X-Amz-Target", valid_600631
  var valid_600632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600632 = validateParameter(valid_600632, JString, required = false,
                                 default = nil)
  if valid_600632 != nil:
    section.add "X-Amz-Content-Sha256", valid_600632
  var valid_600633 = header.getOrDefault("X-Amz-Algorithm")
  valid_600633 = validateParameter(valid_600633, JString, required = false,
                                 default = nil)
  if valid_600633 != nil:
    section.add "X-Amz-Algorithm", valid_600633
  var valid_600634 = header.getOrDefault("X-Amz-Signature")
  valid_600634 = validateParameter(valid_600634, JString, required = false,
                                 default = nil)
  if valid_600634 != nil:
    section.add "X-Amz-Signature", valid_600634
  var valid_600635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600635 = validateParameter(valid_600635, JString, required = false,
                                 default = nil)
  if valid_600635 != nil:
    section.add "X-Amz-SignedHeaders", valid_600635
  var valid_600636 = header.getOrDefault("X-Amz-Credential")
  valid_600636 = validateParameter(valid_600636, JString, required = false,
                                 default = nil)
  if valid_600636 != nil:
    section.add "X-Amz-Credential", valid_600636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600638: Call_RemoveAccountFromOrganization_600626; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified account from the organization.</p> <p>The removed account becomes a standalone account that isn't a member of any organization. It's no longer subject to any policies and is responsible for its own bill payments. The organization's master account is no longer charged for any expenses accrued by the member account after it's removed from the organization.</p> <p>This operation can be called only from the organization's master account. Member accounts can remove themselves with <a>LeaveOrganization</a> instead.</p> <important> <p>You can remove an account from your organization only if the account is configured with the information required to operate as a standalone account. When you create an account in an organization using the AWS Organizations console, API, or CLI, the information required of standalone accounts is <i>not</i> automatically collected. For an account that you want to make standalone, you must accept the end user license agreement (EULA). You must also choose a support plan, provide and verify the required contact information, and provide a current payment method. AWS uses the payment method to charge for any billable (not free tier) AWS activity that occurs while the account isn't attached to an organization. To remove an account that doesn't yet have this information, you must sign in as the member account. Then follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization when all required account information has not yet been provided</a> in the <i>AWS Organizations User Guide.</i> </p> </important>
  ## 
  let valid = call_600638.validator(path, query, header, formData, body)
  let scheme = call_600638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600638.url(scheme.get, call_600638.host, call_600638.base,
                         call_600638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600638, url, valid)

proc call*(call_600639: Call_RemoveAccountFromOrganization_600626; body: JsonNode): Recallable =
  ## removeAccountFromOrganization
  ## <p>Removes the specified account from the organization.</p> <p>The removed account becomes a standalone account that isn't a member of any organization. It's no longer subject to any policies and is responsible for its own bill payments. The organization's master account is no longer charged for any expenses accrued by the member account after it's removed from the organization.</p> <p>This operation can be called only from the organization's master account. Member accounts can remove themselves with <a>LeaveOrganization</a> instead.</p> <important> <p>You can remove an account from your organization only if the account is configured with the information required to operate as a standalone account. When you create an account in an organization using the AWS Organizations console, API, or CLI, the information required of standalone accounts is <i>not</i> automatically collected. For an account that you want to make standalone, you must accept the end user license agreement (EULA). You must also choose a support plan, provide and verify the required contact information, and provide a current payment method. AWS uses the payment method to charge for any billable (not free tier) AWS activity that occurs while the account isn't attached to an organization. To remove an account that doesn't yet have this information, you must sign in as the member account. Then follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization when all required account information has not yet been provided</a> in the <i>AWS Organizations User Guide.</i> </p> </important>
  ##   body: JObject (required)
  var body_600640 = newJObject()
  if body != nil:
    body_600640 = body
  result = call_600639.call(nil, nil, nil, nil, body_600640)

var removeAccountFromOrganization* = Call_RemoveAccountFromOrganization_600626(
    name: "removeAccountFromOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.RemoveAccountFromOrganization",
    validator: validate_RemoveAccountFromOrganization_600627, base: "/",
    url: url_RemoveAccountFromOrganization_600628,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_600641 = ref object of OpenApiRestCall_599369
proc url_TagResource_600643(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_600642(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600644 = header.getOrDefault("X-Amz-Date")
  valid_600644 = validateParameter(valid_600644, JString, required = false,
                                 default = nil)
  if valid_600644 != nil:
    section.add "X-Amz-Date", valid_600644
  var valid_600645 = header.getOrDefault("X-Amz-Security-Token")
  valid_600645 = validateParameter(valid_600645, JString, required = false,
                                 default = nil)
  if valid_600645 != nil:
    section.add "X-Amz-Security-Token", valid_600645
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600646 = header.getOrDefault("X-Amz-Target")
  valid_600646 = validateParameter(valid_600646, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.TagResource"))
  if valid_600646 != nil:
    section.add "X-Amz-Target", valid_600646
  var valid_600647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600647 = validateParameter(valid_600647, JString, required = false,
                                 default = nil)
  if valid_600647 != nil:
    section.add "X-Amz-Content-Sha256", valid_600647
  var valid_600648 = header.getOrDefault("X-Amz-Algorithm")
  valid_600648 = validateParameter(valid_600648, JString, required = false,
                                 default = nil)
  if valid_600648 != nil:
    section.add "X-Amz-Algorithm", valid_600648
  var valid_600649 = header.getOrDefault("X-Amz-Signature")
  valid_600649 = validateParameter(valid_600649, JString, required = false,
                                 default = nil)
  if valid_600649 != nil:
    section.add "X-Amz-Signature", valid_600649
  var valid_600650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600650 = validateParameter(valid_600650, JString, required = false,
                                 default = nil)
  if valid_600650 != nil:
    section.add "X-Amz-SignedHeaders", valid_600650
  var valid_600651 = header.getOrDefault("X-Amz-Credential")
  valid_600651 = validateParameter(valid_600651, JString, required = false,
                                 default = nil)
  if valid_600651 != nil:
    section.add "X-Amz-Credential", valid_600651
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600653: Call_TagResource_600641; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more tags to the specified resource.</p> <p>Currently, you can tag and untag accounts in AWS Organizations.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_600653.validator(path, query, header, formData, body)
  let scheme = call_600653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600653.url(scheme.get, call_600653.host, call_600653.base,
                         call_600653.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600653, url, valid)

proc call*(call_600654: Call_TagResource_600641; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds one or more tags to the specified resource.</p> <p>Currently, you can tag and untag accounts in AWS Organizations.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_600655 = newJObject()
  if body != nil:
    body_600655 = body
  result = call_600654.call(nil, nil, nil, nil, body_600655)

var tagResource* = Call_TagResource_600641(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.TagResource",
                                        validator: validate_TagResource_600642,
                                        base: "/", url: url_TagResource_600643,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_600656 = ref object of OpenApiRestCall_599369
proc url_UntagResource_600658(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_600657(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600659 = header.getOrDefault("X-Amz-Date")
  valid_600659 = validateParameter(valid_600659, JString, required = false,
                                 default = nil)
  if valid_600659 != nil:
    section.add "X-Amz-Date", valid_600659
  var valid_600660 = header.getOrDefault("X-Amz-Security-Token")
  valid_600660 = validateParameter(valid_600660, JString, required = false,
                                 default = nil)
  if valid_600660 != nil:
    section.add "X-Amz-Security-Token", valid_600660
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600661 = header.getOrDefault("X-Amz-Target")
  valid_600661 = validateParameter(valid_600661, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.UntagResource"))
  if valid_600661 != nil:
    section.add "X-Amz-Target", valid_600661
  var valid_600662 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600662 = validateParameter(valid_600662, JString, required = false,
                                 default = nil)
  if valid_600662 != nil:
    section.add "X-Amz-Content-Sha256", valid_600662
  var valid_600663 = header.getOrDefault("X-Amz-Algorithm")
  valid_600663 = validateParameter(valid_600663, JString, required = false,
                                 default = nil)
  if valid_600663 != nil:
    section.add "X-Amz-Algorithm", valid_600663
  var valid_600664 = header.getOrDefault("X-Amz-Signature")
  valid_600664 = validateParameter(valid_600664, JString, required = false,
                                 default = nil)
  if valid_600664 != nil:
    section.add "X-Amz-Signature", valid_600664
  var valid_600665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600665 = validateParameter(valid_600665, JString, required = false,
                                 default = nil)
  if valid_600665 != nil:
    section.add "X-Amz-SignedHeaders", valid_600665
  var valid_600666 = header.getOrDefault("X-Amz-Credential")
  valid_600666 = validateParameter(valid_600666, JString, required = false,
                                 default = nil)
  if valid_600666 != nil:
    section.add "X-Amz-Credential", valid_600666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600668: Call_UntagResource_600656; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a tag from the specified resource. </p> <p>Currently, you can tag and untag accounts in AWS Organizations.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_600668.validator(path, query, header, formData, body)
  let scheme = call_600668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600668.url(scheme.get, call_600668.host, call_600668.base,
                         call_600668.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600668, url, valid)

proc call*(call_600669: Call_UntagResource_600656; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Removes a tag from the specified resource. </p> <p>Currently, you can tag and untag accounts in AWS Organizations.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_600670 = newJObject()
  if body != nil:
    body_600670 = body
  result = call_600669.call(nil, nil, nil, nil, body_600670)

var untagResource* = Call_UntagResource_600656(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.UntagResource",
    validator: validate_UntagResource_600657, base: "/", url: url_UntagResource_600658,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateOrganizationalUnit_600671 = ref object of OpenApiRestCall_599369
proc url_UpdateOrganizationalUnit_600673(protocol: Scheme; host: string;
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

proc validate_UpdateOrganizationalUnit_600672(path: JsonNode; query: JsonNode;
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
  var valid_600674 = header.getOrDefault("X-Amz-Date")
  valid_600674 = validateParameter(valid_600674, JString, required = false,
                                 default = nil)
  if valid_600674 != nil:
    section.add "X-Amz-Date", valid_600674
  var valid_600675 = header.getOrDefault("X-Amz-Security-Token")
  valid_600675 = validateParameter(valid_600675, JString, required = false,
                                 default = nil)
  if valid_600675 != nil:
    section.add "X-Amz-Security-Token", valid_600675
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600676 = header.getOrDefault("X-Amz-Target")
  valid_600676 = validateParameter(valid_600676, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.UpdateOrganizationalUnit"))
  if valid_600676 != nil:
    section.add "X-Amz-Target", valid_600676
  var valid_600677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600677 = validateParameter(valid_600677, JString, required = false,
                                 default = nil)
  if valid_600677 != nil:
    section.add "X-Amz-Content-Sha256", valid_600677
  var valid_600678 = header.getOrDefault("X-Amz-Algorithm")
  valid_600678 = validateParameter(valid_600678, JString, required = false,
                                 default = nil)
  if valid_600678 != nil:
    section.add "X-Amz-Algorithm", valid_600678
  var valid_600679 = header.getOrDefault("X-Amz-Signature")
  valid_600679 = validateParameter(valid_600679, JString, required = false,
                                 default = nil)
  if valid_600679 != nil:
    section.add "X-Amz-Signature", valid_600679
  var valid_600680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600680 = validateParameter(valid_600680, JString, required = false,
                                 default = nil)
  if valid_600680 != nil:
    section.add "X-Amz-SignedHeaders", valid_600680
  var valid_600681 = header.getOrDefault("X-Amz-Credential")
  valid_600681 = validateParameter(valid_600681, JString, required = false,
                                 default = nil)
  if valid_600681 != nil:
    section.add "X-Amz-Credential", valid_600681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600683: Call_UpdateOrganizationalUnit_600671; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Renames the specified organizational unit (OU). The ID and ARN don't change. The child OUs and accounts remain in place, and any attached policies of the OU remain attached. </p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_600683.validator(path, query, header, formData, body)
  let scheme = call_600683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600683.url(scheme.get, call_600683.host, call_600683.base,
                         call_600683.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600683, url, valid)

proc call*(call_600684: Call_UpdateOrganizationalUnit_600671; body: JsonNode): Recallable =
  ## updateOrganizationalUnit
  ## <p>Renames the specified organizational unit (OU). The ID and ARN don't change. The child OUs and accounts remain in place, and any attached policies of the OU remain attached. </p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_600685 = newJObject()
  if body != nil:
    body_600685 = body
  result = call_600684.call(nil, nil, nil, nil, body_600685)

var updateOrganizationalUnit* = Call_UpdateOrganizationalUnit_600671(
    name: "updateOrganizationalUnit", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.UpdateOrganizationalUnit",
    validator: validate_UpdateOrganizationalUnit_600672, base: "/",
    url: url_UpdateOrganizationalUnit_600673, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePolicy_600686 = ref object of OpenApiRestCall_599369
proc url_UpdatePolicy_600688(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePolicy_600687(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600689 = header.getOrDefault("X-Amz-Date")
  valid_600689 = validateParameter(valid_600689, JString, required = false,
                                 default = nil)
  if valid_600689 != nil:
    section.add "X-Amz-Date", valid_600689
  var valid_600690 = header.getOrDefault("X-Amz-Security-Token")
  valid_600690 = validateParameter(valid_600690, JString, required = false,
                                 default = nil)
  if valid_600690 != nil:
    section.add "X-Amz-Security-Token", valid_600690
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600691 = header.getOrDefault("X-Amz-Target")
  valid_600691 = validateParameter(valid_600691, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.UpdatePolicy"))
  if valid_600691 != nil:
    section.add "X-Amz-Target", valid_600691
  var valid_600692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600692 = validateParameter(valid_600692, JString, required = false,
                                 default = nil)
  if valid_600692 != nil:
    section.add "X-Amz-Content-Sha256", valid_600692
  var valid_600693 = header.getOrDefault("X-Amz-Algorithm")
  valid_600693 = validateParameter(valid_600693, JString, required = false,
                                 default = nil)
  if valid_600693 != nil:
    section.add "X-Amz-Algorithm", valid_600693
  var valid_600694 = header.getOrDefault("X-Amz-Signature")
  valid_600694 = validateParameter(valid_600694, JString, required = false,
                                 default = nil)
  if valid_600694 != nil:
    section.add "X-Amz-Signature", valid_600694
  var valid_600695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600695 = validateParameter(valid_600695, JString, required = false,
                                 default = nil)
  if valid_600695 != nil:
    section.add "X-Amz-SignedHeaders", valid_600695
  var valid_600696 = header.getOrDefault("X-Amz-Credential")
  valid_600696 = validateParameter(valid_600696, JString, required = false,
                                 default = nil)
  if valid_600696 != nil:
    section.add "X-Amz-Credential", valid_600696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600698: Call_UpdatePolicy_600686; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing policy with a new name, description, or content. If you don't supply any parameter, that value remains unchanged. You can't change a policy's type.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_600698.validator(path, query, header, formData, body)
  let scheme = call_600698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600698.url(scheme.get, call_600698.host, call_600698.base,
                         call_600698.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600698, url, valid)

proc call*(call_600699: Call_UpdatePolicy_600686; body: JsonNode): Recallable =
  ## updatePolicy
  ## <p>Updates an existing policy with a new name, description, or content. If you don't supply any parameter, that value remains unchanged. You can't change a policy's type.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_600700 = newJObject()
  if body != nil:
    body_600700 = body
  result = call_600699.call(nil, nil, nil, nil, body_600700)

var updatePolicy* = Call_UpdatePolicy_600686(name: "updatePolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.UpdatePolicy",
    validator: validate_UpdatePolicy_600687, base: "/", url: url_UpdatePolicy_600688,
    schemes: {Scheme.Https, Scheme.Http})
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
