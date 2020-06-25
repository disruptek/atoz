
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625426): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_GetRoleCredentials_21625770 = ref object of OpenApiRestCall_21625426
proc url_GetRoleCredentials_21625772(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRoleCredentials_21625771(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21625873 = query.getOrDefault("role_name")
  valid_21625873 = validateParameter(valid_21625873, JString, required = true,
                                   default = nil)
  if valid_21625873 != nil:
    section.add "role_name", valid_21625873
  var valid_21625874 = query.getOrDefault("account_id")
  valid_21625874 = validateParameter(valid_21625874, JString, required = true,
                                   default = nil)
  if valid_21625874 != nil:
    section.add "account_id", valid_21625874
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
  var valid_21625875 = header.getOrDefault("X-Amz-Date")
  valid_21625875 = validateParameter(valid_21625875, JString, required = false,
                                   default = nil)
  if valid_21625875 != nil:
    section.add "X-Amz-Date", valid_21625875
  var valid_21625876 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625876 = validateParameter(valid_21625876, JString, required = false,
                                   default = nil)
  if valid_21625876 != nil:
    section.add "X-Amz-Security-Token", valid_21625876
  var valid_21625877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625877 = validateParameter(valid_21625877, JString, required = false,
                                   default = nil)
  if valid_21625877 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625877
  var valid_21625878 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625878 = validateParameter(valid_21625878, JString, required = false,
                                   default = nil)
  if valid_21625878 != nil:
    section.add "X-Amz-Algorithm", valid_21625878
  var valid_21625879 = header.getOrDefault("X-Amz-Signature")
  valid_21625879 = validateParameter(valid_21625879, JString, required = false,
                                   default = nil)
  if valid_21625879 != nil:
    section.add "X-Amz-Signature", valid_21625879
  var valid_21625880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625880 = validateParameter(valid_21625880, JString, required = false,
                                   default = nil)
  if valid_21625880 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625880
  assert header != nil, "header argument is necessary due to required `x-amz-sso_bearer_token` field"
  var valid_21625881 = header.getOrDefault("x-amz-sso_bearer_token")
  valid_21625881 = validateParameter(valid_21625881, JString, required = true,
                                   default = nil)
  if valid_21625881 != nil:
    section.add "x-amz-sso_bearer_token", valid_21625881
  var valid_21625882 = header.getOrDefault("X-Amz-Credential")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "X-Amz-Credential", valid_21625882
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625907: Call_GetRoleCredentials_21625770; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the STS short-term credentials for a given role name that is assigned to the user.
  ## 
  let valid = call_21625907.validator(path, query, header, formData, body, _)
  let scheme = call_21625907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625907.makeUrl(scheme.get, call_21625907.host, call_21625907.base,
                               call_21625907.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625907, uri, valid, _)

proc call*(call_21625970: Call_GetRoleCredentials_21625770; roleName: string;
          accountId: string): Recallable =
  ## getRoleCredentials
  ## Returns the STS short-term credentials for a given role name that is assigned to the user.
  ##   roleName: string (required)
  ##           : The friendly name of the role that is assigned to the user.
  ##   accountId: string (required)
  ##            : The identifier for the AWS account that is assigned to the user.
  var query_21625972 = newJObject()
  add(query_21625972, "role_name", newJString(roleName))
  add(query_21625972, "account_id", newJString(accountId))
  result = call_21625970.call(nil, query_21625972, nil, nil, nil)

var getRoleCredentials* = Call_GetRoleCredentials_21625770(
    name: "getRoleCredentials", meth: HttpMethod.HttpGet,
    host: "portal.sso.amazonaws.com", route: "/federation/credentials#role_name&account_id&x-amz-sso_bearer_token",
    validator: validate_GetRoleCredentials_21625771, base: "/",
    makeUrl: url_GetRoleCredentials_21625772, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccountRoles_21626010 = ref object of OpenApiRestCall_21625426
proc url_ListAccountRoles_21626012(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAccountRoles_21626011(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626013 = query.getOrDefault("max_result")
  valid_21626013 = validateParameter(valid_21626013, JInt, required = false,
                                   default = nil)
  if valid_21626013 != nil:
    section.add "max_result", valid_21626013
  assert query != nil,
        "query argument is necessary due to required `account_id` field"
  var valid_21626014 = query.getOrDefault("account_id")
  valid_21626014 = validateParameter(valid_21626014, JString, required = true,
                                   default = nil)
  if valid_21626014 != nil:
    section.add "account_id", valid_21626014
  var valid_21626015 = query.getOrDefault("maxResults")
  valid_21626015 = validateParameter(valid_21626015, JString, required = false,
                                   default = nil)
  if valid_21626015 != nil:
    section.add "maxResults", valid_21626015
  var valid_21626016 = query.getOrDefault("nextToken")
  valid_21626016 = validateParameter(valid_21626016, JString, required = false,
                                   default = nil)
  if valid_21626016 != nil:
    section.add "nextToken", valid_21626016
  var valid_21626017 = query.getOrDefault("next_token")
  valid_21626017 = validateParameter(valid_21626017, JString, required = false,
                                   default = nil)
  if valid_21626017 != nil:
    section.add "next_token", valid_21626017
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
  var valid_21626018 = header.getOrDefault("X-Amz-Date")
  valid_21626018 = validateParameter(valid_21626018, JString, required = false,
                                   default = nil)
  if valid_21626018 != nil:
    section.add "X-Amz-Date", valid_21626018
  var valid_21626019 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626019 = validateParameter(valid_21626019, JString, required = false,
                                   default = nil)
  if valid_21626019 != nil:
    section.add "X-Amz-Security-Token", valid_21626019
  var valid_21626020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626020 = validateParameter(valid_21626020, JString, required = false,
                                   default = nil)
  if valid_21626020 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626020
  var valid_21626021 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626021 = validateParameter(valid_21626021, JString, required = false,
                                   default = nil)
  if valid_21626021 != nil:
    section.add "X-Amz-Algorithm", valid_21626021
  var valid_21626022 = header.getOrDefault("X-Amz-Signature")
  valid_21626022 = validateParameter(valid_21626022, JString, required = false,
                                   default = nil)
  if valid_21626022 != nil:
    section.add "X-Amz-Signature", valid_21626022
  var valid_21626023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626023 = validateParameter(valid_21626023, JString, required = false,
                                   default = nil)
  if valid_21626023 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626023
  assert header != nil, "header argument is necessary due to required `x-amz-sso_bearer_token` field"
  var valid_21626024 = header.getOrDefault("x-amz-sso_bearer_token")
  valid_21626024 = validateParameter(valid_21626024, JString, required = true,
                                   default = nil)
  if valid_21626024 != nil:
    section.add "x-amz-sso_bearer_token", valid_21626024
  var valid_21626025 = header.getOrDefault("X-Amz-Credential")
  valid_21626025 = validateParameter(valid_21626025, JString, required = false,
                                   default = nil)
  if valid_21626025 != nil:
    section.add "X-Amz-Credential", valid_21626025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626026: Call_ListAccountRoles_21626010; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all roles that are assigned to the user for a given AWS account.
  ## 
  let valid = call_21626026.validator(path, query, header, formData, body, _)
  let scheme = call_21626026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626026.makeUrl(scheme.get, call_21626026.host, call_21626026.base,
                               call_21626026.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626026, uri, valid, _)

var listAccountRoles* = Call_ListAccountRoles_21626010(name: "listAccountRoles",
    meth: HttpMethod.HttpGet, host: "portal.sso.amazonaws.com",
    route: "/assignment/roles#x-amz-sso_bearer_token&account_id",
    validator: validate_ListAccountRoles_21626011, base: "/",
    makeUrl: url_ListAccountRoles_21626012, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccounts_21626029 = ref object of OpenApiRestCall_21625426
proc url_ListAccounts_21626031(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAccounts_21626030(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626032 = query.getOrDefault("max_result")
  valid_21626032 = validateParameter(valid_21626032, JInt, required = false,
                                   default = nil)
  if valid_21626032 != nil:
    section.add "max_result", valid_21626032
  var valid_21626033 = query.getOrDefault("maxResults")
  valid_21626033 = validateParameter(valid_21626033, JString, required = false,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "maxResults", valid_21626033
  var valid_21626034 = query.getOrDefault("nextToken")
  valid_21626034 = validateParameter(valid_21626034, JString, required = false,
                                   default = nil)
  if valid_21626034 != nil:
    section.add "nextToken", valid_21626034
  var valid_21626035 = query.getOrDefault("next_token")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "next_token", valid_21626035
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
  var valid_21626036 = header.getOrDefault("X-Amz-Date")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Date", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Security-Token", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Algorithm", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-Signature")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Signature", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626041
  assert header != nil, "header argument is necessary due to required `x-amz-sso_bearer_token` field"
  var valid_21626042 = header.getOrDefault("x-amz-sso_bearer_token")
  valid_21626042 = validateParameter(valid_21626042, JString, required = true,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "x-amz-sso_bearer_token", valid_21626042
  var valid_21626043 = header.getOrDefault("X-Amz-Credential")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-Credential", valid_21626043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626044: Call_ListAccounts_21626029; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all AWS accounts assigned to the user. These AWS accounts are assigned by the administrator of the account. For more information, see <a href="https://docs.aws.amazon.com/singlesignon/latest/userguide/useraccess.html#assignusers">Assign User Access</a> in the <i>AWS SSO User Guide</i>. This operation returns a paginated response.
  ## 
  let valid = call_21626044.validator(path, query, header, formData, body, _)
  let scheme = call_21626044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626044.makeUrl(scheme.get, call_21626044.host, call_21626044.base,
                               call_21626044.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626044, uri, valid, _)

var listAccounts* = Call_ListAccounts_21626029(name: "listAccounts",
    meth: HttpMethod.HttpGet, host: "portal.sso.amazonaws.com",
    route: "/assignment/accounts#x-amz-sso_bearer_token",
    validator: validate_ListAccounts_21626030, base: "/", makeUrl: url_ListAccounts_21626031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_Logout_21626047 = ref object of OpenApiRestCall_21625426
proc url_Logout_21626049(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Logout_21626048(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626050 = header.getOrDefault("X-Amz-Date")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Date", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Security-Token", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-Algorithm", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Signature")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Signature", valid_21626054
  var valid_21626055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626055
  assert header != nil, "header argument is necessary due to required `x-amz-sso_bearer_token` field"
  var valid_21626056 = header.getOrDefault("x-amz-sso_bearer_token")
  valid_21626056 = validateParameter(valid_21626056, JString, required = true,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "x-amz-sso_bearer_token", valid_21626056
  var valid_21626057 = header.getOrDefault("X-Amz-Credential")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-Credential", valid_21626057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626058: Call_Logout_21626047; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the client- and server-side session that is associated with the user.
  ## 
  let valid = call_21626058.validator(path, query, header, formData, body, _)
  let scheme = call_21626058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626058.makeUrl(scheme.get, call_21626058.host, call_21626058.base,
                               call_21626058.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626058, uri, valid, _)

proc call*(call_21626059: Call_Logout_21626047): Recallable =
  ## logout
  ## Removes the client- and server-side session that is associated with the user.
  result = call_21626059.call(nil, nil, nil, nil, nil)

var logout* = Call_Logout_21626047(name: "logout", meth: HttpMethod.HttpPost,
                                host: "portal.sso.amazonaws.com",
                                route: "/logout#x-amz-sso_bearer_token",
                                validator: validate_Logout_21626048, base: "/",
                                makeUrl: url_Logout_21626049,
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}