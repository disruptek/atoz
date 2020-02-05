
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

  OpenApiRestCall_612649 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612649](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612649): Option[Scheme] {.used.} =
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
  Call_GetRoleCredentials_612987 = ref object of OpenApiRestCall_612649
proc url_GetRoleCredentials_612989(protocol: Scheme; host: string; base: string;
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

proc validate_GetRoleCredentials_612988(path: JsonNode; query: JsonNode;
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
  var valid_613101 = query.getOrDefault("role_name")
  valid_613101 = validateParameter(valid_613101, JString, required = true,
                                 default = nil)
  if valid_613101 != nil:
    section.add "role_name", valid_613101
  var valid_613102 = query.getOrDefault("account_id")
  valid_613102 = validateParameter(valid_613102, JString, required = true,
                                 default = nil)
  if valid_613102 != nil:
    section.add "account_id", valid_613102
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
  var valid_613103 = header.getOrDefault("X-Amz-Signature")
  valid_613103 = validateParameter(valid_613103, JString, required = false,
                                 default = nil)
  if valid_613103 != nil:
    section.add "X-Amz-Signature", valid_613103
  var valid_613104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613104 = validateParameter(valid_613104, JString, required = false,
                                 default = nil)
  if valid_613104 != nil:
    section.add "X-Amz-Content-Sha256", valid_613104
  var valid_613105 = header.getOrDefault("X-Amz-Date")
  valid_613105 = validateParameter(valid_613105, JString, required = false,
                                 default = nil)
  if valid_613105 != nil:
    section.add "X-Amz-Date", valid_613105
  var valid_613106 = header.getOrDefault("X-Amz-Credential")
  valid_613106 = validateParameter(valid_613106, JString, required = false,
                                 default = nil)
  if valid_613106 != nil:
    section.add "X-Amz-Credential", valid_613106
  var valid_613107 = header.getOrDefault("X-Amz-Security-Token")
  valid_613107 = validateParameter(valid_613107, JString, required = false,
                                 default = nil)
  if valid_613107 != nil:
    section.add "X-Amz-Security-Token", valid_613107
  var valid_613108 = header.getOrDefault("X-Amz-Algorithm")
  valid_613108 = validateParameter(valid_613108, JString, required = false,
                                 default = nil)
  if valid_613108 != nil:
    section.add "X-Amz-Algorithm", valid_613108
  assert header != nil, "header argument is necessary due to required `x-amz-sso_bearer_token` field"
  var valid_613109 = header.getOrDefault("x-amz-sso_bearer_token")
  valid_613109 = validateParameter(valid_613109, JString, required = true,
                                 default = nil)
  if valid_613109 != nil:
    section.add "x-amz-sso_bearer_token", valid_613109
  var valid_613110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613110 = validateParameter(valid_613110, JString, required = false,
                                 default = nil)
  if valid_613110 != nil:
    section.add "X-Amz-SignedHeaders", valid_613110
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613133: Call_GetRoleCredentials_612987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the STS short-term credentials for a given role name that is assigned to the user.
  ## 
  let valid = call_613133.validator(path, query, header, formData, body)
  let scheme = call_613133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613133.url(scheme.get, call_613133.host, call_613133.base,
                         call_613133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613133, url, valid)

proc call*(call_613204: Call_GetRoleCredentials_612987; roleName: string;
          accountId: string): Recallable =
  ## getRoleCredentials
  ## Returns the STS short-term credentials for a given role name that is assigned to the user.
  ##   roleName: string (required)
  ##           : The friendly name of the role that is assigned to the user.
  ##   accountId: string (required)
  ##            : The identifier for the AWS account that is assigned to the user.
  var query_613205 = newJObject()
  add(query_613205, "role_name", newJString(roleName))
  add(query_613205, "account_id", newJString(accountId))
  result = call_613204.call(nil, query_613205, nil, nil, nil)

var getRoleCredentials* = Call_GetRoleCredentials_612987(
    name: "getRoleCredentials", meth: HttpMethod.HttpGet,
    host: "portal.sso.amazonaws.com", route: "/federation/credentials#role_name&account_id&x-amz-sso_bearer_token",
    validator: validate_GetRoleCredentials_612988, base: "/",
    url: url_GetRoleCredentials_612989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccountRoles_613245 = ref object of OpenApiRestCall_612649
proc url_ListAccountRoles_613247(protocol: Scheme; host: string; base: string;
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

proc validate_ListAccountRoles_613246(path: JsonNode; query: JsonNode;
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
  var valid_613248 = query.getOrDefault("nextToken")
  valid_613248 = validateParameter(valid_613248, JString, required = false,
                                 default = nil)
  if valid_613248 != nil:
    section.add "nextToken", valid_613248
  var valid_613249 = query.getOrDefault("next_token")
  valid_613249 = validateParameter(valid_613249, JString, required = false,
                                 default = nil)
  if valid_613249 != nil:
    section.add "next_token", valid_613249
  assert query != nil,
        "query argument is necessary due to required `account_id` field"
  var valid_613250 = query.getOrDefault("account_id")
  valid_613250 = validateParameter(valid_613250, JString, required = true,
                                 default = nil)
  if valid_613250 != nil:
    section.add "account_id", valid_613250
  var valid_613251 = query.getOrDefault("max_result")
  valid_613251 = validateParameter(valid_613251, JInt, required = false, default = nil)
  if valid_613251 != nil:
    section.add "max_result", valid_613251
  var valid_613252 = query.getOrDefault("maxResults")
  valid_613252 = validateParameter(valid_613252, JString, required = false,
                                 default = nil)
  if valid_613252 != nil:
    section.add "maxResults", valid_613252
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
  var valid_613253 = header.getOrDefault("X-Amz-Signature")
  valid_613253 = validateParameter(valid_613253, JString, required = false,
                                 default = nil)
  if valid_613253 != nil:
    section.add "X-Amz-Signature", valid_613253
  var valid_613254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613254 = validateParameter(valid_613254, JString, required = false,
                                 default = nil)
  if valid_613254 != nil:
    section.add "X-Amz-Content-Sha256", valid_613254
  var valid_613255 = header.getOrDefault("X-Amz-Date")
  valid_613255 = validateParameter(valid_613255, JString, required = false,
                                 default = nil)
  if valid_613255 != nil:
    section.add "X-Amz-Date", valid_613255
  var valid_613256 = header.getOrDefault("X-Amz-Credential")
  valid_613256 = validateParameter(valid_613256, JString, required = false,
                                 default = nil)
  if valid_613256 != nil:
    section.add "X-Amz-Credential", valid_613256
  var valid_613257 = header.getOrDefault("X-Amz-Security-Token")
  valid_613257 = validateParameter(valid_613257, JString, required = false,
                                 default = nil)
  if valid_613257 != nil:
    section.add "X-Amz-Security-Token", valid_613257
  var valid_613258 = header.getOrDefault("X-Amz-Algorithm")
  valid_613258 = validateParameter(valid_613258, JString, required = false,
                                 default = nil)
  if valid_613258 != nil:
    section.add "X-Amz-Algorithm", valid_613258
  assert header != nil, "header argument is necessary due to required `x-amz-sso_bearer_token` field"
  var valid_613259 = header.getOrDefault("x-amz-sso_bearer_token")
  valid_613259 = validateParameter(valid_613259, JString, required = true,
                                 default = nil)
  if valid_613259 != nil:
    section.add "x-amz-sso_bearer_token", valid_613259
  var valid_613260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613260 = validateParameter(valid_613260, JString, required = false,
                                 default = nil)
  if valid_613260 != nil:
    section.add "X-Amz-SignedHeaders", valid_613260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613261: Call_ListAccountRoles_613245; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all roles that are assigned to the user for a given AWS account.
  ## 
  let valid = call_613261.validator(path, query, header, formData, body)
  let scheme = call_613261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613261.url(scheme.get, call_613261.host, call_613261.base,
                         call_613261.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613261, url, valid)

var listAccountRoles* = Call_ListAccountRoles_613245(name: "listAccountRoles",
    meth: HttpMethod.HttpGet, host: "portal.sso.amazonaws.com",
    route: "/assignment/roles#x-amz-sso_bearer_token&account_id",
    validator: validate_ListAccountRoles_613246, base: "/",
    url: url_ListAccountRoles_613247, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccounts_613264 = ref object of OpenApiRestCall_612649
proc url_ListAccounts_613266(protocol: Scheme; host: string; base: string;
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

proc validate_ListAccounts_613265(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613267 = query.getOrDefault("nextToken")
  valid_613267 = validateParameter(valid_613267, JString, required = false,
                                 default = nil)
  if valid_613267 != nil:
    section.add "nextToken", valid_613267
  var valid_613268 = query.getOrDefault("next_token")
  valid_613268 = validateParameter(valid_613268, JString, required = false,
                                 default = nil)
  if valid_613268 != nil:
    section.add "next_token", valid_613268
  var valid_613269 = query.getOrDefault("max_result")
  valid_613269 = validateParameter(valid_613269, JInt, required = false, default = nil)
  if valid_613269 != nil:
    section.add "max_result", valid_613269
  var valid_613270 = query.getOrDefault("maxResults")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "maxResults", valid_613270
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
  var valid_613271 = header.getOrDefault("X-Amz-Signature")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Signature", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Content-Sha256", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Date")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Date", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Credential")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Credential", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Security-Token")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Security-Token", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Algorithm")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Algorithm", valid_613276
  assert header != nil, "header argument is necessary due to required `x-amz-sso_bearer_token` field"
  var valid_613277 = header.getOrDefault("x-amz-sso_bearer_token")
  valid_613277 = validateParameter(valid_613277, JString, required = true,
                                 default = nil)
  if valid_613277 != nil:
    section.add "x-amz-sso_bearer_token", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-SignedHeaders", valid_613278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613279: Call_ListAccounts_613264; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all AWS accounts assigned to the user. These AWS accounts are assigned by the administrator of the account. For more information, see <a href="https://docs.aws.amazon.com/singlesignon/latest/userguide/useraccess.html#assignusers">Assign User Access</a> in the <i>AWS SSO User Guide</i>. This operation returns a paginated response.
  ## 
  let valid = call_613279.validator(path, query, header, formData, body)
  let scheme = call_613279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613279.url(scheme.get, call_613279.host, call_613279.base,
                         call_613279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613279, url, valid)

var listAccounts* = Call_ListAccounts_613264(name: "listAccounts",
    meth: HttpMethod.HttpGet, host: "portal.sso.amazonaws.com",
    route: "/assignment/accounts#x-amz-sso_bearer_token",
    validator: validate_ListAccounts_613265, base: "/", url: url_ListAccounts_613266,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_Logout_613282 = ref object of OpenApiRestCall_612649
proc url_Logout_613284(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_Logout_613283(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613285 = header.getOrDefault("X-Amz-Signature")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Signature", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Content-Sha256", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Date")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Date", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Credential")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Credential", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Security-Token")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Security-Token", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-Algorithm")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Algorithm", valid_613290
  assert header != nil, "header argument is necessary due to required `x-amz-sso_bearer_token` field"
  var valid_613291 = header.getOrDefault("x-amz-sso_bearer_token")
  valid_613291 = validateParameter(valid_613291, JString, required = true,
                                 default = nil)
  if valid_613291 != nil:
    section.add "x-amz-sso_bearer_token", valid_613291
  var valid_613292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-SignedHeaders", valid_613292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613293: Call_Logout_613282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the client- and server-side session that is associated with the user.
  ## 
  let valid = call_613293.validator(path, query, header, formData, body)
  let scheme = call_613293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613293.url(scheme.get, call_613293.host, call_613293.base,
                         call_613293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613293, url, valid)

proc call*(call_613294: Call_Logout_613282): Recallable =
  ## logout
  ## Removes the client- and server-side session that is associated with the user.
  result = call_613294.call(nil, nil, nil, nil, nil)

var logout* = Call_Logout_613282(name: "logout", meth: HttpMethod.HttpPost,
                              host: "portal.sso.amazonaws.com",
                              route: "/logout#x-amz-sso_bearer_token",
                              validator: validate_Logout_613283, base: "/",
                              url: url_Logout_613284,
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
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
