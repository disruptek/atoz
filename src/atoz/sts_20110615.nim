
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_PostAssumeRole_601046 = ref object of OpenApiRestCall_600426
proc url_PostAssumeRole_601048(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAssumeRole_601047(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns a set of temporary security credentials that you can use to access AWS resources that you might not normally have access to. These temporary credentials consist of an access key ID, a secret access key, and a security token. Typically, you use <code>AssumeRole</code> within your account or for cross-account access. For a comparison of <code>AssumeRole</code> with other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <important> <p>You cannot use AWS account root user credentials to call <code>AssumeRole</code>. You must use credentials for an IAM user or an IAM role to call <code>AssumeRole</code>.</p> </important> <p>For cross-account access, imagine that you own multiple accounts and need to access resources in each account. You could create long-term credentials in each account to access those resources. However, managing all those credentials and remembering which one can access which account can be time consuming. Instead, you can create one set of long-term credentials in one account. Then use temporary security credentials to access all the other accounts by assuming roles in those accounts. For more information about roles, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html">IAM Roles</a> in the <i>IAM User Guide</i>. </p> <p>By default, the temporary security credentials created by <code>AssumeRole</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. You can provide a value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials created by <code>AssumeRole</code> can be used to make API calls to any AWS service with the following exception: You cannot call the AWS STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>To assume a role from a different account, your AWS account must be trusted by the role. The trust relationship is defined in the role's trust policy when the role is created. That trust policy states which accounts are allowed to delegate that access to users in the account. </p> <p>A user who wants to access a role in a different account must also have permissions that are delegated from the user account administrator. The administrator must attach a policy that allows the user to call <code>AssumeRole</code> for the ARN of the role in the other account. If the user is in the same account as the role, then you can do either of the following:</p> <ul> <li> <p>Attach a policy to the user (identical to the previous user in a different account).</p> </li> <li> <p>Add the user as a principal directly in the role's trust policy.</p> </li> </ul> <p>In this case, the trust policy acts as an IAM resource-based policy. Users in the same account as the role do not need explicit permission to assume the role. For more information about trust policies and resource-based policies, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html">IAM Policies</a> in the <i>IAM User Guide</i>.</p> <p> <b>Using MFA with AssumeRole</b> </p> <p>(Optional) You can include multi-factor authentication (MFA) information when you call <code>AssumeRole</code>. This is useful for cross-account scenarios to ensure that the user that assumes the role has been authenticated with an AWS MFA device. In that scenario, the trust policy of the role being assumed includes a condition that tests for MFA authentication. If the caller does not include valid MFA information, the request to assume the role is denied. The condition in a trust policy that tests for MFA authentication might look like the following example.</p> <p> <code>"Condition": {"Bool": {"aws:MultiFactorAuthPresent": true}}</code> </p> <p>For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/MFAProtectedAPI.html">Configuring MFA-Protected API Access</a> in the <i>IAM User Guide</i> guide.</p> <p>To use MFA with <code>AssumeRole</code>, you pass values for the <code>SerialNumber</code> and <code>TokenCode</code> parameters. The <code>SerialNumber</code> value identifies the user's hardware or virtual MFA device. The <code>TokenCode</code> is the time-based one-time password (TOTP) that the MFA device produces. </p>
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
  var valid_601049 = query.getOrDefault("Action")
  valid_601049 = validateParameter(valid_601049, JString, required = true,
                                 default = newJString("AssumeRole"))
  if valid_601049 != nil:
    section.add "Action", valid_601049
  var valid_601050 = query.getOrDefault("Version")
  valid_601050 = validateParameter(valid_601050, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_601050 != nil:
    section.add "Version", valid_601050
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
  var valid_601051 = header.getOrDefault("X-Amz-Date")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-Date", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-Security-Token")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-Security-Token", valid_601052
  var valid_601053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-Content-Sha256", valid_601053
  var valid_601054 = header.getOrDefault("X-Amz-Algorithm")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "X-Amz-Algorithm", valid_601054
  var valid_601055 = header.getOrDefault("X-Amz-Signature")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Signature", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-SignedHeaders", valid_601056
  var valid_601057 = header.getOrDefault("X-Amz-Credential")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Credential", valid_601057
  result.add "header", section
  ## parameters in `formData` object:
  ##   SerialNumber: JString
  ##               : <p>The identification number of the MFA device that is associated with the user who is making the <code>AssumeRole</code> call. Specify this value if the trust policy of the role being assumed includes a condition that requires MFA authentication. The value is either the serial number for a hardware device (such as <code>GAHT12345678</code>) or an Amazon Resource Name (ARN) for a virtual device (such as <code>arn:aws:iam::123456789012:mfa/user</code>).</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-</p>
  ##   RoleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the role to assume.
  ##   PolicyArns: JArray
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as managed session policies. The policies must exist in the same account as the role.</p> <p>This parameter is optional. You can provide up to 10 managed policy ARNs. However, the plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note> <p>Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p>
  ##   ExternalId: JString
  ##             : <p>A unique identifier that might be required when you assume a role in another account. If the administrator of the account to which the role belongs provided you with an external ID, then provide that value in the <code>ExternalId</code> parameter. This value can be any string, such as a passphrase or account number. A cross-account role is usually set up to trust everyone in an account. Therefore, the administrator of the trusting account might send an external ID to the administrator of the trusted account. That way, only someone with the ID can assume the role, rather than everyone in the account. For more information about the external ID, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user_externalid.html">How to Use an External ID When Granting Access to Your AWS Resources to a Third Party</a> in the <i>IAM User Guide</i>.</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@:/-</p>
  ##   RoleSessionName: JString (required)
  ##                  : <p>An identifier for the assumed role session.</p> <p>Use the role session name to uniquely identify a session when the same role is assumed by different principals or for different reasons. In cross-account scenarios, the role session name is visible to, and can be logged by the account that owns the role. The role session name is also used in the ARN of the assumed role principal. This means that subsequent cross-account API requests that use the temporary security credentials will expose the role session name to the external account in their AWS CloudTrail logs.</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-</p>
  ##   Policy: JString
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>This parameter is optional. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note>
  ##   TokenCode: JString
  ##            : <p>The value provided by the MFA device, if the trust policy of the role being assumed requires MFA (that is, if the policy includes a condition that tests for MFA). If the role being assumed requires MFA and if the <code>TokenCode</code> value is missing or expired, the <code>AssumeRole</code> call returns an "access denied" error.</p> <p>The format for this parameter, as described by its regex pattern, is a sequence of six numeric digits.</p>
  ##   DurationSeconds: JInt
  ##                  : <p>The duration, in seconds, of the role session. The value can range from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. If you specify a value higher than this setting, the operation fails. For example, if you specify a session duration of 12 hours, but your administrator set the maximum session duration to 6 hours, your operation fails. To learn how to view the maximum value for your role, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>.</p> <p>By default, the value is set to <code>3600</code> seconds. </p> <note> <p>The <code>DurationSeconds</code> parameter is separate from the duration of a console session that you might request using the returned credentials. The request to the federation endpoint for a console sign-in token takes a <code>SessionDuration</code> parameter that specifies the maximum length of the console session. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html">Creating a URL that Enables Federated Users to Access the AWS Management Console</a> in the <i>IAM User Guide</i>.</p> </note>
  section = newJObject()
  var valid_601058 = formData.getOrDefault("SerialNumber")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "SerialNumber", valid_601058
  assert formData != nil,
        "formData argument is necessary due to required `RoleArn` field"
  var valid_601059 = formData.getOrDefault("RoleArn")
  valid_601059 = validateParameter(valid_601059, JString, required = true,
                                 default = nil)
  if valid_601059 != nil:
    section.add "RoleArn", valid_601059
  var valid_601060 = formData.getOrDefault("PolicyArns")
  valid_601060 = validateParameter(valid_601060, JArray, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "PolicyArns", valid_601060
  var valid_601061 = formData.getOrDefault("ExternalId")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "ExternalId", valid_601061
  var valid_601062 = formData.getOrDefault("RoleSessionName")
  valid_601062 = validateParameter(valid_601062, JString, required = true,
                                 default = nil)
  if valid_601062 != nil:
    section.add "RoleSessionName", valid_601062
  var valid_601063 = formData.getOrDefault("Policy")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "Policy", valid_601063
  var valid_601064 = formData.getOrDefault("TokenCode")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "TokenCode", valid_601064
  var valid_601065 = formData.getOrDefault("DurationSeconds")
  valid_601065 = validateParameter(valid_601065, JInt, required = false, default = nil)
  if valid_601065 != nil:
    section.add "DurationSeconds", valid_601065
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601066: Call_PostAssumeRole_601046; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a set of temporary security credentials that you can use to access AWS resources that you might not normally have access to. These temporary credentials consist of an access key ID, a secret access key, and a security token. Typically, you use <code>AssumeRole</code> within your account or for cross-account access. For a comparison of <code>AssumeRole</code> with other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <important> <p>You cannot use AWS account root user credentials to call <code>AssumeRole</code>. You must use credentials for an IAM user or an IAM role to call <code>AssumeRole</code>.</p> </important> <p>For cross-account access, imagine that you own multiple accounts and need to access resources in each account. You could create long-term credentials in each account to access those resources. However, managing all those credentials and remembering which one can access which account can be time consuming. Instead, you can create one set of long-term credentials in one account. Then use temporary security credentials to access all the other accounts by assuming roles in those accounts. For more information about roles, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html">IAM Roles</a> in the <i>IAM User Guide</i>. </p> <p>By default, the temporary security credentials created by <code>AssumeRole</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. You can provide a value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials created by <code>AssumeRole</code> can be used to make API calls to any AWS service with the following exception: You cannot call the AWS STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>To assume a role from a different account, your AWS account must be trusted by the role. The trust relationship is defined in the role's trust policy when the role is created. That trust policy states which accounts are allowed to delegate that access to users in the account. </p> <p>A user who wants to access a role in a different account must also have permissions that are delegated from the user account administrator. The administrator must attach a policy that allows the user to call <code>AssumeRole</code> for the ARN of the role in the other account. If the user is in the same account as the role, then you can do either of the following:</p> <ul> <li> <p>Attach a policy to the user (identical to the previous user in a different account).</p> </li> <li> <p>Add the user as a principal directly in the role's trust policy.</p> </li> </ul> <p>In this case, the trust policy acts as an IAM resource-based policy. Users in the same account as the role do not need explicit permission to assume the role. For more information about trust policies and resource-based policies, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html">IAM Policies</a> in the <i>IAM User Guide</i>.</p> <p> <b>Using MFA with AssumeRole</b> </p> <p>(Optional) You can include multi-factor authentication (MFA) information when you call <code>AssumeRole</code>. This is useful for cross-account scenarios to ensure that the user that assumes the role has been authenticated with an AWS MFA device. In that scenario, the trust policy of the role being assumed includes a condition that tests for MFA authentication. If the caller does not include valid MFA information, the request to assume the role is denied. The condition in a trust policy that tests for MFA authentication might look like the following example.</p> <p> <code>"Condition": {"Bool": {"aws:MultiFactorAuthPresent": true}}</code> </p> <p>For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/MFAProtectedAPI.html">Configuring MFA-Protected API Access</a> in the <i>IAM User Guide</i> guide.</p> <p>To use MFA with <code>AssumeRole</code>, you pass values for the <code>SerialNumber</code> and <code>TokenCode</code> parameters. The <code>SerialNumber</code> value identifies the user's hardware or virtual MFA device. The <code>TokenCode</code> is the time-based one-time password (TOTP) that the MFA device produces. </p>
  ## 
  let valid = call_601066.validator(path, query, header, formData, body)
  let scheme = call_601066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601066.url(scheme.get, call_601066.host, call_601066.base,
                         call_601066.route, valid.getOrDefault("path"))
  result = hook(call_601066, url, valid)

proc call*(call_601067: Call_PostAssumeRole_601046; RoleArn: string;
          RoleSessionName: string; SerialNumber: string = "";
          Action: string = "AssumeRole"; PolicyArns: JsonNode = nil;
          ExternalId: string = ""; Policy: string = ""; Version: string = "2011-06-15";
          TokenCode: string = ""; DurationSeconds: int = 0): Recallable =
  ## postAssumeRole
  ## <p>Returns a set of temporary security credentials that you can use to access AWS resources that you might not normally have access to. These temporary credentials consist of an access key ID, a secret access key, and a security token. Typically, you use <code>AssumeRole</code> within your account or for cross-account access. For a comparison of <code>AssumeRole</code> with other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <important> <p>You cannot use AWS account root user credentials to call <code>AssumeRole</code>. You must use credentials for an IAM user or an IAM role to call <code>AssumeRole</code>.</p> </important> <p>For cross-account access, imagine that you own multiple accounts and need to access resources in each account. You could create long-term credentials in each account to access those resources. However, managing all those credentials and remembering which one can access which account can be time consuming. Instead, you can create one set of long-term credentials in one account. Then use temporary security credentials to access all the other accounts by assuming roles in those accounts. For more information about roles, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html">IAM Roles</a> in the <i>IAM User Guide</i>. </p> <p>By default, the temporary security credentials created by <code>AssumeRole</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. You can provide a value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials created by <code>AssumeRole</code> can be used to make API calls to any AWS service with the following exception: You cannot call the AWS STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>To assume a role from a different account, your AWS account must be trusted by the role. The trust relationship is defined in the role's trust policy when the role is created. That trust policy states which accounts are allowed to delegate that access to users in the account. </p> <p>A user who wants to access a role in a different account must also have permissions that are delegated from the user account administrator. The administrator must attach a policy that allows the user to call <code>AssumeRole</code> for the ARN of the role in the other account. If the user is in the same account as the role, then you can do either of the following:</p> <ul> <li> <p>Attach a policy to the user (identical to the previous user in a different account).</p> </li> <li> <p>Add the user as a principal directly in the role's trust policy.</p> </li> </ul> <p>In this case, the trust policy acts as an IAM resource-based policy. Users in the same account as the role do not need explicit permission to assume the role. For more information about trust policies and resource-based policies, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html">IAM Policies</a> in the <i>IAM User Guide</i>.</p> <p> <b>Using MFA with AssumeRole</b> </p> <p>(Optional) You can include multi-factor authentication (MFA) information when you call <code>AssumeRole</code>. This is useful for cross-account scenarios to ensure that the user that assumes the role has been authenticated with an AWS MFA device. In that scenario, the trust policy of the role being assumed includes a condition that tests for MFA authentication. If the caller does not include valid MFA information, the request to assume the role is denied. The condition in a trust policy that tests for MFA authentication might look like the following example.</p> <p> <code>"Condition": {"Bool": {"aws:MultiFactorAuthPresent": true}}</code> </p> <p>For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/MFAProtectedAPI.html">Configuring MFA-Protected API Access</a> in the <i>IAM User Guide</i> guide.</p> <p>To use MFA with <code>AssumeRole</code>, you pass values for the <code>SerialNumber</code> and <code>TokenCode</code> parameters. The <code>SerialNumber</code> value identifies the user's hardware or virtual MFA device. The <code>TokenCode</code> is the time-based one-time password (TOTP) that the MFA device produces. </p>
  ##   SerialNumber: string
  ##               : <p>The identification number of the MFA device that is associated with the user who is making the <code>AssumeRole</code> call. Specify this value if the trust policy of the role being assumed includes a condition that requires MFA authentication. The value is either the serial number for a hardware device (such as <code>GAHT12345678</code>) or an Amazon Resource Name (ARN) for a virtual device (such as <code>arn:aws:iam::123456789012:mfa/user</code>).</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-</p>
  ##   RoleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the role to assume.
  ##   Action: string (required)
  ##   PolicyArns: JArray
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as managed session policies. The policies must exist in the same account as the role.</p> <p>This parameter is optional. You can provide up to 10 managed policy ARNs. However, the plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note> <p>Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p>
  ##   ExternalId: string
  ##             : <p>A unique identifier that might be required when you assume a role in another account. If the administrator of the account to which the role belongs provided you with an external ID, then provide that value in the <code>ExternalId</code> parameter. This value can be any string, such as a passphrase or account number. A cross-account role is usually set up to trust everyone in an account. Therefore, the administrator of the trusting account might send an external ID to the administrator of the trusted account. That way, only someone with the ID can assume the role, rather than everyone in the account. For more information about the external ID, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user_externalid.html">How to Use an External ID When Granting Access to Your AWS Resources to a Third Party</a> in the <i>IAM User Guide</i>.</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@:/-</p>
  ##   RoleSessionName: string (required)
  ##                  : <p>An identifier for the assumed role session.</p> <p>Use the role session name to uniquely identify a session when the same role is assumed by different principals or for different reasons. In cross-account scenarios, the role session name is visible to, and can be logged by the account that owns the role. The role session name is also used in the ARN of the assumed role principal. This means that subsequent cross-account API requests that use the temporary security credentials will expose the role session name to the external account in their AWS CloudTrail logs.</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-</p>
  ##   Policy: string
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>This parameter is optional. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note>
  ##   Version: string (required)
  ##   TokenCode: string
  ##            : <p>The value provided by the MFA device, if the trust policy of the role being assumed requires MFA (that is, if the policy includes a condition that tests for MFA). If the role being assumed requires MFA and if the <code>TokenCode</code> value is missing or expired, the <code>AssumeRole</code> call returns an "access denied" error.</p> <p>The format for this parameter, as described by its regex pattern, is a sequence of six numeric digits.</p>
  ##   DurationSeconds: int
  ##                  : <p>The duration, in seconds, of the role session. The value can range from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. If you specify a value higher than this setting, the operation fails. For example, if you specify a session duration of 12 hours, but your administrator set the maximum session duration to 6 hours, your operation fails. To learn how to view the maximum value for your role, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>.</p> <p>By default, the value is set to <code>3600</code> seconds. </p> <note> <p>The <code>DurationSeconds</code> parameter is separate from the duration of a console session that you might request using the returned credentials. The request to the federation endpoint for a console sign-in token takes a <code>SessionDuration</code> parameter that specifies the maximum length of the console session. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html">Creating a URL that Enables Federated Users to Access the AWS Management Console</a> in the <i>IAM User Guide</i>.</p> </note>
  var query_601068 = newJObject()
  var formData_601069 = newJObject()
  add(formData_601069, "SerialNumber", newJString(SerialNumber))
  add(formData_601069, "RoleArn", newJString(RoleArn))
  add(query_601068, "Action", newJString(Action))
  if PolicyArns != nil:
    formData_601069.add "PolicyArns", PolicyArns
  add(formData_601069, "ExternalId", newJString(ExternalId))
  add(formData_601069, "RoleSessionName", newJString(RoleSessionName))
  add(formData_601069, "Policy", newJString(Policy))
  add(query_601068, "Version", newJString(Version))
  add(formData_601069, "TokenCode", newJString(TokenCode))
  add(formData_601069, "DurationSeconds", newJInt(DurationSeconds))
  result = call_601067.call(nil, query_601068, nil, formData_601069, nil)

var postAssumeRole* = Call_PostAssumeRole_601046(name: "postAssumeRole",
    meth: HttpMethod.HttpPost, host: "sts.amazonaws.com",
    route: "/#Action=AssumeRole", validator: validate_PostAssumeRole_601047,
    base: "/", url: url_PostAssumeRole_601048, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssumeRole_600768 = ref object of OpenApiRestCall_600426
proc url_GetAssumeRole_600770(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAssumeRole_600769(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a set of temporary security credentials that you can use to access AWS resources that you might not normally have access to. These temporary credentials consist of an access key ID, a secret access key, and a security token. Typically, you use <code>AssumeRole</code> within your account or for cross-account access. For a comparison of <code>AssumeRole</code> with other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <important> <p>You cannot use AWS account root user credentials to call <code>AssumeRole</code>. You must use credentials for an IAM user or an IAM role to call <code>AssumeRole</code>.</p> </important> <p>For cross-account access, imagine that you own multiple accounts and need to access resources in each account. You could create long-term credentials in each account to access those resources. However, managing all those credentials and remembering which one can access which account can be time consuming. Instead, you can create one set of long-term credentials in one account. Then use temporary security credentials to access all the other accounts by assuming roles in those accounts. For more information about roles, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html">IAM Roles</a> in the <i>IAM User Guide</i>. </p> <p>By default, the temporary security credentials created by <code>AssumeRole</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. You can provide a value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials created by <code>AssumeRole</code> can be used to make API calls to any AWS service with the following exception: You cannot call the AWS STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>To assume a role from a different account, your AWS account must be trusted by the role. The trust relationship is defined in the role's trust policy when the role is created. That trust policy states which accounts are allowed to delegate that access to users in the account. </p> <p>A user who wants to access a role in a different account must also have permissions that are delegated from the user account administrator. The administrator must attach a policy that allows the user to call <code>AssumeRole</code> for the ARN of the role in the other account. If the user is in the same account as the role, then you can do either of the following:</p> <ul> <li> <p>Attach a policy to the user (identical to the previous user in a different account).</p> </li> <li> <p>Add the user as a principal directly in the role's trust policy.</p> </li> </ul> <p>In this case, the trust policy acts as an IAM resource-based policy. Users in the same account as the role do not need explicit permission to assume the role. For more information about trust policies and resource-based policies, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html">IAM Policies</a> in the <i>IAM User Guide</i>.</p> <p> <b>Using MFA with AssumeRole</b> </p> <p>(Optional) You can include multi-factor authentication (MFA) information when you call <code>AssumeRole</code>. This is useful for cross-account scenarios to ensure that the user that assumes the role has been authenticated with an AWS MFA device. In that scenario, the trust policy of the role being assumed includes a condition that tests for MFA authentication. If the caller does not include valid MFA information, the request to assume the role is denied. The condition in a trust policy that tests for MFA authentication might look like the following example.</p> <p> <code>"Condition": {"Bool": {"aws:MultiFactorAuthPresent": true}}</code> </p> <p>For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/MFAProtectedAPI.html">Configuring MFA-Protected API Access</a> in the <i>IAM User Guide</i> guide.</p> <p>To use MFA with <code>AssumeRole</code>, you pass values for the <code>SerialNumber</code> and <code>TokenCode</code> parameters. The <code>SerialNumber</code> value identifies the user's hardware or virtual MFA device. The <code>TokenCode</code> is the time-based one-time password (TOTP) that the MFA device produces. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
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
  ##   PolicyArns: JArray
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as managed session policies. The policies must exist in the same account as the role.</p> <p>This parameter is optional. You can provide up to 10 managed policy ARNs. However, the plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note> <p>Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p>
  ##   Action: JString (required)
  ##   Policy: JString
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>This parameter is optional. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note>
  ##   ExternalId: JString
  ##             : <p>A unique identifier that might be required when you assume a role in another account. If the administrator of the account to which the role belongs provided you with an external ID, then provide that value in the <code>ExternalId</code> parameter. This value can be any string, such as a passphrase or account number. A cross-account role is usually set up to trust everyone in an account. Therefore, the administrator of the trusting account might send an external ID to the administrator of the trusted account. That way, only someone with the ID can assume the role, rather than everyone in the account. For more information about the external ID, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user_externalid.html">How to Use an External ID When Granting Access to Your AWS Resources to a Third Party</a> in the <i>IAM User Guide</i>.</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@:/-</p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_600882 = query.getOrDefault("TokenCode")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "TokenCode", valid_600882
  var valid_600883 = query.getOrDefault("SerialNumber")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "SerialNumber", valid_600883
  assert query != nil, "query argument is necessary due to required `RoleArn` field"
  var valid_600884 = query.getOrDefault("RoleArn")
  valid_600884 = validateParameter(valid_600884, JString, required = true,
                                 default = nil)
  if valid_600884 != nil:
    section.add "RoleArn", valid_600884
  var valid_600885 = query.getOrDefault("DurationSeconds")
  valid_600885 = validateParameter(valid_600885, JInt, required = false, default = nil)
  if valid_600885 != nil:
    section.add "DurationSeconds", valid_600885
  var valid_600886 = query.getOrDefault("RoleSessionName")
  valid_600886 = validateParameter(valid_600886, JString, required = true,
                                 default = nil)
  if valid_600886 != nil:
    section.add "RoleSessionName", valid_600886
  var valid_600887 = query.getOrDefault("PolicyArns")
  valid_600887 = validateParameter(valid_600887, JArray, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "PolicyArns", valid_600887
  var valid_600901 = query.getOrDefault("Action")
  valid_600901 = validateParameter(valid_600901, JString, required = true,
                                 default = newJString("AssumeRole"))
  if valid_600901 != nil:
    section.add "Action", valid_600901
  var valid_600902 = query.getOrDefault("Policy")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "Policy", valid_600902
  var valid_600903 = query.getOrDefault("ExternalId")
  valid_600903 = validateParameter(valid_600903, JString, required = false,
                                 default = nil)
  if valid_600903 != nil:
    section.add "ExternalId", valid_600903
  var valid_600904 = query.getOrDefault("Version")
  valid_600904 = validateParameter(valid_600904, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_600904 != nil:
    section.add "Version", valid_600904
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
  var valid_600905 = header.getOrDefault("X-Amz-Date")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "X-Amz-Date", valid_600905
  var valid_600906 = header.getOrDefault("X-Amz-Security-Token")
  valid_600906 = validateParameter(valid_600906, JString, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "X-Amz-Security-Token", valid_600906
  var valid_600907 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600907 = validateParameter(valid_600907, JString, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "X-Amz-Content-Sha256", valid_600907
  var valid_600908 = header.getOrDefault("X-Amz-Algorithm")
  valid_600908 = validateParameter(valid_600908, JString, required = false,
                                 default = nil)
  if valid_600908 != nil:
    section.add "X-Amz-Algorithm", valid_600908
  var valid_600909 = header.getOrDefault("X-Amz-Signature")
  valid_600909 = validateParameter(valid_600909, JString, required = false,
                                 default = nil)
  if valid_600909 != nil:
    section.add "X-Amz-Signature", valid_600909
  var valid_600910 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600910 = validateParameter(valid_600910, JString, required = false,
                                 default = nil)
  if valid_600910 != nil:
    section.add "X-Amz-SignedHeaders", valid_600910
  var valid_600911 = header.getOrDefault("X-Amz-Credential")
  valid_600911 = validateParameter(valid_600911, JString, required = false,
                                 default = nil)
  if valid_600911 != nil:
    section.add "X-Amz-Credential", valid_600911
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600934: Call_GetAssumeRole_600768; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a set of temporary security credentials that you can use to access AWS resources that you might not normally have access to. These temporary credentials consist of an access key ID, a secret access key, and a security token. Typically, you use <code>AssumeRole</code> within your account or for cross-account access. For a comparison of <code>AssumeRole</code> with other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <important> <p>You cannot use AWS account root user credentials to call <code>AssumeRole</code>. You must use credentials for an IAM user or an IAM role to call <code>AssumeRole</code>.</p> </important> <p>For cross-account access, imagine that you own multiple accounts and need to access resources in each account. You could create long-term credentials in each account to access those resources. However, managing all those credentials and remembering which one can access which account can be time consuming. Instead, you can create one set of long-term credentials in one account. Then use temporary security credentials to access all the other accounts by assuming roles in those accounts. For more information about roles, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html">IAM Roles</a> in the <i>IAM User Guide</i>. </p> <p>By default, the temporary security credentials created by <code>AssumeRole</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. You can provide a value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials created by <code>AssumeRole</code> can be used to make API calls to any AWS service with the following exception: You cannot call the AWS STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>To assume a role from a different account, your AWS account must be trusted by the role. The trust relationship is defined in the role's trust policy when the role is created. That trust policy states which accounts are allowed to delegate that access to users in the account. </p> <p>A user who wants to access a role in a different account must also have permissions that are delegated from the user account administrator. The administrator must attach a policy that allows the user to call <code>AssumeRole</code> for the ARN of the role in the other account. If the user is in the same account as the role, then you can do either of the following:</p> <ul> <li> <p>Attach a policy to the user (identical to the previous user in a different account).</p> </li> <li> <p>Add the user as a principal directly in the role's trust policy.</p> </li> </ul> <p>In this case, the trust policy acts as an IAM resource-based policy. Users in the same account as the role do not need explicit permission to assume the role. For more information about trust policies and resource-based policies, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html">IAM Policies</a> in the <i>IAM User Guide</i>.</p> <p> <b>Using MFA with AssumeRole</b> </p> <p>(Optional) You can include multi-factor authentication (MFA) information when you call <code>AssumeRole</code>. This is useful for cross-account scenarios to ensure that the user that assumes the role has been authenticated with an AWS MFA device. In that scenario, the trust policy of the role being assumed includes a condition that tests for MFA authentication. If the caller does not include valid MFA information, the request to assume the role is denied. The condition in a trust policy that tests for MFA authentication might look like the following example.</p> <p> <code>"Condition": {"Bool": {"aws:MultiFactorAuthPresent": true}}</code> </p> <p>For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/MFAProtectedAPI.html">Configuring MFA-Protected API Access</a> in the <i>IAM User Guide</i> guide.</p> <p>To use MFA with <code>AssumeRole</code>, you pass values for the <code>SerialNumber</code> and <code>TokenCode</code> parameters. The <code>SerialNumber</code> value identifies the user's hardware or virtual MFA device. The <code>TokenCode</code> is the time-based one-time password (TOTP) that the MFA device produces. </p>
  ## 
  let valid = call_600934.validator(path, query, header, formData, body)
  let scheme = call_600934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600934.url(scheme.get, call_600934.host, call_600934.base,
                         call_600934.route, valid.getOrDefault("path"))
  result = hook(call_600934, url, valid)

proc call*(call_601005: Call_GetAssumeRole_600768; RoleArn: string;
          RoleSessionName: string; TokenCode: string = ""; SerialNumber: string = "";
          DurationSeconds: int = 0; PolicyArns: JsonNode = nil;
          Action: string = "AssumeRole"; Policy: string = ""; ExternalId: string = "";
          Version: string = "2011-06-15"): Recallable =
  ## getAssumeRole
  ## <p>Returns a set of temporary security credentials that you can use to access AWS resources that you might not normally have access to. These temporary credentials consist of an access key ID, a secret access key, and a security token. Typically, you use <code>AssumeRole</code> within your account or for cross-account access. For a comparison of <code>AssumeRole</code> with other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <important> <p>You cannot use AWS account root user credentials to call <code>AssumeRole</code>. You must use credentials for an IAM user or an IAM role to call <code>AssumeRole</code>.</p> </important> <p>For cross-account access, imagine that you own multiple accounts and need to access resources in each account. You could create long-term credentials in each account to access those resources. However, managing all those credentials and remembering which one can access which account can be time consuming. Instead, you can create one set of long-term credentials in one account. Then use temporary security credentials to access all the other accounts by assuming roles in those accounts. For more information about roles, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html">IAM Roles</a> in the <i>IAM User Guide</i>. </p> <p>By default, the temporary security credentials created by <code>AssumeRole</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. You can provide a value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials created by <code>AssumeRole</code> can be used to make API calls to any AWS service with the following exception: You cannot call the AWS STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>To assume a role from a different account, your AWS account must be trusted by the role. The trust relationship is defined in the role's trust policy when the role is created. That trust policy states which accounts are allowed to delegate that access to users in the account. </p> <p>A user who wants to access a role in a different account must also have permissions that are delegated from the user account administrator. The administrator must attach a policy that allows the user to call <code>AssumeRole</code> for the ARN of the role in the other account. If the user is in the same account as the role, then you can do either of the following:</p> <ul> <li> <p>Attach a policy to the user (identical to the previous user in a different account).</p> </li> <li> <p>Add the user as a principal directly in the role's trust policy.</p> </li> </ul> <p>In this case, the trust policy acts as an IAM resource-based policy. Users in the same account as the role do not need explicit permission to assume the role. For more information about trust policies and resource-based policies, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html">IAM Policies</a> in the <i>IAM User Guide</i>.</p> <p> <b>Using MFA with AssumeRole</b> </p> <p>(Optional) You can include multi-factor authentication (MFA) information when you call <code>AssumeRole</code>. This is useful for cross-account scenarios to ensure that the user that assumes the role has been authenticated with an AWS MFA device. In that scenario, the trust policy of the role being assumed includes a condition that tests for MFA authentication. If the caller does not include valid MFA information, the request to assume the role is denied. The condition in a trust policy that tests for MFA authentication might look like the following example.</p> <p> <code>"Condition": {"Bool": {"aws:MultiFactorAuthPresent": true}}</code> </p> <p>For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/MFAProtectedAPI.html">Configuring MFA-Protected API Access</a> in the <i>IAM User Guide</i> guide.</p> <p>To use MFA with <code>AssumeRole</code>, you pass values for the <code>SerialNumber</code> and <code>TokenCode</code> parameters. The <code>SerialNumber</code> value identifies the user's hardware or virtual MFA device. The <code>TokenCode</code> is the time-based one-time password (TOTP) that the MFA device produces. </p>
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
  ##   PolicyArns: JArray
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as managed session policies. The policies must exist in the same account as the role.</p> <p>This parameter is optional. You can provide up to 10 managed policy ARNs. However, the plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note> <p>Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p>
  ##   Action: string (required)
  ##   Policy: string
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>This parameter is optional. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note>
  ##   ExternalId: string
  ##             : <p>A unique identifier that might be required when you assume a role in another account. If the administrator of the account to which the role belongs provided you with an external ID, then provide that value in the <code>ExternalId</code> parameter. This value can be any string, such as a passphrase or account number. A cross-account role is usually set up to trust everyone in an account. Therefore, the administrator of the trusting account might send an external ID to the administrator of the trusted account. That way, only someone with the ID can assume the role, rather than everyone in the account. For more information about the external ID, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user_externalid.html">How to Use an External ID When Granting Access to Your AWS Resources to a Third Party</a> in the <i>IAM User Guide</i>.</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@:/-</p>
  ##   Version: string (required)
  var query_601006 = newJObject()
  add(query_601006, "TokenCode", newJString(TokenCode))
  add(query_601006, "SerialNumber", newJString(SerialNumber))
  add(query_601006, "RoleArn", newJString(RoleArn))
  add(query_601006, "DurationSeconds", newJInt(DurationSeconds))
  add(query_601006, "RoleSessionName", newJString(RoleSessionName))
  if PolicyArns != nil:
    query_601006.add "PolicyArns", PolicyArns
  add(query_601006, "Action", newJString(Action))
  add(query_601006, "Policy", newJString(Policy))
  add(query_601006, "ExternalId", newJString(ExternalId))
  add(query_601006, "Version", newJString(Version))
  result = call_601005.call(nil, query_601006, nil, nil, nil)

var getAssumeRole* = Call_GetAssumeRole_600768(name: "getAssumeRole",
    meth: HttpMethod.HttpGet, host: "sts.amazonaws.com",
    route: "/#Action=AssumeRole", validator: validate_GetAssumeRole_600769,
    base: "/", url: url_GetAssumeRole_600770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAssumeRoleWithSAML_601091 = ref object of OpenApiRestCall_600426
proc url_PostAssumeRoleWithSAML_601093(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAssumeRoleWithSAML_601092(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a set of temporary security credentials for users who have been authenticated via a SAML authentication response. This operation provides a mechanism for tying an enterprise identity store or directory to role-based AWS access without user-specific credentials or configuration. For a comparison of <code>AssumeRoleWithSAML</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials returned by this operation consist of an access key ID, a secret access key, and a security token. Applications can use these temporary security credentials to sign calls to AWS services.</p> <p>By default, the temporary security credentials created by <code>AssumeRoleWithSAML</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. Your role session lasts for the duration that you specify, or until the time specified in the SAML authentication response's <code>SessionNotOnOrAfter</code> value, whichever is shorter. You can provide a <code>DurationSeconds</code> value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials created by <code>AssumeRoleWithSAML</code> can be used to make API calls to any AWS service with the following exception: you cannot call the STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>Before your application can call <code>AssumeRoleWithSAML</code>, you must configure your SAML identity provider (IdP) to issue the claims required by AWS. Additionally, you must use AWS Identity and Access Management (IAM) to create a SAML provider entity in your AWS account that represents your identity provider. You must also create an IAM role that specifies this SAML provider in its trust policy. </p> <p>Calling <code>AssumeRoleWithSAML</code> does not require the use of AWS security credentials. The identity of the caller is validated by using keys in the metadata document that is uploaded for the SAML provider entity for your identity provider. </p> <important> <p>Calling <code>AssumeRoleWithSAML</code> can result in an entry in your AWS CloudTrail logs. The entry includes the value in the <code>NameID</code> element of the SAML assertion. We recommend that you use a <code>NameIDType</code> that is not associated with any personally identifiable information (PII). For example, you could instead use the Persistent Identifier (<code>urn:oasis:names:tc:SAML:2.0:nameid-format:persistent</code>).</p> </important> <p>For more information, see the following resources:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_saml.html">About SAML 2.0-based Federation</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml.html">Creating SAML Identity Providers</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml_relying-party.html">Configuring a Relying Party and Claims</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_saml.html">Creating a Role for SAML 2.0 Federation</a> in the <i>IAM User Guide</i>. </p> </li> </ul>
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
  var valid_601094 = query.getOrDefault("Action")
  valid_601094 = validateParameter(valid_601094, JString, required = true,
                                 default = newJString("AssumeRoleWithSAML"))
  if valid_601094 != nil:
    section.add "Action", valid_601094
  var valid_601095 = query.getOrDefault("Version")
  valid_601095 = validateParameter(valid_601095, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_601095 != nil:
    section.add "Version", valid_601095
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
  var valid_601096 = header.getOrDefault("X-Amz-Date")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-Date", valid_601096
  var valid_601097 = header.getOrDefault("X-Amz-Security-Token")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-Security-Token", valid_601097
  var valid_601098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-Content-Sha256", valid_601098
  var valid_601099 = header.getOrDefault("X-Amz-Algorithm")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "X-Amz-Algorithm", valid_601099
  var valid_601100 = header.getOrDefault("X-Amz-Signature")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Signature", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-SignedHeaders", valid_601101
  var valid_601102 = header.getOrDefault("X-Amz-Credential")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "X-Amz-Credential", valid_601102
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
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as managed session policies. The policies must exist in the same account as the role.</p> <p>This parameter is optional. You can provide up to 10 managed policy ARNs. However, the plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note> <p>Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p>
  ##   Policy: JString
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>This parameter is optional. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>. </p> <p>The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note>
  ##   DurationSeconds: JInt
  ##                  : <p>The duration, in seconds, of the role session. Your role session lasts for the duration that you specify for the <code>DurationSeconds</code> parameter, or until the time specified in the SAML authentication response's <code>SessionNotOnOrAfter</code> value, whichever is shorter. You can provide a <code>DurationSeconds</code> value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. If you specify a value higher than this setting, the operation fails. For example, if you specify a session duration of 12 hours, but your administrator set the maximum session duration to 6 hours, your operation fails. To learn how to view the maximum value for your role, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>.</p> <p>By default, the value is set to <code>3600</code> seconds. </p> <note> <p>The <code>DurationSeconds</code> parameter is separate from the duration of a console session that you might request using the returned credentials. The request to the federation endpoint for a console sign-in token takes a <code>SessionDuration</code> parameter that specifies the maximum length of the console session. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html">Creating a URL that Enables Federated Users to Access the AWS Management Console</a> in the <i>IAM User Guide</i>.</p> </note>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `PrincipalArn` field"
  var valid_601103 = formData.getOrDefault("PrincipalArn")
  valid_601103 = validateParameter(valid_601103, JString, required = true,
                                 default = nil)
  if valid_601103 != nil:
    section.add "PrincipalArn", valid_601103
  var valid_601104 = formData.getOrDefault("RoleArn")
  valid_601104 = validateParameter(valid_601104, JString, required = true,
                                 default = nil)
  if valid_601104 != nil:
    section.add "RoleArn", valid_601104
  var valid_601105 = formData.getOrDefault("SAMLAssertion")
  valid_601105 = validateParameter(valid_601105, JString, required = true,
                                 default = nil)
  if valid_601105 != nil:
    section.add "SAMLAssertion", valid_601105
  var valid_601106 = formData.getOrDefault("PolicyArns")
  valid_601106 = validateParameter(valid_601106, JArray, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "PolicyArns", valid_601106
  var valid_601107 = formData.getOrDefault("Policy")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "Policy", valid_601107
  var valid_601108 = formData.getOrDefault("DurationSeconds")
  valid_601108 = validateParameter(valid_601108, JInt, required = false, default = nil)
  if valid_601108 != nil:
    section.add "DurationSeconds", valid_601108
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601109: Call_PostAssumeRoleWithSAML_601091; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a set of temporary security credentials for users who have been authenticated via a SAML authentication response. This operation provides a mechanism for tying an enterprise identity store or directory to role-based AWS access without user-specific credentials or configuration. For a comparison of <code>AssumeRoleWithSAML</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials returned by this operation consist of an access key ID, a secret access key, and a security token. Applications can use these temporary security credentials to sign calls to AWS services.</p> <p>By default, the temporary security credentials created by <code>AssumeRoleWithSAML</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. Your role session lasts for the duration that you specify, or until the time specified in the SAML authentication response's <code>SessionNotOnOrAfter</code> value, whichever is shorter. You can provide a <code>DurationSeconds</code> value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials created by <code>AssumeRoleWithSAML</code> can be used to make API calls to any AWS service with the following exception: you cannot call the STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>Before your application can call <code>AssumeRoleWithSAML</code>, you must configure your SAML identity provider (IdP) to issue the claims required by AWS. Additionally, you must use AWS Identity and Access Management (IAM) to create a SAML provider entity in your AWS account that represents your identity provider. You must also create an IAM role that specifies this SAML provider in its trust policy. </p> <p>Calling <code>AssumeRoleWithSAML</code> does not require the use of AWS security credentials. The identity of the caller is validated by using keys in the metadata document that is uploaded for the SAML provider entity for your identity provider. </p> <important> <p>Calling <code>AssumeRoleWithSAML</code> can result in an entry in your AWS CloudTrail logs. The entry includes the value in the <code>NameID</code> element of the SAML assertion. We recommend that you use a <code>NameIDType</code> that is not associated with any personally identifiable information (PII). For example, you could instead use the Persistent Identifier (<code>urn:oasis:names:tc:SAML:2.0:nameid-format:persistent</code>).</p> </important> <p>For more information, see the following resources:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_saml.html">About SAML 2.0-based Federation</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml.html">Creating SAML Identity Providers</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml_relying-party.html">Configuring a Relying Party and Claims</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_saml.html">Creating a Role for SAML 2.0 Federation</a> in the <i>IAM User Guide</i>. </p> </li> </ul>
  ## 
  let valid = call_601109.validator(path, query, header, formData, body)
  let scheme = call_601109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601109.url(scheme.get, call_601109.host, call_601109.base,
                         call_601109.route, valid.getOrDefault("path"))
  result = hook(call_601109, url, valid)

proc call*(call_601110: Call_PostAssumeRoleWithSAML_601091; PrincipalArn: string;
          RoleArn: string; SAMLAssertion: string;
          Action: string = "AssumeRoleWithSAML"; PolicyArns: JsonNode = nil;
          Policy: string = ""; Version: string = "2011-06-15"; DurationSeconds: int = 0): Recallable =
  ## postAssumeRoleWithSAML
  ## <p>Returns a set of temporary security credentials for users who have been authenticated via a SAML authentication response. This operation provides a mechanism for tying an enterprise identity store or directory to role-based AWS access without user-specific credentials or configuration. For a comparison of <code>AssumeRoleWithSAML</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials returned by this operation consist of an access key ID, a secret access key, and a security token. Applications can use these temporary security credentials to sign calls to AWS services.</p> <p>By default, the temporary security credentials created by <code>AssumeRoleWithSAML</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. Your role session lasts for the duration that you specify, or until the time specified in the SAML authentication response's <code>SessionNotOnOrAfter</code> value, whichever is shorter. You can provide a <code>DurationSeconds</code> value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials created by <code>AssumeRoleWithSAML</code> can be used to make API calls to any AWS service with the following exception: you cannot call the STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>Before your application can call <code>AssumeRoleWithSAML</code>, you must configure your SAML identity provider (IdP) to issue the claims required by AWS. Additionally, you must use AWS Identity and Access Management (IAM) to create a SAML provider entity in your AWS account that represents your identity provider. You must also create an IAM role that specifies this SAML provider in its trust policy. </p> <p>Calling <code>AssumeRoleWithSAML</code> does not require the use of AWS security credentials. The identity of the caller is validated by using keys in the metadata document that is uploaded for the SAML provider entity for your identity provider. </p> <important> <p>Calling <code>AssumeRoleWithSAML</code> can result in an entry in your AWS CloudTrail logs. The entry includes the value in the <code>NameID</code> element of the SAML assertion. We recommend that you use a <code>NameIDType</code> that is not associated with any personally identifiable information (PII). For example, you could instead use the Persistent Identifier (<code>urn:oasis:names:tc:SAML:2.0:nameid-format:persistent</code>).</p> </important> <p>For more information, see the following resources:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_saml.html">About SAML 2.0-based Federation</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml.html">Creating SAML Identity Providers</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml_relying-party.html">Configuring a Relying Party and Claims</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_saml.html">Creating a Role for SAML 2.0 Federation</a> in the <i>IAM User Guide</i>. </p> </li> </ul>
  ##   PrincipalArn: string (required)
  ##               : The Amazon Resource Name (ARN) of the SAML provider in IAM that describes the IdP.
  ##   RoleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the role that the caller is assuming.
  ##   Action: string (required)
  ##   SAMLAssertion: string (required)
  ##                : <p>The base-64 encoded SAML authentication response provided by the IdP.</p> <p>For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/create-role-saml-IdP-tasks.html">Configuring a Relying Party and Adding Claims</a> in the <i>IAM User Guide</i>. </p>
  ##   PolicyArns: JArray
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as managed session policies. The policies must exist in the same account as the role.</p> <p>This parameter is optional. You can provide up to 10 managed policy ARNs. However, the plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note> <p>Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p>
  ##   Policy: string
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>This parameter is optional. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>. </p> <p>The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note>
  ##   Version: string (required)
  ##   DurationSeconds: int
  ##                  : <p>The duration, in seconds, of the role session. Your role session lasts for the duration that you specify for the <code>DurationSeconds</code> parameter, or until the time specified in the SAML authentication response's <code>SessionNotOnOrAfter</code> value, whichever is shorter. You can provide a <code>DurationSeconds</code> value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. If you specify a value higher than this setting, the operation fails. For example, if you specify a session duration of 12 hours, but your administrator set the maximum session duration to 6 hours, your operation fails. To learn how to view the maximum value for your role, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>.</p> <p>By default, the value is set to <code>3600</code> seconds. </p> <note> <p>The <code>DurationSeconds</code> parameter is separate from the duration of a console session that you might request using the returned credentials. The request to the federation endpoint for a console sign-in token takes a <code>SessionDuration</code> parameter that specifies the maximum length of the console session. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html">Creating a URL that Enables Federated Users to Access the AWS Management Console</a> in the <i>IAM User Guide</i>.</p> </note>
  var query_601111 = newJObject()
  var formData_601112 = newJObject()
  add(formData_601112, "PrincipalArn", newJString(PrincipalArn))
  add(formData_601112, "RoleArn", newJString(RoleArn))
  add(query_601111, "Action", newJString(Action))
  add(formData_601112, "SAMLAssertion", newJString(SAMLAssertion))
  if PolicyArns != nil:
    formData_601112.add "PolicyArns", PolicyArns
  add(formData_601112, "Policy", newJString(Policy))
  add(query_601111, "Version", newJString(Version))
  add(formData_601112, "DurationSeconds", newJInt(DurationSeconds))
  result = call_601110.call(nil, query_601111, nil, formData_601112, nil)

var postAssumeRoleWithSAML* = Call_PostAssumeRoleWithSAML_601091(
    name: "postAssumeRoleWithSAML", meth: HttpMethod.HttpPost,
    host: "sts.amazonaws.com", route: "/#Action=AssumeRoleWithSAML",
    validator: validate_PostAssumeRoleWithSAML_601092, base: "/",
    url: url_PostAssumeRoleWithSAML_601093, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssumeRoleWithSAML_601070 = ref object of OpenApiRestCall_600426
proc url_GetAssumeRoleWithSAML_601072(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAssumeRoleWithSAML_601071(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a set of temporary security credentials for users who have been authenticated via a SAML authentication response. This operation provides a mechanism for tying an enterprise identity store or directory to role-based AWS access without user-specific credentials or configuration. For a comparison of <code>AssumeRoleWithSAML</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials returned by this operation consist of an access key ID, a secret access key, and a security token. Applications can use these temporary security credentials to sign calls to AWS services.</p> <p>By default, the temporary security credentials created by <code>AssumeRoleWithSAML</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. Your role session lasts for the duration that you specify, or until the time specified in the SAML authentication response's <code>SessionNotOnOrAfter</code> value, whichever is shorter. You can provide a <code>DurationSeconds</code> value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials created by <code>AssumeRoleWithSAML</code> can be used to make API calls to any AWS service with the following exception: you cannot call the STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>Before your application can call <code>AssumeRoleWithSAML</code>, you must configure your SAML identity provider (IdP) to issue the claims required by AWS. Additionally, you must use AWS Identity and Access Management (IAM) to create a SAML provider entity in your AWS account that represents your identity provider. You must also create an IAM role that specifies this SAML provider in its trust policy. </p> <p>Calling <code>AssumeRoleWithSAML</code> does not require the use of AWS security credentials. The identity of the caller is validated by using keys in the metadata document that is uploaded for the SAML provider entity for your identity provider. </p> <important> <p>Calling <code>AssumeRoleWithSAML</code> can result in an entry in your AWS CloudTrail logs. The entry includes the value in the <code>NameID</code> element of the SAML assertion. We recommend that you use a <code>NameIDType</code> that is not associated with any personally identifiable information (PII). For example, you could instead use the Persistent Identifier (<code>urn:oasis:names:tc:SAML:2.0:nameid-format:persistent</code>).</p> </important> <p>For more information, see the following resources:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_saml.html">About SAML 2.0-based Federation</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml.html">Creating SAML Identity Providers</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml_relying-party.html">Configuring a Relying Party and Claims</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_saml.html">Creating a Role for SAML 2.0 Federation</a> in the <i>IAM User Guide</i>. </p> </li> </ul>
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
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as managed session policies. The policies must exist in the same account as the role.</p> <p>This parameter is optional. You can provide up to 10 managed policy ARNs. However, the plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note> <p>Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p>
  ##   Action: JString (required)
  ##   PrincipalArn: JString (required)
  ##               : The Amazon Resource Name (ARN) of the SAML provider in IAM that describes the IdP.
  ##   Policy: JString
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>This parameter is optional. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>. </p> <p>The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `RoleArn` field"
  var valid_601073 = query.getOrDefault("RoleArn")
  valid_601073 = validateParameter(valid_601073, JString, required = true,
                                 default = nil)
  if valid_601073 != nil:
    section.add "RoleArn", valid_601073
  var valid_601074 = query.getOrDefault("DurationSeconds")
  valid_601074 = validateParameter(valid_601074, JInt, required = false, default = nil)
  if valid_601074 != nil:
    section.add "DurationSeconds", valid_601074
  var valid_601075 = query.getOrDefault("SAMLAssertion")
  valid_601075 = validateParameter(valid_601075, JString, required = true,
                                 default = nil)
  if valid_601075 != nil:
    section.add "SAMLAssertion", valid_601075
  var valid_601076 = query.getOrDefault("PolicyArns")
  valid_601076 = validateParameter(valid_601076, JArray, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "PolicyArns", valid_601076
  var valid_601077 = query.getOrDefault("Action")
  valid_601077 = validateParameter(valid_601077, JString, required = true,
                                 default = newJString("AssumeRoleWithSAML"))
  if valid_601077 != nil:
    section.add "Action", valid_601077
  var valid_601078 = query.getOrDefault("PrincipalArn")
  valid_601078 = validateParameter(valid_601078, JString, required = true,
                                 default = nil)
  if valid_601078 != nil:
    section.add "PrincipalArn", valid_601078
  var valid_601079 = query.getOrDefault("Policy")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "Policy", valid_601079
  var valid_601080 = query.getOrDefault("Version")
  valid_601080 = validateParameter(valid_601080, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_601080 != nil:
    section.add "Version", valid_601080
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
  var valid_601081 = header.getOrDefault("X-Amz-Date")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-Date", valid_601081
  var valid_601082 = header.getOrDefault("X-Amz-Security-Token")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-Security-Token", valid_601082
  var valid_601083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-Content-Sha256", valid_601083
  var valid_601084 = header.getOrDefault("X-Amz-Algorithm")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-Algorithm", valid_601084
  var valid_601085 = header.getOrDefault("X-Amz-Signature")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Signature", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-SignedHeaders", valid_601086
  var valid_601087 = header.getOrDefault("X-Amz-Credential")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-Credential", valid_601087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601088: Call_GetAssumeRoleWithSAML_601070; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a set of temporary security credentials for users who have been authenticated via a SAML authentication response. This operation provides a mechanism for tying an enterprise identity store or directory to role-based AWS access without user-specific credentials or configuration. For a comparison of <code>AssumeRoleWithSAML</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials returned by this operation consist of an access key ID, a secret access key, and a security token. Applications can use these temporary security credentials to sign calls to AWS services.</p> <p>By default, the temporary security credentials created by <code>AssumeRoleWithSAML</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. Your role session lasts for the duration that you specify, or until the time specified in the SAML authentication response's <code>SessionNotOnOrAfter</code> value, whichever is shorter. You can provide a <code>DurationSeconds</code> value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials created by <code>AssumeRoleWithSAML</code> can be used to make API calls to any AWS service with the following exception: you cannot call the STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>Before your application can call <code>AssumeRoleWithSAML</code>, you must configure your SAML identity provider (IdP) to issue the claims required by AWS. Additionally, you must use AWS Identity and Access Management (IAM) to create a SAML provider entity in your AWS account that represents your identity provider. You must also create an IAM role that specifies this SAML provider in its trust policy. </p> <p>Calling <code>AssumeRoleWithSAML</code> does not require the use of AWS security credentials. The identity of the caller is validated by using keys in the metadata document that is uploaded for the SAML provider entity for your identity provider. </p> <important> <p>Calling <code>AssumeRoleWithSAML</code> can result in an entry in your AWS CloudTrail logs. The entry includes the value in the <code>NameID</code> element of the SAML assertion. We recommend that you use a <code>NameIDType</code> that is not associated with any personally identifiable information (PII). For example, you could instead use the Persistent Identifier (<code>urn:oasis:names:tc:SAML:2.0:nameid-format:persistent</code>).</p> </important> <p>For more information, see the following resources:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_saml.html">About SAML 2.0-based Federation</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml.html">Creating SAML Identity Providers</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml_relying-party.html">Configuring a Relying Party and Claims</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_saml.html">Creating a Role for SAML 2.0 Federation</a> in the <i>IAM User Guide</i>. </p> </li> </ul>
  ## 
  let valid = call_601088.validator(path, query, header, formData, body)
  let scheme = call_601088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601088.url(scheme.get, call_601088.host, call_601088.base,
                         call_601088.route, valid.getOrDefault("path"))
  result = hook(call_601088, url, valid)

proc call*(call_601089: Call_GetAssumeRoleWithSAML_601070; RoleArn: string;
          SAMLAssertion: string; PrincipalArn: string; DurationSeconds: int = 0;
          PolicyArns: JsonNode = nil; Action: string = "AssumeRoleWithSAML";
          Policy: string = ""; Version: string = "2011-06-15"): Recallable =
  ## getAssumeRoleWithSAML
  ## <p>Returns a set of temporary security credentials for users who have been authenticated via a SAML authentication response. This operation provides a mechanism for tying an enterprise identity store or directory to role-based AWS access without user-specific credentials or configuration. For a comparison of <code>AssumeRoleWithSAML</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials returned by this operation consist of an access key ID, a secret access key, and a security token. Applications can use these temporary security credentials to sign calls to AWS services.</p> <p>By default, the temporary security credentials created by <code>AssumeRoleWithSAML</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. Your role session lasts for the duration that you specify, or until the time specified in the SAML authentication response's <code>SessionNotOnOrAfter</code> value, whichever is shorter. You can provide a <code>DurationSeconds</code> value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials created by <code>AssumeRoleWithSAML</code> can be used to make API calls to any AWS service with the following exception: you cannot call the STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>Before your application can call <code>AssumeRoleWithSAML</code>, you must configure your SAML identity provider (IdP) to issue the claims required by AWS. Additionally, you must use AWS Identity and Access Management (IAM) to create a SAML provider entity in your AWS account that represents your identity provider. You must also create an IAM role that specifies this SAML provider in its trust policy. </p> <p>Calling <code>AssumeRoleWithSAML</code> does not require the use of AWS security credentials. The identity of the caller is validated by using keys in the metadata document that is uploaded for the SAML provider entity for your identity provider. </p> <important> <p>Calling <code>AssumeRoleWithSAML</code> can result in an entry in your AWS CloudTrail logs. The entry includes the value in the <code>NameID</code> element of the SAML assertion. We recommend that you use a <code>NameIDType</code> that is not associated with any personally identifiable information (PII). For example, you could instead use the Persistent Identifier (<code>urn:oasis:names:tc:SAML:2.0:nameid-format:persistent</code>).</p> </important> <p>For more information, see the following resources:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_saml.html">About SAML 2.0-based Federation</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml.html">Creating SAML Identity Providers</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml_relying-party.html">Configuring a Relying Party and Claims</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_saml.html">Creating a Role for SAML 2.0 Federation</a> in the <i>IAM User Guide</i>. </p> </li> </ul>
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
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as managed session policies. The policies must exist in the same account as the role.</p> <p>This parameter is optional. You can provide up to 10 managed policy ARNs. However, the plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note> <p>Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p>
  ##   Action: string (required)
  ##   PrincipalArn: string (required)
  ##               : The Amazon Resource Name (ARN) of the SAML provider in IAM that describes the IdP.
  ##   Policy: string
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>This parameter is optional. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>. </p> <p>The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note>
  ##   Version: string (required)
  var query_601090 = newJObject()
  add(query_601090, "RoleArn", newJString(RoleArn))
  add(query_601090, "DurationSeconds", newJInt(DurationSeconds))
  add(query_601090, "SAMLAssertion", newJString(SAMLAssertion))
  if PolicyArns != nil:
    query_601090.add "PolicyArns", PolicyArns
  add(query_601090, "Action", newJString(Action))
  add(query_601090, "PrincipalArn", newJString(PrincipalArn))
  add(query_601090, "Policy", newJString(Policy))
  add(query_601090, "Version", newJString(Version))
  result = call_601089.call(nil, query_601090, nil, nil, nil)

var getAssumeRoleWithSAML* = Call_GetAssumeRoleWithSAML_601070(
    name: "getAssumeRoleWithSAML", meth: HttpMethod.HttpGet,
    host: "sts.amazonaws.com", route: "/#Action=AssumeRoleWithSAML",
    validator: validate_GetAssumeRoleWithSAML_601071, base: "/",
    url: url_GetAssumeRoleWithSAML_601072, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAssumeRoleWithWebIdentity_601135 = ref object of OpenApiRestCall_600426
proc url_PostAssumeRoleWithWebIdentity_601137(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAssumeRoleWithWebIdentity_601136(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a set of temporary security credentials for users who have been authenticated in a mobile or web application with a web identity provider. Example providers include Amazon Cognito, Login with Amazon, Facebook, Google, or any OpenID Connect-compatible identity provider.</p> <note> <p>For mobile applications, we recommend that you use Amazon Cognito. You can use Amazon Cognito with the <a href="http://aws.amazon.com/sdkforios/">AWS SDK for iOS Developer Guide</a> and the <a href="http://aws.amazon.com/sdkforandroid/">AWS SDK for Android Developer Guide</a> to uniquely identify a user. You can also supply the user with a consistent identity throughout the lifetime of an application.</p> <p>To learn more about Amazon Cognito, see <a href="https://docs.aws.amazon.com/mobile/sdkforandroid/developerguide/cognito-auth.html#d0e840">Amazon Cognito Overview</a> in <i>AWS SDK for Android Developer Guide</i> and <a href="https://docs.aws.amazon.com/mobile/sdkforios/developerguide/cognito-auth.html#d0e664">Amazon Cognito Overview</a> in the <i>AWS SDK for iOS Developer Guide</i>.</p> </note> <p>Calling <code>AssumeRoleWithWebIdentity</code> does not require the use of AWS security credentials. Therefore, you can distribute an application (for example, on mobile devices) that requests temporary security credentials without including long-term AWS credentials in the application. You also don't need to deploy server-based proxy services that use long-term AWS credentials. Instead, the identity of the caller is validated by using a token from the web identity provider. For a comparison of <code>AssumeRoleWithWebIdentity</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials returned by this API consist of an access key ID, a secret access key, and a security token. Applications can use these temporary security credentials to sign calls to AWS service API operations.</p> <p>By default, the temporary security credentials created by <code>AssumeRoleWithWebIdentity</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. You can provide a value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>. </p> <p>The temporary security credentials created by <code>AssumeRoleWithWebIdentity</code> can be used to make API calls to any AWS service with the following exception: you cannot call the STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>Before your application can call <code>AssumeRoleWithWebIdentity</code>, you must have an identity token from a supported identity provider and create a role that the application can assume. The role that your application assumes must trust the identity provider that is associated with the identity token. In other words, the identity provider must be specified in the role's trust policy. </p> <important> <p>Calling <code>AssumeRoleWithWebIdentity</code> can result in an entry in your AWS CloudTrail logs. The entry includes the <a href="http://openid.net/specs/openid-connect-core-1_0.html#Claims">Subject</a> of the provided Web Identity Token. We recommend that you avoid using any personally identifiable information (PII) in this field. For example, you could instead use a GUID or a pairwise identifier, as <a href="http://openid.net/specs/openid-connect-core-1_0.html#SubjectIDTypes">suggested in the OIDC specification</a>.</p> </important> <p>For more information about how to use web identity federation and the <code>AssumeRoleWithWebIdentity</code> API, see the following resources: </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_oidc_manual.html">Using Web Identity Federation API Operations for Mobile Apps</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity">Federation Through a Web-based Identity Provider</a>. </p> </li> <li> <p> <a href="https://web-identity-federation-playground.s3.amazonaws.com/index.html"> Web Identity Federation Playground</a>. Walk through the process of authenticating through Login with Amazon, Facebook, or Google, getting temporary security credentials, and then using those credentials to make a request to AWS. </p> </li> <li> <p> <a href="http://aws.amazon.com/sdkforios/">AWS SDK for iOS Developer Guide</a> and <a href="http://aws.amazon.com/sdkforandroid/">AWS SDK for Android Developer Guide</a>. These toolkits contain sample apps that show how to invoke the identity providers, and then how to use the information from these providers to get and use temporary security credentials. </p> </li> <li> <p> <a href="http://aws.amazon.com/articles/web-identity-federation-with-mobile-applications">Web Identity Federation with Mobile Applications</a>. This article discusses web identity federation and shows an example of how to use web identity federation to get access to content in Amazon S3. </p> </li> </ul>
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
  var valid_601138 = query.getOrDefault("Action")
  valid_601138 = validateParameter(valid_601138, JString, required = true, default = newJString(
      "AssumeRoleWithWebIdentity"))
  if valid_601138 != nil:
    section.add "Action", valid_601138
  var valid_601139 = query.getOrDefault("Version")
  valid_601139 = validateParameter(valid_601139, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_601139 != nil:
    section.add "Version", valid_601139
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
  var valid_601140 = header.getOrDefault("X-Amz-Date")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-Date", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-Security-Token")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-Security-Token", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-Content-Sha256", valid_601142
  var valid_601143 = header.getOrDefault("X-Amz-Algorithm")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-Algorithm", valid_601143
  var valid_601144 = header.getOrDefault("X-Amz-Signature")
  valid_601144 = validateParameter(valid_601144, JString, required = false,
                                 default = nil)
  if valid_601144 != nil:
    section.add "X-Amz-Signature", valid_601144
  var valid_601145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-SignedHeaders", valid_601145
  var valid_601146 = header.getOrDefault("X-Amz-Credential")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Credential", valid_601146
  result.add "header", section
  ## parameters in `formData` object:
  ##   ProviderId: JString
  ##             : <p>The fully qualified host component of the domain name of the identity provider.</p> <p>Specify this value only for OAuth 2.0 access tokens. Currently <code>www.amazon.com</code> and <code>graph.facebook.com</code> are the only supported identity providers for OAuth 2.0 access tokens. Do not include URL schemes and port numbers.</p> <p>Do not specify this value for OpenID Connect ID tokens.</p>
  ##   RoleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the role that the caller is assuming.
  ##   PolicyArns: JArray
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as managed session policies. The policies must exist in the same account as the role.</p> <p>This parameter is optional. You can provide up to 10 managed policy ARNs. However, the plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note> <p>Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p>
  ##   WebIdentityToken: JString (required)
  ##                   : The OAuth 2.0 access token or OpenID Connect ID token that is provided by the identity provider. Your application must get this token by authenticating the user who is using your application with a web identity provider before the application makes an <code>AssumeRoleWithWebIdentity</code> call. 
  ##   RoleSessionName: JString (required)
  ##                  : <p>An identifier for the assumed role session. Typically, you pass the name or identifier that is associated with the user who is using your application. That way, the temporary security credentials that your application will use are associated with that user. This session name is included as part of the ARN and assumed role ID in the <code>AssumedRoleUser</code> response element.</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-</p>
  ##   Policy: JString
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>This parameter is optional. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note>
  ##   DurationSeconds: JInt
  ##                  : <p>The duration, in seconds, of the role session. The value can range from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. If you specify a value higher than this setting, the operation fails. For example, if you specify a session duration of 12 hours, but your administrator set the maximum session duration to 6 hours, your operation fails. To learn how to view the maximum value for your role, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>.</p> <p>By default, the value is set to <code>3600</code> seconds. </p> <note> <p>The <code>DurationSeconds</code> parameter is separate from the duration of a console session that you might request using the returned credentials. The request to the federation endpoint for a console sign-in token takes a <code>SessionDuration</code> parameter that specifies the maximum length of the console session. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html">Creating a URL that Enables Federated Users to Access the AWS Management Console</a> in the <i>IAM User Guide</i>.</p> </note>
  section = newJObject()
  var valid_601147 = formData.getOrDefault("ProviderId")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "ProviderId", valid_601147
  assert formData != nil,
        "formData argument is necessary due to required `RoleArn` field"
  var valid_601148 = formData.getOrDefault("RoleArn")
  valid_601148 = validateParameter(valid_601148, JString, required = true,
                                 default = nil)
  if valid_601148 != nil:
    section.add "RoleArn", valid_601148
  var valid_601149 = formData.getOrDefault("PolicyArns")
  valid_601149 = validateParameter(valid_601149, JArray, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "PolicyArns", valid_601149
  var valid_601150 = formData.getOrDefault("WebIdentityToken")
  valid_601150 = validateParameter(valid_601150, JString, required = true,
                                 default = nil)
  if valid_601150 != nil:
    section.add "WebIdentityToken", valid_601150
  var valid_601151 = formData.getOrDefault("RoleSessionName")
  valid_601151 = validateParameter(valid_601151, JString, required = true,
                                 default = nil)
  if valid_601151 != nil:
    section.add "RoleSessionName", valid_601151
  var valid_601152 = formData.getOrDefault("Policy")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "Policy", valid_601152
  var valid_601153 = formData.getOrDefault("DurationSeconds")
  valid_601153 = validateParameter(valid_601153, JInt, required = false, default = nil)
  if valid_601153 != nil:
    section.add "DurationSeconds", valid_601153
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601154: Call_PostAssumeRoleWithWebIdentity_601135; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a set of temporary security credentials for users who have been authenticated in a mobile or web application with a web identity provider. Example providers include Amazon Cognito, Login with Amazon, Facebook, Google, or any OpenID Connect-compatible identity provider.</p> <note> <p>For mobile applications, we recommend that you use Amazon Cognito. You can use Amazon Cognito with the <a href="http://aws.amazon.com/sdkforios/">AWS SDK for iOS Developer Guide</a> and the <a href="http://aws.amazon.com/sdkforandroid/">AWS SDK for Android Developer Guide</a> to uniquely identify a user. You can also supply the user with a consistent identity throughout the lifetime of an application.</p> <p>To learn more about Amazon Cognito, see <a href="https://docs.aws.amazon.com/mobile/sdkforandroid/developerguide/cognito-auth.html#d0e840">Amazon Cognito Overview</a> in <i>AWS SDK for Android Developer Guide</i> and <a href="https://docs.aws.amazon.com/mobile/sdkforios/developerguide/cognito-auth.html#d0e664">Amazon Cognito Overview</a> in the <i>AWS SDK for iOS Developer Guide</i>.</p> </note> <p>Calling <code>AssumeRoleWithWebIdentity</code> does not require the use of AWS security credentials. Therefore, you can distribute an application (for example, on mobile devices) that requests temporary security credentials without including long-term AWS credentials in the application. You also don't need to deploy server-based proxy services that use long-term AWS credentials. Instead, the identity of the caller is validated by using a token from the web identity provider. For a comparison of <code>AssumeRoleWithWebIdentity</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials returned by this API consist of an access key ID, a secret access key, and a security token. Applications can use these temporary security credentials to sign calls to AWS service API operations.</p> <p>By default, the temporary security credentials created by <code>AssumeRoleWithWebIdentity</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. You can provide a value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>. </p> <p>The temporary security credentials created by <code>AssumeRoleWithWebIdentity</code> can be used to make API calls to any AWS service with the following exception: you cannot call the STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>Before your application can call <code>AssumeRoleWithWebIdentity</code>, you must have an identity token from a supported identity provider and create a role that the application can assume. The role that your application assumes must trust the identity provider that is associated with the identity token. In other words, the identity provider must be specified in the role's trust policy. </p> <important> <p>Calling <code>AssumeRoleWithWebIdentity</code> can result in an entry in your AWS CloudTrail logs. The entry includes the <a href="http://openid.net/specs/openid-connect-core-1_0.html#Claims">Subject</a> of the provided Web Identity Token. We recommend that you avoid using any personally identifiable information (PII) in this field. For example, you could instead use a GUID or a pairwise identifier, as <a href="http://openid.net/specs/openid-connect-core-1_0.html#SubjectIDTypes">suggested in the OIDC specification</a>.</p> </important> <p>For more information about how to use web identity federation and the <code>AssumeRoleWithWebIdentity</code> API, see the following resources: </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_oidc_manual.html">Using Web Identity Federation API Operations for Mobile Apps</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity">Federation Through a Web-based Identity Provider</a>. </p> </li> <li> <p> <a href="https://web-identity-federation-playground.s3.amazonaws.com/index.html"> Web Identity Federation Playground</a>. Walk through the process of authenticating through Login with Amazon, Facebook, or Google, getting temporary security credentials, and then using those credentials to make a request to AWS. </p> </li> <li> <p> <a href="http://aws.amazon.com/sdkforios/">AWS SDK for iOS Developer Guide</a> and <a href="http://aws.amazon.com/sdkforandroid/">AWS SDK for Android Developer Guide</a>. These toolkits contain sample apps that show how to invoke the identity providers, and then how to use the information from these providers to get and use temporary security credentials. </p> </li> <li> <p> <a href="http://aws.amazon.com/articles/web-identity-federation-with-mobile-applications">Web Identity Federation with Mobile Applications</a>. This article discusses web identity federation and shows an example of how to use web identity federation to get access to content in Amazon S3. </p> </li> </ul>
  ## 
  let valid = call_601154.validator(path, query, header, formData, body)
  let scheme = call_601154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601154.url(scheme.get, call_601154.host, call_601154.base,
                         call_601154.route, valid.getOrDefault("path"))
  result = hook(call_601154, url, valid)

proc call*(call_601155: Call_PostAssumeRoleWithWebIdentity_601135; RoleArn: string;
          WebIdentityToken: string; RoleSessionName: string;
          ProviderId: string = ""; Action: string = "AssumeRoleWithWebIdentity";
          PolicyArns: JsonNode = nil; Policy: string = "";
          Version: string = "2011-06-15"; DurationSeconds: int = 0): Recallable =
  ## postAssumeRoleWithWebIdentity
  ## <p>Returns a set of temporary security credentials for users who have been authenticated in a mobile or web application with a web identity provider. Example providers include Amazon Cognito, Login with Amazon, Facebook, Google, or any OpenID Connect-compatible identity provider.</p> <note> <p>For mobile applications, we recommend that you use Amazon Cognito. You can use Amazon Cognito with the <a href="http://aws.amazon.com/sdkforios/">AWS SDK for iOS Developer Guide</a> and the <a href="http://aws.amazon.com/sdkforandroid/">AWS SDK for Android Developer Guide</a> to uniquely identify a user. You can also supply the user with a consistent identity throughout the lifetime of an application.</p> <p>To learn more about Amazon Cognito, see <a href="https://docs.aws.amazon.com/mobile/sdkforandroid/developerguide/cognito-auth.html#d0e840">Amazon Cognito Overview</a> in <i>AWS SDK for Android Developer Guide</i> and <a href="https://docs.aws.amazon.com/mobile/sdkforios/developerguide/cognito-auth.html#d0e664">Amazon Cognito Overview</a> in the <i>AWS SDK for iOS Developer Guide</i>.</p> </note> <p>Calling <code>AssumeRoleWithWebIdentity</code> does not require the use of AWS security credentials. Therefore, you can distribute an application (for example, on mobile devices) that requests temporary security credentials without including long-term AWS credentials in the application. You also don't need to deploy server-based proxy services that use long-term AWS credentials. Instead, the identity of the caller is validated by using a token from the web identity provider. For a comparison of <code>AssumeRoleWithWebIdentity</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials returned by this API consist of an access key ID, a secret access key, and a security token. Applications can use these temporary security credentials to sign calls to AWS service API operations.</p> <p>By default, the temporary security credentials created by <code>AssumeRoleWithWebIdentity</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. You can provide a value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>. </p> <p>The temporary security credentials created by <code>AssumeRoleWithWebIdentity</code> can be used to make API calls to any AWS service with the following exception: you cannot call the STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>Before your application can call <code>AssumeRoleWithWebIdentity</code>, you must have an identity token from a supported identity provider and create a role that the application can assume. The role that your application assumes must trust the identity provider that is associated with the identity token. In other words, the identity provider must be specified in the role's trust policy. </p> <important> <p>Calling <code>AssumeRoleWithWebIdentity</code> can result in an entry in your AWS CloudTrail logs. The entry includes the <a href="http://openid.net/specs/openid-connect-core-1_0.html#Claims">Subject</a> of the provided Web Identity Token. We recommend that you avoid using any personally identifiable information (PII) in this field. For example, you could instead use a GUID or a pairwise identifier, as <a href="http://openid.net/specs/openid-connect-core-1_0.html#SubjectIDTypes">suggested in the OIDC specification</a>.</p> </important> <p>For more information about how to use web identity federation and the <code>AssumeRoleWithWebIdentity</code> API, see the following resources: </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_oidc_manual.html">Using Web Identity Federation API Operations for Mobile Apps</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity">Federation Through a Web-based Identity Provider</a>. </p> </li> <li> <p> <a href="https://web-identity-federation-playground.s3.amazonaws.com/index.html"> Web Identity Federation Playground</a>. Walk through the process of authenticating through Login with Amazon, Facebook, or Google, getting temporary security credentials, and then using those credentials to make a request to AWS. </p> </li> <li> <p> <a href="http://aws.amazon.com/sdkforios/">AWS SDK for iOS Developer Guide</a> and <a href="http://aws.amazon.com/sdkforandroid/">AWS SDK for Android Developer Guide</a>. These toolkits contain sample apps that show how to invoke the identity providers, and then how to use the information from these providers to get and use temporary security credentials. </p> </li> <li> <p> <a href="http://aws.amazon.com/articles/web-identity-federation-with-mobile-applications">Web Identity Federation with Mobile Applications</a>. This article discusses web identity federation and shows an example of how to use web identity federation to get access to content in Amazon S3. </p> </li> </ul>
  ##   ProviderId: string
  ##             : <p>The fully qualified host component of the domain name of the identity provider.</p> <p>Specify this value only for OAuth 2.0 access tokens. Currently <code>www.amazon.com</code> and <code>graph.facebook.com</code> are the only supported identity providers for OAuth 2.0 access tokens. Do not include URL schemes and port numbers.</p> <p>Do not specify this value for OpenID Connect ID tokens.</p>
  ##   RoleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the role that the caller is assuming.
  ##   Action: string (required)
  ##   PolicyArns: JArray
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as managed session policies. The policies must exist in the same account as the role.</p> <p>This parameter is optional. You can provide up to 10 managed policy ARNs. However, the plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note> <p>Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p>
  ##   WebIdentityToken: string (required)
  ##                   : The OAuth 2.0 access token or OpenID Connect ID token that is provided by the identity provider. Your application must get this token by authenticating the user who is using your application with a web identity provider before the application makes an <code>AssumeRoleWithWebIdentity</code> call. 
  ##   RoleSessionName: string (required)
  ##                  : <p>An identifier for the assumed role session. Typically, you pass the name or identifier that is associated with the user who is using your application. That way, the temporary security credentials that your application will use are associated with that user. This session name is included as part of the ARN and assumed role ID in the <code>AssumedRoleUser</code> response element.</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-</p>
  ##   Policy: string
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>This parameter is optional. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note>
  ##   Version: string (required)
  ##   DurationSeconds: int
  ##                  : <p>The duration, in seconds, of the role session. The value can range from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. If you specify a value higher than this setting, the operation fails. For example, if you specify a session duration of 12 hours, but your administrator set the maximum session duration to 6 hours, your operation fails. To learn how to view the maximum value for your role, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>.</p> <p>By default, the value is set to <code>3600</code> seconds. </p> <note> <p>The <code>DurationSeconds</code> parameter is separate from the duration of a console session that you might request using the returned credentials. The request to the federation endpoint for a console sign-in token takes a <code>SessionDuration</code> parameter that specifies the maximum length of the console session. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html">Creating a URL that Enables Federated Users to Access the AWS Management Console</a> in the <i>IAM User Guide</i>.</p> </note>
  var query_601156 = newJObject()
  var formData_601157 = newJObject()
  add(formData_601157, "ProviderId", newJString(ProviderId))
  add(formData_601157, "RoleArn", newJString(RoleArn))
  add(query_601156, "Action", newJString(Action))
  if PolicyArns != nil:
    formData_601157.add "PolicyArns", PolicyArns
  add(formData_601157, "WebIdentityToken", newJString(WebIdentityToken))
  add(formData_601157, "RoleSessionName", newJString(RoleSessionName))
  add(formData_601157, "Policy", newJString(Policy))
  add(query_601156, "Version", newJString(Version))
  add(formData_601157, "DurationSeconds", newJInt(DurationSeconds))
  result = call_601155.call(nil, query_601156, nil, formData_601157, nil)

var postAssumeRoleWithWebIdentity* = Call_PostAssumeRoleWithWebIdentity_601135(
    name: "postAssumeRoleWithWebIdentity", meth: HttpMethod.HttpPost,
    host: "sts.amazonaws.com", route: "/#Action=AssumeRoleWithWebIdentity",
    validator: validate_PostAssumeRoleWithWebIdentity_601136, base: "/",
    url: url_PostAssumeRoleWithWebIdentity_601137,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssumeRoleWithWebIdentity_601113 = ref object of OpenApiRestCall_600426
proc url_GetAssumeRoleWithWebIdentity_601115(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAssumeRoleWithWebIdentity_601114(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a set of temporary security credentials for users who have been authenticated in a mobile or web application with a web identity provider. Example providers include Amazon Cognito, Login with Amazon, Facebook, Google, or any OpenID Connect-compatible identity provider.</p> <note> <p>For mobile applications, we recommend that you use Amazon Cognito. You can use Amazon Cognito with the <a href="http://aws.amazon.com/sdkforios/">AWS SDK for iOS Developer Guide</a> and the <a href="http://aws.amazon.com/sdkforandroid/">AWS SDK for Android Developer Guide</a> to uniquely identify a user. You can also supply the user with a consistent identity throughout the lifetime of an application.</p> <p>To learn more about Amazon Cognito, see <a href="https://docs.aws.amazon.com/mobile/sdkforandroid/developerguide/cognito-auth.html#d0e840">Amazon Cognito Overview</a> in <i>AWS SDK for Android Developer Guide</i> and <a href="https://docs.aws.amazon.com/mobile/sdkforios/developerguide/cognito-auth.html#d0e664">Amazon Cognito Overview</a> in the <i>AWS SDK for iOS Developer Guide</i>.</p> </note> <p>Calling <code>AssumeRoleWithWebIdentity</code> does not require the use of AWS security credentials. Therefore, you can distribute an application (for example, on mobile devices) that requests temporary security credentials without including long-term AWS credentials in the application. You also don't need to deploy server-based proxy services that use long-term AWS credentials. Instead, the identity of the caller is validated by using a token from the web identity provider. For a comparison of <code>AssumeRoleWithWebIdentity</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials returned by this API consist of an access key ID, a secret access key, and a security token. Applications can use these temporary security credentials to sign calls to AWS service API operations.</p> <p>By default, the temporary security credentials created by <code>AssumeRoleWithWebIdentity</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. You can provide a value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>. </p> <p>The temporary security credentials created by <code>AssumeRoleWithWebIdentity</code> can be used to make API calls to any AWS service with the following exception: you cannot call the STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>Before your application can call <code>AssumeRoleWithWebIdentity</code>, you must have an identity token from a supported identity provider and create a role that the application can assume. The role that your application assumes must trust the identity provider that is associated with the identity token. In other words, the identity provider must be specified in the role's trust policy. </p> <important> <p>Calling <code>AssumeRoleWithWebIdentity</code> can result in an entry in your AWS CloudTrail logs. The entry includes the <a href="http://openid.net/specs/openid-connect-core-1_0.html#Claims">Subject</a> of the provided Web Identity Token. We recommend that you avoid using any personally identifiable information (PII) in this field. For example, you could instead use a GUID or a pairwise identifier, as <a href="http://openid.net/specs/openid-connect-core-1_0.html#SubjectIDTypes">suggested in the OIDC specification</a>.</p> </important> <p>For more information about how to use web identity federation and the <code>AssumeRoleWithWebIdentity</code> API, see the following resources: </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_oidc_manual.html">Using Web Identity Federation API Operations for Mobile Apps</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity">Federation Through a Web-based Identity Provider</a>. </p> </li> <li> <p> <a href="https://web-identity-federation-playground.s3.amazonaws.com/index.html"> Web Identity Federation Playground</a>. Walk through the process of authenticating through Login with Amazon, Facebook, or Google, getting temporary security credentials, and then using those credentials to make a request to AWS. </p> </li> <li> <p> <a href="http://aws.amazon.com/sdkforios/">AWS SDK for iOS Developer Guide</a> and <a href="http://aws.amazon.com/sdkforandroid/">AWS SDK for Android Developer Guide</a>. These toolkits contain sample apps that show how to invoke the identity providers, and then how to use the information from these providers to get and use temporary security credentials. </p> </li> <li> <p> <a href="http://aws.amazon.com/articles/web-identity-federation-with-mobile-applications">Web Identity Federation with Mobile Applications</a>. This article discusses web identity federation and shows an example of how to use web identity federation to get access to content in Amazon S3. </p> </li> </ul>
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
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as managed session policies. The policies must exist in the same account as the role.</p> <p>This parameter is optional. You can provide up to 10 managed policy ARNs. However, the plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note> <p>Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p>
  ##   Action: JString (required)
  ##   Policy: JString
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>This parameter is optional. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note>
  ##   WebIdentityToken: JString (required)
  ##                   : The OAuth 2.0 access token or OpenID Connect ID token that is provided by the identity provider. Your application must get this token by authenticating the user who is using your application with a web identity provider before the application makes an <code>AssumeRoleWithWebIdentity</code> call. 
  ##   Version: JString (required)
  section = newJObject()
  var valid_601116 = query.getOrDefault("ProviderId")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "ProviderId", valid_601116
  assert query != nil, "query argument is necessary due to required `RoleArn` field"
  var valid_601117 = query.getOrDefault("RoleArn")
  valid_601117 = validateParameter(valid_601117, JString, required = true,
                                 default = nil)
  if valid_601117 != nil:
    section.add "RoleArn", valid_601117
  var valid_601118 = query.getOrDefault("DurationSeconds")
  valid_601118 = validateParameter(valid_601118, JInt, required = false, default = nil)
  if valid_601118 != nil:
    section.add "DurationSeconds", valid_601118
  var valid_601119 = query.getOrDefault("RoleSessionName")
  valid_601119 = validateParameter(valid_601119, JString, required = true,
                                 default = nil)
  if valid_601119 != nil:
    section.add "RoleSessionName", valid_601119
  var valid_601120 = query.getOrDefault("PolicyArns")
  valid_601120 = validateParameter(valid_601120, JArray, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "PolicyArns", valid_601120
  var valid_601121 = query.getOrDefault("Action")
  valid_601121 = validateParameter(valid_601121, JString, required = true, default = newJString(
      "AssumeRoleWithWebIdentity"))
  if valid_601121 != nil:
    section.add "Action", valid_601121
  var valid_601122 = query.getOrDefault("Policy")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "Policy", valid_601122
  var valid_601123 = query.getOrDefault("WebIdentityToken")
  valid_601123 = validateParameter(valid_601123, JString, required = true,
                                 default = nil)
  if valid_601123 != nil:
    section.add "WebIdentityToken", valid_601123
  var valid_601124 = query.getOrDefault("Version")
  valid_601124 = validateParameter(valid_601124, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_601124 != nil:
    section.add "Version", valid_601124
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
  var valid_601125 = header.getOrDefault("X-Amz-Date")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Date", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-Security-Token")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Security-Token", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-Content-Sha256", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-Algorithm")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-Algorithm", valid_601128
  var valid_601129 = header.getOrDefault("X-Amz-Signature")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-Signature", valid_601129
  var valid_601130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-SignedHeaders", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Credential")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Credential", valid_601131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601132: Call_GetAssumeRoleWithWebIdentity_601113; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a set of temporary security credentials for users who have been authenticated in a mobile or web application with a web identity provider. Example providers include Amazon Cognito, Login with Amazon, Facebook, Google, or any OpenID Connect-compatible identity provider.</p> <note> <p>For mobile applications, we recommend that you use Amazon Cognito. You can use Amazon Cognito with the <a href="http://aws.amazon.com/sdkforios/">AWS SDK for iOS Developer Guide</a> and the <a href="http://aws.amazon.com/sdkforandroid/">AWS SDK for Android Developer Guide</a> to uniquely identify a user. You can also supply the user with a consistent identity throughout the lifetime of an application.</p> <p>To learn more about Amazon Cognito, see <a href="https://docs.aws.amazon.com/mobile/sdkforandroid/developerguide/cognito-auth.html#d0e840">Amazon Cognito Overview</a> in <i>AWS SDK for Android Developer Guide</i> and <a href="https://docs.aws.amazon.com/mobile/sdkforios/developerguide/cognito-auth.html#d0e664">Amazon Cognito Overview</a> in the <i>AWS SDK for iOS Developer Guide</i>.</p> </note> <p>Calling <code>AssumeRoleWithWebIdentity</code> does not require the use of AWS security credentials. Therefore, you can distribute an application (for example, on mobile devices) that requests temporary security credentials without including long-term AWS credentials in the application. You also don't need to deploy server-based proxy services that use long-term AWS credentials. Instead, the identity of the caller is validated by using a token from the web identity provider. For a comparison of <code>AssumeRoleWithWebIdentity</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials returned by this API consist of an access key ID, a secret access key, and a security token. Applications can use these temporary security credentials to sign calls to AWS service API operations.</p> <p>By default, the temporary security credentials created by <code>AssumeRoleWithWebIdentity</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. You can provide a value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>. </p> <p>The temporary security credentials created by <code>AssumeRoleWithWebIdentity</code> can be used to make API calls to any AWS service with the following exception: you cannot call the STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>Before your application can call <code>AssumeRoleWithWebIdentity</code>, you must have an identity token from a supported identity provider and create a role that the application can assume. The role that your application assumes must trust the identity provider that is associated with the identity token. In other words, the identity provider must be specified in the role's trust policy. </p> <important> <p>Calling <code>AssumeRoleWithWebIdentity</code> can result in an entry in your AWS CloudTrail logs. The entry includes the <a href="http://openid.net/specs/openid-connect-core-1_0.html#Claims">Subject</a> of the provided Web Identity Token. We recommend that you avoid using any personally identifiable information (PII) in this field. For example, you could instead use a GUID or a pairwise identifier, as <a href="http://openid.net/specs/openid-connect-core-1_0.html#SubjectIDTypes">suggested in the OIDC specification</a>.</p> </important> <p>For more information about how to use web identity federation and the <code>AssumeRoleWithWebIdentity</code> API, see the following resources: </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_oidc_manual.html">Using Web Identity Federation API Operations for Mobile Apps</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity">Federation Through a Web-based Identity Provider</a>. </p> </li> <li> <p> <a href="https://web-identity-federation-playground.s3.amazonaws.com/index.html"> Web Identity Federation Playground</a>. Walk through the process of authenticating through Login with Amazon, Facebook, or Google, getting temporary security credentials, and then using those credentials to make a request to AWS. </p> </li> <li> <p> <a href="http://aws.amazon.com/sdkforios/">AWS SDK for iOS Developer Guide</a> and <a href="http://aws.amazon.com/sdkforandroid/">AWS SDK for Android Developer Guide</a>. These toolkits contain sample apps that show how to invoke the identity providers, and then how to use the information from these providers to get and use temporary security credentials. </p> </li> <li> <p> <a href="http://aws.amazon.com/articles/web-identity-federation-with-mobile-applications">Web Identity Federation with Mobile Applications</a>. This article discusses web identity federation and shows an example of how to use web identity federation to get access to content in Amazon S3. </p> </li> </ul>
  ## 
  let valid = call_601132.validator(path, query, header, formData, body)
  let scheme = call_601132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601132.url(scheme.get, call_601132.host, call_601132.base,
                         call_601132.route, valid.getOrDefault("path"))
  result = hook(call_601132, url, valid)

proc call*(call_601133: Call_GetAssumeRoleWithWebIdentity_601113; RoleArn: string;
          RoleSessionName: string; WebIdentityToken: string;
          ProviderId: string = ""; DurationSeconds: int = 0; PolicyArns: JsonNode = nil;
          Action: string = "AssumeRoleWithWebIdentity"; Policy: string = "";
          Version: string = "2011-06-15"): Recallable =
  ## getAssumeRoleWithWebIdentity
  ## <p>Returns a set of temporary security credentials for users who have been authenticated in a mobile or web application with a web identity provider. Example providers include Amazon Cognito, Login with Amazon, Facebook, Google, or any OpenID Connect-compatible identity provider.</p> <note> <p>For mobile applications, we recommend that you use Amazon Cognito. You can use Amazon Cognito with the <a href="http://aws.amazon.com/sdkforios/">AWS SDK for iOS Developer Guide</a> and the <a href="http://aws.amazon.com/sdkforandroid/">AWS SDK for Android Developer Guide</a> to uniquely identify a user. You can also supply the user with a consistent identity throughout the lifetime of an application.</p> <p>To learn more about Amazon Cognito, see <a href="https://docs.aws.amazon.com/mobile/sdkforandroid/developerguide/cognito-auth.html#d0e840">Amazon Cognito Overview</a> in <i>AWS SDK for Android Developer Guide</i> and <a href="https://docs.aws.amazon.com/mobile/sdkforios/developerguide/cognito-auth.html#d0e664">Amazon Cognito Overview</a> in the <i>AWS SDK for iOS Developer Guide</i>.</p> </note> <p>Calling <code>AssumeRoleWithWebIdentity</code> does not require the use of AWS security credentials. Therefore, you can distribute an application (for example, on mobile devices) that requests temporary security credentials without including long-term AWS credentials in the application. You also don't need to deploy server-based proxy services that use long-term AWS credentials. Instead, the identity of the caller is validated by using a token from the web identity provider. For a comparison of <code>AssumeRoleWithWebIdentity</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The temporary security credentials returned by this API consist of an access key ID, a secret access key, and a security token. Applications can use these temporary security credentials to sign calls to AWS service API operations.</p> <p>By default, the temporary security credentials created by <code>AssumeRoleWithWebIdentity</code> last for one hour. However, you can use the optional <code>DurationSeconds</code> parameter to specify the duration of your session. You can provide a value from 900 seconds (15 minutes) up to the maximum session duration setting for the role. This setting can have a value from 1 hour to 12 hours. To learn how to view the maximum value for your role, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session">View the Maximum Session Duration Setting for a Role</a> in the <i>IAM User Guide</i>. The maximum session duration limit applies when you use the <code>AssumeRole*</code> API operations or the <code>assume-role*</code> CLI commands. However the limit does not apply when you use those operations to create a console URL. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html">Using IAM Roles</a> in the <i>IAM User Guide</i>. </p> <p>The temporary security credentials created by <code>AssumeRoleWithWebIdentity</code> can be used to make API calls to any AWS service with the following exception: you cannot call the STS <code>GetFederationToken</code> or <code>GetSessionToken</code> API operations.</p> <p>(Optional) You can pass inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policies</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>Before your application can call <code>AssumeRoleWithWebIdentity</code>, you must have an identity token from a supported identity provider and create a role that the application can assume. The role that your application assumes must trust the identity provider that is associated with the identity token. In other words, the identity provider must be specified in the role's trust policy. </p> <important> <p>Calling <code>AssumeRoleWithWebIdentity</code> can result in an entry in your AWS CloudTrail logs. The entry includes the <a href="http://openid.net/specs/openid-connect-core-1_0.html#Claims">Subject</a> of the provided Web Identity Token. We recommend that you avoid using any personally identifiable information (PII) in this field. For example, you could instead use a GUID or a pairwise identifier, as <a href="http://openid.net/specs/openid-connect-core-1_0.html#SubjectIDTypes">suggested in the OIDC specification</a>.</p> </important> <p>For more information about how to use web identity federation and the <code>AssumeRoleWithWebIdentity</code> API, see the following resources: </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_oidc_manual.html">Using Web Identity Federation API Operations for Mobile Apps</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity">Federation Through a Web-based Identity Provider</a>. </p> </li> <li> <p> <a href="https://web-identity-federation-playground.s3.amazonaws.com/index.html"> Web Identity Federation Playground</a>. Walk through the process of authenticating through Login with Amazon, Facebook, or Google, getting temporary security credentials, and then using those credentials to make a request to AWS. </p> </li> <li> <p> <a href="http://aws.amazon.com/sdkforios/">AWS SDK for iOS Developer Guide</a> and <a href="http://aws.amazon.com/sdkforandroid/">AWS SDK for Android Developer Guide</a>. These toolkits contain sample apps that show how to invoke the identity providers, and then how to use the information from these providers to get and use temporary security credentials. </p> </li> <li> <p> <a href="http://aws.amazon.com/articles/web-identity-federation-with-mobile-applications">Web Identity Federation with Mobile Applications</a>. This article discusses web identity federation and shows an example of how to use web identity federation to get access to content in Amazon S3. </p> </li> </ul>
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
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as managed session policies. The policies must exist in the same account as the role.</p> <p>This parameter is optional. You can provide up to 10 managed policy ARNs. However, the plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note> <p>Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p>
  ##   Action: string (required)
  ##   Policy: string
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>This parameter is optional. Passing policies to this operation returns new temporary credentials. The resulting session's permissions are the intersection of the role's identity-based policy and the session policies. You can use the role's temporary credentials in subsequent AWS API calls to access resources in the account that owns the role. You cannot use session policies to grant more permissions than those allowed by the identity-based policy of the role that is being assumed. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note>
  ##   WebIdentityToken: string (required)
  ##                   : The OAuth 2.0 access token or OpenID Connect ID token that is provided by the identity provider. Your application must get this token by authenticating the user who is using your application with a web identity provider before the application makes an <code>AssumeRoleWithWebIdentity</code> call. 
  ##   Version: string (required)
  var query_601134 = newJObject()
  add(query_601134, "ProviderId", newJString(ProviderId))
  add(query_601134, "RoleArn", newJString(RoleArn))
  add(query_601134, "DurationSeconds", newJInt(DurationSeconds))
  add(query_601134, "RoleSessionName", newJString(RoleSessionName))
  if PolicyArns != nil:
    query_601134.add "PolicyArns", PolicyArns
  add(query_601134, "Action", newJString(Action))
  add(query_601134, "Policy", newJString(Policy))
  add(query_601134, "WebIdentityToken", newJString(WebIdentityToken))
  add(query_601134, "Version", newJString(Version))
  result = call_601133.call(nil, query_601134, nil, nil, nil)

var getAssumeRoleWithWebIdentity* = Call_GetAssumeRoleWithWebIdentity_601113(
    name: "getAssumeRoleWithWebIdentity", meth: HttpMethod.HttpGet,
    host: "sts.amazonaws.com", route: "/#Action=AssumeRoleWithWebIdentity",
    validator: validate_GetAssumeRoleWithWebIdentity_601114, base: "/",
    url: url_GetAssumeRoleWithWebIdentity_601115,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDecodeAuthorizationMessage_601174 = ref object of OpenApiRestCall_600426
proc url_PostDecodeAuthorizationMessage_601176(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDecodeAuthorizationMessage_601175(path: JsonNode;
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
  var valid_601177 = query.getOrDefault("Action")
  valid_601177 = validateParameter(valid_601177, JString, required = true, default = newJString(
      "DecodeAuthorizationMessage"))
  if valid_601177 != nil:
    section.add "Action", valid_601177
  var valid_601178 = query.getOrDefault("Version")
  valid_601178 = validateParameter(valid_601178, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_601178 != nil:
    section.add "Version", valid_601178
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
  var valid_601179 = header.getOrDefault("X-Amz-Date")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Date", valid_601179
  var valid_601180 = header.getOrDefault("X-Amz-Security-Token")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Security-Token", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-Content-Sha256", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Algorithm")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Algorithm", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-Signature")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Signature", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-SignedHeaders", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-Credential")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Credential", valid_601185
  result.add "header", section
  ## parameters in `formData` object:
  ##   EncodedMessage: JString (required)
  ##                 : The encoded message that was returned with the response.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `EncodedMessage` field"
  var valid_601186 = formData.getOrDefault("EncodedMessage")
  valid_601186 = validateParameter(valid_601186, JString, required = true,
                                 default = nil)
  if valid_601186 != nil:
    section.add "EncodedMessage", valid_601186
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601187: Call_PostDecodeAuthorizationMessage_601174; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Decodes additional information about the authorization status of a request from an encoded message returned in response to an AWS request.</p> <p>For example, if a user is not authorized to perform an operation that he or she has requested, the request returns a <code>Client.UnauthorizedOperation</code> response (an HTTP 403 response). Some AWS operations additionally return an encoded message that can provide details about this authorization failure. </p> <note> <p>Only certain AWS operations return an encoded authorization message. The documentation for an individual operation indicates whether that operation returns an encoded message in addition to returning an HTTP code.</p> </note> <p>The message is encoded because the details of the authorization status can constitute privileged information that the user who requested the operation should not see. To decode an authorization status message, a user must be granted permissions via an IAM policy to request the <code>DecodeAuthorizationMessage</code> (<code>sts:DecodeAuthorizationMessage</code>) action. </p> <p>The decoded message includes the following type of information:</p> <ul> <li> <p>Whether the request was denied due to an explicit deny or due to the absence of an explicit allow. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html#policy-eval-denyallow">Determining Whether a Request is Allowed or Denied</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p>The principal who made the request.</p> </li> <li> <p>The requested action.</p> </li> <li> <p>The requested resource.</p> </li> <li> <p>The values of condition keys in the context of the user's request.</p> </li> </ul>
  ## 
  let valid = call_601187.validator(path, query, header, formData, body)
  let scheme = call_601187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601187.url(scheme.get, call_601187.host, call_601187.base,
                         call_601187.route, valid.getOrDefault("path"))
  result = hook(call_601187, url, valid)

proc call*(call_601188: Call_PostDecodeAuthorizationMessage_601174;
          EncodedMessage: string; Action: string = "DecodeAuthorizationMessage";
          Version: string = "2011-06-15"): Recallable =
  ## postDecodeAuthorizationMessage
  ## <p>Decodes additional information about the authorization status of a request from an encoded message returned in response to an AWS request.</p> <p>For example, if a user is not authorized to perform an operation that he or she has requested, the request returns a <code>Client.UnauthorizedOperation</code> response (an HTTP 403 response). Some AWS operations additionally return an encoded message that can provide details about this authorization failure. </p> <note> <p>Only certain AWS operations return an encoded authorization message. The documentation for an individual operation indicates whether that operation returns an encoded message in addition to returning an HTTP code.</p> </note> <p>The message is encoded because the details of the authorization status can constitute privileged information that the user who requested the operation should not see. To decode an authorization status message, a user must be granted permissions via an IAM policy to request the <code>DecodeAuthorizationMessage</code> (<code>sts:DecodeAuthorizationMessage</code>) action. </p> <p>The decoded message includes the following type of information:</p> <ul> <li> <p>Whether the request was denied due to an explicit deny or due to the absence of an explicit allow. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html#policy-eval-denyallow">Determining Whether a Request is Allowed or Denied</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p>The principal who made the request.</p> </li> <li> <p>The requested action.</p> </li> <li> <p>The requested resource.</p> </li> <li> <p>The values of condition keys in the context of the user's request.</p> </li> </ul>
  ##   Action: string (required)
  ##   EncodedMessage: string (required)
  ##                 : The encoded message that was returned with the response.
  ##   Version: string (required)
  var query_601189 = newJObject()
  var formData_601190 = newJObject()
  add(query_601189, "Action", newJString(Action))
  add(formData_601190, "EncodedMessage", newJString(EncodedMessage))
  add(query_601189, "Version", newJString(Version))
  result = call_601188.call(nil, query_601189, nil, formData_601190, nil)

var postDecodeAuthorizationMessage* = Call_PostDecodeAuthorizationMessage_601174(
    name: "postDecodeAuthorizationMessage", meth: HttpMethod.HttpPost,
    host: "sts.amazonaws.com", route: "/#Action=DecodeAuthorizationMessage",
    validator: validate_PostDecodeAuthorizationMessage_601175, base: "/",
    url: url_PostDecodeAuthorizationMessage_601176,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDecodeAuthorizationMessage_601158 = ref object of OpenApiRestCall_600426
proc url_GetDecodeAuthorizationMessage_601160(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDecodeAuthorizationMessage_601159(path: JsonNode; query: JsonNode;
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
  var valid_601161 = query.getOrDefault("Action")
  valid_601161 = validateParameter(valid_601161, JString, required = true, default = newJString(
      "DecodeAuthorizationMessage"))
  if valid_601161 != nil:
    section.add "Action", valid_601161
  var valid_601162 = query.getOrDefault("Version")
  valid_601162 = validateParameter(valid_601162, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_601162 != nil:
    section.add "Version", valid_601162
  var valid_601163 = query.getOrDefault("EncodedMessage")
  valid_601163 = validateParameter(valid_601163, JString, required = true,
                                 default = nil)
  if valid_601163 != nil:
    section.add "EncodedMessage", valid_601163
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
  var valid_601164 = header.getOrDefault("X-Amz-Date")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Date", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-Security-Token")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Security-Token", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Content-Sha256", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Algorithm")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Algorithm", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-Signature")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Signature", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-SignedHeaders", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-Credential")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Credential", valid_601170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601171: Call_GetDecodeAuthorizationMessage_601158; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Decodes additional information about the authorization status of a request from an encoded message returned in response to an AWS request.</p> <p>For example, if a user is not authorized to perform an operation that he or she has requested, the request returns a <code>Client.UnauthorizedOperation</code> response (an HTTP 403 response). Some AWS operations additionally return an encoded message that can provide details about this authorization failure. </p> <note> <p>Only certain AWS operations return an encoded authorization message. The documentation for an individual operation indicates whether that operation returns an encoded message in addition to returning an HTTP code.</p> </note> <p>The message is encoded because the details of the authorization status can constitute privileged information that the user who requested the operation should not see. To decode an authorization status message, a user must be granted permissions via an IAM policy to request the <code>DecodeAuthorizationMessage</code> (<code>sts:DecodeAuthorizationMessage</code>) action. </p> <p>The decoded message includes the following type of information:</p> <ul> <li> <p>Whether the request was denied due to an explicit deny or due to the absence of an explicit allow. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html#policy-eval-denyallow">Determining Whether a Request is Allowed or Denied</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p>The principal who made the request.</p> </li> <li> <p>The requested action.</p> </li> <li> <p>The requested resource.</p> </li> <li> <p>The values of condition keys in the context of the user's request.</p> </li> </ul>
  ## 
  let valid = call_601171.validator(path, query, header, formData, body)
  let scheme = call_601171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601171.url(scheme.get, call_601171.host, call_601171.base,
                         call_601171.route, valid.getOrDefault("path"))
  result = hook(call_601171, url, valid)

proc call*(call_601172: Call_GetDecodeAuthorizationMessage_601158;
          EncodedMessage: string; Action: string = "DecodeAuthorizationMessage";
          Version: string = "2011-06-15"): Recallable =
  ## getDecodeAuthorizationMessage
  ## <p>Decodes additional information about the authorization status of a request from an encoded message returned in response to an AWS request.</p> <p>For example, if a user is not authorized to perform an operation that he or she has requested, the request returns a <code>Client.UnauthorizedOperation</code> response (an HTTP 403 response). Some AWS operations additionally return an encoded message that can provide details about this authorization failure. </p> <note> <p>Only certain AWS operations return an encoded authorization message. The documentation for an individual operation indicates whether that operation returns an encoded message in addition to returning an HTTP code.</p> </note> <p>The message is encoded because the details of the authorization status can constitute privileged information that the user who requested the operation should not see. To decode an authorization status message, a user must be granted permissions via an IAM policy to request the <code>DecodeAuthorizationMessage</code> (<code>sts:DecodeAuthorizationMessage</code>) action. </p> <p>The decoded message includes the following type of information:</p> <ul> <li> <p>Whether the request was denied due to an explicit deny or due to the absence of an explicit allow. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html#policy-eval-denyallow">Determining Whether a Request is Allowed or Denied</a> in the <i>IAM User Guide</i>. </p> </li> <li> <p>The principal who made the request.</p> </li> <li> <p>The requested action.</p> </li> <li> <p>The requested resource.</p> </li> <li> <p>The values of condition keys in the context of the user's request.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   EncodedMessage: string (required)
  ##                 : The encoded message that was returned with the response.
  var query_601173 = newJObject()
  add(query_601173, "Action", newJString(Action))
  add(query_601173, "Version", newJString(Version))
  add(query_601173, "EncodedMessage", newJString(EncodedMessage))
  result = call_601172.call(nil, query_601173, nil, nil, nil)

var getDecodeAuthorizationMessage* = Call_GetDecodeAuthorizationMessage_601158(
    name: "getDecodeAuthorizationMessage", meth: HttpMethod.HttpGet,
    host: "sts.amazonaws.com", route: "/#Action=DecodeAuthorizationMessage",
    validator: validate_GetDecodeAuthorizationMessage_601159, base: "/",
    url: url_GetDecodeAuthorizationMessage_601160,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetAccessKeyInfo_601207 = ref object of OpenApiRestCall_600426
proc url_PostGetAccessKeyInfo_601209(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostGetAccessKeyInfo_601208(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the account identifier for the specified access key ID.</p> <p>Access keys consist of two parts: an access key ID (for example, <code>AKIAIOSFODNN7EXAMPLE</code>) and a secret access key (for example, <code>wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY</code>). For more information about access keys, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html">Managing Access Keys for IAM Users</a> in the <i>IAM User Guide</i>.</p> <p>When you pass an access key ID to this operation, it returns the ID of the AWS account to which the keys belong. Access key IDs beginning with <code>AKIA</code> are long-term credentials for an IAM user or the AWS account root user. Access key IDs beginning with <code>ASIA</code> are temporary credentials that are created using STS operations. If the account in the response belongs to you, you can sign in as the root user and review your root user access keys. Then, you can pull a <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_getting-report.html">credentials report</a> to learn which IAM user owns the keys. To learn who requested the temporary credentials for an <code>ASIA</code> access key, view the STS events in your <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/cloudtrail-integration.html">CloudTrail logs</a>.</p> <p>This operation does not indicate the state of the access key. The key might be active, inactive, or deleted. Active keys might not have permissions to perform an operation. Providing a deleted access key might return an error that the key doesn't exist.</p>
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
  var valid_601210 = query.getOrDefault("Action")
  valid_601210 = validateParameter(valid_601210, JString, required = true,
                                 default = newJString("GetAccessKeyInfo"))
  if valid_601210 != nil:
    section.add "Action", valid_601210
  var valid_601211 = query.getOrDefault("Version")
  valid_601211 = validateParameter(valid_601211, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_601211 != nil:
    section.add "Version", valid_601211
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
  var valid_601212 = header.getOrDefault("X-Amz-Date")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Date", valid_601212
  var valid_601213 = header.getOrDefault("X-Amz-Security-Token")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "X-Amz-Security-Token", valid_601213
  var valid_601214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "X-Amz-Content-Sha256", valid_601214
  var valid_601215 = header.getOrDefault("X-Amz-Algorithm")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-Algorithm", valid_601215
  var valid_601216 = header.getOrDefault("X-Amz-Signature")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Signature", valid_601216
  var valid_601217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-SignedHeaders", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-Credential")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-Credential", valid_601218
  result.add "header", section
  ## parameters in `formData` object:
  ##   AccessKeyId: JString (required)
  ##              : <p>The identifier of an access key.</p> <p>This parameter allows (through its regex pattern) a string of characters that can consist of any upper- or lowercased letter or digit.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AccessKeyId` field"
  var valid_601219 = formData.getOrDefault("AccessKeyId")
  valid_601219 = validateParameter(valid_601219, JString, required = true,
                                 default = nil)
  if valid_601219 != nil:
    section.add "AccessKeyId", valid_601219
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601220: Call_PostGetAccessKeyInfo_601207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the account identifier for the specified access key ID.</p> <p>Access keys consist of two parts: an access key ID (for example, <code>AKIAIOSFODNN7EXAMPLE</code>) and a secret access key (for example, <code>wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY</code>). For more information about access keys, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html">Managing Access Keys for IAM Users</a> in the <i>IAM User Guide</i>.</p> <p>When you pass an access key ID to this operation, it returns the ID of the AWS account to which the keys belong. Access key IDs beginning with <code>AKIA</code> are long-term credentials for an IAM user or the AWS account root user. Access key IDs beginning with <code>ASIA</code> are temporary credentials that are created using STS operations. If the account in the response belongs to you, you can sign in as the root user and review your root user access keys. Then, you can pull a <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_getting-report.html">credentials report</a> to learn which IAM user owns the keys. To learn who requested the temporary credentials for an <code>ASIA</code> access key, view the STS events in your <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/cloudtrail-integration.html">CloudTrail logs</a>.</p> <p>This operation does not indicate the state of the access key. The key might be active, inactive, or deleted. Active keys might not have permissions to perform an operation. Providing a deleted access key might return an error that the key doesn't exist.</p>
  ## 
  let valid = call_601220.validator(path, query, header, formData, body)
  let scheme = call_601220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601220.url(scheme.get, call_601220.host, call_601220.base,
                         call_601220.route, valid.getOrDefault("path"))
  result = hook(call_601220, url, valid)

proc call*(call_601221: Call_PostGetAccessKeyInfo_601207; AccessKeyId: string;
          Action: string = "GetAccessKeyInfo"; Version: string = "2011-06-15"): Recallable =
  ## postGetAccessKeyInfo
  ## <p>Returns the account identifier for the specified access key ID.</p> <p>Access keys consist of two parts: an access key ID (for example, <code>AKIAIOSFODNN7EXAMPLE</code>) and a secret access key (for example, <code>wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY</code>). For more information about access keys, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html">Managing Access Keys for IAM Users</a> in the <i>IAM User Guide</i>.</p> <p>When you pass an access key ID to this operation, it returns the ID of the AWS account to which the keys belong. Access key IDs beginning with <code>AKIA</code> are long-term credentials for an IAM user or the AWS account root user. Access key IDs beginning with <code>ASIA</code> are temporary credentials that are created using STS operations. If the account in the response belongs to you, you can sign in as the root user and review your root user access keys. Then, you can pull a <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_getting-report.html">credentials report</a> to learn which IAM user owns the keys. To learn who requested the temporary credentials for an <code>ASIA</code> access key, view the STS events in your <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/cloudtrail-integration.html">CloudTrail logs</a>.</p> <p>This operation does not indicate the state of the access key. The key might be active, inactive, or deleted. Active keys might not have permissions to perform an operation. Providing a deleted access key might return an error that the key doesn't exist.</p>
  ##   AccessKeyId: string (required)
  ##              : <p>The identifier of an access key.</p> <p>This parameter allows (through its regex pattern) a string of characters that can consist of any upper- or lowercased letter or digit.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601222 = newJObject()
  var formData_601223 = newJObject()
  add(formData_601223, "AccessKeyId", newJString(AccessKeyId))
  add(query_601222, "Action", newJString(Action))
  add(query_601222, "Version", newJString(Version))
  result = call_601221.call(nil, query_601222, nil, formData_601223, nil)

var postGetAccessKeyInfo* = Call_PostGetAccessKeyInfo_601207(
    name: "postGetAccessKeyInfo", meth: HttpMethod.HttpPost,
    host: "sts.amazonaws.com", route: "/#Action=GetAccessKeyInfo",
    validator: validate_PostGetAccessKeyInfo_601208, base: "/",
    url: url_PostGetAccessKeyInfo_601209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetAccessKeyInfo_601191 = ref object of OpenApiRestCall_600426
proc url_GetGetAccessKeyInfo_601193(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGetAccessKeyInfo_601192(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Returns the account identifier for the specified access key ID.</p> <p>Access keys consist of two parts: an access key ID (for example, <code>AKIAIOSFODNN7EXAMPLE</code>) and a secret access key (for example, <code>wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY</code>). For more information about access keys, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html">Managing Access Keys for IAM Users</a> in the <i>IAM User Guide</i>.</p> <p>When you pass an access key ID to this operation, it returns the ID of the AWS account to which the keys belong. Access key IDs beginning with <code>AKIA</code> are long-term credentials for an IAM user or the AWS account root user. Access key IDs beginning with <code>ASIA</code> are temporary credentials that are created using STS operations. If the account in the response belongs to you, you can sign in as the root user and review your root user access keys. Then, you can pull a <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_getting-report.html">credentials report</a> to learn which IAM user owns the keys. To learn who requested the temporary credentials for an <code>ASIA</code> access key, view the STS events in your <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/cloudtrail-integration.html">CloudTrail logs</a>.</p> <p>This operation does not indicate the state of the access key. The key might be active, inactive, or deleted. Active keys might not have permissions to perform an operation. Providing a deleted access key might return an error that the key doesn't exist.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   AccessKeyId: JString (required)
  ##              : <p>The identifier of an access key.</p> <p>This parameter allows (through its regex pattern) a string of characters that can consist of any upper- or lowercased letter or digit.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `AccessKeyId` field"
  var valid_601194 = query.getOrDefault("AccessKeyId")
  valid_601194 = validateParameter(valid_601194, JString, required = true,
                                 default = nil)
  if valid_601194 != nil:
    section.add "AccessKeyId", valid_601194
  var valid_601195 = query.getOrDefault("Action")
  valid_601195 = validateParameter(valid_601195, JString, required = true,
                                 default = newJString("GetAccessKeyInfo"))
  if valid_601195 != nil:
    section.add "Action", valid_601195
  var valid_601196 = query.getOrDefault("Version")
  valid_601196 = validateParameter(valid_601196, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_601196 != nil:
    section.add "Version", valid_601196
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
  var valid_601197 = header.getOrDefault("X-Amz-Date")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Date", valid_601197
  var valid_601198 = header.getOrDefault("X-Amz-Security-Token")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "X-Amz-Security-Token", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Content-Sha256", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-Algorithm")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Algorithm", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Signature")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Signature", valid_601201
  var valid_601202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-SignedHeaders", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-Credential")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Credential", valid_601203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601204: Call_GetGetAccessKeyInfo_601191; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the account identifier for the specified access key ID.</p> <p>Access keys consist of two parts: an access key ID (for example, <code>AKIAIOSFODNN7EXAMPLE</code>) and a secret access key (for example, <code>wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY</code>). For more information about access keys, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html">Managing Access Keys for IAM Users</a> in the <i>IAM User Guide</i>.</p> <p>When you pass an access key ID to this operation, it returns the ID of the AWS account to which the keys belong. Access key IDs beginning with <code>AKIA</code> are long-term credentials for an IAM user or the AWS account root user. Access key IDs beginning with <code>ASIA</code> are temporary credentials that are created using STS operations. If the account in the response belongs to you, you can sign in as the root user and review your root user access keys. Then, you can pull a <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_getting-report.html">credentials report</a> to learn which IAM user owns the keys. To learn who requested the temporary credentials for an <code>ASIA</code> access key, view the STS events in your <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/cloudtrail-integration.html">CloudTrail logs</a>.</p> <p>This operation does not indicate the state of the access key. The key might be active, inactive, or deleted. Active keys might not have permissions to perform an operation. Providing a deleted access key might return an error that the key doesn't exist.</p>
  ## 
  let valid = call_601204.validator(path, query, header, formData, body)
  let scheme = call_601204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601204.url(scheme.get, call_601204.host, call_601204.base,
                         call_601204.route, valid.getOrDefault("path"))
  result = hook(call_601204, url, valid)

proc call*(call_601205: Call_GetGetAccessKeyInfo_601191; AccessKeyId: string;
          Action: string = "GetAccessKeyInfo"; Version: string = "2011-06-15"): Recallable =
  ## getGetAccessKeyInfo
  ## <p>Returns the account identifier for the specified access key ID.</p> <p>Access keys consist of two parts: an access key ID (for example, <code>AKIAIOSFODNN7EXAMPLE</code>) and a secret access key (for example, <code>wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY</code>). For more information about access keys, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html">Managing Access Keys for IAM Users</a> in the <i>IAM User Guide</i>.</p> <p>When you pass an access key ID to this operation, it returns the ID of the AWS account to which the keys belong. Access key IDs beginning with <code>AKIA</code> are long-term credentials for an IAM user or the AWS account root user. Access key IDs beginning with <code>ASIA</code> are temporary credentials that are created using STS operations. If the account in the response belongs to you, you can sign in as the root user and review your root user access keys. Then, you can pull a <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_getting-report.html">credentials report</a> to learn which IAM user owns the keys. To learn who requested the temporary credentials for an <code>ASIA</code> access key, view the STS events in your <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/cloudtrail-integration.html">CloudTrail logs</a>.</p> <p>This operation does not indicate the state of the access key. The key might be active, inactive, or deleted. Active keys might not have permissions to perform an operation. Providing a deleted access key might return an error that the key doesn't exist.</p>
  ##   AccessKeyId: string (required)
  ##              : <p>The identifier of an access key.</p> <p>This parameter allows (through its regex pattern) a string of characters that can consist of any upper- or lowercased letter or digit.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601206 = newJObject()
  add(query_601206, "AccessKeyId", newJString(AccessKeyId))
  add(query_601206, "Action", newJString(Action))
  add(query_601206, "Version", newJString(Version))
  result = call_601205.call(nil, query_601206, nil, nil, nil)

var getGetAccessKeyInfo* = Call_GetGetAccessKeyInfo_601191(
    name: "getGetAccessKeyInfo", meth: HttpMethod.HttpGet,
    host: "sts.amazonaws.com", route: "/#Action=GetAccessKeyInfo",
    validator: validate_GetGetAccessKeyInfo_601192, base: "/",
    url: url_GetGetAccessKeyInfo_601193, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetCallerIdentity_601239 = ref object of OpenApiRestCall_600426
proc url_PostGetCallerIdentity_601241(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostGetCallerIdentity_601240(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns details about the IAM user or role whose credentials are used to call the operation.</p> <note> <p>No permissions are required to perform this operation. If an administrator adds a policy to your IAM user or role that explicitly denies access to the <code>sts:GetCallerIdentity</code> action, you can still perform this operation. Permissions are not required because the same information is returned when an IAM user or role is denied access. To view an example response, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html#troubleshoot_general_access-denied-delete-mfa">I Am Not Authorized to Perform: iam:DeleteVirtualMFADevice</a>.</p> </note>
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
  var valid_601242 = query.getOrDefault("Action")
  valid_601242 = validateParameter(valid_601242, JString, required = true,
                                 default = newJString("GetCallerIdentity"))
  if valid_601242 != nil:
    section.add "Action", valid_601242
  var valid_601243 = query.getOrDefault("Version")
  valid_601243 = validateParameter(valid_601243, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_601243 != nil:
    section.add "Version", valid_601243
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
  var valid_601244 = header.getOrDefault("X-Amz-Date")
  valid_601244 = validateParameter(valid_601244, JString, required = false,
                                 default = nil)
  if valid_601244 != nil:
    section.add "X-Amz-Date", valid_601244
  var valid_601245 = header.getOrDefault("X-Amz-Security-Token")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-Security-Token", valid_601245
  var valid_601246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-Content-Sha256", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-Algorithm")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-Algorithm", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-Signature")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-Signature", valid_601248
  var valid_601249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-SignedHeaders", valid_601249
  var valid_601250 = header.getOrDefault("X-Amz-Credential")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-Credential", valid_601250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601251: Call_PostGetCallerIdentity_601239; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns details about the IAM user or role whose credentials are used to call the operation.</p> <note> <p>No permissions are required to perform this operation. If an administrator adds a policy to your IAM user or role that explicitly denies access to the <code>sts:GetCallerIdentity</code> action, you can still perform this operation. Permissions are not required because the same information is returned when an IAM user or role is denied access. To view an example response, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html#troubleshoot_general_access-denied-delete-mfa">I Am Not Authorized to Perform: iam:DeleteVirtualMFADevice</a>.</p> </note>
  ## 
  let valid = call_601251.validator(path, query, header, formData, body)
  let scheme = call_601251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601251.url(scheme.get, call_601251.host, call_601251.base,
                         call_601251.route, valid.getOrDefault("path"))
  result = hook(call_601251, url, valid)

proc call*(call_601252: Call_PostGetCallerIdentity_601239;
          Action: string = "GetCallerIdentity"; Version: string = "2011-06-15"): Recallable =
  ## postGetCallerIdentity
  ## <p>Returns details about the IAM user or role whose credentials are used to call the operation.</p> <note> <p>No permissions are required to perform this operation. If an administrator adds a policy to your IAM user or role that explicitly denies access to the <code>sts:GetCallerIdentity</code> action, you can still perform this operation. Permissions are not required because the same information is returned when an IAM user or role is denied access. To view an example response, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html#troubleshoot_general_access-denied-delete-mfa">I Am Not Authorized to Perform: iam:DeleteVirtualMFADevice</a>.</p> </note>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601253 = newJObject()
  add(query_601253, "Action", newJString(Action))
  add(query_601253, "Version", newJString(Version))
  result = call_601252.call(nil, query_601253, nil, nil, nil)

var postGetCallerIdentity* = Call_PostGetCallerIdentity_601239(
    name: "postGetCallerIdentity", meth: HttpMethod.HttpPost,
    host: "sts.amazonaws.com", route: "/#Action=GetCallerIdentity",
    validator: validate_PostGetCallerIdentity_601240, base: "/",
    url: url_PostGetCallerIdentity_601241, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetCallerIdentity_601224 = ref object of OpenApiRestCall_600426
proc url_GetGetCallerIdentity_601226(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGetCallerIdentity_601225(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns details about the IAM user or role whose credentials are used to call the operation.</p> <note> <p>No permissions are required to perform this operation. If an administrator adds a policy to your IAM user or role that explicitly denies access to the <code>sts:GetCallerIdentity</code> action, you can still perform this operation. Permissions are not required because the same information is returned when an IAM user or role is denied access. To view an example response, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html#troubleshoot_general_access-denied-delete-mfa">I Am Not Authorized to Perform: iam:DeleteVirtualMFADevice</a>.</p> </note>
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
  var valid_601227 = query.getOrDefault("Action")
  valid_601227 = validateParameter(valid_601227, JString, required = true,
                                 default = newJString("GetCallerIdentity"))
  if valid_601227 != nil:
    section.add "Action", valid_601227
  var valid_601228 = query.getOrDefault("Version")
  valid_601228 = validateParameter(valid_601228, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_601228 != nil:
    section.add "Version", valid_601228
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
  var valid_601229 = header.getOrDefault("X-Amz-Date")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "X-Amz-Date", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-Security-Token")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-Security-Token", valid_601230
  var valid_601231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Content-Sha256", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-Algorithm")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-Algorithm", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-Signature")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-Signature", valid_601233
  var valid_601234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "X-Amz-SignedHeaders", valid_601234
  var valid_601235 = header.getOrDefault("X-Amz-Credential")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-Credential", valid_601235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601236: Call_GetGetCallerIdentity_601224; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns details about the IAM user or role whose credentials are used to call the operation.</p> <note> <p>No permissions are required to perform this operation. If an administrator adds a policy to your IAM user or role that explicitly denies access to the <code>sts:GetCallerIdentity</code> action, you can still perform this operation. Permissions are not required because the same information is returned when an IAM user or role is denied access. To view an example response, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html#troubleshoot_general_access-denied-delete-mfa">I Am Not Authorized to Perform: iam:DeleteVirtualMFADevice</a>.</p> </note>
  ## 
  let valid = call_601236.validator(path, query, header, formData, body)
  let scheme = call_601236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601236.url(scheme.get, call_601236.host, call_601236.base,
                         call_601236.route, valid.getOrDefault("path"))
  result = hook(call_601236, url, valid)

proc call*(call_601237: Call_GetGetCallerIdentity_601224;
          Action: string = "GetCallerIdentity"; Version: string = "2011-06-15"): Recallable =
  ## getGetCallerIdentity
  ## <p>Returns details about the IAM user or role whose credentials are used to call the operation.</p> <note> <p>No permissions are required to perform this operation. If an administrator adds a policy to your IAM user or role that explicitly denies access to the <code>sts:GetCallerIdentity</code> action, you can still perform this operation. Permissions are not required because the same information is returned when an IAM user or role is denied access. To view an example response, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html#troubleshoot_general_access-denied-delete-mfa">I Am Not Authorized to Perform: iam:DeleteVirtualMFADevice</a>.</p> </note>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601238 = newJObject()
  add(query_601238, "Action", newJString(Action))
  add(query_601238, "Version", newJString(Version))
  result = call_601237.call(nil, query_601238, nil, nil, nil)

var getGetCallerIdentity* = Call_GetGetCallerIdentity_601224(
    name: "getGetCallerIdentity", meth: HttpMethod.HttpGet,
    host: "sts.amazonaws.com", route: "/#Action=GetCallerIdentity",
    validator: validate_GetGetCallerIdentity_601225, base: "/",
    url: url_GetGetCallerIdentity_601226, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetFederationToken_601273 = ref object of OpenApiRestCall_600426
proc url_PostGetFederationToken_601275(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostGetFederationToken_601274(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a set of temporary security credentials (consisting of an access key ID, a secret access key, and a security token) for a federated user. A typical use is in a proxy application that gets temporary security credentials on behalf of distributed applications inside a corporate network. You must call the <code>GetFederationToken</code> operation using the long-term security credentials of an IAM user. As a result, this call is appropriate in contexts where those credentials can be safely stored, usually in a server-based application. For a comparison of <code>GetFederationToken</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <note> <p>You can create a mobile-based or browser-based app that can authenticate users using a web identity provider like Login with Amazon, Facebook, Google, or an OpenID Connect-compatible identity provider. In this case, we recommend that you use <a href="http://aws.amazon.com/cognito/">Amazon Cognito</a> or <code>AssumeRoleWithWebIdentity</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity">Federation Through a Web-based Identity Provider</a>.</p> </note> <p>You can also call <code>GetFederationToken</code> using the security credentials of an AWS account root user, but we do not recommend it. Instead, we recommend that you create an IAM user for the purpose of the proxy application. Then attach a policy to the IAM user that limits federated users to only the actions and resources that they need to access. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html">IAM Best Practices</a> in the <i>IAM User Guide</i>. </p> <p>The temporary credentials are valid for the specified duration, from 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36 hours). The default is 43,200 seconds (12 hours). Temporary credentials that are obtained by using AWS account root user credentials have a maximum duration of 3,600 seconds (1 hour).</p> <p>The temporary security credentials created by <code>GetFederationToken</code> can be used to make API calls to any AWS service with the following exceptions:</p> <ul> <li> <p>You cannot use these credentials to call any IAM API operations.</p> </li> <li> <p>You cannot call any STS API operations except <code>GetCallerIdentity</code>.</p> </li> </ul> <p> <b>Permissions</b> </p> <p>You must pass an inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policy</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters.</p> <p>Though the session policy parameters are optional, if you do not pass a policy, then the resulting federated user session has no permissions. The only exception is when the credentials are used to access a resource that has a resource-based policy that specifically references the federated user session in the <code>Principal</code> element of the policy. When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>. For information about using <code>GetFederationToken</code> to create temporary security credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getfederationtoken">GetFederationToken—Federation Through a Custom Identity Broker</a>. </p>
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
  var valid_601276 = query.getOrDefault("Action")
  valid_601276 = validateParameter(valid_601276, JString, required = true,
                                 default = newJString("GetFederationToken"))
  if valid_601276 != nil:
    section.add "Action", valid_601276
  var valid_601277 = query.getOrDefault("Version")
  valid_601277 = validateParameter(valid_601277, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_601277 != nil:
    section.add "Version", valid_601277
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
  var valid_601278 = header.getOrDefault("X-Amz-Date")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "X-Amz-Date", valid_601278
  var valid_601279 = header.getOrDefault("X-Amz-Security-Token")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "X-Amz-Security-Token", valid_601279
  var valid_601280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "X-Amz-Content-Sha256", valid_601280
  var valid_601281 = header.getOrDefault("X-Amz-Algorithm")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-Algorithm", valid_601281
  var valid_601282 = header.getOrDefault("X-Amz-Signature")
  valid_601282 = validateParameter(valid_601282, JString, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "X-Amz-Signature", valid_601282
  var valid_601283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "X-Amz-SignedHeaders", valid_601283
  var valid_601284 = header.getOrDefault("X-Amz-Credential")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "X-Amz-Credential", valid_601284
  result.add "header", section
  ## parameters in `formData` object:
  ##   Name: JString (required)
  ##       : <p>The name of the federated user. The name is used as an identifier for the temporary security credentials (such as <code>Bob</code>). For example, you can reference the federated user name in a resource-based policy, such as in an Amazon S3 bucket policy.</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-</p>
  ##   PolicyArns: JArray
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as a managed session policy. The policies must exist in the same account as the IAM user that is requesting federated access.</p> <p>You must pass an inline or managed <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policy</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. You can provide up to 10 managed policy ARNs. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <p>This parameter is optional. However, if you do not pass any session policies, then the resulting federated user session has no permissions. The only exception is when the credentials are used to access a resource that has a resource-based policy that specifically references the federated user session in the <code>Principal</code> element of the policy.</p> <p>When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note>
  ##   Policy: JString
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>You must pass an inline or managed <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policy</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies.</p> <p>This parameter is optional. However, if you do not pass any session policies, then the resulting federated user session has no permissions. The only exception is when the credentials are used to access a resource that has a resource-based policy that specifically references the federated user session in the <code>Principal</code> element of the policy.</p> <p>When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note>
  ##   DurationSeconds: JInt
  ##                  : The duration, in seconds, that the session should last. Acceptable durations for federation sessions range from 900 seconds (15 minutes) to 129,600 seconds (36 hours), with 43,200 seconds (12 hours) as the default. Sessions obtained using AWS account root user credentials are restricted to a maximum of 3,600 seconds (one hour). If the specified duration is longer than one hour, the session obtained by using root user credentials defaults to one hour.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_601285 = formData.getOrDefault("Name")
  valid_601285 = validateParameter(valid_601285, JString, required = true,
                                 default = nil)
  if valid_601285 != nil:
    section.add "Name", valid_601285
  var valid_601286 = formData.getOrDefault("PolicyArns")
  valid_601286 = validateParameter(valid_601286, JArray, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "PolicyArns", valid_601286
  var valid_601287 = formData.getOrDefault("Policy")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "Policy", valid_601287
  var valid_601288 = formData.getOrDefault("DurationSeconds")
  valid_601288 = validateParameter(valid_601288, JInt, required = false, default = nil)
  if valid_601288 != nil:
    section.add "DurationSeconds", valid_601288
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601289: Call_PostGetFederationToken_601273; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a set of temporary security credentials (consisting of an access key ID, a secret access key, and a security token) for a federated user. A typical use is in a proxy application that gets temporary security credentials on behalf of distributed applications inside a corporate network. You must call the <code>GetFederationToken</code> operation using the long-term security credentials of an IAM user. As a result, this call is appropriate in contexts where those credentials can be safely stored, usually in a server-based application. For a comparison of <code>GetFederationToken</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <note> <p>You can create a mobile-based or browser-based app that can authenticate users using a web identity provider like Login with Amazon, Facebook, Google, or an OpenID Connect-compatible identity provider. In this case, we recommend that you use <a href="http://aws.amazon.com/cognito/">Amazon Cognito</a> or <code>AssumeRoleWithWebIdentity</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity">Federation Through a Web-based Identity Provider</a>.</p> </note> <p>You can also call <code>GetFederationToken</code> using the security credentials of an AWS account root user, but we do not recommend it. Instead, we recommend that you create an IAM user for the purpose of the proxy application. Then attach a policy to the IAM user that limits federated users to only the actions and resources that they need to access. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html">IAM Best Practices</a> in the <i>IAM User Guide</i>. </p> <p>The temporary credentials are valid for the specified duration, from 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36 hours). The default is 43,200 seconds (12 hours). Temporary credentials that are obtained by using AWS account root user credentials have a maximum duration of 3,600 seconds (1 hour).</p> <p>The temporary security credentials created by <code>GetFederationToken</code> can be used to make API calls to any AWS service with the following exceptions:</p> <ul> <li> <p>You cannot use these credentials to call any IAM API operations.</p> </li> <li> <p>You cannot call any STS API operations except <code>GetCallerIdentity</code>.</p> </li> </ul> <p> <b>Permissions</b> </p> <p>You must pass an inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policy</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters.</p> <p>Though the session policy parameters are optional, if you do not pass a policy, then the resulting federated user session has no permissions. The only exception is when the credentials are used to access a resource that has a resource-based policy that specifically references the federated user session in the <code>Principal</code> element of the policy. When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>. For information about using <code>GetFederationToken</code> to create temporary security credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getfederationtoken">GetFederationToken—Federation Through a Custom Identity Broker</a>. </p>
  ## 
  let valid = call_601289.validator(path, query, header, formData, body)
  let scheme = call_601289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601289.url(scheme.get, call_601289.host, call_601289.base,
                         call_601289.route, valid.getOrDefault("path"))
  result = hook(call_601289, url, valid)

proc call*(call_601290: Call_PostGetFederationToken_601273; Name: string;
          Action: string = "GetFederationToken"; PolicyArns: JsonNode = nil;
          Policy: string = ""; Version: string = "2011-06-15"; DurationSeconds: int = 0): Recallable =
  ## postGetFederationToken
  ## <p>Returns a set of temporary security credentials (consisting of an access key ID, a secret access key, and a security token) for a federated user. A typical use is in a proxy application that gets temporary security credentials on behalf of distributed applications inside a corporate network. You must call the <code>GetFederationToken</code> operation using the long-term security credentials of an IAM user. As a result, this call is appropriate in contexts where those credentials can be safely stored, usually in a server-based application. For a comparison of <code>GetFederationToken</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <note> <p>You can create a mobile-based or browser-based app that can authenticate users using a web identity provider like Login with Amazon, Facebook, Google, or an OpenID Connect-compatible identity provider. In this case, we recommend that you use <a href="http://aws.amazon.com/cognito/">Amazon Cognito</a> or <code>AssumeRoleWithWebIdentity</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity">Federation Through a Web-based Identity Provider</a>.</p> </note> <p>You can also call <code>GetFederationToken</code> using the security credentials of an AWS account root user, but we do not recommend it. Instead, we recommend that you create an IAM user for the purpose of the proxy application. Then attach a policy to the IAM user that limits federated users to only the actions and resources that they need to access. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html">IAM Best Practices</a> in the <i>IAM User Guide</i>. </p> <p>The temporary credentials are valid for the specified duration, from 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36 hours). The default is 43,200 seconds (12 hours). Temporary credentials that are obtained by using AWS account root user credentials have a maximum duration of 3,600 seconds (1 hour).</p> <p>The temporary security credentials created by <code>GetFederationToken</code> can be used to make API calls to any AWS service with the following exceptions:</p> <ul> <li> <p>You cannot use these credentials to call any IAM API operations.</p> </li> <li> <p>You cannot call any STS API operations except <code>GetCallerIdentity</code>.</p> </li> </ul> <p> <b>Permissions</b> </p> <p>You must pass an inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policy</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters.</p> <p>Though the session policy parameters are optional, if you do not pass a policy, then the resulting federated user session has no permissions. The only exception is when the credentials are used to access a resource that has a resource-based policy that specifically references the federated user session in the <code>Principal</code> element of the policy. When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>. For information about using <code>GetFederationToken</code> to create temporary security credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getfederationtoken">GetFederationToken—Federation Through a Custom Identity Broker</a>. </p>
  ##   Name: string (required)
  ##       : <p>The name of the federated user. The name is used as an identifier for the temporary security credentials (such as <code>Bob</code>). For example, you can reference the federated user name in a resource-based policy, such as in an Amazon S3 bucket policy.</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-</p>
  ##   Action: string (required)
  ##   PolicyArns: JArray
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as a managed session policy. The policies must exist in the same account as the IAM user that is requesting federated access.</p> <p>You must pass an inline or managed <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policy</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. You can provide up to 10 managed policy ARNs. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <p>This parameter is optional. However, if you do not pass any session policies, then the resulting federated user session has no permissions. The only exception is when the credentials are used to access a resource that has a resource-based policy that specifically references the federated user session in the <code>Principal</code> element of the policy.</p> <p>When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note>
  ##   Policy: string
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>You must pass an inline or managed <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policy</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies.</p> <p>This parameter is optional. However, if you do not pass any session policies, then the resulting federated user session has no permissions. The only exception is when the credentials are used to access a resource that has a resource-based policy that specifically references the federated user session in the <code>Principal</code> element of the policy.</p> <p>When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note>
  ##   Version: string (required)
  ##   DurationSeconds: int
  ##                  : The duration, in seconds, that the session should last. Acceptable durations for federation sessions range from 900 seconds (15 minutes) to 129,600 seconds (36 hours), with 43,200 seconds (12 hours) as the default. Sessions obtained using AWS account root user credentials are restricted to a maximum of 3,600 seconds (one hour). If the specified duration is longer than one hour, the session obtained by using root user credentials defaults to one hour.
  var query_601291 = newJObject()
  var formData_601292 = newJObject()
  add(formData_601292, "Name", newJString(Name))
  add(query_601291, "Action", newJString(Action))
  if PolicyArns != nil:
    formData_601292.add "PolicyArns", PolicyArns
  add(formData_601292, "Policy", newJString(Policy))
  add(query_601291, "Version", newJString(Version))
  add(formData_601292, "DurationSeconds", newJInt(DurationSeconds))
  result = call_601290.call(nil, query_601291, nil, formData_601292, nil)

var postGetFederationToken* = Call_PostGetFederationToken_601273(
    name: "postGetFederationToken", meth: HttpMethod.HttpPost,
    host: "sts.amazonaws.com", route: "/#Action=GetFederationToken",
    validator: validate_PostGetFederationToken_601274, base: "/",
    url: url_PostGetFederationToken_601275, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetFederationToken_601254 = ref object of OpenApiRestCall_600426
proc url_GetGetFederationToken_601256(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGetFederationToken_601255(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a set of temporary security credentials (consisting of an access key ID, a secret access key, and a security token) for a federated user. A typical use is in a proxy application that gets temporary security credentials on behalf of distributed applications inside a corporate network. You must call the <code>GetFederationToken</code> operation using the long-term security credentials of an IAM user. As a result, this call is appropriate in contexts where those credentials can be safely stored, usually in a server-based application. For a comparison of <code>GetFederationToken</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <note> <p>You can create a mobile-based or browser-based app that can authenticate users using a web identity provider like Login with Amazon, Facebook, Google, or an OpenID Connect-compatible identity provider. In this case, we recommend that you use <a href="http://aws.amazon.com/cognito/">Amazon Cognito</a> or <code>AssumeRoleWithWebIdentity</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity">Federation Through a Web-based Identity Provider</a>.</p> </note> <p>You can also call <code>GetFederationToken</code> using the security credentials of an AWS account root user, but we do not recommend it. Instead, we recommend that you create an IAM user for the purpose of the proxy application. Then attach a policy to the IAM user that limits federated users to only the actions and resources that they need to access. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html">IAM Best Practices</a> in the <i>IAM User Guide</i>. </p> <p>The temporary credentials are valid for the specified duration, from 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36 hours). The default is 43,200 seconds (12 hours). Temporary credentials that are obtained by using AWS account root user credentials have a maximum duration of 3,600 seconds (1 hour).</p> <p>The temporary security credentials created by <code>GetFederationToken</code> can be used to make API calls to any AWS service with the following exceptions:</p> <ul> <li> <p>You cannot use these credentials to call any IAM API operations.</p> </li> <li> <p>You cannot call any STS API operations except <code>GetCallerIdentity</code>.</p> </li> </ul> <p> <b>Permissions</b> </p> <p>You must pass an inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policy</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters.</p> <p>Though the session policy parameters are optional, if you do not pass a policy, then the resulting federated user session has no permissions. The only exception is when the credentials are used to access a resource that has a resource-based policy that specifically references the federated user session in the <code>Principal</code> element of the policy. When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>. For information about using <code>GetFederationToken</code> to create temporary security credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getfederationtoken">GetFederationToken—Federation Through a Custom Identity Broker</a>. </p>
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
  ##   PolicyArns: JArray
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as a managed session policy. The policies must exist in the same account as the IAM user that is requesting federated access.</p> <p>You must pass an inline or managed <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policy</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. You can provide up to 10 managed policy ARNs. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <p>This parameter is optional. However, if you do not pass any session policies, then the resulting federated user session has no permissions. The only exception is when the credentials are used to access a resource that has a resource-based policy that specifically references the federated user session in the <code>Principal</code> element of the policy.</p> <p>When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note>
  ##   Action: JString (required)
  ##   Policy: JString
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>You must pass an inline or managed <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policy</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies.</p> <p>This parameter is optional. However, if you do not pass any session policies, then the resulting federated user session has no permissions. The only exception is when the credentials are used to access a resource that has a resource-based policy that specifically references the federated user session in the <code>Principal</code> element of the policy.</p> <p>When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_601257 = query.getOrDefault("Name")
  valid_601257 = validateParameter(valid_601257, JString, required = true,
                                 default = nil)
  if valid_601257 != nil:
    section.add "Name", valid_601257
  var valid_601258 = query.getOrDefault("DurationSeconds")
  valid_601258 = validateParameter(valid_601258, JInt, required = false, default = nil)
  if valid_601258 != nil:
    section.add "DurationSeconds", valid_601258
  var valid_601259 = query.getOrDefault("PolicyArns")
  valid_601259 = validateParameter(valid_601259, JArray, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "PolicyArns", valid_601259
  var valid_601260 = query.getOrDefault("Action")
  valid_601260 = validateParameter(valid_601260, JString, required = true,
                                 default = newJString("GetFederationToken"))
  if valid_601260 != nil:
    section.add "Action", valid_601260
  var valid_601261 = query.getOrDefault("Policy")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "Policy", valid_601261
  var valid_601262 = query.getOrDefault("Version")
  valid_601262 = validateParameter(valid_601262, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_601262 != nil:
    section.add "Version", valid_601262
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
  var valid_601263 = header.getOrDefault("X-Amz-Date")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-Date", valid_601263
  var valid_601264 = header.getOrDefault("X-Amz-Security-Token")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-Security-Token", valid_601264
  var valid_601265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Content-Sha256", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-Algorithm")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-Algorithm", valid_601266
  var valid_601267 = header.getOrDefault("X-Amz-Signature")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "X-Amz-Signature", valid_601267
  var valid_601268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-SignedHeaders", valid_601268
  var valid_601269 = header.getOrDefault("X-Amz-Credential")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-Credential", valid_601269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601270: Call_GetGetFederationToken_601254; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a set of temporary security credentials (consisting of an access key ID, a secret access key, and a security token) for a federated user. A typical use is in a proxy application that gets temporary security credentials on behalf of distributed applications inside a corporate network. You must call the <code>GetFederationToken</code> operation using the long-term security credentials of an IAM user. As a result, this call is appropriate in contexts where those credentials can be safely stored, usually in a server-based application. For a comparison of <code>GetFederationToken</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <note> <p>You can create a mobile-based or browser-based app that can authenticate users using a web identity provider like Login with Amazon, Facebook, Google, or an OpenID Connect-compatible identity provider. In this case, we recommend that you use <a href="http://aws.amazon.com/cognito/">Amazon Cognito</a> or <code>AssumeRoleWithWebIdentity</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity">Federation Through a Web-based Identity Provider</a>.</p> </note> <p>You can also call <code>GetFederationToken</code> using the security credentials of an AWS account root user, but we do not recommend it. Instead, we recommend that you create an IAM user for the purpose of the proxy application. Then attach a policy to the IAM user that limits federated users to only the actions and resources that they need to access. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html">IAM Best Practices</a> in the <i>IAM User Guide</i>. </p> <p>The temporary credentials are valid for the specified duration, from 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36 hours). The default is 43,200 seconds (12 hours). Temporary credentials that are obtained by using AWS account root user credentials have a maximum duration of 3,600 seconds (1 hour).</p> <p>The temporary security credentials created by <code>GetFederationToken</code> can be used to make API calls to any AWS service with the following exceptions:</p> <ul> <li> <p>You cannot use these credentials to call any IAM API operations.</p> </li> <li> <p>You cannot call any STS API operations except <code>GetCallerIdentity</code>.</p> </li> </ul> <p> <b>Permissions</b> </p> <p>You must pass an inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policy</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters.</p> <p>Though the session policy parameters are optional, if you do not pass a policy, then the resulting federated user session has no permissions. The only exception is when the credentials are used to access a resource that has a resource-based policy that specifically references the federated user session in the <code>Principal</code> element of the policy. When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>. For information about using <code>GetFederationToken</code> to create temporary security credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getfederationtoken">GetFederationToken—Federation Through a Custom Identity Broker</a>. </p>
  ## 
  let valid = call_601270.validator(path, query, header, formData, body)
  let scheme = call_601270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601270.url(scheme.get, call_601270.host, call_601270.base,
                         call_601270.route, valid.getOrDefault("path"))
  result = hook(call_601270, url, valid)

proc call*(call_601271: Call_GetGetFederationToken_601254; Name: string;
          DurationSeconds: int = 0; PolicyArns: JsonNode = nil;
          Action: string = "GetFederationToken"; Policy: string = "";
          Version: string = "2011-06-15"): Recallable =
  ## getGetFederationToken
  ## <p>Returns a set of temporary security credentials (consisting of an access key ID, a secret access key, and a security token) for a federated user. A typical use is in a proxy application that gets temporary security credentials on behalf of distributed applications inside a corporate network. You must call the <code>GetFederationToken</code> operation using the long-term security credentials of an IAM user. As a result, this call is appropriate in contexts where those credentials can be safely stored, usually in a server-based application. For a comparison of <code>GetFederationToken</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <note> <p>You can create a mobile-based or browser-based app that can authenticate users using a web identity provider like Login with Amazon, Facebook, Google, or an OpenID Connect-compatible identity provider. In this case, we recommend that you use <a href="http://aws.amazon.com/cognito/">Amazon Cognito</a> or <code>AssumeRoleWithWebIdentity</code>. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity">Federation Through a Web-based Identity Provider</a>.</p> </note> <p>You can also call <code>GetFederationToken</code> using the security credentials of an AWS account root user, but we do not recommend it. Instead, we recommend that you create an IAM user for the purpose of the proxy application. Then attach a policy to the IAM user that limits federated users to only the actions and resources that they need to access. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html">IAM Best Practices</a> in the <i>IAM User Guide</i>. </p> <p>The temporary credentials are valid for the specified duration, from 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36 hours). The default is 43,200 seconds (12 hours). Temporary credentials that are obtained by using AWS account root user credentials have a maximum duration of 3,600 seconds (1 hour).</p> <p>The temporary security credentials created by <code>GetFederationToken</code> can be used to make API calls to any AWS service with the following exceptions:</p> <ul> <li> <p>You cannot use these credentials to call any IAM API operations.</p> </li> <li> <p>You cannot call any STS API operations except <code>GetCallerIdentity</code>.</p> </li> </ul> <p> <b>Permissions</b> </p> <p>You must pass an inline or managed <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policy</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters.</p> <p>Though the session policy parameters are optional, if you do not pass a policy, then the resulting federated user session has no permissions. The only exception is when the credentials are used to access a resource that has a resource-based policy that specifically references the federated user session in the <code>Principal</code> element of the policy. When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>. For information about using <code>GetFederationToken</code> to create temporary security credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getfederationtoken">GetFederationToken—Federation Through a Custom Identity Broker</a>. </p>
  ##   Name: string (required)
  ##       : <p>The name of the federated user. The name is used as an identifier for the temporary security credentials (such as <code>Bob</code>). For example, you can reference the federated user name in a resource-based policy, such as in an Amazon S3 bucket policy.</p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@-</p>
  ##   DurationSeconds: int
  ##                  : The duration, in seconds, that the session should last. Acceptable durations for federation sessions range from 900 seconds (15 minutes) to 129,600 seconds (36 hours), with 43,200 seconds (12 hours) as the default. Sessions obtained using AWS account root user credentials are restricted to a maximum of 3,600 seconds (one hour). If the specified duration is longer than one hour, the session obtained by using root user credentials defaults to one hour.
  ##   PolicyArns: JArray
  ##             : <p>The Amazon Resource Names (ARNs) of the IAM managed policies that you want to use as a managed session policy. The policies must exist in the same account as the IAM user that is requesting federated access.</p> <p>You must pass an inline or managed <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policy</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies. The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. You can provide up to 10 managed policy ARNs. For more information about ARNs, see <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html">Amazon Resource Names (ARNs) and AWS Service Namespaces</a> in the AWS General Reference.</p> <p>This parameter is optional. However, if you do not pass any session policies, then the resulting federated user session has no permissions. The only exception is when the credentials are used to access a resource that has a resource-based policy that specifically references the federated user session in the <code>Principal</code> element of the policy.</p> <p>When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note>
  ##   Action: string (required)
  ##   Policy: string
  ##         : <p>An IAM policy in JSON format that you want to use as an inline session policy.</p> <p>You must pass an inline or managed <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">session policy</a> to this operation. You can pass a single JSON policy document to use as an inline session policy. You can also specify up to 10 managed policies to use as managed session policies.</p> <p>This parameter is optional. However, if you do not pass any session policies, then the resulting federated user session has no permissions. The only exception is when the credentials are used to access a resource that has a resource-based policy that specifically references the federated user session in the <code>Principal</code> element of the policy.</p> <p>When you pass session policies, the session permissions are the intersection of the IAM user policies and the session policies that you pass. This gives you a way to further restrict the permissions for a federated user. You cannot use session policies to grant more permissions than those that are defined in the permissions policy of the IAM user. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session">Session Policies</a> in the <i>IAM User Guide</i>.</p> <p>The plain text that you use for both inline and managed session policies shouldn't exceed 2048 characters. The JSON policy characters can be any ASCII character from the space character to the end of the valid character list (\u0020 through \u00FF). It can also include the tab (\u0009), linefeed (\u000A), and carriage return (\u000D) characters.</p> <note> <p>The characters in this parameter count towards the 2048 character session policy guideline. However, an AWS conversion compresses the session policies into a packed binary format that has a separate limit. This is the enforced limit. The <code>PackedPolicySize</code> response element indicates by percentage how close the policy is to the upper size limit.</p> </note>
  ##   Version: string (required)
  var query_601272 = newJObject()
  add(query_601272, "Name", newJString(Name))
  add(query_601272, "DurationSeconds", newJInt(DurationSeconds))
  if PolicyArns != nil:
    query_601272.add "PolicyArns", PolicyArns
  add(query_601272, "Action", newJString(Action))
  add(query_601272, "Policy", newJString(Policy))
  add(query_601272, "Version", newJString(Version))
  result = call_601271.call(nil, query_601272, nil, nil, nil)

var getGetFederationToken* = Call_GetGetFederationToken_601254(
    name: "getGetFederationToken", meth: HttpMethod.HttpGet,
    host: "sts.amazonaws.com", route: "/#Action=GetFederationToken",
    validator: validate_GetGetFederationToken_601255, base: "/",
    url: url_GetGetFederationToken_601256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetSessionToken_601311 = ref object of OpenApiRestCall_600426
proc url_PostGetSessionToken_601313(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostGetSessionToken_601312(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Returns a set of temporary credentials for an AWS account or IAM user. The credentials consist of an access key ID, a secret access key, and a security token. Typically, you use <code>GetSessionToken</code> if you want to use MFA to protect programmatic calls to specific AWS API operations like Amazon EC2 <code>StopInstances</code>. MFA-enabled IAM users would need to call <code>GetSessionToken</code> and submit an MFA code that is associated with their MFA device. Using the temporary security credentials that are returned from the call, IAM users can then make programmatic calls to API operations that require MFA authentication. If you do not supply a correct MFA code, then the API returns an access denied error. For a comparison of <code>GetSessionToken</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The <code>GetSessionToken</code> operation must be called by using the long-term AWS security credentials of the AWS account root user or an IAM user. Credentials that are created by IAM users are valid for the duration that you specify. This duration can range from 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36 hours), with a default of 43,200 seconds (12 hours). Credentials based on account credentials can range from 900 seconds (15 minutes) up to 3,600 seconds (1 hour), with a default of 1 hour. </p> <p>The temporary security credentials created by <code>GetSessionToken</code> can be used to make API calls to any AWS service with the following exceptions:</p> <ul> <li> <p>You cannot call any IAM API operations unless MFA authentication information is included in the request.</p> </li> <li> <p>You cannot call any STS API <i>except</i> <code>AssumeRole</code> or <code>GetCallerIdentity</code>.</p> </li> </ul> <note> <p>We recommend that you do not call <code>GetSessionToken</code> with AWS account root user credentials. Instead, follow our <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#create-iam-users">best practices</a> by creating one or more IAM users, giving them the necessary permissions, and using IAM users for everyday interaction with AWS. </p> </note> <p>The credentials that are returned by <code>GetSessionToken</code> are based on permissions associated with the user whose credentials were used to call the operation. If <code>GetSessionToken</code> is called using AWS account root user credentials, the temporary credentials have root user permissions. Similarly, if <code>GetSessionToken</code> is called using the credentials of an IAM user, the temporary credentials have the same permissions as the IAM user. </p> <p>For more information about using <code>GetSessionToken</code> to create temporary credentials, go to <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getsessiontoken">Temporary Credentials for Users in Untrusted Environments</a> in the <i>IAM User Guide</i>. </p>
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
  var valid_601314 = query.getOrDefault("Action")
  valid_601314 = validateParameter(valid_601314, JString, required = true,
                                 default = newJString("GetSessionToken"))
  if valid_601314 != nil:
    section.add "Action", valid_601314
  var valid_601315 = query.getOrDefault("Version")
  valid_601315 = validateParameter(valid_601315, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_601315 != nil:
    section.add "Version", valid_601315
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
  var valid_601316 = header.getOrDefault("X-Amz-Date")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "X-Amz-Date", valid_601316
  var valid_601317 = header.getOrDefault("X-Amz-Security-Token")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "X-Amz-Security-Token", valid_601317
  var valid_601318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601318 = validateParameter(valid_601318, JString, required = false,
                                 default = nil)
  if valid_601318 != nil:
    section.add "X-Amz-Content-Sha256", valid_601318
  var valid_601319 = header.getOrDefault("X-Amz-Algorithm")
  valid_601319 = validateParameter(valid_601319, JString, required = false,
                                 default = nil)
  if valid_601319 != nil:
    section.add "X-Amz-Algorithm", valid_601319
  var valid_601320 = header.getOrDefault("X-Amz-Signature")
  valid_601320 = validateParameter(valid_601320, JString, required = false,
                                 default = nil)
  if valid_601320 != nil:
    section.add "X-Amz-Signature", valid_601320
  var valid_601321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "X-Amz-SignedHeaders", valid_601321
  var valid_601322 = header.getOrDefault("X-Amz-Credential")
  valid_601322 = validateParameter(valid_601322, JString, required = false,
                                 default = nil)
  if valid_601322 != nil:
    section.add "X-Amz-Credential", valid_601322
  result.add "header", section
  ## parameters in `formData` object:
  ##   SerialNumber: JString
  ##               : <p>The identification number of the MFA device that is associated with the IAM user who is making the <code>GetSessionToken</code> call. Specify this value if the IAM user has a policy that requires MFA authentication. The value is either the serial number for a hardware device (such as <code>GAHT12345678</code>) or an Amazon Resource Name (ARN) for a virtual device (such as <code>arn:aws:iam::123456789012:mfa/user</code>). You can find the device for an IAM user by going to the AWS Management Console and viewing the user's security credentials. </p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@:/-</p>
  ##   TokenCode: JString
  ##            : <p>The value provided by the MFA device, if MFA is required. If any policy requires the IAM user to submit an MFA code, specify this value. If MFA authentication is required, the user must provide a code when requesting a set of temporary security credentials. A user who fails to provide the code receives an "access denied" response when requesting resources that require MFA authentication.</p> <p>The format for this parameter, as described by its regex pattern, is a sequence of six numeric digits.</p>
  ##   DurationSeconds: JInt
  ##                  : The duration, in seconds, that the credentials should remain valid. Acceptable durations for IAM user sessions range from 900 seconds (15 minutes) to 129,600 seconds (36 hours), with 43,200 seconds (12 hours) as the default. Sessions for AWS account owners are restricted to a maximum of 3,600 seconds (one hour). If the duration is longer than one hour, the session for AWS account owners defaults to one hour.
  section = newJObject()
  var valid_601323 = formData.getOrDefault("SerialNumber")
  valid_601323 = validateParameter(valid_601323, JString, required = false,
                                 default = nil)
  if valid_601323 != nil:
    section.add "SerialNumber", valid_601323
  var valid_601324 = formData.getOrDefault("TokenCode")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "TokenCode", valid_601324
  var valid_601325 = formData.getOrDefault("DurationSeconds")
  valid_601325 = validateParameter(valid_601325, JInt, required = false, default = nil)
  if valid_601325 != nil:
    section.add "DurationSeconds", valid_601325
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601326: Call_PostGetSessionToken_601311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a set of temporary credentials for an AWS account or IAM user. The credentials consist of an access key ID, a secret access key, and a security token. Typically, you use <code>GetSessionToken</code> if you want to use MFA to protect programmatic calls to specific AWS API operations like Amazon EC2 <code>StopInstances</code>. MFA-enabled IAM users would need to call <code>GetSessionToken</code> and submit an MFA code that is associated with their MFA device. Using the temporary security credentials that are returned from the call, IAM users can then make programmatic calls to API operations that require MFA authentication. If you do not supply a correct MFA code, then the API returns an access denied error. For a comparison of <code>GetSessionToken</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The <code>GetSessionToken</code> operation must be called by using the long-term AWS security credentials of the AWS account root user or an IAM user. Credentials that are created by IAM users are valid for the duration that you specify. This duration can range from 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36 hours), with a default of 43,200 seconds (12 hours). Credentials based on account credentials can range from 900 seconds (15 minutes) up to 3,600 seconds (1 hour), with a default of 1 hour. </p> <p>The temporary security credentials created by <code>GetSessionToken</code> can be used to make API calls to any AWS service with the following exceptions:</p> <ul> <li> <p>You cannot call any IAM API operations unless MFA authentication information is included in the request.</p> </li> <li> <p>You cannot call any STS API <i>except</i> <code>AssumeRole</code> or <code>GetCallerIdentity</code>.</p> </li> </ul> <note> <p>We recommend that you do not call <code>GetSessionToken</code> with AWS account root user credentials. Instead, follow our <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#create-iam-users">best practices</a> by creating one or more IAM users, giving them the necessary permissions, and using IAM users for everyday interaction with AWS. </p> </note> <p>The credentials that are returned by <code>GetSessionToken</code> are based on permissions associated with the user whose credentials were used to call the operation. If <code>GetSessionToken</code> is called using AWS account root user credentials, the temporary credentials have root user permissions. Similarly, if <code>GetSessionToken</code> is called using the credentials of an IAM user, the temporary credentials have the same permissions as the IAM user. </p> <p>For more information about using <code>GetSessionToken</code> to create temporary credentials, go to <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getsessiontoken">Temporary Credentials for Users in Untrusted Environments</a> in the <i>IAM User Guide</i>. </p>
  ## 
  let valid = call_601326.validator(path, query, header, formData, body)
  let scheme = call_601326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601326.url(scheme.get, call_601326.host, call_601326.base,
                         call_601326.route, valid.getOrDefault("path"))
  result = hook(call_601326, url, valid)

proc call*(call_601327: Call_PostGetSessionToken_601311; SerialNumber: string = "";
          Action: string = "GetSessionToken"; Version: string = "2011-06-15";
          TokenCode: string = ""; DurationSeconds: int = 0): Recallable =
  ## postGetSessionToken
  ## <p>Returns a set of temporary credentials for an AWS account or IAM user. The credentials consist of an access key ID, a secret access key, and a security token. Typically, you use <code>GetSessionToken</code> if you want to use MFA to protect programmatic calls to specific AWS API operations like Amazon EC2 <code>StopInstances</code>. MFA-enabled IAM users would need to call <code>GetSessionToken</code> and submit an MFA code that is associated with their MFA device. Using the temporary security credentials that are returned from the call, IAM users can then make programmatic calls to API operations that require MFA authentication. If you do not supply a correct MFA code, then the API returns an access denied error. For a comparison of <code>GetSessionToken</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The <code>GetSessionToken</code> operation must be called by using the long-term AWS security credentials of the AWS account root user or an IAM user. Credentials that are created by IAM users are valid for the duration that you specify. This duration can range from 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36 hours), with a default of 43,200 seconds (12 hours). Credentials based on account credentials can range from 900 seconds (15 minutes) up to 3,600 seconds (1 hour), with a default of 1 hour. </p> <p>The temporary security credentials created by <code>GetSessionToken</code> can be used to make API calls to any AWS service with the following exceptions:</p> <ul> <li> <p>You cannot call any IAM API operations unless MFA authentication information is included in the request.</p> </li> <li> <p>You cannot call any STS API <i>except</i> <code>AssumeRole</code> or <code>GetCallerIdentity</code>.</p> </li> </ul> <note> <p>We recommend that you do not call <code>GetSessionToken</code> with AWS account root user credentials. Instead, follow our <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#create-iam-users">best practices</a> by creating one or more IAM users, giving them the necessary permissions, and using IAM users for everyday interaction with AWS. </p> </note> <p>The credentials that are returned by <code>GetSessionToken</code> are based on permissions associated with the user whose credentials were used to call the operation. If <code>GetSessionToken</code> is called using AWS account root user credentials, the temporary credentials have root user permissions. Similarly, if <code>GetSessionToken</code> is called using the credentials of an IAM user, the temporary credentials have the same permissions as the IAM user. </p> <p>For more information about using <code>GetSessionToken</code> to create temporary credentials, go to <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getsessiontoken">Temporary Credentials for Users in Untrusted Environments</a> in the <i>IAM User Guide</i>. </p>
  ##   SerialNumber: string
  ##               : <p>The identification number of the MFA device that is associated with the IAM user who is making the <code>GetSessionToken</code> call. Specify this value if the IAM user has a policy that requires MFA authentication. The value is either the serial number for a hardware device (such as <code>GAHT12345678</code>) or an Amazon Resource Name (ARN) for a virtual device (such as <code>arn:aws:iam::123456789012:mfa/user</code>). You can find the device for an IAM user by going to the AWS Management Console and viewing the user's security credentials. </p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@:/-</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   TokenCode: string
  ##            : <p>The value provided by the MFA device, if MFA is required. If any policy requires the IAM user to submit an MFA code, specify this value. If MFA authentication is required, the user must provide a code when requesting a set of temporary security credentials. A user who fails to provide the code receives an "access denied" response when requesting resources that require MFA authentication.</p> <p>The format for this parameter, as described by its regex pattern, is a sequence of six numeric digits.</p>
  ##   DurationSeconds: int
  ##                  : The duration, in seconds, that the credentials should remain valid. Acceptable durations for IAM user sessions range from 900 seconds (15 minutes) to 129,600 seconds (36 hours), with 43,200 seconds (12 hours) as the default. Sessions for AWS account owners are restricted to a maximum of 3,600 seconds (one hour). If the duration is longer than one hour, the session for AWS account owners defaults to one hour.
  var query_601328 = newJObject()
  var formData_601329 = newJObject()
  add(formData_601329, "SerialNumber", newJString(SerialNumber))
  add(query_601328, "Action", newJString(Action))
  add(query_601328, "Version", newJString(Version))
  add(formData_601329, "TokenCode", newJString(TokenCode))
  add(formData_601329, "DurationSeconds", newJInt(DurationSeconds))
  result = call_601327.call(nil, query_601328, nil, formData_601329, nil)

var postGetSessionToken* = Call_PostGetSessionToken_601311(
    name: "postGetSessionToken", meth: HttpMethod.HttpPost,
    host: "sts.amazonaws.com", route: "/#Action=GetSessionToken",
    validator: validate_PostGetSessionToken_601312, base: "/",
    url: url_PostGetSessionToken_601313, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetSessionToken_601293 = ref object of OpenApiRestCall_600426
proc url_GetGetSessionToken_601295(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGetSessionToken_601294(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Returns a set of temporary credentials for an AWS account or IAM user. The credentials consist of an access key ID, a secret access key, and a security token. Typically, you use <code>GetSessionToken</code> if you want to use MFA to protect programmatic calls to specific AWS API operations like Amazon EC2 <code>StopInstances</code>. MFA-enabled IAM users would need to call <code>GetSessionToken</code> and submit an MFA code that is associated with their MFA device. Using the temporary security credentials that are returned from the call, IAM users can then make programmatic calls to API operations that require MFA authentication. If you do not supply a correct MFA code, then the API returns an access denied error. For a comparison of <code>GetSessionToken</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The <code>GetSessionToken</code> operation must be called by using the long-term AWS security credentials of the AWS account root user or an IAM user. Credentials that are created by IAM users are valid for the duration that you specify. This duration can range from 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36 hours), with a default of 43,200 seconds (12 hours). Credentials based on account credentials can range from 900 seconds (15 minutes) up to 3,600 seconds (1 hour), with a default of 1 hour. </p> <p>The temporary security credentials created by <code>GetSessionToken</code> can be used to make API calls to any AWS service with the following exceptions:</p> <ul> <li> <p>You cannot call any IAM API operations unless MFA authentication information is included in the request.</p> </li> <li> <p>You cannot call any STS API <i>except</i> <code>AssumeRole</code> or <code>GetCallerIdentity</code>.</p> </li> </ul> <note> <p>We recommend that you do not call <code>GetSessionToken</code> with AWS account root user credentials. Instead, follow our <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#create-iam-users">best practices</a> by creating one or more IAM users, giving them the necessary permissions, and using IAM users for everyday interaction with AWS. </p> </note> <p>The credentials that are returned by <code>GetSessionToken</code> are based on permissions associated with the user whose credentials were used to call the operation. If <code>GetSessionToken</code> is called using AWS account root user credentials, the temporary credentials have root user permissions. Similarly, if <code>GetSessionToken</code> is called using the credentials of an IAM user, the temporary credentials have the same permissions as the IAM user. </p> <p>For more information about using <code>GetSessionToken</code> to create temporary credentials, go to <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getsessiontoken">Temporary Credentials for Users in Untrusted Environments</a> in the <i>IAM User Guide</i>. </p>
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
  var valid_601296 = query.getOrDefault("TokenCode")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "TokenCode", valid_601296
  var valid_601297 = query.getOrDefault("SerialNumber")
  valid_601297 = validateParameter(valid_601297, JString, required = false,
                                 default = nil)
  if valid_601297 != nil:
    section.add "SerialNumber", valid_601297
  var valid_601298 = query.getOrDefault("DurationSeconds")
  valid_601298 = validateParameter(valid_601298, JInt, required = false, default = nil)
  if valid_601298 != nil:
    section.add "DurationSeconds", valid_601298
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601299 = query.getOrDefault("Action")
  valid_601299 = validateParameter(valid_601299, JString, required = true,
                                 default = newJString("GetSessionToken"))
  if valid_601299 != nil:
    section.add "Action", valid_601299
  var valid_601300 = query.getOrDefault("Version")
  valid_601300 = validateParameter(valid_601300, JString, required = true,
                                 default = newJString("2011-06-15"))
  if valid_601300 != nil:
    section.add "Version", valid_601300
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
  var valid_601301 = header.getOrDefault("X-Amz-Date")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "X-Amz-Date", valid_601301
  var valid_601302 = header.getOrDefault("X-Amz-Security-Token")
  valid_601302 = validateParameter(valid_601302, JString, required = false,
                                 default = nil)
  if valid_601302 != nil:
    section.add "X-Amz-Security-Token", valid_601302
  var valid_601303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601303 = validateParameter(valid_601303, JString, required = false,
                                 default = nil)
  if valid_601303 != nil:
    section.add "X-Amz-Content-Sha256", valid_601303
  var valid_601304 = header.getOrDefault("X-Amz-Algorithm")
  valid_601304 = validateParameter(valid_601304, JString, required = false,
                                 default = nil)
  if valid_601304 != nil:
    section.add "X-Amz-Algorithm", valid_601304
  var valid_601305 = header.getOrDefault("X-Amz-Signature")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-Signature", valid_601305
  var valid_601306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-SignedHeaders", valid_601306
  var valid_601307 = header.getOrDefault("X-Amz-Credential")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-Credential", valid_601307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601308: Call_GetGetSessionToken_601293; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a set of temporary credentials for an AWS account or IAM user. The credentials consist of an access key ID, a secret access key, and a security token. Typically, you use <code>GetSessionToken</code> if you want to use MFA to protect programmatic calls to specific AWS API operations like Amazon EC2 <code>StopInstances</code>. MFA-enabled IAM users would need to call <code>GetSessionToken</code> and submit an MFA code that is associated with their MFA device. Using the temporary security credentials that are returned from the call, IAM users can then make programmatic calls to API operations that require MFA authentication. If you do not supply a correct MFA code, then the API returns an access denied error. For a comparison of <code>GetSessionToken</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The <code>GetSessionToken</code> operation must be called by using the long-term AWS security credentials of the AWS account root user or an IAM user. Credentials that are created by IAM users are valid for the duration that you specify. This duration can range from 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36 hours), with a default of 43,200 seconds (12 hours). Credentials based on account credentials can range from 900 seconds (15 minutes) up to 3,600 seconds (1 hour), with a default of 1 hour. </p> <p>The temporary security credentials created by <code>GetSessionToken</code> can be used to make API calls to any AWS service with the following exceptions:</p> <ul> <li> <p>You cannot call any IAM API operations unless MFA authentication information is included in the request.</p> </li> <li> <p>You cannot call any STS API <i>except</i> <code>AssumeRole</code> or <code>GetCallerIdentity</code>.</p> </li> </ul> <note> <p>We recommend that you do not call <code>GetSessionToken</code> with AWS account root user credentials. Instead, follow our <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#create-iam-users">best practices</a> by creating one or more IAM users, giving them the necessary permissions, and using IAM users for everyday interaction with AWS. </p> </note> <p>The credentials that are returned by <code>GetSessionToken</code> are based on permissions associated with the user whose credentials were used to call the operation. If <code>GetSessionToken</code> is called using AWS account root user credentials, the temporary credentials have root user permissions. Similarly, if <code>GetSessionToken</code> is called using the credentials of an IAM user, the temporary credentials have the same permissions as the IAM user. </p> <p>For more information about using <code>GetSessionToken</code> to create temporary credentials, go to <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getsessiontoken">Temporary Credentials for Users in Untrusted Environments</a> in the <i>IAM User Guide</i>. </p>
  ## 
  let valid = call_601308.validator(path, query, header, formData, body)
  let scheme = call_601308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601308.url(scheme.get, call_601308.host, call_601308.base,
                         call_601308.route, valid.getOrDefault("path"))
  result = hook(call_601308, url, valid)

proc call*(call_601309: Call_GetGetSessionToken_601293; TokenCode: string = "";
          SerialNumber: string = ""; DurationSeconds: int = 0;
          Action: string = "GetSessionToken"; Version: string = "2011-06-15"): Recallable =
  ## getGetSessionToken
  ## <p>Returns a set of temporary credentials for an AWS account or IAM user. The credentials consist of an access key ID, a secret access key, and a security token. Typically, you use <code>GetSessionToken</code> if you want to use MFA to protect programmatic calls to specific AWS API operations like Amazon EC2 <code>StopInstances</code>. MFA-enabled IAM users would need to call <code>GetSessionToken</code> and submit an MFA code that is associated with their MFA device. Using the temporary security credentials that are returned from the call, IAM users can then make programmatic calls to API operations that require MFA authentication. If you do not supply a correct MFA code, then the API returns an access denied error. For a comparison of <code>GetSessionToken</code> with the other API operations that produce temporary credentials, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html">Requesting Temporary Security Credentials</a> and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison">Comparing the AWS STS API operations</a> in the <i>IAM User Guide</i>.</p> <p>The <code>GetSessionToken</code> operation must be called by using the long-term AWS security credentials of the AWS account root user or an IAM user. Credentials that are created by IAM users are valid for the duration that you specify. This duration can range from 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36 hours), with a default of 43,200 seconds (12 hours). Credentials based on account credentials can range from 900 seconds (15 minutes) up to 3,600 seconds (1 hour), with a default of 1 hour. </p> <p>The temporary security credentials created by <code>GetSessionToken</code> can be used to make API calls to any AWS service with the following exceptions:</p> <ul> <li> <p>You cannot call any IAM API operations unless MFA authentication information is included in the request.</p> </li> <li> <p>You cannot call any STS API <i>except</i> <code>AssumeRole</code> or <code>GetCallerIdentity</code>.</p> </li> </ul> <note> <p>We recommend that you do not call <code>GetSessionToken</code> with AWS account root user credentials. Instead, follow our <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#create-iam-users">best practices</a> by creating one or more IAM users, giving them the necessary permissions, and using IAM users for everyday interaction with AWS. </p> </note> <p>The credentials that are returned by <code>GetSessionToken</code> are based on permissions associated with the user whose credentials were used to call the operation. If <code>GetSessionToken</code> is called using AWS account root user credentials, the temporary credentials have root user permissions. Similarly, if <code>GetSessionToken</code> is called using the credentials of an IAM user, the temporary credentials have the same permissions as the IAM user. </p> <p>For more information about using <code>GetSessionToken</code> to create temporary credentials, go to <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getsessiontoken">Temporary Credentials for Users in Untrusted Environments</a> in the <i>IAM User Guide</i>. </p>
  ##   TokenCode: string
  ##            : <p>The value provided by the MFA device, if MFA is required. If any policy requires the IAM user to submit an MFA code, specify this value. If MFA authentication is required, the user must provide a code when requesting a set of temporary security credentials. A user who fails to provide the code receives an "access denied" response when requesting resources that require MFA authentication.</p> <p>The format for this parameter, as described by its regex pattern, is a sequence of six numeric digits.</p>
  ##   SerialNumber: string
  ##               : <p>The identification number of the MFA device that is associated with the IAM user who is making the <code>GetSessionToken</code> call. Specify this value if the IAM user has a policy that requires MFA authentication. The value is either the serial number for a hardware device (such as <code>GAHT12345678</code>) or an Amazon Resource Name (ARN) for a virtual device (such as <code>arn:aws:iam::123456789012:mfa/user</code>). You can find the device for an IAM user by going to the AWS Management Console and viewing the user's security credentials. </p> <p>The regex used to validate this parameter is a string of characters consisting of upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: =,.@:/-</p>
  ##   DurationSeconds: int
  ##                  : The duration, in seconds, that the credentials should remain valid. Acceptable durations for IAM user sessions range from 900 seconds (15 minutes) to 129,600 seconds (36 hours), with 43,200 seconds (12 hours) as the default. Sessions for AWS account owners are restricted to a maximum of 3,600 seconds (one hour). If the duration is longer than one hour, the session for AWS account owners defaults to one hour.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601310 = newJObject()
  add(query_601310, "TokenCode", newJString(TokenCode))
  add(query_601310, "SerialNumber", newJString(SerialNumber))
  add(query_601310, "DurationSeconds", newJInt(DurationSeconds))
  add(query_601310, "Action", newJString(Action))
  add(query_601310, "Version", newJString(Version))
  result = call_601309.call(nil, query_601310, nil, nil, nil)

var getGetSessionToken* = Call_GetGetSessionToken_601293(
    name: "getGetSessionToken", meth: HttpMethod.HttpGet, host: "sts.amazonaws.com",
    route: "/#Action=GetSessionToken", validator: validate_GetGetSessionToken_601294,
    base: "/", url: url_GetGetSessionToken_601295,
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
