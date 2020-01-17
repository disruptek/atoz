
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Single Sign-On
## version: 2019-06-10
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>AWS Single Sign-On Portal is a web service that makes it easy for you to assign user access to AWS SSO resources such as the user portal. Users can get AWS account applications and roles assigned to them and get federated into the application.</p> <p>For general information about AWS SSO, see <a href="https://docs.aws.amazon.com/singlesignon/latest/userguide/what-is.html">What is AWS Single Sign-On?</a> in the <i>AWS SSO User Guide</i>.</p> <p>This API reference guide describes the AWS SSO Portal operations that you can call programatically and includes detailed information on data types and errors.</p> <note> <p>AWS provides SDKs that consist of libraries and sample code for various programming languages and platforms, such as Java, Ruby, .Net, iOS, or Android. The SDKs provide a convenient way to create programmatic access to AWS SSO and other AWS services. For more information about the AWS SDKs, including how to download and install them, see <a href="http://aws.amazon.com/tools/">Tools for Amazon Web Services</a>.</p> </note>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/sso/
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

  OpenApiRestCall_605580 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605580](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605580): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "portal.sso.ap-northeast-1.amazonaws.com", "ap-southeast-1": "portal.sso.ap-southeast-1.amazonaws.com",
                           "us-west-2": "portal.sso.us-west-2.amazonaws.com",
                           "eu-west-2": "portal.sso.eu-west-2.amazonaws.com", "ap-northeast-3": "portal.sso.ap-northeast-3.amazonaws.com", "eu-central-1": "portal.sso.eu-central-1.amazonaws.com",
                           "us-east-2": "portal.sso.us-east-2.amazonaws.com",
                           "us-east-1": "portal.sso.us-east-1.amazonaws.com", "cn-northwest-1": "portal.sso.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "portal.sso.ap-south-1.amazonaws.com",
                           "eu-north-1": "portal.sso.eu-north-1.amazonaws.com", "ap-northeast-2": "portal.sso.ap-northeast-2.amazonaws.com",
                           "us-west-1": "portal.sso.us-west-1.amazonaws.com", "us-gov-east-1": "portal.sso.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "portal.sso.eu-west-3.amazonaws.com", "cn-north-1": "portal.sso.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "portal.sso.sa-east-1.amazonaws.com",
                           "eu-west-1": "portal.sso.eu-west-1.amazonaws.com", "us-gov-west-1": "portal.sso.us-gov-west-1.amazonaws.com", "ap-southeast-2": "portal.sso.ap-southeast-2.amazonaws.com", "ca-central-1": "portal.sso.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "portal.sso.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "portal.sso.ap-southeast-1.amazonaws.com",
      "us-west-2": "portal.sso.us-west-2.amazonaws.com",
      "eu-west-2": "portal.sso.eu-west-2.amazonaws.com",
      "ap-northeast-3": "portal.sso.ap-northeast-3.amazonaws.com",
      "eu-central-1": "portal.sso.eu-central-1.amazonaws.com",
      "us-east-2": "portal.sso.us-east-2.amazonaws.com",
      "us-east-1": "portal.sso.us-east-1.amazonaws.com",
      "cn-northwest-1": "portal.sso.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "portal.sso.ap-south-1.amazonaws.com",
      "eu-north-1": "portal.sso.eu-north-1.amazonaws.com",
      "ap-northeast-2": "portal.sso.ap-northeast-2.amazonaws.com",
      "us-west-1": "portal.sso.us-west-1.amazonaws.com",
      "us-gov-east-1": "portal.sso.us-gov-east-1.amazonaws.com",
      "eu-west-3": "portal.sso.eu-west-3.amazonaws.com",
      "cn-north-1": "portal.sso.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "portal.sso.sa-east-1.amazonaws.com",
      "eu-west-1": "portal.sso.eu-west-1.amazonaws.com",
      "us-gov-west-1": "portal.sso.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "portal.sso.ap-southeast-2.amazonaws.com",
      "ca-central-1": "portal.sso.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "sso"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_GetRoleCredentials_605918 = ref object of OpenApiRestCall_605580
proc url_GetRoleCredentials_605920(protocol: Scheme; host: string; base: string;
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

proc validate_GetRoleCredentials_605919(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns the STS short-term credentials for a given role name that is assigned to the user.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   role_name: JString (required)
  ##            : The friendly name of the role that is assigned to the user.
  ##   account_id: JString (required)
  ##             : The identifier for the AWS account that is assigned to the user.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `role_name` field"
  var valid_606032 = query.getOrDefault("role_name")
  valid_606032 = validateParameter(valid_606032, JString, required = true,
                                 default = nil)
  if valid_606032 != nil:
    section.add "role_name", valid_606032
  var valid_606033 = query.getOrDefault("account_id")
  valid_606033 = validateParameter(valid_606033, JString, required = true,
                                 default = nil)
  if valid_606033 != nil:
    section.add "account_id", valid_606033
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   x-amz-sso_bearer_token: JString (required)
  ##                         : The token issued by the <code>CreateToken</code> API call. For more information, see <a 
  ## href="https://docs.aws.amazon.com/singlesignon/latest/OIDCAPIReference/API_CreateToken.html">CreateToken</a> in the <i>AWS SSO OIDC API Reference Guide</i>.
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606034 = header.getOrDefault("X-Amz-Signature")
  valid_606034 = validateParameter(valid_606034, JString, required = false,
                                 default = nil)
  if valid_606034 != nil:
    section.add "X-Amz-Signature", valid_606034
  var valid_606035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606035 = validateParameter(valid_606035, JString, required = false,
                                 default = nil)
  if valid_606035 != nil:
    section.add "X-Amz-Content-Sha256", valid_606035
  var valid_606036 = header.getOrDefault("X-Amz-Date")
  valid_606036 = validateParameter(valid_606036, JString, required = false,
                                 default = nil)
  if valid_606036 != nil:
    section.add "X-Amz-Date", valid_606036
  var valid_606037 = header.getOrDefault("X-Amz-Credential")
  valid_606037 = validateParameter(valid_606037, JString, required = false,
                                 default = nil)
  if valid_606037 != nil:
    section.add "X-Amz-Credential", valid_606037
  var valid_606038 = header.getOrDefault("X-Amz-Security-Token")
  valid_606038 = validateParameter(valid_606038, JString, required = false,
                                 default = nil)
  if valid_606038 != nil:
    section.add "X-Amz-Security-Token", valid_606038
  var valid_606039 = header.getOrDefault("X-Amz-Algorithm")
  valid_606039 = validateParameter(valid_606039, JString, required = false,
                                 default = nil)
  if valid_606039 != nil:
    section.add "X-Amz-Algorithm", valid_606039
  assert header != nil, "header argument is necessary due to required `x-amz-sso_bearer_token` field"
  var valid_606040 = header.getOrDefault("x-amz-sso_bearer_token")
  valid_606040 = validateParameter(valid_606040, JString, required = true,
                                 default = nil)
  if valid_606040 != nil:
    section.add "x-amz-sso_bearer_token", valid_606040
  var valid_606041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606041 = validateParameter(valid_606041, JString, required = false,
                                 default = nil)
  if valid_606041 != nil:
    section.add "X-Amz-SignedHeaders", valid_606041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606064: Call_GetRoleCredentials_605918; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the STS short-term credentials for a given role name that is assigned to the user.
  ## 
  let valid = call_606064.validator(path, query, header, formData, body)
  let scheme = call_606064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606064.url(scheme.get, call_606064.host, call_606064.base,
                         call_606064.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606064, url, valid)

proc call*(call_606135: Call_GetRoleCredentials_605918; roleName: string;
          accountId: string): Recallable =
  ## getRoleCredentials
  ## Returns the STS short-term credentials for a given role name that is assigned to the user.
  ##   roleName: string (required)
  ##           : The friendly name of the role that is assigned to the user.
  ##   accountId: string (required)
  ##            : The identifier for the AWS account that is assigned to the user.
  var query_606136 = newJObject()
  add(query_606136, "role_name", newJString(roleName))
  add(query_606136, "account_id", newJString(accountId))
  result = call_606135.call(nil, query_606136, nil, nil, nil)

var getRoleCredentials* = Call_GetRoleCredentials_605918(
    name: "getRoleCredentials", meth: HttpMethod.HttpGet,
    host: "portal.sso.amazonaws.com", route: "/federation/credentials#role_name&account_id&x-amz-sso_bearer_token",
    validator: validate_GetRoleCredentials_605919, base: "/",
    url: url_GetRoleCredentials_605920, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccountRoles_606176 = ref object of OpenApiRestCall_605580
proc url_ListAccountRoles_606178(protocol: Scheme; host: string; base: string;
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

proc validate_ListAccountRoles_606177(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Lists all roles that are assigned to the user for a given AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   next_token: JString
  ##             : The page token from the previous response output when you request subsequent pages.
  ##   account_id: JString (required)
  ##             : The identifier for the AWS account that is assigned to the user.
  ##   max_result: JInt
  ##             : The number of items that clients can request per page.
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606179 = query.getOrDefault("nextToken")
  valid_606179 = validateParameter(valid_606179, JString, required = false,
                                 default = nil)
  if valid_606179 != nil:
    section.add "nextToken", valid_606179
  var valid_606180 = query.getOrDefault("next_token")
  valid_606180 = validateParameter(valid_606180, JString, required = false,
                                 default = nil)
  if valid_606180 != nil:
    section.add "next_token", valid_606180
  assert query != nil,
        "query argument is necessary due to required `account_id` field"
  var valid_606181 = query.getOrDefault("account_id")
  valid_606181 = validateParameter(valid_606181, JString, required = true,
                                 default = nil)
  if valid_606181 != nil:
    section.add "account_id", valid_606181
  var valid_606182 = query.getOrDefault("max_result")
  valid_606182 = validateParameter(valid_606182, JInt, required = false, default = nil)
  if valid_606182 != nil:
    section.add "max_result", valid_606182
  var valid_606183 = query.getOrDefault("maxResults")
  valid_606183 = validateParameter(valid_606183, JString, required = false,
                                 default = nil)
  if valid_606183 != nil:
    section.add "maxResults", valid_606183
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   x-amz-sso_bearer_token: JString (required)
  ##                         : The token issued by the <code>CreateToken</code> API call. For more information, see <a 
  ## href="https://docs.aws.amazon.com/singlesignon/latest/OIDCAPIReference/API_CreateToken.html">CreateToken</a> in the <i>AWS SSO OIDC API Reference Guide</i>.
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606184 = header.getOrDefault("X-Amz-Signature")
  valid_606184 = validateParameter(valid_606184, JString, required = false,
                                 default = nil)
  if valid_606184 != nil:
    section.add "X-Amz-Signature", valid_606184
  var valid_606185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606185 = validateParameter(valid_606185, JString, required = false,
                                 default = nil)
  if valid_606185 != nil:
    section.add "X-Amz-Content-Sha256", valid_606185
  var valid_606186 = header.getOrDefault("X-Amz-Date")
  valid_606186 = validateParameter(valid_606186, JString, required = false,
                                 default = nil)
  if valid_606186 != nil:
    section.add "X-Amz-Date", valid_606186
  var valid_606187 = header.getOrDefault("X-Amz-Credential")
  valid_606187 = validateParameter(valid_606187, JString, required = false,
                                 default = nil)
  if valid_606187 != nil:
    section.add "X-Amz-Credential", valid_606187
  var valid_606188 = header.getOrDefault("X-Amz-Security-Token")
  valid_606188 = validateParameter(valid_606188, JString, required = false,
                                 default = nil)
  if valid_606188 != nil:
    section.add "X-Amz-Security-Token", valid_606188
  var valid_606189 = header.getOrDefault("X-Amz-Algorithm")
  valid_606189 = validateParameter(valid_606189, JString, required = false,
                                 default = nil)
  if valid_606189 != nil:
    section.add "X-Amz-Algorithm", valid_606189
  assert header != nil, "header argument is necessary due to required `x-amz-sso_bearer_token` field"
  var valid_606190 = header.getOrDefault("x-amz-sso_bearer_token")
  valid_606190 = validateParameter(valid_606190, JString, required = true,
                                 default = nil)
  if valid_606190 != nil:
    section.add "x-amz-sso_bearer_token", valid_606190
  var valid_606191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606191 = validateParameter(valid_606191, JString, required = false,
                                 default = nil)
  if valid_606191 != nil:
    section.add "X-Amz-SignedHeaders", valid_606191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606192: Call_ListAccountRoles_606176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all roles that are assigned to the user for a given AWS account.
  ## 
  let valid = call_606192.validator(path, query, header, formData, body)
  let scheme = call_606192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606192.url(scheme.get, call_606192.host, call_606192.base,
                         call_606192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606192, url, valid)

var listAccountRoles* = Call_ListAccountRoles_606176(name: "listAccountRoles",
    meth: HttpMethod.HttpGet, host: "portal.sso.amazonaws.com",
    route: "/assignment/roles#x-amz-sso_bearer_token&account_id",
    validator: validate_ListAccountRoles_606177, base: "/",
    url: url_ListAccountRoles_606178, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccounts_606195 = ref object of OpenApiRestCall_605580
proc url_ListAccounts_606197(protocol: Scheme; host: string; base: string;
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

proc validate_ListAccounts_606196(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all AWS accounts assigned to the user. These AWS accounts are assigned by the administrator of the account. For more information, see <a href="https://docs.aws.amazon.com/singlesignon/latest/userguide/useraccess.html#assignusers">Assign User Access</a> in the <i>AWS SSO User Guide</i>. This operation returns a paginated response.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   next_token: JString
  ##             : (Optional) When requesting subsequent pages, this is the page token from the previous response output.
  ##   max_result: JInt
  ##             : This is the number of items clients can request per page.
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606198 = query.getOrDefault("nextToken")
  valid_606198 = validateParameter(valid_606198, JString, required = false,
                                 default = nil)
  if valid_606198 != nil:
    section.add "nextToken", valid_606198
  var valid_606199 = query.getOrDefault("next_token")
  valid_606199 = validateParameter(valid_606199, JString, required = false,
                                 default = nil)
  if valid_606199 != nil:
    section.add "next_token", valid_606199
  var valid_606200 = query.getOrDefault("max_result")
  valid_606200 = validateParameter(valid_606200, JInt, required = false, default = nil)
  if valid_606200 != nil:
    section.add "max_result", valid_606200
  var valid_606201 = query.getOrDefault("maxResults")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "maxResults", valid_606201
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   x-amz-sso_bearer_token: JString (required)
  ##                         : The token issued by the <code>CreateToken</code> API call. For more information, see <a 
  ## href="https://docs.aws.amazon.com/singlesignon/latest/OIDCAPIReference/API_CreateToken.html">CreateToken</a> in the <i>AWS SSO OIDC API Reference Guide</i>.
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606202 = header.getOrDefault("X-Amz-Signature")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Signature", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Content-Sha256", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Date")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Date", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Credential")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Credential", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Security-Token")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Security-Token", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-Algorithm")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Algorithm", valid_606207
  assert header != nil, "header argument is necessary due to required `x-amz-sso_bearer_token` field"
  var valid_606208 = header.getOrDefault("x-amz-sso_bearer_token")
  valid_606208 = validateParameter(valid_606208, JString, required = true,
                                 default = nil)
  if valid_606208 != nil:
    section.add "x-amz-sso_bearer_token", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-SignedHeaders", valid_606209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606210: Call_ListAccounts_606195; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all AWS accounts assigned to the user. These AWS accounts are assigned by the administrator of the account. For more information, see <a href="https://docs.aws.amazon.com/singlesignon/latest/userguide/useraccess.html#assignusers">Assign User Access</a> in the <i>AWS SSO User Guide</i>. This operation returns a paginated response.
  ## 
  let valid = call_606210.validator(path, query, header, formData, body)
  let scheme = call_606210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606210.url(scheme.get, call_606210.host, call_606210.base,
                         call_606210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606210, url, valid)

var listAccounts* = Call_ListAccounts_606195(name: "listAccounts",
    meth: HttpMethod.HttpGet, host: "portal.sso.amazonaws.com",
    route: "/assignment/accounts#x-amz-sso_bearer_token",
    validator: validate_ListAccounts_606196, base: "/", url: url_ListAccounts_606197,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_Logout_606213 = ref object of OpenApiRestCall_605580
proc url_Logout_606215(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_Logout_606214(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the client- and server-side session that is associated with the user.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   x-amz-sso_bearer_token: JString (required)
  ##                         : The token issued by the <code>CreateToken</code> API call. For more information, see <a 
  ## href="https://docs.aws.amazon.com/singlesignon/latest/OIDCAPIReference/API_CreateToken.html">CreateToken</a> in the <i>AWS SSO OIDC API Reference Guide</i>.
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606216 = header.getOrDefault("X-Amz-Signature")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Signature", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Content-Sha256", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Date")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Date", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Credential")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Credential", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Security-Token")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Security-Token", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-Algorithm")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-Algorithm", valid_606221
  assert header != nil, "header argument is necessary due to required `x-amz-sso_bearer_token` field"
  var valid_606222 = header.getOrDefault("x-amz-sso_bearer_token")
  valid_606222 = validateParameter(valid_606222, JString, required = true,
                                 default = nil)
  if valid_606222 != nil:
    section.add "x-amz-sso_bearer_token", valid_606222
  var valid_606223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-SignedHeaders", valid_606223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606224: Call_Logout_606213; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the client- and server-side session that is associated with the user.
  ## 
  let valid = call_606224.validator(path, query, header, formData, body)
  let scheme = call_606224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606224.url(scheme.get, call_606224.host, call_606224.base,
                         call_606224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606224, url, valid)

proc call*(call_606225: Call_Logout_606213): Recallable =
  ## logout
  ## Removes the client- and server-side session that is associated with the user.
  result = call_606225.call(nil, nil, nil, nil, nil)

var logout* = Call_Logout_606213(name: "logout", meth: HttpMethod.HttpPost,
                              host: "portal.sso.amazonaws.com",
                              route: "/logout#x-amz-sso_bearer_token",
                              validator: validate_Logout_606214, base: "/",
                              url: url_Logout_606215,
                              schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
