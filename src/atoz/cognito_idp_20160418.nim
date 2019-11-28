
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Cognito Identity Provider
## version: 2016-04-18
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>Using the Amazon Cognito User Pools API, you can create a user pool to manage directories and users. You can authenticate a user to obtain tokens related to user identity and access policies.</p> <p>This API reference provides information about user pools in Amazon Cognito User Pools.</p> <p>For more information, see the Amazon Cognito Documentation.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/cognito-idp/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "cognito-idp.ap-northeast-1.amazonaws.com", "ap-southeast-1": "cognito-idp.ap-southeast-1.amazonaws.com",
                           "us-west-2": "cognito-idp.us-west-2.amazonaws.com",
                           "eu-west-2": "cognito-idp.eu-west-2.amazonaws.com", "ap-northeast-3": "cognito-idp.ap-northeast-3.amazonaws.com", "eu-central-1": "cognito-idp.eu-central-1.amazonaws.com",
                           "us-east-2": "cognito-idp.us-east-2.amazonaws.com",
                           "us-east-1": "cognito-idp.us-east-1.amazonaws.com", "cn-northwest-1": "cognito-idp.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "cognito-idp.ap-south-1.amazonaws.com", "eu-north-1": "cognito-idp.eu-north-1.amazonaws.com", "ap-northeast-2": "cognito-idp.ap-northeast-2.amazonaws.com",
                           "us-west-1": "cognito-idp.us-west-1.amazonaws.com", "us-gov-east-1": "cognito-idp.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "cognito-idp.eu-west-3.amazonaws.com", "cn-north-1": "cognito-idp.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "cognito-idp.sa-east-1.amazonaws.com",
                           "eu-west-1": "cognito-idp.eu-west-1.amazonaws.com", "us-gov-west-1": "cognito-idp.us-gov-west-1.amazonaws.com", "ap-southeast-2": "cognito-idp.ap-southeast-2.amazonaws.com", "ca-central-1": "cognito-idp.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "cognito-idp.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "cognito-idp.ap-southeast-1.amazonaws.com",
      "us-west-2": "cognito-idp.us-west-2.amazonaws.com",
      "eu-west-2": "cognito-idp.eu-west-2.amazonaws.com",
      "ap-northeast-3": "cognito-idp.ap-northeast-3.amazonaws.com",
      "eu-central-1": "cognito-idp.eu-central-1.amazonaws.com",
      "us-east-2": "cognito-idp.us-east-2.amazonaws.com",
      "us-east-1": "cognito-idp.us-east-1.amazonaws.com",
      "cn-northwest-1": "cognito-idp.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "cognito-idp.ap-south-1.amazonaws.com",
      "eu-north-1": "cognito-idp.eu-north-1.amazonaws.com",
      "ap-northeast-2": "cognito-idp.ap-northeast-2.amazonaws.com",
      "us-west-1": "cognito-idp.us-west-1.amazonaws.com",
      "us-gov-east-1": "cognito-idp.us-gov-east-1.amazonaws.com",
      "eu-west-3": "cognito-idp.eu-west-3.amazonaws.com",
      "cn-north-1": "cognito-idp.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "cognito-idp.sa-east-1.amazonaws.com",
      "eu-west-1": "cognito-idp.eu-west-1.amazonaws.com",
      "us-gov-west-1": "cognito-idp.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "cognito-idp.ap-southeast-2.amazonaws.com",
      "ca-central-1": "cognito-idp.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "cognito-idp"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddCustomAttributes_599705 = ref object of OpenApiRestCall_599368
proc url_AddCustomAttributes_599707(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddCustomAttributes_599706(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Adds additional user attributes to the user pool schema.
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
  var valid_599819 = header.getOrDefault("X-Amz-Date")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "X-Amz-Date", valid_599819
  var valid_599820 = header.getOrDefault("X-Amz-Security-Token")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "X-Amz-Security-Token", valid_599820
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599834 = header.getOrDefault("X-Amz-Target")
  valid_599834 = validateParameter(valid_599834, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AddCustomAttributes"))
  if valid_599834 != nil:
    section.add "X-Amz-Target", valid_599834
  var valid_599835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599835 = validateParameter(valid_599835, JString, required = false,
                                 default = nil)
  if valid_599835 != nil:
    section.add "X-Amz-Content-Sha256", valid_599835
  var valid_599836 = header.getOrDefault("X-Amz-Algorithm")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Algorithm", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Signature")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Signature", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-SignedHeaders", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Credential")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Credential", valid_599839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599863: Call_AddCustomAttributes_599705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds additional user attributes to the user pool schema.
  ## 
  let valid = call_599863.validator(path, query, header, formData, body)
  let scheme = call_599863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599863.url(scheme.get, call_599863.host, call_599863.base,
                         call_599863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599863, url, valid)

proc call*(call_599934: Call_AddCustomAttributes_599705; body: JsonNode): Recallable =
  ## addCustomAttributes
  ## Adds additional user attributes to the user pool schema.
  ##   body: JObject (required)
  var body_599935 = newJObject()
  if body != nil:
    body_599935 = body
  result = call_599934.call(nil, nil, nil, nil, body_599935)

var addCustomAttributes* = Call_AddCustomAttributes_599705(
    name: "addCustomAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AddCustomAttributes",
    validator: validate_AddCustomAttributes_599706, base: "/",
    url: url_AddCustomAttributes_599707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminAddUserToGroup_599974 = ref object of OpenApiRestCall_599368
proc url_AdminAddUserToGroup_599976(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminAddUserToGroup_599975(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Adds the specified user to the specified group.</p> <p>Calling this action requires developer credentials.</p>
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
  var valid_599977 = header.getOrDefault("X-Amz-Date")
  valid_599977 = validateParameter(valid_599977, JString, required = false,
                                 default = nil)
  if valid_599977 != nil:
    section.add "X-Amz-Date", valid_599977
  var valid_599978 = header.getOrDefault("X-Amz-Security-Token")
  valid_599978 = validateParameter(valid_599978, JString, required = false,
                                 default = nil)
  if valid_599978 != nil:
    section.add "X-Amz-Security-Token", valid_599978
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599979 = header.getOrDefault("X-Amz-Target")
  valid_599979 = validateParameter(valid_599979, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminAddUserToGroup"))
  if valid_599979 != nil:
    section.add "X-Amz-Target", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Content-Sha256", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Algorithm")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Algorithm", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Signature")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Signature", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-SignedHeaders", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Credential")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Credential", valid_599984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599986: Call_AdminAddUserToGroup_599974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified user to the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_599986.validator(path, query, header, formData, body)
  let scheme = call_599986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599986.url(scheme.get, call_599986.host, call_599986.base,
                         call_599986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599986, url, valid)

proc call*(call_599987: Call_AdminAddUserToGroup_599974; body: JsonNode): Recallable =
  ## adminAddUserToGroup
  ## <p>Adds the specified user to the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_599988 = newJObject()
  if body != nil:
    body_599988 = body
  result = call_599987.call(nil, nil, nil, nil, body_599988)

var adminAddUserToGroup* = Call_AdminAddUserToGroup_599974(
    name: "adminAddUserToGroup", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminAddUserToGroup",
    validator: validate_AdminAddUserToGroup_599975, base: "/",
    url: url_AdminAddUserToGroup_599976, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminConfirmSignUp_599989 = ref object of OpenApiRestCall_599368
proc url_AdminConfirmSignUp_599991(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminConfirmSignUp_599990(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Confirms user registration as an admin without using a confirmation code. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
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
  var valid_599992 = header.getOrDefault("X-Amz-Date")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Date", valid_599992
  var valid_599993 = header.getOrDefault("X-Amz-Security-Token")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Security-Token", valid_599993
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599994 = header.getOrDefault("X-Amz-Target")
  valid_599994 = validateParameter(valid_599994, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminConfirmSignUp"))
  if valid_599994 != nil:
    section.add "X-Amz-Target", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Content-Sha256", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Algorithm")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Algorithm", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Signature")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Signature", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-SignedHeaders", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Credential")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Credential", valid_599999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600001: Call_AdminConfirmSignUp_599989; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Confirms user registration as an admin without using a confirmation code. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_600001.validator(path, query, header, formData, body)
  let scheme = call_600001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600001.url(scheme.get, call_600001.host, call_600001.base,
                         call_600001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600001, url, valid)

proc call*(call_600002: Call_AdminConfirmSignUp_599989; body: JsonNode): Recallable =
  ## adminConfirmSignUp
  ## <p>Confirms user registration as an admin without using a confirmation code. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_600003 = newJObject()
  if body != nil:
    body_600003 = body
  result = call_600002.call(nil, nil, nil, nil, body_600003)

var adminConfirmSignUp* = Call_AdminConfirmSignUp_599989(
    name: "adminConfirmSignUp", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminConfirmSignUp",
    validator: validate_AdminConfirmSignUp_599990, base: "/",
    url: url_AdminConfirmSignUp_599991, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminCreateUser_600004 = ref object of OpenApiRestCall_599368
proc url_AdminCreateUser_600006(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminCreateUser_600005(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Creates a new user in the specified user pool.</p> <p>If <code>MessageAction</code> is not set, the default is to send a welcome message via email or phone (SMS).</p> <note> <p>This message is based on a template that you configured in your call to or . This template includes your custom sign-up instructions and placeholders for user name and temporary password.</p> </note> <p>Alternatively, you can call AdminCreateUser with “SUPPRESS” for the <code>MessageAction</code> parameter, and Amazon Cognito will not send any email. </p> <p>In either case, the user will be in the <code>FORCE_CHANGE_PASSWORD</code> state until they sign in and change their password.</p> <p>AdminCreateUser requires developer credentials.</p>
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
  var valid_600007 = header.getOrDefault("X-Amz-Date")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Date", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Security-Token")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Security-Token", valid_600008
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600009 = header.getOrDefault("X-Amz-Target")
  valid_600009 = validateParameter(valid_600009, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminCreateUser"))
  if valid_600009 != nil:
    section.add "X-Amz-Target", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-Content-Sha256", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Algorithm")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Algorithm", valid_600011
  var valid_600012 = header.getOrDefault("X-Amz-Signature")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-Signature", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-SignedHeaders", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-Credential")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-Credential", valid_600014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600016: Call_AdminCreateUser_600004; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new user in the specified user pool.</p> <p>If <code>MessageAction</code> is not set, the default is to send a welcome message via email or phone (SMS).</p> <note> <p>This message is based on a template that you configured in your call to or . This template includes your custom sign-up instructions and placeholders for user name and temporary password.</p> </note> <p>Alternatively, you can call AdminCreateUser with “SUPPRESS” for the <code>MessageAction</code> parameter, and Amazon Cognito will not send any email. </p> <p>In either case, the user will be in the <code>FORCE_CHANGE_PASSWORD</code> state until they sign in and change their password.</p> <p>AdminCreateUser requires developer credentials.</p>
  ## 
  let valid = call_600016.validator(path, query, header, formData, body)
  let scheme = call_600016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600016.url(scheme.get, call_600016.host, call_600016.base,
                         call_600016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600016, url, valid)

proc call*(call_600017: Call_AdminCreateUser_600004; body: JsonNode): Recallable =
  ## adminCreateUser
  ## <p>Creates a new user in the specified user pool.</p> <p>If <code>MessageAction</code> is not set, the default is to send a welcome message via email or phone (SMS).</p> <note> <p>This message is based on a template that you configured in your call to or . This template includes your custom sign-up instructions and placeholders for user name and temporary password.</p> </note> <p>Alternatively, you can call AdminCreateUser with “SUPPRESS” for the <code>MessageAction</code> parameter, and Amazon Cognito will not send any email. </p> <p>In either case, the user will be in the <code>FORCE_CHANGE_PASSWORD</code> state until they sign in and change their password.</p> <p>AdminCreateUser requires developer credentials.</p>
  ##   body: JObject (required)
  var body_600018 = newJObject()
  if body != nil:
    body_600018 = body
  result = call_600017.call(nil, nil, nil, nil, body_600018)

var adminCreateUser* = Call_AdminCreateUser_600004(name: "adminCreateUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminCreateUser",
    validator: validate_AdminCreateUser_600005, base: "/", url: url_AdminCreateUser_600006,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDeleteUser_600019 = ref object of OpenApiRestCall_599368
proc url_AdminDeleteUser_600021(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminDeleteUser_600020(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Deletes a user as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600024 = header.getOrDefault("X-Amz-Target")
  valid_600024 = validateParameter(valid_600024, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDeleteUser"))
  if valid_600024 != nil:
    section.add "X-Amz-Target", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Content-Sha256", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Algorithm")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Algorithm", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Signature")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Signature", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-SignedHeaders", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-Credential")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-Credential", valid_600029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600031: Call_AdminDeleteUser_600019; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a user as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_600031.validator(path, query, header, formData, body)
  let scheme = call_600031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600031.url(scheme.get, call_600031.host, call_600031.base,
                         call_600031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600031, url, valid)

proc call*(call_600032: Call_AdminDeleteUser_600019; body: JsonNode): Recallable =
  ## adminDeleteUser
  ## <p>Deletes a user as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_600033 = newJObject()
  if body != nil:
    body_600033 = body
  result = call_600032.call(nil, nil, nil, nil, body_600033)

var adminDeleteUser* = Call_AdminDeleteUser_600019(name: "adminDeleteUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDeleteUser",
    validator: validate_AdminDeleteUser_600020, base: "/", url: url_AdminDeleteUser_600021,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDeleteUserAttributes_600034 = ref object of OpenApiRestCall_599368
proc url_AdminDeleteUserAttributes_600036(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminDeleteUserAttributes_600035(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the user attributes in a user pool as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600039 = header.getOrDefault("X-Amz-Target")
  valid_600039 = validateParameter(valid_600039, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDeleteUserAttributes"))
  if valid_600039 != nil:
    section.add "X-Amz-Target", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Content-Sha256", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Algorithm")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Algorithm", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Signature")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Signature", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-SignedHeaders", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-Credential")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-Credential", valid_600044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600046: Call_AdminDeleteUserAttributes_600034; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the user attributes in a user pool as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_600046.validator(path, query, header, formData, body)
  let scheme = call_600046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600046.url(scheme.get, call_600046.host, call_600046.base,
                         call_600046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600046, url, valid)

proc call*(call_600047: Call_AdminDeleteUserAttributes_600034; body: JsonNode): Recallable =
  ## adminDeleteUserAttributes
  ## <p>Deletes the user attributes in a user pool as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_600048 = newJObject()
  if body != nil:
    body_600048 = body
  result = call_600047.call(nil, nil, nil, nil, body_600048)

var adminDeleteUserAttributes* = Call_AdminDeleteUserAttributes_600034(
    name: "adminDeleteUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDeleteUserAttributes",
    validator: validate_AdminDeleteUserAttributes_600035, base: "/",
    url: url_AdminDeleteUserAttributes_600036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDisableProviderForUser_600049 = ref object of OpenApiRestCall_599368
proc url_AdminDisableProviderForUser_600051(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminDisableProviderForUser_600050(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Disables the user from signing in with the specified external (SAML or social) identity provider. If the user to disable is a Cognito User Pools native username + password user, they are not permitted to use their password to sign-in. If the user to disable is a linked external IdP user, any link between that user and an existing user is removed. The next time the external user (no longer attached to the previously linked <code>DestinationUser</code>) signs in, they must create a new user account. See .</p> <p>This action is enabled only for admin access and requires developer credentials.</p> <p>The <code>ProviderName</code> must match the value specified when creating an IdP for the pool. </p> <p>To disable a native username + password user, the <code>ProviderName</code> value must be <code>Cognito</code> and the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code>, with the <code>ProviderAttributeValue</code> being the name that is used in the user pool for the user.</p> <p>The <code>ProviderAttributeName</code> must always be <code>Cognito_Subject</code> for social identity providers. The <code>ProviderAttributeValue</code> must always be the exact subject that was used when the user was originally linked as a source user.</p> <p>For de-linking a SAML identity, there are two scenarios. If the linked identity has not yet been used to sign-in, the <code>ProviderAttributeName</code> and <code>ProviderAttributeValue</code> must be the same values that were used for the <code>SourceUser</code> when the identities were originally linked in the call. (If the linking was done with <code>ProviderAttributeName</code> set to <code>Cognito_Subject</code>, the same applies here). However, if the user has already signed in, the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code> and <code>ProviderAttributeValue</code> must be the subject of the SAML assertion.</p>
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
  var valid_600052 = header.getOrDefault("X-Amz-Date")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Date", valid_600052
  var valid_600053 = header.getOrDefault("X-Amz-Security-Token")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Security-Token", valid_600053
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600054 = header.getOrDefault("X-Amz-Target")
  valid_600054 = validateParameter(valid_600054, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDisableProviderForUser"))
  if valid_600054 != nil:
    section.add "X-Amz-Target", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Content-Sha256", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Algorithm")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Algorithm", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Signature")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Signature", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-SignedHeaders", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Credential")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Credential", valid_600059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600061: Call_AdminDisableProviderForUser_600049; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables the user from signing in with the specified external (SAML or social) identity provider. If the user to disable is a Cognito User Pools native username + password user, they are not permitted to use their password to sign-in. If the user to disable is a linked external IdP user, any link between that user and an existing user is removed. The next time the external user (no longer attached to the previously linked <code>DestinationUser</code>) signs in, they must create a new user account. See .</p> <p>This action is enabled only for admin access and requires developer credentials.</p> <p>The <code>ProviderName</code> must match the value specified when creating an IdP for the pool. </p> <p>To disable a native username + password user, the <code>ProviderName</code> value must be <code>Cognito</code> and the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code>, with the <code>ProviderAttributeValue</code> being the name that is used in the user pool for the user.</p> <p>The <code>ProviderAttributeName</code> must always be <code>Cognito_Subject</code> for social identity providers. The <code>ProviderAttributeValue</code> must always be the exact subject that was used when the user was originally linked as a source user.</p> <p>For de-linking a SAML identity, there are two scenarios. If the linked identity has not yet been used to sign-in, the <code>ProviderAttributeName</code> and <code>ProviderAttributeValue</code> must be the same values that were used for the <code>SourceUser</code> when the identities were originally linked in the call. (If the linking was done with <code>ProviderAttributeName</code> set to <code>Cognito_Subject</code>, the same applies here). However, if the user has already signed in, the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code> and <code>ProviderAttributeValue</code> must be the subject of the SAML assertion.</p>
  ## 
  let valid = call_600061.validator(path, query, header, formData, body)
  let scheme = call_600061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600061.url(scheme.get, call_600061.host, call_600061.base,
                         call_600061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600061, url, valid)

proc call*(call_600062: Call_AdminDisableProviderForUser_600049; body: JsonNode): Recallable =
  ## adminDisableProviderForUser
  ## <p>Disables the user from signing in with the specified external (SAML or social) identity provider. If the user to disable is a Cognito User Pools native username + password user, they are not permitted to use their password to sign-in. If the user to disable is a linked external IdP user, any link between that user and an existing user is removed. The next time the external user (no longer attached to the previously linked <code>DestinationUser</code>) signs in, they must create a new user account. See .</p> <p>This action is enabled only for admin access and requires developer credentials.</p> <p>The <code>ProviderName</code> must match the value specified when creating an IdP for the pool. </p> <p>To disable a native username + password user, the <code>ProviderName</code> value must be <code>Cognito</code> and the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code>, with the <code>ProviderAttributeValue</code> being the name that is used in the user pool for the user.</p> <p>The <code>ProviderAttributeName</code> must always be <code>Cognito_Subject</code> for social identity providers. The <code>ProviderAttributeValue</code> must always be the exact subject that was used when the user was originally linked as a source user.</p> <p>For de-linking a SAML identity, there are two scenarios. If the linked identity has not yet been used to sign-in, the <code>ProviderAttributeName</code> and <code>ProviderAttributeValue</code> must be the same values that were used for the <code>SourceUser</code> when the identities were originally linked in the call. (If the linking was done with <code>ProviderAttributeName</code> set to <code>Cognito_Subject</code>, the same applies here). However, if the user has already signed in, the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code> and <code>ProviderAttributeValue</code> must be the subject of the SAML assertion.</p>
  ##   body: JObject (required)
  var body_600063 = newJObject()
  if body != nil:
    body_600063 = body
  result = call_600062.call(nil, nil, nil, nil, body_600063)

var adminDisableProviderForUser* = Call_AdminDisableProviderForUser_600049(
    name: "adminDisableProviderForUser", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDisableProviderForUser",
    validator: validate_AdminDisableProviderForUser_600050, base: "/",
    url: url_AdminDisableProviderForUser_600051,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDisableUser_600064 = ref object of OpenApiRestCall_599368
proc url_AdminDisableUser_600066(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminDisableUser_600065(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Disables the specified user.</p> <p>Calling this action requires developer credentials.</p>
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
  var valid_600067 = header.getOrDefault("X-Amz-Date")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Date", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-Security-Token")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Security-Token", valid_600068
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600069 = header.getOrDefault("X-Amz-Target")
  valid_600069 = validateParameter(valid_600069, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDisableUser"))
  if valid_600069 != nil:
    section.add "X-Amz-Target", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Content-Sha256", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Algorithm")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Algorithm", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-Signature")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Signature", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-SignedHeaders", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-Credential")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Credential", valid_600074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600076: Call_AdminDisableUser_600064; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables the specified user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_600076.validator(path, query, header, formData, body)
  let scheme = call_600076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600076.url(scheme.get, call_600076.host, call_600076.base,
                         call_600076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600076, url, valid)

proc call*(call_600077: Call_AdminDisableUser_600064; body: JsonNode): Recallable =
  ## adminDisableUser
  ## <p>Disables the specified user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_600078 = newJObject()
  if body != nil:
    body_600078 = body
  result = call_600077.call(nil, nil, nil, nil, body_600078)

var adminDisableUser* = Call_AdminDisableUser_600064(name: "adminDisableUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDisableUser",
    validator: validate_AdminDisableUser_600065, base: "/",
    url: url_AdminDisableUser_600066, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminEnableUser_600079 = ref object of OpenApiRestCall_599368
proc url_AdminEnableUser_600081(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminEnableUser_600080(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Enables the specified user as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
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
  var valid_600082 = header.getOrDefault("X-Amz-Date")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Date", valid_600082
  var valid_600083 = header.getOrDefault("X-Amz-Security-Token")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Security-Token", valid_600083
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600084 = header.getOrDefault("X-Amz-Target")
  valid_600084 = validateParameter(valid_600084, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminEnableUser"))
  if valid_600084 != nil:
    section.add "X-Amz-Target", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Content-Sha256", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-Algorithm")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-Algorithm", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Signature")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Signature", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-SignedHeaders", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Credential")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Credential", valid_600089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600091: Call_AdminEnableUser_600079; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the specified user as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_600091.validator(path, query, header, formData, body)
  let scheme = call_600091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600091.url(scheme.get, call_600091.host, call_600091.base,
                         call_600091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600091, url, valid)

proc call*(call_600092: Call_AdminEnableUser_600079; body: JsonNode): Recallable =
  ## adminEnableUser
  ## <p>Enables the specified user as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_600093 = newJObject()
  if body != nil:
    body_600093 = body
  result = call_600092.call(nil, nil, nil, nil, body_600093)

var adminEnableUser* = Call_AdminEnableUser_600079(name: "adminEnableUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminEnableUser",
    validator: validate_AdminEnableUser_600080, base: "/", url: url_AdminEnableUser_600081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminForgetDevice_600094 = ref object of OpenApiRestCall_599368
proc url_AdminForgetDevice_600096(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminForgetDevice_600095(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Forgets the device, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
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
  var valid_600097 = header.getOrDefault("X-Amz-Date")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "X-Amz-Date", valid_600097
  var valid_600098 = header.getOrDefault("X-Amz-Security-Token")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "X-Amz-Security-Token", valid_600098
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600099 = header.getOrDefault("X-Amz-Target")
  valid_600099 = validateParameter(valid_600099, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminForgetDevice"))
  if valid_600099 != nil:
    section.add "X-Amz-Target", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Content-Sha256", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-Algorithm")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Algorithm", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Signature")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Signature", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-SignedHeaders", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-Credential")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-Credential", valid_600104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600106: Call_AdminForgetDevice_600094; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Forgets the device, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_600106.validator(path, query, header, formData, body)
  let scheme = call_600106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600106.url(scheme.get, call_600106.host, call_600106.base,
                         call_600106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600106, url, valid)

proc call*(call_600107: Call_AdminForgetDevice_600094; body: JsonNode): Recallable =
  ## adminForgetDevice
  ## <p>Forgets the device, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_600108 = newJObject()
  if body != nil:
    body_600108 = body
  result = call_600107.call(nil, nil, nil, nil, body_600108)

var adminForgetDevice* = Call_AdminForgetDevice_600094(name: "adminForgetDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminForgetDevice",
    validator: validate_AdminForgetDevice_600095, base: "/",
    url: url_AdminForgetDevice_600096, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminGetDevice_600109 = ref object of OpenApiRestCall_599368
proc url_AdminGetDevice_600111(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminGetDevice_600110(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Gets the device, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
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
  var valid_600112 = header.getOrDefault("X-Amz-Date")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-Date", valid_600112
  var valid_600113 = header.getOrDefault("X-Amz-Security-Token")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "X-Amz-Security-Token", valid_600113
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600114 = header.getOrDefault("X-Amz-Target")
  valid_600114 = validateParameter(valid_600114, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminGetDevice"))
  if valid_600114 != nil:
    section.add "X-Amz-Target", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-Content-Sha256", valid_600115
  var valid_600116 = header.getOrDefault("X-Amz-Algorithm")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Algorithm", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-Signature")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-Signature", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-SignedHeaders", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Credential")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Credential", valid_600119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600121: Call_AdminGetDevice_600109; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the device, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_600121.validator(path, query, header, formData, body)
  let scheme = call_600121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600121.url(scheme.get, call_600121.host, call_600121.base,
                         call_600121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600121, url, valid)

proc call*(call_600122: Call_AdminGetDevice_600109; body: JsonNode): Recallable =
  ## adminGetDevice
  ## <p>Gets the device, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_600123 = newJObject()
  if body != nil:
    body_600123 = body
  result = call_600122.call(nil, nil, nil, nil, body_600123)

var adminGetDevice* = Call_AdminGetDevice_600109(name: "adminGetDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminGetDevice",
    validator: validate_AdminGetDevice_600110, base: "/", url: url_AdminGetDevice_600111,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminGetUser_600124 = ref object of OpenApiRestCall_599368
proc url_AdminGetUser_600126(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminGetUser_600125(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets the specified user by user name in a user pool as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
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
  var valid_600127 = header.getOrDefault("X-Amz-Date")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Date", valid_600127
  var valid_600128 = header.getOrDefault("X-Amz-Security-Token")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Security-Token", valid_600128
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600129 = header.getOrDefault("X-Amz-Target")
  valid_600129 = validateParameter(valid_600129, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminGetUser"))
  if valid_600129 != nil:
    section.add "X-Amz-Target", valid_600129
  var valid_600130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Content-Sha256", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Algorithm")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Algorithm", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-Signature")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Signature", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-SignedHeaders", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-Credential")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Credential", valid_600134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600136: Call_AdminGetUser_600124; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the specified user by user name in a user pool as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_600136.validator(path, query, header, formData, body)
  let scheme = call_600136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600136.url(scheme.get, call_600136.host, call_600136.base,
                         call_600136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600136, url, valid)

proc call*(call_600137: Call_AdminGetUser_600124; body: JsonNode): Recallable =
  ## adminGetUser
  ## <p>Gets the specified user by user name in a user pool as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_600138 = newJObject()
  if body != nil:
    body_600138 = body
  result = call_600137.call(nil, nil, nil, nil, body_600138)

var adminGetUser* = Call_AdminGetUser_600124(name: "adminGetUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminGetUser",
    validator: validate_AdminGetUser_600125, base: "/", url: url_AdminGetUser_600126,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminInitiateAuth_600139 = ref object of OpenApiRestCall_599368
proc url_AdminInitiateAuth_600141(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminInitiateAuth_600140(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Initiates the authentication flow, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
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
  var valid_600142 = header.getOrDefault("X-Amz-Date")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Date", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-Security-Token")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Security-Token", valid_600143
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600144 = header.getOrDefault("X-Amz-Target")
  valid_600144 = validateParameter(valid_600144, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminInitiateAuth"))
  if valid_600144 != nil:
    section.add "X-Amz-Target", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Content-Sha256", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Algorithm")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Algorithm", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-Signature")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Signature", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-SignedHeaders", valid_600148
  var valid_600149 = header.getOrDefault("X-Amz-Credential")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-Credential", valid_600149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600151: Call_AdminInitiateAuth_600139; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates the authentication flow, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_600151.validator(path, query, header, formData, body)
  let scheme = call_600151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600151.url(scheme.get, call_600151.host, call_600151.base,
                         call_600151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600151, url, valid)

proc call*(call_600152: Call_AdminInitiateAuth_600139; body: JsonNode): Recallable =
  ## adminInitiateAuth
  ## <p>Initiates the authentication flow, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_600153 = newJObject()
  if body != nil:
    body_600153 = body
  result = call_600152.call(nil, nil, nil, nil, body_600153)

var adminInitiateAuth* = Call_AdminInitiateAuth_600139(name: "adminInitiateAuth",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminInitiateAuth",
    validator: validate_AdminInitiateAuth_600140, base: "/",
    url: url_AdminInitiateAuth_600141, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminLinkProviderForUser_600154 = ref object of OpenApiRestCall_599368
proc url_AdminLinkProviderForUser_600156(protocol: Scheme; host: string;
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

proc validate_AdminLinkProviderForUser_600155(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Links an existing user account in a user pool (<code>DestinationUser</code>) to an identity from an external identity provider (<code>SourceUser</code>) based on a specified attribute name and value from the external identity provider. This allows you to create a link from the existing user account to an external federated user identity that has not yet been used to sign in, so that the federated user identity can be used to sign in as the existing user account. </p> <p> For example, if there is an existing user with a username and password, this API links that user to a federated user identity, so that when the federated user identity is used, the user signs in as the existing user account. </p> <important> <p>Because this API allows a user with an external federated identity to sign in as an existing user in the user pool, it is critical that it only be used with external identity providers and provider attributes that have been trusted by the application owner.</p> </important> <p>See also .</p> <p>This action is enabled only for admin access and requires developer credentials.</p>
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
  var valid_600157 = header.getOrDefault("X-Amz-Date")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Date", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-Security-Token")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Security-Token", valid_600158
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600159 = header.getOrDefault("X-Amz-Target")
  valid_600159 = validateParameter(valid_600159, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminLinkProviderForUser"))
  if valid_600159 != nil:
    section.add "X-Amz-Target", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-Content-Sha256", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Algorithm")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Algorithm", valid_600161
  var valid_600162 = header.getOrDefault("X-Amz-Signature")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-Signature", valid_600162
  var valid_600163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-SignedHeaders", valid_600163
  var valid_600164 = header.getOrDefault("X-Amz-Credential")
  valid_600164 = validateParameter(valid_600164, JString, required = false,
                                 default = nil)
  if valid_600164 != nil:
    section.add "X-Amz-Credential", valid_600164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600166: Call_AdminLinkProviderForUser_600154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Links an existing user account in a user pool (<code>DestinationUser</code>) to an identity from an external identity provider (<code>SourceUser</code>) based on a specified attribute name and value from the external identity provider. This allows you to create a link from the existing user account to an external federated user identity that has not yet been used to sign in, so that the federated user identity can be used to sign in as the existing user account. </p> <p> For example, if there is an existing user with a username and password, this API links that user to a federated user identity, so that when the federated user identity is used, the user signs in as the existing user account. </p> <important> <p>Because this API allows a user with an external federated identity to sign in as an existing user in the user pool, it is critical that it only be used with external identity providers and provider attributes that have been trusted by the application owner.</p> </important> <p>See also .</p> <p>This action is enabled only for admin access and requires developer credentials.</p>
  ## 
  let valid = call_600166.validator(path, query, header, formData, body)
  let scheme = call_600166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600166.url(scheme.get, call_600166.host, call_600166.base,
                         call_600166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600166, url, valid)

proc call*(call_600167: Call_AdminLinkProviderForUser_600154; body: JsonNode): Recallable =
  ## adminLinkProviderForUser
  ## <p>Links an existing user account in a user pool (<code>DestinationUser</code>) to an identity from an external identity provider (<code>SourceUser</code>) based on a specified attribute name and value from the external identity provider. This allows you to create a link from the existing user account to an external federated user identity that has not yet been used to sign in, so that the federated user identity can be used to sign in as the existing user account. </p> <p> For example, if there is an existing user with a username and password, this API links that user to a federated user identity, so that when the federated user identity is used, the user signs in as the existing user account. </p> <important> <p>Because this API allows a user with an external federated identity to sign in as an existing user in the user pool, it is critical that it only be used with external identity providers and provider attributes that have been trusted by the application owner.</p> </important> <p>See also .</p> <p>This action is enabled only for admin access and requires developer credentials.</p>
  ##   body: JObject (required)
  var body_600168 = newJObject()
  if body != nil:
    body_600168 = body
  result = call_600167.call(nil, nil, nil, nil, body_600168)

var adminLinkProviderForUser* = Call_AdminLinkProviderForUser_600154(
    name: "adminLinkProviderForUser", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminLinkProviderForUser",
    validator: validate_AdminLinkProviderForUser_600155, base: "/",
    url: url_AdminLinkProviderForUser_600156, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminListDevices_600169 = ref object of OpenApiRestCall_599368
proc url_AdminListDevices_600171(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminListDevices_600170(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Lists devices, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
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
  var valid_600172 = header.getOrDefault("X-Amz-Date")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-Date", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-Security-Token")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-Security-Token", valid_600173
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600174 = header.getOrDefault("X-Amz-Target")
  valid_600174 = validateParameter(valid_600174, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminListDevices"))
  if valid_600174 != nil:
    section.add "X-Amz-Target", valid_600174
  var valid_600175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-Content-Sha256", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-Algorithm")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-Algorithm", valid_600176
  var valid_600177 = header.getOrDefault("X-Amz-Signature")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "X-Amz-Signature", valid_600177
  var valid_600178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "X-Amz-SignedHeaders", valid_600178
  var valid_600179 = header.getOrDefault("X-Amz-Credential")
  valid_600179 = validateParameter(valid_600179, JString, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "X-Amz-Credential", valid_600179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600181: Call_AdminListDevices_600169; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists devices, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_600181.validator(path, query, header, formData, body)
  let scheme = call_600181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600181.url(scheme.get, call_600181.host, call_600181.base,
                         call_600181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600181, url, valid)

proc call*(call_600182: Call_AdminListDevices_600169; body: JsonNode): Recallable =
  ## adminListDevices
  ## <p>Lists devices, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_600183 = newJObject()
  if body != nil:
    body_600183 = body
  result = call_600182.call(nil, nil, nil, nil, body_600183)

var adminListDevices* = Call_AdminListDevices_600169(name: "adminListDevices",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminListDevices",
    validator: validate_AdminListDevices_600170, base: "/",
    url: url_AdminListDevices_600171, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminListGroupsForUser_600184 = ref object of OpenApiRestCall_599368
proc url_AdminListGroupsForUser_600186(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminListGroupsForUser_600185(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the groups that the user belongs to.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600187 = query.getOrDefault("Limit")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "Limit", valid_600187
  var valid_600188 = query.getOrDefault("NextToken")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "NextToken", valid_600188
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
  var valid_600189 = header.getOrDefault("X-Amz-Date")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-Date", valid_600189
  var valid_600190 = header.getOrDefault("X-Amz-Security-Token")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-Security-Token", valid_600190
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600191 = header.getOrDefault("X-Amz-Target")
  valid_600191 = validateParameter(valid_600191, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminListGroupsForUser"))
  if valid_600191 != nil:
    section.add "X-Amz-Target", valid_600191
  var valid_600192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "X-Amz-Content-Sha256", valid_600192
  var valid_600193 = header.getOrDefault("X-Amz-Algorithm")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-Algorithm", valid_600193
  var valid_600194 = header.getOrDefault("X-Amz-Signature")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-Signature", valid_600194
  var valid_600195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600195 = validateParameter(valid_600195, JString, required = false,
                                 default = nil)
  if valid_600195 != nil:
    section.add "X-Amz-SignedHeaders", valid_600195
  var valid_600196 = header.getOrDefault("X-Amz-Credential")
  valid_600196 = validateParameter(valid_600196, JString, required = false,
                                 default = nil)
  if valid_600196 != nil:
    section.add "X-Amz-Credential", valid_600196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600198: Call_AdminListGroupsForUser_600184; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the groups that the user belongs to.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_600198.validator(path, query, header, formData, body)
  let scheme = call_600198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600198.url(scheme.get, call_600198.host, call_600198.base,
                         call_600198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600198, url, valid)

proc call*(call_600199: Call_AdminListGroupsForUser_600184; body: JsonNode;
          Limit: string = ""; NextToken: string = ""): Recallable =
  ## adminListGroupsForUser
  ## <p>Lists the groups that the user belongs to.</p> <p>Calling this action requires developer credentials.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600200 = newJObject()
  var body_600201 = newJObject()
  add(query_600200, "Limit", newJString(Limit))
  add(query_600200, "NextToken", newJString(NextToken))
  if body != nil:
    body_600201 = body
  result = call_600199.call(nil, query_600200, nil, nil, body_600201)

var adminListGroupsForUser* = Call_AdminListGroupsForUser_600184(
    name: "adminListGroupsForUser", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminListGroupsForUser",
    validator: validate_AdminListGroupsForUser_600185, base: "/",
    url: url_AdminListGroupsForUser_600186, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminListUserAuthEvents_600203 = ref object of OpenApiRestCall_599368
proc url_AdminListUserAuthEvents_600205(protocol: Scheme; host: string; base: string;
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

proc validate_AdminListUserAuthEvents_600204(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists a history of user activity and any risks detected as part of Amazon Cognito advanced security.
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
  var valid_600206 = query.getOrDefault("NextToken")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "NextToken", valid_600206
  var valid_600207 = query.getOrDefault("MaxResults")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "MaxResults", valid_600207
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
  var valid_600208 = header.getOrDefault("X-Amz-Date")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "X-Amz-Date", valid_600208
  var valid_600209 = header.getOrDefault("X-Amz-Security-Token")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "X-Amz-Security-Token", valid_600209
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600210 = header.getOrDefault("X-Amz-Target")
  valid_600210 = validateParameter(valid_600210, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminListUserAuthEvents"))
  if valid_600210 != nil:
    section.add "X-Amz-Target", valid_600210
  var valid_600211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600211 = validateParameter(valid_600211, JString, required = false,
                                 default = nil)
  if valid_600211 != nil:
    section.add "X-Amz-Content-Sha256", valid_600211
  var valid_600212 = header.getOrDefault("X-Amz-Algorithm")
  valid_600212 = validateParameter(valid_600212, JString, required = false,
                                 default = nil)
  if valid_600212 != nil:
    section.add "X-Amz-Algorithm", valid_600212
  var valid_600213 = header.getOrDefault("X-Amz-Signature")
  valid_600213 = validateParameter(valid_600213, JString, required = false,
                                 default = nil)
  if valid_600213 != nil:
    section.add "X-Amz-Signature", valid_600213
  var valid_600214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600214 = validateParameter(valid_600214, JString, required = false,
                                 default = nil)
  if valid_600214 != nil:
    section.add "X-Amz-SignedHeaders", valid_600214
  var valid_600215 = header.getOrDefault("X-Amz-Credential")
  valid_600215 = validateParameter(valid_600215, JString, required = false,
                                 default = nil)
  if valid_600215 != nil:
    section.add "X-Amz-Credential", valid_600215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600217: Call_AdminListUserAuthEvents_600203; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists a history of user activity and any risks detected as part of Amazon Cognito advanced security.
  ## 
  let valid = call_600217.validator(path, query, header, formData, body)
  let scheme = call_600217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600217.url(scheme.get, call_600217.host, call_600217.base,
                         call_600217.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600217, url, valid)

proc call*(call_600218: Call_AdminListUserAuthEvents_600203; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## adminListUserAuthEvents
  ## Lists a history of user activity and any risks detected as part of Amazon Cognito advanced security.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600219 = newJObject()
  var body_600220 = newJObject()
  add(query_600219, "NextToken", newJString(NextToken))
  if body != nil:
    body_600220 = body
  add(query_600219, "MaxResults", newJString(MaxResults))
  result = call_600218.call(nil, query_600219, nil, nil, body_600220)

var adminListUserAuthEvents* = Call_AdminListUserAuthEvents_600203(
    name: "adminListUserAuthEvents", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminListUserAuthEvents",
    validator: validate_AdminListUserAuthEvents_600204, base: "/",
    url: url_AdminListUserAuthEvents_600205, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminRemoveUserFromGroup_600221 = ref object of OpenApiRestCall_599368
proc url_AdminRemoveUserFromGroup_600223(protocol: Scheme; host: string;
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

proc validate_AdminRemoveUserFromGroup_600222(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes the specified user from the specified group.</p> <p>Calling this action requires developer credentials.</p>
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
  var valid_600224 = header.getOrDefault("X-Amz-Date")
  valid_600224 = validateParameter(valid_600224, JString, required = false,
                                 default = nil)
  if valid_600224 != nil:
    section.add "X-Amz-Date", valid_600224
  var valid_600225 = header.getOrDefault("X-Amz-Security-Token")
  valid_600225 = validateParameter(valid_600225, JString, required = false,
                                 default = nil)
  if valid_600225 != nil:
    section.add "X-Amz-Security-Token", valid_600225
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600226 = header.getOrDefault("X-Amz-Target")
  valid_600226 = validateParameter(valid_600226, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminRemoveUserFromGroup"))
  if valid_600226 != nil:
    section.add "X-Amz-Target", valid_600226
  var valid_600227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600227 = validateParameter(valid_600227, JString, required = false,
                                 default = nil)
  if valid_600227 != nil:
    section.add "X-Amz-Content-Sha256", valid_600227
  var valid_600228 = header.getOrDefault("X-Amz-Algorithm")
  valid_600228 = validateParameter(valid_600228, JString, required = false,
                                 default = nil)
  if valid_600228 != nil:
    section.add "X-Amz-Algorithm", valid_600228
  var valid_600229 = header.getOrDefault("X-Amz-Signature")
  valid_600229 = validateParameter(valid_600229, JString, required = false,
                                 default = nil)
  if valid_600229 != nil:
    section.add "X-Amz-Signature", valid_600229
  var valid_600230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600230 = validateParameter(valid_600230, JString, required = false,
                                 default = nil)
  if valid_600230 != nil:
    section.add "X-Amz-SignedHeaders", valid_600230
  var valid_600231 = header.getOrDefault("X-Amz-Credential")
  valid_600231 = validateParameter(valid_600231, JString, required = false,
                                 default = nil)
  if valid_600231 != nil:
    section.add "X-Amz-Credential", valid_600231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600233: Call_AdminRemoveUserFromGroup_600221; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified user from the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_600233.validator(path, query, header, formData, body)
  let scheme = call_600233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600233.url(scheme.get, call_600233.host, call_600233.base,
                         call_600233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600233, url, valid)

proc call*(call_600234: Call_AdminRemoveUserFromGroup_600221; body: JsonNode): Recallable =
  ## adminRemoveUserFromGroup
  ## <p>Removes the specified user from the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_600235 = newJObject()
  if body != nil:
    body_600235 = body
  result = call_600234.call(nil, nil, nil, nil, body_600235)

var adminRemoveUserFromGroup* = Call_AdminRemoveUserFromGroup_600221(
    name: "adminRemoveUserFromGroup", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminRemoveUserFromGroup",
    validator: validate_AdminRemoveUserFromGroup_600222, base: "/",
    url: url_AdminRemoveUserFromGroup_600223, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminResetUserPassword_600236 = ref object of OpenApiRestCall_599368
proc url_AdminResetUserPassword_600238(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminResetUserPassword_600237(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Resets the specified user's password in a user pool as an administrator. Works on any user.</p> <p>When a developer calls this API, the current password is invalidated, so it must be changed. If a user tries to sign in after the API is called, the app will get a PasswordResetRequiredException exception back and should direct the user down the flow to reset the password, which is the same as the forgot password flow. In addition, if the user pool has phone verification selected and a verified phone number exists for the user, or if email verification is selected and a verified email exists for the user, calling this API will also result in sending a message to the end user with the code to change their password.</p> <p>Calling this action requires developer credentials.</p>
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
  var valid_600239 = header.getOrDefault("X-Amz-Date")
  valid_600239 = validateParameter(valid_600239, JString, required = false,
                                 default = nil)
  if valid_600239 != nil:
    section.add "X-Amz-Date", valid_600239
  var valid_600240 = header.getOrDefault("X-Amz-Security-Token")
  valid_600240 = validateParameter(valid_600240, JString, required = false,
                                 default = nil)
  if valid_600240 != nil:
    section.add "X-Amz-Security-Token", valid_600240
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600241 = header.getOrDefault("X-Amz-Target")
  valid_600241 = validateParameter(valid_600241, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminResetUserPassword"))
  if valid_600241 != nil:
    section.add "X-Amz-Target", valid_600241
  var valid_600242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600242 = validateParameter(valid_600242, JString, required = false,
                                 default = nil)
  if valid_600242 != nil:
    section.add "X-Amz-Content-Sha256", valid_600242
  var valid_600243 = header.getOrDefault("X-Amz-Algorithm")
  valid_600243 = validateParameter(valid_600243, JString, required = false,
                                 default = nil)
  if valid_600243 != nil:
    section.add "X-Amz-Algorithm", valid_600243
  var valid_600244 = header.getOrDefault("X-Amz-Signature")
  valid_600244 = validateParameter(valid_600244, JString, required = false,
                                 default = nil)
  if valid_600244 != nil:
    section.add "X-Amz-Signature", valid_600244
  var valid_600245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600245 = validateParameter(valid_600245, JString, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "X-Amz-SignedHeaders", valid_600245
  var valid_600246 = header.getOrDefault("X-Amz-Credential")
  valid_600246 = validateParameter(valid_600246, JString, required = false,
                                 default = nil)
  if valid_600246 != nil:
    section.add "X-Amz-Credential", valid_600246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600248: Call_AdminResetUserPassword_600236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Resets the specified user's password in a user pool as an administrator. Works on any user.</p> <p>When a developer calls this API, the current password is invalidated, so it must be changed. If a user tries to sign in after the API is called, the app will get a PasswordResetRequiredException exception back and should direct the user down the flow to reset the password, which is the same as the forgot password flow. In addition, if the user pool has phone verification selected and a verified phone number exists for the user, or if email verification is selected and a verified email exists for the user, calling this API will also result in sending a message to the end user with the code to change their password.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_600248.validator(path, query, header, formData, body)
  let scheme = call_600248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600248.url(scheme.get, call_600248.host, call_600248.base,
                         call_600248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600248, url, valid)

proc call*(call_600249: Call_AdminResetUserPassword_600236; body: JsonNode): Recallable =
  ## adminResetUserPassword
  ## <p>Resets the specified user's password in a user pool as an administrator. Works on any user.</p> <p>When a developer calls this API, the current password is invalidated, so it must be changed. If a user tries to sign in after the API is called, the app will get a PasswordResetRequiredException exception back and should direct the user down the flow to reset the password, which is the same as the forgot password flow. In addition, if the user pool has phone verification selected and a verified phone number exists for the user, or if email verification is selected and a verified email exists for the user, calling this API will also result in sending a message to the end user with the code to change their password.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_600250 = newJObject()
  if body != nil:
    body_600250 = body
  result = call_600249.call(nil, nil, nil, nil, body_600250)

var adminResetUserPassword* = Call_AdminResetUserPassword_600236(
    name: "adminResetUserPassword", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminResetUserPassword",
    validator: validate_AdminResetUserPassword_600237, base: "/",
    url: url_AdminResetUserPassword_600238, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminRespondToAuthChallenge_600251 = ref object of OpenApiRestCall_599368
proc url_AdminRespondToAuthChallenge_600253(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminRespondToAuthChallenge_600252(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Responds to an authentication challenge, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
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
  var valid_600254 = header.getOrDefault("X-Amz-Date")
  valid_600254 = validateParameter(valid_600254, JString, required = false,
                                 default = nil)
  if valid_600254 != nil:
    section.add "X-Amz-Date", valid_600254
  var valid_600255 = header.getOrDefault("X-Amz-Security-Token")
  valid_600255 = validateParameter(valid_600255, JString, required = false,
                                 default = nil)
  if valid_600255 != nil:
    section.add "X-Amz-Security-Token", valid_600255
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600256 = header.getOrDefault("X-Amz-Target")
  valid_600256 = validateParameter(valid_600256, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminRespondToAuthChallenge"))
  if valid_600256 != nil:
    section.add "X-Amz-Target", valid_600256
  var valid_600257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600257 = validateParameter(valid_600257, JString, required = false,
                                 default = nil)
  if valid_600257 != nil:
    section.add "X-Amz-Content-Sha256", valid_600257
  var valid_600258 = header.getOrDefault("X-Amz-Algorithm")
  valid_600258 = validateParameter(valid_600258, JString, required = false,
                                 default = nil)
  if valid_600258 != nil:
    section.add "X-Amz-Algorithm", valid_600258
  var valid_600259 = header.getOrDefault("X-Amz-Signature")
  valid_600259 = validateParameter(valid_600259, JString, required = false,
                                 default = nil)
  if valid_600259 != nil:
    section.add "X-Amz-Signature", valid_600259
  var valid_600260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600260 = validateParameter(valid_600260, JString, required = false,
                                 default = nil)
  if valid_600260 != nil:
    section.add "X-Amz-SignedHeaders", valid_600260
  var valid_600261 = header.getOrDefault("X-Amz-Credential")
  valid_600261 = validateParameter(valid_600261, JString, required = false,
                                 default = nil)
  if valid_600261 != nil:
    section.add "X-Amz-Credential", valid_600261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600263: Call_AdminRespondToAuthChallenge_600251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Responds to an authentication challenge, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_600263.validator(path, query, header, formData, body)
  let scheme = call_600263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600263.url(scheme.get, call_600263.host, call_600263.base,
                         call_600263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600263, url, valid)

proc call*(call_600264: Call_AdminRespondToAuthChallenge_600251; body: JsonNode): Recallable =
  ## adminRespondToAuthChallenge
  ## <p>Responds to an authentication challenge, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_600265 = newJObject()
  if body != nil:
    body_600265 = body
  result = call_600264.call(nil, nil, nil, nil, body_600265)

var adminRespondToAuthChallenge* = Call_AdminRespondToAuthChallenge_600251(
    name: "adminRespondToAuthChallenge", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminRespondToAuthChallenge",
    validator: validate_AdminRespondToAuthChallenge_600252, base: "/",
    url: url_AdminRespondToAuthChallenge_600253,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminSetUserMFAPreference_600266 = ref object of OpenApiRestCall_599368
proc url_AdminSetUserMFAPreference_600268(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminSetUserMFAPreference_600267(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the user's multi-factor authentication (MFA) preference, including which MFA options are enabled and if any are preferred. Only one factor can be set as preferred. The preferred MFA factor will be used to authenticate a user if multiple factors are enabled. If multiple options are enabled and no preference is set, a challenge to choose an MFA option will be returned during sign in.
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
  var valid_600269 = header.getOrDefault("X-Amz-Date")
  valid_600269 = validateParameter(valid_600269, JString, required = false,
                                 default = nil)
  if valid_600269 != nil:
    section.add "X-Amz-Date", valid_600269
  var valid_600270 = header.getOrDefault("X-Amz-Security-Token")
  valid_600270 = validateParameter(valid_600270, JString, required = false,
                                 default = nil)
  if valid_600270 != nil:
    section.add "X-Amz-Security-Token", valid_600270
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600271 = header.getOrDefault("X-Amz-Target")
  valid_600271 = validateParameter(valid_600271, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminSetUserMFAPreference"))
  if valid_600271 != nil:
    section.add "X-Amz-Target", valid_600271
  var valid_600272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600272 = validateParameter(valid_600272, JString, required = false,
                                 default = nil)
  if valid_600272 != nil:
    section.add "X-Amz-Content-Sha256", valid_600272
  var valid_600273 = header.getOrDefault("X-Amz-Algorithm")
  valid_600273 = validateParameter(valid_600273, JString, required = false,
                                 default = nil)
  if valid_600273 != nil:
    section.add "X-Amz-Algorithm", valid_600273
  var valid_600274 = header.getOrDefault("X-Amz-Signature")
  valid_600274 = validateParameter(valid_600274, JString, required = false,
                                 default = nil)
  if valid_600274 != nil:
    section.add "X-Amz-Signature", valid_600274
  var valid_600275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600275 = validateParameter(valid_600275, JString, required = false,
                                 default = nil)
  if valid_600275 != nil:
    section.add "X-Amz-SignedHeaders", valid_600275
  var valid_600276 = header.getOrDefault("X-Amz-Credential")
  valid_600276 = validateParameter(valid_600276, JString, required = false,
                                 default = nil)
  if valid_600276 != nil:
    section.add "X-Amz-Credential", valid_600276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600278: Call_AdminSetUserMFAPreference_600266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the user's multi-factor authentication (MFA) preference, including which MFA options are enabled and if any are preferred. Only one factor can be set as preferred. The preferred MFA factor will be used to authenticate a user if multiple factors are enabled. If multiple options are enabled and no preference is set, a challenge to choose an MFA option will be returned during sign in.
  ## 
  let valid = call_600278.validator(path, query, header, formData, body)
  let scheme = call_600278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600278.url(scheme.get, call_600278.host, call_600278.base,
                         call_600278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600278, url, valid)

proc call*(call_600279: Call_AdminSetUserMFAPreference_600266; body: JsonNode): Recallable =
  ## adminSetUserMFAPreference
  ## Sets the user's multi-factor authentication (MFA) preference, including which MFA options are enabled and if any are preferred. Only one factor can be set as preferred. The preferred MFA factor will be used to authenticate a user if multiple factors are enabled. If multiple options are enabled and no preference is set, a challenge to choose an MFA option will be returned during sign in.
  ##   body: JObject (required)
  var body_600280 = newJObject()
  if body != nil:
    body_600280 = body
  result = call_600279.call(nil, nil, nil, nil, body_600280)

var adminSetUserMFAPreference* = Call_AdminSetUserMFAPreference_600266(
    name: "adminSetUserMFAPreference", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminSetUserMFAPreference",
    validator: validate_AdminSetUserMFAPreference_600267, base: "/",
    url: url_AdminSetUserMFAPreference_600268,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminSetUserPassword_600281 = ref object of OpenApiRestCall_599368
proc url_AdminSetUserPassword_600283(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminSetUserPassword_600282(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sets the specified user's password in a user pool as an administrator. Works on any user. </p> <p>The password can be temporary or permanent. If it is temporary, the user status will be placed into the <code>FORCE_CHANGE_PASSWORD</code> state. When the user next tries to sign in, the InitiateAuth/AdminInitiateAuth response will contain the <code>NEW_PASSWORD_REQUIRED</code> challenge. If the user does not sign in before it expires, the user will not be able to sign in and their password will need to be reset by an administrator. </p> <p>Once the user has set a new password, or the password is permanent, the user status will be set to <code>Confirmed</code>.</p>
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
  var valid_600284 = header.getOrDefault("X-Amz-Date")
  valid_600284 = validateParameter(valid_600284, JString, required = false,
                                 default = nil)
  if valid_600284 != nil:
    section.add "X-Amz-Date", valid_600284
  var valid_600285 = header.getOrDefault("X-Amz-Security-Token")
  valid_600285 = validateParameter(valid_600285, JString, required = false,
                                 default = nil)
  if valid_600285 != nil:
    section.add "X-Amz-Security-Token", valid_600285
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600286 = header.getOrDefault("X-Amz-Target")
  valid_600286 = validateParameter(valid_600286, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminSetUserPassword"))
  if valid_600286 != nil:
    section.add "X-Amz-Target", valid_600286
  var valid_600287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600287 = validateParameter(valid_600287, JString, required = false,
                                 default = nil)
  if valid_600287 != nil:
    section.add "X-Amz-Content-Sha256", valid_600287
  var valid_600288 = header.getOrDefault("X-Amz-Algorithm")
  valid_600288 = validateParameter(valid_600288, JString, required = false,
                                 default = nil)
  if valid_600288 != nil:
    section.add "X-Amz-Algorithm", valid_600288
  var valid_600289 = header.getOrDefault("X-Amz-Signature")
  valid_600289 = validateParameter(valid_600289, JString, required = false,
                                 default = nil)
  if valid_600289 != nil:
    section.add "X-Amz-Signature", valid_600289
  var valid_600290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600290 = validateParameter(valid_600290, JString, required = false,
                                 default = nil)
  if valid_600290 != nil:
    section.add "X-Amz-SignedHeaders", valid_600290
  var valid_600291 = header.getOrDefault("X-Amz-Credential")
  valid_600291 = validateParameter(valid_600291, JString, required = false,
                                 default = nil)
  if valid_600291 != nil:
    section.add "X-Amz-Credential", valid_600291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600293: Call_AdminSetUserPassword_600281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the specified user's password in a user pool as an administrator. Works on any user. </p> <p>The password can be temporary or permanent. If it is temporary, the user status will be placed into the <code>FORCE_CHANGE_PASSWORD</code> state. When the user next tries to sign in, the InitiateAuth/AdminInitiateAuth response will contain the <code>NEW_PASSWORD_REQUIRED</code> challenge. If the user does not sign in before it expires, the user will not be able to sign in and their password will need to be reset by an administrator. </p> <p>Once the user has set a new password, or the password is permanent, the user status will be set to <code>Confirmed</code>.</p>
  ## 
  let valid = call_600293.validator(path, query, header, formData, body)
  let scheme = call_600293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600293.url(scheme.get, call_600293.host, call_600293.base,
                         call_600293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600293, url, valid)

proc call*(call_600294: Call_AdminSetUserPassword_600281; body: JsonNode): Recallable =
  ## adminSetUserPassword
  ## <p>Sets the specified user's password in a user pool as an administrator. Works on any user. </p> <p>The password can be temporary or permanent. If it is temporary, the user status will be placed into the <code>FORCE_CHANGE_PASSWORD</code> state. When the user next tries to sign in, the InitiateAuth/AdminInitiateAuth response will contain the <code>NEW_PASSWORD_REQUIRED</code> challenge. If the user does not sign in before it expires, the user will not be able to sign in and their password will need to be reset by an administrator. </p> <p>Once the user has set a new password, or the password is permanent, the user status will be set to <code>Confirmed</code>.</p>
  ##   body: JObject (required)
  var body_600295 = newJObject()
  if body != nil:
    body_600295 = body
  result = call_600294.call(nil, nil, nil, nil, body_600295)

var adminSetUserPassword* = Call_AdminSetUserPassword_600281(
    name: "adminSetUserPassword", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminSetUserPassword",
    validator: validate_AdminSetUserPassword_600282, base: "/",
    url: url_AdminSetUserPassword_600283, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminSetUserSettings_600296 = ref object of OpenApiRestCall_599368
proc url_AdminSetUserSettings_600298(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminSetUserSettings_600297(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  <i>This action is no longer supported.</i> You can use it to configure only SMS MFA. You can't use it to configure TOTP software token MFA. To configure either type of MFA, use the <a>AdminSetUserMFAPreference</a> action instead.
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
  var valid_600299 = header.getOrDefault("X-Amz-Date")
  valid_600299 = validateParameter(valid_600299, JString, required = false,
                                 default = nil)
  if valid_600299 != nil:
    section.add "X-Amz-Date", valid_600299
  var valid_600300 = header.getOrDefault("X-Amz-Security-Token")
  valid_600300 = validateParameter(valid_600300, JString, required = false,
                                 default = nil)
  if valid_600300 != nil:
    section.add "X-Amz-Security-Token", valid_600300
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600301 = header.getOrDefault("X-Amz-Target")
  valid_600301 = validateParameter(valid_600301, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminSetUserSettings"))
  if valid_600301 != nil:
    section.add "X-Amz-Target", valid_600301
  var valid_600302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600302 = validateParameter(valid_600302, JString, required = false,
                                 default = nil)
  if valid_600302 != nil:
    section.add "X-Amz-Content-Sha256", valid_600302
  var valid_600303 = header.getOrDefault("X-Amz-Algorithm")
  valid_600303 = validateParameter(valid_600303, JString, required = false,
                                 default = nil)
  if valid_600303 != nil:
    section.add "X-Amz-Algorithm", valid_600303
  var valid_600304 = header.getOrDefault("X-Amz-Signature")
  valid_600304 = validateParameter(valid_600304, JString, required = false,
                                 default = nil)
  if valid_600304 != nil:
    section.add "X-Amz-Signature", valid_600304
  var valid_600305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600305 = validateParameter(valid_600305, JString, required = false,
                                 default = nil)
  if valid_600305 != nil:
    section.add "X-Amz-SignedHeaders", valid_600305
  var valid_600306 = header.getOrDefault("X-Amz-Credential")
  valid_600306 = validateParameter(valid_600306, JString, required = false,
                                 default = nil)
  if valid_600306 != nil:
    section.add "X-Amz-Credential", valid_600306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600308: Call_AdminSetUserSettings_600296; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <i>This action is no longer supported.</i> You can use it to configure only SMS MFA. You can't use it to configure TOTP software token MFA. To configure either type of MFA, use the <a>AdminSetUserMFAPreference</a> action instead.
  ## 
  let valid = call_600308.validator(path, query, header, formData, body)
  let scheme = call_600308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600308.url(scheme.get, call_600308.host, call_600308.base,
                         call_600308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600308, url, valid)

proc call*(call_600309: Call_AdminSetUserSettings_600296; body: JsonNode): Recallable =
  ## adminSetUserSettings
  ##  <i>This action is no longer supported.</i> You can use it to configure only SMS MFA. You can't use it to configure TOTP software token MFA. To configure either type of MFA, use the <a>AdminSetUserMFAPreference</a> action instead.
  ##   body: JObject (required)
  var body_600310 = newJObject()
  if body != nil:
    body_600310 = body
  result = call_600309.call(nil, nil, nil, nil, body_600310)

var adminSetUserSettings* = Call_AdminSetUserSettings_600296(
    name: "adminSetUserSettings", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminSetUserSettings",
    validator: validate_AdminSetUserSettings_600297, base: "/",
    url: url_AdminSetUserSettings_600298, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUpdateAuthEventFeedback_600311 = ref object of OpenApiRestCall_599368
proc url_AdminUpdateAuthEventFeedback_600313(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminUpdateAuthEventFeedback_600312(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Provides feedback for an authentication event as to whether it was from a valid user. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
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
  var valid_600314 = header.getOrDefault("X-Amz-Date")
  valid_600314 = validateParameter(valid_600314, JString, required = false,
                                 default = nil)
  if valid_600314 != nil:
    section.add "X-Amz-Date", valid_600314
  var valid_600315 = header.getOrDefault("X-Amz-Security-Token")
  valid_600315 = validateParameter(valid_600315, JString, required = false,
                                 default = nil)
  if valid_600315 != nil:
    section.add "X-Amz-Security-Token", valid_600315
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600316 = header.getOrDefault("X-Amz-Target")
  valid_600316 = validateParameter(valid_600316, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUpdateAuthEventFeedback"))
  if valid_600316 != nil:
    section.add "X-Amz-Target", valid_600316
  var valid_600317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600317 = validateParameter(valid_600317, JString, required = false,
                                 default = nil)
  if valid_600317 != nil:
    section.add "X-Amz-Content-Sha256", valid_600317
  var valid_600318 = header.getOrDefault("X-Amz-Algorithm")
  valid_600318 = validateParameter(valid_600318, JString, required = false,
                                 default = nil)
  if valid_600318 != nil:
    section.add "X-Amz-Algorithm", valid_600318
  var valid_600319 = header.getOrDefault("X-Amz-Signature")
  valid_600319 = validateParameter(valid_600319, JString, required = false,
                                 default = nil)
  if valid_600319 != nil:
    section.add "X-Amz-Signature", valid_600319
  var valid_600320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600320 = validateParameter(valid_600320, JString, required = false,
                                 default = nil)
  if valid_600320 != nil:
    section.add "X-Amz-SignedHeaders", valid_600320
  var valid_600321 = header.getOrDefault("X-Amz-Credential")
  valid_600321 = validateParameter(valid_600321, JString, required = false,
                                 default = nil)
  if valid_600321 != nil:
    section.add "X-Amz-Credential", valid_600321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600323: Call_AdminUpdateAuthEventFeedback_600311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides feedback for an authentication event as to whether it was from a valid user. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ## 
  let valid = call_600323.validator(path, query, header, formData, body)
  let scheme = call_600323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600323.url(scheme.get, call_600323.host, call_600323.base,
                         call_600323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600323, url, valid)

proc call*(call_600324: Call_AdminUpdateAuthEventFeedback_600311; body: JsonNode): Recallable =
  ## adminUpdateAuthEventFeedback
  ## Provides feedback for an authentication event as to whether it was from a valid user. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ##   body: JObject (required)
  var body_600325 = newJObject()
  if body != nil:
    body_600325 = body
  result = call_600324.call(nil, nil, nil, nil, body_600325)

var adminUpdateAuthEventFeedback* = Call_AdminUpdateAuthEventFeedback_600311(
    name: "adminUpdateAuthEventFeedback", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUpdateAuthEventFeedback",
    validator: validate_AdminUpdateAuthEventFeedback_600312, base: "/",
    url: url_AdminUpdateAuthEventFeedback_600313,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUpdateDeviceStatus_600326 = ref object of OpenApiRestCall_599368
proc url_AdminUpdateDeviceStatus_600328(protocol: Scheme; host: string; base: string;
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

proc validate_AdminUpdateDeviceStatus_600327(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the device status as an administrator.</p> <p>Calling this action requires developer credentials.</p>
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
  var valid_600329 = header.getOrDefault("X-Amz-Date")
  valid_600329 = validateParameter(valid_600329, JString, required = false,
                                 default = nil)
  if valid_600329 != nil:
    section.add "X-Amz-Date", valid_600329
  var valid_600330 = header.getOrDefault("X-Amz-Security-Token")
  valid_600330 = validateParameter(valid_600330, JString, required = false,
                                 default = nil)
  if valid_600330 != nil:
    section.add "X-Amz-Security-Token", valid_600330
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600331 = header.getOrDefault("X-Amz-Target")
  valid_600331 = validateParameter(valid_600331, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUpdateDeviceStatus"))
  if valid_600331 != nil:
    section.add "X-Amz-Target", valid_600331
  var valid_600332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600332 = validateParameter(valid_600332, JString, required = false,
                                 default = nil)
  if valid_600332 != nil:
    section.add "X-Amz-Content-Sha256", valid_600332
  var valid_600333 = header.getOrDefault("X-Amz-Algorithm")
  valid_600333 = validateParameter(valid_600333, JString, required = false,
                                 default = nil)
  if valid_600333 != nil:
    section.add "X-Amz-Algorithm", valid_600333
  var valid_600334 = header.getOrDefault("X-Amz-Signature")
  valid_600334 = validateParameter(valid_600334, JString, required = false,
                                 default = nil)
  if valid_600334 != nil:
    section.add "X-Amz-Signature", valid_600334
  var valid_600335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600335 = validateParameter(valid_600335, JString, required = false,
                                 default = nil)
  if valid_600335 != nil:
    section.add "X-Amz-SignedHeaders", valid_600335
  var valid_600336 = header.getOrDefault("X-Amz-Credential")
  valid_600336 = validateParameter(valid_600336, JString, required = false,
                                 default = nil)
  if valid_600336 != nil:
    section.add "X-Amz-Credential", valid_600336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600338: Call_AdminUpdateDeviceStatus_600326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the device status as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_600338.validator(path, query, header, formData, body)
  let scheme = call_600338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600338.url(scheme.get, call_600338.host, call_600338.base,
                         call_600338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600338, url, valid)

proc call*(call_600339: Call_AdminUpdateDeviceStatus_600326; body: JsonNode): Recallable =
  ## adminUpdateDeviceStatus
  ## <p>Updates the device status as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_600340 = newJObject()
  if body != nil:
    body_600340 = body
  result = call_600339.call(nil, nil, nil, nil, body_600340)

var adminUpdateDeviceStatus* = Call_AdminUpdateDeviceStatus_600326(
    name: "adminUpdateDeviceStatus", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUpdateDeviceStatus",
    validator: validate_AdminUpdateDeviceStatus_600327, base: "/",
    url: url_AdminUpdateDeviceStatus_600328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUpdateUserAttributes_600341 = ref object of OpenApiRestCall_599368
proc url_AdminUpdateUserAttributes_600343(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminUpdateUserAttributes_600342(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the specified user's attributes, including developer attributes, as an administrator. Works on any user.</p> <p>For custom attributes, you must prepend the <code>custom:</code> prefix to the attribute name.</p> <p>In addition to updating user attributes, this API can also be used to mark phone and email as verified.</p> <p>Calling this action requires developer credentials.</p>
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
  var valid_600344 = header.getOrDefault("X-Amz-Date")
  valid_600344 = validateParameter(valid_600344, JString, required = false,
                                 default = nil)
  if valid_600344 != nil:
    section.add "X-Amz-Date", valid_600344
  var valid_600345 = header.getOrDefault("X-Amz-Security-Token")
  valid_600345 = validateParameter(valid_600345, JString, required = false,
                                 default = nil)
  if valid_600345 != nil:
    section.add "X-Amz-Security-Token", valid_600345
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600346 = header.getOrDefault("X-Amz-Target")
  valid_600346 = validateParameter(valid_600346, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUpdateUserAttributes"))
  if valid_600346 != nil:
    section.add "X-Amz-Target", valid_600346
  var valid_600347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600347 = validateParameter(valid_600347, JString, required = false,
                                 default = nil)
  if valid_600347 != nil:
    section.add "X-Amz-Content-Sha256", valid_600347
  var valid_600348 = header.getOrDefault("X-Amz-Algorithm")
  valid_600348 = validateParameter(valid_600348, JString, required = false,
                                 default = nil)
  if valid_600348 != nil:
    section.add "X-Amz-Algorithm", valid_600348
  var valid_600349 = header.getOrDefault("X-Amz-Signature")
  valid_600349 = validateParameter(valid_600349, JString, required = false,
                                 default = nil)
  if valid_600349 != nil:
    section.add "X-Amz-Signature", valid_600349
  var valid_600350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600350 = validateParameter(valid_600350, JString, required = false,
                                 default = nil)
  if valid_600350 != nil:
    section.add "X-Amz-SignedHeaders", valid_600350
  var valid_600351 = header.getOrDefault("X-Amz-Credential")
  valid_600351 = validateParameter(valid_600351, JString, required = false,
                                 default = nil)
  if valid_600351 != nil:
    section.add "X-Amz-Credential", valid_600351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600353: Call_AdminUpdateUserAttributes_600341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified user's attributes, including developer attributes, as an administrator. Works on any user.</p> <p>For custom attributes, you must prepend the <code>custom:</code> prefix to the attribute name.</p> <p>In addition to updating user attributes, this API can also be used to mark phone and email as verified.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_600353.validator(path, query, header, formData, body)
  let scheme = call_600353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600353.url(scheme.get, call_600353.host, call_600353.base,
                         call_600353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600353, url, valid)

proc call*(call_600354: Call_AdminUpdateUserAttributes_600341; body: JsonNode): Recallable =
  ## adminUpdateUserAttributes
  ## <p>Updates the specified user's attributes, including developer attributes, as an administrator. Works on any user.</p> <p>For custom attributes, you must prepend the <code>custom:</code> prefix to the attribute name.</p> <p>In addition to updating user attributes, this API can also be used to mark phone and email as verified.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_600355 = newJObject()
  if body != nil:
    body_600355 = body
  result = call_600354.call(nil, nil, nil, nil, body_600355)

var adminUpdateUserAttributes* = Call_AdminUpdateUserAttributes_600341(
    name: "adminUpdateUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUpdateUserAttributes",
    validator: validate_AdminUpdateUserAttributes_600342, base: "/",
    url: url_AdminUpdateUserAttributes_600343,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUserGlobalSignOut_600356 = ref object of OpenApiRestCall_599368
proc url_AdminUserGlobalSignOut_600358(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminUserGlobalSignOut_600357(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Signs out users from all devices, as an administrator. It also invalidates all refresh tokens issued to a user. The user's current access and Id tokens remain valid until their expiry. Access and Id tokens expire one hour after they are issued.</p> <p>Calling this action requires developer credentials.</p>
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
  var valid_600359 = header.getOrDefault("X-Amz-Date")
  valid_600359 = validateParameter(valid_600359, JString, required = false,
                                 default = nil)
  if valid_600359 != nil:
    section.add "X-Amz-Date", valid_600359
  var valid_600360 = header.getOrDefault("X-Amz-Security-Token")
  valid_600360 = validateParameter(valid_600360, JString, required = false,
                                 default = nil)
  if valid_600360 != nil:
    section.add "X-Amz-Security-Token", valid_600360
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600361 = header.getOrDefault("X-Amz-Target")
  valid_600361 = validateParameter(valid_600361, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUserGlobalSignOut"))
  if valid_600361 != nil:
    section.add "X-Amz-Target", valid_600361
  var valid_600362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600362 = validateParameter(valid_600362, JString, required = false,
                                 default = nil)
  if valid_600362 != nil:
    section.add "X-Amz-Content-Sha256", valid_600362
  var valid_600363 = header.getOrDefault("X-Amz-Algorithm")
  valid_600363 = validateParameter(valid_600363, JString, required = false,
                                 default = nil)
  if valid_600363 != nil:
    section.add "X-Amz-Algorithm", valid_600363
  var valid_600364 = header.getOrDefault("X-Amz-Signature")
  valid_600364 = validateParameter(valid_600364, JString, required = false,
                                 default = nil)
  if valid_600364 != nil:
    section.add "X-Amz-Signature", valid_600364
  var valid_600365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600365 = validateParameter(valid_600365, JString, required = false,
                                 default = nil)
  if valid_600365 != nil:
    section.add "X-Amz-SignedHeaders", valid_600365
  var valid_600366 = header.getOrDefault("X-Amz-Credential")
  valid_600366 = validateParameter(valid_600366, JString, required = false,
                                 default = nil)
  if valid_600366 != nil:
    section.add "X-Amz-Credential", valid_600366
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600368: Call_AdminUserGlobalSignOut_600356; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Signs out users from all devices, as an administrator. It also invalidates all refresh tokens issued to a user. The user's current access and Id tokens remain valid until their expiry. Access and Id tokens expire one hour after they are issued.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_600368.validator(path, query, header, formData, body)
  let scheme = call_600368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600368.url(scheme.get, call_600368.host, call_600368.base,
                         call_600368.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600368, url, valid)

proc call*(call_600369: Call_AdminUserGlobalSignOut_600356; body: JsonNode): Recallable =
  ## adminUserGlobalSignOut
  ## <p>Signs out users from all devices, as an administrator. It also invalidates all refresh tokens issued to a user. The user's current access and Id tokens remain valid until their expiry. Access and Id tokens expire one hour after they are issued.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_600370 = newJObject()
  if body != nil:
    body_600370 = body
  result = call_600369.call(nil, nil, nil, nil, body_600370)

var adminUserGlobalSignOut* = Call_AdminUserGlobalSignOut_600356(
    name: "adminUserGlobalSignOut", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUserGlobalSignOut",
    validator: validate_AdminUserGlobalSignOut_600357, base: "/",
    url: url_AdminUserGlobalSignOut_600358, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSoftwareToken_600371 = ref object of OpenApiRestCall_599368
proc url_AssociateSoftwareToken_600373(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateSoftwareToken_600372(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a unique generated shared secret key code for the user account. The request takes an access token or a session string, but not both.
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
  var valid_600374 = header.getOrDefault("X-Amz-Date")
  valid_600374 = validateParameter(valid_600374, JString, required = false,
                                 default = nil)
  if valid_600374 != nil:
    section.add "X-Amz-Date", valid_600374
  var valid_600375 = header.getOrDefault("X-Amz-Security-Token")
  valid_600375 = validateParameter(valid_600375, JString, required = false,
                                 default = nil)
  if valid_600375 != nil:
    section.add "X-Amz-Security-Token", valid_600375
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600376 = header.getOrDefault("X-Amz-Target")
  valid_600376 = validateParameter(valid_600376, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AssociateSoftwareToken"))
  if valid_600376 != nil:
    section.add "X-Amz-Target", valid_600376
  var valid_600377 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600377 = validateParameter(valid_600377, JString, required = false,
                                 default = nil)
  if valid_600377 != nil:
    section.add "X-Amz-Content-Sha256", valid_600377
  var valid_600378 = header.getOrDefault("X-Amz-Algorithm")
  valid_600378 = validateParameter(valid_600378, JString, required = false,
                                 default = nil)
  if valid_600378 != nil:
    section.add "X-Amz-Algorithm", valid_600378
  var valid_600379 = header.getOrDefault("X-Amz-Signature")
  valid_600379 = validateParameter(valid_600379, JString, required = false,
                                 default = nil)
  if valid_600379 != nil:
    section.add "X-Amz-Signature", valid_600379
  var valid_600380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600380 = validateParameter(valid_600380, JString, required = false,
                                 default = nil)
  if valid_600380 != nil:
    section.add "X-Amz-SignedHeaders", valid_600380
  var valid_600381 = header.getOrDefault("X-Amz-Credential")
  valid_600381 = validateParameter(valid_600381, JString, required = false,
                                 default = nil)
  if valid_600381 != nil:
    section.add "X-Amz-Credential", valid_600381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600383: Call_AssociateSoftwareToken_600371; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a unique generated shared secret key code for the user account. The request takes an access token or a session string, but not both.
  ## 
  let valid = call_600383.validator(path, query, header, formData, body)
  let scheme = call_600383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600383.url(scheme.get, call_600383.host, call_600383.base,
                         call_600383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600383, url, valid)

proc call*(call_600384: Call_AssociateSoftwareToken_600371; body: JsonNode): Recallable =
  ## associateSoftwareToken
  ## Returns a unique generated shared secret key code for the user account. The request takes an access token or a session string, but not both.
  ##   body: JObject (required)
  var body_600385 = newJObject()
  if body != nil:
    body_600385 = body
  result = call_600384.call(nil, nil, nil, nil, body_600385)

var associateSoftwareToken* = Call_AssociateSoftwareToken_600371(
    name: "associateSoftwareToken", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AssociateSoftwareToken",
    validator: validate_AssociateSoftwareToken_600372, base: "/",
    url: url_AssociateSoftwareToken_600373, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ChangePassword_600386 = ref object of OpenApiRestCall_599368
proc url_ChangePassword_600388(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ChangePassword_600387(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Changes the password for a specified user in a user pool.
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
  var valid_600389 = header.getOrDefault("X-Amz-Date")
  valid_600389 = validateParameter(valid_600389, JString, required = false,
                                 default = nil)
  if valid_600389 != nil:
    section.add "X-Amz-Date", valid_600389
  var valid_600390 = header.getOrDefault("X-Amz-Security-Token")
  valid_600390 = validateParameter(valid_600390, JString, required = false,
                                 default = nil)
  if valid_600390 != nil:
    section.add "X-Amz-Security-Token", valid_600390
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600391 = header.getOrDefault("X-Amz-Target")
  valid_600391 = validateParameter(valid_600391, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ChangePassword"))
  if valid_600391 != nil:
    section.add "X-Amz-Target", valid_600391
  var valid_600392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600392 = validateParameter(valid_600392, JString, required = false,
                                 default = nil)
  if valid_600392 != nil:
    section.add "X-Amz-Content-Sha256", valid_600392
  var valid_600393 = header.getOrDefault("X-Amz-Algorithm")
  valid_600393 = validateParameter(valid_600393, JString, required = false,
                                 default = nil)
  if valid_600393 != nil:
    section.add "X-Amz-Algorithm", valid_600393
  var valid_600394 = header.getOrDefault("X-Amz-Signature")
  valid_600394 = validateParameter(valid_600394, JString, required = false,
                                 default = nil)
  if valid_600394 != nil:
    section.add "X-Amz-Signature", valid_600394
  var valid_600395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600395 = validateParameter(valid_600395, JString, required = false,
                                 default = nil)
  if valid_600395 != nil:
    section.add "X-Amz-SignedHeaders", valid_600395
  var valid_600396 = header.getOrDefault("X-Amz-Credential")
  valid_600396 = validateParameter(valid_600396, JString, required = false,
                                 default = nil)
  if valid_600396 != nil:
    section.add "X-Amz-Credential", valid_600396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600398: Call_ChangePassword_600386; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the password for a specified user in a user pool.
  ## 
  let valid = call_600398.validator(path, query, header, formData, body)
  let scheme = call_600398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600398.url(scheme.get, call_600398.host, call_600398.base,
                         call_600398.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600398, url, valid)

proc call*(call_600399: Call_ChangePassword_600386; body: JsonNode): Recallable =
  ## changePassword
  ## Changes the password for a specified user in a user pool.
  ##   body: JObject (required)
  var body_600400 = newJObject()
  if body != nil:
    body_600400 = body
  result = call_600399.call(nil, nil, nil, nil, body_600400)

var changePassword* = Call_ChangePassword_600386(name: "changePassword",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ChangePassword",
    validator: validate_ChangePassword_600387, base: "/", url: url_ChangePassword_600388,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmDevice_600401 = ref object of OpenApiRestCall_599368
proc url_ConfirmDevice_600403(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ConfirmDevice_600402(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Confirms tracking of the device. This API call is the call that begins device tracking.
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
  var valid_600404 = header.getOrDefault("X-Amz-Date")
  valid_600404 = validateParameter(valid_600404, JString, required = false,
                                 default = nil)
  if valid_600404 != nil:
    section.add "X-Amz-Date", valid_600404
  var valid_600405 = header.getOrDefault("X-Amz-Security-Token")
  valid_600405 = validateParameter(valid_600405, JString, required = false,
                                 default = nil)
  if valid_600405 != nil:
    section.add "X-Amz-Security-Token", valid_600405
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600406 = header.getOrDefault("X-Amz-Target")
  valid_600406 = validateParameter(valid_600406, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ConfirmDevice"))
  if valid_600406 != nil:
    section.add "X-Amz-Target", valid_600406
  var valid_600407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600407 = validateParameter(valid_600407, JString, required = false,
                                 default = nil)
  if valid_600407 != nil:
    section.add "X-Amz-Content-Sha256", valid_600407
  var valid_600408 = header.getOrDefault("X-Amz-Algorithm")
  valid_600408 = validateParameter(valid_600408, JString, required = false,
                                 default = nil)
  if valid_600408 != nil:
    section.add "X-Amz-Algorithm", valid_600408
  var valid_600409 = header.getOrDefault("X-Amz-Signature")
  valid_600409 = validateParameter(valid_600409, JString, required = false,
                                 default = nil)
  if valid_600409 != nil:
    section.add "X-Amz-Signature", valid_600409
  var valid_600410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600410 = validateParameter(valid_600410, JString, required = false,
                                 default = nil)
  if valid_600410 != nil:
    section.add "X-Amz-SignedHeaders", valid_600410
  var valid_600411 = header.getOrDefault("X-Amz-Credential")
  valid_600411 = validateParameter(valid_600411, JString, required = false,
                                 default = nil)
  if valid_600411 != nil:
    section.add "X-Amz-Credential", valid_600411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600413: Call_ConfirmDevice_600401; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Confirms tracking of the device. This API call is the call that begins device tracking.
  ## 
  let valid = call_600413.validator(path, query, header, formData, body)
  let scheme = call_600413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600413.url(scheme.get, call_600413.host, call_600413.base,
                         call_600413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600413, url, valid)

proc call*(call_600414: Call_ConfirmDevice_600401; body: JsonNode): Recallable =
  ## confirmDevice
  ## Confirms tracking of the device. This API call is the call that begins device tracking.
  ##   body: JObject (required)
  var body_600415 = newJObject()
  if body != nil:
    body_600415 = body
  result = call_600414.call(nil, nil, nil, nil, body_600415)

var confirmDevice* = Call_ConfirmDevice_600401(name: "confirmDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ConfirmDevice",
    validator: validate_ConfirmDevice_600402, base: "/", url: url_ConfirmDevice_600403,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmForgotPassword_600416 = ref object of OpenApiRestCall_599368
proc url_ConfirmForgotPassword_600418(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ConfirmForgotPassword_600417(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Allows a user to enter a confirmation code to reset a forgotten password.
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
      "AWSCognitoIdentityProviderService.ConfirmForgotPassword"))
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

proc call*(call_600428: Call_ConfirmForgotPassword_600416; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a user to enter a confirmation code to reset a forgotten password.
  ## 
  let valid = call_600428.validator(path, query, header, formData, body)
  let scheme = call_600428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600428.url(scheme.get, call_600428.host, call_600428.base,
                         call_600428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600428, url, valid)

proc call*(call_600429: Call_ConfirmForgotPassword_600416; body: JsonNode): Recallable =
  ## confirmForgotPassword
  ## Allows a user to enter a confirmation code to reset a forgotten password.
  ##   body: JObject (required)
  var body_600430 = newJObject()
  if body != nil:
    body_600430 = body
  result = call_600429.call(nil, nil, nil, nil, body_600430)

var confirmForgotPassword* = Call_ConfirmForgotPassword_600416(
    name: "confirmForgotPassword", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ConfirmForgotPassword",
    validator: validate_ConfirmForgotPassword_600417, base: "/",
    url: url_ConfirmForgotPassword_600418, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmSignUp_600431 = ref object of OpenApiRestCall_599368
proc url_ConfirmSignUp_600433(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ConfirmSignUp_600432(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Confirms registration of a user and handles the existing alias from a previous user.
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
  var valid_600434 = header.getOrDefault("X-Amz-Date")
  valid_600434 = validateParameter(valid_600434, JString, required = false,
                                 default = nil)
  if valid_600434 != nil:
    section.add "X-Amz-Date", valid_600434
  var valid_600435 = header.getOrDefault("X-Amz-Security-Token")
  valid_600435 = validateParameter(valid_600435, JString, required = false,
                                 default = nil)
  if valid_600435 != nil:
    section.add "X-Amz-Security-Token", valid_600435
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600436 = header.getOrDefault("X-Amz-Target")
  valid_600436 = validateParameter(valid_600436, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ConfirmSignUp"))
  if valid_600436 != nil:
    section.add "X-Amz-Target", valid_600436
  var valid_600437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600437 = validateParameter(valid_600437, JString, required = false,
                                 default = nil)
  if valid_600437 != nil:
    section.add "X-Amz-Content-Sha256", valid_600437
  var valid_600438 = header.getOrDefault("X-Amz-Algorithm")
  valid_600438 = validateParameter(valid_600438, JString, required = false,
                                 default = nil)
  if valid_600438 != nil:
    section.add "X-Amz-Algorithm", valid_600438
  var valid_600439 = header.getOrDefault("X-Amz-Signature")
  valid_600439 = validateParameter(valid_600439, JString, required = false,
                                 default = nil)
  if valid_600439 != nil:
    section.add "X-Amz-Signature", valid_600439
  var valid_600440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600440 = validateParameter(valid_600440, JString, required = false,
                                 default = nil)
  if valid_600440 != nil:
    section.add "X-Amz-SignedHeaders", valid_600440
  var valid_600441 = header.getOrDefault("X-Amz-Credential")
  valid_600441 = validateParameter(valid_600441, JString, required = false,
                                 default = nil)
  if valid_600441 != nil:
    section.add "X-Amz-Credential", valid_600441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600443: Call_ConfirmSignUp_600431; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Confirms registration of a user and handles the existing alias from a previous user.
  ## 
  let valid = call_600443.validator(path, query, header, formData, body)
  let scheme = call_600443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600443.url(scheme.get, call_600443.host, call_600443.base,
                         call_600443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600443, url, valid)

proc call*(call_600444: Call_ConfirmSignUp_600431; body: JsonNode): Recallable =
  ## confirmSignUp
  ## Confirms registration of a user and handles the existing alias from a previous user.
  ##   body: JObject (required)
  var body_600445 = newJObject()
  if body != nil:
    body_600445 = body
  result = call_600444.call(nil, nil, nil, nil, body_600445)

var confirmSignUp* = Call_ConfirmSignUp_600431(name: "confirmSignUp",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ConfirmSignUp",
    validator: validate_ConfirmSignUp_600432, base: "/", url: url_ConfirmSignUp_600433,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_600446 = ref object of OpenApiRestCall_599368
proc url_CreateGroup_600448(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateGroup_600447(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new group in the specified user pool.</p> <p>Calling this action requires developer credentials.</p>
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
  var valid_600449 = header.getOrDefault("X-Amz-Date")
  valid_600449 = validateParameter(valid_600449, JString, required = false,
                                 default = nil)
  if valid_600449 != nil:
    section.add "X-Amz-Date", valid_600449
  var valid_600450 = header.getOrDefault("X-Amz-Security-Token")
  valid_600450 = validateParameter(valid_600450, JString, required = false,
                                 default = nil)
  if valid_600450 != nil:
    section.add "X-Amz-Security-Token", valid_600450
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600451 = header.getOrDefault("X-Amz-Target")
  valid_600451 = validateParameter(valid_600451, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateGroup"))
  if valid_600451 != nil:
    section.add "X-Amz-Target", valid_600451
  var valid_600452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600452 = validateParameter(valid_600452, JString, required = false,
                                 default = nil)
  if valid_600452 != nil:
    section.add "X-Amz-Content-Sha256", valid_600452
  var valid_600453 = header.getOrDefault("X-Amz-Algorithm")
  valid_600453 = validateParameter(valid_600453, JString, required = false,
                                 default = nil)
  if valid_600453 != nil:
    section.add "X-Amz-Algorithm", valid_600453
  var valid_600454 = header.getOrDefault("X-Amz-Signature")
  valid_600454 = validateParameter(valid_600454, JString, required = false,
                                 default = nil)
  if valid_600454 != nil:
    section.add "X-Amz-Signature", valid_600454
  var valid_600455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600455 = validateParameter(valid_600455, JString, required = false,
                                 default = nil)
  if valid_600455 != nil:
    section.add "X-Amz-SignedHeaders", valid_600455
  var valid_600456 = header.getOrDefault("X-Amz-Credential")
  valid_600456 = validateParameter(valid_600456, JString, required = false,
                                 default = nil)
  if valid_600456 != nil:
    section.add "X-Amz-Credential", valid_600456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600458: Call_CreateGroup_600446; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new group in the specified user pool.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_600458.validator(path, query, header, formData, body)
  let scheme = call_600458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600458.url(scheme.get, call_600458.host, call_600458.base,
                         call_600458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600458, url, valid)

proc call*(call_600459: Call_CreateGroup_600446; body: JsonNode): Recallable =
  ## createGroup
  ## <p>Creates a new group in the specified user pool.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_600460 = newJObject()
  if body != nil:
    body_600460 = body
  result = call_600459.call(nil, nil, nil, nil, body_600460)

var createGroup* = Call_CreateGroup_600446(name: "createGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateGroup",
                                        validator: validate_CreateGroup_600447,
                                        base: "/", url: url_CreateGroup_600448,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIdentityProvider_600461 = ref object of OpenApiRestCall_599368
proc url_CreateIdentityProvider_600463(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateIdentityProvider_600462(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an identity provider for a user pool.
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
  var valid_600464 = header.getOrDefault("X-Amz-Date")
  valid_600464 = validateParameter(valid_600464, JString, required = false,
                                 default = nil)
  if valid_600464 != nil:
    section.add "X-Amz-Date", valid_600464
  var valid_600465 = header.getOrDefault("X-Amz-Security-Token")
  valid_600465 = validateParameter(valid_600465, JString, required = false,
                                 default = nil)
  if valid_600465 != nil:
    section.add "X-Amz-Security-Token", valid_600465
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600466 = header.getOrDefault("X-Amz-Target")
  valid_600466 = validateParameter(valid_600466, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateIdentityProvider"))
  if valid_600466 != nil:
    section.add "X-Amz-Target", valid_600466
  var valid_600467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600467 = validateParameter(valid_600467, JString, required = false,
                                 default = nil)
  if valid_600467 != nil:
    section.add "X-Amz-Content-Sha256", valid_600467
  var valid_600468 = header.getOrDefault("X-Amz-Algorithm")
  valid_600468 = validateParameter(valid_600468, JString, required = false,
                                 default = nil)
  if valid_600468 != nil:
    section.add "X-Amz-Algorithm", valid_600468
  var valid_600469 = header.getOrDefault("X-Amz-Signature")
  valid_600469 = validateParameter(valid_600469, JString, required = false,
                                 default = nil)
  if valid_600469 != nil:
    section.add "X-Amz-Signature", valid_600469
  var valid_600470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600470 = validateParameter(valid_600470, JString, required = false,
                                 default = nil)
  if valid_600470 != nil:
    section.add "X-Amz-SignedHeaders", valid_600470
  var valid_600471 = header.getOrDefault("X-Amz-Credential")
  valid_600471 = validateParameter(valid_600471, JString, required = false,
                                 default = nil)
  if valid_600471 != nil:
    section.add "X-Amz-Credential", valid_600471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600473: Call_CreateIdentityProvider_600461; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an identity provider for a user pool.
  ## 
  let valid = call_600473.validator(path, query, header, formData, body)
  let scheme = call_600473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600473.url(scheme.get, call_600473.host, call_600473.base,
                         call_600473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600473, url, valid)

proc call*(call_600474: Call_CreateIdentityProvider_600461; body: JsonNode): Recallable =
  ## createIdentityProvider
  ## Creates an identity provider for a user pool.
  ##   body: JObject (required)
  var body_600475 = newJObject()
  if body != nil:
    body_600475 = body
  result = call_600474.call(nil, nil, nil, nil, body_600475)

var createIdentityProvider* = Call_CreateIdentityProvider_600461(
    name: "createIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateIdentityProvider",
    validator: validate_CreateIdentityProvider_600462, base: "/",
    url: url_CreateIdentityProvider_600463, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceServer_600476 = ref object of OpenApiRestCall_599368
proc url_CreateResourceServer_600478(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateResourceServer_600477(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new OAuth2.0 resource server and defines custom scopes in it.
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
  var valid_600479 = header.getOrDefault("X-Amz-Date")
  valid_600479 = validateParameter(valid_600479, JString, required = false,
                                 default = nil)
  if valid_600479 != nil:
    section.add "X-Amz-Date", valid_600479
  var valid_600480 = header.getOrDefault("X-Amz-Security-Token")
  valid_600480 = validateParameter(valid_600480, JString, required = false,
                                 default = nil)
  if valid_600480 != nil:
    section.add "X-Amz-Security-Token", valid_600480
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600481 = header.getOrDefault("X-Amz-Target")
  valid_600481 = validateParameter(valid_600481, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateResourceServer"))
  if valid_600481 != nil:
    section.add "X-Amz-Target", valid_600481
  var valid_600482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600482 = validateParameter(valid_600482, JString, required = false,
                                 default = nil)
  if valid_600482 != nil:
    section.add "X-Amz-Content-Sha256", valid_600482
  var valid_600483 = header.getOrDefault("X-Amz-Algorithm")
  valid_600483 = validateParameter(valid_600483, JString, required = false,
                                 default = nil)
  if valid_600483 != nil:
    section.add "X-Amz-Algorithm", valid_600483
  var valid_600484 = header.getOrDefault("X-Amz-Signature")
  valid_600484 = validateParameter(valid_600484, JString, required = false,
                                 default = nil)
  if valid_600484 != nil:
    section.add "X-Amz-Signature", valid_600484
  var valid_600485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600485 = validateParameter(valid_600485, JString, required = false,
                                 default = nil)
  if valid_600485 != nil:
    section.add "X-Amz-SignedHeaders", valid_600485
  var valid_600486 = header.getOrDefault("X-Amz-Credential")
  valid_600486 = validateParameter(valid_600486, JString, required = false,
                                 default = nil)
  if valid_600486 != nil:
    section.add "X-Amz-Credential", valid_600486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600488: Call_CreateResourceServer_600476; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new OAuth2.0 resource server and defines custom scopes in it.
  ## 
  let valid = call_600488.validator(path, query, header, formData, body)
  let scheme = call_600488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600488.url(scheme.get, call_600488.host, call_600488.base,
                         call_600488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600488, url, valid)

proc call*(call_600489: Call_CreateResourceServer_600476; body: JsonNode): Recallable =
  ## createResourceServer
  ## Creates a new OAuth2.0 resource server and defines custom scopes in it.
  ##   body: JObject (required)
  var body_600490 = newJObject()
  if body != nil:
    body_600490 = body
  result = call_600489.call(nil, nil, nil, nil, body_600490)

var createResourceServer* = Call_CreateResourceServer_600476(
    name: "createResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateResourceServer",
    validator: validate_CreateResourceServer_600477, base: "/",
    url: url_CreateResourceServer_600478, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserImportJob_600491 = ref object of OpenApiRestCall_599368
proc url_CreateUserImportJob_600493(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUserImportJob_600492(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Creates the user import job.
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
  var valid_600494 = header.getOrDefault("X-Amz-Date")
  valid_600494 = validateParameter(valid_600494, JString, required = false,
                                 default = nil)
  if valid_600494 != nil:
    section.add "X-Amz-Date", valid_600494
  var valid_600495 = header.getOrDefault("X-Amz-Security-Token")
  valid_600495 = validateParameter(valid_600495, JString, required = false,
                                 default = nil)
  if valid_600495 != nil:
    section.add "X-Amz-Security-Token", valid_600495
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600496 = header.getOrDefault("X-Amz-Target")
  valid_600496 = validateParameter(valid_600496, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserImportJob"))
  if valid_600496 != nil:
    section.add "X-Amz-Target", valid_600496
  var valid_600497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600497 = validateParameter(valid_600497, JString, required = false,
                                 default = nil)
  if valid_600497 != nil:
    section.add "X-Amz-Content-Sha256", valid_600497
  var valid_600498 = header.getOrDefault("X-Amz-Algorithm")
  valid_600498 = validateParameter(valid_600498, JString, required = false,
                                 default = nil)
  if valid_600498 != nil:
    section.add "X-Amz-Algorithm", valid_600498
  var valid_600499 = header.getOrDefault("X-Amz-Signature")
  valid_600499 = validateParameter(valid_600499, JString, required = false,
                                 default = nil)
  if valid_600499 != nil:
    section.add "X-Amz-Signature", valid_600499
  var valid_600500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600500 = validateParameter(valid_600500, JString, required = false,
                                 default = nil)
  if valid_600500 != nil:
    section.add "X-Amz-SignedHeaders", valid_600500
  var valid_600501 = header.getOrDefault("X-Amz-Credential")
  valid_600501 = validateParameter(valid_600501, JString, required = false,
                                 default = nil)
  if valid_600501 != nil:
    section.add "X-Amz-Credential", valid_600501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600503: Call_CreateUserImportJob_600491; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates the user import job.
  ## 
  let valid = call_600503.validator(path, query, header, formData, body)
  let scheme = call_600503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600503.url(scheme.get, call_600503.host, call_600503.base,
                         call_600503.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600503, url, valid)

proc call*(call_600504: Call_CreateUserImportJob_600491; body: JsonNode): Recallable =
  ## createUserImportJob
  ## Creates the user import job.
  ##   body: JObject (required)
  var body_600505 = newJObject()
  if body != nil:
    body_600505 = body
  result = call_600504.call(nil, nil, nil, nil, body_600505)

var createUserImportJob* = Call_CreateUserImportJob_600491(
    name: "createUserImportJob", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserImportJob",
    validator: validate_CreateUserImportJob_600492, base: "/",
    url: url_CreateUserImportJob_600493, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserPool_600506 = ref object of OpenApiRestCall_599368
proc url_CreateUserPool_600508(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUserPool_600507(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a new Amazon Cognito user pool and sets the password policy for the pool.
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
      "AWSCognitoIdentityProviderService.CreateUserPool"))
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

proc call*(call_600518: Call_CreateUserPool_600506; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon Cognito user pool and sets the password policy for the pool.
  ## 
  let valid = call_600518.validator(path, query, header, formData, body)
  let scheme = call_600518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600518.url(scheme.get, call_600518.host, call_600518.base,
                         call_600518.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600518, url, valid)

proc call*(call_600519: Call_CreateUserPool_600506; body: JsonNode): Recallable =
  ## createUserPool
  ## Creates a new Amazon Cognito user pool and sets the password policy for the pool.
  ##   body: JObject (required)
  var body_600520 = newJObject()
  if body != nil:
    body_600520 = body
  result = call_600519.call(nil, nil, nil, nil, body_600520)

var createUserPool* = Call_CreateUserPool_600506(name: "createUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserPool",
    validator: validate_CreateUserPool_600507, base: "/", url: url_CreateUserPool_600508,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserPoolClient_600521 = ref object of OpenApiRestCall_599368
proc url_CreateUserPoolClient_600523(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUserPoolClient_600522(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates the user pool client.
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
  var valid_600524 = header.getOrDefault("X-Amz-Date")
  valid_600524 = validateParameter(valid_600524, JString, required = false,
                                 default = nil)
  if valid_600524 != nil:
    section.add "X-Amz-Date", valid_600524
  var valid_600525 = header.getOrDefault("X-Amz-Security-Token")
  valid_600525 = validateParameter(valid_600525, JString, required = false,
                                 default = nil)
  if valid_600525 != nil:
    section.add "X-Amz-Security-Token", valid_600525
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600526 = header.getOrDefault("X-Amz-Target")
  valid_600526 = validateParameter(valid_600526, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserPoolClient"))
  if valid_600526 != nil:
    section.add "X-Amz-Target", valid_600526
  var valid_600527 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600527 = validateParameter(valid_600527, JString, required = false,
                                 default = nil)
  if valid_600527 != nil:
    section.add "X-Amz-Content-Sha256", valid_600527
  var valid_600528 = header.getOrDefault("X-Amz-Algorithm")
  valid_600528 = validateParameter(valid_600528, JString, required = false,
                                 default = nil)
  if valid_600528 != nil:
    section.add "X-Amz-Algorithm", valid_600528
  var valid_600529 = header.getOrDefault("X-Amz-Signature")
  valid_600529 = validateParameter(valid_600529, JString, required = false,
                                 default = nil)
  if valid_600529 != nil:
    section.add "X-Amz-Signature", valid_600529
  var valid_600530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600530 = validateParameter(valid_600530, JString, required = false,
                                 default = nil)
  if valid_600530 != nil:
    section.add "X-Amz-SignedHeaders", valid_600530
  var valid_600531 = header.getOrDefault("X-Amz-Credential")
  valid_600531 = validateParameter(valid_600531, JString, required = false,
                                 default = nil)
  if valid_600531 != nil:
    section.add "X-Amz-Credential", valid_600531
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600533: Call_CreateUserPoolClient_600521; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates the user pool client.
  ## 
  let valid = call_600533.validator(path, query, header, formData, body)
  let scheme = call_600533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600533.url(scheme.get, call_600533.host, call_600533.base,
                         call_600533.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600533, url, valid)

proc call*(call_600534: Call_CreateUserPoolClient_600521; body: JsonNode): Recallable =
  ## createUserPoolClient
  ## Creates the user pool client.
  ##   body: JObject (required)
  var body_600535 = newJObject()
  if body != nil:
    body_600535 = body
  result = call_600534.call(nil, nil, nil, nil, body_600535)

var createUserPoolClient* = Call_CreateUserPoolClient_600521(
    name: "createUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserPoolClient",
    validator: validate_CreateUserPoolClient_600522, base: "/",
    url: url_CreateUserPoolClient_600523, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserPoolDomain_600536 = ref object of OpenApiRestCall_599368
proc url_CreateUserPoolDomain_600538(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUserPoolDomain_600537(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new domain for a user pool.
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
  var valid_600539 = header.getOrDefault("X-Amz-Date")
  valid_600539 = validateParameter(valid_600539, JString, required = false,
                                 default = nil)
  if valid_600539 != nil:
    section.add "X-Amz-Date", valid_600539
  var valid_600540 = header.getOrDefault("X-Amz-Security-Token")
  valid_600540 = validateParameter(valid_600540, JString, required = false,
                                 default = nil)
  if valid_600540 != nil:
    section.add "X-Amz-Security-Token", valid_600540
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600541 = header.getOrDefault("X-Amz-Target")
  valid_600541 = validateParameter(valid_600541, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserPoolDomain"))
  if valid_600541 != nil:
    section.add "X-Amz-Target", valid_600541
  var valid_600542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600542 = validateParameter(valid_600542, JString, required = false,
                                 default = nil)
  if valid_600542 != nil:
    section.add "X-Amz-Content-Sha256", valid_600542
  var valid_600543 = header.getOrDefault("X-Amz-Algorithm")
  valid_600543 = validateParameter(valid_600543, JString, required = false,
                                 default = nil)
  if valid_600543 != nil:
    section.add "X-Amz-Algorithm", valid_600543
  var valid_600544 = header.getOrDefault("X-Amz-Signature")
  valid_600544 = validateParameter(valid_600544, JString, required = false,
                                 default = nil)
  if valid_600544 != nil:
    section.add "X-Amz-Signature", valid_600544
  var valid_600545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600545 = validateParameter(valid_600545, JString, required = false,
                                 default = nil)
  if valid_600545 != nil:
    section.add "X-Amz-SignedHeaders", valid_600545
  var valid_600546 = header.getOrDefault("X-Amz-Credential")
  valid_600546 = validateParameter(valid_600546, JString, required = false,
                                 default = nil)
  if valid_600546 != nil:
    section.add "X-Amz-Credential", valid_600546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600548: Call_CreateUserPoolDomain_600536; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new domain for a user pool.
  ## 
  let valid = call_600548.validator(path, query, header, formData, body)
  let scheme = call_600548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600548.url(scheme.get, call_600548.host, call_600548.base,
                         call_600548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600548, url, valid)

proc call*(call_600549: Call_CreateUserPoolDomain_600536; body: JsonNode): Recallable =
  ## createUserPoolDomain
  ## Creates a new domain for a user pool.
  ##   body: JObject (required)
  var body_600550 = newJObject()
  if body != nil:
    body_600550 = body
  result = call_600549.call(nil, nil, nil, nil, body_600550)

var createUserPoolDomain* = Call_CreateUserPoolDomain_600536(
    name: "createUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserPoolDomain",
    validator: validate_CreateUserPoolDomain_600537, base: "/",
    url: url_CreateUserPoolDomain_600538, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_600551 = ref object of OpenApiRestCall_599368
proc url_DeleteGroup_600553(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteGroup_600552(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a group. Currently only groups with no members can be deleted.</p> <p>Calling this action requires developer credentials.</p>
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
  var valid_600554 = header.getOrDefault("X-Amz-Date")
  valid_600554 = validateParameter(valid_600554, JString, required = false,
                                 default = nil)
  if valid_600554 != nil:
    section.add "X-Amz-Date", valid_600554
  var valid_600555 = header.getOrDefault("X-Amz-Security-Token")
  valid_600555 = validateParameter(valid_600555, JString, required = false,
                                 default = nil)
  if valid_600555 != nil:
    section.add "X-Amz-Security-Token", valid_600555
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600556 = header.getOrDefault("X-Amz-Target")
  valid_600556 = validateParameter(valid_600556, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteGroup"))
  if valid_600556 != nil:
    section.add "X-Amz-Target", valid_600556
  var valid_600557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600557 = validateParameter(valid_600557, JString, required = false,
                                 default = nil)
  if valid_600557 != nil:
    section.add "X-Amz-Content-Sha256", valid_600557
  var valid_600558 = header.getOrDefault("X-Amz-Algorithm")
  valid_600558 = validateParameter(valid_600558, JString, required = false,
                                 default = nil)
  if valid_600558 != nil:
    section.add "X-Amz-Algorithm", valid_600558
  var valid_600559 = header.getOrDefault("X-Amz-Signature")
  valid_600559 = validateParameter(valid_600559, JString, required = false,
                                 default = nil)
  if valid_600559 != nil:
    section.add "X-Amz-Signature", valid_600559
  var valid_600560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600560 = validateParameter(valid_600560, JString, required = false,
                                 default = nil)
  if valid_600560 != nil:
    section.add "X-Amz-SignedHeaders", valid_600560
  var valid_600561 = header.getOrDefault("X-Amz-Credential")
  valid_600561 = validateParameter(valid_600561, JString, required = false,
                                 default = nil)
  if valid_600561 != nil:
    section.add "X-Amz-Credential", valid_600561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600563: Call_DeleteGroup_600551; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a group. Currently only groups with no members can be deleted.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_600563.validator(path, query, header, formData, body)
  let scheme = call_600563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600563.url(scheme.get, call_600563.host, call_600563.base,
                         call_600563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600563, url, valid)

proc call*(call_600564: Call_DeleteGroup_600551; body: JsonNode): Recallable =
  ## deleteGroup
  ## <p>Deletes a group. Currently only groups with no members can be deleted.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_600565 = newJObject()
  if body != nil:
    body_600565 = body
  result = call_600564.call(nil, nil, nil, nil, body_600565)

var deleteGroup* = Call_DeleteGroup_600551(name: "deleteGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteGroup",
                                        validator: validate_DeleteGroup_600552,
                                        base: "/", url: url_DeleteGroup_600553,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIdentityProvider_600566 = ref object of OpenApiRestCall_599368
proc url_DeleteIdentityProvider_600568(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteIdentityProvider_600567(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an identity provider for a user pool.
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
  var valid_600569 = header.getOrDefault("X-Amz-Date")
  valid_600569 = validateParameter(valid_600569, JString, required = false,
                                 default = nil)
  if valid_600569 != nil:
    section.add "X-Amz-Date", valid_600569
  var valid_600570 = header.getOrDefault("X-Amz-Security-Token")
  valid_600570 = validateParameter(valid_600570, JString, required = false,
                                 default = nil)
  if valid_600570 != nil:
    section.add "X-Amz-Security-Token", valid_600570
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600571 = header.getOrDefault("X-Amz-Target")
  valid_600571 = validateParameter(valid_600571, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteIdentityProvider"))
  if valid_600571 != nil:
    section.add "X-Amz-Target", valid_600571
  var valid_600572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600572 = validateParameter(valid_600572, JString, required = false,
                                 default = nil)
  if valid_600572 != nil:
    section.add "X-Amz-Content-Sha256", valid_600572
  var valid_600573 = header.getOrDefault("X-Amz-Algorithm")
  valid_600573 = validateParameter(valid_600573, JString, required = false,
                                 default = nil)
  if valid_600573 != nil:
    section.add "X-Amz-Algorithm", valid_600573
  var valid_600574 = header.getOrDefault("X-Amz-Signature")
  valid_600574 = validateParameter(valid_600574, JString, required = false,
                                 default = nil)
  if valid_600574 != nil:
    section.add "X-Amz-Signature", valid_600574
  var valid_600575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600575 = validateParameter(valid_600575, JString, required = false,
                                 default = nil)
  if valid_600575 != nil:
    section.add "X-Amz-SignedHeaders", valid_600575
  var valid_600576 = header.getOrDefault("X-Amz-Credential")
  valid_600576 = validateParameter(valid_600576, JString, required = false,
                                 default = nil)
  if valid_600576 != nil:
    section.add "X-Amz-Credential", valid_600576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600578: Call_DeleteIdentityProvider_600566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an identity provider for a user pool.
  ## 
  let valid = call_600578.validator(path, query, header, formData, body)
  let scheme = call_600578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600578.url(scheme.get, call_600578.host, call_600578.base,
                         call_600578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600578, url, valid)

proc call*(call_600579: Call_DeleteIdentityProvider_600566; body: JsonNode): Recallable =
  ## deleteIdentityProvider
  ## Deletes an identity provider for a user pool.
  ##   body: JObject (required)
  var body_600580 = newJObject()
  if body != nil:
    body_600580 = body
  result = call_600579.call(nil, nil, nil, nil, body_600580)

var deleteIdentityProvider* = Call_DeleteIdentityProvider_600566(
    name: "deleteIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteIdentityProvider",
    validator: validate_DeleteIdentityProvider_600567, base: "/",
    url: url_DeleteIdentityProvider_600568, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceServer_600581 = ref object of OpenApiRestCall_599368
proc url_DeleteResourceServer_600583(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteResourceServer_600582(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a resource server.
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
  var valid_600584 = header.getOrDefault("X-Amz-Date")
  valid_600584 = validateParameter(valid_600584, JString, required = false,
                                 default = nil)
  if valid_600584 != nil:
    section.add "X-Amz-Date", valid_600584
  var valid_600585 = header.getOrDefault("X-Amz-Security-Token")
  valid_600585 = validateParameter(valid_600585, JString, required = false,
                                 default = nil)
  if valid_600585 != nil:
    section.add "X-Amz-Security-Token", valid_600585
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600586 = header.getOrDefault("X-Amz-Target")
  valid_600586 = validateParameter(valid_600586, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteResourceServer"))
  if valid_600586 != nil:
    section.add "X-Amz-Target", valid_600586
  var valid_600587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600587 = validateParameter(valid_600587, JString, required = false,
                                 default = nil)
  if valid_600587 != nil:
    section.add "X-Amz-Content-Sha256", valid_600587
  var valid_600588 = header.getOrDefault("X-Amz-Algorithm")
  valid_600588 = validateParameter(valid_600588, JString, required = false,
                                 default = nil)
  if valid_600588 != nil:
    section.add "X-Amz-Algorithm", valid_600588
  var valid_600589 = header.getOrDefault("X-Amz-Signature")
  valid_600589 = validateParameter(valid_600589, JString, required = false,
                                 default = nil)
  if valid_600589 != nil:
    section.add "X-Amz-Signature", valid_600589
  var valid_600590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600590 = validateParameter(valid_600590, JString, required = false,
                                 default = nil)
  if valid_600590 != nil:
    section.add "X-Amz-SignedHeaders", valid_600590
  var valid_600591 = header.getOrDefault("X-Amz-Credential")
  valid_600591 = validateParameter(valid_600591, JString, required = false,
                                 default = nil)
  if valid_600591 != nil:
    section.add "X-Amz-Credential", valid_600591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600593: Call_DeleteResourceServer_600581; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a resource server.
  ## 
  let valid = call_600593.validator(path, query, header, formData, body)
  let scheme = call_600593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600593.url(scheme.get, call_600593.host, call_600593.base,
                         call_600593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600593, url, valid)

proc call*(call_600594: Call_DeleteResourceServer_600581; body: JsonNode): Recallable =
  ## deleteResourceServer
  ## Deletes a resource server.
  ##   body: JObject (required)
  var body_600595 = newJObject()
  if body != nil:
    body_600595 = body
  result = call_600594.call(nil, nil, nil, nil, body_600595)

var deleteResourceServer* = Call_DeleteResourceServer_600581(
    name: "deleteResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteResourceServer",
    validator: validate_DeleteResourceServer_600582, base: "/",
    url: url_DeleteResourceServer_600583, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_600596 = ref object of OpenApiRestCall_599368
proc url_DeleteUser_600598(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUser_600597(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Allows a user to delete himself or herself.
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
  var valid_600599 = header.getOrDefault("X-Amz-Date")
  valid_600599 = validateParameter(valid_600599, JString, required = false,
                                 default = nil)
  if valid_600599 != nil:
    section.add "X-Amz-Date", valid_600599
  var valid_600600 = header.getOrDefault("X-Amz-Security-Token")
  valid_600600 = validateParameter(valid_600600, JString, required = false,
                                 default = nil)
  if valid_600600 != nil:
    section.add "X-Amz-Security-Token", valid_600600
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600601 = header.getOrDefault("X-Amz-Target")
  valid_600601 = validateParameter(valid_600601, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUser"))
  if valid_600601 != nil:
    section.add "X-Amz-Target", valid_600601
  var valid_600602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600602 = validateParameter(valid_600602, JString, required = false,
                                 default = nil)
  if valid_600602 != nil:
    section.add "X-Amz-Content-Sha256", valid_600602
  var valid_600603 = header.getOrDefault("X-Amz-Algorithm")
  valid_600603 = validateParameter(valid_600603, JString, required = false,
                                 default = nil)
  if valid_600603 != nil:
    section.add "X-Amz-Algorithm", valid_600603
  var valid_600604 = header.getOrDefault("X-Amz-Signature")
  valid_600604 = validateParameter(valid_600604, JString, required = false,
                                 default = nil)
  if valid_600604 != nil:
    section.add "X-Amz-Signature", valid_600604
  var valid_600605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600605 = validateParameter(valid_600605, JString, required = false,
                                 default = nil)
  if valid_600605 != nil:
    section.add "X-Amz-SignedHeaders", valid_600605
  var valid_600606 = header.getOrDefault("X-Amz-Credential")
  valid_600606 = validateParameter(valid_600606, JString, required = false,
                                 default = nil)
  if valid_600606 != nil:
    section.add "X-Amz-Credential", valid_600606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600608: Call_DeleteUser_600596; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a user to delete himself or herself.
  ## 
  let valid = call_600608.validator(path, query, header, formData, body)
  let scheme = call_600608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600608.url(scheme.get, call_600608.host, call_600608.base,
                         call_600608.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600608, url, valid)

proc call*(call_600609: Call_DeleteUser_600596; body: JsonNode): Recallable =
  ## deleteUser
  ## Allows a user to delete himself or herself.
  ##   body: JObject (required)
  var body_600610 = newJObject()
  if body != nil:
    body_600610 = body
  result = call_600609.call(nil, nil, nil, nil, body_600610)

var deleteUser* = Call_DeleteUser_600596(name: "deleteUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUser",
                                      validator: validate_DeleteUser_600597,
                                      base: "/", url: url_DeleteUser_600598,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserAttributes_600611 = ref object of OpenApiRestCall_599368
proc url_DeleteUserAttributes_600613(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUserAttributes_600612(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the attributes for a user.
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
      "AWSCognitoIdentityProviderService.DeleteUserAttributes"))
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

proc call*(call_600623: Call_DeleteUserAttributes_600611; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the attributes for a user.
  ## 
  let valid = call_600623.validator(path, query, header, formData, body)
  let scheme = call_600623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600623.url(scheme.get, call_600623.host, call_600623.base,
                         call_600623.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600623, url, valid)

proc call*(call_600624: Call_DeleteUserAttributes_600611; body: JsonNode): Recallable =
  ## deleteUserAttributes
  ## Deletes the attributes for a user.
  ##   body: JObject (required)
  var body_600625 = newJObject()
  if body != nil:
    body_600625 = body
  result = call_600624.call(nil, nil, nil, nil, body_600625)

var deleteUserAttributes* = Call_DeleteUserAttributes_600611(
    name: "deleteUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserAttributes",
    validator: validate_DeleteUserAttributes_600612, base: "/",
    url: url_DeleteUserAttributes_600613, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserPool_600626 = ref object of OpenApiRestCall_599368
proc url_DeleteUserPool_600628(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUserPool_600627(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes the specified Amazon Cognito user pool.
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
      "AWSCognitoIdentityProviderService.DeleteUserPool"))
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

proc call*(call_600638: Call_DeleteUserPool_600626; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Amazon Cognito user pool.
  ## 
  let valid = call_600638.validator(path, query, header, formData, body)
  let scheme = call_600638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600638.url(scheme.get, call_600638.host, call_600638.base,
                         call_600638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600638, url, valid)

proc call*(call_600639: Call_DeleteUserPool_600626; body: JsonNode): Recallable =
  ## deleteUserPool
  ## Deletes the specified Amazon Cognito user pool.
  ##   body: JObject (required)
  var body_600640 = newJObject()
  if body != nil:
    body_600640 = body
  result = call_600639.call(nil, nil, nil, nil, body_600640)

var deleteUserPool* = Call_DeleteUserPool_600626(name: "deleteUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserPool",
    validator: validate_DeleteUserPool_600627, base: "/", url: url_DeleteUserPool_600628,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserPoolClient_600641 = ref object of OpenApiRestCall_599368
proc url_DeleteUserPoolClient_600643(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUserPoolClient_600642(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Allows the developer to delete the user pool client.
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
      "AWSCognitoIdentityProviderService.DeleteUserPoolClient"))
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

proc call*(call_600653: Call_DeleteUserPoolClient_600641; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows the developer to delete the user pool client.
  ## 
  let valid = call_600653.validator(path, query, header, formData, body)
  let scheme = call_600653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600653.url(scheme.get, call_600653.host, call_600653.base,
                         call_600653.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600653, url, valid)

proc call*(call_600654: Call_DeleteUserPoolClient_600641; body: JsonNode): Recallable =
  ## deleteUserPoolClient
  ## Allows the developer to delete the user pool client.
  ##   body: JObject (required)
  var body_600655 = newJObject()
  if body != nil:
    body_600655 = body
  result = call_600654.call(nil, nil, nil, nil, body_600655)

var deleteUserPoolClient* = Call_DeleteUserPoolClient_600641(
    name: "deleteUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserPoolClient",
    validator: validate_DeleteUserPoolClient_600642, base: "/",
    url: url_DeleteUserPoolClient_600643, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserPoolDomain_600656 = ref object of OpenApiRestCall_599368
proc url_DeleteUserPoolDomain_600658(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUserPoolDomain_600657(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a domain for a user pool.
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
      "AWSCognitoIdentityProviderService.DeleteUserPoolDomain"))
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

proc call*(call_600668: Call_DeleteUserPoolDomain_600656; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a domain for a user pool.
  ## 
  let valid = call_600668.validator(path, query, header, formData, body)
  let scheme = call_600668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600668.url(scheme.get, call_600668.host, call_600668.base,
                         call_600668.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600668, url, valid)

proc call*(call_600669: Call_DeleteUserPoolDomain_600656; body: JsonNode): Recallable =
  ## deleteUserPoolDomain
  ## Deletes a domain for a user pool.
  ##   body: JObject (required)
  var body_600670 = newJObject()
  if body != nil:
    body_600670 = body
  result = call_600669.call(nil, nil, nil, nil, body_600670)

var deleteUserPoolDomain* = Call_DeleteUserPoolDomain_600656(
    name: "deleteUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserPoolDomain",
    validator: validate_DeleteUserPoolDomain_600657, base: "/",
    url: url_DeleteUserPoolDomain_600658, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentityProvider_600671 = ref object of OpenApiRestCall_599368
proc url_DescribeIdentityProvider_600673(protocol: Scheme; host: string;
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

proc validate_DescribeIdentityProvider_600672(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about a specific identity provider.
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
      "AWSCognitoIdentityProviderService.DescribeIdentityProvider"))
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

proc call*(call_600683: Call_DescribeIdentityProvider_600671; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specific identity provider.
  ## 
  let valid = call_600683.validator(path, query, header, formData, body)
  let scheme = call_600683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600683.url(scheme.get, call_600683.host, call_600683.base,
                         call_600683.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600683, url, valid)

proc call*(call_600684: Call_DescribeIdentityProvider_600671; body: JsonNode): Recallable =
  ## describeIdentityProvider
  ## Gets information about a specific identity provider.
  ##   body: JObject (required)
  var body_600685 = newJObject()
  if body != nil:
    body_600685 = body
  result = call_600684.call(nil, nil, nil, nil, body_600685)

var describeIdentityProvider* = Call_DescribeIdentityProvider_600671(
    name: "describeIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeIdentityProvider",
    validator: validate_DescribeIdentityProvider_600672, base: "/",
    url: url_DescribeIdentityProvider_600673, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResourceServer_600686 = ref object of OpenApiRestCall_599368
proc url_DescribeResourceServer_600688(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeResourceServer_600687(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes a resource server.
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
      "AWSCognitoIdentityProviderService.DescribeResourceServer"))
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

proc call*(call_600698: Call_DescribeResourceServer_600686; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a resource server.
  ## 
  let valid = call_600698.validator(path, query, header, formData, body)
  let scheme = call_600698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600698.url(scheme.get, call_600698.host, call_600698.base,
                         call_600698.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600698, url, valid)

proc call*(call_600699: Call_DescribeResourceServer_600686; body: JsonNode): Recallable =
  ## describeResourceServer
  ## Describes a resource server.
  ##   body: JObject (required)
  var body_600700 = newJObject()
  if body != nil:
    body_600700 = body
  result = call_600699.call(nil, nil, nil, nil, body_600700)

var describeResourceServer* = Call_DescribeResourceServer_600686(
    name: "describeResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeResourceServer",
    validator: validate_DescribeResourceServer_600687, base: "/",
    url: url_DescribeResourceServer_600688, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRiskConfiguration_600701 = ref object of OpenApiRestCall_599368
proc url_DescribeRiskConfiguration_600703(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeRiskConfiguration_600702(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the risk configuration.
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
  var valid_600704 = header.getOrDefault("X-Amz-Date")
  valid_600704 = validateParameter(valid_600704, JString, required = false,
                                 default = nil)
  if valid_600704 != nil:
    section.add "X-Amz-Date", valid_600704
  var valid_600705 = header.getOrDefault("X-Amz-Security-Token")
  valid_600705 = validateParameter(valid_600705, JString, required = false,
                                 default = nil)
  if valid_600705 != nil:
    section.add "X-Amz-Security-Token", valid_600705
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600706 = header.getOrDefault("X-Amz-Target")
  valid_600706 = validateParameter(valid_600706, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeRiskConfiguration"))
  if valid_600706 != nil:
    section.add "X-Amz-Target", valid_600706
  var valid_600707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600707 = validateParameter(valid_600707, JString, required = false,
                                 default = nil)
  if valid_600707 != nil:
    section.add "X-Amz-Content-Sha256", valid_600707
  var valid_600708 = header.getOrDefault("X-Amz-Algorithm")
  valid_600708 = validateParameter(valid_600708, JString, required = false,
                                 default = nil)
  if valid_600708 != nil:
    section.add "X-Amz-Algorithm", valid_600708
  var valid_600709 = header.getOrDefault("X-Amz-Signature")
  valid_600709 = validateParameter(valid_600709, JString, required = false,
                                 default = nil)
  if valid_600709 != nil:
    section.add "X-Amz-Signature", valid_600709
  var valid_600710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600710 = validateParameter(valid_600710, JString, required = false,
                                 default = nil)
  if valid_600710 != nil:
    section.add "X-Amz-SignedHeaders", valid_600710
  var valid_600711 = header.getOrDefault("X-Amz-Credential")
  valid_600711 = validateParameter(valid_600711, JString, required = false,
                                 default = nil)
  if valid_600711 != nil:
    section.add "X-Amz-Credential", valid_600711
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600713: Call_DescribeRiskConfiguration_600701; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the risk configuration.
  ## 
  let valid = call_600713.validator(path, query, header, formData, body)
  let scheme = call_600713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600713.url(scheme.get, call_600713.host, call_600713.base,
                         call_600713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600713, url, valid)

proc call*(call_600714: Call_DescribeRiskConfiguration_600701; body: JsonNode): Recallable =
  ## describeRiskConfiguration
  ## Describes the risk configuration.
  ##   body: JObject (required)
  var body_600715 = newJObject()
  if body != nil:
    body_600715 = body
  result = call_600714.call(nil, nil, nil, nil, body_600715)

var describeRiskConfiguration* = Call_DescribeRiskConfiguration_600701(
    name: "describeRiskConfiguration", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeRiskConfiguration",
    validator: validate_DescribeRiskConfiguration_600702, base: "/",
    url: url_DescribeRiskConfiguration_600703,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserImportJob_600716 = ref object of OpenApiRestCall_599368
proc url_DescribeUserImportJob_600718(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUserImportJob_600717(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the user import job.
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
  var valid_600719 = header.getOrDefault("X-Amz-Date")
  valid_600719 = validateParameter(valid_600719, JString, required = false,
                                 default = nil)
  if valid_600719 != nil:
    section.add "X-Amz-Date", valid_600719
  var valid_600720 = header.getOrDefault("X-Amz-Security-Token")
  valid_600720 = validateParameter(valid_600720, JString, required = false,
                                 default = nil)
  if valid_600720 != nil:
    section.add "X-Amz-Security-Token", valid_600720
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600721 = header.getOrDefault("X-Amz-Target")
  valid_600721 = validateParameter(valid_600721, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserImportJob"))
  if valid_600721 != nil:
    section.add "X-Amz-Target", valid_600721
  var valid_600722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600722 = validateParameter(valid_600722, JString, required = false,
                                 default = nil)
  if valid_600722 != nil:
    section.add "X-Amz-Content-Sha256", valid_600722
  var valid_600723 = header.getOrDefault("X-Amz-Algorithm")
  valid_600723 = validateParameter(valid_600723, JString, required = false,
                                 default = nil)
  if valid_600723 != nil:
    section.add "X-Amz-Algorithm", valid_600723
  var valid_600724 = header.getOrDefault("X-Amz-Signature")
  valid_600724 = validateParameter(valid_600724, JString, required = false,
                                 default = nil)
  if valid_600724 != nil:
    section.add "X-Amz-Signature", valid_600724
  var valid_600725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600725 = validateParameter(valid_600725, JString, required = false,
                                 default = nil)
  if valid_600725 != nil:
    section.add "X-Amz-SignedHeaders", valid_600725
  var valid_600726 = header.getOrDefault("X-Amz-Credential")
  valid_600726 = validateParameter(valid_600726, JString, required = false,
                                 default = nil)
  if valid_600726 != nil:
    section.add "X-Amz-Credential", valid_600726
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600728: Call_DescribeUserImportJob_600716; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the user import job.
  ## 
  let valid = call_600728.validator(path, query, header, formData, body)
  let scheme = call_600728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600728.url(scheme.get, call_600728.host, call_600728.base,
                         call_600728.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600728, url, valid)

proc call*(call_600729: Call_DescribeUserImportJob_600716; body: JsonNode): Recallable =
  ## describeUserImportJob
  ## Describes the user import job.
  ##   body: JObject (required)
  var body_600730 = newJObject()
  if body != nil:
    body_600730 = body
  result = call_600729.call(nil, nil, nil, nil, body_600730)

var describeUserImportJob* = Call_DescribeUserImportJob_600716(
    name: "describeUserImportJob", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserImportJob",
    validator: validate_DescribeUserImportJob_600717, base: "/",
    url: url_DescribeUserImportJob_600718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserPool_600731 = ref object of OpenApiRestCall_599368
proc url_DescribeUserPool_600733(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUserPool_600732(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns the configuration information and metadata of the specified user pool.
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
  var valid_600734 = header.getOrDefault("X-Amz-Date")
  valid_600734 = validateParameter(valid_600734, JString, required = false,
                                 default = nil)
  if valid_600734 != nil:
    section.add "X-Amz-Date", valid_600734
  var valid_600735 = header.getOrDefault("X-Amz-Security-Token")
  valid_600735 = validateParameter(valid_600735, JString, required = false,
                                 default = nil)
  if valid_600735 != nil:
    section.add "X-Amz-Security-Token", valid_600735
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600736 = header.getOrDefault("X-Amz-Target")
  valid_600736 = validateParameter(valid_600736, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserPool"))
  if valid_600736 != nil:
    section.add "X-Amz-Target", valid_600736
  var valid_600737 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600737 = validateParameter(valid_600737, JString, required = false,
                                 default = nil)
  if valid_600737 != nil:
    section.add "X-Amz-Content-Sha256", valid_600737
  var valid_600738 = header.getOrDefault("X-Amz-Algorithm")
  valid_600738 = validateParameter(valid_600738, JString, required = false,
                                 default = nil)
  if valid_600738 != nil:
    section.add "X-Amz-Algorithm", valid_600738
  var valid_600739 = header.getOrDefault("X-Amz-Signature")
  valid_600739 = validateParameter(valid_600739, JString, required = false,
                                 default = nil)
  if valid_600739 != nil:
    section.add "X-Amz-Signature", valid_600739
  var valid_600740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600740 = validateParameter(valid_600740, JString, required = false,
                                 default = nil)
  if valid_600740 != nil:
    section.add "X-Amz-SignedHeaders", valid_600740
  var valid_600741 = header.getOrDefault("X-Amz-Credential")
  valid_600741 = validateParameter(valid_600741, JString, required = false,
                                 default = nil)
  if valid_600741 != nil:
    section.add "X-Amz-Credential", valid_600741
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600743: Call_DescribeUserPool_600731; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the configuration information and metadata of the specified user pool.
  ## 
  let valid = call_600743.validator(path, query, header, formData, body)
  let scheme = call_600743.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600743.url(scheme.get, call_600743.host, call_600743.base,
                         call_600743.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600743, url, valid)

proc call*(call_600744: Call_DescribeUserPool_600731; body: JsonNode): Recallable =
  ## describeUserPool
  ## Returns the configuration information and metadata of the specified user pool.
  ##   body: JObject (required)
  var body_600745 = newJObject()
  if body != nil:
    body_600745 = body
  result = call_600744.call(nil, nil, nil, nil, body_600745)

var describeUserPool* = Call_DescribeUserPool_600731(name: "describeUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserPool",
    validator: validate_DescribeUserPool_600732, base: "/",
    url: url_DescribeUserPool_600733, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserPoolClient_600746 = ref object of OpenApiRestCall_599368
proc url_DescribeUserPoolClient_600748(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUserPoolClient_600747(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Client method for returning the configuration information and metadata of the specified user pool app client.
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
  var valid_600749 = header.getOrDefault("X-Amz-Date")
  valid_600749 = validateParameter(valid_600749, JString, required = false,
                                 default = nil)
  if valid_600749 != nil:
    section.add "X-Amz-Date", valid_600749
  var valid_600750 = header.getOrDefault("X-Amz-Security-Token")
  valid_600750 = validateParameter(valid_600750, JString, required = false,
                                 default = nil)
  if valid_600750 != nil:
    section.add "X-Amz-Security-Token", valid_600750
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600751 = header.getOrDefault("X-Amz-Target")
  valid_600751 = validateParameter(valid_600751, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserPoolClient"))
  if valid_600751 != nil:
    section.add "X-Amz-Target", valid_600751
  var valid_600752 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600752 = validateParameter(valid_600752, JString, required = false,
                                 default = nil)
  if valid_600752 != nil:
    section.add "X-Amz-Content-Sha256", valid_600752
  var valid_600753 = header.getOrDefault("X-Amz-Algorithm")
  valid_600753 = validateParameter(valid_600753, JString, required = false,
                                 default = nil)
  if valid_600753 != nil:
    section.add "X-Amz-Algorithm", valid_600753
  var valid_600754 = header.getOrDefault("X-Amz-Signature")
  valid_600754 = validateParameter(valid_600754, JString, required = false,
                                 default = nil)
  if valid_600754 != nil:
    section.add "X-Amz-Signature", valid_600754
  var valid_600755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600755 = validateParameter(valid_600755, JString, required = false,
                                 default = nil)
  if valid_600755 != nil:
    section.add "X-Amz-SignedHeaders", valid_600755
  var valid_600756 = header.getOrDefault("X-Amz-Credential")
  valid_600756 = validateParameter(valid_600756, JString, required = false,
                                 default = nil)
  if valid_600756 != nil:
    section.add "X-Amz-Credential", valid_600756
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600758: Call_DescribeUserPoolClient_600746; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Client method for returning the configuration information and metadata of the specified user pool app client.
  ## 
  let valid = call_600758.validator(path, query, header, formData, body)
  let scheme = call_600758.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600758.url(scheme.get, call_600758.host, call_600758.base,
                         call_600758.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600758, url, valid)

proc call*(call_600759: Call_DescribeUserPoolClient_600746; body: JsonNode): Recallable =
  ## describeUserPoolClient
  ## Client method for returning the configuration information and metadata of the specified user pool app client.
  ##   body: JObject (required)
  var body_600760 = newJObject()
  if body != nil:
    body_600760 = body
  result = call_600759.call(nil, nil, nil, nil, body_600760)

var describeUserPoolClient* = Call_DescribeUserPoolClient_600746(
    name: "describeUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserPoolClient",
    validator: validate_DescribeUserPoolClient_600747, base: "/",
    url: url_DescribeUserPoolClient_600748, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserPoolDomain_600761 = ref object of OpenApiRestCall_599368
proc url_DescribeUserPoolDomain_600763(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUserPoolDomain_600762(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about a domain.
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
  var valid_600764 = header.getOrDefault("X-Amz-Date")
  valid_600764 = validateParameter(valid_600764, JString, required = false,
                                 default = nil)
  if valid_600764 != nil:
    section.add "X-Amz-Date", valid_600764
  var valid_600765 = header.getOrDefault("X-Amz-Security-Token")
  valid_600765 = validateParameter(valid_600765, JString, required = false,
                                 default = nil)
  if valid_600765 != nil:
    section.add "X-Amz-Security-Token", valid_600765
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600766 = header.getOrDefault("X-Amz-Target")
  valid_600766 = validateParameter(valid_600766, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserPoolDomain"))
  if valid_600766 != nil:
    section.add "X-Amz-Target", valid_600766
  var valid_600767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600767 = validateParameter(valid_600767, JString, required = false,
                                 default = nil)
  if valid_600767 != nil:
    section.add "X-Amz-Content-Sha256", valid_600767
  var valid_600768 = header.getOrDefault("X-Amz-Algorithm")
  valid_600768 = validateParameter(valid_600768, JString, required = false,
                                 default = nil)
  if valid_600768 != nil:
    section.add "X-Amz-Algorithm", valid_600768
  var valid_600769 = header.getOrDefault("X-Amz-Signature")
  valid_600769 = validateParameter(valid_600769, JString, required = false,
                                 default = nil)
  if valid_600769 != nil:
    section.add "X-Amz-Signature", valid_600769
  var valid_600770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600770 = validateParameter(valid_600770, JString, required = false,
                                 default = nil)
  if valid_600770 != nil:
    section.add "X-Amz-SignedHeaders", valid_600770
  var valid_600771 = header.getOrDefault("X-Amz-Credential")
  valid_600771 = validateParameter(valid_600771, JString, required = false,
                                 default = nil)
  if valid_600771 != nil:
    section.add "X-Amz-Credential", valid_600771
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600773: Call_DescribeUserPoolDomain_600761; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a domain.
  ## 
  let valid = call_600773.validator(path, query, header, formData, body)
  let scheme = call_600773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600773.url(scheme.get, call_600773.host, call_600773.base,
                         call_600773.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600773, url, valid)

proc call*(call_600774: Call_DescribeUserPoolDomain_600761; body: JsonNode): Recallable =
  ## describeUserPoolDomain
  ## Gets information about a domain.
  ##   body: JObject (required)
  var body_600775 = newJObject()
  if body != nil:
    body_600775 = body
  result = call_600774.call(nil, nil, nil, nil, body_600775)

var describeUserPoolDomain* = Call_DescribeUserPoolDomain_600761(
    name: "describeUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserPoolDomain",
    validator: validate_DescribeUserPoolDomain_600762, base: "/",
    url: url_DescribeUserPoolDomain_600763, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ForgetDevice_600776 = ref object of OpenApiRestCall_599368
proc url_ForgetDevice_600778(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ForgetDevice_600777(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Forgets the specified device.
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
  var valid_600779 = header.getOrDefault("X-Amz-Date")
  valid_600779 = validateParameter(valid_600779, JString, required = false,
                                 default = nil)
  if valid_600779 != nil:
    section.add "X-Amz-Date", valid_600779
  var valid_600780 = header.getOrDefault("X-Amz-Security-Token")
  valid_600780 = validateParameter(valid_600780, JString, required = false,
                                 default = nil)
  if valid_600780 != nil:
    section.add "X-Amz-Security-Token", valid_600780
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600781 = header.getOrDefault("X-Amz-Target")
  valid_600781 = validateParameter(valid_600781, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ForgetDevice"))
  if valid_600781 != nil:
    section.add "X-Amz-Target", valid_600781
  var valid_600782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600782 = validateParameter(valid_600782, JString, required = false,
                                 default = nil)
  if valid_600782 != nil:
    section.add "X-Amz-Content-Sha256", valid_600782
  var valid_600783 = header.getOrDefault("X-Amz-Algorithm")
  valid_600783 = validateParameter(valid_600783, JString, required = false,
                                 default = nil)
  if valid_600783 != nil:
    section.add "X-Amz-Algorithm", valid_600783
  var valid_600784 = header.getOrDefault("X-Amz-Signature")
  valid_600784 = validateParameter(valid_600784, JString, required = false,
                                 default = nil)
  if valid_600784 != nil:
    section.add "X-Amz-Signature", valid_600784
  var valid_600785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600785 = validateParameter(valid_600785, JString, required = false,
                                 default = nil)
  if valid_600785 != nil:
    section.add "X-Amz-SignedHeaders", valid_600785
  var valid_600786 = header.getOrDefault("X-Amz-Credential")
  valid_600786 = validateParameter(valid_600786, JString, required = false,
                                 default = nil)
  if valid_600786 != nil:
    section.add "X-Amz-Credential", valid_600786
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600788: Call_ForgetDevice_600776; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Forgets the specified device.
  ## 
  let valid = call_600788.validator(path, query, header, formData, body)
  let scheme = call_600788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600788.url(scheme.get, call_600788.host, call_600788.base,
                         call_600788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600788, url, valid)

proc call*(call_600789: Call_ForgetDevice_600776; body: JsonNode): Recallable =
  ## forgetDevice
  ## Forgets the specified device.
  ##   body: JObject (required)
  var body_600790 = newJObject()
  if body != nil:
    body_600790 = body
  result = call_600789.call(nil, nil, nil, nil, body_600790)

var forgetDevice* = Call_ForgetDevice_600776(name: "forgetDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ForgetDevice",
    validator: validate_ForgetDevice_600777, base: "/", url: url_ForgetDevice_600778,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ForgotPassword_600791 = ref object of OpenApiRestCall_599368
proc url_ForgotPassword_600793(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ForgotPassword_600792(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Calling this API causes a message to be sent to the end user with a confirmation code that is required to change the user's password. For the <code>Username</code> parameter, you can use the username or user alias. If a verified phone number exists for the user, the confirmation code is sent to the phone number. Otherwise, if a verified email exists, the confirmation code is sent to the email. If neither a verified phone number nor a verified email exists, <code>InvalidParameterException</code> is thrown. To use the confirmation code for resetting the password, call .
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
  var valid_600794 = header.getOrDefault("X-Amz-Date")
  valid_600794 = validateParameter(valid_600794, JString, required = false,
                                 default = nil)
  if valid_600794 != nil:
    section.add "X-Amz-Date", valid_600794
  var valid_600795 = header.getOrDefault("X-Amz-Security-Token")
  valid_600795 = validateParameter(valid_600795, JString, required = false,
                                 default = nil)
  if valid_600795 != nil:
    section.add "X-Amz-Security-Token", valid_600795
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600796 = header.getOrDefault("X-Amz-Target")
  valid_600796 = validateParameter(valid_600796, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ForgotPassword"))
  if valid_600796 != nil:
    section.add "X-Amz-Target", valid_600796
  var valid_600797 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600797 = validateParameter(valid_600797, JString, required = false,
                                 default = nil)
  if valid_600797 != nil:
    section.add "X-Amz-Content-Sha256", valid_600797
  var valid_600798 = header.getOrDefault("X-Amz-Algorithm")
  valid_600798 = validateParameter(valid_600798, JString, required = false,
                                 default = nil)
  if valid_600798 != nil:
    section.add "X-Amz-Algorithm", valid_600798
  var valid_600799 = header.getOrDefault("X-Amz-Signature")
  valid_600799 = validateParameter(valid_600799, JString, required = false,
                                 default = nil)
  if valid_600799 != nil:
    section.add "X-Amz-Signature", valid_600799
  var valid_600800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600800 = validateParameter(valid_600800, JString, required = false,
                                 default = nil)
  if valid_600800 != nil:
    section.add "X-Amz-SignedHeaders", valid_600800
  var valid_600801 = header.getOrDefault("X-Amz-Credential")
  valid_600801 = validateParameter(valid_600801, JString, required = false,
                                 default = nil)
  if valid_600801 != nil:
    section.add "X-Amz-Credential", valid_600801
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600803: Call_ForgotPassword_600791; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Calling this API causes a message to be sent to the end user with a confirmation code that is required to change the user's password. For the <code>Username</code> parameter, you can use the username or user alias. If a verified phone number exists for the user, the confirmation code is sent to the phone number. Otherwise, if a verified email exists, the confirmation code is sent to the email. If neither a verified phone number nor a verified email exists, <code>InvalidParameterException</code> is thrown. To use the confirmation code for resetting the password, call .
  ## 
  let valid = call_600803.validator(path, query, header, formData, body)
  let scheme = call_600803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600803.url(scheme.get, call_600803.host, call_600803.base,
                         call_600803.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600803, url, valid)

proc call*(call_600804: Call_ForgotPassword_600791; body: JsonNode): Recallable =
  ## forgotPassword
  ## Calling this API causes a message to be sent to the end user with a confirmation code that is required to change the user's password. For the <code>Username</code> parameter, you can use the username or user alias. If a verified phone number exists for the user, the confirmation code is sent to the phone number. Otherwise, if a verified email exists, the confirmation code is sent to the email. If neither a verified phone number nor a verified email exists, <code>InvalidParameterException</code> is thrown. To use the confirmation code for resetting the password, call .
  ##   body: JObject (required)
  var body_600805 = newJObject()
  if body != nil:
    body_600805 = body
  result = call_600804.call(nil, nil, nil, nil, body_600805)

var forgotPassword* = Call_ForgotPassword_600791(name: "forgotPassword",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ForgotPassword",
    validator: validate_ForgotPassword_600792, base: "/", url: url_ForgotPassword_600793,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCSVHeader_600806 = ref object of OpenApiRestCall_599368
proc url_GetCSVHeader_600808(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCSVHeader_600807(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the header information for the .csv file to be used as input for the user import job.
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
  var valid_600809 = header.getOrDefault("X-Amz-Date")
  valid_600809 = validateParameter(valid_600809, JString, required = false,
                                 default = nil)
  if valid_600809 != nil:
    section.add "X-Amz-Date", valid_600809
  var valid_600810 = header.getOrDefault("X-Amz-Security-Token")
  valid_600810 = validateParameter(valid_600810, JString, required = false,
                                 default = nil)
  if valid_600810 != nil:
    section.add "X-Amz-Security-Token", valid_600810
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600811 = header.getOrDefault("X-Amz-Target")
  valid_600811 = validateParameter(valid_600811, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetCSVHeader"))
  if valid_600811 != nil:
    section.add "X-Amz-Target", valid_600811
  var valid_600812 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600812 = validateParameter(valid_600812, JString, required = false,
                                 default = nil)
  if valid_600812 != nil:
    section.add "X-Amz-Content-Sha256", valid_600812
  var valid_600813 = header.getOrDefault("X-Amz-Algorithm")
  valid_600813 = validateParameter(valid_600813, JString, required = false,
                                 default = nil)
  if valid_600813 != nil:
    section.add "X-Amz-Algorithm", valid_600813
  var valid_600814 = header.getOrDefault("X-Amz-Signature")
  valid_600814 = validateParameter(valid_600814, JString, required = false,
                                 default = nil)
  if valid_600814 != nil:
    section.add "X-Amz-Signature", valid_600814
  var valid_600815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600815 = validateParameter(valid_600815, JString, required = false,
                                 default = nil)
  if valid_600815 != nil:
    section.add "X-Amz-SignedHeaders", valid_600815
  var valid_600816 = header.getOrDefault("X-Amz-Credential")
  valid_600816 = validateParameter(valid_600816, JString, required = false,
                                 default = nil)
  if valid_600816 != nil:
    section.add "X-Amz-Credential", valid_600816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600818: Call_GetCSVHeader_600806; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the header information for the .csv file to be used as input for the user import job.
  ## 
  let valid = call_600818.validator(path, query, header, formData, body)
  let scheme = call_600818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600818.url(scheme.get, call_600818.host, call_600818.base,
                         call_600818.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600818, url, valid)

proc call*(call_600819: Call_GetCSVHeader_600806; body: JsonNode): Recallable =
  ## getCSVHeader
  ## Gets the header information for the .csv file to be used as input for the user import job.
  ##   body: JObject (required)
  var body_600820 = newJObject()
  if body != nil:
    body_600820 = body
  result = call_600819.call(nil, nil, nil, nil, body_600820)

var getCSVHeader* = Call_GetCSVHeader_600806(name: "getCSVHeader",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetCSVHeader",
    validator: validate_GetCSVHeader_600807, base: "/", url: url_GetCSVHeader_600808,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevice_600821 = ref object of OpenApiRestCall_599368
proc url_GetDevice_600823(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevice_600822(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the device.
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
  var valid_600824 = header.getOrDefault("X-Amz-Date")
  valid_600824 = validateParameter(valid_600824, JString, required = false,
                                 default = nil)
  if valid_600824 != nil:
    section.add "X-Amz-Date", valid_600824
  var valid_600825 = header.getOrDefault("X-Amz-Security-Token")
  valid_600825 = validateParameter(valid_600825, JString, required = false,
                                 default = nil)
  if valid_600825 != nil:
    section.add "X-Amz-Security-Token", valid_600825
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600826 = header.getOrDefault("X-Amz-Target")
  valid_600826 = validateParameter(valid_600826, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetDevice"))
  if valid_600826 != nil:
    section.add "X-Amz-Target", valid_600826
  var valid_600827 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600827 = validateParameter(valid_600827, JString, required = false,
                                 default = nil)
  if valid_600827 != nil:
    section.add "X-Amz-Content-Sha256", valid_600827
  var valid_600828 = header.getOrDefault("X-Amz-Algorithm")
  valid_600828 = validateParameter(valid_600828, JString, required = false,
                                 default = nil)
  if valid_600828 != nil:
    section.add "X-Amz-Algorithm", valid_600828
  var valid_600829 = header.getOrDefault("X-Amz-Signature")
  valid_600829 = validateParameter(valid_600829, JString, required = false,
                                 default = nil)
  if valid_600829 != nil:
    section.add "X-Amz-Signature", valid_600829
  var valid_600830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600830 = validateParameter(valid_600830, JString, required = false,
                                 default = nil)
  if valid_600830 != nil:
    section.add "X-Amz-SignedHeaders", valid_600830
  var valid_600831 = header.getOrDefault("X-Amz-Credential")
  valid_600831 = validateParameter(valid_600831, JString, required = false,
                                 default = nil)
  if valid_600831 != nil:
    section.add "X-Amz-Credential", valid_600831
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600833: Call_GetDevice_600821; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the device.
  ## 
  let valid = call_600833.validator(path, query, header, formData, body)
  let scheme = call_600833.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600833.url(scheme.get, call_600833.host, call_600833.base,
                         call_600833.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600833, url, valid)

proc call*(call_600834: Call_GetDevice_600821; body: JsonNode): Recallable =
  ## getDevice
  ## Gets the device.
  ##   body: JObject (required)
  var body_600835 = newJObject()
  if body != nil:
    body_600835 = body
  result = call_600834.call(nil, nil, nil, nil, body_600835)

var getDevice* = Call_GetDevice_600821(name: "getDevice", meth: HttpMethod.HttpPost,
                                    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetDevice",
                                    validator: validate_GetDevice_600822,
                                    base: "/", url: url_GetDevice_600823,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroup_600836 = ref object of OpenApiRestCall_599368
proc url_GetGroup_600838(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGroup_600837(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets a group.</p> <p>Calling this action requires developer credentials.</p>
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
  var valid_600839 = header.getOrDefault("X-Amz-Date")
  valid_600839 = validateParameter(valid_600839, JString, required = false,
                                 default = nil)
  if valid_600839 != nil:
    section.add "X-Amz-Date", valid_600839
  var valid_600840 = header.getOrDefault("X-Amz-Security-Token")
  valid_600840 = validateParameter(valid_600840, JString, required = false,
                                 default = nil)
  if valid_600840 != nil:
    section.add "X-Amz-Security-Token", valid_600840
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600841 = header.getOrDefault("X-Amz-Target")
  valid_600841 = validateParameter(valid_600841, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetGroup"))
  if valid_600841 != nil:
    section.add "X-Amz-Target", valid_600841
  var valid_600842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600842 = validateParameter(valid_600842, JString, required = false,
                                 default = nil)
  if valid_600842 != nil:
    section.add "X-Amz-Content-Sha256", valid_600842
  var valid_600843 = header.getOrDefault("X-Amz-Algorithm")
  valid_600843 = validateParameter(valid_600843, JString, required = false,
                                 default = nil)
  if valid_600843 != nil:
    section.add "X-Amz-Algorithm", valid_600843
  var valid_600844 = header.getOrDefault("X-Amz-Signature")
  valid_600844 = validateParameter(valid_600844, JString, required = false,
                                 default = nil)
  if valid_600844 != nil:
    section.add "X-Amz-Signature", valid_600844
  var valid_600845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600845 = validateParameter(valid_600845, JString, required = false,
                                 default = nil)
  if valid_600845 != nil:
    section.add "X-Amz-SignedHeaders", valid_600845
  var valid_600846 = header.getOrDefault("X-Amz-Credential")
  valid_600846 = validateParameter(valid_600846, JString, required = false,
                                 default = nil)
  if valid_600846 != nil:
    section.add "X-Amz-Credential", valid_600846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600848: Call_GetGroup_600836; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a group.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_600848.validator(path, query, header, formData, body)
  let scheme = call_600848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600848.url(scheme.get, call_600848.host, call_600848.base,
                         call_600848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600848, url, valid)

proc call*(call_600849: Call_GetGroup_600836; body: JsonNode): Recallable =
  ## getGroup
  ## <p>Gets a group.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_600850 = newJObject()
  if body != nil:
    body_600850 = body
  result = call_600849.call(nil, nil, nil, nil, body_600850)

var getGroup* = Call_GetGroup_600836(name: "getGroup", meth: HttpMethod.HttpPost,
                                  host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetGroup",
                                  validator: validate_GetGroup_600837, base: "/",
                                  url: url_GetGroup_600838,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIdentityProviderByIdentifier_600851 = ref object of OpenApiRestCall_599368
proc url_GetIdentityProviderByIdentifier_600853(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetIdentityProviderByIdentifier_600852(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the specified identity provider.
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
  var valid_600854 = header.getOrDefault("X-Amz-Date")
  valid_600854 = validateParameter(valid_600854, JString, required = false,
                                 default = nil)
  if valid_600854 != nil:
    section.add "X-Amz-Date", valid_600854
  var valid_600855 = header.getOrDefault("X-Amz-Security-Token")
  valid_600855 = validateParameter(valid_600855, JString, required = false,
                                 default = nil)
  if valid_600855 != nil:
    section.add "X-Amz-Security-Token", valid_600855
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600856 = header.getOrDefault("X-Amz-Target")
  valid_600856 = validateParameter(valid_600856, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetIdentityProviderByIdentifier"))
  if valid_600856 != nil:
    section.add "X-Amz-Target", valid_600856
  var valid_600857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600857 = validateParameter(valid_600857, JString, required = false,
                                 default = nil)
  if valid_600857 != nil:
    section.add "X-Amz-Content-Sha256", valid_600857
  var valid_600858 = header.getOrDefault("X-Amz-Algorithm")
  valid_600858 = validateParameter(valid_600858, JString, required = false,
                                 default = nil)
  if valid_600858 != nil:
    section.add "X-Amz-Algorithm", valid_600858
  var valid_600859 = header.getOrDefault("X-Amz-Signature")
  valid_600859 = validateParameter(valid_600859, JString, required = false,
                                 default = nil)
  if valid_600859 != nil:
    section.add "X-Amz-Signature", valid_600859
  var valid_600860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600860 = validateParameter(valid_600860, JString, required = false,
                                 default = nil)
  if valid_600860 != nil:
    section.add "X-Amz-SignedHeaders", valid_600860
  var valid_600861 = header.getOrDefault("X-Amz-Credential")
  valid_600861 = validateParameter(valid_600861, JString, required = false,
                                 default = nil)
  if valid_600861 != nil:
    section.add "X-Amz-Credential", valid_600861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600863: Call_GetIdentityProviderByIdentifier_600851;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the specified identity provider.
  ## 
  let valid = call_600863.validator(path, query, header, formData, body)
  let scheme = call_600863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600863.url(scheme.get, call_600863.host, call_600863.base,
                         call_600863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600863, url, valid)

proc call*(call_600864: Call_GetIdentityProviderByIdentifier_600851; body: JsonNode): Recallable =
  ## getIdentityProviderByIdentifier
  ## Gets the specified identity provider.
  ##   body: JObject (required)
  var body_600865 = newJObject()
  if body != nil:
    body_600865 = body
  result = call_600864.call(nil, nil, nil, nil, body_600865)

var getIdentityProviderByIdentifier* = Call_GetIdentityProviderByIdentifier_600851(
    name: "getIdentityProviderByIdentifier", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetIdentityProviderByIdentifier",
    validator: validate_GetIdentityProviderByIdentifier_600852, base: "/",
    url: url_GetIdentityProviderByIdentifier_600853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSigningCertificate_600866 = ref object of OpenApiRestCall_599368
proc url_GetSigningCertificate_600868(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSigningCertificate_600867(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## This method takes a user pool ID, and returns the signing certificate.
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
  var valid_600869 = header.getOrDefault("X-Amz-Date")
  valid_600869 = validateParameter(valid_600869, JString, required = false,
                                 default = nil)
  if valid_600869 != nil:
    section.add "X-Amz-Date", valid_600869
  var valid_600870 = header.getOrDefault("X-Amz-Security-Token")
  valid_600870 = validateParameter(valid_600870, JString, required = false,
                                 default = nil)
  if valid_600870 != nil:
    section.add "X-Amz-Security-Token", valid_600870
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600871 = header.getOrDefault("X-Amz-Target")
  valid_600871 = validateParameter(valid_600871, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetSigningCertificate"))
  if valid_600871 != nil:
    section.add "X-Amz-Target", valid_600871
  var valid_600872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600872 = validateParameter(valid_600872, JString, required = false,
                                 default = nil)
  if valid_600872 != nil:
    section.add "X-Amz-Content-Sha256", valid_600872
  var valid_600873 = header.getOrDefault("X-Amz-Algorithm")
  valid_600873 = validateParameter(valid_600873, JString, required = false,
                                 default = nil)
  if valid_600873 != nil:
    section.add "X-Amz-Algorithm", valid_600873
  var valid_600874 = header.getOrDefault("X-Amz-Signature")
  valid_600874 = validateParameter(valid_600874, JString, required = false,
                                 default = nil)
  if valid_600874 != nil:
    section.add "X-Amz-Signature", valid_600874
  var valid_600875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600875 = validateParameter(valid_600875, JString, required = false,
                                 default = nil)
  if valid_600875 != nil:
    section.add "X-Amz-SignedHeaders", valid_600875
  var valid_600876 = header.getOrDefault("X-Amz-Credential")
  valid_600876 = validateParameter(valid_600876, JString, required = false,
                                 default = nil)
  if valid_600876 != nil:
    section.add "X-Amz-Credential", valid_600876
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600878: Call_GetSigningCertificate_600866; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This method takes a user pool ID, and returns the signing certificate.
  ## 
  let valid = call_600878.validator(path, query, header, formData, body)
  let scheme = call_600878.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600878.url(scheme.get, call_600878.host, call_600878.base,
                         call_600878.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600878, url, valid)

proc call*(call_600879: Call_GetSigningCertificate_600866; body: JsonNode): Recallable =
  ## getSigningCertificate
  ## This method takes a user pool ID, and returns the signing certificate.
  ##   body: JObject (required)
  var body_600880 = newJObject()
  if body != nil:
    body_600880 = body
  result = call_600879.call(nil, nil, nil, nil, body_600880)

var getSigningCertificate* = Call_GetSigningCertificate_600866(
    name: "getSigningCertificate", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetSigningCertificate",
    validator: validate_GetSigningCertificate_600867, base: "/",
    url: url_GetSigningCertificate_600868, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUICustomization_600881 = ref object of OpenApiRestCall_599368
proc url_GetUICustomization_600883(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUICustomization_600882(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Gets the UI Customization information for a particular app client's app UI, if there is something set. If nothing is set for the particular client, but there is an existing pool level customization (app <code>clientId</code> will be <code>ALL</code>), then that is returned. If nothing is present, then an empty shape is returned.
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
  var valid_600884 = header.getOrDefault("X-Amz-Date")
  valid_600884 = validateParameter(valid_600884, JString, required = false,
                                 default = nil)
  if valid_600884 != nil:
    section.add "X-Amz-Date", valid_600884
  var valid_600885 = header.getOrDefault("X-Amz-Security-Token")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "X-Amz-Security-Token", valid_600885
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600886 = header.getOrDefault("X-Amz-Target")
  valid_600886 = validateParameter(valid_600886, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUICustomization"))
  if valid_600886 != nil:
    section.add "X-Amz-Target", valid_600886
  var valid_600887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-Content-Sha256", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-Algorithm")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Algorithm", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-Signature")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Signature", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-SignedHeaders", valid_600890
  var valid_600891 = header.getOrDefault("X-Amz-Credential")
  valid_600891 = validateParameter(valid_600891, JString, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "X-Amz-Credential", valid_600891
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600893: Call_GetUICustomization_600881; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the UI Customization information for a particular app client's app UI, if there is something set. If nothing is set for the particular client, but there is an existing pool level customization (app <code>clientId</code> will be <code>ALL</code>), then that is returned. If nothing is present, then an empty shape is returned.
  ## 
  let valid = call_600893.validator(path, query, header, formData, body)
  let scheme = call_600893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600893.url(scheme.get, call_600893.host, call_600893.base,
                         call_600893.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600893, url, valid)

proc call*(call_600894: Call_GetUICustomization_600881; body: JsonNode): Recallable =
  ## getUICustomization
  ## Gets the UI Customization information for a particular app client's app UI, if there is something set. If nothing is set for the particular client, but there is an existing pool level customization (app <code>clientId</code> will be <code>ALL</code>), then that is returned. If nothing is present, then an empty shape is returned.
  ##   body: JObject (required)
  var body_600895 = newJObject()
  if body != nil:
    body_600895 = body
  result = call_600894.call(nil, nil, nil, nil, body_600895)

var getUICustomization* = Call_GetUICustomization_600881(
    name: "getUICustomization", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUICustomization",
    validator: validate_GetUICustomization_600882, base: "/",
    url: url_GetUICustomization_600883, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUser_600896 = ref object of OpenApiRestCall_599368
proc url_GetUser_600898(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUser_600897(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the user attributes and metadata for a user.
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
  var valid_600899 = header.getOrDefault("X-Amz-Date")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Date", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Security-Token")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Security-Token", valid_600900
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600901 = header.getOrDefault("X-Amz-Target")
  valid_600901 = validateParameter(valid_600901, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUser"))
  if valid_600901 != nil:
    section.add "X-Amz-Target", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Content-Sha256", valid_600902
  var valid_600903 = header.getOrDefault("X-Amz-Algorithm")
  valid_600903 = validateParameter(valid_600903, JString, required = false,
                                 default = nil)
  if valid_600903 != nil:
    section.add "X-Amz-Algorithm", valid_600903
  var valid_600904 = header.getOrDefault("X-Amz-Signature")
  valid_600904 = validateParameter(valid_600904, JString, required = false,
                                 default = nil)
  if valid_600904 != nil:
    section.add "X-Amz-Signature", valid_600904
  var valid_600905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "X-Amz-SignedHeaders", valid_600905
  var valid_600906 = header.getOrDefault("X-Amz-Credential")
  valid_600906 = validateParameter(valid_600906, JString, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "X-Amz-Credential", valid_600906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600908: Call_GetUser_600896; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the user attributes and metadata for a user.
  ## 
  let valid = call_600908.validator(path, query, header, formData, body)
  let scheme = call_600908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600908.url(scheme.get, call_600908.host, call_600908.base,
                         call_600908.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600908, url, valid)

proc call*(call_600909: Call_GetUser_600896; body: JsonNode): Recallable =
  ## getUser
  ## Gets the user attributes and metadata for a user.
  ##   body: JObject (required)
  var body_600910 = newJObject()
  if body != nil:
    body_600910 = body
  result = call_600909.call(nil, nil, nil, nil, body_600910)

var getUser* = Call_GetUser_600896(name: "getUser", meth: HttpMethod.HttpPost,
                                host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUser",
                                validator: validate_GetUser_600897, base: "/",
                                url: url_GetUser_600898,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserAttributeVerificationCode_600911 = ref object of OpenApiRestCall_599368
proc url_GetUserAttributeVerificationCode_600913(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUserAttributeVerificationCode_600912(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the user attribute verification code for the specified attribute name.
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
  var valid_600914 = header.getOrDefault("X-Amz-Date")
  valid_600914 = validateParameter(valid_600914, JString, required = false,
                                 default = nil)
  if valid_600914 != nil:
    section.add "X-Amz-Date", valid_600914
  var valid_600915 = header.getOrDefault("X-Amz-Security-Token")
  valid_600915 = validateParameter(valid_600915, JString, required = false,
                                 default = nil)
  if valid_600915 != nil:
    section.add "X-Amz-Security-Token", valid_600915
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600916 = header.getOrDefault("X-Amz-Target")
  valid_600916 = validateParameter(valid_600916, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUserAttributeVerificationCode"))
  if valid_600916 != nil:
    section.add "X-Amz-Target", valid_600916
  var valid_600917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600917 = validateParameter(valid_600917, JString, required = false,
                                 default = nil)
  if valid_600917 != nil:
    section.add "X-Amz-Content-Sha256", valid_600917
  var valid_600918 = header.getOrDefault("X-Amz-Algorithm")
  valid_600918 = validateParameter(valid_600918, JString, required = false,
                                 default = nil)
  if valid_600918 != nil:
    section.add "X-Amz-Algorithm", valid_600918
  var valid_600919 = header.getOrDefault("X-Amz-Signature")
  valid_600919 = validateParameter(valid_600919, JString, required = false,
                                 default = nil)
  if valid_600919 != nil:
    section.add "X-Amz-Signature", valid_600919
  var valid_600920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600920 = validateParameter(valid_600920, JString, required = false,
                                 default = nil)
  if valid_600920 != nil:
    section.add "X-Amz-SignedHeaders", valid_600920
  var valid_600921 = header.getOrDefault("X-Amz-Credential")
  valid_600921 = validateParameter(valid_600921, JString, required = false,
                                 default = nil)
  if valid_600921 != nil:
    section.add "X-Amz-Credential", valid_600921
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600923: Call_GetUserAttributeVerificationCode_600911;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the user attribute verification code for the specified attribute name.
  ## 
  let valid = call_600923.validator(path, query, header, formData, body)
  let scheme = call_600923.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600923.url(scheme.get, call_600923.host, call_600923.base,
                         call_600923.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600923, url, valid)

proc call*(call_600924: Call_GetUserAttributeVerificationCode_600911;
          body: JsonNode): Recallable =
  ## getUserAttributeVerificationCode
  ## Gets the user attribute verification code for the specified attribute name.
  ##   body: JObject (required)
  var body_600925 = newJObject()
  if body != nil:
    body_600925 = body
  result = call_600924.call(nil, nil, nil, nil, body_600925)

var getUserAttributeVerificationCode* = Call_GetUserAttributeVerificationCode_600911(
    name: "getUserAttributeVerificationCode", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUserAttributeVerificationCode",
    validator: validate_GetUserAttributeVerificationCode_600912, base: "/",
    url: url_GetUserAttributeVerificationCode_600913,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserPoolMfaConfig_600926 = ref object of OpenApiRestCall_599368
proc url_GetUserPoolMfaConfig_600928(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUserPoolMfaConfig_600927(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the user pool multi-factor authentication (MFA) configuration.
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
  var valid_600929 = header.getOrDefault("X-Amz-Date")
  valid_600929 = validateParameter(valid_600929, JString, required = false,
                                 default = nil)
  if valid_600929 != nil:
    section.add "X-Amz-Date", valid_600929
  var valid_600930 = header.getOrDefault("X-Amz-Security-Token")
  valid_600930 = validateParameter(valid_600930, JString, required = false,
                                 default = nil)
  if valid_600930 != nil:
    section.add "X-Amz-Security-Token", valid_600930
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600931 = header.getOrDefault("X-Amz-Target")
  valid_600931 = validateParameter(valid_600931, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUserPoolMfaConfig"))
  if valid_600931 != nil:
    section.add "X-Amz-Target", valid_600931
  var valid_600932 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600932 = validateParameter(valid_600932, JString, required = false,
                                 default = nil)
  if valid_600932 != nil:
    section.add "X-Amz-Content-Sha256", valid_600932
  var valid_600933 = header.getOrDefault("X-Amz-Algorithm")
  valid_600933 = validateParameter(valid_600933, JString, required = false,
                                 default = nil)
  if valid_600933 != nil:
    section.add "X-Amz-Algorithm", valid_600933
  var valid_600934 = header.getOrDefault("X-Amz-Signature")
  valid_600934 = validateParameter(valid_600934, JString, required = false,
                                 default = nil)
  if valid_600934 != nil:
    section.add "X-Amz-Signature", valid_600934
  var valid_600935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600935 = validateParameter(valid_600935, JString, required = false,
                                 default = nil)
  if valid_600935 != nil:
    section.add "X-Amz-SignedHeaders", valid_600935
  var valid_600936 = header.getOrDefault("X-Amz-Credential")
  valid_600936 = validateParameter(valid_600936, JString, required = false,
                                 default = nil)
  if valid_600936 != nil:
    section.add "X-Amz-Credential", valid_600936
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600938: Call_GetUserPoolMfaConfig_600926; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the user pool multi-factor authentication (MFA) configuration.
  ## 
  let valid = call_600938.validator(path, query, header, formData, body)
  let scheme = call_600938.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600938.url(scheme.get, call_600938.host, call_600938.base,
                         call_600938.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600938, url, valid)

proc call*(call_600939: Call_GetUserPoolMfaConfig_600926; body: JsonNode): Recallable =
  ## getUserPoolMfaConfig
  ## Gets the user pool multi-factor authentication (MFA) configuration.
  ##   body: JObject (required)
  var body_600940 = newJObject()
  if body != nil:
    body_600940 = body
  result = call_600939.call(nil, nil, nil, nil, body_600940)

var getUserPoolMfaConfig* = Call_GetUserPoolMfaConfig_600926(
    name: "getUserPoolMfaConfig", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUserPoolMfaConfig",
    validator: validate_GetUserPoolMfaConfig_600927, base: "/",
    url: url_GetUserPoolMfaConfig_600928, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GlobalSignOut_600941 = ref object of OpenApiRestCall_599368
proc url_GlobalSignOut_600943(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GlobalSignOut_600942(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Signs out users from all devices. It also invalidates all refresh tokens issued to a user. The user's current access and Id tokens remain valid until their expiry. Access and Id tokens expire one hour after they are issued.
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
  var valid_600944 = header.getOrDefault("X-Amz-Date")
  valid_600944 = validateParameter(valid_600944, JString, required = false,
                                 default = nil)
  if valid_600944 != nil:
    section.add "X-Amz-Date", valid_600944
  var valid_600945 = header.getOrDefault("X-Amz-Security-Token")
  valid_600945 = validateParameter(valid_600945, JString, required = false,
                                 default = nil)
  if valid_600945 != nil:
    section.add "X-Amz-Security-Token", valid_600945
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600946 = header.getOrDefault("X-Amz-Target")
  valid_600946 = validateParameter(valid_600946, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GlobalSignOut"))
  if valid_600946 != nil:
    section.add "X-Amz-Target", valid_600946
  var valid_600947 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600947 = validateParameter(valid_600947, JString, required = false,
                                 default = nil)
  if valid_600947 != nil:
    section.add "X-Amz-Content-Sha256", valid_600947
  var valid_600948 = header.getOrDefault("X-Amz-Algorithm")
  valid_600948 = validateParameter(valid_600948, JString, required = false,
                                 default = nil)
  if valid_600948 != nil:
    section.add "X-Amz-Algorithm", valid_600948
  var valid_600949 = header.getOrDefault("X-Amz-Signature")
  valid_600949 = validateParameter(valid_600949, JString, required = false,
                                 default = nil)
  if valid_600949 != nil:
    section.add "X-Amz-Signature", valid_600949
  var valid_600950 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600950 = validateParameter(valid_600950, JString, required = false,
                                 default = nil)
  if valid_600950 != nil:
    section.add "X-Amz-SignedHeaders", valid_600950
  var valid_600951 = header.getOrDefault("X-Amz-Credential")
  valid_600951 = validateParameter(valid_600951, JString, required = false,
                                 default = nil)
  if valid_600951 != nil:
    section.add "X-Amz-Credential", valid_600951
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600953: Call_GlobalSignOut_600941; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Signs out users from all devices. It also invalidates all refresh tokens issued to a user. The user's current access and Id tokens remain valid until their expiry. Access and Id tokens expire one hour after they are issued.
  ## 
  let valid = call_600953.validator(path, query, header, formData, body)
  let scheme = call_600953.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600953.url(scheme.get, call_600953.host, call_600953.base,
                         call_600953.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600953, url, valid)

proc call*(call_600954: Call_GlobalSignOut_600941; body: JsonNode): Recallable =
  ## globalSignOut
  ## Signs out users from all devices. It also invalidates all refresh tokens issued to a user. The user's current access and Id tokens remain valid until their expiry. Access and Id tokens expire one hour after they are issued.
  ##   body: JObject (required)
  var body_600955 = newJObject()
  if body != nil:
    body_600955 = body
  result = call_600954.call(nil, nil, nil, nil, body_600955)

var globalSignOut* = Call_GlobalSignOut_600941(name: "globalSignOut",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GlobalSignOut",
    validator: validate_GlobalSignOut_600942, base: "/", url: url_GlobalSignOut_600943,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateAuth_600956 = ref object of OpenApiRestCall_599368
proc url_InitiateAuth_600958(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_InitiateAuth_600957(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Initiates the authentication flow.
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
  var valid_600959 = header.getOrDefault("X-Amz-Date")
  valid_600959 = validateParameter(valid_600959, JString, required = false,
                                 default = nil)
  if valid_600959 != nil:
    section.add "X-Amz-Date", valid_600959
  var valid_600960 = header.getOrDefault("X-Amz-Security-Token")
  valid_600960 = validateParameter(valid_600960, JString, required = false,
                                 default = nil)
  if valid_600960 != nil:
    section.add "X-Amz-Security-Token", valid_600960
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600961 = header.getOrDefault("X-Amz-Target")
  valid_600961 = validateParameter(valid_600961, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.InitiateAuth"))
  if valid_600961 != nil:
    section.add "X-Amz-Target", valid_600961
  var valid_600962 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600962 = validateParameter(valid_600962, JString, required = false,
                                 default = nil)
  if valid_600962 != nil:
    section.add "X-Amz-Content-Sha256", valid_600962
  var valid_600963 = header.getOrDefault("X-Amz-Algorithm")
  valid_600963 = validateParameter(valid_600963, JString, required = false,
                                 default = nil)
  if valid_600963 != nil:
    section.add "X-Amz-Algorithm", valid_600963
  var valid_600964 = header.getOrDefault("X-Amz-Signature")
  valid_600964 = validateParameter(valid_600964, JString, required = false,
                                 default = nil)
  if valid_600964 != nil:
    section.add "X-Amz-Signature", valid_600964
  var valid_600965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600965 = validateParameter(valid_600965, JString, required = false,
                                 default = nil)
  if valid_600965 != nil:
    section.add "X-Amz-SignedHeaders", valid_600965
  var valid_600966 = header.getOrDefault("X-Amz-Credential")
  valid_600966 = validateParameter(valid_600966, JString, required = false,
                                 default = nil)
  if valid_600966 != nil:
    section.add "X-Amz-Credential", valid_600966
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600968: Call_InitiateAuth_600956; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates the authentication flow.
  ## 
  let valid = call_600968.validator(path, query, header, formData, body)
  let scheme = call_600968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600968.url(scheme.get, call_600968.host, call_600968.base,
                         call_600968.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600968, url, valid)

proc call*(call_600969: Call_InitiateAuth_600956; body: JsonNode): Recallable =
  ## initiateAuth
  ## Initiates the authentication flow.
  ##   body: JObject (required)
  var body_600970 = newJObject()
  if body != nil:
    body_600970 = body
  result = call_600969.call(nil, nil, nil, nil, body_600970)

var initiateAuth* = Call_InitiateAuth_600956(name: "initiateAuth",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.InitiateAuth",
    validator: validate_InitiateAuth_600957, base: "/", url: url_InitiateAuth_600958,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevices_600971 = ref object of OpenApiRestCall_599368
proc url_ListDevices_600973(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDevices_600972(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the devices.
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
  var valid_600974 = header.getOrDefault("X-Amz-Date")
  valid_600974 = validateParameter(valid_600974, JString, required = false,
                                 default = nil)
  if valid_600974 != nil:
    section.add "X-Amz-Date", valid_600974
  var valid_600975 = header.getOrDefault("X-Amz-Security-Token")
  valid_600975 = validateParameter(valid_600975, JString, required = false,
                                 default = nil)
  if valid_600975 != nil:
    section.add "X-Amz-Security-Token", valid_600975
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600976 = header.getOrDefault("X-Amz-Target")
  valid_600976 = validateParameter(valid_600976, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListDevices"))
  if valid_600976 != nil:
    section.add "X-Amz-Target", valid_600976
  var valid_600977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600977 = validateParameter(valid_600977, JString, required = false,
                                 default = nil)
  if valid_600977 != nil:
    section.add "X-Amz-Content-Sha256", valid_600977
  var valid_600978 = header.getOrDefault("X-Amz-Algorithm")
  valid_600978 = validateParameter(valid_600978, JString, required = false,
                                 default = nil)
  if valid_600978 != nil:
    section.add "X-Amz-Algorithm", valid_600978
  var valid_600979 = header.getOrDefault("X-Amz-Signature")
  valid_600979 = validateParameter(valid_600979, JString, required = false,
                                 default = nil)
  if valid_600979 != nil:
    section.add "X-Amz-Signature", valid_600979
  var valid_600980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600980 = validateParameter(valid_600980, JString, required = false,
                                 default = nil)
  if valid_600980 != nil:
    section.add "X-Amz-SignedHeaders", valid_600980
  var valid_600981 = header.getOrDefault("X-Amz-Credential")
  valid_600981 = validateParameter(valid_600981, JString, required = false,
                                 default = nil)
  if valid_600981 != nil:
    section.add "X-Amz-Credential", valid_600981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600983: Call_ListDevices_600971; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the devices.
  ## 
  let valid = call_600983.validator(path, query, header, formData, body)
  let scheme = call_600983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600983.url(scheme.get, call_600983.host, call_600983.base,
                         call_600983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600983, url, valid)

proc call*(call_600984: Call_ListDevices_600971; body: JsonNode): Recallable =
  ## listDevices
  ## Lists the devices.
  ##   body: JObject (required)
  var body_600985 = newJObject()
  if body != nil:
    body_600985 = body
  result = call_600984.call(nil, nil, nil, nil, body_600985)

var listDevices* = Call_ListDevices_600971(name: "listDevices",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListDevices",
                                        validator: validate_ListDevices_600972,
                                        base: "/", url: url_ListDevices_600973,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_600986 = ref object of OpenApiRestCall_599368
proc url_ListGroups_600988(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGroups_600987(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the groups associated with a user pool.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600989 = query.getOrDefault("Limit")
  valid_600989 = validateParameter(valid_600989, JString, required = false,
                                 default = nil)
  if valid_600989 != nil:
    section.add "Limit", valid_600989
  var valid_600990 = query.getOrDefault("NextToken")
  valid_600990 = validateParameter(valid_600990, JString, required = false,
                                 default = nil)
  if valid_600990 != nil:
    section.add "NextToken", valid_600990
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
  var valid_600991 = header.getOrDefault("X-Amz-Date")
  valid_600991 = validateParameter(valid_600991, JString, required = false,
                                 default = nil)
  if valid_600991 != nil:
    section.add "X-Amz-Date", valid_600991
  var valid_600992 = header.getOrDefault("X-Amz-Security-Token")
  valid_600992 = validateParameter(valid_600992, JString, required = false,
                                 default = nil)
  if valid_600992 != nil:
    section.add "X-Amz-Security-Token", valid_600992
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600993 = header.getOrDefault("X-Amz-Target")
  valid_600993 = validateParameter(valid_600993, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListGroups"))
  if valid_600993 != nil:
    section.add "X-Amz-Target", valid_600993
  var valid_600994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600994 = validateParameter(valid_600994, JString, required = false,
                                 default = nil)
  if valid_600994 != nil:
    section.add "X-Amz-Content-Sha256", valid_600994
  var valid_600995 = header.getOrDefault("X-Amz-Algorithm")
  valid_600995 = validateParameter(valid_600995, JString, required = false,
                                 default = nil)
  if valid_600995 != nil:
    section.add "X-Amz-Algorithm", valid_600995
  var valid_600996 = header.getOrDefault("X-Amz-Signature")
  valid_600996 = validateParameter(valid_600996, JString, required = false,
                                 default = nil)
  if valid_600996 != nil:
    section.add "X-Amz-Signature", valid_600996
  var valid_600997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600997 = validateParameter(valid_600997, JString, required = false,
                                 default = nil)
  if valid_600997 != nil:
    section.add "X-Amz-SignedHeaders", valid_600997
  var valid_600998 = header.getOrDefault("X-Amz-Credential")
  valid_600998 = validateParameter(valid_600998, JString, required = false,
                                 default = nil)
  if valid_600998 != nil:
    section.add "X-Amz-Credential", valid_600998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601000: Call_ListGroups_600986; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the groups associated with a user pool.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_601000.validator(path, query, header, formData, body)
  let scheme = call_601000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601000.url(scheme.get, call_601000.host, call_601000.base,
                         call_601000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601000, url, valid)

proc call*(call_601001: Call_ListGroups_600986; body: JsonNode; Limit: string = "";
          NextToken: string = ""): Recallable =
  ## listGroups
  ## <p>Lists the groups associated with a user pool.</p> <p>Calling this action requires developer credentials.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601002 = newJObject()
  var body_601003 = newJObject()
  add(query_601002, "Limit", newJString(Limit))
  add(query_601002, "NextToken", newJString(NextToken))
  if body != nil:
    body_601003 = body
  result = call_601001.call(nil, query_601002, nil, nil, body_601003)

var listGroups* = Call_ListGroups_600986(name: "listGroups",
                                      meth: HttpMethod.HttpPost,
                                      host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListGroups",
                                      validator: validate_ListGroups_600987,
                                      base: "/", url: url_ListGroups_600988,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIdentityProviders_601004 = ref object of OpenApiRestCall_599368
proc url_ListIdentityProviders_601006(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListIdentityProviders_601005(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists information about all identity providers for a user pool.
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
  var valid_601007 = query.getOrDefault("NextToken")
  valid_601007 = validateParameter(valid_601007, JString, required = false,
                                 default = nil)
  if valid_601007 != nil:
    section.add "NextToken", valid_601007
  var valid_601008 = query.getOrDefault("MaxResults")
  valid_601008 = validateParameter(valid_601008, JString, required = false,
                                 default = nil)
  if valid_601008 != nil:
    section.add "MaxResults", valid_601008
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
  var valid_601009 = header.getOrDefault("X-Amz-Date")
  valid_601009 = validateParameter(valid_601009, JString, required = false,
                                 default = nil)
  if valid_601009 != nil:
    section.add "X-Amz-Date", valid_601009
  var valid_601010 = header.getOrDefault("X-Amz-Security-Token")
  valid_601010 = validateParameter(valid_601010, JString, required = false,
                                 default = nil)
  if valid_601010 != nil:
    section.add "X-Amz-Security-Token", valid_601010
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601011 = header.getOrDefault("X-Amz-Target")
  valid_601011 = validateParameter(valid_601011, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListIdentityProviders"))
  if valid_601011 != nil:
    section.add "X-Amz-Target", valid_601011
  var valid_601012 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601012 = validateParameter(valid_601012, JString, required = false,
                                 default = nil)
  if valid_601012 != nil:
    section.add "X-Amz-Content-Sha256", valid_601012
  var valid_601013 = header.getOrDefault("X-Amz-Algorithm")
  valid_601013 = validateParameter(valid_601013, JString, required = false,
                                 default = nil)
  if valid_601013 != nil:
    section.add "X-Amz-Algorithm", valid_601013
  var valid_601014 = header.getOrDefault("X-Amz-Signature")
  valid_601014 = validateParameter(valid_601014, JString, required = false,
                                 default = nil)
  if valid_601014 != nil:
    section.add "X-Amz-Signature", valid_601014
  var valid_601015 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601015 = validateParameter(valid_601015, JString, required = false,
                                 default = nil)
  if valid_601015 != nil:
    section.add "X-Amz-SignedHeaders", valid_601015
  var valid_601016 = header.getOrDefault("X-Amz-Credential")
  valid_601016 = validateParameter(valid_601016, JString, required = false,
                                 default = nil)
  if valid_601016 != nil:
    section.add "X-Amz-Credential", valid_601016
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601018: Call_ListIdentityProviders_601004; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about all identity providers for a user pool.
  ## 
  let valid = call_601018.validator(path, query, header, formData, body)
  let scheme = call_601018.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601018.url(scheme.get, call_601018.host, call_601018.base,
                         call_601018.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601018, url, valid)

proc call*(call_601019: Call_ListIdentityProviders_601004; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listIdentityProviders
  ## Lists information about all identity providers for a user pool.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601020 = newJObject()
  var body_601021 = newJObject()
  add(query_601020, "NextToken", newJString(NextToken))
  if body != nil:
    body_601021 = body
  add(query_601020, "MaxResults", newJString(MaxResults))
  result = call_601019.call(nil, query_601020, nil, nil, body_601021)

var listIdentityProviders* = Call_ListIdentityProviders_601004(
    name: "listIdentityProviders", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListIdentityProviders",
    validator: validate_ListIdentityProviders_601005, base: "/",
    url: url_ListIdentityProviders_601006, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceServers_601022 = ref object of OpenApiRestCall_599368
proc url_ListResourceServers_601024(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResourceServers_601023(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the resource servers for a user pool.
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
  var valid_601025 = query.getOrDefault("NextToken")
  valid_601025 = validateParameter(valid_601025, JString, required = false,
                                 default = nil)
  if valid_601025 != nil:
    section.add "NextToken", valid_601025
  var valid_601026 = query.getOrDefault("MaxResults")
  valid_601026 = validateParameter(valid_601026, JString, required = false,
                                 default = nil)
  if valid_601026 != nil:
    section.add "MaxResults", valid_601026
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
  var valid_601027 = header.getOrDefault("X-Amz-Date")
  valid_601027 = validateParameter(valid_601027, JString, required = false,
                                 default = nil)
  if valid_601027 != nil:
    section.add "X-Amz-Date", valid_601027
  var valid_601028 = header.getOrDefault("X-Amz-Security-Token")
  valid_601028 = validateParameter(valid_601028, JString, required = false,
                                 default = nil)
  if valid_601028 != nil:
    section.add "X-Amz-Security-Token", valid_601028
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601029 = header.getOrDefault("X-Amz-Target")
  valid_601029 = validateParameter(valid_601029, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListResourceServers"))
  if valid_601029 != nil:
    section.add "X-Amz-Target", valid_601029
  var valid_601030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601030 = validateParameter(valid_601030, JString, required = false,
                                 default = nil)
  if valid_601030 != nil:
    section.add "X-Amz-Content-Sha256", valid_601030
  var valid_601031 = header.getOrDefault("X-Amz-Algorithm")
  valid_601031 = validateParameter(valid_601031, JString, required = false,
                                 default = nil)
  if valid_601031 != nil:
    section.add "X-Amz-Algorithm", valid_601031
  var valid_601032 = header.getOrDefault("X-Amz-Signature")
  valid_601032 = validateParameter(valid_601032, JString, required = false,
                                 default = nil)
  if valid_601032 != nil:
    section.add "X-Amz-Signature", valid_601032
  var valid_601033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601033 = validateParameter(valid_601033, JString, required = false,
                                 default = nil)
  if valid_601033 != nil:
    section.add "X-Amz-SignedHeaders", valid_601033
  var valid_601034 = header.getOrDefault("X-Amz-Credential")
  valid_601034 = validateParameter(valid_601034, JString, required = false,
                                 default = nil)
  if valid_601034 != nil:
    section.add "X-Amz-Credential", valid_601034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601036: Call_ListResourceServers_601022; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resource servers for a user pool.
  ## 
  let valid = call_601036.validator(path, query, header, formData, body)
  let scheme = call_601036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601036.url(scheme.get, call_601036.host, call_601036.base,
                         call_601036.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601036, url, valid)

proc call*(call_601037: Call_ListResourceServers_601022; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listResourceServers
  ## Lists the resource servers for a user pool.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601038 = newJObject()
  var body_601039 = newJObject()
  add(query_601038, "NextToken", newJString(NextToken))
  if body != nil:
    body_601039 = body
  add(query_601038, "MaxResults", newJString(MaxResults))
  result = call_601037.call(nil, query_601038, nil, nil, body_601039)

var listResourceServers* = Call_ListResourceServers_601022(
    name: "listResourceServers", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListResourceServers",
    validator: validate_ListResourceServers_601023, base: "/",
    url: url_ListResourceServers_601024, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_601040 = ref object of OpenApiRestCall_599368
proc url_ListTagsForResource_601042(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_601041(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Lists the tags that are assigned to an Amazon Cognito user pool.</p> <p>A tag is a label that you can apply to user pools to categorize and manage them in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>You can use this action up to 10 times per second, per account.</p>
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
  var valid_601043 = header.getOrDefault("X-Amz-Date")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Date", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Security-Token")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Security-Token", valid_601044
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601045 = header.getOrDefault("X-Amz-Target")
  valid_601045 = validateParameter(valid_601045, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListTagsForResource"))
  if valid_601045 != nil:
    section.add "X-Amz-Target", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Content-Sha256", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Algorithm")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Algorithm", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-Signature")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Signature", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-SignedHeaders", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-Credential")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Credential", valid_601050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601052: Call_ListTagsForResource_601040; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the tags that are assigned to an Amazon Cognito user pool.</p> <p>A tag is a label that you can apply to user pools to categorize and manage them in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>You can use this action up to 10 times per second, per account.</p>
  ## 
  let valid = call_601052.validator(path, query, header, formData, body)
  let scheme = call_601052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601052.url(scheme.get, call_601052.host, call_601052.base,
                         call_601052.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601052, url, valid)

proc call*(call_601053: Call_ListTagsForResource_601040; body: JsonNode): Recallable =
  ## listTagsForResource
  ## <p>Lists the tags that are assigned to an Amazon Cognito user pool.</p> <p>A tag is a label that you can apply to user pools to categorize and manage them in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>You can use this action up to 10 times per second, per account.</p>
  ##   body: JObject (required)
  var body_601054 = newJObject()
  if body != nil:
    body_601054 = body
  result = call_601053.call(nil, nil, nil, nil, body_601054)

var listTagsForResource* = Call_ListTagsForResource_601040(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListTagsForResource",
    validator: validate_ListTagsForResource_601041, base: "/",
    url: url_ListTagsForResource_601042, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserImportJobs_601055 = ref object of OpenApiRestCall_599368
proc url_ListUserImportJobs_601057(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUserImportJobs_601056(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Lists the user import jobs.
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
  var valid_601058 = header.getOrDefault("X-Amz-Date")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Date", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Security-Token")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Security-Token", valid_601059
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601060 = header.getOrDefault("X-Amz-Target")
  valid_601060 = validateParameter(valid_601060, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUserImportJobs"))
  if valid_601060 != nil:
    section.add "X-Amz-Target", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Content-Sha256", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Algorithm")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Algorithm", valid_601062
  var valid_601063 = header.getOrDefault("X-Amz-Signature")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-Signature", valid_601063
  var valid_601064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-SignedHeaders", valid_601064
  var valid_601065 = header.getOrDefault("X-Amz-Credential")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Credential", valid_601065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601067: Call_ListUserImportJobs_601055; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the user import jobs.
  ## 
  let valid = call_601067.validator(path, query, header, formData, body)
  let scheme = call_601067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601067.url(scheme.get, call_601067.host, call_601067.base,
                         call_601067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601067, url, valid)

proc call*(call_601068: Call_ListUserImportJobs_601055; body: JsonNode): Recallable =
  ## listUserImportJobs
  ## Lists the user import jobs.
  ##   body: JObject (required)
  var body_601069 = newJObject()
  if body != nil:
    body_601069 = body
  result = call_601068.call(nil, nil, nil, nil, body_601069)

var listUserImportJobs* = Call_ListUserImportJobs_601055(
    name: "listUserImportJobs", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUserImportJobs",
    validator: validate_ListUserImportJobs_601056, base: "/",
    url: url_ListUserImportJobs_601057, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserPoolClients_601070 = ref object of OpenApiRestCall_599368
proc url_ListUserPoolClients_601072(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUserPoolClients_601071(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the clients that have been created for the specified user pool.
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
  var valid_601073 = query.getOrDefault("NextToken")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "NextToken", valid_601073
  var valid_601074 = query.getOrDefault("MaxResults")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "MaxResults", valid_601074
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
  var valid_601075 = header.getOrDefault("X-Amz-Date")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Date", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-Security-Token")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Security-Token", valid_601076
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601077 = header.getOrDefault("X-Amz-Target")
  valid_601077 = validateParameter(valid_601077, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUserPoolClients"))
  if valid_601077 != nil:
    section.add "X-Amz-Target", valid_601077
  var valid_601078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601078 = validateParameter(valid_601078, JString, required = false,
                                 default = nil)
  if valid_601078 != nil:
    section.add "X-Amz-Content-Sha256", valid_601078
  var valid_601079 = header.getOrDefault("X-Amz-Algorithm")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "X-Amz-Algorithm", valid_601079
  var valid_601080 = header.getOrDefault("X-Amz-Signature")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "X-Amz-Signature", valid_601080
  var valid_601081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-SignedHeaders", valid_601081
  var valid_601082 = header.getOrDefault("X-Amz-Credential")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-Credential", valid_601082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601084: Call_ListUserPoolClients_601070; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the clients that have been created for the specified user pool.
  ## 
  let valid = call_601084.validator(path, query, header, formData, body)
  let scheme = call_601084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601084.url(scheme.get, call_601084.host, call_601084.base,
                         call_601084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601084, url, valid)

proc call*(call_601085: Call_ListUserPoolClients_601070; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listUserPoolClients
  ## Lists the clients that have been created for the specified user pool.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601086 = newJObject()
  var body_601087 = newJObject()
  add(query_601086, "NextToken", newJString(NextToken))
  if body != nil:
    body_601087 = body
  add(query_601086, "MaxResults", newJString(MaxResults))
  result = call_601085.call(nil, query_601086, nil, nil, body_601087)

var listUserPoolClients* = Call_ListUserPoolClients_601070(
    name: "listUserPoolClients", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUserPoolClients",
    validator: validate_ListUserPoolClients_601071, base: "/",
    url: url_ListUserPoolClients_601072, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserPools_601088 = ref object of OpenApiRestCall_599368
proc url_ListUserPools_601090(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUserPools_601089(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the user pools associated with an AWS account.
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
  var valid_601091 = query.getOrDefault("NextToken")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "NextToken", valid_601091
  var valid_601092 = query.getOrDefault("MaxResults")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "MaxResults", valid_601092
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
  var valid_601093 = header.getOrDefault("X-Amz-Date")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-Date", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-Security-Token")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Security-Token", valid_601094
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601095 = header.getOrDefault("X-Amz-Target")
  valid_601095 = validateParameter(valid_601095, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUserPools"))
  if valid_601095 != nil:
    section.add "X-Amz-Target", valid_601095
  var valid_601096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-Content-Sha256", valid_601096
  var valid_601097 = header.getOrDefault("X-Amz-Algorithm")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-Algorithm", valid_601097
  var valid_601098 = header.getOrDefault("X-Amz-Signature")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-Signature", valid_601098
  var valid_601099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "X-Amz-SignedHeaders", valid_601099
  var valid_601100 = header.getOrDefault("X-Amz-Credential")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Credential", valid_601100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601102: Call_ListUserPools_601088; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the user pools associated with an AWS account.
  ## 
  let valid = call_601102.validator(path, query, header, formData, body)
  let scheme = call_601102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601102.url(scheme.get, call_601102.host, call_601102.base,
                         call_601102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601102, url, valid)

proc call*(call_601103: Call_ListUserPools_601088; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listUserPools
  ## Lists the user pools associated with an AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601104 = newJObject()
  var body_601105 = newJObject()
  add(query_601104, "NextToken", newJString(NextToken))
  if body != nil:
    body_601105 = body
  add(query_601104, "MaxResults", newJString(MaxResults))
  result = call_601103.call(nil, query_601104, nil, nil, body_601105)

var listUserPools* = Call_ListUserPools_601088(name: "listUserPools",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUserPools",
    validator: validate_ListUserPools_601089, base: "/", url: url_ListUserPools_601090,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_601106 = ref object of OpenApiRestCall_599368
proc url_ListUsers_601108(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUsers_601107(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the users in the Amazon Cognito user pool.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   PaginationToken: JString
  ##                  : Pagination token
  section = newJObject()
  var valid_601109 = query.getOrDefault("Limit")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "Limit", valid_601109
  var valid_601110 = query.getOrDefault("PaginationToken")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "PaginationToken", valid_601110
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
  var valid_601111 = header.getOrDefault("X-Amz-Date")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-Date", valid_601111
  var valid_601112 = header.getOrDefault("X-Amz-Security-Token")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-Security-Token", valid_601112
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601113 = header.getOrDefault("X-Amz-Target")
  valid_601113 = validateParameter(valid_601113, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUsers"))
  if valid_601113 != nil:
    section.add "X-Amz-Target", valid_601113
  var valid_601114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "X-Amz-Content-Sha256", valid_601114
  var valid_601115 = header.getOrDefault("X-Amz-Algorithm")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Algorithm", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Signature")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Signature", valid_601116
  var valid_601117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "X-Amz-SignedHeaders", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Credential")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Credential", valid_601118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601120: Call_ListUsers_601106; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the users in the Amazon Cognito user pool.
  ## 
  let valid = call_601120.validator(path, query, header, formData, body)
  let scheme = call_601120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601120.url(scheme.get, call_601120.host, call_601120.base,
                         call_601120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601120, url, valid)

proc call*(call_601121: Call_ListUsers_601106; body: JsonNode; Limit: string = "";
          PaginationToken: string = ""): Recallable =
  ## listUsers
  ## Lists the users in the Amazon Cognito user pool.
  ##   Limit: string
  ##        : Pagination limit
  ##   PaginationToken: string
  ##                  : Pagination token
  ##   body: JObject (required)
  var query_601122 = newJObject()
  var body_601123 = newJObject()
  add(query_601122, "Limit", newJString(Limit))
  add(query_601122, "PaginationToken", newJString(PaginationToken))
  if body != nil:
    body_601123 = body
  result = call_601121.call(nil, query_601122, nil, nil, body_601123)

var listUsers* = Call_ListUsers_601106(name: "listUsers", meth: HttpMethod.HttpPost,
                                    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUsers",
                                    validator: validate_ListUsers_601107,
                                    base: "/", url: url_ListUsers_601108,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsersInGroup_601124 = ref object of OpenApiRestCall_599368
proc url_ListUsersInGroup_601126(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUsersInGroup_601125(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Lists the users in the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_601127 = query.getOrDefault("Limit")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "Limit", valid_601127
  var valid_601128 = query.getOrDefault("NextToken")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "NextToken", valid_601128
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
  var valid_601129 = header.getOrDefault("X-Amz-Date")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-Date", valid_601129
  var valid_601130 = header.getOrDefault("X-Amz-Security-Token")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Security-Token", valid_601130
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601131 = header.getOrDefault("X-Amz-Target")
  valid_601131 = validateParameter(valid_601131, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUsersInGroup"))
  if valid_601131 != nil:
    section.add "X-Amz-Target", valid_601131
  var valid_601132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "X-Amz-Content-Sha256", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Algorithm")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Algorithm", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Signature")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Signature", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-SignedHeaders", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-Credential")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Credential", valid_601136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601138: Call_ListUsersInGroup_601124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the users in the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_601138.validator(path, query, header, formData, body)
  let scheme = call_601138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601138.url(scheme.get, call_601138.host, call_601138.base,
                         call_601138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601138, url, valid)

proc call*(call_601139: Call_ListUsersInGroup_601124; body: JsonNode;
          Limit: string = ""; NextToken: string = ""): Recallable =
  ## listUsersInGroup
  ## <p>Lists the users in the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601140 = newJObject()
  var body_601141 = newJObject()
  add(query_601140, "Limit", newJString(Limit))
  add(query_601140, "NextToken", newJString(NextToken))
  if body != nil:
    body_601141 = body
  result = call_601139.call(nil, query_601140, nil, nil, body_601141)

var listUsersInGroup* = Call_ListUsersInGroup_601124(name: "listUsersInGroup",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUsersInGroup",
    validator: validate_ListUsersInGroup_601125, base: "/",
    url: url_ListUsersInGroup_601126, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResendConfirmationCode_601142 = ref object of OpenApiRestCall_599368
proc url_ResendConfirmationCode_601144(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ResendConfirmationCode_601143(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Resends the confirmation (for confirmation of registration) to a specific user in the user pool.
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
  var valid_601145 = header.getOrDefault("X-Amz-Date")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-Date", valid_601145
  var valid_601146 = header.getOrDefault("X-Amz-Security-Token")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Security-Token", valid_601146
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601147 = header.getOrDefault("X-Amz-Target")
  valid_601147 = validateParameter(valid_601147, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ResendConfirmationCode"))
  if valid_601147 != nil:
    section.add "X-Amz-Target", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Content-Sha256", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-Algorithm")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Algorithm", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Signature")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Signature", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-SignedHeaders", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Credential")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Credential", valid_601152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601154: Call_ResendConfirmationCode_601142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resends the confirmation (for confirmation of registration) to a specific user in the user pool.
  ## 
  let valid = call_601154.validator(path, query, header, formData, body)
  let scheme = call_601154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601154.url(scheme.get, call_601154.host, call_601154.base,
                         call_601154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601154, url, valid)

proc call*(call_601155: Call_ResendConfirmationCode_601142; body: JsonNode): Recallable =
  ## resendConfirmationCode
  ## Resends the confirmation (for confirmation of registration) to a specific user in the user pool.
  ##   body: JObject (required)
  var body_601156 = newJObject()
  if body != nil:
    body_601156 = body
  result = call_601155.call(nil, nil, nil, nil, body_601156)

var resendConfirmationCode* = Call_ResendConfirmationCode_601142(
    name: "resendConfirmationCode", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ResendConfirmationCode",
    validator: validate_ResendConfirmationCode_601143, base: "/",
    url: url_ResendConfirmationCode_601144, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RespondToAuthChallenge_601157 = ref object of OpenApiRestCall_599368
proc url_RespondToAuthChallenge_601159(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RespondToAuthChallenge_601158(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Responds to the authentication challenge.
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
  var valid_601160 = header.getOrDefault("X-Amz-Date")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "X-Amz-Date", valid_601160
  var valid_601161 = header.getOrDefault("X-Amz-Security-Token")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-Security-Token", valid_601161
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601162 = header.getOrDefault("X-Amz-Target")
  valid_601162 = validateParameter(valid_601162, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.RespondToAuthChallenge"))
  if valid_601162 != nil:
    section.add "X-Amz-Target", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Content-Sha256", valid_601163
  var valid_601164 = header.getOrDefault("X-Amz-Algorithm")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Algorithm", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-Signature")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Signature", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-SignedHeaders", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Credential")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Credential", valid_601167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601169: Call_RespondToAuthChallenge_601157; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Responds to the authentication challenge.
  ## 
  let valid = call_601169.validator(path, query, header, formData, body)
  let scheme = call_601169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601169.url(scheme.get, call_601169.host, call_601169.base,
                         call_601169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601169, url, valid)

proc call*(call_601170: Call_RespondToAuthChallenge_601157; body: JsonNode): Recallable =
  ## respondToAuthChallenge
  ## Responds to the authentication challenge.
  ##   body: JObject (required)
  var body_601171 = newJObject()
  if body != nil:
    body_601171 = body
  result = call_601170.call(nil, nil, nil, nil, body_601171)

var respondToAuthChallenge* = Call_RespondToAuthChallenge_601157(
    name: "respondToAuthChallenge", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.RespondToAuthChallenge",
    validator: validate_RespondToAuthChallenge_601158, base: "/",
    url: url_RespondToAuthChallenge_601159, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetRiskConfiguration_601172 = ref object of OpenApiRestCall_599368
proc url_SetRiskConfiguration_601174(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SetRiskConfiguration_601173(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Configures actions on detected risks. To delete the risk configuration for <code>UserPoolId</code> or <code>ClientId</code>, pass null values for all four configuration types.</p> <p>To enable Amazon Cognito advanced security features, update the user pool to include the <code>UserPoolAddOns</code> key<code>AdvancedSecurityMode</code>.</p> <p>See .</p>
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
  var valid_601175 = header.getOrDefault("X-Amz-Date")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "X-Amz-Date", valid_601175
  var valid_601176 = header.getOrDefault("X-Amz-Security-Token")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "X-Amz-Security-Token", valid_601176
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601177 = header.getOrDefault("X-Amz-Target")
  valid_601177 = validateParameter(valid_601177, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetRiskConfiguration"))
  if valid_601177 != nil:
    section.add "X-Amz-Target", valid_601177
  var valid_601178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "X-Amz-Content-Sha256", valid_601178
  var valid_601179 = header.getOrDefault("X-Amz-Algorithm")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Algorithm", valid_601179
  var valid_601180 = header.getOrDefault("X-Amz-Signature")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Signature", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-SignedHeaders", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Credential")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Credential", valid_601182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601184: Call_SetRiskConfiguration_601172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configures actions on detected risks. To delete the risk configuration for <code>UserPoolId</code> or <code>ClientId</code>, pass null values for all four configuration types.</p> <p>To enable Amazon Cognito advanced security features, update the user pool to include the <code>UserPoolAddOns</code> key<code>AdvancedSecurityMode</code>.</p> <p>See .</p>
  ## 
  let valid = call_601184.validator(path, query, header, formData, body)
  let scheme = call_601184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601184.url(scheme.get, call_601184.host, call_601184.base,
                         call_601184.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601184, url, valid)

proc call*(call_601185: Call_SetRiskConfiguration_601172; body: JsonNode): Recallable =
  ## setRiskConfiguration
  ## <p>Configures actions on detected risks. To delete the risk configuration for <code>UserPoolId</code> or <code>ClientId</code>, pass null values for all four configuration types.</p> <p>To enable Amazon Cognito advanced security features, update the user pool to include the <code>UserPoolAddOns</code> key<code>AdvancedSecurityMode</code>.</p> <p>See .</p>
  ##   body: JObject (required)
  var body_601186 = newJObject()
  if body != nil:
    body_601186 = body
  result = call_601185.call(nil, nil, nil, nil, body_601186)

var setRiskConfiguration* = Call_SetRiskConfiguration_601172(
    name: "setRiskConfiguration", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetRiskConfiguration",
    validator: validate_SetRiskConfiguration_601173, base: "/",
    url: url_SetRiskConfiguration_601174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUICustomization_601187 = ref object of OpenApiRestCall_599368
proc url_SetUICustomization_601189(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SetUICustomization_601188(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Sets the UI customization information for a user pool's built-in app UI.</p> <p>You can specify app UI customization settings for a single client (with a specific <code>clientId</code>) or for all clients (by setting the <code>clientId</code> to <code>ALL</code>). If you specify <code>ALL</code>, the default configuration will be used for every client that has no UI customization set previously. If you specify UI customization settings for a particular client, it will no longer fall back to the <code>ALL</code> configuration. </p> <note> <p>To use this API, your user pool must have a domain associated with it. Otherwise, there is no place to host the app's pages, and the service will throw an error.</p> </note>
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
  var valid_601190 = header.getOrDefault("X-Amz-Date")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "X-Amz-Date", valid_601190
  var valid_601191 = header.getOrDefault("X-Amz-Security-Token")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "X-Amz-Security-Token", valid_601191
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601192 = header.getOrDefault("X-Amz-Target")
  valid_601192 = validateParameter(valid_601192, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUICustomization"))
  if valid_601192 != nil:
    section.add "X-Amz-Target", valid_601192
  var valid_601193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-Content-Sha256", valid_601193
  var valid_601194 = header.getOrDefault("X-Amz-Algorithm")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Algorithm", valid_601194
  var valid_601195 = header.getOrDefault("X-Amz-Signature")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Signature", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-SignedHeaders", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Credential")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Credential", valid_601197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601199: Call_SetUICustomization_601187; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the UI customization information for a user pool's built-in app UI.</p> <p>You can specify app UI customization settings for a single client (with a specific <code>clientId</code>) or for all clients (by setting the <code>clientId</code> to <code>ALL</code>). If you specify <code>ALL</code>, the default configuration will be used for every client that has no UI customization set previously. If you specify UI customization settings for a particular client, it will no longer fall back to the <code>ALL</code> configuration. </p> <note> <p>To use this API, your user pool must have a domain associated with it. Otherwise, there is no place to host the app's pages, and the service will throw an error.</p> </note>
  ## 
  let valid = call_601199.validator(path, query, header, formData, body)
  let scheme = call_601199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601199.url(scheme.get, call_601199.host, call_601199.base,
                         call_601199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601199, url, valid)

proc call*(call_601200: Call_SetUICustomization_601187; body: JsonNode): Recallable =
  ## setUICustomization
  ## <p>Sets the UI customization information for a user pool's built-in app UI.</p> <p>You can specify app UI customization settings for a single client (with a specific <code>clientId</code>) or for all clients (by setting the <code>clientId</code> to <code>ALL</code>). If you specify <code>ALL</code>, the default configuration will be used for every client that has no UI customization set previously. If you specify UI customization settings for a particular client, it will no longer fall back to the <code>ALL</code> configuration. </p> <note> <p>To use this API, your user pool must have a domain associated with it. Otherwise, there is no place to host the app's pages, and the service will throw an error.</p> </note>
  ##   body: JObject (required)
  var body_601201 = newJObject()
  if body != nil:
    body_601201 = body
  result = call_601200.call(nil, nil, nil, nil, body_601201)

var setUICustomization* = Call_SetUICustomization_601187(
    name: "setUICustomization", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUICustomization",
    validator: validate_SetUICustomization_601188, base: "/",
    url: url_SetUICustomization_601189, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUserMFAPreference_601202 = ref object of OpenApiRestCall_599368
proc url_SetUserMFAPreference_601204(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SetUserMFAPreference_601203(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Set the user's multi-factor authentication (MFA) method preference, including which MFA factors are enabled and if any are preferred. Only one factor can be set as preferred. The preferred MFA factor will be used to authenticate a user if multiple factors are enabled. If multiple options are enabled and no preference is set, a challenge to choose an MFA option will be returned during sign in.
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
  var valid_601205 = header.getOrDefault("X-Amz-Date")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "X-Amz-Date", valid_601205
  var valid_601206 = header.getOrDefault("X-Amz-Security-Token")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Security-Token", valid_601206
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601207 = header.getOrDefault("X-Amz-Target")
  valid_601207 = validateParameter(valid_601207, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUserMFAPreference"))
  if valid_601207 != nil:
    section.add "X-Amz-Target", valid_601207
  var valid_601208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-Content-Sha256", valid_601208
  var valid_601209 = header.getOrDefault("X-Amz-Algorithm")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Algorithm", valid_601209
  var valid_601210 = header.getOrDefault("X-Amz-Signature")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Signature", valid_601210
  var valid_601211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-SignedHeaders", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-Credential")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Credential", valid_601212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601214: Call_SetUserMFAPreference_601202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the user's multi-factor authentication (MFA) method preference, including which MFA factors are enabled and if any are preferred. Only one factor can be set as preferred. The preferred MFA factor will be used to authenticate a user if multiple factors are enabled. If multiple options are enabled and no preference is set, a challenge to choose an MFA option will be returned during sign in.
  ## 
  let valid = call_601214.validator(path, query, header, formData, body)
  let scheme = call_601214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601214.url(scheme.get, call_601214.host, call_601214.base,
                         call_601214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601214, url, valid)

proc call*(call_601215: Call_SetUserMFAPreference_601202; body: JsonNode): Recallable =
  ## setUserMFAPreference
  ## Set the user's multi-factor authentication (MFA) method preference, including which MFA factors are enabled and if any are preferred. Only one factor can be set as preferred. The preferred MFA factor will be used to authenticate a user if multiple factors are enabled. If multiple options are enabled and no preference is set, a challenge to choose an MFA option will be returned during sign in.
  ##   body: JObject (required)
  var body_601216 = newJObject()
  if body != nil:
    body_601216 = body
  result = call_601215.call(nil, nil, nil, nil, body_601216)

var setUserMFAPreference* = Call_SetUserMFAPreference_601202(
    name: "setUserMFAPreference", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUserMFAPreference",
    validator: validate_SetUserMFAPreference_601203, base: "/",
    url: url_SetUserMFAPreference_601204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUserPoolMfaConfig_601217 = ref object of OpenApiRestCall_599368
proc url_SetUserPoolMfaConfig_601219(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SetUserPoolMfaConfig_601218(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Set the user pool multi-factor authentication (MFA) configuration.
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
  var valid_601220 = header.getOrDefault("X-Amz-Date")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Date", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-Security-Token")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-Security-Token", valid_601221
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601222 = header.getOrDefault("X-Amz-Target")
  valid_601222 = validateParameter(valid_601222, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUserPoolMfaConfig"))
  if valid_601222 != nil:
    section.add "X-Amz-Target", valid_601222
  var valid_601223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "X-Amz-Content-Sha256", valid_601223
  var valid_601224 = header.getOrDefault("X-Amz-Algorithm")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "X-Amz-Algorithm", valid_601224
  var valid_601225 = header.getOrDefault("X-Amz-Signature")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "X-Amz-Signature", valid_601225
  var valid_601226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "X-Amz-SignedHeaders", valid_601226
  var valid_601227 = header.getOrDefault("X-Amz-Credential")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Credential", valid_601227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601229: Call_SetUserPoolMfaConfig_601217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the user pool multi-factor authentication (MFA) configuration.
  ## 
  let valid = call_601229.validator(path, query, header, formData, body)
  let scheme = call_601229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601229.url(scheme.get, call_601229.host, call_601229.base,
                         call_601229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601229, url, valid)

proc call*(call_601230: Call_SetUserPoolMfaConfig_601217; body: JsonNode): Recallable =
  ## setUserPoolMfaConfig
  ## Set the user pool multi-factor authentication (MFA) configuration.
  ##   body: JObject (required)
  var body_601231 = newJObject()
  if body != nil:
    body_601231 = body
  result = call_601230.call(nil, nil, nil, nil, body_601231)

var setUserPoolMfaConfig* = Call_SetUserPoolMfaConfig_601217(
    name: "setUserPoolMfaConfig", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUserPoolMfaConfig",
    validator: validate_SetUserPoolMfaConfig_601218, base: "/",
    url: url_SetUserPoolMfaConfig_601219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUserSettings_601232 = ref object of OpenApiRestCall_599368
proc url_SetUserSettings_601234(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SetUserSettings_601233(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ##  <i>This action is no longer supported.</i> You can use it to configure only SMS MFA. You can't use it to configure TOTP software token MFA. To configure either type of MFA, use the <a>SetUserMFAPreference</a> action instead.
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
  var valid_601235 = header.getOrDefault("X-Amz-Date")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-Date", valid_601235
  var valid_601236 = header.getOrDefault("X-Amz-Security-Token")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "X-Amz-Security-Token", valid_601236
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601237 = header.getOrDefault("X-Amz-Target")
  valid_601237 = validateParameter(valid_601237, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUserSettings"))
  if valid_601237 != nil:
    section.add "X-Amz-Target", valid_601237
  var valid_601238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "X-Amz-Content-Sha256", valid_601238
  var valid_601239 = header.getOrDefault("X-Amz-Algorithm")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "X-Amz-Algorithm", valid_601239
  var valid_601240 = header.getOrDefault("X-Amz-Signature")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "X-Amz-Signature", valid_601240
  var valid_601241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "X-Amz-SignedHeaders", valid_601241
  var valid_601242 = header.getOrDefault("X-Amz-Credential")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Credential", valid_601242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601244: Call_SetUserSettings_601232; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <i>This action is no longer supported.</i> You can use it to configure only SMS MFA. You can't use it to configure TOTP software token MFA. To configure either type of MFA, use the <a>SetUserMFAPreference</a> action instead.
  ## 
  let valid = call_601244.validator(path, query, header, formData, body)
  let scheme = call_601244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601244.url(scheme.get, call_601244.host, call_601244.base,
                         call_601244.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601244, url, valid)

proc call*(call_601245: Call_SetUserSettings_601232; body: JsonNode): Recallable =
  ## setUserSettings
  ##  <i>This action is no longer supported.</i> You can use it to configure only SMS MFA. You can't use it to configure TOTP software token MFA. To configure either type of MFA, use the <a>SetUserMFAPreference</a> action instead.
  ##   body: JObject (required)
  var body_601246 = newJObject()
  if body != nil:
    body_601246 = body
  result = call_601245.call(nil, nil, nil, nil, body_601246)

var setUserSettings* = Call_SetUserSettings_601232(name: "setUserSettings",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUserSettings",
    validator: validate_SetUserSettings_601233, base: "/", url: url_SetUserSettings_601234,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SignUp_601247 = ref object of OpenApiRestCall_599368
proc url_SignUp_601249(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SignUp_601248(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## Registers the user in the specified user pool and creates a user name, password, and user attributes.
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
  var valid_601250 = header.getOrDefault("X-Amz-Date")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-Date", valid_601250
  var valid_601251 = header.getOrDefault("X-Amz-Security-Token")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-Security-Token", valid_601251
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601252 = header.getOrDefault("X-Amz-Target")
  valid_601252 = validateParameter(valid_601252, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SignUp"))
  if valid_601252 != nil:
    section.add "X-Amz-Target", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-Content-Sha256", valid_601253
  var valid_601254 = header.getOrDefault("X-Amz-Algorithm")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-Algorithm", valid_601254
  var valid_601255 = header.getOrDefault("X-Amz-Signature")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "X-Amz-Signature", valid_601255
  var valid_601256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-SignedHeaders", valid_601256
  var valid_601257 = header.getOrDefault("X-Amz-Credential")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Credential", valid_601257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601259: Call_SignUp_601247; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers the user in the specified user pool and creates a user name, password, and user attributes.
  ## 
  let valid = call_601259.validator(path, query, header, formData, body)
  let scheme = call_601259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601259.url(scheme.get, call_601259.host, call_601259.base,
                         call_601259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601259, url, valid)

proc call*(call_601260: Call_SignUp_601247; body: JsonNode): Recallable =
  ## signUp
  ## Registers the user in the specified user pool and creates a user name, password, and user attributes.
  ##   body: JObject (required)
  var body_601261 = newJObject()
  if body != nil:
    body_601261 = body
  result = call_601260.call(nil, nil, nil, nil, body_601261)

var signUp* = Call_SignUp_601247(name: "signUp", meth: HttpMethod.HttpPost,
                              host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SignUp",
                              validator: validate_SignUp_601248, base: "/",
                              url: url_SignUp_601249,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartUserImportJob_601262 = ref object of OpenApiRestCall_599368
proc url_StartUserImportJob_601264(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartUserImportJob_601263(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Starts the user import.
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
  var valid_601265 = header.getOrDefault("X-Amz-Date")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Date", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-Security-Token")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-Security-Token", valid_601266
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601267 = header.getOrDefault("X-Amz-Target")
  valid_601267 = validateParameter(valid_601267, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.StartUserImportJob"))
  if valid_601267 != nil:
    section.add "X-Amz-Target", valid_601267
  var valid_601268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-Content-Sha256", valid_601268
  var valid_601269 = header.getOrDefault("X-Amz-Algorithm")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-Algorithm", valid_601269
  var valid_601270 = header.getOrDefault("X-Amz-Signature")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "X-Amz-Signature", valid_601270
  var valid_601271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "X-Amz-SignedHeaders", valid_601271
  var valid_601272 = header.getOrDefault("X-Amz-Credential")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-Credential", valid_601272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601274: Call_StartUserImportJob_601262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the user import.
  ## 
  let valid = call_601274.validator(path, query, header, formData, body)
  let scheme = call_601274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601274.url(scheme.get, call_601274.host, call_601274.base,
                         call_601274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601274, url, valid)

proc call*(call_601275: Call_StartUserImportJob_601262; body: JsonNode): Recallable =
  ## startUserImportJob
  ## Starts the user import.
  ##   body: JObject (required)
  var body_601276 = newJObject()
  if body != nil:
    body_601276 = body
  result = call_601275.call(nil, nil, nil, nil, body_601276)

var startUserImportJob* = Call_StartUserImportJob_601262(
    name: "startUserImportJob", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.StartUserImportJob",
    validator: validate_StartUserImportJob_601263, base: "/",
    url: url_StartUserImportJob_601264, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopUserImportJob_601277 = ref object of OpenApiRestCall_599368
proc url_StopUserImportJob_601279(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopUserImportJob_601278(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Stops the user import job.
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
  var valid_601280 = header.getOrDefault("X-Amz-Date")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "X-Amz-Date", valid_601280
  var valid_601281 = header.getOrDefault("X-Amz-Security-Token")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-Security-Token", valid_601281
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601282 = header.getOrDefault("X-Amz-Target")
  valid_601282 = validateParameter(valid_601282, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.StopUserImportJob"))
  if valid_601282 != nil:
    section.add "X-Amz-Target", valid_601282
  var valid_601283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "X-Amz-Content-Sha256", valid_601283
  var valid_601284 = header.getOrDefault("X-Amz-Algorithm")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "X-Amz-Algorithm", valid_601284
  var valid_601285 = header.getOrDefault("X-Amz-Signature")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "X-Amz-Signature", valid_601285
  var valid_601286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "X-Amz-SignedHeaders", valid_601286
  var valid_601287 = header.getOrDefault("X-Amz-Credential")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-Credential", valid_601287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601289: Call_StopUserImportJob_601277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the user import job.
  ## 
  let valid = call_601289.validator(path, query, header, formData, body)
  let scheme = call_601289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601289.url(scheme.get, call_601289.host, call_601289.base,
                         call_601289.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601289, url, valid)

proc call*(call_601290: Call_StopUserImportJob_601277; body: JsonNode): Recallable =
  ## stopUserImportJob
  ## Stops the user import job.
  ##   body: JObject (required)
  var body_601291 = newJObject()
  if body != nil:
    body_601291 = body
  result = call_601290.call(nil, nil, nil, nil, body_601291)

var stopUserImportJob* = Call_StopUserImportJob_601277(name: "stopUserImportJob",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.StopUserImportJob",
    validator: validate_StopUserImportJob_601278, base: "/",
    url: url_StopUserImportJob_601279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_601292 = ref object of OpenApiRestCall_599368
proc url_TagResource_601294(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_601293(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Assigns a set of tags to an Amazon Cognito user pool. A tag is a label that you can use to categorize and manage user pools in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>Each tag consists of a key and value, both of which you define. A key is a general category for more specific values. For example, if you have two versions of a user pool, one for testing and another for production, you might assign an <code>Environment</code> tag key to both user pools. The value of this key might be <code>Test</code> for one user pool and <code>Production</code> for the other.</p> <p>Tags are useful for cost tracking and access control. You can activate your tags so that they appear on the Billing and Cost Management console, where you can track the costs associated with your user pools. In an IAM policy, you can constrain permissions for user pools based on specific tags or tag values.</p> <p>You can use this action up to 5 times per second, per account. A user pool can have as many as 50 tags.</p>
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
  var valid_601295 = header.getOrDefault("X-Amz-Date")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "X-Amz-Date", valid_601295
  var valid_601296 = header.getOrDefault("X-Amz-Security-Token")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-Security-Token", valid_601296
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601297 = header.getOrDefault("X-Amz-Target")
  valid_601297 = validateParameter(valid_601297, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.TagResource"))
  if valid_601297 != nil:
    section.add "X-Amz-Target", valid_601297
  var valid_601298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "X-Amz-Content-Sha256", valid_601298
  var valid_601299 = header.getOrDefault("X-Amz-Algorithm")
  valid_601299 = validateParameter(valid_601299, JString, required = false,
                                 default = nil)
  if valid_601299 != nil:
    section.add "X-Amz-Algorithm", valid_601299
  var valid_601300 = header.getOrDefault("X-Amz-Signature")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "X-Amz-Signature", valid_601300
  var valid_601301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "X-Amz-SignedHeaders", valid_601301
  var valid_601302 = header.getOrDefault("X-Amz-Credential")
  valid_601302 = validateParameter(valid_601302, JString, required = false,
                                 default = nil)
  if valid_601302 != nil:
    section.add "X-Amz-Credential", valid_601302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601304: Call_TagResource_601292; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns a set of tags to an Amazon Cognito user pool. A tag is a label that you can use to categorize and manage user pools in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>Each tag consists of a key and value, both of which you define. A key is a general category for more specific values. For example, if you have two versions of a user pool, one for testing and another for production, you might assign an <code>Environment</code> tag key to both user pools. The value of this key might be <code>Test</code> for one user pool and <code>Production</code> for the other.</p> <p>Tags are useful for cost tracking and access control. You can activate your tags so that they appear on the Billing and Cost Management console, where you can track the costs associated with your user pools. In an IAM policy, you can constrain permissions for user pools based on specific tags or tag values.</p> <p>You can use this action up to 5 times per second, per account. A user pool can have as many as 50 tags.</p>
  ## 
  let valid = call_601304.validator(path, query, header, formData, body)
  let scheme = call_601304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601304.url(scheme.get, call_601304.host, call_601304.base,
                         call_601304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601304, url, valid)

proc call*(call_601305: Call_TagResource_601292; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Assigns a set of tags to an Amazon Cognito user pool. A tag is a label that you can use to categorize and manage user pools in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>Each tag consists of a key and value, both of which you define. A key is a general category for more specific values. For example, if you have two versions of a user pool, one for testing and another for production, you might assign an <code>Environment</code> tag key to both user pools. The value of this key might be <code>Test</code> for one user pool and <code>Production</code> for the other.</p> <p>Tags are useful for cost tracking and access control. You can activate your tags so that they appear on the Billing and Cost Management console, where you can track the costs associated with your user pools. In an IAM policy, you can constrain permissions for user pools based on specific tags or tag values.</p> <p>You can use this action up to 5 times per second, per account. A user pool can have as many as 50 tags.</p>
  ##   body: JObject (required)
  var body_601306 = newJObject()
  if body != nil:
    body_601306 = body
  result = call_601305.call(nil, nil, nil, nil, body_601306)

var tagResource* = Call_TagResource_601292(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.TagResource",
                                        validator: validate_TagResource_601293,
                                        base: "/", url: url_TagResource_601294,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601307 = ref object of OpenApiRestCall_599368
proc url_UntagResource_601309(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_601308(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the specified tags from an Amazon Cognito user pool. You can use this action up to 5 times per second, per account
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
  var valid_601310 = header.getOrDefault("X-Amz-Date")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "X-Amz-Date", valid_601310
  var valid_601311 = header.getOrDefault("X-Amz-Security-Token")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "X-Amz-Security-Token", valid_601311
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601312 = header.getOrDefault("X-Amz-Target")
  valid_601312 = validateParameter(valid_601312, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UntagResource"))
  if valid_601312 != nil:
    section.add "X-Amz-Target", valid_601312
  var valid_601313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601313 = validateParameter(valid_601313, JString, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "X-Amz-Content-Sha256", valid_601313
  var valid_601314 = header.getOrDefault("X-Amz-Algorithm")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "X-Amz-Algorithm", valid_601314
  var valid_601315 = header.getOrDefault("X-Amz-Signature")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "X-Amz-Signature", valid_601315
  var valid_601316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "X-Amz-SignedHeaders", valid_601316
  var valid_601317 = header.getOrDefault("X-Amz-Credential")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "X-Amz-Credential", valid_601317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601319: Call_UntagResource_601307; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified tags from an Amazon Cognito user pool. You can use this action up to 5 times per second, per account
  ## 
  let valid = call_601319.validator(path, query, header, formData, body)
  let scheme = call_601319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601319.url(scheme.get, call_601319.host, call_601319.base,
                         call_601319.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601319, url, valid)

proc call*(call_601320: Call_UntagResource_601307; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tags from an Amazon Cognito user pool. You can use this action up to 5 times per second, per account
  ##   body: JObject (required)
  var body_601321 = newJObject()
  if body != nil:
    body_601321 = body
  result = call_601320.call(nil, nil, nil, nil, body_601321)

var untagResource* = Call_UntagResource_601307(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UntagResource",
    validator: validate_UntagResource_601308, base: "/", url: url_UntagResource_601309,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthEventFeedback_601322 = ref object of OpenApiRestCall_599368
proc url_UpdateAuthEventFeedback_601324(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAuthEventFeedback_601323(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Provides the feedback for an authentication event whether it was from a valid user or not. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
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
  var valid_601325 = header.getOrDefault("X-Amz-Date")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "X-Amz-Date", valid_601325
  var valid_601326 = header.getOrDefault("X-Amz-Security-Token")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "X-Amz-Security-Token", valid_601326
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601327 = header.getOrDefault("X-Amz-Target")
  valid_601327 = validateParameter(valid_601327, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateAuthEventFeedback"))
  if valid_601327 != nil:
    section.add "X-Amz-Target", valid_601327
  var valid_601328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601328 = validateParameter(valid_601328, JString, required = false,
                                 default = nil)
  if valid_601328 != nil:
    section.add "X-Amz-Content-Sha256", valid_601328
  var valid_601329 = header.getOrDefault("X-Amz-Algorithm")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "X-Amz-Algorithm", valid_601329
  var valid_601330 = header.getOrDefault("X-Amz-Signature")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "X-Amz-Signature", valid_601330
  var valid_601331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-SignedHeaders", valid_601331
  var valid_601332 = header.getOrDefault("X-Amz-Credential")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "X-Amz-Credential", valid_601332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601334: Call_UpdateAuthEventFeedback_601322; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the feedback for an authentication event whether it was from a valid user or not. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ## 
  let valid = call_601334.validator(path, query, header, formData, body)
  let scheme = call_601334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601334.url(scheme.get, call_601334.host, call_601334.base,
                         call_601334.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601334, url, valid)

proc call*(call_601335: Call_UpdateAuthEventFeedback_601322; body: JsonNode): Recallable =
  ## updateAuthEventFeedback
  ## Provides the feedback for an authentication event whether it was from a valid user or not. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ##   body: JObject (required)
  var body_601336 = newJObject()
  if body != nil:
    body_601336 = body
  result = call_601335.call(nil, nil, nil, nil, body_601336)

var updateAuthEventFeedback* = Call_UpdateAuthEventFeedback_601322(
    name: "updateAuthEventFeedback", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateAuthEventFeedback",
    validator: validate_UpdateAuthEventFeedback_601323, base: "/",
    url: url_UpdateAuthEventFeedback_601324, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceStatus_601337 = ref object of OpenApiRestCall_599368
proc url_UpdateDeviceStatus_601339(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDeviceStatus_601338(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Updates the device status.
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
  var valid_601340 = header.getOrDefault("X-Amz-Date")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "X-Amz-Date", valid_601340
  var valid_601341 = header.getOrDefault("X-Amz-Security-Token")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "X-Amz-Security-Token", valid_601341
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601342 = header.getOrDefault("X-Amz-Target")
  valid_601342 = validateParameter(valid_601342, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateDeviceStatus"))
  if valid_601342 != nil:
    section.add "X-Amz-Target", valid_601342
  var valid_601343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-Content-Sha256", valid_601343
  var valid_601344 = header.getOrDefault("X-Amz-Algorithm")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-Algorithm", valid_601344
  var valid_601345 = header.getOrDefault("X-Amz-Signature")
  valid_601345 = validateParameter(valid_601345, JString, required = false,
                                 default = nil)
  if valid_601345 != nil:
    section.add "X-Amz-Signature", valid_601345
  var valid_601346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-SignedHeaders", valid_601346
  var valid_601347 = header.getOrDefault("X-Amz-Credential")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-Credential", valid_601347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601349: Call_UpdateDeviceStatus_601337; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the device status.
  ## 
  let valid = call_601349.validator(path, query, header, formData, body)
  let scheme = call_601349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601349.url(scheme.get, call_601349.host, call_601349.base,
                         call_601349.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601349, url, valid)

proc call*(call_601350: Call_UpdateDeviceStatus_601337; body: JsonNode): Recallable =
  ## updateDeviceStatus
  ## Updates the device status.
  ##   body: JObject (required)
  var body_601351 = newJObject()
  if body != nil:
    body_601351 = body
  result = call_601350.call(nil, nil, nil, nil, body_601351)

var updateDeviceStatus* = Call_UpdateDeviceStatus_601337(
    name: "updateDeviceStatus", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateDeviceStatus",
    validator: validate_UpdateDeviceStatus_601338, base: "/",
    url: url_UpdateDeviceStatus_601339, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_601352 = ref object of OpenApiRestCall_599368
proc url_UpdateGroup_601354(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateGroup_601353(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the specified group with the specified attributes.</p> <p>Calling this action requires developer credentials.</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
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
  var valid_601355 = header.getOrDefault("X-Amz-Date")
  valid_601355 = validateParameter(valid_601355, JString, required = false,
                                 default = nil)
  if valid_601355 != nil:
    section.add "X-Amz-Date", valid_601355
  var valid_601356 = header.getOrDefault("X-Amz-Security-Token")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "X-Amz-Security-Token", valid_601356
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601357 = header.getOrDefault("X-Amz-Target")
  valid_601357 = validateParameter(valid_601357, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateGroup"))
  if valid_601357 != nil:
    section.add "X-Amz-Target", valid_601357
  var valid_601358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-Content-Sha256", valid_601358
  var valid_601359 = header.getOrDefault("X-Amz-Algorithm")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "X-Amz-Algorithm", valid_601359
  var valid_601360 = header.getOrDefault("X-Amz-Signature")
  valid_601360 = validateParameter(valid_601360, JString, required = false,
                                 default = nil)
  if valid_601360 != nil:
    section.add "X-Amz-Signature", valid_601360
  var valid_601361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "X-Amz-SignedHeaders", valid_601361
  var valid_601362 = header.getOrDefault("X-Amz-Credential")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-Credential", valid_601362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601364: Call_UpdateGroup_601352; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified group with the specified attributes.</p> <p>Calling this action requires developer credentials.</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ## 
  let valid = call_601364.validator(path, query, header, formData, body)
  let scheme = call_601364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601364.url(scheme.get, call_601364.host, call_601364.base,
                         call_601364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601364, url, valid)

proc call*(call_601365: Call_UpdateGroup_601352; body: JsonNode): Recallable =
  ## updateGroup
  ## <p>Updates the specified group with the specified attributes.</p> <p>Calling this action requires developer credentials.</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ##   body: JObject (required)
  var body_601366 = newJObject()
  if body != nil:
    body_601366 = body
  result = call_601365.call(nil, nil, nil, nil, body_601366)

var updateGroup* = Call_UpdateGroup_601352(name: "updateGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateGroup",
                                        validator: validate_UpdateGroup_601353,
                                        base: "/", url: url_UpdateGroup_601354,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIdentityProvider_601367 = ref object of OpenApiRestCall_599368
proc url_UpdateIdentityProvider_601369(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateIdentityProvider_601368(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates identity provider information for a user pool.
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
  var valid_601370 = header.getOrDefault("X-Amz-Date")
  valid_601370 = validateParameter(valid_601370, JString, required = false,
                                 default = nil)
  if valid_601370 != nil:
    section.add "X-Amz-Date", valid_601370
  var valid_601371 = header.getOrDefault("X-Amz-Security-Token")
  valid_601371 = validateParameter(valid_601371, JString, required = false,
                                 default = nil)
  if valid_601371 != nil:
    section.add "X-Amz-Security-Token", valid_601371
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601372 = header.getOrDefault("X-Amz-Target")
  valid_601372 = validateParameter(valid_601372, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateIdentityProvider"))
  if valid_601372 != nil:
    section.add "X-Amz-Target", valid_601372
  var valid_601373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601373 = validateParameter(valid_601373, JString, required = false,
                                 default = nil)
  if valid_601373 != nil:
    section.add "X-Amz-Content-Sha256", valid_601373
  var valid_601374 = header.getOrDefault("X-Amz-Algorithm")
  valid_601374 = validateParameter(valid_601374, JString, required = false,
                                 default = nil)
  if valid_601374 != nil:
    section.add "X-Amz-Algorithm", valid_601374
  var valid_601375 = header.getOrDefault("X-Amz-Signature")
  valid_601375 = validateParameter(valid_601375, JString, required = false,
                                 default = nil)
  if valid_601375 != nil:
    section.add "X-Amz-Signature", valid_601375
  var valid_601376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "X-Amz-SignedHeaders", valid_601376
  var valid_601377 = header.getOrDefault("X-Amz-Credential")
  valid_601377 = validateParameter(valid_601377, JString, required = false,
                                 default = nil)
  if valid_601377 != nil:
    section.add "X-Amz-Credential", valid_601377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601379: Call_UpdateIdentityProvider_601367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates identity provider information for a user pool.
  ## 
  let valid = call_601379.validator(path, query, header, formData, body)
  let scheme = call_601379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601379.url(scheme.get, call_601379.host, call_601379.base,
                         call_601379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601379, url, valid)

proc call*(call_601380: Call_UpdateIdentityProvider_601367; body: JsonNode): Recallable =
  ## updateIdentityProvider
  ## Updates identity provider information for a user pool.
  ##   body: JObject (required)
  var body_601381 = newJObject()
  if body != nil:
    body_601381 = body
  result = call_601380.call(nil, nil, nil, nil, body_601381)

var updateIdentityProvider* = Call_UpdateIdentityProvider_601367(
    name: "updateIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateIdentityProvider",
    validator: validate_UpdateIdentityProvider_601368, base: "/",
    url: url_UpdateIdentityProvider_601369, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceServer_601382 = ref object of OpenApiRestCall_599368
proc url_UpdateResourceServer_601384(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateResourceServer_601383(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the name and scopes of resource server. All other fields are read-only.</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
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
  var valid_601385 = header.getOrDefault("X-Amz-Date")
  valid_601385 = validateParameter(valid_601385, JString, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "X-Amz-Date", valid_601385
  var valid_601386 = header.getOrDefault("X-Amz-Security-Token")
  valid_601386 = validateParameter(valid_601386, JString, required = false,
                                 default = nil)
  if valid_601386 != nil:
    section.add "X-Amz-Security-Token", valid_601386
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601387 = header.getOrDefault("X-Amz-Target")
  valid_601387 = validateParameter(valid_601387, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateResourceServer"))
  if valid_601387 != nil:
    section.add "X-Amz-Target", valid_601387
  var valid_601388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601388 = validateParameter(valid_601388, JString, required = false,
                                 default = nil)
  if valid_601388 != nil:
    section.add "X-Amz-Content-Sha256", valid_601388
  var valid_601389 = header.getOrDefault("X-Amz-Algorithm")
  valid_601389 = validateParameter(valid_601389, JString, required = false,
                                 default = nil)
  if valid_601389 != nil:
    section.add "X-Amz-Algorithm", valid_601389
  var valid_601390 = header.getOrDefault("X-Amz-Signature")
  valid_601390 = validateParameter(valid_601390, JString, required = false,
                                 default = nil)
  if valid_601390 != nil:
    section.add "X-Amz-Signature", valid_601390
  var valid_601391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601391 = validateParameter(valid_601391, JString, required = false,
                                 default = nil)
  if valid_601391 != nil:
    section.add "X-Amz-SignedHeaders", valid_601391
  var valid_601392 = header.getOrDefault("X-Amz-Credential")
  valid_601392 = validateParameter(valid_601392, JString, required = false,
                                 default = nil)
  if valid_601392 != nil:
    section.add "X-Amz-Credential", valid_601392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601394: Call_UpdateResourceServer_601382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the name and scopes of resource server. All other fields are read-only.</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ## 
  let valid = call_601394.validator(path, query, header, formData, body)
  let scheme = call_601394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601394.url(scheme.get, call_601394.host, call_601394.base,
                         call_601394.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601394, url, valid)

proc call*(call_601395: Call_UpdateResourceServer_601382; body: JsonNode): Recallable =
  ## updateResourceServer
  ## <p>Updates the name and scopes of resource server. All other fields are read-only.</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ##   body: JObject (required)
  var body_601396 = newJObject()
  if body != nil:
    body_601396 = body
  result = call_601395.call(nil, nil, nil, nil, body_601396)

var updateResourceServer* = Call_UpdateResourceServer_601382(
    name: "updateResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateResourceServer",
    validator: validate_UpdateResourceServer_601383, base: "/",
    url: url_UpdateResourceServer_601384, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserAttributes_601397 = ref object of OpenApiRestCall_599368
proc url_UpdateUserAttributes_601399(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUserAttributes_601398(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Allows a user to update a specific attribute (one at a time).
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
  var valid_601400 = header.getOrDefault("X-Amz-Date")
  valid_601400 = validateParameter(valid_601400, JString, required = false,
                                 default = nil)
  if valid_601400 != nil:
    section.add "X-Amz-Date", valid_601400
  var valid_601401 = header.getOrDefault("X-Amz-Security-Token")
  valid_601401 = validateParameter(valid_601401, JString, required = false,
                                 default = nil)
  if valid_601401 != nil:
    section.add "X-Amz-Security-Token", valid_601401
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601402 = header.getOrDefault("X-Amz-Target")
  valid_601402 = validateParameter(valid_601402, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserAttributes"))
  if valid_601402 != nil:
    section.add "X-Amz-Target", valid_601402
  var valid_601403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601403 = validateParameter(valid_601403, JString, required = false,
                                 default = nil)
  if valid_601403 != nil:
    section.add "X-Amz-Content-Sha256", valid_601403
  var valid_601404 = header.getOrDefault("X-Amz-Algorithm")
  valid_601404 = validateParameter(valid_601404, JString, required = false,
                                 default = nil)
  if valid_601404 != nil:
    section.add "X-Amz-Algorithm", valid_601404
  var valid_601405 = header.getOrDefault("X-Amz-Signature")
  valid_601405 = validateParameter(valid_601405, JString, required = false,
                                 default = nil)
  if valid_601405 != nil:
    section.add "X-Amz-Signature", valid_601405
  var valid_601406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601406 = validateParameter(valid_601406, JString, required = false,
                                 default = nil)
  if valid_601406 != nil:
    section.add "X-Amz-SignedHeaders", valid_601406
  var valid_601407 = header.getOrDefault("X-Amz-Credential")
  valid_601407 = validateParameter(valid_601407, JString, required = false,
                                 default = nil)
  if valid_601407 != nil:
    section.add "X-Amz-Credential", valid_601407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601409: Call_UpdateUserAttributes_601397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a user to update a specific attribute (one at a time).
  ## 
  let valid = call_601409.validator(path, query, header, formData, body)
  let scheme = call_601409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601409.url(scheme.get, call_601409.host, call_601409.base,
                         call_601409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601409, url, valid)

proc call*(call_601410: Call_UpdateUserAttributes_601397; body: JsonNode): Recallable =
  ## updateUserAttributes
  ## Allows a user to update a specific attribute (one at a time).
  ##   body: JObject (required)
  var body_601411 = newJObject()
  if body != nil:
    body_601411 = body
  result = call_601410.call(nil, nil, nil, nil, body_601411)

var updateUserAttributes* = Call_UpdateUserAttributes_601397(
    name: "updateUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserAttributes",
    validator: validate_UpdateUserAttributes_601398, base: "/",
    url: url_UpdateUserAttributes_601399, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPool_601412 = ref object of OpenApiRestCall_599368
proc url_UpdateUserPool_601414(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUserPool_601413(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Updates the specified user pool with the specified attributes. You can get a list of the current user pool settings with .</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
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
  var valid_601415 = header.getOrDefault("X-Amz-Date")
  valid_601415 = validateParameter(valid_601415, JString, required = false,
                                 default = nil)
  if valid_601415 != nil:
    section.add "X-Amz-Date", valid_601415
  var valid_601416 = header.getOrDefault("X-Amz-Security-Token")
  valid_601416 = validateParameter(valid_601416, JString, required = false,
                                 default = nil)
  if valid_601416 != nil:
    section.add "X-Amz-Security-Token", valid_601416
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601417 = header.getOrDefault("X-Amz-Target")
  valid_601417 = validateParameter(valid_601417, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserPool"))
  if valid_601417 != nil:
    section.add "X-Amz-Target", valid_601417
  var valid_601418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601418 = validateParameter(valid_601418, JString, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "X-Amz-Content-Sha256", valid_601418
  var valid_601419 = header.getOrDefault("X-Amz-Algorithm")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "X-Amz-Algorithm", valid_601419
  var valid_601420 = header.getOrDefault("X-Amz-Signature")
  valid_601420 = validateParameter(valid_601420, JString, required = false,
                                 default = nil)
  if valid_601420 != nil:
    section.add "X-Amz-Signature", valid_601420
  var valid_601421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601421 = validateParameter(valid_601421, JString, required = false,
                                 default = nil)
  if valid_601421 != nil:
    section.add "X-Amz-SignedHeaders", valid_601421
  var valid_601422 = header.getOrDefault("X-Amz-Credential")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "X-Amz-Credential", valid_601422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601424: Call_UpdateUserPool_601412; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified user pool with the specified attributes. You can get a list of the current user pool settings with .</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ## 
  let valid = call_601424.validator(path, query, header, formData, body)
  let scheme = call_601424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601424.url(scheme.get, call_601424.host, call_601424.base,
                         call_601424.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601424, url, valid)

proc call*(call_601425: Call_UpdateUserPool_601412; body: JsonNode): Recallable =
  ## updateUserPool
  ## <p>Updates the specified user pool with the specified attributes. You can get a list of the current user pool settings with .</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ##   body: JObject (required)
  var body_601426 = newJObject()
  if body != nil:
    body_601426 = body
  result = call_601425.call(nil, nil, nil, nil, body_601426)

var updateUserPool* = Call_UpdateUserPool_601412(name: "updateUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserPool",
    validator: validate_UpdateUserPool_601413, base: "/", url: url_UpdateUserPool_601414,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPoolClient_601427 = ref object of OpenApiRestCall_599368
proc url_UpdateUserPoolClient_601429(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUserPoolClient_601428(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the specified user pool app client with the specified attributes. You can get a list of the current user pool app client settings with .</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
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
  var valid_601430 = header.getOrDefault("X-Amz-Date")
  valid_601430 = validateParameter(valid_601430, JString, required = false,
                                 default = nil)
  if valid_601430 != nil:
    section.add "X-Amz-Date", valid_601430
  var valid_601431 = header.getOrDefault("X-Amz-Security-Token")
  valid_601431 = validateParameter(valid_601431, JString, required = false,
                                 default = nil)
  if valid_601431 != nil:
    section.add "X-Amz-Security-Token", valid_601431
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601432 = header.getOrDefault("X-Amz-Target")
  valid_601432 = validateParameter(valid_601432, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserPoolClient"))
  if valid_601432 != nil:
    section.add "X-Amz-Target", valid_601432
  var valid_601433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601433 = validateParameter(valid_601433, JString, required = false,
                                 default = nil)
  if valid_601433 != nil:
    section.add "X-Amz-Content-Sha256", valid_601433
  var valid_601434 = header.getOrDefault("X-Amz-Algorithm")
  valid_601434 = validateParameter(valid_601434, JString, required = false,
                                 default = nil)
  if valid_601434 != nil:
    section.add "X-Amz-Algorithm", valid_601434
  var valid_601435 = header.getOrDefault("X-Amz-Signature")
  valid_601435 = validateParameter(valid_601435, JString, required = false,
                                 default = nil)
  if valid_601435 != nil:
    section.add "X-Amz-Signature", valid_601435
  var valid_601436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601436 = validateParameter(valid_601436, JString, required = false,
                                 default = nil)
  if valid_601436 != nil:
    section.add "X-Amz-SignedHeaders", valid_601436
  var valid_601437 = header.getOrDefault("X-Amz-Credential")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-Credential", valid_601437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601439: Call_UpdateUserPoolClient_601427; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified user pool app client with the specified attributes. You can get a list of the current user pool app client settings with .</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ## 
  let valid = call_601439.validator(path, query, header, formData, body)
  let scheme = call_601439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601439.url(scheme.get, call_601439.host, call_601439.base,
                         call_601439.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601439, url, valid)

proc call*(call_601440: Call_UpdateUserPoolClient_601427; body: JsonNode): Recallable =
  ## updateUserPoolClient
  ## <p>Updates the specified user pool app client with the specified attributes. You can get a list of the current user pool app client settings with .</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ##   body: JObject (required)
  var body_601441 = newJObject()
  if body != nil:
    body_601441 = body
  result = call_601440.call(nil, nil, nil, nil, body_601441)

var updateUserPoolClient* = Call_UpdateUserPoolClient_601427(
    name: "updateUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserPoolClient",
    validator: validate_UpdateUserPoolClient_601428, base: "/",
    url: url_UpdateUserPoolClient_601429, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPoolDomain_601442 = ref object of OpenApiRestCall_599368
proc url_UpdateUserPoolDomain_601444(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUserPoolDomain_601443(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the Secure Sockets Layer (SSL) certificate for the custom domain for your user pool.</p> <p>You can use this operation to provide the Amazon Resource Name (ARN) of a new certificate to Amazon Cognito. You cannot use it to change the domain for a user pool.</p> <p>A custom domain is used to host the Amazon Cognito hosted UI, which provides sign-up and sign-in pages for your application. When you set up a custom domain, you provide a certificate that you manage with AWS Certificate Manager (ACM). When necessary, you can use this operation to change the certificate that you applied to your custom domain.</p> <p>Usually, this is unnecessary following routine certificate renewal with ACM. When you renew your existing certificate in ACM, the ARN for your certificate remains the same, and your custom domain uses the new certificate automatically.</p> <p>However, if you replace your existing certificate with a new one, ACM gives the new certificate a new ARN. To apply the new certificate to your custom domain, you must provide this ARN to Amazon Cognito.</p> <p>When you add your new certificate in ACM, you must choose US East (N. Virginia) as the AWS Region.</p> <p>After you submit your request, Amazon Cognito requires up to 1 hour to distribute your new certificate to your custom domain.</p> <p>For more information about adding a custom domain to your user pool, see <a href="https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-add-custom-domain.html">Using Your Own Domain for the Hosted UI</a>.</p>
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
  var valid_601445 = header.getOrDefault("X-Amz-Date")
  valid_601445 = validateParameter(valid_601445, JString, required = false,
                                 default = nil)
  if valid_601445 != nil:
    section.add "X-Amz-Date", valid_601445
  var valid_601446 = header.getOrDefault("X-Amz-Security-Token")
  valid_601446 = validateParameter(valid_601446, JString, required = false,
                                 default = nil)
  if valid_601446 != nil:
    section.add "X-Amz-Security-Token", valid_601446
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601447 = header.getOrDefault("X-Amz-Target")
  valid_601447 = validateParameter(valid_601447, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserPoolDomain"))
  if valid_601447 != nil:
    section.add "X-Amz-Target", valid_601447
  var valid_601448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601448 = validateParameter(valid_601448, JString, required = false,
                                 default = nil)
  if valid_601448 != nil:
    section.add "X-Amz-Content-Sha256", valid_601448
  var valid_601449 = header.getOrDefault("X-Amz-Algorithm")
  valid_601449 = validateParameter(valid_601449, JString, required = false,
                                 default = nil)
  if valid_601449 != nil:
    section.add "X-Amz-Algorithm", valid_601449
  var valid_601450 = header.getOrDefault("X-Amz-Signature")
  valid_601450 = validateParameter(valid_601450, JString, required = false,
                                 default = nil)
  if valid_601450 != nil:
    section.add "X-Amz-Signature", valid_601450
  var valid_601451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601451 = validateParameter(valid_601451, JString, required = false,
                                 default = nil)
  if valid_601451 != nil:
    section.add "X-Amz-SignedHeaders", valid_601451
  var valid_601452 = header.getOrDefault("X-Amz-Credential")
  valid_601452 = validateParameter(valid_601452, JString, required = false,
                                 default = nil)
  if valid_601452 != nil:
    section.add "X-Amz-Credential", valid_601452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601454: Call_UpdateUserPoolDomain_601442; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the Secure Sockets Layer (SSL) certificate for the custom domain for your user pool.</p> <p>You can use this operation to provide the Amazon Resource Name (ARN) of a new certificate to Amazon Cognito. You cannot use it to change the domain for a user pool.</p> <p>A custom domain is used to host the Amazon Cognito hosted UI, which provides sign-up and sign-in pages for your application. When you set up a custom domain, you provide a certificate that you manage with AWS Certificate Manager (ACM). When necessary, you can use this operation to change the certificate that you applied to your custom domain.</p> <p>Usually, this is unnecessary following routine certificate renewal with ACM. When you renew your existing certificate in ACM, the ARN for your certificate remains the same, and your custom domain uses the new certificate automatically.</p> <p>However, if you replace your existing certificate with a new one, ACM gives the new certificate a new ARN. To apply the new certificate to your custom domain, you must provide this ARN to Amazon Cognito.</p> <p>When you add your new certificate in ACM, you must choose US East (N. Virginia) as the AWS Region.</p> <p>After you submit your request, Amazon Cognito requires up to 1 hour to distribute your new certificate to your custom domain.</p> <p>For more information about adding a custom domain to your user pool, see <a href="https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-add-custom-domain.html">Using Your Own Domain for the Hosted UI</a>.</p>
  ## 
  let valid = call_601454.validator(path, query, header, formData, body)
  let scheme = call_601454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601454.url(scheme.get, call_601454.host, call_601454.base,
                         call_601454.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601454, url, valid)

proc call*(call_601455: Call_UpdateUserPoolDomain_601442; body: JsonNode): Recallable =
  ## updateUserPoolDomain
  ## <p>Updates the Secure Sockets Layer (SSL) certificate for the custom domain for your user pool.</p> <p>You can use this operation to provide the Amazon Resource Name (ARN) of a new certificate to Amazon Cognito. You cannot use it to change the domain for a user pool.</p> <p>A custom domain is used to host the Amazon Cognito hosted UI, which provides sign-up and sign-in pages for your application. When you set up a custom domain, you provide a certificate that you manage with AWS Certificate Manager (ACM). When necessary, you can use this operation to change the certificate that you applied to your custom domain.</p> <p>Usually, this is unnecessary following routine certificate renewal with ACM. When you renew your existing certificate in ACM, the ARN for your certificate remains the same, and your custom domain uses the new certificate automatically.</p> <p>However, if you replace your existing certificate with a new one, ACM gives the new certificate a new ARN. To apply the new certificate to your custom domain, you must provide this ARN to Amazon Cognito.</p> <p>When you add your new certificate in ACM, you must choose US East (N. Virginia) as the AWS Region.</p> <p>After you submit your request, Amazon Cognito requires up to 1 hour to distribute your new certificate to your custom domain.</p> <p>For more information about adding a custom domain to your user pool, see <a href="https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-add-custom-domain.html">Using Your Own Domain for the Hosted UI</a>.</p>
  ##   body: JObject (required)
  var body_601456 = newJObject()
  if body != nil:
    body_601456 = body
  result = call_601455.call(nil, nil, nil, nil, body_601456)

var updateUserPoolDomain* = Call_UpdateUserPoolDomain_601442(
    name: "updateUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserPoolDomain",
    validator: validate_UpdateUserPoolDomain_601443, base: "/",
    url: url_UpdateUserPoolDomain_601444, schemes: {Scheme.Https, Scheme.Http})
type
  Call_VerifySoftwareToken_601457 = ref object of OpenApiRestCall_599368
proc url_VerifySoftwareToken_601459(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_VerifySoftwareToken_601458(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Use this API to register a user's entered TOTP code and mark the user's software token MFA status as "verified" if successful. The request takes an access token or a session string, but not both.
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
  var valid_601460 = header.getOrDefault("X-Amz-Date")
  valid_601460 = validateParameter(valid_601460, JString, required = false,
                                 default = nil)
  if valid_601460 != nil:
    section.add "X-Amz-Date", valid_601460
  var valid_601461 = header.getOrDefault("X-Amz-Security-Token")
  valid_601461 = validateParameter(valid_601461, JString, required = false,
                                 default = nil)
  if valid_601461 != nil:
    section.add "X-Amz-Security-Token", valid_601461
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601462 = header.getOrDefault("X-Amz-Target")
  valid_601462 = validateParameter(valid_601462, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.VerifySoftwareToken"))
  if valid_601462 != nil:
    section.add "X-Amz-Target", valid_601462
  var valid_601463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601463 = validateParameter(valid_601463, JString, required = false,
                                 default = nil)
  if valid_601463 != nil:
    section.add "X-Amz-Content-Sha256", valid_601463
  var valid_601464 = header.getOrDefault("X-Amz-Algorithm")
  valid_601464 = validateParameter(valid_601464, JString, required = false,
                                 default = nil)
  if valid_601464 != nil:
    section.add "X-Amz-Algorithm", valid_601464
  var valid_601465 = header.getOrDefault("X-Amz-Signature")
  valid_601465 = validateParameter(valid_601465, JString, required = false,
                                 default = nil)
  if valid_601465 != nil:
    section.add "X-Amz-Signature", valid_601465
  var valid_601466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601466 = validateParameter(valid_601466, JString, required = false,
                                 default = nil)
  if valid_601466 != nil:
    section.add "X-Amz-SignedHeaders", valid_601466
  var valid_601467 = header.getOrDefault("X-Amz-Credential")
  valid_601467 = validateParameter(valid_601467, JString, required = false,
                                 default = nil)
  if valid_601467 != nil:
    section.add "X-Amz-Credential", valid_601467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601469: Call_VerifySoftwareToken_601457; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Use this API to register a user's entered TOTP code and mark the user's software token MFA status as "verified" if successful. The request takes an access token or a session string, but not both.
  ## 
  let valid = call_601469.validator(path, query, header, formData, body)
  let scheme = call_601469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601469.url(scheme.get, call_601469.host, call_601469.base,
                         call_601469.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601469, url, valid)

proc call*(call_601470: Call_VerifySoftwareToken_601457; body: JsonNode): Recallable =
  ## verifySoftwareToken
  ## Use this API to register a user's entered TOTP code and mark the user's software token MFA status as "verified" if successful. The request takes an access token or a session string, but not both.
  ##   body: JObject (required)
  var body_601471 = newJObject()
  if body != nil:
    body_601471 = body
  result = call_601470.call(nil, nil, nil, nil, body_601471)

var verifySoftwareToken* = Call_VerifySoftwareToken_601457(
    name: "verifySoftwareToken", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.VerifySoftwareToken",
    validator: validate_VerifySoftwareToken_601458, base: "/",
    url: url_VerifySoftwareToken_601459, schemes: {Scheme.Https, Scheme.Http})
type
  Call_VerifyUserAttribute_601472 = ref object of OpenApiRestCall_599368
proc url_VerifyUserAttribute_601474(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_VerifyUserAttribute_601473(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Verifies the specified user attributes in the user pool.
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
  var valid_601475 = header.getOrDefault("X-Amz-Date")
  valid_601475 = validateParameter(valid_601475, JString, required = false,
                                 default = nil)
  if valid_601475 != nil:
    section.add "X-Amz-Date", valid_601475
  var valid_601476 = header.getOrDefault("X-Amz-Security-Token")
  valid_601476 = validateParameter(valid_601476, JString, required = false,
                                 default = nil)
  if valid_601476 != nil:
    section.add "X-Amz-Security-Token", valid_601476
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601477 = header.getOrDefault("X-Amz-Target")
  valid_601477 = validateParameter(valid_601477, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.VerifyUserAttribute"))
  if valid_601477 != nil:
    section.add "X-Amz-Target", valid_601477
  var valid_601478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601478 = validateParameter(valid_601478, JString, required = false,
                                 default = nil)
  if valid_601478 != nil:
    section.add "X-Amz-Content-Sha256", valid_601478
  var valid_601479 = header.getOrDefault("X-Amz-Algorithm")
  valid_601479 = validateParameter(valid_601479, JString, required = false,
                                 default = nil)
  if valid_601479 != nil:
    section.add "X-Amz-Algorithm", valid_601479
  var valid_601480 = header.getOrDefault("X-Amz-Signature")
  valid_601480 = validateParameter(valid_601480, JString, required = false,
                                 default = nil)
  if valid_601480 != nil:
    section.add "X-Amz-Signature", valid_601480
  var valid_601481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601481 = validateParameter(valid_601481, JString, required = false,
                                 default = nil)
  if valid_601481 != nil:
    section.add "X-Amz-SignedHeaders", valid_601481
  var valid_601482 = header.getOrDefault("X-Amz-Credential")
  valid_601482 = validateParameter(valid_601482, JString, required = false,
                                 default = nil)
  if valid_601482 != nil:
    section.add "X-Amz-Credential", valid_601482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601484: Call_VerifyUserAttribute_601472; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Verifies the specified user attributes in the user pool.
  ## 
  let valid = call_601484.validator(path, query, header, formData, body)
  let scheme = call_601484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601484.url(scheme.get, call_601484.host, call_601484.base,
                         call_601484.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601484, url, valid)

proc call*(call_601485: Call_VerifyUserAttribute_601472; body: JsonNode): Recallable =
  ## verifyUserAttribute
  ## Verifies the specified user attributes in the user pool.
  ##   body: JObject (required)
  var body_601486 = newJObject()
  if body != nil:
    body_601486 = body
  result = call_601485.call(nil, nil, nil, nil, body_601486)

var verifyUserAttribute* = Call_VerifyUserAttribute_601472(
    name: "verifyUserAttribute", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.VerifyUserAttribute",
    validator: validate_VerifyUserAttribute_601473, base: "/",
    url: url_VerifyUserAttribute_601474, schemes: {Scheme.Https, Scheme.Http})
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
