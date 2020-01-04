
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

  OpenApiRestCall_601390 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601390](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601390): Option[Scheme] {.used.} =
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
  Call_AcceptHandshake_601728 = ref object of OpenApiRestCall_601390
proc url_AcceptHandshake_601730(protocol: Scheme; host: string; base: string;
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

proc validate_AcceptHandshake_601729(path: JsonNode; query: JsonNode;
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
  var valid_601855 = header.getOrDefault("X-Amz-Target")
  valid_601855 = validateParameter(valid_601855, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.AcceptHandshake"))
  if valid_601855 != nil:
    section.add "X-Amz-Target", valid_601855
  var valid_601856 = header.getOrDefault("X-Amz-Signature")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Signature", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Content-Sha256", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Date")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Date", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Credential")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Credential", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Security-Token")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Security-Token", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Algorithm")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Algorithm", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-SignedHeaders", valid_601862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601886: Call_AcceptHandshake_601728; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends a response to the originator of a handshake agreeing to the action proposed by the handshake request. </p> <p>This operation can be called only by the following principals when they also have the relevant IAM permissions:</p> <ul> <li> <p> <b>Invitation to join</b> or <b>Approve all features request</b> handshakes: only a principal from the member account. </p> <p>The user who calls the API for an invitation to join must have the <code>organizations:AcceptHandshake</code> permission. If you enabled all features in the organization, the user must also have the <code>iam:CreateServiceLinkedRole</code> permission so that AWS Organizations can create the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integration_services.html#orgs_integration_service-linked-roles">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide</i>.</p> </li> <li> <p> <b>Enable all features final confirmation</b> handshake: only a principal from the master account.</p> <p>For more information about invitations, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_invites.html">Inviting an AWS Account to Join Your Organization</a> in the <i>AWS Organizations User Guide.</i> For more information about requests to enable all features in the organization, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">Enabling All Features in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>After you accept a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
  ## 
  let valid = call_601886.validator(path, query, header, formData, body)
  let scheme = call_601886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601886.url(scheme.get, call_601886.host, call_601886.base,
                         call_601886.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601886, url, valid)

proc call*(call_601957: Call_AcceptHandshake_601728; body: JsonNode): Recallable =
  ## acceptHandshake
  ## <p>Sends a response to the originator of a handshake agreeing to the action proposed by the handshake request. </p> <p>This operation can be called only by the following principals when they also have the relevant IAM permissions:</p> <ul> <li> <p> <b>Invitation to join</b> or <b>Approve all features request</b> handshakes: only a principal from the member account. </p> <p>The user who calls the API for an invitation to join must have the <code>organizations:AcceptHandshake</code> permission. If you enabled all features in the organization, the user must also have the <code>iam:CreateServiceLinkedRole</code> permission so that AWS Organizations can create the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integration_services.html#orgs_integration_service-linked-roles">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide</i>.</p> </li> <li> <p> <b>Enable all features final confirmation</b> handshake: only a principal from the master account.</p> <p>For more information about invitations, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_invites.html">Inviting an AWS Account to Join Your Organization</a> in the <i>AWS Organizations User Guide.</i> For more information about requests to enable all features in the organization, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">Enabling All Features in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>After you accept a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
  ##   body: JObject (required)
  var body_601958 = newJObject()
  if body != nil:
    body_601958 = body
  result = call_601957.call(nil, nil, nil, nil, body_601958)

var acceptHandshake* = Call_AcceptHandshake_601728(name: "acceptHandshake",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.AcceptHandshake",
    validator: validate_AcceptHandshake_601729, base: "/", url: url_AcceptHandshake_601730,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachPolicy_601997 = ref object of OpenApiRestCall_601390
proc url_AttachPolicy_601999(protocol: Scheme; host: string; base: string;
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

proc validate_AttachPolicy_601998(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602000 = header.getOrDefault("X-Amz-Target")
  valid_602000 = validateParameter(valid_602000, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.AttachPolicy"))
  if valid_602000 != nil:
    section.add "X-Amz-Target", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-Signature")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Signature", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Content-Sha256", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Date")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Date", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Credential")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Credential", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Security-Token")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Security-Token", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Algorithm")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Algorithm", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-SignedHeaders", valid_602007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602009: Call_AttachPolicy_601997; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches a policy to a root, an organizational unit (OU), or an individual account.</p> <p>How the policy affects accounts depends on the type of policy:</p> <ul> <li> <p>For more information about attaching SCPs, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html">How SCPs Work</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>For information about attaching tag policies, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies-inheritance.html">How Policy Inheritance Works</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_602009.validator(path, query, header, formData, body)
  let scheme = call_602009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602009.url(scheme.get, call_602009.host, call_602009.base,
                         call_602009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602009, url, valid)

proc call*(call_602010: Call_AttachPolicy_601997; body: JsonNode): Recallable =
  ## attachPolicy
  ## <p>Attaches a policy to a root, an organizational unit (OU), or an individual account.</p> <p>How the policy affects accounts depends on the type of policy:</p> <ul> <li> <p>For more information about attaching SCPs, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html">How SCPs Work</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>For information about attaching tag policies, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies-inheritance.html">How Policy Inheritance Works</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_602011 = newJObject()
  if body != nil:
    body_602011 = body
  result = call_602010.call(nil, nil, nil, nil, body_602011)

var attachPolicy* = Call_AttachPolicy_601997(name: "attachPolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.AttachPolicy",
    validator: validate_AttachPolicy_601998, base: "/", url: url_AttachPolicy_601999,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelHandshake_602012 = ref object of OpenApiRestCall_601390
proc url_CancelHandshake_602014(protocol: Scheme; host: string; base: string;
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

proc validate_CancelHandshake_602013(path: JsonNode; query: JsonNode;
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
  var valid_602015 = header.getOrDefault("X-Amz-Target")
  valid_602015 = validateParameter(valid_602015, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CancelHandshake"))
  if valid_602015 != nil:
    section.add "X-Amz-Target", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Signature")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Signature", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Content-Sha256", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Date")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Date", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Credential")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Credential", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Security-Token")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Security-Token", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-Algorithm")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Algorithm", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-SignedHeaders", valid_602022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602024: Call_CancelHandshake_602012; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Cancels a handshake. Canceling a handshake sets the handshake state to <code>CANCELED</code>. </p> <p>This operation can be called only from the account that originated the handshake. The recipient of the handshake can't cancel it, but can use <a>DeclineHandshake</a> instead. After a handshake is canceled, the recipient can no longer respond to that handshake.</p> <p>After you cancel a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
  ## 
  let valid = call_602024.validator(path, query, header, formData, body)
  let scheme = call_602024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602024.url(scheme.get, call_602024.host, call_602024.base,
                         call_602024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602024, url, valid)

proc call*(call_602025: Call_CancelHandshake_602012; body: JsonNode): Recallable =
  ## cancelHandshake
  ## <p>Cancels a handshake. Canceling a handshake sets the handshake state to <code>CANCELED</code>. </p> <p>This operation can be called only from the account that originated the handshake. The recipient of the handshake can't cancel it, but can use <a>DeclineHandshake</a> instead. After a handshake is canceled, the recipient can no longer respond to that handshake.</p> <p>After you cancel a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.</p>
  ##   body: JObject (required)
  var body_602026 = newJObject()
  if body != nil:
    body_602026 = body
  result = call_602025.call(nil, nil, nil, nil, body_602026)

var cancelHandshake* = Call_CancelHandshake_602012(name: "cancelHandshake",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CancelHandshake",
    validator: validate_CancelHandshake_602013, base: "/", url: url_CancelHandshake_602014,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAccount_602027 = ref object of OpenApiRestCall_601390
proc url_CreateAccount_602029(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAccount_602028(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602030 = header.getOrDefault("X-Amz-Target")
  valid_602030 = validateParameter(valid_602030, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CreateAccount"))
  if valid_602030 != nil:
    section.add "X-Amz-Target", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Signature")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Signature", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Content-Sha256", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Date")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Date", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Credential")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Credential", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Security-Token")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Security-Token", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-Algorithm")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Algorithm", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-SignedHeaders", valid_602037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602039: Call_CreateAccount_602027; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS account that is automatically a member of the organization whose credentials made the request. This is an asynchronous request that AWS performs in the background. Because <code>CreateAccount</code> operates asynchronously, it can return a successful completion message even though account initialization might still be in progress. You might need to wait a few minutes before you can successfully access the account. To check the status of the request, do one of the following:</p> <ul> <li> <p>Use the <code>OperationId</code> response element from this operation to provide as a parameter to the <a>DescribeCreateAccountStatus</a> operation.</p> </li> <li> <p>Check the AWS CloudTrail log for the <code>CreateAccountResult</code> event. For information on using AWS CloudTrail with AWS Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_monitoring.html">Monitoring the Activity in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p/> <p>The user who calls the API to create an account must have the <code>organizations:CreateAccount</code> permission. If you enabled all features in the organization, AWS Organizations creates the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html#orgs_integrate_services-using_slrs">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide</i>.</p> <p>AWS Organizations preconfigures the new member account with a role (named <code>OrganizationAccountAccessRole</code> by default) that grants users in the master account administrator permissions in the new member account. Principals in the master account can assume the role. AWS Organizations clones the company name and address information for the new account from the organization's master account.</p> <p>This operation can be called only from the organization's master account.</p> <p>For more information about creating accounts, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_create.html">Creating an AWS Account in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <ul> <li> <p>When you create an account in an organization, the information required for the account to operate as a standalone account is <i>not</i> automatically collected. For example, information about the payment method and signing the end user license agreement (EULA) is not collected. If you must remove an account from your organization later, you can do so only after you provide the missing information. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization as a member account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> <li> <p>If you get an exception that indicates that you exceeded your account limits for the organization, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>If you get an exception that indicates that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>Using <code>CreateAccount</code> to create multiple temporary accounts isn't recommended. You can only close an account from the Billing and Cost Management Console, and you must be signed in as the root user. For information on the requirements and process for closing an account, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html">Closing an AWS Account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> </ul> </important> <note> <p>When you create a member account with this operation, you can choose whether to create the account with the <b>IAM User and Role Access to Billing Information</b> switch enabled. If you enable it, IAM users and roles that have appropriate permissions can view billing information for the account. If you disable it, only the account root user can access billing information. For information about how to disable this switch for an account, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html">Granting Access to Your Billing Information and Tools</a>.</p> </note>
  ## 
  let valid = call_602039.validator(path, query, header, formData, body)
  let scheme = call_602039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602039.url(scheme.get, call_602039.host, call_602039.base,
                         call_602039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602039, url, valid)

proc call*(call_602040: Call_CreateAccount_602027; body: JsonNode): Recallable =
  ## createAccount
  ## <p>Creates an AWS account that is automatically a member of the organization whose credentials made the request. This is an asynchronous request that AWS performs in the background. Because <code>CreateAccount</code> operates asynchronously, it can return a successful completion message even though account initialization might still be in progress. You might need to wait a few minutes before you can successfully access the account. To check the status of the request, do one of the following:</p> <ul> <li> <p>Use the <code>OperationId</code> response element from this operation to provide as a parameter to the <a>DescribeCreateAccountStatus</a> operation.</p> </li> <li> <p>Check the AWS CloudTrail log for the <code>CreateAccountResult</code> event. For information on using AWS CloudTrail with AWS Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_monitoring.html">Monitoring the Activity in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p/> <p>The user who calls the API to create an account must have the <code>organizations:CreateAccount</code> permission. If you enabled all features in the organization, AWS Organizations creates the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html#orgs_integrate_services-using_slrs">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide</i>.</p> <p>AWS Organizations preconfigures the new member account with a role (named <code>OrganizationAccountAccessRole</code> by default) that grants users in the master account administrator permissions in the new member account. Principals in the master account can assume the role. AWS Organizations clones the company name and address information for the new account from the organization's master account.</p> <p>This operation can be called only from the organization's master account.</p> <p>For more information about creating accounts, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_create.html">Creating an AWS Account in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <ul> <li> <p>When you create an account in an organization, the information required for the account to operate as a standalone account is <i>not</i> automatically collected. For example, information about the payment method and signing the end user license agreement (EULA) is not collected. If you must remove an account from your organization later, you can do so only after you provide the missing information. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization as a member account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> <li> <p>If you get an exception that indicates that you exceeded your account limits for the organization, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>If you get an exception that indicates that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>Using <code>CreateAccount</code> to create multiple temporary accounts isn't recommended. You can only close an account from the Billing and Cost Management Console, and you must be signed in as the root user. For information on the requirements and process for closing an account, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html">Closing an AWS Account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> </ul> </important> <note> <p>When you create a member account with this operation, you can choose whether to create the account with the <b>IAM User and Role Access to Billing Information</b> switch enabled. If you enable it, IAM users and roles that have appropriate permissions can view billing information for the account. If you disable it, only the account root user can access billing information. For information about how to disable this switch for an account, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html">Granting Access to Your Billing Information and Tools</a>.</p> </note>
  ##   body: JObject (required)
  var body_602041 = newJObject()
  if body != nil:
    body_602041 = body
  result = call_602040.call(nil, nil, nil, nil, body_602041)

var createAccount* = Call_CreateAccount_602027(name: "createAccount",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CreateAccount",
    validator: validate_CreateAccount_602028, base: "/", url: url_CreateAccount_602029,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGovCloudAccount_602042 = ref object of OpenApiRestCall_601390
proc url_CreateGovCloudAccount_602044(protocol: Scheme; host: string; base: string;
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

proc validate_CreateGovCloudAccount_602043(path: JsonNode; query: JsonNode;
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
  var valid_602045 = header.getOrDefault("X-Amz-Target")
  valid_602045 = validateParameter(valid_602045, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CreateGovCloudAccount"))
  if valid_602045 != nil:
    section.add "X-Amz-Target", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Signature")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Signature", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Content-Sha256", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Date")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Date", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Credential")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Credential", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Security-Token")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Security-Token", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-Algorithm")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Algorithm", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-SignedHeaders", valid_602052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602054: Call_CreateGovCloudAccount_602042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This action is available if all of the following are true:</p> <ul> <li> <p>You're authorized to create accounts in the AWS GovCloud (US) Region. For more information on the AWS GovCloud (US) Region, see the <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/welcome.html"> <i>AWS GovCloud User Guide</i>.</a> </p> </li> <li> <p>You already have an account in the AWS GovCloud (US) Region that is associated with your master account in the commercial Region. </p> </li> <li> <p>You call this action from the master account of your organization in the commercial Region.</p> </li> <li> <p>You have the <code>organizations:CreateGovCloudAccount</code> permission. AWS Organizations creates the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html#orgs_integrate_services-using_slrs">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>AWS automatically enables AWS CloudTrail for AWS GovCloud (US) accounts, but you should also do the following:</p> <ul> <li> <p>Verify that AWS CloudTrail is enabled to store logs.</p> </li> <li> <p>Create an S3 bucket for AWS CloudTrail log storage.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/verifying-cloudtrail.html">Verifying AWS CloudTrail Is Enabled</a> in the <i>AWS GovCloud User Guide</i>. </p> </li> </ul> <p>You call this action from the master account of your organization in the commercial Region to create a standalone AWS account in the AWS GovCloud (US) Region. After the account is created, the master account of an organization in the AWS GovCloud (US) Region can invite it to that organization. For more information on inviting standalone accounts in the AWS GovCloud (US) to join an organization, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-organizations.html">AWS Organizations</a> in the <i>AWS GovCloud User Guide.</i> </p> <p>Calling <code>CreateGovCloudAccount</code> is an asynchronous request that AWS performs in the background. Because <code>CreateGovCloudAccount</code> operates asynchronously, it can return a successful completion message even though account initialization might still be in progress. You might need to wait a few minutes before you can successfully access the account. To check the status of the request, do one of the following:</p> <ul> <li> <p>Use the <code>OperationId</code> response element from this operation to provide as a parameter to the <a>DescribeCreateAccountStatus</a> operation.</p> </li> <li> <p>Check the AWS CloudTrail log for the <code>CreateAccountResult</code> event. For information on using AWS CloudTrail with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_monitoring.html">Monitoring the Activity in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p/> <p>When you call the <code>CreateGovCloudAccount</code> action, you create two accounts: a standalone account in the AWS GovCloud (US) Region and an associated account in the commercial Region for billing and support purposes. The account in the commercial Region is automatically a member of the organization whose credentials made the request. Both accounts are associated with the same email address.</p> <p>A role is created in the new account in the commercial Region that allows the master account in the organization in the commercial Region to assume it. An AWS GovCloud (US) account is then created and associated with the commercial account that you just created. A role is created in the new AWS GovCloud (US) account. This role can be assumed by the AWS GovCloud (US) account that is associated with the master account of the commercial organization. For more information and to view a diagram that explains how account access works, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-organizations.html">AWS Organizations</a> in the <i>AWS GovCloud User Guide.</i> </p> <p>For more information about creating accounts, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_create.html">Creating an AWS Account in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <ul> <li> <p>You can create an account in an organization using the AWS Organizations console, API, or CLI commands. When you do, the information required for the account to operate as a standalone account, such as a payment method, is <i>not</i> automatically collected. If you must remove an account from your organization later, you can do so only after you provide the missing information. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization as a member account</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>If you get an exception that indicates that you exceeded your account limits for the organization, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>If you get an exception that indicates that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>Using <code>CreateGovCloudAccount</code> to create multiple temporary accounts isn't recommended. You can only close an account from the AWS Billing and Cost Management console, and you must be signed in as the root user. For information on the requirements and process for closing an account, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html">Closing an AWS Account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> </ul> </important> <note> <p>When you create a member account with this operation, you can choose whether to create the account with the <b>IAM User and Role Access to Billing Information</b> switch enabled. If you enable it, IAM users and roles that have appropriate permissions can view billing information for the account. If you disable it, only the account root user can access billing information. For information about how to disable this switch for an account, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html">Granting Access to Your Billing Information and Tools</a>.</p> </note>
  ## 
  let valid = call_602054.validator(path, query, header, formData, body)
  let scheme = call_602054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602054.url(scheme.get, call_602054.host, call_602054.base,
                         call_602054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602054, url, valid)

proc call*(call_602055: Call_CreateGovCloudAccount_602042; body: JsonNode): Recallable =
  ## createGovCloudAccount
  ## <p>This action is available if all of the following are true:</p> <ul> <li> <p>You're authorized to create accounts in the AWS GovCloud (US) Region. For more information on the AWS GovCloud (US) Region, see the <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/welcome.html"> <i>AWS GovCloud User Guide</i>.</a> </p> </li> <li> <p>You already have an account in the AWS GovCloud (US) Region that is associated with your master account in the commercial Region. </p> </li> <li> <p>You call this action from the master account of your organization in the commercial Region.</p> </li> <li> <p>You have the <code>organizations:CreateGovCloudAccount</code> permission. AWS Organizations creates the required service-linked role named <code>AWSServiceRoleForOrganizations</code>. For more information, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html#orgs_integrate_services-using_slrs">AWS Organizations and Service-Linked Roles</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p>AWS automatically enables AWS CloudTrail for AWS GovCloud (US) accounts, but you should also do the following:</p> <ul> <li> <p>Verify that AWS CloudTrail is enabled to store logs.</p> </li> <li> <p>Create an S3 bucket for AWS CloudTrail log storage.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/verifying-cloudtrail.html">Verifying AWS CloudTrail Is Enabled</a> in the <i>AWS GovCloud User Guide</i>. </p> </li> </ul> <p>You call this action from the master account of your organization in the commercial Region to create a standalone AWS account in the AWS GovCloud (US) Region. After the account is created, the master account of an organization in the AWS GovCloud (US) Region can invite it to that organization. For more information on inviting standalone accounts in the AWS GovCloud (US) to join an organization, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-organizations.html">AWS Organizations</a> in the <i>AWS GovCloud User Guide.</i> </p> <p>Calling <code>CreateGovCloudAccount</code> is an asynchronous request that AWS performs in the background. Because <code>CreateGovCloudAccount</code> operates asynchronously, it can return a successful completion message even though account initialization might still be in progress. You might need to wait a few minutes before you can successfully access the account. To check the status of the request, do one of the following:</p> <ul> <li> <p>Use the <code>OperationId</code> response element from this operation to provide as a parameter to the <a>DescribeCreateAccountStatus</a> operation.</p> </li> <li> <p>Check the AWS CloudTrail log for the <code>CreateAccountResult</code> event. For information on using AWS CloudTrail with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_monitoring.html">Monitoring the Activity in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> </li> </ul> <p/> <p>When you call the <code>CreateGovCloudAccount</code> action, you create two accounts: a standalone account in the AWS GovCloud (US) Region and an associated account in the commercial Region for billing and support purposes. The account in the commercial Region is automatically a member of the organization whose credentials made the request. Both accounts are associated with the same email address.</p> <p>A role is created in the new account in the commercial Region that allows the master account in the organization in the commercial Region to assume it. An AWS GovCloud (US) account is then created and associated with the commercial account that you just created. A role is created in the new AWS GovCloud (US) account. This role can be assumed by the AWS GovCloud (US) account that is associated with the master account of the commercial organization. For more information and to view a diagram that explains how account access works, see <a href="http://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-organizations.html">AWS Organizations</a> in the <i>AWS GovCloud User Guide.</i> </p> <p>For more information about creating accounts, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_create.html">Creating an AWS Account in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <ul> <li> <p>You can create an account in an organization using the AWS Organizations console, API, or CLI commands. When you do, the information required for the account to operate as a standalone account, such as a payment method, is <i>not</i> automatically collected. If you must remove an account from your organization later, you can do so only after you provide the missing information. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization as a member account</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>If you get an exception that indicates that you exceeded your account limits for the organization, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>If you get an exception that indicates that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> <li> <p>Using <code>CreateGovCloudAccount</code> to create multiple temporary accounts isn't recommended. You can only close an account from the AWS Billing and Cost Management console, and you must be signed in as the root user. For information on the requirements and process for closing an account, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html">Closing an AWS Account</a> in the <i>AWS Organizations User Guide</i>.</p> </li> </ul> </important> <note> <p>When you create a member account with this operation, you can choose whether to create the account with the <b>IAM User and Role Access to Billing Information</b> switch enabled. If you enable it, IAM users and roles that have appropriate permissions can view billing information for the account. If you disable it, only the account root user can access billing information. For information about how to disable this switch for an account, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html">Granting Access to Your Billing Information and Tools</a>.</p> </note>
  ##   body: JObject (required)
  var body_602056 = newJObject()
  if body != nil:
    body_602056 = body
  result = call_602055.call(nil, nil, nil, nil, body_602056)

var createGovCloudAccount* = Call_CreateGovCloudAccount_602042(
    name: "createGovCloudAccount", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CreateGovCloudAccount",
    validator: validate_CreateGovCloudAccount_602043, base: "/",
    url: url_CreateGovCloudAccount_602044, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateOrganization_602057 = ref object of OpenApiRestCall_601390
proc url_CreateOrganization_602059(protocol: Scheme; host: string; base: string;
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

proc validate_CreateOrganization_602058(path: JsonNode; query: JsonNode;
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
  var valid_602060 = header.getOrDefault("X-Amz-Target")
  valid_602060 = validateParameter(valid_602060, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CreateOrganization"))
  if valid_602060 != nil:
    section.add "X-Amz-Target", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Signature")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Signature", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Content-Sha256", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Date")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Date", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Credential")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Credential", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Security-Token")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Security-Token", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-Algorithm")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Algorithm", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-SignedHeaders", valid_602067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602069: Call_CreateOrganization_602057; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS organization. The account whose user is calling the <code>CreateOrganization</code> operation automatically becomes the <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/orgs_getting-started_concepts.html#account">master account</a> of the new organization.</p> <p>This operation must be called using credentials from the account that is to become the new organization's master account. The principal must also have the relevant IAM permissions.</p> <p>By default (or if you set the <code>FeatureSet</code> parameter to <code>ALL</code>), the new organization is created with all features enabled. In addition, service control policies are automatically enabled in the root. If you instead create the organization supporting only the consolidated billing features, no policy types are enabled by default, and you can't use organization policies.</p>
  ## 
  let valid = call_602069.validator(path, query, header, formData, body)
  let scheme = call_602069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602069.url(scheme.get, call_602069.host, call_602069.base,
                         call_602069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602069, url, valid)

proc call*(call_602070: Call_CreateOrganization_602057; body: JsonNode): Recallable =
  ## createOrganization
  ## <p>Creates an AWS organization. The account whose user is calling the <code>CreateOrganization</code> operation automatically becomes the <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/orgs_getting-started_concepts.html#account">master account</a> of the new organization.</p> <p>This operation must be called using credentials from the account that is to become the new organization's master account. The principal must also have the relevant IAM permissions.</p> <p>By default (or if you set the <code>FeatureSet</code> parameter to <code>ALL</code>), the new organization is created with all features enabled. In addition, service control policies are automatically enabled in the root. If you instead create the organization supporting only the consolidated billing features, no policy types are enabled by default, and you can't use organization policies.</p>
  ##   body: JObject (required)
  var body_602071 = newJObject()
  if body != nil:
    body_602071 = body
  result = call_602070.call(nil, nil, nil, nil, body_602071)

var createOrganization* = Call_CreateOrganization_602057(
    name: "createOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CreateOrganization",
    validator: validate_CreateOrganization_602058, base: "/",
    url: url_CreateOrganization_602059, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateOrganizationalUnit_602072 = ref object of OpenApiRestCall_601390
proc url_CreateOrganizationalUnit_602074(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateOrganizationalUnit_602073(path: JsonNode; query: JsonNode;
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
  var valid_602075 = header.getOrDefault("X-Amz-Target")
  valid_602075 = validateParameter(valid_602075, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CreateOrganizationalUnit"))
  if valid_602075 != nil:
    section.add "X-Amz-Target", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Signature")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Signature", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Content-Sha256", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Date")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Date", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Credential")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Credential", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Security-Token")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Security-Token", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-Algorithm")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-Algorithm", valid_602081
  var valid_602082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "X-Amz-SignedHeaders", valid_602082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602084: Call_CreateOrganizationalUnit_602072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an organizational unit (OU) within a root or parent OU. An OU is a container for accounts that enables you to organize your accounts to apply policies according to your business requirements. The number of levels deep that you can nest OUs is dependent upon the policy types enabled for that root. For service control policies, the limit is five. </p> <p>For more information about OUs, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_ous.html">Managing Organizational Units</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_602084.validator(path, query, header, formData, body)
  let scheme = call_602084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602084.url(scheme.get, call_602084.host, call_602084.base,
                         call_602084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602084, url, valid)

proc call*(call_602085: Call_CreateOrganizationalUnit_602072; body: JsonNode): Recallable =
  ## createOrganizationalUnit
  ## <p>Creates an organizational unit (OU) within a root or parent OU. An OU is a container for accounts that enables you to organize your accounts to apply policies according to your business requirements. The number of levels deep that you can nest OUs is dependent upon the policy types enabled for that root. For service control policies, the limit is five. </p> <p>For more information about OUs, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_ous.html">Managing Organizational Units</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_602086 = newJObject()
  if body != nil:
    body_602086 = body
  result = call_602085.call(nil, nil, nil, nil, body_602086)

var createOrganizationalUnit* = Call_CreateOrganizationalUnit_602072(
    name: "createOrganizationalUnit", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CreateOrganizationalUnit",
    validator: validate_CreateOrganizationalUnit_602073, base: "/",
    url: url_CreateOrganizationalUnit_602074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePolicy_602087 = ref object of OpenApiRestCall_601390
proc url_CreatePolicy_602089(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePolicy_602088(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602090 = header.getOrDefault("X-Amz-Target")
  valid_602090 = validateParameter(valid_602090, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.CreatePolicy"))
  if valid_602090 != nil:
    section.add "X-Amz-Target", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Signature")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Signature", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Content-Sha256", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Date")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Date", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Credential")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Credential", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Security-Token")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Security-Token", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-Algorithm")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-Algorithm", valid_602096
  var valid_602097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "X-Amz-SignedHeaders", valid_602097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602099: Call_CreatePolicy_602087; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a policy of a specified type that you can attach to a root, an organizational unit (OU), or an individual AWS account.</p> <p>For more information about policies and their use, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies.html">Managing Organization Policies</a>.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_602099.validator(path, query, header, formData, body)
  let scheme = call_602099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602099.url(scheme.get, call_602099.host, call_602099.base,
                         call_602099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602099, url, valid)

proc call*(call_602100: Call_CreatePolicy_602087; body: JsonNode): Recallable =
  ## createPolicy
  ## <p>Creates a policy of a specified type that you can attach to a root, an organizational unit (OU), or an individual AWS account.</p> <p>For more information about policies and their use, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies.html">Managing Organization Policies</a>.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_602101 = newJObject()
  if body != nil:
    body_602101 = body
  result = call_602100.call(nil, nil, nil, nil, body_602101)

var createPolicy* = Call_CreatePolicy_602087(name: "createPolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.CreatePolicy",
    validator: validate_CreatePolicy_602088, base: "/", url: url_CreatePolicy_602089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeclineHandshake_602102 = ref object of OpenApiRestCall_601390
proc url_DeclineHandshake_602104(protocol: Scheme; host: string; base: string;
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

proc validate_DeclineHandshake_602103(path: JsonNode; query: JsonNode;
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
  var valid_602105 = header.getOrDefault("X-Amz-Target")
  valid_602105 = validateParameter(valid_602105, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DeclineHandshake"))
  if valid_602105 != nil:
    section.add "X-Amz-Target", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Signature")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Signature", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Content-Sha256", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Date")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Date", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Credential")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Credential", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Security-Token")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Security-Token", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-Algorithm")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Algorithm", valid_602111
  var valid_602112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-SignedHeaders", valid_602112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602114: Call_DeclineHandshake_602102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Declines a handshake request. This sets the handshake state to <code>DECLINED</code> and effectively deactivates the request.</p> <p>This operation can be called only from the account that received the handshake. The originator of the handshake can use <a>CancelHandshake</a> instead. The originator can't reactivate a declined request, but can reinitiate the process with a new handshake request.</p> <p>After you decline a handshake, it continues to appear in the results of relevant API operations for only 30 days. After that, it's deleted.</p>
  ## 
  let valid = call_602114.validator(path, query, header, formData, body)
  let scheme = call_602114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602114.url(scheme.get, call_602114.host, call_602114.base,
                         call_602114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602114, url, valid)

proc call*(call_602115: Call_DeclineHandshake_602102; body: JsonNode): Recallable =
  ## declineHandshake
  ## <p>Declines a handshake request. This sets the handshake state to <code>DECLINED</code> and effectively deactivates the request.</p> <p>This operation can be called only from the account that received the handshake. The originator of the handshake can use <a>CancelHandshake</a> instead. The originator can't reactivate a declined request, but can reinitiate the process with a new handshake request.</p> <p>After you decline a handshake, it continues to appear in the results of relevant API operations for only 30 days. After that, it's deleted.</p>
  ##   body: JObject (required)
  var body_602116 = newJObject()
  if body != nil:
    body_602116 = body
  result = call_602115.call(nil, nil, nil, nil, body_602116)

var declineHandshake* = Call_DeclineHandshake_602102(name: "declineHandshake",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DeclineHandshake",
    validator: validate_DeclineHandshake_602103, base: "/",
    url: url_DeclineHandshake_602104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteOrganization_602117 = ref object of OpenApiRestCall_601390
proc url_DeleteOrganization_602119(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteOrganization_602118(path: JsonNode; query: JsonNode;
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
  var valid_602120 = header.getOrDefault("X-Amz-Target")
  valid_602120 = validateParameter(valid_602120, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DeleteOrganization"))
  if valid_602120 != nil:
    section.add "X-Amz-Target", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Signature")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Signature", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Content-Sha256", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Date")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Date", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Credential")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Credential", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Security-Token")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Security-Token", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-Algorithm")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-Algorithm", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-SignedHeaders", valid_602127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602128: Call_DeleteOrganization_602117; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the organization. You can delete an organization only by using credentials from the master account. The organization must be empty of member accounts.
  ## 
  let valid = call_602128.validator(path, query, header, formData, body)
  let scheme = call_602128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602128.url(scheme.get, call_602128.host, call_602128.base,
                         call_602128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602128, url, valid)

proc call*(call_602129: Call_DeleteOrganization_602117): Recallable =
  ## deleteOrganization
  ## Deletes the organization. You can delete an organization only by using credentials from the master account. The organization must be empty of member accounts.
  result = call_602129.call(nil, nil, nil, nil, nil)

var deleteOrganization* = Call_DeleteOrganization_602117(
    name: "deleteOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DeleteOrganization",
    validator: validate_DeleteOrganization_602118, base: "/",
    url: url_DeleteOrganization_602119, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteOrganizationalUnit_602130 = ref object of OpenApiRestCall_601390
proc url_DeleteOrganizationalUnit_602132(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteOrganizationalUnit_602131(path: JsonNode; query: JsonNode;
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
  var valid_602133 = header.getOrDefault("X-Amz-Target")
  valid_602133 = validateParameter(valid_602133, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DeleteOrganizationalUnit"))
  if valid_602133 != nil:
    section.add "X-Amz-Target", valid_602133
  var valid_602134 = header.getOrDefault("X-Amz-Signature")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "X-Amz-Signature", valid_602134
  var valid_602135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Content-Sha256", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Date")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Date", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-Credential")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Credential", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-Security-Token")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Security-Token", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Algorithm")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Algorithm", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-SignedHeaders", valid_602140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602142: Call_DeleteOrganizationalUnit_602130; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an organizational unit (OU) from a root or another OU. You must first remove all accounts and child OUs from the OU that you want to delete.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_602142.validator(path, query, header, formData, body)
  let scheme = call_602142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602142.url(scheme.get, call_602142.host, call_602142.base,
                         call_602142.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602142, url, valid)

proc call*(call_602143: Call_DeleteOrganizationalUnit_602130; body: JsonNode): Recallable =
  ## deleteOrganizationalUnit
  ## <p>Deletes an organizational unit (OU) from a root or another OU. You must first remove all accounts and child OUs from the OU that you want to delete.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_602144 = newJObject()
  if body != nil:
    body_602144 = body
  result = call_602143.call(nil, nil, nil, nil, body_602144)

var deleteOrganizationalUnit* = Call_DeleteOrganizationalUnit_602130(
    name: "deleteOrganizationalUnit", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DeleteOrganizationalUnit",
    validator: validate_DeleteOrganizationalUnit_602131, base: "/",
    url: url_DeleteOrganizationalUnit_602132, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePolicy_602145 = ref object of OpenApiRestCall_601390
proc url_DeletePolicy_602147(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePolicy_602146(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602148 = header.getOrDefault("X-Amz-Target")
  valid_602148 = validateParameter(valid_602148, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DeletePolicy"))
  if valid_602148 != nil:
    section.add "X-Amz-Target", valid_602148
  var valid_602149 = header.getOrDefault("X-Amz-Signature")
  valid_602149 = validateParameter(valid_602149, JString, required = false,
                                 default = nil)
  if valid_602149 != nil:
    section.add "X-Amz-Signature", valid_602149
  var valid_602150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-Content-Sha256", valid_602150
  var valid_602151 = header.getOrDefault("X-Amz-Date")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-Date", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-Credential")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-Credential", valid_602152
  var valid_602153 = header.getOrDefault("X-Amz-Security-Token")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Security-Token", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Algorithm")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Algorithm", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-SignedHeaders", valid_602155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602157: Call_DeletePolicy_602145; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified policy from your organization. Before you perform this operation, you must first detach the policy from all organizational units (OUs), roots, and accounts.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_602157.validator(path, query, header, formData, body)
  let scheme = call_602157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602157.url(scheme.get, call_602157.host, call_602157.base,
                         call_602157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602157, url, valid)

proc call*(call_602158: Call_DeletePolicy_602145; body: JsonNode): Recallable =
  ## deletePolicy
  ## <p>Deletes the specified policy from your organization. Before you perform this operation, you must first detach the policy from all organizational units (OUs), roots, and accounts.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_602159 = newJObject()
  if body != nil:
    body_602159 = body
  result = call_602158.call(nil, nil, nil, nil, body_602159)

var deletePolicy* = Call_DeletePolicy_602145(name: "deletePolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DeletePolicy",
    validator: validate_DeletePolicy_602146, base: "/", url: url_DeletePolicy_602147,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccount_602160 = ref object of OpenApiRestCall_601390
proc url_DescribeAccount_602162(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeAccount_602161(path: JsonNode; query: JsonNode;
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
  var valid_602163 = header.getOrDefault("X-Amz-Target")
  valid_602163 = validateParameter(valid_602163, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribeAccount"))
  if valid_602163 != nil:
    section.add "X-Amz-Target", valid_602163
  var valid_602164 = header.getOrDefault("X-Amz-Signature")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-Signature", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Content-Sha256", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-Date")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Date", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-Credential")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Credential", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-Security-Token")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-Security-Token", valid_602168
  var valid_602169 = header.getOrDefault("X-Amz-Algorithm")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-Algorithm", valid_602169
  var valid_602170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-SignedHeaders", valid_602170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602172: Call_DescribeAccount_602160; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves AWS Organizations related information about the specified account.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_602172.validator(path, query, header, formData, body)
  let scheme = call_602172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602172.url(scheme.get, call_602172.host, call_602172.base,
                         call_602172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602172, url, valid)

proc call*(call_602173: Call_DescribeAccount_602160; body: JsonNode): Recallable =
  ## describeAccount
  ## <p>Retrieves AWS Organizations related information about the specified account.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_602174 = newJObject()
  if body != nil:
    body_602174 = body
  result = call_602173.call(nil, nil, nil, nil, body_602174)

var describeAccount* = Call_DescribeAccount_602160(name: "describeAccount",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribeAccount",
    validator: validate_DescribeAccount_602161, base: "/", url: url_DescribeAccount_602162,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCreateAccountStatus_602175 = ref object of OpenApiRestCall_601390
proc url_DescribeCreateAccountStatus_602177(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCreateAccountStatus_602176(path: JsonNode; query: JsonNode;
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
  var valid_602178 = header.getOrDefault("X-Amz-Target")
  valid_602178 = validateParameter(valid_602178, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribeCreateAccountStatus"))
  if valid_602178 != nil:
    section.add "X-Amz-Target", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Signature")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Signature", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Content-Sha256", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Date")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Date", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-Credential")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Credential", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-Security-Token")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Security-Token", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-Algorithm")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-Algorithm", valid_602184
  var valid_602185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "X-Amz-SignedHeaders", valid_602185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602187: Call_DescribeCreateAccountStatus_602175; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the current status of an asynchronous request to create an account.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_602187.validator(path, query, header, formData, body)
  let scheme = call_602187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602187.url(scheme.get, call_602187.host, call_602187.base,
                         call_602187.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602187, url, valid)

proc call*(call_602188: Call_DescribeCreateAccountStatus_602175; body: JsonNode): Recallable =
  ## describeCreateAccountStatus
  ## <p>Retrieves the current status of an asynchronous request to create an account.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_602189 = newJObject()
  if body != nil:
    body_602189 = body
  result = call_602188.call(nil, nil, nil, nil, body_602189)

var describeCreateAccountStatus* = Call_DescribeCreateAccountStatus_602175(
    name: "describeCreateAccountStatus", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribeCreateAccountStatus",
    validator: validate_DescribeCreateAccountStatus_602176, base: "/",
    url: url_DescribeCreateAccountStatus_602177,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEffectivePolicy_602190 = ref object of OpenApiRestCall_601390
proc url_DescribeEffectivePolicy_602192(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEffectivePolicy_602191(path: JsonNode; query: JsonNode;
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
  var valid_602193 = header.getOrDefault("X-Amz-Target")
  valid_602193 = validateParameter(valid_602193, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribeEffectivePolicy"))
  if valid_602193 != nil:
    section.add "X-Amz-Target", valid_602193
  var valid_602194 = header.getOrDefault("X-Amz-Signature")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-Signature", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Content-Sha256", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Date")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Date", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Credential")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Credential", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Security-Token")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Security-Token", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-Algorithm")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Algorithm", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-SignedHeaders", valid_602200
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602202: Call_DescribeEffectivePolicy_602190; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the contents of the effective tag policy for the account. The effective tag policy is the aggregation of any tag policies the account inherits, plus any policy directly that is attached to the account. </p> <p>This action returns information on tag policies only.</p> <p>For more information on policy inheritance, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies-inheritance.html">How Policy Inheritance Works</a> in the <i>AWS Organizations User Guide</i>.</p> <p>This operation can be called from any account in the organization.</p>
  ## 
  let valid = call_602202.validator(path, query, header, formData, body)
  let scheme = call_602202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602202.url(scheme.get, call_602202.host, call_602202.base,
                         call_602202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602202, url, valid)

proc call*(call_602203: Call_DescribeEffectivePolicy_602190; body: JsonNode): Recallable =
  ## describeEffectivePolicy
  ## <p>Returns the contents of the effective tag policy for the account. The effective tag policy is the aggregation of any tag policies the account inherits, plus any policy directly that is attached to the account. </p> <p>This action returns information on tag policies only.</p> <p>For more information on policy inheritance, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies-inheritance.html">How Policy Inheritance Works</a> in the <i>AWS Organizations User Guide</i>.</p> <p>This operation can be called from any account in the organization.</p>
  ##   body: JObject (required)
  var body_602204 = newJObject()
  if body != nil:
    body_602204 = body
  result = call_602203.call(nil, nil, nil, nil, body_602204)

var describeEffectivePolicy* = Call_DescribeEffectivePolicy_602190(
    name: "describeEffectivePolicy", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribeEffectivePolicy",
    validator: validate_DescribeEffectivePolicy_602191, base: "/",
    url: url_DescribeEffectivePolicy_602192, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHandshake_602205 = ref object of OpenApiRestCall_601390
proc url_DescribeHandshake_602207(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeHandshake_602206(path: JsonNode; query: JsonNode;
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
  var valid_602208 = header.getOrDefault("X-Amz-Target")
  valid_602208 = validateParameter(valid_602208, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribeHandshake"))
  if valid_602208 != nil:
    section.add "X-Amz-Target", valid_602208
  var valid_602209 = header.getOrDefault("X-Amz-Signature")
  valid_602209 = validateParameter(valid_602209, JString, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "X-Amz-Signature", valid_602209
  var valid_602210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-Content-Sha256", valid_602210
  var valid_602211 = header.getOrDefault("X-Amz-Date")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Date", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-Credential")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-Credential", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-Security-Token")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Security-Token", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-Algorithm")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-Algorithm", valid_602214
  var valid_602215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-SignedHeaders", valid_602215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602217: Call_DescribeHandshake_602205; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about a previously requested handshake. The handshake ID comes from the response to the original <a>InviteAccountToOrganization</a> operation that generated the handshake.</p> <p>You can access handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> for only 30 days after they change to that state. They're then deleted and no longer accessible.</p> <p>This operation can be called from any account in the organization.</p>
  ## 
  let valid = call_602217.validator(path, query, header, formData, body)
  let scheme = call_602217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602217.url(scheme.get, call_602217.host, call_602217.base,
                         call_602217.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602217, url, valid)

proc call*(call_602218: Call_DescribeHandshake_602205; body: JsonNode): Recallable =
  ## describeHandshake
  ## <p>Retrieves information about a previously requested handshake. The handshake ID comes from the response to the original <a>InviteAccountToOrganization</a> operation that generated the handshake.</p> <p>You can access handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> for only 30 days after they change to that state. They're then deleted and no longer accessible.</p> <p>This operation can be called from any account in the organization.</p>
  ##   body: JObject (required)
  var body_602219 = newJObject()
  if body != nil:
    body_602219 = body
  result = call_602218.call(nil, nil, nil, nil, body_602219)

var describeHandshake* = Call_DescribeHandshake_602205(name: "describeHandshake",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribeHandshake",
    validator: validate_DescribeHandshake_602206, base: "/",
    url: url_DescribeHandshake_602207, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOrganization_602220 = ref object of OpenApiRestCall_601390
proc url_DescribeOrganization_602222(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeOrganization_602221(path: JsonNode; query: JsonNode;
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
  var valid_602223 = header.getOrDefault("X-Amz-Target")
  valid_602223 = validateParameter(valid_602223, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribeOrganization"))
  if valid_602223 != nil:
    section.add "X-Amz-Target", valid_602223
  var valid_602224 = header.getOrDefault("X-Amz-Signature")
  valid_602224 = validateParameter(valid_602224, JString, required = false,
                                 default = nil)
  if valid_602224 != nil:
    section.add "X-Amz-Signature", valid_602224
  var valid_602225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "X-Amz-Content-Sha256", valid_602225
  var valid_602226 = header.getOrDefault("X-Amz-Date")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-Date", valid_602226
  var valid_602227 = header.getOrDefault("X-Amz-Credential")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-Credential", valid_602227
  var valid_602228 = header.getOrDefault("X-Amz-Security-Token")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-Security-Token", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-Algorithm")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-Algorithm", valid_602229
  var valid_602230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-SignedHeaders", valid_602230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602231: Call_DescribeOrganization_602220; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about the organization that the user's account belongs to.</p> <p>This operation can be called from any account in the organization.</p> <note> <p>Even if a policy type is shown as available in the organization, you can disable it separately at the root level with <a>DisablePolicyType</a>. Use <a>ListRoots</a> to see the status of policy types for a specified root.</p> </note>
  ## 
  let valid = call_602231.validator(path, query, header, formData, body)
  let scheme = call_602231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602231.url(scheme.get, call_602231.host, call_602231.base,
                         call_602231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602231, url, valid)

proc call*(call_602232: Call_DescribeOrganization_602220): Recallable =
  ## describeOrganization
  ## <p>Retrieves information about the organization that the user's account belongs to.</p> <p>This operation can be called from any account in the organization.</p> <note> <p>Even if a policy type is shown as available in the organization, you can disable it separately at the root level with <a>DisablePolicyType</a>. Use <a>ListRoots</a> to see the status of policy types for a specified root.</p> </note>
  result = call_602232.call(nil, nil, nil, nil, nil)

var describeOrganization* = Call_DescribeOrganization_602220(
    name: "describeOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribeOrganization",
    validator: validate_DescribeOrganization_602221, base: "/",
    url: url_DescribeOrganization_602222, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOrganizationalUnit_602233 = ref object of OpenApiRestCall_601390
proc url_DescribeOrganizationalUnit_602235(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeOrganizationalUnit_602234(path: JsonNode; query: JsonNode;
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
  var valid_602236 = header.getOrDefault("X-Amz-Target")
  valid_602236 = validateParameter(valid_602236, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribeOrganizationalUnit"))
  if valid_602236 != nil:
    section.add "X-Amz-Target", valid_602236
  var valid_602237 = header.getOrDefault("X-Amz-Signature")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "X-Amz-Signature", valid_602237
  var valid_602238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "X-Amz-Content-Sha256", valid_602238
  var valid_602239 = header.getOrDefault("X-Amz-Date")
  valid_602239 = validateParameter(valid_602239, JString, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "X-Amz-Date", valid_602239
  var valid_602240 = header.getOrDefault("X-Amz-Credential")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-Credential", valid_602240
  var valid_602241 = header.getOrDefault("X-Amz-Security-Token")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-Security-Token", valid_602241
  var valid_602242 = header.getOrDefault("X-Amz-Algorithm")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "X-Amz-Algorithm", valid_602242
  var valid_602243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "X-Amz-SignedHeaders", valid_602243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602245: Call_DescribeOrganizationalUnit_602233; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about an organizational unit (OU).</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_602245.validator(path, query, header, formData, body)
  let scheme = call_602245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602245.url(scheme.get, call_602245.host, call_602245.base,
                         call_602245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602245, url, valid)

proc call*(call_602246: Call_DescribeOrganizationalUnit_602233; body: JsonNode): Recallable =
  ## describeOrganizationalUnit
  ## <p>Retrieves information about an organizational unit (OU).</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_602247 = newJObject()
  if body != nil:
    body_602247 = body
  result = call_602246.call(nil, nil, nil, nil, body_602247)

var describeOrganizationalUnit* = Call_DescribeOrganizationalUnit_602233(
    name: "describeOrganizationalUnit", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribeOrganizationalUnit",
    validator: validate_DescribeOrganizationalUnit_602234, base: "/",
    url: url_DescribeOrganizationalUnit_602235,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePolicy_602248 = ref object of OpenApiRestCall_601390
proc url_DescribePolicy_602250(protocol: Scheme; host: string; base: string;
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

proc validate_DescribePolicy_602249(path: JsonNode; query: JsonNode;
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
  var valid_602251 = header.getOrDefault("X-Amz-Target")
  valid_602251 = validateParameter(valid_602251, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DescribePolicy"))
  if valid_602251 != nil:
    section.add "X-Amz-Target", valid_602251
  var valid_602252 = header.getOrDefault("X-Amz-Signature")
  valid_602252 = validateParameter(valid_602252, JString, required = false,
                                 default = nil)
  if valid_602252 != nil:
    section.add "X-Amz-Signature", valid_602252
  var valid_602253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602253 = validateParameter(valid_602253, JString, required = false,
                                 default = nil)
  if valid_602253 != nil:
    section.add "X-Amz-Content-Sha256", valid_602253
  var valid_602254 = header.getOrDefault("X-Amz-Date")
  valid_602254 = validateParameter(valid_602254, JString, required = false,
                                 default = nil)
  if valid_602254 != nil:
    section.add "X-Amz-Date", valid_602254
  var valid_602255 = header.getOrDefault("X-Amz-Credential")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "X-Amz-Credential", valid_602255
  var valid_602256 = header.getOrDefault("X-Amz-Security-Token")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-Security-Token", valid_602256
  var valid_602257 = header.getOrDefault("X-Amz-Algorithm")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "X-Amz-Algorithm", valid_602257
  var valid_602258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602258 = validateParameter(valid_602258, JString, required = false,
                                 default = nil)
  if valid_602258 != nil:
    section.add "X-Amz-SignedHeaders", valid_602258
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602260: Call_DescribePolicy_602248; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about a policy.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_602260.validator(path, query, header, formData, body)
  let scheme = call_602260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602260.url(scheme.get, call_602260.host, call_602260.base,
                         call_602260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602260, url, valid)

proc call*(call_602261: Call_DescribePolicy_602248; body: JsonNode): Recallable =
  ## describePolicy
  ## <p>Retrieves information about a policy.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_602262 = newJObject()
  if body != nil:
    body_602262 = body
  result = call_602261.call(nil, nil, nil, nil, body_602262)

var describePolicy* = Call_DescribePolicy_602248(name: "describePolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DescribePolicy",
    validator: validate_DescribePolicy_602249, base: "/", url: url_DescribePolicy_602250,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachPolicy_602263 = ref object of OpenApiRestCall_601390
proc url_DetachPolicy_602265(protocol: Scheme; host: string; base: string;
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

proc validate_DetachPolicy_602264(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602266 = header.getOrDefault("X-Amz-Target")
  valid_602266 = validateParameter(valid_602266, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DetachPolicy"))
  if valid_602266 != nil:
    section.add "X-Amz-Target", valid_602266
  var valid_602267 = header.getOrDefault("X-Amz-Signature")
  valid_602267 = validateParameter(valid_602267, JString, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "X-Amz-Signature", valid_602267
  var valid_602268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602268 = validateParameter(valid_602268, JString, required = false,
                                 default = nil)
  if valid_602268 != nil:
    section.add "X-Amz-Content-Sha256", valid_602268
  var valid_602269 = header.getOrDefault("X-Amz-Date")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "X-Amz-Date", valid_602269
  var valid_602270 = header.getOrDefault("X-Amz-Credential")
  valid_602270 = validateParameter(valid_602270, JString, required = false,
                                 default = nil)
  if valid_602270 != nil:
    section.add "X-Amz-Credential", valid_602270
  var valid_602271 = header.getOrDefault("X-Amz-Security-Token")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "X-Amz-Security-Token", valid_602271
  var valid_602272 = header.getOrDefault("X-Amz-Algorithm")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-Algorithm", valid_602272
  var valid_602273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-SignedHeaders", valid_602273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602275: Call_DetachPolicy_602263; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detaches a policy from a target root, organizational unit (OU), or account. If the policy being detached is a service control policy (SCP), the changes to permissions for IAM users and roles in affected accounts are immediate.</p> <p> <b>Note:</b> Every root, OU, and account must have at least one SCP attached. You can replace the default <code>FullAWSAccess</code> policy with one that limits the permissions that can be delegated. To do that, you must attach the replacement policy before you can remove the default one. This is the authorization strategy of using an <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html#orgs_policies_whitelist">allow list</a>. You could instead attach a second SCP and leave the <code>FullAWSAccess</code> SCP still attached. You could then specify <code>"Effect": "Deny"</code> in the second SCP to override the <code>"Effect": "Allow"</code> in the <code>FullAWSAccess</code> policy (or any other attached SCP). If you take these steps, you're using the authorization strategy of a <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html#orgs_policies_blacklist">deny list</a>. </p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_602275.validator(path, query, header, formData, body)
  let scheme = call_602275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602275.url(scheme.get, call_602275.host, call_602275.base,
                         call_602275.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602275, url, valid)

proc call*(call_602276: Call_DetachPolicy_602263; body: JsonNode): Recallable =
  ## detachPolicy
  ## <p>Detaches a policy from a target root, organizational unit (OU), or account. If the policy being detached is a service control policy (SCP), the changes to permissions for IAM users and roles in affected accounts are immediate.</p> <p> <b>Note:</b> Every root, OU, and account must have at least one SCP attached. You can replace the default <code>FullAWSAccess</code> policy with one that limits the permissions that can be delegated. To do that, you must attach the replacement policy before you can remove the default one. This is the authorization strategy of using an <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html#orgs_policies_whitelist">allow list</a>. You could instead attach a second SCP and leave the <code>FullAWSAccess</code> SCP still attached. You could then specify <code>"Effect": "Deny"</code> in the second SCP to override the <code>"Effect": "Allow"</code> in the <code>FullAWSAccess</code> policy (or any other attached SCP). If you take these steps, you're using the authorization strategy of a <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_about-scps.html#orgs_policies_blacklist">deny list</a>. </p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_602277 = newJObject()
  if body != nil:
    body_602277 = body
  result = call_602276.call(nil, nil, nil, nil, body_602277)

var detachPolicy* = Call_DetachPolicy_602263(name: "detachPolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DetachPolicy",
    validator: validate_DetachPolicy_602264, base: "/", url: url_DetachPolicy_602265,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableAWSServiceAccess_602278 = ref object of OpenApiRestCall_601390
proc url_DisableAWSServiceAccess_602280(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableAWSServiceAccess_602279(path: JsonNode; query: JsonNode;
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
  var valid_602281 = header.getOrDefault("X-Amz-Target")
  valid_602281 = validateParameter(valid_602281, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DisableAWSServiceAccess"))
  if valid_602281 != nil:
    section.add "X-Amz-Target", valid_602281
  var valid_602282 = header.getOrDefault("X-Amz-Signature")
  valid_602282 = validateParameter(valid_602282, JString, required = false,
                                 default = nil)
  if valid_602282 != nil:
    section.add "X-Amz-Signature", valid_602282
  var valid_602283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "X-Amz-Content-Sha256", valid_602283
  var valid_602284 = header.getOrDefault("X-Amz-Date")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "X-Amz-Date", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-Credential")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-Credential", valid_602285
  var valid_602286 = header.getOrDefault("X-Amz-Security-Token")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "X-Amz-Security-Token", valid_602286
  var valid_602287 = header.getOrDefault("X-Amz-Algorithm")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "X-Amz-Algorithm", valid_602287
  var valid_602288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "X-Amz-SignedHeaders", valid_602288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602290: Call_DisableAWSServiceAccess_602278; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables the integration of an AWS service (the service that is specified by <code>ServicePrincipal</code>) with AWS Organizations. When you disable integration, the specified service no longer can create a <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html">service-linked role</a> in <i>new</i> accounts in your organization. This means the service can't perform operations on your behalf on any new accounts in your organization. The service can still perform operations in older accounts until the service completes its clean-up from AWS Organizations.</p> <p/> <important> <p>We recommend that you disable integration between AWS Organizations and the specified AWS service by using the console or commands that are provided by the specified service. Doing so ensures that the other service is aware that it can clean up any resources that are required only for the integration. How the service cleans up its resources in the organization's accounts depends on that service. For more information, see the documentation for the other AWS service.</p> </important> <p>After you perform the <code>DisableAWSServiceAccess</code> operation, the specified service can no longer perform operations in your organization's accounts. The only exception is when the operations are explicitly permitted by IAM policies that are attached to your roles. </p> <p>For more information about integrating other services with AWS Organizations, including the list of services that work with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_602290.validator(path, query, header, formData, body)
  let scheme = call_602290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602290.url(scheme.get, call_602290.host, call_602290.base,
                         call_602290.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602290, url, valid)

proc call*(call_602291: Call_DisableAWSServiceAccess_602278; body: JsonNode): Recallable =
  ## disableAWSServiceAccess
  ## <p>Disables the integration of an AWS service (the service that is specified by <code>ServicePrincipal</code>) with AWS Organizations. When you disable integration, the specified service no longer can create a <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html">service-linked role</a> in <i>new</i> accounts in your organization. This means the service can't perform operations on your behalf on any new accounts in your organization. The service can still perform operations in older accounts until the service completes its clean-up from AWS Organizations.</p> <p/> <important> <p>We recommend that you disable integration between AWS Organizations and the specified AWS service by using the console or commands that are provided by the specified service. Doing so ensures that the other service is aware that it can clean up any resources that are required only for the integration. How the service cleans up its resources in the organization's accounts depends on that service. For more information, see the documentation for the other AWS service.</p> </important> <p>After you perform the <code>DisableAWSServiceAccess</code> operation, the specified service can no longer perform operations in your organization's accounts. The only exception is when the operations are explicitly permitted by IAM policies that are attached to your roles. </p> <p>For more information about integrating other services with AWS Organizations, including the list of services that work with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_602292 = newJObject()
  if body != nil:
    body_602292 = body
  result = call_602291.call(nil, nil, nil, nil, body_602292)

var disableAWSServiceAccess* = Call_DisableAWSServiceAccess_602278(
    name: "disableAWSServiceAccess", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DisableAWSServiceAccess",
    validator: validate_DisableAWSServiceAccess_602279, base: "/",
    url: url_DisableAWSServiceAccess_602280, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisablePolicyType_602293 = ref object of OpenApiRestCall_601390
proc url_DisablePolicyType_602295(protocol: Scheme; host: string; base: string;
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

proc validate_DisablePolicyType_602294(path: JsonNode; query: JsonNode;
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
  var valid_602296 = header.getOrDefault("X-Amz-Target")
  valid_602296 = validateParameter(valid_602296, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.DisablePolicyType"))
  if valid_602296 != nil:
    section.add "X-Amz-Target", valid_602296
  var valid_602297 = header.getOrDefault("X-Amz-Signature")
  valid_602297 = validateParameter(valid_602297, JString, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "X-Amz-Signature", valid_602297
  var valid_602298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602298 = validateParameter(valid_602298, JString, required = false,
                                 default = nil)
  if valid_602298 != nil:
    section.add "X-Amz-Content-Sha256", valid_602298
  var valid_602299 = header.getOrDefault("X-Amz-Date")
  valid_602299 = validateParameter(valid_602299, JString, required = false,
                                 default = nil)
  if valid_602299 != nil:
    section.add "X-Amz-Date", valid_602299
  var valid_602300 = header.getOrDefault("X-Amz-Credential")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-Credential", valid_602300
  var valid_602301 = header.getOrDefault("X-Amz-Security-Token")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "X-Amz-Security-Token", valid_602301
  var valid_602302 = header.getOrDefault("X-Amz-Algorithm")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "X-Amz-Algorithm", valid_602302
  var valid_602303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602303 = validateParameter(valid_602303, JString, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "X-Amz-SignedHeaders", valid_602303
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602305: Call_DisablePolicyType_602293; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables an organizational control policy type in a root and detaches all policies of that type from the organization root, OUs, and accounts. A policy of a certain type can be attached to entities in a root only if that type is enabled in the root. After you perform this operation, you no longer can attach policies of the specified type to that root or to any organizational unit (OU) or account in that root. You can undo this by using the <a>EnablePolicyType</a> operation.</p> <p>This is an asynchronous request that AWS performs in the background. If you disable a policy for a root, it still appears enabled for the organization if <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">all features</a> are enabled for the organization. AWS recommends that you first use <a>ListRoots</a> to see the status of policy types for a specified root, and then use this operation. </p> <p>This operation can be called only from the organization's master account.</p> <p> To view the status of available policy types in the organization, use <a>DescribeOrganization</a>.</p>
  ## 
  let valid = call_602305.validator(path, query, header, formData, body)
  let scheme = call_602305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602305.url(scheme.get, call_602305.host, call_602305.base,
                         call_602305.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602305, url, valid)

proc call*(call_602306: Call_DisablePolicyType_602293; body: JsonNode): Recallable =
  ## disablePolicyType
  ## <p>Disables an organizational control policy type in a root and detaches all policies of that type from the organization root, OUs, and accounts. A policy of a certain type can be attached to entities in a root only if that type is enabled in the root. After you perform this operation, you no longer can attach policies of the specified type to that root or to any organizational unit (OU) or account in that root. You can undo this by using the <a>EnablePolicyType</a> operation.</p> <p>This is an asynchronous request that AWS performs in the background. If you disable a policy for a root, it still appears enabled for the organization if <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">all features</a> are enabled for the organization. AWS recommends that you first use <a>ListRoots</a> to see the status of policy types for a specified root, and then use this operation. </p> <p>This operation can be called only from the organization's master account.</p> <p> To view the status of available policy types in the organization, use <a>DescribeOrganization</a>.</p>
  ##   body: JObject (required)
  var body_602307 = newJObject()
  if body != nil:
    body_602307 = body
  result = call_602306.call(nil, nil, nil, nil, body_602307)

var disablePolicyType* = Call_DisablePolicyType_602293(name: "disablePolicyType",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.DisablePolicyType",
    validator: validate_DisablePolicyType_602294, base: "/",
    url: url_DisablePolicyType_602295, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableAWSServiceAccess_602308 = ref object of OpenApiRestCall_601390
proc url_EnableAWSServiceAccess_602310(protocol: Scheme; host: string; base: string;
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

proc validate_EnableAWSServiceAccess_602309(path: JsonNode; query: JsonNode;
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
  var valid_602311 = header.getOrDefault("X-Amz-Target")
  valid_602311 = validateParameter(valid_602311, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.EnableAWSServiceAccess"))
  if valid_602311 != nil:
    section.add "X-Amz-Target", valid_602311
  var valid_602312 = header.getOrDefault("X-Amz-Signature")
  valid_602312 = validateParameter(valid_602312, JString, required = false,
                                 default = nil)
  if valid_602312 != nil:
    section.add "X-Amz-Signature", valid_602312
  var valid_602313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "X-Amz-Content-Sha256", valid_602313
  var valid_602314 = header.getOrDefault("X-Amz-Date")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-Date", valid_602314
  var valid_602315 = header.getOrDefault("X-Amz-Credential")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-Credential", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-Security-Token")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-Security-Token", valid_602316
  var valid_602317 = header.getOrDefault("X-Amz-Algorithm")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Algorithm", valid_602317
  var valid_602318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602318 = validateParameter(valid_602318, JString, required = false,
                                 default = nil)
  if valid_602318 != nil:
    section.add "X-Amz-SignedHeaders", valid_602318
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602320: Call_EnableAWSServiceAccess_602308; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the integration of an AWS service (the service that is specified by <code>ServicePrincipal</code>) with AWS Organizations. When you enable integration, you allow the specified service to create a <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html">service-linked role</a> in all the accounts in your organization. This allows the service to perform operations on your behalf in your organization and its accounts.</p> <important> <p>We recommend that you enable integration between AWS Organizations and the specified AWS service by using the console or commands that are provided by the specified service. Doing so ensures that the service is aware that it can create the resources that are required for the integration. How the service creates those resources in the organization's accounts depends on that service. For more information, see the documentation for the other AWS service.</p> </important> <p>For more information about enabling services to integrate with AWS Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account and only if the organization has <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">enabled all features</a>.</p>
  ## 
  let valid = call_602320.validator(path, query, header, formData, body)
  let scheme = call_602320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602320.url(scheme.get, call_602320.host, call_602320.base,
                         call_602320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602320, url, valid)

proc call*(call_602321: Call_EnableAWSServiceAccess_602308; body: JsonNode): Recallable =
  ## enableAWSServiceAccess
  ## <p>Enables the integration of an AWS service (the service that is specified by <code>ServicePrincipal</code>) with AWS Organizations. When you enable integration, you allow the specified service to create a <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html">service-linked role</a> in all the accounts in your organization. This allows the service to perform operations on your behalf in your organization and its accounts.</p> <important> <p>We recommend that you enable integration between AWS Organizations and the specified AWS service by using the console or commands that are provided by the specified service. Doing so ensures that the service is aware that it can create the resources that are required for the integration. How the service creates those resources in the organization's accounts depends on that service. For more information, see the documentation for the other AWS service.</p> </important> <p>For more information about enabling services to integrate with AWS Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account and only if the organization has <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">enabled all features</a>.</p>
  ##   body: JObject (required)
  var body_602322 = newJObject()
  if body != nil:
    body_602322 = body
  result = call_602321.call(nil, nil, nil, nil, body_602322)

var enableAWSServiceAccess* = Call_EnableAWSServiceAccess_602308(
    name: "enableAWSServiceAccess", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.EnableAWSServiceAccess",
    validator: validate_EnableAWSServiceAccess_602309, base: "/",
    url: url_EnableAWSServiceAccess_602310, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableAllFeatures_602323 = ref object of OpenApiRestCall_601390
proc url_EnableAllFeatures_602325(protocol: Scheme; host: string; base: string;
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

proc validate_EnableAllFeatures_602324(path: JsonNode; query: JsonNode;
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
  var valid_602326 = header.getOrDefault("X-Amz-Target")
  valid_602326 = validateParameter(valid_602326, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.EnableAllFeatures"))
  if valid_602326 != nil:
    section.add "X-Amz-Target", valid_602326
  var valid_602327 = header.getOrDefault("X-Amz-Signature")
  valid_602327 = validateParameter(valid_602327, JString, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "X-Amz-Signature", valid_602327
  var valid_602328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602328 = validateParameter(valid_602328, JString, required = false,
                                 default = nil)
  if valid_602328 != nil:
    section.add "X-Amz-Content-Sha256", valid_602328
  var valid_602329 = header.getOrDefault("X-Amz-Date")
  valid_602329 = validateParameter(valid_602329, JString, required = false,
                                 default = nil)
  if valid_602329 != nil:
    section.add "X-Amz-Date", valid_602329
  var valid_602330 = header.getOrDefault("X-Amz-Credential")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "X-Amz-Credential", valid_602330
  var valid_602331 = header.getOrDefault("X-Amz-Security-Token")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-Security-Token", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-Algorithm")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Algorithm", valid_602332
  var valid_602333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-SignedHeaders", valid_602333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602335: Call_EnableAllFeatures_602323; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables all features in an organization. This enables the use of organization policies that can restrict the services and actions that can be called in each account. Until you enable all features, you have access only to consolidated billing. You can't use any of the advanced account administration features that AWS Organizations supports. For more information, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">Enabling All Features in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <p>This operation is required only for organizations that were created explicitly with only the consolidated billing features enabled. Calling this operation sends a handshake to every invited account in the organization. The feature set change can be finalized and the additional features enabled only after all administrators in the invited accounts approve the change. Accepting the handshake approves the change.</p> </important> <p>After you enable all features, you can separately enable or disable individual policy types in a root using <a>EnablePolicyType</a> and <a>DisablePolicyType</a>. To see the status of policy types in a root, use <a>ListRoots</a>.</p> <p>After all invited member accounts accept the handshake, you finalize the feature set change by accepting the handshake that contains <code>"Action": "ENABLE_ALL_FEATURES"</code>. This completes the change.</p> <p>After you enable all features in your organization, the master account in the organization can apply policies on all member accounts. These policies can restrict what users and even administrators in those accounts can do. The master account can apply policies that prevent accounts from leaving the organization. Ensure that your account administrators are aware of this.</p> <p>This operation can be called only from the organization's master account. </p>
  ## 
  let valid = call_602335.validator(path, query, header, formData, body)
  let scheme = call_602335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602335.url(scheme.get, call_602335.host, call_602335.base,
                         call_602335.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602335, url, valid)

proc call*(call_602336: Call_EnableAllFeatures_602323; body: JsonNode): Recallable =
  ## enableAllFeatures
  ## <p>Enables all features in an organization. This enables the use of organization policies that can restrict the services and actions that can be called in each account. Until you enable all features, you have access only to consolidated billing. You can't use any of the advanced account administration features that AWS Organizations supports. For more information, see <a href="https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html">Enabling All Features in Your Organization</a> in the <i>AWS Organizations User Guide.</i> </p> <important> <p>This operation is required only for organizations that were created explicitly with only the consolidated billing features enabled. Calling this operation sends a handshake to every invited account in the organization. The feature set change can be finalized and the additional features enabled only after all administrators in the invited accounts approve the change. Accepting the handshake approves the change.</p> </important> <p>After you enable all features, you can separately enable or disable individual policy types in a root using <a>EnablePolicyType</a> and <a>DisablePolicyType</a>. To see the status of policy types in a root, use <a>ListRoots</a>.</p> <p>After all invited member accounts accept the handshake, you finalize the feature set change by accepting the handshake that contains <code>"Action": "ENABLE_ALL_FEATURES"</code>. This completes the change.</p> <p>After you enable all features in your organization, the master account in the organization can apply policies on all member accounts. These policies can restrict what users and even administrators in those accounts can do. The master account can apply policies that prevent accounts from leaving the organization. Ensure that your account administrators are aware of this.</p> <p>This operation can be called only from the organization's master account. </p>
  ##   body: JObject (required)
  var body_602337 = newJObject()
  if body != nil:
    body_602337 = body
  result = call_602336.call(nil, nil, nil, nil, body_602337)

var enableAllFeatures* = Call_EnableAllFeatures_602323(name: "enableAllFeatures",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.EnableAllFeatures",
    validator: validate_EnableAllFeatures_602324, base: "/",
    url: url_EnableAllFeatures_602325, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnablePolicyType_602338 = ref object of OpenApiRestCall_601390
proc url_EnablePolicyType_602340(protocol: Scheme; host: string; base: string;
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

proc validate_EnablePolicyType_602339(path: JsonNode; query: JsonNode;
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
  var valid_602341 = header.getOrDefault("X-Amz-Target")
  valid_602341 = validateParameter(valid_602341, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.EnablePolicyType"))
  if valid_602341 != nil:
    section.add "X-Amz-Target", valid_602341
  var valid_602342 = header.getOrDefault("X-Amz-Signature")
  valid_602342 = validateParameter(valid_602342, JString, required = false,
                                 default = nil)
  if valid_602342 != nil:
    section.add "X-Amz-Signature", valid_602342
  var valid_602343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602343 = validateParameter(valid_602343, JString, required = false,
                                 default = nil)
  if valid_602343 != nil:
    section.add "X-Amz-Content-Sha256", valid_602343
  var valid_602344 = header.getOrDefault("X-Amz-Date")
  valid_602344 = validateParameter(valid_602344, JString, required = false,
                                 default = nil)
  if valid_602344 != nil:
    section.add "X-Amz-Date", valid_602344
  var valid_602345 = header.getOrDefault("X-Amz-Credential")
  valid_602345 = validateParameter(valid_602345, JString, required = false,
                                 default = nil)
  if valid_602345 != nil:
    section.add "X-Amz-Credential", valid_602345
  var valid_602346 = header.getOrDefault("X-Amz-Security-Token")
  valid_602346 = validateParameter(valid_602346, JString, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "X-Amz-Security-Token", valid_602346
  var valid_602347 = header.getOrDefault("X-Amz-Algorithm")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "X-Amz-Algorithm", valid_602347
  var valid_602348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "X-Amz-SignedHeaders", valid_602348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602350: Call_EnablePolicyType_602338; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables a policy type in a root. After you enable a policy type in a root, you can attach policies of that type to the root, any organizational unit (OU), or account in that root. You can undo this by using the <a>DisablePolicyType</a> operation.</p> <p>This is an asynchronous request that AWS performs in the background. AWS recommends that you first use <a>ListRoots</a> to see the status of policy types for a specified root, and then use this operation. </p> <p>This operation can be called only from the organization's master account.</p> <p>You can enable a policy type in a root only if that policy type is available in the organization. To view the status of available policy types in the organization, use <a>DescribeOrganization</a>.</p>
  ## 
  let valid = call_602350.validator(path, query, header, formData, body)
  let scheme = call_602350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602350.url(scheme.get, call_602350.host, call_602350.base,
                         call_602350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602350, url, valid)

proc call*(call_602351: Call_EnablePolicyType_602338; body: JsonNode): Recallable =
  ## enablePolicyType
  ## <p>Enables a policy type in a root. After you enable a policy type in a root, you can attach policies of that type to the root, any organizational unit (OU), or account in that root. You can undo this by using the <a>DisablePolicyType</a> operation.</p> <p>This is an asynchronous request that AWS performs in the background. AWS recommends that you first use <a>ListRoots</a> to see the status of policy types for a specified root, and then use this operation. </p> <p>This operation can be called only from the organization's master account.</p> <p>You can enable a policy type in a root only if that policy type is available in the organization. To view the status of available policy types in the organization, use <a>DescribeOrganization</a>.</p>
  ##   body: JObject (required)
  var body_602352 = newJObject()
  if body != nil:
    body_602352 = body
  result = call_602351.call(nil, nil, nil, nil, body_602352)

var enablePolicyType* = Call_EnablePolicyType_602338(name: "enablePolicyType",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.EnablePolicyType",
    validator: validate_EnablePolicyType_602339, base: "/",
    url: url_EnablePolicyType_602340, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteAccountToOrganization_602353 = ref object of OpenApiRestCall_601390
proc url_InviteAccountToOrganization_602355(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_InviteAccountToOrganization_602354(path: JsonNode; query: JsonNode;
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
  var valid_602356 = header.getOrDefault("X-Amz-Target")
  valid_602356 = validateParameter(valid_602356, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.InviteAccountToOrganization"))
  if valid_602356 != nil:
    section.add "X-Amz-Target", valid_602356
  var valid_602357 = header.getOrDefault("X-Amz-Signature")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "X-Amz-Signature", valid_602357
  var valid_602358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602358 = validateParameter(valid_602358, JString, required = false,
                                 default = nil)
  if valid_602358 != nil:
    section.add "X-Amz-Content-Sha256", valid_602358
  var valid_602359 = header.getOrDefault("X-Amz-Date")
  valid_602359 = validateParameter(valid_602359, JString, required = false,
                                 default = nil)
  if valid_602359 != nil:
    section.add "X-Amz-Date", valid_602359
  var valid_602360 = header.getOrDefault("X-Amz-Credential")
  valid_602360 = validateParameter(valid_602360, JString, required = false,
                                 default = nil)
  if valid_602360 != nil:
    section.add "X-Amz-Credential", valid_602360
  var valid_602361 = header.getOrDefault("X-Amz-Security-Token")
  valid_602361 = validateParameter(valid_602361, JString, required = false,
                                 default = nil)
  if valid_602361 != nil:
    section.add "X-Amz-Security-Token", valid_602361
  var valid_602362 = header.getOrDefault("X-Amz-Algorithm")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "X-Amz-Algorithm", valid_602362
  var valid_602363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602363 = validateParameter(valid_602363, JString, required = false,
                                 default = nil)
  if valid_602363 != nil:
    section.add "X-Amz-SignedHeaders", valid_602363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602365: Call_InviteAccountToOrganization_602353; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends an invitation to another account to join your organization as a member account. AWS Organizations sends email on your behalf to the email address that is associated with the other account's owner. The invitation is implemented as a <a>Handshake</a> whose details are in the response.</p> <important> <ul> <li> <p>You can invite AWS accounts only from the same seller as the master account. For example, assume that your organization's master account was created by Amazon Internet Services Pvt. Ltd (AISPL), an AWS seller in India. You can invite only other AISPL accounts to your organization. You can't combine accounts from AISPL and AWS or from any other AWS seller. For more information, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/useconsolidatedbilliing-India.html">Consolidated Billing in India</a>.</p> </li> <li> <p>You might receive an exception that indicates that you exceeded your account limits for the organization or that the operation failed because your organization is still initializing. If so, wait one hour and then try again. If the error persists after an hour, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> </ul> </important> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_602365.validator(path, query, header, formData, body)
  let scheme = call_602365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602365.url(scheme.get, call_602365.host, call_602365.base,
                         call_602365.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602365, url, valid)

proc call*(call_602366: Call_InviteAccountToOrganization_602353; body: JsonNode): Recallable =
  ## inviteAccountToOrganization
  ## <p>Sends an invitation to another account to join your organization as a member account. AWS Organizations sends email on your behalf to the email address that is associated with the other account's owner. The invitation is implemented as a <a>Handshake</a> whose details are in the response.</p> <important> <ul> <li> <p>You can invite AWS accounts only from the same seller as the master account. For example, assume that your organization's master account was created by Amazon Internet Services Pvt. Ltd (AISPL), an AWS seller in India. You can invite only other AISPL accounts to your organization. You can't combine accounts from AISPL and AWS or from any other AWS seller. For more information, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/useconsolidatedbilliing-India.html">Consolidated Billing in India</a>.</p> </li> <li> <p>You might receive an exception that indicates that you exceeded your account limits for the organization or that the operation failed because your organization is still initializing. If so, wait one hour and then try again. If the error persists after an hour, contact <a href="https://console.aws.amazon.com/support/home#/">AWS Support</a>.</p> </li> </ul> </important> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_602367 = newJObject()
  if body != nil:
    body_602367 = body
  result = call_602366.call(nil, nil, nil, nil, body_602367)

var inviteAccountToOrganization* = Call_InviteAccountToOrganization_602353(
    name: "inviteAccountToOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.InviteAccountToOrganization",
    validator: validate_InviteAccountToOrganization_602354, base: "/",
    url: url_InviteAccountToOrganization_602355,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_LeaveOrganization_602368 = ref object of OpenApiRestCall_601390
proc url_LeaveOrganization_602370(protocol: Scheme; host: string; base: string;
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

proc validate_LeaveOrganization_602369(path: JsonNode; query: JsonNode;
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
  var valid_602371 = header.getOrDefault("X-Amz-Target")
  valid_602371 = validateParameter(valid_602371, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.LeaveOrganization"))
  if valid_602371 != nil:
    section.add "X-Amz-Target", valid_602371
  var valid_602372 = header.getOrDefault("X-Amz-Signature")
  valid_602372 = validateParameter(valid_602372, JString, required = false,
                                 default = nil)
  if valid_602372 != nil:
    section.add "X-Amz-Signature", valid_602372
  var valid_602373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602373 = validateParameter(valid_602373, JString, required = false,
                                 default = nil)
  if valid_602373 != nil:
    section.add "X-Amz-Content-Sha256", valid_602373
  var valid_602374 = header.getOrDefault("X-Amz-Date")
  valid_602374 = validateParameter(valid_602374, JString, required = false,
                                 default = nil)
  if valid_602374 != nil:
    section.add "X-Amz-Date", valid_602374
  var valid_602375 = header.getOrDefault("X-Amz-Credential")
  valid_602375 = validateParameter(valid_602375, JString, required = false,
                                 default = nil)
  if valid_602375 != nil:
    section.add "X-Amz-Credential", valid_602375
  var valid_602376 = header.getOrDefault("X-Amz-Security-Token")
  valid_602376 = validateParameter(valid_602376, JString, required = false,
                                 default = nil)
  if valid_602376 != nil:
    section.add "X-Amz-Security-Token", valid_602376
  var valid_602377 = header.getOrDefault("X-Amz-Algorithm")
  valid_602377 = validateParameter(valid_602377, JString, required = false,
                                 default = nil)
  if valid_602377 != nil:
    section.add "X-Amz-Algorithm", valid_602377
  var valid_602378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602378 = validateParameter(valid_602378, JString, required = false,
                                 default = nil)
  if valid_602378 != nil:
    section.add "X-Amz-SignedHeaders", valid_602378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602379: Call_LeaveOrganization_602368; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a member account from its parent organization. This version of the operation is performed by the account that wants to leave. To remove a member account as a user in the master account, use <a>RemoveAccountFromOrganization</a> instead.</p> <p>This operation can be called only from a member account in the organization.</p> <important> <ul> <li> <p>The master account in an organization with all features enabled can set service control policies (SCPs) that can restrict what administrators of member accounts can do. These restrictions can include preventing member accounts from successfully calling <code>LeaveOrganization</code>. </p> </li> <li> <p>You can leave an organization as a member account only if the account is configured with the information required to operate as a standalone account. When you create an account in an organization using the AWS Organizations console, API, or CLI, the information required of standalone accounts is <i>not</i> automatically collected. For each account that you want to make standalone, you must accept the end user license agreement (EULA). You must also choose a support plan, provide and verify the required contact information, and provide a current payment method. AWS uses the payment method to charge for any billable (not free tier) AWS activity that occurs while the account isn't attached to an organization. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization when all required account information has not yet been provided</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>You can leave an organization only after you enable IAM user access to billing in your account. For more information, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html#ControllingAccessWebsite-Activate">Activating Access to the Billing and Cost Management Console</a> in the <i>AWS Billing and Cost Management User Guide.</i> </p> </li> </ul> </important>
  ## 
  let valid = call_602379.validator(path, query, header, formData, body)
  let scheme = call_602379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602379.url(scheme.get, call_602379.host, call_602379.base,
                         call_602379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602379, url, valid)

proc call*(call_602380: Call_LeaveOrganization_602368): Recallable =
  ## leaveOrganization
  ## <p>Removes a member account from its parent organization. This version of the operation is performed by the account that wants to leave. To remove a member account as a user in the master account, use <a>RemoveAccountFromOrganization</a> instead.</p> <p>This operation can be called only from a member account in the organization.</p> <important> <ul> <li> <p>The master account in an organization with all features enabled can set service control policies (SCPs) that can restrict what administrators of member accounts can do. These restrictions can include preventing member accounts from successfully calling <code>LeaveOrganization</code>. </p> </li> <li> <p>You can leave an organization as a member account only if the account is configured with the information required to operate as a standalone account. When you create an account in an organization using the AWS Organizations console, API, or CLI, the information required of standalone accounts is <i>not</i> automatically collected. For each account that you want to make standalone, you must accept the end user license agreement (EULA). You must also choose a support plan, provide and verify the required contact information, and provide a current payment method. AWS uses the payment method to charge for any billable (not free tier) AWS activity that occurs while the account isn't attached to an organization. Follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization when all required account information has not yet been provided</a> in the <i>AWS Organizations User Guide.</i> </p> </li> <li> <p>You can leave an organization only after you enable IAM user access to billing in your account. For more information, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html#ControllingAccessWebsite-Activate">Activating Access to the Billing and Cost Management Console</a> in the <i>AWS Billing and Cost Management User Guide.</i> </p> </li> </ul> </important>
  result = call_602380.call(nil, nil, nil, nil, nil)

var leaveOrganization* = Call_LeaveOrganization_602368(name: "leaveOrganization",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.LeaveOrganization",
    validator: validate_LeaveOrganization_602369, base: "/",
    url: url_LeaveOrganization_602370, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAWSServiceAccessForOrganization_602381 = ref object of OpenApiRestCall_601390
proc url_ListAWSServiceAccessForOrganization_602383(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAWSServiceAccessForOrganization_602382(path: JsonNode;
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
  var valid_602384 = query.getOrDefault("MaxResults")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "MaxResults", valid_602384
  var valid_602385 = query.getOrDefault("NextToken")
  valid_602385 = validateParameter(valid_602385, JString, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "NextToken", valid_602385
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
  var valid_602386 = header.getOrDefault("X-Amz-Target")
  valid_602386 = validateParameter(valid_602386, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListAWSServiceAccessForOrganization"))
  if valid_602386 != nil:
    section.add "X-Amz-Target", valid_602386
  var valid_602387 = header.getOrDefault("X-Amz-Signature")
  valid_602387 = validateParameter(valid_602387, JString, required = false,
                                 default = nil)
  if valid_602387 != nil:
    section.add "X-Amz-Signature", valid_602387
  var valid_602388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602388 = validateParameter(valid_602388, JString, required = false,
                                 default = nil)
  if valid_602388 != nil:
    section.add "X-Amz-Content-Sha256", valid_602388
  var valid_602389 = header.getOrDefault("X-Amz-Date")
  valid_602389 = validateParameter(valid_602389, JString, required = false,
                                 default = nil)
  if valid_602389 != nil:
    section.add "X-Amz-Date", valid_602389
  var valid_602390 = header.getOrDefault("X-Amz-Credential")
  valid_602390 = validateParameter(valid_602390, JString, required = false,
                                 default = nil)
  if valid_602390 != nil:
    section.add "X-Amz-Credential", valid_602390
  var valid_602391 = header.getOrDefault("X-Amz-Security-Token")
  valid_602391 = validateParameter(valid_602391, JString, required = false,
                                 default = nil)
  if valid_602391 != nil:
    section.add "X-Amz-Security-Token", valid_602391
  var valid_602392 = header.getOrDefault("X-Amz-Algorithm")
  valid_602392 = validateParameter(valid_602392, JString, required = false,
                                 default = nil)
  if valid_602392 != nil:
    section.add "X-Amz-Algorithm", valid_602392
  var valid_602393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602393 = validateParameter(valid_602393, JString, required = false,
                                 default = nil)
  if valid_602393 != nil:
    section.add "X-Amz-SignedHeaders", valid_602393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602395: Call_ListAWSServiceAccessForOrganization_602381;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of the AWS services that you enabled to integrate with your organization. After a service on this list creates the resources that it requires for the integration, it can perform operations on your organization and its accounts.</p> <p>For more information about integrating other services with AWS Organizations, including the list of services that currently work with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_602395.validator(path, query, header, formData, body)
  let scheme = call_602395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602395.url(scheme.get, call_602395.host, call_602395.base,
                         call_602395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602395, url, valid)

proc call*(call_602396: Call_ListAWSServiceAccessForOrganization_602381;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAWSServiceAccessForOrganization
  ## <p>Returns a list of the AWS services that you enabled to integrate with your organization. After a service on this list creates the resources that it requires for the integration, it can perform operations on your organization and its accounts.</p> <p>For more information about integrating other services with AWS Organizations, including the list of services that currently work with Organizations, see <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html">Integrating AWS Organizations with Other AWS Services</a> in the <i>AWS Organizations User Guide.</i> </p> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602397 = newJObject()
  var body_602398 = newJObject()
  add(query_602397, "MaxResults", newJString(MaxResults))
  add(query_602397, "NextToken", newJString(NextToken))
  if body != nil:
    body_602398 = body
  result = call_602396.call(nil, query_602397, nil, nil, body_602398)

var listAWSServiceAccessForOrganization* = Call_ListAWSServiceAccessForOrganization_602381(
    name: "listAWSServiceAccessForOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListAWSServiceAccessForOrganization",
    validator: validate_ListAWSServiceAccessForOrganization_602382, base: "/",
    url: url_ListAWSServiceAccessForOrganization_602383,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccounts_602400 = ref object of OpenApiRestCall_601390
proc url_ListAccounts_602402(protocol: Scheme; host: string; base: string;
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

proc validate_ListAccounts_602401(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602403 = query.getOrDefault("MaxResults")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "MaxResults", valid_602403
  var valid_602404 = query.getOrDefault("NextToken")
  valid_602404 = validateParameter(valid_602404, JString, required = false,
                                 default = nil)
  if valid_602404 != nil:
    section.add "NextToken", valid_602404
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
  var valid_602405 = header.getOrDefault("X-Amz-Target")
  valid_602405 = validateParameter(valid_602405, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListAccounts"))
  if valid_602405 != nil:
    section.add "X-Amz-Target", valid_602405
  var valid_602406 = header.getOrDefault("X-Amz-Signature")
  valid_602406 = validateParameter(valid_602406, JString, required = false,
                                 default = nil)
  if valid_602406 != nil:
    section.add "X-Amz-Signature", valid_602406
  var valid_602407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602407 = validateParameter(valid_602407, JString, required = false,
                                 default = nil)
  if valid_602407 != nil:
    section.add "X-Amz-Content-Sha256", valid_602407
  var valid_602408 = header.getOrDefault("X-Amz-Date")
  valid_602408 = validateParameter(valid_602408, JString, required = false,
                                 default = nil)
  if valid_602408 != nil:
    section.add "X-Amz-Date", valid_602408
  var valid_602409 = header.getOrDefault("X-Amz-Credential")
  valid_602409 = validateParameter(valid_602409, JString, required = false,
                                 default = nil)
  if valid_602409 != nil:
    section.add "X-Amz-Credential", valid_602409
  var valid_602410 = header.getOrDefault("X-Amz-Security-Token")
  valid_602410 = validateParameter(valid_602410, JString, required = false,
                                 default = nil)
  if valid_602410 != nil:
    section.add "X-Amz-Security-Token", valid_602410
  var valid_602411 = header.getOrDefault("X-Amz-Algorithm")
  valid_602411 = validateParameter(valid_602411, JString, required = false,
                                 default = nil)
  if valid_602411 != nil:
    section.add "X-Amz-Algorithm", valid_602411
  var valid_602412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602412 = validateParameter(valid_602412, JString, required = false,
                                 default = nil)
  if valid_602412 != nil:
    section.add "X-Amz-SignedHeaders", valid_602412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602414: Call_ListAccounts_602400; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all the accounts in the organization. To request only the accounts in a specified root or organizational unit (OU), use the <a>ListAccountsForParent</a> operation instead.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_602414.validator(path, query, header, formData, body)
  let scheme = call_602414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602414.url(scheme.get, call_602414.host, call_602414.base,
                         call_602414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602414, url, valid)

proc call*(call_602415: Call_ListAccounts_602400; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAccounts
  ## <p>Lists all the accounts in the organization. To request only the accounts in a specified root or organizational unit (OU), use the <a>ListAccountsForParent</a> operation instead.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602416 = newJObject()
  var body_602417 = newJObject()
  add(query_602416, "MaxResults", newJString(MaxResults))
  add(query_602416, "NextToken", newJString(NextToken))
  if body != nil:
    body_602417 = body
  result = call_602415.call(nil, query_602416, nil, nil, body_602417)

var listAccounts* = Call_ListAccounts_602400(name: "listAccounts",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListAccounts",
    validator: validate_ListAccounts_602401, base: "/", url: url_ListAccounts_602402,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccountsForParent_602418 = ref object of OpenApiRestCall_601390
proc url_ListAccountsForParent_602420(protocol: Scheme; host: string; base: string;
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

proc validate_ListAccountsForParent_602419(path: JsonNode; query: JsonNode;
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
  var valid_602421 = query.getOrDefault("MaxResults")
  valid_602421 = validateParameter(valid_602421, JString, required = false,
                                 default = nil)
  if valid_602421 != nil:
    section.add "MaxResults", valid_602421
  var valid_602422 = query.getOrDefault("NextToken")
  valid_602422 = validateParameter(valid_602422, JString, required = false,
                                 default = nil)
  if valid_602422 != nil:
    section.add "NextToken", valid_602422
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
  var valid_602423 = header.getOrDefault("X-Amz-Target")
  valid_602423 = validateParameter(valid_602423, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListAccountsForParent"))
  if valid_602423 != nil:
    section.add "X-Amz-Target", valid_602423
  var valid_602424 = header.getOrDefault("X-Amz-Signature")
  valid_602424 = validateParameter(valid_602424, JString, required = false,
                                 default = nil)
  if valid_602424 != nil:
    section.add "X-Amz-Signature", valid_602424
  var valid_602425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602425 = validateParameter(valid_602425, JString, required = false,
                                 default = nil)
  if valid_602425 != nil:
    section.add "X-Amz-Content-Sha256", valid_602425
  var valid_602426 = header.getOrDefault("X-Amz-Date")
  valid_602426 = validateParameter(valid_602426, JString, required = false,
                                 default = nil)
  if valid_602426 != nil:
    section.add "X-Amz-Date", valid_602426
  var valid_602427 = header.getOrDefault("X-Amz-Credential")
  valid_602427 = validateParameter(valid_602427, JString, required = false,
                                 default = nil)
  if valid_602427 != nil:
    section.add "X-Amz-Credential", valid_602427
  var valid_602428 = header.getOrDefault("X-Amz-Security-Token")
  valid_602428 = validateParameter(valid_602428, JString, required = false,
                                 default = nil)
  if valid_602428 != nil:
    section.add "X-Amz-Security-Token", valid_602428
  var valid_602429 = header.getOrDefault("X-Amz-Algorithm")
  valid_602429 = validateParameter(valid_602429, JString, required = false,
                                 default = nil)
  if valid_602429 != nil:
    section.add "X-Amz-Algorithm", valid_602429
  var valid_602430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602430 = validateParameter(valid_602430, JString, required = false,
                                 default = nil)
  if valid_602430 != nil:
    section.add "X-Amz-SignedHeaders", valid_602430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602432: Call_ListAccountsForParent_602418; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the accounts in an organization that are contained by the specified target root or organizational unit (OU). If you specify the root, you get a list of all the accounts that aren't in any OU. If you specify an OU, you get a list of all the accounts in only that OU and not in any child OUs. To get a list of all accounts in the organization, use the <a>ListAccounts</a> operation.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_602432.validator(path, query, header, formData, body)
  let scheme = call_602432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602432.url(scheme.get, call_602432.host, call_602432.base,
                         call_602432.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602432, url, valid)

proc call*(call_602433: Call_ListAccountsForParent_602418; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAccountsForParent
  ## <p>Lists the accounts in an organization that are contained by the specified target root or organizational unit (OU). If you specify the root, you get a list of all the accounts that aren't in any OU. If you specify an OU, you get a list of all the accounts in only that OU and not in any child OUs. To get a list of all accounts in the organization, use the <a>ListAccounts</a> operation.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602434 = newJObject()
  var body_602435 = newJObject()
  add(query_602434, "MaxResults", newJString(MaxResults))
  add(query_602434, "NextToken", newJString(NextToken))
  if body != nil:
    body_602435 = body
  result = call_602433.call(nil, query_602434, nil, nil, body_602435)

var listAccountsForParent* = Call_ListAccountsForParent_602418(
    name: "listAccountsForParent", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListAccountsForParent",
    validator: validate_ListAccountsForParent_602419, base: "/",
    url: url_ListAccountsForParent_602420, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChildren_602436 = ref object of OpenApiRestCall_601390
proc url_ListChildren_602438(protocol: Scheme; host: string; base: string;
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

proc validate_ListChildren_602437(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602439 = query.getOrDefault("MaxResults")
  valid_602439 = validateParameter(valid_602439, JString, required = false,
                                 default = nil)
  if valid_602439 != nil:
    section.add "MaxResults", valid_602439
  var valid_602440 = query.getOrDefault("NextToken")
  valid_602440 = validateParameter(valid_602440, JString, required = false,
                                 default = nil)
  if valid_602440 != nil:
    section.add "NextToken", valid_602440
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
  var valid_602441 = header.getOrDefault("X-Amz-Target")
  valid_602441 = validateParameter(valid_602441, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListChildren"))
  if valid_602441 != nil:
    section.add "X-Amz-Target", valid_602441
  var valid_602442 = header.getOrDefault("X-Amz-Signature")
  valid_602442 = validateParameter(valid_602442, JString, required = false,
                                 default = nil)
  if valid_602442 != nil:
    section.add "X-Amz-Signature", valid_602442
  var valid_602443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602443 = validateParameter(valid_602443, JString, required = false,
                                 default = nil)
  if valid_602443 != nil:
    section.add "X-Amz-Content-Sha256", valid_602443
  var valid_602444 = header.getOrDefault("X-Amz-Date")
  valid_602444 = validateParameter(valid_602444, JString, required = false,
                                 default = nil)
  if valid_602444 != nil:
    section.add "X-Amz-Date", valid_602444
  var valid_602445 = header.getOrDefault("X-Amz-Credential")
  valid_602445 = validateParameter(valid_602445, JString, required = false,
                                 default = nil)
  if valid_602445 != nil:
    section.add "X-Amz-Credential", valid_602445
  var valid_602446 = header.getOrDefault("X-Amz-Security-Token")
  valid_602446 = validateParameter(valid_602446, JString, required = false,
                                 default = nil)
  if valid_602446 != nil:
    section.add "X-Amz-Security-Token", valid_602446
  var valid_602447 = header.getOrDefault("X-Amz-Algorithm")
  valid_602447 = validateParameter(valid_602447, JString, required = false,
                                 default = nil)
  if valid_602447 != nil:
    section.add "X-Amz-Algorithm", valid_602447
  var valid_602448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602448 = validateParameter(valid_602448, JString, required = false,
                                 default = nil)
  if valid_602448 != nil:
    section.add "X-Amz-SignedHeaders", valid_602448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602450: Call_ListChildren_602436; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all of the organizational units (OUs) or accounts that are contained in the specified parent OU or root. This operation, along with <a>ListParents</a> enables you to traverse the tree structure that makes up this root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_602450.validator(path, query, header, formData, body)
  let scheme = call_602450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602450.url(scheme.get, call_602450.host, call_602450.base,
                         call_602450.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602450, url, valid)

proc call*(call_602451: Call_ListChildren_602436; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listChildren
  ## <p>Lists all of the organizational units (OUs) or accounts that are contained in the specified parent OU or root. This operation, along with <a>ListParents</a> enables you to traverse the tree structure that makes up this root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602452 = newJObject()
  var body_602453 = newJObject()
  add(query_602452, "MaxResults", newJString(MaxResults))
  add(query_602452, "NextToken", newJString(NextToken))
  if body != nil:
    body_602453 = body
  result = call_602451.call(nil, query_602452, nil, nil, body_602453)

var listChildren* = Call_ListChildren_602436(name: "listChildren",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListChildren",
    validator: validate_ListChildren_602437, base: "/", url: url_ListChildren_602438,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCreateAccountStatus_602454 = ref object of OpenApiRestCall_601390
proc url_ListCreateAccountStatus_602456(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCreateAccountStatus_602455(path: JsonNode; query: JsonNode;
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
  var valid_602457 = query.getOrDefault("MaxResults")
  valid_602457 = validateParameter(valid_602457, JString, required = false,
                                 default = nil)
  if valid_602457 != nil:
    section.add "MaxResults", valid_602457
  var valid_602458 = query.getOrDefault("NextToken")
  valid_602458 = validateParameter(valid_602458, JString, required = false,
                                 default = nil)
  if valid_602458 != nil:
    section.add "NextToken", valid_602458
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
  var valid_602459 = header.getOrDefault("X-Amz-Target")
  valid_602459 = validateParameter(valid_602459, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListCreateAccountStatus"))
  if valid_602459 != nil:
    section.add "X-Amz-Target", valid_602459
  var valid_602460 = header.getOrDefault("X-Amz-Signature")
  valid_602460 = validateParameter(valid_602460, JString, required = false,
                                 default = nil)
  if valid_602460 != nil:
    section.add "X-Amz-Signature", valid_602460
  var valid_602461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602461 = validateParameter(valid_602461, JString, required = false,
                                 default = nil)
  if valid_602461 != nil:
    section.add "X-Amz-Content-Sha256", valid_602461
  var valid_602462 = header.getOrDefault("X-Amz-Date")
  valid_602462 = validateParameter(valid_602462, JString, required = false,
                                 default = nil)
  if valid_602462 != nil:
    section.add "X-Amz-Date", valid_602462
  var valid_602463 = header.getOrDefault("X-Amz-Credential")
  valid_602463 = validateParameter(valid_602463, JString, required = false,
                                 default = nil)
  if valid_602463 != nil:
    section.add "X-Amz-Credential", valid_602463
  var valid_602464 = header.getOrDefault("X-Amz-Security-Token")
  valid_602464 = validateParameter(valid_602464, JString, required = false,
                                 default = nil)
  if valid_602464 != nil:
    section.add "X-Amz-Security-Token", valid_602464
  var valid_602465 = header.getOrDefault("X-Amz-Algorithm")
  valid_602465 = validateParameter(valid_602465, JString, required = false,
                                 default = nil)
  if valid_602465 != nil:
    section.add "X-Amz-Algorithm", valid_602465
  var valid_602466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602466 = validateParameter(valid_602466, JString, required = false,
                                 default = nil)
  if valid_602466 != nil:
    section.add "X-Amz-SignedHeaders", valid_602466
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602468: Call_ListCreateAccountStatus_602454; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the account creation requests that match the specified status that is currently being tracked for the organization.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_602468.validator(path, query, header, formData, body)
  let scheme = call_602468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602468.url(scheme.get, call_602468.host, call_602468.base,
                         call_602468.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602468, url, valid)

proc call*(call_602469: Call_ListCreateAccountStatus_602454; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCreateAccountStatus
  ## <p>Lists the account creation requests that match the specified status that is currently being tracked for the organization.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602470 = newJObject()
  var body_602471 = newJObject()
  add(query_602470, "MaxResults", newJString(MaxResults))
  add(query_602470, "NextToken", newJString(NextToken))
  if body != nil:
    body_602471 = body
  result = call_602469.call(nil, query_602470, nil, nil, body_602471)

var listCreateAccountStatus* = Call_ListCreateAccountStatus_602454(
    name: "listCreateAccountStatus", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListCreateAccountStatus",
    validator: validate_ListCreateAccountStatus_602455, base: "/",
    url: url_ListCreateAccountStatus_602456, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHandshakesForAccount_602472 = ref object of OpenApiRestCall_601390
proc url_ListHandshakesForAccount_602474(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListHandshakesForAccount_602473(path: JsonNode; query: JsonNode;
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
  var valid_602475 = query.getOrDefault("MaxResults")
  valid_602475 = validateParameter(valid_602475, JString, required = false,
                                 default = nil)
  if valid_602475 != nil:
    section.add "MaxResults", valid_602475
  var valid_602476 = query.getOrDefault("NextToken")
  valid_602476 = validateParameter(valid_602476, JString, required = false,
                                 default = nil)
  if valid_602476 != nil:
    section.add "NextToken", valid_602476
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
  var valid_602477 = header.getOrDefault("X-Amz-Target")
  valid_602477 = validateParameter(valid_602477, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListHandshakesForAccount"))
  if valid_602477 != nil:
    section.add "X-Amz-Target", valid_602477
  var valid_602478 = header.getOrDefault("X-Amz-Signature")
  valid_602478 = validateParameter(valid_602478, JString, required = false,
                                 default = nil)
  if valid_602478 != nil:
    section.add "X-Amz-Signature", valid_602478
  var valid_602479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602479 = validateParameter(valid_602479, JString, required = false,
                                 default = nil)
  if valid_602479 != nil:
    section.add "X-Amz-Content-Sha256", valid_602479
  var valid_602480 = header.getOrDefault("X-Amz-Date")
  valid_602480 = validateParameter(valid_602480, JString, required = false,
                                 default = nil)
  if valid_602480 != nil:
    section.add "X-Amz-Date", valid_602480
  var valid_602481 = header.getOrDefault("X-Amz-Credential")
  valid_602481 = validateParameter(valid_602481, JString, required = false,
                                 default = nil)
  if valid_602481 != nil:
    section.add "X-Amz-Credential", valid_602481
  var valid_602482 = header.getOrDefault("X-Amz-Security-Token")
  valid_602482 = validateParameter(valid_602482, JString, required = false,
                                 default = nil)
  if valid_602482 != nil:
    section.add "X-Amz-Security-Token", valid_602482
  var valid_602483 = header.getOrDefault("X-Amz-Algorithm")
  valid_602483 = validateParameter(valid_602483, JString, required = false,
                                 default = nil)
  if valid_602483 != nil:
    section.add "X-Amz-Algorithm", valid_602483
  var valid_602484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602484 = validateParameter(valid_602484, JString, required = false,
                                 default = nil)
  if valid_602484 != nil:
    section.add "X-Amz-SignedHeaders", valid_602484
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602486: Call_ListHandshakesForAccount_602472; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the current handshakes that are associated with the account of the requesting user.</p> <p>Handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> appear in the results of this API for only 30 days after changing to that state. After that, they're deleted and no longer accessible.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called from any account in the organization.</p>
  ## 
  let valid = call_602486.validator(path, query, header, formData, body)
  let scheme = call_602486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602486.url(scheme.get, call_602486.host, call_602486.base,
                         call_602486.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602486, url, valid)

proc call*(call_602487: Call_ListHandshakesForAccount_602472; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listHandshakesForAccount
  ## <p>Lists the current handshakes that are associated with the account of the requesting user.</p> <p>Handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> appear in the results of this API for only 30 days after changing to that state. After that, they're deleted and no longer accessible.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called from any account in the organization.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602488 = newJObject()
  var body_602489 = newJObject()
  add(query_602488, "MaxResults", newJString(MaxResults))
  add(query_602488, "NextToken", newJString(NextToken))
  if body != nil:
    body_602489 = body
  result = call_602487.call(nil, query_602488, nil, nil, body_602489)

var listHandshakesForAccount* = Call_ListHandshakesForAccount_602472(
    name: "listHandshakesForAccount", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListHandshakesForAccount",
    validator: validate_ListHandshakesForAccount_602473, base: "/",
    url: url_ListHandshakesForAccount_602474, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHandshakesForOrganization_602490 = ref object of OpenApiRestCall_601390
proc url_ListHandshakesForOrganization_602492(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListHandshakesForOrganization_602491(path: JsonNode; query: JsonNode;
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
  var valid_602493 = query.getOrDefault("MaxResults")
  valid_602493 = validateParameter(valid_602493, JString, required = false,
                                 default = nil)
  if valid_602493 != nil:
    section.add "MaxResults", valid_602493
  var valid_602494 = query.getOrDefault("NextToken")
  valid_602494 = validateParameter(valid_602494, JString, required = false,
                                 default = nil)
  if valid_602494 != nil:
    section.add "NextToken", valid_602494
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
  var valid_602495 = header.getOrDefault("X-Amz-Target")
  valid_602495 = validateParameter(valid_602495, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListHandshakesForOrganization"))
  if valid_602495 != nil:
    section.add "X-Amz-Target", valid_602495
  var valid_602496 = header.getOrDefault("X-Amz-Signature")
  valid_602496 = validateParameter(valid_602496, JString, required = false,
                                 default = nil)
  if valid_602496 != nil:
    section.add "X-Amz-Signature", valid_602496
  var valid_602497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602497 = validateParameter(valid_602497, JString, required = false,
                                 default = nil)
  if valid_602497 != nil:
    section.add "X-Amz-Content-Sha256", valid_602497
  var valid_602498 = header.getOrDefault("X-Amz-Date")
  valid_602498 = validateParameter(valid_602498, JString, required = false,
                                 default = nil)
  if valid_602498 != nil:
    section.add "X-Amz-Date", valid_602498
  var valid_602499 = header.getOrDefault("X-Amz-Credential")
  valid_602499 = validateParameter(valid_602499, JString, required = false,
                                 default = nil)
  if valid_602499 != nil:
    section.add "X-Amz-Credential", valid_602499
  var valid_602500 = header.getOrDefault("X-Amz-Security-Token")
  valid_602500 = validateParameter(valid_602500, JString, required = false,
                                 default = nil)
  if valid_602500 != nil:
    section.add "X-Amz-Security-Token", valid_602500
  var valid_602501 = header.getOrDefault("X-Amz-Algorithm")
  valid_602501 = validateParameter(valid_602501, JString, required = false,
                                 default = nil)
  if valid_602501 != nil:
    section.add "X-Amz-Algorithm", valid_602501
  var valid_602502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602502 = validateParameter(valid_602502, JString, required = false,
                                 default = nil)
  if valid_602502 != nil:
    section.add "X-Amz-SignedHeaders", valid_602502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602504: Call_ListHandshakesForOrganization_602490; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the handshakes that are associated with the organization that the requesting user is part of. The <code>ListHandshakesForOrganization</code> operation returns a list of handshake structures. Each structure contains details and status about a handshake.</p> <p>Handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> appear in the results of this API for only 30 days after changing to that state. After that, they're deleted and no longer accessible.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_602504.validator(path, query, header, formData, body)
  let scheme = call_602504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602504.url(scheme.get, call_602504.host, call_602504.base,
                         call_602504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602504, url, valid)

proc call*(call_602505: Call_ListHandshakesForOrganization_602490; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listHandshakesForOrganization
  ## <p>Lists the handshakes that are associated with the organization that the requesting user is part of. The <code>ListHandshakesForOrganization</code> operation returns a list of handshake structures. Each structure contains details and status about a handshake.</p> <p>Handshakes that are <code>ACCEPTED</code>, <code>DECLINED</code>, or <code>CANCELED</code> appear in the results of this API for only 30 days after changing to that state. After that, they're deleted and no longer accessible.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602506 = newJObject()
  var body_602507 = newJObject()
  add(query_602506, "MaxResults", newJString(MaxResults))
  add(query_602506, "NextToken", newJString(NextToken))
  if body != nil:
    body_602507 = body
  result = call_602505.call(nil, query_602506, nil, nil, body_602507)

var listHandshakesForOrganization* = Call_ListHandshakesForOrganization_602490(
    name: "listHandshakesForOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListHandshakesForOrganization",
    validator: validate_ListHandshakesForOrganization_602491, base: "/",
    url: url_ListHandshakesForOrganization_602492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOrganizationalUnitsForParent_602508 = ref object of OpenApiRestCall_601390
proc url_ListOrganizationalUnitsForParent_602510(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOrganizationalUnitsForParent_602509(path: JsonNode;
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
  var valid_602511 = query.getOrDefault("MaxResults")
  valid_602511 = validateParameter(valid_602511, JString, required = false,
                                 default = nil)
  if valid_602511 != nil:
    section.add "MaxResults", valid_602511
  var valid_602512 = query.getOrDefault("NextToken")
  valid_602512 = validateParameter(valid_602512, JString, required = false,
                                 default = nil)
  if valid_602512 != nil:
    section.add "NextToken", valid_602512
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
  var valid_602513 = header.getOrDefault("X-Amz-Target")
  valid_602513 = validateParameter(valid_602513, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListOrganizationalUnitsForParent"))
  if valid_602513 != nil:
    section.add "X-Amz-Target", valid_602513
  var valid_602514 = header.getOrDefault("X-Amz-Signature")
  valid_602514 = validateParameter(valid_602514, JString, required = false,
                                 default = nil)
  if valid_602514 != nil:
    section.add "X-Amz-Signature", valid_602514
  var valid_602515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602515 = validateParameter(valid_602515, JString, required = false,
                                 default = nil)
  if valid_602515 != nil:
    section.add "X-Amz-Content-Sha256", valid_602515
  var valid_602516 = header.getOrDefault("X-Amz-Date")
  valid_602516 = validateParameter(valid_602516, JString, required = false,
                                 default = nil)
  if valid_602516 != nil:
    section.add "X-Amz-Date", valid_602516
  var valid_602517 = header.getOrDefault("X-Amz-Credential")
  valid_602517 = validateParameter(valid_602517, JString, required = false,
                                 default = nil)
  if valid_602517 != nil:
    section.add "X-Amz-Credential", valid_602517
  var valid_602518 = header.getOrDefault("X-Amz-Security-Token")
  valid_602518 = validateParameter(valid_602518, JString, required = false,
                                 default = nil)
  if valid_602518 != nil:
    section.add "X-Amz-Security-Token", valid_602518
  var valid_602519 = header.getOrDefault("X-Amz-Algorithm")
  valid_602519 = validateParameter(valid_602519, JString, required = false,
                                 default = nil)
  if valid_602519 != nil:
    section.add "X-Amz-Algorithm", valid_602519
  var valid_602520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602520 = validateParameter(valid_602520, JString, required = false,
                                 default = nil)
  if valid_602520 != nil:
    section.add "X-Amz-SignedHeaders", valid_602520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602522: Call_ListOrganizationalUnitsForParent_602508;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the organizational units (OUs) in a parent organizational unit or root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_602522.validator(path, query, header, formData, body)
  let scheme = call_602522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602522.url(scheme.get, call_602522.host, call_602522.base,
                         call_602522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602522, url, valid)

proc call*(call_602523: Call_ListOrganizationalUnitsForParent_602508;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listOrganizationalUnitsForParent
  ## <p>Lists the organizational units (OUs) in a parent organizational unit or root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602524 = newJObject()
  var body_602525 = newJObject()
  add(query_602524, "MaxResults", newJString(MaxResults))
  add(query_602524, "NextToken", newJString(NextToken))
  if body != nil:
    body_602525 = body
  result = call_602523.call(nil, query_602524, nil, nil, body_602525)

var listOrganizationalUnitsForParent* = Call_ListOrganizationalUnitsForParent_602508(
    name: "listOrganizationalUnitsForParent", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListOrganizationalUnitsForParent",
    validator: validate_ListOrganizationalUnitsForParent_602509, base: "/",
    url: url_ListOrganizationalUnitsForParent_602510,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListParents_602526 = ref object of OpenApiRestCall_601390
proc url_ListParents_602528(protocol: Scheme; host: string; base: string;
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

proc validate_ListParents_602527(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602529 = query.getOrDefault("MaxResults")
  valid_602529 = validateParameter(valid_602529, JString, required = false,
                                 default = nil)
  if valid_602529 != nil:
    section.add "MaxResults", valid_602529
  var valid_602530 = query.getOrDefault("NextToken")
  valid_602530 = validateParameter(valid_602530, JString, required = false,
                                 default = nil)
  if valid_602530 != nil:
    section.add "NextToken", valid_602530
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
  var valid_602531 = header.getOrDefault("X-Amz-Target")
  valid_602531 = validateParameter(valid_602531, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListParents"))
  if valid_602531 != nil:
    section.add "X-Amz-Target", valid_602531
  var valid_602532 = header.getOrDefault("X-Amz-Signature")
  valid_602532 = validateParameter(valid_602532, JString, required = false,
                                 default = nil)
  if valid_602532 != nil:
    section.add "X-Amz-Signature", valid_602532
  var valid_602533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602533 = validateParameter(valid_602533, JString, required = false,
                                 default = nil)
  if valid_602533 != nil:
    section.add "X-Amz-Content-Sha256", valid_602533
  var valid_602534 = header.getOrDefault("X-Amz-Date")
  valid_602534 = validateParameter(valid_602534, JString, required = false,
                                 default = nil)
  if valid_602534 != nil:
    section.add "X-Amz-Date", valid_602534
  var valid_602535 = header.getOrDefault("X-Amz-Credential")
  valid_602535 = validateParameter(valid_602535, JString, required = false,
                                 default = nil)
  if valid_602535 != nil:
    section.add "X-Amz-Credential", valid_602535
  var valid_602536 = header.getOrDefault("X-Amz-Security-Token")
  valid_602536 = validateParameter(valid_602536, JString, required = false,
                                 default = nil)
  if valid_602536 != nil:
    section.add "X-Amz-Security-Token", valid_602536
  var valid_602537 = header.getOrDefault("X-Amz-Algorithm")
  valid_602537 = validateParameter(valid_602537, JString, required = false,
                                 default = nil)
  if valid_602537 != nil:
    section.add "X-Amz-Algorithm", valid_602537
  var valid_602538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602538 = validateParameter(valid_602538, JString, required = false,
                                 default = nil)
  if valid_602538 != nil:
    section.add "X-Amz-SignedHeaders", valid_602538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602540: Call_ListParents_602526; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the root or organizational units (OUs) that serve as the immediate parent of the specified child OU or account. This operation, along with <a>ListChildren</a> enables you to traverse the tree structure that makes up this root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p> <note> <p>In the current release, a child can have only a single parent. </p> </note>
  ## 
  let valid = call_602540.validator(path, query, header, formData, body)
  let scheme = call_602540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602540.url(scheme.get, call_602540.host, call_602540.base,
                         call_602540.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602540, url, valid)

proc call*(call_602541: Call_ListParents_602526; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listParents
  ## <p>Lists the root or organizational units (OUs) that serve as the immediate parent of the specified child OU or account. This operation, along with <a>ListChildren</a> enables you to traverse the tree structure that makes up this root.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p> <note> <p>In the current release, a child can have only a single parent. </p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602542 = newJObject()
  var body_602543 = newJObject()
  add(query_602542, "MaxResults", newJString(MaxResults))
  add(query_602542, "NextToken", newJString(NextToken))
  if body != nil:
    body_602543 = body
  result = call_602541.call(nil, query_602542, nil, nil, body_602543)

var listParents* = Call_ListParents_602526(name: "listParents",
                                        meth: HttpMethod.HttpPost,
                                        host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListParents",
                                        validator: validate_ListParents_602527,
                                        base: "/", url: url_ListParents_602528,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPolicies_602544 = ref object of OpenApiRestCall_601390
proc url_ListPolicies_602546(protocol: Scheme; host: string; base: string;
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

proc validate_ListPolicies_602545(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602547 = query.getOrDefault("MaxResults")
  valid_602547 = validateParameter(valid_602547, JString, required = false,
                                 default = nil)
  if valid_602547 != nil:
    section.add "MaxResults", valid_602547
  var valid_602548 = query.getOrDefault("NextToken")
  valid_602548 = validateParameter(valid_602548, JString, required = false,
                                 default = nil)
  if valid_602548 != nil:
    section.add "NextToken", valid_602548
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
  var valid_602549 = header.getOrDefault("X-Amz-Target")
  valid_602549 = validateParameter(valid_602549, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListPolicies"))
  if valid_602549 != nil:
    section.add "X-Amz-Target", valid_602549
  var valid_602550 = header.getOrDefault("X-Amz-Signature")
  valid_602550 = validateParameter(valid_602550, JString, required = false,
                                 default = nil)
  if valid_602550 != nil:
    section.add "X-Amz-Signature", valid_602550
  var valid_602551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602551 = validateParameter(valid_602551, JString, required = false,
                                 default = nil)
  if valid_602551 != nil:
    section.add "X-Amz-Content-Sha256", valid_602551
  var valid_602552 = header.getOrDefault("X-Amz-Date")
  valid_602552 = validateParameter(valid_602552, JString, required = false,
                                 default = nil)
  if valid_602552 != nil:
    section.add "X-Amz-Date", valid_602552
  var valid_602553 = header.getOrDefault("X-Amz-Credential")
  valid_602553 = validateParameter(valid_602553, JString, required = false,
                                 default = nil)
  if valid_602553 != nil:
    section.add "X-Amz-Credential", valid_602553
  var valid_602554 = header.getOrDefault("X-Amz-Security-Token")
  valid_602554 = validateParameter(valid_602554, JString, required = false,
                                 default = nil)
  if valid_602554 != nil:
    section.add "X-Amz-Security-Token", valid_602554
  var valid_602555 = header.getOrDefault("X-Amz-Algorithm")
  valid_602555 = validateParameter(valid_602555, JString, required = false,
                                 default = nil)
  if valid_602555 != nil:
    section.add "X-Amz-Algorithm", valid_602555
  var valid_602556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602556 = validateParameter(valid_602556, JString, required = false,
                                 default = nil)
  if valid_602556 != nil:
    section.add "X-Amz-SignedHeaders", valid_602556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602558: Call_ListPolicies_602544; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the list of all policies in an organization of a specified type.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_602558.validator(path, query, header, formData, body)
  let scheme = call_602558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602558.url(scheme.get, call_602558.host, call_602558.base,
                         call_602558.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602558, url, valid)

proc call*(call_602559: Call_ListPolicies_602544; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listPolicies
  ## <p>Retrieves the list of all policies in an organization of a specified type.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602560 = newJObject()
  var body_602561 = newJObject()
  add(query_602560, "MaxResults", newJString(MaxResults))
  add(query_602560, "NextToken", newJString(NextToken))
  if body != nil:
    body_602561 = body
  result = call_602559.call(nil, query_602560, nil, nil, body_602561)

var listPolicies* = Call_ListPolicies_602544(name: "listPolicies",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListPolicies",
    validator: validate_ListPolicies_602545, base: "/", url: url_ListPolicies_602546,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPoliciesForTarget_602562 = ref object of OpenApiRestCall_601390
proc url_ListPoliciesForTarget_602564(protocol: Scheme; host: string; base: string;
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

proc validate_ListPoliciesForTarget_602563(path: JsonNode; query: JsonNode;
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
  var valid_602565 = query.getOrDefault("MaxResults")
  valid_602565 = validateParameter(valid_602565, JString, required = false,
                                 default = nil)
  if valid_602565 != nil:
    section.add "MaxResults", valid_602565
  var valid_602566 = query.getOrDefault("NextToken")
  valid_602566 = validateParameter(valid_602566, JString, required = false,
                                 default = nil)
  if valid_602566 != nil:
    section.add "NextToken", valid_602566
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
  var valid_602567 = header.getOrDefault("X-Amz-Target")
  valid_602567 = validateParameter(valid_602567, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListPoliciesForTarget"))
  if valid_602567 != nil:
    section.add "X-Amz-Target", valid_602567
  var valid_602568 = header.getOrDefault("X-Amz-Signature")
  valid_602568 = validateParameter(valid_602568, JString, required = false,
                                 default = nil)
  if valid_602568 != nil:
    section.add "X-Amz-Signature", valid_602568
  var valid_602569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602569 = validateParameter(valid_602569, JString, required = false,
                                 default = nil)
  if valid_602569 != nil:
    section.add "X-Amz-Content-Sha256", valid_602569
  var valid_602570 = header.getOrDefault("X-Amz-Date")
  valid_602570 = validateParameter(valid_602570, JString, required = false,
                                 default = nil)
  if valid_602570 != nil:
    section.add "X-Amz-Date", valid_602570
  var valid_602571 = header.getOrDefault("X-Amz-Credential")
  valid_602571 = validateParameter(valid_602571, JString, required = false,
                                 default = nil)
  if valid_602571 != nil:
    section.add "X-Amz-Credential", valid_602571
  var valid_602572 = header.getOrDefault("X-Amz-Security-Token")
  valid_602572 = validateParameter(valid_602572, JString, required = false,
                                 default = nil)
  if valid_602572 != nil:
    section.add "X-Amz-Security-Token", valid_602572
  var valid_602573 = header.getOrDefault("X-Amz-Algorithm")
  valid_602573 = validateParameter(valid_602573, JString, required = false,
                                 default = nil)
  if valid_602573 != nil:
    section.add "X-Amz-Algorithm", valid_602573
  var valid_602574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602574 = validateParameter(valid_602574, JString, required = false,
                                 default = nil)
  if valid_602574 != nil:
    section.add "X-Amz-SignedHeaders", valid_602574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602576: Call_ListPoliciesForTarget_602562; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the policies that are directly attached to the specified target root, organizational unit (OU), or account. You must specify the policy type that you want included in the returned list.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_602576.validator(path, query, header, formData, body)
  let scheme = call_602576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602576.url(scheme.get, call_602576.host, call_602576.base,
                         call_602576.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602576, url, valid)

proc call*(call_602577: Call_ListPoliciesForTarget_602562; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listPoliciesForTarget
  ## <p>Lists the policies that are directly attached to the specified target root, organizational unit (OU), or account. You must specify the policy type that you want included in the returned list.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602578 = newJObject()
  var body_602579 = newJObject()
  add(query_602578, "MaxResults", newJString(MaxResults))
  add(query_602578, "NextToken", newJString(NextToken))
  if body != nil:
    body_602579 = body
  result = call_602577.call(nil, query_602578, nil, nil, body_602579)

var listPoliciesForTarget* = Call_ListPoliciesForTarget_602562(
    name: "listPoliciesForTarget", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListPoliciesForTarget",
    validator: validate_ListPoliciesForTarget_602563, base: "/",
    url: url_ListPoliciesForTarget_602564, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoots_602580 = ref object of OpenApiRestCall_601390
proc url_ListRoots_602582(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListRoots_602581(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602583 = query.getOrDefault("MaxResults")
  valid_602583 = validateParameter(valid_602583, JString, required = false,
                                 default = nil)
  if valid_602583 != nil:
    section.add "MaxResults", valid_602583
  var valid_602584 = query.getOrDefault("NextToken")
  valid_602584 = validateParameter(valid_602584, JString, required = false,
                                 default = nil)
  if valid_602584 != nil:
    section.add "NextToken", valid_602584
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
  var valid_602585 = header.getOrDefault("X-Amz-Target")
  valid_602585 = validateParameter(valid_602585, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListRoots"))
  if valid_602585 != nil:
    section.add "X-Amz-Target", valid_602585
  var valid_602586 = header.getOrDefault("X-Amz-Signature")
  valid_602586 = validateParameter(valid_602586, JString, required = false,
                                 default = nil)
  if valid_602586 != nil:
    section.add "X-Amz-Signature", valid_602586
  var valid_602587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602587 = validateParameter(valid_602587, JString, required = false,
                                 default = nil)
  if valid_602587 != nil:
    section.add "X-Amz-Content-Sha256", valid_602587
  var valid_602588 = header.getOrDefault("X-Amz-Date")
  valid_602588 = validateParameter(valid_602588, JString, required = false,
                                 default = nil)
  if valid_602588 != nil:
    section.add "X-Amz-Date", valid_602588
  var valid_602589 = header.getOrDefault("X-Amz-Credential")
  valid_602589 = validateParameter(valid_602589, JString, required = false,
                                 default = nil)
  if valid_602589 != nil:
    section.add "X-Amz-Credential", valid_602589
  var valid_602590 = header.getOrDefault("X-Amz-Security-Token")
  valid_602590 = validateParameter(valid_602590, JString, required = false,
                                 default = nil)
  if valid_602590 != nil:
    section.add "X-Amz-Security-Token", valid_602590
  var valid_602591 = header.getOrDefault("X-Amz-Algorithm")
  valid_602591 = validateParameter(valid_602591, JString, required = false,
                                 default = nil)
  if valid_602591 != nil:
    section.add "X-Amz-Algorithm", valid_602591
  var valid_602592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602592 = validateParameter(valid_602592, JString, required = false,
                                 default = nil)
  if valid_602592 != nil:
    section.add "X-Amz-SignedHeaders", valid_602592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602594: Call_ListRoots_602580; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the roots that are defined in the current organization.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p> <note> <p>Policy types can be enabled and disabled in roots. This is distinct from whether they're available in the organization. When you enable all features, you make policy types available for use in that organization. Individual policy types can then be enabled and disabled in a root. To see the availability of a policy type in an organization, use <a>DescribeOrganization</a>.</p> </note>
  ## 
  let valid = call_602594.validator(path, query, header, formData, body)
  let scheme = call_602594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602594.url(scheme.get, call_602594.host, call_602594.base,
                         call_602594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602594, url, valid)

proc call*(call_602595: Call_ListRoots_602580; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listRoots
  ## <p>Lists the roots that are defined in the current organization.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p> <note> <p>Policy types can be enabled and disabled in roots. This is distinct from whether they're available in the organization. When you enable all features, you make policy types available for use in that organization. Individual policy types can then be enabled and disabled in a root. To see the availability of a policy type in an organization, use <a>DescribeOrganization</a>.</p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602596 = newJObject()
  var body_602597 = newJObject()
  add(query_602596, "MaxResults", newJString(MaxResults))
  add(query_602596, "NextToken", newJString(NextToken))
  if body != nil:
    body_602597 = body
  result = call_602595.call(nil, query_602596, nil, nil, body_602597)

var listRoots* = Call_ListRoots_602580(name: "listRoots", meth: HttpMethod.HttpPost,
                                    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListRoots",
                                    validator: validate_ListRoots_602581,
                                    base: "/", url: url_ListRoots_602582,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_602598 = ref object of OpenApiRestCall_601390
proc url_ListTagsForResource_602600(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_602599(path: JsonNode; query: JsonNode;
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
  var valid_602601 = query.getOrDefault("NextToken")
  valid_602601 = validateParameter(valid_602601, JString, required = false,
                                 default = nil)
  if valid_602601 != nil:
    section.add "NextToken", valid_602601
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
  var valid_602602 = header.getOrDefault("X-Amz-Target")
  valid_602602 = validateParameter(valid_602602, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListTagsForResource"))
  if valid_602602 != nil:
    section.add "X-Amz-Target", valid_602602
  var valid_602603 = header.getOrDefault("X-Amz-Signature")
  valid_602603 = validateParameter(valid_602603, JString, required = false,
                                 default = nil)
  if valid_602603 != nil:
    section.add "X-Amz-Signature", valid_602603
  var valid_602604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602604 = validateParameter(valid_602604, JString, required = false,
                                 default = nil)
  if valid_602604 != nil:
    section.add "X-Amz-Content-Sha256", valid_602604
  var valid_602605 = header.getOrDefault("X-Amz-Date")
  valid_602605 = validateParameter(valid_602605, JString, required = false,
                                 default = nil)
  if valid_602605 != nil:
    section.add "X-Amz-Date", valid_602605
  var valid_602606 = header.getOrDefault("X-Amz-Credential")
  valid_602606 = validateParameter(valid_602606, JString, required = false,
                                 default = nil)
  if valid_602606 != nil:
    section.add "X-Amz-Credential", valid_602606
  var valid_602607 = header.getOrDefault("X-Amz-Security-Token")
  valid_602607 = validateParameter(valid_602607, JString, required = false,
                                 default = nil)
  if valid_602607 != nil:
    section.add "X-Amz-Security-Token", valid_602607
  var valid_602608 = header.getOrDefault("X-Amz-Algorithm")
  valid_602608 = validateParameter(valid_602608, JString, required = false,
                                 default = nil)
  if valid_602608 != nil:
    section.add "X-Amz-Algorithm", valid_602608
  var valid_602609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602609 = validateParameter(valid_602609, JString, required = false,
                                 default = nil)
  if valid_602609 != nil:
    section.add "X-Amz-SignedHeaders", valid_602609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602611: Call_ListTagsForResource_602598; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists tags for the specified resource. </p> <p>Currently, you can list tags on an account in AWS Organizations.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_602611.validator(path, query, header, formData, body)
  let scheme = call_602611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602611.url(scheme.get, call_602611.host, call_602611.base,
                         call_602611.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602611, url, valid)

proc call*(call_602612: Call_ListTagsForResource_602598; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## listTagsForResource
  ## <p>Lists tags for the specified resource. </p> <p>Currently, you can list tags on an account in AWS Organizations.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602613 = newJObject()
  var body_602614 = newJObject()
  add(query_602613, "NextToken", newJString(NextToken))
  if body != nil:
    body_602614 = body
  result = call_602612.call(nil, query_602613, nil, nil, body_602614)

var listTagsForResource* = Call_ListTagsForResource_602598(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListTagsForResource",
    validator: validate_ListTagsForResource_602599, base: "/",
    url: url_ListTagsForResource_602600, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTargetsForPolicy_602615 = ref object of OpenApiRestCall_601390
proc url_ListTargetsForPolicy_602617(protocol: Scheme; host: string; base: string;
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

proc validate_ListTargetsForPolicy_602616(path: JsonNode; query: JsonNode;
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
  var valid_602618 = query.getOrDefault("MaxResults")
  valid_602618 = validateParameter(valid_602618, JString, required = false,
                                 default = nil)
  if valid_602618 != nil:
    section.add "MaxResults", valid_602618
  var valid_602619 = query.getOrDefault("NextToken")
  valid_602619 = validateParameter(valid_602619, JString, required = false,
                                 default = nil)
  if valid_602619 != nil:
    section.add "NextToken", valid_602619
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
  var valid_602620 = header.getOrDefault("X-Amz-Target")
  valid_602620 = validateParameter(valid_602620, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.ListTargetsForPolicy"))
  if valid_602620 != nil:
    section.add "X-Amz-Target", valid_602620
  var valid_602621 = header.getOrDefault("X-Amz-Signature")
  valid_602621 = validateParameter(valid_602621, JString, required = false,
                                 default = nil)
  if valid_602621 != nil:
    section.add "X-Amz-Signature", valid_602621
  var valid_602622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602622 = validateParameter(valid_602622, JString, required = false,
                                 default = nil)
  if valid_602622 != nil:
    section.add "X-Amz-Content-Sha256", valid_602622
  var valid_602623 = header.getOrDefault("X-Amz-Date")
  valid_602623 = validateParameter(valid_602623, JString, required = false,
                                 default = nil)
  if valid_602623 != nil:
    section.add "X-Amz-Date", valid_602623
  var valid_602624 = header.getOrDefault("X-Amz-Credential")
  valid_602624 = validateParameter(valid_602624, JString, required = false,
                                 default = nil)
  if valid_602624 != nil:
    section.add "X-Amz-Credential", valid_602624
  var valid_602625 = header.getOrDefault("X-Amz-Security-Token")
  valid_602625 = validateParameter(valid_602625, JString, required = false,
                                 default = nil)
  if valid_602625 != nil:
    section.add "X-Amz-Security-Token", valid_602625
  var valid_602626 = header.getOrDefault("X-Amz-Algorithm")
  valid_602626 = validateParameter(valid_602626, JString, required = false,
                                 default = nil)
  if valid_602626 != nil:
    section.add "X-Amz-Algorithm", valid_602626
  var valid_602627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602627 = validateParameter(valid_602627, JString, required = false,
                                 default = nil)
  if valid_602627 != nil:
    section.add "X-Amz-SignedHeaders", valid_602627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602629: Call_ListTargetsForPolicy_602615; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all the roots, organizational units (OUs), and accounts that the specified policy is attached to.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_602629.validator(path, query, header, formData, body)
  let scheme = call_602629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602629.url(scheme.get, call_602629.host, call_602629.base,
                         call_602629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602629, url, valid)

proc call*(call_602630: Call_ListTargetsForPolicy_602615; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTargetsForPolicy
  ## <p>Lists all the roots, organizational units (OUs), and accounts that the specified policy is attached to.</p> <note> <p>Always check the <code>NextToken</code> response parameter for a <code>null</code> value when calling a <code>List*</code> operation. These operations can occasionally return an empty set of results even when there are more results available. The <code>NextToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display.</p> </note> <p>This operation can be called only from the organization's master account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602631 = newJObject()
  var body_602632 = newJObject()
  add(query_602631, "MaxResults", newJString(MaxResults))
  add(query_602631, "NextToken", newJString(NextToken))
  if body != nil:
    body_602632 = body
  result = call_602630.call(nil, query_602631, nil, nil, body_602632)

var listTargetsForPolicy* = Call_ListTargetsForPolicy_602615(
    name: "listTargetsForPolicy", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.ListTargetsForPolicy",
    validator: validate_ListTargetsForPolicy_602616, base: "/",
    url: url_ListTargetsForPolicy_602617, schemes: {Scheme.Https, Scheme.Http})
type
  Call_MoveAccount_602633 = ref object of OpenApiRestCall_601390
proc url_MoveAccount_602635(protocol: Scheme; host: string; base: string;
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

proc validate_MoveAccount_602634(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602636 = header.getOrDefault("X-Amz-Target")
  valid_602636 = validateParameter(valid_602636, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.MoveAccount"))
  if valid_602636 != nil:
    section.add "X-Amz-Target", valid_602636
  var valid_602637 = header.getOrDefault("X-Amz-Signature")
  valid_602637 = validateParameter(valid_602637, JString, required = false,
                                 default = nil)
  if valid_602637 != nil:
    section.add "X-Amz-Signature", valid_602637
  var valid_602638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602638 = validateParameter(valid_602638, JString, required = false,
                                 default = nil)
  if valid_602638 != nil:
    section.add "X-Amz-Content-Sha256", valid_602638
  var valid_602639 = header.getOrDefault("X-Amz-Date")
  valid_602639 = validateParameter(valid_602639, JString, required = false,
                                 default = nil)
  if valid_602639 != nil:
    section.add "X-Amz-Date", valid_602639
  var valid_602640 = header.getOrDefault("X-Amz-Credential")
  valid_602640 = validateParameter(valid_602640, JString, required = false,
                                 default = nil)
  if valid_602640 != nil:
    section.add "X-Amz-Credential", valid_602640
  var valid_602641 = header.getOrDefault("X-Amz-Security-Token")
  valid_602641 = validateParameter(valid_602641, JString, required = false,
                                 default = nil)
  if valid_602641 != nil:
    section.add "X-Amz-Security-Token", valid_602641
  var valid_602642 = header.getOrDefault("X-Amz-Algorithm")
  valid_602642 = validateParameter(valid_602642, JString, required = false,
                                 default = nil)
  if valid_602642 != nil:
    section.add "X-Amz-Algorithm", valid_602642
  var valid_602643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602643 = validateParameter(valid_602643, JString, required = false,
                                 default = nil)
  if valid_602643 != nil:
    section.add "X-Amz-SignedHeaders", valid_602643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602645: Call_MoveAccount_602633; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Moves an account from its current source parent root or organizational unit (OU) to the specified destination parent root or OU.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_602645.validator(path, query, header, formData, body)
  let scheme = call_602645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602645.url(scheme.get, call_602645.host, call_602645.base,
                         call_602645.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602645, url, valid)

proc call*(call_602646: Call_MoveAccount_602633; body: JsonNode): Recallable =
  ## moveAccount
  ## <p>Moves an account from its current source parent root or organizational unit (OU) to the specified destination parent root or OU.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_602647 = newJObject()
  if body != nil:
    body_602647 = body
  result = call_602646.call(nil, nil, nil, nil, body_602647)

var moveAccount* = Call_MoveAccount_602633(name: "moveAccount",
                                        meth: HttpMethod.HttpPost,
                                        host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.MoveAccount",
                                        validator: validate_MoveAccount_602634,
                                        base: "/", url: url_MoveAccount_602635,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAccountFromOrganization_602648 = ref object of OpenApiRestCall_601390
proc url_RemoveAccountFromOrganization_602650(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RemoveAccountFromOrganization_602649(path: JsonNode; query: JsonNode;
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
  var valid_602651 = header.getOrDefault("X-Amz-Target")
  valid_602651 = validateParameter(valid_602651, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.RemoveAccountFromOrganization"))
  if valid_602651 != nil:
    section.add "X-Amz-Target", valid_602651
  var valid_602652 = header.getOrDefault("X-Amz-Signature")
  valid_602652 = validateParameter(valid_602652, JString, required = false,
                                 default = nil)
  if valid_602652 != nil:
    section.add "X-Amz-Signature", valid_602652
  var valid_602653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602653 = validateParameter(valid_602653, JString, required = false,
                                 default = nil)
  if valid_602653 != nil:
    section.add "X-Amz-Content-Sha256", valid_602653
  var valid_602654 = header.getOrDefault("X-Amz-Date")
  valid_602654 = validateParameter(valid_602654, JString, required = false,
                                 default = nil)
  if valid_602654 != nil:
    section.add "X-Amz-Date", valid_602654
  var valid_602655 = header.getOrDefault("X-Amz-Credential")
  valid_602655 = validateParameter(valid_602655, JString, required = false,
                                 default = nil)
  if valid_602655 != nil:
    section.add "X-Amz-Credential", valid_602655
  var valid_602656 = header.getOrDefault("X-Amz-Security-Token")
  valid_602656 = validateParameter(valid_602656, JString, required = false,
                                 default = nil)
  if valid_602656 != nil:
    section.add "X-Amz-Security-Token", valid_602656
  var valid_602657 = header.getOrDefault("X-Amz-Algorithm")
  valid_602657 = validateParameter(valid_602657, JString, required = false,
                                 default = nil)
  if valid_602657 != nil:
    section.add "X-Amz-Algorithm", valid_602657
  var valid_602658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602658 = validateParameter(valid_602658, JString, required = false,
                                 default = nil)
  if valid_602658 != nil:
    section.add "X-Amz-SignedHeaders", valid_602658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602660: Call_RemoveAccountFromOrganization_602648; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified account from the organization.</p> <p>The removed account becomes a standalone account that isn't a member of any organization. It's no longer subject to any policies and is responsible for its own bill payments. The organization's master account is no longer charged for any expenses accrued by the member account after it's removed from the organization.</p> <p>This operation can be called only from the organization's master account. Member accounts can remove themselves with <a>LeaveOrganization</a> instead.</p> <important> <p>You can remove an account from your organization only if the account is configured with the information required to operate as a standalone account. When you create an account in an organization using the AWS Organizations console, API, or CLI, the information required of standalone accounts is <i>not</i> automatically collected. For an account that you want to make standalone, you must accept the end user license agreement (EULA). You must also choose a support plan, provide and verify the required contact information, and provide a current payment method. AWS uses the payment method to charge for any billable (not free tier) AWS activity that occurs while the account isn't attached to an organization. To remove an account that doesn't yet have this information, you must sign in as the member account. Then follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization when all required account information has not yet been provided</a> in the <i>AWS Organizations User Guide.</i> </p> </important>
  ## 
  let valid = call_602660.validator(path, query, header, formData, body)
  let scheme = call_602660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602660.url(scheme.get, call_602660.host, call_602660.base,
                         call_602660.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602660, url, valid)

proc call*(call_602661: Call_RemoveAccountFromOrganization_602648; body: JsonNode): Recallable =
  ## removeAccountFromOrganization
  ## <p>Removes the specified account from the organization.</p> <p>The removed account becomes a standalone account that isn't a member of any organization. It's no longer subject to any policies and is responsible for its own bill payments. The organization's master account is no longer charged for any expenses accrued by the member account after it's removed from the organization.</p> <p>This operation can be called only from the organization's master account. Member accounts can remove themselves with <a>LeaveOrganization</a> instead.</p> <important> <p>You can remove an account from your organization only if the account is configured with the information required to operate as a standalone account. When you create an account in an organization using the AWS Organizations console, API, or CLI, the information required of standalone accounts is <i>not</i> automatically collected. For an account that you want to make standalone, you must accept the end user license agreement (EULA). You must also choose a support plan, provide and verify the required contact information, and provide a current payment method. AWS uses the payment method to charge for any billable (not free tier) AWS activity that occurs while the account isn't attached to an organization. To remove an account that doesn't yet have this information, you must sign in as the member account. Then follow the steps at <a href="http://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info"> To leave an organization when all required account information has not yet been provided</a> in the <i>AWS Organizations User Guide.</i> </p> </important>
  ##   body: JObject (required)
  var body_602662 = newJObject()
  if body != nil:
    body_602662 = body
  result = call_602661.call(nil, nil, nil, nil, body_602662)

var removeAccountFromOrganization* = Call_RemoveAccountFromOrganization_602648(
    name: "removeAccountFromOrganization", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.RemoveAccountFromOrganization",
    validator: validate_RemoveAccountFromOrganization_602649, base: "/",
    url: url_RemoveAccountFromOrganization_602650,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602663 = ref object of OpenApiRestCall_601390
proc url_TagResource_602665(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_602664(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602666 = header.getOrDefault("X-Amz-Target")
  valid_602666 = validateParameter(valid_602666, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.TagResource"))
  if valid_602666 != nil:
    section.add "X-Amz-Target", valid_602666
  var valid_602667 = header.getOrDefault("X-Amz-Signature")
  valid_602667 = validateParameter(valid_602667, JString, required = false,
                                 default = nil)
  if valid_602667 != nil:
    section.add "X-Amz-Signature", valid_602667
  var valid_602668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602668 = validateParameter(valid_602668, JString, required = false,
                                 default = nil)
  if valid_602668 != nil:
    section.add "X-Amz-Content-Sha256", valid_602668
  var valid_602669 = header.getOrDefault("X-Amz-Date")
  valid_602669 = validateParameter(valid_602669, JString, required = false,
                                 default = nil)
  if valid_602669 != nil:
    section.add "X-Amz-Date", valid_602669
  var valid_602670 = header.getOrDefault("X-Amz-Credential")
  valid_602670 = validateParameter(valid_602670, JString, required = false,
                                 default = nil)
  if valid_602670 != nil:
    section.add "X-Amz-Credential", valid_602670
  var valid_602671 = header.getOrDefault("X-Amz-Security-Token")
  valid_602671 = validateParameter(valid_602671, JString, required = false,
                                 default = nil)
  if valid_602671 != nil:
    section.add "X-Amz-Security-Token", valid_602671
  var valid_602672 = header.getOrDefault("X-Amz-Algorithm")
  valid_602672 = validateParameter(valid_602672, JString, required = false,
                                 default = nil)
  if valid_602672 != nil:
    section.add "X-Amz-Algorithm", valid_602672
  var valid_602673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602673 = validateParameter(valid_602673, JString, required = false,
                                 default = nil)
  if valid_602673 != nil:
    section.add "X-Amz-SignedHeaders", valid_602673
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602675: Call_TagResource_602663; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more tags to the specified resource.</p> <p>Currently, you can tag and untag accounts in AWS Organizations.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_602675.validator(path, query, header, formData, body)
  let scheme = call_602675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602675.url(scheme.get, call_602675.host, call_602675.base,
                         call_602675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602675, url, valid)

proc call*(call_602676: Call_TagResource_602663; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds one or more tags to the specified resource.</p> <p>Currently, you can tag and untag accounts in AWS Organizations.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_602677 = newJObject()
  if body != nil:
    body_602677 = body
  result = call_602676.call(nil, nil, nil, nil, body_602677)

var tagResource* = Call_TagResource_602663(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "organizations.amazonaws.com", route: "/#X-Amz-Target=AWSOrganizationsV20161128.TagResource",
                                        validator: validate_TagResource_602664,
                                        base: "/", url: url_TagResource_602665,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602678 = ref object of OpenApiRestCall_601390
proc url_UntagResource_602680(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_602679(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602681 = header.getOrDefault("X-Amz-Target")
  valid_602681 = validateParameter(valid_602681, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.UntagResource"))
  if valid_602681 != nil:
    section.add "X-Amz-Target", valid_602681
  var valid_602682 = header.getOrDefault("X-Amz-Signature")
  valid_602682 = validateParameter(valid_602682, JString, required = false,
                                 default = nil)
  if valid_602682 != nil:
    section.add "X-Amz-Signature", valid_602682
  var valid_602683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602683 = validateParameter(valid_602683, JString, required = false,
                                 default = nil)
  if valid_602683 != nil:
    section.add "X-Amz-Content-Sha256", valid_602683
  var valid_602684 = header.getOrDefault("X-Amz-Date")
  valid_602684 = validateParameter(valid_602684, JString, required = false,
                                 default = nil)
  if valid_602684 != nil:
    section.add "X-Amz-Date", valid_602684
  var valid_602685 = header.getOrDefault("X-Amz-Credential")
  valid_602685 = validateParameter(valid_602685, JString, required = false,
                                 default = nil)
  if valid_602685 != nil:
    section.add "X-Amz-Credential", valid_602685
  var valid_602686 = header.getOrDefault("X-Amz-Security-Token")
  valid_602686 = validateParameter(valid_602686, JString, required = false,
                                 default = nil)
  if valid_602686 != nil:
    section.add "X-Amz-Security-Token", valid_602686
  var valid_602687 = header.getOrDefault("X-Amz-Algorithm")
  valid_602687 = validateParameter(valid_602687, JString, required = false,
                                 default = nil)
  if valid_602687 != nil:
    section.add "X-Amz-Algorithm", valid_602687
  var valid_602688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602688 = validateParameter(valid_602688, JString, required = false,
                                 default = nil)
  if valid_602688 != nil:
    section.add "X-Amz-SignedHeaders", valid_602688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602690: Call_UntagResource_602678; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a tag from the specified resource. </p> <p>Currently, you can tag and untag accounts in AWS Organizations.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_602690.validator(path, query, header, formData, body)
  let scheme = call_602690.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602690.url(scheme.get, call_602690.host, call_602690.base,
                         call_602690.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602690, url, valid)

proc call*(call_602691: Call_UntagResource_602678; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Removes a tag from the specified resource. </p> <p>Currently, you can tag and untag accounts in AWS Organizations.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_602692 = newJObject()
  if body != nil:
    body_602692 = body
  result = call_602691.call(nil, nil, nil, nil, body_602692)

var untagResource* = Call_UntagResource_602678(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.UntagResource",
    validator: validate_UntagResource_602679, base: "/", url: url_UntagResource_602680,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateOrganizationalUnit_602693 = ref object of OpenApiRestCall_601390
proc url_UpdateOrganizationalUnit_602695(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateOrganizationalUnit_602694(path: JsonNode; query: JsonNode;
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
  var valid_602696 = header.getOrDefault("X-Amz-Target")
  valid_602696 = validateParameter(valid_602696, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.UpdateOrganizationalUnit"))
  if valid_602696 != nil:
    section.add "X-Amz-Target", valid_602696
  var valid_602697 = header.getOrDefault("X-Amz-Signature")
  valid_602697 = validateParameter(valid_602697, JString, required = false,
                                 default = nil)
  if valid_602697 != nil:
    section.add "X-Amz-Signature", valid_602697
  var valid_602698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602698 = validateParameter(valid_602698, JString, required = false,
                                 default = nil)
  if valid_602698 != nil:
    section.add "X-Amz-Content-Sha256", valid_602698
  var valid_602699 = header.getOrDefault("X-Amz-Date")
  valid_602699 = validateParameter(valid_602699, JString, required = false,
                                 default = nil)
  if valid_602699 != nil:
    section.add "X-Amz-Date", valid_602699
  var valid_602700 = header.getOrDefault("X-Amz-Credential")
  valid_602700 = validateParameter(valid_602700, JString, required = false,
                                 default = nil)
  if valid_602700 != nil:
    section.add "X-Amz-Credential", valid_602700
  var valid_602701 = header.getOrDefault("X-Amz-Security-Token")
  valid_602701 = validateParameter(valid_602701, JString, required = false,
                                 default = nil)
  if valid_602701 != nil:
    section.add "X-Amz-Security-Token", valid_602701
  var valid_602702 = header.getOrDefault("X-Amz-Algorithm")
  valid_602702 = validateParameter(valid_602702, JString, required = false,
                                 default = nil)
  if valid_602702 != nil:
    section.add "X-Amz-Algorithm", valid_602702
  var valid_602703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602703 = validateParameter(valid_602703, JString, required = false,
                                 default = nil)
  if valid_602703 != nil:
    section.add "X-Amz-SignedHeaders", valid_602703
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602705: Call_UpdateOrganizationalUnit_602693; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Renames the specified organizational unit (OU). The ID and ARN don't change. The child OUs and accounts remain in place, and any attached policies of the OU remain attached. </p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_602705.validator(path, query, header, formData, body)
  let scheme = call_602705.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602705.url(scheme.get, call_602705.host, call_602705.base,
                         call_602705.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602705, url, valid)

proc call*(call_602706: Call_UpdateOrganizationalUnit_602693; body: JsonNode): Recallable =
  ## updateOrganizationalUnit
  ## <p>Renames the specified organizational unit (OU). The ID and ARN don't change. The child OUs and accounts remain in place, and any attached policies of the OU remain attached. </p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_602707 = newJObject()
  if body != nil:
    body_602707 = body
  result = call_602706.call(nil, nil, nil, nil, body_602707)

var updateOrganizationalUnit* = Call_UpdateOrganizationalUnit_602693(
    name: "updateOrganizationalUnit", meth: HttpMethod.HttpPost,
    host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.UpdateOrganizationalUnit",
    validator: validate_UpdateOrganizationalUnit_602694, base: "/",
    url: url_UpdateOrganizationalUnit_602695, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePolicy_602708 = ref object of OpenApiRestCall_601390
proc url_UpdatePolicy_602710(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePolicy_602709(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602711 = header.getOrDefault("X-Amz-Target")
  valid_602711 = validateParameter(valid_602711, JString, required = true, default = newJString(
      "AWSOrganizationsV20161128.UpdatePolicy"))
  if valid_602711 != nil:
    section.add "X-Amz-Target", valid_602711
  var valid_602712 = header.getOrDefault("X-Amz-Signature")
  valid_602712 = validateParameter(valid_602712, JString, required = false,
                                 default = nil)
  if valid_602712 != nil:
    section.add "X-Amz-Signature", valid_602712
  var valid_602713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602713 = validateParameter(valid_602713, JString, required = false,
                                 default = nil)
  if valid_602713 != nil:
    section.add "X-Amz-Content-Sha256", valid_602713
  var valid_602714 = header.getOrDefault("X-Amz-Date")
  valid_602714 = validateParameter(valid_602714, JString, required = false,
                                 default = nil)
  if valid_602714 != nil:
    section.add "X-Amz-Date", valid_602714
  var valid_602715 = header.getOrDefault("X-Amz-Credential")
  valid_602715 = validateParameter(valid_602715, JString, required = false,
                                 default = nil)
  if valid_602715 != nil:
    section.add "X-Amz-Credential", valid_602715
  var valid_602716 = header.getOrDefault("X-Amz-Security-Token")
  valid_602716 = validateParameter(valid_602716, JString, required = false,
                                 default = nil)
  if valid_602716 != nil:
    section.add "X-Amz-Security-Token", valid_602716
  var valid_602717 = header.getOrDefault("X-Amz-Algorithm")
  valid_602717 = validateParameter(valid_602717, JString, required = false,
                                 default = nil)
  if valid_602717 != nil:
    section.add "X-Amz-Algorithm", valid_602717
  var valid_602718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602718 = validateParameter(valid_602718, JString, required = false,
                                 default = nil)
  if valid_602718 != nil:
    section.add "X-Amz-SignedHeaders", valid_602718
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602720: Call_UpdatePolicy_602708; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing policy with a new name, description, or content. If you don't supply any parameter, that value remains unchanged. You can't change a policy's type.</p> <p>This operation can be called only from the organization's master account.</p>
  ## 
  let valid = call_602720.validator(path, query, header, formData, body)
  let scheme = call_602720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602720.url(scheme.get, call_602720.host, call_602720.base,
                         call_602720.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602720, url, valid)

proc call*(call_602721: Call_UpdatePolicy_602708; body: JsonNode): Recallable =
  ## updatePolicy
  ## <p>Updates an existing policy with a new name, description, or content. If you don't supply any parameter, that value remains unchanged. You can't change a policy's type.</p> <p>This operation can be called only from the organization's master account.</p>
  ##   body: JObject (required)
  var body_602722 = newJObject()
  if body != nil:
    body_602722 = body
  result = call_602721.call(nil, nil, nil, nil, body_602722)

var updatePolicy* = Call_UpdatePolicy_602708(name: "updatePolicy",
    meth: HttpMethod.HttpPost, host: "organizations.amazonaws.com",
    route: "/#X-Amz-Target=AWSOrganizationsV20161128.UpdatePolicy",
    validator: validate_UpdatePolicy_602709, base: "/", url: url_UpdatePolicy_602710,
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
