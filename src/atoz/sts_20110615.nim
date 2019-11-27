
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Security Token Service
## version: 2011-06-15
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Security Token Service</fullname> <p>The AWS Security Token Service (STS) is a web service that enables you to request temporary, limited-privilege credentials for AWS Identity and Access Management (IAM) users or for users that you authenticate (federated users). This guide provides descriptions of the STS API. For more detailed information about using this service, go to <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp.html">Temporary Security Credentials</a>. </p> <p>For information about setting up signatures and authorization through the API, go to <a href="https://docs.aws.amazon.com/general/latest/gr/signing_aws_api_requests.html">Signing AWS API Requests</a> in the <i>AWS General Reference</i>. For general information about the Query API, go to <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/IAM_UsingQueryAPI.html">Making Query Requests</a> in <i>Using IAM</i>. For information about using security tokens with other AWS products, go to <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_aws-services-that-work-with-iam.html">AWS Services That Work with IAM</a> in the <i>IAM User Guide</i>. </p> <p>If you're new to AWS and need additional technical information about a specific AWS product, you can find the product's technical documentation at <a href="http://aws.amazon.com/documentation/">http://aws.amazon.com/documentation/</a>. </p> <p> <b>Endpoints</b> </p> <p>By default, AWS Security Token Service (STS) is available as a global service, and all AWS STS requests go to a single endpoint at <code>https://sts.amazonaws.com</code>. Global requests map to the US East (N. Virginia) region. AWS recommends using Regional AWS STS endpoints instead of the global endpoint to reduce latency, build in redundancy, and increase session token validity. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Managing AWS STS in an AWS Region</a> in the <i>IAM User Guide</i>.</p> <p>Most AWS Regions are enabled for operations in all AWS services by default. Those Regions are automatically activated for use with AWS STS. Some Regions, such as Asia Pacific (Hong Kong), must be manually enabled. To learn more about enabling and disabling AWS Regions, see <a href="https://docs.aws.amazon.com/general/latest/gr/rande-manage.html">Managing AWS Regions</a> in the <i>AWS General Reference</i>. When you enable these AWS Regions, they are automatically activated for use with AWS STS. You cannot activate the STS endpoint for a Region that is disabled. Tokens that are valid in all AWS Regions are longer than tokens that are valid in Regions that are enabled by default. Changing this setting might affect existing systems where you temporarily store tokens. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html#sts-regions-manage-tokens">Managing Global Endpoint Session Tokens</a> in the <i>IAM User Guide</i>.</p> <p>After you activate a Region for use with AWS STS, you can direct AWS STS API calls to that Region. AWS STS recommends that you provide both the Region and endpoint when you make calls to a Regional endpoint. You can provide the Region alone for manually enabled Regions, such as Asia Pacific (Hong Kong). In this case, the calls are directed to the STS Regional endpoint. However, if you provide the Region alone for Regions enabled by default, the calls are directed to the global endpoint of <code>https://sts.amazonaws.com</code>.</p> <p>To view the list of AWS STS endpoints and whether they are active by default, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html#id_credentials_temp_enable-regions_writing_code">Writing Code to Use AWS STS Regions</a> in the <i>IAM User Guide</i>.</p> <p> <b>Recording API requests</b> </p> <p>STS supports AWS CloudTrail, which is a service that records AWS calls for your AWS account and delivers log files to an Amazon S3 bucket. By using information collected by CloudTrail, you can determine what requests were successfully made to STS, who made the request, when it was made, and so on.</p> <p>If you activate AWS STS endpoints in Regions other than the default global endpoint, then you must also turn on CloudTrail logging in those Regions. This is necessary to record any AWS STS API calls that are made in those Regions. For more information, see <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/aggregating_logs_regions_turn_on_ct.html">Turning On CloudTrail in Additional Regions</a> in the <i>AWS CloudTrail User Guide</i>.</p> <p>AWS Security Token Service (STS) is a global service with a single endpoint at <code>https://sts.amazonaws.com</code>. Calls to this endpoint are logged as calls to a global service. However, because this endpoint is physically located in the US East (N. Virginia) Region, your logs list <code>us-east-1</code> as the event Region. CloudTrail does not write these logs to the US East (Ohio) Region unless you choose to include global service logs in that Region. CloudTrail writes calls to all Regional endpoints to their respective Regions. For example, calls to sts.us-east-2.amazonaws.com are published to the US East (Ohio) Region and calls to sts.eu-central-1.amazonaws.com are published to the EU (Frankfurt) Region.</p> <p>To learn more about CloudTrail, including how to turn it on and find your log files, see the <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/what_is_cloud_trail_top_level.html">AWS CloudTrail User Guide</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/sts/
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
  awsServers = {Scheme.Http: {"cn-northwest-1": "sts.cn-northwest-1.amazonaws.com.cn",
                           "us-gov-east-1": "sts.us-gov-east-1.amazonaws.com",
                           "cn-north-1": "sts.cn-north-1.amazonaws.com.cn",
                           "us-gov-west-1": "sts.us-gov-west-1.amazonaws.com"}.toTable, Scheme.Https: {
      "cn-northwest-1": "sts.cn-northwest-1.amazonaws.com.cn",
      "us-gov-east-1": "sts.us-gov-east-1.amazonaws.com",
      "cn-north-1": "sts.cn-north-1.amazonaws.com.cn",
      "us-gov-west-1": "sts.us-gov-west-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "sts"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAssumeRole_599985 = ref object of OpenApiRestCall_599368
proc url_PostAssumeRole_599987(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAssumeRole_599986(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns a set of temporary security credentials that you can use to access AWS resources that you might not normally have access to. These temporary credentials consist of an access key ID, a secret access key, and a security token. Typically, you use <code>AssumeRole</code> within your account or for cross-account access. For a comparison of <code>AssumeRole</code> with other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <important> <p>You cannot use AWS account root user credentials to call <code>AssumeRole</code>. You must use credentials for an IAM user or an IAM role to call <code>AssumeRole</code>.</p> </important> <p>For cross-account access, imagine that you own multiple accounts and need to access resources in each account. You could create long-term credentials in each account to access those resources. However, managing all those credentials and remembering which one can access which account can be time consuming. Instead, you can create one set of long-term credentials in one account. Then use temporary security credentials to access all the other accounts by assuming roles in those accounts. For more information about roles, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html">IAM Roles</a> in the <i>IAM User Guide</i>. </p> <p> <b>Session Duration</b> </p> <p>By default, the temporary security credentials created by <code>AssumeRole</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. You can provide a value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>.</p> <p> <b>Permissions</b> </p> <p>The temporary security credentials created by <code>AssumeRole</code> can be used to make API calls to any AWS service with the following exception: You cannot call the AWS STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>To assume a role from a different account, your AWS account must be trusted by the role. The trust relationship is defined in the role's trust policy when the role is created. That trust policy states which accounts are allowed to delegate that access to users in the account. </p> <p>A user who wants to access a role in a different account must also have permissions that are delegated from the user account administrator. The administrator must attach a policy that allows the user to call <code>AssumeRole</code> for the ARN of the role in the other account. If the user is in the same account as the role, then you can do either of the following:</p> <ul> <li> <p>Attach a policy to the user (identical to the previous user in a different account).</p> </li> <li> <p>Add the user as a principal directly in the role's trust policy.</p> </li> </ul> <p>In this case, the trust policy acts as an IAM resource-based policy. Users in the same account as the role do not need explicit permission to assume the role. For more information about trust policies and resource-based policies, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html">IAM Policies</a> in the <i>IAM User Guide</i>.</p> <p> <b>Tags</b> </p> <p>(Optional) You can pass tag key-value pairs to your session. These tags are called session tags. For more information about session tags, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Passing Session Tags in STS</a> in the <i>IAM User Guide</i>.</p> <p>An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html">Tutorial: Using Tags for Attribute-Based Access Control</a> in the <i>IAM User Guide</i>.</p> <p>You can set the session tags as transitive. Transitive tags persist during role chaining. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining">Chaining Roles with Session Tags</a> in the <i>IAM User Guide</i>.</p> <p> <b>Using MFA with AssumeRole</b> </p> <p>(Optional) You can include multi-factor authentication (MFA) information when you call <code>AssumeRole</code>. This is useful for cross-account scenarios to ensure that the user that assumes the role has been authenticated with an AWS MFA device. In that scenario, the trust policy of the role being assumed includes a condition that tests for MFA authentication. If the caller does not include valid MFA information, the request to assume the role is denied. The condition in a trust policy that tests for MFA authentication might look like the following example.</p> <p> <code>"Condition": {"Bool": {"aws:MultiFactorAuthPresent": true}}</code> </p> <p>For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/MFAProtectedAPI.html">Configuring MFA-Protected API Access</a> in the <i>IAM User Guide</i> guide.</p> <p>To use MFA with <code>AssumeRole</code>, you pass values for the <code>SerialNumber</code> and <code>TokenCode</code> parameters. The <code>SerialNumber</code> value identifies the user's hardware or virtual MFA device. The <code>TokenCode</code> is the time-based one-time password (TOTP) that the MFA device produces. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_599988 = query.getOrDefault("Action")
  valid_599988 = validateParameter(valid_599988, JString, required = true,
                                 default = newJString("AssumeRole"))
  if valid_599988 != nil:
    section.add "Action", valid_599988
  var valid_599989 = query.getOrDefault("Version")
  valid_599989 = validateParameter(valid_599989, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_599989 != nil:
    section.add "Version", valid_599989
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599990 = header.getOrDefault("X-Amz-Date")
  valid_599990 = validateParameter(valid_599990, JString, required = false,
                                 default = nil)
  if valid_599990 != nil:
    section.add "X-Amz-Date", valid_599990
  var valid_599991 = header.getOrDefault("X-Amz-Security-Token")
  valid_599991 = validateParameter(valid_599991, JString, required = false,
                                 default = nil)
  if valid_599991 != nil:
    section.add "X-Amz-Security-Token", valid_599991
  var valid_599992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Content-Sha256", valid_599992
  var valid_599993 = header.getOrDefault("X-Amz-Algorithm")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Algorithm", valid_599993
  var valid_599994 = header.getOrDefault("X-Amz-Signature")
  valid_599994 = validateParameter(valid_599994, JString, required = false,
                                 default = nil)
  if valid_599994 != nil:
    section.add "X-Amz-Signature", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-SignedHeaders", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Credential")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Credential", valid_599996
  result.add "header", section
  ## parameters in `formData` object:
  ##   SerialNumber: JString
  ##               : <p>The identification number of the MFA device that is associated with the user who is making the <code>AssumeRole</code> call. Specify this value if the trust policy of the role being assumed includes a condition that requires MFA authentication. The value is either the serial number for a hardware device (such as <code>GAHT12345678</code>) or an Amazon Resource Name (ARN) for a virtual device (such as <code>arn:aws:iam::123456789012:mfa/user</code>).</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-</p>
  ##   Tags: JArray
  ##       : <p>A list of session tags that you want to pass. Each session tag consists of a key name and an associated value. For more information about session tags, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Tagging AWS STS Sessions</a> in the <i>IAM User Guide</i>.</p> <p>This parameter is optional. You can pass up to 50 session tags. The plain text session tag keys can’t exceed 128 characters, and the values can’t exceed 256 characters. For these and additional limits, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length">IAM and STS Character Limits</a> in the <i>IAM User Guide</i>.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>You can pass a session tag with the same key as a tag that is already attached to the role. When you do, session tags override a role tag with the same key. </p> <p>Tag key–value pairs are not case sensitive, but case is preserved. This means that you cannot have separate <code>Department</code> and <code>department</code> tag keys. Assume that the role has the <code>Department</code>=<code>Marketing</code> tag and you pass the <code>department</code>=<code>engineering</code> session tag. <code>Department</code> and <code>department</code> are not saved as separate tags, and the session tag passed in the request takes precedence over the role tag.</p> <p>Additionally, if you used temporary credentials to perform this operation, the new session inherits any transitive session tags from the calling session. If you pass a session tag with the same key as an inherited tag, the operation fails. To view the inherited tags for a session, see the AWS CloudTrail logs. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/session-tags.html#id_session-tags_ctlogs">Viewing Session Tags in CloudTrail</a> in the <i>IAM User Guide</i>.</p>
  ##   TransitiveTagKeys: JArray
  ##                    : <p>A list of keys for session tags that you want to set as transitive. If you set a tag key as transitive, the corresponding key and value passes to subsequent sessions in a role chain. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining">Chaining Roles with Session Tags</a> in the <i>IAM User Guide</i>.</p> <p>This parameter is optional. When you set session tags as transitive, the session policy and session tags packed binary limit is not affected.</p> <p>If you choose not to specify a transitive tag key, then no tags are passed from this session to any subsequent sessions.</p>
  ##   RoleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the role to assume.
  ##   PolicyArns: JArray
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as managed session policies. The policies must exist in the same account as the role.</p> <p>This parameter is optional. You can provide up to 10 managed policy ARNs. However, the plain text that you use for both inline and managed session policies can't exceed 2,048 characters. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p>
  ##   ExternalId: JString
  ##             : <p>A unique identifier that might be required when you assume a role in another account. If the administrator of the account to which the role belongs provided you with an external ID, then provide that value in the <code>ExternalId</code> parameter. This value can be any string, such as a passphrase or account number. A cross-account role is usually set up to trust everyone in an account. Therefore, the administrator of the trusting account might send an external ID to the administrator of the trusted account. That way, only someone with the ID can assume the role, rather than everyone in the account. For more information about the external ID, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user_externalid.html">How to Use an External ID When Granting Access to Your AWS Resources to a Third Party</a> in the <i>IAM User Guide</i>.</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@:/-</p>
  ##   RoleSessionName: JString (required)
  ##                  : <p>An identifier for the assumed role session.</p> <p>Use the role session name to uniquely identify a session when the same role is assumed by different principals or for different reasons. In cross-account scenarios, the role session name is visible to, and can be logged by the account that owns the role. The role session name is also used in the ARN of the assumed role principal. This means that subsequent cross-account API requests that use the temporary security credentials will expose the role session name to the external account in their AWS CloudTrail logs.</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-</p>
  ##   Policy: JString
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>This parameter is optional. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note>
  ##   TokenCode: JString
  ##            : <p>The value provided by the MFA device, if the trust policy of the role being assumed requires MFA (that is, if the policy includes a condition that tests for MFA). If the role being assumed requires MFA and if the <code>TokenCode</code> value is missing or expired, the <code>AssumeRole</code> call returns an "access denied" error.</p> <p>The format for this parameter, as described by its regex pattern, is a sequence of six numeric digits.</p>
  ##   DurationSeconds: JInt
  ##                  : <p>The duration, in seconds, of the role session. The value can range from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. If you specify a value higher than this setting, the operation fails. For example, if you specify a session duration of 12 hours, but your administrator set the maximum session duration to 6 hours, your operation fails. To learn how to view the maximum value for your role, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>.</p> <p>By default, the value is set to <code>3600</code> seconds. </p> <note> <p>The <code>DurationSeconds</code> parameter is separate from the duration of a console session that you might request using the returned credentials. The request to the federation endpoint for a console sign-in token takes a <code>SessionDuration</code> parameter that specifies the maximum length of the console session. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html">Creating a URL that Enables Federated Users to Access the AWS Management Console</a> in the <i>IAM User Guide</i>.</p> </note>
  section = newJObject()
  var valid_599997 = formData.getOrDefault("SerialNumber")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "SerialNumber", valid_599997
  var valid_599998 = formData.getOrDefault("Tags")
  valid_599998 = validateParameter(valid_599998, JArray, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "Tags", valid_599998
  var valid_599999 = formData.getOrDefault("TransitiveTagKeys")
  valid_599999 = validateParameter(valid_599999, JArray, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "TransitiveTagKeys", valid_599999
  assert formData != nil,
        "formData argument is necessary due to required `RoleArn` field"
  var valid_600000 = formData.getOrDefault("RoleArn")
  valid_600000 = validateParameter(valid_600000, JString, required = true,
                                 default = nil)
  if valid_600000 != nil:
    section.add "RoleArn", valid_600000
  var valid_600001 = formData.getOrDefault("PolicyArns")
  valid_600001 = validateParameter(valid_600001, JArray, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "PolicyArns", valid_600001
  var valid_600002 = formData.getOrDefault("ExternalId")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "ExternalId", valid_600002
  var valid_600003 = formData.getOrDefault("RoleSessionName")
  valid_600003 = validateParameter(valid_600003, JString, required = true,
                                 default = nil)
  if valid_600003 != nil:
    section.add "RoleSessionName", valid_600003
  var valid_600004 = formData.getOrDefault("Policy")
  valid_600004 = validateParameter(valid_600004, JString, required = false,
                                 default = nil)
  if valid_600004 != nil:
    section.add "Policy", valid_600004
  var valid_600005 = formData.getOrDefault("TokenCode")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "TokenCode", valid_600005
  var valid_600006 = formData.getOrDefault("DurationSeconds")
  valid_600006 = validateParameter(valid_600006, JInt, required = false, default = nil)
  if valid_600006 != nil:
    section.add "DurationSeconds", valid_600006
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600007: Call_PostAssumeRole_599985; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a set of temporary security credentials that you can use to access AWS resources that you might not normally have access to. These temporary credentials consist of an access key ID, a secret access key, and a security token. Typically, you use <code>AssumeRole</code> within your account or for cross-account access. For a comparison of <code>AssumeRole</code> with other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <important> <p>You cannot use AWS account root user credentials to call <code>AssumeRole</code>. You must use credentials for an IAM user or an IAM role to call <code>AssumeRole</code>.</p> </important> <p>For cross-account access, imagine that you own multiple accounts and need to access resources in each account. You could create long-term credentials in each account to access those resources. However, managing all those credentials and remembering which one can access which account can be time consuming. Instead, you can create one set of long-term credentials in one account. Then use temporary security credentials to access all the other accounts by assuming roles in those accounts. For more information about roles, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html">IAM Roles</a> in the <i>IAM User Guide</i>. </p> <p> <b>Session Duration</b> </p> <p>By default, the temporary security credentials created by <code>AssumeRole</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. You can provide a value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>.</p> <p> <b>Permissions</b> </p> <p>The temporary security credentials created by <code>AssumeRole</code> can be used to make API calls to any AWS service with the following exception: You cannot call the AWS STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>To assume a role from a different account, your AWS account must be trusted by the role. The trust relationship is defined in the role's trust policy when the role is created. That trust policy states which accounts are allowed to delegate that access to users in the account. </p> <p>A user who wants to access a role in a different account must also have permissions that are delegated from the user account administrator. The administrator must attach a policy that allows the user to call <code>AssumeRole</code> for the ARN of the role in the other account. If the user is in the same account as the role, then you can do either of the following:</p> <ul> <li> <p>Attach a policy to the user (identical to the previous user in a different account).</p> </li> <li> <p>Add the user as a principal directly in the role's trust policy.</p> </li> </ul> <p>In this case, the trust policy acts as an IAM resource-based policy. Users in the same account as the role do not need explicit permission to assume the role. For more information about trust policies and resource-based policies, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html">IAM Policies</a> in the <i>IAM User Guide</i>.</p> <p> <b>Tags</b> </p> <p>(Optional) You can pass tag key-value pairs to your session. These tags are called session tags. For more information about session tags, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Passing Session Tags in STS</a> in the <i>IAM User Guide</i>.</p> <p>An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html">Tutorial: Using Tags for Attribute-Based Access Control</a> in the <i>IAM User Guide</i>.</p> <p>You can set the session tags as transitive. Transitive tags persist during role chaining. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining">Chaining Roles with Session Tags</a> in the <i>IAM User Guide</i>.</p> <p> <b>Using MFA with AssumeRole</b> </p> <p>(Optional) You can include multi-factor authentication (MFA) information when you call <code>AssumeRole</code>. This is useful for cross-account scenarios to ensure that the user that assumes the role has been authenticated with an AWS MFA device. In that scenario, the trust policy of the role being assumed includes a condition that tests for MFA authentication. If the caller does not include valid MFA information, the request to assume the role is denied. The condition in a trust policy that tests for MFA authentication might look like the following example.</p> <p> <code>"Condition": {"Bool": {"aws:MultiFactorAuthPresent": true}}</code> </p> <p>For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/MFAProtectedAPI.html">Configuring MFA-Protected API Access</a> in the <i>IAM User Guide</i> guide.</p> <p>To use MFA with <code>AssumeRole</code>, you pass values for the <code>SerialNumber</code> and <code>TokenCode</code> parameters. The <code>SerialNumber</code> value identifies the user's hardware or virtual MFA device. The <code>TokenCode</code> is the time-based one-time password (TOTP) that the MFA device produces. </p>
  ## 
  let valid = call_600007.validator(path, query, header, formData, body)
  let scheme = call_600007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600007.url(scheme.get, call_600007.host, call_600007.base,
                         call_600007.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600007, url, valid)

proc call*(call_600008: Call_PostAssumeRole_599985; RoleArn: string;
          RoleSessionName: string; SerialNumber: string = ""; Tags: JsonNode = nil;
          TransitiveTagKeys: JsonNode = nil; Action: string = "AssumeRole";
          PolicyArns: JsonNode = nil; ExternalId: string = ""; Policy: string = "";
          Version: string = "2011-06-15"; TokenCode: string = "";
          DurationSeconds: int = 0): Recallable =
  ## postAssumeRole
  ## <p>Returns a set of temporary security credentials that you can use to access AWS resources that you might not normally have access to. These temporary credentials consist of an access key ID, a secret access key, and a security token. Typically, you use <code>AssumeRole</code> within your account or for cross-account access. For a comparison of <code>AssumeRole</code> with other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <important> <p>You cannot use AWS account root user credentials to call <code>AssumeRole</code>. You must use credentials for an IAM user or an IAM role to call <code>AssumeRole</code>.</p> </important> <p>For cross-account access, imagine that you own multiple accounts and need to access resources in each account. You could create long-term credentials in each account to access those resources. However, managing all those credentials and remembering which one can access which account can be time consuming. Instead, you can create one set of long-term credentials in one account. Then use temporary security credentials to access all the other accounts by assuming roles in those accounts. For more information about roles, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html">IAM Roles</a> in the <i>IAM User Guide</i>. </p> <p> <b>Session Duration</b> </p> <p>By default, the temporary security credentials created by <code>AssumeRole</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. You can provide a value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>.</p> <p> <b>Permissions</b> </p> <p>The temporary security credentials created by <code>AssumeRole</code> can be used to make API calls to any AWS service with the following exception: You cannot call the AWS STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>To assume a role from a different account, your AWS account must be trusted by the role. The trust relationship is defined in the role's trust policy when the role is created. That trust policy states which accounts are allowed to delegate that access to users in the account. </p> <p>A user who wants to access a role in a different account must also have permissions that are delegated from the user account administrator. The administrator must attach a policy that allows the user to call <code>AssumeRole</code> for the ARN of the role in the other account. If the user is in the same account as the role, then you can do either of the following:</p> <ul> <li> <p>Attach a policy to the user (identical to the previous user in a different account).</p> </li> <li> <p>Add the user as a principal directly in the role's trust policy.</p> </li> </ul> <p>In this case, the trust policy acts as an IAM resource-based policy. Users in the same account as the role do not need explicit permission to assume the role. For more information about trust policies and resource-based policies, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html">IAM Policies</a> in the <i>IAM User Guide</i>.</p> <p> <b>Tags</b> </p> <p>(Optional) You can pass tag key-value pairs to your session. These tags are called session tags. For more information about session tags, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Passing Session Tags in STS</a> in the <i>IAM User Guide</i>.</p> <p>An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html">Tutorial: Using Tags for Attribute-Based Access Control</a> in the <i>IAM User Guide</i>.</p> <p>You can set the session tags as transitive. Transitive tags persist during role chaining. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining">Chaining Roles with Session Tags</a> in the <i>IAM User Guide</i>.</p> <p> <b>Using MFA with AssumeRole</b> </p> <p>(Optional) You can include multi-factor authentication (MFA) information when you call <code>AssumeRole</code>. This is useful for cross-account scenarios to ensure that the user that assumes the role has been authenticated with an AWS MFA device. In that scenario, the trust policy of the role being assumed includes a condition that tests for MFA authentication. If the caller does not include valid MFA information, the request to assume the role is denied. The condition in a trust policy that tests for MFA authentication might look like the following example.</p> <p> <code>"Condition": {"Bool": {"aws:MultiFactorAuthPresent": true}}</code> </p> <p>For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/MFAProtectedAPI.html">Configuring MFA-Protected API Access</a> in the <i>IAM User Guide</i> guide.</p> <p>To use MFA with <code>AssumeRole</code>, you pass values for the <code>SerialNumber</code> and <code>TokenCode</code> parameters. The <code>SerialNumber</code> value identifies the user's hardware or virtual MFA device. The <code>TokenCode</code> is the time-based one-time password (TOTP) that the MFA device produces. </p>
  ##   SerialNumber: string
  ##               : <p>The identification number of the MFA device that is associated with the user who is making the <code>AssumeRole</code> call. Specify this value if the trust policy of the role being assumed includes a condition that requires MFA authentication. The value is either the serial number for a hardware device (such as <code>GAHT12345678</code>) or an Amazon Resource Name (ARN) for a virtual device (such as <code>arn:aws:iam::123456789012:mfa/user</code>).</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-</p>
  ##   Tags: JArray
  ##       : <p>A list of session tags that you want to pass. Each session tag consists of a key name and an associated value. For more information about session tags, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Tagging AWS STS Sessions</a> in the <i>IAM User Guide</i>.</p> <p>This parameter is optional. You can pass up to 50 session tags. The plain text session tag keys can’t exceed 128 characters, and the values can’t exceed 256 characters. For these and additional limits, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length">IAM and STS Character Limits</a> in the <i>IAM User Guide</i>.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>You can pass a session tag with the same key as a tag that is already attached to the role. When you do, session tags override a role tag with the same key. </p> <p>Tag key–value pairs are not case sensitive, but case is preserved. This means that you cannot have separate <code>Department</code> and <code>department</code> tag keys. Assume that the role has the <code>Department</code>=<code>Marketing</code> tag and you pass the <code>department</code>=<code>engineering</code> session tag. <code>Department</code> and <code>department</code> are not saved as separate tags, and the session tag passed in the request takes precedence over the role tag.</p> <p>Additionally, if you used temporary credentials to perform this operation, the new session inherits any transitive session tags from the calling session. If you pass a session tag with the same key as an inherited tag, the operation fails. To view the inherited tags for a session, see the AWS CloudTrail logs. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/session-tags.html#id_session-tags_ctlogs">Viewing Session Tags in CloudTrail</a> in the <i>IAM User Guide</i>.</p>
  ##   TransitiveTagKeys: JArray
  ##                    : <p>A list of keys for session tags that you want to set as transitive. If you set a tag key as transitive, the corresponding key and value passes to subsequent sessions in a role chain. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining">Chaining Roles with Session Tags</a> in the <i>IAM User Guide</i>.</p> <p>This parameter is optional. When you set session tags as transitive, the session policy and session tags packed binary limit is not affected.</p> <p>If you choose not to specify a transitive tag key, then no tags are passed from this session to any subsequent sessions.</p>
  ##   RoleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the role to assume.
  ##   Action: string (required)
  ##   PolicyArns: JArray
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as managed session policies. The policies must exist in the same account as the role.</p> <p>This parameter is optional. You can provide up to 10 managed policy ARNs. However, the plain text that you use for both inline and managed session policies can't exceed 2,048 characters. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p>
  ##   ExternalId: string
  ##             : <p>A unique identifier that might be required when you assume a role in another account. If the administrator of the account to which the role belongs provided you with an external ID, then provide that value in the <code>ExternalId</code> parameter. This value can be any string, such as a passphrase or account number. A cross-account role is usually set up to trust everyone in an account. Therefore, the administrator of the trusting account might send an external ID to the administrator of the trusted account. That way, only someone with the ID can assume the role, rather than everyone in the account. For more information about the external ID, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user_externalid.html">How to Use an External ID When Granting Access to Your AWS Resources to a Third Party</a> in the <i>IAM User Guide</i>.</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@:/-</p>
  ##   RoleSessionName: string (required)
  ##                  : <p>An identifier for the assumed role session.</p> <p>Use the role session name to uniquely identify a session when the same role is assumed by different principals or for different reasons. In cross-account scenarios, the role session name is visible to, and can be logged by the account that owns the role. The role session name is also used in the ARN of the assumed role principal. This means that subsequent cross-account API requests that use the temporary security credentials will expose the role session name to the external account in their AWS CloudTrail logs.</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-</p>
  ##   Policy: string
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>This parameter is optional. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note>
  ##   Version: string (required)
  ##   TokenCode: string
  ##            : <p>The value provided by the MFA device, if the trust policy of the role being assumed requires MFA (that is, if the policy includes a condition that tests for MFA). If the role being assumed requires MFA and if the <code>TokenCode</code> value is missing or expired, the <code>AssumeRole</code> call returns an "access denied" error.</p> <p>The format for this parameter, as described by its regex pattern, is a sequence of six numeric digits.</p>
  ##   DurationSeconds: int
  ##                  : <p>The duration, in seconds, of the role session. The value can range from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. If you specify a value higher than this setting, the operation fails. For example, if you specify a session duration of 12 hours, but your administrator set the maximum session duration to 6 hours, your operation fails. To learn how to view the maximum value for your role, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>.</p> <p>By default, the value is set to <code>3600</code> seconds. </p> <note> <p>The <code>DurationSeconds</code> parameter is separate from the duration of a console session that you might request using the returned credentials. The request to the federation endpoint for a console sign-in token takes a <code>SessionDuration</code> parameter that specifies the maximum length of the console session. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html">Creating a URL that Enables Federated Users to Access the AWS Management Console</a> in the <i>IAM User Guide</i>.</p> </note>
  var query_600009 = newJObject()
  var formData_600010 = newJObject()
  add(formData_600010, "SerialNumber", newJString(SerialNumber))
  if Tags != nil:
    formData_600010.add "Tags", Tags
  if TransitiveTagKeys != nil:
    formData_600010.add "TransitiveTagKeys", TransitiveTagKeys
  add(formData_600010, "RoleArn", newJString(RoleArn))
  add(query_600009, "Action", newJString(Action))
  if PolicyArns != nil:
    formData_600010.add "PolicyArns", PolicyArns
  add(formData_600010, "ExternalId", newJString(ExternalId))
  add(formData_600010, "RoleSessionName", newJString(RoleSessionName))
  add(formData_600010, "Policy", newJString(Policy))
  add(query_600009, "Version", newJString(Version))
  add(formData_600010, "TokenCode", newJString(TokenCode))
  add(formData_600010, "DurationSeconds", newJInt(DurationSeconds))
  result = call_600008.call(nil, query_600009, nil, formData_600010, nil)

var postAssumeRole* = Call_PostAssumeRole_599985(name: "postAssumeRole",
    meth: HttpMethod.HttpPost, host: "sts.amazonaws.com",
    route: "/#Action=AssumeRole", validator: validate_PostAssumeRole_599986,
    base: "/", url: url_PostAssumeRole_599987, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssumeRole_599705 = ref object of OpenApiRestCall_599368
proc url_GetAssumeRole_599707(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAssumeRole_599706(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a set of temporary security credentials that you can use to access AWS resources that you might not normally have access to. These temporary credentials consist of an access key ID, a secret access key, and a security token. Typically, you use <code>AssumeRole</code> within your account or for cross-account access. For a comparison of <code>AssumeRole</code> with other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <important> <p>You cannot use AWS account root user credentials to call <code>AssumeRole</code>. You must use credentials for an IAM user or an IAM role to call <code>AssumeRole</code>.</p> </important> <p>For cross-account access, imagine that you own multiple accounts and need to access resources in each account. You could create long-term credentials in each account to access those resources. However, managing all those credentials and remembering which one can access which account can be time consuming. Instead, you can create one set of long-term credentials in one account. Then use temporary security credentials to access all the other accounts by assuming roles in those accounts. For more information about roles, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html">IAM Roles</a> in the <i>IAM User Guide</i>. </p> <p> <b>Session Duration</b> </p> <p>By default, the temporary security credentials created by <code>AssumeRole</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. You can provide a value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>.</p> <p> <b>Permissions</b> </p> <p>The temporary security credentials created by <code>AssumeRole</code> can be used to make API calls to any AWS service with the following exception: You cannot call the AWS STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>To assume a role from a different account, your AWS account must be trusted by the role. The trust relationship is defined in the role's trust policy when the role is created. That trust policy states which accounts are allowed to delegate that access to users in the account. </p> <p>A user who wants to access a role in a different account must also have permissions that are delegated from the user account administrator. The administrator must attach a policy that allows the user to call <code>AssumeRole</code> for the ARN of the role in the other account. If the user is in the same account as the role, then you can do either of the following:</p> <ul> <li> <p>Attach a policy to the user (identical to the previous user in a different account).</p> </li> <li> <p>Add the user as a principal directly in the role's trust policy.</p> </li> </ul> <p>In this case, the trust policy acts as an IAM resource-based policy. Users in the same account as the role do not need explicit permission to assume the role. For more information about trust policies and resource-based policies, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html">IAM Policies</a> in the <i>IAM User Guide</i>.</p> <p> <b>Tags</b> </p> <p>(Optional) You can pass tag key-value pairs to your session. These tags are called session tags. For more information about session tags, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Passing Session Tags in STS</a> in the <i>IAM User Guide</i>.</p> <p>An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html">Tutorial: Using Tags for Attribute-Based Access Control</a> in the <i>IAM User Guide</i>.</p> <p>You can set the session tags as transitive. Transitive tags persist during role chaining. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining">Chaining Roles with Session Tags</a> in the <i>IAM User Guide</i>.</p> <p> <b>Using MFA with AssumeRole</b> </p> <p>(Optional) You can include multi-factor authentication (MFA) information when you call <code>AssumeRole</code>. This is useful for cross-account scenarios to ensure that the user that assumes the role has been authenticated with an AWS MFA device. In that scenario, the trust policy of the role being assumed includes a condition that tests for MFA authentication. If the caller does not include valid MFA information, the request to assume the role is denied. The condition in a trust policy that tests for MFA authentication might look like the following example.</p> <p> <code>"Condition": {"Bool": {"aws:MultiFactorAuthPresent": true}}</code> </p> <p>For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/MFAProtectedAPI.html">Configuring MFA-Protected API Access</a> in the <i>IAM User Guide</i> guide.</p> <p>To use MFA with <code>AssumeRole</code>, you pass values for the <code>SerialNumber</code> and <code>TokenCode</code> parameters. The <code>SerialNumber</code> value identifies the user's hardware or virtual MFA device. The <code>TokenCode</code> is the time-based one-time password (TOTP) that the MFA device produces. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   TransitiveTagKeys: JArray
  ##                    : <p>A list of keys for session tags that you want to set as transitive. If you set a tag key as transitive, the corresponding key and value passes to subsequent sessions in a role chain. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining">Chaining Roles with Session Tags</a> in the <i>IAM User Guide</i>.</p> <p>This parameter is optional. When you set session tags as transitive, the session policy and session tags packed binary limit is not affected.</p> <p>If you choose not to specify a transitive tag key, then no tags are passed from this session to any subsequent sessions.</p>
  ##   TokenCode: JString
  ##            : <p>The value provided by the MFA device, if the trust policy of the role being assumed requires MFA (that is, if the policy includes a condition that tests for MFA). If the role being assumed requires MFA and if the <code>TokenCode</code> value is missing or expired, the <code>AssumeRole</code> call returns an "access denied" error.</p> <p>The format for this parameter, as described by its regex pattern, is a sequence of six numeric digits.</p>
  ##   SerialNumber: JString
  ##               : <p>The identification number of the MFA device that is associated with the user who is making the <code>AssumeRole</code> call. Specify this value if the trust policy of the role being assumed includes a condition that requires MFA authentication. The value is either the serial number for a hardware device (such as <code>GAHT12345678</code>) or an Amazon Resource Name (ARN) for a virtual device (such as <code>arn:aws:iam::123456789012:mfa/user</code>).</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-</p>
  ##   RoleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the role to assume.
  ##   DurationSeconds: JInt
  ##                  : <p>The duration, in seconds, of the role session. The value can range from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. If you specify a value higher than this setting, the operation fails. For example, if you specify a session duration of 12 hours, but your administrator set the maximum session duration to 6 hours, your operation fails. To learn how to view the maximum value for your role, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>.</p> <p>By default, the value is set to <code>3600</code> seconds. </p> <note> <p>The <code>DurationSeconds</code> parameter is separate from the duration of a console session that you might request using the returned credentials. The request to the federation endpoint for a console sign-in token takes a <code>SessionDuration</code> parameter that specifies the maximum length of the console session. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html">Creating a URL that Enables Federated Users to Access the AWS Management Console</a> in the <i>IAM User Guide</i>.</p> </note>
  ##   RoleSessionName: JString (required)
  ##                  : <p>An identifier for the assumed role session.</p> <p>Use the role session name to uniquely identify a session when the same role is assumed by different principals or for different reasons. In cross-account scenarios, the role session name is visible to, and can be logged by the account that owns the role. The role session name is also used in the ARN of the assumed role principal. This means that subsequent cross-account API requests that use the temporary security credentials will expose the role session name to the external account in their AWS CloudTrail logs.</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-</p>
  ##   Tags: JArray
  ##       : <p>A list of session tags that you want to pass. Each session tag consists of a key name and an associated value. For more information about session tags, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Tagging AWS STS Sessions</a> in the <i>IAM User Guide</i>.</p> <p>This parameter is optional. You can pass up to 50 session tags. The plain text session tag keys can’t exceed 128 characters, and the values can’t exceed 256 characters. For these and additional limits, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length">IAM and STS Character Limits</a> in the <i>IAM User Guide</i>.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>You can pass a session tag with the same key as a tag that is already attached to the role. When you do, session tags override a role tag with the same key. </p> <p>Tag key–value pairs are not case sensitive, but case is preserved. This means that you cannot have separate <code>Department</code> and <code>department</code> tag keys. Assume that the role has the <code>Department</code>=<code>Marketing</code> tag and you pass the <code>department</code>=<code>engineering</code> session tag. <code>Department</code> and <code>department</code> are not saved as separate tags, and the session tag passed in the request takes precedence over the role tag.</p> <p>Additionally, if you used temporary credentials to perform this operation, the new session inherits any transitive session tags from the calling session. If you pass a session tag with the same key as an inherited tag, the operation fails. To view the inherited tags for a session, see the AWS CloudTrail logs. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/session-tags.html#id_session-tags_ctlogs">Viewing Session Tags in CloudTrail</a> in the <i>IAM User Guide</i>.</p>
  ##   PolicyArns: JArray
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as managed session policies. The policies must exist in the same account as the role.</p> <p>This parameter is optional. You can provide up to 10 managed policy ARNs. However, the plain text that you use for both inline and managed session policies can't exceed 2,048 characters. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p>
  ##   Action: JString (required)
  ##   Policy: JString
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>This parameter is optional. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note>
  ##   ExternalId: JString
  ##             : <p>A unique identifier that might be required when you assume a role in another account. If the administrator of the account to which the role belongs provided you with an external ID, then provide that value in the <code>ExternalId</code> parameter. This value can be any string, such as a passphrase or account number. A cross-account role is usually set up to trust everyone in an account. Therefore, the administrator of the trusting account might send an external ID to the administrator of the trusted account. That way, only someone with the ID can assume the role, rather than everyone in the account. For more information about the external ID, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user_externalid.html">How to Use an External ID When Granting Access to Your AWS Resources to a Third Party</a> in the <i>IAM User Guide</i>.</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@:/-</p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_599819 = query.getOrDefault("TransitiveTagKeys")
  valid_599819 = validateParameter(valid_599819, JArray, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "TransitiveTagKeys", valid_599819
  var valid_599820 = query.getOrDefault("TokenCode")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "TokenCode", valid_599820
  var valid_599821 = query.getOrDefault("SerialNumber")
  valid_599821 = validateParameter(valid_599821, JString, required = false,
                                 default = nil)
  if valid_599821 != nil:
    section.add "SerialNumber", valid_599821
  assert query != nil, "query argument is necessary due to required `RoleArn` field"
  var valid_599822 = query.getOrDefault("RoleArn")
  valid_599822 = validateParameter(valid_599822, JString, required = true,
                                 default = nil)
  if valid_599822 != nil:
    section.add "RoleArn", valid_599822
  var valid_599823 = query.getOrDefault("DurationSeconds")
  valid_599823 = validateParameter(valid_599823, JInt, required = false, default = nil)
  if valid_599823 != nil:
    section.add "DurationSeconds", valid_599823
  var valid_599824 = query.getOrDefault("RoleSessionName")
  valid_599824 = validateParameter(valid_599824, JString, required = true,
                                 default = nil)
  if valid_599824 != nil:
    section.add "RoleSessionName", valid_599824
  var valid_599825 = query.getOrDefault("Tags")
  valid_599825 = validateParameter(valid_599825, JArray, required = false,
                                 default = nil)
  if valid_599825 != nil:
    section.add "Tags", valid_599825
  var valid_599826 = query.getOrDefault("PolicyArns")
  valid_599826 = validateParameter(valid_599826, JArray, required = false,
                                 default = nil)
  if valid_599826 != nil:
    section.add "PolicyArns", valid_599826
  var valid_599840 = query.getOrDefault("Action")
  valid_599840 = validateParameter(valid_599840, JString, required = true,
                                 default = newJString("AssumeRole"))
  if valid_599840 != nil:
    section.add "Action", valid_599840
  var valid_599841 = query.getOrDefault("Policy")
  valid_599841 = validateParameter(valid_599841, JString, required = false,
                                 default = nil)
  if valid_599841 != nil:
    section.add "Policy", valid_599841
  var valid_599842 = query.getOrDefault("ExternalId")
  valid_599842 = validateParameter(valid_599842, JString, required = false,
                                 default = nil)
  if valid_599842 != nil:
    section.add "ExternalId", valid_599842
  var valid_599843 = query.getOrDefault("Version")
  valid_599843 = validateParameter(valid_599843, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_599843 != nil:
    section.add "Version", valid_599843
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599844 = header.getOrDefault("X-Amz-Date")
  valid_599844 = validateParameter(valid_599844, JString, required = false,
                                 default = nil)
  if valid_599844 != nil:
    section.add "X-Amz-Date", valid_599844
  var valid_599845 = header.getOrDefault("X-Amz-Security-Token")
  valid_599845 = validateParameter(valid_599845, JString, required = false,
                                 default = nil)
  if valid_599845 != nil:
    section.add "X-Amz-Security-Token", valid_599845
  var valid_599846 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599846 = validateParameter(valid_599846, JString, required = false,
                                 default = nil)
  if valid_599846 != nil:
    section.add "X-Amz-Content-Sha256", valid_599846
  var valid_599847 = header.getOrDefault("X-Amz-Algorithm")
  valid_599847 = validateParameter(valid_599847, JString, required = false,
                                 default = nil)
  if valid_599847 != nil:
    section.add "X-Amz-Algorithm", valid_599847
  var valid_599848 = header.getOrDefault("X-Amz-Signature")
  valid_599848 = validateParameter(valid_599848, JString, required = false,
                                 default = nil)
  if valid_599848 != nil:
    section.add "X-Amz-Signature", valid_599848
  var valid_599849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599849 = validateParameter(valid_599849, JString, required = false,
                                 default = nil)
  if valid_599849 != nil:
    section.add "X-Amz-SignedHeaders", valid_599849
  var valid_599850 = header.getOrDefault("X-Amz-Credential")
  valid_599850 = validateParameter(valid_599850, JString, required = false,
                                 default = nil)
  if valid_599850 != nil:
    section.add "X-Amz-Credential", valid_599850
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599873: Call_GetAssumeRole_599705; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a set of temporary security credentials that you can use to access AWS resources that you might not normally have access to. These temporary credentials consist of an access key ID, a secret access key, and a security token. Typically, you use <code>AssumeRole</code> within your account or for cross-account access. For a comparison of <code>AssumeRole</code> with other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <important> <p>You cannot use AWS account root user credentials to call <code>AssumeRole</code>. You must use credentials for an IAM user or an IAM role to call <code>AssumeRole</code>.</p> </important> <p>For cross-account access, imagine that you own multiple accounts and need to access resources in each account. You could create long-term credentials in each account to access those resources. However, managing all those credentials and remembering which one can access which account can be time consuming. Instead, you can create one set of long-term credentials in one account. Then use temporary security credentials to access all the other accounts by assuming roles in those accounts. For more information about roles, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html">IAM Roles</a> in the <i>IAM User Guide</i>. </p> <p> <b>Session Duration</b> </p> <p>By default, the temporary security credentials created by <code>AssumeRole</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. You can provide a value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>.</p> <p> <b>Permissions</b> </p> <p>The temporary security credentials created by <code>AssumeRole</code> can be used to make API calls to any AWS service with the following exception: You cannot call the AWS STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>To assume a role from a different account, your AWS account must be trusted by the role. The trust relationship is defined in the role's trust policy when the role is created. That trust policy states which accounts are allowed to delegate that access to users in the account. </p> <p>A user who wants to access a role in a different account must also have permissions that are delegated from the user account administrator. The administrator must attach a policy that allows the user to call <code>AssumeRole</code> for the ARN of the role in the other account. If the user is in the same account as the role, then you can do either of the following:</p> <ul> <li> <p>Attach a policy to the user (identical to the previous user in a different account).</p> </li> <li> <p>Add the user as a principal directly in the role's trust policy.</p> </li> </ul> <p>In this case, the trust policy acts as an IAM resource-based policy. Users in the same account as the role do not need explicit permission to assume the role. For more information about trust policies and resource-based policies, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html">IAM Policies</a> in the <i>IAM User Guide</i>.</p> <p> <b>Tags</b> </p> <p>(Optional) You can pass tag key-value pairs to your session. These tags are called session tags. For more information about session tags, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Passing Session Tags in STS</a> in the <i>IAM User Guide</i>.</p> <p>An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html">Tutorial: Using Tags for Attribute-Based Access Control</a> in the <i>IAM User Guide</i>.</p> <p>You can set the session tags as transitive. Transitive tags persist during role chaining. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining">Chaining Roles with Session Tags</a> in the <i>IAM User Guide</i>.</p> <p> <b>Using MFA with AssumeRole</b> </p> <p>(Optional) You can include multi-factor authentication (MFA) information when you call <code>AssumeRole</code>. This is useful for cross-account scenarios to ensure that the user that assumes the role has been authenticated with an AWS MFA device. In that scenario, the trust policy of the role being assumed includes a condition that tests for MFA authentication. If the caller does not include valid MFA information, the request to assume the role is denied. The condition in a trust policy that tests for MFA authentication might look like the following example.</p> <p> <code>"Condition": {"Bool": {"aws:MultiFactorAuthPresent": true}}</code> </p> <p>For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/MFAProtectedAPI.html">Configuring MFA-Protected API Access</a> in the <i>IAM User Guide</i> guide.</p> <p>To use MFA with <code>AssumeRole</code>, you pass values for the <code>SerialNumber</code> and <code>TokenCode</code> parameters. The <code>SerialNumber</code> value identifies the user's hardware or virtual MFA device. The <code>TokenCode</code> is the time-based one-time password (TOTP) that the MFA device produces. </p>
  ## 
  let valid = call_599873.validator(path, query, header, formData, body)
  let scheme = call_599873.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599873.url(scheme.get, call_599873.host, call_599873.base,
                         call_599873.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599873, url, valid)

proc call*(call_599944: Call_GetAssumeRole_599705; RoleArn: string;
          RoleSessionName: string; TransitiveTagKeys: JsonNode = nil;
          TokenCode: string = ""; SerialNumber: string = ""; DurationSeconds: int = 0;
          Tags: JsonNode = nil; PolicyArns: JsonNode = nil;
          Action: string = "AssumeRole"; Policy: string = ""; ExternalId: string = "";
          Version: string = "2011-06-15"): Recallable =
  ## getAssumeRole
  ## <p>Returns a set of temporary security credentials that you can use to access AWS resources that you might not normally have access to. These temporary credentials consist of an access key ID, a secret access key, and a security token. Typically, you use <code>AssumeRole</code> within your account or for cross-account access. For a comparison of <code>AssumeRole</code> with other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <important> <p>You cannot use AWS account root user credentials to call <code>AssumeRole</code>. You must use credentials for an IAM user or an IAM role to call <code>AssumeRole</code>.</p> </important> <p>For cross-account access, imagine that you own multiple accounts and need to access resources in each account. You could create long-term credentials in each account to access those resources. However, managing all those credentials and remembering which one can access which account can be time consuming. Instead, you can create one set of long-term credentials in one account. Then use temporary security credentials to access all the other accounts by assuming roles in those accounts. For more information about roles, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html">IAM Roles</a> in the <i>IAM User Guide</i>. </p> <p> <b>Session Duration</b> </p> <p>By default, the temporary security credentials created by <code>AssumeRole</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. You can provide a value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>.</p> <p> <b>Permissions</b> </p> <p>The temporary security credentials created by <code>AssumeRole</code> can be used to make API calls to any AWS service with the following exception: You cannot call the AWS STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>To assume a role from a different account, your AWS account must be trusted by the role. The trust relationship is defined in the role's trust policy when the role is created. That trust policy states which accounts are allowed to delegate that access to users in the account. </p> <p>A user who wants to access a role in a different account must also have permissions that are delegated from the user account administrator. The administrator must attach a policy that allows the user to call <code>AssumeRole</code> for the ARN of the role in the other account. If the user is in the same account as the role, then you can do either of the following:</p> <ul> <li> <p>Attach a policy to the user (identical to the previous user in a different account).</p> </li> <li> <p>Add the user as a principal directly in the role's trust policy.</p> </li> </ul> <p>In this case, the trust policy acts as an IAM resource-based policy. Users in the same account as the role do not need explicit permission to assume the role. For more information about trust policies and resource-based policies, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html">IAM Policies</a> in the <i>IAM User Guide</i>.</p> <p> <b>Tags</b> </p> <p>(Optional) You can pass tag key-value pairs to your session. These tags are called session tags. For more information about session tags, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Passing Session Tags in STS</a> in the <i>IAM User Guide</i>.</p> <p>An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html">Tutorial: Using Tags for Attribute-Based Access Control</a> in the <i>IAM User Guide</i>.</p> <p>You can set the session tags as transitive. Transitive tags persist during role chaining. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining">Chaining Roles with Session Tags</a> in the <i>IAM User Guide</i>.</p> <p> <b>Using MFA with AssumeRole</b> </p> <p>(Optional) You can include multi-factor authentication (MFA) information when you call <code>AssumeRole</code>. This is useful for cross-account scenarios to ensure that the user that assumes the role has been authenticated with an AWS MFA device. In that scenario, the trust policy of the role being assumed includes a condition that tests for MFA authentication. If the caller does not include valid MFA information, the request to assume the role is denied. The condition in a trust policy that tests for MFA authentication might look like the following example.</p> <p> <code>"Condition": {"Bool": {"aws:MultiFactorAuthPresent": true}}</code> </p> <p>For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/MFAProtectedAPI.html">Configuring MFA-Protected API Access</a> in the <i>IAM User Guide</i> guide.</p> <p>To use MFA with <code>AssumeRole</code>, you pass values for the <code>SerialNumber</code> and <code>TokenCode</code> parameters. The <code>SerialNumber</code> value identifies the user's hardware or virtual MFA device. The <code>TokenCode</code> is the time-based one-time password (TOTP) that the MFA device produces. </p>
  ##   TransitiveTagKeys: JArray
  ##                    : <p>A list of keys for session tags that you want to set as transitive. If you set a tag key as transitive, the corresponding key and value passes to subsequent sessions in a role chain. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining">Chaining Roles with Session Tags</a> in the <i>IAM User Guide</i>.</p> <p>This parameter is optional. When you set session tags as transitive, the session policy and session tags packed binary limit is not affected.</p> <p>If you choose not to specify a transitive tag key, then no tags are passed from this session to any subsequent sessions.</p>
  ##   TokenCode: string
  ##            : <p>The value provided by the MFA device, if the trust policy of the role being assumed requires MFA (that is, if the policy includes a condition that tests for MFA). If the role being assumed requires MFA and if the <code>TokenCode</code> value is missing or expired, the <code>AssumeRole</code> call returns an "access denied" error.</p> <p>The format for this parameter, as described by its regex pattern, is a sequence of six numeric digits.</p>
  ##   SerialNumber: string
  ##               : <p>The identification number of the MFA device that is associated with the user who is making the <code>AssumeRole</code> call. Specify this value if the trust policy of the role being assumed includes a condition that requires MFA authentication. The value is either the serial number for a hardware device (such as <code>GAHT12345678</code>) or an Amazon Resource Name (ARN) for a virtual device (such as <code>arn:aws:iam::123456789012:mfa/user</code>).</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-</p>
  ##   RoleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the role to assume.
  ##   DurationSeconds: int
  ##                  : <p>The duration, in seconds, of the role session. The value can range from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. If you specify a value higher than this setting, the operation fails. For example, if you specify a session duration of 12 hours, but your administrator set the maximum session duration to 6 hours, your operation fails. To learn how to view the maximum value for your role, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>.</p> <p>By default, the value is set to <code>3600</code> seconds. </p> <note> <p>The <code>DurationSeconds</code> parameter is separate from the duration of a console session that you might request using the returned credentials. The request to the federation endpoint for a console sign-in token takes a <code>SessionDuration</code> parameter that specifies the maximum length of the console session. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html">Creating a URL that Enables Federated Users to Access the AWS Management Console</a> in the <i>IAM User Guide</i>.</p> </note>
  ##   RoleSessionName: string (required)
  ##                  : <p>An identifier for the assumed role session.</p> <p>Use the role session name to uniquely identify a session when the same role is assumed by different principals or for different reasons. In cross-account scenarios, the role session name is visible to, and can be logged by the account that owns the role. The role session name is also used in the ARN of the assumed role principal. This means that subsequent cross-account API requests that use the temporary security credentials will expose the role session name to the external account in their AWS CloudTrail logs.</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-</p>
  ##   Tags: JArray
  ##       : <p>A list of session tags that you want to pass. Each session tag consists of a key name and an associated value. For more information about session tags, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Tagging AWS STS Sessions</a> in the <i>IAM User Guide</i>.</p> <p>This parameter is optional. You can pass up to 50 session tags. The plain text session tag keys can’t exceed 128 characters, and the values can’t exceed 256 characters. For these and additional limits, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length">IAM and STS Character Limits</a> in the <i>IAM User Guide</i>.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>You can pass a session tag with the same key as a tag that is already attached to the role. When you do, session tags override a role tag with the same key. </p> <p>Tag key–value pairs are not case sensitive, but case is preserved. This means that you cannot have separate <code>Department</code> and <code>department</code> tag keys. Assume that the role has the <code>Department</code>=<code>Marketing</code> tag and you pass the <code>department</code>=<code>engineering</code> session tag. <code>Department</code> and <code>department</code> are not saved as separate tags, and the session tag passed in the request takes precedence over the role tag.</p> <p>Additionally, if you used temporary credentials to perform this operation, the new session inherits any transitive session tags from the calling session. If you pass a session tag with the same key as an inherited tag, the operation fails. To view the inherited tags for a session, see the AWS CloudTrail logs. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/session-tags.html#id_session-tags_ctlogs">Viewing Session Tags in CloudTrail</a> in the <i>IAM User Guide</i>.</p>
  ##   PolicyArns: JArray
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as managed session policies. The policies must exist in the same account as the role.</p> <p>This parameter is optional. You can provide up to 10 managed policy ARNs. However, the plain text that you use for both inline and managed session policies can't exceed 2,048 characters. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p>
  ##   Action: string (required)
  ##   Policy: string
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>This parameter is optional. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note>
  ##   ExternalId: string
  ##             : <p>A unique identifier that might be required when you assume a role in another account. If the administrator of the account to which the role belongs provided you with an external ID, then provide that value in the <code>ExternalId</code> parameter. This value can be any string, such as a passphrase or account number. A cross-account role is usually set up to trust everyone in an account. Therefore, the administrator of the trusting account might send an external ID to the administrator of the trusted account. That way, only someone with the ID can assume the role, rather than everyone in the account. For more information about the external ID, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user_externalid.html">How to Use an External ID When Granting Access to Your AWS Resources to a Third Party</a> in the <i>IAM User Guide</i>.</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@:/-</p>
  ##   Version: string (required)
  var query_599945 = newJObject()
  if TransitiveTagKeys != nil:
    query_599945.add "TransitiveTagKeys", TransitiveTagKeys
  add(query_599945, "TokenCode", newJString(TokenCode))
  add(query_599945, "SerialNumber", newJString(SerialNumber))
  add(query_599945, "RoleArn", newJString(RoleArn))
  add(query_599945, "DurationSeconds", newJInt(DurationSeconds))
  add(query_599945, "RoleSessionName", newJString(RoleSessionName))
  if Tags != nil:
    query_599945.add "Tags", Tags
  if PolicyArns != nil:
    query_599945.add "PolicyArns", PolicyArns
  add(query_599945, "Action", newJString(Action))
  add(query_599945, "Policy", newJString(Policy))
  add(query_599945, "ExternalId", newJString(ExternalId))
  add(query_599945, "Version", newJString(Version))
  result = call_599944.call(nil, query_599945, nil, nil, nil)

var getAssumeRole* = Call_GetAssumeRole_599705(name: "getAssumeRole",
    meth: HttpMethod.HttpGet, host: "sts.amazonaws.com",
    route: "/#Action=AssumeRole", validator: validate_GetAssumeRole_599706,
    base: "/", url: url_GetAssumeRole_599707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAssumeRoleWithSAML_600032 = ref object of OpenApiRestCall_599368
proc url_PostAssumeRoleWithSAML_600034(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAssumeRoleWithSAML_600033(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a set of temporary security credentials for users who have been authenticated via a SAML authentication response. This operation provides a mechanism for tying an enterprise identity store or directory to role-based AWS access without user-specific credentials or configuration. For a comparison of <code>AssumeRoleWithSAML</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials returned by this operation consist of an access key ID, a secret access key, and a security token. Applications can use these temporary security credentials to sign calls to AWS services.</p> <p> <b>Session Duration</b> </p> <p>By default, the temporary security credentials created by <code>AssumeRoleWithSAML</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. Your role session lasts for the duration that you specify, or until the time specified in the SAML authentication response's <code>SessionNotOnOrAfter</code> value, whichever is shorter. You can provide a <code>DurationSeconds</code> value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>.</p> <p> <b>Permissions</b> </p> <p>The temporary security credentials created by <code>AssumeRoleWithSAML</code> can be used to make API calls to any AWS service with the following exception: you cannot call the STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>Calling <code>AssumeRoleWithSAML</code> does not require the use of AWS security credentials. The identity of the caller is validated by using keys in the metadata document that is uploaded for the SAML provider entity for your identity provider. </p> <important> <p>Calling <code>AssumeRoleWithSAML</code> can result in an entry in your AWS CloudTrail logs. The entry includes the value in the <code>NameID</code> element of the SAML assertion. We recommend that you use a <code>NameIDType</code> that is not associated with any personally identifiable information (PII). For example, you could instead use the persistent identifier (<code>urn:oasis:names:tc:SAML:2.0:nameid-format:persistent</code>).</p> </important> <p> <b>Tags</b> </p> <p>(Optional) You can configure your IdP to pass attributes into your SAML assertion as session tags. Each session tag consists of a key name and an associated value. For more information about session tags, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Passing Session Tags in STS</a> in the <i>IAM User Guide</i>.</p> <p>You can pass up to 50 session tags. The plain text session tag keys can’t exceed 128 characters and the values can’t exceed 256 characters. For these and additional limits, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length">IAM and STS Character Limits</a> in the <i>IAM User Guide</i>.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>You can pass a session tag with the same key as a tag that is attached to the role. When you do, session tags override the role's tags with the same key.</p> <p>An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html">Tutorial: Using Tags for Attribute-Based Access Control</a> in the <i>IAM User Guide</i>.</p> <p>You can set the session tags as transitive. Transitive tags persist during role chaining. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining">Chaining Roles with Session Tags</a> in the <i>IAM User Guide</i>.</p> <p> <b>SAML Configuration</b> </p> <p>Before your application can call <code>AssumeRoleWithSAML</code>, you must configure your SAML identity provider (IdP) to issue the claims required by AWS. Additionally, you must use AWS Identity and Access Management (IAM) to create a SAML provider entity in your AWS account that represents your identity provider. You must also create an IAM role that specifies this SAML provider in its trust policy. </p> <p>For more information, see the following resources:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_saml.html">About SAML 2.0-based Federation</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml.html">Creating SAML Identity Providers</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml_relying-party.html">Configuring a Relying Party and Claims</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_saml.html">Creating a Role for SAML 2.0 Federation</a> in the <i>IAM User Guide</i>. </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600035 = query.getOrDefault("Action")
  valid_600035 = validateParameter(valid_600035, JString, required = true,
                                 default = newJString("AssumeRoleWithSAML"))
  if valid_600035 != nil:
    section.add "Action", valid_600035
  var valid_600036 = query.getOrDefault("Version")
  valid_600036 = validateParameter(valid_600036, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_600036 != nil:
    section.add "Version", valid_600036
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
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
  var valid_600039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "X-Amz-Content-Sha256", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Algorithm")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Algorithm", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Signature")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Signature", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-SignedHeaders", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-Credential")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-Credential", valid_600043
  result.add "header", section
  ## parameters in `formData` object:
  ##   PrincipalArn: JString (required)
  ##               : The Amazon Resource Name (ARN) of the SAML provider in IAM that describes the IdP.
  ##   RoleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the role that the caller is assuming.
  ##   SAMLAssertion: JString (required)
  ##                : <p>The base-64 encoded SAML authentication response provided by the IdP.</p> <p>For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/create-role-saml-IdP-tasks.html">Configuring a Relying Party and Adding Claims</a> in the <i>IAM User Guide</i>. </p>
  ##   PolicyArns: JArray
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as managed session policies. The policies must exist in the same account as the role.</p> <p>This parameter is optional. You can provide up to 10 managed policy ARNs. However, the plain text that you use for both inline and managed session policies can't exceed 2,048 characters. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p>
  ##   Policy: JString
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>This parameter is optional. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>. </p> <p>The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note>
  ##   DurationSeconds: JInt
  ##                  : <p>The duration, in seconds, of the role session. Your role session lasts for the duration that you specify for the <code>DurationSeconds</code> parameter, or until the time specified in the SAML authentication response's <code>SessionNotOnOrAfter</code> value, whichever is shorter. You can provide a <code>DurationSeconds</code> value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. If you specify a value higher than this setting, the operation fails. For example, if you specify a session duration of 12 hours, but your administrator set the maximum session duration to 6 hours, your operation fails. To learn how to view the maximum value for your role, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>.</p> <p>By default, the value is set to <code>3600</code> seconds. </p> <note> <p>The <code>DurationSeconds</code> parameter is separate from the duration of a console session that you might request using the returned credentials. The request to the federation endpoint for a console sign-in token takes a <code>SessionDuration</code> parameter that specifies the maximum length of the console session. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html">Creating a URL that Enables Federated Users to Access the AWS Management Console</a> in the <i>IAM User Guide</i>.</p> </note>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `PrincipalArn` field"
  var valid_600044 = formData.getOrDefault("PrincipalArn")
  valid_600044 = validateParameter(valid_600044, JString, required = true,
                                 default = nil)
  if valid_600044 != nil:
    section.add "PrincipalArn", valid_600044
  var valid_600045 = formData.getOrDefault("RoleArn")
  valid_600045 = validateParameter(valid_600045, JString, required = true,
                                 default = nil)
  if valid_600045 != nil:
    section.add "RoleArn", valid_600045
  var valid_600046 = formData.getOrDefault("SAMLAssertion")
  valid_600046 = validateParameter(valid_600046, JString, required = true,
                                 default = nil)
  if valid_600046 != nil:
    section.add "SAMLAssertion", valid_600046
  var valid_600047 = formData.getOrDefault("PolicyArns")
  valid_600047 = validateParameter(valid_600047, JArray, required = false,
                                 default = nil)
  if valid_600047 != nil:
    section.add "PolicyArns", valid_600047
  var valid_600048 = formData.getOrDefault("Policy")
  valid_600048 = validateParameter(valid_600048, JString, required = false,
                                 default = nil)
  if valid_600048 != nil:
    section.add "Policy", valid_600048
  var valid_600049 = formData.getOrDefault("DurationSeconds")
  valid_600049 = validateParameter(valid_600049, JInt, required = false, default = nil)
  if valid_600049 != nil:
    section.add "DurationSeconds", valid_600049
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600050: Call_PostAssumeRoleWithSAML_600032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a set of temporary security credentials for users who have been authenticated via a SAML authentication response. This operation provides a mechanism for tying an enterprise identity store or directory to role-based AWS access without user-specific credentials or configuration. For a comparison of <code>AssumeRoleWithSAML</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials returned by this operation consist of an access key ID, a secret access key, and a security token. Applications can use these temporary security credentials to sign calls to AWS services.</p> <p> <b>Session Duration</b> </p> <p>By default, the temporary security credentials created by <code>AssumeRoleWithSAML</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. Your role session lasts for the duration that you specify, or until the time specified in the SAML authentication response's <code>SessionNotOnOrAfter</code> value, whichever is shorter. You can provide a <code>DurationSeconds</code> value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>.</p> <p> <b>Permissions</b> </p> <p>The temporary security credentials created by <code>AssumeRoleWithSAML</code> can be used to make API calls to any AWS service with the following exception: you cannot call the STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>Calling <code>AssumeRoleWithSAML</code> does not require the use of AWS security credentials. The identity of the caller is validated by using keys in the metadata document that is uploaded for the SAML provider entity for your identity provider. </p> <important> <p>Calling <code>AssumeRoleWithSAML</code> can result in an entry in your AWS CloudTrail logs. The entry includes the value in the <code>NameID</code> element of the SAML assertion. We recommend that you use a <code>NameIDType</code> that is not associated with any personally identifiable information (PII). For example, you could instead use the persistent identifier (<code>urn:oasis:names:tc:SAML:2.0:nameid-format:persistent</code>).</p> </important> <p> <b>Tags</b> </p> <p>(Optional) You can configure your IdP to pass attributes into your SAML assertion as session tags. Each session tag consists of a key name and an associated value. For more information about session tags, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Passing Session Tags in STS</a> in the <i>IAM User Guide</i>.</p> <p>You can pass up to 50 session tags. The plain text session tag keys can’t exceed 128 characters and the values can’t exceed 256 characters. For these and additional limits, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length">IAM and STS Character Limits</a> in the <i>IAM User Guide</i>.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>You can pass a session tag with the same key as a tag that is attached to the role. When you do, session tags override the role's tags with the same key.</p> <p>An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html">Tutorial: Using Tags for Attribute-Based Access Control</a> in the <i>IAM User Guide</i>.</p> <p>You can set the session tags as transitive. Transitive tags persist during role chaining. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining">Chaining Roles with Session Tags</a> in the <i>IAM User Guide</i>.</p> <p> <b>SAML Configuration</b> </p> <p>Before your application can call <code>AssumeRoleWithSAML</code>, you must configure your SAML identity provider (IdP) to issue the claims required by AWS. Additionally, you must use AWS Identity and Access Management (IAM) to create a SAML provider entity in your AWS account that represents your identity provider. You must also create an IAM role that specifies this SAML provider in its trust policy. </p> <p>For more information, see the following resources:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_saml.html">About SAML 2.0-based Federation</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml.html">Creating SAML Identity Providers</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml_relying-party.html">Configuring a Relying Party and Claims</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_saml.html">Creating a Role for SAML 2.0 Federation</a> in the <i>IAM User Guide</i>. </p> </li> </ul>
  ## 
  let valid = call_600050.validator(path, query, header, formData, body)
  let scheme = call_600050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600050.url(scheme.get, call_600050.host, call_600050.base,
                         call_600050.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600050, url, valid)

proc call*(call_600051: Call_PostAssumeRoleWithSAML_600032; PrincipalArn: string;
          RoleArn: string; SAMLAssertion: string;
          Action: string = "AssumeRoleWithSAML"; PolicyArns: JsonNode = nil;
          Policy: string = ""; Version: string = "2011-06-15"; DurationSeconds: int = 0): Recallable =
  ## postAssumeRoleWithSAML
  ## <p>Returns a set of temporary security credentials for users who have been authenticated via a SAML authentication response. This operation provides a mechanism for tying an enterprise identity store or directory to role-based AWS access without user-specific credentials or configuration. For a comparison of <code>AssumeRoleWithSAML</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials returned by this operation consist of an access key ID, a secret access key, and a security token. Applications can use these temporary security credentials to sign calls to AWS services.</p> <p> <b>Session Duration</b> </p> <p>By default, the temporary security credentials created by <code>AssumeRoleWithSAML</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. Your role session lasts for the duration that you specify, or until the time specified in the SAML authentication response's <code>SessionNotOnOrAfter</code> value, whichever is shorter. You can provide a <code>DurationSeconds</code> value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>.</p> <p> <b>Permissions</b> </p> <p>The temporary security credentials created by <code>AssumeRoleWithSAML</code> can be used to make API calls to any AWS service with the following exception: you cannot call the STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>Calling <code>AssumeRoleWithSAML</code> does not require the use of AWS security credentials. The identity of the caller is validated by using keys in the metadata document that is uploaded for the SAML provider entity for your identity provider. </p> <important> <p>Calling <code>AssumeRoleWithSAML</code> can result in an entry in your AWS CloudTrail logs. The entry includes the value in the <code>NameID</code> element of the SAML assertion. We recommend that you use a <code>NameIDType</code> that is not associated with any personally identifiable information (PII). For example, you could instead use the persistent identifier (<code>urn:oasis:names:tc:SAML:2.0:nameid-format:persistent</code>).</p> </important> <p> <b>Tags</b> </p> <p>(Optional) You can configure your IdP to pass attributes into your SAML assertion as session tags. Each session tag consists of a key name and an associated value. For more information about session tags, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Passing Session Tags in STS</a> in the <i>IAM User Guide</i>.</p> <p>You can pass up to 50 session tags. The plain text session tag keys can’t exceed 128 characters and the values can’t exceed 256 characters. For these and additional limits, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length">IAM and STS Character Limits</a> in the <i>IAM User Guide</i>.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>You can pass a session tag with the same key as a tag that is attached to the role. When you do, session tags override the role's tags with the same key.</p> <p>An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html">Tutorial: Using Tags for Attribute-Based Access Control</a> in the <i>IAM User Guide</i>.</p> <p>You can set the session tags as transitive. Transitive tags persist during role chaining. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining">Chaining Roles with Session Tags</a> in the <i>IAM User Guide</i>.</p> <p> <b>SAML Configuration</b> </p> <p>Before your application can call <code>AssumeRoleWithSAML</code>, you must configure your SAML identity provider (IdP) to issue the claims required by AWS. Additionally, you must use AWS Identity and Access Management (IAM) to create a SAML provider entity in your AWS account that represents your identity provider. You must also create an IAM role that specifies this SAML provider in its trust policy. </p> <p>For more information, see the following resources:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_saml.html">About SAML 2.0-based Federation</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml.html">Creating SAML Identity Providers</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml_relying-party.html">Configuring a Relying Party and Claims</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_saml.html">Creating a Role for SAML 2.0 Federation</a> in the <i>IAM User Guide</i>. </p> </li> </ul>
  ##   PrincipalArn: string (required)
  ##               : The Amazon Resource Name (ARN) of the SAML provider in IAM that describes the IdP.
  ##   RoleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the role that the caller is assuming.
  ##   Action: string (required)
  ##   SAMLAssertion: string (required)
  ##                : <p>The base-64 encoded SAML authentication response provided by the IdP.</p> <p>For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/create-role-saml-IdP-tasks.html">Configuring a Relying Party and Adding Claims</a> in the <i>IAM User Guide</i>. </p>
  ##   PolicyArns: JArray
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as managed session policies. The policies must exist in the same account as the role.</p> <p>This parameter is optional. You can provide up to 10 managed policy ARNs. However, the plain text that you use for both inline and managed session policies can't exceed 2,048 characters. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p>
  ##   Policy: string
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>This parameter is optional. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>. </p> <p>The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note>
  ##   Version: string (required)
  ##   DurationSeconds: int
  ##                  : <p>The duration, in seconds, of the role session. Your role session lasts for the duration that you specify for the <code>DurationSeconds</code> parameter, or until the time specified in the SAML authentication response's <code>SessionNotOnOrAfter</code> value, whichever is shorter. You can provide a <code>DurationSeconds</code> value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. If you specify a value higher than this setting, the operation fails. For example, if you specify a session duration of 12 hours, but your administrator set the maximum session duration to 6 hours, your operation fails. To learn how to view the maximum value for your role, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>.</p> <p>By default, the value is set to <code>3600</code> seconds. </p> <note> <p>The <code>DurationSeconds</code> parameter is separate from the duration of a console session that you might request using the returned credentials. The request to the federation endpoint for a console sign-in token takes a <code>SessionDuration</code> parameter that specifies the maximum length of the console session. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html">Creating a URL that Enables Federated Users to Access the AWS Management Console</a> in the <i>IAM User Guide</i>.</p> </note>
  var query_600052 = newJObject()
  var formData_600053 = newJObject()
  add(formData_600053, "PrincipalArn", newJString(PrincipalArn))
  add(formData_600053, "RoleArn", newJString(RoleArn))
  add(query_600052, "Action", newJString(Action))
  add(formData_600053, "SAMLAssertion", newJString(SAMLAssertion))
  if PolicyArns != nil:
    formData_600053.add "PolicyArns", PolicyArns
  add(formData_600053, "Policy", newJString(Policy))
  add(query_600052, "Version", newJString(Version))
  add(formData_600053, "DurationSeconds", newJInt(DurationSeconds))
  result = call_600051.call(nil, query_600052, nil, formData_600053, nil)

var postAssumeRoleWithSAML* = Call_PostAssumeRoleWithSAML_600032(
    name: "postAssumeRoleWithSAML", meth: HttpMethod.HttpPost,
    host: "sts.amazonaws.com", route: "/#Action=AssumeRoleWithSAML",
    validator: validate_PostAssumeRoleWithSAML_600033, base: "/",
    url: url_PostAssumeRoleWithSAML_600034, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssumeRoleWithSAML_600011 = ref object of OpenApiRestCall_599368
proc url_GetAssumeRoleWithSAML_600013(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAssumeRoleWithSAML_600012(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a set of temporary security credentials for users who have been authenticated via a SAML authentication response. This operation provides a mechanism for tying an enterprise identity store or directory to role-based AWS access without user-specific credentials or configuration. For a comparison of <code>AssumeRoleWithSAML</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials returned by this operation consist of an access key ID, a secret access key, and a security token. Applications can use these temporary security credentials to sign calls to AWS services.</p> <p> <b>Session Duration</b> </p> <p>By default, the temporary security credentials created by <code>AssumeRoleWithSAML</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. Your role session lasts for the duration that you specify, or until the time specified in the SAML authentication response's <code>SessionNotOnOrAfter</code> value, whichever is shorter. You can provide a <code>DurationSeconds</code> value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>.</p> <p> <b>Permissions</b> </p> <p>The temporary security credentials created by <code>AssumeRoleWithSAML</code> can be used to make API calls to any AWS service with the following exception: you cannot call the STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>Calling <code>AssumeRoleWithSAML</code> does not require the use of AWS security credentials. The identity of the caller is validated by using keys in the metadata document that is uploaded for the SAML provider entity for your identity provider. </p> <important> <p>Calling <code>AssumeRoleWithSAML</code> can result in an entry in your AWS CloudTrail logs. The entry includes the value in the <code>NameID</code> element of the SAML assertion. We recommend that you use a <code>NameIDType</code> that is not associated with any personally identifiable information (PII). For example, you could instead use the persistent identifier (<code>urn:oasis:names:tc:SAML:2.0:nameid-format:persistent</code>).</p> </important> <p> <b>Tags</b> </p> <p>(Optional) You can configure your IdP to pass attributes into your SAML assertion as session tags. Each session tag consists of a key name and an associated value. For more information about session tags, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Passing Session Tags in STS</a> in the <i>IAM User Guide</i>.</p> <p>You can pass up to 50 session tags. The plain text session tag keys can’t exceed 128 characters and the values can’t exceed 256 characters. For these and additional limits, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length">IAM and STS Character Limits</a> in the <i>IAM User Guide</i>.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>You can pass a session tag with the same key as a tag that is attached to the role. When you do, session tags override the role's tags with the same key.</p> <p>An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html">Tutorial: Using Tags for Attribute-Based Access Control</a> in the <i>IAM User Guide</i>.</p> <p>You can set the session tags as transitive. Transitive tags persist during role chaining. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining">Chaining Roles with Session Tags</a> in the <i>IAM User Guide</i>.</p> <p> <b>SAML Configuration</b> </p> <p>Before your application can call <code>AssumeRoleWithSAML</code>, you must configure your SAML identity provider (IdP) to issue the claims required by AWS. Additionally, you must use AWS Identity and Access Management (IAM) to create a SAML provider entity in your AWS account that represents your identity provider. You must also create an IAM role that specifies this SAML provider in its trust policy. </p> <p>For more information, see the following resources:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_saml.html">About SAML 2.0-based Federation</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml.html">Creating SAML Identity Providers</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml_relying-party.html">Configuring a Relying Party and Claims</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_saml.html">Creating a Role for SAML 2.0 Federation</a> in the <i>IAM User Guide</i>. </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   RoleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the role that the caller is assuming.
  ##   DurationSeconds: JInt
  ##                  : <p>The duration, in seconds, of the role session. Your role session lasts for the duration that you specify for the <code>DurationSeconds</code> parameter, or until the time specified in the SAML authentication response's <code>SessionNotOnOrAfter</code> value, whichever is shorter. You can provide a <code>DurationSeconds</code> value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. If you specify a value higher than this setting, the operation fails. For example, if you specify a session duration of 12 hours, but your administrator set the maximum session duration to 6 hours, your operation fails. To learn how to view the maximum value for your role, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>.</p> <p>By default, the value is set to <code>3600</code> seconds. </p> <note> <p>The <code>DurationSeconds</code> parameter is separate from the duration of a console session that you might request using the returned credentials. The request to the federation endpoint for a console sign-in token takes a <code>SessionDuration</code> parameter that specifies the maximum length of the console session. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html">Creating a URL that Enables Federated Users to Access the AWS Management Console</a> in the <i>IAM User Guide</i>.</p> </note>
  ##   SAMLAssertion: JString (required)
  ##                : <p>The base-64 encoded SAML authentication response provided by the IdP.</p> <p>For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/create-role-saml-IdP-tasks.html">Configuring a Relying Party and Adding Claims</a> in the <i>IAM User Guide</i>. </p>
  ##   PolicyArns: JArray
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as managed session policies. The policies must exist in the same account as the role.</p> <p>This parameter is optional. You can provide up to 10 managed policy ARNs. However, the plain text that you use for both inline and managed session policies can't exceed 2,048 characters. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p>
  ##   Action: JString (required)
  ##   PrincipalArn: JString (required)
  ##               : The Amazon Resource Name (ARN) of the SAML provider in IAM that describes the IdP.
  ##   Policy: JString
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>This parameter is optional. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>. </p> <p>The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `RoleArn` field"
  var valid_600014 = query.getOrDefault("RoleArn")
  valid_600014 = validateParameter(valid_600014, JString, required = true,
                                 default = nil)
  if valid_600014 != nil:
    section.add "RoleArn", valid_600014
  var valid_600015 = query.getOrDefault("DurationSeconds")
  valid_600015 = validateParameter(valid_600015, JInt, required = false, default = nil)
  if valid_600015 != nil:
    section.add "DurationSeconds", valid_600015
  var valid_600016 = query.getOrDefault("SAMLAssertion")
  valid_600016 = validateParameter(valid_600016, JString, required = true,
                                 default = nil)
  if valid_600016 != nil:
    section.add "SAMLAssertion", valid_600016
  var valid_600017 = query.getOrDefault("PolicyArns")
  valid_600017 = validateParameter(valid_600017, JArray, required = false,
                                 default = nil)
  if valid_600017 != nil:
    section.add "PolicyArns", valid_600017
  var valid_600018 = query.getOrDefault("Action")
  valid_600018 = validateParameter(valid_600018, JString, required = true,
                                 default = newJString("AssumeRoleWithSAML"))
  if valid_600018 != nil:
    section.add "Action", valid_600018
  var valid_600019 = query.getOrDefault("PrincipalArn")
  valid_600019 = validateParameter(valid_600019, JString, required = true,
                                 default = nil)
  if valid_600019 != nil:
    section.add "PrincipalArn", valid_600019
  var valid_600020 = query.getOrDefault("Policy")
  valid_600020 = validateParameter(valid_600020, JString, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "Policy", valid_600020
  var valid_600021 = query.getOrDefault("Version")
  valid_600021 = validateParameter(valid_600021, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_600021 != nil:
    section.add "Version", valid_600021
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
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
  var valid_600024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600024 = validateParameter(valid_600024, JString, required = false,
                                 default = nil)
  if valid_600024 != nil:
    section.add "X-Amz-Content-Sha256", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Algorithm")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Algorithm", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Signature")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Signature", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-SignedHeaders", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-Credential")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-Credential", valid_600028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600029: Call_GetAssumeRoleWithSAML_600011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a set of temporary security credentials for users who have been authenticated via a SAML authentication response. This operation provides a mechanism for tying an enterprise identity store or directory to role-based AWS access without user-specific credentials or configuration. For a comparison of <code>AssumeRoleWithSAML</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials returned by this operation consist of an access key ID, a secret access key, and a security token. Applications can use these temporary security credentials to sign calls to AWS services.</p> <p> <b>Session Duration</b> </p> <p>By default, the temporary security credentials created by <code>AssumeRoleWithSAML</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. Your role session lasts for the duration that you specify, or until the time specified in the SAML authentication response's <code>SessionNotOnOrAfter</code> value, whichever is shorter. You can provide a <code>DurationSeconds</code> value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>.</p> <p> <b>Permissions</b> </p> <p>The temporary security credentials created by <code>AssumeRoleWithSAML</code> can be used to make API calls to any AWS service with the following exception: you cannot call the STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>Calling <code>AssumeRoleWithSAML</code> does not require the use of AWS security credentials. The identity of the caller is validated by using keys in the metadata document that is uploaded for the SAML provider entity for your identity provider. </p> <important> <p>Calling <code>AssumeRoleWithSAML</code> can result in an entry in your AWS CloudTrail logs. The entry includes the value in the <code>NameID</code> element of the SAML assertion. We recommend that you use a <code>NameIDType</code> that is not associated with any personally identifiable information (PII). For example, you could instead use the persistent identifier (<code>urn:oasis:names:tc:SAML:2.0:nameid-format:persistent</code>).</p> </important> <p> <b>Tags</b> </p> <p>(Optional) You can configure your IdP to pass attributes into your SAML assertion as session tags. Each session tag consists of a key name and an associated value. For more information about session tags, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Passing Session Tags in STS</a> in the <i>IAM User Guide</i>.</p> <p>You can pass up to 50 session tags. The plain text session tag keys can’t exceed 128 characters and the values can’t exceed 256 characters. For these and additional limits, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length">IAM and STS Character Limits</a> in the <i>IAM User Guide</i>.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>You can pass a session tag with the same key as a tag that is attached to the role. When you do, session tags override the role's tags with the same key.</p> <p>An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html">Tutorial: Using Tags for Attribute-Based Access Control</a> in the <i>IAM User Guide</i>.</p> <p>You can set the session tags as transitive. Transitive tags persist during role chaining. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining">Chaining Roles with Session Tags</a> in the <i>IAM User Guide</i>.</p> <p> <b>SAML Configuration</b> </p> <p>Before your application can call <code>AssumeRoleWithSAML</code>, you must configure your SAML identity provider (IdP) to issue the claims required by AWS. Additionally, you must use AWS Identity and Access Management (IAM) to create a SAML provider entity in your AWS account that represents your identity provider. You must also create an IAM role that specifies this SAML provider in its trust policy. </p> <p>For more information, see the following resources:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_saml.html">About SAML 2.0-based Federation</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml.html">Creating SAML Identity Providers</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml_relying-party.html">Configuring a Relying Party and Claims</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_saml.html">Creating a Role for SAML 2.0 Federation</a> in the <i>IAM User Guide</i>. </p> </li> </ul>
  ## 
  let valid = call_600029.validator(path, query, header, formData, body)
  let scheme = call_600029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600029.url(scheme.get, call_600029.host, call_600029.base,
                         call_600029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600029, url, valid)

proc call*(call_600030: Call_GetAssumeRoleWithSAML_600011; RoleArn: string;
          SAMLAssertion: string; PrincipalArn: string; DurationSeconds: int = 0;
          PolicyArns: JsonNode = nil; Action: string = "AssumeRoleWithSAML";
          Policy: string = ""; Version: string = "2011-06-15"): Recallable =
  ## getAssumeRoleWithSAML
  ## <p>Returns a set of temporary security credentials for users who have been authenticated via a SAML authentication response. This operation provides a mechanism for tying an enterprise identity store or directory to role-based AWS access without user-specific credentials or configuration. For a comparison of <code>AssumeRoleWithSAML</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials returned by this operation consist of an access key ID, a secret access key, and a security token. Applications can use these temporary security credentials to sign calls to AWS services.</p> <p> <b>Session Duration</b> </p> <p>By default, the temporary security credentials created by <code>AssumeRoleWithSAML</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. Your role session lasts for the duration that you specify, or until the time specified in the SAML authentication response's <code>SessionNotOnOrAfter</code> value, whichever is shorter. You can provide a <code>DurationSeconds</code> value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>.</p> <p> <b>Permissions</b> </p> <p>The temporary security credentials created by <code>AssumeRoleWithSAML</code> can be used to make API calls to any AWS service with the following exception: you cannot call the STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>Calling <code>AssumeRoleWithSAML</code> does not require the use of AWS security credentials. The identity of the caller is validated by using keys in the metadata document that is uploaded for the SAML provider entity for your identity provider. </p> <important> <p>Calling <code>AssumeRoleWithSAML</code> can result in an entry in your AWS CloudTrail logs. The entry includes the value in the <code>NameID</code> element of the SAML assertion. We recommend that you use a <code>NameIDType</code> that is not associated with any personally identifiable information (PII). For example, you could instead use the persistent identifier (<code>urn:oasis:names:tc:SAML:2.0:nameid-format:persistent</code>).</p> </important> <p> <b>Tags</b> </p> <p>(Optional) You can configure your IdP to pass attributes into your SAML assertion as session tags. Each session tag consists of a key name and an associated value. For more information about session tags, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Passing Session Tags in STS</a> in the <i>IAM User Guide</i>.</p> <p>You can pass up to 50 session tags. The plain text session tag keys can’t exceed 128 characters and the values can’t exceed 256 characters. For these and additional limits, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length">IAM and STS Character Limits</a> in the <i>IAM User Guide</i>.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>You can pass a session tag with the same key as a tag that is attached to the role. When you do, session tags override the role's tags with the same key.</p> <p>An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html">Tutorial: Using Tags for Attribute-Based Access Control</a> in the <i>IAM User Guide</i>.</p> <p>You can set the session tags as transitive. Transitive tags persist during role chaining. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining">Chaining Roles with Session Tags</a> in the <i>IAM User Guide</i>.</p> <p> <b>SAML Configuration</b> </p> <p>Before your application can call <code>AssumeRoleWithSAML</code>, you must configure your SAML identity provider (IdP) to issue the claims required by AWS. Additionally, you must use AWS Identity and Access Management (IAM) to create a SAML provider entity in your AWS account that represents your identity provider. You must also create an IAM role that specifies this SAML provider in its trust policy. </p> <p>For more information, see the following resources:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_saml.html">About SAML 2.0-based Federation</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml.html">Creating SAML Identity Providers</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml_relying-party.html">Configuring a Relying Party and Claims</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_saml.html">Creating a Role for SAML 2.0 Federation</a> in the <i>IAM User Guide</i>. </p> </li> </ul>
  ##   RoleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the role that the caller is assuming.
  ##   DurationSeconds: int
  ##                  : <p>The duration, in seconds, of the role session. Your role session lasts for the duration that you specify for the <code>DurationSeconds</code> parameter, or until the time specified in the SAML authentication response's <code>SessionNotOnOrAfter</code> value, whichever is shorter. You can provide a <code>DurationSeconds</code> value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. If you specify a value higher than this setting, the operation fails. For example, if you specify a session duration of 12 hours, but your administrator set the maximum session duration to 6 hours, your operation fails. To learn how to view the maximum value for your role, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>.</p> <p>By default, the value is set to <code>3600</code> seconds. </p> <note> <p>The <code>DurationSeconds</code> parameter is separate from the duration of a console session that you might request using the returned credentials. The request to the federation endpoint for a console sign-in token takes a <code>SessionDuration</code> parameter that specifies the maximum length of the console session. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html">Creating a URL that Enables Federated Users to Access the AWS Management Console</a> in the <i>IAM User Guide</i>.</p> </note>
  ##   SAMLAssertion: string (required)
  ##                : <p>The base-64 encoded SAML authentication response provided by the IdP.</p> <p>For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/create-role-saml-IdP-tasks.html">Configuring a Relying Party and Adding Claims</a> in the <i>IAM User Guide</i>. </p>
  ##   PolicyArns: JArray
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as managed session policies. The policies must exist in the same account as the role.</p> <p>This parameter is optional. You can provide up to 10 managed policy ARNs. However, the plain text that you use for both inline and managed session policies can't exceed 2,048 characters. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p>
  ##   Action: string (required)
  ##   PrincipalArn: string (required)
  ##               : The Amazon Resource Name (ARN) of the SAML provider in IAM that describes the IdP.
  ##   Policy: string
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>This parameter is optional. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>. </p> <p>The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note>
  ##   Version: string (required)
  var query_600031 = newJObject()
  add(query_600031, "RoleArn", newJString(RoleArn))
  add(query_600031, "DurationSeconds", newJInt(DurationSeconds))
  add(query_600031, "SAMLAssertion", newJString(SAMLAssertion))
  if PolicyArns != nil:
    query_600031.add "PolicyArns", PolicyArns
  add(query_600031, "Action", newJString(Action))
  add(query_600031, "PrincipalArn", newJString(PrincipalArn))
  add(query_600031, "Policy", newJString(Policy))
  add(query_600031, "Version", newJString(Version))
  result = call_600030.call(nil, query_600031, nil, nil, nil)

var getAssumeRoleWithSAML* = Call_GetAssumeRoleWithSAML_600011(
    name: "getAssumeRoleWithSAML", meth: HttpMethod.HttpGet,
    host: "sts.amazonaws.com", route: "/#Action=AssumeRoleWithSAML",
    validator: validate_GetAssumeRoleWithSAML_600012, base: "/",
    url: url_GetAssumeRoleWithSAML_600013, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAssumeRoleWithWebIdentity_600076 = ref object of OpenApiRestCall_599368
proc url_PostAssumeRoleWithWebIdentity_600078(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAssumeRoleWithWebIdentity_600077(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a set of temporary security credentials for users who have been authenticated in a mobile or web application with a web identity provider. Example providers include Amazon Cognito, Login with Amazon, Facebook, Google, or any OpenID Connect-compatible identity provider.</p> <note> <p>For mobile applications, we recommend that you use Amazon Cognito. You can use Amazon Cognito with the <a href="http://aws.amazon.com/sdkforios/">AWS SDK for iOS Developer Guide</a> and the <a href="http://aws.amazon.com/sdkforandroid/">AWS SDK for Android Developer Guide</a> to uniquely identify a user. You can also supply the user with a consistent identity throughout the lifetime of an application.</p> <p>To learn more about Amazon Cognito, see <a href="https://docs.aws.amazon.com/mobile/sdkforandroid/developerguide/cognito-auth.html#d0e840">Amazon Cognito Overview</a> in <i>AWS SDK for Android Developer Guide</i> and <a href="https://docs.aws.amazon.com/mobile/sdkforios/developerguide/cognito-auth.html#d0e664">Amazon Cognito Overview</a> in the <i>AWS SDK for iOS Developer Guide</i>.</p> </note> <p>Calling <code>AssumeRoleWithWebIdentity</code> does not require the use of AWS security credentials. Therefore, you can distribute an application (for example, on mobile devices) that requests temporary security credentials without including long-term AWS credentials in the application. You also don't need to deploy server-based proxy services that use long-term AWS credentials. Instead, the identity of the caller is validated by using a token from the web identity provider. For a comparison of <code>AssumeRoleWithWebIdentity</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials returned by this API consist of an access key ID, a secret access key, and a security token. Applications can use these temporary security credentials to sign calls to AWS service API operations.</p> <p> <b>Session Duration</b> </p> <p>By default, the temporary security credentials created by <code>AssumeRoleWithWebIdentity</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. You can provide a value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>. </p> <p> <b>Permissions</b> </p> <p>The temporary security credentials created by <code>AssumeRoleWithWebIdentity</code> can be used to make API calls to any AWS service with the following exception: you cannot call the STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p> <b>Tags</b> </p> <p>(Optional) You can configure your IdP to pass attributes into your web identity token as session tags. Each session tag consists of a key name and an associated value. For more information about session tags, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Passing Session Tags in STS</a> in the <i>IAM User Guide</i>.</p> <p>You can pass up to 50 session tags. The plain text session tag keys can’t exceed 128 characters and the values can’t exceed 256 characters. For these and additional limits, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length">IAM and STS Character Limits</a> in the <i>IAM User Guide</i>.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>You can pass a session tag with the same key as a tag that is attached to the role. When you do, the session tag overrides the role tag with the same key.</p> <p>An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html">Tutorial: Using Tags for Attribute-Based Access Control</a> in the <i>IAM User Guide</i>.</p> <p>You can set the session tags as transitive. Transitive tags persist during role chaining. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining">Chaining Roles with Session Tags</a> in the <i>IAM User Guide</i>.</p> <p> <b>Identities</b> </p> <p>Before your application can call <code>AssumeRoleWithWebIdentity</code>, you must have an identity token from a supported identity provider and create a role that the application can assume. The role that your application assumes must trust the identity provider that is associated with the identity token. In other words, the identity provider must be specified in the role's trust policy. </p> <important> <p>Calling <code>AssumeRoleWithWebIdentity</code> can result in an entry in your AWS CloudTrail logs. The entry includes the <a href="http://openid.net/specs/openid-connect-core-1_0.html#Claims">Subject</a> of the provided Web Identity Token. We recommend that you avoid using any personally identifiable information (PII) in this field. For example, you could instead use a GUID or a pairwise identifier, as <a href="http://openid.net/specs/openid-connect-core-1_0.html#SubjectIDTypes">suggested in the OIDC specification</a>.</p> </important> <p>For more information about how to use web identity federation and the <code>AssumeRoleWithWebIdentity</code> API, see the following resources: </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_oidc_manual.html">Using Web Identity Federation API Operations for Mobile Apps</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity">Federation Through a Web-based Identity Provider</a>. </p> </li> <li> <p> <a href="https://web-identity-federation-playground.s3.amazonaws.com/index.html"> Web Identity Federation Playground</a>. Walk through the process of authenticating through Login with Amazon, Facebook, or Google, getting temporary security credentials, and then using those credentials to make a request to AWS. </p> </li> <li> <p> <a href="http://aws.amazon.com/sdkforios/">AWS SDK for iOS Developer Guide</a> and <a href="http://aws.amazon.com/sdkforandroid/">AWS SDK for Android Developer Guide</a>. These toolkits contain sample apps that show how to invoke the identity providers. The toolkits then show how to use the information from these providers to get and use temporary security credentials. </p> </li> <li> <p> <a href="http://aws.amazon.com/articles/web-identity-federation-with-mobile-applications">Web Identity Federation with Mobile Applications</a>. This article discusses web identity federation and shows an example of how to use web identity federation to get access to content in Amazon S3. </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600079 = query.getOrDefault("Action")
  valid_600079 = validateParameter(valid_600079, JString, required = true, default = newJString(
      "AssumeRoleWithWebIdentity"))
  if valid_600079 != nil:
    section.add "Action", valid_600079
  var valid_600080 = query.getOrDefault("Version")
  valid_600080 = validateParameter(valid_600080, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_600080 != nil:
    section.add "Version", valid_600080
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600081 = header.getOrDefault("X-Amz-Date")
  valid_600081 = validateParameter(valid_600081, JString, required = false,
                                 default = nil)
  if valid_600081 != nil:
    section.add "X-Amz-Date", valid_600081
  var valid_600082 = header.getOrDefault("X-Amz-Security-Token")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Security-Token", valid_600082
  var valid_600083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Content-Sha256", valid_600083
  var valid_600084 = header.getOrDefault("X-Amz-Algorithm")
  valid_600084 = validateParameter(valid_600084, JString, required = false,
                                 default = nil)
  if valid_600084 != nil:
    section.add "X-Amz-Algorithm", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Signature")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Signature", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-SignedHeaders", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Credential")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Credential", valid_600087
  result.add "header", section
  ## parameters in `formData` object:
  ##   ProviderId: JString
  ##             : <p>The fully qualified host component of the domain name of the identity provider.</p> <p>Specify this value only for OAuth 2.0 access tokens. Currently <code>www.amazon.com</code> and <code>graph.facebook.com</code> are the only supported identity providers for OAuth 2.0 access tokens. Do not include URL schemes and port numbers.</p> <p>Do not specify this value for OpenID Connect ID tokens.</p>
  ##   RoleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the role that the caller is assuming.
  ##   PolicyArns: JArray
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as managed session policies. The policies must exist in the same account as the role.</p> <p>This parameter is optional. You can provide up to 10 managed policy ARNs. However, the plain text that you use for both inline and managed session policies can't exceed 2,048 characters. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p>
  ##   WebIdentityToken: JString (required)
  ##                   : The OAuth 2.0 access token or OpenID Connect ID token that is provided by the identity provider. Your application must get this token by authenticating the user who is using your application with a web identity provider before the application makes an <code>AssumeRoleWithWebIdentity</code> call. 
  ##   RoleSessionName: JString (required)
  ##                  : <p>An identifier for the assumed role session. Typically, you pass the name or identifier that is associated with the user who is using your application. That way, the temporary security credentials that your application will use are associated with that user. This session name is included as part of the ARN and assumed role ID in the <code>AssumedRoleUser</code> response element.</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-</p>
  ##   Policy: JString
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>This parameter is optional. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note>
  ##   DurationSeconds: JInt
  ##                  : <p>The duration, in seconds, of the role session. The value can range from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. If you specify a value higher than this setting, the operation fails. For example, if you specify a session duration of 12 hours, but your administrator set the maximum session duration to 6 hours, your operation fails. To learn how to view the maximum value for your role, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>.</p> <p>By default, the value is set to <code>3600</code> seconds. </p> <note> <p>The <code>DurationSeconds</code> parameter is separate from the duration of a console session that you might request using the returned credentials. The request to the federation endpoint for a console sign-in token takes a <code>SessionDuration</code> parameter that specifies the maximum length of the console session. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html">Creating a URL that Enables Federated Users to Access the AWS Management Console</a> in the <i>IAM User Guide</i>.</p> </note>
  section = newJObject()
  var valid_600088 = formData.getOrDefault("ProviderId")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "ProviderId", valid_600088
  assert formData != nil,
        "formData argument is necessary due to required `RoleArn` field"
  var valid_600089 = formData.getOrDefault("RoleArn")
  valid_600089 = validateParameter(valid_600089, JString, required = true,
                                 default = nil)
  if valid_600089 != nil:
    section.add "RoleArn", valid_600089
  var valid_600090 = formData.getOrDefault("PolicyArns")
  valid_600090 = validateParameter(valid_600090, JArray, required = false,
                                 default = nil)
  if valid_600090 != nil:
    section.add "PolicyArns", valid_600090
  var valid_600091 = formData.getOrDefault("WebIdentityToken")
  valid_600091 = validateParameter(valid_600091, JString, required = true,
                                 default = nil)
  if valid_600091 != nil:
    section.add "WebIdentityToken", valid_600091
  var valid_600092 = formData.getOrDefault("RoleSessionName")
  valid_600092 = validateParameter(valid_600092, JString, required = true,
                                 default = nil)
  if valid_600092 != nil:
    section.add "RoleSessionName", valid_600092
  var valid_600093 = formData.getOrDefault("Policy")
  valid_600093 = validateParameter(valid_600093, JString, required = false,
                                 default = nil)
  if valid_600093 != nil:
    section.add "Policy", valid_600093
  var valid_600094 = formData.getOrDefault("DurationSeconds")
  valid_600094 = validateParameter(valid_600094, JInt, required = false, default = nil)
  if valid_600094 != nil:
    section.add "DurationSeconds", valid_600094
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600095: Call_PostAssumeRoleWithWebIdentity_600076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a set of temporary security credentials for users who have been authenticated in a mobile or web application with a web identity provider. Example providers include Amazon Cognito, Login with Amazon, Facebook, Google, or any OpenID Connect-compatible identity provider.</p> <note> <p>For mobile applications, we recommend that you use Amazon Cognito. You can use Amazon Cognito with the <a href="http://aws.amazon.com/sdkforios/">AWS SDK for iOS Developer Guide</a> and the <a href="http://aws.amazon.com/sdkforandroid/">AWS SDK for Android Developer Guide</a> to uniquely identify a user. You can also supply the user with a consistent identity throughout the lifetime of an application.</p> <p>To learn more about Amazon Cognito, see <a href="https://docs.aws.amazon.com/mobile/sdkforandroid/developerguide/cognito-auth.html#d0e840">Amazon Cognito Overview</a> in <i>AWS SDK for Android Developer Guide</i> and <a href="https://docs.aws.amazon.com/mobile/sdkforios/developerguide/cognito-auth.html#d0e664">Amazon Cognito Overview</a> in the <i>AWS SDK for iOS Developer Guide</i>.</p> </note> <p>Calling <code>AssumeRoleWithWebIdentity</code> does not require the use of AWS security credentials. Therefore, you can distribute an application (for example, on mobile devices) that requests temporary security credentials without including long-term AWS credentials in the application. You also don't need to deploy server-based proxy services that use long-term AWS credentials. Instead, the identity of the caller is validated by using a token from the web identity provider. For a comparison of <code>AssumeRoleWithWebIdentity</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials returned by this API consist of an access key ID, a secret access key, and a security token. Applications can use these temporary security credentials to sign calls to AWS service API operations.</p> <p> <b>Session Duration</b> </p> <p>By default, the temporary security credentials created by <code>AssumeRoleWithWebIdentity</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. You can provide a value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>. </p> <p> <b>Permissions</b> </p> <p>The temporary security credentials created by <code>AssumeRoleWithWebIdentity</code> can be used to make API calls to any AWS service with the following exception: you cannot call the STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p> <b>Tags</b> </p> <p>(Optional) You can configure your IdP to pass attributes into your web identity token as session tags. Each session tag consists of a key name and an associated value. For more information about session tags, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Passing Session Tags in STS</a> in the <i>IAM User Guide</i>.</p> <p>You can pass up to 50 session tags. The plain text session tag keys can’t exceed 128 characters and the values can’t exceed 256 characters. For these and additional limits, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length">IAM and STS Character Limits</a> in the <i>IAM User Guide</i>.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>You can pass a session tag with the same key as a tag that is attached to the role. When you do, the session tag overrides the role tag with the same key.</p> <p>An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html">Tutorial: Using Tags for Attribute-Based Access Control</a> in the <i>IAM User Guide</i>.</p> <p>You can set the session tags as transitive. Transitive tags persist during role chaining. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining">Chaining Roles with Session Tags</a> in the <i>IAM User Guide</i>.</p> <p> <b>Identities</b> </p> <p>Before your application can call <code>AssumeRoleWithWebIdentity</code>, you must have an identity token from a supported identity provider and create a role that the application can assume. The role that your application assumes must trust the identity provider that is associated with the identity token. In other words, the identity provider must be specified in the role's trust policy. </p> <important> <p>Calling <code>AssumeRoleWithWebIdentity</code> can result in an entry in your AWS CloudTrail logs. The entry includes the <a href="http://openid.net/specs/openid-connect-core-1_0.html#Claims">Subject</a> of the provided Web Identity Token. We recommend that you avoid using any personally identifiable information (PII) in this field. For example, you could instead use a GUID or a pairwise identifier, as <a href="http://openid.net/specs/openid-connect-core-1_0.html#SubjectIDTypes">suggested in the OIDC specification</a>.</p> </important> <p>For more information about how to use web identity federation and the <code>AssumeRoleWithWebIdentity</code> API, see the following resources: </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_oidc_manual.html">Using Web Identity Federation API Operations for Mobile Apps</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity">Federation Through a Web-based Identity Provider</a>. </p> </li> <li> <p> <a href="https://web-identity-federation-playground.s3.amazonaws.com/index.html"> Web Identity Federation Playground</a>. Walk through the process of authenticating through Login with Amazon, Facebook, or Google, getting temporary security credentials, and then using those credentials to make a request to AWS. </p> </li> <li> <p> <a href="http://aws.amazon.com/sdkforios/">AWS SDK for iOS Developer Guide</a> and <a href="http://aws.amazon.com/sdkforandroid/">AWS SDK for Android Developer Guide</a>. These toolkits contain sample apps that show how to invoke the identity providers. The toolkits then show how to use the information from these providers to get and use temporary security credentials. </p> </li> <li> <p> <a href="http://aws.amazon.com/articles/web-identity-federation-with-mobile-applications">Web Identity Federation with Mobile Applications</a>. This article discusses web identity federation and shows an example of how to use web identity federation to get access to content in Amazon S3. </p> </li> </ul>
  ## 
  let valid = call_600095.validator(path, query, header, formData, body)
  let scheme = call_600095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600095.url(scheme.get, call_600095.host, call_600095.base,
                         call_600095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600095, url, valid)

proc call*(call_600096: Call_PostAssumeRoleWithWebIdentity_600076; RoleArn: string;
          WebIdentityToken: string; RoleSessionName: string;
          ProviderId: string = ""; Action: string = "AssumeRoleWithWebIdentity";
          PolicyArns: JsonNode = nil; Policy: string = "";
          Version: string = "2011-06-15"; DurationSeconds: int = 0): Recallable =
  ## postAssumeRoleWithWebIdentity
  ## <p>Returns a set of temporary security credentials for users who have been authenticated in a mobile or web application with a web identity provider. Example providers include Amazon Cognito, Login with Amazon, Facebook, Google, or any OpenID Connect-compatible identity provider.</p> <note> <p>For mobile applications, we recommend that you use Amazon Cognito. You can use Amazon Cognito with the <a href="http://aws.amazon.com/sdkforios/">AWS SDK for iOS Developer Guide</a> and the <a href="http://aws.amazon.com/sdkforandroid/">AWS SDK for Android Developer Guide</a> to uniquely identify a user. You can also supply the user with a consistent identity throughout the lifetime of an application.</p> <p>To learn more about Amazon Cognito, see <a href="https://docs.aws.amazon.com/mobile/sdkforandroid/developerguide/cognito-auth.html#d0e840">Amazon Cognito Overview</a> in <i>AWS SDK for Android Developer Guide</i> and <a href="https://docs.aws.amazon.com/mobile/sdkforios/developerguide/cognito-auth.html#d0e664">Amazon Cognito Overview</a> in the <i>AWS SDK for iOS Developer Guide</i>.</p> </note> <p>Calling <code>AssumeRoleWithWebIdentity</code> does not require the use of AWS security credentials. Therefore, you can distribute an application (for example, on mobile devices) that requests temporary security credentials without including long-term AWS credentials in the application. You also don't need to deploy server-based proxy services that use long-term AWS credentials. Instead, the identity of the caller is validated by using a token from the web identity provider. For a comparison of <code>AssumeRoleWithWebIdentity</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials returned by this API consist of an access key ID, a secret access key, and a security token. Applications can use these temporary security credentials to sign calls to AWS service API operations.</p> <p> <b>Session Duration</b> </p> <p>By default, the temporary security credentials created by <code>AssumeRoleWithWebIdentity</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. You can provide a value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>. </p> <p> <b>Permissions</b> </p> <p>The temporary security credentials created by <code>AssumeRoleWithWebIdentity</code> can be used to make API calls to any AWS service with the following exception: you cannot call the STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p> <b>Tags</b> </p> <p>(Optional) You can configure your IdP to pass attributes into your web identity token as session tags. Each session tag consists of a key name and an associated value. For more information about session tags, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Passing Session Tags in STS</a> in the <i>IAM User Guide</i>.</p> <p>You can pass up to 50 session tags. The plain text session tag keys can’t exceed 128 characters and the values can’t exceed 256 characters. For these and additional limits, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length">IAM and STS Character Limits</a> in the <i>IAM User Guide</i>.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>You can pass a session tag with the same key as a tag that is attached to the role. When you do, the session tag overrides the role tag with the same key.</p> <p>An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html">Tutorial: Using Tags for Attribute-Based Access Control</a> in the <i>IAM User Guide</i>.</p> <p>You can set the session tags as transitive. Transitive tags persist during role chaining. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining">Chaining Roles with Session Tags</a> in the <i>IAM User Guide</i>.</p> <p> <b>Identities</b> </p> <p>Before your application can call <code>AssumeRoleWithWebIdentity</code>, you must have an identity token from a supported identity provider and create a role that the application can assume. The role that your application assumes must trust the identity provider that is associated with the identity token. In other words, the identity provider must be specified in the role's trust policy. </p> <important> <p>Calling <code>AssumeRoleWithWebIdentity</code> can result in an entry in your AWS CloudTrail logs. The entry includes the <a href="http://openid.net/specs/openid-connect-core-1_0.html#Claims">Subject</a> of the provided Web Identity Token. We recommend that you avoid using any personally identifiable information (PII) in this field. For example, you could instead use a GUID or a pairwise identifier, as <a href="http://openid.net/specs/openid-connect-core-1_0.html#SubjectIDTypes">suggested in the OIDC specification</a>.</p> </important> <p>For more information about how to use web identity federation and the <code>AssumeRoleWithWebIdentity</code> API, see the following resources: </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_oidc_manual.html">Using Web Identity Federation API Operations for Mobile Apps</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity">Federation Through a Web-based Identity Provider</a>. </p> </li> <li> <p> <a href="https://web-identity-federation-playground.s3.amazonaws.com/index.html"> Web Identity Federation Playground</a>. Walk through the process of authenticating through Login with Amazon, Facebook, or Google, getting temporary security credentials, and then using those credentials to make a request to AWS. </p> </li> <li> <p> <a href="http://aws.amazon.com/sdkforios/">AWS SDK for iOS Developer Guide</a> and <a href="http://aws.amazon.com/sdkforandroid/">AWS SDK for Android Developer Guide</a>. These toolkits contain sample apps that show how to invoke the identity providers. The toolkits then show how to use the information from these providers to get and use temporary security credentials. </p> </li> <li> <p> <a href="http://aws.amazon.com/articles/web-identity-federation-with-mobile-applications">Web Identity Federation with Mobile Applications</a>. This article discusses web identity federation and shows an example of how to use web identity federation to get access to content in Amazon S3. </p> </li> </ul>
  ##   ProviderId: string
  ##             : <p>The fully qualified host component of the domain name of the identity provider.</p> <p>Specify this value only for OAuth 2.0 access tokens. Currently <code>www.amazon.com</code> and <code>graph.facebook.com</code> are the only supported identity providers for OAuth 2.0 access tokens. Do not include URL schemes and port numbers.</p> <p>Do not specify this value for OpenID Connect ID tokens.</p>
  ##   RoleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the role that the caller is assuming.
  ##   Action: string (required)
  ##   PolicyArns: JArray
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as managed session policies. The policies must exist in the same account as the role.</p> <p>This parameter is optional. You can provide up to 10 managed policy ARNs. However, the plain text that you use for both inline and managed session policies can't exceed 2,048 characters. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p>
  ##   WebIdentityToken: string (required)
  ##                   : The OAuth 2.0 access token or OpenID Connect ID token that is provided by the identity provider. Your application must get this token by authenticating the user who is using your application with a web identity provider before the application makes an <code>AssumeRoleWithWebIdentity</code> call. 
  ##   RoleSessionName: string (required)
  ##                  : <p>An identifier for the assumed role session. Typically, you pass the name or identifier that is associated with the user who is using your application. That way, the temporary security credentials that your application will use are associated with that user. This session name is included as part of the ARN and assumed role ID in the <code>AssumedRoleUser</code> response element.</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-</p>
  ##   Policy: string
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>This parameter is optional. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note>
  ##   Version: string (required)
  ##   DurationSeconds: int
  ##                  : <p>The duration, in seconds, of the role session. The value can range from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. If you specify a value higher than this setting, the operation fails. For example, if you specify a session duration of 12 hours, but your administrator set the maximum session duration to 6 hours, your operation fails. To learn how to view the maximum value for your role, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>.</p> <p>By default, the value is set to <code>3600</code> seconds. </p> <note> <p>The <code>DurationSeconds</code> parameter is separate from the duration of a console session that you might request using the returned credentials. The request to the federation endpoint for a console sign-in token takes a <code>SessionDuration</code> parameter that specifies the maximum length of the console session. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html">Creating a URL that Enables Federated Users to Access the AWS Management Console</a> in the <i>IAM User Guide</i>.</p> </note>
  var query_600097 = newJObject()
  var formData_600098 = newJObject()
  add(formData_600098, "ProviderId", newJString(ProviderId))
  add(formData_600098, "RoleArn", newJString(RoleArn))
  add(query_600097, "Action", newJString(Action))
  if PolicyArns != nil:
    formData_600098.add "PolicyArns", PolicyArns
  add(formData_600098, "WebIdentityToken", newJString(WebIdentityToken))
  add(formData_600098, "RoleSessionName", newJString(RoleSessionName))
  add(formData_600098, "Policy", newJString(Policy))
  add(query_600097, "Version", newJString(Version))
  add(formData_600098, "DurationSeconds", newJInt(DurationSeconds))
  result = call_600096.call(nil, query_600097, nil, formData_600098, nil)

var postAssumeRoleWithWebIdentity* = Call_PostAssumeRoleWithWebIdentity_600076(
    name: "postAssumeRoleWithWebIdentity", meth: HttpMethod.HttpPost,
    host: "sts.amazonaws.com", route: "/#Action=AssumeRoleWithWebIdentity",
    validator: validate_PostAssumeRoleWithWebIdentity_600077, base: "/",
    url: url_PostAssumeRoleWithWebIdentity_600078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssumeRoleWithWebIdentity_600054 = ref object of OpenApiRestCall_599368
proc url_GetAssumeRoleWithWebIdentity_600056(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAssumeRoleWithWebIdentity_600055(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a set of temporary security credentials for users who have been authenticated in a mobile or web application with a web identity provider. Example providers include Amazon Cognito, Login with Amazon, Facebook, Google, or any OpenID Connect-compatible identity provider.</p> <note> <p>For mobile applications, we recommend that you use Amazon Cognito. You can use Amazon Cognito with the <a href="http://aws.amazon.com/sdkforios/">AWS SDK for iOS Developer Guide</a> and the <a href="http://aws.amazon.com/sdkforandroid/">AWS SDK for Android Developer Guide</a> to uniquely identify a user. You can also supply the user with a consistent identity throughout the lifetime of an application.</p> <p>To learn more about Amazon Cognito, see <a href="https://docs.aws.amazon.com/mobile/sdkforandroid/developerguide/cognito-auth.html#d0e840">Amazon Cognito Overview</a> in <i>AWS SDK for Android Developer Guide</i> and <a href="https://docs.aws.amazon.com/mobile/sdkforios/developerguide/cognito-auth.html#d0e664">Amazon Cognito Overview</a> in the <i>AWS SDK for iOS Developer Guide</i>.</p> </note> <p>Calling <code>AssumeRoleWithWebIdentity</code> does not require the use of AWS security credentials. Therefore, you can distribute an application (for example, on mobile devices) that requests temporary security credentials without including long-term AWS credentials in the application. You also don't need to deploy server-based proxy services that use long-term AWS credentials. Instead, the identity of the caller is validated by using a token from the web identity provider. For a comparison of <code>AssumeRoleWithWebIdentity</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials returned by this API consist of an access key ID, a secret access key, and a security token. Applications can use these temporary security credentials to sign calls to AWS service API operations.</p> <p> <b>Session Duration</b> </p> <p>By default, the temporary security credentials created by <code>AssumeRoleWithWebIdentity</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. You can provide a value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>. </p> <p> <b>Permissions</b> </p> <p>The temporary security credentials created by <code>AssumeRoleWithWebIdentity</code> can be used to make API calls to any AWS service with the following exception: you cannot call the STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p> <b>Tags</b> </p> <p>(Optional) You can configure your IdP to pass attributes into your web identity token as session tags. Each session tag consists of a key name and an associated value. For more information about session tags, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Passing Session Tags in STS</a> in the <i>IAM User Guide</i>.</p> <p>You can pass up to 50 session tags. The plain text session tag keys can’t exceed 128 characters and the values can’t exceed 256 characters. For these and additional limits, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length">IAM and STS Character Limits</a> in the <i>IAM User Guide</i>.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>You can pass a session tag with the same key as a tag that is attached to the role. When you do, the session tag overrides the role tag with the same key.</p> <p>An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html">Tutorial: Using Tags for Attribute-Based Access Control</a> in the <i>IAM User Guide</i>.</p> <p>You can set the session tags as transitive. Transitive tags persist during role chaining. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining">Chaining Roles with Session Tags</a> in the <i>IAM User Guide</i>.</p> <p> <b>Identities</b> </p> <p>Before your application can call <code>AssumeRoleWithWebIdentity</code>, you must have an identity token from a supported identity provider and create a role that the application can assume. The role that your application assumes must trust the identity provider that is associated with the identity token. In other words, the identity provider must be specified in the role's trust policy. </p> <important> <p>Calling <code>AssumeRoleWithWebIdentity</code> can result in an entry in your AWS CloudTrail logs. The entry includes the <a href="http://openid.net/specs/openid-connect-core-1_0.html#Claims">Subject</a> of the provided Web Identity Token. We recommend that you avoid using any personally identifiable information (PII) in this field. For example, you could instead use a GUID or a pairwise identifier, as <a href="http://openid.net/specs/openid-connect-core-1_0.html#SubjectIDTypes">suggested in the OIDC specification</a>.</p> </important> <p>For more information about how to use web identity federation and the <code>AssumeRoleWithWebIdentity</code> API, see the following resources: </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_oidc_manual.html">Using Web Identity Federation API Operations for Mobile Apps</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity">Federation Through a Web-based Identity Provider</a>. </p> </li> <li> <p> <a href="https://web-identity-federation-playground.s3.amazonaws.com/index.html"> Web Identity Federation Playground</a>. Walk through the process of authenticating through Login with Amazon, Facebook, or Google, getting temporary security credentials, and then using those credentials to make a request to AWS. </p> </li> <li> <p> <a href="http://aws.amazon.com/sdkforios/">AWS SDK for iOS Developer Guide</a> and <a href="http://aws.amazon.com/sdkforandroid/">AWS SDK for Android Developer Guide</a>. These toolkits contain sample apps that show how to invoke the identity providers. The toolkits then show how to use the information from these providers to get and use temporary security credentials. </p> </li> <li> <p> <a href="http://aws.amazon.com/articles/web-identity-federation-with-mobile-applications">Web Identity Federation with Mobile Applications</a>. This article discusses web identity federation and shows an example of how to use web identity federation to get access to content in Amazon S3. </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ProviderId: JString
  ##             : <p>The fully qualified host component of the domain name of the identity provider.</p> <p>Specify this value only for OAuth 2.0 access tokens. Currently <code>www.amazon.com</code> and <code>graph.facebook.com</code> are the only supported identity providers for OAuth 2.0 access tokens. Do not include URL schemes and port numbers.</p> <p>Do not specify this value for OpenID Connect ID tokens.</p>
  ##   RoleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the role that the caller is assuming.
  ##   DurationSeconds: JInt
  ##                  : <p>The duration, in seconds, of the role session. The value can range from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. If you specify a value higher than this setting, the operation fails. For example, if you specify a session duration of 12 hours, but your administrator set the maximum session duration to 6 hours, your operation fails. To learn how to view the maximum value for your role, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>.</p> <p>By default, the value is set to <code>3600</code> seconds. </p> <note> <p>The <code>DurationSeconds</code> parameter is separate from the duration of a console session that you might request using the returned credentials. The request to the federation endpoint for a console sign-in token takes a <code>SessionDuration</code> parameter that specifies the maximum length of the console session. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html">Creating a URL that Enables Federated Users to Access the AWS Management Console</a> in the <i>IAM User Guide</i>.</p> </note>
  ##   RoleSessionName: JString (required)
  ##                  : <p>An identifier for the assumed role session. Typically, you pass the name or identifier that is associated with the user who is using your application. That way, the temporary security credentials that your application will use are associated with that user. This session name is included as part of the ARN and assumed role ID in the <code>AssumedRoleUser</code> response element.</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-</p>
  ##   PolicyArns: JArray
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as managed session policies. The policies must exist in the same account as the role.</p> <p>This parameter is optional. You can provide up to 10 managed policy ARNs. However, the plain text that you use for both inline and managed session policies can't exceed 2,048 characters. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p>
  ##   Action: JString (required)
  ##   Policy: JString
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>This parameter is optional. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note>
  ##   WebIdentityToken: JString (required)
  ##                   : The OAuth 2.0 access token or OpenID Connect ID token that is provided by the identity provider. Your application must get this token by authenticating the user who is using your application with a web identity provider before the application makes an <code>AssumeRoleWithWebIdentity</code> call. 
  ##   Version: JString (required)
  section = newJObject()
  var valid_600057 = query.getOrDefault("ProviderId")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "ProviderId", valid_600057
  assert query != nil, "query argument is necessary due to required `RoleArn` field"
  var valid_600058 = query.getOrDefault("RoleArn")
  valid_600058 = validateParameter(valid_600058, JString, required = true,
                                 default = nil)
  if valid_600058 != nil:
    section.add "RoleArn", valid_600058
  var valid_600059 = query.getOrDefault("DurationSeconds")
  valid_600059 = validateParameter(valid_600059, JInt, required = false, default = nil)
  if valid_600059 != nil:
    section.add "DurationSeconds", valid_600059
  var valid_600060 = query.getOrDefault("RoleSessionName")
  valid_600060 = validateParameter(valid_600060, JString, required = true,
                                 default = nil)
  if valid_600060 != nil:
    section.add "RoleSessionName", valid_600060
  var valid_600061 = query.getOrDefault("PolicyArns")
  valid_600061 = validateParameter(valid_600061, JArray, required = false,
                                 default = nil)
  if valid_600061 != nil:
    section.add "PolicyArns", valid_600061
  var valid_600062 = query.getOrDefault("Action")
  valid_600062 = validateParameter(valid_600062, JString, required = true, default = newJString(
      "AssumeRoleWithWebIdentity"))
  if valid_600062 != nil:
    section.add "Action", valid_600062
  var valid_600063 = query.getOrDefault("Policy")
  valid_600063 = validateParameter(valid_600063, JString, required = false,
                                 default = nil)
  if valid_600063 != nil:
    section.add "Policy", valid_600063
  var valid_600064 = query.getOrDefault("WebIdentityToken")
  valid_600064 = validateParameter(valid_600064, JString, required = true,
                                 default = nil)
  if valid_600064 != nil:
    section.add "WebIdentityToken", valid_600064
  var valid_600065 = query.getOrDefault("Version")
  valid_600065 = validateParameter(valid_600065, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_600065 != nil:
    section.add "Version", valid_600065
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600066 = header.getOrDefault("X-Amz-Date")
  valid_600066 = validateParameter(valid_600066, JString, required = false,
                                 default = nil)
  if valid_600066 != nil:
    section.add "X-Amz-Date", valid_600066
  var valid_600067 = header.getOrDefault("X-Amz-Security-Token")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Security-Token", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Content-Sha256", valid_600068
  var valid_600069 = header.getOrDefault("X-Amz-Algorithm")
  valid_600069 = validateParameter(valid_600069, JString, required = false,
                                 default = nil)
  if valid_600069 != nil:
    section.add "X-Amz-Algorithm", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-Signature")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Signature", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-SignedHeaders", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-Credential")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Credential", valid_600072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600073: Call_GetAssumeRoleWithWebIdentity_600054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a set of temporary security credentials for users who have been authenticated in a mobile or web application with a web identity provider. Example providers include Amazon Cognito, Login with Amazon, Facebook, Google, or any OpenID Connect-compatible identity provider.</p> <note> <p>For mobile applications, we recommend that you use Amazon Cognito. You can use Amazon Cognito with the <a href="http://aws.amazon.com/sdkforios/">AWS SDK for iOS Developer Guide</a> and the <a href="http://aws.amazon.com/sdkforandroid/">AWS SDK for Android Developer Guide</a> to uniquely identify a user. You can also supply the user with a consistent identity throughout the lifetime of an application.</p> <p>To learn more about Amazon Cognito, see <a href="https://docs.aws.amazon.com/mobile/sdkforandroid/developerguide/cognito-auth.html#d0e840">Amazon Cognito Overview</a> in <i>AWS SDK for Android Developer Guide</i> and <a href="https://docs.aws.amazon.com/mobile/sdkforios/developerguide/cognito-auth.html#d0e664">Amazon Cognito Overview</a> in the <i>AWS SDK for iOS Developer Guide</i>.</p> </note> <p>Calling <code>AssumeRoleWithWebIdentity</code> does not require the use of AWS security credentials. Therefore, you can distribute an application (for example, on mobile devices) that requests temporary security credentials without including long-term AWS credentials in the application. You also don't need to deploy server-based proxy services that use long-term AWS credentials. Instead, the identity of the caller is validated by using a token from the web identity provider. For a comparison of <code>AssumeRoleWithWebIdentity</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials returned by this API consist of an access key ID, a secret access key, and a security token. Applications can use these temporary security credentials to sign calls to AWS service API operations.</p> <p> <b>Session Duration</b> </p> <p>By default, the temporary security credentials created by <code>AssumeRoleWithWebIdentity</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. You can provide a value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>. </p> <p> <b>Permissions</b> </p> <p>The temporary security credentials created by <code>AssumeRoleWithWebIdentity</code> can be used to make API calls to any AWS service with the following exception: you cannot call the STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p> <b>Tags</b> </p> <p>(Optional) You can configure your IdP to pass attributes into your web identity token as session tags. Each session tag consists of a key name and an associated value. For more information about session tags, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Passing Session Tags in STS</a> in the <i>IAM User Guide</i>.</p> <p>You can pass up to 50 session tags. The plain text session tag keys can’t exceed 128 characters and the values can’t exceed 256 characters. For these and additional limits, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length">IAM and STS Character Limits</a> in the <i>IAM User Guide</i>.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>You can pass a session tag with the same key as a tag that is attached to the role. When you do, the session tag overrides the role tag with the same key.</p> <p>An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html">Tutorial: Using Tags for Attribute-Based Access Control</a> in the <i>IAM User Guide</i>.</p> <p>You can set the session tags as transitive. Transitive tags persist during role chaining. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining">Chaining Roles with Session Tags</a> in the <i>IAM User Guide</i>.</p> <p> <b>Identities</b> </p> <p>Before your application can call <code>AssumeRoleWithWebIdentity</code>, you must have an identity token from a supported identity provider and create a role that the application can assume. The role that your application assumes must trust the identity provider that is associated with the identity token. In other words, the identity provider must be specified in the role's trust policy. </p> <important> <p>Calling <code>AssumeRoleWithWebIdentity</code> can result in an entry in your AWS CloudTrail logs. The entry includes the <a href="http://openid.net/specs/openid-connect-core-1_0.html#Claims">Subject</a> of the provided Web Identity Token. We recommend that you avoid using any personally identifiable information (PII) in this field. For example, you could instead use a GUID or a pairwise identifier, as <a href="http://openid.net/specs/openid-connect-core-1_0.html#SubjectIDTypes">suggested in the OIDC specification</a>.</p> </important> <p>For more information about how to use web identity federation and the <code>AssumeRoleWithWebIdentity</code> API, see the following resources: </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_oidc_manual.html">Using Web Identity Federation API Operations for Mobile Apps</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity">Federation Through a Web-based Identity Provider</a>. </p> </li> <li> <p> <a href="https://web-identity-federation-playground.s3.amazonaws.com/index.html"> Web Identity Federation Playground</a>. Walk through the process of authenticating through Login with Amazon, Facebook, or Google, getting temporary security credentials, and then using those credentials to make a request to AWS. </p> </li> <li> <p> <a href="http://aws.amazon.com/sdkforios/">AWS SDK for iOS Developer Guide</a> and <a href="http://aws.amazon.com/sdkforandroid/">AWS SDK for Android Developer Guide</a>. These toolkits contain sample apps that show how to invoke the identity providers. The toolkits then show how to use the information from these providers to get and use temporary security credentials. </p> </li> <li> <p> <a href="http://aws.amazon.com/articles/web-identity-federation-with-mobile-applications">Web Identity Federation with Mobile Applications</a>. This article discusses web identity federation and shows an example of how to use web identity federation to get access to content in Amazon S3. </p> </li> </ul>
  ## 
  let valid = call_600073.validator(path, query, header, formData, body)
  let scheme = call_600073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600073.url(scheme.get, call_600073.host, call_600073.base,
                         call_600073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600073, url, valid)

proc call*(call_600074: Call_GetAssumeRoleWithWebIdentity_600054; RoleArn: string;
          RoleSessionName: string; WebIdentityToken: string;
          ProviderId: string = ""; DurationSeconds: int = 0; PolicyArns: JsonNode = nil;
          Action: string = "AssumeRoleWithWebIdentity"; Policy: string = "";
          Version: string = "2011-06-15"): Recallable =
  ## getAssumeRoleWithWebIdentity
  ## <p>Returns a set of temporary security credentials for users who have been authenticated in a mobile or web application with a web identity provider. Example providers include Amazon Cognito, Login with Amazon, Facebook, Google, or any OpenID Connect-compatible identity provider.</p> <note> <p>For mobile applications, we recommend that you use Amazon Cognito. You can use Amazon Cognito with the <a href="http://aws.amazon.com/sdkforios/">AWS SDK for iOS Developer Guide</a> and the <a href="http://aws.amazon.com/sdkforandroid/">AWS SDK for Android Developer Guide</a> to uniquely identify a user. You can also supply the user with a consistent identity throughout the lifetime of an application.</p> <p>To learn more about Amazon Cognito, see <a href="https://docs.aws.amazon.com/mobile/sdkforandroid/developerguide/cognito-auth.html#d0e840">Amazon Cognito Overview</a> in <i>AWS SDK for Android Developer Guide</i> and <a href="https://docs.aws.amazon.com/mobile/sdkforios/developerguide/cognito-auth.html#d0e664">Amazon Cognito Overview</a> in the <i>AWS SDK for iOS Developer Guide</i>.</p> </note> <p>Calling <code>AssumeRoleWithWebIdentity</code> does not require the use of AWS security credentials. Therefore, you can distribute an application (for example, on mobile devices) that requests temporary security credentials without including long-term AWS credentials in the application. You also don't need to deploy server-based proxy services that use long-term AWS credentials. Instead, the identity of the caller is validated by using a token from the web identity provider. For a comparison of <code>AssumeRoleWithWebIdentity</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials returned by this API consist of an access key ID, a secret access key, and a security token. Applications can use these temporary security credentials to sign calls to AWS service API operations.</p> <p> <b>Session Duration</b> </p> <p>By default, the temporary security credentials created by <code>AssumeRoleWithWebIdentity</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. You can provide a value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>. </p> <p> <b>Permissions</b> </p> <p>The temporary security credentials created by <code>AssumeRoleWithWebIdentity</code> can be used to make API calls to any AWS service with the following exception: you cannot call the STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p> <b>Tags</b> </p> <p>(Optional) You can configure your IdP to pass attributes into your web identity token as session tags. Each session tag consists of a key name and an associated value. For more information about session tags, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Passing Session Tags in STS</a> in the <i>IAM User Guide</i>.</p> <p>You can pass up to 50 session tags. The plain text session tag keys can’t exceed 128 characters and the values can’t exceed 256 characters. For these and additional limits, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length">IAM and STS Character Limits</a> in the <i>IAM User Guide</i>.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>You can pass a session tag with the same key as a tag that is attached to the role. When you do, the session tag overrides the role tag with the same key.</p> <p>An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html">Tutorial: Using Tags for Attribute-Based Access Control</a> in the <i>IAM User Guide</i>.</p> <p>You can set the session tags as transitive. Transitive tags persist during role chaining. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining">Chaining Roles with Session Tags</a> in the <i>IAM User Guide</i>.</p> <p> <b>Identities</b> </p> <p>Before your application can call <code>AssumeRoleWithWebIdentity</code>, you must have an identity token from a supported identity provider and create a role that the application can assume. The role that your application assumes must trust the identity provider that is associated with the identity token. In other words, the identity provider must be specified in the role's trust policy. </p> <important> <p>Calling <code>AssumeRoleWithWebIdentity</code> can result in an entry in your AWS CloudTrail logs. The entry includes the <a href="http://openid.net/specs/openid-connect-core-1_0.html#Claims">Subject</a> of the provided Web Identity Token. We recommend that you avoid using any personally identifiable information (PII) in this field. For example, you could instead use a GUID or a pairwise identifier, as <a href="http://openid.net/specs/openid-connect-core-1_0.html#SubjectIDTypes">suggested in the OIDC specification</a>.</p> </important> <p>For more information about how to use web identity federation and the <code>AssumeRoleWithWebIdentity</code> API, see the following resources: </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_oidc_manual.html">Using Web Identity Federation API Operations for Mobile Apps</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity">Federation Through a Web-based Identity Provider</a>. </p> </li> <li> <p> <a href="https://web-identity-federation-playground.s3.amazonaws.com/index.html"> Web Identity Federation Playground</a>. Walk through the process of authenticating through Login with Amazon, Facebook, or Google, getting temporary security credentials, and then using those credentials to make a request to AWS. </p> </li> <li> <p> <a href="http://aws.amazon.com/sdkforios/">AWS SDK for iOS Developer Guide</a> and <a href="http://aws.amazon.com/sdkforandroid/">AWS SDK for Android Developer Guide</a>. These toolkits contain sample apps that show how to invoke the identity providers. The toolkits then show how to use the information from these providers to get and use temporary security credentials. </p> </li> <li> <p> <a href="http://aws.amazon.com/articles/web-identity-federation-with-mobile-applications">Web Identity Federation with Mobile Applications</a>. This article discusses web identity federation and shows an example of how to use web identity federation to get access to content in Amazon S3. </p> </li> </ul>
  ##   ProviderId: string
  ##             : <p>The fully qualified host component of the domain name of the identity provider.</p> <p>Specify this value only for OAuth 2.0 access tokens. Currently <code>www.amazon.com</code> and <code>graph.facebook.com</code> are the only supported identity providers for OAuth 2.0 access tokens. Do not include URL schemes and port numbers.</p> <p>Do not specify this value for OpenID Connect ID tokens.</p>
  ##   RoleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the role that the caller is assuming.
  ##   DurationSeconds: int
  ##                  : <p>The duration, in seconds, of the role session. The value can range from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. If you specify a value higher than this setting, the operation fails. For example, if you specify a session duration of 12 hours, but your administrator set the maximum session duration to 6 hours, your operation fails. To learn how to view the maximum value for your role, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>.</p> <p>By default, the value is set to <code>3600</code> seconds. </p> <note> <p>The <code>DurationSeconds</code> parameter is separate from the duration of a console session that you might request using the returned credentials. The request to the federation endpoint for a console sign-in token takes a <code>SessionDuration</code> parameter that specifies the maximum length of the console session. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html">Creating a URL that Enables Federated Users to Access the AWS Management Console</a> in the <i>IAM User Guide</i>.</p> </note>
  ##   RoleSessionName: string (required)
  ##                  : <p>An identifier for the assumed role session. Typically, you pass the name or identifier that is associated with the user who is using your application. That way, the temporary security credentials that your application will use are associated with that user. This session name is included as part of the ARN and assumed role ID in the <code>AssumedRoleUser</code> response element.</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-</p>
  ##   PolicyArns: JArray
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as managed session policies. The policies must exist in the same account as the role.</p> <p>This parameter is optional. You can provide up to 10 managed policy ARNs. However, the plain text that you use for both inline and managed session policies can't exceed 2,048 characters. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p>
  ##   Action: string (required)
  ##   Policy: string
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>This parameter is optional. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note>
  ##   WebIdentityToken: string (required)
  ##                   : The OAuth 2.0 access token or OpenID Connect ID token that is provided by the identity provider. Your application must get this token by authenticating the user who is using your application with a web identity provider before the application makes an <code>AssumeRoleWithWebIdentity</code> call. 
  ##   Version: string (required)
  var query_600075 = newJObject()
  add(query_600075, "ProviderId", newJString(ProviderId))
  add(query_600075, "RoleArn", newJString(RoleArn))
  add(query_600075, "DurationSeconds", newJInt(DurationSeconds))
  add(query_600075, "RoleSessionName", newJString(RoleSessionName))
  if PolicyArns != nil:
    query_600075.add "PolicyArns", PolicyArns
  add(query_600075, "Action", newJString(Action))
  add(query_600075, "Policy", newJString(Policy))
  add(query_600075, "WebIdentityToken", newJString(WebIdentityToken))
  add(query_600075, "Version", newJString(Version))
  result = call_600074.call(nil, query_600075, nil, nil, nil)

var getAssumeRoleWithWebIdentity* = Call_GetAssumeRoleWithWebIdentity_600054(
    name: "getAssumeRoleWithWebIdentity", meth: HttpMethod.HttpGet,
    host: "sts.amazonaws.com", route: "/#Action=AssumeRoleWithWebIdentity",
    validator: validate_GetAssumeRoleWithWebIdentity_600055, base: "/",
    url: url_GetAssumeRoleWithWebIdentity_600056,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDecodeAuthorizationMessage_600115 = ref object of OpenApiRestCall_599368
proc url_PostDecodeAuthorizationMessage_600117(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDecodeAuthorizationMessage_600116(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Decodes additional information about the authorization status of a request from an encoded message returned in response to an AWS request.</p> <p>For example, if a user is not authorized to perform an operation that he or she has requested, the request returns a <code>Client.UnauthorizedOperation</code> response (an HTTP 403 response). Some AWS operations additionally return an encoded message that can provide details about this authorization failure. </p> <note> <p>Only certain AWS operations return an encoded authorization message. The documentation for an individual operation indicates whether that operation returns an encoded message in addition to returning an HTTP code.</p> </note> <p>The message is encoded because the details of the authorization status can constitute privileged information that the user who requested the operation should not see. To decode an authorization status message, a user must be granted permissions via an IAM policy to request the <code>DecodeAuthorizationMessage</code> (<code>sts:DecodeAuthorizationMessage</code>) action. </p> <p>The decoded message includes the following type of information:</p> <ul> <li> <p>Whether the request was denied due to an explicit deny or due to the absence of an explicit allow. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html#policy-eval-denyallow">Determining Whether a Request is Allowed or Denied</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p>The principal who made the request.</p> </li> <li> <p>The requested action.</p> </li> <li> <p>The requested resource.</p> </li> <li> <p>The values of condition keys in the context of the user's request.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600118 = query.getOrDefault("Action")
  valid_600118 = validateParameter(valid_600118, JString, required = true, default = newJString(
      "DecodeAuthorizationMessage"))
  if valid_600118 != nil:
    section.add "Action", valid_600118
  var valid_600119 = query.getOrDefault("Version")
  valid_600119 = validateParameter(valid_600119, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_600119 != nil:
    section.add "Version", valid_600119
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600120 = header.getOrDefault("X-Amz-Date")
  valid_600120 = validateParameter(valid_600120, JString, required = false,
                                 default = nil)
  if valid_600120 != nil:
    section.add "X-Amz-Date", valid_600120
  var valid_600121 = header.getOrDefault("X-Amz-Security-Token")
  valid_600121 = validateParameter(valid_600121, JString, required = false,
                                 default = nil)
  if valid_600121 != nil:
    section.add "X-Amz-Security-Token", valid_600121
  var valid_600122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "X-Amz-Content-Sha256", valid_600122
  var valid_600123 = header.getOrDefault("X-Amz-Algorithm")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "X-Amz-Algorithm", valid_600123
  var valid_600124 = header.getOrDefault("X-Amz-Signature")
  valid_600124 = validateParameter(valid_600124, JString, required = false,
                                 default = nil)
  if valid_600124 != nil:
    section.add "X-Amz-Signature", valid_600124
  var valid_600125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600125 = validateParameter(valid_600125, JString, required = false,
                                 default = nil)
  if valid_600125 != nil:
    section.add "X-Amz-SignedHeaders", valid_600125
  var valid_600126 = header.getOrDefault("X-Amz-Credential")
  valid_600126 = validateParameter(valid_600126, JString, required = false,
                                 default = nil)
  if valid_600126 != nil:
    section.add "X-Amz-Credential", valid_600126
  result.add "header", section
  ## parameters in `formData` object:
  ##   EncodedMessage: JString (required)
  ##                 : The encoded message that was returned with the response.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `EncodedMessage` field"
  var valid_600127 = formData.getOrDefault("EncodedMessage")
  valid_600127 = validateParameter(valid_600127, JString, required = true,
                                 default = nil)
  if valid_600127 != nil:
    section.add "EncodedMessage", valid_600127
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600128: Call_PostDecodeAuthorizationMessage_600115; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Decodes additional information about the authorization status of a request from an encoded message returned in response to an AWS request.</p> <p>For example, if a user is not authorized to perform an operation that he or she has requested, the request returns a <code>Client.UnauthorizedOperation</code> response (an HTTP 403 response). Some AWS operations additionally return an encoded message that can provide details about this authorization failure. </p> <note> <p>Only certain AWS operations return an encoded authorization message. The documentation for an individual operation indicates whether that operation returns an encoded message in addition to returning an HTTP code.</p> </note> <p>The message is encoded because the details of the authorization status can constitute privileged information that the user who requested the operation should not see. To decode an authorization status message, a user must be granted permissions via an IAM policy to request the <code>DecodeAuthorizationMessage</code> (<code>sts:DecodeAuthorizationMessage</code>) action. </p> <p>The decoded message includes the following type of information:</p> <ul> <li> <p>Whether the request was denied due to an explicit deny or due to the absence of an explicit allow. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html#policy-eval-denyallow">Determining Whether a Request is Allowed or Denied</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p>The principal who made the request.</p> </li> <li> <p>The requested action.</p> </li> <li> <p>The requested resource.</p> </li> <li> <p>The values of condition keys in the context of the user's request.</p> </li> </ul>
  ## 
  let valid = call_600128.validator(path, query, header, formData, body)
  let scheme = call_600128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600128.url(scheme.get, call_600128.host, call_600128.base,
                         call_600128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600128, url, valid)

proc call*(call_600129: Call_PostDecodeAuthorizationMessage_600115;
          EncodedMessage: string; Action: string = "DecodeAuthorizationMessage";
          Version: string = "2011-06-15"): Recallable =
  ## postDecodeAuthorizationMessage
  ## <p>Decodes additional information about the authorization status of a request from an encoded message returned in response to an AWS request.</p> <p>For example, if a user is not authorized to perform an operation that he or she has requested, the request returns a <code>Client.UnauthorizedOperation</code> response (an HTTP 403 response). Some AWS operations additionally return an encoded message that can provide details about this authorization failure. </p> <note> <p>Only certain AWS operations return an encoded authorization message. The documentation for an individual operation indicates whether that operation returns an encoded message in addition to returning an HTTP code.</p> </note> <p>The message is encoded because the details of the authorization status can constitute privileged information that the user who requested the operation should not see. To decode an authorization status message, a user must be granted permissions via an IAM policy to request the <code>DecodeAuthorizationMessage</code> (<code>sts:DecodeAuthorizationMessage</code>) action. </p> <p>The decoded message includes the following type of information:</p> <ul> <li> <p>Whether the request was denied due to an explicit deny or due to the absence of an explicit allow. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html#policy-eval-denyallow">Determining Whether a Request is Allowed or Denied</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p>The principal who made the request.</p> </li> <li> <p>The requested action.</p> </li> <li> <p>The requested resource.</p> </li> <li> <p>The values of condition keys in the context of the user's request.</p> </li> </ul>
  ##   Action: string (required)
  ##   EncodedMessage: string (required)
  ##                 : The encoded message that was returned with the response.
  ##   Version: string (required)
  var query_600130 = newJObject()
  var formData_600131 = newJObject()
  add(query_600130, "Action", newJString(Action))
  add(formData_600131, "EncodedMessage", newJString(EncodedMessage))
  add(query_600130, "Version", newJString(Version))
  result = call_600129.call(nil, query_600130, nil, formData_600131, nil)

var postDecodeAuthorizationMessage* = Call_PostDecodeAuthorizationMessage_600115(
    name: "postDecodeAuthorizationMessage", meth: HttpMethod.HttpPost,
    host: "sts.amazonaws.com", route: "/#Action=DecodeAuthorizationMessage",
    validator: validate_PostDecodeAuthorizationMessage_600116, base: "/",
    url: url_PostDecodeAuthorizationMessage_600117,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDecodeAuthorizationMessage_600099 = ref object of OpenApiRestCall_599368
proc url_GetDecodeAuthorizationMessage_600101(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDecodeAuthorizationMessage_600100(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Decodes additional information about the authorization status of a request from an encoded message returned in response to an AWS request.</p> <p>For example, if a user is not authorized to perform an operation that he or she has requested, the request returns a <code>Client.UnauthorizedOperation</code> response (an HTTP 403 response). Some AWS operations additionally return an encoded message that can provide details about this authorization failure. </p> <note> <p>Only certain AWS operations return an encoded authorization message. The documentation for an individual operation indicates whether that operation returns an encoded message in addition to returning an HTTP code.</p> </note> <p>The message is encoded because the details of the authorization status can constitute privileged information that the user who requested the operation should not see. To decode an authorization status message, a user must be granted permissions via an IAM policy to request the <code>DecodeAuthorizationMessage</code> (<code>sts:DecodeAuthorizationMessage</code>) action. </p> <p>The decoded message includes the following type of information:</p> <ul> <li> <p>Whether the request was denied due to an explicit deny or due to the absence of an explicit allow. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html#policy-eval-denyallow">Determining Whether a Request is Allowed or Denied</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p>The principal who made the request.</p> </li> <li> <p>The requested action.</p> </li> <li> <p>The requested resource.</p> </li> <li> <p>The values of condition keys in the context of the user's request.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   EncodedMessage: JString (required)
  ##                 : The encoded message that was returned with the response.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600102 = query.getOrDefault("Action")
  valid_600102 = validateParameter(valid_600102, JString, required = true, default = newJString(
      "DecodeAuthorizationMessage"))
  if valid_600102 != nil:
    section.add "Action", valid_600102
  var valid_600103 = query.getOrDefault("Version")
  valid_600103 = validateParameter(valid_600103, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_600103 != nil:
    section.add "Version", valid_600103
  var valid_600104 = query.getOrDefault("EncodedMessage")
  valid_600104 = validateParameter(valid_600104, JString, required = true,
                                 default = nil)
  if valid_600104 != nil:
    section.add "EncodedMessage", valid_600104
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600105 = header.getOrDefault("X-Amz-Date")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "X-Amz-Date", valid_600105
  var valid_600106 = header.getOrDefault("X-Amz-Security-Token")
  valid_600106 = validateParameter(valid_600106, JString, required = false,
                                 default = nil)
  if valid_600106 != nil:
    section.add "X-Amz-Security-Token", valid_600106
  var valid_600107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600107 = validateParameter(valid_600107, JString, required = false,
                                 default = nil)
  if valid_600107 != nil:
    section.add "X-Amz-Content-Sha256", valid_600107
  var valid_600108 = header.getOrDefault("X-Amz-Algorithm")
  valid_600108 = validateParameter(valid_600108, JString, required = false,
                                 default = nil)
  if valid_600108 != nil:
    section.add "X-Amz-Algorithm", valid_600108
  var valid_600109 = header.getOrDefault("X-Amz-Signature")
  valid_600109 = validateParameter(valid_600109, JString, required = false,
                                 default = nil)
  if valid_600109 != nil:
    section.add "X-Amz-Signature", valid_600109
  var valid_600110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600110 = validateParameter(valid_600110, JString, required = false,
                                 default = nil)
  if valid_600110 != nil:
    section.add "X-Amz-SignedHeaders", valid_600110
  var valid_600111 = header.getOrDefault("X-Amz-Credential")
  valid_600111 = validateParameter(valid_600111, JString, required = false,
                                 default = nil)
  if valid_600111 != nil:
    section.add "X-Amz-Credential", valid_600111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600112: Call_GetDecodeAuthorizationMessage_600099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Decodes additional information about the authorization status of a request from an encoded message returned in response to an AWS request.</p> <p>For example, if a user is not authorized to perform an operation that he or she has requested, the request returns a <code>Client.UnauthorizedOperation</code> response (an HTTP 403 response). Some AWS operations additionally return an encoded message that can provide details about this authorization failure. </p> <note> <p>Only certain AWS operations return an encoded authorization message. The documentation for an individual operation indicates whether that operation returns an encoded message in addition to returning an HTTP code.</p> </note> <p>The message is encoded because the details of the authorization status can constitute privileged information that the user who requested the operation should not see. To decode an authorization status message, a user must be granted permissions via an IAM policy to request the <code>DecodeAuthorizationMessage</code> (<code>sts:DecodeAuthorizationMessage</code>) action. </p> <p>The decoded message includes the following type of information:</p> <ul> <li> <p>Whether the request was denied due to an explicit deny or due to the absence of an explicit allow. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html#policy-eval-denyallow">Determining Whether a Request is Allowed or Denied</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p>The principal who made the request.</p> </li> <li> <p>The requested action.</p> </li> <li> <p>The requested resource.</p> </li> <li> <p>The values of condition keys in the context of the user's request.</p> </li> </ul>
  ## 
  let valid = call_600112.validator(path, query, header, formData, body)
  let scheme = call_600112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600112.url(scheme.get, call_600112.host, call_600112.base,
                         call_600112.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600112, url, valid)

proc call*(call_600113: Call_GetDecodeAuthorizationMessage_600099;
          EncodedMessage: string; Action: string = "DecodeAuthorizationMessage";
          Version: string = "2011-06-15"): Recallable =
  ## getDecodeAuthorizationMessage
  ## <p>Decodes additional information about the authorization status of a request from an encoded message returned in response to an AWS request.</p> <p>For example, if a user is not authorized to perform an operation that he or she has requested, the request returns a <code>Client.UnauthorizedOperation</code> response (an HTTP 403 response). Some AWS operations additionally return an encoded message that can provide details about this authorization failure. </p> <note> <p>Only certain AWS operations return an encoded authorization message. The documentation for an individual operation indicates whether that operation returns an encoded message in addition to returning an HTTP code.</p> </note> <p>The message is encoded because the details of the authorization status can constitute privileged information that the user who requested the operation should not see. To decode an authorization status message, a user must be granted permissions via an IAM policy to request the <code>DecodeAuthorizationMessage</code> (<code>sts:DecodeAuthorizationMessage</code>) action. </p> <p>The decoded message includes the following type of information:</p> <ul> <li> <p>Whether the request was denied due to an explicit deny or due to the absence of an explicit allow. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html#policy-eval-denyallow">Determining Whether a Request is Allowed or Denied</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p>The principal who made the request.</p> </li> <li> <p>The requested action.</p> </li> <li> <p>The requested resource.</p> </li> <li> <p>The values of condition keys in the context of the user's request.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   EncodedMessage: string (required)
  ##                 : The encoded message that was returned with the response.
  var query_600114 = newJObject()
  add(query_600114, "Action", newJString(Action))
  add(query_600114, "Version", newJString(Version))
  add(query_600114, "EncodedMessage", newJString(EncodedMessage))
  result = call_600113.call(nil, query_600114, nil, nil, nil)

var getDecodeAuthorizationMessage* = Call_GetDecodeAuthorizationMessage_600099(
    name: "getDecodeAuthorizationMessage", meth: HttpMethod.HttpGet,
    host: "sts.amazonaws.com", route: "/#Action=DecodeAuthorizationMessage",
    validator: validate_GetDecodeAuthorizationMessage_600100, base: "/",
    url: url_GetDecodeAuthorizationMessage_600101,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetAccessKeyInfo_600148 = ref object of OpenApiRestCall_599368
proc url_PostGetAccessKeyInfo_600150(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetAccessKeyInfo_600149(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the account identifier for the specified access key ID.</p> <p>Access keys consist of two parts: an access key ID (for example, <code>AKIAIOSFODNN7EXAMPLE</code>) and a secret access key (for example, <code>wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY</code>). For more information about access keys, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html">Managing Access Keys for IAM Users</a> in the <i>IAM User Guide</i>.</p> <p>When you pass an access key ID to this operation, it returns the ID of the AWS account to which the keys belong. Access key IDs beginning with <code>AKIA</code> are long-term credentials for an IAM user or the AWS account root user. Access key IDs beginning with <code>ASIA</code> are temporary credentials that are created using STS operations. If the account in the response belongs to you, you can sign in as the root user and review your root user access keys. Then, you can pull a <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_getting-report.html">credentials report</a> to learn which IAM user owns the keys. To learn who requested the temporary credentials for an <code>ASIA</code> access key, view the STS events in your <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/cloudtrail-integration.html">CloudTrail logs</a> in the <i>IAM User Guide</i>.</p> <p>This operation does not indicate the state of the access key. The key might be active, inactive, or deleted. Active keys might not have permissions to perform an operation. Providing a deleted access key might return an error that the key doesn't exist.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600151 = query.getOrDefault("Action")
  valid_600151 = validateParameter(valid_600151, JString, required = true,
                                 default = newJString("GetAccessKeyInfo"))
  if valid_600151 != nil:
    section.add "Action", valid_600151
  var valid_600152 = query.getOrDefault("Version")
  valid_600152 = validateParameter(valid_600152, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_600152 != nil:
    section.add "Version", valid_600152
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600153 = header.getOrDefault("X-Amz-Date")
  valid_600153 = validateParameter(valid_600153, JString, required = false,
                                 default = nil)
  if valid_600153 != nil:
    section.add "X-Amz-Date", valid_600153
  var valid_600154 = header.getOrDefault("X-Amz-Security-Token")
  valid_600154 = validateParameter(valid_600154, JString, required = false,
                                 default = nil)
  if valid_600154 != nil:
    section.add "X-Amz-Security-Token", valid_600154
  var valid_600155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600155 = validateParameter(valid_600155, JString, required = false,
                                 default = nil)
  if valid_600155 != nil:
    section.add "X-Amz-Content-Sha256", valid_600155
  var valid_600156 = header.getOrDefault("X-Amz-Algorithm")
  valid_600156 = validateParameter(valid_600156, JString, required = false,
                                 default = nil)
  if valid_600156 != nil:
    section.add "X-Amz-Algorithm", valid_600156
  var valid_600157 = header.getOrDefault("X-Amz-Signature")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Signature", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-SignedHeaders", valid_600158
  var valid_600159 = header.getOrDefault("X-Amz-Credential")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "X-Amz-Credential", valid_600159
  result.add "header", section
  ## parameters in `formData` object:
  ##   AccessKeyId: JString (required)
  ##              : <p>The identifier of an access key.</p> <p>This parameter allows (through its regex pattern) a string of characters that can consist of any upper- or lowercase letter or digit.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AccessKeyId` field"
  var valid_600160 = formData.getOrDefault("AccessKeyId")
  valid_600160 = validateParameter(valid_600160, JString, required = true,
                                 default = nil)
  if valid_600160 != nil:
    section.add "AccessKeyId", valid_600160
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600161: Call_PostGetAccessKeyInfo_600148; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the account identifier for the specified access key ID.</p> <p>Access keys consist of two parts: an access key ID (for example, <code>AKIAIOSFODNN7EXAMPLE</code>) and a secret access key (for example, <code>wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY</code>). For more information about access keys, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html">Managing Access Keys for IAM Users</a> in the <i>IAM User Guide</i>.</p> <p>When you pass an access key ID to this operation, it returns the ID of the AWS account to which the keys belong. Access key IDs beginning with <code>AKIA</code> are long-term credentials for an IAM user or the AWS account root user. Access key IDs beginning with <code>ASIA</code> are temporary credentials that are created using STS operations. If the account in the response belongs to you, you can sign in as the root user and review your root user access keys. Then, you can pull a <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_getting-report.html">credentials report</a> to learn which IAM user owns the keys. To learn who requested the temporary credentials for an <code>ASIA</code> access key, view the STS events in your <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/cloudtrail-integration.html">CloudTrail logs</a> in the <i>IAM User Guide</i>.</p> <p>This operation does not indicate the state of the access key. The key might be active, inactive, or deleted. Active keys might not have permissions to perform an operation. Providing a deleted access key might return an error that the key doesn't exist.</p>
  ## 
  let valid = call_600161.validator(path, query, header, formData, body)
  let scheme = call_600161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600161.url(scheme.get, call_600161.host, call_600161.base,
                         call_600161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600161, url, valid)

proc call*(call_600162: Call_PostGetAccessKeyInfo_600148; AccessKeyId: string;
          Action: string = "GetAccessKeyInfo"; Version: string = "2011-06-15"): Recallable =
  ## postGetAccessKeyInfo
  ## <p>Returns the account identifier for the specified access key ID.</p> <p>Access keys consist of two parts: an access key ID (for example, <code>AKIAIOSFODNN7EXAMPLE</code>) and a secret access key (for example, <code>wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY</code>). For more information about access keys, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html">Managing Access Keys for IAM Users</a> in the <i>IAM User Guide</i>.</p> <p>When you pass an access key ID to this operation, it returns the ID of the AWS account to which the keys belong. Access key IDs beginning with <code>AKIA</code> are long-term credentials for an IAM user or the AWS account root user. Access key IDs beginning with <code>ASIA</code> are temporary credentials that are created using STS operations. If the account in the response belongs to you, you can sign in as the root user and review your root user access keys. Then, you can pull a <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_getting-report.html">credentials report</a> to learn which IAM user owns the keys. To learn who requested the temporary credentials for an <code>ASIA</code> access key, view the STS events in your <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/cloudtrail-integration.html">CloudTrail logs</a> in the <i>IAM User Guide</i>.</p> <p>This operation does not indicate the state of the access key. The key might be active, inactive, or deleted. Active keys might not have permissions to perform an operation. Providing a deleted access key might return an error that the key doesn't exist.</p>
  ##   AccessKeyId: string (required)
  ##              : <p>The identifier of an access key.</p> <p>This parameter allows (through its regex pattern) a string of characters that can consist of any upper- or lowercase letter or digit.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600163 = newJObject()
  var formData_600164 = newJObject()
  add(formData_600164, "AccessKeyId", newJString(AccessKeyId))
  add(query_600163, "Action", newJString(Action))
  add(query_600163, "Version", newJString(Version))
  result = call_600162.call(nil, query_600163, nil, formData_600164, nil)

var postGetAccessKeyInfo* = Call_PostGetAccessKeyInfo_600148(
    name: "postGetAccessKeyInfo", meth: HttpMethod.HttpPost,
    host: "sts.amazonaws.com", route: "/#Action=GetAccessKeyInfo",
    validator: validate_PostGetAccessKeyInfo_600149, base: "/",
    url: url_PostGetAccessKeyInfo_600150, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetAccessKeyInfo_600132 = ref object of OpenApiRestCall_599368
proc url_GetGetAccessKeyInfo_600134(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetAccessKeyInfo_600133(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Returns the account identifier for the specified access key ID.</p> <p>Access keys consist of two parts: an access key ID (for example, <code>AKIAIOSFODNN7EXAMPLE</code>) and a secret access key (for example, <code>wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY</code>). For more information about access keys, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html">Managing Access Keys for IAM Users</a> in the <i>IAM User Guide</i>.</p> <p>When you pass an access key ID to this operation, it returns the ID of the AWS account to which the keys belong. Access key IDs beginning with <code>AKIA</code> are long-term credentials for an IAM user or the AWS account root user. Access key IDs beginning with <code>ASIA</code> are temporary credentials that are created using STS operations. If the account in the response belongs to you, you can sign in as the root user and review your root user access keys. Then, you can pull a <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_getting-report.html">credentials report</a> to learn which IAM user owns the keys. To learn who requested the temporary credentials for an <code>ASIA</code> access key, view the STS events in your <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/cloudtrail-integration.html">CloudTrail logs</a> in the <i>IAM User Guide</i>.</p> <p>This operation does not indicate the state of the access key. The key might be active, inactive, or deleted. Active keys might not have permissions to perform an operation. Providing a deleted access key might return an error that the key doesn't exist.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   AccessKeyId: JString (required)
  ##              : <p>The identifier of an access key.</p> <p>This parameter allows (through its regex pattern) a string of characters that can consist of any upper- or lowercase letter or digit.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `AccessKeyId` field"
  var valid_600135 = query.getOrDefault("AccessKeyId")
  valid_600135 = validateParameter(valid_600135, JString, required = true,
                                 default = nil)
  if valid_600135 != nil:
    section.add "AccessKeyId", valid_600135
  var valid_600136 = query.getOrDefault("Action")
  valid_600136 = validateParameter(valid_600136, JString, required = true,
                                 default = newJString("GetAccessKeyInfo"))
  if valid_600136 != nil:
    section.add "Action", valid_600136
  var valid_600137 = query.getOrDefault("Version")
  valid_600137 = validateParameter(valid_600137, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_600137 != nil:
    section.add "Version", valid_600137
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600138 = header.getOrDefault("X-Amz-Date")
  valid_600138 = validateParameter(valid_600138, JString, required = false,
                                 default = nil)
  if valid_600138 != nil:
    section.add "X-Amz-Date", valid_600138
  var valid_600139 = header.getOrDefault("X-Amz-Security-Token")
  valid_600139 = validateParameter(valid_600139, JString, required = false,
                                 default = nil)
  if valid_600139 != nil:
    section.add "X-Amz-Security-Token", valid_600139
  var valid_600140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600140 = validateParameter(valid_600140, JString, required = false,
                                 default = nil)
  if valid_600140 != nil:
    section.add "X-Amz-Content-Sha256", valid_600140
  var valid_600141 = header.getOrDefault("X-Amz-Algorithm")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "X-Amz-Algorithm", valid_600141
  var valid_600142 = header.getOrDefault("X-Amz-Signature")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Signature", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-SignedHeaders", valid_600143
  var valid_600144 = header.getOrDefault("X-Amz-Credential")
  valid_600144 = validateParameter(valid_600144, JString, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "X-Amz-Credential", valid_600144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600145: Call_GetGetAccessKeyInfo_600132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the account identifier for the specified access key ID.</p> <p>Access keys consist of two parts: an access key ID (for example, <code>AKIAIOSFODNN7EXAMPLE</code>) and a secret access key (for example, <code>wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY</code>). For more information about access keys, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html">Managing Access Keys for IAM Users</a> in the <i>IAM User Guide</i>.</p> <p>When you pass an access key ID to this operation, it returns the ID of the AWS account to which the keys belong. Access key IDs beginning with <code>AKIA</code> are long-term credentials for an IAM user or the AWS account root user. Access key IDs beginning with <code>ASIA</code> are temporary credentials that are created using STS operations. If the account in the response belongs to you, you can sign in as the root user and review your root user access keys. Then, you can pull a <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_getting-report.html">credentials report</a> to learn which IAM user owns the keys. To learn who requested the temporary credentials for an <code>ASIA</code> access key, view the STS events in your <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/cloudtrail-integration.html">CloudTrail logs</a> in the <i>IAM User Guide</i>.</p> <p>This operation does not indicate the state of the access key. The key might be active, inactive, or deleted. Active keys might not have permissions to perform an operation. Providing a deleted access key might return an error that the key doesn't exist.</p>
  ## 
  let valid = call_600145.validator(path, query, header, formData, body)
  let scheme = call_600145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600145.url(scheme.get, call_600145.host, call_600145.base,
                         call_600145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600145, url, valid)

proc call*(call_600146: Call_GetGetAccessKeyInfo_600132; AccessKeyId: string;
          Action: string = "GetAccessKeyInfo"; Version: string = "2011-06-15"): Recallable =
  ## getGetAccessKeyInfo
  ## <p>Returns the account identifier for the specified access key ID.</p> <p>Access keys consist of two parts: an access key ID (for example, <code>AKIAIOSFODNN7EXAMPLE</code>) and a secret access key (for example, <code>wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY</code>). For more information about access keys, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html">Managing Access Keys for IAM Users</a> in the <i>IAM User Guide</i>.</p> <p>When you pass an access key ID to this operation, it returns the ID of the AWS account to which the keys belong. Access key IDs beginning with <code>AKIA</code> are long-term credentials for an IAM user or the AWS account root user. Access key IDs beginning with <code>ASIA</code> are temporary credentials that are created using STS operations. If the account in the response belongs to you, you can sign in as the root user and review your root user access keys. Then, you can pull a <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_getting-report.html">credentials report</a> to learn which IAM user owns the keys. To learn who requested the temporary credentials for an <code>ASIA</code> access key, view the STS events in your <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/cloudtrail-integration.html">CloudTrail logs</a> in the <i>IAM User Guide</i>.</p> <p>This operation does not indicate the state of the access key. The key might be active, inactive, or deleted. Active keys might not have permissions to perform an operation. Providing a deleted access key might return an error that the key doesn't exist.</p>
  ##   AccessKeyId: string (required)
  ##              : <p>The identifier of an access key.</p> <p>This parameter allows (through its regex pattern) a string of characters that can consist of any upper- or lowercase letter or digit.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600147 = newJObject()
  add(query_600147, "AccessKeyId", newJString(AccessKeyId))
  add(query_600147, "Action", newJString(Action))
  add(query_600147, "Version", newJString(Version))
  result = call_600146.call(nil, query_600147, nil, nil, nil)

var getGetAccessKeyInfo* = Call_GetGetAccessKeyInfo_600132(
    name: "getGetAccessKeyInfo", meth: HttpMethod.HttpGet,
    host: "sts.amazonaws.com", route: "/#Action=GetAccessKeyInfo",
    validator: validate_GetGetAccessKeyInfo_600133, base: "/",
    url: url_GetGetAccessKeyInfo_600134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetCallerIdentity_600180 = ref object of OpenApiRestCall_599368
proc url_PostGetCallerIdentity_600182(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetCallerIdentity_600181(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns details about the IAM user or role whose credentials are used to call the operation.</p> <note> <p>No permissions are required to perform this operation. If an administrator adds a policy to your IAM user or role that explicitly denies access to the <code>sts:GetCallerIdentity</code> action, you can still perform this operation. Permissions are not required because the same information is returned when an IAM user or role is denied access. To view an example response, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html#troubleshoot_general_access-denied-delete-mfa">I Am Not Authorized to Perform: iam:DeleteVirtualMFADevice</a> in the <i>IAM User Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600183 = query.getOrDefault("Action")
  valid_600183 = validateParameter(valid_600183, JString, required = true,
                                 default = newJString("GetCallerIdentity"))
  if valid_600183 != nil:
    section.add "Action", valid_600183
  var valid_600184 = query.getOrDefault("Version")
  valid_600184 = validateParameter(valid_600184, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_600184 != nil:
    section.add "Version", valid_600184
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600185 = header.getOrDefault("X-Amz-Date")
  valid_600185 = validateParameter(valid_600185, JString, required = false,
                                 default = nil)
  if valid_600185 != nil:
    section.add "X-Amz-Date", valid_600185
  var valid_600186 = header.getOrDefault("X-Amz-Security-Token")
  valid_600186 = validateParameter(valid_600186, JString, required = false,
                                 default = nil)
  if valid_600186 != nil:
    section.add "X-Amz-Security-Token", valid_600186
  var valid_600187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "X-Amz-Content-Sha256", valid_600187
  var valid_600188 = header.getOrDefault("X-Amz-Algorithm")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-Algorithm", valid_600188
  var valid_600189 = header.getOrDefault("X-Amz-Signature")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-Signature", valid_600189
  var valid_600190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-SignedHeaders", valid_600190
  var valid_600191 = header.getOrDefault("X-Amz-Credential")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "X-Amz-Credential", valid_600191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600192: Call_PostGetCallerIdentity_600180; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns details about the IAM user or role whose credentials are used to call the operation.</p> <note> <p>No permissions are required to perform this operation. If an administrator adds a policy to your IAM user or role that explicitly denies access to the <code>sts:GetCallerIdentity</code> action, you can still perform this operation. Permissions are not required because the same information is returned when an IAM user or role is denied access. To view an example response, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html#troubleshoot_general_access-denied-delete-mfa">I Am Not Authorized to Perform: iam:DeleteVirtualMFADevice</a> in the <i>IAM User Guide</i>.</p> </note>
  ## 
  let valid = call_600192.validator(path, query, header, formData, body)
  let scheme = call_600192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600192.url(scheme.get, call_600192.host, call_600192.base,
                         call_600192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600192, url, valid)

proc call*(call_600193: Call_PostGetCallerIdentity_600180;
          Action: string = "GetCallerIdentity"; Version: string = "2011-06-15"): Recallable =
  ## postGetCallerIdentity
  ## <p>Returns details about the IAM user or role whose credentials are used to call the operation.</p> <note> <p>No permissions are required to perform this operation. If an administrator adds a policy to your IAM user or role that explicitly denies access to the <code>sts:GetCallerIdentity</code> action, you can still perform this operation. Permissions are not required because the same information is returned when an IAM user or role is denied access. To view an example response, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html#troubleshoot_general_access-denied-delete-mfa">I Am Not Authorized to Perform: iam:DeleteVirtualMFADevice</a> in the <i>IAM User Guide</i>.</p> </note>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600194 = newJObject()
  add(query_600194, "Action", newJString(Action))
  add(query_600194, "Version", newJString(Version))
  result = call_600193.call(nil, query_600194, nil, nil, nil)

var postGetCallerIdentity* = Call_PostGetCallerIdentity_600180(
    name: "postGetCallerIdentity", meth: HttpMethod.HttpPost,
    host: "sts.amazonaws.com", route: "/#Action=GetCallerIdentity",
    validator: validate_PostGetCallerIdentity_600181, base: "/",
    url: url_PostGetCallerIdentity_600182, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetCallerIdentity_600165 = ref object of OpenApiRestCall_599368
proc url_GetGetCallerIdentity_600167(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetCallerIdentity_600166(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns details about the IAM user or role whose credentials are used to call the operation.</p> <note> <p>No permissions are required to perform this operation. If an administrator adds a policy to your IAM user or role that explicitly denies access to the <code>sts:GetCallerIdentity</code> action, you can still perform this operation. Permissions are not required because the same information is returned when an IAM user or role is denied access. To view an example response, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html#troubleshoot_general_access-denied-delete-mfa">I Am Not Authorized to Perform: iam:DeleteVirtualMFADevice</a> in the <i>IAM User Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600168 = query.getOrDefault("Action")
  valid_600168 = validateParameter(valid_600168, JString, required = true,
                                 default = newJString("GetCallerIdentity"))
  if valid_600168 != nil:
    section.add "Action", valid_600168
  var valid_600169 = query.getOrDefault("Version")
  valid_600169 = validateParameter(valid_600169, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_600169 != nil:
    section.add "Version", valid_600169
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600170 = header.getOrDefault("X-Amz-Date")
  valid_600170 = validateParameter(valid_600170, JString, required = false,
                                 default = nil)
  if valid_600170 != nil:
    section.add "X-Amz-Date", valid_600170
  var valid_600171 = header.getOrDefault("X-Amz-Security-Token")
  valid_600171 = validateParameter(valid_600171, JString, required = false,
                                 default = nil)
  if valid_600171 != nil:
    section.add "X-Amz-Security-Token", valid_600171
  var valid_600172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-Content-Sha256", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-Algorithm")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-Algorithm", valid_600173
  var valid_600174 = header.getOrDefault("X-Amz-Signature")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "X-Amz-Signature", valid_600174
  var valid_600175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-SignedHeaders", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-Credential")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-Credential", valid_600176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600177: Call_GetGetCallerIdentity_600165; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns details about the IAM user or role whose credentials are used to call the operation.</p> <note> <p>No permissions are required to perform this operation. If an administrator adds a policy to your IAM user or role that explicitly denies access to the <code>sts:GetCallerIdentity</code> action, you can still perform this operation. Permissions are not required because the same information is returned when an IAM user or role is denied access. To view an example response, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html#troubleshoot_general_access-denied-delete-mfa">I Am Not Authorized to Perform: iam:DeleteVirtualMFADevice</a> in the <i>IAM User Guide</i>.</p> </note>
  ## 
  let valid = call_600177.validator(path, query, header, formData, body)
  let scheme = call_600177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600177.url(scheme.get, call_600177.host, call_600177.base,
                         call_600177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600177, url, valid)

proc call*(call_600178: Call_GetGetCallerIdentity_600165;
          Action: string = "GetCallerIdentity"; Version: string = "2011-06-15"): Recallable =
  ## getGetCallerIdentity
  ## <p>Returns details about the IAM user or role whose credentials are used to call the operation.</p> <note> <p>No permissions are required to perform this operation. If an administrator adds a policy to your IAM user or role that explicitly denies access to the <code>sts:GetCallerIdentity</code> action, you can still perform this operation. Permissions are not required because the same information is returned when an IAM user or role is denied access. To view an example response, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html#troubleshoot_general_access-denied-delete-mfa">I Am Not Authorized to Perform: iam:DeleteVirtualMFADevice</a> in the <i>IAM User Guide</i>.</p> </note>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600179 = newJObject()
  add(query_600179, "Action", newJString(Action))
  add(query_600179, "Version", newJString(Version))
  result = call_600178.call(nil, query_600179, nil, nil, nil)

var getGetCallerIdentity* = Call_GetGetCallerIdentity_600165(
    name: "getGetCallerIdentity", meth: HttpMethod.HttpGet,
    host: "sts.amazonaws.com", route: "/#Action=GetCallerIdentity",
    validator: validate_GetGetCallerIdentity_600166, base: "/",
    url: url_GetGetCallerIdentity_600167, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetFederationToken_600215 = ref object of OpenApiRestCall_599368
proc url_PostGetFederationToken_600217(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetFederationToken_600216(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a set of temporary security credentials (consisting of an access key ID, a secret access key, and a security token) for a federated user. A typical use is in a proxy application that gets temporary security credentials on behalf of distributed applications inside a corporate network. You must call the <code>GetFederationToken</code> operation using the long-term security credentials of an IAM user. As a result, this call is appropriate in contexts where those credentials can be safely stored, usually in a server-based application. For a comparison of <code>GetFederationToken</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <note> <p>You can create a mobile-based or browser-based app that can authenticate users using a web identity provider like Login with Amazon, Facebook, Google, or an OpenID Connect-compatible identity provider. In this case, we recommend that you use <a href="http://aws.amazon.com/cognito/">Amazon Cognito</a> or <code>AssumeRoleWithWebIdentity</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity">Federation Through a Web-based Identity Provider</a> in the <i>IAM User Guide</i>.</p> </note> <p>You can also call <code>GetFederationToken</code> using the security credentials of an AWS account root user, but we do not recommend it. Instead, we recommend that you create an IAM user for the purpose of the proxy application. Then attach a policy to the IAM user that limits federated users to only the actions and resources that they need to access. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html">IAM Best Practices</a> in the <i>IAM User Guide</i>. </p> <p> <b>Session duration</b> </p> <p>The temporary credentials are valid for the specified duration, from 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36 hours). The default session duration is 43,200 seconds (12 hours). Temporary credentials that are obtained by using AWS account root user credentials have a maximum duration of 3,600 seconds (1 hour).</p> <p> <b>Permissions</b> </p> <p>You can use the temporary credentials created by <code>GetFederationToken</code> in any AWS service except the following:</p> <ul> <li> <p>You cannot call any IAM operations using the AWS CLI or the AWS API. </p> </li> <li> <p>You cannot call any STS operations except <code>GetCallerIdentity</code>.</p> </li> </ul> <p>You must pass an inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policy</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies can't exceed 2,048 characters.</p> <p>Though the session policy parameters are optional, if you do not pass a policy, then the resulting federated user session has no permissions. When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>. For information about using <code>GetFederationToken</code> to create temporary security credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getfederationtoken">GetFederationToken—Federation Through a Custom Identity Broker</a>. </p> <p>You can use the credentials to access a resource that has a resource-based policy. If that policy specifically references the federated user session in the <code>Principal</code> element of the policy, the session has the permissions allowed by the policy. These permissions are granted in addition to the permissions granted by the session policies.</p> <p> <b>Tags</b> </p> <p>(Optional) You can pass tag key-value pairs to your session. These are called session tags. For more information about session tags, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Passing Session Tags in STS</a> in the <i>IAM User Guide</i>.</p> <p>An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html">Tutorial: Using Tags for Attribute-Based Access Control</a> in the <i>IAM User Guide</i>.</p> <p>Tag key–value pairs are not case sensitive, but case is preserved. This means that you cannot have separate <code>Department</code> and <code>department</code> tag keys. Assume that the user that you are federating has the <code>Department</code>=<code>Marketing</code> tag and you pass the <code>department</code>=<code>engineering</code> session tag. <code>Department</code> and <code>department</code> are not saved as separate tags, and the session tag passed in the request takes precedence over the user tag.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600218 = query.getOrDefault("Action")
  valid_600218 = validateParameter(valid_600218, JString, required = true,
                                 default = newJString("GetFederationToken"))
  if valid_600218 != nil:
    section.add "Action", valid_600218
  var valid_600219 = query.getOrDefault("Version")
  valid_600219 = validateParameter(valid_600219, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_600219 != nil:
    section.add "Version", valid_600219
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600220 = header.getOrDefault("X-Amz-Date")
  valid_600220 = validateParameter(valid_600220, JString, required = false,
                                 default = nil)
  if valid_600220 != nil:
    section.add "X-Amz-Date", valid_600220
  var valid_600221 = header.getOrDefault("X-Amz-Security-Token")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "X-Amz-Security-Token", valid_600221
  var valid_600222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600222 = validateParameter(valid_600222, JString, required = false,
                                 default = nil)
  if valid_600222 != nil:
    section.add "X-Amz-Content-Sha256", valid_600222
  var valid_600223 = header.getOrDefault("X-Amz-Algorithm")
  valid_600223 = validateParameter(valid_600223, JString, required = false,
                                 default = nil)
  if valid_600223 != nil:
    section.add "X-Amz-Algorithm", valid_600223
  var valid_600224 = header.getOrDefault("X-Amz-Signature")
  valid_600224 = validateParameter(valid_600224, JString, required = false,
                                 default = nil)
  if valid_600224 != nil:
    section.add "X-Amz-Signature", valid_600224
  var valid_600225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600225 = validateParameter(valid_600225, JString, required = false,
                                 default = nil)
  if valid_600225 != nil:
    section.add "X-Amz-SignedHeaders", valid_600225
  var valid_600226 = header.getOrDefault("X-Amz-Credential")
  valid_600226 = validateParameter(valid_600226, JString, required = false,
                                 default = nil)
  if valid_600226 != nil:
    section.add "X-Amz-Credential", valid_600226
  result.add "header", section
  ## parameters in `formData` object:
  ##   Name: JString (required)
  ##       : <p>The name of the federated user. The name is used as an identifier for the temporary security credentials (such as <code>Bob</code>). For example, you can reference the federated user name in a resource-based policy, such as in an Amazon S3 bucket policy.</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-</p>
  ##   Tags: JArray
  ##       : <p>A list of session tags. Each session tag consists of a key name and an associated value. For more information about session tags, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Passing Session Tags in STS</a> in the <i>IAM User Guide</i>.</p> <p>This parameter is optional. You can pass up to 50 session tags. The plain text session tag keys can’t exceed 128 characters and the values can’t exceed 256 characters. For these and additional limits, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length">IAM and STS Character Limits</a> in the <i>IAM User Guide</i>.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>You can pass a session tag with the same key as a tag that is already attached to the user you are federating. When you do, session tags override a user tag with the same key. </p> <p>Tag key–value pairs are not case sensitive, but case is preserved. This means that you cannot have separate <code>Department</code> and <code>department</code> tag keys. Assume that the role has the <code>Department</code>=<code>Marketing</code> tag and you pass the <code>department</code>=<code>engineering</code> session tag. <code>Department</code> and <code>department</code> are not saved as separate tags, and the session tag passed in the request takes precedence over the role tag.</p>
  ##   PolicyArns: JArray
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as a managed session policy. The policies must exist in the same account as the IAM user that is requesting federated access.</p> <p>You must pass an inline or managed <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policy</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. You can provide up to 10 managed policy ARNs. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <p>This parameter is optional. However, if you do not pass any session policies, then the resulting federated user session has no permissions.</p> <p>When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>The resulting credentials can be used to access a resource that has a resource-based policy. If that policy specifically references the federated user session in the <code>Principal</code> element of the policy, the session has the permissions allowed by the policy. These permissions are granted in addition to the permissions that are granted by the session policies.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note>
  ##   Policy: JString
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>You must pass an inline or managed <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policy</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies.</p> <p>This parameter is optional. However, if you do not pass any session policies, then the resulting federated user session has no permissions.</p> <p>When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>The resulting credentials can be used to access a resource that has a resource-based policy. If that policy specifically references the federated user session in the <code>Principal</code> element of the policy, the session has the permissions allowed by the policy. These permissions are granted in addition to the permissions that are granted by the session policies.</p> <p>The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note>
  ##   DurationSeconds: JInt
  ##                  : The duration, in seconds, that the session should last. Acceptable durations for federation sessions range from 900 seconds (15 minutes) to 129,600 seconds (36 hours), with 43,200 seconds (12 hours) as the default. Sessions obtained using AWS account root user credentials are restricted to a maximum of 3,600 seconds (one hour). If the specified duration is longer than one hour, the session obtained by using root user credentials defaults to one hour.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_600227 = formData.getOrDefault("Name")
  valid_600227 = validateParameter(valid_600227, JString, required = true,
                                 default = nil)
  if valid_600227 != nil:
    section.add "Name", valid_600227
  var valid_600228 = formData.getOrDefault("Tags")
  valid_600228 = validateParameter(valid_600228, JArray, required = false,
                                 default = nil)
  if valid_600228 != nil:
    section.add "Tags", valid_600228
  var valid_600229 = formData.getOrDefault("PolicyArns")
  valid_600229 = validateParameter(valid_600229, JArray, required = false,
                                 default = nil)
  if valid_600229 != nil:
    section.add "PolicyArns", valid_600229
  var valid_600230 = formData.getOrDefault("Policy")
  valid_600230 = validateParameter(valid_600230, JString, required = false,
                                 default = nil)
  if valid_600230 != nil:
    section.add "Policy", valid_600230
  var valid_600231 = formData.getOrDefault("DurationSeconds")
  valid_600231 = validateParameter(valid_600231, JInt, required = false, default = nil)
  if valid_600231 != nil:
    section.add "DurationSeconds", valid_600231
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600232: Call_PostGetFederationToken_600215; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a set of temporary security credentials (consisting of an access key ID, a secret access key, and a security token) for a federated user. A typical use is in a proxy application that gets temporary security credentials on behalf of distributed applications inside a corporate network. You must call the <code>GetFederationToken</code> operation using the long-term security credentials of an IAM user. As a result, this call is appropriate in contexts where those credentials can be safely stored, usually in a server-based application. For a comparison of <code>GetFederationToken</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <note> <p>You can create a mobile-based or browser-based app that can authenticate users using a web identity provider like Login with Amazon, Facebook, Google, or an OpenID Connect-compatible identity provider. In this case, we recommend that you use <a href="http://aws.amazon.com/cognito/">Amazon Cognito</a> or <code>AssumeRoleWithWebIdentity</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity">Federation Through a Web-based Identity Provider</a> in the <i>IAM User Guide</i>.</p> </note> <p>You can also call <code>GetFederationToken</code> using the security credentials of an AWS account root user, but we do not recommend it. Instead, we recommend that you create an IAM user for the purpose of the proxy application. Then attach a policy to the IAM user that limits federated users to only the actions and resources that they need to access. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html">IAM Best Practices</a> in the <i>IAM User Guide</i>. </p> <p> <b>Session duration</b> </p> <p>The temporary credentials are valid for the specified duration, from 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36 hours). The default session duration is 43,200 seconds (12 hours). Temporary credentials that are obtained by using AWS account root user credentials have a maximum duration of 3,600 seconds (1 hour).</p> <p> <b>Permissions</b> </p> <p>You can use the temporary credentials created by <code>GetFederationToken</code> in any AWS service except the following:</p> <ul> <li> <p>You cannot call any IAM operations using the AWS CLI or the AWS API. </p> </li> <li> <p>You cannot call any STS operations except <code>GetCallerIdentity</code>.</p> </li> </ul> <p>You must pass an inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policy</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies can't exceed 2,048 characters.</p> <p>Though the session policy parameters are optional, if you do not pass a policy, then the resulting federated user session has no permissions. When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>. For information about using <code>GetFederationToken</code> to create temporary security credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getfederationtoken">GetFederationToken—Federation Through a Custom Identity Broker</a>. </p> <p>You can use the credentials to access a resource that has a resource-based policy. If that policy specifically references the federated user session in the <code>Principal</code> element of the policy, the session has the permissions allowed by the policy. These permissions are granted in addition to the permissions granted by the session policies.</p> <p> <b>Tags</b> </p> <p>(Optional) You can pass tag key-value pairs to your session. These are called session tags. For more information about session tags, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Passing Session Tags in STS</a> in the <i>IAM User Guide</i>.</p> <p>An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html">Tutorial: Using Tags for Attribute-Based Access Control</a> in the <i>IAM User Guide</i>.</p> <p>Tag key–value pairs are not case sensitive, but case is preserved. This means that you cannot have separate <code>Department</code> and <code>department</code> tag keys. Assume that the user that you are federating has the <code>Department</code>=<code>Marketing</code> tag and you pass the <code>department</code>=<code>engineering</code> session tag. <code>Department</code> and <code>department</code> are not saved as separate tags, and the session tag passed in the request takes precedence over the user tag.</p>
  ## 
  let valid = call_600232.validator(path, query, header, formData, body)
  let scheme = call_600232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600232.url(scheme.get, call_600232.host, call_600232.base,
                         call_600232.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600232, url, valid)

proc call*(call_600233: Call_PostGetFederationToken_600215; Name: string;
          Tags: JsonNode = nil; Action: string = "GetFederationToken";
          PolicyArns: JsonNode = nil; Policy: string = "";
          Version: string = "2011-06-15"; DurationSeconds: int = 0): Recallable =
  ## postGetFederationToken
  ## <p>Returns a set of temporary security credentials (consisting of an access key ID, a secret access key, and a security token) for a federated user. A typical use is in a proxy application that gets temporary security credentials on behalf of distributed applications inside a corporate network. You must call the <code>GetFederationToken</code> operation using the long-term security credentials of an IAM user. As a result, this call is appropriate in contexts where those credentials can be safely stored, usually in a server-based application. For a comparison of <code>GetFederationToken</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <note> <p>You can create a mobile-based or browser-based app that can authenticate users using a web identity provider like Login with Amazon, Facebook, Google, or an OpenID Connect-compatible identity provider. In this case, we recommend that you use <a href="http://aws.amazon.com/cognito/">Amazon Cognito</a> or <code>AssumeRoleWithWebIdentity</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity">Federation Through a Web-based Identity Provider</a> in the <i>IAM User Guide</i>.</p> </note> <p>You can also call <code>GetFederationToken</code> using the security credentials of an AWS account root user, but we do not recommend it. Instead, we recommend that you create an IAM user for the purpose of the proxy application. Then attach a policy to the IAM user that limits federated users to only the actions and resources that they need to access. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html">IAM Best Practices</a> in the <i>IAM User Guide</i>. </p> <p> <b>Session duration</b> </p> <p>The temporary credentials are valid for the specified duration, from 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36 hours). The default session duration is 43,200 seconds (12 hours). Temporary credentials that are obtained by using AWS account root user credentials have a maximum duration of 3,600 seconds (1 hour).</p> <p> <b>Permissions</b> </p> <p>You can use the temporary credentials created by <code>GetFederationToken</code> in any AWS service except the following:</p> <ul> <li> <p>You cannot call any IAM operations using the AWS CLI or the AWS API. </p> </li> <li> <p>You cannot call any STS operations except <code>GetCallerIdentity</code>.</p> </li> </ul> <p>You must pass an inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policy</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies can't exceed 2,048 characters.</p> <p>Though the session policy parameters are optional, if you do not pass a policy, then the resulting federated user session has no permissions. When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>. For information about using <code>GetFederationToken</code> to create temporary security credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getfederationtoken">GetFederationToken—Federation Through a Custom Identity Broker</a>. </p> <p>You can use the credentials to access a resource that has a resource-based policy. If that policy specifically references the federated user session in the <code>Principal</code> element of the policy, the session has the permissions allowed by the policy. These permissions are granted in addition to the permissions granted by the session policies.</p> <p> <b>Tags</b> </p> <p>(Optional) You can pass tag key-value pairs to your session. These are called session tags. For more information about session tags, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Passing Session Tags in STS</a> in the <i>IAM User Guide</i>.</p> <p>An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html">Tutorial: Using Tags for Attribute-Based Access Control</a> in the <i>IAM User Guide</i>.</p> <p>Tag key–value pairs are not case sensitive, but case is preserved. This means that you cannot have separate <code>Department</code> and <code>department</code> tag keys. Assume that the user that you are federating has the <code>Department</code>=<code>Marketing</code> tag and you pass the <code>department</code>=<code>engineering</code> session tag. <code>Department</code> and <code>department</code> are not saved as separate tags, and the session tag passed in the request takes precedence over the user tag.</p>
  ##   Name: string (required)
  ##       : <p>The name of the federated user. The name is used as an identifier for the temporary security credentials (such as <code>Bob</code>). For example, you can reference the federated user name in a resource-based policy, such as in an Amazon S3 bucket policy.</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-</p>
  ##   Tags: JArray
  ##       : <p>A list of session tags. Each session tag consists of a key name and an associated value. For more information about session tags, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Passing Session Tags in STS</a> in the <i>IAM User Guide</i>.</p> <p>This parameter is optional. You can pass up to 50 session tags. The plain text session tag keys can’t exceed 128 characters and the values can’t exceed 256 characters. For these and additional limits, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length">IAM and STS Character Limits</a> in the <i>IAM User Guide</i>.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>You can pass a session tag with the same key as a tag that is already attached to the user you are federating. When you do, session tags override a user tag with the same key. </p> <p>Tag key–value pairs are not case sensitive, but case is preserved. This means that you cannot have separate <code>Department</code> and <code>department</code> tag keys. Assume that the role has the <code>Department</code>=<code>Marketing</code> tag and you pass the <code>department</code>=<code>engineering</code> session tag. <code>Department</code> and <code>department</code> are not saved as separate tags, and the session tag passed in the request takes precedence over the role tag.</p>
  ##   Action: string (required)
  ##   PolicyArns: JArray
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as a managed session policy. The policies must exist in the same account as the IAM user that is requesting federated access.</p> <p>You must pass an inline or managed <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policy</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. You can provide up to 10 managed policy ARNs. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <p>This parameter is optional. However, if you do not pass any session policies, then the resulting federated user session has no permissions.</p> <p>When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>The resulting credentials can be used to access a resource that has a resource-based policy. If that policy specifically references the federated user session in the <code>Principal</code> element of the policy, the session has the permissions allowed by the policy. These permissions are granted in addition to the permissions that are granted by the session policies.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note>
  ##   Policy: string
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>You must pass an inline or managed <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policy</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies.</p> <p>This parameter is optional. However, if you do not pass any session policies, then the resulting federated user session has no permissions.</p> <p>When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>The resulting credentials can be used to access a resource that has a resource-based policy. If that policy specifically references the federated user session in the <code>Principal</code> element of the policy, the session has the permissions allowed by the policy. These permissions are granted in addition to the permissions that are granted by the session policies.</p> <p>The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note>
  ##   Version: string (required)
  ##   DurationSeconds: int
  ##                  : The duration, in seconds, that the session should last. Acceptable durations for federation sessions range from 900 seconds (15 minutes) to 129,600 seconds (36 hours), with 43,200 seconds (12 hours) as the default. Sessions obtained using AWS account root user credentials are restricted to a maximum of 3,600 seconds (one hour). If the specified duration is longer than one hour, the session obtained by using root user credentials defaults to one hour.
  var query_600234 = newJObject()
  var formData_600235 = newJObject()
  add(formData_600235, "Name", newJString(Name))
  if Tags != nil:
    formData_600235.add "Tags", Tags
  add(query_600234, "Action", newJString(Action))
  if PolicyArns != nil:
    formData_600235.add "PolicyArns", PolicyArns
  add(formData_600235, "Policy", newJString(Policy))
  add(query_600234, "Version", newJString(Version))
  add(formData_600235, "DurationSeconds", newJInt(DurationSeconds))
  result = call_600233.call(nil, query_600234, nil, formData_600235, nil)

var postGetFederationToken* = Call_PostGetFederationToken_600215(
    name: "postGetFederationToken", meth: HttpMethod.HttpPost,
    host: "sts.amazonaws.com", route: "/#Action=GetFederationToken",
    validator: validate_PostGetFederationToken_600216, base: "/",
    url: url_PostGetFederationToken_600217, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetFederationToken_600195 = ref object of OpenApiRestCall_599368
proc url_GetGetFederationToken_600197(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetFederationToken_600196(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a set of temporary security credentials (consisting of an access key ID, a secret access key, and a security token) for a federated user. A typical use is in a proxy application that gets temporary security credentials on behalf of distributed applications inside a corporate network. You must call the <code>GetFederationToken</code> operation using the long-term security credentials of an IAM user. As a result, this call is appropriate in contexts where those credentials can be safely stored, usually in a server-based application. For a comparison of <code>GetFederationToken</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <note> <p>You can create a mobile-based or browser-based app that can authenticate users using a web identity provider like Login with Amazon, Facebook, Google, or an OpenID Connect-compatible identity provider. In this case, we recommend that you use <a href="http://aws.amazon.com/cognito/">Amazon Cognito</a> or <code>AssumeRoleWithWebIdentity</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity">Federation Through a Web-based Identity Provider</a> in the <i>IAM User Guide</i>.</p> </note> <p>You can also call <code>GetFederationToken</code> using the security credentials of an AWS account root user, but we do not recommend it. Instead, we recommend that you create an IAM user for the purpose of the proxy application. Then attach a policy to the IAM user that limits federated users to only the actions and resources that they need to access. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html">IAM Best Practices</a> in the <i>IAM User Guide</i>. </p> <p> <b>Session duration</b> </p> <p>The temporary credentials are valid for the specified duration, from 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36 hours). The default session duration is 43,200 seconds (12 hours). Temporary credentials that are obtained by using AWS account root user credentials have a maximum duration of 3,600 seconds (1 hour).</p> <p> <b>Permissions</b> </p> <p>You can use the temporary credentials created by <code>GetFederationToken</code> in any AWS service except the following:</p> <ul> <li> <p>You cannot call any IAM operations using the AWS CLI or the AWS API. </p> </li> <li> <p>You cannot call any STS operations except <code>GetCallerIdentity</code>.</p> </li> </ul> <p>You must pass an inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policy</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies can't exceed 2,048 characters.</p> <p>Though the session policy parameters are optional, if you do not pass a policy, then the resulting federated user session has no permissions. When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>. For information about using <code>GetFederationToken</code> to create temporary security credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getfederationtoken">GetFederationToken—Federation Through a Custom Identity Broker</a>. </p> <p>You can use the credentials to access a resource that has a resource-based policy. If that policy specifically references the federated user session in the <code>Principal</code> element of the policy, the session has the permissions allowed by the policy. These permissions are granted in addition to the permissions granted by the session policies.</p> <p> <b>Tags</b> </p> <p>(Optional) You can pass tag key-value pairs to your session. These are called session tags. For more information about session tags, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Passing Session Tags in STS</a> in the <i>IAM User Guide</i>.</p> <p>An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html">Tutorial: Using Tags for Attribute-Based Access Control</a> in the <i>IAM User Guide</i>.</p> <p>Tag key–value pairs are not case sensitive, but case is preserved. This means that you cannot have separate <code>Department</code> and <code>department</code> tag keys. Assume that the user that you are federating has the <code>Department</code>=<code>Marketing</code> tag and you pass the <code>department</code>=<code>engineering</code> session tag. <code>Department</code> and <code>department</code> are not saved as separate tags, and the session tag passed in the request takes precedence over the user tag.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Name: JString (required)
  ##       : <p>The name of the federated user. The name is used as an identifier for the temporary security credentials (such as <code>Bob</code>). For example, you can reference the federated user name in a resource-based policy, such as in an Amazon S3 bucket policy.</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-</p>
  ##   DurationSeconds: JInt
  ##                  : The duration, in seconds, that the session should last. Acceptable durations for federation sessions range from 900 seconds (15 minutes) to 129,600 seconds (36 hours), with 43,200 seconds (12 hours) as the default. Sessions obtained using AWS account root user credentials are restricted to a maximum of 3,600 seconds (one hour). If the specified duration is longer than one hour, the session obtained by using root user credentials defaults to one hour.
  ##   Tags: JArray
  ##       : <p>A list of session tags. Each session tag consists of a key name and an associated value. For more information about session tags, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Passing Session Tags in STS</a> in the <i>IAM User Guide</i>.</p> <p>This parameter is optional. You can pass up to 50 session tags. The plain text session tag keys can’t exceed 128 characters and the values can’t exceed 256 characters. For these and additional limits, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length">IAM and STS Character Limits</a> in the <i>IAM User Guide</i>.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>You can pass a session tag with the same key as a tag that is already attached to the user you are federating. When you do, session tags override a user tag with the same key. </p> <p>Tag key–value pairs are not case sensitive, but case is preserved. This means that you cannot have separate <code>Department</code> and <code>department</code> tag keys. Assume that the role has the <code>Department</code>=<code>Marketing</code> tag and you pass the <code>department</code>=<code>engineering</code> session tag. <code>Department</code> and <code>department</code> are not saved as separate tags, and the session tag passed in the request takes precedence over the role tag.</p>
  ##   PolicyArns: JArray
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as a managed session policy. The policies must exist in the same account as the IAM user that is requesting federated access.</p> <p>You must pass an inline or managed <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policy</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. You can provide up to 10 managed policy ARNs. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <p>This parameter is optional. However, if you do not pass any session policies, then the resulting federated user session has no permissions.</p> <p>When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>The resulting credentials can be used to access a resource that has a resource-based policy. If that policy specifically references the federated user session in the <code>Principal</code> element of the policy, the session has the permissions allowed by the policy. These permissions are granted in addition to the permissions that are granted by the session policies.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note>
  ##   Action: JString (required)
  ##   Policy: JString
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>You must pass an inline or managed <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policy</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies.</p> <p>This parameter is optional. However, if you do not pass any session policies, then the resulting federated user session has no permissions.</p> <p>When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>The resulting credentials can be used to access a resource that has a resource-based policy. If that policy specifically references the federated user session in the <code>Principal</code> element of the policy, the session has the permissions allowed by the policy. These permissions are granted in addition to the permissions that are granted by the session policies.</p> <p>The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_600198 = query.getOrDefault("Name")
  valid_600198 = validateParameter(valid_600198, JString, required = true,
                                 default = nil)
  if valid_600198 != nil:
    section.add "Name", valid_600198
  var valid_600199 = query.getOrDefault("DurationSeconds")
  valid_600199 = validateParameter(valid_600199, JInt, required = false, default = nil)
  if valid_600199 != nil:
    section.add "DurationSeconds", valid_600199
  var valid_600200 = query.getOrDefault("Tags")
  valid_600200 = validateParameter(valid_600200, JArray, required = false,
                                 default = nil)
  if valid_600200 != nil:
    section.add "Tags", valid_600200
  var valid_600201 = query.getOrDefault("PolicyArns")
  valid_600201 = validateParameter(valid_600201, JArray, required = false,
                                 default = nil)
  if valid_600201 != nil:
    section.add "PolicyArns", valid_600201
  var valid_600202 = query.getOrDefault("Action")
  valid_600202 = validateParameter(valid_600202, JString, required = true,
                                 default = newJString("GetFederationToken"))
  if valid_600202 != nil:
    section.add "Action", valid_600202
  var valid_600203 = query.getOrDefault("Policy")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "Policy", valid_600203
  var valid_600204 = query.getOrDefault("Version")
  valid_600204 = validateParameter(valid_600204, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_600204 != nil:
    section.add "Version", valid_600204
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600205 = header.getOrDefault("X-Amz-Date")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-Date", valid_600205
  var valid_600206 = header.getOrDefault("X-Amz-Security-Token")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "X-Amz-Security-Token", valid_600206
  var valid_600207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "X-Amz-Content-Sha256", valid_600207
  var valid_600208 = header.getOrDefault("X-Amz-Algorithm")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "X-Amz-Algorithm", valid_600208
  var valid_600209 = header.getOrDefault("X-Amz-Signature")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "X-Amz-Signature", valid_600209
  var valid_600210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600210 = validateParameter(valid_600210, JString, required = false,
                                 default = nil)
  if valid_600210 != nil:
    section.add "X-Amz-SignedHeaders", valid_600210
  var valid_600211 = header.getOrDefault("X-Amz-Credential")
  valid_600211 = validateParameter(valid_600211, JString, required = false,
                                 default = nil)
  if valid_600211 != nil:
    section.add "X-Amz-Credential", valid_600211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600212: Call_GetGetFederationToken_600195; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a set of temporary security credentials (consisting of an access key ID, a secret access key, and a security token) for a federated user. A typical use is in a proxy application that gets temporary security credentials on behalf of distributed applications inside a corporate network. You must call the <code>GetFederationToken</code> operation using the long-term security credentials of an IAM user. As a result, this call is appropriate in contexts where those credentials can be safely stored, usually in a server-based application. For a comparison of <code>GetFederationToken</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <note> <p>You can create a mobile-based or browser-based app that can authenticate users using a web identity provider like Login with Amazon, Facebook, Google, or an OpenID Connect-compatible identity provider. In this case, we recommend that you use <a href="http://aws.amazon.com/cognito/">Amazon Cognito</a> or <code>AssumeRoleWithWebIdentity</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity">Federation Through a Web-based Identity Provider</a> in the <i>IAM User Guide</i>.</p> </note> <p>You can also call <code>GetFederationToken</code> using the security credentials of an AWS account root user, but we do not recommend it. Instead, we recommend that you create an IAM user for the purpose of the proxy application. Then attach a policy to the IAM user that limits federated users to only the actions and resources that they need to access. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html">IAM Best Practices</a> in the <i>IAM User Guide</i>. </p> <p> <b>Session duration</b> </p> <p>The temporary credentials are valid for the specified duration, from 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36 hours). The default session duration is 43,200 seconds (12 hours). Temporary credentials that are obtained by using AWS account root user credentials have a maximum duration of 3,600 seconds (1 hour).</p> <p> <b>Permissions</b> </p> <p>You can use the temporary credentials created by <code>GetFederationToken</code> in any AWS service except the following:</p> <ul> <li> <p>You cannot call any IAM operations using the AWS CLI or the AWS API. </p> </li> <li> <p>You cannot call any STS operations except <code>GetCallerIdentity</code>.</p> </li> </ul> <p>You must pass an inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policy</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies can't exceed 2,048 characters.</p> <p>Though the session policy parameters are optional, if you do not pass a policy, then the resulting federated user session has no permissions. When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>. For information about using <code>GetFederationToken</code> to create temporary security credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getfederationtoken">GetFederationToken—Federation Through a Custom Identity Broker</a>. </p> <p>You can use the credentials to access a resource that has a resource-based policy. If that policy specifically references the federated user session in the <code>Principal</code> element of the policy, the session has the permissions allowed by the policy. These permissions are granted in addition to the permissions granted by the session policies.</p> <p> <b>Tags</b> </p> <p>(Optional) You can pass tag key-value pairs to your session. These are called session tags. For more information about session tags, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Passing Session Tags in STS</a> in the <i>IAM User Guide</i>.</p> <p>An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html">Tutorial: Using Tags for Attribute-Based Access Control</a> in the <i>IAM User Guide</i>.</p> <p>Tag key–value pairs are not case sensitive, but case is preserved. This means that you cannot have separate <code>Department</code> and <code>department</code> tag keys. Assume that the user that you are federating has the <code>Department</code>=<code>Marketing</code> tag and you pass the <code>department</code>=<code>engineering</code> session tag. <code>Department</code> and <code>department</code> are not saved as separate tags, and the session tag passed in the request takes precedence over the user tag.</p>
  ## 
  let valid = call_600212.validator(path, query, header, formData, body)
  let scheme = call_600212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600212.url(scheme.get, call_600212.host, call_600212.base,
                         call_600212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600212, url, valid)

proc call*(call_600213: Call_GetGetFederationToken_600195; Name: string;
          DurationSeconds: int = 0; Tags: JsonNode = nil; PolicyArns: JsonNode = nil;
          Action: string = "GetFederationToken"; Policy: string = "";
          Version: string = "2011-06-15"): Recallable =
  ## getGetFederationToken
  ## <p>Returns a set of temporary security credentials (consisting of an access key ID, a secret access key, and a security token) for a federated user. A typical use is in a proxy application that gets temporary security credentials on behalf of distributed applications inside a corporate network. You must call the <code>GetFederationToken</code> operation using the long-term security credentials of an IAM user. As a result, this call is appropriate in contexts where those credentials can be safely stored, usually in a server-based application. For a comparison of <code>GetFederationToken</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <note> <p>You can create a mobile-based or browser-based app that can authenticate users using a web identity provider like Login with Amazon, Facebook, Google, or an OpenID Connect-compatible identity provider. In this case, we recommend that you use <a href="http://aws.amazon.com/cognito/">Amazon Cognito</a> or <code>AssumeRoleWithWebIdentity</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity">Federation Through a Web-based Identity Provider</a> in the <i>IAM User Guide</i>.</p> </note> <p>You can also call <code>GetFederationToken</code> using the security credentials of an AWS account root user, but we do not recommend it. Instead, we recommend that you create an IAM user for the purpose of the proxy application. Then attach a policy to the IAM user that limits federated users to only the actions and resources that they need to access. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html">IAM Best Practices</a> in the <i>IAM User Guide</i>. </p> <p> <b>Session duration</b> </p> <p>The temporary credentials are valid for the specified duration, from 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36 hours). The default session duration is 43,200 seconds (12 hours). Temporary credentials that are obtained by using AWS account root user credentials have a maximum duration of 3,600 seconds (1 hour).</p> <p> <b>Permissions</b> </p> <p>You can use the temporary credentials created by <code>GetFederationToken</code> in any AWS service except the following:</p> <ul> <li> <p>You cannot call any IAM operations using the AWS CLI or the AWS API. </p> </li> <li> <p>You cannot call any STS operations except <code>GetCallerIdentity</code>.</p> </li> </ul> <p>You must pass an inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policy</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies can't exceed 2,048 characters.</p> <p>Though the session policy parameters are optional, if you do not pass a policy, then the resulting federated user session has no permissions. When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>. For information about using <code>GetFederationToken</code> to create temporary security credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getfederationtoken">GetFederationToken—Federation Through a Custom Identity Broker</a>. </p> <p>You can use the credentials to access a resource that has a resource-based policy. If that policy specifically references the federated user session in the <code>Principal</code> element of the policy, the session has the permissions allowed by the policy. These permissions are granted in addition to the permissions granted by the session policies.</p> <p> <b>Tags</b> </p> <p>(Optional) You can pass tag key-value pairs to your session. These are called session tags. For more information about session tags, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Passing Session Tags in STS</a> in the <i>IAM User Guide</i>.</p> <p>An administrator must grant you the permissions necessary to pass session tags. The administrator can also create granular permissions to allow you to pass only specific session tags. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html">Tutorial: Using Tags for Attribute-Based Access Control</a> in the <i>IAM User Guide</i>.</p> <p>Tag key–value pairs are not case sensitive, but case is preserved. This means that you cannot have separate <code>Department</code> and <code>department</code> tag keys. Assume that the user that you are federating has the <code>Department</code>=<code>Marketing</code> tag and you pass the <code>department</code>=<code>engineering</code> session tag. <code>Department</code> and <code>department</code> are not saved as separate tags, and the session tag passed in the request takes precedence over the user tag.</p>
  ##   Name: string (required)
  ##       : <p>The name of the federated user. The name is used as an identifier for the temporary security credentials (such as <code>Bob</code>). For example, you can reference the federated user name in a resource-based policy, such as in an Amazon S3 bucket policy.</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-</p>
  ##   DurationSeconds: int
  ##                  : The duration, in seconds, that the session should last. Acceptable durations for federation sessions range from 900 seconds (15 minutes) to 129,600 seconds (36 hours), with 43,200 seconds (12 hours) as the default. Sessions obtained using AWS account root user credentials are restricted to a maximum of 3,600 seconds (one hour). If the specified duration is longer than one hour, the session obtained by using root user credentials defaults to one hour.
  ##   Tags: JArray
  ##       : <p>A list of session tags. Each session tag consists of a key name and an associated value. For more information about session tags, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html">Passing Session Tags in STS</a> in the <i>IAM User Guide</i>.</p> <p>This parameter is optional. You can pass up to 50 session tags. The plain text session tag keys can’t exceed 128 characters and the values can’t exceed 256 characters. For these and additional limits, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length">IAM and STS Character Limits</a> in the <i>IAM User Guide</i>.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note> <p>You can pass a session tag with the same key as a tag that is already attached to the user you are federating. When you do, session tags override a user tag with the same key. </p> <p>Tag key–value pairs are not case sensitive, but case is preserved. This means that you cannot have separate <code>Department</code> and <code>department</code> tag keys. Assume that the role has the <code>Department</code>=<code>Marketing</code> tag and you pass the <code>department</code>=<code>engineering</code> session tag. <code>Department</code> and <code>department</code> are not saved as separate tags, and the session tag passed in the request takes precedence over the role tag.</p>
  ##   PolicyArns: JArray
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as a managed session policy. The policies must exist in the same account as the IAM user that is requesting federated access.</p> <p>You must pass an inline or managed <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policy</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. You can provide up to 10 managed policy ARNs. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <p>This parameter is optional. However, if you do not pass any session policies, then the resulting federated user session has no permissions.</p> <p>When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>The resulting credentials can be used to access a resource that has a resource-based policy. If that policy specifically references the federated user session in the <code>Principal</code> element of the policy, the session has the permissions allowed by the policy. These permissions are granted in addition to the permissions that are granted by the session policies.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note>
  ##   Action: string (required)
  ##   Policy: string
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>You must pass an inline or managed <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policy</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies.</p> <p>This parameter is optional. However, if you do not pass any session policies, then the resulting federated user session has no permissions.</p> <p>When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>The resulting credentials can be used to access a resource that has a resource-based policy. If that policy specifically references the federated user session in the <code>Principal</code> element of the policy, the session has the permissions allowed by the policy. These permissions are granted in addition to the permissions that are granted by the session policies.</p> <p>The plain text that you use for both inline and managed session policies can't exceed 2,048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>An AWS conversion compresses the passed session policies and session tags into a packed binary format that has a separate limit. Your request can fail for this limit even if your plain text meets the other requirements. The <code>PackedPolicySize</code> response element indicates by percentage how close the policies and tags for your request are to the upper size limit. </p> </note>
  ##   Version: string (required)
  var query_600214 = newJObject()
  add(query_600214, "Name", newJString(Name))
  add(query_600214, "DurationSeconds", newJInt(DurationSeconds))
  if Tags != nil:
    query_600214.add "Tags", Tags
  if PolicyArns != nil:
    query_600214.add "PolicyArns", PolicyArns
  add(query_600214, "Action", newJString(Action))
  add(query_600214, "Policy", newJString(Policy))
  add(query_600214, "Version", newJString(Version))
  result = call_600213.call(nil, query_600214, nil, nil, nil)

var getGetFederationToken* = Call_GetGetFederationToken_600195(
    name: "getGetFederationToken", meth: HttpMethod.HttpGet,
    host: "sts.amazonaws.com", route: "/#Action=GetFederationToken",
    validator: validate_GetGetFederationToken_600196, base: "/",
    url: url_GetGetFederationToken_600197, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetSessionToken_600254 = ref object of OpenApiRestCall_599368
proc url_PostGetSessionToken_600256(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetSessionToken_600255(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Returns a set of temporary credentials for an AWS account or IAM user. The credentials consist of an access key ID, a secret access key, and a security token. Typically, you use <code>GetSessionToken</code> if you want to use MFA to protect programmatic calls to specific AWS API operations like Amazon EC2 <code>StopInstances</code>. MFA-enabled IAM users would need to call <code>GetSessionToken</code> and submit an MFA code that is associated with their MFA device. Using the temporary security credentials that are returned from the call, IAM users can then make programmatic calls to API operations that require MFA authentication. If you do not supply a correct MFA code, then the API returns an access denied error. For a comparison of <code>GetSessionToken</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p> <b>Session Duration</b> </p> <p>The <code>GetSessionToken</code> operation must be called by using the long-term AWS security credentials of the AWS account root user or an IAM user. Credentials that are created by IAM users are valid for the duration that you specify. This duration can range from 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36 hours), with a default of 43,200 seconds (12 hours). Credentials based on account credentials can range from 900 seconds (15 minutes) up to 3,600 seconds (1 hour), with a default of 1 hour. </p> <p> <b>Permissions</b> </p> <p>The temporary security credentials created by <code>GetSessionToken</code> can be used to make API calls to any AWS service with the following exceptions:</p> <ul> <li> <p>You cannot call any IAM API operations unless MFA authentication information is included in the request.</p> </li> <li> <p>You cannot call any STS API <i>except</i> <code>AssumeRole</code> or <code>GetCallerIdentity</code>.</p> </li> </ul> <note> <p>We recommend that you do not call <code>GetSessionToken</code> with AWS account root user credentials. Instead, follow our <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#create-iam-users">best practices</a> by creating one or more IAM users, giving them the necessary permissions, and using IAM users for everyday interaction with AWS. </p> </note> <p>The credentials that are returned by <code>GetSessionToken</code> are based on permissions associated with the user whose credentials were used to call the operation. If <code>GetSessionToken</code> is called using AWS account root user credentials, the temporary credentials have root user permissions. Similarly, if <code>GetSessionToken</code> is called using the credentials of an IAM user, the temporary credentials have the same permissions as the IAM user. </p> <p>For more information about using <code>GetSessionToken</code> to create temporary credentials, go to <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getsessiontoken">Temporary Credentials for Users in Untrusted Environments</a> in the <i>IAM User Guide</i>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600257 = query.getOrDefault("Action")
  valid_600257 = validateParameter(valid_600257, JString, required = true,
                                 default = newJString("GetSessionToken"))
  if valid_600257 != nil:
    section.add "Action", valid_600257
  var valid_600258 = query.getOrDefault("Version")
  valid_600258 = validateParameter(valid_600258, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_600258 != nil:
    section.add "Version", valid_600258
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
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
  var valid_600261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600261 = validateParameter(valid_600261, JString, required = false,
                                 default = nil)
  if valid_600261 != nil:
    section.add "X-Amz-Content-Sha256", valid_600261
  var valid_600262 = header.getOrDefault("X-Amz-Algorithm")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "X-Amz-Algorithm", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-Signature")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Signature", valid_600263
  var valid_600264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600264 = validateParameter(valid_600264, JString, required = false,
                                 default = nil)
  if valid_600264 != nil:
    section.add "X-Amz-SignedHeaders", valid_600264
  var valid_600265 = header.getOrDefault("X-Amz-Credential")
  valid_600265 = validateParameter(valid_600265, JString, required = false,
                                 default = nil)
  if valid_600265 != nil:
    section.add "X-Amz-Credential", valid_600265
  result.add "header", section
  ## parameters in `formData` object:
  ##   SerialNumber: JString
  ##               : <p>The identification number of the MFA device that is associated with the IAM user who is making the <code>GetSessionToken</code> call. Specify this value if the IAM user has a policy that requires MFA authentication. The value is either the serial number for a hardware device (such as <code>GAHT12345678</code>) or an Amazon Resource Name (ARN) for a virtual device (such as <code>arn:aws:iam::123456789012:mfa/user</code>). You can find the device for an IAM user by going to the AWS Management Console and viewing the user's security credentials. </p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@:/-</p>
  ##   TokenCode: JString
  ##            : <p>The value provided by the MFA device, if MFA is required. If any policy requires the IAM user to submit an MFA code, specify this value. If MFA authentication is required, the user must provide a code when requesting a set of temporary security credentials. A user who fails to provide the code receives an "access denied" response when requesting resources that require MFA authentication.</p> <p>The format for this parameter, as described by its regex pattern, is a sequence of six numeric digits.</p>
  ##   DurationSeconds: JInt
  ##                  : The duration, in seconds, that the credentials should remain valid. Acceptable durations for IAM user sessions range from 900 seconds (15 minutes) to 129,600 seconds (36 hours), with 43,200 seconds (12 hours) as the default. Sessions for AWS account owners are restricted to a maximum of 3,600 seconds (one hour). If the duration is longer than one hour, the session for AWS account owners defaults to one hour.
  section = newJObject()
  var valid_600266 = formData.getOrDefault("SerialNumber")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "SerialNumber", valid_600266
  var valid_600267 = formData.getOrDefault("TokenCode")
  valid_600267 = validateParameter(valid_600267, JString, required = false,
                                 default = nil)
  if valid_600267 != nil:
    section.add "TokenCode", valid_600267
  var valid_600268 = formData.getOrDefault("DurationSeconds")
  valid_600268 = validateParameter(valid_600268, JInt, required = false, default = nil)
  if valid_600268 != nil:
    section.add "DurationSeconds", valid_600268
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600269: Call_PostGetSessionToken_600254; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a set of temporary credentials for an AWS account or IAM user. The credentials consist of an access key ID, a secret access key, and a security token. Typically, you use <code>GetSessionToken</code> if you want to use MFA to protect programmatic calls to specific AWS API operations like Amazon EC2 <code>StopInstances</code>. MFA-enabled IAM users would need to call <code>GetSessionToken</code> and submit an MFA code that is associated with their MFA device. Using the temporary security credentials that are returned from the call, IAM users can then make programmatic calls to API operations that require MFA authentication. If you do not supply a correct MFA code, then the API returns an access denied error. For a comparison of <code>GetSessionToken</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p> <b>Session Duration</b> </p> <p>The <code>GetSessionToken</code> operation must be called by using the long-term AWS security credentials of the AWS account root user or an IAM user. Credentials that are created by IAM users are valid for the duration that you specify. This duration can range from 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36 hours), with a default of 43,200 seconds (12 hours). Credentials based on account credentials can range from 900 seconds (15 minutes) up to 3,600 seconds (1 hour), with a default of 1 hour. </p> <p> <b>Permissions</b> </p> <p>The temporary security credentials created by <code>GetSessionToken</code> can be used to make API calls to any AWS service with the following exceptions:</p> <ul> <li> <p>You cannot call any IAM API operations unless MFA authentication information is included in the request.</p> </li> <li> <p>You cannot call any STS API <i>except</i> <code>AssumeRole</code> or <code>GetCallerIdentity</code>.</p> </li> </ul> <note> <p>We recommend that you do not call <code>GetSessionToken</code> with AWS account root user credentials. Instead, follow our <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#create-iam-users">best practices</a> by creating one or more IAM users, giving them the necessary permissions, and using IAM users for everyday interaction with AWS. </p> </note> <p>The credentials that are returned by <code>GetSessionToken</code> are based on permissions associated with the user whose credentials were used to call the operation. If <code>GetSessionToken</code> is called using AWS account root user credentials, the temporary credentials have root user permissions. Similarly, if <code>GetSessionToken</code> is called using the credentials of an IAM user, the temporary credentials have the same permissions as the IAM user. </p> <p>For more information about using <code>GetSessionToken</code> to create temporary credentials, go to <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getsessiontoken">Temporary Credentials for Users in Untrusted Environments</a> in the <i>IAM User Guide</i>. </p>
  ## 
  let valid = call_600269.validator(path, query, header, formData, body)
  let scheme = call_600269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600269.url(scheme.get, call_600269.host, call_600269.base,
                         call_600269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600269, url, valid)

proc call*(call_600270: Call_PostGetSessionToken_600254; SerialNumber: string = "";
          Action: string = "GetSessionToken"; Version: string = "2011-06-15";
          TokenCode: string = ""; DurationSeconds: int = 0): Recallable =
  ## postGetSessionToken
  ## <p>Returns a set of temporary credentials for an AWS account or IAM user. The credentials consist of an access key ID, a secret access key, and a security token. Typically, you use <code>GetSessionToken</code> if you want to use MFA to protect programmatic calls to specific AWS API operations like Amazon EC2 <code>StopInstances</code>. MFA-enabled IAM users would need to call <code>GetSessionToken</code> and submit an MFA code that is associated with their MFA device. Using the temporary security credentials that are returned from the call, IAM users can then make programmatic calls to API operations that require MFA authentication. If you do not supply a correct MFA code, then the API returns an access denied error. For a comparison of <code>GetSessionToken</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p> <b>Session Duration</b> </p> <p>The <code>GetSessionToken</code> operation must be called by using the long-term AWS security credentials of the AWS account root user or an IAM user. Credentials that are created by IAM users are valid for the duration that you specify. This duration can range from 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36 hours), with a default of 43,200 seconds (12 hours). Credentials based on account credentials can range from 900 seconds (15 minutes) up to 3,600 seconds (1 hour), with a default of 1 hour. </p> <p> <b>Permissions</b> </p> <p>The temporary security credentials created by <code>GetSessionToken</code> can be used to make API calls to any AWS service with the following exceptions:</p> <ul> <li> <p>You cannot call any IAM API operations unless MFA authentication information is included in the request.</p> </li> <li> <p>You cannot call any STS API <i>except</i> <code>AssumeRole</code> or <code>GetCallerIdentity</code>.</p> </li> </ul> <note> <p>We recommend that you do not call <code>GetSessionToken</code> with AWS account root user credentials. Instead, follow our <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#create-iam-users">best practices</a> by creating one or more IAM users, giving them the necessary permissions, and using IAM users for everyday interaction with AWS. </p> </note> <p>The credentials that are returned by <code>GetSessionToken</code> are based on permissions associated with the user whose credentials were used to call the operation. If <code>GetSessionToken</code> is called using AWS account root user credentials, the temporary credentials have root user permissions. Similarly, if <code>GetSessionToken</code> is called using the credentials of an IAM user, the temporary credentials have the same permissions as the IAM user. </p> <p>For more information about using <code>GetSessionToken</code> to create temporary credentials, go to <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getsessiontoken">Temporary Credentials for Users in Untrusted Environments</a> in the <i>IAM User Guide</i>. </p>
  ##   SerialNumber: string
  ##               : <p>The identification number of the MFA device that is associated with the IAM user who is making the <code>GetSessionToken</code> call. Specify this value if the IAM user has a policy that requires MFA authentication. The value is either the serial number for a hardware device (such as <code>GAHT12345678</code>) or an Amazon Resource Name (ARN) for a virtual device (such as <code>arn:aws:iam::123456789012:mfa/user</code>). You can find the device for an IAM user by going to the AWS Management Console and viewing the user's security credentials. </p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@:/-</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   TokenCode: string
  ##            : <p>The value provided by the MFA device, if MFA is required. If any policy requires the IAM user to submit an MFA code, specify this value. If MFA authentication is required, the user must provide a code when requesting a set of temporary security credentials. A user who fails to provide the code receives an "access denied" response when requesting resources that require MFA authentication.</p> <p>The format for this parameter, as described by its regex pattern, is a sequence of six numeric digits.</p>
  ##   DurationSeconds: int
  ##                  : The duration, in seconds, that the credentials should remain valid. Acceptable durations for IAM user sessions range from 900 seconds (15 minutes) to 129,600 seconds (36 hours), with 43,200 seconds (12 hours) as the default. Sessions for AWS account owners are restricted to a maximum of 3,600 seconds (one hour). If the duration is longer than one hour, the session for AWS account owners defaults to one hour.
  var query_600271 = newJObject()
  var formData_600272 = newJObject()
  add(formData_600272, "SerialNumber", newJString(SerialNumber))
  add(query_600271, "Action", newJString(Action))
  add(query_600271, "Version", newJString(Version))
  add(formData_600272, "TokenCode", newJString(TokenCode))
  add(formData_600272, "DurationSeconds", newJInt(DurationSeconds))
  result = call_600270.call(nil, query_600271, nil, formData_600272, nil)

var postGetSessionToken* = Call_PostGetSessionToken_600254(
    name: "postGetSessionToken", meth: HttpMethod.HttpPost,
    host: "sts.amazonaws.com", route: "/#Action=GetSessionToken",
    validator: validate_PostGetSessionToken_600255, base: "/",
    url: url_PostGetSessionToken_600256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetSessionToken_600236 = ref object of OpenApiRestCall_599368
proc url_GetGetSessionToken_600238(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetSessionToken_600237(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Returns a set of temporary credentials for an AWS account or IAM user. The credentials consist of an access key ID, a secret access key, and a security token. Typically, you use <code>GetSessionToken</code> if you want to use MFA to protect programmatic calls to specific AWS API operations like Amazon EC2 <code>StopInstances</code>. MFA-enabled IAM users would need to call <code>GetSessionToken</code> and submit an MFA code that is associated with their MFA device. Using the temporary security credentials that are returned from the call, IAM users can then make programmatic calls to API operations that require MFA authentication. If you do not supply a correct MFA code, then the API returns an access denied error. For a comparison of <code>GetSessionToken</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p> <b>Session Duration</b> </p> <p>The <code>GetSessionToken</code> operation must be called by using the long-term AWS security credentials of the AWS account root user or an IAM user. Credentials that are created by IAM users are valid for the duration that you specify. This duration can range from 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36 hours), with a default of 43,200 seconds (12 hours). Credentials based on account credentials can range from 900 seconds (15 minutes) up to 3,600 seconds (1 hour), with a default of 1 hour. </p> <p> <b>Permissions</b> </p> <p>The temporary security credentials created by <code>GetSessionToken</code> can be used to make API calls to any AWS service with the following exceptions:</p> <ul> <li> <p>You cannot call any IAM API operations unless MFA authentication information is included in the request.</p> </li> <li> <p>You cannot call any STS API <i>except</i> <code>AssumeRole</code> or <code>GetCallerIdentity</code>.</p> </li> </ul> <note> <p>We recommend that you do not call <code>GetSessionToken</code> with AWS account root user credentials. Instead, follow our <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#create-iam-users">best practices</a> by creating one or more IAM users, giving them the necessary permissions, and using IAM users for everyday interaction with AWS. </p> </note> <p>The credentials that are returned by <code>GetSessionToken</code> are based on permissions associated with the user whose credentials were used to call the operation. If <code>GetSessionToken</code> is called using AWS account root user credentials, the temporary credentials have root user permissions. Similarly, if <code>GetSessionToken</code> is called using the credentials of an IAM user, the temporary credentials have the same permissions as the IAM user. </p> <p>For more information about using <code>GetSessionToken</code> to create temporary credentials, go to <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getsessiontoken">Temporary Credentials for Users in Untrusted Environments</a> in the <i>IAM User Guide</i>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   TokenCode: JString
  ##            : <p>The value provided by the MFA device, if MFA is required. If any policy requires the IAM user to submit an MFA code, specify this value. If MFA authentication is required, the user must provide a code when requesting a set of temporary security credentials. A user who fails to provide the code receives an "access denied" response when requesting resources that require MFA authentication.</p> <p>The format for this parameter, as described by its regex pattern, is a sequence of six numeric digits.</p>
  ##   SerialNumber: JString
  ##               : <p>The identification number of the MFA device that is associated with the IAM user who is making the <code>GetSessionToken</code> call. Specify this value if the IAM user has a policy that requires MFA authentication. The value is either the serial number for a hardware device (such as <code>GAHT12345678</code>) or an Amazon Resource Name (ARN) for a virtual device (such as <code>arn:aws:iam::123456789012:mfa/user</code>). You can find the device for an IAM user by going to the AWS Management Console and viewing the user's security credentials. </p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@:/-</p>
  ##   DurationSeconds: JInt
  ##                  : The duration, in seconds, that the credentials should remain valid. Acceptable durations for IAM user sessions range from 900 seconds (15 minutes) to 129,600 seconds (36 hours), with 43,200 seconds (12 hours) as the default. Sessions for AWS account owners are restricted to a maximum of 3,600 seconds (one hour). If the duration is longer than one hour, the session for AWS account owners defaults to one hour.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_600239 = query.getOrDefault("TokenCode")
  valid_600239 = validateParameter(valid_600239, JString, required = false,
                                 default = nil)
  if valid_600239 != nil:
    section.add "TokenCode", valid_600239
  var valid_600240 = query.getOrDefault("SerialNumber")
  valid_600240 = validateParameter(valid_600240, JString, required = false,
                                 default = nil)
  if valid_600240 != nil:
    section.add "SerialNumber", valid_600240
  var valid_600241 = query.getOrDefault("DurationSeconds")
  valid_600241 = validateParameter(valid_600241, JInt, required = false, default = nil)
  if valid_600241 != nil:
    section.add "DurationSeconds", valid_600241
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600242 = query.getOrDefault("Action")
  valid_600242 = validateParameter(valid_600242, JString, required = true,
                                 default = newJString("GetSessionToken"))
  if valid_600242 != nil:
    section.add "Action", valid_600242
  var valid_600243 = query.getOrDefault("Version")
  valid_600243 = validateParameter(valid_600243, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_600243 != nil:
    section.add "Version", valid_600243
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
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
  var valid_600246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600246 = validateParameter(valid_600246, JString, required = false,
                                 default = nil)
  if valid_600246 != nil:
    section.add "X-Amz-Content-Sha256", valid_600246
  var valid_600247 = header.getOrDefault("X-Amz-Algorithm")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "X-Amz-Algorithm", valid_600247
  var valid_600248 = header.getOrDefault("X-Amz-Signature")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "X-Amz-Signature", valid_600248
  var valid_600249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600249 = validateParameter(valid_600249, JString, required = false,
                                 default = nil)
  if valid_600249 != nil:
    section.add "X-Amz-SignedHeaders", valid_600249
  var valid_600250 = header.getOrDefault("X-Amz-Credential")
  valid_600250 = validateParameter(valid_600250, JString, required = false,
                                 default = nil)
  if valid_600250 != nil:
    section.add "X-Amz-Credential", valid_600250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600251: Call_GetGetSessionToken_600236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a set of temporary credentials for an AWS account or IAM user. The credentials consist of an access key ID, a secret access key, and a security token. Typically, you use <code>GetSessionToken</code> if you want to use MFA to protect programmatic calls to specific AWS API operations like Amazon EC2 <code>StopInstances</code>. MFA-enabled IAM users would need to call <code>GetSessionToken</code> and submit an MFA code that is associated with their MFA device. Using the temporary security credentials that are returned from the call, IAM users can then make programmatic calls to API operations that require MFA authentication. If you do not supply a correct MFA code, then the API returns an access denied error. For a comparison of <code>GetSessionToken</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p> <b>Session Duration</b> </p> <p>The <code>GetSessionToken</code> operation must be called by using the long-term AWS security credentials of the AWS account root user or an IAM user. Credentials that are created by IAM users are valid for the duration that you specify. This duration can range from 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36 hours), with a default of 43,200 seconds (12 hours). Credentials based on account credentials can range from 900 seconds (15 minutes) up to 3,600 seconds (1 hour), with a default of 1 hour. </p> <p> <b>Permissions</b> </p> <p>The temporary security credentials created by <code>GetSessionToken</code> can be used to make API calls to any AWS service with the following exceptions:</p> <ul> <li> <p>You cannot call any IAM API operations unless MFA authentication information is included in the request.</p> </li> <li> <p>You cannot call any STS API <i>except</i> <code>AssumeRole</code> or <code>GetCallerIdentity</code>.</p> </li> </ul> <note> <p>We recommend that you do not call <code>GetSessionToken</code> with AWS account root user credentials. Instead, follow our <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#create-iam-users">best practices</a> by creating one or more IAM users, giving them the necessary permissions, and using IAM users for everyday interaction with AWS. </p> </note> <p>The credentials that are returned by <code>GetSessionToken</code> are based on permissions associated with the user whose credentials were used to call the operation. If <code>GetSessionToken</code> is called using AWS account root user credentials, the temporary credentials have root user permissions. Similarly, if <code>GetSessionToken</code> is called using the credentials of an IAM user, the temporary credentials have the same permissions as the IAM user. </p> <p>For more information about using <code>GetSessionToken</code> to create temporary credentials, go to <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getsessiontoken">Temporary Credentials for Users in Untrusted Environments</a> in the <i>IAM User Guide</i>. </p>
  ## 
  let valid = call_600251.validator(path, query, header, formData, body)
  let scheme = call_600251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600251.url(scheme.get, call_600251.host, call_600251.base,
                         call_600251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600251, url, valid)

proc call*(call_600252: Call_GetGetSessionToken_600236; TokenCode: string = "";
          SerialNumber: string = ""; DurationSeconds: int = 0;
          Action: string = "GetSessionToken"; Version: string = "2011-06-15"): Recallable =
  ## getGetSessionToken
  ## <p>Returns a set of temporary credentials for an AWS account or IAM user. The credentials consist of an access key ID, a secret access key, and a security token. Typically, you use <code>GetSessionToken</code> if you want to use MFA to protect programmatic calls to specific AWS API operations like Amazon EC2 <code>StopInstances</code>. MFA-enabled IAM users would need to call <code>GetSessionToken</code> and submit an MFA code that is associated with their MFA device. Using the temporary security credentials that are returned from the call, IAM users can then make programmatic calls to API operations that require MFA authentication. If you do not supply a correct MFA code, then the API returns an access denied error. For a comparison of <code>GetSessionToken</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p> <b>Session Duration</b> </p> <p>The <code>GetSessionToken</code> operation must be called by using the long-term AWS security credentials of the AWS account root user or an IAM user. Credentials that are created by IAM users are valid for the duration that you specify. This duration can range from 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36 hours), with a default of 43,200 seconds (12 hours). Credentials based on account credentials can range from 900 seconds (15 minutes) up to 3,600 seconds (1 hour), with a default of 1 hour. </p> <p> <b>Permissions</b> </p> <p>The temporary security credentials created by <code>GetSessionToken</code> can be used to make API calls to any AWS service with the following exceptions:</p> <ul> <li> <p>You cannot call any IAM API operations unless MFA authentication information is included in the request.</p> </li> <li> <p>You cannot call any STS API <i>except</i> <code>AssumeRole</code> or <code>GetCallerIdentity</code>.</p> </li> </ul> <note> <p>We recommend that you do not call <code>GetSessionToken</code> with AWS account root user credentials. Instead, follow our <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#create-iam-users">best practices</a> by creating one or more IAM users, giving them the necessary permissions, and using IAM users for everyday interaction with AWS. </p> </note> <p>The credentials that are returned by <code>GetSessionToken</code> are based on permissions associated with the user whose credentials were used to call the operation. If <code>GetSessionToken</code> is called using AWS account root user credentials, the temporary credentials have root user permissions. Similarly, if <code>GetSessionToken</code> is called using the credentials of an IAM user, the temporary credentials have the same permissions as the IAM user. </p> <p>For more information about using <code>GetSessionToken</code> to create temporary credentials, go to <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getsessiontoken">Temporary Credentials for Users in Untrusted Environments</a> in the <i>IAM User Guide</i>. </p>
  ##   TokenCode: string
  ##            : <p>The value provided by the MFA device, if MFA is required. If any policy requires the IAM user to submit an MFA code, specify this value. If MFA authentication is required, the user must provide a code when requesting a set of temporary security credentials. A user who fails to provide the code receives an "access denied" response when requesting resources that require MFA authentication.</p> <p>The format for this parameter, as described by its regex pattern, is a sequence of six numeric digits.</p>
  ##   SerialNumber: string
  ##               : <p>The identification number of the MFA device that is associated with the IAM user who is making the <code>GetSessionToken</code> call. Specify this value if the IAM user has a policy that requires MFA authentication. The value is either the serial number for a hardware device (such as <code>GAHT12345678</code>) or an Amazon Resource Name (ARN) for a virtual device (such as <code>arn:aws:iam::123456789012:mfa/user</code>). You can find the device for an IAM user by going to the AWS Management Console and viewing the user's security credentials. </p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@:/-</p>
  ##   DurationSeconds: int
  ##                  : The duration, in seconds, that the credentials should remain valid. Acceptable durations for IAM user sessions range from 900 seconds (15 minutes) to 129,600 seconds (36 hours), with 43,200 seconds (12 hours) as the default. Sessions for AWS account owners are restricted to a maximum of 3,600 seconds (one hour). If the duration is longer than one hour, the session for AWS account owners defaults to one hour.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600253 = newJObject()
  add(query_600253, "TokenCode", newJString(TokenCode))
  add(query_600253, "SerialNumber", newJString(SerialNumber))
  add(query_600253, "DurationSeconds", newJInt(DurationSeconds))
  add(query_600253, "Action", newJString(Action))
  add(query_600253, "Version", newJString(Version))
  result = call_600252.call(nil, query_600253, nil, nil, nil)

var getGetSessionToken* = Call_GetGetSessionToken_600236(
    name: "getGetSessionToken", meth: HttpMethod.HttpGet, host: "sts.amazonaws.com",
    route: "/#Action=GetSessionToken", validator: validate_GetGetSessionToken_600237,
    base: "/", url: url_GetGetSessionToken_600238,
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
