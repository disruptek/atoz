
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AddCustomAttributes_772933 = ref object of OpenApiRestCall_772597
proc url_AddCustomAttributes_772935(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AddCustomAttributes_772934(path: JsonNode; query: JsonNode;
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
  var valid_773047 = header.getOrDefault("X-Amz-Date")
  valid_773047 = validateParameter(valid_773047, JString, required = false,
                                 default = nil)
  if valid_773047 != nil:
    section.add "X-Amz-Date", valid_773047
  var valid_773048 = header.getOrDefault("X-Amz-Security-Token")
  valid_773048 = validateParameter(valid_773048, JString, required = false,
                                 default = nil)
  if valid_773048 != nil:
    section.add "X-Amz-Security-Token", valid_773048
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773062 = header.getOrDefault("X-Amz-Target")
  valid_773062 = validateParameter(valid_773062, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AddCustomAttributes"))
  if valid_773062 != nil:
    section.add "X-Amz-Target", valid_773062
  var valid_773063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773063 = validateParameter(valid_773063, JString, required = false,
                                 default = nil)
  if valid_773063 != nil:
    section.add "X-Amz-Content-Sha256", valid_773063
  var valid_773064 = header.getOrDefault("X-Amz-Algorithm")
  valid_773064 = validateParameter(valid_773064, JString, required = false,
                                 default = nil)
  if valid_773064 != nil:
    section.add "X-Amz-Algorithm", valid_773064
  var valid_773065 = header.getOrDefault("X-Amz-Signature")
  valid_773065 = validateParameter(valid_773065, JString, required = false,
                                 default = nil)
  if valid_773065 != nil:
    section.add "X-Amz-Signature", valid_773065
  var valid_773066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773066 = validateParameter(valid_773066, JString, required = false,
                                 default = nil)
  if valid_773066 != nil:
    section.add "X-Amz-SignedHeaders", valid_773066
  var valid_773067 = header.getOrDefault("X-Amz-Credential")
  valid_773067 = validateParameter(valid_773067, JString, required = false,
                                 default = nil)
  if valid_773067 != nil:
    section.add "X-Amz-Credential", valid_773067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773091: Call_AddCustomAttributes_772933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds additional user attributes to the user pool schema.
  ## 
  let valid = call_773091.validator(path, query, header, formData, body)
  let scheme = call_773091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773091.url(scheme.get, call_773091.host, call_773091.base,
                         call_773091.route, valid.getOrDefault("path"))
  result = hook(call_773091, url, valid)

proc call*(call_773162: Call_AddCustomAttributes_772933; body: JsonNode): Recallable =
  ## addCustomAttributes
  ## Adds additional user attributes to the user pool schema.
  ##   body: JObject (required)
  var body_773163 = newJObject()
  if body != nil:
    body_773163 = body
  result = call_773162.call(nil, nil, nil, nil, body_773163)

var addCustomAttributes* = Call_AddCustomAttributes_772933(
    name: "addCustomAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AddCustomAttributes",
    validator: validate_AddCustomAttributes_772934, base: "/",
    url: url_AddCustomAttributes_772935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminAddUserToGroup_773202 = ref object of OpenApiRestCall_772597
proc url_AdminAddUserToGroup_773204(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminAddUserToGroup_773203(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Adds the specified user to the specified group.</p> <p>Requires developer credentials.</p>
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
  var valid_773205 = header.getOrDefault("X-Amz-Date")
  valid_773205 = validateParameter(valid_773205, JString, required = false,
                                 default = nil)
  if valid_773205 != nil:
    section.add "X-Amz-Date", valid_773205
  var valid_773206 = header.getOrDefault("X-Amz-Security-Token")
  valid_773206 = validateParameter(valid_773206, JString, required = false,
                                 default = nil)
  if valid_773206 != nil:
    section.add "X-Amz-Security-Token", valid_773206
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773207 = header.getOrDefault("X-Amz-Target")
  valid_773207 = validateParameter(valid_773207, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminAddUserToGroup"))
  if valid_773207 != nil:
    section.add "X-Amz-Target", valid_773207
  var valid_773208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773208 = validateParameter(valid_773208, JString, required = false,
                                 default = nil)
  if valid_773208 != nil:
    section.add "X-Amz-Content-Sha256", valid_773208
  var valid_773209 = header.getOrDefault("X-Amz-Algorithm")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Algorithm", valid_773209
  var valid_773210 = header.getOrDefault("X-Amz-Signature")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-Signature", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-SignedHeaders", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Credential")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Credential", valid_773212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773214: Call_AdminAddUserToGroup_773202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified user to the specified group.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_773214.validator(path, query, header, formData, body)
  let scheme = call_773214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773214.url(scheme.get, call_773214.host, call_773214.base,
                         call_773214.route, valid.getOrDefault("path"))
  result = hook(call_773214, url, valid)

proc call*(call_773215: Call_AdminAddUserToGroup_773202; body: JsonNode): Recallable =
  ## adminAddUserToGroup
  ## <p>Adds the specified user to the specified group.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_773216 = newJObject()
  if body != nil:
    body_773216 = body
  result = call_773215.call(nil, nil, nil, nil, body_773216)

var adminAddUserToGroup* = Call_AdminAddUserToGroup_773202(
    name: "adminAddUserToGroup", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminAddUserToGroup",
    validator: validate_AdminAddUserToGroup_773203, base: "/",
    url: url_AdminAddUserToGroup_773204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminConfirmSignUp_773217 = ref object of OpenApiRestCall_772597
proc url_AdminConfirmSignUp_773219(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminConfirmSignUp_773218(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Confirms user registration as an admin without using a confirmation code. Works on any user.</p> <p>Requires developer credentials.</p>
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
  var valid_773220 = header.getOrDefault("X-Amz-Date")
  valid_773220 = validateParameter(valid_773220, JString, required = false,
                                 default = nil)
  if valid_773220 != nil:
    section.add "X-Amz-Date", valid_773220
  var valid_773221 = header.getOrDefault("X-Amz-Security-Token")
  valid_773221 = validateParameter(valid_773221, JString, required = false,
                                 default = nil)
  if valid_773221 != nil:
    section.add "X-Amz-Security-Token", valid_773221
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773222 = header.getOrDefault("X-Amz-Target")
  valid_773222 = validateParameter(valid_773222, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminConfirmSignUp"))
  if valid_773222 != nil:
    section.add "X-Amz-Target", valid_773222
  var valid_773223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "X-Amz-Content-Sha256", valid_773223
  var valid_773224 = header.getOrDefault("X-Amz-Algorithm")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "X-Amz-Algorithm", valid_773224
  var valid_773225 = header.getOrDefault("X-Amz-Signature")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-Signature", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-SignedHeaders", valid_773226
  var valid_773227 = header.getOrDefault("X-Amz-Credential")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-Credential", valid_773227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773229: Call_AdminConfirmSignUp_773217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Confirms user registration as an admin without using a confirmation code. Works on any user.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_773229.validator(path, query, header, formData, body)
  let scheme = call_773229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773229.url(scheme.get, call_773229.host, call_773229.base,
                         call_773229.route, valid.getOrDefault("path"))
  result = hook(call_773229, url, valid)

proc call*(call_773230: Call_AdminConfirmSignUp_773217; body: JsonNode): Recallable =
  ## adminConfirmSignUp
  ## <p>Confirms user registration as an admin without using a confirmation code. Works on any user.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_773231 = newJObject()
  if body != nil:
    body_773231 = body
  result = call_773230.call(nil, nil, nil, nil, body_773231)

var adminConfirmSignUp* = Call_AdminConfirmSignUp_773217(
    name: "adminConfirmSignUp", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminConfirmSignUp",
    validator: validate_AdminConfirmSignUp_773218, base: "/",
    url: url_AdminConfirmSignUp_773219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminCreateUser_773232 = ref object of OpenApiRestCall_772597
proc url_AdminCreateUser_773234(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminCreateUser_773233(path: JsonNode; query: JsonNode;
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
  var valid_773235 = header.getOrDefault("X-Amz-Date")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-Date", valid_773235
  var valid_773236 = header.getOrDefault("X-Amz-Security-Token")
  valid_773236 = validateParameter(valid_773236, JString, required = false,
                                 default = nil)
  if valid_773236 != nil:
    section.add "X-Amz-Security-Token", valid_773236
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773237 = header.getOrDefault("X-Amz-Target")
  valid_773237 = validateParameter(valid_773237, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminCreateUser"))
  if valid_773237 != nil:
    section.add "X-Amz-Target", valid_773237
  var valid_773238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773238 = validateParameter(valid_773238, JString, required = false,
                                 default = nil)
  if valid_773238 != nil:
    section.add "X-Amz-Content-Sha256", valid_773238
  var valid_773239 = header.getOrDefault("X-Amz-Algorithm")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "X-Amz-Algorithm", valid_773239
  var valid_773240 = header.getOrDefault("X-Amz-Signature")
  valid_773240 = validateParameter(valid_773240, JString, required = false,
                                 default = nil)
  if valid_773240 != nil:
    section.add "X-Amz-Signature", valid_773240
  var valid_773241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "X-Amz-SignedHeaders", valid_773241
  var valid_773242 = header.getOrDefault("X-Amz-Credential")
  valid_773242 = validateParameter(valid_773242, JString, required = false,
                                 default = nil)
  if valid_773242 != nil:
    section.add "X-Amz-Credential", valid_773242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773244: Call_AdminCreateUser_773232; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new user in the specified user pool.</p> <p>If <code>MessageAction</code> is not set, the default is to send a welcome message via email or phone (SMS).</p> <note> <p>This message is based on a template that you configured in your call to or . This template includes your custom sign-up instructions and placeholders for user name and temporary password.</p> </note> <p>Alternatively, you can call AdminCreateUser with “SUPPRESS” for the <code>MessageAction</code> parameter, and Amazon Cognito will not send any email. </p> <p>In either case, the user will be in the <code>FORCE_CHANGE_PASSWORD</code> state until they sign in and change their password.</p> <p>AdminCreateUser requires developer credentials.</p>
  ## 
  let valid = call_773244.validator(path, query, header, formData, body)
  let scheme = call_773244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773244.url(scheme.get, call_773244.host, call_773244.base,
                         call_773244.route, valid.getOrDefault("path"))
  result = hook(call_773244, url, valid)

proc call*(call_773245: Call_AdminCreateUser_773232; body: JsonNode): Recallable =
  ## adminCreateUser
  ## <p>Creates a new user in the specified user pool.</p> <p>If <code>MessageAction</code> is not set, the default is to send a welcome message via email or phone (SMS).</p> <note> <p>This message is based on a template that you configured in your call to or . This template includes your custom sign-up instructions and placeholders for user name and temporary password.</p> </note> <p>Alternatively, you can call AdminCreateUser with “SUPPRESS” for the <code>MessageAction</code> parameter, and Amazon Cognito will not send any email. </p> <p>In either case, the user will be in the <code>FORCE_CHANGE_PASSWORD</code> state until they sign in and change their password.</p> <p>AdminCreateUser requires developer credentials.</p>
  ##   body: JObject (required)
  var body_773246 = newJObject()
  if body != nil:
    body_773246 = body
  result = call_773245.call(nil, nil, nil, nil, body_773246)

var adminCreateUser* = Call_AdminCreateUser_773232(name: "adminCreateUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminCreateUser",
    validator: validate_AdminCreateUser_773233, base: "/", url: url_AdminCreateUser_773234,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDeleteUser_773247 = ref object of OpenApiRestCall_772597
proc url_AdminDeleteUser_773249(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminDeleteUser_773248(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Deletes a user as an administrator. Works on any user.</p> <p>Requires developer credentials.</p>
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
  var valid_773250 = header.getOrDefault("X-Amz-Date")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-Date", valid_773250
  var valid_773251 = header.getOrDefault("X-Amz-Security-Token")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "X-Amz-Security-Token", valid_773251
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773252 = header.getOrDefault("X-Amz-Target")
  valid_773252 = validateParameter(valid_773252, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDeleteUser"))
  if valid_773252 != nil:
    section.add "X-Amz-Target", valid_773252
  var valid_773253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-Content-Sha256", valid_773253
  var valid_773254 = header.getOrDefault("X-Amz-Algorithm")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Algorithm", valid_773254
  var valid_773255 = header.getOrDefault("X-Amz-Signature")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "X-Amz-Signature", valid_773255
  var valid_773256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-SignedHeaders", valid_773256
  var valid_773257 = header.getOrDefault("X-Amz-Credential")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = nil)
  if valid_773257 != nil:
    section.add "X-Amz-Credential", valid_773257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773259: Call_AdminDeleteUser_773247; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a user as an administrator. Works on any user.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_773259.validator(path, query, header, formData, body)
  let scheme = call_773259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773259.url(scheme.get, call_773259.host, call_773259.base,
                         call_773259.route, valid.getOrDefault("path"))
  result = hook(call_773259, url, valid)

proc call*(call_773260: Call_AdminDeleteUser_773247; body: JsonNode): Recallable =
  ## adminDeleteUser
  ## <p>Deletes a user as an administrator. Works on any user.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_773261 = newJObject()
  if body != nil:
    body_773261 = body
  result = call_773260.call(nil, nil, nil, nil, body_773261)

var adminDeleteUser* = Call_AdminDeleteUser_773247(name: "adminDeleteUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDeleteUser",
    validator: validate_AdminDeleteUser_773248, base: "/", url: url_AdminDeleteUser_773249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDeleteUserAttributes_773262 = ref object of OpenApiRestCall_772597
proc url_AdminDeleteUserAttributes_773264(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminDeleteUserAttributes_773263(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the user attributes in a user pool as an administrator. Works on any user.</p> <p>Requires developer credentials.</p>
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
  var valid_773265 = header.getOrDefault("X-Amz-Date")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "X-Amz-Date", valid_773265
  var valid_773266 = header.getOrDefault("X-Amz-Security-Token")
  valid_773266 = validateParameter(valid_773266, JString, required = false,
                                 default = nil)
  if valid_773266 != nil:
    section.add "X-Amz-Security-Token", valid_773266
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773267 = header.getOrDefault("X-Amz-Target")
  valid_773267 = validateParameter(valid_773267, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDeleteUserAttributes"))
  if valid_773267 != nil:
    section.add "X-Amz-Target", valid_773267
  var valid_773268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-Content-Sha256", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Algorithm")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Algorithm", valid_773269
  var valid_773270 = header.getOrDefault("X-Amz-Signature")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-Signature", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-SignedHeaders", valid_773271
  var valid_773272 = header.getOrDefault("X-Amz-Credential")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "X-Amz-Credential", valid_773272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773274: Call_AdminDeleteUserAttributes_773262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the user attributes in a user pool as an administrator. Works on any user.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_773274.validator(path, query, header, formData, body)
  let scheme = call_773274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773274.url(scheme.get, call_773274.host, call_773274.base,
                         call_773274.route, valid.getOrDefault("path"))
  result = hook(call_773274, url, valid)

proc call*(call_773275: Call_AdminDeleteUserAttributes_773262; body: JsonNode): Recallable =
  ## adminDeleteUserAttributes
  ## <p>Deletes the user attributes in a user pool as an administrator. Works on any user.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_773276 = newJObject()
  if body != nil:
    body_773276 = body
  result = call_773275.call(nil, nil, nil, nil, body_773276)

var adminDeleteUserAttributes* = Call_AdminDeleteUserAttributes_773262(
    name: "adminDeleteUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDeleteUserAttributes",
    validator: validate_AdminDeleteUserAttributes_773263, base: "/",
    url: url_AdminDeleteUserAttributes_773264,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDisableProviderForUser_773277 = ref object of OpenApiRestCall_772597
proc url_AdminDisableProviderForUser_773279(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminDisableProviderForUser_773278(path: JsonNode; query: JsonNode;
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
  var valid_773280 = header.getOrDefault("X-Amz-Date")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = nil)
  if valid_773280 != nil:
    section.add "X-Amz-Date", valid_773280
  var valid_773281 = header.getOrDefault("X-Amz-Security-Token")
  valid_773281 = validateParameter(valid_773281, JString, required = false,
                                 default = nil)
  if valid_773281 != nil:
    section.add "X-Amz-Security-Token", valid_773281
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773282 = header.getOrDefault("X-Amz-Target")
  valid_773282 = validateParameter(valid_773282, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDisableProviderForUser"))
  if valid_773282 != nil:
    section.add "X-Amz-Target", valid_773282
  var valid_773283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "X-Amz-Content-Sha256", valid_773283
  var valid_773284 = header.getOrDefault("X-Amz-Algorithm")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "X-Amz-Algorithm", valid_773284
  var valid_773285 = header.getOrDefault("X-Amz-Signature")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = nil)
  if valid_773285 != nil:
    section.add "X-Amz-Signature", valid_773285
  var valid_773286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "X-Amz-SignedHeaders", valid_773286
  var valid_773287 = header.getOrDefault("X-Amz-Credential")
  valid_773287 = validateParameter(valid_773287, JString, required = false,
                                 default = nil)
  if valid_773287 != nil:
    section.add "X-Amz-Credential", valid_773287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773289: Call_AdminDisableProviderForUser_773277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables the user from signing in with the specified external (SAML or social) identity provider. If the user to disable is a Cognito User Pools native username + password user, they are not permitted to use their password to sign-in. If the user to disable is a linked external IdP user, any link between that user and an existing user is removed. The next time the external user (no longer attached to the previously linked <code>DestinationUser</code>) signs in, they must create a new user account. See .</p> <p>This action is enabled only for admin access and requires developer credentials.</p> <p>The <code>ProviderName</code> must match the value specified when creating an IdP for the pool. </p> <p>To disable a native username + password user, the <code>ProviderName</code> value must be <code>Cognito</code> and the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code>, with the <code>ProviderAttributeValue</code> being the name that is used in the user pool for the user.</p> <p>The <code>ProviderAttributeName</code> must always be <code>Cognito_Subject</code> for social identity providers. The <code>ProviderAttributeValue</code> must always be the exact subject that was used when the user was originally linked as a source user.</p> <p>For de-linking a SAML identity, there are two scenarios. If the linked identity has not yet been used to sign-in, the <code>ProviderAttributeName</code> and <code>ProviderAttributeValue</code> must be the same values that were used for the <code>SourceUser</code> when the identities were originally linked in the call. (If the linking was done with <code>ProviderAttributeName</code> set to <code>Cognito_Subject</code>, the same applies here). However, if the user has already signed in, the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code> and <code>ProviderAttributeValue</code> must be the subject of the SAML assertion.</p>
  ## 
  let valid = call_773289.validator(path, query, header, formData, body)
  let scheme = call_773289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773289.url(scheme.get, call_773289.host, call_773289.base,
                         call_773289.route, valid.getOrDefault("path"))
  result = hook(call_773289, url, valid)

proc call*(call_773290: Call_AdminDisableProviderForUser_773277; body: JsonNode): Recallable =
  ## adminDisableProviderForUser
  ## <p>Disables the user from signing in with the specified external (SAML or social) identity provider. If the user to disable is a Cognito User Pools native username + password user, they are not permitted to use their password to sign-in. If the user to disable is a linked external IdP user, any link between that user and an existing user is removed. The next time the external user (no longer attached to the previously linked <code>DestinationUser</code>) signs in, they must create a new user account. See .</p> <p>This action is enabled only for admin access and requires developer credentials.</p> <p>The <code>ProviderName</code> must match the value specified when creating an IdP for the pool. </p> <p>To disable a native username + password user, the <code>ProviderName</code> value must be <code>Cognito</code> and the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code>, with the <code>ProviderAttributeValue</code> being the name that is used in the user pool for the user.</p> <p>The <code>ProviderAttributeName</code> must always be <code>Cognito_Subject</code> for social identity providers. The <code>ProviderAttributeValue</code> must always be the exact subject that was used when the user was originally linked as a source user.</p> <p>For de-linking a SAML identity, there are two scenarios. If the linked identity has not yet been used to sign-in, the <code>ProviderAttributeName</code> and <code>ProviderAttributeValue</code> must be the same values that were used for the <code>SourceUser</code> when the identities were originally linked in the call. (If the linking was done with <code>ProviderAttributeName</code> set to <code>Cognito_Subject</code>, the same applies here). However, if the user has already signed in, the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code> and <code>ProviderAttributeValue</code> must be the subject of the SAML assertion.</p>
  ##   body: JObject (required)
  var body_773291 = newJObject()
  if body != nil:
    body_773291 = body
  result = call_773290.call(nil, nil, nil, nil, body_773291)

var adminDisableProviderForUser* = Call_AdminDisableProviderForUser_773277(
    name: "adminDisableProviderForUser", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDisableProviderForUser",
    validator: validate_AdminDisableProviderForUser_773278, base: "/",
    url: url_AdminDisableProviderForUser_773279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDisableUser_773292 = ref object of OpenApiRestCall_772597
proc url_AdminDisableUser_773294(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminDisableUser_773293(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Disables the specified user as an administrator. Works on any user.</p> <p>Requires developer credentials.</p>
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
  var valid_773295 = header.getOrDefault("X-Amz-Date")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "X-Amz-Date", valid_773295
  var valid_773296 = header.getOrDefault("X-Amz-Security-Token")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "X-Amz-Security-Token", valid_773296
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773297 = header.getOrDefault("X-Amz-Target")
  valid_773297 = validateParameter(valid_773297, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDisableUser"))
  if valid_773297 != nil:
    section.add "X-Amz-Target", valid_773297
  var valid_773298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773298 = validateParameter(valid_773298, JString, required = false,
                                 default = nil)
  if valid_773298 != nil:
    section.add "X-Amz-Content-Sha256", valid_773298
  var valid_773299 = header.getOrDefault("X-Amz-Algorithm")
  valid_773299 = validateParameter(valid_773299, JString, required = false,
                                 default = nil)
  if valid_773299 != nil:
    section.add "X-Amz-Algorithm", valid_773299
  var valid_773300 = header.getOrDefault("X-Amz-Signature")
  valid_773300 = validateParameter(valid_773300, JString, required = false,
                                 default = nil)
  if valid_773300 != nil:
    section.add "X-Amz-Signature", valid_773300
  var valid_773301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773301 = validateParameter(valid_773301, JString, required = false,
                                 default = nil)
  if valid_773301 != nil:
    section.add "X-Amz-SignedHeaders", valid_773301
  var valid_773302 = header.getOrDefault("X-Amz-Credential")
  valid_773302 = validateParameter(valid_773302, JString, required = false,
                                 default = nil)
  if valid_773302 != nil:
    section.add "X-Amz-Credential", valid_773302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773304: Call_AdminDisableUser_773292; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables the specified user as an administrator. Works on any user.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_773304.validator(path, query, header, formData, body)
  let scheme = call_773304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773304.url(scheme.get, call_773304.host, call_773304.base,
                         call_773304.route, valid.getOrDefault("path"))
  result = hook(call_773304, url, valid)

proc call*(call_773305: Call_AdminDisableUser_773292; body: JsonNode): Recallable =
  ## adminDisableUser
  ## <p>Disables the specified user as an administrator. Works on any user.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_773306 = newJObject()
  if body != nil:
    body_773306 = body
  result = call_773305.call(nil, nil, nil, nil, body_773306)

var adminDisableUser* = Call_AdminDisableUser_773292(name: "adminDisableUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDisableUser",
    validator: validate_AdminDisableUser_773293, base: "/",
    url: url_AdminDisableUser_773294, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminEnableUser_773307 = ref object of OpenApiRestCall_772597
proc url_AdminEnableUser_773309(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminEnableUser_773308(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Enables the specified user as an administrator. Works on any user.</p> <p>Requires developer credentials.</p>
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
  var valid_773310 = header.getOrDefault("X-Amz-Date")
  valid_773310 = validateParameter(valid_773310, JString, required = false,
                                 default = nil)
  if valid_773310 != nil:
    section.add "X-Amz-Date", valid_773310
  var valid_773311 = header.getOrDefault("X-Amz-Security-Token")
  valid_773311 = validateParameter(valid_773311, JString, required = false,
                                 default = nil)
  if valid_773311 != nil:
    section.add "X-Amz-Security-Token", valid_773311
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773312 = header.getOrDefault("X-Amz-Target")
  valid_773312 = validateParameter(valid_773312, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminEnableUser"))
  if valid_773312 != nil:
    section.add "X-Amz-Target", valid_773312
  var valid_773313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773313 = validateParameter(valid_773313, JString, required = false,
                                 default = nil)
  if valid_773313 != nil:
    section.add "X-Amz-Content-Sha256", valid_773313
  var valid_773314 = header.getOrDefault("X-Amz-Algorithm")
  valid_773314 = validateParameter(valid_773314, JString, required = false,
                                 default = nil)
  if valid_773314 != nil:
    section.add "X-Amz-Algorithm", valid_773314
  var valid_773315 = header.getOrDefault("X-Amz-Signature")
  valid_773315 = validateParameter(valid_773315, JString, required = false,
                                 default = nil)
  if valid_773315 != nil:
    section.add "X-Amz-Signature", valid_773315
  var valid_773316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773316 = validateParameter(valid_773316, JString, required = false,
                                 default = nil)
  if valid_773316 != nil:
    section.add "X-Amz-SignedHeaders", valid_773316
  var valid_773317 = header.getOrDefault("X-Amz-Credential")
  valid_773317 = validateParameter(valid_773317, JString, required = false,
                                 default = nil)
  if valid_773317 != nil:
    section.add "X-Amz-Credential", valid_773317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773319: Call_AdminEnableUser_773307; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the specified user as an administrator. Works on any user.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_773319.validator(path, query, header, formData, body)
  let scheme = call_773319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773319.url(scheme.get, call_773319.host, call_773319.base,
                         call_773319.route, valid.getOrDefault("path"))
  result = hook(call_773319, url, valid)

proc call*(call_773320: Call_AdminEnableUser_773307; body: JsonNode): Recallable =
  ## adminEnableUser
  ## <p>Enables the specified user as an administrator. Works on any user.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_773321 = newJObject()
  if body != nil:
    body_773321 = body
  result = call_773320.call(nil, nil, nil, nil, body_773321)

var adminEnableUser* = Call_AdminEnableUser_773307(name: "adminEnableUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminEnableUser",
    validator: validate_AdminEnableUser_773308, base: "/", url: url_AdminEnableUser_773309,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminForgetDevice_773322 = ref object of OpenApiRestCall_772597
proc url_AdminForgetDevice_773324(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminForgetDevice_773323(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Forgets the device, as an administrator.</p> <p>Requires developer credentials.</p>
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
  var valid_773325 = header.getOrDefault("X-Amz-Date")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "X-Amz-Date", valid_773325
  var valid_773326 = header.getOrDefault("X-Amz-Security-Token")
  valid_773326 = validateParameter(valid_773326, JString, required = false,
                                 default = nil)
  if valid_773326 != nil:
    section.add "X-Amz-Security-Token", valid_773326
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773327 = header.getOrDefault("X-Amz-Target")
  valid_773327 = validateParameter(valid_773327, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminForgetDevice"))
  if valid_773327 != nil:
    section.add "X-Amz-Target", valid_773327
  var valid_773328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773328 = validateParameter(valid_773328, JString, required = false,
                                 default = nil)
  if valid_773328 != nil:
    section.add "X-Amz-Content-Sha256", valid_773328
  var valid_773329 = header.getOrDefault("X-Amz-Algorithm")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "X-Amz-Algorithm", valid_773329
  var valid_773330 = header.getOrDefault("X-Amz-Signature")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "X-Amz-Signature", valid_773330
  var valid_773331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773331 = validateParameter(valid_773331, JString, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "X-Amz-SignedHeaders", valid_773331
  var valid_773332 = header.getOrDefault("X-Amz-Credential")
  valid_773332 = validateParameter(valid_773332, JString, required = false,
                                 default = nil)
  if valid_773332 != nil:
    section.add "X-Amz-Credential", valid_773332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773334: Call_AdminForgetDevice_773322; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Forgets the device, as an administrator.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_773334.validator(path, query, header, formData, body)
  let scheme = call_773334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773334.url(scheme.get, call_773334.host, call_773334.base,
                         call_773334.route, valid.getOrDefault("path"))
  result = hook(call_773334, url, valid)

proc call*(call_773335: Call_AdminForgetDevice_773322; body: JsonNode): Recallable =
  ## adminForgetDevice
  ## <p>Forgets the device, as an administrator.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_773336 = newJObject()
  if body != nil:
    body_773336 = body
  result = call_773335.call(nil, nil, nil, nil, body_773336)

var adminForgetDevice* = Call_AdminForgetDevice_773322(name: "adminForgetDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminForgetDevice",
    validator: validate_AdminForgetDevice_773323, base: "/",
    url: url_AdminForgetDevice_773324, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminGetDevice_773337 = ref object of OpenApiRestCall_772597
proc url_AdminGetDevice_773339(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminGetDevice_773338(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Gets the device, as an administrator.</p> <p>Requires developer credentials.</p>
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
  var valid_773340 = header.getOrDefault("X-Amz-Date")
  valid_773340 = validateParameter(valid_773340, JString, required = false,
                                 default = nil)
  if valid_773340 != nil:
    section.add "X-Amz-Date", valid_773340
  var valid_773341 = header.getOrDefault("X-Amz-Security-Token")
  valid_773341 = validateParameter(valid_773341, JString, required = false,
                                 default = nil)
  if valid_773341 != nil:
    section.add "X-Amz-Security-Token", valid_773341
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773342 = header.getOrDefault("X-Amz-Target")
  valid_773342 = validateParameter(valid_773342, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminGetDevice"))
  if valid_773342 != nil:
    section.add "X-Amz-Target", valid_773342
  var valid_773343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773343 = validateParameter(valid_773343, JString, required = false,
                                 default = nil)
  if valid_773343 != nil:
    section.add "X-Amz-Content-Sha256", valid_773343
  var valid_773344 = header.getOrDefault("X-Amz-Algorithm")
  valid_773344 = validateParameter(valid_773344, JString, required = false,
                                 default = nil)
  if valid_773344 != nil:
    section.add "X-Amz-Algorithm", valid_773344
  var valid_773345 = header.getOrDefault("X-Amz-Signature")
  valid_773345 = validateParameter(valid_773345, JString, required = false,
                                 default = nil)
  if valid_773345 != nil:
    section.add "X-Amz-Signature", valid_773345
  var valid_773346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "X-Amz-SignedHeaders", valid_773346
  var valid_773347 = header.getOrDefault("X-Amz-Credential")
  valid_773347 = validateParameter(valid_773347, JString, required = false,
                                 default = nil)
  if valid_773347 != nil:
    section.add "X-Amz-Credential", valid_773347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773349: Call_AdminGetDevice_773337; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the device, as an administrator.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_773349.validator(path, query, header, formData, body)
  let scheme = call_773349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773349.url(scheme.get, call_773349.host, call_773349.base,
                         call_773349.route, valid.getOrDefault("path"))
  result = hook(call_773349, url, valid)

proc call*(call_773350: Call_AdminGetDevice_773337; body: JsonNode): Recallable =
  ## adminGetDevice
  ## <p>Gets the device, as an administrator.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_773351 = newJObject()
  if body != nil:
    body_773351 = body
  result = call_773350.call(nil, nil, nil, nil, body_773351)

var adminGetDevice* = Call_AdminGetDevice_773337(name: "adminGetDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminGetDevice",
    validator: validate_AdminGetDevice_773338, base: "/", url: url_AdminGetDevice_773339,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminGetUser_773352 = ref object of OpenApiRestCall_772597
proc url_AdminGetUser_773354(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminGetUser_773353(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets the specified user by user name in a user pool as an administrator. Works on any user.</p> <p>Requires developer credentials.</p>
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
  var valid_773355 = header.getOrDefault("X-Amz-Date")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = nil)
  if valid_773355 != nil:
    section.add "X-Amz-Date", valid_773355
  var valid_773356 = header.getOrDefault("X-Amz-Security-Token")
  valid_773356 = validateParameter(valid_773356, JString, required = false,
                                 default = nil)
  if valid_773356 != nil:
    section.add "X-Amz-Security-Token", valid_773356
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773357 = header.getOrDefault("X-Amz-Target")
  valid_773357 = validateParameter(valid_773357, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminGetUser"))
  if valid_773357 != nil:
    section.add "X-Amz-Target", valid_773357
  var valid_773358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-Content-Sha256", valid_773358
  var valid_773359 = header.getOrDefault("X-Amz-Algorithm")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-Algorithm", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-Signature")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-Signature", valid_773360
  var valid_773361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-SignedHeaders", valid_773361
  var valid_773362 = header.getOrDefault("X-Amz-Credential")
  valid_773362 = validateParameter(valid_773362, JString, required = false,
                                 default = nil)
  if valid_773362 != nil:
    section.add "X-Amz-Credential", valid_773362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773364: Call_AdminGetUser_773352; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the specified user by user name in a user pool as an administrator. Works on any user.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_773364.validator(path, query, header, formData, body)
  let scheme = call_773364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773364.url(scheme.get, call_773364.host, call_773364.base,
                         call_773364.route, valid.getOrDefault("path"))
  result = hook(call_773364, url, valid)

proc call*(call_773365: Call_AdminGetUser_773352; body: JsonNode): Recallable =
  ## adminGetUser
  ## <p>Gets the specified user by user name in a user pool as an administrator. Works on any user.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_773366 = newJObject()
  if body != nil:
    body_773366 = body
  result = call_773365.call(nil, nil, nil, nil, body_773366)

var adminGetUser* = Call_AdminGetUser_773352(name: "adminGetUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminGetUser",
    validator: validate_AdminGetUser_773353, base: "/", url: url_AdminGetUser_773354,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminInitiateAuth_773367 = ref object of OpenApiRestCall_772597
proc url_AdminInitiateAuth_773369(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminInitiateAuth_773368(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Initiates the authentication flow, as an administrator.</p> <p>Requires developer credentials.</p>
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
  var valid_773370 = header.getOrDefault("X-Amz-Date")
  valid_773370 = validateParameter(valid_773370, JString, required = false,
                                 default = nil)
  if valid_773370 != nil:
    section.add "X-Amz-Date", valid_773370
  var valid_773371 = header.getOrDefault("X-Amz-Security-Token")
  valid_773371 = validateParameter(valid_773371, JString, required = false,
                                 default = nil)
  if valid_773371 != nil:
    section.add "X-Amz-Security-Token", valid_773371
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773372 = header.getOrDefault("X-Amz-Target")
  valid_773372 = validateParameter(valid_773372, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminInitiateAuth"))
  if valid_773372 != nil:
    section.add "X-Amz-Target", valid_773372
  var valid_773373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-Content-Sha256", valid_773373
  var valid_773374 = header.getOrDefault("X-Amz-Algorithm")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-Algorithm", valid_773374
  var valid_773375 = header.getOrDefault("X-Amz-Signature")
  valid_773375 = validateParameter(valid_773375, JString, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "X-Amz-Signature", valid_773375
  var valid_773376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773376 = validateParameter(valid_773376, JString, required = false,
                                 default = nil)
  if valid_773376 != nil:
    section.add "X-Amz-SignedHeaders", valid_773376
  var valid_773377 = header.getOrDefault("X-Amz-Credential")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "X-Amz-Credential", valid_773377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773379: Call_AdminInitiateAuth_773367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates the authentication flow, as an administrator.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_773379.validator(path, query, header, formData, body)
  let scheme = call_773379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773379.url(scheme.get, call_773379.host, call_773379.base,
                         call_773379.route, valid.getOrDefault("path"))
  result = hook(call_773379, url, valid)

proc call*(call_773380: Call_AdminInitiateAuth_773367; body: JsonNode): Recallable =
  ## adminInitiateAuth
  ## <p>Initiates the authentication flow, as an administrator.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_773381 = newJObject()
  if body != nil:
    body_773381 = body
  result = call_773380.call(nil, nil, nil, nil, body_773381)

var adminInitiateAuth* = Call_AdminInitiateAuth_773367(name: "adminInitiateAuth",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminInitiateAuth",
    validator: validate_AdminInitiateAuth_773368, base: "/",
    url: url_AdminInitiateAuth_773369, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminLinkProviderForUser_773382 = ref object of OpenApiRestCall_772597
proc url_AdminLinkProviderForUser_773384(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminLinkProviderForUser_773383(path: JsonNode; query: JsonNode;
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
  var valid_773385 = header.getOrDefault("X-Amz-Date")
  valid_773385 = validateParameter(valid_773385, JString, required = false,
                                 default = nil)
  if valid_773385 != nil:
    section.add "X-Amz-Date", valid_773385
  var valid_773386 = header.getOrDefault("X-Amz-Security-Token")
  valid_773386 = validateParameter(valid_773386, JString, required = false,
                                 default = nil)
  if valid_773386 != nil:
    section.add "X-Amz-Security-Token", valid_773386
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773387 = header.getOrDefault("X-Amz-Target")
  valid_773387 = validateParameter(valid_773387, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminLinkProviderForUser"))
  if valid_773387 != nil:
    section.add "X-Amz-Target", valid_773387
  var valid_773388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "X-Amz-Content-Sha256", valid_773388
  var valid_773389 = header.getOrDefault("X-Amz-Algorithm")
  valid_773389 = validateParameter(valid_773389, JString, required = false,
                                 default = nil)
  if valid_773389 != nil:
    section.add "X-Amz-Algorithm", valid_773389
  var valid_773390 = header.getOrDefault("X-Amz-Signature")
  valid_773390 = validateParameter(valid_773390, JString, required = false,
                                 default = nil)
  if valid_773390 != nil:
    section.add "X-Amz-Signature", valid_773390
  var valid_773391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773391 = validateParameter(valid_773391, JString, required = false,
                                 default = nil)
  if valid_773391 != nil:
    section.add "X-Amz-SignedHeaders", valid_773391
  var valid_773392 = header.getOrDefault("X-Amz-Credential")
  valid_773392 = validateParameter(valid_773392, JString, required = false,
                                 default = nil)
  if valid_773392 != nil:
    section.add "X-Amz-Credential", valid_773392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773394: Call_AdminLinkProviderForUser_773382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Links an existing user account in a user pool (<code>DestinationUser</code>) to an identity from an external identity provider (<code>SourceUser</code>) based on a specified attribute name and value from the external identity provider. This allows you to create a link from the existing user account to an external federated user identity that has not yet been used to sign in, so that the federated user identity can be used to sign in as the existing user account. </p> <p> For example, if there is an existing user with a username and password, this API links that user to a federated user identity, so that when the federated user identity is used, the user signs in as the existing user account. </p> <important> <p>Because this API allows a user with an external federated identity to sign in as an existing user in the user pool, it is critical that it only be used with external identity providers and provider attributes that have been trusted by the application owner.</p> </important> <p>See also .</p> <p>This action is enabled only for admin access and requires developer credentials.</p>
  ## 
  let valid = call_773394.validator(path, query, header, formData, body)
  let scheme = call_773394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773394.url(scheme.get, call_773394.host, call_773394.base,
                         call_773394.route, valid.getOrDefault("path"))
  result = hook(call_773394, url, valid)

proc call*(call_773395: Call_AdminLinkProviderForUser_773382; body: JsonNode): Recallable =
  ## adminLinkProviderForUser
  ## <p>Links an existing user account in a user pool (<code>DestinationUser</code>) to an identity from an external identity provider (<code>SourceUser</code>) based on a specified attribute name and value from the external identity provider. This allows you to create a link from the existing user account to an external federated user identity that has not yet been used to sign in, so that the federated user identity can be used to sign in as the existing user account. </p> <p> For example, if there is an existing user with a username and password, this API links that user to a federated user identity, so that when the federated user identity is used, the user signs in as the existing user account. </p> <important> <p>Because this API allows a user with an external federated identity to sign in as an existing user in the user pool, it is critical that it only be used with external identity providers and provider attributes that have been trusted by the application owner.</p> </important> <p>See also .</p> <p>This action is enabled only for admin access and requires developer credentials.</p>
  ##   body: JObject (required)
  var body_773396 = newJObject()
  if body != nil:
    body_773396 = body
  result = call_773395.call(nil, nil, nil, nil, body_773396)

var adminLinkProviderForUser* = Call_AdminLinkProviderForUser_773382(
    name: "adminLinkProviderForUser", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminLinkProviderForUser",
    validator: validate_AdminLinkProviderForUser_773383, base: "/",
    url: url_AdminLinkProviderForUser_773384, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminListDevices_773397 = ref object of OpenApiRestCall_772597
proc url_AdminListDevices_773399(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminListDevices_773398(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Lists devices, as an administrator.</p> <p>Requires developer credentials.</p>
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
  var valid_773400 = header.getOrDefault("X-Amz-Date")
  valid_773400 = validateParameter(valid_773400, JString, required = false,
                                 default = nil)
  if valid_773400 != nil:
    section.add "X-Amz-Date", valid_773400
  var valid_773401 = header.getOrDefault("X-Amz-Security-Token")
  valid_773401 = validateParameter(valid_773401, JString, required = false,
                                 default = nil)
  if valid_773401 != nil:
    section.add "X-Amz-Security-Token", valid_773401
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773402 = header.getOrDefault("X-Amz-Target")
  valid_773402 = validateParameter(valid_773402, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminListDevices"))
  if valid_773402 != nil:
    section.add "X-Amz-Target", valid_773402
  var valid_773403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773403 = validateParameter(valid_773403, JString, required = false,
                                 default = nil)
  if valid_773403 != nil:
    section.add "X-Amz-Content-Sha256", valid_773403
  var valid_773404 = header.getOrDefault("X-Amz-Algorithm")
  valid_773404 = validateParameter(valid_773404, JString, required = false,
                                 default = nil)
  if valid_773404 != nil:
    section.add "X-Amz-Algorithm", valid_773404
  var valid_773405 = header.getOrDefault("X-Amz-Signature")
  valid_773405 = validateParameter(valid_773405, JString, required = false,
                                 default = nil)
  if valid_773405 != nil:
    section.add "X-Amz-Signature", valid_773405
  var valid_773406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773406 = validateParameter(valid_773406, JString, required = false,
                                 default = nil)
  if valid_773406 != nil:
    section.add "X-Amz-SignedHeaders", valid_773406
  var valid_773407 = header.getOrDefault("X-Amz-Credential")
  valid_773407 = validateParameter(valid_773407, JString, required = false,
                                 default = nil)
  if valid_773407 != nil:
    section.add "X-Amz-Credential", valid_773407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773409: Call_AdminListDevices_773397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists devices, as an administrator.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_773409.validator(path, query, header, formData, body)
  let scheme = call_773409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773409.url(scheme.get, call_773409.host, call_773409.base,
                         call_773409.route, valid.getOrDefault("path"))
  result = hook(call_773409, url, valid)

proc call*(call_773410: Call_AdminListDevices_773397; body: JsonNode): Recallable =
  ## adminListDevices
  ## <p>Lists devices, as an administrator.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_773411 = newJObject()
  if body != nil:
    body_773411 = body
  result = call_773410.call(nil, nil, nil, nil, body_773411)

var adminListDevices* = Call_AdminListDevices_773397(name: "adminListDevices",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminListDevices",
    validator: validate_AdminListDevices_773398, base: "/",
    url: url_AdminListDevices_773399, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminListGroupsForUser_773412 = ref object of OpenApiRestCall_772597
proc url_AdminListGroupsForUser_773414(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminListGroupsForUser_773413(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the groups that the user belongs to.</p> <p>Requires developer credentials.</p>
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
  var valid_773415 = query.getOrDefault("Limit")
  valid_773415 = validateParameter(valid_773415, JString, required = false,
                                 default = nil)
  if valid_773415 != nil:
    section.add "Limit", valid_773415
  var valid_773416 = query.getOrDefault("NextToken")
  valid_773416 = validateParameter(valid_773416, JString, required = false,
                                 default = nil)
  if valid_773416 != nil:
    section.add "NextToken", valid_773416
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
  var valid_773417 = header.getOrDefault("X-Amz-Date")
  valid_773417 = validateParameter(valid_773417, JString, required = false,
                                 default = nil)
  if valid_773417 != nil:
    section.add "X-Amz-Date", valid_773417
  var valid_773418 = header.getOrDefault("X-Amz-Security-Token")
  valid_773418 = validateParameter(valid_773418, JString, required = false,
                                 default = nil)
  if valid_773418 != nil:
    section.add "X-Amz-Security-Token", valid_773418
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773419 = header.getOrDefault("X-Amz-Target")
  valid_773419 = validateParameter(valid_773419, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminListGroupsForUser"))
  if valid_773419 != nil:
    section.add "X-Amz-Target", valid_773419
  var valid_773420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773420 = validateParameter(valid_773420, JString, required = false,
                                 default = nil)
  if valid_773420 != nil:
    section.add "X-Amz-Content-Sha256", valid_773420
  var valid_773421 = header.getOrDefault("X-Amz-Algorithm")
  valid_773421 = validateParameter(valid_773421, JString, required = false,
                                 default = nil)
  if valid_773421 != nil:
    section.add "X-Amz-Algorithm", valid_773421
  var valid_773422 = header.getOrDefault("X-Amz-Signature")
  valid_773422 = validateParameter(valid_773422, JString, required = false,
                                 default = nil)
  if valid_773422 != nil:
    section.add "X-Amz-Signature", valid_773422
  var valid_773423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773423 = validateParameter(valid_773423, JString, required = false,
                                 default = nil)
  if valid_773423 != nil:
    section.add "X-Amz-SignedHeaders", valid_773423
  var valid_773424 = header.getOrDefault("X-Amz-Credential")
  valid_773424 = validateParameter(valid_773424, JString, required = false,
                                 default = nil)
  if valid_773424 != nil:
    section.add "X-Amz-Credential", valid_773424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773426: Call_AdminListGroupsForUser_773412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the groups that the user belongs to.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_773426.validator(path, query, header, formData, body)
  let scheme = call_773426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773426.url(scheme.get, call_773426.host, call_773426.base,
                         call_773426.route, valid.getOrDefault("path"))
  result = hook(call_773426, url, valid)

proc call*(call_773427: Call_AdminListGroupsForUser_773412; body: JsonNode;
          Limit: string = ""; NextToken: string = ""): Recallable =
  ## adminListGroupsForUser
  ## <p>Lists the groups that the user belongs to.</p> <p>Requires developer credentials.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773428 = newJObject()
  var body_773429 = newJObject()
  add(query_773428, "Limit", newJString(Limit))
  add(query_773428, "NextToken", newJString(NextToken))
  if body != nil:
    body_773429 = body
  result = call_773427.call(nil, query_773428, nil, nil, body_773429)

var adminListGroupsForUser* = Call_AdminListGroupsForUser_773412(
    name: "adminListGroupsForUser", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminListGroupsForUser",
    validator: validate_AdminListGroupsForUser_773413, base: "/",
    url: url_AdminListGroupsForUser_773414, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminListUserAuthEvents_773431 = ref object of OpenApiRestCall_772597
proc url_AdminListUserAuthEvents_773433(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminListUserAuthEvents_773432(path: JsonNode; query: JsonNode;
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
  var valid_773434 = query.getOrDefault("NextToken")
  valid_773434 = validateParameter(valid_773434, JString, required = false,
                                 default = nil)
  if valid_773434 != nil:
    section.add "NextToken", valid_773434
  var valid_773435 = query.getOrDefault("MaxResults")
  valid_773435 = validateParameter(valid_773435, JString, required = false,
                                 default = nil)
  if valid_773435 != nil:
    section.add "MaxResults", valid_773435
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
  var valid_773436 = header.getOrDefault("X-Amz-Date")
  valid_773436 = validateParameter(valid_773436, JString, required = false,
                                 default = nil)
  if valid_773436 != nil:
    section.add "X-Amz-Date", valid_773436
  var valid_773437 = header.getOrDefault("X-Amz-Security-Token")
  valid_773437 = validateParameter(valid_773437, JString, required = false,
                                 default = nil)
  if valid_773437 != nil:
    section.add "X-Amz-Security-Token", valid_773437
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773438 = header.getOrDefault("X-Amz-Target")
  valid_773438 = validateParameter(valid_773438, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminListUserAuthEvents"))
  if valid_773438 != nil:
    section.add "X-Amz-Target", valid_773438
  var valid_773439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773439 = validateParameter(valid_773439, JString, required = false,
                                 default = nil)
  if valid_773439 != nil:
    section.add "X-Amz-Content-Sha256", valid_773439
  var valid_773440 = header.getOrDefault("X-Amz-Algorithm")
  valid_773440 = validateParameter(valid_773440, JString, required = false,
                                 default = nil)
  if valid_773440 != nil:
    section.add "X-Amz-Algorithm", valid_773440
  var valid_773441 = header.getOrDefault("X-Amz-Signature")
  valid_773441 = validateParameter(valid_773441, JString, required = false,
                                 default = nil)
  if valid_773441 != nil:
    section.add "X-Amz-Signature", valid_773441
  var valid_773442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773442 = validateParameter(valid_773442, JString, required = false,
                                 default = nil)
  if valid_773442 != nil:
    section.add "X-Amz-SignedHeaders", valid_773442
  var valid_773443 = header.getOrDefault("X-Amz-Credential")
  valid_773443 = validateParameter(valid_773443, JString, required = false,
                                 default = nil)
  if valid_773443 != nil:
    section.add "X-Amz-Credential", valid_773443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773445: Call_AdminListUserAuthEvents_773431; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists a history of user activity and any risks detected as part of Amazon Cognito advanced security.
  ## 
  let valid = call_773445.validator(path, query, header, formData, body)
  let scheme = call_773445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773445.url(scheme.get, call_773445.host, call_773445.base,
                         call_773445.route, valid.getOrDefault("path"))
  result = hook(call_773445, url, valid)

proc call*(call_773446: Call_AdminListUserAuthEvents_773431; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## adminListUserAuthEvents
  ## Lists a history of user activity and any risks detected as part of Amazon Cognito advanced security.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773447 = newJObject()
  var body_773448 = newJObject()
  add(query_773447, "NextToken", newJString(NextToken))
  if body != nil:
    body_773448 = body
  add(query_773447, "MaxResults", newJString(MaxResults))
  result = call_773446.call(nil, query_773447, nil, nil, body_773448)

var adminListUserAuthEvents* = Call_AdminListUserAuthEvents_773431(
    name: "adminListUserAuthEvents", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminListUserAuthEvents",
    validator: validate_AdminListUserAuthEvents_773432, base: "/",
    url: url_AdminListUserAuthEvents_773433, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminRemoveUserFromGroup_773449 = ref object of OpenApiRestCall_772597
proc url_AdminRemoveUserFromGroup_773451(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminRemoveUserFromGroup_773450(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes the specified user from the specified group.</p> <p>Requires developer credentials.</p>
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
  var valid_773452 = header.getOrDefault("X-Amz-Date")
  valid_773452 = validateParameter(valid_773452, JString, required = false,
                                 default = nil)
  if valid_773452 != nil:
    section.add "X-Amz-Date", valid_773452
  var valid_773453 = header.getOrDefault("X-Amz-Security-Token")
  valid_773453 = validateParameter(valid_773453, JString, required = false,
                                 default = nil)
  if valid_773453 != nil:
    section.add "X-Amz-Security-Token", valid_773453
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773454 = header.getOrDefault("X-Amz-Target")
  valid_773454 = validateParameter(valid_773454, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminRemoveUserFromGroup"))
  if valid_773454 != nil:
    section.add "X-Amz-Target", valid_773454
  var valid_773455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773455 = validateParameter(valid_773455, JString, required = false,
                                 default = nil)
  if valid_773455 != nil:
    section.add "X-Amz-Content-Sha256", valid_773455
  var valid_773456 = header.getOrDefault("X-Amz-Algorithm")
  valid_773456 = validateParameter(valid_773456, JString, required = false,
                                 default = nil)
  if valid_773456 != nil:
    section.add "X-Amz-Algorithm", valid_773456
  var valid_773457 = header.getOrDefault("X-Amz-Signature")
  valid_773457 = validateParameter(valid_773457, JString, required = false,
                                 default = nil)
  if valid_773457 != nil:
    section.add "X-Amz-Signature", valid_773457
  var valid_773458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773458 = validateParameter(valid_773458, JString, required = false,
                                 default = nil)
  if valid_773458 != nil:
    section.add "X-Amz-SignedHeaders", valid_773458
  var valid_773459 = header.getOrDefault("X-Amz-Credential")
  valid_773459 = validateParameter(valid_773459, JString, required = false,
                                 default = nil)
  if valid_773459 != nil:
    section.add "X-Amz-Credential", valid_773459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773461: Call_AdminRemoveUserFromGroup_773449; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified user from the specified group.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_773461.validator(path, query, header, formData, body)
  let scheme = call_773461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773461.url(scheme.get, call_773461.host, call_773461.base,
                         call_773461.route, valid.getOrDefault("path"))
  result = hook(call_773461, url, valid)

proc call*(call_773462: Call_AdminRemoveUserFromGroup_773449; body: JsonNode): Recallable =
  ## adminRemoveUserFromGroup
  ## <p>Removes the specified user from the specified group.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_773463 = newJObject()
  if body != nil:
    body_773463 = body
  result = call_773462.call(nil, nil, nil, nil, body_773463)

var adminRemoveUserFromGroup* = Call_AdminRemoveUserFromGroup_773449(
    name: "adminRemoveUserFromGroup", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminRemoveUserFromGroup",
    validator: validate_AdminRemoveUserFromGroup_773450, base: "/",
    url: url_AdminRemoveUserFromGroup_773451, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminResetUserPassword_773464 = ref object of OpenApiRestCall_772597
proc url_AdminResetUserPassword_773466(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminResetUserPassword_773465(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Resets the specified user's password in a user pool as an administrator. Works on any user.</p> <p>When a developer calls this API, the current password is invalidated, so it must be changed. If a user tries to sign in after the API is called, the app will get a PasswordResetRequiredException exception back and should direct the user down the flow to reset the password, which is the same as the forgot password flow. In addition, if the user pool has phone verification selected and a verified phone number exists for the user, or if email verification is selected and a verified email exists for the user, calling this API will also result in sending a message to the end user with the code to change their password.</p> <p>Requires developer credentials.</p>
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
  var valid_773467 = header.getOrDefault("X-Amz-Date")
  valid_773467 = validateParameter(valid_773467, JString, required = false,
                                 default = nil)
  if valid_773467 != nil:
    section.add "X-Amz-Date", valid_773467
  var valid_773468 = header.getOrDefault("X-Amz-Security-Token")
  valid_773468 = validateParameter(valid_773468, JString, required = false,
                                 default = nil)
  if valid_773468 != nil:
    section.add "X-Amz-Security-Token", valid_773468
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773469 = header.getOrDefault("X-Amz-Target")
  valid_773469 = validateParameter(valid_773469, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminResetUserPassword"))
  if valid_773469 != nil:
    section.add "X-Amz-Target", valid_773469
  var valid_773470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773470 = validateParameter(valid_773470, JString, required = false,
                                 default = nil)
  if valid_773470 != nil:
    section.add "X-Amz-Content-Sha256", valid_773470
  var valid_773471 = header.getOrDefault("X-Amz-Algorithm")
  valid_773471 = validateParameter(valid_773471, JString, required = false,
                                 default = nil)
  if valid_773471 != nil:
    section.add "X-Amz-Algorithm", valid_773471
  var valid_773472 = header.getOrDefault("X-Amz-Signature")
  valid_773472 = validateParameter(valid_773472, JString, required = false,
                                 default = nil)
  if valid_773472 != nil:
    section.add "X-Amz-Signature", valid_773472
  var valid_773473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773473 = validateParameter(valid_773473, JString, required = false,
                                 default = nil)
  if valid_773473 != nil:
    section.add "X-Amz-SignedHeaders", valid_773473
  var valid_773474 = header.getOrDefault("X-Amz-Credential")
  valid_773474 = validateParameter(valid_773474, JString, required = false,
                                 default = nil)
  if valid_773474 != nil:
    section.add "X-Amz-Credential", valid_773474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773476: Call_AdminResetUserPassword_773464; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Resets the specified user's password in a user pool as an administrator. Works on any user.</p> <p>When a developer calls this API, the current password is invalidated, so it must be changed. If a user tries to sign in after the API is called, the app will get a PasswordResetRequiredException exception back and should direct the user down the flow to reset the password, which is the same as the forgot password flow. In addition, if the user pool has phone verification selected and a verified phone number exists for the user, or if email verification is selected and a verified email exists for the user, calling this API will also result in sending a message to the end user with the code to change their password.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_773476.validator(path, query, header, formData, body)
  let scheme = call_773476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773476.url(scheme.get, call_773476.host, call_773476.base,
                         call_773476.route, valid.getOrDefault("path"))
  result = hook(call_773476, url, valid)

proc call*(call_773477: Call_AdminResetUserPassword_773464; body: JsonNode): Recallable =
  ## adminResetUserPassword
  ## <p>Resets the specified user's password in a user pool as an administrator. Works on any user.</p> <p>When a developer calls this API, the current password is invalidated, so it must be changed. If a user tries to sign in after the API is called, the app will get a PasswordResetRequiredException exception back and should direct the user down the flow to reset the password, which is the same as the forgot password flow. In addition, if the user pool has phone verification selected and a verified phone number exists for the user, or if email verification is selected and a verified email exists for the user, calling this API will also result in sending a message to the end user with the code to change their password.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_773478 = newJObject()
  if body != nil:
    body_773478 = body
  result = call_773477.call(nil, nil, nil, nil, body_773478)

var adminResetUserPassword* = Call_AdminResetUserPassword_773464(
    name: "adminResetUserPassword", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminResetUserPassword",
    validator: validate_AdminResetUserPassword_773465, base: "/",
    url: url_AdminResetUserPassword_773466, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminRespondToAuthChallenge_773479 = ref object of OpenApiRestCall_772597
proc url_AdminRespondToAuthChallenge_773481(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminRespondToAuthChallenge_773480(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Responds to an authentication challenge, as an administrator.</p> <p>Requires developer credentials.</p>
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
  var valid_773482 = header.getOrDefault("X-Amz-Date")
  valid_773482 = validateParameter(valid_773482, JString, required = false,
                                 default = nil)
  if valid_773482 != nil:
    section.add "X-Amz-Date", valid_773482
  var valid_773483 = header.getOrDefault("X-Amz-Security-Token")
  valid_773483 = validateParameter(valid_773483, JString, required = false,
                                 default = nil)
  if valid_773483 != nil:
    section.add "X-Amz-Security-Token", valid_773483
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773484 = header.getOrDefault("X-Amz-Target")
  valid_773484 = validateParameter(valid_773484, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminRespondToAuthChallenge"))
  if valid_773484 != nil:
    section.add "X-Amz-Target", valid_773484
  var valid_773485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773485 = validateParameter(valid_773485, JString, required = false,
                                 default = nil)
  if valid_773485 != nil:
    section.add "X-Amz-Content-Sha256", valid_773485
  var valid_773486 = header.getOrDefault("X-Amz-Algorithm")
  valid_773486 = validateParameter(valid_773486, JString, required = false,
                                 default = nil)
  if valid_773486 != nil:
    section.add "X-Amz-Algorithm", valid_773486
  var valid_773487 = header.getOrDefault("X-Amz-Signature")
  valid_773487 = validateParameter(valid_773487, JString, required = false,
                                 default = nil)
  if valid_773487 != nil:
    section.add "X-Amz-Signature", valid_773487
  var valid_773488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773488 = validateParameter(valid_773488, JString, required = false,
                                 default = nil)
  if valid_773488 != nil:
    section.add "X-Amz-SignedHeaders", valid_773488
  var valid_773489 = header.getOrDefault("X-Amz-Credential")
  valid_773489 = validateParameter(valid_773489, JString, required = false,
                                 default = nil)
  if valid_773489 != nil:
    section.add "X-Amz-Credential", valid_773489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773491: Call_AdminRespondToAuthChallenge_773479; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Responds to an authentication challenge, as an administrator.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_773491.validator(path, query, header, formData, body)
  let scheme = call_773491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773491.url(scheme.get, call_773491.host, call_773491.base,
                         call_773491.route, valid.getOrDefault("path"))
  result = hook(call_773491, url, valid)

proc call*(call_773492: Call_AdminRespondToAuthChallenge_773479; body: JsonNode): Recallable =
  ## adminRespondToAuthChallenge
  ## <p>Responds to an authentication challenge, as an administrator.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_773493 = newJObject()
  if body != nil:
    body_773493 = body
  result = call_773492.call(nil, nil, nil, nil, body_773493)

var adminRespondToAuthChallenge* = Call_AdminRespondToAuthChallenge_773479(
    name: "adminRespondToAuthChallenge", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminRespondToAuthChallenge",
    validator: validate_AdminRespondToAuthChallenge_773480, base: "/",
    url: url_AdminRespondToAuthChallenge_773481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminSetUserMFAPreference_773494 = ref object of OpenApiRestCall_772597
proc url_AdminSetUserMFAPreference_773496(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminSetUserMFAPreference_773495(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the user's multi-factor authentication (MFA) preference.
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
  var valid_773497 = header.getOrDefault("X-Amz-Date")
  valid_773497 = validateParameter(valid_773497, JString, required = false,
                                 default = nil)
  if valid_773497 != nil:
    section.add "X-Amz-Date", valid_773497
  var valid_773498 = header.getOrDefault("X-Amz-Security-Token")
  valid_773498 = validateParameter(valid_773498, JString, required = false,
                                 default = nil)
  if valid_773498 != nil:
    section.add "X-Amz-Security-Token", valid_773498
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773499 = header.getOrDefault("X-Amz-Target")
  valid_773499 = validateParameter(valid_773499, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminSetUserMFAPreference"))
  if valid_773499 != nil:
    section.add "X-Amz-Target", valid_773499
  var valid_773500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773500 = validateParameter(valid_773500, JString, required = false,
                                 default = nil)
  if valid_773500 != nil:
    section.add "X-Amz-Content-Sha256", valid_773500
  var valid_773501 = header.getOrDefault("X-Amz-Algorithm")
  valid_773501 = validateParameter(valid_773501, JString, required = false,
                                 default = nil)
  if valid_773501 != nil:
    section.add "X-Amz-Algorithm", valid_773501
  var valid_773502 = header.getOrDefault("X-Amz-Signature")
  valid_773502 = validateParameter(valid_773502, JString, required = false,
                                 default = nil)
  if valid_773502 != nil:
    section.add "X-Amz-Signature", valid_773502
  var valid_773503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773503 = validateParameter(valid_773503, JString, required = false,
                                 default = nil)
  if valid_773503 != nil:
    section.add "X-Amz-SignedHeaders", valid_773503
  var valid_773504 = header.getOrDefault("X-Amz-Credential")
  valid_773504 = validateParameter(valid_773504, JString, required = false,
                                 default = nil)
  if valid_773504 != nil:
    section.add "X-Amz-Credential", valid_773504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773506: Call_AdminSetUserMFAPreference_773494; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the user's multi-factor authentication (MFA) preference.
  ## 
  let valid = call_773506.validator(path, query, header, formData, body)
  let scheme = call_773506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773506.url(scheme.get, call_773506.host, call_773506.base,
                         call_773506.route, valid.getOrDefault("path"))
  result = hook(call_773506, url, valid)

proc call*(call_773507: Call_AdminSetUserMFAPreference_773494; body: JsonNode): Recallable =
  ## adminSetUserMFAPreference
  ## Sets the user's multi-factor authentication (MFA) preference.
  ##   body: JObject (required)
  var body_773508 = newJObject()
  if body != nil:
    body_773508 = body
  result = call_773507.call(nil, nil, nil, nil, body_773508)

var adminSetUserMFAPreference* = Call_AdminSetUserMFAPreference_773494(
    name: "adminSetUserMFAPreference", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminSetUserMFAPreference",
    validator: validate_AdminSetUserMFAPreference_773495, base: "/",
    url: url_AdminSetUserMFAPreference_773496,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminSetUserPassword_773509 = ref object of OpenApiRestCall_772597
proc url_AdminSetUserPassword_773511(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminSetUserPassword_773510(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_773512 = header.getOrDefault("X-Amz-Date")
  valid_773512 = validateParameter(valid_773512, JString, required = false,
                                 default = nil)
  if valid_773512 != nil:
    section.add "X-Amz-Date", valid_773512
  var valid_773513 = header.getOrDefault("X-Amz-Security-Token")
  valid_773513 = validateParameter(valid_773513, JString, required = false,
                                 default = nil)
  if valid_773513 != nil:
    section.add "X-Amz-Security-Token", valid_773513
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773514 = header.getOrDefault("X-Amz-Target")
  valid_773514 = validateParameter(valid_773514, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminSetUserPassword"))
  if valid_773514 != nil:
    section.add "X-Amz-Target", valid_773514
  var valid_773515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773515 = validateParameter(valid_773515, JString, required = false,
                                 default = nil)
  if valid_773515 != nil:
    section.add "X-Amz-Content-Sha256", valid_773515
  var valid_773516 = header.getOrDefault("X-Amz-Algorithm")
  valid_773516 = validateParameter(valid_773516, JString, required = false,
                                 default = nil)
  if valid_773516 != nil:
    section.add "X-Amz-Algorithm", valid_773516
  var valid_773517 = header.getOrDefault("X-Amz-Signature")
  valid_773517 = validateParameter(valid_773517, JString, required = false,
                                 default = nil)
  if valid_773517 != nil:
    section.add "X-Amz-Signature", valid_773517
  var valid_773518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773518 = validateParameter(valid_773518, JString, required = false,
                                 default = nil)
  if valid_773518 != nil:
    section.add "X-Amz-SignedHeaders", valid_773518
  var valid_773519 = header.getOrDefault("X-Amz-Credential")
  valid_773519 = validateParameter(valid_773519, JString, required = false,
                                 default = nil)
  if valid_773519 != nil:
    section.add "X-Amz-Credential", valid_773519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773521: Call_AdminSetUserPassword_773509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773521.validator(path, query, header, formData, body)
  let scheme = call_773521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773521.url(scheme.get, call_773521.host, call_773521.base,
                         call_773521.route, valid.getOrDefault("path"))
  result = hook(call_773521, url, valid)

proc call*(call_773522: Call_AdminSetUserPassword_773509; body: JsonNode): Recallable =
  ## adminSetUserPassword
  ##   body: JObject (required)
  var body_773523 = newJObject()
  if body != nil:
    body_773523 = body
  result = call_773522.call(nil, nil, nil, nil, body_773523)

var adminSetUserPassword* = Call_AdminSetUserPassword_773509(
    name: "adminSetUserPassword", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminSetUserPassword",
    validator: validate_AdminSetUserPassword_773510, base: "/",
    url: url_AdminSetUserPassword_773511, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminSetUserSettings_773524 = ref object of OpenApiRestCall_772597
proc url_AdminSetUserSettings_773526(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminSetUserSettings_773525(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sets all the user settings for a specified user name. Works on any user.</p> <p>Requires developer credentials.</p>
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
  var valid_773527 = header.getOrDefault("X-Amz-Date")
  valid_773527 = validateParameter(valid_773527, JString, required = false,
                                 default = nil)
  if valid_773527 != nil:
    section.add "X-Amz-Date", valid_773527
  var valid_773528 = header.getOrDefault("X-Amz-Security-Token")
  valid_773528 = validateParameter(valid_773528, JString, required = false,
                                 default = nil)
  if valid_773528 != nil:
    section.add "X-Amz-Security-Token", valid_773528
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773529 = header.getOrDefault("X-Amz-Target")
  valid_773529 = validateParameter(valid_773529, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminSetUserSettings"))
  if valid_773529 != nil:
    section.add "X-Amz-Target", valid_773529
  var valid_773530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773530 = validateParameter(valid_773530, JString, required = false,
                                 default = nil)
  if valid_773530 != nil:
    section.add "X-Amz-Content-Sha256", valid_773530
  var valid_773531 = header.getOrDefault("X-Amz-Algorithm")
  valid_773531 = validateParameter(valid_773531, JString, required = false,
                                 default = nil)
  if valid_773531 != nil:
    section.add "X-Amz-Algorithm", valid_773531
  var valid_773532 = header.getOrDefault("X-Amz-Signature")
  valid_773532 = validateParameter(valid_773532, JString, required = false,
                                 default = nil)
  if valid_773532 != nil:
    section.add "X-Amz-Signature", valid_773532
  var valid_773533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773533 = validateParameter(valid_773533, JString, required = false,
                                 default = nil)
  if valid_773533 != nil:
    section.add "X-Amz-SignedHeaders", valid_773533
  var valid_773534 = header.getOrDefault("X-Amz-Credential")
  valid_773534 = validateParameter(valid_773534, JString, required = false,
                                 default = nil)
  if valid_773534 != nil:
    section.add "X-Amz-Credential", valid_773534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773536: Call_AdminSetUserSettings_773524; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets all the user settings for a specified user name. Works on any user.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_773536.validator(path, query, header, formData, body)
  let scheme = call_773536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773536.url(scheme.get, call_773536.host, call_773536.base,
                         call_773536.route, valid.getOrDefault("path"))
  result = hook(call_773536, url, valid)

proc call*(call_773537: Call_AdminSetUserSettings_773524; body: JsonNode): Recallable =
  ## adminSetUserSettings
  ## <p>Sets all the user settings for a specified user name. Works on any user.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_773538 = newJObject()
  if body != nil:
    body_773538 = body
  result = call_773537.call(nil, nil, nil, nil, body_773538)

var adminSetUserSettings* = Call_AdminSetUserSettings_773524(
    name: "adminSetUserSettings", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminSetUserSettings",
    validator: validate_AdminSetUserSettings_773525, base: "/",
    url: url_AdminSetUserSettings_773526, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUpdateAuthEventFeedback_773539 = ref object of OpenApiRestCall_772597
proc url_AdminUpdateAuthEventFeedback_773541(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminUpdateAuthEventFeedback_773540(path: JsonNode; query: JsonNode;
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
  var valid_773542 = header.getOrDefault("X-Amz-Date")
  valid_773542 = validateParameter(valid_773542, JString, required = false,
                                 default = nil)
  if valid_773542 != nil:
    section.add "X-Amz-Date", valid_773542
  var valid_773543 = header.getOrDefault("X-Amz-Security-Token")
  valid_773543 = validateParameter(valid_773543, JString, required = false,
                                 default = nil)
  if valid_773543 != nil:
    section.add "X-Amz-Security-Token", valid_773543
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773544 = header.getOrDefault("X-Amz-Target")
  valid_773544 = validateParameter(valid_773544, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUpdateAuthEventFeedback"))
  if valid_773544 != nil:
    section.add "X-Amz-Target", valid_773544
  var valid_773545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773545 = validateParameter(valid_773545, JString, required = false,
                                 default = nil)
  if valid_773545 != nil:
    section.add "X-Amz-Content-Sha256", valid_773545
  var valid_773546 = header.getOrDefault("X-Amz-Algorithm")
  valid_773546 = validateParameter(valid_773546, JString, required = false,
                                 default = nil)
  if valid_773546 != nil:
    section.add "X-Amz-Algorithm", valid_773546
  var valid_773547 = header.getOrDefault("X-Amz-Signature")
  valid_773547 = validateParameter(valid_773547, JString, required = false,
                                 default = nil)
  if valid_773547 != nil:
    section.add "X-Amz-Signature", valid_773547
  var valid_773548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773548 = validateParameter(valid_773548, JString, required = false,
                                 default = nil)
  if valid_773548 != nil:
    section.add "X-Amz-SignedHeaders", valid_773548
  var valid_773549 = header.getOrDefault("X-Amz-Credential")
  valid_773549 = validateParameter(valid_773549, JString, required = false,
                                 default = nil)
  if valid_773549 != nil:
    section.add "X-Amz-Credential", valid_773549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773551: Call_AdminUpdateAuthEventFeedback_773539; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides feedback for an authentication event as to whether it was from a valid user. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ## 
  let valid = call_773551.validator(path, query, header, formData, body)
  let scheme = call_773551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773551.url(scheme.get, call_773551.host, call_773551.base,
                         call_773551.route, valid.getOrDefault("path"))
  result = hook(call_773551, url, valid)

proc call*(call_773552: Call_AdminUpdateAuthEventFeedback_773539; body: JsonNode): Recallable =
  ## adminUpdateAuthEventFeedback
  ## Provides feedback for an authentication event as to whether it was from a valid user. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ##   body: JObject (required)
  var body_773553 = newJObject()
  if body != nil:
    body_773553 = body
  result = call_773552.call(nil, nil, nil, nil, body_773553)

var adminUpdateAuthEventFeedback* = Call_AdminUpdateAuthEventFeedback_773539(
    name: "adminUpdateAuthEventFeedback", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUpdateAuthEventFeedback",
    validator: validate_AdminUpdateAuthEventFeedback_773540, base: "/",
    url: url_AdminUpdateAuthEventFeedback_773541,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUpdateDeviceStatus_773554 = ref object of OpenApiRestCall_772597
proc url_AdminUpdateDeviceStatus_773556(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminUpdateDeviceStatus_773555(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the device status as an administrator.</p> <p>Requires developer credentials.</p>
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
  var valid_773557 = header.getOrDefault("X-Amz-Date")
  valid_773557 = validateParameter(valid_773557, JString, required = false,
                                 default = nil)
  if valid_773557 != nil:
    section.add "X-Amz-Date", valid_773557
  var valid_773558 = header.getOrDefault("X-Amz-Security-Token")
  valid_773558 = validateParameter(valid_773558, JString, required = false,
                                 default = nil)
  if valid_773558 != nil:
    section.add "X-Amz-Security-Token", valid_773558
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773559 = header.getOrDefault("X-Amz-Target")
  valid_773559 = validateParameter(valid_773559, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUpdateDeviceStatus"))
  if valid_773559 != nil:
    section.add "X-Amz-Target", valid_773559
  var valid_773560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773560 = validateParameter(valid_773560, JString, required = false,
                                 default = nil)
  if valid_773560 != nil:
    section.add "X-Amz-Content-Sha256", valid_773560
  var valid_773561 = header.getOrDefault("X-Amz-Algorithm")
  valid_773561 = validateParameter(valid_773561, JString, required = false,
                                 default = nil)
  if valid_773561 != nil:
    section.add "X-Amz-Algorithm", valid_773561
  var valid_773562 = header.getOrDefault("X-Amz-Signature")
  valid_773562 = validateParameter(valid_773562, JString, required = false,
                                 default = nil)
  if valid_773562 != nil:
    section.add "X-Amz-Signature", valid_773562
  var valid_773563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773563 = validateParameter(valid_773563, JString, required = false,
                                 default = nil)
  if valid_773563 != nil:
    section.add "X-Amz-SignedHeaders", valid_773563
  var valid_773564 = header.getOrDefault("X-Amz-Credential")
  valid_773564 = validateParameter(valid_773564, JString, required = false,
                                 default = nil)
  if valid_773564 != nil:
    section.add "X-Amz-Credential", valid_773564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773566: Call_AdminUpdateDeviceStatus_773554; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the device status as an administrator.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_773566.validator(path, query, header, formData, body)
  let scheme = call_773566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773566.url(scheme.get, call_773566.host, call_773566.base,
                         call_773566.route, valid.getOrDefault("path"))
  result = hook(call_773566, url, valid)

proc call*(call_773567: Call_AdminUpdateDeviceStatus_773554; body: JsonNode): Recallable =
  ## adminUpdateDeviceStatus
  ## <p>Updates the device status as an administrator.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_773568 = newJObject()
  if body != nil:
    body_773568 = body
  result = call_773567.call(nil, nil, nil, nil, body_773568)

var adminUpdateDeviceStatus* = Call_AdminUpdateDeviceStatus_773554(
    name: "adminUpdateDeviceStatus", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUpdateDeviceStatus",
    validator: validate_AdminUpdateDeviceStatus_773555, base: "/",
    url: url_AdminUpdateDeviceStatus_773556, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUpdateUserAttributes_773569 = ref object of OpenApiRestCall_772597
proc url_AdminUpdateUserAttributes_773571(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminUpdateUserAttributes_773570(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the specified user's attributes, including developer attributes, as an administrator. Works on any user.</p> <p>For custom attributes, you must prepend the <code>custom:</code> prefix to the attribute name.</p> <p>In addition to updating user attributes, this API can also be used to mark phone and email as verified.</p> <p>Requires developer credentials.</p>
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
  var valid_773572 = header.getOrDefault("X-Amz-Date")
  valid_773572 = validateParameter(valid_773572, JString, required = false,
                                 default = nil)
  if valid_773572 != nil:
    section.add "X-Amz-Date", valid_773572
  var valid_773573 = header.getOrDefault("X-Amz-Security-Token")
  valid_773573 = validateParameter(valid_773573, JString, required = false,
                                 default = nil)
  if valid_773573 != nil:
    section.add "X-Amz-Security-Token", valid_773573
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773574 = header.getOrDefault("X-Amz-Target")
  valid_773574 = validateParameter(valid_773574, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUpdateUserAttributes"))
  if valid_773574 != nil:
    section.add "X-Amz-Target", valid_773574
  var valid_773575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773575 = validateParameter(valid_773575, JString, required = false,
                                 default = nil)
  if valid_773575 != nil:
    section.add "X-Amz-Content-Sha256", valid_773575
  var valid_773576 = header.getOrDefault("X-Amz-Algorithm")
  valid_773576 = validateParameter(valid_773576, JString, required = false,
                                 default = nil)
  if valid_773576 != nil:
    section.add "X-Amz-Algorithm", valid_773576
  var valid_773577 = header.getOrDefault("X-Amz-Signature")
  valid_773577 = validateParameter(valid_773577, JString, required = false,
                                 default = nil)
  if valid_773577 != nil:
    section.add "X-Amz-Signature", valid_773577
  var valid_773578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773578 = validateParameter(valid_773578, JString, required = false,
                                 default = nil)
  if valid_773578 != nil:
    section.add "X-Amz-SignedHeaders", valid_773578
  var valid_773579 = header.getOrDefault("X-Amz-Credential")
  valid_773579 = validateParameter(valid_773579, JString, required = false,
                                 default = nil)
  if valid_773579 != nil:
    section.add "X-Amz-Credential", valid_773579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773581: Call_AdminUpdateUserAttributes_773569; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified user's attributes, including developer attributes, as an administrator. Works on any user.</p> <p>For custom attributes, you must prepend the <code>custom:</code> prefix to the attribute name.</p> <p>In addition to updating user attributes, this API can also be used to mark phone and email as verified.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_773581.validator(path, query, header, formData, body)
  let scheme = call_773581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773581.url(scheme.get, call_773581.host, call_773581.base,
                         call_773581.route, valid.getOrDefault("path"))
  result = hook(call_773581, url, valid)

proc call*(call_773582: Call_AdminUpdateUserAttributes_773569; body: JsonNode): Recallable =
  ## adminUpdateUserAttributes
  ## <p>Updates the specified user's attributes, including developer attributes, as an administrator. Works on any user.</p> <p>For custom attributes, you must prepend the <code>custom:</code> prefix to the attribute name.</p> <p>In addition to updating user attributes, this API can also be used to mark phone and email as verified.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_773583 = newJObject()
  if body != nil:
    body_773583 = body
  result = call_773582.call(nil, nil, nil, nil, body_773583)

var adminUpdateUserAttributes* = Call_AdminUpdateUserAttributes_773569(
    name: "adminUpdateUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUpdateUserAttributes",
    validator: validate_AdminUpdateUserAttributes_773570, base: "/",
    url: url_AdminUpdateUserAttributes_773571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUserGlobalSignOut_773584 = ref object of OpenApiRestCall_772597
proc url_AdminUserGlobalSignOut_773586(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminUserGlobalSignOut_773585(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Signs out users from all devices, as an administrator.</p> <p>Requires developer credentials.</p>
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
  var valid_773587 = header.getOrDefault("X-Amz-Date")
  valid_773587 = validateParameter(valid_773587, JString, required = false,
                                 default = nil)
  if valid_773587 != nil:
    section.add "X-Amz-Date", valid_773587
  var valid_773588 = header.getOrDefault("X-Amz-Security-Token")
  valid_773588 = validateParameter(valid_773588, JString, required = false,
                                 default = nil)
  if valid_773588 != nil:
    section.add "X-Amz-Security-Token", valid_773588
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773589 = header.getOrDefault("X-Amz-Target")
  valid_773589 = validateParameter(valid_773589, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUserGlobalSignOut"))
  if valid_773589 != nil:
    section.add "X-Amz-Target", valid_773589
  var valid_773590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773590 = validateParameter(valid_773590, JString, required = false,
                                 default = nil)
  if valid_773590 != nil:
    section.add "X-Amz-Content-Sha256", valid_773590
  var valid_773591 = header.getOrDefault("X-Amz-Algorithm")
  valid_773591 = validateParameter(valid_773591, JString, required = false,
                                 default = nil)
  if valid_773591 != nil:
    section.add "X-Amz-Algorithm", valid_773591
  var valid_773592 = header.getOrDefault("X-Amz-Signature")
  valid_773592 = validateParameter(valid_773592, JString, required = false,
                                 default = nil)
  if valid_773592 != nil:
    section.add "X-Amz-Signature", valid_773592
  var valid_773593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773593 = validateParameter(valid_773593, JString, required = false,
                                 default = nil)
  if valid_773593 != nil:
    section.add "X-Amz-SignedHeaders", valid_773593
  var valid_773594 = header.getOrDefault("X-Amz-Credential")
  valid_773594 = validateParameter(valid_773594, JString, required = false,
                                 default = nil)
  if valid_773594 != nil:
    section.add "X-Amz-Credential", valid_773594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773596: Call_AdminUserGlobalSignOut_773584; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Signs out users from all devices, as an administrator.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_773596.validator(path, query, header, formData, body)
  let scheme = call_773596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773596.url(scheme.get, call_773596.host, call_773596.base,
                         call_773596.route, valid.getOrDefault("path"))
  result = hook(call_773596, url, valid)

proc call*(call_773597: Call_AdminUserGlobalSignOut_773584; body: JsonNode): Recallable =
  ## adminUserGlobalSignOut
  ## <p>Signs out users from all devices, as an administrator.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_773598 = newJObject()
  if body != nil:
    body_773598 = body
  result = call_773597.call(nil, nil, nil, nil, body_773598)

var adminUserGlobalSignOut* = Call_AdminUserGlobalSignOut_773584(
    name: "adminUserGlobalSignOut", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUserGlobalSignOut",
    validator: validate_AdminUserGlobalSignOut_773585, base: "/",
    url: url_AdminUserGlobalSignOut_773586, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSoftwareToken_773599 = ref object of OpenApiRestCall_772597
proc url_AssociateSoftwareToken_773601(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AssociateSoftwareToken_773600(path: JsonNode; query: JsonNode;
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
  var valid_773602 = header.getOrDefault("X-Amz-Date")
  valid_773602 = validateParameter(valid_773602, JString, required = false,
                                 default = nil)
  if valid_773602 != nil:
    section.add "X-Amz-Date", valid_773602
  var valid_773603 = header.getOrDefault("X-Amz-Security-Token")
  valid_773603 = validateParameter(valid_773603, JString, required = false,
                                 default = nil)
  if valid_773603 != nil:
    section.add "X-Amz-Security-Token", valid_773603
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773604 = header.getOrDefault("X-Amz-Target")
  valid_773604 = validateParameter(valid_773604, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AssociateSoftwareToken"))
  if valid_773604 != nil:
    section.add "X-Amz-Target", valid_773604
  var valid_773605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773605 = validateParameter(valid_773605, JString, required = false,
                                 default = nil)
  if valid_773605 != nil:
    section.add "X-Amz-Content-Sha256", valid_773605
  var valid_773606 = header.getOrDefault("X-Amz-Algorithm")
  valid_773606 = validateParameter(valid_773606, JString, required = false,
                                 default = nil)
  if valid_773606 != nil:
    section.add "X-Amz-Algorithm", valid_773606
  var valid_773607 = header.getOrDefault("X-Amz-Signature")
  valid_773607 = validateParameter(valid_773607, JString, required = false,
                                 default = nil)
  if valid_773607 != nil:
    section.add "X-Amz-Signature", valid_773607
  var valid_773608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773608 = validateParameter(valid_773608, JString, required = false,
                                 default = nil)
  if valid_773608 != nil:
    section.add "X-Amz-SignedHeaders", valid_773608
  var valid_773609 = header.getOrDefault("X-Amz-Credential")
  valid_773609 = validateParameter(valid_773609, JString, required = false,
                                 default = nil)
  if valid_773609 != nil:
    section.add "X-Amz-Credential", valid_773609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773611: Call_AssociateSoftwareToken_773599; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a unique generated shared secret key code for the user account. The request takes an access token or a session string, but not both.
  ## 
  let valid = call_773611.validator(path, query, header, formData, body)
  let scheme = call_773611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773611.url(scheme.get, call_773611.host, call_773611.base,
                         call_773611.route, valid.getOrDefault("path"))
  result = hook(call_773611, url, valid)

proc call*(call_773612: Call_AssociateSoftwareToken_773599; body: JsonNode): Recallable =
  ## associateSoftwareToken
  ## Returns a unique generated shared secret key code for the user account. The request takes an access token or a session string, but not both.
  ##   body: JObject (required)
  var body_773613 = newJObject()
  if body != nil:
    body_773613 = body
  result = call_773612.call(nil, nil, nil, nil, body_773613)

var associateSoftwareToken* = Call_AssociateSoftwareToken_773599(
    name: "associateSoftwareToken", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AssociateSoftwareToken",
    validator: validate_AssociateSoftwareToken_773600, base: "/",
    url: url_AssociateSoftwareToken_773601, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ChangePassword_773614 = ref object of OpenApiRestCall_772597
proc url_ChangePassword_773616(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ChangePassword_773615(path: JsonNode; query: JsonNode;
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
  var valid_773617 = header.getOrDefault("X-Amz-Date")
  valid_773617 = validateParameter(valid_773617, JString, required = false,
                                 default = nil)
  if valid_773617 != nil:
    section.add "X-Amz-Date", valid_773617
  var valid_773618 = header.getOrDefault("X-Amz-Security-Token")
  valid_773618 = validateParameter(valid_773618, JString, required = false,
                                 default = nil)
  if valid_773618 != nil:
    section.add "X-Amz-Security-Token", valid_773618
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773619 = header.getOrDefault("X-Amz-Target")
  valid_773619 = validateParameter(valid_773619, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ChangePassword"))
  if valid_773619 != nil:
    section.add "X-Amz-Target", valid_773619
  var valid_773620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773620 = validateParameter(valid_773620, JString, required = false,
                                 default = nil)
  if valid_773620 != nil:
    section.add "X-Amz-Content-Sha256", valid_773620
  var valid_773621 = header.getOrDefault("X-Amz-Algorithm")
  valid_773621 = validateParameter(valid_773621, JString, required = false,
                                 default = nil)
  if valid_773621 != nil:
    section.add "X-Amz-Algorithm", valid_773621
  var valid_773622 = header.getOrDefault("X-Amz-Signature")
  valid_773622 = validateParameter(valid_773622, JString, required = false,
                                 default = nil)
  if valid_773622 != nil:
    section.add "X-Amz-Signature", valid_773622
  var valid_773623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773623 = validateParameter(valid_773623, JString, required = false,
                                 default = nil)
  if valid_773623 != nil:
    section.add "X-Amz-SignedHeaders", valid_773623
  var valid_773624 = header.getOrDefault("X-Amz-Credential")
  valid_773624 = validateParameter(valid_773624, JString, required = false,
                                 default = nil)
  if valid_773624 != nil:
    section.add "X-Amz-Credential", valid_773624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773626: Call_ChangePassword_773614; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the password for a specified user in a user pool.
  ## 
  let valid = call_773626.validator(path, query, header, formData, body)
  let scheme = call_773626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773626.url(scheme.get, call_773626.host, call_773626.base,
                         call_773626.route, valid.getOrDefault("path"))
  result = hook(call_773626, url, valid)

proc call*(call_773627: Call_ChangePassword_773614; body: JsonNode): Recallable =
  ## changePassword
  ## Changes the password for a specified user in a user pool.
  ##   body: JObject (required)
  var body_773628 = newJObject()
  if body != nil:
    body_773628 = body
  result = call_773627.call(nil, nil, nil, nil, body_773628)

var changePassword* = Call_ChangePassword_773614(name: "changePassword",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ChangePassword",
    validator: validate_ChangePassword_773615, base: "/", url: url_ChangePassword_773616,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmDevice_773629 = ref object of OpenApiRestCall_772597
proc url_ConfirmDevice_773631(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ConfirmDevice_773630(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773632 = header.getOrDefault("X-Amz-Date")
  valid_773632 = validateParameter(valid_773632, JString, required = false,
                                 default = nil)
  if valid_773632 != nil:
    section.add "X-Amz-Date", valid_773632
  var valid_773633 = header.getOrDefault("X-Amz-Security-Token")
  valid_773633 = validateParameter(valid_773633, JString, required = false,
                                 default = nil)
  if valid_773633 != nil:
    section.add "X-Amz-Security-Token", valid_773633
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773634 = header.getOrDefault("X-Amz-Target")
  valid_773634 = validateParameter(valid_773634, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ConfirmDevice"))
  if valid_773634 != nil:
    section.add "X-Amz-Target", valid_773634
  var valid_773635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773635 = validateParameter(valid_773635, JString, required = false,
                                 default = nil)
  if valid_773635 != nil:
    section.add "X-Amz-Content-Sha256", valid_773635
  var valid_773636 = header.getOrDefault("X-Amz-Algorithm")
  valid_773636 = validateParameter(valid_773636, JString, required = false,
                                 default = nil)
  if valid_773636 != nil:
    section.add "X-Amz-Algorithm", valid_773636
  var valid_773637 = header.getOrDefault("X-Amz-Signature")
  valid_773637 = validateParameter(valid_773637, JString, required = false,
                                 default = nil)
  if valid_773637 != nil:
    section.add "X-Amz-Signature", valid_773637
  var valid_773638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773638 = validateParameter(valid_773638, JString, required = false,
                                 default = nil)
  if valid_773638 != nil:
    section.add "X-Amz-SignedHeaders", valid_773638
  var valid_773639 = header.getOrDefault("X-Amz-Credential")
  valid_773639 = validateParameter(valid_773639, JString, required = false,
                                 default = nil)
  if valid_773639 != nil:
    section.add "X-Amz-Credential", valid_773639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773641: Call_ConfirmDevice_773629; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Confirms tracking of the device. This API call is the call that begins device tracking.
  ## 
  let valid = call_773641.validator(path, query, header, formData, body)
  let scheme = call_773641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773641.url(scheme.get, call_773641.host, call_773641.base,
                         call_773641.route, valid.getOrDefault("path"))
  result = hook(call_773641, url, valid)

proc call*(call_773642: Call_ConfirmDevice_773629; body: JsonNode): Recallable =
  ## confirmDevice
  ## Confirms tracking of the device. This API call is the call that begins device tracking.
  ##   body: JObject (required)
  var body_773643 = newJObject()
  if body != nil:
    body_773643 = body
  result = call_773642.call(nil, nil, nil, nil, body_773643)

var confirmDevice* = Call_ConfirmDevice_773629(name: "confirmDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ConfirmDevice",
    validator: validate_ConfirmDevice_773630, base: "/", url: url_ConfirmDevice_773631,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmForgotPassword_773644 = ref object of OpenApiRestCall_772597
proc url_ConfirmForgotPassword_773646(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ConfirmForgotPassword_773645(path: JsonNode; query: JsonNode;
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
  var valid_773647 = header.getOrDefault("X-Amz-Date")
  valid_773647 = validateParameter(valid_773647, JString, required = false,
                                 default = nil)
  if valid_773647 != nil:
    section.add "X-Amz-Date", valid_773647
  var valid_773648 = header.getOrDefault("X-Amz-Security-Token")
  valid_773648 = validateParameter(valid_773648, JString, required = false,
                                 default = nil)
  if valid_773648 != nil:
    section.add "X-Amz-Security-Token", valid_773648
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773649 = header.getOrDefault("X-Amz-Target")
  valid_773649 = validateParameter(valid_773649, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ConfirmForgotPassword"))
  if valid_773649 != nil:
    section.add "X-Amz-Target", valid_773649
  var valid_773650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773650 = validateParameter(valid_773650, JString, required = false,
                                 default = nil)
  if valid_773650 != nil:
    section.add "X-Amz-Content-Sha256", valid_773650
  var valid_773651 = header.getOrDefault("X-Amz-Algorithm")
  valid_773651 = validateParameter(valid_773651, JString, required = false,
                                 default = nil)
  if valid_773651 != nil:
    section.add "X-Amz-Algorithm", valid_773651
  var valid_773652 = header.getOrDefault("X-Amz-Signature")
  valid_773652 = validateParameter(valid_773652, JString, required = false,
                                 default = nil)
  if valid_773652 != nil:
    section.add "X-Amz-Signature", valid_773652
  var valid_773653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773653 = validateParameter(valid_773653, JString, required = false,
                                 default = nil)
  if valid_773653 != nil:
    section.add "X-Amz-SignedHeaders", valid_773653
  var valid_773654 = header.getOrDefault("X-Amz-Credential")
  valid_773654 = validateParameter(valid_773654, JString, required = false,
                                 default = nil)
  if valid_773654 != nil:
    section.add "X-Amz-Credential", valid_773654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773656: Call_ConfirmForgotPassword_773644; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a user to enter a confirmation code to reset a forgotten password.
  ## 
  let valid = call_773656.validator(path, query, header, formData, body)
  let scheme = call_773656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773656.url(scheme.get, call_773656.host, call_773656.base,
                         call_773656.route, valid.getOrDefault("path"))
  result = hook(call_773656, url, valid)

proc call*(call_773657: Call_ConfirmForgotPassword_773644; body: JsonNode): Recallable =
  ## confirmForgotPassword
  ## Allows a user to enter a confirmation code to reset a forgotten password.
  ##   body: JObject (required)
  var body_773658 = newJObject()
  if body != nil:
    body_773658 = body
  result = call_773657.call(nil, nil, nil, nil, body_773658)

var confirmForgotPassword* = Call_ConfirmForgotPassword_773644(
    name: "confirmForgotPassword", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ConfirmForgotPassword",
    validator: validate_ConfirmForgotPassword_773645, base: "/",
    url: url_ConfirmForgotPassword_773646, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmSignUp_773659 = ref object of OpenApiRestCall_772597
proc url_ConfirmSignUp_773661(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ConfirmSignUp_773660(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773662 = header.getOrDefault("X-Amz-Date")
  valid_773662 = validateParameter(valid_773662, JString, required = false,
                                 default = nil)
  if valid_773662 != nil:
    section.add "X-Amz-Date", valid_773662
  var valid_773663 = header.getOrDefault("X-Amz-Security-Token")
  valid_773663 = validateParameter(valid_773663, JString, required = false,
                                 default = nil)
  if valid_773663 != nil:
    section.add "X-Amz-Security-Token", valid_773663
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773664 = header.getOrDefault("X-Amz-Target")
  valid_773664 = validateParameter(valid_773664, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ConfirmSignUp"))
  if valid_773664 != nil:
    section.add "X-Amz-Target", valid_773664
  var valid_773665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773665 = validateParameter(valid_773665, JString, required = false,
                                 default = nil)
  if valid_773665 != nil:
    section.add "X-Amz-Content-Sha256", valid_773665
  var valid_773666 = header.getOrDefault("X-Amz-Algorithm")
  valid_773666 = validateParameter(valid_773666, JString, required = false,
                                 default = nil)
  if valid_773666 != nil:
    section.add "X-Amz-Algorithm", valid_773666
  var valid_773667 = header.getOrDefault("X-Amz-Signature")
  valid_773667 = validateParameter(valid_773667, JString, required = false,
                                 default = nil)
  if valid_773667 != nil:
    section.add "X-Amz-Signature", valid_773667
  var valid_773668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773668 = validateParameter(valid_773668, JString, required = false,
                                 default = nil)
  if valid_773668 != nil:
    section.add "X-Amz-SignedHeaders", valid_773668
  var valid_773669 = header.getOrDefault("X-Amz-Credential")
  valid_773669 = validateParameter(valid_773669, JString, required = false,
                                 default = nil)
  if valid_773669 != nil:
    section.add "X-Amz-Credential", valid_773669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773671: Call_ConfirmSignUp_773659; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Confirms registration of a user and handles the existing alias from a previous user.
  ## 
  let valid = call_773671.validator(path, query, header, formData, body)
  let scheme = call_773671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773671.url(scheme.get, call_773671.host, call_773671.base,
                         call_773671.route, valid.getOrDefault("path"))
  result = hook(call_773671, url, valid)

proc call*(call_773672: Call_ConfirmSignUp_773659; body: JsonNode): Recallable =
  ## confirmSignUp
  ## Confirms registration of a user and handles the existing alias from a previous user.
  ##   body: JObject (required)
  var body_773673 = newJObject()
  if body != nil:
    body_773673 = body
  result = call_773672.call(nil, nil, nil, nil, body_773673)

var confirmSignUp* = Call_ConfirmSignUp_773659(name: "confirmSignUp",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ConfirmSignUp",
    validator: validate_ConfirmSignUp_773660, base: "/", url: url_ConfirmSignUp_773661,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_773674 = ref object of OpenApiRestCall_772597
proc url_CreateGroup_773676(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateGroup_773675(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new group in the specified user pool.</p> <p>Requires developer credentials.</p>
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
  var valid_773677 = header.getOrDefault("X-Amz-Date")
  valid_773677 = validateParameter(valid_773677, JString, required = false,
                                 default = nil)
  if valid_773677 != nil:
    section.add "X-Amz-Date", valid_773677
  var valid_773678 = header.getOrDefault("X-Amz-Security-Token")
  valid_773678 = validateParameter(valid_773678, JString, required = false,
                                 default = nil)
  if valid_773678 != nil:
    section.add "X-Amz-Security-Token", valid_773678
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773679 = header.getOrDefault("X-Amz-Target")
  valid_773679 = validateParameter(valid_773679, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateGroup"))
  if valid_773679 != nil:
    section.add "X-Amz-Target", valid_773679
  var valid_773680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773680 = validateParameter(valid_773680, JString, required = false,
                                 default = nil)
  if valid_773680 != nil:
    section.add "X-Amz-Content-Sha256", valid_773680
  var valid_773681 = header.getOrDefault("X-Amz-Algorithm")
  valid_773681 = validateParameter(valid_773681, JString, required = false,
                                 default = nil)
  if valid_773681 != nil:
    section.add "X-Amz-Algorithm", valid_773681
  var valid_773682 = header.getOrDefault("X-Amz-Signature")
  valid_773682 = validateParameter(valid_773682, JString, required = false,
                                 default = nil)
  if valid_773682 != nil:
    section.add "X-Amz-Signature", valid_773682
  var valid_773683 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773683 = validateParameter(valid_773683, JString, required = false,
                                 default = nil)
  if valid_773683 != nil:
    section.add "X-Amz-SignedHeaders", valid_773683
  var valid_773684 = header.getOrDefault("X-Amz-Credential")
  valid_773684 = validateParameter(valid_773684, JString, required = false,
                                 default = nil)
  if valid_773684 != nil:
    section.add "X-Amz-Credential", valid_773684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773686: Call_CreateGroup_773674; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new group in the specified user pool.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_773686.validator(path, query, header, formData, body)
  let scheme = call_773686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773686.url(scheme.get, call_773686.host, call_773686.base,
                         call_773686.route, valid.getOrDefault("path"))
  result = hook(call_773686, url, valid)

proc call*(call_773687: Call_CreateGroup_773674; body: JsonNode): Recallable =
  ## createGroup
  ## <p>Creates a new group in the specified user pool.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_773688 = newJObject()
  if body != nil:
    body_773688 = body
  result = call_773687.call(nil, nil, nil, nil, body_773688)

var createGroup* = Call_CreateGroup_773674(name: "createGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateGroup",
                                        validator: validate_CreateGroup_773675,
                                        base: "/", url: url_CreateGroup_773676,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIdentityProvider_773689 = ref object of OpenApiRestCall_772597
proc url_CreateIdentityProvider_773691(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateIdentityProvider_773690(path: JsonNode; query: JsonNode;
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
  var valid_773692 = header.getOrDefault("X-Amz-Date")
  valid_773692 = validateParameter(valid_773692, JString, required = false,
                                 default = nil)
  if valid_773692 != nil:
    section.add "X-Amz-Date", valid_773692
  var valid_773693 = header.getOrDefault("X-Amz-Security-Token")
  valid_773693 = validateParameter(valid_773693, JString, required = false,
                                 default = nil)
  if valid_773693 != nil:
    section.add "X-Amz-Security-Token", valid_773693
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773694 = header.getOrDefault("X-Amz-Target")
  valid_773694 = validateParameter(valid_773694, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateIdentityProvider"))
  if valid_773694 != nil:
    section.add "X-Amz-Target", valid_773694
  var valid_773695 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773695 = validateParameter(valid_773695, JString, required = false,
                                 default = nil)
  if valid_773695 != nil:
    section.add "X-Amz-Content-Sha256", valid_773695
  var valid_773696 = header.getOrDefault("X-Amz-Algorithm")
  valid_773696 = validateParameter(valid_773696, JString, required = false,
                                 default = nil)
  if valid_773696 != nil:
    section.add "X-Amz-Algorithm", valid_773696
  var valid_773697 = header.getOrDefault("X-Amz-Signature")
  valid_773697 = validateParameter(valid_773697, JString, required = false,
                                 default = nil)
  if valid_773697 != nil:
    section.add "X-Amz-Signature", valid_773697
  var valid_773698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773698 = validateParameter(valid_773698, JString, required = false,
                                 default = nil)
  if valid_773698 != nil:
    section.add "X-Amz-SignedHeaders", valid_773698
  var valid_773699 = header.getOrDefault("X-Amz-Credential")
  valid_773699 = validateParameter(valid_773699, JString, required = false,
                                 default = nil)
  if valid_773699 != nil:
    section.add "X-Amz-Credential", valid_773699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773701: Call_CreateIdentityProvider_773689; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an identity provider for a user pool.
  ## 
  let valid = call_773701.validator(path, query, header, formData, body)
  let scheme = call_773701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773701.url(scheme.get, call_773701.host, call_773701.base,
                         call_773701.route, valid.getOrDefault("path"))
  result = hook(call_773701, url, valid)

proc call*(call_773702: Call_CreateIdentityProvider_773689; body: JsonNode): Recallable =
  ## createIdentityProvider
  ## Creates an identity provider for a user pool.
  ##   body: JObject (required)
  var body_773703 = newJObject()
  if body != nil:
    body_773703 = body
  result = call_773702.call(nil, nil, nil, nil, body_773703)

var createIdentityProvider* = Call_CreateIdentityProvider_773689(
    name: "createIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateIdentityProvider",
    validator: validate_CreateIdentityProvider_773690, base: "/",
    url: url_CreateIdentityProvider_773691, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceServer_773704 = ref object of OpenApiRestCall_772597
proc url_CreateResourceServer_773706(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateResourceServer_773705(path: JsonNode; query: JsonNode;
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
  var valid_773707 = header.getOrDefault("X-Amz-Date")
  valid_773707 = validateParameter(valid_773707, JString, required = false,
                                 default = nil)
  if valid_773707 != nil:
    section.add "X-Amz-Date", valid_773707
  var valid_773708 = header.getOrDefault("X-Amz-Security-Token")
  valid_773708 = validateParameter(valid_773708, JString, required = false,
                                 default = nil)
  if valid_773708 != nil:
    section.add "X-Amz-Security-Token", valid_773708
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773709 = header.getOrDefault("X-Amz-Target")
  valid_773709 = validateParameter(valid_773709, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateResourceServer"))
  if valid_773709 != nil:
    section.add "X-Amz-Target", valid_773709
  var valid_773710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773710 = validateParameter(valid_773710, JString, required = false,
                                 default = nil)
  if valid_773710 != nil:
    section.add "X-Amz-Content-Sha256", valid_773710
  var valid_773711 = header.getOrDefault("X-Amz-Algorithm")
  valid_773711 = validateParameter(valid_773711, JString, required = false,
                                 default = nil)
  if valid_773711 != nil:
    section.add "X-Amz-Algorithm", valid_773711
  var valid_773712 = header.getOrDefault("X-Amz-Signature")
  valid_773712 = validateParameter(valid_773712, JString, required = false,
                                 default = nil)
  if valid_773712 != nil:
    section.add "X-Amz-Signature", valid_773712
  var valid_773713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773713 = validateParameter(valid_773713, JString, required = false,
                                 default = nil)
  if valid_773713 != nil:
    section.add "X-Amz-SignedHeaders", valid_773713
  var valid_773714 = header.getOrDefault("X-Amz-Credential")
  valid_773714 = validateParameter(valid_773714, JString, required = false,
                                 default = nil)
  if valid_773714 != nil:
    section.add "X-Amz-Credential", valid_773714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773716: Call_CreateResourceServer_773704; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new OAuth2.0 resource server and defines custom scopes in it.
  ## 
  let valid = call_773716.validator(path, query, header, formData, body)
  let scheme = call_773716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773716.url(scheme.get, call_773716.host, call_773716.base,
                         call_773716.route, valid.getOrDefault("path"))
  result = hook(call_773716, url, valid)

proc call*(call_773717: Call_CreateResourceServer_773704; body: JsonNode): Recallable =
  ## createResourceServer
  ## Creates a new OAuth2.0 resource server and defines custom scopes in it.
  ##   body: JObject (required)
  var body_773718 = newJObject()
  if body != nil:
    body_773718 = body
  result = call_773717.call(nil, nil, nil, nil, body_773718)

var createResourceServer* = Call_CreateResourceServer_773704(
    name: "createResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateResourceServer",
    validator: validate_CreateResourceServer_773705, base: "/",
    url: url_CreateResourceServer_773706, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserImportJob_773719 = ref object of OpenApiRestCall_772597
proc url_CreateUserImportJob_773721(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateUserImportJob_773720(path: JsonNode; query: JsonNode;
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
  var valid_773722 = header.getOrDefault("X-Amz-Date")
  valid_773722 = validateParameter(valid_773722, JString, required = false,
                                 default = nil)
  if valid_773722 != nil:
    section.add "X-Amz-Date", valid_773722
  var valid_773723 = header.getOrDefault("X-Amz-Security-Token")
  valid_773723 = validateParameter(valid_773723, JString, required = false,
                                 default = nil)
  if valid_773723 != nil:
    section.add "X-Amz-Security-Token", valid_773723
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773724 = header.getOrDefault("X-Amz-Target")
  valid_773724 = validateParameter(valid_773724, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserImportJob"))
  if valid_773724 != nil:
    section.add "X-Amz-Target", valid_773724
  var valid_773725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773725 = validateParameter(valid_773725, JString, required = false,
                                 default = nil)
  if valid_773725 != nil:
    section.add "X-Amz-Content-Sha256", valid_773725
  var valid_773726 = header.getOrDefault("X-Amz-Algorithm")
  valid_773726 = validateParameter(valid_773726, JString, required = false,
                                 default = nil)
  if valid_773726 != nil:
    section.add "X-Amz-Algorithm", valid_773726
  var valid_773727 = header.getOrDefault("X-Amz-Signature")
  valid_773727 = validateParameter(valid_773727, JString, required = false,
                                 default = nil)
  if valid_773727 != nil:
    section.add "X-Amz-Signature", valid_773727
  var valid_773728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773728 = validateParameter(valid_773728, JString, required = false,
                                 default = nil)
  if valid_773728 != nil:
    section.add "X-Amz-SignedHeaders", valid_773728
  var valid_773729 = header.getOrDefault("X-Amz-Credential")
  valid_773729 = validateParameter(valid_773729, JString, required = false,
                                 default = nil)
  if valid_773729 != nil:
    section.add "X-Amz-Credential", valid_773729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773731: Call_CreateUserImportJob_773719; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates the user import job.
  ## 
  let valid = call_773731.validator(path, query, header, formData, body)
  let scheme = call_773731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773731.url(scheme.get, call_773731.host, call_773731.base,
                         call_773731.route, valid.getOrDefault("path"))
  result = hook(call_773731, url, valid)

proc call*(call_773732: Call_CreateUserImportJob_773719; body: JsonNode): Recallable =
  ## createUserImportJob
  ## Creates the user import job.
  ##   body: JObject (required)
  var body_773733 = newJObject()
  if body != nil:
    body_773733 = body
  result = call_773732.call(nil, nil, nil, nil, body_773733)

var createUserImportJob* = Call_CreateUserImportJob_773719(
    name: "createUserImportJob", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserImportJob",
    validator: validate_CreateUserImportJob_773720, base: "/",
    url: url_CreateUserImportJob_773721, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserPool_773734 = ref object of OpenApiRestCall_772597
proc url_CreateUserPool_773736(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateUserPool_773735(path: JsonNode; query: JsonNode;
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
  var valid_773737 = header.getOrDefault("X-Amz-Date")
  valid_773737 = validateParameter(valid_773737, JString, required = false,
                                 default = nil)
  if valid_773737 != nil:
    section.add "X-Amz-Date", valid_773737
  var valid_773738 = header.getOrDefault("X-Amz-Security-Token")
  valid_773738 = validateParameter(valid_773738, JString, required = false,
                                 default = nil)
  if valid_773738 != nil:
    section.add "X-Amz-Security-Token", valid_773738
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773739 = header.getOrDefault("X-Amz-Target")
  valid_773739 = validateParameter(valid_773739, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserPool"))
  if valid_773739 != nil:
    section.add "X-Amz-Target", valid_773739
  var valid_773740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773740 = validateParameter(valid_773740, JString, required = false,
                                 default = nil)
  if valid_773740 != nil:
    section.add "X-Amz-Content-Sha256", valid_773740
  var valid_773741 = header.getOrDefault("X-Amz-Algorithm")
  valid_773741 = validateParameter(valid_773741, JString, required = false,
                                 default = nil)
  if valid_773741 != nil:
    section.add "X-Amz-Algorithm", valid_773741
  var valid_773742 = header.getOrDefault("X-Amz-Signature")
  valid_773742 = validateParameter(valid_773742, JString, required = false,
                                 default = nil)
  if valid_773742 != nil:
    section.add "X-Amz-Signature", valid_773742
  var valid_773743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773743 = validateParameter(valid_773743, JString, required = false,
                                 default = nil)
  if valid_773743 != nil:
    section.add "X-Amz-SignedHeaders", valid_773743
  var valid_773744 = header.getOrDefault("X-Amz-Credential")
  valid_773744 = validateParameter(valid_773744, JString, required = false,
                                 default = nil)
  if valid_773744 != nil:
    section.add "X-Amz-Credential", valid_773744
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773746: Call_CreateUserPool_773734; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon Cognito user pool and sets the password policy for the pool.
  ## 
  let valid = call_773746.validator(path, query, header, formData, body)
  let scheme = call_773746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773746.url(scheme.get, call_773746.host, call_773746.base,
                         call_773746.route, valid.getOrDefault("path"))
  result = hook(call_773746, url, valid)

proc call*(call_773747: Call_CreateUserPool_773734; body: JsonNode): Recallable =
  ## createUserPool
  ## Creates a new Amazon Cognito user pool and sets the password policy for the pool.
  ##   body: JObject (required)
  var body_773748 = newJObject()
  if body != nil:
    body_773748 = body
  result = call_773747.call(nil, nil, nil, nil, body_773748)

var createUserPool* = Call_CreateUserPool_773734(name: "createUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserPool",
    validator: validate_CreateUserPool_773735, base: "/", url: url_CreateUserPool_773736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserPoolClient_773749 = ref object of OpenApiRestCall_772597
proc url_CreateUserPoolClient_773751(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateUserPoolClient_773750(path: JsonNode; query: JsonNode;
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
  var valid_773752 = header.getOrDefault("X-Amz-Date")
  valid_773752 = validateParameter(valid_773752, JString, required = false,
                                 default = nil)
  if valid_773752 != nil:
    section.add "X-Amz-Date", valid_773752
  var valid_773753 = header.getOrDefault("X-Amz-Security-Token")
  valid_773753 = validateParameter(valid_773753, JString, required = false,
                                 default = nil)
  if valid_773753 != nil:
    section.add "X-Amz-Security-Token", valid_773753
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773754 = header.getOrDefault("X-Amz-Target")
  valid_773754 = validateParameter(valid_773754, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserPoolClient"))
  if valid_773754 != nil:
    section.add "X-Amz-Target", valid_773754
  var valid_773755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773755 = validateParameter(valid_773755, JString, required = false,
                                 default = nil)
  if valid_773755 != nil:
    section.add "X-Amz-Content-Sha256", valid_773755
  var valid_773756 = header.getOrDefault("X-Amz-Algorithm")
  valid_773756 = validateParameter(valid_773756, JString, required = false,
                                 default = nil)
  if valid_773756 != nil:
    section.add "X-Amz-Algorithm", valid_773756
  var valid_773757 = header.getOrDefault("X-Amz-Signature")
  valid_773757 = validateParameter(valid_773757, JString, required = false,
                                 default = nil)
  if valid_773757 != nil:
    section.add "X-Amz-Signature", valid_773757
  var valid_773758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773758 = validateParameter(valid_773758, JString, required = false,
                                 default = nil)
  if valid_773758 != nil:
    section.add "X-Amz-SignedHeaders", valid_773758
  var valid_773759 = header.getOrDefault("X-Amz-Credential")
  valid_773759 = validateParameter(valid_773759, JString, required = false,
                                 default = nil)
  if valid_773759 != nil:
    section.add "X-Amz-Credential", valid_773759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773761: Call_CreateUserPoolClient_773749; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates the user pool client.
  ## 
  let valid = call_773761.validator(path, query, header, formData, body)
  let scheme = call_773761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773761.url(scheme.get, call_773761.host, call_773761.base,
                         call_773761.route, valid.getOrDefault("path"))
  result = hook(call_773761, url, valid)

proc call*(call_773762: Call_CreateUserPoolClient_773749; body: JsonNode): Recallable =
  ## createUserPoolClient
  ## Creates the user pool client.
  ##   body: JObject (required)
  var body_773763 = newJObject()
  if body != nil:
    body_773763 = body
  result = call_773762.call(nil, nil, nil, nil, body_773763)

var createUserPoolClient* = Call_CreateUserPoolClient_773749(
    name: "createUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserPoolClient",
    validator: validate_CreateUserPoolClient_773750, base: "/",
    url: url_CreateUserPoolClient_773751, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserPoolDomain_773764 = ref object of OpenApiRestCall_772597
proc url_CreateUserPoolDomain_773766(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateUserPoolDomain_773765(path: JsonNode; query: JsonNode;
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
  var valid_773767 = header.getOrDefault("X-Amz-Date")
  valid_773767 = validateParameter(valid_773767, JString, required = false,
                                 default = nil)
  if valid_773767 != nil:
    section.add "X-Amz-Date", valid_773767
  var valid_773768 = header.getOrDefault("X-Amz-Security-Token")
  valid_773768 = validateParameter(valid_773768, JString, required = false,
                                 default = nil)
  if valid_773768 != nil:
    section.add "X-Amz-Security-Token", valid_773768
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773769 = header.getOrDefault("X-Amz-Target")
  valid_773769 = validateParameter(valid_773769, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserPoolDomain"))
  if valid_773769 != nil:
    section.add "X-Amz-Target", valid_773769
  var valid_773770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773770 = validateParameter(valid_773770, JString, required = false,
                                 default = nil)
  if valid_773770 != nil:
    section.add "X-Amz-Content-Sha256", valid_773770
  var valid_773771 = header.getOrDefault("X-Amz-Algorithm")
  valid_773771 = validateParameter(valid_773771, JString, required = false,
                                 default = nil)
  if valid_773771 != nil:
    section.add "X-Amz-Algorithm", valid_773771
  var valid_773772 = header.getOrDefault("X-Amz-Signature")
  valid_773772 = validateParameter(valid_773772, JString, required = false,
                                 default = nil)
  if valid_773772 != nil:
    section.add "X-Amz-Signature", valid_773772
  var valid_773773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773773 = validateParameter(valid_773773, JString, required = false,
                                 default = nil)
  if valid_773773 != nil:
    section.add "X-Amz-SignedHeaders", valid_773773
  var valid_773774 = header.getOrDefault("X-Amz-Credential")
  valid_773774 = validateParameter(valid_773774, JString, required = false,
                                 default = nil)
  if valid_773774 != nil:
    section.add "X-Amz-Credential", valid_773774
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773776: Call_CreateUserPoolDomain_773764; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new domain for a user pool.
  ## 
  let valid = call_773776.validator(path, query, header, formData, body)
  let scheme = call_773776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773776.url(scheme.get, call_773776.host, call_773776.base,
                         call_773776.route, valid.getOrDefault("path"))
  result = hook(call_773776, url, valid)

proc call*(call_773777: Call_CreateUserPoolDomain_773764; body: JsonNode): Recallable =
  ## createUserPoolDomain
  ## Creates a new domain for a user pool.
  ##   body: JObject (required)
  var body_773778 = newJObject()
  if body != nil:
    body_773778 = body
  result = call_773777.call(nil, nil, nil, nil, body_773778)

var createUserPoolDomain* = Call_CreateUserPoolDomain_773764(
    name: "createUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserPoolDomain",
    validator: validate_CreateUserPoolDomain_773765, base: "/",
    url: url_CreateUserPoolDomain_773766, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_773779 = ref object of OpenApiRestCall_772597
proc url_DeleteGroup_773781(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteGroup_773780(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a group. Currently only groups with no members can be deleted.</p> <p>Requires developer credentials.</p>
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
  var valid_773782 = header.getOrDefault("X-Amz-Date")
  valid_773782 = validateParameter(valid_773782, JString, required = false,
                                 default = nil)
  if valid_773782 != nil:
    section.add "X-Amz-Date", valid_773782
  var valid_773783 = header.getOrDefault("X-Amz-Security-Token")
  valid_773783 = validateParameter(valid_773783, JString, required = false,
                                 default = nil)
  if valid_773783 != nil:
    section.add "X-Amz-Security-Token", valid_773783
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773784 = header.getOrDefault("X-Amz-Target")
  valid_773784 = validateParameter(valid_773784, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteGroup"))
  if valid_773784 != nil:
    section.add "X-Amz-Target", valid_773784
  var valid_773785 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773785 = validateParameter(valid_773785, JString, required = false,
                                 default = nil)
  if valid_773785 != nil:
    section.add "X-Amz-Content-Sha256", valid_773785
  var valid_773786 = header.getOrDefault("X-Amz-Algorithm")
  valid_773786 = validateParameter(valid_773786, JString, required = false,
                                 default = nil)
  if valid_773786 != nil:
    section.add "X-Amz-Algorithm", valid_773786
  var valid_773787 = header.getOrDefault("X-Amz-Signature")
  valid_773787 = validateParameter(valid_773787, JString, required = false,
                                 default = nil)
  if valid_773787 != nil:
    section.add "X-Amz-Signature", valid_773787
  var valid_773788 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773788 = validateParameter(valid_773788, JString, required = false,
                                 default = nil)
  if valid_773788 != nil:
    section.add "X-Amz-SignedHeaders", valid_773788
  var valid_773789 = header.getOrDefault("X-Amz-Credential")
  valid_773789 = validateParameter(valid_773789, JString, required = false,
                                 default = nil)
  if valid_773789 != nil:
    section.add "X-Amz-Credential", valid_773789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773791: Call_DeleteGroup_773779; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a group. Currently only groups with no members can be deleted.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_773791.validator(path, query, header, formData, body)
  let scheme = call_773791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773791.url(scheme.get, call_773791.host, call_773791.base,
                         call_773791.route, valid.getOrDefault("path"))
  result = hook(call_773791, url, valid)

proc call*(call_773792: Call_DeleteGroup_773779; body: JsonNode): Recallable =
  ## deleteGroup
  ## <p>Deletes a group. Currently only groups with no members can be deleted.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_773793 = newJObject()
  if body != nil:
    body_773793 = body
  result = call_773792.call(nil, nil, nil, nil, body_773793)

var deleteGroup* = Call_DeleteGroup_773779(name: "deleteGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteGroup",
                                        validator: validate_DeleteGroup_773780,
                                        base: "/", url: url_DeleteGroup_773781,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIdentityProvider_773794 = ref object of OpenApiRestCall_772597
proc url_DeleteIdentityProvider_773796(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteIdentityProvider_773795(path: JsonNode; query: JsonNode;
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
  var valid_773797 = header.getOrDefault("X-Amz-Date")
  valid_773797 = validateParameter(valid_773797, JString, required = false,
                                 default = nil)
  if valid_773797 != nil:
    section.add "X-Amz-Date", valid_773797
  var valid_773798 = header.getOrDefault("X-Amz-Security-Token")
  valid_773798 = validateParameter(valid_773798, JString, required = false,
                                 default = nil)
  if valid_773798 != nil:
    section.add "X-Amz-Security-Token", valid_773798
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773799 = header.getOrDefault("X-Amz-Target")
  valid_773799 = validateParameter(valid_773799, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteIdentityProvider"))
  if valid_773799 != nil:
    section.add "X-Amz-Target", valid_773799
  var valid_773800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773800 = validateParameter(valid_773800, JString, required = false,
                                 default = nil)
  if valid_773800 != nil:
    section.add "X-Amz-Content-Sha256", valid_773800
  var valid_773801 = header.getOrDefault("X-Amz-Algorithm")
  valid_773801 = validateParameter(valid_773801, JString, required = false,
                                 default = nil)
  if valid_773801 != nil:
    section.add "X-Amz-Algorithm", valid_773801
  var valid_773802 = header.getOrDefault("X-Amz-Signature")
  valid_773802 = validateParameter(valid_773802, JString, required = false,
                                 default = nil)
  if valid_773802 != nil:
    section.add "X-Amz-Signature", valid_773802
  var valid_773803 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773803 = validateParameter(valid_773803, JString, required = false,
                                 default = nil)
  if valid_773803 != nil:
    section.add "X-Amz-SignedHeaders", valid_773803
  var valid_773804 = header.getOrDefault("X-Amz-Credential")
  valid_773804 = validateParameter(valid_773804, JString, required = false,
                                 default = nil)
  if valid_773804 != nil:
    section.add "X-Amz-Credential", valid_773804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773806: Call_DeleteIdentityProvider_773794; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an identity provider for a user pool.
  ## 
  let valid = call_773806.validator(path, query, header, formData, body)
  let scheme = call_773806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773806.url(scheme.get, call_773806.host, call_773806.base,
                         call_773806.route, valid.getOrDefault("path"))
  result = hook(call_773806, url, valid)

proc call*(call_773807: Call_DeleteIdentityProvider_773794; body: JsonNode): Recallable =
  ## deleteIdentityProvider
  ## Deletes an identity provider for a user pool.
  ##   body: JObject (required)
  var body_773808 = newJObject()
  if body != nil:
    body_773808 = body
  result = call_773807.call(nil, nil, nil, nil, body_773808)

var deleteIdentityProvider* = Call_DeleteIdentityProvider_773794(
    name: "deleteIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteIdentityProvider",
    validator: validate_DeleteIdentityProvider_773795, base: "/",
    url: url_DeleteIdentityProvider_773796, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceServer_773809 = ref object of OpenApiRestCall_772597
proc url_DeleteResourceServer_773811(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteResourceServer_773810(path: JsonNode; query: JsonNode;
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
  var valid_773812 = header.getOrDefault("X-Amz-Date")
  valid_773812 = validateParameter(valid_773812, JString, required = false,
                                 default = nil)
  if valid_773812 != nil:
    section.add "X-Amz-Date", valid_773812
  var valid_773813 = header.getOrDefault("X-Amz-Security-Token")
  valid_773813 = validateParameter(valid_773813, JString, required = false,
                                 default = nil)
  if valid_773813 != nil:
    section.add "X-Amz-Security-Token", valid_773813
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773814 = header.getOrDefault("X-Amz-Target")
  valid_773814 = validateParameter(valid_773814, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteResourceServer"))
  if valid_773814 != nil:
    section.add "X-Amz-Target", valid_773814
  var valid_773815 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773815 = validateParameter(valid_773815, JString, required = false,
                                 default = nil)
  if valid_773815 != nil:
    section.add "X-Amz-Content-Sha256", valid_773815
  var valid_773816 = header.getOrDefault("X-Amz-Algorithm")
  valid_773816 = validateParameter(valid_773816, JString, required = false,
                                 default = nil)
  if valid_773816 != nil:
    section.add "X-Amz-Algorithm", valid_773816
  var valid_773817 = header.getOrDefault("X-Amz-Signature")
  valid_773817 = validateParameter(valid_773817, JString, required = false,
                                 default = nil)
  if valid_773817 != nil:
    section.add "X-Amz-Signature", valid_773817
  var valid_773818 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773818 = validateParameter(valid_773818, JString, required = false,
                                 default = nil)
  if valid_773818 != nil:
    section.add "X-Amz-SignedHeaders", valid_773818
  var valid_773819 = header.getOrDefault("X-Amz-Credential")
  valid_773819 = validateParameter(valid_773819, JString, required = false,
                                 default = nil)
  if valid_773819 != nil:
    section.add "X-Amz-Credential", valid_773819
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773821: Call_DeleteResourceServer_773809; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a resource server.
  ## 
  let valid = call_773821.validator(path, query, header, formData, body)
  let scheme = call_773821.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773821.url(scheme.get, call_773821.host, call_773821.base,
                         call_773821.route, valid.getOrDefault("path"))
  result = hook(call_773821, url, valid)

proc call*(call_773822: Call_DeleteResourceServer_773809; body: JsonNode): Recallable =
  ## deleteResourceServer
  ## Deletes a resource server.
  ##   body: JObject (required)
  var body_773823 = newJObject()
  if body != nil:
    body_773823 = body
  result = call_773822.call(nil, nil, nil, nil, body_773823)

var deleteResourceServer* = Call_DeleteResourceServer_773809(
    name: "deleteResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteResourceServer",
    validator: validate_DeleteResourceServer_773810, base: "/",
    url: url_DeleteResourceServer_773811, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_773824 = ref object of OpenApiRestCall_772597
proc url_DeleteUser_773826(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteUser_773825(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773827 = header.getOrDefault("X-Amz-Date")
  valid_773827 = validateParameter(valid_773827, JString, required = false,
                                 default = nil)
  if valid_773827 != nil:
    section.add "X-Amz-Date", valid_773827
  var valid_773828 = header.getOrDefault("X-Amz-Security-Token")
  valid_773828 = validateParameter(valid_773828, JString, required = false,
                                 default = nil)
  if valid_773828 != nil:
    section.add "X-Amz-Security-Token", valid_773828
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773829 = header.getOrDefault("X-Amz-Target")
  valid_773829 = validateParameter(valid_773829, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUser"))
  if valid_773829 != nil:
    section.add "X-Amz-Target", valid_773829
  var valid_773830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773830 = validateParameter(valid_773830, JString, required = false,
                                 default = nil)
  if valid_773830 != nil:
    section.add "X-Amz-Content-Sha256", valid_773830
  var valid_773831 = header.getOrDefault("X-Amz-Algorithm")
  valid_773831 = validateParameter(valid_773831, JString, required = false,
                                 default = nil)
  if valid_773831 != nil:
    section.add "X-Amz-Algorithm", valid_773831
  var valid_773832 = header.getOrDefault("X-Amz-Signature")
  valid_773832 = validateParameter(valid_773832, JString, required = false,
                                 default = nil)
  if valid_773832 != nil:
    section.add "X-Amz-Signature", valid_773832
  var valid_773833 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773833 = validateParameter(valid_773833, JString, required = false,
                                 default = nil)
  if valid_773833 != nil:
    section.add "X-Amz-SignedHeaders", valid_773833
  var valid_773834 = header.getOrDefault("X-Amz-Credential")
  valid_773834 = validateParameter(valid_773834, JString, required = false,
                                 default = nil)
  if valid_773834 != nil:
    section.add "X-Amz-Credential", valid_773834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773836: Call_DeleteUser_773824; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a user to delete himself or herself.
  ## 
  let valid = call_773836.validator(path, query, header, formData, body)
  let scheme = call_773836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773836.url(scheme.get, call_773836.host, call_773836.base,
                         call_773836.route, valid.getOrDefault("path"))
  result = hook(call_773836, url, valid)

proc call*(call_773837: Call_DeleteUser_773824; body: JsonNode): Recallable =
  ## deleteUser
  ## Allows a user to delete himself or herself.
  ##   body: JObject (required)
  var body_773838 = newJObject()
  if body != nil:
    body_773838 = body
  result = call_773837.call(nil, nil, nil, nil, body_773838)

var deleteUser* = Call_DeleteUser_773824(name: "deleteUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUser",
                                      validator: validate_DeleteUser_773825,
                                      base: "/", url: url_DeleteUser_773826,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserAttributes_773839 = ref object of OpenApiRestCall_772597
proc url_DeleteUserAttributes_773841(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteUserAttributes_773840(path: JsonNode; query: JsonNode;
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
  var valid_773842 = header.getOrDefault("X-Amz-Date")
  valid_773842 = validateParameter(valid_773842, JString, required = false,
                                 default = nil)
  if valid_773842 != nil:
    section.add "X-Amz-Date", valid_773842
  var valid_773843 = header.getOrDefault("X-Amz-Security-Token")
  valid_773843 = validateParameter(valid_773843, JString, required = false,
                                 default = nil)
  if valid_773843 != nil:
    section.add "X-Amz-Security-Token", valid_773843
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773844 = header.getOrDefault("X-Amz-Target")
  valid_773844 = validateParameter(valid_773844, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUserAttributes"))
  if valid_773844 != nil:
    section.add "X-Amz-Target", valid_773844
  var valid_773845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773845 = validateParameter(valid_773845, JString, required = false,
                                 default = nil)
  if valid_773845 != nil:
    section.add "X-Amz-Content-Sha256", valid_773845
  var valid_773846 = header.getOrDefault("X-Amz-Algorithm")
  valid_773846 = validateParameter(valid_773846, JString, required = false,
                                 default = nil)
  if valid_773846 != nil:
    section.add "X-Amz-Algorithm", valid_773846
  var valid_773847 = header.getOrDefault("X-Amz-Signature")
  valid_773847 = validateParameter(valid_773847, JString, required = false,
                                 default = nil)
  if valid_773847 != nil:
    section.add "X-Amz-Signature", valid_773847
  var valid_773848 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773848 = validateParameter(valid_773848, JString, required = false,
                                 default = nil)
  if valid_773848 != nil:
    section.add "X-Amz-SignedHeaders", valid_773848
  var valid_773849 = header.getOrDefault("X-Amz-Credential")
  valid_773849 = validateParameter(valid_773849, JString, required = false,
                                 default = nil)
  if valid_773849 != nil:
    section.add "X-Amz-Credential", valid_773849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773851: Call_DeleteUserAttributes_773839; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the attributes for a user.
  ## 
  let valid = call_773851.validator(path, query, header, formData, body)
  let scheme = call_773851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773851.url(scheme.get, call_773851.host, call_773851.base,
                         call_773851.route, valid.getOrDefault("path"))
  result = hook(call_773851, url, valid)

proc call*(call_773852: Call_DeleteUserAttributes_773839; body: JsonNode): Recallable =
  ## deleteUserAttributes
  ## Deletes the attributes for a user.
  ##   body: JObject (required)
  var body_773853 = newJObject()
  if body != nil:
    body_773853 = body
  result = call_773852.call(nil, nil, nil, nil, body_773853)

var deleteUserAttributes* = Call_DeleteUserAttributes_773839(
    name: "deleteUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserAttributes",
    validator: validate_DeleteUserAttributes_773840, base: "/",
    url: url_DeleteUserAttributes_773841, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserPool_773854 = ref object of OpenApiRestCall_772597
proc url_DeleteUserPool_773856(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteUserPool_773855(path: JsonNode; query: JsonNode;
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
  var valid_773857 = header.getOrDefault("X-Amz-Date")
  valid_773857 = validateParameter(valid_773857, JString, required = false,
                                 default = nil)
  if valid_773857 != nil:
    section.add "X-Amz-Date", valid_773857
  var valid_773858 = header.getOrDefault("X-Amz-Security-Token")
  valid_773858 = validateParameter(valid_773858, JString, required = false,
                                 default = nil)
  if valid_773858 != nil:
    section.add "X-Amz-Security-Token", valid_773858
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773859 = header.getOrDefault("X-Amz-Target")
  valid_773859 = validateParameter(valid_773859, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUserPool"))
  if valid_773859 != nil:
    section.add "X-Amz-Target", valid_773859
  var valid_773860 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773860 = validateParameter(valid_773860, JString, required = false,
                                 default = nil)
  if valid_773860 != nil:
    section.add "X-Amz-Content-Sha256", valid_773860
  var valid_773861 = header.getOrDefault("X-Amz-Algorithm")
  valid_773861 = validateParameter(valid_773861, JString, required = false,
                                 default = nil)
  if valid_773861 != nil:
    section.add "X-Amz-Algorithm", valid_773861
  var valid_773862 = header.getOrDefault("X-Amz-Signature")
  valid_773862 = validateParameter(valid_773862, JString, required = false,
                                 default = nil)
  if valid_773862 != nil:
    section.add "X-Amz-Signature", valid_773862
  var valid_773863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773863 = validateParameter(valid_773863, JString, required = false,
                                 default = nil)
  if valid_773863 != nil:
    section.add "X-Amz-SignedHeaders", valid_773863
  var valid_773864 = header.getOrDefault("X-Amz-Credential")
  valid_773864 = validateParameter(valid_773864, JString, required = false,
                                 default = nil)
  if valid_773864 != nil:
    section.add "X-Amz-Credential", valid_773864
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773866: Call_DeleteUserPool_773854; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Amazon Cognito user pool.
  ## 
  let valid = call_773866.validator(path, query, header, formData, body)
  let scheme = call_773866.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773866.url(scheme.get, call_773866.host, call_773866.base,
                         call_773866.route, valid.getOrDefault("path"))
  result = hook(call_773866, url, valid)

proc call*(call_773867: Call_DeleteUserPool_773854; body: JsonNode): Recallable =
  ## deleteUserPool
  ## Deletes the specified Amazon Cognito user pool.
  ##   body: JObject (required)
  var body_773868 = newJObject()
  if body != nil:
    body_773868 = body
  result = call_773867.call(nil, nil, nil, nil, body_773868)

var deleteUserPool* = Call_DeleteUserPool_773854(name: "deleteUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserPool",
    validator: validate_DeleteUserPool_773855, base: "/", url: url_DeleteUserPool_773856,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserPoolClient_773869 = ref object of OpenApiRestCall_772597
proc url_DeleteUserPoolClient_773871(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteUserPoolClient_773870(path: JsonNode; query: JsonNode;
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
  var valid_773872 = header.getOrDefault("X-Amz-Date")
  valid_773872 = validateParameter(valid_773872, JString, required = false,
                                 default = nil)
  if valid_773872 != nil:
    section.add "X-Amz-Date", valid_773872
  var valid_773873 = header.getOrDefault("X-Amz-Security-Token")
  valid_773873 = validateParameter(valid_773873, JString, required = false,
                                 default = nil)
  if valid_773873 != nil:
    section.add "X-Amz-Security-Token", valid_773873
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773874 = header.getOrDefault("X-Amz-Target")
  valid_773874 = validateParameter(valid_773874, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUserPoolClient"))
  if valid_773874 != nil:
    section.add "X-Amz-Target", valid_773874
  var valid_773875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773875 = validateParameter(valid_773875, JString, required = false,
                                 default = nil)
  if valid_773875 != nil:
    section.add "X-Amz-Content-Sha256", valid_773875
  var valid_773876 = header.getOrDefault("X-Amz-Algorithm")
  valid_773876 = validateParameter(valid_773876, JString, required = false,
                                 default = nil)
  if valid_773876 != nil:
    section.add "X-Amz-Algorithm", valid_773876
  var valid_773877 = header.getOrDefault("X-Amz-Signature")
  valid_773877 = validateParameter(valid_773877, JString, required = false,
                                 default = nil)
  if valid_773877 != nil:
    section.add "X-Amz-Signature", valid_773877
  var valid_773878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773878 = validateParameter(valid_773878, JString, required = false,
                                 default = nil)
  if valid_773878 != nil:
    section.add "X-Amz-SignedHeaders", valid_773878
  var valid_773879 = header.getOrDefault("X-Amz-Credential")
  valid_773879 = validateParameter(valid_773879, JString, required = false,
                                 default = nil)
  if valid_773879 != nil:
    section.add "X-Amz-Credential", valid_773879
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773881: Call_DeleteUserPoolClient_773869; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows the developer to delete the user pool client.
  ## 
  let valid = call_773881.validator(path, query, header, formData, body)
  let scheme = call_773881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773881.url(scheme.get, call_773881.host, call_773881.base,
                         call_773881.route, valid.getOrDefault("path"))
  result = hook(call_773881, url, valid)

proc call*(call_773882: Call_DeleteUserPoolClient_773869; body: JsonNode): Recallable =
  ## deleteUserPoolClient
  ## Allows the developer to delete the user pool client.
  ##   body: JObject (required)
  var body_773883 = newJObject()
  if body != nil:
    body_773883 = body
  result = call_773882.call(nil, nil, nil, nil, body_773883)

var deleteUserPoolClient* = Call_DeleteUserPoolClient_773869(
    name: "deleteUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserPoolClient",
    validator: validate_DeleteUserPoolClient_773870, base: "/",
    url: url_DeleteUserPoolClient_773871, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserPoolDomain_773884 = ref object of OpenApiRestCall_772597
proc url_DeleteUserPoolDomain_773886(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteUserPoolDomain_773885(path: JsonNode; query: JsonNode;
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
  var valid_773887 = header.getOrDefault("X-Amz-Date")
  valid_773887 = validateParameter(valid_773887, JString, required = false,
                                 default = nil)
  if valid_773887 != nil:
    section.add "X-Amz-Date", valid_773887
  var valid_773888 = header.getOrDefault("X-Amz-Security-Token")
  valid_773888 = validateParameter(valid_773888, JString, required = false,
                                 default = nil)
  if valid_773888 != nil:
    section.add "X-Amz-Security-Token", valid_773888
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773889 = header.getOrDefault("X-Amz-Target")
  valid_773889 = validateParameter(valid_773889, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUserPoolDomain"))
  if valid_773889 != nil:
    section.add "X-Amz-Target", valid_773889
  var valid_773890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773890 = validateParameter(valid_773890, JString, required = false,
                                 default = nil)
  if valid_773890 != nil:
    section.add "X-Amz-Content-Sha256", valid_773890
  var valid_773891 = header.getOrDefault("X-Amz-Algorithm")
  valid_773891 = validateParameter(valid_773891, JString, required = false,
                                 default = nil)
  if valid_773891 != nil:
    section.add "X-Amz-Algorithm", valid_773891
  var valid_773892 = header.getOrDefault("X-Amz-Signature")
  valid_773892 = validateParameter(valid_773892, JString, required = false,
                                 default = nil)
  if valid_773892 != nil:
    section.add "X-Amz-Signature", valid_773892
  var valid_773893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773893 = validateParameter(valid_773893, JString, required = false,
                                 default = nil)
  if valid_773893 != nil:
    section.add "X-Amz-SignedHeaders", valid_773893
  var valid_773894 = header.getOrDefault("X-Amz-Credential")
  valid_773894 = validateParameter(valid_773894, JString, required = false,
                                 default = nil)
  if valid_773894 != nil:
    section.add "X-Amz-Credential", valid_773894
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773896: Call_DeleteUserPoolDomain_773884; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a domain for a user pool.
  ## 
  let valid = call_773896.validator(path, query, header, formData, body)
  let scheme = call_773896.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773896.url(scheme.get, call_773896.host, call_773896.base,
                         call_773896.route, valid.getOrDefault("path"))
  result = hook(call_773896, url, valid)

proc call*(call_773897: Call_DeleteUserPoolDomain_773884; body: JsonNode): Recallable =
  ## deleteUserPoolDomain
  ## Deletes a domain for a user pool.
  ##   body: JObject (required)
  var body_773898 = newJObject()
  if body != nil:
    body_773898 = body
  result = call_773897.call(nil, nil, nil, nil, body_773898)

var deleteUserPoolDomain* = Call_DeleteUserPoolDomain_773884(
    name: "deleteUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserPoolDomain",
    validator: validate_DeleteUserPoolDomain_773885, base: "/",
    url: url_DeleteUserPoolDomain_773886, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentityProvider_773899 = ref object of OpenApiRestCall_772597
proc url_DescribeIdentityProvider_773901(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeIdentityProvider_773900(path: JsonNode; query: JsonNode;
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
  var valid_773902 = header.getOrDefault("X-Amz-Date")
  valid_773902 = validateParameter(valid_773902, JString, required = false,
                                 default = nil)
  if valid_773902 != nil:
    section.add "X-Amz-Date", valid_773902
  var valid_773903 = header.getOrDefault("X-Amz-Security-Token")
  valid_773903 = validateParameter(valid_773903, JString, required = false,
                                 default = nil)
  if valid_773903 != nil:
    section.add "X-Amz-Security-Token", valid_773903
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773904 = header.getOrDefault("X-Amz-Target")
  valid_773904 = validateParameter(valid_773904, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeIdentityProvider"))
  if valid_773904 != nil:
    section.add "X-Amz-Target", valid_773904
  var valid_773905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773905 = validateParameter(valid_773905, JString, required = false,
                                 default = nil)
  if valid_773905 != nil:
    section.add "X-Amz-Content-Sha256", valid_773905
  var valid_773906 = header.getOrDefault("X-Amz-Algorithm")
  valid_773906 = validateParameter(valid_773906, JString, required = false,
                                 default = nil)
  if valid_773906 != nil:
    section.add "X-Amz-Algorithm", valid_773906
  var valid_773907 = header.getOrDefault("X-Amz-Signature")
  valid_773907 = validateParameter(valid_773907, JString, required = false,
                                 default = nil)
  if valid_773907 != nil:
    section.add "X-Amz-Signature", valid_773907
  var valid_773908 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773908 = validateParameter(valid_773908, JString, required = false,
                                 default = nil)
  if valid_773908 != nil:
    section.add "X-Amz-SignedHeaders", valid_773908
  var valid_773909 = header.getOrDefault("X-Amz-Credential")
  valid_773909 = validateParameter(valid_773909, JString, required = false,
                                 default = nil)
  if valid_773909 != nil:
    section.add "X-Amz-Credential", valid_773909
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773911: Call_DescribeIdentityProvider_773899; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specific identity provider.
  ## 
  let valid = call_773911.validator(path, query, header, formData, body)
  let scheme = call_773911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773911.url(scheme.get, call_773911.host, call_773911.base,
                         call_773911.route, valid.getOrDefault("path"))
  result = hook(call_773911, url, valid)

proc call*(call_773912: Call_DescribeIdentityProvider_773899; body: JsonNode): Recallable =
  ## describeIdentityProvider
  ## Gets information about a specific identity provider.
  ##   body: JObject (required)
  var body_773913 = newJObject()
  if body != nil:
    body_773913 = body
  result = call_773912.call(nil, nil, nil, nil, body_773913)

var describeIdentityProvider* = Call_DescribeIdentityProvider_773899(
    name: "describeIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeIdentityProvider",
    validator: validate_DescribeIdentityProvider_773900, base: "/",
    url: url_DescribeIdentityProvider_773901, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResourceServer_773914 = ref object of OpenApiRestCall_772597
proc url_DescribeResourceServer_773916(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeResourceServer_773915(path: JsonNode; query: JsonNode;
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
  var valid_773917 = header.getOrDefault("X-Amz-Date")
  valid_773917 = validateParameter(valid_773917, JString, required = false,
                                 default = nil)
  if valid_773917 != nil:
    section.add "X-Amz-Date", valid_773917
  var valid_773918 = header.getOrDefault("X-Amz-Security-Token")
  valid_773918 = validateParameter(valid_773918, JString, required = false,
                                 default = nil)
  if valid_773918 != nil:
    section.add "X-Amz-Security-Token", valid_773918
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773919 = header.getOrDefault("X-Amz-Target")
  valid_773919 = validateParameter(valid_773919, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeResourceServer"))
  if valid_773919 != nil:
    section.add "X-Amz-Target", valid_773919
  var valid_773920 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773920 = validateParameter(valid_773920, JString, required = false,
                                 default = nil)
  if valid_773920 != nil:
    section.add "X-Amz-Content-Sha256", valid_773920
  var valid_773921 = header.getOrDefault("X-Amz-Algorithm")
  valid_773921 = validateParameter(valid_773921, JString, required = false,
                                 default = nil)
  if valid_773921 != nil:
    section.add "X-Amz-Algorithm", valid_773921
  var valid_773922 = header.getOrDefault("X-Amz-Signature")
  valid_773922 = validateParameter(valid_773922, JString, required = false,
                                 default = nil)
  if valid_773922 != nil:
    section.add "X-Amz-Signature", valid_773922
  var valid_773923 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773923 = validateParameter(valid_773923, JString, required = false,
                                 default = nil)
  if valid_773923 != nil:
    section.add "X-Amz-SignedHeaders", valid_773923
  var valid_773924 = header.getOrDefault("X-Amz-Credential")
  valid_773924 = validateParameter(valid_773924, JString, required = false,
                                 default = nil)
  if valid_773924 != nil:
    section.add "X-Amz-Credential", valid_773924
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773926: Call_DescribeResourceServer_773914; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a resource server.
  ## 
  let valid = call_773926.validator(path, query, header, formData, body)
  let scheme = call_773926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773926.url(scheme.get, call_773926.host, call_773926.base,
                         call_773926.route, valid.getOrDefault("path"))
  result = hook(call_773926, url, valid)

proc call*(call_773927: Call_DescribeResourceServer_773914; body: JsonNode): Recallable =
  ## describeResourceServer
  ## Describes a resource server.
  ##   body: JObject (required)
  var body_773928 = newJObject()
  if body != nil:
    body_773928 = body
  result = call_773927.call(nil, nil, nil, nil, body_773928)

var describeResourceServer* = Call_DescribeResourceServer_773914(
    name: "describeResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeResourceServer",
    validator: validate_DescribeResourceServer_773915, base: "/",
    url: url_DescribeResourceServer_773916, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRiskConfiguration_773929 = ref object of OpenApiRestCall_772597
proc url_DescribeRiskConfiguration_773931(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeRiskConfiguration_773930(path: JsonNode; query: JsonNode;
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
  var valid_773932 = header.getOrDefault("X-Amz-Date")
  valid_773932 = validateParameter(valid_773932, JString, required = false,
                                 default = nil)
  if valid_773932 != nil:
    section.add "X-Amz-Date", valid_773932
  var valid_773933 = header.getOrDefault("X-Amz-Security-Token")
  valid_773933 = validateParameter(valid_773933, JString, required = false,
                                 default = nil)
  if valid_773933 != nil:
    section.add "X-Amz-Security-Token", valid_773933
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773934 = header.getOrDefault("X-Amz-Target")
  valid_773934 = validateParameter(valid_773934, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeRiskConfiguration"))
  if valid_773934 != nil:
    section.add "X-Amz-Target", valid_773934
  var valid_773935 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773935 = validateParameter(valid_773935, JString, required = false,
                                 default = nil)
  if valid_773935 != nil:
    section.add "X-Amz-Content-Sha256", valid_773935
  var valid_773936 = header.getOrDefault("X-Amz-Algorithm")
  valid_773936 = validateParameter(valid_773936, JString, required = false,
                                 default = nil)
  if valid_773936 != nil:
    section.add "X-Amz-Algorithm", valid_773936
  var valid_773937 = header.getOrDefault("X-Amz-Signature")
  valid_773937 = validateParameter(valid_773937, JString, required = false,
                                 default = nil)
  if valid_773937 != nil:
    section.add "X-Amz-Signature", valid_773937
  var valid_773938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773938 = validateParameter(valid_773938, JString, required = false,
                                 default = nil)
  if valid_773938 != nil:
    section.add "X-Amz-SignedHeaders", valid_773938
  var valid_773939 = header.getOrDefault("X-Amz-Credential")
  valid_773939 = validateParameter(valid_773939, JString, required = false,
                                 default = nil)
  if valid_773939 != nil:
    section.add "X-Amz-Credential", valid_773939
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773941: Call_DescribeRiskConfiguration_773929; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the risk configuration.
  ## 
  let valid = call_773941.validator(path, query, header, formData, body)
  let scheme = call_773941.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773941.url(scheme.get, call_773941.host, call_773941.base,
                         call_773941.route, valid.getOrDefault("path"))
  result = hook(call_773941, url, valid)

proc call*(call_773942: Call_DescribeRiskConfiguration_773929; body: JsonNode): Recallable =
  ## describeRiskConfiguration
  ## Describes the risk configuration.
  ##   body: JObject (required)
  var body_773943 = newJObject()
  if body != nil:
    body_773943 = body
  result = call_773942.call(nil, nil, nil, nil, body_773943)

var describeRiskConfiguration* = Call_DescribeRiskConfiguration_773929(
    name: "describeRiskConfiguration", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeRiskConfiguration",
    validator: validate_DescribeRiskConfiguration_773930, base: "/",
    url: url_DescribeRiskConfiguration_773931,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserImportJob_773944 = ref object of OpenApiRestCall_772597
proc url_DescribeUserImportJob_773946(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeUserImportJob_773945(path: JsonNode; query: JsonNode;
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
  var valid_773947 = header.getOrDefault("X-Amz-Date")
  valid_773947 = validateParameter(valid_773947, JString, required = false,
                                 default = nil)
  if valid_773947 != nil:
    section.add "X-Amz-Date", valid_773947
  var valid_773948 = header.getOrDefault("X-Amz-Security-Token")
  valid_773948 = validateParameter(valid_773948, JString, required = false,
                                 default = nil)
  if valid_773948 != nil:
    section.add "X-Amz-Security-Token", valid_773948
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773949 = header.getOrDefault("X-Amz-Target")
  valid_773949 = validateParameter(valid_773949, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserImportJob"))
  if valid_773949 != nil:
    section.add "X-Amz-Target", valid_773949
  var valid_773950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773950 = validateParameter(valid_773950, JString, required = false,
                                 default = nil)
  if valid_773950 != nil:
    section.add "X-Amz-Content-Sha256", valid_773950
  var valid_773951 = header.getOrDefault("X-Amz-Algorithm")
  valid_773951 = validateParameter(valid_773951, JString, required = false,
                                 default = nil)
  if valid_773951 != nil:
    section.add "X-Amz-Algorithm", valid_773951
  var valid_773952 = header.getOrDefault("X-Amz-Signature")
  valid_773952 = validateParameter(valid_773952, JString, required = false,
                                 default = nil)
  if valid_773952 != nil:
    section.add "X-Amz-Signature", valid_773952
  var valid_773953 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773953 = validateParameter(valid_773953, JString, required = false,
                                 default = nil)
  if valid_773953 != nil:
    section.add "X-Amz-SignedHeaders", valid_773953
  var valid_773954 = header.getOrDefault("X-Amz-Credential")
  valid_773954 = validateParameter(valid_773954, JString, required = false,
                                 default = nil)
  if valid_773954 != nil:
    section.add "X-Amz-Credential", valid_773954
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773956: Call_DescribeUserImportJob_773944; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the user import job.
  ## 
  let valid = call_773956.validator(path, query, header, formData, body)
  let scheme = call_773956.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773956.url(scheme.get, call_773956.host, call_773956.base,
                         call_773956.route, valid.getOrDefault("path"))
  result = hook(call_773956, url, valid)

proc call*(call_773957: Call_DescribeUserImportJob_773944; body: JsonNode): Recallable =
  ## describeUserImportJob
  ## Describes the user import job.
  ##   body: JObject (required)
  var body_773958 = newJObject()
  if body != nil:
    body_773958 = body
  result = call_773957.call(nil, nil, nil, nil, body_773958)

var describeUserImportJob* = Call_DescribeUserImportJob_773944(
    name: "describeUserImportJob", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserImportJob",
    validator: validate_DescribeUserImportJob_773945, base: "/",
    url: url_DescribeUserImportJob_773946, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserPool_773959 = ref object of OpenApiRestCall_772597
proc url_DescribeUserPool_773961(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeUserPool_773960(path: JsonNode; query: JsonNode;
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
  var valid_773962 = header.getOrDefault("X-Amz-Date")
  valid_773962 = validateParameter(valid_773962, JString, required = false,
                                 default = nil)
  if valid_773962 != nil:
    section.add "X-Amz-Date", valid_773962
  var valid_773963 = header.getOrDefault("X-Amz-Security-Token")
  valid_773963 = validateParameter(valid_773963, JString, required = false,
                                 default = nil)
  if valid_773963 != nil:
    section.add "X-Amz-Security-Token", valid_773963
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773964 = header.getOrDefault("X-Amz-Target")
  valid_773964 = validateParameter(valid_773964, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserPool"))
  if valid_773964 != nil:
    section.add "X-Amz-Target", valid_773964
  var valid_773965 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773965 = validateParameter(valid_773965, JString, required = false,
                                 default = nil)
  if valid_773965 != nil:
    section.add "X-Amz-Content-Sha256", valid_773965
  var valid_773966 = header.getOrDefault("X-Amz-Algorithm")
  valid_773966 = validateParameter(valid_773966, JString, required = false,
                                 default = nil)
  if valid_773966 != nil:
    section.add "X-Amz-Algorithm", valid_773966
  var valid_773967 = header.getOrDefault("X-Amz-Signature")
  valid_773967 = validateParameter(valid_773967, JString, required = false,
                                 default = nil)
  if valid_773967 != nil:
    section.add "X-Amz-Signature", valid_773967
  var valid_773968 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773968 = validateParameter(valid_773968, JString, required = false,
                                 default = nil)
  if valid_773968 != nil:
    section.add "X-Amz-SignedHeaders", valid_773968
  var valid_773969 = header.getOrDefault("X-Amz-Credential")
  valid_773969 = validateParameter(valid_773969, JString, required = false,
                                 default = nil)
  if valid_773969 != nil:
    section.add "X-Amz-Credential", valid_773969
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773971: Call_DescribeUserPool_773959; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the configuration information and metadata of the specified user pool.
  ## 
  let valid = call_773971.validator(path, query, header, formData, body)
  let scheme = call_773971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773971.url(scheme.get, call_773971.host, call_773971.base,
                         call_773971.route, valid.getOrDefault("path"))
  result = hook(call_773971, url, valid)

proc call*(call_773972: Call_DescribeUserPool_773959; body: JsonNode): Recallable =
  ## describeUserPool
  ## Returns the configuration information and metadata of the specified user pool.
  ##   body: JObject (required)
  var body_773973 = newJObject()
  if body != nil:
    body_773973 = body
  result = call_773972.call(nil, nil, nil, nil, body_773973)

var describeUserPool* = Call_DescribeUserPool_773959(name: "describeUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserPool",
    validator: validate_DescribeUserPool_773960, base: "/",
    url: url_DescribeUserPool_773961, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserPoolClient_773974 = ref object of OpenApiRestCall_772597
proc url_DescribeUserPoolClient_773976(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeUserPoolClient_773975(path: JsonNode; query: JsonNode;
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
  var valid_773977 = header.getOrDefault("X-Amz-Date")
  valid_773977 = validateParameter(valid_773977, JString, required = false,
                                 default = nil)
  if valid_773977 != nil:
    section.add "X-Amz-Date", valid_773977
  var valid_773978 = header.getOrDefault("X-Amz-Security-Token")
  valid_773978 = validateParameter(valid_773978, JString, required = false,
                                 default = nil)
  if valid_773978 != nil:
    section.add "X-Amz-Security-Token", valid_773978
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773979 = header.getOrDefault("X-Amz-Target")
  valid_773979 = validateParameter(valid_773979, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserPoolClient"))
  if valid_773979 != nil:
    section.add "X-Amz-Target", valid_773979
  var valid_773980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773980 = validateParameter(valid_773980, JString, required = false,
                                 default = nil)
  if valid_773980 != nil:
    section.add "X-Amz-Content-Sha256", valid_773980
  var valid_773981 = header.getOrDefault("X-Amz-Algorithm")
  valid_773981 = validateParameter(valid_773981, JString, required = false,
                                 default = nil)
  if valid_773981 != nil:
    section.add "X-Amz-Algorithm", valid_773981
  var valid_773982 = header.getOrDefault("X-Amz-Signature")
  valid_773982 = validateParameter(valid_773982, JString, required = false,
                                 default = nil)
  if valid_773982 != nil:
    section.add "X-Amz-Signature", valid_773982
  var valid_773983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773983 = validateParameter(valid_773983, JString, required = false,
                                 default = nil)
  if valid_773983 != nil:
    section.add "X-Amz-SignedHeaders", valid_773983
  var valid_773984 = header.getOrDefault("X-Amz-Credential")
  valid_773984 = validateParameter(valid_773984, JString, required = false,
                                 default = nil)
  if valid_773984 != nil:
    section.add "X-Amz-Credential", valid_773984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773986: Call_DescribeUserPoolClient_773974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Client method for returning the configuration information and metadata of the specified user pool app client.
  ## 
  let valid = call_773986.validator(path, query, header, formData, body)
  let scheme = call_773986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773986.url(scheme.get, call_773986.host, call_773986.base,
                         call_773986.route, valid.getOrDefault("path"))
  result = hook(call_773986, url, valid)

proc call*(call_773987: Call_DescribeUserPoolClient_773974; body: JsonNode): Recallable =
  ## describeUserPoolClient
  ## Client method for returning the configuration information and metadata of the specified user pool app client.
  ##   body: JObject (required)
  var body_773988 = newJObject()
  if body != nil:
    body_773988 = body
  result = call_773987.call(nil, nil, nil, nil, body_773988)

var describeUserPoolClient* = Call_DescribeUserPoolClient_773974(
    name: "describeUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserPoolClient",
    validator: validate_DescribeUserPoolClient_773975, base: "/",
    url: url_DescribeUserPoolClient_773976, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserPoolDomain_773989 = ref object of OpenApiRestCall_772597
proc url_DescribeUserPoolDomain_773991(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeUserPoolDomain_773990(path: JsonNode; query: JsonNode;
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
  var valid_773992 = header.getOrDefault("X-Amz-Date")
  valid_773992 = validateParameter(valid_773992, JString, required = false,
                                 default = nil)
  if valid_773992 != nil:
    section.add "X-Amz-Date", valid_773992
  var valid_773993 = header.getOrDefault("X-Amz-Security-Token")
  valid_773993 = validateParameter(valid_773993, JString, required = false,
                                 default = nil)
  if valid_773993 != nil:
    section.add "X-Amz-Security-Token", valid_773993
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773994 = header.getOrDefault("X-Amz-Target")
  valid_773994 = validateParameter(valid_773994, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserPoolDomain"))
  if valid_773994 != nil:
    section.add "X-Amz-Target", valid_773994
  var valid_773995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773995 = validateParameter(valid_773995, JString, required = false,
                                 default = nil)
  if valid_773995 != nil:
    section.add "X-Amz-Content-Sha256", valid_773995
  var valid_773996 = header.getOrDefault("X-Amz-Algorithm")
  valid_773996 = validateParameter(valid_773996, JString, required = false,
                                 default = nil)
  if valid_773996 != nil:
    section.add "X-Amz-Algorithm", valid_773996
  var valid_773997 = header.getOrDefault("X-Amz-Signature")
  valid_773997 = validateParameter(valid_773997, JString, required = false,
                                 default = nil)
  if valid_773997 != nil:
    section.add "X-Amz-Signature", valid_773997
  var valid_773998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773998 = validateParameter(valid_773998, JString, required = false,
                                 default = nil)
  if valid_773998 != nil:
    section.add "X-Amz-SignedHeaders", valid_773998
  var valid_773999 = header.getOrDefault("X-Amz-Credential")
  valid_773999 = validateParameter(valid_773999, JString, required = false,
                                 default = nil)
  if valid_773999 != nil:
    section.add "X-Amz-Credential", valid_773999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774001: Call_DescribeUserPoolDomain_773989; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a domain.
  ## 
  let valid = call_774001.validator(path, query, header, formData, body)
  let scheme = call_774001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774001.url(scheme.get, call_774001.host, call_774001.base,
                         call_774001.route, valid.getOrDefault("path"))
  result = hook(call_774001, url, valid)

proc call*(call_774002: Call_DescribeUserPoolDomain_773989; body: JsonNode): Recallable =
  ## describeUserPoolDomain
  ## Gets information about a domain.
  ##   body: JObject (required)
  var body_774003 = newJObject()
  if body != nil:
    body_774003 = body
  result = call_774002.call(nil, nil, nil, nil, body_774003)

var describeUserPoolDomain* = Call_DescribeUserPoolDomain_773989(
    name: "describeUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserPoolDomain",
    validator: validate_DescribeUserPoolDomain_773990, base: "/",
    url: url_DescribeUserPoolDomain_773991, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ForgetDevice_774004 = ref object of OpenApiRestCall_772597
proc url_ForgetDevice_774006(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ForgetDevice_774005(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774007 = header.getOrDefault("X-Amz-Date")
  valid_774007 = validateParameter(valid_774007, JString, required = false,
                                 default = nil)
  if valid_774007 != nil:
    section.add "X-Amz-Date", valid_774007
  var valid_774008 = header.getOrDefault("X-Amz-Security-Token")
  valid_774008 = validateParameter(valid_774008, JString, required = false,
                                 default = nil)
  if valid_774008 != nil:
    section.add "X-Amz-Security-Token", valid_774008
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774009 = header.getOrDefault("X-Amz-Target")
  valid_774009 = validateParameter(valid_774009, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ForgetDevice"))
  if valid_774009 != nil:
    section.add "X-Amz-Target", valid_774009
  var valid_774010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774010 = validateParameter(valid_774010, JString, required = false,
                                 default = nil)
  if valid_774010 != nil:
    section.add "X-Amz-Content-Sha256", valid_774010
  var valid_774011 = header.getOrDefault("X-Amz-Algorithm")
  valid_774011 = validateParameter(valid_774011, JString, required = false,
                                 default = nil)
  if valid_774011 != nil:
    section.add "X-Amz-Algorithm", valid_774011
  var valid_774012 = header.getOrDefault("X-Amz-Signature")
  valid_774012 = validateParameter(valid_774012, JString, required = false,
                                 default = nil)
  if valid_774012 != nil:
    section.add "X-Amz-Signature", valid_774012
  var valid_774013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774013 = validateParameter(valid_774013, JString, required = false,
                                 default = nil)
  if valid_774013 != nil:
    section.add "X-Amz-SignedHeaders", valid_774013
  var valid_774014 = header.getOrDefault("X-Amz-Credential")
  valid_774014 = validateParameter(valid_774014, JString, required = false,
                                 default = nil)
  if valid_774014 != nil:
    section.add "X-Amz-Credential", valid_774014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774016: Call_ForgetDevice_774004; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Forgets the specified device.
  ## 
  let valid = call_774016.validator(path, query, header, formData, body)
  let scheme = call_774016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774016.url(scheme.get, call_774016.host, call_774016.base,
                         call_774016.route, valid.getOrDefault("path"))
  result = hook(call_774016, url, valid)

proc call*(call_774017: Call_ForgetDevice_774004; body: JsonNode): Recallable =
  ## forgetDevice
  ## Forgets the specified device.
  ##   body: JObject (required)
  var body_774018 = newJObject()
  if body != nil:
    body_774018 = body
  result = call_774017.call(nil, nil, nil, nil, body_774018)

var forgetDevice* = Call_ForgetDevice_774004(name: "forgetDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ForgetDevice",
    validator: validate_ForgetDevice_774005, base: "/", url: url_ForgetDevice_774006,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ForgotPassword_774019 = ref object of OpenApiRestCall_772597
proc url_ForgotPassword_774021(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ForgotPassword_774020(path: JsonNode; query: JsonNode;
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
  var valid_774022 = header.getOrDefault("X-Amz-Date")
  valid_774022 = validateParameter(valid_774022, JString, required = false,
                                 default = nil)
  if valid_774022 != nil:
    section.add "X-Amz-Date", valid_774022
  var valid_774023 = header.getOrDefault("X-Amz-Security-Token")
  valid_774023 = validateParameter(valid_774023, JString, required = false,
                                 default = nil)
  if valid_774023 != nil:
    section.add "X-Amz-Security-Token", valid_774023
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774024 = header.getOrDefault("X-Amz-Target")
  valid_774024 = validateParameter(valid_774024, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ForgotPassword"))
  if valid_774024 != nil:
    section.add "X-Amz-Target", valid_774024
  var valid_774025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774025 = validateParameter(valid_774025, JString, required = false,
                                 default = nil)
  if valid_774025 != nil:
    section.add "X-Amz-Content-Sha256", valid_774025
  var valid_774026 = header.getOrDefault("X-Amz-Algorithm")
  valid_774026 = validateParameter(valid_774026, JString, required = false,
                                 default = nil)
  if valid_774026 != nil:
    section.add "X-Amz-Algorithm", valid_774026
  var valid_774027 = header.getOrDefault("X-Amz-Signature")
  valid_774027 = validateParameter(valid_774027, JString, required = false,
                                 default = nil)
  if valid_774027 != nil:
    section.add "X-Amz-Signature", valid_774027
  var valid_774028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774028 = validateParameter(valid_774028, JString, required = false,
                                 default = nil)
  if valid_774028 != nil:
    section.add "X-Amz-SignedHeaders", valid_774028
  var valid_774029 = header.getOrDefault("X-Amz-Credential")
  valid_774029 = validateParameter(valid_774029, JString, required = false,
                                 default = nil)
  if valid_774029 != nil:
    section.add "X-Amz-Credential", valid_774029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774031: Call_ForgotPassword_774019; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Calling this API causes a message to be sent to the end user with a confirmation code that is required to change the user's password. For the <code>Username</code> parameter, you can use the username or user alias. If a verified phone number exists for the user, the confirmation code is sent to the phone number. Otherwise, if a verified email exists, the confirmation code is sent to the email. If neither a verified phone number nor a verified email exists, <code>InvalidParameterException</code> is thrown. To use the confirmation code for resetting the password, call .
  ## 
  let valid = call_774031.validator(path, query, header, formData, body)
  let scheme = call_774031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774031.url(scheme.get, call_774031.host, call_774031.base,
                         call_774031.route, valid.getOrDefault("path"))
  result = hook(call_774031, url, valid)

proc call*(call_774032: Call_ForgotPassword_774019; body: JsonNode): Recallable =
  ## forgotPassword
  ## Calling this API causes a message to be sent to the end user with a confirmation code that is required to change the user's password. For the <code>Username</code> parameter, you can use the username or user alias. If a verified phone number exists for the user, the confirmation code is sent to the phone number. Otherwise, if a verified email exists, the confirmation code is sent to the email. If neither a verified phone number nor a verified email exists, <code>InvalidParameterException</code> is thrown. To use the confirmation code for resetting the password, call .
  ##   body: JObject (required)
  var body_774033 = newJObject()
  if body != nil:
    body_774033 = body
  result = call_774032.call(nil, nil, nil, nil, body_774033)

var forgotPassword* = Call_ForgotPassword_774019(name: "forgotPassword",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ForgotPassword",
    validator: validate_ForgotPassword_774020, base: "/", url: url_ForgotPassword_774021,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCSVHeader_774034 = ref object of OpenApiRestCall_772597
proc url_GetCSVHeader_774036(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCSVHeader_774035(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774037 = header.getOrDefault("X-Amz-Date")
  valid_774037 = validateParameter(valid_774037, JString, required = false,
                                 default = nil)
  if valid_774037 != nil:
    section.add "X-Amz-Date", valid_774037
  var valid_774038 = header.getOrDefault("X-Amz-Security-Token")
  valid_774038 = validateParameter(valid_774038, JString, required = false,
                                 default = nil)
  if valid_774038 != nil:
    section.add "X-Amz-Security-Token", valid_774038
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774039 = header.getOrDefault("X-Amz-Target")
  valid_774039 = validateParameter(valid_774039, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetCSVHeader"))
  if valid_774039 != nil:
    section.add "X-Amz-Target", valid_774039
  var valid_774040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774040 = validateParameter(valid_774040, JString, required = false,
                                 default = nil)
  if valid_774040 != nil:
    section.add "X-Amz-Content-Sha256", valid_774040
  var valid_774041 = header.getOrDefault("X-Amz-Algorithm")
  valid_774041 = validateParameter(valid_774041, JString, required = false,
                                 default = nil)
  if valid_774041 != nil:
    section.add "X-Amz-Algorithm", valid_774041
  var valid_774042 = header.getOrDefault("X-Amz-Signature")
  valid_774042 = validateParameter(valid_774042, JString, required = false,
                                 default = nil)
  if valid_774042 != nil:
    section.add "X-Amz-Signature", valid_774042
  var valid_774043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774043 = validateParameter(valid_774043, JString, required = false,
                                 default = nil)
  if valid_774043 != nil:
    section.add "X-Amz-SignedHeaders", valid_774043
  var valid_774044 = header.getOrDefault("X-Amz-Credential")
  valid_774044 = validateParameter(valid_774044, JString, required = false,
                                 default = nil)
  if valid_774044 != nil:
    section.add "X-Amz-Credential", valid_774044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774046: Call_GetCSVHeader_774034; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the header information for the .csv file to be used as input for the user import job.
  ## 
  let valid = call_774046.validator(path, query, header, formData, body)
  let scheme = call_774046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774046.url(scheme.get, call_774046.host, call_774046.base,
                         call_774046.route, valid.getOrDefault("path"))
  result = hook(call_774046, url, valid)

proc call*(call_774047: Call_GetCSVHeader_774034; body: JsonNode): Recallable =
  ## getCSVHeader
  ## Gets the header information for the .csv file to be used as input for the user import job.
  ##   body: JObject (required)
  var body_774048 = newJObject()
  if body != nil:
    body_774048 = body
  result = call_774047.call(nil, nil, nil, nil, body_774048)

var getCSVHeader* = Call_GetCSVHeader_774034(name: "getCSVHeader",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetCSVHeader",
    validator: validate_GetCSVHeader_774035, base: "/", url: url_GetCSVHeader_774036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevice_774049 = ref object of OpenApiRestCall_772597
proc url_GetDevice_774051(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDevice_774050(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774052 = header.getOrDefault("X-Amz-Date")
  valid_774052 = validateParameter(valid_774052, JString, required = false,
                                 default = nil)
  if valid_774052 != nil:
    section.add "X-Amz-Date", valid_774052
  var valid_774053 = header.getOrDefault("X-Amz-Security-Token")
  valid_774053 = validateParameter(valid_774053, JString, required = false,
                                 default = nil)
  if valid_774053 != nil:
    section.add "X-Amz-Security-Token", valid_774053
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774054 = header.getOrDefault("X-Amz-Target")
  valid_774054 = validateParameter(valid_774054, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetDevice"))
  if valid_774054 != nil:
    section.add "X-Amz-Target", valid_774054
  var valid_774055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774055 = validateParameter(valid_774055, JString, required = false,
                                 default = nil)
  if valid_774055 != nil:
    section.add "X-Amz-Content-Sha256", valid_774055
  var valid_774056 = header.getOrDefault("X-Amz-Algorithm")
  valid_774056 = validateParameter(valid_774056, JString, required = false,
                                 default = nil)
  if valid_774056 != nil:
    section.add "X-Amz-Algorithm", valid_774056
  var valid_774057 = header.getOrDefault("X-Amz-Signature")
  valid_774057 = validateParameter(valid_774057, JString, required = false,
                                 default = nil)
  if valid_774057 != nil:
    section.add "X-Amz-Signature", valid_774057
  var valid_774058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774058 = validateParameter(valid_774058, JString, required = false,
                                 default = nil)
  if valid_774058 != nil:
    section.add "X-Amz-SignedHeaders", valid_774058
  var valid_774059 = header.getOrDefault("X-Amz-Credential")
  valid_774059 = validateParameter(valid_774059, JString, required = false,
                                 default = nil)
  if valid_774059 != nil:
    section.add "X-Amz-Credential", valid_774059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774061: Call_GetDevice_774049; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the device.
  ## 
  let valid = call_774061.validator(path, query, header, formData, body)
  let scheme = call_774061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774061.url(scheme.get, call_774061.host, call_774061.base,
                         call_774061.route, valid.getOrDefault("path"))
  result = hook(call_774061, url, valid)

proc call*(call_774062: Call_GetDevice_774049; body: JsonNode): Recallable =
  ## getDevice
  ## Gets the device.
  ##   body: JObject (required)
  var body_774063 = newJObject()
  if body != nil:
    body_774063 = body
  result = call_774062.call(nil, nil, nil, nil, body_774063)

var getDevice* = Call_GetDevice_774049(name: "getDevice", meth: HttpMethod.HttpPost,
                                    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetDevice",
                                    validator: validate_GetDevice_774050,
                                    base: "/", url: url_GetDevice_774051,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroup_774064 = ref object of OpenApiRestCall_772597
proc url_GetGroup_774066(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGroup_774065(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets a group.</p> <p>Requires developer credentials.</p>
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
  var valid_774067 = header.getOrDefault("X-Amz-Date")
  valid_774067 = validateParameter(valid_774067, JString, required = false,
                                 default = nil)
  if valid_774067 != nil:
    section.add "X-Amz-Date", valid_774067
  var valid_774068 = header.getOrDefault("X-Amz-Security-Token")
  valid_774068 = validateParameter(valid_774068, JString, required = false,
                                 default = nil)
  if valid_774068 != nil:
    section.add "X-Amz-Security-Token", valid_774068
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774069 = header.getOrDefault("X-Amz-Target")
  valid_774069 = validateParameter(valid_774069, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetGroup"))
  if valid_774069 != nil:
    section.add "X-Amz-Target", valid_774069
  var valid_774070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774070 = validateParameter(valid_774070, JString, required = false,
                                 default = nil)
  if valid_774070 != nil:
    section.add "X-Amz-Content-Sha256", valid_774070
  var valid_774071 = header.getOrDefault("X-Amz-Algorithm")
  valid_774071 = validateParameter(valid_774071, JString, required = false,
                                 default = nil)
  if valid_774071 != nil:
    section.add "X-Amz-Algorithm", valid_774071
  var valid_774072 = header.getOrDefault("X-Amz-Signature")
  valid_774072 = validateParameter(valid_774072, JString, required = false,
                                 default = nil)
  if valid_774072 != nil:
    section.add "X-Amz-Signature", valid_774072
  var valid_774073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774073 = validateParameter(valid_774073, JString, required = false,
                                 default = nil)
  if valid_774073 != nil:
    section.add "X-Amz-SignedHeaders", valid_774073
  var valid_774074 = header.getOrDefault("X-Amz-Credential")
  valid_774074 = validateParameter(valid_774074, JString, required = false,
                                 default = nil)
  if valid_774074 != nil:
    section.add "X-Amz-Credential", valid_774074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774076: Call_GetGroup_774064; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a group.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_774076.validator(path, query, header, formData, body)
  let scheme = call_774076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774076.url(scheme.get, call_774076.host, call_774076.base,
                         call_774076.route, valid.getOrDefault("path"))
  result = hook(call_774076, url, valid)

proc call*(call_774077: Call_GetGroup_774064; body: JsonNode): Recallable =
  ## getGroup
  ## <p>Gets a group.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_774078 = newJObject()
  if body != nil:
    body_774078 = body
  result = call_774077.call(nil, nil, nil, nil, body_774078)

var getGroup* = Call_GetGroup_774064(name: "getGroup", meth: HttpMethod.HttpPost,
                                  host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetGroup",
                                  validator: validate_GetGroup_774065, base: "/",
                                  url: url_GetGroup_774066,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIdentityProviderByIdentifier_774079 = ref object of OpenApiRestCall_772597
proc url_GetIdentityProviderByIdentifier_774081(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetIdentityProviderByIdentifier_774080(path: JsonNode;
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
  var valid_774082 = header.getOrDefault("X-Amz-Date")
  valid_774082 = validateParameter(valid_774082, JString, required = false,
                                 default = nil)
  if valid_774082 != nil:
    section.add "X-Amz-Date", valid_774082
  var valid_774083 = header.getOrDefault("X-Amz-Security-Token")
  valid_774083 = validateParameter(valid_774083, JString, required = false,
                                 default = nil)
  if valid_774083 != nil:
    section.add "X-Amz-Security-Token", valid_774083
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774084 = header.getOrDefault("X-Amz-Target")
  valid_774084 = validateParameter(valid_774084, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetIdentityProviderByIdentifier"))
  if valid_774084 != nil:
    section.add "X-Amz-Target", valid_774084
  var valid_774085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774085 = validateParameter(valid_774085, JString, required = false,
                                 default = nil)
  if valid_774085 != nil:
    section.add "X-Amz-Content-Sha256", valid_774085
  var valid_774086 = header.getOrDefault("X-Amz-Algorithm")
  valid_774086 = validateParameter(valid_774086, JString, required = false,
                                 default = nil)
  if valid_774086 != nil:
    section.add "X-Amz-Algorithm", valid_774086
  var valid_774087 = header.getOrDefault("X-Amz-Signature")
  valid_774087 = validateParameter(valid_774087, JString, required = false,
                                 default = nil)
  if valid_774087 != nil:
    section.add "X-Amz-Signature", valid_774087
  var valid_774088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774088 = validateParameter(valid_774088, JString, required = false,
                                 default = nil)
  if valid_774088 != nil:
    section.add "X-Amz-SignedHeaders", valid_774088
  var valid_774089 = header.getOrDefault("X-Amz-Credential")
  valid_774089 = validateParameter(valid_774089, JString, required = false,
                                 default = nil)
  if valid_774089 != nil:
    section.add "X-Amz-Credential", valid_774089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774091: Call_GetIdentityProviderByIdentifier_774079;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the specified identity provider.
  ## 
  let valid = call_774091.validator(path, query, header, formData, body)
  let scheme = call_774091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774091.url(scheme.get, call_774091.host, call_774091.base,
                         call_774091.route, valid.getOrDefault("path"))
  result = hook(call_774091, url, valid)

proc call*(call_774092: Call_GetIdentityProviderByIdentifier_774079; body: JsonNode): Recallable =
  ## getIdentityProviderByIdentifier
  ## Gets the specified identity provider.
  ##   body: JObject (required)
  var body_774093 = newJObject()
  if body != nil:
    body_774093 = body
  result = call_774092.call(nil, nil, nil, nil, body_774093)

var getIdentityProviderByIdentifier* = Call_GetIdentityProviderByIdentifier_774079(
    name: "getIdentityProviderByIdentifier", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetIdentityProviderByIdentifier",
    validator: validate_GetIdentityProviderByIdentifier_774080, base: "/",
    url: url_GetIdentityProviderByIdentifier_774081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSigningCertificate_774094 = ref object of OpenApiRestCall_772597
proc url_GetSigningCertificate_774096(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSigningCertificate_774095(path: JsonNode; query: JsonNode;
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
  var valid_774097 = header.getOrDefault("X-Amz-Date")
  valid_774097 = validateParameter(valid_774097, JString, required = false,
                                 default = nil)
  if valid_774097 != nil:
    section.add "X-Amz-Date", valid_774097
  var valid_774098 = header.getOrDefault("X-Amz-Security-Token")
  valid_774098 = validateParameter(valid_774098, JString, required = false,
                                 default = nil)
  if valid_774098 != nil:
    section.add "X-Amz-Security-Token", valid_774098
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774099 = header.getOrDefault("X-Amz-Target")
  valid_774099 = validateParameter(valid_774099, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetSigningCertificate"))
  if valid_774099 != nil:
    section.add "X-Amz-Target", valid_774099
  var valid_774100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774100 = validateParameter(valid_774100, JString, required = false,
                                 default = nil)
  if valid_774100 != nil:
    section.add "X-Amz-Content-Sha256", valid_774100
  var valid_774101 = header.getOrDefault("X-Amz-Algorithm")
  valid_774101 = validateParameter(valid_774101, JString, required = false,
                                 default = nil)
  if valid_774101 != nil:
    section.add "X-Amz-Algorithm", valid_774101
  var valid_774102 = header.getOrDefault("X-Amz-Signature")
  valid_774102 = validateParameter(valid_774102, JString, required = false,
                                 default = nil)
  if valid_774102 != nil:
    section.add "X-Amz-Signature", valid_774102
  var valid_774103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774103 = validateParameter(valid_774103, JString, required = false,
                                 default = nil)
  if valid_774103 != nil:
    section.add "X-Amz-SignedHeaders", valid_774103
  var valid_774104 = header.getOrDefault("X-Amz-Credential")
  valid_774104 = validateParameter(valid_774104, JString, required = false,
                                 default = nil)
  if valid_774104 != nil:
    section.add "X-Amz-Credential", valid_774104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774106: Call_GetSigningCertificate_774094; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This method takes a user pool ID, and returns the signing certificate.
  ## 
  let valid = call_774106.validator(path, query, header, formData, body)
  let scheme = call_774106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774106.url(scheme.get, call_774106.host, call_774106.base,
                         call_774106.route, valid.getOrDefault("path"))
  result = hook(call_774106, url, valid)

proc call*(call_774107: Call_GetSigningCertificate_774094; body: JsonNode): Recallable =
  ## getSigningCertificate
  ## This method takes a user pool ID, and returns the signing certificate.
  ##   body: JObject (required)
  var body_774108 = newJObject()
  if body != nil:
    body_774108 = body
  result = call_774107.call(nil, nil, nil, nil, body_774108)

var getSigningCertificate* = Call_GetSigningCertificate_774094(
    name: "getSigningCertificate", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetSigningCertificate",
    validator: validate_GetSigningCertificate_774095, base: "/",
    url: url_GetSigningCertificate_774096, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUICustomization_774109 = ref object of OpenApiRestCall_772597
proc url_GetUICustomization_774111(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUICustomization_774110(path: JsonNode; query: JsonNode;
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
  var valid_774112 = header.getOrDefault("X-Amz-Date")
  valid_774112 = validateParameter(valid_774112, JString, required = false,
                                 default = nil)
  if valid_774112 != nil:
    section.add "X-Amz-Date", valid_774112
  var valid_774113 = header.getOrDefault("X-Amz-Security-Token")
  valid_774113 = validateParameter(valid_774113, JString, required = false,
                                 default = nil)
  if valid_774113 != nil:
    section.add "X-Amz-Security-Token", valid_774113
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774114 = header.getOrDefault("X-Amz-Target")
  valid_774114 = validateParameter(valid_774114, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUICustomization"))
  if valid_774114 != nil:
    section.add "X-Amz-Target", valid_774114
  var valid_774115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774115 = validateParameter(valid_774115, JString, required = false,
                                 default = nil)
  if valid_774115 != nil:
    section.add "X-Amz-Content-Sha256", valid_774115
  var valid_774116 = header.getOrDefault("X-Amz-Algorithm")
  valid_774116 = validateParameter(valid_774116, JString, required = false,
                                 default = nil)
  if valid_774116 != nil:
    section.add "X-Amz-Algorithm", valid_774116
  var valid_774117 = header.getOrDefault("X-Amz-Signature")
  valid_774117 = validateParameter(valid_774117, JString, required = false,
                                 default = nil)
  if valid_774117 != nil:
    section.add "X-Amz-Signature", valid_774117
  var valid_774118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774118 = validateParameter(valid_774118, JString, required = false,
                                 default = nil)
  if valid_774118 != nil:
    section.add "X-Amz-SignedHeaders", valid_774118
  var valid_774119 = header.getOrDefault("X-Amz-Credential")
  valid_774119 = validateParameter(valid_774119, JString, required = false,
                                 default = nil)
  if valid_774119 != nil:
    section.add "X-Amz-Credential", valid_774119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774121: Call_GetUICustomization_774109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the UI Customization information for a particular app client's app UI, if there is something set. If nothing is set for the particular client, but there is an existing pool level customization (app <code>clientId</code> will be <code>ALL</code>), then that is returned. If nothing is present, then an empty shape is returned.
  ## 
  let valid = call_774121.validator(path, query, header, formData, body)
  let scheme = call_774121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774121.url(scheme.get, call_774121.host, call_774121.base,
                         call_774121.route, valid.getOrDefault("path"))
  result = hook(call_774121, url, valid)

proc call*(call_774122: Call_GetUICustomization_774109; body: JsonNode): Recallable =
  ## getUICustomization
  ## Gets the UI Customization information for a particular app client's app UI, if there is something set. If nothing is set for the particular client, but there is an existing pool level customization (app <code>clientId</code> will be <code>ALL</code>), then that is returned. If nothing is present, then an empty shape is returned.
  ##   body: JObject (required)
  var body_774123 = newJObject()
  if body != nil:
    body_774123 = body
  result = call_774122.call(nil, nil, nil, nil, body_774123)

var getUICustomization* = Call_GetUICustomization_774109(
    name: "getUICustomization", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUICustomization",
    validator: validate_GetUICustomization_774110, base: "/",
    url: url_GetUICustomization_774111, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUser_774124 = ref object of OpenApiRestCall_772597
proc url_GetUser_774126(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUser_774125(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774127 = header.getOrDefault("X-Amz-Date")
  valid_774127 = validateParameter(valid_774127, JString, required = false,
                                 default = nil)
  if valid_774127 != nil:
    section.add "X-Amz-Date", valid_774127
  var valid_774128 = header.getOrDefault("X-Amz-Security-Token")
  valid_774128 = validateParameter(valid_774128, JString, required = false,
                                 default = nil)
  if valid_774128 != nil:
    section.add "X-Amz-Security-Token", valid_774128
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774129 = header.getOrDefault("X-Amz-Target")
  valid_774129 = validateParameter(valid_774129, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUser"))
  if valid_774129 != nil:
    section.add "X-Amz-Target", valid_774129
  var valid_774130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774130 = validateParameter(valid_774130, JString, required = false,
                                 default = nil)
  if valid_774130 != nil:
    section.add "X-Amz-Content-Sha256", valid_774130
  var valid_774131 = header.getOrDefault("X-Amz-Algorithm")
  valid_774131 = validateParameter(valid_774131, JString, required = false,
                                 default = nil)
  if valid_774131 != nil:
    section.add "X-Amz-Algorithm", valid_774131
  var valid_774132 = header.getOrDefault("X-Amz-Signature")
  valid_774132 = validateParameter(valid_774132, JString, required = false,
                                 default = nil)
  if valid_774132 != nil:
    section.add "X-Amz-Signature", valid_774132
  var valid_774133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774133 = validateParameter(valid_774133, JString, required = false,
                                 default = nil)
  if valid_774133 != nil:
    section.add "X-Amz-SignedHeaders", valid_774133
  var valid_774134 = header.getOrDefault("X-Amz-Credential")
  valid_774134 = validateParameter(valid_774134, JString, required = false,
                                 default = nil)
  if valid_774134 != nil:
    section.add "X-Amz-Credential", valid_774134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774136: Call_GetUser_774124; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the user attributes and metadata for a user.
  ## 
  let valid = call_774136.validator(path, query, header, formData, body)
  let scheme = call_774136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774136.url(scheme.get, call_774136.host, call_774136.base,
                         call_774136.route, valid.getOrDefault("path"))
  result = hook(call_774136, url, valid)

proc call*(call_774137: Call_GetUser_774124; body: JsonNode): Recallable =
  ## getUser
  ## Gets the user attributes and metadata for a user.
  ##   body: JObject (required)
  var body_774138 = newJObject()
  if body != nil:
    body_774138 = body
  result = call_774137.call(nil, nil, nil, nil, body_774138)

var getUser* = Call_GetUser_774124(name: "getUser", meth: HttpMethod.HttpPost,
                                host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUser",
                                validator: validate_GetUser_774125, base: "/",
                                url: url_GetUser_774126,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserAttributeVerificationCode_774139 = ref object of OpenApiRestCall_772597
proc url_GetUserAttributeVerificationCode_774141(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUserAttributeVerificationCode_774140(path: JsonNode;
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
  var valid_774142 = header.getOrDefault("X-Amz-Date")
  valid_774142 = validateParameter(valid_774142, JString, required = false,
                                 default = nil)
  if valid_774142 != nil:
    section.add "X-Amz-Date", valid_774142
  var valid_774143 = header.getOrDefault("X-Amz-Security-Token")
  valid_774143 = validateParameter(valid_774143, JString, required = false,
                                 default = nil)
  if valid_774143 != nil:
    section.add "X-Amz-Security-Token", valid_774143
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774144 = header.getOrDefault("X-Amz-Target")
  valid_774144 = validateParameter(valid_774144, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUserAttributeVerificationCode"))
  if valid_774144 != nil:
    section.add "X-Amz-Target", valid_774144
  var valid_774145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774145 = validateParameter(valid_774145, JString, required = false,
                                 default = nil)
  if valid_774145 != nil:
    section.add "X-Amz-Content-Sha256", valid_774145
  var valid_774146 = header.getOrDefault("X-Amz-Algorithm")
  valid_774146 = validateParameter(valid_774146, JString, required = false,
                                 default = nil)
  if valid_774146 != nil:
    section.add "X-Amz-Algorithm", valid_774146
  var valid_774147 = header.getOrDefault("X-Amz-Signature")
  valid_774147 = validateParameter(valid_774147, JString, required = false,
                                 default = nil)
  if valid_774147 != nil:
    section.add "X-Amz-Signature", valid_774147
  var valid_774148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774148 = validateParameter(valid_774148, JString, required = false,
                                 default = nil)
  if valid_774148 != nil:
    section.add "X-Amz-SignedHeaders", valid_774148
  var valid_774149 = header.getOrDefault("X-Amz-Credential")
  valid_774149 = validateParameter(valid_774149, JString, required = false,
                                 default = nil)
  if valid_774149 != nil:
    section.add "X-Amz-Credential", valid_774149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774151: Call_GetUserAttributeVerificationCode_774139;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the user attribute verification code for the specified attribute name.
  ## 
  let valid = call_774151.validator(path, query, header, formData, body)
  let scheme = call_774151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774151.url(scheme.get, call_774151.host, call_774151.base,
                         call_774151.route, valid.getOrDefault("path"))
  result = hook(call_774151, url, valid)

proc call*(call_774152: Call_GetUserAttributeVerificationCode_774139;
          body: JsonNode): Recallable =
  ## getUserAttributeVerificationCode
  ## Gets the user attribute verification code for the specified attribute name.
  ##   body: JObject (required)
  var body_774153 = newJObject()
  if body != nil:
    body_774153 = body
  result = call_774152.call(nil, nil, nil, nil, body_774153)

var getUserAttributeVerificationCode* = Call_GetUserAttributeVerificationCode_774139(
    name: "getUserAttributeVerificationCode", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUserAttributeVerificationCode",
    validator: validate_GetUserAttributeVerificationCode_774140, base: "/",
    url: url_GetUserAttributeVerificationCode_774141,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserPoolMfaConfig_774154 = ref object of OpenApiRestCall_772597
proc url_GetUserPoolMfaConfig_774156(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUserPoolMfaConfig_774155(path: JsonNode; query: JsonNode;
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
  var valid_774157 = header.getOrDefault("X-Amz-Date")
  valid_774157 = validateParameter(valid_774157, JString, required = false,
                                 default = nil)
  if valid_774157 != nil:
    section.add "X-Amz-Date", valid_774157
  var valid_774158 = header.getOrDefault("X-Amz-Security-Token")
  valid_774158 = validateParameter(valid_774158, JString, required = false,
                                 default = nil)
  if valid_774158 != nil:
    section.add "X-Amz-Security-Token", valid_774158
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774159 = header.getOrDefault("X-Amz-Target")
  valid_774159 = validateParameter(valid_774159, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUserPoolMfaConfig"))
  if valid_774159 != nil:
    section.add "X-Amz-Target", valid_774159
  var valid_774160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774160 = validateParameter(valid_774160, JString, required = false,
                                 default = nil)
  if valid_774160 != nil:
    section.add "X-Amz-Content-Sha256", valid_774160
  var valid_774161 = header.getOrDefault("X-Amz-Algorithm")
  valid_774161 = validateParameter(valid_774161, JString, required = false,
                                 default = nil)
  if valid_774161 != nil:
    section.add "X-Amz-Algorithm", valid_774161
  var valid_774162 = header.getOrDefault("X-Amz-Signature")
  valid_774162 = validateParameter(valid_774162, JString, required = false,
                                 default = nil)
  if valid_774162 != nil:
    section.add "X-Amz-Signature", valid_774162
  var valid_774163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774163 = validateParameter(valid_774163, JString, required = false,
                                 default = nil)
  if valid_774163 != nil:
    section.add "X-Amz-SignedHeaders", valid_774163
  var valid_774164 = header.getOrDefault("X-Amz-Credential")
  valid_774164 = validateParameter(valid_774164, JString, required = false,
                                 default = nil)
  if valid_774164 != nil:
    section.add "X-Amz-Credential", valid_774164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774166: Call_GetUserPoolMfaConfig_774154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the user pool multi-factor authentication (MFA) configuration.
  ## 
  let valid = call_774166.validator(path, query, header, formData, body)
  let scheme = call_774166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774166.url(scheme.get, call_774166.host, call_774166.base,
                         call_774166.route, valid.getOrDefault("path"))
  result = hook(call_774166, url, valid)

proc call*(call_774167: Call_GetUserPoolMfaConfig_774154; body: JsonNode): Recallable =
  ## getUserPoolMfaConfig
  ## Gets the user pool multi-factor authentication (MFA) configuration.
  ##   body: JObject (required)
  var body_774168 = newJObject()
  if body != nil:
    body_774168 = body
  result = call_774167.call(nil, nil, nil, nil, body_774168)

var getUserPoolMfaConfig* = Call_GetUserPoolMfaConfig_774154(
    name: "getUserPoolMfaConfig", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUserPoolMfaConfig",
    validator: validate_GetUserPoolMfaConfig_774155, base: "/",
    url: url_GetUserPoolMfaConfig_774156, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GlobalSignOut_774169 = ref object of OpenApiRestCall_772597
proc url_GlobalSignOut_774171(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GlobalSignOut_774170(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Signs out users from all devices.
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
  var valid_774172 = header.getOrDefault("X-Amz-Date")
  valid_774172 = validateParameter(valid_774172, JString, required = false,
                                 default = nil)
  if valid_774172 != nil:
    section.add "X-Amz-Date", valid_774172
  var valid_774173 = header.getOrDefault("X-Amz-Security-Token")
  valid_774173 = validateParameter(valid_774173, JString, required = false,
                                 default = nil)
  if valid_774173 != nil:
    section.add "X-Amz-Security-Token", valid_774173
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774174 = header.getOrDefault("X-Amz-Target")
  valid_774174 = validateParameter(valid_774174, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GlobalSignOut"))
  if valid_774174 != nil:
    section.add "X-Amz-Target", valid_774174
  var valid_774175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774175 = validateParameter(valid_774175, JString, required = false,
                                 default = nil)
  if valid_774175 != nil:
    section.add "X-Amz-Content-Sha256", valid_774175
  var valid_774176 = header.getOrDefault("X-Amz-Algorithm")
  valid_774176 = validateParameter(valid_774176, JString, required = false,
                                 default = nil)
  if valid_774176 != nil:
    section.add "X-Amz-Algorithm", valid_774176
  var valid_774177 = header.getOrDefault("X-Amz-Signature")
  valid_774177 = validateParameter(valid_774177, JString, required = false,
                                 default = nil)
  if valid_774177 != nil:
    section.add "X-Amz-Signature", valid_774177
  var valid_774178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774178 = validateParameter(valid_774178, JString, required = false,
                                 default = nil)
  if valid_774178 != nil:
    section.add "X-Amz-SignedHeaders", valid_774178
  var valid_774179 = header.getOrDefault("X-Amz-Credential")
  valid_774179 = validateParameter(valid_774179, JString, required = false,
                                 default = nil)
  if valid_774179 != nil:
    section.add "X-Amz-Credential", valid_774179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774181: Call_GlobalSignOut_774169; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Signs out users from all devices.
  ## 
  let valid = call_774181.validator(path, query, header, formData, body)
  let scheme = call_774181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774181.url(scheme.get, call_774181.host, call_774181.base,
                         call_774181.route, valid.getOrDefault("path"))
  result = hook(call_774181, url, valid)

proc call*(call_774182: Call_GlobalSignOut_774169; body: JsonNode): Recallable =
  ## globalSignOut
  ## Signs out users from all devices.
  ##   body: JObject (required)
  var body_774183 = newJObject()
  if body != nil:
    body_774183 = body
  result = call_774182.call(nil, nil, nil, nil, body_774183)

var globalSignOut* = Call_GlobalSignOut_774169(name: "globalSignOut",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GlobalSignOut",
    validator: validate_GlobalSignOut_774170, base: "/", url: url_GlobalSignOut_774171,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateAuth_774184 = ref object of OpenApiRestCall_772597
proc url_InitiateAuth_774186(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_InitiateAuth_774185(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774187 = header.getOrDefault("X-Amz-Date")
  valid_774187 = validateParameter(valid_774187, JString, required = false,
                                 default = nil)
  if valid_774187 != nil:
    section.add "X-Amz-Date", valid_774187
  var valid_774188 = header.getOrDefault("X-Amz-Security-Token")
  valid_774188 = validateParameter(valid_774188, JString, required = false,
                                 default = nil)
  if valid_774188 != nil:
    section.add "X-Amz-Security-Token", valid_774188
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774189 = header.getOrDefault("X-Amz-Target")
  valid_774189 = validateParameter(valid_774189, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.InitiateAuth"))
  if valid_774189 != nil:
    section.add "X-Amz-Target", valid_774189
  var valid_774190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774190 = validateParameter(valid_774190, JString, required = false,
                                 default = nil)
  if valid_774190 != nil:
    section.add "X-Amz-Content-Sha256", valid_774190
  var valid_774191 = header.getOrDefault("X-Amz-Algorithm")
  valid_774191 = validateParameter(valid_774191, JString, required = false,
                                 default = nil)
  if valid_774191 != nil:
    section.add "X-Amz-Algorithm", valid_774191
  var valid_774192 = header.getOrDefault("X-Amz-Signature")
  valid_774192 = validateParameter(valid_774192, JString, required = false,
                                 default = nil)
  if valid_774192 != nil:
    section.add "X-Amz-Signature", valid_774192
  var valid_774193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774193 = validateParameter(valid_774193, JString, required = false,
                                 default = nil)
  if valid_774193 != nil:
    section.add "X-Amz-SignedHeaders", valid_774193
  var valid_774194 = header.getOrDefault("X-Amz-Credential")
  valid_774194 = validateParameter(valid_774194, JString, required = false,
                                 default = nil)
  if valid_774194 != nil:
    section.add "X-Amz-Credential", valid_774194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774196: Call_InitiateAuth_774184; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates the authentication flow.
  ## 
  let valid = call_774196.validator(path, query, header, formData, body)
  let scheme = call_774196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774196.url(scheme.get, call_774196.host, call_774196.base,
                         call_774196.route, valid.getOrDefault("path"))
  result = hook(call_774196, url, valid)

proc call*(call_774197: Call_InitiateAuth_774184; body: JsonNode): Recallable =
  ## initiateAuth
  ## Initiates the authentication flow.
  ##   body: JObject (required)
  var body_774198 = newJObject()
  if body != nil:
    body_774198 = body
  result = call_774197.call(nil, nil, nil, nil, body_774198)

var initiateAuth* = Call_InitiateAuth_774184(name: "initiateAuth",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.InitiateAuth",
    validator: validate_InitiateAuth_774185, base: "/", url: url_InitiateAuth_774186,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevices_774199 = ref object of OpenApiRestCall_772597
proc url_ListDevices_774201(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDevices_774200(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774202 = header.getOrDefault("X-Amz-Date")
  valid_774202 = validateParameter(valid_774202, JString, required = false,
                                 default = nil)
  if valid_774202 != nil:
    section.add "X-Amz-Date", valid_774202
  var valid_774203 = header.getOrDefault("X-Amz-Security-Token")
  valid_774203 = validateParameter(valid_774203, JString, required = false,
                                 default = nil)
  if valid_774203 != nil:
    section.add "X-Amz-Security-Token", valid_774203
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774204 = header.getOrDefault("X-Amz-Target")
  valid_774204 = validateParameter(valid_774204, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListDevices"))
  if valid_774204 != nil:
    section.add "X-Amz-Target", valid_774204
  var valid_774205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774205 = validateParameter(valid_774205, JString, required = false,
                                 default = nil)
  if valid_774205 != nil:
    section.add "X-Amz-Content-Sha256", valid_774205
  var valid_774206 = header.getOrDefault("X-Amz-Algorithm")
  valid_774206 = validateParameter(valid_774206, JString, required = false,
                                 default = nil)
  if valid_774206 != nil:
    section.add "X-Amz-Algorithm", valid_774206
  var valid_774207 = header.getOrDefault("X-Amz-Signature")
  valid_774207 = validateParameter(valid_774207, JString, required = false,
                                 default = nil)
  if valid_774207 != nil:
    section.add "X-Amz-Signature", valid_774207
  var valid_774208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774208 = validateParameter(valid_774208, JString, required = false,
                                 default = nil)
  if valid_774208 != nil:
    section.add "X-Amz-SignedHeaders", valid_774208
  var valid_774209 = header.getOrDefault("X-Amz-Credential")
  valid_774209 = validateParameter(valid_774209, JString, required = false,
                                 default = nil)
  if valid_774209 != nil:
    section.add "X-Amz-Credential", valid_774209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774211: Call_ListDevices_774199; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the devices.
  ## 
  let valid = call_774211.validator(path, query, header, formData, body)
  let scheme = call_774211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774211.url(scheme.get, call_774211.host, call_774211.base,
                         call_774211.route, valid.getOrDefault("path"))
  result = hook(call_774211, url, valid)

proc call*(call_774212: Call_ListDevices_774199; body: JsonNode): Recallable =
  ## listDevices
  ## Lists the devices.
  ##   body: JObject (required)
  var body_774213 = newJObject()
  if body != nil:
    body_774213 = body
  result = call_774212.call(nil, nil, nil, nil, body_774213)

var listDevices* = Call_ListDevices_774199(name: "listDevices",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListDevices",
                                        validator: validate_ListDevices_774200,
                                        base: "/", url: url_ListDevices_774201,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_774214 = ref object of OpenApiRestCall_772597
proc url_ListGroups_774216(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListGroups_774215(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the groups associated with a user pool.</p> <p>Requires developer credentials.</p>
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
  var valid_774217 = query.getOrDefault("Limit")
  valid_774217 = validateParameter(valid_774217, JString, required = false,
                                 default = nil)
  if valid_774217 != nil:
    section.add "Limit", valid_774217
  var valid_774218 = query.getOrDefault("NextToken")
  valid_774218 = validateParameter(valid_774218, JString, required = false,
                                 default = nil)
  if valid_774218 != nil:
    section.add "NextToken", valid_774218
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
  var valid_774219 = header.getOrDefault("X-Amz-Date")
  valid_774219 = validateParameter(valid_774219, JString, required = false,
                                 default = nil)
  if valid_774219 != nil:
    section.add "X-Amz-Date", valid_774219
  var valid_774220 = header.getOrDefault("X-Amz-Security-Token")
  valid_774220 = validateParameter(valid_774220, JString, required = false,
                                 default = nil)
  if valid_774220 != nil:
    section.add "X-Amz-Security-Token", valid_774220
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774221 = header.getOrDefault("X-Amz-Target")
  valid_774221 = validateParameter(valid_774221, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListGroups"))
  if valid_774221 != nil:
    section.add "X-Amz-Target", valid_774221
  var valid_774222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774222 = validateParameter(valid_774222, JString, required = false,
                                 default = nil)
  if valid_774222 != nil:
    section.add "X-Amz-Content-Sha256", valid_774222
  var valid_774223 = header.getOrDefault("X-Amz-Algorithm")
  valid_774223 = validateParameter(valid_774223, JString, required = false,
                                 default = nil)
  if valid_774223 != nil:
    section.add "X-Amz-Algorithm", valid_774223
  var valid_774224 = header.getOrDefault("X-Amz-Signature")
  valid_774224 = validateParameter(valid_774224, JString, required = false,
                                 default = nil)
  if valid_774224 != nil:
    section.add "X-Amz-Signature", valid_774224
  var valid_774225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774225 = validateParameter(valid_774225, JString, required = false,
                                 default = nil)
  if valid_774225 != nil:
    section.add "X-Amz-SignedHeaders", valid_774225
  var valid_774226 = header.getOrDefault("X-Amz-Credential")
  valid_774226 = validateParameter(valid_774226, JString, required = false,
                                 default = nil)
  if valid_774226 != nil:
    section.add "X-Amz-Credential", valid_774226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774228: Call_ListGroups_774214; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the groups associated with a user pool.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_774228.validator(path, query, header, formData, body)
  let scheme = call_774228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774228.url(scheme.get, call_774228.host, call_774228.base,
                         call_774228.route, valid.getOrDefault("path"))
  result = hook(call_774228, url, valid)

proc call*(call_774229: Call_ListGroups_774214; body: JsonNode; Limit: string = "";
          NextToken: string = ""): Recallable =
  ## listGroups
  ## <p>Lists the groups associated with a user pool.</p> <p>Requires developer credentials.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_774230 = newJObject()
  var body_774231 = newJObject()
  add(query_774230, "Limit", newJString(Limit))
  add(query_774230, "NextToken", newJString(NextToken))
  if body != nil:
    body_774231 = body
  result = call_774229.call(nil, query_774230, nil, nil, body_774231)

var listGroups* = Call_ListGroups_774214(name: "listGroups",
                                      meth: HttpMethod.HttpPost,
                                      host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListGroups",
                                      validator: validate_ListGroups_774215,
                                      base: "/", url: url_ListGroups_774216,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIdentityProviders_774232 = ref object of OpenApiRestCall_772597
proc url_ListIdentityProviders_774234(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListIdentityProviders_774233(path: JsonNode; query: JsonNode;
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
  var valid_774235 = query.getOrDefault("NextToken")
  valid_774235 = validateParameter(valid_774235, JString, required = false,
                                 default = nil)
  if valid_774235 != nil:
    section.add "NextToken", valid_774235
  var valid_774236 = query.getOrDefault("MaxResults")
  valid_774236 = validateParameter(valid_774236, JString, required = false,
                                 default = nil)
  if valid_774236 != nil:
    section.add "MaxResults", valid_774236
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
  var valid_774237 = header.getOrDefault("X-Amz-Date")
  valid_774237 = validateParameter(valid_774237, JString, required = false,
                                 default = nil)
  if valid_774237 != nil:
    section.add "X-Amz-Date", valid_774237
  var valid_774238 = header.getOrDefault("X-Amz-Security-Token")
  valid_774238 = validateParameter(valid_774238, JString, required = false,
                                 default = nil)
  if valid_774238 != nil:
    section.add "X-Amz-Security-Token", valid_774238
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774239 = header.getOrDefault("X-Amz-Target")
  valid_774239 = validateParameter(valid_774239, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListIdentityProviders"))
  if valid_774239 != nil:
    section.add "X-Amz-Target", valid_774239
  var valid_774240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774240 = validateParameter(valid_774240, JString, required = false,
                                 default = nil)
  if valid_774240 != nil:
    section.add "X-Amz-Content-Sha256", valid_774240
  var valid_774241 = header.getOrDefault("X-Amz-Algorithm")
  valid_774241 = validateParameter(valid_774241, JString, required = false,
                                 default = nil)
  if valid_774241 != nil:
    section.add "X-Amz-Algorithm", valid_774241
  var valid_774242 = header.getOrDefault("X-Amz-Signature")
  valid_774242 = validateParameter(valid_774242, JString, required = false,
                                 default = nil)
  if valid_774242 != nil:
    section.add "X-Amz-Signature", valid_774242
  var valid_774243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774243 = validateParameter(valid_774243, JString, required = false,
                                 default = nil)
  if valid_774243 != nil:
    section.add "X-Amz-SignedHeaders", valid_774243
  var valid_774244 = header.getOrDefault("X-Amz-Credential")
  valid_774244 = validateParameter(valid_774244, JString, required = false,
                                 default = nil)
  if valid_774244 != nil:
    section.add "X-Amz-Credential", valid_774244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774246: Call_ListIdentityProviders_774232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about all identity providers for a user pool.
  ## 
  let valid = call_774246.validator(path, query, header, formData, body)
  let scheme = call_774246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774246.url(scheme.get, call_774246.host, call_774246.base,
                         call_774246.route, valid.getOrDefault("path"))
  result = hook(call_774246, url, valid)

proc call*(call_774247: Call_ListIdentityProviders_774232; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listIdentityProviders
  ## Lists information about all identity providers for a user pool.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774248 = newJObject()
  var body_774249 = newJObject()
  add(query_774248, "NextToken", newJString(NextToken))
  if body != nil:
    body_774249 = body
  add(query_774248, "MaxResults", newJString(MaxResults))
  result = call_774247.call(nil, query_774248, nil, nil, body_774249)

var listIdentityProviders* = Call_ListIdentityProviders_774232(
    name: "listIdentityProviders", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListIdentityProviders",
    validator: validate_ListIdentityProviders_774233, base: "/",
    url: url_ListIdentityProviders_774234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceServers_774250 = ref object of OpenApiRestCall_772597
proc url_ListResourceServers_774252(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListResourceServers_774251(path: JsonNode; query: JsonNode;
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
  var valid_774253 = query.getOrDefault("NextToken")
  valid_774253 = validateParameter(valid_774253, JString, required = false,
                                 default = nil)
  if valid_774253 != nil:
    section.add "NextToken", valid_774253
  var valid_774254 = query.getOrDefault("MaxResults")
  valid_774254 = validateParameter(valid_774254, JString, required = false,
                                 default = nil)
  if valid_774254 != nil:
    section.add "MaxResults", valid_774254
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
  var valid_774255 = header.getOrDefault("X-Amz-Date")
  valid_774255 = validateParameter(valid_774255, JString, required = false,
                                 default = nil)
  if valid_774255 != nil:
    section.add "X-Amz-Date", valid_774255
  var valid_774256 = header.getOrDefault("X-Amz-Security-Token")
  valid_774256 = validateParameter(valid_774256, JString, required = false,
                                 default = nil)
  if valid_774256 != nil:
    section.add "X-Amz-Security-Token", valid_774256
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774257 = header.getOrDefault("X-Amz-Target")
  valid_774257 = validateParameter(valid_774257, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListResourceServers"))
  if valid_774257 != nil:
    section.add "X-Amz-Target", valid_774257
  var valid_774258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774258 = validateParameter(valid_774258, JString, required = false,
                                 default = nil)
  if valid_774258 != nil:
    section.add "X-Amz-Content-Sha256", valid_774258
  var valid_774259 = header.getOrDefault("X-Amz-Algorithm")
  valid_774259 = validateParameter(valid_774259, JString, required = false,
                                 default = nil)
  if valid_774259 != nil:
    section.add "X-Amz-Algorithm", valid_774259
  var valid_774260 = header.getOrDefault("X-Amz-Signature")
  valid_774260 = validateParameter(valid_774260, JString, required = false,
                                 default = nil)
  if valid_774260 != nil:
    section.add "X-Amz-Signature", valid_774260
  var valid_774261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774261 = validateParameter(valid_774261, JString, required = false,
                                 default = nil)
  if valid_774261 != nil:
    section.add "X-Amz-SignedHeaders", valid_774261
  var valid_774262 = header.getOrDefault("X-Amz-Credential")
  valid_774262 = validateParameter(valid_774262, JString, required = false,
                                 default = nil)
  if valid_774262 != nil:
    section.add "X-Amz-Credential", valid_774262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774264: Call_ListResourceServers_774250; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resource servers for a user pool.
  ## 
  let valid = call_774264.validator(path, query, header, formData, body)
  let scheme = call_774264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774264.url(scheme.get, call_774264.host, call_774264.base,
                         call_774264.route, valid.getOrDefault("path"))
  result = hook(call_774264, url, valid)

proc call*(call_774265: Call_ListResourceServers_774250; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listResourceServers
  ## Lists the resource servers for a user pool.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774266 = newJObject()
  var body_774267 = newJObject()
  add(query_774266, "NextToken", newJString(NextToken))
  if body != nil:
    body_774267 = body
  add(query_774266, "MaxResults", newJString(MaxResults))
  result = call_774265.call(nil, query_774266, nil, nil, body_774267)

var listResourceServers* = Call_ListResourceServers_774250(
    name: "listResourceServers", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListResourceServers",
    validator: validate_ListResourceServers_774251, base: "/",
    url: url_ListResourceServers_774252, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_774268 = ref object of OpenApiRestCall_772597
proc url_ListTagsForResource_774270(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource_774269(path: JsonNode; query: JsonNode;
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
  var valid_774271 = header.getOrDefault("X-Amz-Date")
  valid_774271 = validateParameter(valid_774271, JString, required = false,
                                 default = nil)
  if valid_774271 != nil:
    section.add "X-Amz-Date", valid_774271
  var valid_774272 = header.getOrDefault("X-Amz-Security-Token")
  valid_774272 = validateParameter(valid_774272, JString, required = false,
                                 default = nil)
  if valid_774272 != nil:
    section.add "X-Amz-Security-Token", valid_774272
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774273 = header.getOrDefault("X-Amz-Target")
  valid_774273 = validateParameter(valid_774273, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListTagsForResource"))
  if valid_774273 != nil:
    section.add "X-Amz-Target", valid_774273
  var valid_774274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774274 = validateParameter(valid_774274, JString, required = false,
                                 default = nil)
  if valid_774274 != nil:
    section.add "X-Amz-Content-Sha256", valid_774274
  var valid_774275 = header.getOrDefault("X-Amz-Algorithm")
  valid_774275 = validateParameter(valid_774275, JString, required = false,
                                 default = nil)
  if valid_774275 != nil:
    section.add "X-Amz-Algorithm", valid_774275
  var valid_774276 = header.getOrDefault("X-Amz-Signature")
  valid_774276 = validateParameter(valid_774276, JString, required = false,
                                 default = nil)
  if valid_774276 != nil:
    section.add "X-Amz-Signature", valid_774276
  var valid_774277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774277 = validateParameter(valid_774277, JString, required = false,
                                 default = nil)
  if valid_774277 != nil:
    section.add "X-Amz-SignedHeaders", valid_774277
  var valid_774278 = header.getOrDefault("X-Amz-Credential")
  valid_774278 = validateParameter(valid_774278, JString, required = false,
                                 default = nil)
  if valid_774278 != nil:
    section.add "X-Amz-Credential", valid_774278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774280: Call_ListTagsForResource_774268; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the tags that are assigned to an Amazon Cognito user pool.</p> <p>A tag is a label that you can apply to user pools to categorize and manage them in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>You can use this action up to 10 times per second, per account.</p>
  ## 
  let valid = call_774280.validator(path, query, header, formData, body)
  let scheme = call_774280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774280.url(scheme.get, call_774280.host, call_774280.base,
                         call_774280.route, valid.getOrDefault("path"))
  result = hook(call_774280, url, valid)

proc call*(call_774281: Call_ListTagsForResource_774268; body: JsonNode): Recallable =
  ## listTagsForResource
  ## <p>Lists the tags that are assigned to an Amazon Cognito user pool.</p> <p>A tag is a label that you can apply to user pools to categorize and manage them in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>You can use this action up to 10 times per second, per account.</p>
  ##   body: JObject (required)
  var body_774282 = newJObject()
  if body != nil:
    body_774282 = body
  result = call_774281.call(nil, nil, nil, nil, body_774282)

var listTagsForResource* = Call_ListTagsForResource_774268(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListTagsForResource",
    validator: validate_ListTagsForResource_774269, base: "/",
    url: url_ListTagsForResource_774270, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserImportJobs_774283 = ref object of OpenApiRestCall_772597
proc url_ListUserImportJobs_774285(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListUserImportJobs_774284(path: JsonNode; query: JsonNode;
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
  var valid_774286 = header.getOrDefault("X-Amz-Date")
  valid_774286 = validateParameter(valid_774286, JString, required = false,
                                 default = nil)
  if valid_774286 != nil:
    section.add "X-Amz-Date", valid_774286
  var valid_774287 = header.getOrDefault("X-Amz-Security-Token")
  valid_774287 = validateParameter(valid_774287, JString, required = false,
                                 default = nil)
  if valid_774287 != nil:
    section.add "X-Amz-Security-Token", valid_774287
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774288 = header.getOrDefault("X-Amz-Target")
  valid_774288 = validateParameter(valid_774288, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUserImportJobs"))
  if valid_774288 != nil:
    section.add "X-Amz-Target", valid_774288
  var valid_774289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774289 = validateParameter(valid_774289, JString, required = false,
                                 default = nil)
  if valid_774289 != nil:
    section.add "X-Amz-Content-Sha256", valid_774289
  var valid_774290 = header.getOrDefault("X-Amz-Algorithm")
  valid_774290 = validateParameter(valid_774290, JString, required = false,
                                 default = nil)
  if valid_774290 != nil:
    section.add "X-Amz-Algorithm", valid_774290
  var valid_774291 = header.getOrDefault("X-Amz-Signature")
  valid_774291 = validateParameter(valid_774291, JString, required = false,
                                 default = nil)
  if valid_774291 != nil:
    section.add "X-Amz-Signature", valid_774291
  var valid_774292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774292 = validateParameter(valid_774292, JString, required = false,
                                 default = nil)
  if valid_774292 != nil:
    section.add "X-Amz-SignedHeaders", valid_774292
  var valid_774293 = header.getOrDefault("X-Amz-Credential")
  valid_774293 = validateParameter(valid_774293, JString, required = false,
                                 default = nil)
  if valid_774293 != nil:
    section.add "X-Amz-Credential", valid_774293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774295: Call_ListUserImportJobs_774283; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the user import jobs.
  ## 
  let valid = call_774295.validator(path, query, header, formData, body)
  let scheme = call_774295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774295.url(scheme.get, call_774295.host, call_774295.base,
                         call_774295.route, valid.getOrDefault("path"))
  result = hook(call_774295, url, valid)

proc call*(call_774296: Call_ListUserImportJobs_774283; body: JsonNode): Recallable =
  ## listUserImportJobs
  ## Lists the user import jobs.
  ##   body: JObject (required)
  var body_774297 = newJObject()
  if body != nil:
    body_774297 = body
  result = call_774296.call(nil, nil, nil, nil, body_774297)

var listUserImportJobs* = Call_ListUserImportJobs_774283(
    name: "listUserImportJobs", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUserImportJobs",
    validator: validate_ListUserImportJobs_774284, base: "/",
    url: url_ListUserImportJobs_774285, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserPoolClients_774298 = ref object of OpenApiRestCall_772597
proc url_ListUserPoolClients_774300(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListUserPoolClients_774299(path: JsonNode; query: JsonNode;
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
  var valid_774301 = query.getOrDefault("NextToken")
  valid_774301 = validateParameter(valid_774301, JString, required = false,
                                 default = nil)
  if valid_774301 != nil:
    section.add "NextToken", valid_774301
  var valid_774302 = query.getOrDefault("MaxResults")
  valid_774302 = validateParameter(valid_774302, JString, required = false,
                                 default = nil)
  if valid_774302 != nil:
    section.add "MaxResults", valid_774302
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
  var valid_774303 = header.getOrDefault("X-Amz-Date")
  valid_774303 = validateParameter(valid_774303, JString, required = false,
                                 default = nil)
  if valid_774303 != nil:
    section.add "X-Amz-Date", valid_774303
  var valid_774304 = header.getOrDefault("X-Amz-Security-Token")
  valid_774304 = validateParameter(valid_774304, JString, required = false,
                                 default = nil)
  if valid_774304 != nil:
    section.add "X-Amz-Security-Token", valid_774304
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774305 = header.getOrDefault("X-Amz-Target")
  valid_774305 = validateParameter(valid_774305, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUserPoolClients"))
  if valid_774305 != nil:
    section.add "X-Amz-Target", valid_774305
  var valid_774306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774306 = validateParameter(valid_774306, JString, required = false,
                                 default = nil)
  if valid_774306 != nil:
    section.add "X-Amz-Content-Sha256", valid_774306
  var valid_774307 = header.getOrDefault("X-Amz-Algorithm")
  valid_774307 = validateParameter(valid_774307, JString, required = false,
                                 default = nil)
  if valid_774307 != nil:
    section.add "X-Amz-Algorithm", valid_774307
  var valid_774308 = header.getOrDefault("X-Amz-Signature")
  valid_774308 = validateParameter(valid_774308, JString, required = false,
                                 default = nil)
  if valid_774308 != nil:
    section.add "X-Amz-Signature", valid_774308
  var valid_774309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774309 = validateParameter(valid_774309, JString, required = false,
                                 default = nil)
  if valid_774309 != nil:
    section.add "X-Amz-SignedHeaders", valid_774309
  var valid_774310 = header.getOrDefault("X-Amz-Credential")
  valid_774310 = validateParameter(valid_774310, JString, required = false,
                                 default = nil)
  if valid_774310 != nil:
    section.add "X-Amz-Credential", valid_774310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774312: Call_ListUserPoolClients_774298; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the clients that have been created for the specified user pool.
  ## 
  let valid = call_774312.validator(path, query, header, formData, body)
  let scheme = call_774312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774312.url(scheme.get, call_774312.host, call_774312.base,
                         call_774312.route, valid.getOrDefault("path"))
  result = hook(call_774312, url, valid)

proc call*(call_774313: Call_ListUserPoolClients_774298; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listUserPoolClients
  ## Lists the clients that have been created for the specified user pool.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774314 = newJObject()
  var body_774315 = newJObject()
  add(query_774314, "NextToken", newJString(NextToken))
  if body != nil:
    body_774315 = body
  add(query_774314, "MaxResults", newJString(MaxResults))
  result = call_774313.call(nil, query_774314, nil, nil, body_774315)

var listUserPoolClients* = Call_ListUserPoolClients_774298(
    name: "listUserPoolClients", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUserPoolClients",
    validator: validate_ListUserPoolClients_774299, base: "/",
    url: url_ListUserPoolClients_774300, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserPools_774316 = ref object of OpenApiRestCall_772597
proc url_ListUserPools_774318(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListUserPools_774317(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774319 = query.getOrDefault("NextToken")
  valid_774319 = validateParameter(valid_774319, JString, required = false,
                                 default = nil)
  if valid_774319 != nil:
    section.add "NextToken", valid_774319
  var valid_774320 = query.getOrDefault("MaxResults")
  valid_774320 = validateParameter(valid_774320, JString, required = false,
                                 default = nil)
  if valid_774320 != nil:
    section.add "MaxResults", valid_774320
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
  var valid_774321 = header.getOrDefault("X-Amz-Date")
  valid_774321 = validateParameter(valid_774321, JString, required = false,
                                 default = nil)
  if valid_774321 != nil:
    section.add "X-Amz-Date", valid_774321
  var valid_774322 = header.getOrDefault("X-Amz-Security-Token")
  valid_774322 = validateParameter(valid_774322, JString, required = false,
                                 default = nil)
  if valid_774322 != nil:
    section.add "X-Amz-Security-Token", valid_774322
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774323 = header.getOrDefault("X-Amz-Target")
  valid_774323 = validateParameter(valid_774323, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUserPools"))
  if valid_774323 != nil:
    section.add "X-Amz-Target", valid_774323
  var valid_774324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774324 = validateParameter(valid_774324, JString, required = false,
                                 default = nil)
  if valid_774324 != nil:
    section.add "X-Amz-Content-Sha256", valid_774324
  var valid_774325 = header.getOrDefault("X-Amz-Algorithm")
  valid_774325 = validateParameter(valid_774325, JString, required = false,
                                 default = nil)
  if valid_774325 != nil:
    section.add "X-Amz-Algorithm", valid_774325
  var valid_774326 = header.getOrDefault("X-Amz-Signature")
  valid_774326 = validateParameter(valid_774326, JString, required = false,
                                 default = nil)
  if valid_774326 != nil:
    section.add "X-Amz-Signature", valid_774326
  var valid_774327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774327 = validateParameter(valid_774327, JString, required = false,
                                 default = nil)
  if valid_774327 != nil:
    section.add "X-Amz-SignedHeaders", valid_774327
  var valid_774328 = header.getOrDefault("X-Amz-Credential")
  valid_774328 = validateParameter(valid_774328, JString, required = false,
                                 default = nil)
  if valid_774328 != nil:
    section.add "X-Amz-Credential", valid_774328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774330: Call_ListUserPools_774316; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the user pools associated with an AWS account.
  ## 
  let valid = call_774330.validator(path, query, header, formData, body)
  let scheme = call_774330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774330.url(scheme.get, call_774330.host, call_774330.base,
                         call_774330.route, valid.getOrDefault("path"))
  result = hook(call_774330, url, valid)

proc call*(call_774331: Call_ListUserPools_774316; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listUserPools
  ## Lists the user pools associated with an AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774332 = newJObject()
  var body_774333 = newJObject()
  add(query_774332, "NextToken", newJString(NextToken))
  if body != nil:
    body_774333 = body
  add(query_774332, "MaxResults", newJString(MaxResults))
  result = call_774331.call(nil, query_774332, nil, nil, body_774333)

var listUserPools* = Call_ListUserPools_774316(name: "listUserPools",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUserPools",
    validator: validate_ListUserPools_774317, base: "/", url: url_ListUserPools_774318,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_774334 = ref object of OpenApiRestCall_772597
proc url_ListUsers_774336(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListUsers_774335(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the users in the Amazon Cognito user pool.
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
  var valid_774337 = header.getOrDefault("X-Amz-Date")
  valid_774337 = validateParameter(valid_774337, JString, required = false,
                                 default = nil)
  if valid_774337 != nil:
    section.add "X-Amz-Date", valid_774337
  var valid_774338 = header.getOrDefault("X-Amz-Security-Token")
  valid_774338 = validateParameter(valid_774338, JString, required = false,
                                 default = nil)
  if valid_774338 != nil:
    section.add "X-Amz-Security-Token", valid_774338
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774339 = header.getOrDefault("X-Amz-Target")
  valid_774339 = validateParameter(valid_774339, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUsers"))
  if valid_774339 != nil:
    section.add "X-Amz-Target", valid_774339
  var valid_774340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774340 = validateParameter(valid_774340, JString, required = false,
                                 default = nil)
  if valid_774340 != nil:
    section.add "X-Amz-Content-Sha256", valid_774340
  var valid_774341 = header.getOrDefault("X-Amz-Algorithm")
  valid_774341 = validateParameter(valid_774341, JString, required = false,
                                 default = nil)
  if valid_774341 != nil:
    section.add "X-Amz-Algorithm", valid_774341
  var valid_774342 = header.getOrDefault("X-Amz-Signature")
  valid_774342 = validateParameter(valid_774342, JString, required = false,
                                 default = nil)
  if valid_774342 != nil:
    section.add "X-Amz-Signature", valid_774342
  var valid_774343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774343 = validateParameter(valid_774343, JString, required = false,
                                 default = nil)
  if valid_774343 != nil:
    section.add "X-Amz-SignedHeaders", valid_774343
  var valid_774344 = header.getOrDefault("X-Amz-Credential")
  valid_774344 = validateParameter(valid_774344, JString, required = false,
                                 default = nil)
  if valid_774344 != nil:
    section.add "X-Amz-Credential", valid_774344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774346: Call_ListUsers_774334; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the users in the Amazon Cognito user pool.
  ## 
  let valid = call_774346.validator(path, query, header, formData, body)
  let scheme = call_774346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774346.url(scheme.get, call_774346.host, call_774346.base,
                         call_774346.route, valid.getOrDefault("path"))
  result = hook(call_774346, url, valid)

proc call*(call_774347: Call_ListUsers_774334; body: JsonNode): Recallable =
  ## listUsers
  ## Lists the users in the Amazon Cognito user pool.
  ##   body: JObject (required)
  var body_774348 = newJObject()
  if body != nil:
    body_774348 = body
  result = call_774347.call(nil, nil, nil, nil, body_774348)

var listUsers* = Call_ListUsers_774334(name: "listUsers", meth: HttpMethod.HttpPost,
                                    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUsers",
                                    validator: validate_ListUsers_774335,
                                    base: "/", url: url_ListUsers_774336,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsersInGroup_774349 = ref object of OpenApiRestCall_772597
proc url_ListUsersInGroup_774351(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListUsersInGroup_774350(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Lists the users in the specified group.</p> <p>Requires developer credentials.</p>
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
  var valid_774352 = query.getOrDefault("Limit")
  valid_774352 = validateParameter(valid_774352, JString, required = false,
                                 default = nil)
  if valid_774352 != nil:
    section.add "Limit", valid_774352
  var valid_774353 = query.getOrDefault("NextToken")
  valid_774353 = validateParameter(valid_774353, JString, required = false,
                                 default = nil)
  if valid_774353 != nil:
    section.add "NextToken", valid_774353
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
  var valid_774354 = header.getOrDefault("X-Amz-Date")
  valid_774354 = validateParameter(valid_774354, JString, required = false,
                                 default = nil)
  if valid_774354 != nil:
    section.add "X-Amz-Date", valid_774354
  var valid_774355 = header.getOrDefault("X-Amz-Security-Token")
  valid_774355 = validateParameter(valid_774355, JString, required = false,
                                 default = nil)
  if valid_774355 != nil:
    section.add "X-Amz-Security-Token", valid_774355
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774356 = header.getOrDefault("X-Amz-Target")
  valid_774356 = validateParameter(valid_774356, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUsersInGroup"))
  if valid_774356 != nil:
    section.add "X-Amz-Target", valid_774356
  var valid_774357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774357 = validateParameter(valid_774357, JString, required = false,
                                 default = nil)
  if valid_774357 != nil:
    section.add "X-Amz-Content-Sha256", valid_774357
  var valid_774358 = header.getOrDefault("X-Amz-Algorithm")
  valid_774358 = validateParameter(valid_774358, JString, required = false,
                                 default = nil)
  if valid_774358 != nil:
    section.add "X-Amz-Algorithm", valid_774358
  var valid_774359 = header.getOrDefault("X-Amz-Signature")
  valid_774359 = validateParameter(valid_774359, JString, required = false,
                                 default = nil)
  if valid_774359 != nil:
    section.add "X-Amz-Signature", valid_774359
  var valid_774360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774360 = validateParameter(valid_774360, JString, required = false,
                                 default = nil)
  if valid_774360 != nil:
    section.add "X-Amz-SignedHeaders", valid_774360
  var valid_774361 = header.getOrDefault("X-Amz-Credential")
  valid_774361 = validateParameter(valid_774361, JString, required = false,
                                 default = nil)
  if valid_774361 != nil:
    section.add "X-Amz-Credential", valid_774361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774363: Call_ListUsersInGroup_774349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the users in the specified group.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_774363.validator(path, query, header, formData, body)
  let scheme = call_774363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774363.url(scheme.get, call_774363.host, call_774363.base,
                         call_774363.route, valid.getOrDefault("path"))
  result = hook(call_774363, url, valid)

proc call*(call_774364: Call_ListUsersInGroup_774349; body: JsonNode;
          Limit: string = ""; NextToken: string = ""): Recallable =
  ## listUsersInGroup
  ## <p>Lists the users in the specified group.</p> <p>Requires developer credentials.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_774365 = newJObject()
  var body_774366 = newJObject()
  add(query_774365, "Limit", newJString(Limit))
  add(query_774365, "NextToken", newJString(NextToken))
  if body != nil:
    body_774366 = body
  result = call_774364.call(nil, query_774365, nil, nil, body_774366)

var listUsersInGroup* = Call_ListUsersInGroup_774349(name: "listUsersInGroup",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUsersInGroup",
    validator: validate_ListUsersInGroup_774350, base: "/",
    url: url_ListUsersInGroup_774351, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResendConfirmationCode_774367 = ref object of OpenApiRestCall_772597
proc url_ResendConfirmationCode_774369(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ResendConfirmationCode_774368(path: JsonNode; query: JsonNode;
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
  var valid_774370 = header.getOrDefault("X-Amz-Date")
  valid_774370 = validateParameter(valid_774370, JString, required = false,
                                 default = nil)
  if valid_774370 != nil:
    section.add "X-Amz-Date", valid_774370
  var valid_774371 = header.getOrDefault("X-Amz-Security-Token")
  valid_774371 = validateParameter(valid_774371, JString, required = false,
                                 default = nil)
  if valid_774371 != nil:
    section.add "X-Amz-Security-Token", valid_774371
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774372 = header.getOrDefault("X-Amz-Target")
  valid_774372 = validateParameter(valid_774372, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ResendConfirmationCode"))
  if valid_774372 != nil:
    section.add "X-Amz-Target", valid_774372
  var valid_774373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774373 = validateParameter(valid_774373, JString, required = false,
                                 default = nil)
  if valid_774373 != nil:
    section.add "X-Amz-Content-Sha256", valid_774373
  var valid_774374 = header.getOrDefault("X-Amz-Algorithm")
  valid_774374 = validateParameter(valid_774374, JString, required = false,
                                 default = nil)
  if valid_774374 != nil:
    section.add "X-Amz-Algorithm", valid_774374
  var valid_774375 = header.getOrDefault("X-Amz-Signature")
  valid_774375 = validateParameter(valid_774375, JString, required = false,
                                 default = nil)
  if valid_774375 != nil:
    section.add "X-Amz-Signature", valid_774375
  var valid_774376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774376 = validateParameter(valid_774376, JString, required = false,
                                 default = nil)
  if valid_774376 != nil:
    section.add "X-Amz-SignedHeaders", valid_774376
  var valid_774377 = header.getOrDefault("X-Amz-Credential")
  valid_774377 = validateParameter(valid_774377, JString, required = false,
                                 default = nil)
  if valid_774377 != nil:
    section.add "X-Amz-Credential", valid_774377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774379: Call_ResendConfirmationCode_774367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resends the confirmation (for confirmation of registration) to a specific user in the user pool.
  ## 
  let valid = call_774379.validator(path, query, header, formData, body)
  let scheme = call_774379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774379.url(scheme.get, call_774379.host, call_774379.base,
                         call_774379.route, valid.getOrDefault("path"))
  result = hook(call_774379, url, valid)

proc call*(call_774380: Call_ResendConfirmationCode_774367; body: JsonNode): Recallable =
  ## resendConfirmationCode
  ## Resends the confirmation (for confirmation of registration) to a specific user in the user pool.
  ##   body: JObject (required)
  var body_774381 = newJObject()
  if body != nil:
    body_774381 = body
  result = call_774380.call(nil, nil, nil, nil, body_774381)

var resendConfirmationCode* = Call_ResendConfirmationCode_774367(
    name: "resendConfirmationCode", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ResendConfirmationCode",
    validator: validate_ResendConfirmationCode_774368, base: "/",
    url: url_ResendConfirmationCode_774369, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RespondToAuthChallenge_774382 = ref object of OpenApiRestCall_772597
proc url_RespondToAuthChallenge_774384(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RespondToAuthChallenge_774383(path: JsonNode; query: JsonNode;
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
  var valid_774385 = header.getOrDefault("X-Amz-Date")
  valid_774385 = validateParameter(valid_774385, JString, required = false,
                                 default = nil)
  if valid_774385 != nil:
    section.add "X-Amz-Date", valid_774385
  var valid_774386 = header.getOrDefault("X-Amz-Security-Token")
  valid_774386 = validateParameter(valid_774386, JString, required = false,
                                 default = nil)
  if valid_774386 != nil:
    section.add "X-Amz-Security-Token", valid_774386
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774387 = header.getOrDefault("X-Amz-Target")
  valid_774387 = validateParameter(valid_774387, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.RespondToAuthChallenge"))
  if valid_774387 != nil:
    section.add "X-Amz-Target", valid_774387
  var valid_774388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774388 = validateParameter(valid_774388, JString, required = false,
                                 default = nil)
  if valid_774388 != nil:
    section.add "X-Amz-Content-Sha256", valid_774388
  var valid_774389 = header.getOrDefault("X-Amz-Algorithm")
  valid_774389 = validateParameter(valid_774389, JString, required = false,
                                 default = nil)
  if valid_774389 != nil:
    section.add "X-Amz-Algorithm", valid_774389
  var valid_774390 = header.getOrDefault("X-Amz-Signature")
  valid_774390 = validateParameter(valid_774390, JString, required = false,
                                 default = nil)
  if valid_774390 != nil:
    section.add "X-Amz-Signature", valid_774390
  var valid_774391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774391 = validateParameter(valid_774391, JString, required = false,
                                 default = nil)
  if valid_774391 != nil:
    section.add "X-Amz-SignedHeaders", valid_774391
  var valid_774392 = header.getOrDefault("X-Amz-Credential")
  valid_774392 = validateParameter(valid_774392, JString, required = false,
                                 default = nil)
  if valid_774392 != nil:
    section.add "X-Amz-Credential", valid_774392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774394: Call_RespondToAuthChallenge_774382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Responds to the authentication challenge.
  ## 
  let valid = call_774394.validator(path, query, header, formData, body)
  let scheme = call_774394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774394.url(scheme.get, call_774394.host, call_774394.base,
                         call_774394.route, valid.getOrDefault("path"))
  result = hook(call_774394, url, valid)

proc call*(call_774395: Call_RespondToAuthChallenge_774382; body: JsonNode): Recallable =
  ## respondToAuthChallenge
  ## Responds to the authentication challenge.
  ##   body: JObject (required)
  var body_774396 = newJObject()
  if body != nil:
    body_774396 = body
  result = call_774395.call(nil, nil, nil, nil, body_774396)

var respondToAuthChallenge* = Call_RespondToAuthChallenge_774382(
    name: "respondToAuthChallenge", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.RespondToAuthChallenge",
    validator: validate_RespondToAuthChallenge_774383, base: "/",
    url: url_RespondToAuthChallenge_774384, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetRiskConfiguration_774397 = ref object of OpenApiRestCall_772597
proc url_SetRiskConfiguration_774399(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SetRiskConfiguration_774398(path: JsonNode; query: JsonNode;
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
  var valid_774400 = header.getOrDefault("X-Amz-Date")
  valid_774400 = validateParameter(valid_774400, JString, required = false,
                                 default = nil)
  if valid_774400 != nil:
    section.add "X-Amz-Date", valid_774400
  var valid_774401 = header.getOrDefault("X-Amz-Security-Token")
  valid_774401 = validateParameter(valid_774401, JString, required = false,
                                 default = nil)
  if valid_774401 != nil:
    section.add "X-Amz-Security-Token", valid_774401
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774402 = header.getOrDefault("X-Amz-Target")
  valid_774402 = validateParameter(valid_774402, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetRiskConfiguration"))
  if valid_774402 != nil:
    section.add "X-Amz-Target", valid_774402
  var valid_774403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774403 = validateParameter(valid_774403, JString, required = false,
                                 default = nil)
  if valid_774403 != nil:
    section.add "X-Amz-Content-Sha256", valid_774403
  var valid_774404 = header.getOrDefault("X-Amz-Algorithm")
  valid_774404 = validateParameter(valid_774404, JString, required = false,
                                 default = nil)
  if valid_774404 != nil:
    section.add "X-Amz-Algorithm", valid_774404
  var valid_774405 = header.getOrDefault("X-Amz-Signature")
  valid_774405 = validateParameter(valid_774405, JString, required = false,
                                 default = nil)
  if valid_774405 != nil:
    section.add "X-Amz-Signature", valid_774405
  var valid_774406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774406 = validateParameter(valid_774406, JString, required = false,
                                 default = nil)
  if valid_774406 != nil:
    section.add "X-Amz-SignedHeaders", valid_774406
  var valid_774407 = header.getOrDefault("X-Amz-Credential")
  valid_774407 = validateParameter(valid_774407, JString, required = false,
                                 default = nil)
  if valid_774407 != nil:
    section.add "X-Amz-Credential", valid_774407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774409: Call_SetRiskConfiguration_774397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configures actions on detected risks. To delete the risk configuration for <code>UserPoolId</code> or <code>ClientId</code>, pass null values for all four configuration types.</p> <p>To enable Amazon Cognito advanced security features, update the user pool to include the <code>UserPoolAddOns</code> key<code>AdvancedSecurityMode</code>.</p> <p>See .</p>
  ## 
  let valid = call_774409.validator(path, query, header, formData, body)
  let scheme = call_774409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774409.url(scheme.get, call_774409.host, call_774409.base,
                         call_774409.route, valid.getOrDefault("path"))
  result = hook(call_774409, url, valid)

proc call*(call_774410: Call_SetRiskConfiguration_774397; body: JsonNode): Recallable =
  ## setRiskConfiguration
  ## <p>Configures actions on detected risks. To delete the risk configuration for <code>UserPoolId</code> or <code>ClientId</code>, pass null values for all four configuration types.</p> <p>To enable Amazon Cognito advanced security features, update the user pool to include the <code>UserPoolAddOns</code> key<code>AdvancedSecurityMode</code>.</p> <p>See .</p>
  ##   body: JObject (required)
  var body_774411 = newJObject()
  if body != nil:
    body_774411 = body
  result = call_774410.call(nil, nil, nil, nil, body_774411)

var setRiskConfiguration* = Call_SetRiskConfiguration_774397(
    name: "setRiskConfiguration", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetRiskConfiguration",
    validator: validate_SetRiskConfiguration_774398, base: "/",
    url: url_SetRiskConfiguration_774399, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUICustomization_774412 = ref object of OpenApiRestCall_772597
proc url_SetUICustomization_774414(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SetUICustomization_774413(path: JsonNode; query: JsonNode;
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
  var valid_774415 = header.getOrDefault("X-Amz-Date")
  valid_774415 = validateParameter(valid_774415, JString, required = false,
                                 default = nil)
  if valid_774415 != nil:
    section.add "X-Amz-Date", valid_774415
  var valid_774416 = header.getOrDefault("X-Amz-Security-Token")
  valid_774416 = validateParameter(valid_774416, JString, required = false,
                                 default = nil)
  if valid_774416 != nil:
    section.add "X-Amz-Security-Token", valid_774416
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774417 = header.getOrDefault("X-Amz-Target")
  valid_774417 = validateParameter(valid_774417, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUICustomization"))
  if valid_774417 != nil:
    section.add "X-Amz-Target", valid_774417
  var valid_774418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774418 = validateParameter(valid_774418, JString, required = false,
                                 default = nil)
  if valid_774418 != nil:
    section.add "X-Amz-Content-Sha256", valid_774418
  var valid_774419 = header.getOrDefault("X-Amz-Algorithm")
  valid_774419 = validateParameter(valid_774419, JString, required = false,
                                 default = nil)
  if valid_774419 != nil:
    section.add "X-Amz-Algorithm", valid_774419
  var valid_774420 = header.getOrDefault("X-Amz-Signature")
  valid_774420 = validateParameter(valid_774420, JString, required = false,
                                 default = nil)
  if valid_774420 != nil:
    section.add "X-Amz-Signature", valid_774420
  var valid_774421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774421 = validateParameter(valid_774421, JString, required = false,
                                 default = nil)
  if valid_774421 != nil:
    section.add "X-Amz-SignedHeaders", valid_774421
  var valid_774422 = header.getOrDefault("X-Amz-Credential")
  valid_774422 = validateParameter(valid_774422, JString, required = false,
                                 default = nil)
  if valid_774422 != nil:
    section.add "X-Amz-Credential", valid_774422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774424: Call_SetUICustomization_774412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the UI customization information for a user pool's built-in app UI.</p> <p>You can specify app UI customization settings for a single client (with a specific <code>clientId</code>) or for all clients (by setting the <code>clientId</code> to <code>ALL</code>). If you specify <code>ALL</code>, the default configuration will be used for every client that has no UI customization set previously. If you specify UI customization settings for a particular client, it will no longer fall back to the <code>ALL</code> configuration. </p> <note> <p>To use this API, your user pool must have a domain associated with it. Otherwise, there is no place to host the app's pages, and the service will throw an error.</p> </note>
  ## 
  let valid = call_774424.validator(path, query, header, formData, body)
  let scheme = call_774424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774424.url(scheme.get, call_774424.host, call_774424.base,
                         call_774424.route, valid.getOrDefault("path"))
  result = hook(call_774424, url, valid)

proc call*(call_774425: Call_SetUICustomization_774412; body: JsonNode): Recallable =
  ## setUICustomization
  ## <p>Sets the UI customization information for a user pool's built-in app UI.</p> <p>You can specify app UI customization settings for a single client (with a specific <code>clientId</code>) or for all clients (by setting the <code>clientId</code> to <code>ALL</code>). If you specify <code>ALL</code>, the default configuration will be used for every client that has no UI customization set previously. If you specify UI customization settings for a particular client, it will no longer fall back to the <code>ALL</code> configuration. </p> <note> <p>To use this API, your user pool must have a domain associated with it. Otherwise, there is no place to host the app's pages, and the service will throw an error.</p> </note>
  ##   body: JObject (required)
  var body_774426 = newJObject()
  if body != nil:
    body_774426 = body
  result = call_774425.call(nil, nil, nil, nil, body_774426)

var setUICustomization* = Call_SetUICustomization_774412(
    name: "setUICustomization", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUICustomization",
    validator: validate_SetUICustomization_774413, base: "/",
    url: url_SetUICustomization_774414, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUserMFAPreference_774427 = ref object of OpenApiRestCall_772597
proc url_SetUserMFAPreference_774429(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SetUserMFAPreference_774428(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Set the user's multi-factor authentication (MFA) method preference.
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
  var valid_774430 = header.getOrDefault("X-Amz-Date")
  valid_774430 = validateParameter(valid_774430, JString, required = false,
                                 default = nil)
  if valid_774430 != nil:
    section.add "X-Amz-Date", valid_774430
  var valid_774431 = header.getOrDefault("X-Amz-Security-Token")
  valid_774431 = validateParameter(valid_774431, JString, required = false,
                                 default = nil)
  if valid_774431 != nil:
    section.add "X-Amz-Security-Token", valid_774431
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774432 = header.getOrDefault("X-Amz-Target")
  valid_774432 = validateParameter(valid_774432, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUserMFAPreference"))
  if valid_774432 != nil:
    section.add "X-Amz-Target", valid_774432
  var valid_774433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774433 = validateParameter(valid_774433, JString, required = false,
                                 default = nil)
  if valid_774433 != nil:
    section.add "X-Amz-Content-Sha256", valid_774433
  var valid_774434 = header.getOrDefault("X-Amz-Algorithm")
  valid_774434 = validateParameter(valid_774434, JString, required = false,
                                 default = nil)
  if valid_774434 != nil:
    section.add "X-Amz-Algorithm", valid_774434
  var valid_774435 = header.getOrDefault("X-Amz-Signature")
  valid_774435 = validateParameter(valid_774435, JString, required = false,
                                 default = nil)
  if valid_774435 != nil:
    section.add "X-Amz-Signature", valid_774435
  var valid_774436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774436 = validateParameter(valid_774436, JString, required = false,
                                 default = nil)
  if valid_774436 != nil:
    section.add "X-Amz-SignedHeaders", valid_774436
  var valid_774437 = header.getOrDefault("X-Amz-Credential")
  valid_774437 = validateParameter(valid_774437, JString, required = false,
                                 default = nil)
  if valid_774437 != nil:
    section.add "X-Amz-Credential", valid_774437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774439: Call_SetUserMFAPreference_774427; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the user's multi-factor authentication (MFA) method preference.
  ## 
  let valid = call_774439.validator(path, query, header, formData, body)
  let scheme = call_774439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774439.url(scheme.get, call_774439.host, call_774439.base,
                         call_774439.route, valid.getOrDefault("path"))
  result = hook(call_774439, url, valid)

proc call*(call_774440: Call_SetUserMFAPreference_774427; body: JsonNode): Recallable =
  ## setUserMFAPreference
  ## Set the user's multi-factor authentication (MFA) method preference.
  ##   body: JObject (required)
  var body_774441 = newJObject()
  if body != nil:
    body_774441 = body
  result = call_774440.call(nil, nil, nil, nil, body_774441)

var setUserMFAPreference* = Call_SetUserMFAPreference_774427(
    name: "setUserMFAPreference", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUserMFAPreference",
    validator: validate_SetUserMFAPreference_774428, base: "/",
    url: url_SetUserMFAPreference_774429, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUserPoolMfaConfig_774442 = ref object of OpenApiRestCall_772597
proc url_SetUserPoolMfaConfig_774444(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SetUserPoolMfaConfig_774443(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Set the user pool MFA configuration.
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
  var valid_774445 = header.getOrDefault("X-Amz-Date")
  valid_774445 = validateParameter(valid_774445, JString, required = false,
                                 default = nil)
  if valid_774445 != nil:
    section.add "X-Amz-Date", valid_774445
  var valid_774446 = header.getOrDefault("X-Amz-Security-Token")
  valid_774446 = validateParameter(valid_774446, JString, required = false,
                                 default = nil)
  if valid_774446 != nil:
    section.add "X-Amz-Security-Token", valid_774446
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774447 = header.getOrDefault("X-Amz-Target")
  valid_774447 = validateParameter(valid_774447, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUserPoolMfaConfig"))
  if valid_774447 != nil:
    section.add "X-Amz-Target", valid_774447
  var valid_774448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774448 = validateParameter(valid_774448, JString, required = false,
                                 default = nil)
  if valid_774448 != nil:
    section.add "X-Amz-Content-Sha256", valid_774448
  var valid_774449 = header.getOrDefault("X-Amz-Algorithm")
  valid_774449 = validateParameter(valid_774449, JString, required = false,
                                 default = nil)
  if valid_774449 != nil:
    section.add "X-Amz-Algorithm", valid_774449
  var valid_774450 = header.getOrDefault("X-Amz-Signature")
  valid_774450 = validateParameter(valid_774450, JString, required = false,
                                 default = nil)
  if valid_774450 != nil:
    section.add "X-Amz-Signature", valid_774450
  var valid_774451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774451 = validateParameter(valid_774451, JString, required = false,
                                 default = nil)
  if valid_774451 != nil:
    section.add "X-Amz-SignedHeaders", valid_774451
  var valid_774452 = header.getOrDefault("X-Amz-Credential")
  valid_774452 = validateParameter(valid_774452, JString, required = false,
                                 default = nil)
  if valid_774452 != nil:
    section.add "X-Amz-Credential", valid_774452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774454: Call_SetUserPoolMfaConfig_774442; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the user pool MFA configuration.
  ## 
  let valid = call_774454.validator(path, query, header, formData, body)
  let scheme = call_774454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774454.url(scheme.get, call_774454.host, call_774454.base,
                         call_774454.route, valid.getOrDefault("path"))
  result = hook(call_774454, url, valid)

proc call*(call_774455: Call_SetUserPoolMfaConfig_774442; body: JsonNode): Recallable =
  ## setUserPoolMfaConfig
  ## Set the user pool MFA configuration.
  ##   body: JObject (required)
  var body_774456 = newJObject()
  if body != nil:
    body_774456 = body
  result = call_774455.call(nil, nil, nil, nil, body_774456)

var setUserPoolMfaConfig* = Call_SetUserPoolMfaConfig_774442(
    name: "setUserPoolMfaConfig", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUserPoolMfaConfig",
    validator: validate_SetUserPoolMfaConfig_774443, base: "/",
    url: url_SetUserPoolMfaConfig_774444, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUserSettings_774457 = ref object of OpenApiRestCall_772597
proc url_SetUserSettings_774459(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SetUserSettings_774458(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Sets the user settings like multi-factor authentication (MFA). If MFA is to be removed for a particular attribute pass the attribute with code delivery as null. If null list is passed, all MFA options are removed.
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
  var valid_774460 = header.getOrDefault("X-Amz-Date")
  valid_774460 = validateParameter(valid_774460, JString, required = false,
                                 default = nil)
  if valid_774460 != nil:
    section.add "X-Amz-Date", valid_774460
  var valid_774461 = header.getOrDefault("X-Amz-Security-Token")
  valid_774461 = validateParameter(valid_774461, JString, required = false,
                                 default = nil)
  if valid_774461 != nil:
    section.add "X-Amz-Security-Token", valid_774461
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774462 = header.getOrDefault("X-Amz-Target")
  valid_774462 = validateParameter(valid_774462, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUserSettings"))
  if valid_774462 != nil:
    section.add "X-Amz-Target", valid_774462
  var valid_774463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774463 = validateParameter(valid_774463, JString, required = false,
                                 default = nil)
  if valid_774463 != nil:
    section.add "X-Amz-Content-Sha256", valid_774463
  var valid_774464 = header.getOrDefault("X-Amz-Algorithm")
  valid_774464 = validateParameter(valid_774464, JString, required = false,
                                 default = nil)
  if valid_774464 != nil:
    section.add "X-Amz-Algorithm", valid_774464
  var valid_774465 = header.getOrDefault("X-Amz-Signature")
  valid_774465 = validateParameter(valid_774465, JString, required = false,
                                 default = nil)
  if valid_774465 != nil:
    section.add "X-Amz-Signature", valid_774465
  var valid_774466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774466 = validateParameter(valid_774466, JString, required = false,
                                 default = nil)
  if valid_774466 != nil:
    section.add "X-Amz-SignedHeaders", valid_774466
  var valid_774467 = header.getOrDefault("X-Amz-Credential")
  valid_774467 = validateParameter(valid_774467, JString, required = false,
                                 default = nil)
  if valid_774467 != nil:
    section.add "X-Amz-Credential", valid_774467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774469: Call_SetUserSettings_774457; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the user settings like multi-factor authentication (MFA). If MFA is to be removed for a particular attribute pass the attribute with code delivery as null. If null list is passed, all MFA options are removed.
  ## 
  let valid = call_774469.validator(path, query, header, formData, body)
  let scheme = call_774469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774469.url(scheme.get, call_774469.host, call_774469.base,
                         call_774469.route, valid.getOrDefault("path"))
  result = hook(call_774469, url, valid)

proc call*(call_774470: Call_SetUserSettings_774457; body: JsonNode): Recallable =
  ## setUserSettings
  ## Sets the user settings like multi-factor authentication (MFA). If MFA is to be removed for a particular attribute pass the attribute with code delivery as null. If null list is passed, all MFA options are removed.
  ##   body: JObject (required)
  var body_774471 = newJObject()
  if body != nil:
    body_774471 = body
  result = call_774470.call(nil, nil, nil, nil, body_774471)

var setUserSettings* = Call_SetUserSettings_774457(name: "setUserSettings",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUserSettings",
    validator: validate_SetUserSettings_774458, base: "/", url: url_SetUserSettings_774459,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SignUp_774472 = ref object of OpenApiRestCall_772597
proc url_SignUp_774474(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SignUp_774473(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774475 = header.getOrDefault("X-Amz-Date")
  valid_774475 = validateParameter(valid_774475, JString, required = false,
                                 default = nil)
  if valid_774475 != nil:
    section.add "X-Amz-Date", valid_774475
  var valid_774476 = header.getOrDefault("X-Amz-Security-Token")
  valid_774476 = validateParameter(valid_774476, JString, required = false,
                                 default = nil)
  if valid_774476 != nil:
    section.add "X-Amz-Security-Token", valid_774476
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774477 = header.getOrDefault("X-Amz-Target")
  valid_774477 = validateParameter(valid_774477, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SignUp"))
  if valid_774477 != nil:
    section.add "X-Amz-Target", valid_774477
  var valid_774478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774478 = validateParameter(valid_774478, JString, required = false,
                                 default = nil)
  if valid_774478 != nil:
    section.add "X-Amz-Content-Sha256", valid_774478
  var valid_774479 = header.getOrDefault("X-Amz-Algorithm")
  valid_774479 = validateParameter(valid_774479, JString, required = false,
                                 default = nil)
  if valid_774479 != nil:
    section.add "X-Amz-Algorithm", valid_774479
  var valid_774480 = header.getOrDefault("X-Amz-Signature")
  valid_774480 = validateParameter(valid_774480, JString, required = false,
                                 default = nil)
  if valid_774480 != nil:
    section.add "X-Amz-Signature", valid_774480
  var valid_774481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774481 = validateParameter(valid_774481, JString, required = false,
                                 default = nil)
  if valid_774481 != nil:
    section.add "X-Amz-SignedHeaders", valid_774481
  var valid_774482 = header.getOrDefault("X-Amz-Credential")
  valid_774482 = validateParameter(valid_774482, JString, required = false,
                                 default = nil)
  if valid_774482 != nil:
    section.add "X-Amz-Credential", valid_774482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774484: Call_SignUp_774472; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers the user in the specified user pool and creates a user name, password, and user attributes.
  ## 
  let valid = call_774484.validator(path, query, header, formData, body)
  let scheme = call_774484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774484.url(scheme.get, call_774484.host, call_774484.base,
                         call_774484.route, valid.getOrDefault("path"))
  result = hook(call_774484, url, valid)

proc call*(call_774485: Call_SignUp_774472; body: JsonNode): Recallable =
  ## signUp
  ## Registers the user in the specified user pool and creates a user name, password, and user attributes.
  ##   body: JObject (required)
  var body_774486 = newJObject()
  if body != nil:
    body_774486 = body
  result = call_774485.call(nil, nil, nil, nil, body_774486)

var signUp* = Call_SignUp_774472(name: "signUp", meth: HttpMethod.HttpPost,
                              host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SignUp",
                              validator: validate_SignUp_774473, base: "/",
                              url: url_SignUp_774474,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartUserImportJob_774487 = ref object of OpenApiRestCall_772597
proc url_StartUserImportJob_774489(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartUserImportJob_774488(path: JsonNode; query: JsonNode;
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
  var valid_774490 = header.getOrDefault("X-Amz-Date")
  valid_774490 = validateParameter(valid_774490, JString, required = false,
                                 default = nil)
  if valid_774490 != nil:
    section.add "X-Amz-Date", valid_774490
  var valid_774491 = header.getOrDefault("X-Amz-Security-Token")
  valid_774491 = validateParameter(valid_774491, JString, required = false,
                                 default = nil)
  if valid_774491 != nil:
    section.add "X-Amz-Security-Token", valid_774491
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774492 = header.getOrDefault("X-Amz-Target")
  valid_774492 = validateParameter(valid_774492, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.StartUserImportJob"))
  if valid_774492 != nil:
    section.add "X-Amz-Target", valid_774492
  var valid_774493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774493 = validateParameter(valid_774493, JString, required = false,
                                 default = nil)
  if valid_774493 != nil:
    section.add "X-Amz-Content-Sha256", valid_774493
  var valid_774494 = header.getOrDefault("X-Amz-Algorithm")
  valid_774494 = validateParameter(valid_774494, JString, required = false,
                                 default = nil)
  if valid_774494 != nil:
    section.add "X-Amz-Algorithm", valid_774494
  var valid_774495 = header.getOrDefault("X-Amz-Signature")
  valid_774495 = validateParameter(valid_774495, JString, required = false,
                                 default = nil)
  if valid_774495 != nil:
    section.add "X-Amz-Signature", valid_774495
  var valid_774496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774496 = validateParameter(valid_774496, JString, required = false,
                                 default = nil)
  if valid_774496 != nil:
    section.add "X-Amz-SignedHeaders", valid_774496
  var valid_774497 = header.getOrDefault("X-Amz-Credential")
  valid_774497 = validateParameter(valid_774497, JString, required = false,
                                 default = nil)
  if valid_774497 != nil:
    section.add "X-Amz-Credential", valid_774497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774499: Call_StartUserImportJob_774487; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the user import.
  ## 
  let valid = call_774499.validator(path, query, header, formData, body)
  let scheme = call_774499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774499.url(scheme.get, call_774499.host, call_774499.base,
                         call_774499.route, valid.getOrDefault("path"))
  result = hook(call_774499, url, valid)

proc call*(call_774500: Call_StartUserImportJob_774487; body: JsonNode): Recallable =
  ## startUserImportJob
  ## Starts the user import.
  ##   body: JObject (required)
  var body_774501 = newJObject()
  if body != nil:
    body_774501 = body
  result = call_774500.call(nil, nil, nil, nil, body_774501)

var startUserImportJob* = Call_StartUserImportJob_774487(
    name: "startUserImportJob", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.StartUserImportJob",
    validator: validate_StartUserImportJob_774488, base: "/",
    url: url_StartUserImportJob_774489, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopUserImportJob_774502 = ref object of OpenApiRestCall_772597
proc url_StopUserImportJob_774504(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopUserImportJob_774503(path: JsonNode; query: JsonNode;
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
  var valid_774505 = header.getOrDefault("X-Amz-Date")
  valid_774505 = validateParameter(valid_774505, JString, required = false,
                                 default = nil)
  if valid_774505 != nil:
    section.add "X-Amz-Date", valid_774505
  var valid_774506 = header.getOrDefault("X-Amz-Security-Token")
  valid_774506 = validateParameter(valid_774506, JString, required = false,
                                 default = nil)
  if valid_774506 != nil:
    section.add "X-Amz-Security-Token", valid_774506
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774507 = header.getOrDefault("X-Amz-Target")
  valid_774507 = validateParameter(valid_774507, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.StopUserImportJob"))
  if valid_774507 != nil:
    section.add "X-Amz-Target", valid_774507
  var valid_774508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774508 = validateParameter(valid_774508, JString, required = false,
                                 default = nil)
  if valid_774508 != nil:
    section.add "X-Amz-Content-Sha256", valid_774508
  var valid_774509 = header.getOrDefault("X-Amz-Algorithm")
  valid_774509 = validateParameter(valid_774509, JString, required = false,
                                 default = nil)
  if valid_774509 != nil:
    section.add "X-Amz-Algorithm", valid_774509
  var valid_774510 = header.getOrDefault("X-Amz-Signature")
  valid_774510 = validateParameter(valid_774510, JString, required = false,
                                 default = nil)
  if valid_774510 != nil:
    section.add "X-Amz-Signature", valid_774510
  var valid_774511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774511 = validateParameter(valid_774511, JString, required = false,
                                 default = nil)
  if valid_774511 != nil:
    section.add "X-Amz-SignedHeaders", valid_774511
  var valid_774512 = header.getOrDefault("X-Amz-Credential")
  valid_774512 = validateParameter(valid_774512, JString, required = false,
                                 default = nil)
  if valid_774512 != nil:
    section.add "X-Amz-Credential", valid_774512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774514: Call_StopUserImportJob_774502; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the user import job.
  ## 
  let valid = call_774514.validator(path, query, header, formData, body)
  let scheme = call_774514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774514.url(scheme.get, call_774514.host, call_774514.base,
                         call_774514.route, valid.getOrDefault("path"))
  result = hook(call_774514, url, valid)

proc call*(call_774515: Call_StopUserImportJob_774502; body: JsonNode): Recallable =
  ## stopUserImportJob
  ## Stops the user import job.
  ##   body: JObject (required)
  var body_774516 = newJObject()
  if body != nil:
    body_774516 = body
  result = call_774515.call(nil, nil, nil, nil, body_774516)

var stopUserImportJob* = Call_StopUserImportJob_774502(name: "stopUserImportJob",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.StopUserImportJob",
    validator: validate_StopUserImportJob_774503, base: "/",
    url: url_StopUserImportJob_774504, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_774517 = ref object of OpenApiRestCall_772597
proc url_TagResource_774519(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_774518(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774520 = header.getOrDefault("X-Amz-Date")
  valid_774520 = validateParameter(valid_774520, JString, required = false,
                                 default = nil)
  if valid_774520 != nil:
    section.add "X-Amz-Date", valid_774520
  var valid_774521 = header.getOrDefault("X-Amz-Security-Token")
  valid_774521 = validateParameter(valid_774521, JString, required = false,
                                 default = nil)
  if valid_774521 != nil:
    section.add "X-Amz-Security-Token", valid_774521
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774522 = header.getOrDefault("X-Amz-Target")
  valid_774522 = validateParameter(valid_774522, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.TagResource"))
  if valid_774522 != nil:
    section.add "X-Amz-Target", valid_774522
  var valid_774523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774523 = validateParameter(valid_774523, JString, required = false,
                                 default = nil)
  if valid_774523 != nil:
    section.add "X-Amz-Content-Sha256", valid_774523
  var valid_774524 = header.getOrDefault("X-Amz-Algorithm")
  valid_774524 = validateParameter(valid_774524, JString, required = false,
                                 default = nil)
  if valid_774524 != nil:
    section.add "X-Amz-Algorithm", valid_774524
  var valid_774525 = header.getOrDefault("X-Amz-Signature")
  valid_774525 = validateParameter(valid_774525, JString, required = false,
                                 default = nil)
  if valid_774525 != nil:
    section.add "X-Amz-Signature", valid_774525
  var valid_774526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774526 = validateParameter(valid_774526, JString, required = false,
                                 default = nil)
  if valid_774526 != nil:
    section.add "X-Amz-SignedHeaders", valid_774526
  var valid_774527 = header.getOrDefault("X-Amz-Credential")
  valid_774527 = validateParameter(valid_774527, JString, required = false,
                                 default = nil)
  if valid_774527 != nil:
    section.add "X-Amz-Credential", valid_774527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774529: Call_TagResource_774517; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns a set of tags to an Amazon Cognito user pool. A tag is a label that you can use to categorize and manage user pools in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>Each tag consists of a key and value, both of which you define. A key is a general category for more specific values. For example, if you have two versions of a user pool, one for testing and another for production, you might assign an <code>Environment</code> tag key to both user pools. The value of this key might be <code>Test</code> for one user pool and <code>Production</code> for the other.</p> <p>Tags are useful for cost tracking and access control. You can activate your tags so that they appear on the Billing and Cost Management console, where you can track the costs associated with your user pools. In an IAM policy, you can constrain permissions for user pools based on specific tags or tag values.</p> <p>You can use this action up to 5 times per second, per account. A user pool can have as many as 50 tags.</p>
  ## 
  let valid = call_774529.validator(path, query, header, formData, body)
  let scheme = call_774529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774529.url(scheme.get, call_774529.host, call_774529.base,
                         call_774529.route, valid.getOrDefault("path"))
  result = hook(call_774529, url, valid)

proc call*(call_774530: Call_TagResource_774517; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Assigns a set of tags to an Amazon Cognito user pool. A tag is a label that you can use to categorize and manage user pools in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>Each tag consists of a key and value, both of which you define. A key is a general category for more specific values. For example, if you have two versions of a user pool, one for testing and another for production, you might assign an <code>Environment</code> tag key to both user pools. The value of this key might be <code>Test</code> for one user pool and <code>Production</code> for the other.</p> <p>Tags are useful for cost tracking and access control. You can activate your tags so that they appear on the Billing and Cost Management console, where you can track the costs associated with your user pools. In an IAM policy, you can constrain permissions for user pools based on specific tags or tag values.</p> <p>You can use this action up to 5 times per second, per account. A user pool can have as many as 50 tags.</p>
  ##   body: JObject (required)
  var body_774531 = newJObject()
  if body != nil:
    body_774531 = body
  result = call_774530.call(nil, nil, nil, nil, body_774531)

var tagResource* = Call_TagResource_774517(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.TagResource",
                                        validator: validate_TagResource_774518,
                                        base: "/", url: url_TagResource_774519,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_774532 = ref object of OpenApiRestCall_772597
proc url_UntagResource_774534(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_774533(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774535 = header.getOrDefault("X-Amz-Date")
  valid_774535 = validateParameter(valid_774535, JString, required = false,
                                 default = nil)
  if valid_774535 != nil:
    section.add "X-Amz-Date", valid_774535
  var valid_774536 = header.getOrDefault("X-Amz-Security-Token")
  valid_774536 = validateParameter(valid_774536, JString, required = false,
                                 default = nil)
  if valid_774536 != nil:
    section.add "X-Amz-Security-Token", valid_774536
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774537 = header.getOrDefault("X-Amz-Target")
  valid_774537 = validateParameter(valid_774537, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UntagResource"))
  if valid_774537 != nil:
    section.add "X-Amz-Target", valid_774537
  var valid_774538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774538 = validateParameter(valid_774538, JString, required = false,
                                 default = nil)
  if valid_774538 != nil:
    section.add "X-Amz-Content-Sha256", valid_774538
  var valid_774539 = header.getOrDefault("X-Amz-Algorithm")
  valid_774539 = validateParameter(valid_774539, JString, required = false,
                                 default = nil)
  if valid_774539 != nil:
    section.add "X-Amz-Algorithm", valid_774539
  var valid_774540 = header.getOrDefault("X-Amz-Signature")
  valid_774540 = validateParameter(valid_774540, JString, required = false,
                                 default = nil)
  if valid_774540 != nil:
    section.add "X-Amz-Signature", valid_774540
  var valid_774541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774541 = validateParameter(valid_774541, JString, required = false,
                                 default = nil)
  if valid_774541 != nil:
    section.add "X-Amz-SignedHeaders", valid_774541
  var valid_774542 = header.getOrDefault("X-Amz-Credential")
  valid_774542 = validateParameter(valid_774542, JString, required = false,
                                 default = nil)
  if valid_774542 != nil:
    section.add "X-Amz-Credential", valid_774542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774544: Call_UntagResource_774532; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified tags from an Amazon Cognito user pool. You can use this action up to 5 times per second, per account
  ## 
  let valid = call_774544.validator(path, query, header, formData, body)
  let scheme = call_774544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774544.url(scheme.get, call_774544.host, call_774544.base,
                         call_774544.route, valid.getOrDefault("path"))
  result = hook(call_774544, url, valid)

proc call*(call_774545: Call_UntagResource_774532; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tags from an Amazon Cognito user pool. You can use this action up to 5 times per second, per account
  ##   body: JObject (required)
  var body_774546 = newJObject()
  if body != nil:
    body_774546 = body
  result = call_774545.call(nil, nil, nil, nil, body_774546)

var untagResource* = Call_UntagResource_774532(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UntagResource",
    validator: validate_UntagResource_774533, base: "/", url: url_UntagResource_774534,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthEventFeedback_774547 = ref object of OpenApiRestCall_772597
proc url_UpdateAuthEventFeedback_774549(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateAuthEventFeedback_774548(path: JsonNode; query: JsonNode;
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
  var valid_774550 = header.getOrDefault("X-Amz-Date")
  valid_774550 = validateParameter(valid_774550, JString, required = false,
                                 default = nil)
  if valid_774550 != nil:
    section.add "X-Amz-Date", valid_774550
  var valid_774551 = header.getOrDefault("X-Amz-Security-Token")
  valid_774551 = validateParameter(valid_774551, JString, required = false,
                                 default = nil)
  if valid_774551 != nil:
    section.add "X-Amz-Security-Token", valid_774551
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774552 = header.getOrDefault("X-Amz-Target")
  valid_774552 = validateParameter(valid_774552, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateAuthEventFeedback"))
  if valid_774552 != nil:
    section.add "X-Amz-Target", valid_774552
  var valid_774553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774553 = validateParameter(valid_774553, JString, required = false,
                                 default = nil)
  if valid_774553 != nil:
    section.add "X-Amz-Content-Sha256", valid_774553
  var valid_774554 = header.getOrDefault("X-Amz-Algorithm")
  valid_774554 = validateParameter(valid_774554, JString, required = false,
                                 default = nil)
  if valid_774554 != nil:
    section.add "X-Amz-Algorithm", valid_774554
  var valid_774555 = header.getOrDefault("X-Amz-Signature")
  valid_774555 = validateParameter(valid_774555, JString, required = false,
                                 default = nil)
  if valid_774555 != nil:
    section.add "X-Amz-Signature", valid_774555
  var valid_774556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774556 = validateParameter(valid_774556, JString, required = false,
                                 default = nil)
  if valid_774556 != nil:
    section.add "X-Amz-SignedHeaders", valid_774556
  var valid_774557 = header.getOrDefault("X-Amz-Credential")
  valid_774557 = validateParameter(valid_774557, JString, required = false,
                                 default = nil)
  if valid_774557 != nil:
    section.add "X-Amz-Credential", valid_774557
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774559: Call_UpdateAuthEventFeedback_774547; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the feedback for an authentication event whether it was from a valid user or not. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ## 
  let valid = call_774559.validator(path, query, header, formData, body)
  let scheme = call_774559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774559.url(scheme.get, call_774559.host, call_774559.base,
                         call_774559.route, valid.getOrDefault("path"))
  result = hook(call_774559, url, valid)

proc call*(call_774560: Call_UpdateAuthEventFeedback_774547; body: JsonNode): Recallable =
  ## updateAuthEventFeedback
  ## Provides the feedback for an authentication event whether it was from a valid user or not. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ##   body: JObject (required)
  var body_774561 = newJObject()
  if body != nil:
    body_774561 = body
  result = call_774560.call(nil, nil, nil, nil, body_774561)

var updateAuthEventFeedback* = Call_UpdateAuthEventFeedback_774547(
    name: "updateAuthEventFeedback", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateAuthEventFeedback",
    validator: validate_UpdateAuthEventFeedback_774548, base: "/",
    url: url_UpdateAuthEventFeedback_774549, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceStatus_774562 = ref object of OpenApiRestCall_772597
proc url_UpdateDeviceStatus_774564(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateDeviceStatus_774563(path: JsonNode; query: JsonNode;
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
  var valid_774565 = header.getOrDefault("X-Amz-Date")
  valid_774565 = validateParameter(valid_774565, JString, required = false,
                                 default = nil)
  if valid_774565 != nil:
    section.add "X-Amz-Date", valid_774565
  var valid_774566 = header.getOrDefault("X-Amz-Security-Token")
  valid_774566 = validateParameter(valid_774566, JString, required = false,
                                 default = nil)
  if valid_774566 != nil:
    section.add "X-Amz-Security-Token", valid_774566
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774567 = header.getOrDefault("X-Amz-Target")
  valid_774567 = validateParameter(valid_774567, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateDeviceStatus"))
  if valid_774567 != nil:
    section.add "X-Amz-Target", valid_774567
  var valid_774568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774568 = validateParameter(valid_774568, JString, required = false,
                                 default = nil)
  if valid_774568 != nil:
    section.add "X-Amz-Content-Sha256", valid_774568
  var valid_774569 = header.getOrDefault("X-Amz-Algorithm")
  valid_774569 = validateParameter(valid_774569, JString, required = false,
                                 default = nil)
  if valid_774569 != nil:
    section.add "X-Amz-Algorithm", valid_774569
  var valid_774570 = header.getOrDefault("X-Amz-Signature")
  valid_774570 = validateParameter(valid_774570, JString, required = false,
                                 default = nil)
  if valid_774570 != nil:
    section.add "X-Amz-Signature", valid_774570
  var valid_774571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774571 = validateParameter(valid_774571, JString, required = false,
                                 default = nil)
  if valid_774571 != nil:
    section.add "X-Amz-SignedHeaders", valid_774571
  var valid_774572 = header.getOrDefault("X-Amz-Credential")
  valid_774572 = validateParameter(valid_774572, JString, required = false,
                                 default = nil)
  if valid_774572 != nil:
    section.add "X-Amz-Credential", valid_774572
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774574: Call_UpdateDeviceStatus_774562; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the device status.
  ## 
  let valid = call_774574.validator(path, query, header, formData, body)
  let scheme = call_774574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774574.url(scheme.get, call_774574.host, call_774574.base,
                         call_774574.route, valid.getOrDefault("path"))
  result = hook(call_774574, url, valid)

proc call*(call_774575: Call_UpdateDeviceStatus_774562; body: JsonNode): Recallable =
  ## updateDeviceStatus
  ## Updates the device status.
  ##   body: JObject (required)
  var body_774576 = newJObject()
  if body != nil:
    body_774576 = body
  result = call_774575.call(nil, nil, nil, nil, body_774576)

var updateDeviceStatus* = Call_UpdateDeviceStatus_774562(
    name: "updateDeviceStatus", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateDeviceStatus",
    validator: validate_UpdateDeviceStatus_774563, base: "/",
    url: url_UpdateDeviceStatus_774564, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_774577 = ref object of OpenApiRestCall_772597
proc url_UpdateGroup_774579(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateGroup_774578(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the specified group with the specified attributes.</p> <p>Requires developer credentials.</p>
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
  var valid_774580 = header.getOrDefault("X-Amz-Date")
  valid_774580 = validateParameter(valid_774580, JString, required = false,
                                 default = nil)
  if valid_774580 != nil:
    section.add "X-Amz-Date", valid_774580
  var valid_774581 = header.getOrDefault("X-Amz-Security-Token")
  valid_774581 = validateParameter(valid_774581, JString, required = false,
                                 default = nil)
  if valid_774581 != nil:
    section.add "X-Amz-Security-Token", valid_774581
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774582 = header.getOrDefault("X-Amz-Target")
  valid_774582 = validateParameter(valid_774582, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateGroup"))
  if valid_774582 != nil:
    section.add "X-Amz-Target", valid_774582
  var valid_774583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774583 = validateParameter(valid_774583, JString, required = false,
                                 default = nil)
  if valid_774583 != nil:
    section.add "X-Amz-Content-Sha256", valid_774583
  var valid_774584 = header.getOrDefault("X-Amz-Algorithm")
  valid_774584 = validateParameter(valid_774584, JString, required = false,
                                 default = nil)
  if valid_774584 != nil:
    section.add "X-Amz-Algorithm", valid_774584
  var valid_774585 = header.getOrDefault("X-Amz-Signature")
  valid_774585 = validateParameter(valid_774585, JString, required = false,
                                 default = nil)
  if valid_774585 != nil:
    section.add "X-Amz-Signature", valid_774585
  var valid_774586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774586 = validateParameter(valid_774586, JString, required = false,
                                 default = nil)
  if valid_774586 != nil:
    section.add "X-Amz-SignedHeaders", valid_774586
  var valid_774587 = header.getOrDefault("X-Amz-Credential")
  valid_774587 = validateParameter(valid_774587, JString, required = false,
                                 default = nil)
  if valid_774587 != nil:
    section.add "X-Amz-Credential", valid_774587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774589: Call_UpdateGroup_774577; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified group with the specified attributes.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_774589.validator(path, query, header, formData, body)
  let scheme = call_774589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774589.url(scheme.get, call_774589.host, call_774589.base,
                         call_774589.route, valid.getOrDefault("path"))
  result = hook(call_774589, url, valid)

proc call*(call_774590: Call_UpdateGroup_774577; body: JsonNode): Recallable =
  ## updateGroup
  ## <p>Updates the specified group with the specified attributes.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_774591 = newJObject()
  if body != nil:
    body_774591 = body
  result = call_774590.call(nil, nil, nil, nil, body_774591)

var updateGroup* = Call_UpdateGroup_774577(name: "updateGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateGroup",
                                        validator: validate_UpdateGroup_774578,
                                        base: "/", url: url_UpdateGroup_774579,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIdentityProvider_774592 = ref object of OpenApiRestCall_772597
proc url_UpdateIdentityProvider_774594(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateIdentityProvider_774593(path: JsonNode; query: JsonNode;
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
  var valid_774595 = header.getOrDefault("X-Amz-Date")
  valid_774595 = validateParameter(valid_774595, JString, required = false,
                                 default = nil)
  if valid_774595 != nil:
    section.add "X-Amz-Date", valid_774595
  var valid_774596 = header.getOrDefault("X-Amz-Security-Token")
  valid_774596 = validateParameter(valid_774596, JString, required = false,
                                 default = nil)
  if valid_774596 != nil:
    section.add "X-Amz-Security-Token", valid_774596
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774597 = header.getOrDefault("X-Amz-Target")
  valid_774597 = validateParameter(valid_774597, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateIdentityProvider"))
  if valid_774597 != nil:
    section.add "X-Amz-Target", valid_774597
  var valid_774598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774598 = validateParameter(valid_774598, JString, required = false,
                                 default = nil)
  if valid_774598 != nil:
    section.add "X-Amz-Content-Sha256", valid_774598
  var valid_774599 = header.getOrDefault("X-Amz-Algorithm")
  valid_774599 = validateParameter(valid_774599, JString, required = false,
                                 default = nil)
  if valid_774599 != nil:
    section.add "X-Amz-Algorithm", valid_774599
  var valid_774600 = header.getOrDefault("X-Amz-Signature")
  valid_774600 = validateParameter(valid_774600, JString, required = false,
                                 default = nil)
  if valid_774600 != nil:
    section.add "X-Amz-Signature", valid_774600
  var valid_774601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774601 = validateParameter(valid_774601, JString, required = false,
                                 default = nil)
  if valid_774601 != nil:
    section.add "X-Amz-SignedHeaders", valid_774601
  var valid_774602 = header.getOrDefault("X-Amz-Credential")
  valid_774602 = validateParameter(valid_774602, JString, required = false,
                                 default = nil)
  if valid_774602 != nil:
    section.add "X-Amz-Credential", valid_774602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774604: Call_UpdateIdentityProvider_774592; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates identity provider information for a user pool.
  ## 
  let valid = call_774604.validator(path, query, header, formData, body)
  let scheme = call_774604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774604.url(scheme.get, call_774604.host, call_774604.base,
                         call_774604.route, valid.getOrDefault("path"))
  result = hook(call_774604, url, valid)

proc call*(call_774605: Call_UpdateIdentityProvider_774592; body: JsonNode): Recallable =
  ## updateIdentityProvider
  ## Updates identity provider information for a user pool.
  ##   body: JObject (required)
  var body_774606 = newJObject()
  if body != nil:
    body_774606 = body
  result = call_774605.call(nil, nil, nil, nil, body_774606)

var updateIdentityProvider* = Call_UpdateIdentityProvider_774592(
    name: "updateIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateIdentityProvider",
    validator: validate_UpdateIdentityProvider_774593, base: "/",
    url: url_UpdateIdentityProvider_774594, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceServer_774607 = ref object of OpenApiRestCall_772597
proc url_UpdateResourceServer_774609(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateResourceServer_774608(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the name and scopes of resource server. All other fields are read-only.
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
  var valid_774610 = header.getOrDefault("X-Amz-Date")
  valid_774610 = validateParameter(valid_774610, JString, required = false,
                                 default = nil)
  if valid_774610 != nil:
    section.add "X-Amz-Date", valid_774610
  var valid_774611 = header.getOrDefault("X-Amz-Security-Token")
  valid_774611 = validateParameter(valid_774611, JString, required = false,
                                 default = nil)
  if valid_774611 != nil:
    section.add "X-Amz-Security-Token", valid_774611
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774612 = header.getOrDefault("X-Amz-Target")
  valid_774612 = validateParameter(valid_774612, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateResourceServer"))
  if valid_774612 != nil:
    section.add "X-Amz-Target", valid_774612
  var valid_774613 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774613 = validateParameter(valid_774613, JString, required = false,
                                 default = nil)
  if valid_774613 != nil:
    section.add "X-Amz-Content-Sha256", valid_774613
  var valid_774614 = header.getOrDefault("X-Amz-Algorithm")
  valid_774614 = validateParameter(valid_774614, JString, required = false,
                                 default = nil)
  if valid_774614 != nil:
    section.add "X-Amz-Algorithm", valid_774614
  var valid_774615 = header.getOrDefault("X-Amz-Signature")
  valid_774615 = validateParameter(valid_774615, JString, required = false,
                                 default = nil)
  if valid_774615 != nil:
    section.add "X-Amz-Signature", valid_774615
  var valid_774616 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774616 = validateParameter(valid_774616, JString, required = false,
                                 default = nil)
  if valid_774616 != nil:
    section.add "X-Amz-SignedHeaders", valid_774616
  var valid_774617 = header.getOrDefault("X-Amz-Credential")
  valid_774617 = validateParameter(valid_774617, JString, required = false,
                                 default = nil)
  if valid_774617 != nil:
    section.add "X-Amz-Credential", valid_774617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774619: Call_UpdateResourceServer_774607; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the name and scopes of resource server. All other fields are read-only.
  ## 
  let valid = call_774619.validator(path, query, header, formData, body)
  let scheme = call_774619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774619.url(scheme.get, call_774619.host, call_774619.base,
                         call_774619.route, valid.getOrDefault("path"))
  result = hook(call_774619, url, valid)

proc call*(call_774620: Call_UpdateResourceServer_774607; body: JsonNode): Recallable =
  ## updateResourceServer
  ## Updates the name and scopes of resource server. All other fields are read-only.
  ##   body: JObject (required)
  var body_774621 = newJObject()
  if body != nil:
    body_774621 = body
  result = call_774620.call(nil, nil, nil, nil, body_774621)

var updateResourceServer* = Call_UpdateResourceServer_774607(
    name: "updateResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateResourceServer",
    validator: validate_UpdateResourceServer_774608, base: "/",
    url: url_UpdateResourceServer_774609, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserAttributes_774622 = ref object of OpenApiRestCall_772597
proc url_UpdateUserAttributes_774624(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateUserAttributes_774623(path: JsonNode; query: JsonNode;
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
  var valid_774625 = header.getOrDefault("X-Amz-Date")
  valid_774625 = validateParameter(valid_774625, JString, required = false,
                                 default = nil)
  if valid_774625 != nil:
    section.add "X-Amz-Date", valid_774625
  var valid_774626 = header.getOrDefault("X-Amz-Security-Token")
  valid_774626 = validateParameter(valid_774626, JString, required = false,
                                 default = nil)
  if valid_774626 != nil:
    section.add "X-Amz-Security-Token", valid_774626
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774627 = header.getOrDefault("X-Amz-Target")
  valid_774627 = validateParameter(valid_774627, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserAttributes"))
  if valid_774627 != nil:
    section.add "X-Amz-Target", valid_774627
  var valid_774628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774628 = validateParameter(valid_774628, JString, required = false,
                                 default = nil)
  if valid_774628 != nil:
    section.add "X-Amz-Content-Sha256", valid_774628
  var valid_774629 = header.getOrDefault("X-Amz-Algorithm")
  valid_774629 = validateParameter(valid_774629, JString, required = false,
                                 default = nil)
  if valid_774629 != nil:
    section.add "X-Amz-Algorithm", valid_774629
  var valid_774630 = header.getOrDefault("X-Amz-Signature")
  valid_774630 = validateParameter(valid_774630, JString, required = false,
                                 default = nil)
  if valid_774630 != nil:
    section.add "X-Amz-Signature", valid_774630
  var valid_774631 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774631 = validateParameter(valid_774631, JString, required = false,
                                 default = nil)
  if valid_774631 != nil:
    section.add "X-Amz-SignedHeaders", valid_774631
  var valid_774632 = header.getOrDefault("X-Amz-Credential")
  valid_774632 = validateParameter(valid_774632, JString, required = false,
                                 default = nil)
  if valid_774632 != nil:
    section.add "X-Amz-Credential", valid_774632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774634: Call_UpdateUserAttributes_774622; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a user to update a specific attribute (one at a time).
  ## 
  let valid = call_774634.validator(path, query, header, formData, body)
  let scheme = call_774634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774634.url(scheme.get, call_774634.host, call_774634.base,
                         call_774634.route, valid.getOrDefault("path"))
  result = hook(call_774634, url, valid)

proc call*(call_774635: Call_UpdateUserAttributes_774622; body: JsonNode): Recallable =
  ## updateUserAttributes
  ## Allows a user to update a specific attribute (one at a time).
  ##   body: JObject (required)
  var body_774636 = newJObject()
  if body != nil:
    body_774636 = body
  result = call_774635.call(nil, nil, nil, nil, body_774636)

var updateUserAttributes* = Call_UpdateUserAttributes_774622(
    name: "updateUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserAttributes",
    validator: validate_UpdateUserAttributes_774623, base: "/",
    url: url_UpdateUserAttributes_774624, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPool_774637 = ref object of OpenApiRestCall_772597
proc url_UpdateUserPool_774639(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateUserPool_774638(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates the specified user pool with the specified attributes. If you don't provide a value for an attribute, it will be set to the default value. You can get a list of the current user pool settings with .
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
  var valid_774640 = header.getOrDefault("X-Amz-Date")
  valid_774640 = validateParameter(valid_774640, JString, required = false,
                                 default = nil)
  if valid_774640 != nil:
    section.add "X-Amz-Date", valid_774640
  var valid_774641 = header.getOrDefault("X-Amz-Security-Token")
  valid_774641 = validateParameter(valid_774641, JString, required = false,
                                 default = nil)
  if valid_774641 != nil:
    section.add "X-Amz-Security-Token", valid_774641
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774642 = header.getOrDefault("X-Amz-Target")
  valid_774642 = validateParameter(valid_774642, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserPool"))
  if valid_774642 != nil:
    section.add "X-Amz-Target", valid_774642
  var valid_774643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774643 = validateParameter(valid_774643, JString, required = false,
                                 default = nil)
  if valid_774643 != nil:
    section.add "X-Amz-Content-Sha256", valid_774643
  var valid_774644 = header.getOrDefault("X-Amz-Algorithm")
  valid_774644 = validateParameter(valid_774644, JString, required = false,
                                 default = nil)
  if valid_774644 != nil:
    section.add "X-Amz-Algorithm", valid_774644
  var valid_774645 = header.getOrDefault("X-Amz-Signature")
  valid_774645 = validateParameter(valid_774645, JString, required = false,
                                 default = nil)
  if valid_774645 != nil:
    section.add "X-Amz-Signature", valid_774645
  var valid_774646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774646 = validateParameter(valid_774646, JString, required = false,
                                 default = nil)
  if valid_774646 != nil:
    section.add "X-Amz-SignedHeaders", valid_774646
  var valid_774647 = header.getOrDefault("X-Amz-Credential")
  valid_774647 = validateParameter(valid_774647, JString, required = false,
                                 default = nil)
  if valid_774647 != nil:
    section.add "X-Amz-Credential", valid_774647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774649: Call_UpdateUserPool_774637; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified user pool with the specified attributes. If you don't provide a value for an attribute, it will be set to the default value. You can get a list of the current user pool settings with .
  ## 
  let valid = call_774649.validator(path, query, header, formData, body)
  let scheme = call_774649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774649.url(scheme.get, call_774649.host, call_774649.base,
                         call_774649.route, valid.getOrDefault("path"))
  result = hook(call_774649, url, valid)

proc call*(call_774650: Call_UpdateUserPool_774637; body: JsonNode): Recallable =
  ## updateUserPool
  ## Updates the specified user pool with the specified attributes. If you don't provide a value for an attribute, it will be set to the default value. You can get a list of the current user pool settings with .
  ##   body: JObject (required)
  var body_774651 = newJObject()
  if body != nil:
    body_774651 = body
  result = call_774650.call(nil, nil, nil, nil, body_774651)

var updateUserPool* = Call_UpdateUserPool_774637(name: "updateUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserPool",
    validator: validate_UpdateUserPool_774638, base: "/", url: url_UpdateUserPool_774639,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPoolClient_774652 = ref object of OpenApiRestCall_772597
proc url_UpdateUserPoolClient_774654(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateUserPoolClient_774653(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the specified user pool app client with the specified attributes. If you don't provide a value for an attribute, it will be set to the default value. You can get a list of the current user pool app client settings with .
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
  var valid_774655 = header.getOrDefault("X-Amz-Date")
  valid_774655 = validateParameter(valid_774655, JString, required = false,
                                 default = nil)
  if valid_774655 != nil:
    section.add "X-Amz-Date", valid_774655
  var valid_774656 = header.getOrDefault("X-Amz-Security-Token")
  valid_774656 = validateParameter(valid_774656, JString, required = false,
                                 default = nil)
  if valid_774656 != nil:
    section.add "X-Amz-Security-Token", valid_774656
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774657 = header.getOrDefault("X-Amz-Target")
  valid_774657 = validateParameter(valid_774657, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserPoolClient"))
  if valid_774657 != nil:
    section.add "X-Amz-Target", valid_774657
  var valid_774658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774658 = validateParameter(valid_774658, JString, required = false,
                                 default = nil)
  if valid_774658 != nil:
    section.add "X-Amz-Content-Sha256", valid_774658
  var valid_774659 = header.getOrDefault("X-Amz-Algorithm")
  valid_774659 = validateParameter(valid_774659, JString, required = false,
                                 default = nil)
  if valid_774659 != nil:
    section.add "X-Amz-Algorithm", valid_774659
  var valid_774660 = header.getOrDefault("X-Amz-Signature")
  valid_774660 = validateParameter(valid_774660, JString, required = false,
                                 default = nil)
  if valid_774660 != nil:
    section.add "X-Amz-Signature", valid_774660
  var valid_774661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774661 = validateParameter(valid_774661, JString, required = false,
                                 default = nil)
  if valid_774661 != nil:
    section.add "X-Amz-SignedHeaders", valid_774661
  var valid_774662 = header.getOrDefault("X-Amz-Credential")
  valid_774662 = validateParameter(valid_774662, JString, required = false,
                                 default = nil)
  if valid_774662 != nil:
    section.add "X-Amz-Credential", valid_774662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774664: Call_UpdateUserPoolClient_774652; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified user pool app client with the specified attributes. If you don't provide a value for an attribute, it will be set to the default value. You can get a list of the current user pool app client settings with .
  ## 
  let valid = call_774664.validator(path, query, header, formData, body)
  let scheme = call_774664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774664.url(scheme.get, call_774664.host, call_774664.base,
                         call_774664.route, valid.getOrDefault("path"))
  result = hook(call_774664, url, valid)

proc call*(call_774665: Call_UpdateUserPoolClient_774652; body: JsonNode): Recallable =
  ## updateUserPoolClient
  ## Updates the specified user pool app client with the specified attributes. If you don't provide a value for an attribute, it will be set to the default value. You can get a list of the current user pool app client settings with .
  ##   body: JObject (required)
  var body_774666 = newJObject()
  if body != nil:
    body_774666 = body
  result = call_774665.call(nil, nil, nil, nil, body_774666)

var updateUserPoolClient* = Call_UpdateUserPoolClient_774652(
    name: "updateUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserPoolClient",
    validator: validate_UpdateUserPoolClient_774653, base: "/",
    url: url_UpdateUserPoolClient_774654, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPoolDomain_774667 = ref object of OpenApiRestCall_772597
proc url_UpdateUserPoolDomain_774669(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateUserPoolDomain_774668(path: JsonNode; query: JsonNode;
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
  var valid_774670 = header.getOrDefault("X-Amz-Date")
  valid_774670 = validateParameter(valid_774670, JString, required = false,
                                 default = nil)
  if valid_774670 != nil:
    section.add "X-Amz-Date", valid_774670
  var valid_774671 = header.getOrDefault("X-Amz-Security-Token")
  valid_774671 = validateParameter(valid_774671, JString, required = false,
                                 default = nil)
  if valid_774671 != nil:
    section.add "X-Amz-Security-Token", valid_774671
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774672 = header.getOrDefault("X-Amz-Target")
  valid_774672 = validateParameter(valid_774672, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserPoolDomain"))
  if valid_774672 != nil:
    section.add "X-Amz-Target", valid_774672
  var valid_774673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774673 = validateParameter(valid_774673, JString, required = false,
                                 default = nil)
  if valid_774673 != nil:
    section.add "X-Amz-Content-Sha256", valid_774673
  var valid_774674 = header.getOrDefault("X-Amz-Algorithm")
  valid_774674 = validateParameter(valid_774674, JString, required = false,
                                 default = nil)
  if valid_774674 != nil:
    section.add "X-Amz-Algorithm", valid_774674
  var valid_774675 = header.getOrDefault("X-Amz-Signature")
  valid_774675 = validateParameter(valid_774675, JString, required = false,
                                 default = nil)
  if valid_774675 != nil:
    section.add "X-Amz-Signature", valid_774675
  var valid_774676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774676 = validateParameter(valid_774676, JString, required = false,
                                 default = nil)
  if valid_774676 != nil:
    section.add "X-Amz-SignedHeaders", valid_774676
  var valid_774677 = header.getOrDefault("X-Amz-Credential")
  valid_774677 = validateParameter(valid_774677, JString, required = false,
                                 default = nil)
  if valid_774677 != nil:
    section.add "X-Amz-Credential", valid_774677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774679: Call_UpdateUserPoolDomain_774667; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the Secure Sockets Layer (SSL) certificate for the custom domain for your user pool.</p> <p>You can use this operation to provide the Amazon Resource Name (ARN) of a new certificate to Amazon Cognito. You cannot use it to change the domain for a user pool.</p> <p>A custom domain is used to host the Amazon Cognito hosted UI, which provides sign-up and sign-in pages for your application. When you set up a custom domain, you provide a certificate that you manage with AWS Certificate Manager (ACM). When necessary, you can use this operation to change the certificate that you applied to your custom domain.</p> <p>Usually, this is unnecessary following routine certificate renewal with ACM. When you renew your existing certificate in ACM, the ARN for your certificate remains the same, and your custom domain uses the new certificate automatically.</p> <p>However, if you replace your existing certificate with a new one, ACM gives the new certificate a new ARN. To apply the new certificate to your custom domain, you must provide this ARN to Amazon Cognito.</p> <p>When you add your new certificate in ACM, you must choose US East (N. Virginia) as the AWS Region.</p> <p>After you submit your request, Amazon Cognito requires up to 1 hour to distribute your new certificate to your custom domain.</p> <p>For more information about adding a custom domain to your user pool, see <a href="https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-add-custom-domain.html">Using Your Own Domain for the Hosted UI</a>.</p>
  ## 
  let valid = call_774679.validator(path, query, header, formData, body)
  let scheme = call_774679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774679.url(scheme.get, call_774679.host, call_774679.base,
                         call_774679.route, valid.getOrDefault("path"))
  result = hook(call_774679, url, valid)

proc call*(call_774680: Call_UpdateUserPoolDomain_774667; body: JsonNode): Recallable =
  ## updateUserPoolDomain
  ## <p>Updates the Secure Sockets Layer (SSL) certificate for the custom domain for your user pool.</p> <p>You can use this operation to provide the Amazon Resource Name (ARN) of a new certificate to Amazon Cognito. You cannot use it to change the domain for a user pool.</p> <p>A custom domain is used to host the Amazon Cognito hosted UI, which provides sign-up and sign-in pages for your application. When you set up a custom domain, you provide a certificate that you manage with AWS Certificate Manager (ACM). When necessary, you can use this operation to change the certificate that you applied to your custom domain.</p> <p>Usually, this is unnecessary following routine certificate renewal with ACM. When you renew your existing certificate in ACM, the ARN for your certificate remains the same, and your custom domain uses the new certificate automatically.</p> <p>However, if you replace your existing certificate with a new one, ACM gives the new certificate a new ARN. To apply the new certificate to your custom domain, you must provide this ARN to Amazon Cognito.</p> <p>When you add your new certificate in ACM, you must choose US East (N. Virginia) as the AWS Region.</p> <p>After you submit your request, Amazon Cognito requires up to 1 hour to distribute your new certificate to your custom domain.</p> <p>For more information about adding a custom domain to your user pool, see <a href="https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-add-custom-domain.html">Using Your Own Domain for the Hosted UI</a>.</p>
  ##   body: JObject (required)
  var body_774681 = newJObject()
  if body != nil:
    body_774681 = body
  result = call_774680.call(nil, nil, nil, nil, body_774681)

var updateUserPoolDomain* = Call_UpdateUserPoolDomain_774667(
    name: "updateUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserPoolDomain",
    validator: validate_UpdateUserPoolDomain_774668, base: "/",
    url: url_UpdateUserPoolDomain_774669, schemes: {Scheme.Https, Scheme.Http})
type
  Call_VerifySoftwareToken_774682 = ref object of OpenApiRestCall_772597
proc url_VerifySoftwareToken_774684(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_VerifySoftwareToken_774683(path: JsonNode; query: JsonNode;
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
  var valid_774685 = header.getOrDefault("X-Amz-Date")
  valid_774685 = validateParameter(valid_774685, JString, required = false,
                                 default = nil)
  if valid_774685 != nil:
    section.add "X-Amz-Date", valid_774685
  var valid_774686 = header.getOrDefault("X-Amz-Security-Token")
  valid_774686 = validateParameter(valid_774686, JString, required = false,
                                 default = nil)
  if valid_774686 != nil:
    section.add "X-Amz-Security-Token", valid_774686
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774687 = header.getOrDefault("X-Amz-Target")
  valid_774687 = validateParameter(valid_774687, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.VerifySoftwareToken"))
  if valid_774687 != nil:
    section.add "X-Amz-Target", valid_774687
  var valid_774688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774688 = validateParameter(valid_774688, JString, required = false,
                                 default = nil)
  if valid_774688 != nil:
    section.add "X-Amz-Content-Sha256", valid_774688
  var valid_774689 = header.getOrDefault("X-Amz-Algorithm")
  valid_774689 = validateParameter(valid_774689, JString, required = false,
                                 default = nil)
  if valid_774689 != nil:
    section.add "X-Amz-Algorithm", valid_774689
  var valid_774690 = header.getOrDefault("X-Amz-Signature")
  valid_774690 = validateParameter(valid_774690, JString, required = false,
                                 default = nil)
  if valid_774690 != nil:
    section.add "X-Amz-Signature", valid_774690
  var valid_774691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774691 = validateParameter(valid_774691, JString, required = false,
                                 default = nil)
  if valid_774691 != nil:
    section.add "X-Amz-SignedHeaders", valid_774691
  var valid_774692 = header.getOrDefault("X-Amz-Credential")
  valid_774692 = validateParameter(valid_774692, JString, required = false,
                                 default = nil)
  if valid_774692 != nil:
    section.add "X-Amz-Credential", valid_774692
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774694: Call_VerifySoftwareToken_774682; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Use this API to register a user's entered TOTP code and mark the user's software token MFA status as "verified" if successful. The request takes an access token or a session string, but not both.
  ## 
  let valid = call_774694.validator(path, query, header, formData, body)
  let scheme = call_774694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774694.url(scheme.get, call_774694.host, call_774694.base,
                         call_774694.route, valid.getOrDefault("path"))
  result = hook(call_774694, url, valid)

proc call*(call_774695: Call_VerifySoftwareToken_774682; body: JsonNode): Recallable =
  ## verifySoftwareToken
  ## Use this API to register a user's entered TOTP code and mark the user's software token MFA status as "verified" if successful. The request takes an access token or a session string, but not both.
  ##   body: JObject (required)
  var body_774696 = newJObject()
  if body != nil:
    body_774696 = body
  result = call_774695.call(nil, nil, nil, nil, body_774696)

var verifySoftwareToken* = Call_VerifySoftwareToken_774682(
    name: "verifySoftwareToken", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.VerifySoftwareToken",
    validator: validate_VerifySoftwareToken_774683, base: "/",
    url: url_VerifySoftwareToken_774684, schemes: {Scheme.Https, Scheme.Http})
type
  Call_VerifyUserAttribute_774697 = ref object of OpenApiRestCall_772597
proc url_VerifyUserAttribute_774699(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_VerifyUserAttribute_774698(path: JsonNode; query: JsonNode;
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
  var valid_774700 = header.getOrDefault("X-Amz-Date")
  valid_774700 = validateParameter(valid_774700, JString, required = false,
                                 default = nil)
  if valid_774700 != nil:
    section.add "X-Amz-Date", valid_774700
  var valid_774701 = header.getOrDefault("X-Amz-Security-Token")
  valid_774701 = validateParameter(valid_774701, JString, required = false,
                                 default = nil)
  if valid_774701 != nil:
    section.add "X-Amz-Security-Token", valid_774701
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774702 = header.getOrDefault("X-Amz-Target")
  valid_774702 = validateParameter(valid_774702, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.VerifyUserAttribute"))
  if valid_774702 != nil:
    section.add "X-Amz-Target", valid_774702
  var valid_774703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774703 = validateParameter(valid_774703, JString, required = false,
                                 default = nil)
  if valid_774703 != nil:
    section.add "X-Amz-Content-Sha256", valid_774703
  var valid_774704 = header.getOrDefault("X-Amz-Algorithm")
  valid_774704 = validateParameter(valid_774704, JString, required = false,
                                 default = nil)
  if valid_774704 != nil:
    section.add "X-Amz-Algorithm", valid_774704
  var valid_774705 = header.getOrDefault("X-Amz-Signature")
  valid_774705 = validateParameter(valid_774705, JString, required = false,
                                 default = nil)
  if valid_774705 != nil:
    section.add "X-Amz-Signature", valid_774705
  var valid_774706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774706 = validateParameter(valid_774706, JString, required = false,
                                 default = nil)
  if valid_774706 != nil:
    section.add "X-Amz-SignedHeaders", valid_774706
  var valid_774707 = header.getOrDefault("X-Amz-Credential")
  valid_774707 = validateParameter(valid_774707, JString, required = false,
                                 default = nil)
  if valid_774707 != nil:
    section.add "X-Amz-Credential", valid_774707
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774709: Call_VerifyUserAttribute_774697; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Verifies the specified user attributes in the user pool.
  ## 
  let valid = call_774709.validator(path, query, header, formData, body)
  let scheme = call_774709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774709.url(scheme.get, call_774709.host, call_774709.base,
                         call_774709.route, valid.getOrDefault("path"))
  result = hook(call_774709, url, valid)

proc call*(call_774710: Call_VerifyUserAttribute_774697; body: JsonNode): Recallable =
  ## verifyUserAttribute
  ## Verifies the specified user attributes in the user pool.
  ##   body: JObject (required)
  var body_774711 = newJObject()
  if body != nil:
    body_774711 = body
  result = call_774710.call(nil, nil, nil, nil, body_774711)

var verifyUserAttribute* = Call_VerifyUserAttribute_774697(
    name: "verifyUserAttribute", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.VerifyUserAttribute",
    validator: validate_VerifyUserAttribute_774698, base: "/",
    url: url_VerifyUserAttribute_774699, schemes: {Scheme.Https, Scheme.Http})
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
