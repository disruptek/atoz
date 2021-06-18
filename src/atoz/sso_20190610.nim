
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
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

  OpenApiRestCall_402656038 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656038](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656038): Option[Scheme] {.used.} =
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "portal.sso.ap-northeast-1.amazonaws.com", "ap-southeast-1": "portal.sso.ap-southeast-1.amazonaws.com", "us-west-2": "portal.sso.us-west-2.amazonaws.com", "eu-west-2": "portal.sso.eu-west-2.amazonaws.com", "ap-northeast-3": "portal.sso.ap-northeast-3.amazonaws.com", "eu-central-1": "portal.sso.eu-central-1.amazonaws.com", "us-east-2": "portal.sso.us-east-2.amazonaws.com", "us-east-1": "portal.sso.us-east-1.amazonaws.com", "cn-northwest-1": "portal.sso.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "portal.sso.ap-south-1.amazonaws.com", "eu-north-1": "portal.sso.eu-north-1.amazonaws.com", "ap-northeast-2": "portal.sso.ap-northeast-2.amazonaws.com", "us-west-1": "portal.sso.us-west-1.amazonaws.com", "us-gov-east-1": "portal.sso.us-gov-east-1.amazonaws.com", "eu-west-3": "portal.sso.eu-west-3.amazonaws.com", "cn-north-1": "portal.sso.cn-north-1.amazonaws.com.cn", "sa-east-1": "portal.sso.sa-east-1.amazonaws.com", "eu-west-1": "portal.sso.eu-west-1.amazonaws.com", "us-gov-west-1": "portal.sso.us-gov-west-1.amazonaws.com", "ap-southeast-2": "portal.sso.ap-southeast-2.amazonaws.com", "ca-central-1": "portal.sso.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_GetRoleCredentials_402656288 = ref object of OpenApiRestCall_402656038
proc url_GetRoleCredentials_402656290(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRoleCredentials_402656289(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the STS short-term credentials for a given role name that is assigned to the user.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   account_id: JString (required)
                                  ##             : The identifier for the AWS account that is assigned to the user.
  ##   
                                                                                                                   ## role_name: JString (required)
                                                                                                                   ##            
                                                                                                                   ## : 
                                                                                                                   ## The 
                                                                                                                   ## friendly 
                                                                                                                   ## name 
                                                                                                                   ## of 
                                                                                                                   ## the 
                                                                                                                   ## role 
                                                                                                                   ## that 
                                                                                                                   ## is 
                                                                                                                   ## assigned 
                                                                                                                   ## to 
                                                                                                                   ## the 
                                                                                                                   ## user.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `account_id` field"
  var valid_402656369 = query.getOrDefault("account_id")
  valid_402656369 = validateParameter(valid_402656369, JString, required = true,
                                      default = nil)
  if valid_402656369 != nil:
    section.add "account_id", valid_402656369
  var valid_402656370 = query.getOrDefault("role_name")
  valid_402656370 = validateParameter(valid_402656370, JString, required = true,
                                      default = nil)
  if valid_402656370 != nil:
    section.add "role_name", valid_402656370
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  ##   x-amz-sso_bearer_token: JString (required)
                                   ##                         : The token issued by the <code>CreateToken</code> API call. For more information, see <a 
                                   ## href="https://docs.aws.amazon.com/singlesignon/latest/OIDCAPIReference/API_CreateToken.html">CreateToken</a> 
                                   ## in 
                                   ## the <i>AWS SSO OIDC API Reference Guide</i>.
  section = newJObject()
  var valid_402656371 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656371 = validateParameter(valid_402656371, JString,
                                      required = false, default = nil)
  if valid_402656371 != nil:
    section.add "X-Amz-Security-Token", valid_402656371
  var valid_402656372 = header.getOrDefault("X-Amz-Signature")
  valid_402656372 = validateParameter(valid_402656372, JString,
                                      required = false, default = nil)
  if valid_402656372 != nil:
    section.add "X-Amz-Signature", valid_402656372
  var valid_402656373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656373 = validateParameter(valid_402656373, JString,
                                      required = false, default = nil)
  if valid_402656373 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656373
  var valid_402656374 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656374 = validateParameter(valid_402656374, JString,
                                      required = false, default = nil)
  if valid_402656374 != nil:
    section.add "X-Amz-Algorithm", valid_402656374
  var valid_402656375 = header.getOrDefault("X-Amz-Date")
  valid_402656375 = validateParameter(valid_402656375, JString,
                                      required = false, default = nil)
  if valid_402656375 != nil:
    section.add "X-Amz-Date", valid_402656375
  var valid_402656376 = header.getOrDefault("X-Amz-Credential")
  valid_402656376 = validateParameter(valid_402656376, JString,
                                      required = false, default = nil)
  if valid_402656376 != nil:
    section.add "X-Amz-Credential", valid_402656376
  var valid_402656377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656377 = validateParameter(valid_402656377, JString,
                                      required = false, default = nil)
  if valid_402656377 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656377
  assert header != nil, "header argument is necessary due to required `x-amz-sso_bearer_token` field"
  var valid_402656378 = header.getOrDefault("x-amz-sso_bearer_token")
  valid_402656378 = validateParameter(valid_402656378, JString, required = true,
                                      default = nil)
  if valid_402656378 != nil:
    section.add "x-amz-sso_bearer_token", valid_402656378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656392: Call_GetRoleCredentials_402656288;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the STS short-term credentials for a given role name that is assigned to the user.
                                                                                         ## 
  let valid = call_402656392.validator(path, query, header, formData, body, _)
  let scheme = call_402656392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656392.makeUrl(scheme.get, call_402656392.host, call_402656392.base,
                                   call_402656392.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656392, uri, valid, _)

proc call*(call_402656441: Call_GetRoleCredentials_402656288; accountId: string;
           roleName: string): Recallable =
  ## getRoleCredentials
  ## Returns the STS short-term credentials for a given role name that is assigned to the user.
  ##   
                                                                                               ## accountId: string (required)
                                                                                               ##            
                                                                                               ## : 
                                                                                               ## The 
                                                                                               ## identifier 
                                                                                               ## for 
                                                                                               ## the 
                                                                                               ## AWS 
                                                                                               ## account 
                                                                                               ## that 
                                                                                               ## is 
                                                                                               ## assigned 
                                                                                               ## to 
                                                                                               ## the 
                                                                                               ## user.
  ##   
                                                                                                       ## roleName: string (required)
                                                                                                       ##           
                                                                                                       ## : 
                                                                                                       ## The 
                                                                                                       ## friendly 
                                                                                                       ## name 
                                                                                                       ## of 
                                                                                                       ## the 
                                                                                                       ## role 
                                                                                                       ## that 
                                                                                                       ## is 
                                                                                                       ## assigned 
                                                                                                       ## to 
                                                                                                       ## the 
                                                                                                       ## user.
  var query_402656442 = newJObject()
  add(query_402656442, "account_id", newJString(accountId))
  add(query_402656442, "role_name", newJString(roleName))
  result = call_402656441.call(nil, query_402656442, nil, nil, nil)

var getRoleCredentials* = Call_GetRoleCredentials_402656288(
    name: "getRoleCredentials", meth: HttpMethod.HttpGet,
    host: "portal.sso.amazonaws.com", route: "/federation/credentials#role_name&account_id&x-amz-sso_bearer_token",
    validator: validate_GetRoleCredentials_402656289, base: "/",
    makeUrl: url_GetRoleCredentials_402656290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccountRoles_402656472 = ref object of OpenApiRestCall_402656038
proc url_ListAccountRoles_402656474(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAccountRoles_402656473(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists all roles that are assigned to the user for a given AWS account.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
                                  ##             : Pagination limit
  ##   nextToken: JString
                                                                   ##            : Pagination token
  ##   
                                                                                                   ## account_id: JString (required)
                                                                                                   ##             
                                                                                                   ## : 
                                                                                                   ## The 
                                                                                                   ## identifier 
                                                                                                   ## for 
                                                                                                   ## the 
                                                                                                   ## AWS 
                                                                                                   ## account 
                                                                                                   ## that 
                                                                                                   ## is 
                                                                                                   ## assigned 
                                                                                                   ## to 
                                                                                                   ## the 
                                                                                                   ## user.
  ##   
                                                                                                           ## max_result: JInt
                                                                                                           ##             
                                                                                                           ## : 
                                                                                                           ## The 
                                                                                                           ## number 
                                                                                                           ## of 
                                                                                                           ## items 
                                                                                                           ## that 
                                                                                                           ## clients 
                                                                                                           ## can 
                                                                                                           ## request 
                                                                                                           ## per 
                                                                                                           ## page.
  ##   
                                                                                                                   ## next_token: JString
                                                                                                                   ##             
                                                                                                                   ## : 
                                                                                                                   ## The 
                                                                                                                   ## page 
                                                                                                                   ## token 
                                                                                                                   ## from 
                                                                                                                   ## the 
                                                                                                                   ## previous 
                                                                                                                   ## response 
                                                                                                                   ## output 
                                                                                                                   ## when 
                                                                                                                   ## you 
                                                                                                                   ## request 
                                                                                                                   ## subsequent 
                                                                                                                   ## pages.
  section = newJObject()
  var valid_402656475 = query.getOrDefault("maxResults")
  valid_402656475 = validateParameter(valid_402656475, JString,
                                      required = false, default = nil)
  if valid_402656475 != nil:
    section.add "maxResults", valid_402656475
  var valid_402656476 = query.getOrDefault("nextToken")
  valid_402656476 = validateParameter(valid_402656476, JString,
                                      required = false, default = nil)
  if valid_402656476 != nil:
    section.add "nextToken", valid_402656476
  assert query != nil,
         "query argument is necessary due to required `account_id` field"
  var valid_402656477 = query.getOrDefault("account_id")
  valid_402656477 = validateParameter(valid_402656477, JString, required = true,
                                      default = nil)
  if valid_402656477 != nil:
    section.add "account_id", valid_402656477
  var valid_402656478 = query.getOrDefault("max_result")
  valid_402656478 = validateParameter(valid_402656478, JInt, required = false,
                                      default = nil)
  if valid_402656478 != nil:
    section.add "max_result", valid_402656478
  var valid_402656479 = query.getOrDefault("next_token")
  valid_402656479 = validateParameter(valid_402656479, JString,
                                      required = false, default = nil)
  if valid_402656479 != nil:
    section.add "next_token", valid_402656479
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  ##   x-amz-sso_bearer_token: JString (required)
                                   ##                         : The token issued by the <code>CreateToken</code> API call. For more information, see <a 
                                   ## href="https://docs.aws.amazon.com/singlesignon/latest/OIDCAPIReference/API_CreateToken.html">CreateToken</a> 
                                   ## in 
                                   ## the <i>AWS SSO OIDC API Reference Guide</i>.
  section = newJObject()
  var valid_402656480 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656480 = validateParameter(valid_402656480, JString,
                                      required = false, default = nil)
  if valid_402656480 != nil:
    section.add "X-Amz-Security-Token", valid_402656480
  var valid_402656481 = header.getOrDefault("X-Amz-Signature")
  valid_402656481 = validateParameter(valid_402656481, JString,
                                      required = false, default = nil)
  if valid_402656481 != nil:
    section.add "X-Amz-Signature", valid_402656481
  var valid_402656482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656482 = validateParameter(valid_402656482, JString,
                                      required = false, default = nil)
  if valid_402656482 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656482
  var valid_402656483 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656483 = validateParameter(valid_402656483, JString,
                                      required = false, default = nil)
  if valid_402656483 != nil:
    section.add "X-Amz-Algorithm", valid_402656483
  var valid_402656484 = header.getOrDefault("X-Amz-Date")
  valid_402656484 = validateParameter(valid_402656484, JString,
                                      required = false, default = nil)
  if valid_402656484 != nil:
    section.add "X-Amz-Date", valid_402656484
  var valid_402656485 = header.getOrDefault("X-Amz-Credential")
  valid_402656485 = validateParameter(valid_402656485, JString,
                                      required = false, default = nil)
  if valid_402656485 != nil:
    section.add "X-Amz-Credential", valid_402656485
  var valid_402656486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656486 = validateParameter(valid_402656486, JString,
                                      required = false, default = nil)
  if valid_402656486 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656486
  assert header != nil, "header argument is necessary due to required `x-amz-sso_bearer_token` field"
  var valid_402656487 = header.getOrDefault("x-amz-sso_bearer_token")
  valid_402656487 = validateParameter(valid_402656487, JString, required = true,
                                      default = nil)
  if valid_402656487 != nil:
    section.add "x-amz-sso_bearer_token", valid_402656487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656488: Call_ListAccountRoles_402656472;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all roles that are assigned to the user for a given AWS account.
                                                                                         ## 
  let valid = call_402656488.validator(path, query, header, formData, body, _)
  let scheme = call_402656488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656488.makeUrl(scheme.get, call_402656488.host, call_402656488.base,
                                   call_402656488.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656488, uri, valid, _)

var listAccountRoles* = Call_ListAccountRoles_402656472(
    name: "listAccountRoles", meth: HttpMethod.HttpGet,
    host: "portal.sso.amazonaws.com",
    route: "/assignment/roles#x-amz-sso_bearer_token&account_id",
    validator: validate_ListAccountRoles_402656473, base: "/",
    makeUrl: url_ListAccountRoles_402656474,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccounts_402656491 = ref object of OpenApiRestCall_402656038
proc url_ListAccounts_402656493(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAccounts_402656492(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists all AWS accounts assigned to the user. These AWS accounts are assigned by the administrator of the account. For more information, see <a href="https://docs.aws.amazon.com/singlesignon/latest/userguide/useraccess.html#assignusers">Assign User Access</a> in the <i>AWS SSO User Guide</i>. This operation returns a paginated response.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
                                  ##             : Pagination limit
  ##   nextToken: JString
                                                                   ##            : Pagination token
  ##   
                                                                                                   ## max_result: JInt
                                                                                                   ##             
                                                                                                   ## : 
                                                                                                   ## This 
                                                                                                   ## is 
                                                                                                   ## the 
                                                                                                   ## number 
                                                                                                   ## of 
                                                                                                   ## items 
                                                                                                   ## clients 
                                                                                                   ## can 
                                                                                                   ## request 
                                                                                                   ## per 
                                                                                                   ## page.
  ##   
                                                                                                           ## next_token: JString
                                                                                                           ##             
                                                                                                           ## : 
                                                                                                           ## (Optional) 
                                                                                                           ## When 
                                                                                                           ## requesting 
                                                                                                           ## subsequent 
                                                                                                           ## pages, 
                                                                                                           ## this 
                                                                                                           ## is 
                                                                                                           ## the 
                                                                                                           ## page 
                                                                                                           ## token 
                                                                                                           ## from 
                                                                                                           ## the 
                                                                                                           ## previous 
                                                                                                           ## response 
                                                                                                           ## output.
  section = newJObject()
  var valid_402656494 = query.getOrDefault("maxResults")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "maxResults", valid_402656494
  var valid_402656495 = query.getOrDefault("nextToken")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "nextToken", valid_402656495
  var valid_402656496 = query.getOrDefault("max_result")
  valid_402656496 = validateParameter(valid_402656496, JInt, required = false,
                                      default = nil)
  if valid_402656496 != nil:
    section.add "max_result", valid_402656496
  var valid_402656497 = query.getOrDefault("next_token")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "next_token", valid_402656497
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  ##   x-amz-sso_bearer_token: JString (required)
                                   ##                         : The token issued by the <code>CreateToken</code> API call. For more information, see <a 
                                   ## href="https://docs.aws.amazon.com/singlesignon/latest/OIDCAPIReference/API_CreateToken.html">CreateToken</a> 
                                   ## in 
                                   ## the <i>AWS SSO OIDC API Reference Guide</i>.
  section = newJObject()
  var valid_402656498 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Security-Token", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-Signature")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-Signature", valid_402656499
  var valid_402656500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656500 = validateParameter(valid_402656500, JString,
                                      required = false, default = nil)
  if valid_402656500 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656500
  var valid_402656501 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656501 = validateParameter(valid_402656501, JString,
                                      required = false, default = nil)
  if valid_402656501 != nil:
    section.add "X-Amz-Algorithm", valid_402656501
  var valid_402656502 = header.getOrDefault("X-Amz-Date")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-Date", valid_402656502
  var valid_402656503 = header.getOrDefault("X-Amz-Credential")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-Credential", valid_402656503
  var valid_402656504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656504
  assert header != nil, "header argument is necessary due to required `x-amz-sso_bearer_token` field"
  var valid_402656505 = header.getOrDefault("x-amz-sso_bearer_token")
  valid_402656505 = validateParameter(valid_402656505, JString, required = true,
                                      default = nil)
  if valid_402656505 != nil:
    section.add "x-amz-sso_bearer_token", valid_402656505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656506: Call_ListAccounts_402656491; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all AWS accounts assigned to the user. These AWS accounts are assigned by the administrator of the account. For more information, see <a href="https://docs.aws.amazon.com/singlesignon/latest/userguide/useraccess.html#assignusers">Assign User Access</a> in the <i>AWS SSO User Guide</i>. This operation returns a paginated response.
                                                                                         ## 
  let valid = call_402656506.validator(path, query, header, formData, body, _)
  let scheme = call_402656506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656506.makeUrl(scheme.get, call_402656506.host, call_402656506.base,
                                   call_402656506.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656506, uri, valid, _)

var listAccounts* = Call_ListAccounts_402656491(name: "listAccounts",
    meth: HttpMethod.HttpGet, host: "portal.sso.amazonaws.com",
    route: "/assignment/accounts#x-amz-sso_bearer_token",
    validator: validate_ListAccounts_402656492, base: "/",
    makeUrl: url_ListAccounts_402656493, schemes: {Scheme.Https, Scheme.Http})
type
  Call_Logout_402656509 = ref object of OpenApiRestCall_402656038
proc url_Logout_402656511(protocol: Scheme; host: string; base: string;
                          route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Logout_402656510(path: JsonNode; query: JsonNode;
                               header: JsonNode; formData: JsonNode;
                               body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  ##   x-amz-sso_bearer_token: JString (required)
                                   ##                         : The token issued by the <code>CreateToken</code> API call. For more information, see <a 
                                   ## href="https://docs.aws.amazon.com/singlesignon/latest/OIDCAPIReference/API_CreateToken.html">CreateToken</a> 
                                   ## in 
                                   ## the <i>AWS SSO OIDC API Reference Guide</i>.
  section = newJObject()
  var valid_402656512 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Security-Token", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Signature")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Signature", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656514
  var valid_402656515 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-Algorithm", valid_402656515
  var valid_402656516 = header.getOrDefault("X-Amz-Date")
  valid_402656516 = validateParameter(valid_402656516, JString,
                                      required = false, default = nil)
  if valid_402656516 != nil:
    section.add "X-Amz-Date", valid_402656516
  var valid_402656517 = header.getOrDefault("X-Amz-Credential")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "X-Amz-Credential", valid_402656517
  var valid_402656518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656518
  assert header != nil, "header argument is necessary due to required `x-amz-sso_bearer_token` field"
  var valid_402656519 = header.getOrDefault("x-amz-sso_bearer_token")
  valid_402656519 = validateParameter(valid_402656519, JString, required = true,
                                      default = nil)
  if valid_402656519 != nil:
    section.add "x-amz-sso_bearer_token", valid_402656519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656520: Call_Logout_402656509; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the client- and server-side session that is associated with the user.
                                                                                         ## 
  let valid = call_402656520.validator(path, query, header, formData, body, _)
  let scheme = call_402656520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656520.makeUrl(scheme.get, call_402656520.host, call_402656520.base,
                                   call_402656520.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656520, uri, valid, _)

proc call*(call_402656521: Call_Logout_402656509): Recallable =
  ## logout
  ## Removes the client- and server-side session that is associated with the user.
  result = call_402656521.call(nil, nil, nil, nil, nil)

var logout* = Call_Logout_402656509(name: "logout", meth: HttpMethod.HttpPost,
                                    host: "portal.sso.amazonaws.com",
                                    route: "/logout#x-amz-sso_bearer_token",
                                    validator: validate_Logout_402656510,
                                    base: "/", makeUrl: url_Logout_402656511,
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
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
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