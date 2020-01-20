
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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
  Call_AddCustomAttributes_605927 = ref object of OpenApiRestCall_605589
proc url_AddCustomAttributes_605929(protocol: Scheme; host: string; base: string;
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

proc validate_AddCustomAttributes_605928(path: JsonNode; query: JsonNode;
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
  var valid_606054 = header.getOrDefault("X-Amz-Target")
  valid_606054 = validateParameter(valid_606054, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AddCustomAttributes"))
  if valid_606054 != nil:
    section.add "X-Amz-Target", valid_606054
  var valid_606055 = header.getOrDefault("X-Amz-Signature")
  valid_606055 = validateParameter(valid_606055, JString, required = false,
                                 default = nil)
  if valid_606055 != nil:
    section.add "X-Amz-Signature", valid_606055
  var valid_606056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "X-Amz-Content-Sha256", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Date")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Date", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Credential")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Credential", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Security-Token")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Security-Token", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Algorithm")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Algorithm", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-SignedHeaders", valid_606061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606085: Call_AddCustomAttributes_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds additional user attributes to the user pool schema.
  ## 
  let valid = call_606085.validator(path, query, header, formData, body)
  let scheme = call_606085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606085.url(scheme.get, call_606085.host, call_606085.base,
                         call_606085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606085, url, valid)

proc call*(call_606156: Call_AddCustomAttributes_605927; body: JsonNode): Recallable =
  ## addCustomAttributes
  ## Adds additional user attributes to the user pool schema.
  ##   body: JObject (required)
  var body_606157 = newJObject()
  if body != nil:
    body_606157 = body
  result = call_606156.call(nil, nil, nil, nil, body_606157)

var addCustomAttributes* = Call_AddCustomAttributes_605927(
    name: "addCustomAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AddCustomAttributes",
    validator: validate_AddCustomAttributes_605928, base: "/",
    url: url_AddCustomAttributes_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminAddUserToGroup_606196 = ref object of OpenApiRestCall_605589
proc url_AdminAddUserToGroup_606198(protocol: Scheme; host: string; base: string;
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

proc validate_AdminAddUserToGroup_606197(path: JsonNode; query: JsonNode;
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
  var valid_606199 = header.getOrDefault("X-Amz-Target")
  valid_606199 = validateParameter(valid_606199, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminAddUserToGroup"))
  if valid_606199 != nil:
    section.add "X-Amz-Target", valid_606199
  var valid_606200 = header.getOrDefault("X-Amz-Signature")
  valid_606200 = validateParameter(valid_606200, JString, required = false,
                                 default = nil)
  if valid_606200 != nil:
    section.add "X-Amz-Signature", valid_606200
  var valid_606201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Content-Sha256", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Date")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Date", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Credential")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Credential", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Security-Token")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Security-Token", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Algorithm")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Algorithm", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-SignedHeaders", valid_606206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606208: Call_AdminAddUserToGroup_606196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified user to the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_606208.validator(path, query, header, formData, body)
  let scheme = call_606208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606208.url(scheme.get, call_606208.host, call_606208.base,
                         call_606208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606208, url, valid)

proc call*(call_606209: Call_AdminAddUserToGroup_606196; body: JsonNode): Recallable =
  ## adminAddUserToGroup
  ## <p>Adds the specified user to the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_606210 = newJObject()
  if body != nil:
    body_606210 = body
  result = call_606209.call(nil, nil, nil, nil, body_606210)

var adminAddUserToGroup* = Call_AdminAddUserToGroup_606196(
    name: "adminAddUserToGroup", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminAddUserToGroup",
    validator: validate_AdminAddUserToGroup_606197, base: "/",
    url: url_AdminAddUserToGroup_606198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminConfirmSignUp_606211 = ref object of OpenApiRestCall_605589
proc url_AdminConfirmSignUp_606213(protocol: Scheme; host: string; base: string;
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

proc validate_AdminConfirmSignUp_606212(path: JsonNode; query: JsonNode;
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
  var valid_606214 = header.getOrDefault("X-Amz-Target")
  valid_606214 = validateParameter(valid_606214, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminConfirmSignUp"))
  if valid_606214 != nil:
    section.add "X-Amz-Target", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-Signature")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Signature", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Content-Sha256", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Date")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Date", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Credential")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Credential", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Security-Token")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Security-Token", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Algorithm")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Algorithm", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-SignedHeaders", valid_606221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606223: Call_AdminConfirmSignUp_606211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Confirms user registration as an admin without using a confirmation code. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_606223.validator(path, query, header, formData, body)
  let scheme = call_606223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606223.url(scheme.get, call_606223.host, call_606223.base,
                         call_606223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606223, url, valid)

proc call*(call_606224: Call_AdminConfirmSignUp_606211; body: JsonNode): Recallable =
  ## adminConfirmSignUp
  ## <p>Confirms user registration as an admin without using a confirmation code. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_606225 = newJObject()
  if body != nil:
    body_606225 = body
  result = call_606224.call(nil, nil, nil, nil, body_606225)

var adminConfirmSignUp* = Call_AdminConfirmSignUp_606211(
    name: "adminConfirmSignUp", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminConfirmSignUp",
    validator: validate_AdminConfirmSignUp_606212, base: "/",
    url: url_AdminConfirmSignUp_606213, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminCreateUser_606226 = ref object of OpenApiRestCall_605589
proc url_AdminCreateUser_606228(protocol: Scheme; host: string; base: string;
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

proc validate_AdminCreateUser_606227(path: JsonNode; query: JsonNode;
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
  var valid_606229 = header.getOrDefault("X-Amz-Target")
  valid_606229 = validateParameter(valid_606229, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminCreateUser"))
  if valid_606229 != nil:
    section.add "X-Amz-Target", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-Signature")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Signature", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Content-Sha256", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Date")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Date", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Credential")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Credential", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Security-Token")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Security-Token", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Algorithm")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Algorithm", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-SignedHeaders", valid_606236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606238: Call_AdminCreateUser_606226; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new user in the specified user pool.</p> <p>If <code>MessageAction</code> is not set, the default is to send a welcome message via email or phone (SMS).</p> <note> <p>This message is based on a template that you configured in your call to or . This template includes your custom sign-up instructions and placeholders for user name and temporary password.</p> </note> <p>Alternatively, you can call AdminCreateUser with “SUPPRESS” for the <code>MessageAction</code> parameter, and Amazon Cognito will not send any email. </p> <p>In either case, the user will be in the <code>FORCE_CHANGE_PASSWORD</code> state until they sign in and change their password.</p> <p>AdminCreateUser requires developer credentials.</p>
  ## 
  let valid = call_606238.validator(path, query, header, formData, body)
  let scheme = call_606238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606238.url(scheme.get, call_606238.host, call_606238.base,
                         call_606238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606238, url, valid)

proc call*(call_606239: Call_AdminCreateUser_606226; body: JsonNode): Recallable =
  ## adminCreateUser
  ## <p>Creates a new user in the specified user pool.</p> <p>If <code>MessageAction</code> is not set, the default is to send a welcome message via email or phone (SMS).</p> <note> <p>This message is based on a template that you configured in your call to or . This template includes your custom sign-up instructions and placeholders for user name and temporary password.</p> </note> <p>Alternatively, you can call AdminCreateUser with “SUPPRESS” for the <code>MessageAction</code> parameter, and Amazon Cognito will not send any email. </p> <p>In either case, the user will be in the <code>FORCE_CHANGE_PASSWORD</code> state until they sign in and change their password.</p> <p>AdminCreateUser requires developer credentials.</p>
  ##   body: JObject (required)
  var body_606240 = newJObject()
  if body != nil:
    body_606240 = body
  result = call_606239.call(nil, nil, nil, nil, body_606240)

var adminCreateUser* = Call_AdminCreateUser_606226(name: "adminCreateUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminCreateUser",
    validator: validate_AdminCreateUser_606227, base: "/", url: url_AdminCreateUser_606228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDeleteUser_606241 = ref object of OpenApiRestCall_605589
proc url_AdminDeleteUser_606243(protocol: Scheme; host: string; base: string;
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

proc validate_AdminDeleteUser_606242(path: JsonNode; query: JsonNode;
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
  var valid_606244 = header.getOrDefault("X-Amz-Target")
  valid_606244 = validateParameter(valid_606244, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDeleteUser"))
  if valid_606244 != nil:
    section.add "X-Amz-Target", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Signature")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Signature", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Content-Sha256", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Date")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Date", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Credential")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Credential", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Security-Token")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Security-Token", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Algorithm")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Algorithm", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-SignedHeaders", valid_606251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606253: Call_AdminDeleteUser_606241; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a user as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_606253.validator(path, query, header, formData, body)
  let scheme = call_606253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606253.url(scheme.get, call_606253.host, call_606253.base,
                         call_606253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606253, url, valid)

proc call*(call_606254: Call_AdminDeleteUser_606241; body: JsonNode): Recallable =
  ## adminDeleteUser
  ## <p>Deletes a user as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_606255 = newJObject()
  if body != nil:
    body_606255 = body
  result = call_606254.call(nil, nil, nil, nil, body_606255)

var adminDeleteUser* = Call_AdminDeleteUser_606241(name: "adminDeleteUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDeleteUser",
    validator: validate_AdminDeleteUser_606242, base: "/", url: url_AdminDeleteUser_606243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDeleteUserAttributes_606256 = ref object of OpenApiRestCall_605589
proc url_AdminDeleteUserAttributes_606258(protocol: Scheme; host: string;
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

proc validate_AdminDeleteUserAttributes_606257(path: JsonNode; query: JsonNode;
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
  var valid_606259 = header.getOrDefault("X-Amz-Target")
  valid_606259 = validateParameter(valid_606259, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDeleteUserAttributes"))
  if valid_606259 != nil:
    section.add "X-Amz-Target", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Signature")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Signature", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Content-Sha256", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Date")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Date", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Credential")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Credential", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Security-Token")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Security-Token", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Algorithm")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Algorithm", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-SignedHeaders", valid_606266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606268: Call_AdminDeleteUserAttributes_606256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the user attributes in a user pool as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_606268.validator(path, query, header, formData, body)
  let scheme = call_606268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606268.url(scheme.get, call_606268.host, call_606268.base,
                         call_606268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606268, url, valid)

proc call*(call_606269: Call_AdminDeleteUserAttributes_606256; body: JsonNode): Recallable =
  ## adminDeleteUserAttributes
  ## <p>Deletes the user attributes in a user pool as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_606270 = newJObject()
  if body != nil:
    body_606270 = body
  result = call_606269.call(nil, nil, nil, nil, body_606270)

var adminDeleteUserAttributes* = Call_AdminDeleteUserAttributes_606256(
    name: "adminDeleteUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDeleteUserAttributes",
    validator: validate_AdminDeleteUserAttributes_606257, base: "/",
    url: url_AdminDeleteUserAttributes_606258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDisableProviderForUser_606271 = ref object of OpenApiRestCall_605589
proc url_AdminDisableProviderForUser_606273(protocol: Scheme; host: string;
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

proc validate_AdminDisableProviderForUser_606272(path: JsonNode; query: JsonNode;
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
  var valid_606274 = header.getOrDefault("X-Amz-Target")
  valid_606274 = validateParameter(valid_606274, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDisableProviderForUser"))
  if valid_606274 != nil:
    section.add "X-Amz-Target", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Signature")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Signature", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Content-Sha256", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Date")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Date", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Credential")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Credential", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Security-Token")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Security-Token", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Algorithm")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Algorithm", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-SignedHeaders", valid_606281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606283: Call_AdminDisableProviderForUser_606271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables the user from signing in with the specified external (SAML or social) identity provider. If the user to disable is a Cognito User Pools native username + password user, they are not permitted to use their password to sign-in. If the user to disable is a linked external IdP user, any link between that user and an existing user is removed. The next time the external user (no longer attached to the previously linked <code>DestinationUser</code>) signs in, they must create a new user account. See .</p> <p>This action is enabled only for admin access and requires developer credentials.</p> <p>The <code>ProviderName</code> must match the value specified when creating an IdP for the pool. </p> <p>To disable a native username + password user, the <code>ProviderName</code> value must be <code>Cognito</code> and the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code>, with the <code>ProviderAttributeValue</code> being the name that is used in the user pool for the user.</p> <p>The <code>ProviderAttributeName</code> must always be <code>Cognito_Subject</code> for social identity providers. The <code>ProviderAttributeValue</code> must always be the exact subject that was used when the user was originally linked as a source user.</p> <p>For de-linking a SAML identity, there are two scenarios. If the linked identity has not yet been used to sign-in, the <code>ProviderAttributeName</code> and <code>ProviderAttributeValue</code> must be the same values that were used for the <code>SourceUser</code> when the identities were originally linked in the call. (If the linking was done with <code>ProviderAttributeName</code> set to <code>Cognito_Subject</code>, the same applies here). However, if the user has already signed in, the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code> and <code>ProviderAttributeValue</code> must be the subject of the SAML assertion.</p>
  ## 
  let valid = call_606283.validator(path, query, header, formData, body)
  let scheme = call_606283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606283.url(scheme.get, call_606283.host, call_606283.base,
                         call_606283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606283, url, valid)

proc call*(call_606284: Call_AdminDisableProviderForUser_606271; body: JsonNode): Recallable =
  ## adminDisableProviderForUser
  ## <p>Disables the user from signing in with the specified external (SAML or social) identity provider. If the user to disable is a Cognito User Pools native username + password user, they are not permitted to use their password to sign-in. If the user to disable is a linked external IdP user, any link between that user and an existing user is removed. The next time the external user (no longer attached to the previously linked <code>DestinationUser</code>) signs in, they must create a new user account. See .</p> <p>This action is enabled only for admin access and requires developer credentials.</p> <p>The <code>ProviderName</code> must match the value specified when creating an IdP for the pool. </p> <p>To disable a native username + password user, the <code>ProviderName</code> value must be <code>Cognito</code> and the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code>, with the <code>ProviderAttributeValue</code> being the name that is used in the user pool for the user.</p> <p>The <code>ProviderAttributeName</code> must always be <code>Cognito_Subject</code> for social identity providers. The <code>ProviderAttributeValue</code> must always be the exact subject that was used when the user was originally linked as a source user.</p> <p>For de-linking a SAML identity, there are two scenarios. If the linked identity has not yet been used to sign-in, the <code>ProviderAttributeName</code> and <code>ProviderAttributeValue</code> must be the same values that were used for the <code>SourceUser</code> when the identities were originally linked in the call. (If the linking was done with <code>ProviderAttributeName</code> set to <code>Cognito_Subject</code>, the same applies here). However, if the user has already signed in, the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code> and <code>ProviderAttributeValue</code> must be the subject of the SAML assertion.</p>
  ##   body: JObject (required)
  var body_606285 = newJObject()
  if body != nil:
    body_606285 = body
  result = call_606284.call(nil, nil, nil, nil, body_606285)

var adminDisableProviderForUser* = Call_AdminDisableProviderForUser_606271(
    name: "adminDisableProviderForUser", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDisableProviderForUser",
    validator: validate_AdminDisableProviderForUser_606272, base: "/",
    url: url_AdminDisableProviderForUser_606273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDisableUser_606286 = ref object of OpenApiRestCall_605589
proc url_AdminDisableUser_606288(protocol: Scheme; host: string; base: string;
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

proc validate_AdminDisableUser_606287(path: JsonNode; query: JsonNode;
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
  var valid_606289 = header.getOrDefault("X-Amz-Target")
  valid_606289 = validateParameter(valid_606289, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDisableUser"))
  if valid_606289 != nil:
    section.add "X-Amz-Target", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Signature")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Signature", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Content-Sha256", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-Date")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Date", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Credential")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Credential", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Security-Token")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Security-Token", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Algorithm")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Algorithm", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-SignedHeaders", valid_606296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606298: Call_AdminDisableUser_606286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables the specified user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_606298.validator(path, query, header, formData, body)
  let scheme = call_606298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606298.url(scheme.get, call_606298.host, call_606298.base,
                         call_606298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606298, url, valid)

proc call*(call_606299: Call_AdminDisableUser_606286; body: JsonNode): Recallable =
  ## adminDisableUser
  ## <p>Disables the specified user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_606300 = newJObject()
  if body != nil:
    body_606300 = body
  result = call_606299.call(nil, nil, nil, nil, body_606300)

var adminDisableUser* = Call_AdminDisableUser_606286(name: "adminDisableUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDisableUser",
    validator: validate_AdminDisableUser_606287, base: "/",
    url: url_AdminDisableUser_606288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminEnableUser_606301 = ref object of OpenApiRestCall_605589
proc url_AdminEnableUser_606303(protocol: Scheme; host: string; base: string;
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

proc validate_AdminEnableUser_606302(path: JsonNode; query: JsonNode;
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
  var valid_606304 = header.getOrDefault("X-Amz-Target")
  valid_606304 = validateParameter(valid_606304, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminEnableUser"))
  if valid_606304 != nil:
    section.add "X-Amz-Target", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Signature")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Signature", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Content-Sha256", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Date")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Date", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Credential")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Credential", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Security-Token")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Security-Token", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Algorithm")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Algorithm", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-SignedHeaders", valid_606311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606313: Call_AdminEnableUser_606301; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the specified user as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_606313.validator(path, query, header, formData, body)
  let scheme = call_606313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606313.url(scheme.get, call_606313.host, call_606313.base,
                         call_606313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606313, url, valid)

proc call*(call_606314: Call_AdminEnableUser_606301; body: JsonNode): Recallable =
  ## adminEnableUser
  ## <p>Enables the specified user as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_606315 = newJObject()
  if body != nil:
    body_606315 = body
  result = call_606314.call(nil, nil, nil, nil, body_606315)

var adminEnableUser* = Call_AdminEnableUser_606301(name: "adminEnableUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminEnableUser",
    validator: validate_AdminEnableUser_606302, base: "/", url: url_AdminEnableUser_606303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminForgetDevice_606316 = ref object of OpenApiRestCall_605589
proc url_AdminForgetDevice_606318(protocol: Scheme; host: string; base: string;
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

proc validate_AdminForgetDevice_606317(path: JsonNode; query: JsonNode;
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
  var valid_606319 = header.getOrDefault("X-Amz-Target")
  valid_606319 = validateParameter(valid_606319, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminForgetDevice"))
  if valid_606319 != nil:
    section.add "X-Amz-Target", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Signature")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Signature", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Content-Sha256", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Date")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Date", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Credential")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Credential", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Security-Token")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Security-Token", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-Algorithm")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Algorithm", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-SignedHeaders", valid_606326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606328: Call_AdminForgetDevice_606316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Forgets the device, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_606328.validator(path, query, header, formData, body)
  let scheme = call_606328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606328.url(scheme.get, call_606328.host, call_606328.base,
                         call_606328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606328, url, valid)

proc call*(call_606329: Call_AdminForgetDevice_606316; body: JsonNode): Recallable =
  ## adminForgetDevice
  ## <p>Forgets the device, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_606330 = newJObject()
  if body != nil:
    body_606330 = body
  result = call_606329.call(nil, nil, nil, nil, body_606330)

var adminForgetDevice* = Call_AdminForgetDevice_606316(name: "adminForgetDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminForgetDevice",
    validator: validate_AdminForgetDevice_606317, base: "/",
    url: url_AdminForgetDevice_606318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminGetDevice_606331 = ref object of OpenApiRestCall_605589
proc url_AdminGetDevice_606333(protocol: Scheme; host: string; base: string;
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

proc validate_AdminGetDevice_606332(path: JsonNode; query: JsonNode;
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
  var valid_606334 = header.getOrDefault("X-Amz-Target")
  valid_606334 = validateParameter(valid_606334, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminGetDevice"))
  if valid_606334 != nil:
    section.add "X-Amz-Target", valid_606334
  var valid_606335 = header.getOrDefault("X-Amz-Signature")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Signature", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Content-Sha256", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Date")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Date", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Credential")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Credential", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Security-Token")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Security-Token", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Algorithm")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Algorithm", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-SignedHeaders", valid_606341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606343: Call_AdminGetDevice_606331; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the device, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_606343.validator(path, query, header, formData, body)
  let scheme = call_606343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606343.url(scheme.get, call_606343.host, call_606343.base,
                         call_606343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606343, url, valid)

proc call*(call_606344: Call_AdminGetDevice_606331; body: JsonNode): Recallable =
  ## adminGetDevice
  ## <p>Gets the device, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_606345 = newJObject()
  if body != nil:
    body_606345 = body
  result = call_606344.call(nil, nil, nil, nil, body_606345)

var adminGetDevice* = Call_AdminGetDevice_606331(name: "adminGetDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminGetDevice",
    validator: validate_AdminGetDevice_606332, base: "/", url: url_AdminGetDevice_606333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminGetUser_606346 = ref object of OpenApiRestCall_605589
proc url_AdminGetUser_606348(protocol: Scheme; host: string; base: string;
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

proc validate_AdminGetUser_606347(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606349 = header.getOrDefault("X-Amz-Target")
  valid_606349 = validateParameter(valid_606349, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminGetUser"))
  if valid_606349 != nil:
    section.add "X-Amz-Target", valid_606349
  var valid_606350 = header.getOrDefault("X-Amz-Signature")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Signature", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Content-Sha256", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-Date")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Date", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-Credential")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Credential", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Security-Token")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Security-Token", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Algorithm")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Algorithm", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-SignedHeaders", valid_606356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606358: Call_AdminGetUser_606346; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the specified user by user name in a user pool as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_606358.validator(path, query, header, formData, body)
  let scheme = call_606358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606358.url(scheme.get, call_606358.host, call_606358.base,
                         call_606358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606358, url, valid)

proc call*(call_606359: Call_AdminGetUser_606346; body: JsonNode): Recallable =
  ## adminGetUser
  ## <p>Gets the specified user by user name in a user pool as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_606360 = newJObject()
  if body != nil:
    body_606360 = body
  result = call_606359.call(nil, nil, nil, nil, body_606360)

var adminGetUser* = Call_AdminGetUser_606346(name: "adminGetUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminGetUser",
    validator: validate_AdminGetUser_606347, base: "/", url: url_AdminGetUser_606348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminInitiateAuth_606361 = ref object of OpenApiRestCall_605589
proc url_AdminInitiateAuth_606363(protocol: Scheme; host: string; base: string;
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

proc validate_AdminInitiateAuth_606362(path: JsonNode; query: JsonNode;
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
  var valid_606364 = header.getOrDefault("X-Amz-Target")
  valid_606364 = validateParameter(valid_606364, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminInitiateAuth"))
  if valid_606364 != nil:
    section.add "X-Amz-Target", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-Signature")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Signature", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Content-Sha256", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Date")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Date", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Credential")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Credential", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Security-Token")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Security-Token", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Algorithm")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Algorithm", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-SignedHeaders", valid_606371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606373: Call_AdminInitiateAuth_606361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates the authentication flow, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_606373.validator(path, query, header, formData, body)
  let scheme = call_606373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606373.url(scheme.get, call_606373.host, call_606373.base,
                         call_606373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606373, url, valid)

proc call*(call_606374: Call_AdminInitiateAuth_606361; body: JsonNode): Recallable =
  ## adminInitiateAuth
  ## <p>Initiates the authentication flow, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_606375 = newJObject()
  if body != nil:
    body_606375 = body
  result = call_606374.call(nil, nil, nil, nil, body_606375)

var adminInitiateAuth* = Call_AdminInitiateAuth_606361(name: "adminInitiateAuth",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminInitiateAuth",
    validator: validate_AdminInitiateAuth_606362, base: "/",
    url: url_AdminInitiateAuth_606363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminLinkProviderForUser_606376 = ref object of OpenApiRestCall_605589
proc url_AdminLinkProviderForUser_606378(protocol: Scheme; host: string;
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

proc validate_AdminLinkProviderForUser_606377(path: JsonNode; query: JsonNode;
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
  var valid_606379 = header.getOrDefault("X-Amz-Target")
  valid_606379 = validateParameter(valid_606379, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminLinkProviderForUser"))
  if valid_606379 != nil:
    section.add "X-Amz-Target", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Signature")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Signature", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Content-Sha256", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Date")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Date", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-Credential")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Credential", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-Security-Token")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Security-Token", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-Algorithm")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Algorithm", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-SignedHeaders", valid_606386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606388: Call_AdminLinkProviderForUser_606376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Links an existing user account in a user pool (<code>DestinationUser</code>) to an identity from an external identity provider (<code>SourceUser</code>) based on a specified attribute name and value from the external identity provider. This allows you to create a link from the existing user account to an external federated user identity that has not yet been used to sign in, so that the federated user identity can be used to sign in as the existing user account. </p> <p> For example, if there is an existing user with a username and password, this API links that user to a federated user identity, so that when the federated user identity is used, the user signs in as the existing user account. </p> <important> <p>Because this API allows a user with an external federated identity to sign in as an existing user in the user pool, it is critical that it only be used with external identity providers and provider attributes that have been trusted by the application owner.</p> </important> <p>See also .</p> <p>This action is enabled only for admin access and requires developer credentials.</p>
  ## 
  let valid = call_606388.validator(path, query, header, formData, body)
  let scheme = call_606388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606388.url(scheme.get, call_606388.host, call_606388.base,
                         call_606388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606388, url, valid)

proc call*(call_606389: Call_AdminLinkProviderForUser_606376; body: JsonNode): Recallable =
  ## adminLinkProviderForUser
  ## <p>Links an existing user account in a user pool (<code>DestinationUser</code>) to an identity from an external identity provider (<code>SourceUser</code>) based on a specified attribute name and value from the external identity provider. This allows you to create a link from the existing user account to an external federated user identity that has not yet been used to sign in, so that the federated user identity can be used to sign in as the existing user account. </p> <p> For example, if there is an existing user with a username and password, this API links that user to a federated user identity, so that when the federated user identity is used, the user signs in as the existing user account. </p> <important> <p>Because this API allows a user with an external federated identity to sign in as an existing user in the user pool, it is critical that it only be used with external identity providers and provider attributes that have been trusted by the application owner.</p> </important> <p>See also .</p> <p>This action is enabled only for admin access and requires developer credentials.</p>
  ##   body: JObject (required)
  var body_606390 = newJObject()
  if body != nil:
    body_606390 = body
  result = call_606389.call(nil, nil, nil, nil, body_606390)

var adminLinkProviderForUser* = Call_AdminLinkProviderForUser_606376(
    name: "adminLinkProviderForUser", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminLinkProviderForUser",
    validator: validate_AdminLinkProviderForUser_606377, base: "/",
    url: url_AdminLinkProviderForUser_606378, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminListDevices_606391 = ref object of OpenApiRestCall_605589
proc url_AdminListDevices_606393(protocol: Scheme; host: string; base: string;
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

proc validate_AdminListDevices_606392(path: JsonNode; query: JsonNode;
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
  var valid_606394 = header.getOrDefault("X-Amz-Target")
  valid_606394 = validateParameter(valid_606394, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminListDevices"))
  if valid_606394 != nil:
    section.add "X-Amz-Target", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-Signature")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Signature", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Content-Sha256", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Date")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Date", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Credential")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Credential", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-Security-Token")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Security-Token", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Algorithm")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Algorithm", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-SignedHeaders", valid_606401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606403: Call_AdminListDevices_606391; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists devices, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_606403.validator(path, query, header, formData, body)
  let scheme = call_606403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606403.url(scheme.get, call_606403.host, call_606403.base,
                         call_606403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606403, url, valid)

proc call*(call_606404: Call_AdminListDevices_606391; body: JsonNode): Recallable =
  ## adminListDevices
  ## <p>Lists devices, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_606405 = newJObject()
  if body != nil:
    body_606405 = body
  result = call_606404.call(nil, nil, nil, nil, body_606405)

var adminListDevices* = Call_AdminListDevices_606391(name: "adminListDevices",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminListDevices",
    validator: validate_AdminListDevices_606392, base: "/",
    url: url_AdminListDevices_606393, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminListGroupsForUser_606406 = ref object of OpenApiRestCall_605589
proc url_AdminListGroupsForUser_606408(protocol: Scheme; host: string; base: string;
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

proc validate_AdminListGroupsForUser_606407(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the groups that the user belongs to.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   Limit: JString
  ##        : Pagination limit
  section = newJObject()
  var valid_606409 = query.getOrDefault("NextToken")
  valid_606409 = validateParameter(valid_606409, JString, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "NextToken", valid_606409
  var valid_606410 = query.getOrDefault("Limit")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "Limit", valid_606410
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
  var valid_606411 = header.getOrDefault("X-Amz-Target")
  valid_606411 = validateParameter(valid_606411, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminListGroupsForUser"))
  if valid_606411 != nil:
    section.add "X-Amz-Target", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-Signature")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Signature", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Content-Sha256", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Date")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Date", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-Credential")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Credential", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-Security-Token")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-Security-Token", valid_606416
  var valid_606417 = header.getOrDefault("X-Amz-Algorithm")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "X-Amz-Algorithm", valid_606417
  var valid_606418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "X-Amz-SignedHeaders", valid_606418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606420: Call_AdminListGroupsForUser_606406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the groups that the user belongs to.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_606420.validator(path, query, header, formData, body)
  let scheme = call_606420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606420.url(scheme.get, call_606420.host, call_606420.base,
                         call_606420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606420, url, valid)

proc call*(call_606421: Call_AdminListGroupsForUser_606406; body: JsonNode;
          NextToken: string = ""; Limit: string = ""): Recallable =
  ## adminListGroupsForUser
  ## <p>Lists the groups that the user belongs to.</p> <p>Calling this action requires developer credentials.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_606422 = newJObject()
  var body_606423 = newJObject()
  add(query_606422, "NextToken", newJString(NextToken))
  add(query_606422, "Limit", newJString(Limit))
  if body != nil:
    body_606423 = body
  result = call_606421.call(nil, query_606422, nil, nil, body_606423)

var adminListGroupsForUser* = Call_AdminListGroupsForUser_606406(
    name: "adminListGroupsForUser", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminListGroupsForUser",
    validator: validate_AdminListGroupsForUser_606407, base: "/",
    url: url_AdminListGroupsForUser_606408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminListUserAuthEvents_606425 = ref object of OpenApiRestCall_605589
proc url_AdminListUserAuthEvents_606427(protocol: Scheme; host: string; base: string;
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

proc validate_AdminListUserAuthEvents_606426(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists a history of user activity and any risks detected as part of Amazon Cognito advanced security.
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
  var valid_606428 = query.getOrDefault("MaxResults")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "MaxResults", valid_606428
  var valid_606429 = query.getOrDefault("NextToken")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "NextToken", valid_606429
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
  var valid_606430 = header.getOrDefault("X-Amz-Target")
  valid_606430 = validateParameter(valid_606430, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminListUserAuthEvents"))
  if valid_606430 != nil:
    section.add "X-Amz-Target", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-Signature")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-Signature", valid_606431
  var valid_606432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606432 = validateParameter(valid_606432, JString, required = false,
                                 default = nil)
  if valid_606432 != nil:
    section.add "X-Amz-Content-Sha256", valid_606432
  var valid_606433 = header.getOrDefault("X-Amz-Date")
  valid_606433 = validateParameter(valid_606433, JString, required = false,
                                 default = nil)
  if valid_606433 != nil:
    section.add "X-Amz-Date", valid_606433
  var valid_606434 = header.getOrDefault("X-Amz-Credential")
  valid_606434 = validateParameter(valid_606434, JString, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "X-Amz-Credential", valid_606434
  var valid_606435 = header.getOrDefault("X-Amz-Security-Token")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "X-Amz-Security-Token", valid_606435
  var valid_606436 = header.getOrDefault("X-Amz-Algorithm")
  valid_606436 = validateParameter(valid_606436, JString, required = false,
                                 default = nil)
  if valid_606436 != nil:
    section.add "X-Amz-Algorithm", valid_606436
  var valid_606437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606437 = validateParameter(valid_606437, JString, required = false,
                                 default = nil)
  if valid_606437 != nil:
    section.add "X-Amz-SignedHeaders", valid_606437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606439: Call_AdminListUserAuthEvents_606425; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists a history of user activity and any risks detected as part of Amazon Cognito advanced security.
  ## 
  let valid = call_606439.validator(path, query, header, formData, body)
  let scheme = call_606439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606439.url(scheme.get, call_606439.host, call_606439.base,
                         call_606439.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606439, url, valid)

proc call*(call_606440: Call_AdminListUserAuthEvents_606425; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## adminListUserAuthEvents
  ## Lists a history of user activity and any risks detected as part of Amazon Cognito advanced security.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606441 = newJObject()
  var body_606442 = newJObject()
  add(query_606441, "MaxResults", newJString(MaxResults))
  add(query_606441, "NextToken", newJString(NextToken))
  if body != nil:
    body_606442 = body
  result = call_606440.call(nil, query_606441, nil, nil, body_606442)

var adminListUserAuthEvents* = Call_AdminListUserAuthEvents_606425(
    name: "adminListUserAuthEvents", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminListUserAuthEvents",
    validator: validate_AdminListUserAuthEvents_606426, base: "/",
    url: url_AdminListUserAuthEvents_606427, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminRemoveUserFromGroup_606443 = ref object of OpenApiRestCall_605589
proc url_AdminRemoveUserFromGroup_606445(protocol: Scheme; host: string;
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

proc validate_AdminRemoveUserFromGroup_606444(path: JsonNode; query: JsonNode;
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
  var valid_606446 = header.getOrDefault("X-Amz-Target")
  valid_606446 = validateParameter(valid_606446, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminRemoveUserFromGroup"))
  if valid_606446 != nil:
    section.add "X-Amz-Target", valid_606446
  var valid_606447 = header.getOrDefault("X-Amz-Signature")
  valid_606447 = validateParameter(valid_606447, JString, required = false,
                                 default = nil)
  if valid_606447 != nil:
    section.add "X-Amz-Signature", valid_606447
  var valid_606448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606448 = validateParameter(valid_606448, JString, required = false,
                                 default = nil)
  if valid_606448 != nil:
    section.add "X-Amz-Content-Sha256", valid_606448
  var valid_606449 = header.getOrDefault("X-Amz-Date")
  valid_606449 = validateParameter(valid_606449, JString, required = false,
                                 default = nil)
  if valid_606449 != nil:
    section.add "X-Amz-Date", valid_606449
  var valid_606450 = header.getOrDefault("X-Amz-Credential")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-Credential", valid_606450
  var valid_606451 = header.getOrDefault("X-Amz-Security-Token")
  valid_606451 = validateParameter(valid_606451, JString, required = false,
                                 default = nil)
  if valid_606451 != nil:
    section.add "X-Amz-Security-Token", valid_606451
  var valid_606452 = header.getOrDefault("X-Amz-Algorithm")
  valid_606452 = validateParameter(valid_606452, JString, required = false,
                                 default = nil)
  if valid_606452 != nil:
    section.add "X-Amz-Algorithm", valid_606452
  var valid_606453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606453 = validateParameter(valid_606453, JString, required = false,
                                 default = nil)
  if valid_606453 != nil:
    section.add "X-Amz-SignedHeaders", valid_606453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606455: Call_AdminRemoveUserFromGroup_606443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified user from the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_606455.validator(path, query, header, formData, body)
  let scheme = call_606455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606455.url(scheme.get, call_606455.host, call_606455.base,
                         call_606455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606455, url, valid)

proc call*(call_606456: Call_AdminRemoveUserFromGroup_606443; body: JsonNode): Recallable =
  ## adminRemoveUserFromGroup
  ## <p>Removes the specified user from the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_606457 = newJObject()
  if body != nil:
    body_606457 = body
  result = call_606456.call(nil, nil, nil, nil, body_606457)

var adminRemoveUserFromGroup* = Call_AdminRemoveUserFromGroup_606443(
    name: "adminRemoveUserFromGroup", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminRemoveUserFromGroup",
    validator: validate_AdminRemoveUserFromGroup_606444, base: "/",
    url: url_AdminRemoveUserFromGroup_606445, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminResetUserPassword_606458 = ref object of OpenApiRestCall_605589
proc url_AdminResetUserPassword_606460(protocol: Scheme; host: string; base: string;
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

proc validate_AdminResetUserPassword_606459(path: JsonNode; query: JsonNode;
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
  var valid_606461 = header.getOrDefault("X-Amz-Target")
  valid_606461 = validateParameter(valid_606461, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminResetUserPassword"))
  if valid_606461 != nil:
    section.add "X-Amz-Target", valid_606461
  var valid_606462 = header.getOrDefault("X-Amz-Signature")
  valid_606462 = validateParameter(valid_606462, JString, required = false,
                                 default = nil)
  if valid_606462 != nil:
    section.add "X-Amz-Signature", valid_606462
  var valid_606463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606463 = validateParameter(valid_606463, JString, required = false,
                                 default = nil)
  if valid_606463 != nil:
    section.add "X-Amz-Content-Sha256", valid_606463
  var valid_606464 = header.getOrDefault("X-Amz-Date")
  valid_606464 = validateParameter(valid_606464, JString, required = false,
                                 default = nil)
  if valid_606464 != nil:
    section.add "X-Amz-Date", valid_606464
  var valid_606465 = header.getOrDefault("X-Amz-Credential")
  valid_606465 = validateParameter(valid_606465, JString, required = false,
                                 default = nil)
  if valid_606465 != nil:
    section.add "X-Amz-Credential", valid_606465
  var valid_606466 = header.getOrDefault("X-Amz-Security-Token")
  valid_606466 = validateParameter(valid_606466, JString, required = false,
                                 default = nil)
  if valid_606466 != nil:
    section.add "X-Amz-Security-Token", valid_606466
  var valid_606467 = header.getOrDefault("X-Amz-Algorithm")
  valid_606467 = validateParameter(valid_606467, JString, required = false,
                                 default = nil)
  if valid_606467 != nil:
    section.add "X-Amz-Algorithm", valid_606467
  var valid_606468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606468 = validateParameter(valid_606468, JString, required = false,
                                 default = nil)
  if valid_606468 != nil:
    section.add "X-Amz-SignedHeaders", valid_606468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606470: Call_AdminResetUserPassword_606458; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Resets the specified user's password in a user pool as an administrator. Works on any user.</p> <p>When a developer calls this API, the current password is invalidated, so it must be changed. If a user tries to sign in after the API is called, the app will get a PasswordResetRequiredException exception back and should direct the user down the flow to reset the password, which is the same as the forgot password flow. In addition, if the user pool has phone verification selected and a verified phone number exists for the user, or if email verification is selected and a verified email exists for the user, calling this API will also result in sending a message to the end user with the code to change their password.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_606470.validator(path, query, header, formData, body)
  let scheme = call_606470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606470.url(scheme.get, call_606470.host, call_606470.base,
                         call_606470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606470, url, valid)

proc call*(call_606471: Call_AdminResetUserPassword_606458; body: JsonNode): Recallable =
  ## adminResetUserPassword
  ## <p>Resets the specified user's password in a user pool as an administrator. Works on any user.</p> <p>When a developer calls this API, the current password is invalidated, so it must be changed. If a user tries to sign in after the API is called, the app will get a PasswordResetRequiredException exception back and should direct the user down the flow to reset the password, which is the same as the forgot password flow. In addition, if the user pool has phone verification selected and a verified phone number exists for the user, or if email verification is selected and a verified email exists for the user, calling this API will also result in sending a message to the end user with the code to change their password.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_606472 = newJObject()
  if body != nil:
    body_606472 = body
  result = call_606471.call(nil, nil, nil, nil, body_606472)

var adminResetUserPassword* = Call_AdminResetUserPassword_606458(
    name: "adminResetUserPassword", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminResetUserPassword",
    validator: validate_AdminResetUserPassword_606459, base: "/",
    url: url_AdminResetUserPassword_606460, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminRespondToAuthChallenge_606473 = ref object of OpenApiRestCall_605589
proc url_AdminRespondToAuthChallenge_606475(protocol: Scheme; host: string;
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

proc validate_AdminRespondToAuthChallenge_606474(path: JsonNode; query: JsonNode;
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
  var valid_606476 = header.getOrDefault("X-Amz-Target")
  valid_606476 = validateParameter(valid_606476, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminRespondToAuthChallenge"))
  if valid_606476 != nil:
    section.add "X-Amz-Target", valid_606476
  var valid_606477 = header.getOrDefault("X-Amz-Signature")
  valid_606477 = validateParameter(valid_606477, JString, required = false,
                                 default = nil)
  if valid_606477 != nil:
    section.add "X-Amz-Signature", valid_606477
  var valid_606478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606478 = validateParameter(valid_606478, JString, required = false,
                                 default = nil)
  if valid_606478 != nil:
    section.add "X-Amz-Content-Sha256", valid_606478
  var valid_606479 = header.getOrDefault("X-Amz-Date")
  valid_606479 = validateParameter(valid_606479, JString, required = false,
                                 default = nil)
  if valid_606479 != nil:
    section.add "X-Amz-Date", valid_606479
  var valid_606480 = header.getOrDefault("X-Amz-Credential")
  valid_606480 = validateParameter(valid_606480, JString, required = false,
                                 default = nil)
  if valid_606480 != nil:
    section.add "X-Amz-Credential", valid_606480
  var valid_606481 = header.getOrDefault("X-Amz-Security-Token")
  valid_606481 = validateParameter(valid_606481, JString, required = false,
                                 default = nil)
  if valid_606481 != nil:
    section.add "X-Amz-Security-Token", valid_606481
  var valid_606482 = header.getOrDefault("X-Amz-Algorithm")
  valid_606482 = validateParameter(valid_606482, JString, required = false,
                                 default = nil)
  if valid_606482 != nil:
    section.add "X-Amz-Algorithm", valid_606482
  var valid_606483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606483 = validateParameter(valid_606483, JString, required = false,
                                 default = nil)
  if valid_606483 != nil:
    section.add "X-Amz-SignedHeaders", valid_606483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606485: Call_AdminRespondToAuthChallenge_606473; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Responds to an authentication challenge, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_606485.validator(path, query, header, formData, body)
  let scheme = call_606485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606485.url(scheme.get, call_606485.host, call_606485.base,
                         call_606485.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606485, url, valid)

proc call*(call_606486: Call_AdminRespondToAuthChallenge_606473; body: JsonNode): Recallable =
  ## adminRespondToAuthChallenge
  ## <p>Responds to an authentication challenge, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_606487 = newJObject()
  if body != nil:
    body_606487 = body
  result = call_606486.call(nil, nil, nil, nil, body_606487)

var adminRespondToAuthChallenge* = Call_AdminRespondToAuthChallenge_606473(
    name: "adminRespondToAuthChallenge", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminRespondToAuthChallenge",
    validator: validate_AdminRespondToAuthChallenge_606474, base: "/",
    url: url_AdminRespondToAuthChallenge_606475,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminSetUserMFAPreference_606488 = ref object of OpenApiRestCall_605589
proc url_AdminSetUserMFAPreference_606490(protocol: Scheme; host: string;
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

proc validate_AdminSetUserMFAPreference_606489(path: JsonNode; query: JsonNode;
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
  var valid_606491 = header.getOrDefault("X-Amz-Target")
  valid_606491 = validateParameter(valid_606491, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminSetUserMFAPreference"))
  if valid_606491 != nil:
    section.add "X-Amz-Target", valid_606491
  var valid_606492 = header.getOrDefault("X-Amz-Signature")
  valid_606492 = validateParameter(valid_606492, JString, required = false,
                                 default = nil)
  if valid_606492 != nil:
    section.add "X-Amz-Signature", valid_606492
  var valid_606493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606493 = validateParameter(valid_606493, JString, required = false,
                                 default = nil)
  if valid_606493 != nil:
    section.add "X-Amz-Content-Sha256", valid_606493
  var valid_606494 = header.getOrDefault("X-Amz-Date")
  valid_606494 = validateParameter(valid_606494, JString, required = false,
                                 default = nil)
  if valid_606494 != nil:
    section.add "X-Amz-Date", valid_606494
  var valid_606495 = header.getOrDefault("X-Amz-Credential")
  valid_606495 = validateParameter(valid_606495, JString, required = false,
                                 default = nil)
  if valid_606495 != nil:
    section.add "X-Amz-Credential", valid_606495
  var valid_606496 = header.getOrDefault("X-Amz-Security-Token")
  valid_606496 = validateParameter(valid_606496, JString, required = false,
                                 default = nil)
  if valid_606496 != nil:
    section.add "X-Amz-Security-Token", valid_606496
  var valid_606497 = header.getOrDefault("X-Amz-Algorithm")
  valid_606497 = validateParameter(valid_606497, JString, required = false,
                                 default = nil)
  if valid_606497 != nil:
    section.add "X-Amz-Algorithm", valid_606497
  var valid_606498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606498 = validateParameter(valid_606498, JString, required = false,
                                 default = nil)
  if valid_606498 != nil:
    section.add "X-Amz-SignedHeaders", valid_606498
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606500: Call_AdminSetUserMFAPreference_606488; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the user's multi-factor authentication (MFA) preference, including which MFA options are enabled and if any are preferred. Only one factor can be set as preferred. The preferred MFA factor will be used to authenticate a user if multiple factors are enabled. If multiple options are enabled and no preference is set, a challenge to choose an MFA option will be returned during sign in.
  ## 
  let valid = call_606500.validator(path, query, header, formData, body)
  let scheme = call_606500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606500.url(scheme.get, call_606500.host, call_606500.base,
                         call_606500.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606500, url, valid)

proc call*(call_606501: Call_AdminSetUserMFAPreference_606488; body: JsonNode): Recallable =
  ## adminSetUserMFAPreference
  ## Sets the user's multi-factor authentication (MFA) preference, including which MFA options are enabled and if any are preferred. Only one factor can be set as preferred. The preferred MFA factor will be used to authenticate a user if multiple factors are enabled. If multiple options are enabled and no preference is set, a challenge to choose an MFA option will be returned during sign in.
  ##   body: JObject (required)
  var body_606502 = newJObject()
  if body != nil:
    body_606502 = body
  result = call_606501.call(nil, nil, nil, nil, body_606502)

var adminSetUserMFAPreference* = Call_AdminSetUserMFAPreference_606488(
    name: "adminSetUserMFAPreference", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminSetUserMFAPreference",
    validator: validate_AdminSetUserMFAPreference_606489, base: "/",
    url: url_AdminSetUserMFAPreference_606490,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminSetUserPassword_606503 = ref object of OpenApiRestCall_605589
proc url_AdminSetUserPassword_606505(protocol: Scheme; host: string; base: string;
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

proc validate_AdminSetUserPassword_606504(path: JsonNode; query: JsonNode;
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
  var valid_606506 = header.getOrDefault("X-Amz-Target")
  valid_606506 = validateParameter(valid_606506, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminSetUserPassword"))
  if valid_606506 != nil:
    section.add "X-Amz-Target", valid_606506
  var valid_606507 = header.getOrDefault("X-Amz-Signature")
  valid_606507 = validateParameter(valid_606507, JString, required = false,
                                 default = nil)
  if valid_606507 != nil:
    section.add "X-Amz-Signature", valid_606507
  var valid_606508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606508 = validateParameter(valid_606508, JString, required = false,
                                 default = nil)
  if valid_606508 != nil:
    section.add "X-Amz-Content-Sha256", valid_606508
  var valid_606509 = header.getOrDefault("X-Amz-Date")
  valid_606509 = validateParameter(valid_606509, JString, required = false,
                                 default = nil)
  if valid_606509 != nil:
    section.add "X-Amz-Date", valid_606509
  var valid_606510 = header.getOrDefault("X-Amz-Credential")
  valid_606510 = validateParameter(valid_606510, JString, required = false,
                                 default = nil)
  if valid_606510 != nil:
    section.add "X-Amz-Credential", valid_606510
  var valid_606511 = header.getOrDefault("X-Amz-Security-Token")
  valid_606511 = validateParameter(valid_606511, JString, required = false,
                                 default = nil)
  if valid_606511 != nil:
    section.add "X-Amz-Security-Token", valid_606511
  var valid_606512 = header.getOrDefault("X-Amz-Algorithm")
  valid_606512 = validateParameter(valid_606512, JString, required = false,
                                 default = nil)
  if valid_606512 != nil:
    section.add "X-Amz-Algorithm", valid_606512
  var valid_606513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606513 = validateParameter(valid_606513, JString, required = false,
                                 default = nil)
  if valid_606513 != nil:
    section.add "X-Amz-SignedHeaders", valid_606513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606515: Call_AdminSetUserPassword_606503; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the specified user's password in a user pool as an administrator. Works on any user. </p> <p>The password can be temporary or permanent. If it is temporary, the user status will be placed into the <code>FORCE_CHANGE_PASSWORD</code> state. When the user next tries to sign in, the InitiateAuth/AdminInitiateAuth response will contain the <code>NEW_PASSWORD_REQUIRED</code> challenge. If the user does not sign in before it expires, the user will not be able to sign in and their password will need to be reset by an administrator. </p> <p>Once the user has set a new password, or the password is permanent, the user status will be set to <code>Confirmed</code>.</p>
  ## 
  let valid = call_606515.validator(path, query, header, formData, body)
  let scheme = call_606515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606515.url(scheme.get, call_606515.host, call_606515.base,
                         call_606515.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606515, url, valid)

proc call*(call_606516: Call_AdminSetUserPassword_606503; body: JsonNode): Recallable =
  ## adminSetUserPassword
  ## <p>Sets the specified user's password in a user pool as an administrator. Works on any user. </p> <p>The password can be temporary or permanent. If it is temporary, the user status will be placed into the <code>FORCE_CHANGE_PASSWORD</code> state. When the user next tries to sign in, the InitiateAuth/AdminInitiateAuth response will contain the <code>NEW_PASSWORD_REQUIRED</code> challenge. If the user does not sign in before it expires, the user will not be able to sign in and their password will need to be reset by an administrator. </p> <p>Once the user has set a new password, or the password is permanent, the user status will be set to <code>Confirmed</code>.</p>
  ##   body: JObject (required)
  var body_606517 = newJObject()
  if body != nil:
    body_606517 = body
  result = call_606516.call(nil, nil, nil, nil, body_606517)

var adminSetUserPassword* = Call_AdminSetUserPassword_606503(
    name: "adminSetUserPassword", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminSetUserPassword",
    validator: validate_AdminSetUserPassword_606504, base: "/",
    url: url_AdminSetUserPassword_606505, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminSetUserSettings_606518 = ref object of OpenApiRestCall_605589
proc url_AdminSetUserSettings_606520(protocol: Scheme; host: string; base: string;
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

proc validate_AdminSetUserSettings_606519(path: JsonNode; query: JsonNode;
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
  var valid_606521 = header.getOrDefault("X-Amz-Target")
  valid_606521 = validateParameter(valid_606521, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminSetUserSettings"))
  if valid_606521 != nil:
    section.add "X-Amz-Target", valid_606521
  var valid_606522 = header.getOrDefault("X-Amz-Signature")
  valid_606522 = validateParameter(valid_606522, JString, required = false,
                                 default = nil)
  if valid_606522 != nil:
    section.add "X-Amz-Signature", valid_606522
  var valid_606523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606523 = validateParameter(valid_606523, JString, required = false,
                                 default = nil)
  if valid_606523 != nil:
    section.add "X-Amz-Content-Sha256", valid_606523
  var valid_606524 = header.getOrDefault("X-Amz-Date")
  valid_606524 = validateParameter(valid_606524, JString, required = false,
                                 default = nil)
  if valid_606524 != nil:
    section.add "X-Amz-Date", valid_606524
  var valid_606525 = header.getOrDefault("X-Amz-Credential")
  valid_606525 = validateParameter(valid_606525, JString, required = false,
                                 default = nil)
  if valid_606525 != nil:
    section.add "X-Amz-Credential", valid_606525
  var valid_606526 = header.getOrDefault("X-Amz-Security-Token")
  valid_606526 = validateParameter(valid_606526, JString, required = false,
                                 default = nil)
  if valid_606526 != nil:
    section.add "X-Amz-Security-Token", valid_606526
  var valid_606527 = header.getOrDefault("X-Amz-Algorithm")
  valid_606527 = validateParameter(valid_606527, JString, required = false,
                                 default = nil)
  if valid_606527 != nil:
    section.add "X-Amz-Algorithm", valid_606527
  var valid_606528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606528 = validateParameter(valid_606528, JString, required = false,
                                 default = nil)
  if valid_606528 != nil:
    section.add "X-Amz-SignedHeaders", valid_606528
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606530: Call_AdminSetUserSettings_606518; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <i>This action is no longer supported.</i> You can use it to configure only SMS MFA. You can't use it to configure TOTP software token MFA. To configure either type of MFA, use the <a>AdminSetUserMFAPreference</a> action instead.
  ## 
  let valid = call_606530.validator(path, query, header, formData, body)
  let scheme = call_606530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606530.url(scheme.get, call_606530.host, call_606530.base,
                         call_606530.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606530, url, valid)

proc call*(call_606531: Call_AdminSetUserSettings_606518; body: JsonNode): Recallable =
  ## adminSetUserSettings
  ##  <i>This action is no longer supported.</i> You can use it to configure only SMS MFA. You can't use it to configure TOTP software token MFA. To configure either type of MFA, use the <a>AdminSetUserMFAPreference</a> action instead.
  ##   body: JObject (required)
  var body_606532 = newJObject()
  if body != nil:
    body_606532 = body
  result = call_606531.call(nil, nil, nil, nil, body_606532)

var adminSetUserSettings* = Call_AdminSetUserSettings_606518(
    name: "adminSetUserSettings", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminSetUserSettings",
    validator: validate_AdminSetUserSettings_606519, base: "/",
    url: url_AdminSetUserSettings_606520, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUpdateAuthEventFeedback_606533 = ref object of OpenApiRestCall_605589
proc url_AdminUpdateAuthEventFeedback_606535(protocol: Scheme; host: string;
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

proc validate_AdminUpdateAuthEventFeedback_606534(path: JsonNode; query: JsonNode;
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
  var valid_606536 = header.getOrDefault("X-Amz-Target")
  valid_606536 = validateParameter(valid_606536, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUpdateAuthEventFeedback"))
  if valid_606536 != nil:
    section.add "X-Amz-Target", valid_606536
  var valid_606537 = header.getOrDefault("X-Amz-Signature")
  valid_606537 = validateParameter(valid_606537, JString, required = false,
                                 default = nil)
  if valid_606537 != nil:
    section.add "X-Amz-Signature", valid_606537
  var valid_606538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606538 = validateParameter(valid_606538, JString, required = false,
                                 default = nil)
  if valid_606538 != nil:
    section.add "X-Amz-Content-Sha256", valid_606538
  var valid_606539 = header.getOrDefault("X-Amz-Date")
  valid_606539 = validateParameter(valid_606539, JString, required = false,
                                 default = nil)
  if valid_606539 != nil:
    section.add "X-Amz-Date", valid_606539
  var valid_606540 = header.getOrDefault("X-Amz-Credential")
  valid_606540 = validateParameter(valid_606540, JString, required = false,
                                 default = nil)
  if valid_606540 != nil:
    section.add "X-Amz-Credential", valid_606540
  var valid_606541 = header.getOrDefault("X-Amz-Security-Token")
  valid_606541 = validateParameter(valid_606541, JString, required = false,
                                 default = nil)
  if valid_606541 != nil:
    section.add "X-Amz-Security-Token", valid_606541
  var valid_606542 = header.getOrDefault("X-Amz-Algorithm")
  valid_606542 = validateParameter(valid_606542, JString, required = false,
                                 default = nil)
  if valid_606542 != nil:
    section.add "X-Amz-Algorithm", valid_606542
  var valid_606543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606543 = validateParameter(valid_606543, JString, required = false,
                                 default = nil)
  if valid_606543 != nil:
    section.add "X-Amz-SignedHeaders", valid_606543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606545: Call_AdminUpdateAuthEventFeedback_606533; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides feedback for an authentication event as to whether it was from a valid user. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ## 
  let valid = call_606545.validator(path, query, header, formData, body)
  let scheme = call_606545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606545.url(scheme.get, call_606545.host, call_606545.base,
                         call_606545.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606545, url, valid)

proc call*(call_606546: Call_AdminUpdateAuthEventFeedback_606533; body: JsonNode): Recallable =
  ## adminUpdateAuthEventFeedback
  ## Provides feedback for an authentication event as to whether it was from a valid user. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ##   body: JObject (required)
  var body_606547 = newJObject()
  if body != nil:
    body_606547 = body
  result = call_606546.call(nil, nil, nil, nil, body_606547)

var adminUpdateAuthEventFeedback* = Call_AdminUpdateAuthEventFeedback_606533(
    name: "adminUpdateAuthEventFeedback", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUpdateAuthEventFeedback",
    validator: validate_AdminUpdateAuthEventFeedback_606534, base: "/",
    url: url_AdminUpdateAuthEventFeedback_606535,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUpdateDeviceStatus_606548 = ref object of OpenApiRestCall_605589
proc url_AdminUpdateDeviceStatus_606550(protocol: Scheme; host: string; base: string;
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

proc validate_AdminUpdateDeviceStatus_606549(path: JsonNode; query: JsonNode;
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
  var valid_606551 = header.getOrDefault("X-Amz-Target")
  valid_606551 = validateParameter(valid_606551, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUpdateDeviceStatus"))
  if valid_606551 != nil:
    section.add "X-Amz-Target", valid_606551
  var valid_606552 = header.getOrDefault("X-Amz-Signature")
  valid_606552 = validateParameter(valid_606552, JString, required = false,
                                 default = nil)
  if valid_606552 != nil:
    section.add "X-Amz-Signature", valid_606552
  var valid_606553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606553 = validateParameter(valid_606553, JString, required = false,
                                 default = nil)
  if valid_606553 != nil:
    section.add "X-Amz-Content-Sha256", valid_606553
  var valid_606554 = header.getOrDefault("X-Amz-Date")
  valid_606554 = validateParameter(valid_606554, JString, required = false,
                                 default = nil)
  if valid_606554 != nil:
    section.add "X-Amz-Date", valid_606554
  var valid_606555 = header.getOrDefault("X-Amz-Credential")
  valid_606555 = validateParameter(valid_606555, JString, required = false,
                                 default = nil)
  if valid_606555 != nil:
    section.add "X-Amz-Credential", valid_606555
  var valid_606556 = header.getOrDefault("X-Amz-Security-Token")
  valid_606556 = validateParameter(valid_606556, JString, required = false,
                                 default = nil)
  if valid_606556 != nil:
    section.add "X-Amz-Security-Token", valid_606556
  var valid_606557 = header.getOrDefault("X-Amz-Algorithm")
  valid_606557 = validateParameter(valid_606557, JString, required = false,
                                 default = nil)
  if valid_606557 != nil:
    section.add "X-Amz-Algorithm", valid_606557
  var valid_606558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606558 = validateParameter(valid_606558, JString, required = false,
                                 default = nil)
  if valid_606558 != nil:
    section.add "X-Amz-SignedHeaders", valid_606558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606560: Call_AdminUpdateDeviceStatus_606548; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the device status as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_606560.validator(path, query, header, formData, body)
  let scheme = call_606560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606560.url(scheme.get, call_606560.host, call_606560.base,
                         call_606560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606560, url, valid)

proc call*(call_606561: Call_AdminUpdateDeviceStatus_606548; body: JsonNode): Recallable =
  ## adminUpdateDeviceStatus
  ## <p>Updates the device status as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_606562 = newJObject()
  if body != nil:
    body_606562 = body
  result = call_606561.call(nil, nil, nil, nil, body_606562)

var adminUpdateDeviceStatus* = Call_AdminUpdateDeviceStatus_606548(
    name: "adminUpdateDeviceStatus", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUpdateDeviceStatus",
    validator: validate_AdminUpdateDeviceStatus_606549, base: "/",
    url: url_AdminUpdateDeviceStatus_606550, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUpdateUserAttributes_606563 = ref object of OpenApiRestCall_605589
proc url_AdminUpdateUserAttributes_606565(protocol: Scheme; host: string;
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

proc validate_AdminUpdateUserAttributes_606564(path: JsonNode; query: JsonNode;
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
  var valid_606566 = header.getOrDefault("X-Amz-Target")
  valid_606566 = validateParameter(valid_606566, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUpdateUserAttributes"))
  if valid_606566 != nil:
    section.add "X-Amz-Target", valid_606566
  var valid_606567 = header.getOrDefault("X-Amz-Signature")
  valid_606567 = validateParameter(valid_606567, JString, required = false,
                                 default = nil)
  if valid_606567 != nil:
    section.add "X-Amz-Signature", valid_606567
  var valid_606568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606568 = validateParameter(valid_606568, JString, required = false,
                                 default = nil)
  if valid_606568 != nil:
    section.add "X-Amz-Content-Sha256", valid_606568
  var valid_606569 = header.getOrDefault("X-Amz-Date")
  valid_606569 = validateParameter(valid_606569, JString, required = false,
                                 default = nil)
  if valid_606569 != nil:
    section.add "X-Amz-Date", valid_606569
  var valid_606570 = header.getOrDefault("X-Amz-Credential")
  valid_606570 = validateParameter(valid_606570, JString, required = false,
                                 default = nil)
  if valid_606570 != nil:
    section.add "X-Amz-Credential", valid_606570
  var valid_606571 = header.getOrDefault("X-Amz-Security-Token")
  valid_606571 = validateParameter(valid_606571, JString, required = false,
                                 default = nil)
  if valid_606571 != nil:
    section.add "X-Amz-Security-Token", valid_606571
  var valid_606572 = header.getOrDefault("X-Amz-Algorithm")
  valid_606572 = validateParameter(valid_606572, JString, required = false,
                                 default = nil)
  if valid_606572 != nil:
    section.add "X-Amz-Algorithm", valid_606572
  var valid_606573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606573 = validateParameter(valid_606573, JString, required = false,
                                 default = nil)
  if valid_606573 != nil:
    section.add "X-Amz-SignedHeaders", valid_606573
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606575: Call_AdminUpdateUserAttributes_606563; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified user's attributes, including developer attributes, as an administrator. Works on any user.</p> <p>For custom attributes, you must prepend the <code>custom:</code> prefix to the attribute name.</p> <p>In addition to updating user attributes, this API can also be used to mark phone and email as verified.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_606575.validator(path, query, header, formData, body)
  let scheme = call_606575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606575.url(scheme.get, call_606575.host, call_606575.base,
                         call_606575.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606575, url, valid)

proc call*(call_606576: Call_AdminUpdateUserAttributes_606563; body: JsonNode): Recallable =
  ## adminUpdateUserAttributes
  ## <p>Updates the specified user's attributes, including developer attributes, as an administrator. Works on any user.</p> <p>For custom attributes, you must prepend the <code>custom:</code> prefix to the attribute name.</p> <p>In addition to updating user attributes, this API can also be used to mark phone and email as verified.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_606577 = newJObject()
  if body != nil:
    body_606577 = body
  result = call_606576.call(nil, nil, nil, nil, body_606577)

var adminUpdateUserAttributes* = Call_AdminUpdateUserAttributes_606563(
    name: "adminUpdateUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUpdateUserAttributes",
    validator: validate_AdminUpdateUserAttributes_606564, base: "/",
    url: url_AdminUpdateUserAttributes_606565,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUserGlobalSignOut_606578 = ref object of OpenApiRestCall_605589
proc url_AdminUserGlobalSignOut_606580(protocol: Scheme; host: string; base: string;
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

proc validate_AdminUserGlobalSignOut_606579(path: JsonNode; query: JsonNode;
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
  var valid_606581 = header.getOrDefault("X-Amz-Target")
  valid_606581 = validateParameter(valid_606581, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUserGlobalSignOut"))
  if valid_606581 != nil:
    section.add "X-Amz-Target", valid_606581
  var valid_606582 = header.getOrDefault("X-Amz-Signature")
  valid_606582 = validateParameter(valid_606582, JString, required = false,
                                 default = nil)
  if valid_606582 != nil:
    section.add "X-Amz-Signature", valid_606582
  var valid_606583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606583 = validateParameter(valid_606583, JString, required = false,
                                 default = nil)
  if valid_606583 != nil:
    section.add "X-Amz-Content-Sha256", valid_606583
  var valid_606584 = header.getOrDefault("X-Amz-Date")
  valid_606584 = validateParameter(valid_606584, JString, required = false,
                                 default = nil)
  if valid_606584 != nil:
    section.add "X-Amz-Date", valid_606584
  var valid_606585 = header.getOrDefault("X-Amz-Credential")
  valid_606585 = validateParameter(valid_606585, JString, required = false,
                                 default = nil)
  if valid_606585 != nil:
    section.add "X-Amz-Credential", valid_606585
  var valid_606586 = header.getOrDefault("X-Amz-Security-Token")
  valid_606586 = validateParameter(valid_606586, JString, required = false,
                                 default = nil)
  if valid_606586 != nil:
    section.add "X-Amz-Security-Token", valid_606586
  var valid_606587 = header.getOrDefault("X-Amz-Algorithm")
  valid_606587 = validateParameter(valid_606587, JString, required = false,
                                 default = nil)
  if valid_606587 != nil:
    section.add "X-Amz-Algorithm", valid_606587
  var valid_606588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606588 = validateParameter(valid_606588, JString, required = false,
                                 default = nil)
  if valid_606588 != nil:
    section.add "X-Amz-SignedHeaders", valid_606588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606590: Call_AdminUserGlobalSignOut_606578; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Signs out users from all devices, as an administrator. It also invalidates all refresh tokens issued to a user. The user's current access and Id tokens remain valid until their expiry. Access and Id tokens expire one hour after they are issued.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_606590.validator(path, query, header, formData, body)
  let scheme = call_606590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606590.url(scheme.get, call_606590.host, call_606590.base,
                         call_606590.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606590, url, valid)

proc call*(call_606591: Call_AdminUserGlobalSignOut_606578; body: JsonNode): Recallable =
  ## adminUserGlobalSignOut
  ## <p>Signs out users from all devices, as an administrator. It also invalidates all refresh tokens issued to a user. The user's current access and Id tokens remain valid until their expiry. Access and Id tokens expire one hour after they are issued.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_606592 = newJObject()
  if body != nil:
    body_606592 = body
  result = call_606591.call(nil, nil, nil, nil, body_606592)

var adminUserGlobalSignOut* = Call_AdminUserGlobalSignOut_606578(
    name: "adminUserGlobalSignOut", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUserGlobalSignOut",
    validator: validate_AdminUserGlobalSignOut_606579, base: "/",
    url: url_AdminUserGlobalSignOut_606580, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSoftwareToken_606593 = ref object of OpenApiRestCall_605589
proc url_AssociateSoftwareToken_606595(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateSoftwareToken_606594(path: JsonNode; query: JsonNode;
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
  var valid_606596 = header.getOrDefault("X-Amz-Target")
  valid_606596 = validateParameter(valid_606596, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AssociateSoftwareToken"))
  if valid_606596 != nil:
    section.add "X-Amz-Target", valid_606596
  var valid_606597 = header.getOrDefault("X-Amz-Signature")
  valid_606597 = validateParameter(valid_606597, JString, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "X-Amz-Signature", valid_606597
  var valid_606598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606598 = validateParameter(valid_606598, JString, required = false,
                                 default = nil)
  if valid_606598 != nil:
    section.add "X-Amz-Content-Sha256", valid_606598
  var valid_606599 = header.getOrDefault("X-Amz-Date")
  valid_606599 = validateParameter(valid_606599, JString, required = false,
                                 default = nil)
  if valid_606599 != nil:
    section.add "X-Amz-Date", valid_606599
  var valid_606600 = header.getOrDefault("X-Amz-Credential")
  valid_606600 = validateParameter(valid_606600, JString, required = false,
                                 default = nil)
  if valid_606600 != nil:
    section.add "X-Amz-Credential", valid_606600
  var valid_606601 = header.getOrDefault("X-Amz-Security-Token")
  valid_606601 = validateParameter(valid_606601, JString, required = false,
                                 default = nil)
  if valid_606601 != nil:
    section.add "X-Amz-Security-Token", valid_606601
  var valid_606602 = header.getOrDefault("X-Amz-Algorithm")
  valid_606602 = validateParameter(valid_606602, JString, required = false,
                                 default = nil)
  if valid_606602 != nil:
    section.add "X-Amz-Algorithm", valid_606602
  var valid_606603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606603 = validateParameter(valid_606603, JString, required = false,
                                 default = nil)
  if valid_606603 != nil:
    section.add "X-Amz-SignedHeaders", valid_606603
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606605: Call_AssociateSoftwareToken_606593; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a unique generated shared secret key code for the user account. The request takes an access token or a session string, but not both.
  ## 
  let valid = call_606605.validator(path, query, header, formData, body)
  let scheme = call_606605.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606605.url(scheme.get, call_606605.host, call_606605.base,
                         call_606605.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606605, url, valid)

proc call*(call_606606: Call_AssociateSoftwareToken_606593; body: JsonNode): Recallable =
  ## associateSoftwareToken
  ## Returns a unique generated shared secret key code for the user account. The request takes an access token or a session string, but not both.
  ##   body: JObject (required)
  var body_606607 = newJObject()
  if body != nil:
    body_606607 = body
  result = call_606606.call(nil, nil, nil, nil, body_606607)

var associateSoftwareToken* = Call_AssociateSoftwareToken_606593(
    name: "associateSoftwareToken", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AssociateSoftwareToken",
    validator: validate_AssociateSoftwareToken_606594, base: "/",
    url: url_AssociateSoftwareToken_606595, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ChangePassword_606608 = ref object of OpenApiRestCall_605589
proc url_ChangePassword_606610(protocol: Scheme; host: string; base: string;
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

proc validate_ChangePassword_606609(path: JsonNode; query: JsonNode;
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
  var valid_606611 = header.getOrDefault("X-Amz-Target")
  valid_606611 = validateParameter(valid_606611, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ChangePassword"))
  if valid_606611 != nil:
    section.add "X-Amz-Target", valid_606611
  var valid_606612 = header.getOrDefault("X-Amz-Signature")
  valid_606612 = validateParameter(valid_606612, JString, required = false,
                                 default = nil)
  if valid_606612 != nil:
    section.add "X-Amz-Signature", valid_606612
  var valid_606613 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606613 = validateParameter(valid_606613, JString, required = false,
                                 default = nil)
  if valid_606613 != nil:
    section.add "X-Amz-Content-Sha256", valid_606613
  var valid_606614 = header.getOrDefault("X-Amz-Date")
  valid_606614 = validateParameter(valid_606614, JString, required = false,
                                 default = nil)
  if valid_606614 != nil:
    section.add "X-Amz-Date", valid_606614
  var valid_606615 = header.getOrDefault("X-Amz-Credential")
  valid_606615 = validateParameter(valid_606615, JString, required = false,
                                 default = nil)
  if valid_606615 != nil:
    section.add "X-Amz-Credential", valid_606615
  var valid_606616 = header.getOrDefault("X-Amz-Security-Token")
  valid_606616 = validateParameter(valid_606616, JString, required = false,
                                 default = nil)
  if valid_606616 != nil:
    section.add "X-Amz-Security-Token", valid_606616
  var valid_606617 = header.getOrDefault("X-Amz-Algorithm")
  valid_606617 = validateParameter(valid_606617, JString, required = false,
                                 default = nil)
  if valid_606617 != nil:
    section.add "X-Amz-Algorithm", valid_606617
  var valid_606618 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606618 = validateParameter(valid_606618, JString, required = false,
                                 default = nil)
  if valid_606618 != nil:
    section.add "X-Amz-SignedHeaders", valid_606618
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606620: Call_ChangePassword_606608; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the password for a specified user in a user pool.
  ## 
  let valid = call_606620.validator(path, query, header, formData, body)
  let scheme = call_606620.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606620.url(scheme.get, call_606620.host, call_606620.base,
                         call_606620.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606620, url, valid)

proc call*(call_606621: Call_ChangePassword_606608; body: JsonNode): Recallable =
  ## changePassword
  ## Changes the password for a specified user in a user pool.
  ##   body: JObject (required)
  var body_606622 = newJObject()
  if body != nil:
    body_606622 = body
  result = call_606621.call(nil, nil, nil, nil, body_606622)

var changePassword* = Call_ChangePassword_606608(name: "changePassword",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ChangePassword",
    validator: validate_ChangePassword_606609, base: "/", url: url_ChangePassword_606610,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmDevice_606623 = ref object of OpenApiRestCall_605589
proc url_ConfirmDevice_606625(protocol: Scheme; host: string; base: string;
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

proc validate_ConfirmDevice_606624(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606626 = header.getOrDefault("X-Amz-Target")
  valid_606626 = validateParameter(valid_606626, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ConfirmDevice"))
  if valid_606626 != nil:
    section.add "X-Amz-Target", valid_606626
  var valid_606627 = header.getOrDefault("X-Amz-Signature")
  valid_606627 = validateParameter(valid_606627, JString, required = false,
                                 default = nil)
  if valid_606627 != nil:
    section.add "X-Amz-Signature", valid_606627
  var valid_606628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606628 = validateParameter(valid_606628, JString, required = false,
                                 default = nil)
  if valid_606628 != nil:
    section.add "X-Amz-Content-Sha256", valid_606628
  var valid_606629 = header.getOrDefault("X-Amz-Date")
  valid_606629 = validateParameter(valid_606629, JString, required = false,
                                 default = nil)
  if valid_606629 != nil:
    section.add "X-Amz-Date", valid_606629
  var valid_606630 = header.getOrDefault("X-Amz-Credential")
  valid_606630 = validateParameter(valid_606630, JString, required = false,
                                 default = nil)
  if valid_606630 != nil:
    section.add "X-Amz-Credential", valid_606630
  var valid_606631 = header.getOrDefault("X-Amz-Security-Token")
  valid_606631 = validateParameter(valid_606631, JString, required = false,
                                 default = nil)
  if valid_606631 != nil:
    section.add "X-Amz-Security-Token", valid_606631
  var valid_606632 = header.getOrDefault("X-Amz-Algorithm")
  valid_606632 = validateParameter(valid_606632, JString, required = false,
                                 default = nil)
  if valid_606632 != nil:
    section.add "X-Amz-Algorithm", valid_606632
  var valid_606633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606633 = validateParameter(valid_606633, JString, required = false,
                                 default = nil)
  if valid_606633 != nil:
    section.add "X-Amz-SignedHeaders", valid_606633
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606635: Call_ConfirmDevice_606623; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Confirms tracking of the device. This API call is the call that begins device tracking.
  ## 
  let valid = call_606635.validator(path, query, header, formData, body)
  let scheme = call_606635.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606635.url(scheme.get, call_606635.host, call_606635.base,
                         call_606635.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606635, url, valid)

proc call*(call_606636: Call_ConfirmDevice_606623; body: JsonNode): Recallable =
  ## confirmDevice
  ## Confirms tracking of the device. This API call is the call that begins device tracking.
  ##   body: JObject (required)
  var body_606637 = newJObject()
  if body != nil:
    body_606637 = body
  result = call_606636.call(nil, nil, nil, nil, body_606637)

var confirmDevice* = Call_ConfirmDevice_606623(name: "confirmDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ConfirmDevice",
    validator: validate_ConfirmDevice_606624, base: "/", url: url_ConfirmDevice_606625,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmForgotPassword_606638 = ref object of OpenApiRestCall_605589
proc url_ConfirmForgotPassword_606640(protocol: Scheme; host: string; base: string;
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

proc validate_ConfirmForgotPassword_606639(path: JsonNode; query: JsonNode;
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
  var valid_606641 = header.getOrDefault("X-Amz-Target")
  valid_606641 = validateParameter(valid_606641, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ConfirmForgotPassword"))
  if valid_606641 != nil:
    section.add "X-Amz-Target", valid_606641
  var valid_606642 = header.getOrDefault("X-Amz-Signature")
  valid_606642 = validateParameter(valid_606642, JString, required = false,
                                 default = nil)
  if valid_606642 != nil:
    section.add "X-Amz-Signature", valid_606642
  var valid_606643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606643 = validateParameter(valid_606643, JString, required = false,
                                 default = nil)
  if valid_606643 != nil:
    section.add "X-Amz-Content-Sha256", valid_606643
  var valid_606644 = header.getOrDefault("X-Amz-Date")
  valid_606644 = validateParameter(valid_606644, JString, required = false,
                                 default = nil)
  if valid_606644 != nil:
    section.add "X-Amz-Date", valid_606644
  var valid_606645 = header.getOrDefault("X-Amz-Credential")
  valid_606645 = validateParameter(valid_606645, JString, required = false,
                                 default = nil)
  if valid_606645 != nil:
    section.add "X-Amz-Credential", valid_606645
  var valid_606646 = header.getOrDefault("X-Amz-Security-Token")
  valid_606646 = validateParameter(valid_606646, JString, required = false,
                                 default = nil)
  if valid_606646 != nil:
    section.add "X-Amz-Security-Token", valid_606646
  var valid_606647 = header.getOrDefault("X-Amz-Algorithm")
  valid_606647 = validateParameter(valid_606647, JString, required = false,
                                 default = nil)
  if valid_606647 != nil:
    section.add "X-Amz-Algorithm", valid_606647
  var valid_606648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606648 = validateParameter(valid_606648, JString, required = false,
                                 default = nil)
  if valid_606648 != nil:
    section.add "X-Amz-SignedHeaders", valid_606648
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606650: Call_ConfirmForgotPassword_606638; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a user to enter a confirmation code to reset a forgotten password.
  ## 
  let valid = call_606650.validator(path, query, header, formData, body)
  let scheme = call_606650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606650.url(scheme.get, call_606650.host, call_606650.base,
                         call_606650.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606650, url, valid)

proc call*(call_606651: Call_ConfirmForgotPassword_606638; body: JsonNode): Recallable =
  ## confirmForgotPassword
  ## Allows a user to enter a confirmation code to reset a forgotten password.
  ##   body: JObject (required)
  var body_606652 = newJObject()
  if body != nil:
    body_606652 = body
  result = call_606651.call(nil, nil, nil, nil, body_606652)

var confirmForgotPassword* = Call_ConfirmForgotPassword_606638(
    name: "confirmForgotPassword", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ConfirmForgotPassword",
    validator: validate_ConfirmForgotPassword_606639, base: "/",
    url: url_ConfirmForgotPassword_606640, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmSignUp_606653 = ref object of OpenApiRestCall_605589
proc url_ConfirmSignUp_606655(protocol: Scheme; host: string; base: string;
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

proc validate_ConfirmSignUp_606654(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606656 = header.getOrDefault("X-Amz-Target")
  valid_606656 = validateParameter(valid_606656, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ConfirmSignUp"))
  if valid_606656 != nil:
    section.add "X-Amz-Target", valid_606656
  var valid_606657 = header.getOrDefault("X-Amz-Signature")
  valid_606657 = validateParameter(valid_606657, JString, required = false,
                                 default = nil)
  if valid_606657 != nil:
    section.add "X-Amz-Signature", valid_606657
  var valid_606658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606658 = validateParameter(valid_606658, JString, required = false,
                                 default = nil)
  if valid_606658 != nil:
    section.add "X-Amz-Content-Sha256", valid_606658
  var valid_606659 = header.getOrDefault("X-Amz-Date")
  valid_606659 = validateParameter(valid_606659, JString, required = false,
                                 default = nil)
  if valid_606659 != nil:
    section.add "X-Amz-Date", valid_606659
  var valid_606660 = header.getOrDefault("X-Amz-Credential")
  valid_606660 = validateParameter(valid_606660, JString, required = false,
                                 default = nil)
  if valid_606660 != nil:
    section.add "X-Amz-Credential", valid_606660
  var valid_606661 = header.getOrDefault("X-Amz-Security-Token")
  valid_606661 = validateParameter(valid_606661, JString, required = false,
                                 default = nil)
  if valid_606661 != nil:
    section.add "X-Amz-Security-Token", valid_606661
  var valid_606662 = header.getOrDefault("X-Amz-Algorithm")
  valid_606662 = validateParameter(valid_606662, JString, required = false,
                                 default = nil)
  if valid_606662 != nil:
    section.add "X-Amz-Algorithm", valid_606662
  var valid_606663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606663 = validateParameter(valid_606663, JString, required = false,
                                 default = nil)
  if valid_606663 != nil:
    section.add "X-Amz-SignedHeaders", valid_606663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606665: Call_ConfirmSignUp_606653; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Confirms registration of a user and handles the existing alias from a previous user.
  ## 
  let valid = call_606665.validator(path, query, header, formData, body)
  let scheme = call_606665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606665.url(scheme.get, call_606665.host, call_606665.base,
                         call_606665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606665, url, valid)

proc call*(call_606666: Call_ConfirmSignUp_606653; body: JsonNode): Recallable =
  ## confirmSignUp
  ## Confirms registration of a user and handles the existing alias from a previous user.
  ##   body: JObject (required)
  var body_606667 = newJObject()
  if body != nil:
    body_606667 = body
  result = call_606666.call(nil, nil, nil, nil, body_606667)

var confirmSignUp* = Call_ConfirmSignUp_606653(name: "confirmSignUp",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ConfirmSignUp",
    validator: validate_ConfirmSignUp_606654, base: "/", url: url_ConfirmSignUp_606655,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_606668 = ref object of OpenApiRestCall_605589
proc url_CreateGroup_606670(protocol: Scheme; host: string; base: string;
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

proc validate_CreateGroup_606669(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606671 = header.getOrDefault("X-Amz-Target")
  valid_606671 = validateParameter(valid_606671, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateGroup"))
  if valid_606671 != nil:
    section.add "X-Amz-Target", valid_606671
  var valid_606672 = header.getOrDefault("X-Amz-Signature")
  valid_606672 = validateParameter(valid_606672, JString, required = false,
                                 default = nil)
  if valid_606672 != nil:
    section.add "X-Amz-Signature", valid_606672
  var valid_606673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606673 = validateParameter(valid_606673, JString, required = false,
                                 default = nil)
  if valid_606673 != nil:
    section.add "X-Amz-Content-Sha256", valid_606673
  var valid_606674 = header.getOrDefault("X-Amz-Date")
  valid_606674 = validateParameter(valid_606674, JString, required = false,
                                 default = nil)
  if valid_606674 != nil:
    section.add "X-Amz-Date", valid_606674
  var valid_606675 = header.getOrDefault("X-Amz-Credential")
  valid_606675 = validateParameter(valid_606675, JString, required = false,
                                 default = nil)
  if valid_606675 != nil:
    section.add "X-Amz-Credential", valid_606675
  var valid_606676 = header.getOrDefault("X-Amz-Security-Token")
  valid_606676 = validateParameter(valid_606676, JString, required = false,
                                 default = nil)
  if valid_606676 != nil:
    section.add "X-Amz-Security-Token", valid_606676
  var valid_606677 = header.getOrDefault("X-Amz-Algorithm")
  valid_606677 = validateParameter(valid_606677, JString, required = false,
                                 default = nil)
  if valid_606677 != nil:
    section.add "X-Amz-Algorithm", valid_606677
  var valid_606678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606678 = validateParameter(valid_606678, JString, required = false,
                                 default = nil)
  if valid_606678 != nil:
    section.add "X-Amz-SignedHeaders", valid_606678
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606680: Call_CreateGroup_606668; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new group in the specified user pool.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_606680.validator(path, query, header, formData, body)
  let scheme = call_606680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606680.url(scheme.get, call_606680.host, call_606680.base,
                         call_606680.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606680, url, valid)

proc call*(call_606681: Call_CreateGroup_606668; body: JsonNode): Recallable =
  ## createGroup
  ## <p>Creates a new group in the specified user pool.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_606682 = newJObject()
  if body != nil:
    body_606682 = body
  result = call_606681.call(nil, nil, nil, nil, body_606682)

var createGroup* = Call_CreateGroup_606668(name: "createGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateGroup",
                                        validator: validate_CreateGroup_606669,
                                        base: "/", url: url_CreateGroup_606670,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIdentityProvider_606683 = ref object of OpenApiRestCall_605589
proc url_CreateIdentityProvider_606685(protocol: Scheme; host: string; base: string;
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

proc validate_CreateIdentityProvider_606684(path: JsonNode; query: JsonNode;
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
  var valid_606686 = header.getOrDefault("X-Amz-Target")
  valid_606686 = validateParameter(valid_606686, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateIdentityProvider"))
  if valid_606686 != nil:
    section.add "X-Amz-Target", valid_606686
  var valid_606687 = header.getOrDefault("X-Amz-Signature")
  valid_606687 = validateParameter(valid_606687, JString, required = false,
                                 default = nil)
  if valid_606687 != nil:
    section.add "X-Amz-Signature", valid_606687
  var valid_606688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606688 = validateParameter(valid_606688, JString, required = false,
                                 default = nil)
  if valid_606688 != nil:
    section.add "X-Amz-Content-Sha256", valid_606688
  var valid_606689 = header.getOrDefault("X-Amz-Date")
  valid_606689 = validateParameter(valid_606689, JString, required = false,
                                 default = nil)
  if valid_606689 != nil:
    section.add "X-Amz-Date", valid_606689
  var valid_606690 = header.getOrDefault("X-Amz-Credential")
  valid_606690 = validateParameter(valid_606690, JString, required = false,
                                 default = nil)
  if valid_606690 != nil:
    section.add "X-Amz-Credential", valid_606690
  var valid_606691 = header.getOrDefault("X-Amz-Security-Token")
  valid_606691 = validateParameter(valid_606691, JString, required = false,
                                 default = nil)
  if valid_606691 != nil:
    section.add "X-Amz-Security-Token", valid_606691
  var valid_606692 = header.getOrDefault("X-Amz-Algorithm")
  valid_606692 = validateParameter(valid_606692, JString, required = false,
                                 default = nil)
  if valid_606692 != nil:
    section.add "X-Amz-Algorithm", valid_606692
  var valid_606693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606693 = validateParameter(valid_606693, JString, required = false,
                                 default = nil)
  if valid_606693 != nil:
    section.add "X-Amz-SignedHeaders", valid_606693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606695: Call_CreateIdentityProvider_606683; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an identity provider for a user pool.
  ## 
  let valid = call_606695.validator(path, query, header, formData, body)
  let scheme = call_606695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606695.url(scheme.get, call_606695.host, call_606695.base,
                         call_606695.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606695, url, valid)

proc call*(call_606696: Call_CreateIdentityProvider_606683; body: JsonNode): Recallable =
  ## createIdentityProvider
  ## Creates an identity provider for a user pool.
  ##   body: JObject (required)
  var body_606697 = newJObject()
  if body != nil:
    body_606697 = body
  result = call_606696.call(nil, nil, nil, nil, body_606697)

var createIdentityProvider* = Call_CreateIdentityProvider_606683(
    name: "createIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateIdentityProvider",
    validator: validate_CreateIdentityProvider_606684, base: "/",
    url: url_CreateIdentityProvider_606685, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceServer_606698 = ref object of OpenApiRestCall_605589
proc url_CreateResourceServer_606700(protocol: Scheme; host: string; base: string;
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

proc validate_CreateResourceServer_606699(path: JsonNode; query: JsonNode;
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
  var valid_606701 = header.getOrDefault("X-Amz-Target")
  valid_606701 = validateParameter(valid_606701, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateResourceServer"))
  if valid_606701 != nil:
    section.add "X-Amz-Target", valid_606701
  var valid_606702 = header.getOrDefault("X-Amz-Signature")
  valid_606702 = validateParameter(valid_606702, JString, required = false,
                                 default = nil)
  if valid_606702 != nil:
    section.add "X-Amz-Signature", valid_606702
  var valid_606703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606703 = validateParameter(valid_606703, JString, required = false,
                                 default = nil)
  if valid_606703 != nil:
    section.add "X-Amz-Content-Sha256", valid_606703
  var valid_606704 = header.getOrDefault("X-Amz-Date")
  valid_606704 = validateParameter(valid_606704, JString, required = false,
                                 default = nil)
  if valid_606704 != nil:
    section.add "X-Amz-Date", valid_606704
  var valid_606705 = header.getOrDefault("X-Amz-Credential")
  valid_606705 = validateParameter(valid_606705, JString, required = false,
                                 default = nil)
  if valid_606705 != nil:
    section.add "X-Amz-Credential", valid_606705
  var valid_606706 = header.getOrDefault("X-Amz-Security-Token")
  valid_606706 = validateParameter(valid_606706, JString, required = false,
                                 default = nil)
  if valid_606706 != nil:
    section.add "X-Amz-Security-Token", valid_606706
  var valid_606707 = header.getOrDefault("X-Amz-Algorithm")
  valid_606707 = validateParameter(valid_606707, JString, required = false,
                                 default = nil)
  if valid_606707 != nil:
    section.add "X-Amz-Algorithm", valid_606707
  var valid_606708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606708 = validateParameter(valid_606708, JString, required = false,
                                 default = nil)
  if valid_606708 != nil:
    section.add "X-Amz-SignedHeaders", valid_606708
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606710: Call_CreateResourceServer_606698; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new OAuth2.0 resource server and defines custom scopes in it.
  ## 
  let valid = call_606710.validator(path, query, header, formData, body)
  let scheme = call_606710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606710.url(scheme.get, call_606710.host, call_606710.base,
                         call_606710.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606710, url, valid)

proc call*(call_606711: Call_CreateResourceServer_606698; body: JsonNode): Recallable =
  ## createResourceServer
  ## Creates a new OAuth2.0 resource server and defines custom scopes in it.
  ##   body: JObject (required)
  var body_606712 = newJObject()
  if body != nil:
    body_606712 = body
  result = call_606711.call(nil, nil, nil, nil, body_606712)

var createResourceServer* = Call_CreateResourceServer_606698(
    name: "createResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateResourceServer",
    validator: validate_CreateResourceServer_606699, base: "/",
    url: url_CreateResourceServer_606700, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserImportJob_606713 = ref object of OpenApiRestCall_605589
proc url_CreateUserImportJob_606715(protocol: Scheme; host: string; base: string;
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

proc validate_CreateUserImportJob_606714(path: JsonNode; query: JsonNode;
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
  var valid_606716 = header.getOrDefault("X-Amz-Target")
  valid_606716 = validateParameter(valid_606716, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserImportJob"))
  if valid_606716 != nil:
    section.add "X-Amz-Target", valid_606716
  var valid_606717 = header.getOrDefault("X-Amz-Signature")
  valid_606717 = validateParameter(valid_606717, JString, required = false,
                                 default = nil)
  if valid_606717 != nil:
    section.add "X-Amz-Signature", valid_606717
  var valid_606718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606718 = validateParameter(valid_606718, JString, required = false,
                                 default = nil)
  if valid_606718 != nil:
    section.add "X-Amz-Content-Sha256", valid_606718
  var valid_606719 = header.getOrDefault("X-Amz-Date")
  valid_606719 = validateParameter(valid_606719, JString, required = false,
                                 default = nil)
  if valid_606719 != nil:
    section.add "X-Amz-Date", valid_606719
  var valid_606720 = header.getOrDefault("X-Amz-Credential")
  valid_606720 = validateParameter(valid_606720, JString, required = false,
                                 default = nil)
  if valid_606720 != nil:
    section.add "X-Amz-Credential", valid_606720
  var valid_606721 = header.getOrDefault("X-Amz-Security-Token")
  valid_606721 = validateParameter(valid_606721, JString, required = false,
                                 default = nil)
  if valid_606721 != nil:
    section.add "X-Amz-Security-Token", valid_606721
  var valid_606722 = header.getOrDefault("X-Amz-Algorithm")
  valid_606722 = validateParameter(valid_606722, JString, required = false,
                                 default = nil)
  if valid_606722 != nil:
    section.add "X-Amz-Algorithm", valid_606722
  var valid_606723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606723 = validateParameter(valid_606723, JString, required = false,
                                 default = nil)
  if valid_606723 != nil:
    section.add "X-Amz-SignedHeaders", valid_606723
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606725: Call_CreateUserImportJob_606713; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates the user import job.
  ## 
  let valid = call_606725.validator(path, query, header, formData, body)
  let scheme = call_606725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606725.url(scheme.get, call_606725.host, call_606725.base,
                         call_606725.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606725, url, valid)

proc call*(call_606726: Call_CreateUserImportJob_606713; body: JsonNode): Recallable =
  ## createUserImportJob
  ## Creates the user import job.
  ##   body: JObject (required)
  var body_606727 = newJObject()
  if body != nil:
    body_606727 = body
  result = call_606726.call(nil, nil, nil, nil, body_606727)

var createUserImportJob* = Call_CreateUserImportJob_606713(
    name: "createUserImportJob", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserImportJob",
    validator: validate_CreateUserImportJob_606714, base: "/",
    url: url_CreateUserImportJob_606715, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserPool_606728 = ref object of OpenApiRestCall_605589
proc url_CreateUserPool_606730(protocol: Scheme; host: string; base: string;
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

proc validate_CreateUserPool_606729(path: JsonNode; query: JsonNode;
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
  var valid_606731 = header.getOrDefault("X-Amz-Target")
  valid_606731 = validateParameter(valid_606731, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserPool"))
  if valid_606731 != nil:
    section.add "X-Amz-Target", valid_606731
  var valid_606732 = header.getOrDefault("X-Amz-Signature")
  valid_606732 = validateParameter(valid_606732, JString, required = false,
                                 default = nil)
  if valid_606732 != nil:
    section.add "X-Amz-Signature", valid_606732
  var valid_606733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606733 = validateParameter(valid_606733, JString, required = false,
                                 default = nil)
  if valid_606733 != nil:
    section.add "X-Amz-Content-Sha256", valid_606733
  var valid_606734 = header.getOrDefault("X-Amz-Date")
  valid_606734 = validateParameter(valid_606734, JString, required = false,
                                 default = nil)
  if valid_606734 != nil:
    section.add "X-Amz-Date", valid_606734
  var valid_606735 = header.getOrDefault("X-Amz-Credential")
  valid_606735 = validateParameter(valid_606735, JString, required = false,
                                 default = nil)
  if valid_606735 != nil:
    section.add "X-Amz-Credential", valid_606735
  var valid_606736 = header.getOrDefault("X-Amz-Security-Token")
  valid_606736 = validateParameter(valid_606736, JString, required = false,
                                 default = nil)
  if valid_606736 != nil:
    section.add "X-Amz-Security-Token", valid_606736
  var valid_606737 = header.getOrDefault("X-Amz-Algorithm")
  valid_606737 = validateParameter(valid_606737, JString, required = false,
                                 default = nil)
  if valid_606737 != nil:
    section.add "X-Amz-Algorithm", valid_606737
  var valid_606738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606738 = validateParameter(valid_606738, JString, required = false,
                                 default = nil)
  if valid_606738 != nil:
    section.add "X-Amz-SignedHeaders", valid_606738
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606740: Call_CreateUserPool_606728; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon Cognito user pool and sets the password policy for the pool.
  ## 
  let valid = call_606740.validator(path, query, header, formData, body)
  let scheme = call_606740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606740.url(scheme.get, call_606740.host, call_606740.base,
                         call_606740.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606740, url, valid)

proc call*(call_606741: Call_CreateUserPool_606728; body: JsonNode): Recallable =
  ## createUserPool
  ## Creates a new Amazon Cognito user pool and sets the password policy for the pool.
  ##   body: JObject (required)
  var body_606742 = newJObject()
  if body != nil:
    body_606742 = body
  result = call_606741.call(nil, nil, nil, nil, body_606742)

var createUserPool* = Call_CreateUserPool_606728(name: "createUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserPool",
    validator: validate_CreateUserPool_606729, base: "/", url: url_CreateUserPool_606730,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserPoolClient_606743 = ref object of OpenApiRestCall_605589
proc url_CreateUserPoolClient_606745(protocol: Scheme; host: string; base: string;
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

proc validate_CreateUserPoolClient_606744(path: JsonNode; query: JsonNode;
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
  var valid_606746 = header.getOrDefault("X-Amz-Target")
  valid_606746 = validateParameter(valid_606746, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserPoolClient"))
  if valid_606746 != nil:
    section.add "X-Amz-Target", valid_606746
  var valid_606747 = header.getOrDefault("X-Amz-Signature")
  valid_606747 = validateParameter(valid_606747, JString, required = false,
                                 default = nil)
  if valid_606747 != nil:
    section.add "X-Amz-Signature", valid_606747
  var valid_606748 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606748 = validateParameter(valid_606748, JString, required = false,
                                 default = nil)
  if valid_606748 != nil:
    section.add "X-Amz-Content-Sha256", valid_606748
  var valid_606749 = header.getOrDefault("X-Amz-Date")
  valid_606749 = validateParameter(valid_606749, JString, required = false,
                                 default = nil)
  if valid_606749 != nil:
    section.add "X-Amz-Date", valid_606749
  var valid_606750 = header.getOrDefault("X-Amz-Credential")
  valid_606750 = validateParameter(valid_606750, JString, required = false,
                                 default = nil)
  if valid_606750 != nil:
    section.add "X-Amz-Credential", valid_606750
  var valid_606751 = header.getOrDefault("X-Amz-Security-Token")
  valid_606751 = validateParameter(valid_606751, JString, required = false,
                                 default = nil)
  if valid_606751 != nil:
    section.add "X-Amz-Security-Token", valid_606751
  var valid_606752 = header.getOrDefault("X-Amz-Algorithm")
  valid_606752 = validateParameter(valid_606752, JString, required = false,
                                 default = nil)
  if valid_606752 != nil:
    section.add "X-Amz-Algorithm", valid_606752
  var valid_606753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606753 = validateParameter(valid_606753, JString, required = false,
                                 default = nil)
  if valid_606753 != nil:
    section.add "X-Amz-SignedHeaders", valid_606753
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606755: Call_CreateUserPoolClient_606743; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates the user pool client.
  ## 
  let valid = call_606755.validator(path, query, header, formData, body)
  let scheme = call_606755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606755.url(scheme.get, call_606755.host, call_606755.base,
                         call_606755.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606755, url, valid)

proc call*(call_606756: Call_CreateUserPoolClient_606743; body: JsonNode): Recallable =
  ## createUserPoolClient
  ## Creates the user pool client.
  ##   body: JObject (required)
  var body_606757 = newJObject()
  if body != nil:
    body_606757 = body
  result = call_606756.call(nil, nil, nil, nil, body_606757)

var createUserPoolClient* = Call_CreateUserPoolClient_606743(
    name: "createUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserPoolClient",
    validator: validate_CreateUserPoolClient_606744, base: "/",
    url: url_CreateUserPoolClient_606745, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserPoolDomain_606758 = ref object of OpenApiRestCall_605589
proc url_CreateUserPoolDomain_606760(protocol: Scheme; host: string; base: string;
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

proc validate_CreateUserPoolDomain_606759(path: JsonNode; query: JsonNode;
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
  var valid_606761 = header.getOrDefault("X-Amz-Target")
  valid_606761 = validateParameter(valid_606761, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserPoolDomain"))
  if valid_606761 != nil:
    section.add "X-Amz-Target", valid_606761
  var valid_606762 = header.getOrDefault("X-Amz-Signature")
  valid_606762 = validateParameter(valid_606762, JString, required = false,
                                 default = nil)
  if valid_606762 != nil:
    section.add "X-Amz-Signature", valid_606762
  var valid_606763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606763 = validateParameter(valid_606763, JString, required = false,
                                 default = nil)
  if valid_606763 != nil:
    section.add "X-Amz-Content-Sha256", valid_606763
  var valid_606764 = header.getOrDefault("X-Amz-Date")
  valid_606764 = validateParameter(valid_606764, JString, required = false,
                                 default = nil)
  if valid_606764 != nil:
    section.add "X-Amz-Date", valid_606764
  var valid_606765 = header.getOrDefault("X-Amz-Credential")
  valid_606765 = validateParameter(valid_606765, JString, required = false,
                                 default = nil)
  if valid_606765 != nil:
    section.add "X-Amz-Credential", valid_606765
  var valid_606766 = header.getOrDefault("X-Amz-Security-Token")
  valid_606766 = validateParameter(valid_606766, JString, required = false,
                                 default = nil)
  if valid_606766 != nil:
    section.add "X-Amz-Security-Token", valid_606766
  var valid_606767 = header.getOrDefault("X-Amz-Algorithm")
  valid_606767 = validateParameter(valid_606767, JString, required = false,
                                 default = nil)
  if valid_606767 != nil:
    section.add "X-Amz-Algorithm", valid_606767
  var valid_606768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606768 = validateParameter(valid_606768, JString, required = false,
                                 default = nil)
  if valid_606768 != nil:
    section.add "X-Amz-SignedHeaders", valid_606768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606770: Call_CreateUserPoolDomain_606758; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new domain for a user pool.
  ## 
  let valid = call_606770.validator(path, query, header, formData, body)
  let scheme = call_606770.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606770.url(scheme.get, call_606770.host, call_606770.base,
                         call_606770.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606770, url, valid)

proc call*(call_606771: Call_CreateUserPoolDomain_606758; body: JsonNode): Recallable =
  ## createUserPoolDomain
  ## Creates a new domain for a user pool.
  ##   body: JObject (required)
  var body_606772 = newJObject()
  if body != nil:
    body_606772 = body
  result = call_606771.call(nil, nil, nil, nil, body_606772)

var createUserPoolDomain* = Call_CreateUserPoolDomain_606758(
    name: "createUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserPoolDomain",
    validator: validate_CreateUserPoolDomain_606759, base: "/",
    url: url_CreateUserPoolDomain_606760, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_606773 = ref object of OpenApiRestCall_605589
proc url_DeleteGroup_606775(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGroup_606774(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606776 = header.getOrDefault("X-Amz-Target")
  valid_606776 = validateParameter(valid_606776, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteGroup"))
  if valid_606776 != nil:
    section.add "X-Amz-Target", valid_606776
  var valid_606777 = header.getOrDefault("X-Amz-Signature")
  valid_606777 = validateParameter(valid_606777, JString, required = false,
                                 default = nil)
  if valid_606777 != nil:
    section.add "X-Amz-Signature", valid_606777
  var valid_606778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606778 = validateParameter(valid_606778, JString, required = false,
                                 default = nil)
  if valid_606778 != nil:
    section.add "X-Amz-Content-Sha256", valid_606778
  var valid_606779 = header.getOrDefault("X-Amz-Date")
  valid_606779 = validateParameter(valid_606779, JString, required = false,
                                 default = nil)
  if valid_606779 != nil:
    section.add "X-Amz-Date", valid_606779
  var valid_606780 = header.getOrDefault("X-Amz-Credential")
  valid_606780 = validateParameter(valid_606780, JString, required = false,
                                 default = nil)
  if valid_606780 != nil:
    section.add "X-Amz-Credential", valid_606780
  var valid_606781 = header.getOrDefault("X-Amz-Security-Token")
  valid_606781 = validateParameter(valid_606781, JString, required = false,
                                 default = nil)
  if valid_606781 != nil:
    section.add "X-Amz-Security-Token", valid_606781
  var valid_606782 = header.getOrDefault("X-Amz-Algorithm")
  valid_606782 = validateParameter(valid_606782, JString, required = false,
                                 default = nil)
  if valid_606782 != nil:
    section.add "X-Amz-Algorithm", valid_606782
  var valid_606783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606783 = validateParameter(valid_606783, JString, required = false,
                                 default = nil)
  if valid_606783 != nil:
    section.add "X-Amz-SignedHeaders", valid_606783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606785: Call_DeleteGroup_606773; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a group. Currently only groups with no members can be deleted.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_606785.validator(path, query, header, formData, body)
  let scheme = call_606785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606785.url(scheme.get, call_606785.host, call_606785.base,
                         call_606785.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606785, url, valid)

proc call*(call_606786: Call_DeleteGroup_606773; body: JsonNode): Recallable =
  ## deleteGroup
  ## <p>Deletes a group. Currently only groups with no members can be deleted.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_606787 = newJObject()
  if body != nil:
    body_606787 = body
  result = call_606786.call(nil, nil, nil, nil, body_606787)

var deleteGroup* = Call_DeleteGroup_606773(name: "deleteGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteGroup",
                                        validator: validate_DeleteGroup_606774,
                                        base: "/", url: url_DeleteGroup_606775,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIdentityProvider_606788 = ref object of OpenApiRestCall_605589
proc url_DeleteIdentityProvider_606790(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteIdentityProvider_606789(path: JsonNode; query: JsonNode;
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
  var valid_606791 = header.getOrDefault("X-Amz-Target")
  valid_606791 = validateParameter(valid_606791, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteIdentityProvider"))
  if valid_606791 != nil:
    section.add "X-Amz-Target", valid_606791
  var valid_606792 = header.getOrDefault("X-Amz-Signature")
  valid_606792 = validateParameter(valid_606792, JString, required = false,
                                 default = nil)
  if valid_606792 != nil:
    section.add "X-Amz-Signature", valid_606792
  var valid_606793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606793 = validateParameter(valid_606793, JString, required = false,
                                 default = nil)
  if valid_606793 != nil:
    section.add "X-Amz-Content-Sha256", valid_606793
  var valid_606794 = header.getOrDefault("X-Amz-Date")
  valid_606794 = validateParameter(valid_606794, JString, required = false,
                                 default = nil)
  if valid_606794 != nil:
    section.add "X-Amz-Date", valid_606794
  var valid_606795 = header.getOrDefault("X-Amz-Credential")
  valid_606795 = validateParameter(valid_606795, JString, required = false,
                                 default = nil)
  if valid_606795 != nil:
    section.add "X-Amz-Credential", valid_606795
  var valid_606796 = header.getOrDefault("X-Amz-Security-Token")
  valid_606796 = validateParameter(valid_606796, JString, required = false,
                                 default = nil)
  if valid_606796 != nil:
    section.add "X-Amz-Security-Token", valid_606796
  var valid_606797 = header.getOrDefault("X-Amz-Algorithm")
  valid_606797 = validateParameter(valid_606797, JString, required = false,
                                 default = nil)
  if valid_606797 != nil:
    section.add "X-Amz-Algorithm", valid_606797
  var valid_606798 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606798 = validateParameter(valid_606798, JString, required = false,
                                 default = nil)
  if valid_606798 != nil:
    section.add "X-Amz-SignedHeaders", valid_606798
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606800: Call_DeleteIdentityProvider_606788; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an identity provider for a user pool.
  ## 
  let valid = call_606800.validator(path, query, header, formData, body)
  let scheme = call_606800.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606800.url(scheme.get, call_606800.host, call_606800.base,
                         call_606800.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606800, url, valid)

proc call*(call_606801: Call_DeleteIdentityProvider_606788; body: JsonNode): Recallable =
  ## deleteIdentityProvider
  ## Deletes an identity provider for a user pool.
  ##   body: JObject (required)
  var body_606802 = newJObject()
  if body != nil:
    body_606802 = body
  result = call_606801.call(nil, nil, nil, nil, body_606802)

var deleteIdentityProvider* = Call_DeleteIdentityProvider_606788(
    name: "deleteIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteIdentityProvider",
    validator: validate_DeleteIdentityProvider_606789, base: "/",
    url: url_DeleteIdentityProvider_606790, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceServer_606803 = ref object of OpenApiRestCall_605589
proc url_DeleteResourceServer_606805(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteResourceServer_606804(path: JsonNode; query: JsonNode;
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
  var valid_606806 = header.getOrDefault("X-Amz-Target")
  valid_606806 = validateParameter(valid_606806, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteResourceServer"))
  if valid_606806 != nil:
    section.add "X-Amz-Target", valid_606806
  var valid_606807 = header.getOrDefault("X-Amz-Signature")
  valid_606807 = validateParameter(valid_606807, JString, required = false,
                                 default = nil)
  if valid_606807 != nil:
    section.add "X-Amz-Signature", valid_606807
  var valid_606808 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606808 = validateParameter(valid_606808, JString, required = false,
                                 default = nil)
  if valid_606808 != nil:
    section.add "X-Amz-Content-Sha256", valid_606808
  var valid_606809 = header.getOrDefault("X-Amz-Date")
  valid_606809 = validateParameter(valid_606809, JString, required = false,
                                 default = nil)
  if valid_606809 != nil:
    section.add "X-Amz-Date", valid_606809
  var valid_606810 = header.getOrDefault("X-Amz-Credential")
  valid_606810 = validateParameter(valid_606810, JString, required = false,
                                 default = nil)
  if valid_606810 != nil:
    section.add "X-Amz-Credential", valid_606810
  var valid_606811 = header.getOrDefault("X-Amz-Security-Token")
  valid_606811 = validateParameter(valid_606811, JString, required = false,
                                 default = nil)
  if valid_606811 != nil:
    section.add "X-Amz-Security-Token", valid_606811
  var valid_606812 = header.getOrDefault("X-Amz-Algorithm")
  valid_606812 = validateParameter(valid_606812, JString, required = false,
                                 default = nil)
  if valid_606812 != nil:
    section.add "X-Amz-Algorithm", valid_606812
  var valid_606813 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606813 = validateParameter(valid_606813, JString, required = false,
                                 default = nil)
  if valid_606813 != nil:
    section.add "X-Amz-SignedHeaders", valid_606813
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606815: Call_DeleteResourceServer_606803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a resource server.
  ## 
  let valid = call_606815.validator(path, query, header, formData, body)
  let scheme = call_606815.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606815.url(scheme.get, call_606815.host, call_606815.base,
                         call_606815.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606815, url, valid)

proc call*(call_606816: Call_DeleteResourceServer_606803; body: JsonNode): Recallable =
  ## deleteResourceServer
  ## Deletes a resource server.
  ##   body: JObject (required)
  var body_606817 = newJObject()
  if body != nil:
    body_606817 = body
  result = call_606816.call(nil, nil, nil, nil, body_606817)

var deleteResourceServer* = Call_DeleteResourceServer_606803(
    name: "deleteResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteResourceServer",
    validator: validate_DeleteResourceServer_606804, base: "/",
    url: url_DeleteResourceServer_606805, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_606818 = ref object of OpenApiRestCall_605589
proc url_DeleteUser_606820(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteUser_606819(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606821 = header.getOrDefault("X-Amz-Target")
  valid_606821 = validateParameter(valid_606821, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUser"))
  if valid_606821 != nil:
    section.add "X-Amz-Target", valid_606821
  var valid_606822 = header.getOrDefault("X-Amz-Signature")
  valid_606822 = validateParameter(valid_606822, JString, required = false,
                                 default = nil)
  if valid_606822 != nil:
    section.add "X-Amz-Signature", valid_606822
  var valid_606823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606823 = validateParameter(valid_606823, JString, required = false,
                                 default = nil)
  if valid_606823 != nil:
    section.add "X-Amz-Content-Sha256", valid_606823
  var valid_606824 = header.getOrDefault("X-Amz-Date")
  valid_606824 = validateParameter(valid_606824, JString, required = false,
                                 default = nil)
  if valid_606824 != nil:
    section.add "X-Amz-Date", valid_606824
  var valid_606825 = header.getOrDefault("X-Amz-Credential")
  valid_606825 = validateParameter(valid_606825, JString, required = false,
                                 default = nil)
  if valid_606825 != nil:
    section.add "X-Amz-Credential", valid_606825
  var valid_606826 = header.getOrDefault("X-Amz-Security-Token")
  valid_606826 = validateParameter(valid_606826, JString, required = false,
                                 default = nil)
  if valid_606826 != nil:
    section.add "X-Amz-Security-Token", valid_606826
  var valid_606827 = header.getOrDefault("X-Amz-Algorithm")
  valid_606827 = validateParameter(valid_606827, JString, required = false,
                                 default = nil)
  if valid_606827 != nil:
    section.add "X-Amz-Algorithm", valid_606827
  var valid_606828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606828 = validateParameter(valid_606828, JString, required = false,
                                 default = nil)
  if valid_606828 != nil:
    section.add "X-Amz-SignedHeaders", valid_606828
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606830: Call_DeleteUser_606818; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a user to delete himself or herself.
  ## 
  let valid = call_606830.validator(path, query, header, formData, body)
  let scheme = call_606830.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606830.url(scheme.get, call_606830.host, call_606830.base,
                         call_606830.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606830, url, valid)

proc call*(call_606831: Call_DeleteUser_606818; body: JsonNode): Recallable =
  ## deleteUser
  ## Allows a user to delete himself or herself.
  ##   body: JObject (required)
  var body_606832 = newJObject()
  if body != nil:
    body_606832 = body
  result = call_606831.call(nil, nil, nil, nil, body_606832)

var deleteUser* = Call_DeleteUser_606818(name: "deleteUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUser",
                                      validator: validate_DeleteUser_606819,
                                      base: "/", url: url_DeleteUser_606820,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserAttributes_606833 = ref object of OpenApiRestCall_605589
proc url_DeleteUserAttributes_606835(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUserAttributes_606834(path: JsonNode; query: JsonNode;
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
  var valid_606836 = header.getOrDefault("X-Amz-Target")
  valid_606836 = validateParameter(valid_606836, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUserAttributes"))
  if valid_606836 != nil:
    section.add "X-Amz-Target", valid_606836
  var valid_606837 = header.getOrDefault("X-Amz-Signature")
  valid_606837 = validateParameter(valid_606837, JString, required = false,
                                 default = nil)
  if valid_606837 != nil:
    section.add "X-Amz-Signature", valid_606837
  var valid_606838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606838 = validateParameter(valid_606838, JString, required = false,
                                 default = nil)
  if valid_606838 != nil:
    section.add "X-Amz-Content-Sha256", valid_606838
  var valid_606839 = header.getOrDefault("X-Amz-Date")
  valid_606839 = validateParameter(valid_606839, JString, required = false,
                                 default = nil)
  if valid_606839 != nil:
    section.add "X-Amz-Date", valid_606839
  var valid_606840 = header.getOrDefault("X-Amz-Credential")
  valid_606840 = validateParameter(valid_606840, JString, required = false,
                                 default = nil)
  if valid_606840 != nil:
    section.add "X-Amz-Credential", valid_606840
  var valid_606841 = header.getOrDefault("X-Amz-Security-Token")
  valid_606841 = validateParameter(valid_606841, JString, required = false,
                                 default = nil)
  if valid_606841 != nil:
    section.add "X-Amz-Security-Token", valid_606841
  var valid_606842 = header.getOrDefault("X-Amz-Algorithm")
  valid_606842 = validateParameter(valid_606842, JString, required = false,
                                 default = nil)
  if valid_606842 != nil:
    section.add "X-Amz-Algorithm", valid_606842
  var valid_606843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606843 = validateParameter(valid_606843, JString, required = false,
                                 default = nil)
  if valid_606843 != nil:
    section.add "X-Amz-SignedHeaders", valid_606843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606845: Call_DeleteUserAttributes_606833; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the attributes for a user.
  ## 
  let valid = call_606845.validator(path, query, header, formData, body)
  let scheme = call_606845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606845.url(scheme.get, call_606845.host, call_606845.base,
                         call_606845.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606845, url, valid)

proc call*(call_606846: Call_DeleteUserAttributes_606833; body: JsonNode): Recallable =
  ## deleteUserAttributes
  ## Deletes the attributes for a user.
  ##   body: JObject (required)
  var body_606847 = newJObject()
  if body != nil:
    body_606847 = body
  result = call_606846.call(nil, nil, nil, nil, body_606847)

var deleteUserAttributes* = Call_DeleteUserAttributes_606833(
    name: "deleteUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserAttributes",
    validator: validate_DeleteUserAttributes_606834, base: "/",
    url: url_DeleteUserAttributes_606835, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserPool_606848 = ref object of OpenApiRestCall_605589
proc url_DeleteUserPool_606850(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUserPool_606849(path: JsonNode; query: JsonNode;
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
  var valid_606851 = header.getOrDefault("X-Amz-Target")
  valid_606851 = validateParameter(valid_606851, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUserPool"))
  if valid_606851 != nil:
    section.add "X-Amz-Target", valid_606851
  var valid_606852 = header.getOrDefault("X-Amz-Signature")
  valid_606852 = validateParameter(valid_606852, JString, required = false,
                                 default = nil)
  if valid_606852 != nil:
    section.add "X-Amz-Signature", valid_606852
  var valid_606853 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606853 = validateParameter(valid_606853, JString, required = false,
                                 default = nil)
  if valid_606853 != nil:
    section.add "X-Amz-Content-Sha256", valid_606853
  var valid_606854 = header.getOrDefault("X-Amz-Date")
  valid_606854 = validateParameter(valid_606854, JString, required = false,
                                 default = nil)
  if valid_606854 != nil:
    section.add "X-Amz-Date", valid_606854
  var valid_606855 = header.getOrDefault("X-Amz-Credential")
  valid_606855 = validateParameter(valid_606855, JString, required = false,
                                 default = nil)
  if valid_606855 != nil:
    section.add "X-Amz-Credential", valid_606855
  var valid_606856 = header.getOrDefault("X-Amz-Security-Token")
  valid_606856 = validateParameter(valid_606856, JString, required = false,
                                 default = nil)
  if valid_606856 != nil:
    section.add "X-Amz-Security-Token", valid_606856
  var valid_606857 = header.getOrDefault("X-Amz-Algorithm")
  valid_606857 = validateParameter(valid_606857, JString, required = false,
                                 default = nil)
  if valid_606857 != nil:
    section.add "X-Amz-Algorithm", valid_606857
  var valid_606858 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606858 = validateParameter(valid_606858, JString, required = false,
                                 default = nil)
  if valid_606858 != nil:
    section.add "X-Amz-SignedHeaders", valid_606858
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606860: Call_DeleteUserPool_606848; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Amazon Cognito user pool.
  ## 
  let valid = call_606860.validator(path, query, header, formData, body)
  let scheme = call_606860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606860.url(scheme.get, call_606860.host, call_606860.base,
                         call_606860.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606860, url, valid)

proc call*(call_606861: Call_DeleteUserPool_606848; body: JsonNode): Recallable =
  ## deleteUserPool
  ## Deletes the specified Amazon Cognito user pool.
  ##   body: JObject (required)
  var body_606862 = newJObject()
  if body != nil:
    body_606862 = body
  result = call_606861.call(nil, nil, nil, nil, body_606862)

var deleteUserPool* = Call_DeleteUserPool_606848(name: "deleteUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserPool",
    validator: validate_DeleteUserPool_606849, base: "/", url: url_DeleteUserPool_606850,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserPoolClient_606863 = ref object of OpenApiRestCall_605589
proc url_DeleteUserPoolClient_606865(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUserPoolClient_606864(path: JsonNode; query: JsonNode;
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
  var valid_606866 = header.getOrDefault("X-Amz-Target")
  valid_606866 = validateParameter(valid_606866, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUserPoolClient"))
  if valid_606866 != nil:
    section.add "X-Amz-Target", valid_606866
  var valid_606867 = header.getOrDefault("X-Amz-Signature")
  valid_606867 = validateParameter(valid_606867, JString, required = false,
                                 default = nil)
  if valid_606867 != nil:
    section.add "X-Amz-Signature", valid_606867
  var valid_606868 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606868 = validateParameter(valid_606868, JString, required = false,
                                 default = nil)
  if valid_606868 != nil:
    section.add "X-Amz-Content-Sha256", valid_606868
  var valid_606869 = header.getOrDefault("X-Amz-Date")
  valid_606869 = validateParameter(valid_606869, JString, required = false,
                                 default = nil)
  if valid_606869 != nil:
    section.add "X-Amz-Date", valid_606869
  var valid_606870 = header.getOrDefault("X-Amz-Credential")
  valid_606870 = validateParameter(valid_606870, JString, required = false,
                                 default = nil)
  if valid_606870 != nil:
    section.add "X-Amz-Credential", valid_606870
  var valid_606871 = header.getOrDefault("X-Amz-Security-Token")
  valid_606871 = validateParameter(valid_606871, JString, required = false,
                                 default = nil)
  if valid_606871 != nil:
    section.add "X-Amz-Security-Token", valid_606871
  var valid_606872 = header.getOrDefault("X-Amz-Algorithm")
  valid_606872 = validateParameter(valid_606872, JString, required = false,
                                 default = nil)
  if valid_606872 != nil:
    section.add "X-Amz-Algorithm", valid_606872
  var valid_606873 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606873 = validateParameter(valid_606873, JString, required = false,
                                 default = nil)
  if valid_606873 != nil:
    section.add "X-Amz-SignedHeaders", valid_606873
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606875: Call_DeleteUserPoolClient_606863; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows the developer to delete the user pool client.
  ## 
  let valid = call_606875.validator(path, query, header, formData, body)
  let scheme = call_606875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606875.url(scheme.get, call_606875.host, call_606875.base,
                         call_606875.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606875, url, valid)

proc call*(call_606876: Call_DeleteUserPoolClient_606863; body: JsonNode): Recallable =
  ## deleteUserPoolClient
  ## Allows the developer to delete the user pool client.
  ##   body: JObject (required)
  var body_606877 = newJObject()
  if body != nil:
    body_606877 = body
  result = call_606876.call(nil, nil, nil, nil, body_606877)

var deleteUserPoolClient* = Call_DeleteUserPoolClient_606863(
    name: "deleteUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserPoolClient",
    validator: validate_DeleteUserPoolClient_606864, base: "/",
    url: url_DeleteUserPoolClient_606865, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserPoolDomain_606878 = ref object of OpenApiRestCall_605589
proc url_DeleteUserPoolDomain_606880(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUserPoolDomain_606879(path: JsonNode; query: JsonNode;
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
  var valid_606881 = header.getOrDefault("X-Amz-Target")
  valid_606881 = validateParameter(valid_606881, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUserPoolDomain"))
  if valid_606881 != nil:
    section.add "X-Amz-Target", valid_606881
  var valid_606882 = header.getOrDefault("X-Amz-Signature")
  valid_606882 = validateParameter(valid_606882, JString, required = false,
                                 default = nil)
  if valid_606882 != nil:
    section.add "X-Amz-Signature", valid_606882
  var valid_606883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606883 = validateParameter(valid_606883, JString, required = false,
                                 default = nil)
  if valid_606883 != nil:
    section.add "X-Amz-Content-Sha256", valid_606883
  var valid_606884 = header.getOrDefault("X-Amz-Date")
  valid_606884 = validateParameter(valid_606884, JString, required = false,
                                 default = nil)
  if valid_606884 != nil:
    section.add "X-Amz-Date", valid_606884
  var valid_606885 = header.getOrDefault("X-Amz-Credential")
  valid_606885 = validateParameter(valid_606885, JString, required = false,
                                 default = nil)
  if valid_606885 != nil:
    section.add "X-Amz-Credential", valid_606885
  var valid_606886 = header.getOrDefault("X-Amz-Security-Token")
  valid_606886 = validateParameter(valid_606886, JString, required = false,
                                 default = nil)
  if valid_606886 != nil:
    section.add "X-Amz-Security-Token", valid_606886
  var valid_606887 = header.getOrDefault("X-Amz-Algorithm")
  valid_606887 = validateParameter(valid_606887, JString, required = false,
                                 default = nil)
  if valid_606887 != nil:
    section.add "X-Amz-Algorithm", valid_606887
  var valid_606888 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606888 = validateParameter(valid_606888, JString, required = false,
                                 default = nil)
  if valid_606888 != nil:
    section.add "X-Amz-SignedHeaders", valid_606888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606890: Call_DeleteUserPoolDomain_606878; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a domain for a user pool.
  ## 
  let valid = call_606890.validator(path, query, header, formData, body)
  let scheme = call_606890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606890.url(scheme.get, call_606890.host, call_606890.base,
                         call_606890.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606890, url, valid)

proc call*(call_606891: Call_DeleteUserPoolDomain_606878; body: JsonNode): Recallable =
  ## deleteUserPoolDomain
  ## Deletes a domain for a user pool.
  ##   body: JObject (required)
  var body_606892 = newJObject()
  if body != nil:
    body_606892 = body
  result = call_606891.call(nil, nil, nil, nil, body_606892)

var deleteUserPoolDomain* = Call_DeleteUserPoolDomain_606878(
    name: "deleteUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserPoolDomain",
    validator: validate_DeleteUserPoolDomain_606879, base: "/",
    url: url_DeleteUserPoolDomain_606880, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentityProvider_606893 = ref object of OpenApiRestCall_605589
proc url_DescribeIdentityProvider_606895(protocol: Scheme; host: string;
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

proc validate_DescribeIdentityProvider_606894(path: JsonNode; query: JsonNode;
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
  var valid_606896 = header.getOrDefault("X-Amz-Target")
  valid_606896 = validateParameter(valid_606896, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeIdentityProvider"))
  if valid_606896 != nil:
    section.add "X-Amz-Target", valid_606896
  var valid_606897 = header.getOrDefault("X-Amz-Signature")
  valid_606897 = validateParameter(valid_606897, JString, required = false,
                                 default = nil)
  if valid_606897 != nil:
    section.add "X-Amz-Signature", valid_606897
  var valid_606898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606898 = validateParameter(valid_606898, JString, required = false,
                                 default = nil)
  if valid_606898 != nil:
    section.add "X-Amz-Content-Sha256", valid_606898
  var valid_606899 = header.getOrDefault("X-Amz-Date")
  valid_606899 = validateParameter(valid_606899, JString, required = false,
                                 default = nil)
  if valid_606899 != nil:
    section.add "X-Amz-Date", valid_606899
  var valid_606900 = header.getOrDefault("X-Amz-Credential")
  valid_606900 = validateParameter(valid_606900, JString, required = false,
                                 default = nil)
  if valid_606900 != nil:
    section.add "X-Amz-Credential", valid_606900
  var valid_606901 = header.getOrDefault("X-Amz-Security-Token")
  valid_606901 = validateParameter(valid_606901, JString, required = false,
                                 default = nil)
  if valid_606901 != nil:
    section.add "X-Amz-Security-Token", valid_606901
  var valid_606902 = header.getOrDefault("X-Amz-Algorithm")
  valid_606902 = validateParameter(valid_606902, JString, required = false,
                                 default = nil)
  if valid_606902 != nil:
    section.add "X-Amz-Algorithm", valid_606902
  var valid_606903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606903 = validateParameter(valid_606903, JString, required = false,
                                 default = nil)
  if valid_606903 != nil:
    section.add "X-Amz-SignedHeaders", valid_606903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606905: Call_DescribeIdentityProvider_606893; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specific identity provider.
  ## 
  let valid = call_606905.validator(path, query, header, formData, body)
  let scheme = call_606905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606905.url(scheme.get, call_606905.host, call_606905.base,
                         call_606905.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606905, url, valid)

proc call*(call_606906: Call_DescribeIdentityProvider_606893; body: JsonNode): Recallable =
  ## describeIdentityProvider
  ## Gets information about a specific identity provider.
  ##   body: JObject (required)
  var body_606907 = newJObject()
  if body != nil:
    body_606907 = body
  result = call_606906.call(nil, nil, nil, nil, body_606907)

var describeIdentityProvider* = Call_DescribeIdentityProvider_606893(
    name: "describeIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeIdentityProvider",
    validator: validate_DescribeIdentityProvider_606894, base: "/",
    url: url_DescribeIdentityProvider_606895, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResourceServer_606908 = ref object of OpenApiRestCall_605589
proc url_DescribeResourceServer_606910(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeResourceServer_606909(path: JsonNode; query: JsonNode;
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
  var valid_606911 = header.getOrDefault("X-Amz-Target")
  valid_606911 = validateParameter(valid_606911, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeResourceServer"))
  if valid_606911 != nil:
    section.add "X-Amz-Target", valid_606911
  var valid_606912 = header.getOrDefault("X-Amz-Signature")
  valid_606912 = validateParameter(valid_606912, JString, required = false,
                                 default = nil)
  if valid_606912 != nil:
    section.add "X-Amz-Signature", valid_606912
  var valid_606913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606913 = validateParameter(valid_606913, JString, required = false,
                                 default = nil)
  if valid_606913 != nil:
    section.add "X-Amz-Content-Sha256", valid_606913
  var valid_606914 = header.getOrDefault("X-Amz-Date")
  valid_606914 = validateParameter(valid_606914, JString, required = false,
                                 default = nil)
  if valid_606914 != nil:
    section.add "X-Amz-Date", valid_606914
  var valid_606915 = header.getOrDefault("X-Amz-Credential")
  valid_606915 = validateParameter(valid_606915, JString, required = false,
                                 default = nil)
  if valid_606915 != nil:
    section.add "X-Amz-Credential", valid_606915
  var valid_606916 = header.getOrDefault("X-Amz-Security-Token")
  valid_606916 = validateParameter(valid_606916, JString, required = false,
                                 default = nil)
  if valid_606916 != nil:
    section.add "X-Amz-Security-Token", valid_606916
  var valid_606917 = header.getOrDefault("X-Amz-Algorithm")
  valid_606917 = validateParameter(valid_606917, JString, required = false,
                                 default = nil)
  if valid_606917 != nil:
    section.add "X-Amz-Algorithm", valid_606917
  var valid_606918 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606918 = validateParameter(valid_606918, JString, required = false,
                                 default = nil)
  if valid_606918 != nil:
    section.add "X-Amz-SignedHeaders", valid_606918
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606920: Call_DescribeResourceServer_606908; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a resource server.
  ## 
  let valid = call_606920.validator(path, query, header, formData, body)
  let scheme = call_606920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606920.url(scheme.get, call_606920.host, call_606920.base,
                         call_606920.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606920, url, valid)

proc call*(call_606921: Call_DescribeResourceServer_606908; body: JsonNode): Recallable =
  ## describeResourceServer
  ## Describes a resource server.
  ##   body: JObject (required)
  var body_606922 = newJObject()
  if body != nil:
    body_606922 = body
  result = call_606921.call(nil, nil, nil, nil, body_606922)

var describeResourceServer* = Call_DescribeResourceServer_606908(
    name: "describeResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeResourceServer",
    validator: validate_DescribeResourceServer_606909, base: "/",
    url: url_DescribeResourceServer_606910, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRiskConfiguration_606923 = ref object of OpenApiRestCall_605589
proc url_DescribeRiskConfiguration_606925(protocol: Scheme; host: string;
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

proc validate_DescribeRiskConfiguration_606924(path: JsonNode; query: JsonNode;
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
  var valid_606926 = header.getOrDefault("X-Amz-Target")
  valid_606926 = validateParameter(valid_606926, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeRiskConfiguration"))
  if valid_606926 != nil:
    section.add "X-Amz-Target", valid_606926
  var valid_606927 = header.getOrDefault("X-Amz-Signature")
  valid_606927 = validateParameter(valid_606927, JString, required = false,
                                 default = nil)
  if valid_606927 != nil:
    section.add "X-Amz-Signature", valid_606927
  var valid_606928 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606928 = validateParameter(valid_606928, JString, required = false,
                                 default = nil)
  if valid_606928 != nil:
    section.add "X-Amz-Content-Sha256", valid_606928
  var valid_606929 = header.getOrDefault("X-Amz-Date")
  valid_606929 = validateParameter(valid_606929, JString, required = false,
                                 default = nil)
  if valid_606929 != nil:
    section.add "X-Amz-Date", valid_606929
  var valid_606930 = header.getOrDefault("X-Amz-Credential")
  valid_606930 = validateParameter(valid_606930, JString, required = false,
                                 default = nil)
  if valid_606930 != nil:
    section.add "X-Amz-Credential", valid_606930
  var valid_606931 = header.getOrDefault("X-Amz-Security-Token")
  valid_606931 = validateParameter(valid_606931, JString, required = false,
                                 default = nil)
  if valid_606931 != nil:
    section.add "X-Amz-Security-Token", valid_606931
  var valid_606932 = header.getOrDefault("X-Amz-Algorithm")
  valid_606932 = validateParameter(valid_606932, JString, required = false,
                                 default = nil)
  if valid_606932 != nil:
    section.add "X-Amz-Algorithm", valid_606932
  var valid_606933 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606933 = validateParameter(valid_606933, JString, required = false,
                                 default = nil)
  if valid_606933 != nil:
    section.add "X-Amz-SignedHeaders", valid_606933
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606935: Call_DescribeRiskConfiguration_606923; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the risk configuration.
  ## 
  let valid = call_606935.validator(path, query, header, formData, body)
  let scheme = call_606935.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606935.url(scheme.get, call_606935.host, call_606935.base,
                         call_606935.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606935, url, valid)

proc call*(call_606936: Call_DescribeRiskConfiguration_606923; body: JsonNode): Recallable =
  ## describeRiskConfiguration
  ## Describes the risk configuration.
  ##   body: JObject (required)
  var body_606937 = newJObject()
  if body != nil:
    body_606937 = body
  result = call_606936.call(nil, nil, nil, nil, body_606937)

var describeRiskConfiguration* = Call_DescribeRiskConfiguration_606923(
    name: "describeRiskConfiguration", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeRiskConfiguration",
    validator: validate_DescribeRiskConfiguration_606924, base: "/",
    url: url_DescribeRiskConfiguration_606925,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserImportJob_606938 = ref object of OpenApiRestCall_605589
proc url_DescribeUserImportJob_606940(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUserImportJob_606939(path: JsonNode; query: JsonNode;
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
  var valid_606941 = header.getOrDefault("X-Amz-Target")
  valid_606941 = validateParameter(valid_606941, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserImportJob"))
  if valid_606941 != nil:
    section.add "X-Amz-Target", valid_606941
  var valid_606942 = header.getOrDefault("X-Amz-Signature")
  valid_606942 = validateParameter(valid_606942, JString, required = false,
                                 default = nil)
  if valid_606942 != nil:
    section.add "X-Amz-Signature", valid_606942
  var valid_606943 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606943 = validateParameter(valid_606943, JString, required = false,
                                 default = nil)
  if valid_606943 != nil:
    section.add "X-Amz-Content-Sha256", valid_606943
  var valid_606944 = header.getOrDefault("X-Amz-Date")
  valid_606944 = validateParameter(valid_606944, JString, required = false,
                                 default = nil)
  if valid_606944 != nil:
    section.add "X-Amz-Date", valid_606944
  var valid_606945 = header.getOrDefault("X-Amz-Credential")
  valid_606945 = validateParameter(valid_606945, JString, required = false,
                                 default = nil)
  if valid_606945 != nil:
    section.add "X-Amz-Credential", valid_606945
  var valid_606946 = header.getOrDefault("X-Amz-Security-Token")
  valid_606946 = validateParameter(valid_606946, JString, required = false,
                                 default = nil)
  if valid_606946 != nil:
    section.add "X-Amz-Security-Token", valid_606946
  var valid_606947 = header.getOrDefault("X-Amz-Algorithm")
  valid_606947 = validateParameter(valid_606947, JString, required = false,
                                 default = nil)
  if valid_606947 != nil:
    section.add "X-Amz-Algorithm", valid_606947
  var valid_606948 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606948 = validateParameter(valid_606948, JString, required = false,
                                 default = nil)
  if valid_606948 != nil:
    section.add "X-Amz-SignedHeaders", valid_606948
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606950: Call_DescribeUserImportJob_606938; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the user import job.
  ## 
  let valid = call_606950.validator(path, query, header, formData, body)
  let scheme = call_606950.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606950.url(scheme.get, call_606950.host, call_606950.base,
                         call_606950.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606950, url, valid)

proc call*(call_606951: Call_DescribeUserImportJob_606938; body: JsonNode): Recallable =
  ## describeUserImportJob
  ## Describes the user import job.
  ##   body: JObject (required)
  var body_606952 = newJObject()
  if body != nil:
    body_606952 = body
  result = call_606951.call(nil, nil, nil, nil, body_606952)

var describeUserImportJob* = Call_DescribeUserImportJob_606938(
    name: "describeUserImportJob", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserImportJob",
    validator: validate_DescribeUserImportJob_606939, base: "/",
    url: url_DescribeUserImportJob_606940, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserPool_606953 = ref object of OpenApiRestCall_605589
proc url_DescribeUserPool_606955(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUserPool_606954(path: JsonNode; query: JsonNode;
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
  var valid_606956 = header.getOrDefault("X-Amz-Target")
  valid_606956 = validateParameter(valid_606956, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserPool"))
  if valid_606956 != nil:
    section.add "X-Amz-Target", valid_606956
  var valid_606957 = header.getOrDefault("X-Amz-Signature")
  valid_606957 = validateParameter(valid_606957, JString, required = false,
                                 default = nil)
  if valid_606957 != nil:
    section.add "X-Amz-Signature", valid_606957
  var valid_606958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606958 = validateParameter(valid_606958, JString, required = false,
                                 default = nil)
  if valid_606958 != nil:
    section.add "X-Amz-Content-Sha256", valid_606958
  var valid_606959 = header.getOrDefault("X-Amz-Date")
  valid_606959 = validateParameter(valid_606959, JString, required = false,
                                 default = nil)
  if valid_606959 != nil:
    section.add "X-Amz-Date", valid_606959
  var valid_606960 = header.getOrDefault("X-Amz-Credential")
  valid_606960 = validateParameter(valid_606960, JString, required = false,
                                 default = nil)
  if valid_606960 != nil:
    section.add "X-Amz-Credential", valid_606960
  var valid_606961 = header.getOrDefault("X-Amz-Security-Token")
  valid_606961 = validateParameter(valid_606961, JString, required = false,
                                 default = nil)
  if valid_606961 != nil:
    section.add "X-Amz-Security-Token", valid_606961
  var valid_606962 = header.getOrDefault("X-Amz-Algorithm")
  valid_606962 = validateParameter(valid_606962, JString, required = false,
                                 default = nil)
  if valid_606962 != nil:
    section.add "X-Amz-Algorithm", valid_606962
  var valid_606963 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606963 = validateParameter(valid_606963, JString, required = false,
                                 default = nil)
  if valid_606963 != nil:
    section.add "X-Amz-SignedHeaders", valid_606963
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606965: Call_DescribeUserPool_606953; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the configuration information and metadata of the specified user pool.
  ## 
  let valid = call_606965.validator(path, query, header, formData, body)
  let scheme = call_606965.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606965.url(scheme.get, call_606965.host, call_606965.base,
                         call_606965.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606965, url, valid)

proc call*(call_606966: Call_DescribeUserPool_606953; body: JsonNode): Recallable =
  ## describeUserPool
  ## Returns the configuration information and metadata of the specified user pool.
  ##   body: JObject (required)
  var body_606967 = newJObject()
  if body != nil:
    body_606967 = body
  result = call_606966.call(nil, nil, nil, nil, body_606967)

var describeUserPool* = Call_DescribeUserPool_606953(name: "describeUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserPool",
    validator: validate_DescribeUserPool_606954, base: "/",
    url: url_DescribeUserPool_606955, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserPoolClient_606968 = ref object of OpenApiRestCall_605589
proc url_DescribeUserPoolClient_606970(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUserPoolClient_606969(path: JsonNode; query: JsonNode;
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
  var valid_606971 = header.getOrDefault("X-Amz-Target")
  valid_606971 = validateParameter(valid_606971, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserPoolClient"))
  if valid_606971 != nil:
    section.add "X-Amz-Target", valid_606971
  var valid_606972 = header.getOrDefault("X-Amz-Signature")
  valid_606972 = validateParameter(valid_606972, JString, required = false,
                                 default = nil)
  if valid_606972 != nil:
    section.add "X-Amz-Signature", valid_606972
  var valid_606973 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606973 = validateParameter(valid_606973, JString, required = false,
                                 default = nil)
  if valid_606973 != nil:
    section.add "X-Amz-Content-Sha256", valid_606973
  var valid_606974 = header.getOrDefault("X-Amz-Date")
  valid_606974 = validateParameter(valid_606974, JString, required = false,
                                 default = nil)
  if valid_606974 != nil:
    section.add "X-Amz-Date", valid_606974
  var valid_606975 = header.getOrDefault("X-Amz-Credential")
  valid_606975 = validateParameter(valid_606975, JString, required = false,
                                 default = nil)
  if valid_606975 != nil:
    section.add "X-Amz-Credential", valid_606975
  var valid_606976 = header.getOrDefault("X-Amz-Security-Token")
  valid_606976 = validateParameter(valid_606976, JString, required = false,
                                 default = nil)
  if valid_606976 != nil:
    section.add "X-Amz-Security-Token", valid_606976
  var valid_606977 = header.getOrDefault("X-Amz-Algorithm")
  valid_606977 = validateParameter(valid_606977, JString, required = false,
                                 default = nil)
  if valid_606977 != nil:
    section.add "X-Amz-Algorithm", valid_606977
  var valid_606978 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606978 = validateParameter(valid_606978, JString, required = false,
                                 default = nil)
  if valid_606978 != nil:
    section.add "X-Amz-SignedHeaders", valid_606978
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606980: Call_DescribeUserPoolClient_606968; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Client method for returning the configuration information and metadata of the specified user pool app client.
  ## 
  let valid = call_606980.validator(path, query, header, formData, body)
  let scheme = call_606980.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606980.url(scheme.get, call_606980.host, call_606980.base,
                         call_606980.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606980, url, valid)

proc call*(call_606981: Call_DescribeUserPoolClient_606968; body: JsonNode): Recallable =
  ## describeUserPoolClient
  ## Client method for returning the configuration information and metadata of the specified user pool app client.
  ##   body: JObject (required)
  var body_606982 = newJObject()
  if body != nil:
    body_606982 = body
  result = call_606981.call(nil, nil, nil, nil, body_606982)

var describeUserPoolClient* = Call_DescribeUserPoolClient_606968(
    name: "describeUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserPoolClient",
    validator: validate_DescribeUserPoolClient_606969, base: "/",
    url: url_DescribeUserPoolClient_606970, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserPoolDomain_606983 = ref object of OpenApiRestCall_605589
proc url_DescribeUserPoolDomain_606985(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUserPoolDomain_606984(path: JsonNode; query: JsonNode;
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
  var valid_606986 = header.getOrDefault("X-Amz-Target")
  valid_606986 = validateParameter(valid_606986, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserPoolDomain"))
  if valid_606986 != nil:
    section.add "X-Amz-Target", valid_606986
  var valid_606987 = header.getOrDefault("X-Amz-Signature")
  valid_606987 = validateParameter(valid_606987, JString, required = false,
                                 default = nil)
  if valid_606987 != nil:
    section.add "X-Amz-Signature", valid_606987
  var valid_606988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606988 = validateParameter(valid_606988, JString, required = false,
                                 default = nil)
  if valid_606988 != nil:
    section.add "X-Amz-Content-Sha256", valid_606988
  var valid_606989 = header.getOrDefault("X-Amz-Date")
  valid_606989 = validateParameter(valid_606989, JString, required = false,
                                 default = nil)
  if valid_606989 != nil:
    section.add "X-Amz-Date", valid_606989
  var valid_606990 = header.getOrDefault("X-Amz-Credential")
  valid_606990 = validateParameter(valid_606990, JString, required = false,
                                 default = nil)
  if valid_606990 != nil:
    section.add "X-Amz-Credential", valid_606990
  var valid_606991 = header.getOrDefault("X-Amz-Security-Token")
  valid_606991 = validateParameter(valid_606991, JString, required = false,
                                 default = nil)
  if valid_606991 != nil:
    section.add "X-Amz-Security-Token", valid_606991
  var valid_606992 = header.getOrDefault("X-Amz-Algorithm")
  valid_606992 = validateParameter(valid_606992, JString, required = false,
                                 default = nil)
  if valid_606992 != nil:
    section.add "X-Amz-Algorithm", valid_606992
  var valid_606993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606993 = validateParameter(valid_606993, JString, required = false,
                                 default = nil)
  if valid_606993 != nil:
    section.add "X-Amz-SignedHeaders", valid_606993
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606995: Call_DescribeUserPoolDomain_606983; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a domain.
  ## 
  let valid = call_606995.validator(path, query, header, formData, body)
  let scheme = call_606995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606995.url(scheme.get, call_606995.host, call_606995.base,
                         call_606995.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606995, url, valid)

proc call*(call_606996: Call_DescribeUserPoolDomain_606983; body: JsonNode): Recallable =
  ## describeUserPoolDomain
  ## Gets information about a domain.
  ##   body: JObject (required)
  var body_606997 = newJObject()
  if body != nil:
    body_606997 = body
  result = call_606996.call(nil, nil, nil, nil, body_606997)

var describeUserPoolDomain* = Call_DescribeUserPoolDomain_606983(
    name: "describeUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserPoolDomain",
    validator: validate_DescribeUserPoolDomain_606984, base: "/",
    url: url_DescribeUserPoolDomain_606985, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ForgetDevice_606998 = ref object of OpenApiRestCall_605589
proc url_ForgetDevice_607000(protocol: Scheme; host: string; base: string;
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

proc validate_ForgetDevice_606999(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607001 = header.getOrDefault("X-Amz-Target")
  valid_607001 = validateParameter(valid_607001, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ForgetDevice"))
  if valid_607001 != nil:
    section.add "X-Amz-Target", valid_607001
  var valid_607002 = header.getOrDefault("X-Amz-Signature")
  valid_607002 = validateParameter(valid_607002, JString, required = false,
                                 default = nil)
  if valid_607002 != nil:
    section.add "X-Amz-Signature", valid_607002
  var valid_607003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607003 = validateParameter(valid_607003, JString, required = false,
                                 default = nil)
  if valid_607003 != nil:
    section.add "X-Amz-Content-Sha256", valid_607003
  var valid_607004 = header.getOrDefault("X-Amz-Date")
  valid_607004 = validateParameter(valid_607004, JString, required = false,
                                 default = nil)
  if valid_607004 != nil:
    section.add "X-Amz-Date", valid_607004
  var valid_607005 = header.getOrDefault("X-Amz-Credential")
  valid_607005 = validateParameter(valid_607005, JString, required = false,
                                 default = nil)
  if valid_607005 != nil:
    section.add "X-Amz-Credential", valid_607005
  var valid_607006 = header.getOrDefault("X-Amz-Security-Token")
  valid_607006 = validateParameter(valid_607006, JString, required = false,
                                 default = nil)
  if valid_607006 != nil:
    section.add "X-Amz-Security-Token", valid_607006
  var valid_607007 = header.getOrDefault("X-Amz-Algorithm")
  valid_607007 = validateParameter(valid_607007, JString, required = false,
                                 default = nil)
  if valid_607007 != nil:
    section.add "X-Amz-Algorithm", valid_607007
  var valid_607008 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607008 = validateParameter(valid_607008, JString, required = false,
                                 default = nil)
  if valid_607008 != nil:
    section.add "X-Amz-SignedHeaders", valid_607008
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607010: Call_ForgetDevice_606998; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Forgets the specified device.
  ## 
  let valid = call_607010.validator(path, query, header, formData, body)
  let scheme = call_607010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607010.url(scheme.get, call_607010.host, call_607010.base,
                         call_607010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607010, url, valid)

proc call*(call_607011: Call_ForgetDevice_606998; body: JsonNode): Recallable =
  ## forgetDevice
  ## Forgets the specified device.
  ##   body: JObject (required)
  var body_607012 = newJObject()
  if body != nil:
    body_607012 = body
  result = call_607011.call(nil, nil, nil, nil, body_607012)

var forgetDevice* = Call_ForgetDevice_606998(name: "forgetDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ForgetDevice",
    validator: validate_ForgetDevice_606999, base: "/", url: url_ForgetDevice_607000,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ForgotPassword_607013 = ref object of OpenApiRestCall_605589
proc url_ForgotPassword_607015(protocol: Scheme; host: string; base: string;
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

proc validate_ForgotPassword_607014(path: JsonNode; query: JsonNode;
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
  var valid_607016 = header.getOrDefault("X-Amz-Target")
  valid_607016 = validateParameter(valid_607016, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ForgotPassword"))
  if valid_607016 != nil:
    section.add "X-Amz-Target", valid_607016
  var valid_607017 = header.getOrDefault("X-Amz-Signature")
  valid_607017 = validateParameter(valid_607017, JString, required = false,
                                 default = nil)
  if valid_607017 != nil:
    section.add "X-Amz-Signature", valid_607017
  var valid_607018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607018 = validateParameter(valid_607018, JString, required = false,
                                 default = nil)
  if valid_607018 != nil:
    section.add "X-Amz-Content-Sha256", valid_607018
  var valid_607019 = header.getOrDefault("X-Amz-Date")
  valid_607019 = validateParameter(valid_607019, JString, required = false,
                                 default = nil)
  if valid_607019 != nil:
    section.add "X-Amz-Date", valid_607019
  var valid_607020 = header.getOrDefault("X-Amz-Credential")
  valid_607020 = validateParameter(valid_607020, JString, required = false,
                                 default = nil)
  if valid_607020 != nil:
    section.add "X-Amz-Credential", valid_607020
  var valid_607021 = header.getOrDefault("X-Amz-Security-Token")
  valid_607021 = validateParameter(valid_607021, JString, required = false,
                                 default = nil)
  if valid_607021 != nil:
    section.add "X-Amz-Security-Token", valid_607021
  var valid_607022 = header.getOrDefault("X-Amz-Algorithm")
  valid_607022 = validateParameter(valid_607022, JString, required = false,
                                 default = nil)
  if valid_607022 != nil:
    section.add "X-Amz-Algorithm", valid_607022
  var valid_607023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607023 = validateParameter(valid_607023, JString, required = false,
                                 default = nil)
  if valid_607023 != nil:
    section.add "X-Amz-SignedHeaders", valid_607023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607025: Call_ForgotPassword_607013; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Calling this API causes a message to be sent to the end user with a confirmation code that is required to change the user's password. For the <code>Username</code> parameter, you can use the username or user alias. If a verified phone number exists for the user, the confirmation code is sent to the phone number. Otherwise, if a verified email exists, the confirmation code is sent to the email. If neither a verified phone number nor a verified email exists, <code>InvalidParameterException</code> is thrown. To use the confirmation code for resetting the password, call .
  ## 
  let valid = call_607025.validator(path, query, header, formData, body)
  let scheme = call_607025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607025.url(scheme.get, call_607025.host, call_607025.base,
                         call_607025.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607025, url, valid)

proc call*(call_607026: Call_ForgotPassword_607013; body: JsonNode): Recallable =
  ## forgotPassword
  ## Calling this API causes a message to be sent to the end user with a confirmation code that is required to change the user's password. For the <code>Username</code> parameter, you can use the username or user alias. If a verified phone number exists for the user, the confirmation code is sent to the phone number. Otherwise, if a verified email exists, the confirmation code is sent to the email. If neither a verified phone number nor a verified email exists, <code>InvalidParameterException</code> is thrown. To use the confirmation code for resetting the password, call .
  ##   body: JObject (required)
  var body_607027 = newJObject()
  if body != nil:
    body_607027 = body
  result = call_607026.call(nil, nil, nil, nil, body_607027)

var forgotPassword* = Call_ForgotPassword_607013(name: "forgotPassword",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ForgotPassword",
    validator: validate_ForgotPassword_607014, base: "/", url: url_ForgotPassword_607015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCSVHeader_607028 = ref object of OpenApiRestCall_605589
proc url_GetCSVHeader_607030(protocol: Scheme; host: string; base: string;
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

proc validate_GetCSVHeader_607029(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607031 = header.getOrDefault("X-Amz-Target")
  valid_607031 = validateParameter(valid_607031, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetCSVHeader"))
  if valid_607031 != nil:
    section.add "X-Amz-Target", valid_607031
  var valid_607032 = header.getOrDefault("X-Amz-Signature")
  valid_607032 = validateParameter(valid_607032, JString, required = false,
                                 default = nil)
  if valid_607032 != nil:
    section.add "X-Amz-Signature", valid_607032
  var valid_607033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607033 = validateParameter(valid_607033, JString, required = false,
                                 default = nil)
  if valid_607033 != nil:
    section.add "X-Amz-Content-Sha256", valid_607033
  var valid_607034 = header.getOrDefault("X-Amz-Date")
  valid_607034 = validateParameter(valid_607034, JString, required = false,
                                 default = nil)
  if valid_607034 != nil:
    section.add "X-Amz-Date", valid_607034
  var valid_607035 = header.getOrDefault("X-Amz-Credential")
  valid_607035 = validateParameter(valid_607035, JString, required = false,
                                 default = nil)
  if valid_607035 != nil:
    section.add "X-Amz-Credential", valid_607035
  var valid_607036 = header.getOrDefault("X-Amz-Security-Token")
  valid_607036 = validateParameter(valid_607036, JString, required = false,
                                 default = nil)
  if valid_607036 != nil:
    section.add "X-Amz-Security-Token", valid_607036
  var valid_607037 = header.getOrDefault("X-Amz-Algorithm")
  valid_607037 = validateParameter(valid_607037, JString, required = false,
                                 default = nil)
  if valid_607037 != nil:
    section.add "X-Amz-Algorithm", valid_607037
  var valid_607038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607038 = validateParameter(valid_607038, JString, required = false,
                                 default = nil)
  if valid_607038 != nil:
    section.add "X-Amz-SignedHeaders", valid_607038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607040: Call_GetCSVHeader_607028; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the header information for the .csv file to be used as input for the user import job.
  ## 
  let valid = call_607040.validator(path, query, header, formData, body)
  let scheme = call_607040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607040.url(scheme.get, call_607040.host, call_607040.base,
                         call_607040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607040, url, valid)

proc call*(call_607041: Call_GetCSVHeader_607028; body: JsonNode): Recallable =
  ## getCSVHeader
  ## Gets the header information for the .csv file to be used as input for the user import job.
  ##   body: JObject (required)
  var body_607042 = newJObject()
  if body != nil:
    body_607042 = body
  result = call_607041.call(nil, nil, nil, nil, body_607042)

var getCSVHeader* = Call_GetCSVHeader_607028(name: "getCSVHeader",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetCSVHeader",
    validator: validate_GetCSVHeader_607029, base: "/", url: url_GetCSVHeader_607030,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevice_607043 = ref object of OpenApiRestCall_605589
proc url_GetDevice_607045(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetDevice_607044(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607046 = header.getOrDefault("X-Amz-Target")
  valid_607046 = validateParameter(valid_607046, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetDevice"))
  if valid_607046 != nil:
    section.add "X-Amz-Target", valid_607046
  var valid_607047 = header.getOrDefault("X-Amz-Signature")
  valid_607047 = validateParameter(valid_607047, JString, required = false,
                                 default = nil)
  if valid_607047 != nil:
    section.add "X-Amz-Signature", valid_607047
  var valid_607048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607048 = validateParameter(valid_607048, JString, required = false,
                                 default = nil)
  if valid_607048 != nil:
    section.add "X-Amz-Content-Sha256", valid_607048
  var valid_607049 = header.getOrDefault("X-Amz-Date")
  valid_607049 = validateParameter(valid_607049, JString, required = false,
                                 default = nil)
  if valid_607049 != nil:
    section.add "X-Amz-Date", valid_607049
  var valid_607050 = header.getOrDefault("X-Amz-Credential")
  valid_607050 = validateParameter(valid_607050, JString, required = false,
                                 default = nil)
  if valid_607050 != nil:
    section.add "X-Amz-Credential", valid_607050
  var valid_607051 = header.getOrDefault("X-Amz-Security-Token")
  valid_607051 = validateParameter(valid_607051, JString, required = false,
                                 default = nil)
  if valid_607051 != nil:
    section.add "X-Amz-Security-Token", valid_607051
  var valid_607052 = header.getOrDefault("X-Amz-Algorithm")
  valid_607052 = validateParameter(valid_607052, JString, required = false,
                                 default = nil)
  if valid_607052 != nil:
    section.add "X-Amz-Algorithm", valid_607052
  var valid_607053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607053 = validateParameter(valid_607053, JString, required = false,
                                 default = nil)
  if valid_607053 != nil:
    section.add "X-Amz-SignedHeaders", valid_607053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607055: Call_GetDevice_607043; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the device.
  ## 
  let valid = call_607055.validator(path, query, header, formData, body)
  let scheme = call_607055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607055.url(scheme.get, call_607055.host, call_607055.base,
                         call_607055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607055, url, valid)

proc call*(call_607056: Call_GetDevice_607043; body: JsonNode): Recallable =
  ## getDevice
  ## Gets the device.
  ##   body: JObject (required)
  var body_607057 = newJObject()
  if body != nil:
    body_607057 = body
  result = call_607056.call(nil, nil, nil, nil, body_607057)

var getDevice* = Call_GetDevice_607043(name: "getDevice", meth: HttpMethod.HttpPost,
                                    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetDevice",
                                    validator: validate_GetDevice_607044,
                                    base: "/", url: url_GetDevice_607045,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroup_607058 = ref object of OpenApiRestCall_605589
proc url_GetGroup_607060(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetGroup_607059(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607061 = header.getOrDefault("X-Amz-Target")
  valid_607061 = validateParameter(valid_607061, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetGroup"))
  if valid_607061 != nil:
    section.add "X-Amz-Target", valid_607061
  var valid_607062 = header.getOrDefault("X-Amz-Signature")
  valid_607062 = validateParameter(valid_607062, JString, required = false,
                                 default = nil)
  if valid_607062 != nil:
    section.add "X-Amz-Signature", valid_607062
  var valid_607063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607063 = validateParameter(valid_607063, JString, required = false,
                                 default = nil)
  if valid_607063 != nil:
    section.add "X-Amz-Content-Sha256", valid_607063
  var valid_607064 = header.getOrDefault("X-Amz-Date")
  valid_607064 = validateParameter(valid_607064, JString, required = false,
                                 default = nil)
  if valid_607064 != nil:
    section.add "X-Amz-Date", valid_607064
  var valid_607065 = header.getOrDefault("X-Amz-Credential")
  valid_607065 = validateParameter(valid_607065, JString, required = false,
                                 default = nil)
  if valid_607065 != nil:
    section.add "X-Amz-Credential", valid_607065
  var valid_607066 = header.getOrDefault("X-Amz-Security-Token")
  valid_607066 = validateParameter(valid_607066, JString, required = false,
                                 default = nil)
  if valid_607066 != nil:
    section.add "X-Amz-Security-Token", valid_607066
  var valid_607067 = header.getOrDefault("X-Amz-Algorithm")
  valid_607067 = validateParameter(valid_607067, JString, required = false,
                                 default = nil)
  if valid_607067 != nil:
    section.add "X-Amz-Algorithm", valid_607067
  var valid_607068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607068 = validateParameter(valid_607068, JString, required = false,
                                 default = nil)
  if valid_607068 != nil:
    section.add "X-Amz-SignedHeaders", valid_607068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607070: Call_GetGroup_607058; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a group.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_607070.validator(path, query, header, formData, body)
  let scheme = call_607070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607070.url(scheme.get, call_607070.host, call_607070.base,
                         call_607070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607070, url, valid)

proc call*(call_607071: Call_GetGroup_607058; body: JsonNode): Recallable =
  ## getGroup
  ## <p>Gets a group.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_607072 = newJObject()
  if body != nil:
    body_607072 = body
  result = call_607071.call(nil, nil, nil, nil, body_607072)

var getGroup* = Call_GetGroup_607058(name: "getGroup", meth: HttpMethod.HttpPost,
                                  host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetGroup",
                                  validator: validate_GetGroup_607059, base: "/",
                                  url: url_GetGroup_607060,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIdentityProviderByIdentifier_607073 = ref object of OpenApiRestCall_605589
proc url_GetIdentityProviderByIdentifier_607075(protocol: Scheme; host: string;
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

proc validate_GetIdentityProviderByIdentifier_607074(path: JsonNode;
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
  var valid_607076 = header.getOrDefault("X-Amz-Target")
  valid_607076 = validateParameter(valid_607076, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetIdentityProviderByIdentifier"))
  if valid_607076 != nil:
    section.add "X-Amz-Target", valid_607076
  var valid_607077 = header.getOrDefault("X-Amz-Signature")
  valid_607077 = validateParameter(valid_607077, JString, required = false,
                                 default = nil)
  if valid_607077 != nil:
    section.add "X-Amz-Signature", valid_607077
  var valid_607078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607078 = validateParameter(valid_607078, JString, required = false,
                                 default = nil)
  if valid_607078 != nil:
    section.add "X-Amz-Content-Sha256", valid_607078
  var valid_607079 = header.getOrDefault("X-Amz-Date")
  valid_607079 = validateParameter(valid_607079, JString, required = false,
                                 default = nil)
  if valid_607079 != nil:
    section.add "X-Amz-Date", valid_607079
  var valid_607080 = header.getOrDefault("X-Amz-Credential")
  valid_607080 = validateParameter(valid_607080, JString, required = false,
                                 default = nil)
  if valid_607080 != nil:
    section.add "X-Amz-Credential", valid_607080
  var valid_607081 = header.getOrDefault("X-Amz-Security-Token")
  valid_607081 = validateParameter(valid_607081, JString, required = false,
                                 default = nil)
  if valid_607081 != nil:
    section.add "X-Amz-Security-Token", valid_607081
  var valid_607082 = header.getOrDefault("X-Amz-Algorithm")
  valid_607082 = validateParameter(valid_607082, JString, required = false,
                                 default = nil)
  if valid_607082 != nil:
    section.add "X-Amz-Algorithm", valid_607082
  var valid_607083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607083 = validateParameter(valid_607083, JString, required = false,
                                 default = nil)
  if valid_607083 != nil:
    section.add "X-Amz-SignedHeaders", valid_607083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607085: Call_GetIdentityProviderByIdentifier_607073;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the specified identity provider.
  ## 
  let valid = call_607085.validator(path, query, header, formData, body)
  let scheme = call_607085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607085.url(scheme.get, call_607085.host, call_607085.base,
                         call_607085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607085, url, valid)

proc call*(call_607086: Call_GetIdentityProviderByIdentifier_607073; body: JsonNode): Recallable =
  ## getIdentityProviderByIdentifier
  ## Gets the specified identity provider.
  ##   body: JObject (required)
  var body_607087 = newJObject()
  if body != nil:
    body_607087 = body
  result = call_607086.call(nil, nil, nil, nil, body_607087)

var getIdentityProviderByIdentifier* = Call_GetIdentityProviderByIdentifier_607073(
    name: "getIdentityProviderByIdentifier", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetIdentityProviderByIdentifier",
    validator: validate_GetIdentityProviderByIdentifier_607074, base: "/",
    url: url_GetIdentityProviderByIdentifier_607075,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSigningCertificate_607088 = ref object of OpenApiRestCall_605589
proc url_GetSigningCertificate_607090(protocol: Scheme; host: string; base: string;
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

proc validate_GetSigningCertificate_607089(path: JsonNode; query: JsonNode;
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
  var valid_607091 = header.getOrDefault("X-Amz-Target")
  valid_607091 = validateParameter(valid_607091, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetSigningCertificate"))
  if valid_607091 != nil:
    section.add "X-Amz-Target", valid_607091
  var valid_607092 = header.getOrDefault("X-Amz-Signature")
  valid_607092 = validateParameter(valid_607092, JString, required = false,
                                 default = nil)
  if valid_607092 != nil:
    section.add "X-Amz-Signature", valid_607092
  var valid_607093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607093 = validateParameter(valid_607093, JString, required = false,
                                 default = nil)
  if valid_607093 != nil:
    section.add "X-Amz-Content-Sha256", valid_607093
  var valid_607094 = header.getOrDefault("X-Amz-Date")
  valid_607094 = validateParameter(valid_607094, JString, required = false,
                                 default = nil)
  if valid_607094 != nil:
    section.add "X-Amz-Date", valid_607094
  var valid_607095 = header.getOrDefault("X-Amz-Credential")
  valid_607095 = validateParameter(valid_607095, JString, required = false,
                                 default = nil)
  if valid_607095 != nil:
    section.add "X-Amz-Credential", valid_607095
  var valid_607096 = header.getOrDefault("X-Amz-Security-Token")
  valid_607096 = validateParameter(valid_607096, JString, required = false,
                                 default = nil)
  if valid_607096 != nil:
    section.add "X-Amz-Security-Token", valid_607096
  var valid_607097 = header.getOrDefault("X-Amz-Algorithm")
  valid_607097 = validateParameter(valid_607097, JString, required = false,
                                 default = nil)
  if valid_607097 != nil:
    section.add "X-Amz-Algorithm", valid_607097
  var valid_607098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607098 = validateParameter(valid_607098, JString, required = false,
                                 default = nil)
  if valid_607098 != nil:
    section.add "X-Amz-SignedHeaders", valid_607098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607100: Call_GetSigningCertificate_607088; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This method takes a user pool ID, and returns the signing certificate.
  ## 
  let valid = call_607100.validator(path, query, header, formData, body)
  let scheme = call_607100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607100.url(scheme.get, call_607100.host, call_607100.base,
                         call_607100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607100, url, valid)

proc call*(call_607101: Call_GetSigningCertificate_607088; body: JsonNode): Recallable =
  ## getSigningCertificate
  ## This method takes a user pool ID, and returns the signing certificate.
  ##   body: JObject (required)
  var body_607102 = newJObject()
  if body != nil:
    body_607102 = body
  result = call_607101.call(nil, nil, nil, nil, body_607102)

var getSigningCertificate* = Call_GetSigningCertificate_607088(
    name: "getSigningCertificate", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetSigningCertificate",
    validator: validate_GetSigningCertificate_607089, base: "/",
    url: url_GetSigningCertificate_607090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUICustomization_607103 = ref object of OpenApiRestCall_605589
proc url_GetUICustomization_607105(protocol: Scheme; host: string; base: string;
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

proc validate_GetUICustomization_607104(path: JsonNode; query: JsonNode;
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
  var valid_607106 = header.getOrDefault("X-Amz-Target")
  valid_607106 = validateParameter(valid_607106, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUICustomization"))
  if valid_607106 != nil:
    section.add "X-Amz-Target", valid_607106
  var valid_607107 = header.getOrDefault("X-Amz-Signature")
  valid_607107 = validateParameter(valid_607107, JString, required = false,
                                 default = nil)
  if valid_607107 != nil:
    section.add "X-Amz-Signature", valid_607107
  var valid_607108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607108 = validateParameter(valid_607108, JString, required = false,
                                 default = nil)
  if valid_607108 != nil:
    section.add "X-Amz-Content-Sha256", valid_607108
  var valid_607109 = header.getOrDefault("X-Amz-Date")
  valid_607109 = validateParameter(valid_607109, JString, required = false,
                                 default = nil)
  if valid_607109 != nil:
    section.add "X-Amz-Date", valid_607109
  var valid_607110 = header.getOrDefault("X-Amz-Credential")
  valid_607110 = validateParameter(valid_607110, JString, required = false,
                                 default = nil)
  if valid_607110 != nil:
    section.add "X-Amz-Credential", valid_607110
  var valid_607111 = header.getOrDefault("X-Amz-Security-Token")
  valid_607111 = validateParameter(valid_607111, JString, required = false,
                                 default = nil)
  if valid_607111 != nil:
    section.add "X-Amz-Security-Token", valid_607111
  var valid_607112 = header.getOrDefault("X-Amz-Algorithm")
  valid_607112 = validateParameter(valid_607112, JString, required = false,
                                 default = nil)
  if valid_607112 != nil:
    section.add "X-Amz-Algorithm", valid_607112
  var valid_607113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607113 = validateParameter(valid_607113, JString, required = false,
                                 default = nil)
  if valid_607113 != nil:
    section.add "X-Amz-SignedHeaders", valid_607113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607115: Call_GetUICustomization_607103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the UI Customization information for a particular app client's app UI, if there is something set. If nothing is set for the particular client, but there is an existing pool level customization (app <code>clientId</code> will be <code>ALL</code>), then that is returned. If nothing is present, then an empty shape is returned.
  ## 
  let valid = call_607115.validator(path, query, header, formData, body)
  let scheme = call_607115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607115.url(scheme.get, call_607115.host, call_607115.base,
                         call_607115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607115, url, valid)

proc call*(call_607116: Call_GetUICustomization_607103; body: JsonNode): Recallable =
  ## getUICustomization
  ## Gets the UI Customization information for a particular app client's app UI, if there is something set. If nothing is set for the particular client, but there is an existing pool level customization (app <code>clientId</code> will be <code>ALL</code>), then that is returned. If nothing is present, then an empty shape is returned.
  ##   body: JObject (required)
  var body_607117 = newJObject()
  if body != nil:
    body_607117 = body
  result = call_607116.call(nil, nil, nil, nil, body_607117)

var getUICustomization* = Call_GetUICustomization_607103(
    name: "getUICustomization", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUICustomization",
    validator: validate_GetUICustomization_607104, base: "/",
    url: url_GetUICustomization_607105, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUser_607118 = ref object of OpenApiRestCall_605589
proc url_GetUser_607120(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetUser_607119(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607121 = header.getOrDefault("X-Amz-Target")
  valid_607121 = validateParameter(valid_607121, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUser"))
  if valid_607121 != nil:
    section.add "X-Amz-Target", valid_607121
  var valid_607122 = header.getOrDefault("X-Amz-Signature")
  valid_607122 = validateParameter(valid_607122, JString, required = false,
                                 default = nil)
  if valid_607122 != nil:
    section.add "X-Amz-Signature", valid_607122
  var valid_607123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607123 = validateParameter(valid_607123, JString, required = false,
                                 default = nil)
  if valid_607123 != nil:
    section.add "X-Amz-Content-Sha256", valid_607123
  var valid_607124 = header.getOrDefault("X-Amz-Date")
  valid_607124 = validateParameter(valid_607124, JString, required = false,
                                 default = nil)
  if valid_607124 != nil:
    section.add "X-Amz-Date", valid_607124
  var valid_607125 = header.getOrDefault("X-Amz-Credential")
  valid_607125 = validateParameter(valid_607125, JString, required = false,
                                 default = nil)
  if valid_607125 != nil:
    section.add "X-Amz-Credential", valid_607125
  var valid_607126 = header.getOrDefault("X-Amz-Security-Token")
  valid_607126 = validateParameter(valid_607126, JString, required = false,
                                 default = nil)
  if valid_607126 != nil:
    section.add "X-Amz-Security-Token", valid_607126
  var valid_607127 = header.getOrDefault("X-Amz-Algorithm")
  valid_607127 = validateParameter(valid_607127, JString, required = false,
                                 default = nil)
  if valid_607127 != nil:
    section.add "X-Amz-Algorithm", valid_607127
  var valid_607128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607128 = validateParameter(valid_607128, JString, required = false,
                                 default = nil)
  if valid_607128 != nil:
    section.add "X-Amz-SignedHeaders", valid_607128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607130: Call_GetUser_607118; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the user attributes and metadata for a user.
  ## 
  let valid = call_607130.validator(path, query, header, formData, body)
  let scheme = call_607130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607130.url(scheme.get, call_607130.host, call_607130.base,
                         call_607130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607130, url, valid)

proc call*(call_607131: Call_GetUser_607118; body: JsonNode): Recallable =
  ## getUser
  ## Gets the user attributes and metadata for a user.
  ##   body: JObject (required)
  var body_607132 = newJObject()
  if body != nil:
    body_607132 = body
  result = call_607131.call(nil, nil, nil, nil, body_607132)

var getUser* = Call_GetUser_607118(name: "getUser", meth: HttpMethod.HttpPost,
                                host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUser",
                                validator: validate_GetUser_607119, base: "/",
                                url: url_GetUser_607120,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserAttributeVerificationCode_607133 = ref object of OpenApiRestCall_605589
proc url_GetUserAttributeVerificationCode_607135(protocol: Scheme; host: string;
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

proc validate_GetUserAttributeVerificationCode_607134(path: JsonNode;
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
  var valid_607136 = header.getOrDefault("X-Amz-Target")
  valid_607136 = validateParameter(valid_607136, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUserAttributeVerificationCode"))
  if valid_607136 != nil:
    section.add "X-Amz-Target", valid_607136
  var valid_607137 = header.getOrDefault("X-Amz-Signature")
  valid_607137 = validateParameter(valid_607137, JString, required = false,
                                 default = nil)
  if valid_607137 != nil:
    section.add "X-Amz-Signature", valid_607137
  var valid_607138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607138 = validateParameter(valid_607138, JString, required = false,
                                 default = nil)
  if valid_607138 != nil:
    section.add "X-Amz-Content-Sha256", valid_607138
  var valid_607139 = header.getOrDefault("X-Amz-Date")
  valid_607139 = validateParameter(valid_607139, JString, required = false,
                                 default = nil)
  if valid_607139 != nil:
    section.add "X-Amz-Date", valid_607139
  var valid_607140 = header.getOrDefault("X-Amz-Credential")
  valid_607140 = validateParameter(valid_607140, JString, required = false,
                                 default = nil)
  if valid_607140 != nil:
    section.add "X-Amz-Credential", valid_607140
  var valid_607141 = header.getOrDefault("X-Amz-Security-Token")
  valid_607141 = validateParameter(valid_607141, JString, required = false,
                                 default = nil)
  if valid_607141 != nil:
    section.add "X-Amz-Security-Token", valid_607141
  var valid_607142 = header.getOrDefault("X-Amz-Algorithm")
  valid_607142 = validateParameter(valid_607142, JString, required = false,
                                 default = nil)
  if valid_607142 != nil:
    section.add "X-Amz-Algorithm", valid_607142
  var valid_607143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607143 = validateParameter(valid_607143, JString, required = false,
                                 default = nil)
  if valid_607143 != nil:
    section.add "X-Amz-SignedHeaders", valid_607143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607145: Call_GetUserAttributeVerificationCode_607133;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the user attribute verification code for the specified attribute name.
  ## 
  let valid = call_607145.validator(path, query, header, formData, body)
  let scheme = call_607145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607145.url(scheme.get, call_607145.host, call_607145.base,
                         call_607145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607145, url, valid)

proc call*(call_607146: Call_GetUserAttributeVerificationCode_607133;
          body: JsonNode): Recallable =
  ## getUserAttributeVerificationCode
  ## Gets the user attribute verification code for the specified attribute name.
  ##   body: JObject (required)
  var body_607147 = newJObject()
  if body != nil:
    body_607147 = body
  result = call_607146.call(nil, nil, nil, nil, body_607147)

var getUserAttributeVerificationCode* = Call_GetUserAttributeVerificationCode_607133(
    name: "getUserAttributeVerificationCode", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUserAttributeVerificationCode",
    validator: validate_GetUserAttributeVerificationCode_607134, base: "/",
    url: url_GetUserAttributeVerificationCode_607135,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserPoolMfaConfig_607148 = ref object of OpenApiRestCall_605589
proc url_GetUserPoolMfaConfig_607150(protocol: Scheme; host: string; base: string;
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

proc validate_GetUserPoolMfaConfig_607149(path: JsonNode; query: JsonNode;
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
  var valid_607151 = header.getOrDefault("X-Amz-Target")
  valid_607151 = validateParameter(valid_607151, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUserPoolMfaConfig"))
  if valid_607151 != nil:
    section.add "X-Amz-Target", valid_607151
  var valid_607152 = header.getOrDefault("X-Amz-Signature")
  valid_607152 = validateParameter(valid_607152, JString, required = false,
                                 default = nil)
  if valid_607152 != nil:
    section.add "X-Amz-Signature", valid_607152
  var valid_607153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607153 = validateParameter(valid_607153, JString, required = false,
                                 default = nil)
  if valid_607153 != nil:
    section.add "X-Amz-Content-Sha256", valid_607153
  var valid_607154 = header.getOrDefault("X-Amz-Date")
  valid_607154 = validateParameter(valid_607154, JString, required = false,
                                 default = nil)
  if valid_607154 != nil:
    section.add "X-Amz-Date", valid_607154
  var valid_607155 = header.getOrDefault("X-Amz-Credential")
  valid_607155 = validateParameter(valid_607155, JString, required = false,
                                 default = nil)
  if valid_607155 != nil:
    section.add "X-Amz-Credential", valid_607155
  var valid_607156 = header.getOrDefault("X-Amz-Security-Token")
  valid_607156 = validateParameter(valid_607156, JString, required = false,
                                 default = nil)
  if valid_607156 != nil:
    section.add "X-Amz-Security-Token", valid_607156
  var valid_607157 = header.getOrDefault("X-Amz-Algorithm")
  valid_607157 = validateParameter(valid_607157, JString, required = false,
                                 default = nil)
  if valid_607157 != nil:
    section.add "X-Amz-Algorithm", valid_607157
  var valid_607158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607158 = validateParameter(valid_607158, JString, required = false,
                                 default = nil)
  if valid_607158 != nil:
    section.add "X-Amz-SignedHeaders", valid_607158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607160: Call_GetUserPoolMfaConfig_607148; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the user pool multi-factor authentication (MFA) configuration.
  ## 
  let valid = call_607160.validator(path, query, header, formData, body)
  let scheme = call_607160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607160.url(scheme.get, call_607160.host, call_607160.base,
                         call_607160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607160, url, valid)

proc call*(call_607161: Call_GetUserPoolMfaConfig_607148; body: JsonNode): Recallable =
  ## getUserPoolMfaConfig
  ## Gets the user pool multi-factor authentication (MFA) configuration.
  ##   body: JObject (required)
  var body_607162 = newJObject()
  if body != nil:
    body_607162 = body
  result = call_607161.call(nil, nil, nil, nil, body_607162)

var getUserPoolMfaConfig* = Call_GetUserPoolMfaConfig_607148(
    name: "getUserPoolMfaConfig", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUserPoolMfaConfig",
    validator: validate_GetUserPoolMfaConfig_607149, base: "/",
    url: url_GetUserPoolMfaConfig_607150, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GlobalSignOut_607163 = ref object of OpenApiRestCall_605589
proc url_GlobalSignOut_607165(protocol: Scheme; host: string; base: string;
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

proc validate_GlobalSignOut_607164(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607166 = header.getOrDefault("X-Amz-Target")
  valid_607166 = validateParameter(valid_607166, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GlobalSignOut"))
  if valid_607166 != nil:
    section.add "X-Amz-Target", valid_607166
  var valid_607167 = header.getOrDefault("X-Amz-Signature")
  valid_607167 = validateParameter(valid_607167, JString, required = false,
                                 default = nil)
  if valid_607167 != nil:
    section.add "X-Amz-Signature", valid_607167
  var valid_607168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607168 = validateParameter(valid_607168, JString, required = false,
                                 default = nil)
  if valid_607168 != nil:
    section.add "X-Amz-Content-Sha256", valid_607168
  var valid_607169 = header.getOrDefault("X-Amz-Date")
  valid_607169 = validateParameter(valid_607169, JString, required = false,
                                 default = nil)
  if valid_607169 != nil:
    section.add "X-Amz-Date", valid_607169
  var valid_607170 = header.getOrDefault("X-Amz-Credential")
  valid_607170 = validateParameter(valid_607170, JString, required = false,
                                 default = nil)
  if valid_607170 != nil:
    section.add "X-Amz-Credential", valid_607170
  var valid_607171 = header.getOrDefault("X-Amz-Security-Token")
  valid_607171 = validateParameter(valid_607171, JString, required = false,
                                 default = nil)
  if valid_607171 != nil:
    section.add "X-Amz-Security-Token", valid_607171
  var valid_607172 = header.getOrDefault("X-Amz-Algorithm")
  valid_607172 = validateParameter(valid_607172, JString, required = false,
                                 default = nil)
  if valid_607172 != nil:
    section.add "X-Amz-Algorithm", valid_607172
  var valid_607173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607173 = validateParameter(valid_607173, JString, required = false,
                                 default = nil)
  if valid_607173 != nil:
    section.add "X-Amz-SignedHeaders", valid_607173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607175: Call_GlobalSignOut_607163; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Signs out users from all devices. It also invalidates all refresh tokens issued to a user. The user's current access and Id tokens remain valid until their expiry. Access and Id tokens expire one hour after they are issued.
  ## 
  let valid = call_607175.validator(path, query, header, formData, body)
  let scheme = call_607175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607175.url(scheme.get, call_607175.host, call_607175.base,
                         call_607175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607175, url, valid)

proc call*(call_607176: Call_GlobalSignOut_607163; body: JsonNode): Recallable =
  ## globalSignOut
  ## Signs out users from all devices. It also invalidates all refresh tokens issued to a user. The user's current access and Id tokens remain valid until their expiry. Access and Id tokens expire one hour after they are issued.
  ##   body: JObject (required)
  var body_607177 = newJObject()
  if body != nil:
    body_607177 = body
  result = call_607176.call(nil, nil, nil, nil, body_607177)

var globalSignOut* = Call_GlobalSignOut_607163(name: "globalSignOut",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GlobalSignOut",
    validator: validate_GlobalSignOut_607164, base: "/", url: url_GlobalSignOut_607165,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateAuth_607178 = ref object of OpenApiRestCall_605589
proc url_InitiateAuth_607180(protocol: Scheme; host: string; base: string;
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

proc validate_InitiateAuth_607179(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607181 = header.getOrDefault("X-Amz-Target")
  valid_607181 = validateParameter(valid_607181, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.InitiateAuth"))
  if valid_607181 != nil:
    section.add "X-Amz-Target", valid_607181
  var valid_607182 = header.getOrDefault("X-Amz-Signature")
  valid_607182 = validateParameter(valid_607182, JString, required = false,
                                 default = nil)
  if valid_607182 != nil:
    section.add "X-Amz-Signature", valid_607182
  var valid_607183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607183 = validateParameter(valid_607183, JString, required = false,
                                 default = nil)
  if valid_607183 != nil:
    section.add "X-Amz-Content-Sha256", valid_607183
  var valid_607184 = header.getOrDefault("X-Amz-Date")
  valid_607184 = validateParameter(valid_607184, JString, required = false,
                                 default = nil)
  if valid_607184 != nil:
    section.add "X-Amz-Date", valid_607184
  var valid_607185 = header.getOrDefault("X-Amz-Credential")
  valid_607185 = validateParameter(valid_607185, JString, required = false,
                                 default = nil)
  if valid_607185 != nil:
    section.add "X-Amz-Credential", valid_607185
  var valid_607186 = header.getOrDefault("X-Amz-Security-Token")
  valid_607186 = validateParameter(valid_607186, JString, required = false,
                                 default = nil)
  if valid_607186 != nil:
    section.add "X-Amz-Security-Token", valid_607186
  var valid_607187 = header.getOrDefault("X-Amz-Algorithm")
  valid_607187 = validateParameter(valid_607187, JString, required = false,
                                 default = nil)
  if valid_607187 != nil:
    section.add "X-Amz-Algorithm", valid_607187
  var valid_607188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607188 = validateParameter(valid_607188, JString, required = false,
                                 default = nil)
  if valid_607188 != nil:
    section.add "X-Amz-SignedHeaders", valid_607188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607190: Call_InitiateAuth_607178; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates the authentication flow.
  ## 
  let valid = call_607190.validator(path, query, header, formData, body)
  let scheme = call_607190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607190.url(scheme.get, call_607190.host, call_607190.base,
                         call_607190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607190, url, valid)

proc call*(call_607191: Call_InitiateAuth_607178; body: JsonNode): Recallable =
  ## initiateAuth
  ## Initiates the authentication flow.
  ##   body: JObject (required)
  var body_607192 = newJObject()
  if body != nil:
    body_607192 = body
  result = call_607191.call(nil, nil, nil, nil, body_607192)

var initiateAuth* = Call_InitiateAuth_607178(name: "initiateAuth",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.InitiateAuth",
    validator: validate_InitiateAuth_607179, base: "/", url: url_InitiateAuth_607180,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevices_607193 = ref object of OpenApiRestCall_605589
proc url_ListDevices_607195(protocol: Scheme; host: string; base: string;
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

proc validate_ListDevices_607194(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607196 = header.getOrDefault("X-Amz-Target")
  valid_607196 = validateParameter(valid_607196, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListDevices"))
  if valid_607196 != nil:
    section.add "X-Amz-Target", valid_607196
  var valid_607197 = header.getOrDefault("X-Amz-Signature")
  valid_607197 = validateParameter(valid_607197, JString, required = false,
                                 default = nil)
  if valid_607197 != nil:
    section.add "X-Amz-Signature", valid_607197
  var valid_607198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607198 = validateParameter(valid_607198, JString, required = false,
                                 default = nil)
  if valid_607198 != nil:
    section.add "X-Amz-Content-Sha256", valid_607198
  var valid_607199 = header.getOrDefault("X-Amz-Date")
  valid_607199 = validateParameter(valid_607199, JString, required = false,
                                 default = nil)
  if valid_607199 != nil:
    section.add "X-Amz-Date", valid_607199
  var valid_607200 = header.getOrDefault("X-Amz-Credential")
  valid_607200 = validateParameter(valid_607200, JString, required = false,
                                 default = nil)
  if valid_607200 != nil:
    section.add "X-Amz-Credential", valid_607200
  var valid_607201 = header.getOrDefault("X-Amz-Security-Token")
  valid_607201 = validateParameter(valid_607201, JString, required = false,
                                 default = nil)
  if valid_607201 != nil:
    section.add "X-Amz-Security-Token", valid_607201
  var valid_607202 = header.getOrDefault("X-Amz-Algorithm")
  valid_607202 = validateParameter(valid_607202, JString, required = false,
                                 default = nil)
  if valid_607202 != nil:
    section.add "X-Amz-Algorithm", valid_607202
  var valid_607203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607203 = validateParameter(valid_607203, JString, required = false,
                                 default = nil)
  if valid_607203 != nil:
    section.add "X-Amz-SignedHeaders", valid_607203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607205: Call_ListDevices_607193; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the devices.
  ## 
  let valid = call_607205.validator(path, query, header, formData, body)
  let scheme = call_607205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607205.url(scheme.get, call_607205.host, call_607205.base,
                         call_607205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607205, url, valid)

proc call*(call_607206: Call_ListDevices_607193; body: JsonNode): Recallable =
  ## listDevices
  ## Lists the devices.
  ##   body: JObject (required)
  var body_607207 = newJObject()
  if body != nil:
    body_607207 = body
  result = call_607206.call(nil, nil, nil, nil, body_607207)

var listDevices* = Call_ListDevices_607193(name: "listDevices",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListDevices",
                                        validator: validate_ListDevices_607194,
                                        base: "/", url: url_ListDevices_607195,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_607208 = ref object of OpenApiRestCall_605589
proc url_ListGroups_607210(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListGroups_607209(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the groups associated with a user pool.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   Limit: JString
  ##        : Pagination limit
  section = newJObject()
  var valid_607211 = query.getOrDefault("NextToken")
  valid_607211 = validateParameter(valid_607211, JString, required = false,
                                 default = nil)
  if valid_607211 != nil:
    section.add "NextToken", valid_607211
  var valid_607212 = query.getOrDefault("Limit")
  valid_607212 = validateParameter(valid_607212, JString, required = false,
                                 default = nil)
  if valid_607212 != nil:
    section.add "Limit", valid_607212
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
  var valid_607213 = header.getOrDefault("X-Amz-Target")
  valid_607213 = validateParameter(valid_607213, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListGroups"))
  if valid_607213 != nil:
    section.add "X-Amz-Target", valid_607213
  var valid_607214 = header.getOrDefault("X-Amz-Signature")
  valid_607214 = validateParameter(valid_607214, JString, required = false,
                                 default = nil)
  if valid_607214 != nil:
    section.add "X-Amz-Signature", valid_607214
  var valid_607215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607215 = validateParameter(valid_607215, JString, required = false,
                                 default = nil)
  if valid_607215 != nil:
    section.add "X-Amz-Content-Sha256", valid_607215
  var valid_607216 = header.getOrDefault("X-Amz-Date")
  valid_607216 = validateParameter(valid_607216, JString, required = false,
                                 default = nil)
  if valid_607216 != nil:
    section.add "X-Amz-Date", valid_607216
  var valid_607217 = header.getOrDefault("X-Amz-Credential")
  valid_607217 = validateParameter(valid_607217, JString, required = false,
                                 default = nil)
  if valid_607217 != nil:
    section.add "X-Amz-Credential", valid_607217
  var valid_607218 = header.getOrDefault("X-Amz-Security-Token")
  valid_607218 = validateParameter(valid_607218, JString, required = false,
                                 default = nil)
  if valid_607218 != nil:
    section.add "X-Amz-Security-Token", valid_607218
  var valid_607219 = header.getOrDefault("X-Amz-Algorithm")
  valid_607219 = validateParameter(valid_607219, JString, required = false,
                                 default = nil)
  if valid_607219 != nil:
    section.add "X-Amz-Algorithm", valid_607219
  var valid_607220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607220 = validateParameter(valid_607220, JString, required = false,
                                 default = nil)
  if valid_607220 != nil:
    section.add "X-Amz-SignedHeaders", valid_607220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607222: Call_ListGroups_607208; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the groups associated with a user pool.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_607222.validator(path, query, header, formData, body)
  let scheme = call_607222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607222.url(scheme.get, call_607222.host, call_607222.base,
                         call_607222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607222, url, valid)

proc call*(call_607223: Call_ListGroups_607208; body: JsonNode;
          NextToken: string = ""; Limit: string = ""): Recallable =
  ## listGroups
  ## <p>Lists the groups associated with a user pool.</p> <p>Calling this action requires developer credentials.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_607224 = newJObject()
  var body_607225 = newJObject()
  add(query_607224, "NextToken", newJString(NextToken))
  add(query_607224, "Limit", newJString(Limit))
  if body != nil:
    body_607225 = body
  result = call_607223.call(nil, query_607224, nil, nil, body_607225)

var listGroups* = Call_ListGroups_607208(name: "listGroups",
                                      meth: HttpMethod.HttpPost,
                                      host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListGroups",
                                      validator: validate_ListGroups_607209,
                                      base: "/", url: url_ListGroups_607210,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIdentityProviders_607226 = ref object of OpenApiRestCall_605589
proc url_ListIdentityProviders_607228(protocol: Scheme; host: string; base: string;
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

proc validate_ListIdentityProviders_607227(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists information about all identity providers for a user pool.
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
  var valid_607229 = query.getOrDefault("MaxResults")
  valid_607229 = validateParameter(valid_607229, JString, required = false,
                                 default = nil)
  if valid_607229 != nil:
    section.add "MaxResults", valid_607229
  var valid_607230 = query.getOrDefault("NextToken")
  valid_607230 = validateParameter(valid_607230, JString, required = false,
                                 default = nil)
  if valid_607230 != nil:
    section.add "NextToken", valid_607230
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
  var valid_607231 = header.getOrDefault("X-Amz-Target")
  valid_607231 = validateParameter(valid_607231, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListIdentityProviders"))
  if valid_607231 != nil:
    section.add "X-Amz-Target", valid_607231
  var valid_607232 = header.getOrDefault("X-Amz-Signature")
  valid_607232 = validateParameter(valid_607232, JString, required = false,
                                 default = nil)
  if valid_607232 != nil:
    section.add "X-Amz-Signature", valid_607232
  var valid_607233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607233 = validateParameter(valid_607233, JString, required = false,
                                 default = nil)
  if valid_607233 != nil:
    section.add "X-Amz-Content-Sha256", valid_607233
  var valid_607234 = header.getOrDefault("X-Amz-Date")
  valid_607234 = validateParameter(valid_607234, JString, required = false,
                                 default = nil)
  if valid_607234 != nil:
    section.add "X-Amz-Date", valid_607234
  var valid_607235 = header.getOrDefault("X-Amz-Credential")
  valid_607235 = validateParameter(valid_607235, JString, required = false,
                                 default = nil)
  if valid_607235 != nil:
    section.add "X-Amz-Credential", valid_607235
  var valid_607236 = header.getOrDefault("X-Amz-Security-Token")
  valid_607236 = validateParameter(valid_607236, JString, required = false,
                                 default = nil)
  if valid_607236 != nil:
    section.add "X-Amz-Security-Token", valid_607236
  var valid_607237 = header.getOrDefault("X-Amz-Algorithm")
  valid_607237 = validateParameter(valid_607237, JString, required = false,
                                 default = nil)
  if valid_607237 != nil:
    section.add "X-Amz-Algorithm", valid_607237
  var valid_607238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607238 = validateParameter(valid_607238, JString, required = false,
                                 default = nil)
  if valid_607238 != nil:
    section.add "X-Amz-SignedHeaders", valid_607238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607240: Call_ListIdentityProviders_607226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about all identity providers for a user pool.
  ## 
  let valid = call_607240.validator(path, query, header, formData, body)
  let scheme = call_607240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607240.url(scheme.get, call_607240.host, call_607240.base,
                         call_607240.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607240, url, valid)

proc call*(call_607241: Call_ListIdentityProviders_607226; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listIdentityProviders
  ## Lists information about all identity providers for a user pool.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607242 = newJObject()
  var body_607243 = newJObject()
  add(query_607242, "MaxResults", newJString(MaxResults))
  add(query_607242, "NextToken", newJString(NextToken))
  if body != nil:
    body_607243 = body
  result = call_607241.call(nil, query_607242, nil, nil, body_607243)

var listIdentityProviders* = Call_ListIdentityProviders_607226(
    name: "listIdentityProviders", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListIdentityProviders",
    validator: validate_ListIdentityProviders_607227, base: "/",
    url: url_ListIdentityProviders_607228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceServers_607244 = ref object of OpenApiRestCall_605589
proc url_ListResourceServers_607246(protocol: Scheme; host: string; base: string;
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

proc validate_ListResourceServers_607245(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the resource servers for a user pool.
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
  var valid_607247 = query.getOrDefault("MaxResults")
  valid_607247 = validateParameter(valid_607247, JString, required = false,
                                 default = nil)
  if valid_607247 != nil:
    section.add "MaxResults", valid_607247
  var valid_607248 = query.getOrDefault("NextToken")
  valid_607248 = validateParameter(valid_607248, JString, required = false,
                                 default = nil)
  if valid_607248 != nil:
    section.add "NextToken", valid_607248
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
  var valid_607249 = header.getOrDefault("X-Amz-Target")
  valid_607249 = validateParameter(valid_607249, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListResourceServers"))
  if valid_607249 != nil:
    section.add "X-Amz-Target", valid_607249
  var valid_607250 = header.getOrDefault("X-Amz-Signature")
  valid_607250 = validateParameter(valid_607250, JString, required = false,
                                 default = nil)
  if valid_607250 != nil:
    section.add "X-Amz-Signature", valid_607250
  var valid_607251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607251 = validateParameter(valid_607251, JString, required = false,
                                 default = nil)
  if valid_607251 != nil:
    section.add "X-Amz-Content-Sha256", valid_607251
  var valid_607252 = header.getOrDefault("X-Amz-Date")
  valid_607252 = validateParameter(valid_607252, JString, required = false,
                                 default = nil)
  if valid_607252 != nil:
    section.add "X-Amz-Date", valid_607252
  var valid_607253 = header.getOrDefault("X-Amz-Credential")
  valid_607253 = validateParameter(valid_607253, JString, required = false,
                                 default = nil)
  if valid_607253 != nil:
    section.add "X-Amz-Credential", valid_607253
  var valid_607254 = header.getOrDefault("X-Amz-Security-Token")
  valid_607254 = validateParameter(valid_607254, JString, required = false,
                                 default = nil)
  if valid_607254 != nil:
    section.add "X-Amz-Security-Token", valid_607254
  var valid_607255 = header.getOrDefault("X-Amz-Algorithm")
  valid_607255 = validateParameter(valid_607255, JString, required = false,
                                 default = nil)
  if valid_607255 != nil:
    section.add "X-Amz-Algorithm", valid_607255
  var valid_607256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607256 = validateParameter(valid_607256, JString, required = false,
                                 default = nil)
  if valid_607256 != nil:
    section.add "X-Amz-SignedHeaders", valid_607256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607258: Call_ListResourceServers_607244; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resource servers for a user pool.
  ## 
  let valid = call_607258.validator(path, query, header, formData, body)
  let scheme = call_607258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607258.url(scheme.get, call_607258.host, call_607258.base,
                         call_607258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607258, url, valid)

proc call*(call_607259: Call_ListResourceServers_607244; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listResourceServers
  ## Lists the resource servers for a user pool.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607260 = newJObject()
  var body_607261 = newJObject()
  add(query_607260, "MaxResults", newJString(MaxResults))
  add(query_607260, "NextToken", newJString(NextToken))
  if body != nil:
    body_607261 = body
  result = call_607259.call(nil, query_607260, nil, nil, body_607261)

var listResourceServers* = Call_ListResourceServers_607244(
    name: "listResourceServers", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListResourceServers",
    validator: validate_ListResourceServers_607245, base: "/",
    url: url_ListResourceServers_607246, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_607262 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_607264(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_607263(path: JsonNode; query: JsonNode;
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
  var valid_607265 = header.getOrDefault("X-Amz-Target")
  valid_607265 = validateParameter(valid_607265, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListTagsForResource"))
  if valid_607265 != nil:
    section.add "X-Amz-Target", valid_607265
  var valid_607266 = header.getOrDefault("X-Amz-Signature")
  valid_607266 = validateParameter(valid_607266, JString, required = false,
                                 default = nil)
  if valid_607266 != nil:
    section.add "X-Amz-Signature", valid_607266
  var valid_607267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607267 = validateParameter(valid_607267, JString, required = false,
                                 default = nil)
  if valid_607267 != nil:
    section.add "X-Amz-Content-Sha256", valid_607267
  var valid_607268 = header.getOrDefault("X-Amz-Date")
  valid_607268 = validateParameter(valid_607268, JString, required = false,
                                 default = nil)
  if valid_607268 != nil:
    section.add "X-Amz-Date", valid_607268
  var valid_607269 = header.getOrDefault("X-Amz-Credential")
  valid_607269 = validateParameter(valid_607269, JString, required = false,
                                 default = nil)
  if valid_607269 != nil:
    section.add "X-Amz-Credential", valid_607269
  var valid_607270 = header.getOrDefault("X-Amz-Security-Token")
  valid_607270 = validateParameter(valid_607270, JString, required = false,
                                 default = nil)
  if valid_607270 != nil:
    section.add "X-Amz-Security-Token", valid_607270
  var valid_607271 = header.getOrDefault("X-Amz-Algorithm")
  valid_607271 = validateParameter(valid_607271, JString, required = false,
                                 default = nil)
  if valid_607271 != nil:
    section.add "X-Amz-Algorithm", valid_607271
  var valid_607272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607272 = validateParameter(valid_607272, JString, required = false,
                                 default = nil)
  if valid_607272 != nil:
    section.add "X-Amz-SignedHeaders", valid_607272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607274: Call_ListTagsForResource_607262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the tags that are assigned to an Amazon Cognito user pool.</p> <p>A tag is a label that you can apply to user pools to categorize and manage them in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>You can use this action up to 10 times per second, per account.</p>
  ## 
  let valid = call_607274.validator(path, query, header, formData, body)
  let scheme = call_607274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607274.url(scheme.get, call_607274.host, call_607274.base,
                         call_607274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607274, url, valid)

proc call*(call_607275: Call_ListTagsForResource_607262; body: JsonNode): Recallable =
  ## listTagsForResource
  ## <p>Lists the tags that are assigned to an Amazon Cognito user pool.</p> <p>A tag is a label that you can apply to user pools to categorize and manage them in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>You can use this action up to 10 times per second, per account.</p>
  ##   body: JObject (required)
  var body_607276 = newJObject()
  if body != nil:
    body_607276 = body
  result = call_607275.call(nil, nil, nil, nil, body_607276)

var listTagsForResource* = Call_ListTagsForResource_607262(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListTagsForResource",
    validator: validate_ListTagsForResource_607263, base: "/",
    url: url_ListTagsForResource_607264, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserImportJobs_607277 = ref object of OpenApiRestCall_605589
proc url_ListUserImportJobs_607279(protocol: Scheme; host: string; base: string;
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

proc validate_ListUserImportJobs_607278(path: JsonNode; query: JsonNode;
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
  var valid_607280 = header.getOrDefault("X-Amz-Target")
  valid_607280 = validateParameter(valid_607280, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUserImportJobs"))
  if valid_607280 != nil:
    section.add "X-Amz-Target", valid_607280
  var valid_607281 = header.getOrDefault("X-Amz-Signature")
  valid_607281 = validateParameter(valid_607281, JString, required = false,
                                 default = nil)
  if valid_607281 != nil:
    section.add "X-Amz-Signature", valid_607281
  var valid_607282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607282 = validateParameter(valid_607282, JString, required = false,
                                 default = nil)
  if valid_607282 != nil:
    section.add "X-Amz-Content-Sha256", valid_607282
  var valid_607283 = header.getOrDefault("X-Amz-Date")
  valid_607283 = validateParameter(valid_607283, JString, required = false,
                                 default = nil)
  if valid_607283 != nil:
    section.add "X-Amz-Date", valid_607283
  var valid_607284 = header.getOrDefault("X-Amz-Credential")
  valid_607284 = validateParameter(valid_607284, JString, required = false,
                                 default = nil)
  if valid_607284 != nil:
    section.add "X-Amz-Credential", valid_607284
  var valid_607285 = header.getOrDefault("X-Amz-Security-Token")
  valid_607285 = validateParameter(valid_607285, JString, required = false,
                                 default = nil)
  if valid_607285 != nil:
    section.add "X-Amz-Security-Token", valid_607285
  var valid_607286 = header.getOrDefault("X-Amz-Algorithm")
  valid_607286 = validateParameter(valid_607286, JString, required = false,
                                 default = nil)
  if valid_607286 != nil:
    section.add "X-Amz-Algorithm", valid_607286
  var valid_607287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607287 = validateParameter(valid_607287, JString, required = false,
                                 default = nil)
  if valid_607287 != nil:
    section.add "X-Amz-SignedHeaders", valid_607287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607289: Call_ListUserImportJobs_607277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the user import jobs.
  ## 
  let valid = call_607289.validator(path, query, header, formData, body)
  let scheme = call_607289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607289.url(scheme.get, call_607289.host, call_607289.base,
                         call_607289.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607289, url, valid)

proc call*(call_607290: Call_ListUserImportJobs_607277; body: JsonNode): Recallable =
  ## listUserImportJobs
  ## Lists the user import jobs.
  ##   body: JObject (required)
  var body_607291 = newJObject()
  if body != nil:
    body_607291 = body
  result = call_607290.call(nil, nil, nil, nil, body_607291)

var listUserImportJobs* = Call_ListUserImportJobs_607277(
    name: "listUserImportJobs", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUserImportJobs",
    validator: validate_ListUserImportJobs_607278, base: "/",
    url: url_ListUserImportJobs_607279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserPoolClients_607292 = ref object of OpenApiRestCall_605589
proc url_ListUserPoolClients_607294(protocol: Scheme; host: string; base: string;
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

proc validate_ListUserPoolClients_607293(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the clients that have been created for the specified user pool.
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
  var valid_607295 = query.getOrDefault("MaxResults")
  valid_607295 = validateParameter(valid_607295, JString, required = false,
                                 default = nil)
  if valid_607295 != nil:
    section.add "MaxResults", valid_607295
  var valid_607296 = query.getOrDefault("NextToken")
  valid_607296 = validateParameter(valid_607296, JString, required = false,
                                 default = nil)
  if valid_607296 != nil:
    section.add "NextToken", valid_607296
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
  var valid_607297 = header.getOrDefault("X-Amz-Target")
  valid_607297 = validateParameter(valid_607297, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUserPoolClients"))
  if valid_607297 != nil:
    section.add "X-Amz-Target", valid_607297
  var valid_607298 = header.getOrDefault("X-Amz-Signature")
  valid_607298 = validateParameter(valid_607298, JString, required = false,
                                 default = nil)
  if valid_607298 != nil:
    section.add "X-Amz-Signature", valid_607298
  var valid_607299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607299 = validateParameter(valid_607299, JString, required = false,
                                 default = nil)
  if valid_607299 != nil:
    section.add "X-Amz-Content-Sha256", valid_607299
  var valid_607300 = header.getOrDefault("X-Amz-Date")
  valid_607300 = validateParameter(valid_607300, JString, required = false,
                                 default = nil)
  if valid_607300 != nil:
    section.add "X-Amz-Date", valid_607300
  var valid_607301 = header.getOrDefault("X-Amz-Credential")
  valid_607301 = validateParameter(valid_607301, JString, required = false,
                                 default = nil)
  if valid_607301 != nil:
    section.add "X-Amz-Credential", valid_607301
  var valid_607302 = header.getOrDefault("X-Amz-Security-Token")
  valid_607302 = validateParameter(valid_607302, JString, required = false,
                                 default = nil)
  if valid_607302 != nil:
    section.add "X-Amz-Security-Token", valid_607302
  var valid_607303 = header.getOrDefault("X-Amz-Algorithm")
  valid_607303 = validateParameter(valid_607303, JString, required = false,
                                 default = nil)
  if valid_607303 != nil:
    section.add "X-Amz-Algorithm", valid_607303
  var valid_607304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607304 = validateParameter(valid_607304, JString, required = false,
                                 default = nil)
  if valid_607304 != nil:
    section.add "X-Amz-SignedHeaders", valid_607304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607306: Call_ListUserPoolClients_607292; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the clients that have been created for the specified user pool.
  ## 
  let valid = call_607306.validator(path, query, header, formData, body)
  let scheme = call_607306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607306.url(scheme.get, call_607306.host, call_607306.base,
                         call_607306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607306, url, valid)

proc call*(call_607307: Call_ListUserPoolClients_607292; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listUserPoolClients
  ## Lists the clients that have been created for the specified user pool.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607308 = newJObject()
  var body_607309 = newJObject()
  add(query_607308, "MaxResults", newJString(MaxResults))
  add(query_607308, "NextToken", newJString(NextToken))
  if body != nil:
    body_607309 = body
  result = call_607307.call(nil, query_607308, nil, nil, body_607309)

var listUserPoolClients* = Call_ListUserPoolClients_607292(
    name: "listUserPoolClients", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUserPoolClients",
    validator: validate_ListUserPoolClients_607293, base: "/",
    url: url_ListUserPoolClients_607294, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserPools_607310 = ref object of OpenApiRestCall_605589
proc url_ListUserPools_607312(protocol: Scheme; host: string; base: string;
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

proc validate_ListUserPools_607311(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the user pools associated with an AWS account.
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
  var valid_607313 = query.getOrDefault("MaxResults")
  valid_607313 = validateParameter(valid_607313, JString, required = false,
                                 default = nil)
  if valid_607313 != nil:
    section.add "MaxResults", valid_607313
  var valid_607314 = query.getOrDefault("NextToken")
  valid_607314 = validateParameter(valid_607314, JString, required = false,
                                 default = nil)
  if valid_607314 != nil:
    section.add "NextToken", valid_607314
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
  var valid_607315 = header.getOrDefault("X-Amz-Target")
  valid_607315 = validateParameter(valid_607315, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUserPools"))
  if valid_607315 != nil:
    section.add "X-Amz-Target", valid_607315
  var valid_607316 = header.getOrDefault("X-Amz-Signature")
  valid_607316 = validateParameter(valid_607316, JString, required = false,
                                 default = nil)
  if valid_607316 != nil:
    section.add "X-Amz-Signature", valid_607316
  var valid_607317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607317 = validateParameter(valid_607317, JString, required = false,
                                 default = nil)
  if valid_607317 != nil:
    section.add "X-Amz-Content-Sha256", valid_607317
  var valid_607318 = header.getOrDefault("X-Amz-Date")
  valid_607318 = validateParameter(valid_607318, JString, required = false,
                                 default = nil)
  if valid_607318 != nil:
    section.add "X-Amz-Date", valid_607318
  var valid_607319 = header.getOrDefault("X-Amz-Credential")
  valid_607319 = validateParameter(valid_607319, JString, required = false,
                                 default = nil)
  if valid_607319 != nil:
    section.add "X-Amz-Credential", valid_607319
  var valid_607320 = header.getOrDefault("X-Amz-Security-Token")
  valid_607320 = validateParameter(valid_607320, JString, required = false,
                                 default = nil)
  if valid_607320 != nil:
    section.add "X-Amz-Security-Token", valid_607320
  var valid_607321 = header.getOrDefault("X-Amz-Algorithm")
  valid_607321 = validateParameter(valid_607321, JString, required = false,
                                 default = nil)
  if valid_607321 != nil:
    section.add "X-Amz-Algorithm", valid_607321
  var valid_607322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607322 = validateParameter(valid_607322, JString, required = false,
                                 default = nil)
  if valid_607322 != nil:
    section.add "X-Amz-SignedHeaders", valid_607322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607324: Call_ListUserPools_607310; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the user pools associated with an AWS account.
  ## 
  let valid = call_607324.validator(path, query, header, formData, body)
  let scheme = call_607324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607324.url(scheme.get, call_607324.host, call_607324.base,
                         call_607324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607324, url, valid)

proc call*(call_607325: Call_ListUserPools_607310; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listUserPools
  ## Lists the user pools associated with an AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607326 = newJObject()
  var body_607327 = newJObject()
  add(query_607326, "MaxResults", newJString(MaxResults))
  add(query_607326, "NextToken", newJString(NextToken))
  if body != nil:
    body_607327 = body
  result = call_607325.call(nil, query_607326, nil, nil, body_607327)

var listUserPools* = Call_ListUserPools_607310(name: "listUserPools",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUserPools",
    validator: validate_ListUserPools_607311, base: "/", url: url_ListUserPools_607312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_607328 = ref object of OpenApiRestCall_605589
proc url_ListUsers_607330(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListUsers_607329(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607331 = query.getOrDefault("Limit")
  valid_607331 = validateParameter(valid_607331, JString, required = false,
                                 default = nil)
  if valid_607331 != nil:
    section.add "Limit", valid_607331
  var valid_607332 = query.getOrDefault("PaginationToken")
  valid_607332 = validateParameter(valid_607332, JString, required = false,
                                 default = nil)
  if valid_607332 != nil:
    section.add "PaginationToken", valid_607332
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
  var valid_607333 = header.getOrDefault("X-Amz-Target")
  valid_607333 = validateParameter(valid_607333, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUsers"))
  if valid_607333 != nil:
    section.add "X-Amz-Target", valid_607333
  var valid_607334 = header.getOrDefault("X-Amz-Signature")
  valid_607334 = validateParameter(valid_607334, JString, required = false,
                                 default = nil)
  if valid_607334 != nil:
    section.add "X-Amz-Signature", valid_607334
  var valid_607335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607335 = validateParameter(valid_607335, JString, required = false,
                                 default = nil)
  if valid_607335 != nil:
    section.add "X-Amz-Content-Sha256", valid_607335
  var valid_607336 = header.getOrDefault("X-Amz-Date")
  valid_607336 = validateParameter(valid_607336, JString, required = false,
                                 default = nil)
  if valid_607336 != nil:
    section.add "X-Amz-Date", valid_607336
  var valid_607337 = header.getOrDefault("X-Amz-Credential")
  valid_607337 = validateParameter(valid_607337, JString, required = false,
                                 default = nil)
  if valid_607337 != nil:
    section.add "X-Amz-Credential", valid_607337
  var valid_607338 = header.getOrDefault("X-Amz-Security-Token")
  valid_607338 = validateParameter(valid_607338, JString, required = false,
                                 default = nil)
  if valid_607338 != nil:
    section.add "X-Amz-Security-Token", valid_607338
  var valid_607339 = header.getOrDefault("X-Amz-Algorithm")
  valid_607339 = validateParameter(valid_607339, JString, required = false,
                                 default = nil)
  if valid_607339 != nil:
    section.add "X-Amz-Algorithm", valid_607339
  var valid_607340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607340 = validateParameter(valid_607340, JString, required = false,
                                 default = nil)
  if valid_607340 != nil:
    section.add "X-Amz-SignedHeaders", valid_607340
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607342: Call_ListUsers_607328; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the users in the Amazon Cognito user pool.
  ## 
  let valid = call_607342.validator(path, query, header, formData, body)
  let scheme = call_607342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607342.url(scheme.get, call_607342.host, call_607342.base,
                         call_607342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607342, url, valid)

proc call*(call_607343: Call_ListUsers_607328; body: JsonNode; Limit: string = "";
          PaginationToken: string = ""): Recallable =
  ## listUsers
  ## Lists the users in the Amazon Cognito user pool.
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  ##   PaginationToken: string
  ##                  : Pagination token
  var query_607344 = newJObject()
  var body_607345 = newJObject()
  add(query_607344, "Limit", newJString(Limit))
  if body != nil:
    body_607345 = body
  add(query_607344, "PaginationToken", newJString(PaginationToken))
  result = call_607343.call(nil, query_607344, nil, nil, body_607345)

var listUsers* = Call_ListUsers_607328(name: "listUsers", meth: HttpMethod.HttpPost,
                                    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUsers",
                                    validator: validate_ListUsers_607329,
                                    base: "/", url: url_ListUsers_607330,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsersInGroup_607346 = ref object of OpenApiRestCall_605589
proc url_ListUsersInGroup_607348(protocol: Scheme; host: string; base: string;
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

proc validate_ListUsersInGroup_607347(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Lists the users in the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   Limit: JString
  ##        : Pagination limit
  section = newJObject()
  var valid_607349 = query.getOrDefault("NextToken")
  valid_607349 = validateParameter(valid_607349, JString, required = false,
                                 default = nil)
  if valid_607349 != nil:
    section.add "NextToken", valid_607349
  var valid_607350 = query.getOrDefault("Limit")
  valid_607350 = validateParameter(valid_607350, JString, required = false,
                                 default = nil)
  if valid_607350 != nil:
    section.add "Limit", valid_607350
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
  var valid_607351 = header.getOrDefault("X-Amz-Target")
  valid_607351 = validateParameter(valid_607351, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUsersInGroup"))
  if valid_607351 != nil:
    section.add "X-Amz-Target", valid_607351
  var valid_607352 = header.getOrDefault("X-Amz-Signature")
  valid_607352 = validateParameter(valid_607352, JString, required = false,
                                 default = nil)
  if valid_607352 != nil:
    section.add "X-Amz-Signature", valid_607352
  var valid_607353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607353 = validateParameter(valid_607353, JString, required = false,
                                 default = nil)
  if valid_607353 != nil:
    section.add "X-Amz-Content-Sha256", valid_607353
  var valid_607354 = header.getOrDefault("X-Amz-Date")
  valid_607354 = validateParameter(valid_607354, JString, required = false,
                                 default = nil)
  if valid_607354 != nil:
    section.add "X-Amz-Date", valid_607354
  var valid_607355 = header.getOrDefault("X-Amz-Credential")
  valid_607355 = validateParameter(valid_607355, JString, required = false,
                                 default = nil)
  if valid_607355 != nil:
    section.add "X-Amz-Credential", valid_607355
  var valid_607356 = header.getOrDefault("X-Amz-Security-Token")
  valid_607356 = validateParameter(valid_607356, JString, required = false,
                                 default = nil)
  if valid_607356 != nil:
    section.add "X-Amz-Security-Token", valid_607356
  var valid_607357 = header.getOrDefault("X-Amz-Algorithm")
  valid_607357 = validateParameter(valid_607357, JString, required = false,
                                 default = nil)
  if valid_607357 != nil:
    section.add "X-Amz-Algorithm", valid_607357
  var valid_607358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607358 = validateParameter(valid_607358, JString, required = false,
                                 default = nil)
  if valid_607358 != nil:
    section.add "X-Amz-SignedHeaders", valid_607358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607360: Call_ListUsersInGroup_607346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the users in the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_607360.validator(path, query, header, formData, body)
  let scheme = call_607360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607360.url(scheme.get, call_607360.host, call_607360.base,
                         call_607360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607360, url, valid)

proc call*(call_607361: Call_ListUsersInGroup_607346; body: JsonNode;
          NextToken: string = ""; Limit: string = ""): Recallable =
  ## listUsersInGroup
  ## <p>Lists the users in the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_607362 = newJObject()
  var body_607363 = newJObject()
  add(query_607362, "NextToken", newJString(NextToken))
  add(query_607362, "Limit", newJString(Limit))
  if body != nil:
    body_607363 = body
  result = call_607361.call(nil, query_607362, nil, nil, body_607363)

var listUsersInGroup* = Call_ListUsersInGroup_607346(name: "listUsersInGroup",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUsersInGroup",
    validator: validate_ListUsersInGroup_607347, base: "/",
    url: url_ListUsersInGroup_607348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResendConfirmationCode_607364 = ref object of OpenApiRestCall_605589
proc url_ResendConfirmationCode_607366(protocol: Scheme; host: string; base: string;
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

proc validate_ResendConfirmationCode_607365(path: JsonNode; query: JsonNode;
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
  var valid_607367 = header.getOrDefault("X-Amz-Target")
  valid_607367 = validateParameter(valid_607367, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ResendConfirmationCode"))
  if valid_607367 != nil:
    section.add "X-Amz-Target", valid_607367
  var valid_607368 = header.getOrDefault("X-Amz-Signature")
  valid_607368 = validateParameter(valid_607368, JString, required = false,
                                 default = nil)
  if valid_607368 != nil:
    section.add "X-Amz-Signature", valid_607368
  var valid_607369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607369 = validateParameter(valid_607369, JString, required = false,
                                 default = nil)
  if valid_607369 != nil:
    section.add "X-Amz-Content-Sha256", valid_607369
  var valid_607370 = header.getOrDefault("X-Amz-Date")
  valid_607370 = validateParameter(valid_607370, JString, required = false,
                                 default = nil)
  if valid_607370 != nil:
    section.add "X-Amz-Date", valid_607370
  var valid_607371 = header.getOrDefault("X-Amz-Credential")
  valid_607371 = validateParameter(valid_607371, JString, required = false,
                                 default = nil)
  if valid_607371 != nil:
    section.add "X-Amz-Credential", valid_607371
  var valid_607372 = header.getOrDefault("X-Amz-Security-Token")
  valid_607372 = validateParameter(valid_607372, JString, required = false,
                                 default = nil)
  if valid_607372 != nil:
    section.add "X-Amz-Security-Token", valid_607372
  var valid_607373 = header.getOrDefault("X-Amz-Algorithm")
  valid_607373 = validateParameter(valid_607373, JString, required = false,
                                 default = nil)
  if valid_607373 != nil:
    section.add "X-Amz-Algorithm", valid_607373
  var valid_607374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607374 = validateParameter(valid_607374, JString, required = false,
                                 default = nil)
  if valid_607374 != nil:
    section.add "X-Amz-SignedHeaders", valid_607374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607376: Call_ResendConfirmationCode_607364; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resends the confirmation (for confirmation of registration) to a specific user in the user pool.
  ## 
  let valid = call_607376.validator(path, query, header, formData, body)
  let scheme = call_607376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607376.url(scheme.get, call_607376.host, call_607376.base,
                         call_607376.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607376, url, valid)

proc call*(call_607377: Call_ResendConfirmationCode_607364; body: JsonNode): Recallable =
  ## resendConfirmationCode
  ## Resends the confirmation (for confirmation of registration) to a specific user in the user pool.
  ##   body: JObject (required)
  var body_607378 = newJObject()
  if body != nil:
    body_607378 = body
  result = call_607377.call(nil, nil, nil, nil, body_607378)

var resendConfirmationCode* = Call_ResendConfirmationCode_607364(
    name: "resendConfirmationCode", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ResendConfirmationCode",
    validator: validate_ResendConfirmationCode_607365, base: "/",
    url: url_ResendConfirmationCode_607366, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RespondToAuthChallenge_607379 = ref object of OpenApiRestCall_605589
proc url_RespondToAuthChallenge_607381(protocol: Scheme; host: string; base: string;
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

proc validate_RespondToAuthChallenge_607380(path: JsonNode; query: JsonNode;
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
  var valid_607382 = header.getOrDefault("X-Amz-Target")
  valid_607382 = validateParameter(valid_607382, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.RespondToAuthChallenge"))
  if valid_607382 != nil:
    section.add "X-Amz-Target", valid_607382
  var valid_607383 = header.getOrDefault("X-Amz-Signature")
  valid_607383 = validateParameter(valid_607383, JString, required = false,
                                 default = nil)
  if valid_607383 != nil:
    section.add "X-Amz-Signature", valid_607383
  var valid_607384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607384 = validateParameter(valid_607384, JString, required = false,
                                 default = nil)
  if valid_607384 != nil:
    section.add "X-Amz-Content-Sha256", valid_607384
  var valid_607385 = header.getOrDefault("X-Amz-Date")
  valid_607385 = validateParameter(valid_607385, JString, required = false,
                                 default = nil)
  if valid_607385 != nil:
    section.add "X-Amz-Date", valid_607385
  var valid_607386 = header.getOrDefault("X-Amz-Credential")
  valid_607386 = validateParameter(valid_607386, JString, required = false,
                                 default = nil)
  if valid_607386 != nil:
    section.add "X-Amz-Credential", valid_607386
  var valid_607387 = header.getOrDefault("X-Amz-Security-Token")
  valid_607387 = validateParameter(valid_607387, JString, required = false,
                                 default = nil)
  if valid_607387 != nil:
    section.add "X-Amz-Security-Token", valid_607387
  var valid_607388 = header.getOrDefault("X-Amz-Algorithm")
  valid_607388 = validateParameter(valid_607388, JString, required = false,
                                 default = nil)
  if valid_607388 != nil:
    section.add "X-Amz-Algorithm", valid_607388
  var valid_607389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607389 = validateParameter(valid_607389, JString, required = false,
                                 default = nil)
  if valid_607389 != nil:
    section.add "X-Amz-SignedHeaders", valid_607389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607391: Call_RespondToAuthChallenge_607379; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Responds to the authentication challenge.
  ## 
  let valid = call_607391.validator(path, query, header, formData, body)
  let scheme = call_607391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607391.url(scheme.get, call_607391.host, call_607391.base,
                         call_607391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607391, url, valid)

proc call*(call_607392: Call_RespondToAuthChallenge_607379; body: JsonNode): Recallable =
  ## respondToAuthChallenge
  ## Responds to the authentication challenge.
  ##   body: JObject (required)
  var body_607393 = newJObject()
  if body != nil:
    body_607393 = body
  result = call_607392.call(nil, nil, nil, nil, body_607393)

var respondToAuthChallenge* = Call_RespondToAuthChallenge_607379(
    name: "respondToAuthChallenge", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.RespondToAuthChallenge",
    validator: validate_RespondToAuthChallenge_607380, base: "/",
    url: url_RespondToAuthChallenge_607381, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetRiskConfiguration_607394 = ref object of OpenApiRestCall_605589
proc url_SetRiskConfiguration_607396(protocol: Scheme; host: string; base: string;
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

proc validate_SetRiskConfiguration_607395(path: JsonNode; query: JsonNode;
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
  var valid_607397 = header.getOrDefault("X-Amz-Target")
  valid_607397 = validateParameter(valid_607397, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetRiskConfiguration"))
  if valid_607397 != nil:
    section.add "X-Amz-Target", valid_607397
  var valid_607398 = header.getOrDefault("X-Amz-Signature")
  valid_607398 = validateParameter(valid_607398, JString, required = false,
                                 default = nil)
  if valid_607398 != nil:
    section.add "X-Amz-Signature", valid_607398
  var valid_607399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607399 = validateParameter(valid_607399, JString, required = false,
                                 default = nil)
  if valid_607399 != nil:
    section.add "X-Amz-Content-Sha256", valid_607399
  var valid_607400 = header.getOrDefault("X-Amz-Date")
  valid_607400 = validateParameter(valid_607400, JString, required = false,
                                 default = nil)
  if valid_607400 != nil:
    section.add "X-Amz-Date", valid_607400
  var valid_607401 = header.getOrDefault("X-Amz-Credential")
  valid_607401 = validateParameter(valid_607401, JString, required = false,
                                 default = nil)
  if valid_607401 != nil:
    section.add "X-Amz-Credential", valid_607401
  var valid_607402 = header.getOrDefault("X-Amz-Security-Token")
  valid_607402 = validateParameter(valid_607402, JString, required = false,
                                 default = nil)
  if valid_607402 != nil:
    section.add "X-Amz-Security-Token", valid_607402
  var valid_607403 = header.getOrDefault("X-Amz-Algorithm")
  valid_607403 = validateParameter(valid_607403, JString, required = false,
                                 default = nil)
  if valid_607403 != nil:
    section.add "X-Amz-Algorithm", valid_607403
  var valid_607404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607404 = validateParameter(valid_607404, JString, required = false,
                                 default = nil)
  if valid_607404 != nil:
    section.add "X-Amz-SignedHeaders", valid_607404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607406: Call_SetRiskConfiguration_607394; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configures actions on detected risks. To delete the risk configuration for <code>UserPoolId</code> or <code>ClientId</code>, pass null values for all four configuration types.</p> <p>To enable Amazon Cognito advanced security features, update the user pool to include the <code>UserPoolAddOns</code> key<code>AdvancedSecurityMode</code>.</p> <p>See .</p>
  ## 
  let valid = call_607406.validator(path, query, header, formData, body)
  let scheme = call_607406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607406.url(scheme.get, call_607406.host, call_607406.base,
                         call_607406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607406, url, valid)

proc call*(call_607407: Call_SetRiskConfiguration_607394; body: JsonNode): Recallable =
  ## setRiskConfiguration
  ## <p>Configures actions on detected risks. To delete the risk configuration for <code>UserPoolId</code> or <code>ClientId</code>, pass null values for all four configuration types.</p> <p>To enable Amazon Cognito advanced security features, update the user pool to include the <code>UserPoolAddOns</code> key<code>AdvancedSecurityMode</code>.</p> <p>See .</p>
  ##   body: JObject (required)
  var body_607408 = newJObject()
  if body != nil:
    body_607408 = body
  result = call_607407.call(nil, nil, nil, nil, body_607408)

var setRiskConfiguration* = Call_SetRiskConfiguration_607394(
    name: "setRiskConfiguration", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetRiskConfiguration",
    validator: validate_SetRiskConfiguration_607395, base: "/",
    url: url_SetRiskConfiguration_607396, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUICustomization_607409 = ref object of OpenApiRestCall_605589
proc url_SetUICustomization_607411(protocol: Scheme; host: string; base: string;
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

proc validate_SetUICustomization_607410(path: JsonNode; query: JsonNode;
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
  var valid_607412 = header.getOrDefault("X-Amz-Target")
  valid_607412 = validateParameter(valid_607412, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUICustomization"))
  if valid_607412 != nil:
    section.add "X-Amz-Target", valid_607412
  var valid_607413 = header.getOrDefault("X-Amz-Signature")
  valid_607413 = validateParameter(valid_607413, JString, required = false,
                                 default = nil)
  if valid_607413 != nil:
    section.add "X-Amz-Signature", valid_607413
  var valid_607414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607414 = validateParameter(valid_607414, JString, required = false,
                                 default = nil)
  if valid_607414 != nil:
    section.add "X-Amz-Content-Sha256", valid_607414
  var valid_607415 = header.getOrDefault("X-Amz-Date")
  valid_607415 = validateParameter(valid_607415, JString, required = false,
                                 default = nil)
  if valid_607415 != nil:
    section.add "X-Amz-Date", valid_607415
  var valid_607416 = header.getOrDefault("X-Amz-Credential")
  valid_607416 = validateParameter(valid_607416, JString, required = false,
                                 default = nil)
  if valid_607416 != nil:
    section.add "X-Amz-Credential", valid_607416
  var valid_607417 = header.getOrDefault("X-Amz-Security-Token")
  valid_607417 = validateParameter(valid_607417, JString, required = false,
                                 default = nil)
  if valid_607417 != nil:
    section.add "X-Amz-Security-Token", valid_607417
  var valid_607418 = header.getOrDefault("X-Amz-Algorithm")
  valid_607418 = validateParameter(valid_607418, JString, required = false,
                                 default = nil)
  if valid_607418 != nil:
    section.add "X-Amz-Algorithm", valid_607418
  var valid_607419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607419 = validateParameter(valid_607419, JString, required = false,
                                 default = nil)
  if valid_607419 != nil:
    section.add "X-Amz-SignedHeaders", valid_607419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607421: Call_SetUICustomization_607409; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the UI customization information for a user pool's built-in app UI.</p> <p>You can specify app UI customization settings for a single client (with a specific <code>clientId</code>) or for all clients (by setting the <code>clientId</code> to <code>ALL</code>). If you specify <code>ALL</code>, the default configuration will be used for every client that has no UI customization set previously. If you specify UI customization settings for a particular client, it will no longer fall back to the <code>ALL</code> configuration. </p> <note> <p>To use this API, your user pool must have a domain associated with it. Otherwise, there is no place to host the app's pages, and the service will throw an error.</p> </note>
  ## 
  let valid = call_607421.validator(path, query, header, formData, body)
  let scheme = call_607421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607421.url(scheme.get, call_607421.host, call_607421.base,
                         call_607421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607421, url, valid)

proc call*(call_607422: Call_SetUICustomization_607409; body: JsonNode): Recallable =
  ## setUICustomization
  ## <p>Sets the UI customization information for a user pool's built-in app UI.</p> <p>You can specify app UI customization settings for a single client (with a specific <code>clientId</code>) or for all clients (by setting the <code>clientId</code> to <code>ALL</code>). If you specify <code>ALL</code>, the default configuration will be used for every client that has no UI customization set previously. If you specify UI customization settings for a particular client, it will no longer fall back to the <code>ALL</code> configuration. </p> <note> <p>To use this API, your user pool must have a domain associated with it. Otherwise, there is no place to host the app's pages, and the service will throw an error.</p> </note>
  ##   body: JObject (required)
  var body_607423 = newJObject()
  if body != nil:
    body_607423 = body
  result = call_607422.call(nil, nil, nil, nil, body_607423)

var setUICustomization* = Call_SetUICustomization_607409(
    name: "setUICustomization", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUICustomization",
    validator: validate_SetUICustomization_607410, base: "/",
    url: url_SetUICustomization_607411, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUserMFAPreference_607424 = ref object of OpenApiRestCall_605589
proc url_SetUserMFAPreference_607426(protocol: Scheme; host: string; base: string;
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

proc validate_SetUserMFAPreference_607425(path: JsonNode; query: JsonNode;
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
  var valid_607427 = header.getOrDefault("X-Amz-Target")
  valid_607427 = validateParameter(valid_607427, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUserMFAPreference"))
  if valid_607427 != nil:
    section.add "X-Amz-Target", valid_607427
  var valid_607428 = header.getOrDefault("X-Amz-Signature")
  valid_607428 = validateParameter(valid_607428, JString, required = false,
                                 default = nil)
  if valid_607428 != nil:
    section.add "X-Amz-Signature", valid_607428
  var valid_607429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607429 = validateParameter(valid_607429, JString, required = false,
                                 default = nil)
  if valid_607429 != nil:
    section.add "X-Amz-Content-Sha256", valid_607429
  var valid_607430 = header.getOrDefault("X-Amz-Date")
  valid_607430 = validateParameter(valid_607430, JString, required = false,
                                 default = nil)
  if valid_607430 != nil:
    section.add "X-Amz-Date", valid_607430
  var valid_607431 = header.getOrDefault("X-Amz-Credential")
  valid_607431 = validateParameter(valid_607431, JString, required = false,
                                 default = nil)
  if valid_607431 != nil:
    section.add "X-Amz-Credential", valid_607431
  var valid_607432 = header.getOrDefault("X-Amz-Security-Token")
  valid_607432 = validateParameter(valid_607432, JString, required = false,
                                 default = nil)
  if valid_607432 != nil:
    section.add "X-Amz-Security-Token", valid_607432
  var valid_607433 = header.getOrDefault("X-Amz-Algorithm")
  valid_607433 = validateParameter(valid_607433, JString, required = false,
                                 default = nil)
  if valid_607433 != nil:
    section.add "X-Amz-Algorithm", valid_607433
  var valid_607434 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607434 = validateParameter(valid_607434, JString, required = false,
                                 default = nil)
  if valid_607434 != nil:
    section.add "X-Amz-SignedHeaders", valid_607434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607436: Call_SetUserMFAPreference_607424; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the user's multi-factor authentication (MFA) method preference, including which MFA factors are enabled and if any are preferred. Only one factor can be set as preferred. The preferred MFA factor will be used to authenticate a user if multiple factors are enabled. If multiple options are enabled and no preference is set, a challenge to choose an MFA option will be returned during sign in.
  ## 
  let valid = call_607436.validator(path, query, header, formData, body)
  let scheme = call_607436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607436.url(scheme.get, call_607436.host, call_607436.base,
                         call_607436.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607436, url, valid)

proc call*(call_607437: Call_SetUserMFAPreference_607424; body: JsonNode): Recallable =
  ## setUserMFAPreference
  ## Set the user's multi-factor authentication (MFA) method preference, including which MFA factors are enabled and if any are preferred. Only one factor can be set as preferred. The preferred MFA factor will be used to authenticate a user if multiple factors are enabled. If multiple options are enabled and no preference is set, a challenge to choose an MFA option will be returned during sign in.
  ##   body: JObject (required)
  var body_607438 = newJObject()
  if body != nil:
    body_607438 = body
  result = call_607437.call(nil, nil, nil, nil, body_607438)

var setUserMFAPreference* = Call_SetUserMFAPreference_607424(
    name: "setUserMFAPreference", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUserMFAPreference",
    validator: validate_SetUserMFAPreference_607425, base: "/",
    url: url_SetUserMFAPreference_607426, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUserPoolMfaConfig_607439 = ref object of OpenApiRestCall_605589
proc url_SetUserPoolMfaConfig_607441(protocol: Scheme; host: string; base: string;
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

proc validate_SetUserPoolMfaConfig_607440(path: JsonNode; query: JsonNode;
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
  var valid_607442 = header.getOrDefault("X-Amz-Target")
  valid_607442 = validateParameter(valid_607442, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUserPoolMfaConfig"))
  if valid_607442 != nil:
    section.add "X-Amz-Target", valid_607442
  var valid_607443 = header.getOrDefault("X-Amz-Signature")
  valid_607443 = validateParameter(valid_607443, JString, required = false,
                                 default = nil)
  if valid_607443 != nil:
    section.add "X-Amz-Signature", valid_607443
  var valid_607444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607444 = validateParameter(valid_607444, JString, required = false,
                                 default = nil)
  if valid_607444 != nil:
    section.add "X-Amz-Content-Sha256", valid_607444
  var valid_607445 = header.getOrDefault("X-Amz-Date")
  valid_607445 = validateParameter(valid_607445, JString, required = false,
                                 default = nil)
  if valid_607445 != nil:
    section.add "X-Amz-Date", valid_607445
  var valid_607446 = header.getOrDefault("X-Amz-Credential")
  valid_607446 = validateParameter(valid_607446, JString, required = false,
                                 default = nil)
  if valid_607446 != nil:
    section.add "X-Amz-Credential", valid_607446
  var valid_607447 = header.getOrDefault("X-Amz-Security-Token")
  valid_607447 = validateParameter(valid_607447, JString, required = false,
                                 default = nil)
  if valid_607447 != nil:
    section.add "X-Amz-Security-Token", valid_607447
  var valid_607448 = header.getOrDefault("X-Amz-Algorithm")
  valid_607448 = validateParameter(valid_607448, JString, required = false,
                                 default = nil)
  if valid_607448 != nil:
    section.add "X-Amz-Algorithm", valid_607448
  var valid_607449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607449 = validateParameter(valid_607449, JString, required = false,
                                 default = nil)
  if valid_607449 != nil:
    section.add "X-Amz-SignedHeaders", valid_607449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607451: Call_SetUserPoolMfaConfig_607439; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the user pool multi-factor authentication (MFA) configuration.
  ## 
  let valid = call_607451.validator(path, query, header, formData, body)
  let scheme = call_607451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607451.url(scheme.get, call_607451.host, call_607451.base,
                         call_607451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607451, url, valid)

proc call*(call_607452: Call_SetUserPoolMfaConfig_607439; body: JsonNode): Recallable =
  ## setUserPoolMfaConfig
  ## Set the user pool multi-factor authentication (MFA) configuration.
  ##   body: JObject (required)
  var body_607453 = newJObject()
  if body != nil:
    body_607453 = body
  result = call_607452.call(nil, nil, nil, nil, body_607453)

var setUserPoolMfaConfig* = Call_SetUserPoolMfaConfig_607439(
    name: "setUserPoolMfaConfig", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUserPoolMfaConfig",
    validator: validate_SetUserPoolMfaConfig_607440, base: "/",
    url: url_SetUserPoolMfaConfig_607441, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUserSettings_607454 = ref object of OpenApiRestCall_605589
proc url_SetUserSettings_607456(protocol: Scheme; host: string; base: string;
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

proc validate_SetUserSettings_607455(path: JsonNode; query: JsonNode;
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
  var valid_607457 = header.getOrDefault("X-Amz-Target")
  valid_607457 = validateParameter(valid_607457, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUserSettings"))
  if valid_607457 != nil:
    section.add "X-Amz-Target", valid_607457
  var valid_607458 = header.getOrDefault("X-Amz-Signature")
  valid_607458 = validateParameter(valid_607458, JString, required = false,
                                 default = nil)
  if valid_607458 != nil:
    section.add "X-Amz-Signature", valid_607458
  var valid_607459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607459 = validateParameter(valid_607459, JString, required = false,
                                 default = nil)
  if valid_607459 != nil:
    section.add "X-Amz-Content-Sha256", valid_607459
  var valid_607460 = header.getOrDefault("X-Amz-Date")
  valid_607460 = validateParameter(valid_607460, JString, required = false,
                                 default = nil)
  if valid_607460 != nil:
    section.add "X-Amz-Date", valid_607460
  var valid_607461 = header.getOrDefault("X-Amz-Credential")
  valid_607461 = validateParameter(valid_607461, JString, required = false,
                                 default = nil)
  if valid_607461 != nil:
    section.add "X-Amz-Credential", valid_607461
  var valid_607462 = header.getOrDefault("X-Amz-Security-Token")
  valid_607462 = validateParameter(valid_607462, JString, required = false,
                                 default = nil)
  if valid_607462 != nil:
    section.add "X-Amz-Security-Token", valid_607462
  var valid_607463 = header.getOrDefault("X-Amz-Algorithm")
  valid_607463 = validateParameter(valid_607463, JString, required = false,
                                 default = nil)
  if valid_607463 != nil:
    section.add "X-Amz-Algorithm", valid_607463
  var valid_607464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607464 = validateParameter(valid_607464, JString, required = false,
                                 default = nil)
  if valid_607464 != nil:
    section.add "X-Amz-SignedHeaders", valid_607464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607466: Call_SetUserSettings_607454; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <i>This action is no longer supported.</i> You can use it to configure only SMS MFA. You can't use it to configure TOTP software token MFA. To configure either type of MFA, use the <a>SetUserMFAPreference</a> action instead.
  ## 
  let valid = call_607466.validator(path, query, header, formData, body)
  let scheme = call_607466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607466.url(scheme.get, call_607466.host, call_607466.base,
                         call_607466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607466, url, valid)

proc call*(call_607467: Call_SetUserSettings_607454; body: JsonNode): Recallable =
  ## setUserSettings
  ##  <i>This action is no longer supported.</i> You can use it to configure only SMS MFA. You can't use it to configure TOTP software token MFA. To configure either type of MFA, use the <a>SetUserMFAPreference</a> action instead.
  ##   body: JObject (required)
  var body_607468 = newJObject()
  if body != nil:
    body_607468 = body
  result = call_607467.call(nil, nil, nil, nil, body_607468)

var setUserSettings* = Call_SetUserSettings_607454(name: "setUserSettings",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUserSettings",
    validator: validate_SetUserSettings_607455, base: "/", url: url_SetUserSettings_607456,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SignUp_607469 = ref object of OpenApiRestCall_605589
proc url_SignUp_607471(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_SignUp_607470(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607472 = header.getOrDefault("X-Amz-Target")
  valid_607472 = validateParameter(valid_607472, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SignUp"))
  if valid_607472 != nil:
    section.add "X-Amz-Target", valid_607472
  var valid_607473 = header.getOrDefault("X-Amz-Signature")
  valid_607473 = validateParameter(valid_607473, JString, required = false,
                                 default = nil)
  if valid_607473 != nil:
    section.add "X-Amz-Signature", valid_607473
  var valid_607474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607474 = validateParameter(valid_607474, JString, required = false,
                                 default = nil)
  if valid_607474 != nil:
    section.add "X-Amz-Content-Sha256", valid_607474
  var valid_607475 = header.getOrDefault("X-Amz-Date")
  valid_607475 = validateParameter(valid_607475, JString, required = false,
                                 default = nil)
  if valid_607475 != nil:
    section.add "X-Amz-Date", valid_607475
  var valid_607476 = header.getOrDefault("X-Amz-Credential")
  valid_607476 = validateParameter(valid_607476, JString, required = false,
                                 default = nil)
  if valid_607476 != nil:
    section.add "X-Amz-Credential", valid_607476
  var valid_607477 = header.getOrDefault("X-Amz-Security-Token")
  valid_607477 = validateParameter(valid_607477, JString, required = false,
                                 default = nil)
  if valid_607477 != nil:
    section.add "X-Amz-Security-Token", valid_607477
  var valid_607478 = header.getOrDefault("X-Amz-Algorithm")
  valid_607478 = validateParameter(valid_607478, JString, required = false,
                                 default = nil)
  if valid_607478 != nil:
    section.add "X-Amz-Algorithm", valid_607478
  var valid_607479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607479 = validateParameter(valid_607479, JString, required = false,
                                 default = nil)
  if valid_607479 != nil:
    section.add "X-Amz-SignedHeaders", valid_607479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607481: Call_SignUp_607469; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers the user in the specified user pool and creates a user name, password, and user attributes.
  ## 
  let valid = call_607481.validator(path, query, header, formData, body)
  let scheme = call_607481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607481.url(scheme.get, call_607481.host, call_607481.base,
                         call_607481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607481, url, valid)

proc call*(call_607482: Call_SignUp_607469; body: JsonNode): Recallable =
  ## signUp
  ## Registers the user in the specified user pool and creates a user name, password, and user attributes.
  ##   body: JObject (required)
  var body_607483 = newJObject()
  if body != nil:
    body_607483 = body
  result = call_607482.call(nil, nil, nil, nil, body_607483)

var signUp* = Call_SignUp_607469(name: "signUp", meth: HttpMethod.HttpPost,
                              host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SignUp",
                              validator: validate_SignUp_607470, base: "/",
                              url: url_SignUp_607471,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartUserImportJob_607484 = ref object of OpenApiRestCall_605589
proc url_StartUserImportJob_607486(protocol: Scheme; host: string; base: string;
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

proc validate_StartUserImportJob_607485(path: JsonNode; query: JsonNode;
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
  var valid_607487 = header.getOrDefault("X-Amz-Target")
  valid_607487 = validateParameter(valid_607487, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.StartUserImportJob"))
  if valid_607487 != nil:
    section.add "X-Amz-Target", valid_607487
  var valid_607488 = header.getOrDefault("X-Amz-Signature")
  valid_607488 = validateParameter(valid_607488, JString, required = false,
                                 default = nil)
  if valid_607488 != nil:
    section.add "X-Amz-Signature", valid_607488
  var valid_607489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607489 = validateParameter(valid_607489, JString, required = false,
                                 default = nil)
  if valid_607489 != nil:
    section.add "X-Amz-Content-Sha256", valid_607489
  var valid_607490 = header.getOrDefault("X-Amz-Date")
  valid_607490 = validateParameter(valid_607490, JString, required = false,
                                 default = nil)
  if valid_607490 != nil:
    section.add "X-Amz-Date", valid_607490
  var valid_607491 = header.getOrDefault("X-Amz-Credential")
  valid_607491 = validateParameter(valid_607491, JString, required = false,
                                 default = nil)
  if valid_607491 != nil:
    section.add "X-Amz-Credential", valid_607491
  var valid_607492 = header.getOrDefault("X-Amz-Security-Token")
  valid_607492 = validateParameter(valid_607492, JString, required = false,
                                 default = nil)
  if valid_607492 != nil:
    section.add "X-Amz-Security-Token", valid_607492
  var valid_607493 = header.getOrDefault("X-Amz-Algorithm")
  valid_607493 = validateParameter(valid_607493, JString, required = false,
                                 default = nil)
  if valid_607493 != nil:
    section.add "X-Amz-Algorithm", valid_607493
  var valid_607494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607494 = validateParameter(valid_607494, JString, required = false,
                                 default = nil)
  if valid_607494 != nil:
    section.add "X-Amz-SignedHeaders", valid_607494
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607496: Call_StartUserImportJob_607484; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the user import.
  ## 
  let valid = call_607496.validator(path, query, header, formData, body)
  let scheme = call_607496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607496.url(scheme.get, call_607496.host, call_607496.base,
                         call_607496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607496, url, valid)

proc call*(call_607497: Call_StartUserImportJob_607484; body: JsonNode): Recallable =
  ## startUserImportJob
  ## Starts the user import.
  ##   body: JObject (required)
  var body_607498 = newJObject()
  if body != nil:
    body_607498 = body
  result = call_607497.call(nil, nil, nil, nil, body_607498)

var startUserImportJob* = Call_StartUserImportJob_607484(
    name: "startUserImportJob", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.StartUserImportJob",
    validator: validate_StartUserImportJob_607485, base: "/",
    url: url_StartUserImportJob_607486, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopUserImportJob_607499 = ref object of OpenApiRestCall_605589
proc url_StopUserImportJob_607501(protocol: Scheme; host: string; base: string;
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

proc validate_StopUserImportJob_607500(path: JsonNode; query: JsonNode;
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
  var valid_607502 = header.getOrDefault("X-Amz-Target")
  valid_607502 = validateParameter(valid_607502, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.StopUserImportJob"))
  if valid_607502 != nil:
    section.add "X-Amz-Target", valid_607502
  var valid_607503 = header.getOrDefault("X-Amz-Signature")
  valid_607503 = validateParameter(valid_607503, JString, required = false,
                                 default = nil)
  if valid_607503 != nil:
    section.add "X-Amz-Signature", valid_607503
  var valid_607504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607504 = validateParameter(valid_607504, JString, required = false,
                                 default = nil)
  if valid_607504 != nil:
    section.add "X-Amz-Content-Sha256", valid_607504
  var valid_607505 = header.getOrDefault("X-Amz-Date")
  valid_607505 = validateParameter(valid_607505, JString, required = false,
                                 default = nil)
  if valid_607505 != nil:
    section.add "X-Amz-Date", valid_607505
  var valid_607506 = header.getOrDefault("X-Amz-Credential")
  valid_607506 = validateParameter(valid_607506, JString, required = false,
                                 default = nil)
  if valid_607506 != nil:
    section.add "X-Amz-Credential", valid_607506
  var valid_607507 = header.getOrDefault("X-Amz-Security-Token")
  valid_607507 = validateParameter(valid_607507, JString, required = false,
                                 default = nil)
  if valid_607507 != nil:
    section.add "X-Amz-Security-Token", valid_607507
  var valid_607508 = header.getOrDefault("X-Amz-Algorithm")
  valid_607508 = validateParameter(valid_607508, JString, required = false,
                                 default = nil)
  if valid_607508 != nil:
    section.add "X-Amz-Algorithm", valid_607508
  var valid_607509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607509 = validateParameter(valid_607509, JString, required = false,
                                 default = nil)
  if valid_607509 != nil:
    section.add "X-Amz-SignedHeaders", valid_607509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607511: Call_StopUserImportJob_607499; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the user import job.
  ## 
  let valid = call_607511.validator(path, query, header, formData, body)
  let scheme = call_607511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607511.url(scheme.get, call_607511.host, call_607511.base,
                         call_607511.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607511, url, valid)

proc call*(call_607512: Call_StopUserImportJob_607499; body: JsonNode): Recallable =
  ## stopUserImportJob
  ## Stops the user import job.
  ##   body: JObject (required)
  var body_607513 = newJObject()
  if body != nil:
    body_607513 = body
  result = call_607512.call(nil, nil, nil, nil, body_607513)

var stopUserImportJob* = Call_StopUserImportJob_607499(name: "stopUserImportJob",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.StopUserImportJob",
    validator: validate_StopUserImportJob_607500, base: "/",
    url: url_StopUserImportJob_607501, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_607514 = ref object of OpenApiRestCall_605589
proc url_TagResource_607516(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_607515(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607517 = header.getOrDefault("X-Amz-Target")
  valid_607517 = validateParameter(valid_607517, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.TagResource"))
  if valid_607517 != nil:
    section.add "X-Amz-Target", valid_607517
  var valid_607518 = header.getOrDefault("X-Amz-Signature")
  valid_607518 = validateParameter(valid_607518, JString, required = false,
                                 default = nil)
  if valid_607518 != nil:
    section.add "X-Amz-Signature", valid_607518
  var valid_607519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607519 = validateParameter(valid_607519, JString, required = false,
                                 default = nil)
  if valid_607519 != nil:
    section.add "X-Amz-Content-Sha256", valid_607519
  var valid_607520 = header.getOrDefault("X-Amz-Date")
  valid_607520 = validateParameter(valid_607520, JString, required = false,
                                 default = nil)
  if valid_607520 != nil:
    section.add "X-Amz-Date", valid_607520
  var valid_607521 = header.getOrDefault("X-Amz-Credential")
  valid_607521 = validateParameter(valid_607521, JString, required = false,
                                 default = nil)
  if valid_607521 != nil:
    section.add "X-Amz-Credential", valid_607521
  var valid_607522 = header.getOrDefault("X-Amz-Security-Token")
  valid_607522 = validateParameter(valid_607522, JString, required = false,
                                 default = nil)
  if valid_607522 != nil:
    section.add "X-Amz-Security-Token", valid_607522
  var valid_607523 = header.getOrDefault("X-Amz-Algorithm")
  valid_607523 = validateParameter(valid_607523, JString, required = false,
                                 default = nil)
  if valid_607523 != nil:
    section.add "X-Amz-Algorithm", valid_607523
  var valid_607524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607524 = validateParameter(valid_607524, JString, required = false,
                                 default = nil)
  if valid_607524 != nil:
    section.add "X-Amz-SignedHeaders", valid_607524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607526: Call_TagResource_607514; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns a set of tags to an Amazon Cognito user pool. A tag is a label that you can use to categorize and manage user pools in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>Each tag consists of a key and value, both of which you define. A key is a general category for more specific values. For example, if you have two versions of a user pool, one for testing and another for production, you might assign an <code>Environment</code> tag key to both user pools. The value of this key might be <code>Test</code> for one user pool and <code>Production</code> for the other.</p> <p>Tags are useful for cost tracking and access control. You can activate your tags so that they appear on the Billing and Cost Management console, where you can track the costs associated with your user pools. In an IAM policy, you can constrain permissions for user pools based on specific tags or tag values.</p> <p>You can use this action up to 5 times per second, per account. A user pool can have as many as 50 tags.</p>
  ## 
  let valid = call_607526.validator(path, query, header, formData, body)
  let scheme = call_607526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607526.url(scheme.get, call_607526.host, call_607526.base,
                         call_607526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607526, url, valid)

proc call*(call_607527: Call_TagResource_607514; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Assigns a set of tags to an Amazon Cognito user pool. A tag is a label that you can use to categorize and manage user pools in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>Each tag consists of a key and value, both of which you define. A key is a general category for more specific values. For example, if you have two versions of a user pool, one for testing and another for production, you might assign an <code>Environment</code> tag key to both user pools. The value of this key might be <code>Test</code> for one user pool and <code>Production</code> for the other.</p> <p>Tags are useful for cost tracking and access control. You can activate your tags so that they appear on the Billing and Cost Management console, where you can track the costs associated with your user pools. In an IAM policy, you can constrain permissions for user pools based on specific tags or tag values.</p> <p>You can use this action up to 5 times per second, per account. A user pool can have as many as 50 tags.</p>
  ##   body: JObject (required)
  var body_607528 = newJObject()
  if body != nil:
    body_607528 = body
  result = call_607527.call(nil, nil, nil, nil, body_607528)

var tagResource* = Call_TagResource_607514(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.TagResource",
                                        validator: validate_TagResource_607515,
                                        base: "/", url: url_TagResource_607516,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_607529 = ref object of OpenApiRestCall_605589
proc url_UntagResource_607531(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_607530(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607532 = header.getOrDefault("X-Amz-Target")
  valid_607532 = validateParameter(valid_607532, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UntagResource"))
  if valid_607532 != nil:
    section.add "X-Amz-Target", valid_607532
  var valid_607533 = header.getOrDefault("X-Amz-Signature")
  valid_607533 = validateParameter(valid_607533, JString, required = false,
                                 default = nil)
  if valid_607533 != nil:
    section.add "X-Amz-Signature", valid_607533
  var valid_607534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607534 = validateParameter(valid_607534, JString, required = false,
                                 default = nil)
  if valid_607534 != nil:
    section.add "X-Amz-Content-Sha256", valid_607534
  var valid_607535 = header.getOrDefault("X-Amz-Date")
  valid_607535 = validateParameter(valid_607535, JString, required = false,
                                 default = nil)
  if valid_607535 != nil:
    section.add "X-Amz-Date", valid_607535
  var valid_607536 = header.getOrDefault("X-Amz-Credential")
  valid_607536 = validateParameter(valid_607536, JString, required = false,
                                 default = nil)
  if valid_607536 != nil:
    section.add "X-Amz-Credential", valid_607536
  var valid_607537 = header.getOrDefault("X-Amz-Security-Token")
  valid_607537 = validateParameter(valid_607537, JString, required = false,
                                 default = nil)
  if valid_607537 != nil:
    section.add "X-Amz-Security-Token", valid_607537
  var valid_607538 = header.getOrDefault("X-Amz-Algorithm")
  valid_607538 = validateParameter(valid_607538, JString, required = false,
                                 default = nil)
  if valid_607538 != nil:
    section.add "X-Amz-Algorithm", valid_607538
  var valid_607539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607539 = validateParameter(valid_607539, JString, required = false,
                                 default = nil)
  if valid_607539 != nil:
    section.add "X-Amz-SignedHeaders", valid_607539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607541: Call_UntagResource_607529; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified tags from an Amazon Cognito user pool. You can use this action up to 5 times per second, per account
  ## 
  let valid = call_607541.validator(path, query, header, formData, body)
  let scheme = call_607541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607541.url(scheme.get, call_607541.host, call_607541.base,
                         call_607541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607541, url, valid)

proc call*(call_607542: Call_UntagResource_607529; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tags from an Amazon Cognito user pool. You can use this action up to 5 times per second, per account
  ##   body: JObject (required)
  var body_607543 = newJObject()
  if body != nil:
    body_607543 = body
  result = call_607542.call(nil, nil, nil, nil, body_607543)

var untagResource* = Call_UntagResource_607529(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UntagResource",
    validator: validate_UntagResource_607530, base: "/", url: url_UntagResource_607531,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthEventFeedback_607544 = ref object of OpenApiRestCall_605589
proc url_UpdateAuthEventFeedback_607546(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAuthEventFeedback_607545(path: JsonNode; query: JsonNode;
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
  var valid_607547 = header.getOrDefault("X-Amz-Target")
  valid_607547 = validateParameter(valid_607547, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateAuthEventFeedback"))
  if valid_607547 != nil:
    section.add "X-Amz-Target", valid_607547
  var valid_607548 = header.getOrDefault("X-Amz-Signature")
  valid_607548 = validateParameter(valid_607548, JString, required = false,
                                 default = nil)
  if valid_607548 != nil:
    section.add "X-Amz-Signature", valid_607548
  var valid_607549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607549 = validateParameter(valid_607549, JString, required = false,
                                 default = nil)
  if valid_607549 != nil:
    section.add "X-Amz-Content-Sha256", valid_607549
  var valid_607550 = header.getOrDefault("X-Amz-Date")
  valid_607550 = validateParameter(valid_607550, JString, required = false,
                                 default = nil)
  if valid_607550 != nil:
    section.add "X-Amz-Date", valid_607550
  var valid_607551 = header.getOrDefault("X-Amz-Credential")
  valid_607551 = validateParameter(valid_607551, JString, required = false,
                                 default = nil)
  if valid_607551 != nil:
    section.add "X-Amz-Credential", valid_607551
  var valid_607552 = header.getOrDefault("X-Amz-Security-Token")
  valid_607552 = validateParameter(valid_607552, JString, required = false,
                                 default = nil)
  if valid_607552 != nil:
    section.add "X-Amz-Security-Token", valid_607552
  var valid_607553 = header.getOrDefault("X-Amz-Algorithm")
  valid_607553 = validateParameter(valid_607553, JString, required = false,
                                 default = nil)
  if valid_607553 != nil:
    section.add "X-Amz-Algorithm", valid_607553
  var valid_607554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607554 = validateParameter(valid_607554, JString, required = false,
                                 default = nil)
  if valid_607554 != nil:
    section.add "X-Amz-SignedHeaders", valid_607554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607556: Call_UpdateAuthEventFeedback_607544; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the feedback for an authentication event whether it was from a valid user or not. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ## 
  let valid = call_607556.validator(path, query, header, formData, body)
  let scheme = call_607556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607556.url(scheme.get, call_607556.host, call_607556.base,
                         call_607556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607556, url, valid)

proc call*(call_607557: Call_UpdateAuthEventFeedback_607544; body: JsonNode): Recallable =
  ## updateAuthEventFeedback
  ## Provides the feedback for an authentication event whether it was from a valid user or not. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ##   body: JObject (required)
  var body_607558 = newJObject()
  if body != nil:
    body_607558 = body
  result = call_607557.call(nil, nil, nil, nil, body_607558)

var updateAuthEventFeedback* = Call_UpdateAuthEventFeedback_607544(
    name: "updateAuthEventFeedback", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateAuthEventFeedback",
    validator: validate_UpdateAuthEventFeedback_607545, base: "/",
    url: url_UpdateAuthEventFeedback_607546, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceStatus_607559 = ref object of OpenApiRestCall_605589
proc url_UpdateDeviceStatus_607561(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDeviceStatus_607560(path: JsonNode; query: JsonNode;
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
  var valid_607562 = header.getOrDefault("X-Amz-Target")
  valid_607562 = validateParameter(valid_607562, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateDeviceStatus"))
  if valid_607562 != nil:
    section.add "X-Amz-Target", valid_607562
  var valid_607563 = header.getOrDefault("X-Amz-Signature")
  valid_607563 = validateParameter(valid_607563, JString, required = false,
                                 default = nil)
  if valid_607563 != nil:
    section.add "X-Amz-Signature", valid_607563
  var valid_607564 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607564 = validateParameter(valid_607564, JString, required = false,
                                 default = nil)
  if valid_607564 != nil:
    section.add "X-Amz-Content-Sha256", valid_607564
  var valid_607565 = header.getOrDefault("X-Amz-Date")
  valid_607565 = validateParameter(valid_607565, JString, required = false,
                                 default = nil)
  if valid_607565 != nil:
    section.add "X-Amz-Date", valid_607565
  var valid_607566 = header.getOrDefault("X-Amz-Credential")
  valid_607566 = validateParameter(valid_607566, JString, required = false,
                                 default = nil)
  if valid_607566 != nil:
    section.add "X-Amz-Credential", valid_607566
  var valid_607567 = header.getOrDefault("X-Amz-Security-Token")
  valid_607567 = validateParameter(valid_607567, JString, required = false,
                                 default = nil)
  if valid_607567 != nil:
    section.add "X-Amz-Security-Token", valid_607567
  var valid_607568 = header.getOrDefault("X-Amz-Algorithm")
  valid_607568 = validateParameter(valid_607568, JString, required = false,
                                 default = nil)
  if valid_607568 != nil:
    section.add "X-Amz-Algorithm", valid_607568
  var valid_607569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607569 = validateParameter(valid_607569, JString, required = false,
                                 default = nil)
  if valid_607569 != nil:
    section.add "X-Amz-SignedHeaders", valid_607569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607571: Call_UpdateDeviceStatus_607559; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the device status.
  ## 
  let valid = call_607571.validator(path, query, header, formData, body)
  let scheme = call_607571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607571.url(scheme.get, call_607571.host, call_607571.base,
                         call_607571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607571, url, valid)

proc call*(call_607572: Call_UpdateDeviceStatus_607559; body: JsonNode): Recallable =
  ## updateDeviceStatus
  ## Updates the device status.
  ##   body: JObject (required)
  var body_607573 = newJObject()
  if body != nil:
    body_607573 = body
  result = call_607572.call(nil, nil, nil, nil, body_607573)

var updateDeviceStatus* = Call_UpdateDeviceStatus_607559(
    name: "updateDeviceStatus", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateDeviceStatus",
    validator: validate_UpdateDeviceStatus_607560, base: "/",
    url: url_UpdateDeviceStatus_607561, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_607574 = ref object of OpenApiRestCall_605589
proc url_UpdateGroup_607576(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGroup_607575(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607577 = header.getOrDefault("X-Amz-Target")
  valid_607577 = validateParameter(valid_607577, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateGroup"))
  if valid_607577 != nil:
    section.add "X-Amz-Target", valid_607577
  var valid_607578 = header.getOrDefault("X-Amz-Signature")
  valid_607578 = validateParameter(valid_607578, JString, required = false,
                                 default = nil)
  if valid_607578 != nil:
    section.add "X-Amz-Signature", valid_607578
  var valid_607579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607579 = validateParameter(valid_607579, JString, required = false,
                                 default = nil)
  if valid_607579 != nil:
    section.add "X-Amz-Content-Sha256", valid_607579
  var valid_607580 = header.getOrDefault("X-Amz-Date")
  valid_607580 = validateParameter(valid_607580, JString, required = false,
                                 default = nil)
  if valid_607580 != nil:
    section.add "X-Amz-Date", valid_607580
  var valid_607581 = header.getOrDefault("X-Amz-Credential")
  valid_607581 = validateParameter(valid_607581, JString, required = false,
                                 default = nil)
  if valid_607581 != nil:
    section.add "X-Amz-Credential", valid_607581
  var valid_607582 = header.getOrDefault("X-Amz-Security-Token")
  valid_607582 = validateParameter(valid_607582, JString, required = false,
                                 default = nil)
  if valid_607582 != nil:
    section.add "X-Amz-Security-Token", valid_607582
  var valid_607583 = header.getOrDefault("X-Amz-Algorithm")
  valid_607583 = validateParameter(valid_607583, JString, required = false,
                                 default = nil)
  if valid_607583 != nil:
    section.add "X-Amz-Algorithm", valid_607583
  var valid_607584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607584 = validateParameter(valid_607584, JString, required = false,
                                 default = nil)
  if valid_607584 != nil:
    section.add "X-Amz-SignedHeaders", valid_607584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607586: Call_UpdateGroup_607574; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified group with the specified attributes.</p> <p>Calling this action requires developer credentials.</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ## 
  let valid = call_607586.validator(path, query, header, formData, body)
  let scheme = call_607586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607586.url(scheme.get, call_607586.host, call_607586.base,
                         call_607586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607586, url, valid)

proc call*(call_607587: Call_UpdateGroup_607574; body: JsonNode): Recallable =
  ## updateGroup
  ## <p>Updates the specified group with the specified attributes.</p> <p>Calling this action requires developer credentials.</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ##   body: JObject (required)
  var body_607588 = newJObject()
  if body != nil:
    body_607588 = body
  result = call_607587.call(nil, nil, nil, nil, body_607588)

var updateGroup* = Call_UpdateGroup_607574(name: "updateGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateGroup",
                                        validator: validate_UpdateGroup_607575,
                                        base: "/", url: url_UpdateGroup_607576,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIdentityProvider_607589 = ref object of OpenApiRestCall_605589
proc url_UpdateIdentityProvider_607591(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateIdentityProvider_607590(path: JsonNode; query: JsonNode;
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
  var valid_607592 = header.getOrDefault("X-Amz-Target")
  valid_607592 = validateParameter(valid_607592, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateIdentityProvider"))
  if valid_607592 != nil:
    section.add "X-Amz-Target", valid_607592
  var valid_607593 = header.getOrDefault("X-Amz-Signature")
  valid_607593 = validateParameter(valid_607593, JString, required = false,
                                 default = nil)
  if valid_607593 != nil:
    section.add "X-Amz-Signature", valid_607593
  var valid_607594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607594 = validateParameter(valid_607594, JString, required = false,
                                 default = nil)
  if valid_607594 != nil:
    section.add "X-Amz-Content-Sha256", valid_607594
  var valid_607595 = header.getOrDefault("X-Amz-Date")
  valid_607595 = validateParameter(valid_607595, JString, required = false,
                                 default = nil)
  if valid_607595 != nil:
    section.add "X-Amz-Date", valid_607595
  var valid_607596 = header.getOrDefault("X-Amz-Credential")
  valid_607596 = validateParameter(valid_607596, JString, required = false,
                                 default = nil)
  if valid_607596 != nil:
    section.add "X-Amz-Credential", valid_607596
  var valid_607597 = header.getOrDefault("X-Amz-Security-Token")
  valid_607597 = validateParameter(valid_607597, JString, required = false,
                                 default = nil)
  if valid_607597 != nil:
    section.add "X-Amz-Security-Token", valid_607597
  var valid_607598 = header.getOrDefault("X-Amz-Algorithm")
  valid_607598 = validateParameter(valid_607598, JString, required = false,
                                 default = nil)
  if valid_607598 != nil:
    section.add "X-Amz-Algorithm", valid_607598
  var valid_607599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607599 = validateParameter(valid_607599, JString, required = false,
                                 default = nil)
  if valid_607599 != nil:
    section.add "X-Amz-SignedHeaders", valid_607599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607601: Call_UpdateIdentityProvider_607589; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates identity provider information for a user pool.
  ## 
  let valid = call_607601.validator(path, query, header, formData, body)
  let scheme = call_607601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607601.url(scheme.get, call_607601.host, call_607601.base,
                         call_607601.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607601, url, valid)

proc call*(call_607602: Call_UpdateIdentityProvider_607589; body: JsonNode): Recallable =
  ## updateIdentityProvider
  ## Updates identity provider information for a user pool.
  ##   body: JObject (required)
  var body_607603 = newJObject()
  if body != nil:
    body_607603 = body
  result = call_607602.call(nil, nil, nil, nil, body_607603)

var updateIdentityProvider* = Call_UpdateIdentityProvider_607589(
    name: "updateIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateIdentityProvider",
    validator: validate_UpdateIdentityProvider_607590, base: "/",
    url: url_UpdateIdentityProvider_607591, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceServer_607604 = ref object of OpenApiRestCall_605589
proc url_UpdateResourceServer_607606(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateResourceServer_607605(path: JsonNode; query: JsonNode;
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
  var valid_607607 = header.getOrDefault("X-Amz-Target")
  valid_607607 = validateParameter(valid_607607, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateResourceServer"))
  if valid_607607 != nil:
    section.add "X-Amz-Target", valid_607607
  var valid_607608 = header.getOrDefault("X-Amz-Signature")
  valid_607608 = validateParameter(valid_607608, JString, required = false,
                                 default = nil)
  if valid_607608 != nil:
    section.add "X-Amz-Signature", valid_607608
  var valid_607609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607609 = validateParameter(valid_607609, JString, required = false,
                                 default = nil)
  if valid_607609 != nil:
    section.add "X-Amz-Content-Sha256", valid_607609
  var valid_607610 = header.getOrDefault("X-Amz-Date")
  valid_607610 = validateParameter(valid_607610, JString, required = false,
                                 default = nil)
  if valid_607610 != nil:
    section.add "X-Amz-Date", valid_607610
  var valid_607611 = header.getOrDefault("X-Amz-Credential")
  valid_607611 = validateParameter(valid_607611, JString, required = false,
                                 default = nil)
  if valid_607611 != nil:
    section.add "X-Amz-Credential", valid_607611
  var valid_607612 = header.getOrDefault("X-Amz-Security-Token")
  valid_607612 = validateParameter(valid_607612, JString, required = false,
                                 default = nil)
  if valid_607612 != nil:
    section.add "X-Amz-Security-Token", valid_607612
  var valid_607613 = header.getOrDefault("X-Amz-Algorithm")
  valid_607613 = validateParameter(valid_607613, JString, required = false,
                                 default = nil)
  if valid_607613 != nil:
    section.add "X-Amz-Algorithm", valid_607613
  var valid_607614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607614 = validateParameter(valid_607614, JString, required = false,
                                 default = nil)
  if valid_607614 != nil:
    section.add "X-Amz-SignedHeaders", valid_607614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607616: Call_UpdateResourceServer_607604; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the name and scopes of resource server. All other fields are read-only.</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ## 
  let valid = call_607616.validator(path, query, header, formData, body)
  let scheme = call_607616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607616.url(scheme.get, call_607616.host, call_607616.base,
                         call_607616.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607616, url, valid)

proc call*(call_607617: Call_UpdateResourceServer_607604; body: JsonNode): Recallable =
  ## updateResourceServer
  ## <p>Updates the name and scopes of resource server. All other fields are read-only.</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ##   body: JObject (required)
  var body_607618 = newJObject()
  if body != nil:
    body_607618 = body
  result = call_607617.call(nil, nil, nil, nil, body_607618)

var updateResourceServer* = Call_UpdateResourceServer_607604(
    name: "updateResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateResourceServer",
    validator: validate_UpdateResourceServer_607605, base: "/",
    url: url_UpdateResourceServer_607606, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserAttributes_607619 = ref object of OpenApiRestCall_605589
proc url_UpdateUserAttributes_607621(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserAttributes_607620(path: JsonNode; query: JsonNode;
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
  var valid_607622 = header.getOrDefault("X-Amz-Target")
  valid_607622 = validateParameter(valid_607622, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserAttributes"))
  if valid_607622 != nil:
    section.add "X-Amz-Target", valid_607622
  var valid_607623 = header.getOrDefault("X-Amz-Signature")
  valid_607623 = validateParameter(valid_607623, JString, required = false,
                                 default = nil)
  if valid_607623 != nil:
    section.add "X-Amz-Signature", valid_607623
  var valid_607624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607624 = validateParameter(valid_607624, JString, required = false,
                                 default = nil)
  if valid_607624 != nil:
    section.add "X-Amz-Content-Sha256", valid_607624
  var valid_607625 = header.getOrDefault("X-Amz-Date")
  valid_607625 = validateParameter(valid_607625, JString, required = false,
                                 default = nil)
  if valid_607625 != nil:
    section.add "X-Amz-Date", valid_607625
  var valid_607626 = header.getOrDefault("X-Amz-Credential")
  valid_607626 = validateParameter(valid_607626, JString, required = false,
                                 default = nil)
  if valid_607626 != nil:
    section.add "X-Amz-Credential", valid_607626
  var valid_607627 = header.getOrDefault("X-Amz-Security-Token")
  valid_607627 = validateParameter(valid_607627, JString, required = false,
                                 default = nil)
  if valid_607627 != nil:
    section.add "X-Amz-Security-Token", valid_607627
  var valid_607628 = header.getOrDefault("X-Amz-Algorithm")
  valid_607628 = validateParameter(valid_607628, JString, required = false,
                                 default = nil)
  if valid_607628 != nil:
    section.add "X-Amz-Algorithm", valid_607628
  var valid_607629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607629 = validateParameter(valid_607629, JString, required = false,
                                 default = nil)
  if valid_607629 != nil:
    section.add "X-Amz-SignedHeaders", valid_607629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607631: Call_UpdateUserAttributes_607619; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a user to update a specific attribute (one at a time).
  ## 
  let valid = call_607631.validator(path, query, header, formData, body)
  let scheme = call_607631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607631.url(scheme.get, call_607631.host, call_607631.base,
                         call_607631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607631, url, valid)

proc call*(call_607632: Call_UpdateUserAttributes_607619; body: JsonNode): Recallable =
  ## updateUserAttributes
  ## Allows a user to update a specific attribute (one at a time).
  ##   body: JObject (required)
  var body_607633 = newJObject()
  if body != nil:
    body_607633 = body
  result = call_607632.call(nil, nil, nil, nil, body_607633)

var updateUserAttributes* = Call_UpdateUserAttributes_607619(
    name: "updateUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserAttributes",
    validator: validate_UpdateUserAttributes_607620, base: "/",
    url: url_UpdateUserAttributes_607621, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPool_607634 = ref object of OpenApiRestCall_605589
proc url_UpdateUserPool_607636(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserPool_607635(path: JsonNode; query: JsonNode;
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
  var valid_607637 = header.getOrDefault("X-Amz-Target")
  valid_607637 = validateParameter(valid_607637, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserPool"))
  if valid_607637 != nil:
    section.add "X-Amz-Target", valid_607637
  var valid_607638 = header.getOrDefault("X-Amz-Signature")
  valid_607638 = validateParameter(valid_607638, JString, required = false,
                                 default = nil)
  if valid_607638 != nil:
    section.add "X-Amz-Signature", valid_607638
  var valid_607639 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607639 = validateParameter(valid_607639, JString, required = false,
                                 default = nil)
  if valid_607639 != nil:
    section.add "X-Amz-Content-Sha256", valid_607639
  var valid_607640 = header.getOrDefault("X-Amz-Date")
  valid_607640 = validateParameter(valid_607640, JString, required = false,
                                 default = nil)
  if valid_607640 != nil:
    section.add "X-Amz-Date", valid_607640
  var valid_607641 = header.getOrDefault("X-Amz-Credential")
  valid_607641 = validateParameter(valid_607641, JString, required = false,
                                 default = nil)
  if valid_607641 != nil:
    section.add "X-Amz-Credential", valid_607641
  var valid_607642 = header.getOrDefault("X-Amz-Security-Token")
  valid_607642 = validateParameter(valid_607642, JString, required = false,
                                 default = nil)
  if valid_607642 != nil:
    section.add "X-Amz-Security-Token", valid_607642
  var valid_607643 = header.getOrDefault("X-Amz-Algorithm")
  valid_607643 = validateParameter(valid_607643, JString, required = false,
                                 default = nil)
  if valid_607643 != nil:
    section.add "X-Amz-Algorithm", valid_607643
  var valid_607644 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607644 = validateParameter(valid_607644, JString, required = false,
                                 default = nil)
  if valid_607644 != nil:
    section.add "X-Amz-SignedHeaders", valid_607644
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607646: Call_UpdateUserPool_607634; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified user pool with the specified attributes. You can get a list of the current user pool settings with .</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ## 
  let valid = call_607646.validator(path, query, header, formData, body)
  let scheme = call_607646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607646.url(scheme.get, call_607646.host, call_607646.base,
                         call_607646.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607646, url, valid)

proc call*(call_607647: Call_UpdateUserPool_607634; body: JsonNode): Recallable =
  ## updateUserPool
  ## <p>Updates the specified user pool with the specified attributes. You can get a list of the current user pool settings with .</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ##   body: JObject (required)
  var body_607648 = newJObject()
  if body != nil:
    body_607648 = body
  result = call_607647.call(nil, nil, nil, nil, body_607648)

var updateUserPool* = Call_UpdateUserPool_607634(name: "updateUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserPool",
    validator: validate_UpdateUserPool_607635, base: "/", url: url_UpdateUserPool_607636,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPoolClient_607649 = ref object of OpenApiRestCall_605589
proc url_UpdateUserPoolClient_607651(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserPoolClient_607650(path: JsonNode; query: JsonNode;
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
  var valid_607652 = header.getOrDefault("X-Amz-Target")
  valid_607652 = validateParameter(valid_607652, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserPoolClient"))
  if valid_607652 != nil:
    section.add "X-Amz-Target", valid_607652
  var valid_607653 = header.getOrDefault("X-Amz-Signature")
  valid_607653 = validateParameter(valid_607653, JString, required = false,
                                 default = nil)
  if valid_607653 != nil:
    section.add "X-Amz-Signature", valid_607653
  var valid_607654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607654 = validateParameter(valid_607654, JString, required = false,
                                 default = nil)
  if valid_607654 != nil:
    section.add "X-Amz-Content-Sha256", valid_607654
  var valid_607655 = header.getOrDefault("X-Amz-Date")
  valid_607655 = validateParameter(valid_607655, JString, required = false,
                                 default = nil)
  if valid_607655 != nil:
    section.add "X-Amz-Date", valid_607655
  var valid_607656 = header.getOrDefault("X-Amz-Credential")
  valid_607656 = validateParameter(valid_607656, JString, required = false,
                                 default = nil)
  if valid_607656 != nil:
    section.add "X-Amz-Credential", valid_607656
  var valid_607657 = header.getOrDefault("X-Amz-Security-Token")
  valid_607657 = validateParameter(valid_607657, JString, required = false,
                                 default = nil)
  if valid_607657 != nil:
    section.add "X-Amz-Security-Token", valid_607657
  var valid_607658 = header.getOrDefault("X-Amz-Algorithm")
  valid_607658 = validateParameter(valid_607658, JString, required = false,
                                 default = nil)
  if valid_607658 != nil:
    section.add "X-Amz-Algorithm", valid_607658
  var valid_607659 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607659 = validateParameter(valid_607659, JString, required = false,
                                 default = nil)
  if valid_607659 != nil:
    section.add "X-Amz-SignedHeaders", valid_607659
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607661: Call_UpdateUserPoolClient_607649; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified user pool app client with the specified attributes. You can get a list of the current user pool app client settings with .</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ## 
  let valid = call_607661.validator(path, query, header, formData, body)
  let scheme = call_607661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607661.url(scheme.get, call_607661.host, call_607661.base,
                         call_607661.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607661, url, valid)

proc call*(call_607662: Call_UpdateUserPoolClient_607649; body: JsonNode): Recallable =
  ## updateUserPoolClient
  ## <p>Updates the specified user pool app client with the specified attributes. You can get a list of the current user pool app client settings with .</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ##   body: JObject (required)
  var body_607663 = newJObject()
  if body != nil:
    body_607663 = body
  result = call_607662.call(nil, nil, nil, nil, body_607663)

var updateUserPoolClient* = Call_UpdateUserPoolClient_607649(
    name: "updateUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserPoolClient",
    validator: validate_UpdateUserPoolClient_607650, base: "/",
    url: url_UpdateUserPoolClient_607651, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPoolDomain_607664 = ref object of OpenApiRestCall_605589
proc url_UpdateUserPoolDomain_607666(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserPoolDomain_607665(path: JsonNode; query: JsonNode;
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
  var valid_607667 = header.getOrDefault("X-Amz-Target")
  valid_607667 = validateParameter(valid_607667, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserPoolDomain"))
  if valid_607667 != nil:
    section.add "X-Amz-Target", valid_607667
  var valid_607668 = header.getOrDefault("X-Amz-Signature")
  valid_607668 = validateParameter(valid_607668, JString, required = false,
                                 default = nil)
  if valid_607668 != nil:
    section.add "X-Amz-Signature", valid_607668
  var valid_607669 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607669 = validateParameter(valid_607669, JString, required = false,
                                 default = nil)
  if valid_607669 != nil:
    section.add "X-Amz-Content-Sha256", valid_607669
  var valid_607670 = header.getOrDefault("X-Amz-Date")
  valid_607670 = validateParameter(valid_607670, JString, required = false,
                                 default = nil)
  if valid_607670 != nil:
    section.add "X-Amz-Date", valid_607670
  var valid_607671 = header.getOrDefault("X-Amz-Credential")
  valid_607671 = validateParameter(valid_607671, JString, required = false,
                                 default = nil)
  if valid_607671 != nil:
    section.add "X-Amz-Credential", valid_607671
  var valid_607672 = header.getOrDefault("X-Amz-Security-Token")
  valid_607672 = validateParameter(valid_607672, JString, required = false,
                                 default = nil)
  if valid_607672 != nil:
    section.add "X-Amz-Security-Token", valid_607672
  var valid_607673 = header.getOrDefault("X-Amz-Algorithm")
  valid_607673 = validateParameter(valid_607673, JString, required = false,
                                 default = nil)
  if valid_607673 != nil:
    section.add "X-Amz-Algorithm", valid_607673
  var valid_607674 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607674 = validateParameter(valid_607674, JString, required = false,
                                 default = nil)
  if valid_607674 != nil:
    section.add "X-Amz-SignedHeaders", valid_607674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607676: Call_UpdateUserPoolDomain_607664; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the Secure Sockets Layer (SSL) certificate for the custom domain for your user pool.</p> <p>You can use this operation to provide the Amazon Resource Name (ARN) of a new certificate to Amazon Cognito. You cannot use it to change the domain for a user pool.</p> <p>A custom domain is used to host the Amazon Cognito hosted UI, which provides sign-up and sign-in pages for your application. When you set up a custom domain, you provide a certificate that you manage with AWS Certificate Manager (ACM). When necessary, you can use this operation to change the certificate that you applied to your custom domain.</p> <p>Usually, this is unnecessary following routine certificate renewal with ACM. When you renew your existing certificate in ACM, the ARN for your certificate remains the same, and your custom domain uses the new certificate automatically.</p> <p>However, if you replace your existing certificate with a new one, ACM gives the new certificate a new ARN. To apply the new certificate to your custom domain, you must provide this ARN to Amazon Cognito.</p> <p>When you add your new certificate in ACM, you must choose US East (N. Virginia) as the AWS Region.</p> <p>After you submit your request, Amazon Cognito requires up to 1 hour to distribute your new certificate to your custom domain.</p> <p>For more information about adding a custom domain to your user pool, see <a href="https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-add-custom-domain.html">Using Your Own Domain for the Hosted UI</a>.</p>
  ## 
  let valid = call_607676.validator(path, query, header, formData, body)
  let scheme = call_607676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607676.url(scheme.get, call_607676.host, call_607676.base,
                         call_607676.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607676, url, valid)

proc call*(call_607677: Call_UpdateUserPoolDomain_607664; body: JsonNode): Recallable =
  ## updateUserPoolDomain
  ## <p>Updates the Secure Sockets Layer (SSL) certificate for the custom domain for your user pool.</p> <p>You can use this operation to provide the Amazon Resource Name (ARN) of a new certificate to Amazon Cognito. You cannot use it to change the domain for a user pool.</p> <p>A custom domain is used to host the Amazon Cognito hosted UI, which provides sign-up and sign-in pages for your application. When you set up a custom domain, you provide a certificate that you manage with AWS Certificate Manager (ACM). When necessary, you can use this operation to change the certificate that you applied to your custom domain.</p> <p>Usually, this is unnecessary following routine certificate renewal with ACM. When you renew your existing certificate in ACM, the ARN for your certificate remains the same, and your custom domain uses the new certificate automatically.</p> <p>However, if you replace your existing certificate with a new one, ACM gives the new certificate a new ARN. To apply the new certificate to your custom domain, you must provide this ARN to Amazon Cognito.</p> <p>When you add your new certificate in ACM, you must choose US East (N. Virginia) as the AWS Region.</p> <p>After you submit your request, Amazon Cognito requires up to 1 hour to distribute your new certificate to your custom domain.</p> <p>For more information about adding a custom domain to your user pool, see <a href="https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-add-custom-domain.html">Using Your Own Domain for the Hosted UI</a>.</p>
  ##   body: JObject (required)
  var body_607678 = newJObject()
  if body != nil:
    body_607678 = body
  result = call_607677.call(nil, nil, nil, nil, body_607678)

var updateUserPoolDomain* = Call_UpdateUserPoolDomain_607664(
    name: "updateUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserPoolDomain",
    validator: validate_UpdateUserPoolDomain_607665, base: "/",
    url: url_UpdateUserPoolDomain_607666, schemes: {Scheme.Https, Scheme.Http})
type
  Call_VerifySoftwareToken_607679 = ref object of OpenApiRestCall_605589
proc url_VerifySoftwareToken_607681(protocol: Scheme; host: string; base: string;
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

proc validate_VerifySoftwareToken_607680(path: JsonNode; query: JsonNode;
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
  var valid_607682 = header.getOrDefault("X-Amz-Target")
  valid_607682 = validateParameter(valid_607682, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.VerifySoftwareToken"))
  if valid_607682 != nil:
    section.add "X-Amz-Target", valid_607682
  var valid_607683 = header.getOrDefault("X-Amz-Signature")
  valid_607683 = validateParameter(valid_607683, JString, required = false,
                                 default = nil)
  if valid_607683 != nil:
    section.add "X-Amz-Signature", valid_607683
  var valid_607684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607684 = validateParameter(valid_607684, JString, required = false,
                                 default = nil)
  if valid_607684 != nil:
    section.add "X-Amz-Content-Sha256", valid_607684
  var valid_607685 = header.getOrDefault("X-Amz-Date")
  valid_607685 = validateParameter(valid_607685, JString, required = false,
                                 default = nil)
  if valid_607685 != nil:
    section.add "X-Amz-Date", valid_607685
  var valid_607686 = header.getOrDefault("X-Amz-Credential")
  valid_607686 = validateParameter(valid_607686, JString, required = false,
                                 default = nil)
  if valid_607686 != nil:
    section.add "X-Amz-Credential", valid_607686
  var valid_607687 = header.getOrDefault("X-Amz-Security-Token")
  valid_607687 = validateParameter(valid_607687, JString, required = false,
                                 default = nil)
  if valid_607687 != nil:
    section.add "X-Amz-Security-Token", valid_607687
  var valid_607688 = header.getOrDefault("X-Amz-Algorithm")
  valid_607688 = validateParameter(valid_607688, JString, required = false,
                                 default = nil)
  if valid_607688 != nil:
    section.add "X-Amz-Algorithm", valid_607688
  var valid_607689 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607689 = validateParameter(valid_607689, JString, required = false,
                                 default = nil)
  if valid_607689 != nil:
    section.add "X-Amz-SignedHeaders", valid_607689
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607691: Call_VerifySoftwareToken_607679; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Use this API to register a user's entered TOTP code and mark the user's software token MFA status as "verified" if successful. The request takes an access token or a session string, but not both.
  ## 
  let valid = call_607691.validator(path, query, header, formData, body)
  let scheme = call_607691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607691.url(scheme.get, call_607691.host, call_607691.base,
                         call_607691.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607691, url, valid)

proc call*(call_607692: Call_VerifySoftwareToken_607679; body: JsonNode): Recallable =
  ## verifySoftwareToken
  ## Use this API to register a user's entered TOTP code and mark the user's software token MFA status as "verified" if successful. The request takes an access token or a session string, but not both.
  ##   body: JObject (required)
  var body_607693 = newJObject()
  if body != nil:
    body_607693 = body
  result = call_607692.call(nil, nil, nil, nil, body_607693)

var verifySoftwareToken* = Call_VerifySoftwareToken_607679(
    name: "verifySoftwareToken", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.VerifySoftwareToken",
    validator: validate_VerifySoftwareToken_607680, base: "/",
    url: url_VerifySoftwareToken_607681, schemes: {Scheme.Https, Scheme.Http})
type
  Call_VerifyUserAttribute_607694 = ref object of OpenApiRestCall_605589
proc url_VerifyUserAttribute_607696(protocol: Scheme; host: string; base: string;
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

proc validate_VerifyUserAttribute_607695(path: JsonNode; query: JsonNode;
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
  var valid_607697 = header.getOrDefault("X-Amz-Target")
  valid_607697 = validateParameter(valid_607697, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.VerifyUserAttribute"))
  if valid_607697 != nil:
    section.add "X-Amz-Target", valid_607697
  var valid_607698 = header.getOrDefault("X-Amz-Signature")
  valid_607698 = validateParameter(valid_607698, JString, required = false,
                                 default = nil)
  if valid_607698 != nil:
    section.add "X-Amz-Signature", valid_607698
  var valid_607699 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607699 = validateParameter(valid_607699, JString, required = false,
                                 default = nil)
  if valid_607699 != nil:
    section.add "X-Amz-Content-Sha256", valid_607699
  var valid_607700 = header.getOrDefault("X-Amz-Date")
  valid_607700 = validateParameter(valid_607700, JString, required = false,
                                 default = nil)
  if valid_607700 != nil:
    section.add "X-Amz-Date", valid_607700
  var valid_607701 = header.getOrDefault("X-Amz-Credential")
  valid_607701 = validateParameter(valid_607701, JString, required = false,
                                 default = nil)
  if valid_607701 != nil:
    section.add "X-Amz-Credential", valid_607701
  var valid_607702 = header.getOrDefault("X-Amz-Security-Token")
  valid_607702 = validateParameter(valid_607702, JString, required = false,
                                 default = nil)
  if valid_607702 != nil:
    section.add "X-Amz-Security-Token", valid_607702
  var valid_607703 = header.getOrDefault("X-Amz-Algorithm")
  valid_607703 = validateParameter(valid_607703, JString, required = false,
                                 default = nil)
  if valid_607703 != nil:
    section.add "X-Amz-Algorithm", valid_607703
  var valid_607704 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607704 = validateParameter(valid_607704, JString, required = false,
                                 default = nil)
  if valid_607704 != nil:
    section.add "X-Amz-SignedHeaders", valid_607704
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607706: Call_VerifyUserAttribute_607694; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Verifies the specified user attributes in the user pool.
  ## 
  let valid = call_607706.validator(path, query, header, formData, body)
  let scheme = call_607706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607706.url(scheme.get, call_607706.host, call_607706.base,
                         call_607706.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607706, url, valid)

proc call*(call_607707: Call_VerifyUserAttribute_607694; body: JsonNode): Recallable =
  ## verifyUserAttribute
  ## Verifies the specified user attributes in the user pool.
  ##   body: JObject (required)
  var body_607708 = newJObject()
  if body != nil:
    body_607708 = body
  result = call_607707.call(nil, nil, nil, nil, body_607708)

var verifyUserAttribute* = Call_VerifyUserAttribute_607694(
    name: "verifyUserAttribute", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.VerifyUserAttribute",
    validator: validate_VerifyUserAttribute_607695, base: "/",
    url: url_VerifyUserAttribute_607696, schemes: {Scheme.Https, Scheme.Http})
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
