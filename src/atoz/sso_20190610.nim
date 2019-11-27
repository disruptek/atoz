
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

  OpenApiRestCall_599359 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599359](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599359): Option[Scheme] {.used.} =
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
  Call_GetRoleCredentials_599696 = ref object of OpenApiRestCall_599359
proc url_GetRoleCredentials_599698(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRoleCredentials_599697(path: JsonNode; query: JsonNode;
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
  var valid_599810 = query.getOrDefault("role_name")
  valid_599810 = validateParameter(valid_599810, JString, required = true,
                                 default = nil)
  if valid_599810 != nil:
    section.add "role_name", valid_599810
  var valid_599811 = query.getOrDefault("account_id")
  valid_599811 = validateParameter(valid_599811, JString, required = true,
                                 default = nil)
  if valid_599811 != nil:
    section.add "account_id", valid_599811
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   x-amz-sso_bearer_token: JString (required)
  ##                         : The token issued by the <code>CreateToken</code> API call. For more information, see <a 
  ## href="https://docs.aws.amazon.com/singlesignon/latest/OIDCAPIReference/API_CreateToken.html">CreateToken</a> in the <i>AWS SSO OIDC API Reference Guide</i>.
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599812 = header.getOrDefault("X-Amz-Date")
  valid_599812 = validateParameter(valid_599812, JString, required = false,
                                 default = nil)
  if valid_599812 != nil:
    section.add "X-Amz-Date", valid_599812
  var valid_599813 = header.getOrDefault("X-Amz-Security-Token")
  valid_599813 = validateParameter(valid_599813, JString, required = false,
                                 default = nil)
  if valid_599813 != nil:
    section.add "X-Amz-Security-Token", valid_599813
  var valid_599814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599814 = validateParameter(valid_599814, JString, required = false,
                                 default = nil)
  if valid_599814 != nil:
    section.add "X-Amz-Content-Sha256", valid_599814
  var valid_599815 = header.getOrDefault("X-Amz-Algorithm")
  valid_599815 = validateParameter(valid_599815, JString, required = false,
                                 default = nil)
  if valid_599815 != nil:
    section.add "X-Amz-Algorithm", valid_599815
  var valid_599816 = header.getOrDefault("X-Amz-Signature")
  valid_599816 = validateParameter(valid_599816, JString, required = false,
                                 default = nil)
  if valid_599816 != nil:
    section.add "X-Amz-Signature", valid_599816
  var valid_599817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599817 = validateParameter(valid_599817, JString, required = false,
                                 default = nil)
  if valid_599817 != nil:
    section.add "X-Amz-SignedHeaders", valid_599817
  assert header != nil, "header argument is necessary due to required `x-amz-sso_bearer_token` field"
  var valid_599818 = header.getOrDefault("x-amz-sso_bearer_token")
  valid_599818 = validateParameter(valid_599818, JString, required = true,
                                 default = nil)
  if valid_599818 != nil:
    section.add "x-amz-sso_bearer_token", valid_599818
  var valid_599819 = header.getOrDefault("X-Amz-Credential")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "X-Amz-Credential", valid_599819
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599842: Call_GetRoleCredentials_599696; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the STS short-term credentials for a given role name that is assigned to the user.
  ## 
  let valid = call_599842.validator(path, query, header, formData, body)
  let scheme = call_599842.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599842.url(scheme.get, call_599842.host, call_599842.base,
                         call_599842.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599842, url, valid)

proc call*(call_599913: Call_GetRoleCredentials_599696; roleName: string;
          accountId: string): Recallable =
  ## getRoleCredentials
  ## Returns the STS short-term credentials for a given role name that is assigned to the user.
  ##   roleName: string (required)
  ##           : The friendly name of the role that is assigned to the user.
  ##   accountId: string (required)
  ##            : The identifier for the AWS account that is assigned to the user.
  var query_599914 = newJObject()
  add(query_599914, "role_name", newJString(roleName))
  add(query_599914, "account_id", newJString(accountId))
  result = call_599913.call(nil, query_599914, nil, nil, nil)

var getRoleCredentials* = Call_GetRoleCredentials_599696(
    name: "getRoleCredentials", meth: HttpMethod.HttpGet,
    host: "portal.sso.amazonaws.com", route: "/federation/credentials#role_name&account_id&x-amz-sso_bearer_token",
    validator: validate_GetRoleCredentials_599697, base: "/",
    url: url_GetRoleCredentials_599698, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccountRoles_599954 = ref object of OpenApiRestCall_599359
proc url_ListAccountRoles_599956(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAccountRoles_599955(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Lists all roles that are assigned to the user for a given AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   max_result: JInt
  ##             : The number of items that clients can request per page.
  ##   account_id: JString (required)
  ##             : The identifier for the AWS account that is assigned to the user.
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  ##   next_token: JString
  ##             : The page token from the previous response output when you request subsequent pages.
  section = newJObject()
  var valid_599957 = query.getOrDefault("max_result")
  valid_599957 = validateParameter(valid_599957, JInt, required = false, default = nil)
  if valid_599957 != nil:
    section.add "max_result", valid_599957
  assert query != nil,
        "query argument is necessary due to required `account_id` field"
  var valid_599958 = query.getOrDefault("account_id")
  valid_599958 = validateParameter(valid_599958, JString, required = true,
                                 default = nil)
  if valid_599958 != nil:
    section.add "account_id", valid_599958
  var valid_599959 = query.getOrDefault("maxResults")
  valid_599959 = validateParameter(valid_599959, JString, required = false,
                                 default = nil)
  if valid_599959 != nil:
    section.add "maxResults", valid_599959
  var valid_599960 = query.getOrDefault("nextToken")
  valid_599960 = validateParameter(valid_599960, JString, required = false,
                                 default = nil)
  if valid_599960 != nil:
    section.add "nextToken", valid_599960
  var valid_599961 = query.getOrDefault("next_token")
  valid_599961 = validateParameter(valid_599961, JString, required = false,
                                 default = nil)
  if valid_599961 != nil:
    section.add "next_token", valid_599961
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   x-amz-sso_bearer_token: JString (required)
  ##                         : The token issued by the <code>CreateToken</code> API call. For more information, see <a 
  ## href="https://docs.aws.amazon.com/singlesignon/latest/OIDCAPIReference/API_CreateToken.html">CreateToken</a> in the <i>AWS SSO OIDC API Reference Guide</i>.
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599962 = header.getOrDefault("X-Amz-Date")
  valid_599962 = validateParameter(valid_599962, JString, required = false,
                                 default = nil)
  if valid_599962 != nil:
    section.add "X-Amz-Date", valid_599962
  var valid_599963 = header.getOrDefault("X-Amz-Security-Token")
  valid_599963 = validateParameter(valid_599963, JString, required = false,
                                 default = nil)
  if valid_599963 != nil:
    section.add "X-Amz-Security-Token", valid_599963
  var valid_599964 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599964 = validateParameter(valid_599964, JString, required = false,
                                 default = nil)
  if valid_599964 != nil:
    section.add "X-Amz-Content-Sha256", valid_599964
  var valid_599965 = header.getOrDefault("X-Amz-Algorithm")
  valid_599965 = validateParameter(valid_599965, JString, required = false,
                                 default = nil)
  if valid_599965 != nil:
    section.add "X-Amz-Algorithm", valid_599965
  var valid_599966 = header.getOrDefault("X-Amz-Signature")
  valid_599966 = validateParameter(valid_599966, JString, required = false,
                                 default = nil)
  if valid_599966 != nil:
    section.add "X-Amz-Signature", valid_599966
  var valid_599967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599967 = validateParameter(valid_599967, JString, required = false,
                                 default = nil)
  if valid_599967 != nil:
    section.add "X-Amz-SignedHeaders", valid_599967
  assert header != nil, "header argument is necessary due to required `x-amz-sso_bearer_token` field"
  var valid_599968 = header.getOrDefault("x-amz-sso_bearer_token")
  valid_599968 = validateParameter(valid_599968, JString, required = true,
                                 default = nil)
  if valid_599968 != nil:
    section.add "x-amz-sso_bearer_token", valid_599968
  var valid_599969 = header.getOrDefault("X-Amz-Credential")
  valid_599969 = validateParameter(valid_599969, JString, required = false,
                                 default = nil)
  if valid_599969 != nil:
    section.add "X-Amz-Credential", valid_599969
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599970: Call_ListAccountRoles_599954; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all roles that are assigned to the user for a given AWS account.
  ## 
  let valid = call_599970.validator(path, query, header, formData, body)
  let scheme = call_599970.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599970.url(scheme.get, call_599970.host, call_599970.base,
                         call_599970.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599970, url, valid)

var listAccountRoles* = Call_ListAccountRoles_599954(name: "listAccountRoles",
    meth: HttpMethod.HttpGet, host: "portal.sso.amazonaws.com",
    route: "/assignment/roles#x-amz-sso_bearer_token&account_id",
    validator: validate_ListAccountRoles_599955, base: "/",
    url: url_ListAccountRoles_599956, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccounts_599973 = ref object of OpenApiRestCall_599359
proc url_ListAccounts_599975(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAccounts_599974(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all AWS accounts assigned to the user. These AWS accounts are assigned by the administrator of the account. For more information, see <a href="https://docs.aws.amazon.com/singlesignon/latest/userguide/useraccess.html#assignusers">Assign User Access</a> in the <i>AWS SSO User Guide</i>. This operation returns a paginated response.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   max_result: JInt
  ##             : This is the number of items clients can request per page.
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  ##   next_token: JString
  ##             : (Optional) When requesting subsequent pages, this is the page token from the previous response output.
  section = newJObject()
  var valid_599976 = query.getOrDefault("max_result")
  valid_599976 = validateParameter(valid_599976, JInt, required = false, default = nil)
  if valid_599976 != nil:
    section.add "max_result", valid_599976
  var valid_599977 = query.getOrDefault("maxResults")
  valid_599977 = validateParameter(valid_599977, JString, required = false,
                                 default = nil)
  if valid_599977 != nil:
    section.add "maxResults", valid_599977
  var valid_599978 = query.getOrDefault("nextToken")
  valid_599978 = validateParameter(valid_599978, JString, required = false,
                                 default = nil)
  if valid_599978 != nil:
    section.add "nextToken", valid_599978
  var valid_599979 = query.getOrDefault("next_token")
  valid_599979 = validateParameter(valid_599979, JString, required = false,
                                 default = nil)
  if valid_599979 != nil:
    section.add "next_token", valid_599979
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   x-amz-sso_bearer_token: JString (required)
  ##                         : The token issued by the <code>CreateToken</code> API call. For more information, see <a 
  ## href="https://docs.aws.amazon.com/singlesignon/latest/OIDCAPIReference/API_CreateToken.html">CreateToken</a> in the <i>AWS SSO OIDC API Reference Guide</i>.
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599980 = header.getOrDefault("X-Amz-Date")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Date", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Security-Token")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Security-Token", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Content-Sha256", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-Algorithm")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Algorithm", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Signature")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Signature", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-SignedHeaders", valid_599985
  assert header != nil, "header argument is necessary due to required `x-amz-sso_bearer_token` field"
  var valid_599986 = header.getOrDefault("x-amz-sso_bearer_token")
  valid_599986 = validateParameter(valid_599986, JString, required = true,
                                 default = nil)
  if valid_599986 != nil:
    section.add "x-amz-sso_bearer_token", valid_599986
  var valid_599987 = header.getOrDefault("X-Amz-Credential")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-Credential", valid_599987
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599988: Call_ListAccounts_599973; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all AWS accounts assigned to the user. These AWS accounts are assigned by the administrator of the account. For more information, see <a href="https://docs.aws.amazon.com/singlesignon/latest/userguide/useraccess.html#assignusers">Assign User Access</a> in the <i>AWS SSO User Guide</i>. This operation returns a paginated response.
  ## 
  let valid = call_599988.validator(path, query, header, formData, body)
  let scheme = call_599988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599988.url(scheme.get, call_599988.host, call_599988.base,
                         call_599988.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599988, url, valid)

var listAccounts* = Call_ListAccounts_599973(name: "listAccounts",
    meth: HttpMethod.HttpGet, host: "portal.sso.amazonaws.com",
    route: "/assignment/accounts#x-amz-sso_bearer_token",
    validator: validate_ListAccounts_599974, base: "/", url: url_ListAccounts_599975,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_Logout_599991 = ref object of OpenApiRestCall_599359
proc url_Logout_599993(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Logout_599992(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   x-amz-sso_bearer_token: JString (required)
  ##                         : The token issued by the <code>CreateToken</code> API call. For more information, see <a 
  ## href="https://docs.aws.amazon.com/singlesignon/latest/OIDCAPIReference/API_CreateToken.html">CreateToken</a> in the <i>AWS SSO OIDC API Reference Guide</i>.
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599994 = header.getOrDefault("X-Amz-Date")
  valid_599994 = validateParameter(valid_599994, JString, required = false,
                                 default = nil)
  if valid_599994 != nil:
    section.add "X-Amz-Date", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Security-Token")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Security-Token", valid_599995
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
  assert header != nil, "header argument is necessary due to required `x-amz-sso_bearer_token` field"
  var valid_600000 = header.getOrDefault("x-amz-sso_bearer_token")
  valid_600000 = validateParameter(valid_600000, JString, required = true,
                                 default = nil)
  if valid_600000 != nil:
    section.add "x-amz-sso_bearer_token", valid_600000
  var valid_600001 = header.getOrDefault("X-Amz-Credential")
  valid_600001 = validateParameter(valid_600001, JString, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "X-Amz-Credential", valid_600001
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600002: Call_Logout_599991; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the client- and server-side session that is associated with the user.
  ## 
  let valid = call_600002.validator(path, query, header, formData, body)
  let scheme = call_600002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600002.url(scheme.get, call_600002.host, call_600002.base,
                         call_600002.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600002, url, valid)

proc call*(call_600003: Call_Logout_599991): Recallable =
  ## logout
  ## Removes the client- and server-side session that is associated with the user.
  result = call_600003.call(nil, nil, nil, nil, nil)

var logout* = Call_Logout_599991(name: "logout", meth: HttpMethod.HttpPost,
                              host: "portal.sso.amazonaws.com",
                              route: "/logout#x-amz-sso_bearer_token",
                              validator: validate_Logout_599992, base: "/",
                              url: url_Logout_599993,
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
