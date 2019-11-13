
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

  OpenApiRestCall_593380 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593380](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593380): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_GetRoleCredentials_593718 = ref object of OpenApiRestCall_593380
proc url_GetRoleCredentials_593720(protocol: Scheme; host: string; base: string;
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

proc validate_GetRoleCredentials_593719(path: JsonNode; query: JsonNode;
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
  var valid_593832 = query.getOrDefault("role_name")
  valid_593832 = validateParameter(valid_593832, JString, required = true,
                                 default = nil)
  if valid_593832 != nil:
    section.add "role_name", valid_593832
  var valid_593833 = query.getOrDefault("account_id")
  valid_593833 = validateParameter(valid_593833, JString, required = true,
                                 default = nil)
  if valid_593833 != nil:
    section.add "account_id", valid_593833
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
  var valid_593834 = header.getOrDefault("X-Amz-Signature")
  valid_593834 = validateParameter(valid_593834, JString, required = false,
                                 default = nil)
  if valid_593834 != nil:
    section.add "X-Amz-Signature", valid_593834
  var valid_593835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593835 = validateParameter(valid_593835, JString, required = false,
                                 default = nil)
  if valid_593835 != nil:
    section.add "X-Amz-Content-Sha256", valid_593835
  var valid_593836 = header.getOrDefault("X-Amz-Date")
  valid_593836 = validateParameter(valid_593836, JString, required = false,
                                 default = nil)
  if valid_593836 != nil:
    section.add "X-Amz-Date", valid_593836
  var valid_593837 = header.getOrDefault("X-Amz-Credential")
  valid_593837 = validateParameter(valid_593837, JString, required = false,
                                 default = nil)
  if valid_593837 != nil:
    section.add "X-Amz-Credential", valid_593837
  var valid_593838 = header.getOrDefault("X-Amz-Security-Token")
  valid_593838 = validateParameter(valid_593838, JString, required = false,
                                 default = nil)
  if valid_593838 != nil:
    section.add "X-Amz-Security-Token", valid_593838
  var valid_593839 = header.getOrDefault("X-Amz-Algorithm")
  valid_593839 = validateParameter(valid_593839, JString, required = false,
                                 default = nil)
  if valid_593839 != nil:
    section.add "X-Amz-Algorithm", valid_593839
  assert header != nil, "header argument is necessary due to required `x-amz-sso_bearer_token` field"
  var valid_593840 = header.getOrDefault("x-amz-sso_bearer_token")
  valid_593840 = validateParameter(valid_593840, JString, required = true,
                                 default = nil)
  if valid_593840 != nil:
    section.add "x-amz-sso_bearer_token", valid_593840
  var valid_593841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593841 = validateParameter(valid_593841, JString, required = false,
                                 default = nil)
  if valid_593841 != nil:
    section.add "X-Amz-SignedHeaders", valid_593841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593864: Call_GetRoleCredentials_593718; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the STS short-term credentials for a given role name that is assigned to the user.
  ## 
  let valid = call_593864.validator(path, query, header, formData, body)
  let scheme = call_593864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593864.url(scheme.get, call_593864.host, call_593864.base,
                         call_593864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593864, url, valid)

proc call*(call_593935: Call_GetRoleCredentials_593718; roleName: string;
          accountId: string): Recallable =
  ## getRoleCredentials
  ## Returns the STS short-term credentials for a given role name that is assigned to the user.
  ##   roleName: string (required)
  ##           : The friendly name of the role that is assigned to the user.
  ##   accountId: string (required)
  ##            : The identifier for the AWS account that is assigned to the user.
  var query_593936 = newJObject()
  add(query_593936, "role_name", newJString(roleName))
  add(query_593936, "account_id", newJString(accountId))
  result = call_593935.call(nil, query_593936, nil, nil, nil)

var getRoleCredentials* = Call_GetRoleCredentials_593718(
    name: "getRoleCredentials", meth: HttpMethod.HttpGet,
    host: "portal.sso.amazonaws.com", route: "/federation/credentials#role_name&account_id&x-amz-sso_bearer_token",
    validator: validate_GetRoleCredentials_593719, base: "/",
    url: url_GetRoleCredentials_593720, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccountRoles_593976 = ref object of OpenApiRestCall_593380
proc url_ListAccountRoles_593978(protocol: Scheme; host: string; base: string;
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

proc validate_ListAccountRoles_593977(path: JsonNode; query: JsonNode;
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
  var valid_593979 = query.getOrDefault("nextToken")
  valid_593979 = validateParameter(valid_593979, JString, required = false,
                                 default = nil)
  if valid_593979 != nil:
    section.add "nextToken", valid_593979
  var valid_593980 = query.getOrDefault("next_token")
  valid_593980 = validateParameter(valid_593980, JString, required = false,
                                 default = nil)
  if valid_593980 != nil:
    section.add "next_token", valid_593980
  assert query != nil,
        "query argument is necessary due to required `account_id` field"
  var valid_593981 = query.getOrDefault("account_id")
  valid_593981 = validateParameter(valid_593981, JString, required = true,
                                 default = nil)
  if valid_593981 != nil:
    section.add "account_id", valid_593981
  var valid_593982 = query.getOrDefault("max_result")
  valid_593982 = validateParameter(valid_593982, JInt, required = false, default = nil)
  if valid_593982 != nil:
    section.add "max_result", valid_593982
  var valid_593983 = query.getOrDefault("maxResults")
  valid_593983 = validateParameter(valid_593983, JString, required = false,
                                 default = nil)
  if valid_593983 != nil:
    section.add "maxResults", valid_593983
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
  var valid_593984 = header.getOrDefault("X-Amz-Signature")
  valid_593984 = validateParameter(valid_593984, JString, required = false,
                                 default = nil)
  if valid_593984 != nil:
    section.add "X-Amz-Signature", valid_593984
  var valid_593985 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593985 = validateParameter(valid_593985, JString, required = false,
                                 default = nil)
  if valid_593985 != nil:
    section.add "X-Amz-Content-Sha256", valid_593985
  var valid_593986 = header.getOrDefault("X-Amz-Date")
  valid_593986 = validateParameter(valid_593986, JString, required = false,
                                 default = nil)
  if valid_593986 != nil:
    section.add "X-Amz-Date", valid_593986
  var valid_593987 = header.getOrDefault("X-Amz-Credential")
  valid_593987 = validateParameter(valid_593987, JString, required = false,
                                 default = nil)
  if valid_593987 != nil:
    section.add "X-Amz-Credential", valid_593987
  var valid_593988 = header.getOrDefault("X-Amz-Security-Token")
  valid_593988 = validateParameter(valid_593988, JString, required = false,
                                 default = nil)
  if valid_593988 != nil:
    section.add "X-Amz-Security-Token", valid_593988
  var valid_593989 = header.getOrDefault("X-Amz-Algorithm")
  valid_593989 = validateParameter(valid_593989, JString, required = false,
                                 default = nil)
  if valid_593989 != nil:
    section.add "X-Amz-Algorithm", valid_593989
  assert header != nil, "header argument is necessary due to required `x-amz-sso_bearer_token` field"
  var valid_593990 = header.getOrDefault("x-amz-sso_bearer_token")
  valid_593990 = validateParameter(valid_593990, JString, required = true,
                                 default = nil)
  if valid_593990 != nil:
    section.add "x-amz-sso_bearer_token", valid_593990
  var valid_593991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593991 = validateParameter(valid_593991, JString, required = false,
                                 default = nil)
  if valid_593991 != nil:
    section.add "X-Amz-SignedHeaders", valid_593991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593992: Call_ListAccountRoles_593976; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all roles that are assigned to the user for a given AWS account.
  ## 
  let valid = call_593992.validator(path, query, header, formData, body)
  let scheme = call_593992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593992.url(scheme.get, call_593992.host, call_593992.base,
                         call_593992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593992, url, valid)

var listAccountRoles* = Call_ListAccountRoles_593976(name: "listAccountRoles",
    meth: HttpMethod.HttpGet, host: "portal.sso.amazonaws.com",
    route: "/assignment/roles#x-amz-sso_bearer_token&account_id",
    validator: validate_ListAccountRoles_593977, base: "/",
    url: url_ListAccountRoles_593978, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccounts_593995 = ref object of OpenApiRestCall_593380
proc url_ListAccounts_593997(protocol: Scheme; host: string; base: string;
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

proc validate_ListAccounts_593996(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593998 = query.getOrDefault("nextToken")
  valid_593998 = validateParameter(valid_593998, JString, required = false,
                                 default = nil)
  if valid_593998 != nil:
    section.add "nextToken", valid_593998
  var valid_593999 = query.getOrDefault("next_token")
  valid_593999 = validateParameter(valid_593999, JString, required = false,
                                 default = nil)
  if valid_593999 != nil:
    section.add "next_token", valid_593999
  var valid_594000 = query.getOrDefault("max_result")
  valid_594000 = validateParameter(valid_594000, JInt, required = false, default = nil)
  if valid_594000 != nil:
    section.add "max_result", valid_594000
  var valid_594001 = query.getOrDefault("maxResults")
  valid_594001 = validateParameter(valid_594001, JString, required = false,
                                 default = nil)
  if valid_594001 != nil:
    section.add "maxResults", valid_594001
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
  var valid_594002 = header.getOrDefault("X-Amz-Signature")
  valid_594002 = validateParameter(valid_594002, JString, required = false,
                                 default = nil)
  if valid_594002 != nil:
    section.add "X-Amz-Signature", valid_594002
  var valid_594003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594003 = validateParameter(valid_594003, JString, required = false,
                                 default = nil)
  if valid_594003 != nil:
    section.add "X-Amz-Content-Sha256", valid_594003
  var valid_594004 = header.getOrDefault("X-Amz-Date")
  valid_594004 = validateParameter(valid_594004, JString, required = false,
                                 default = nil)
  if valid_594004 != nil:
    section.add "X-Amz-Date", valid_594004
  var valid_594005 = header.getOrDefault("X-Amz-Credential")
  valid_594005 = validateParameter(valid_594005, JString, required = false,
                                 default = nil)
  if valid_594005 != nil:
    section.add "X-Amz-Credential", valid_594005
  var valid_594006 = header.getOrDefault("X-Amz-Security-Token")
  valid_594006 = validateParameter(valid_594006, JString, required = false,
                                 default = nil)
  if valid_594006 != nil:
    section.add "X-Amz-Security-Token", valid_594006
  var valid_594007 = header.getOrDefault("X-Amz-Algorithm")
  valid_594007 = validateParameter(valid_594007, JString, required = false,
                                 default = nil)
  if valid_594007 != nil:
    section.add "X-Amz-Algorithm", valid_594007
  assert header != nil, "header argument is necessary due to required `x-amz-sso_bearer_token` field"
  var valid_594008 = header.getOrDefault("x-amz-sso_bearer_token")
  valid_594008 = validateParameter(valid_594008, JString, required = true,
                                 default = nil)
  if valid_594008 != nil:
    section.add "x-amz-sso_bearer_token", valid_594008
  var valid_594009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594009 = validateParameter(valid_594009, JString, required = false,
                                 default = nil)
  if valid_594009 != nil:
    section.add "X-Amz-SignedHeaders", valid_594009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594010: Call_ListAccounts_593995; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all AWS accounts assigned to the user. These AWS accounts are assigned by the administrator of the account. For more information, see <a href="https://docs.aws.amazon.com/singlesignon/latest/userguide/useraccess.html#assignusers">Assign User Access</a> in the <i>AWS SSO User Guide</i>. This operation returns a paginated response.
  ## 
  let valid = call_594010.validator(path, query, header, formData, body)
  let scheme = call_594010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594010.url(scheme.get, call_594010.host, call_594010.base,
                         call_594010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594010, url, valid)

var listAccounts* = Call_ListAccounts_593995(name: "listAccounts",
    meth: HttpMethod.HttpGet, host: "portal.sso.amazonaws.com",
    route: "/assignment/accounts#x-amz-sso_bearer_token",
    validator: validate_ListAccounts_593996, base: "/", url: url_ListAccounts_593997,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_Logout_594013 = ref object of OpenApiRestCall_593380
proc url_Logout_594015(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_Logout_594014(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594016 = header.getOrDefault("X-Amz-Signature")
  valid_594016 = validateParameter(valid_594016, JString, required = false,
                                 default = nil)
  if valid_594016 != nil:
    section.add "X-Amz-Signature", valid_594016
  var valid_594017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594017 = validateParameter(valid_594017, JString, required = false,
                                 default = nil)
  if valid_594017 != nil:
    section.add "X-Amz-Content-Sha256", valid_594017
  var valid_594018 = header.getOrDefault("X-Amz-Date")
  valid_594018 = validateParameter(valid_594018, JString, required = false,
                                 default = nil)
  if valid_594018 != nil:
    section.add "X-Amz-Date", valid_594018
  var valid_594019 = header.getOrDefault("X-Amz-Credential")
  valid_594019 = validateParameter(valid_594019, JString, required = false,
                                 default = nil)
  if valid_594019 != nil:
    section.add "X-Amz-Credential", valid_594019
  var valid_594020 = header.getOrDefault("X-Amz-Security-Token")
  valid_594020 = validateParameter(valid_594020, JString, required = false,
                                 default = nil)
  if valid_594020 != nil:
    section.add "X-Amz-Security-Token", valid_594020
  var valid_594021 = header.getOrDefault("X-Amz-Algorithm")
  valid_594021 = validateParameter(valid_594021, JString, required = false,
                                 default = nil)
  if valid_594021 != nil:
    section.add "X-Amz-Algorithm", valid_594021
  assert header != nil, "header argument is necessary due to required `x-amz-sso_bearer_token` field"
  var valid_594022 = header.getOrDefault("x-amz-sso_bearer_token")
  valid_594022 = validateParameter(valid_594022, JString, required = true,
                                 default = nil)
  if valid_594022 != nil:
    section.add "x-amz-sso_bearer_token", valid_594022
  var valid_594023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594023 = validateParameter(valid_594023, JString, required = false,
                                 default = nil)
  if valid_594023 != nil:
    section.add "X-Amz-SignedHeaders", valid_594023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594024: Call_Logout_594013; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the client- and server-side session that is associated with the user.
  ## 
  let valid = call_594024.validator(path, query, header, formData, body)
  let scheme = call_594024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594024.url(scheme.get, call_594024.host, call_594024.base,
                         call_594024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594024, url, valid)

proc call*(call_594025: Call_Logout_594013): Recallable =
  ## logout
  ## Removes the client- and server-side session that is associated with the user.
  result = call_594025.call(nil, nil, nil, nil, nil)

var logout* = Call_Logout_594013(name: "logout", meth: HttpMethod.HttpPost,
                              host: "portal.sso.amazonaws.com",
                              route: "/logout#x-amz-sso_bearer_token",
                              validator: validate_Logout_594014, base: "/",
                              url: url_Logout_594015,
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
