
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

  OpenApiRestCall_602433 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602433](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602433): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AddCustomAttributes_602770 = ref object of OpenApiRestCall_602433
proc url_AddCustomAttributes_602772(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AddCustomAttributes_602771(path: JsonNode; query: JsonNode;
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
  var valid_602884 = header.getOrDefault("X-Amz-Date")
  valid_602884 = validateParameter(valid_602884, JString, required = false,
                                 default = nil)
  if valid_602884 != nil:
    section.add "X-Amz-Date", valid_602884
  var valid_602885 = header.getOrDefault("X-Amz-Security-Token")
  valid_602885 = validateParameter(valid_602885, JString, required = false,
                                 default = nil)
  if valid_602885 != nil:
    section.add "X-Amz-Security-Token", valid_602885
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602899 = header.getOrDefault("X-Amz-Target")
  valid_602899 = validateParameter(valid_602899, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AddCustomAttributes"))
  if valid_602899 != nil:
    section.add "X-Amz-Target", valid_602899
  var valid_602900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602900 = validateParameter(valid_602900, JString, required = false,
                                 default = nil)
  if valid_602900 != nil:
    section.add "X-Amz-Content-Sha256", valid_602900
  var valid_602901 = header.getOrDefault("X-Amz-Algorithm")
  valid_602901 = validateParameter(valid_602901, JString, required = false,
                                 default = nil)
  if valid_602901 != nil:
    section.add "X-Amz-Algorithm", valid_602901
  var valid_602902 = header.getOrDefault("X-Amz-Signature")
  valid_602902 = validateParameter(valid_602902, JString, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "X-Amz-Signature", valid_602902
  var valid_602903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602903 = validateParameter(valid_602903, JString, required = false,
                                 default = nil)
  if valid_602903 != nil:
    section.add "X-Amz-SignedHeaders", valid_602903
  var valid_602904 = header.getOrDefault("X-Amz-Credential")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "X-Amz-Credential", valid_602904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602928: Call_AddCustomAttributes_602770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds additional user attributes to the user pool schema.
  ## 
  let valid = call_602928.validator(path, query, header, formData, body)
  let scheme = call_602928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602928.url(scheme.get, call_602928.host, call_602928.base,
                         call_602928.route, valid.getOrDefault("path"))
  result = hook(call_602928, url, valid)

proc call*(call_602999: Call_AddCustomAttributes_602770; body: JsonNode): Recallable =
  ## addCustomAttributes
  ## Adds additional user attributes to the user pool schema.
  ##   body: JObject (required)
  var body_603000 = newJObject()
  if body != nil:
    body_603000 = body
  result = call_602999.call(nil, nil, nil, nil, body_603000)

var addCustomAttributes* = Call_AddCustomAttributes_602770(
    name: "addCustomAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AddCustomAttributes",
    validator: validate_AddCustomAttributes_602771, base: "/",
    url: url_AddCustomAttributes_602772, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminAddUserToGroup_603039 = ref object of OpenApiRestCall_602433
proc url_AdminAddUserToGroup_603041(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminAddUserToGroup_603040(path: JsonNode; query: JsonNode;
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
  var valid_603042 = header.getOrDefault("X-Amz-Date")
  valid_603042 = validateParameter(valid_603042, JString, required = false,
                                 default = nil)
  if valid_603042 != nil:
    section.add "X-Amz-Date", valid_603042
  var valid_603043 = header.getOrDefault("X-Amz-Security-Token")
  valid_603043 = validateParameter(valid_603043, JString, required = false,
                                 default = nil)
  if valid_603043 != nil:
    section.add "X-Amz-Security-Token", valid_603043
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603044 = header.getOrDefault("X-Amz-Target")
  valid_603044 = validateParameter(valid_603044, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminAddUserToGroup"))
  if valid_603044 != nil:
    section.add "X-Amz-Target", valid_603044
  var valid_603045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603045 = validateParameter(valid_603045, JString, required = false,
                                 default = nil)
  if valid_603045 != nil:
    section.add "X-Amz-Content-Sha256", valid_603045
  var valid_603046 = header.getOrDefault("X-Amz-Algorithm")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "X-Amz-Algorithm", valid_603046
  var valid_603047 = header.getOrDefault("X-Amz-Signature")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "X-Amz-Signature", valid_603047
  var valid_603048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-SignedHeaders", valid_603048
  var valid_603049 = header.getOrDefault("X-Amz-Credential")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "X-Amz-Credential", valid_603049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603051: Call_AdminAddUserToGroup_603039; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified user to the specified group.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_603051.validator(path, query, header, formData, body)
  let scheme = call_603051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603051.url(scheme.get, call_603051.host, call_603051.base,
                         call_603051.route, valid.getOrDefault("path"))
  result = hook(call_603051, url, valid)

proc call*(call_603052: Call_AdminAddUserToGroup_603039; body: JsonNode): Recallable =
  ## adminAddUserToGroup
  ## <p>Adds the specified user to the specified group.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_603053 = newJObject()
  if body != nil:
    body_603053 = body
  result = call_603052.call(nil, nil, nil, nil, body_603053)

var adminAddUserToGroup* = Call_AdminAddUserToGroup_603039(
    name: "adminAddUserToGroup", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminAddUserToGroup",
    validator: validate_AdminAddUserToGroup_603040, base: "/",
    url: url_AdminAddUserToGroup_603041, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminConfirmSignUp_603054 = ref object of OpenApiRestCall_602433
proc url_AdminConfirmSignUp_603056(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminConfirmSignUp_603055(path: JsonNode; query: JsonNode;
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
  var valid_603057 = header.getOrDefault("X-Amz-Date")
  valid_603057 = validateParameter(valid_603057, JString, required = false,
                                 default = nil)
  if valid_603057 != nil:
    section.add "X-Amz-Date", valid_603057
  var valid_603058 = header.getOrDefault("X-Amz-Security-Token")
  valid_603058 = validateParameter(valid_603058, JString, required = false,
                                 default = nil)
  if valid_603058 != nil:
    section.add "X-Amz-Security-Token", valid_603058
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603059 = header.getOrDefault("X-Amz-Target")
  valid_603059 = validateParameter(valid_603059, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminConfirmSignUp"))
  if valid_603059 != nil:
    section.add "X-Amz-Target", valid_603059
  var valid_603060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603060 = validateParameter(valid_603060, JString, required = false,
                                 default = nil)
  if valid_603060 != nil:
    section.add "X-Amz-Content-Sha256", valid_603060
  var valid_603061 = header.getOrDefault("X-Amz-Algorithm")
  valid_603061 = validateParameter(valid_603061, JString, required = false,
                                 default = nil)
  if valid_603061 != nil:
    section.add "X-Amz-Algorithm", valid_603061
  var valid_603062 = header.getOrDefault("X-Amz-Signature")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "X-Amz-Signature", valid_603062
  var valid_603063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-SignedHeaders", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-Credential")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Credential", valid_603064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603066: Call_AdminConfirmSignUp_603054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Confirms user registration as an admin without using a confirmation code. Works on any user.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_603066.validator(path, query, header, formData, body)
  let scheme = call_603066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603066.url(scheme.get, call_603066.host, call_603066.base,
                         call_603066.route, valid.getOrDefault("path"))
  result = hook(call_603066, url, valid)

proc call*(call_603067: Call_AdminConfirmSignUp_603054; body: JsonNode): Recallable =
  ## adminConfirmSignUp
  ## <p>Confirms user registration as an admin without using a confirmation code. Works on any user.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_603068 = newJObject()
  if body != nil:
    body_603068 = body
  result = call_603067.call(nil, nil, nil, nil, body_603068)

var adminConfirmSignUp* = Call_AdminConfirmSignUp_603054(
    name: "adminConfirmSignUp", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminConfirmSignUp",
    validator: validate_AdminConfirmSignUp_603055, base: "/",
    url: url_AdminConfirmSignUp_603056, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminCreateUser_603069 = ref object of OpenApiRestCall_602433
proc url_AdminCreateUser_603071(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminCreateUser_603070(path: JsonNode; query: JsonNode;
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
  var valid_603072 = header.getOrDefault("X-Amz-Date")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-Date", valid_603072
  var valid_603073 = header.getOrDefault("X-Amz-Security-Token")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-Security-Token", valid_603073
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603074 = header.getOrDefault("X-Amz-Target")
  valid_603074 = validateParameter(valid_603074, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminCreateUser"))
  if valid_603074 != nil:
    section.add "X-Amz-Target", valid_603074
  var valid_603075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Content-Sha256", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Algorithm")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Algorithm", valid_603076
  var valid_603077 = header.getOrDefault("X-Amz-Signature")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "X-Amz-Signature", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-SignedHeaders", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Credential")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Credential", valid_603079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603081: Call_AdminCreateUser_603069; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new user in the specified user pool.</p> <p>If <code>MessageAction</code> is not set, the default is to send a welcome message via email or phone (SMS).</p> <note> <p>This message is based on a template that you configured in your call to or . This template includes your custom sign-up instructions and placeholders for user name and temporary password.</p> </note> <p>Alternatively, you can call AdminCreateUser with “SUPPRESS” for the <code>MessageAction</code> parameter, and Amazon Cognito will not send any email. </p> <p>In either case, the user will be in the <code>FORCE_CHANGE_PASSWORD</code> state until they sign in and change their password.</p> <p>AdminCreateUser requires developer credentials.</p>
  ## 
  let valid = call_603081.validator(path, query, header, formData, body)
  let scheme = call_603081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603081.url(scheme.get, call_603081.host, call_603081.base,
                         call_603081.route, valid.getOrDefault("path"))
  result = hook(call_603081, url, valid)

proc call*(call_603082: Call_AdminCreateUser_603069; body: JsonNode): Recallable =
  ## adminCreateUser
  ## <p>Creates a new user in the specified user pool.</p> <p>If <code>MessageAction</code> is not set, the default is to send a welcome message via email or phone (SMS).</p> <note> <p>This message is based on a template that you configured in your call to or . This template includes your custom sign-up instructions and placeholders for user name and temporary password.</p> </note> <p>Alternatively, you can call AdminCreateUser with “SUPPRESS” for the <code>MessageAction</code> parameter, and Amazon Cognito will not send any email. </p> <p>In either case, the user will be in the <code>FORCE_CHANGE_PASSWORD</code> state until they sign in and change their password.</p> <p>AdminCreateUser requires developer credentials.</p>
  ##   body: JObject (required)
  var body_603083 = newJObject()
  if body != nil:
    body_603083 = body
  result = call_603082.call(nil, nil, nil, nil, body_603083)

var adminCreateUser* = Call_AdminCreateUser_603069(name: "adminCreateUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminCreateUser",
    validator: validate_AdminCreateUser_603070, base: "/", url: url_AdminCreateUser_603071,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDeleteUser_603084 = ref object of OpenApiRestCall_602433
proc url_AdminDeleteUser_603086(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminDeleteUser_603085(path: JsonNode; query: JsonNode;
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
  var valid_603087 = header.getOrDefault("X-Amz-Date")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-Date", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Security-Token")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Security-Token", valid_603088
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603089 = header.getOrDefault("X-Amz-Target")
  valid_603089 = validateParameter(valid_603089, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDeleteUser"))
  if valid_603089 != nil:
    section.add "X-Amz-Target", valid_603089
  var valid_603090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Content-Sha256", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Algorithm")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Algorithm", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-Signature")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-Signature", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-SignedHeaders", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Credential")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Credential", valid_603094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603096: Call_AdminDeleteUser_603084; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a user as an administrator. Works on any user.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_603096.validator(path, query, header, formData, body)
  let scheme = call_603096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603096.url(scheme.get, call_603096.host, call_603096.base,
                         call_603096.route, valid.getOrDefault("path"))
  result = hook(call_603096, url, valid)

proc call*(call_603097: Call_AdminDeleteUser_603084; body: JsonNode): Recallable =
  ## adminDeleteUser
  ## <p>Deletes a user as an administrator. Works on any user.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_603098 = newJObject()
  if body != nil:
    body_603098 = body
  result = call_603097.call(nil, nil, nil, nil, body_603098)

var adminDeleteUser* = Call_AdminDeleteUser_603084(name: "adminDeleteUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDeleteUser",
    validator: validate_AdminDeleteUser_603085, base: "/", url: url_AdminDeleteUser_603086,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDeleteUserAttributes_603099 = ref object of OpenApiRestCall_602433
proc url_AdminDeleteUserAttributes_603101(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminDeleteUserAttributes_603100(path: JsonNode; query: JsonNode;
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
  var valid_603102 = header.getOrDefault("X-Amz-Date")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Date", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Security-Token")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Security-Token", valid_603103
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603104 = header.getOrDefault("X-Amz-Target")
  valid_603104 = validateParameter(valid_603104, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDeleteUserAttributes"))
  if valid_603104 != nil:
    section.add "X-Amz-Target", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Content-Sha256", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Algorithm")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Algorithm", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-Signature")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-Signature", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-SignedHeaders", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Credential")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Credential", valid_603109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603111: Call_AdminDeleteUserAttributes_603099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the user attributes in a user pool as an administrator. Works on any user.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_603111.validator(path, query, header, formData, body)
  let scheme = call_603111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603111.url(scheme.get, call_603111.host, call_603111.base,
                         call_603111.route, valid.getOrDefault("path"))
  result = hook(call_603111, url, valid)

proc call*(call_603112: Call_AdminDeleteUserAttributes_603099; body: JsonNode): Recallable =
  ## adminDeleteUserAttributes
  ## <p>Deletes the user attributes in a user pool as an administrator. Works on any user.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_603113 = newJObject()
  if body != nil:
    body_603113 = body
  result = call_603112.call(nil, nil, nil, nil, body_603113)

var adminDeleteUserAttributes* = Call_AdminDeleteUserAttributes_603099(
    name: "adminDeleteUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDeleteUserAttributes",
    validator: validate_AdminDeleteUserAttributes_603100, base: "/",
    url: url_AdminDeleteUserAttributes_603101,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDisableProviderForUser_603114 = ref object of OpenApiRestCall_602433
proc url_AdminDisableProviderForUser_603116(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminDisableProviderForUser_603115(path: JsonNode; query: JsonNode;
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
  var valid_603117 = header.getOrDefault("X-Amz-Date")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Date", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Security-Token")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Security-Token", valid_603118
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603119 = header.getOrDefault("X-Amz-Target")
  valid_603119 = validateParameter(valid_603119, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDisableProviderForUser"))
  if valid_603119 != nil:
    section.add "X-Amz-Target", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Content-Sha256", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Algorithm")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Algorithm", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Signature")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Signature", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-SignedHeaders", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Credential")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Credential", valid_603124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603126: Call_AdminDisableProviderForUser_603114; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables the user from signing in with the specified external (SAML or social) identity provider. If the user to disable is a Cognito User Pools native username + password user, they are not permitted to use their password to sign-in. If the user to disable is a linked external IdP user, any link between that user and an existing user is removed. The next time the external user (no longer attached to the previously linked <code>DestinationUser</code>) signs in, they must create a new user account. See .</p> <p>This action is enabled only for admin access and requires developer credentials.</p> <p>The <code>ProviderName</code> must match the value specified when creating an IdP for the pool. </p> <p>To disable a native username + password user, the <code>ProviderName</code> value must be <code>Cognito</code> and the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code>, with the <code>ProviderAttributeValue</code> being the name that is used in the user pool for the user.</p> <p>The <code>ProviderAttributeName</code> must always be <code>Cognito_Subject</code> for social identity providers. The <code>ProviderAttributeValue</code> must always be the exact subject that was used when the user was originally linked as a source user.</p> <p>For de-linking a SAML identity, there are two scenarios. If the linked identity has not yet been used to sign-in, the <code>ProviderAttributeName</code> and <code>ProviderAttributeValue</code> must be the same values that were used for the <code>SourceUser</code> when the identities were originally linked in the call. (If the linking was done with <code>ProviderAttributeName</code> set to <code>Cognito_Subject</code>, the same applies here). However, if the user has already signed in, the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code> and <code>ProviderAttributeValue</code> must be the subject of the SAML assertion.</p>
  ## 
  let valid = call_603126.validator(path, query, header, formData, body)
  let scheme = call_603126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603126.url(scheme.get, call_603126.host, call_603126.base,
                         call_603126.route, valid.getOrDefault("path"))
  result = hook(call_603126, url, valid)

proc call*(call_603127: Call_AdminDisableProviderForUser_603114; body: JsonNode): Recallable =
  ## adminDisableProviderForUser
  ## <p>Disables the user from signing in with the specified external (SAML or social) identity provider. If the user to disable is a Cognito User Pools native username + password user, they are not permitted to use their password to sign-in. If the user to disable is a linked external IdP user, any link between that user and an existing user is removed. The next time the external user (no longer attached to the previously linked <code>DestinationUser</code>) signs in, they must create a new user account. See .</p> <p>This action is enabled only for admin access and requires developer credentials.</p> <p>The <code>ProviderName</code> must match the value specified when creating an IdP for the pool. </p> <p>To disable a native username + password user, the <code>ProviderName</code> value must be <code>Cognito</code> and the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code>, with the <code>ProviderAttributeValue</code> being the name that is used in the user pool for the user.</p> <p>The <code>ProviderAttributeName</code> must always be <code>Cognito_Subject</code> for social identity providers. The <code>ProviderAttributeValue</code> must always be the exact subject that was used when the user was originally linked as a source user.</p> <p>For de-linking a SAML identity, there are two scenarios. If the linked identity has not yet been used to sign-in, the <code>ProviderAttributeName</code> and <code>ProviderAttributeValue</code> must be the same values that were used for the <code>SourceUser</code> when the identities were originally linked in the call. (If the linking was done with <code>ProviderAttributeName</code> set to <code>Cognito_Subject</code>, the same applies here). However, if the user has already signed in, the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code> and <code>ProviderAttributeValue</code> must be the subject of the SAML assertion.</p>
  ##   body: JObject (required)
  var body_603128 = newJObject()
  if body != nil:
    body_603128 = body
  result = call_603127.call(nil, nil, nil, nil, body_603128)

var adminDisableProviderForUser* = Call_AdminDisableProviderForUser_603114(
    name: "adminDisableProviderForUser", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDisableProviderForUser",
    validator: validate_AdminDisableProviderForUser_603115, base: "/",
    url: url_AdminDisableProviderForUser_603116,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDisableUser_603129 = ref object of OpenApiRestCall_602433
proc url_AdminDisableUser_603131(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminDisableUser_603130(path: JsonNode; query: JsonNode;
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
  var valid_603132 = header.getOrDefault("X-Amz-Date")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-Date", valid_603132
  var valid_603133 = header.getOrDefault("X-Amz-Security-Token")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Security-Token", valid_603133
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603134 = header.getOrDefault("X-Amz-Target")
  valid_603134 = validateParameter(valid_603134, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDisableUser"))
  if valid_603134 != nil:
    section.add "X-Amz-Target", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Content-Sha256", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Algorithm")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Algorithm", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Signature")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Signature", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-SignedHeaders", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Credential")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Credential", valid_603139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603141: Call_AdminDisableUser_603129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables the specified user as an administrator. Works on any user.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_603141.validator(path, query, header, formData, body)
  let scheme = call_603141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603141.url(scheme.get, call_603141.host, call_603141.base,
                         call_603141.route, valid.getOrDefault("path"))
  result = hook(call_603141, url, valid)

proc call*(call_603142: Call_AdminDisableUser_603129; body: JsonNode): Recallable =
  ## adminDisableUser
  ## <p>Disables the specified user as an administrator. Works on any user.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_603143 = newJObject()
  if body != nil:
    body_603143 = body
  result = call_603142.call(nil, nil, nil, nil, body_603143)

var adminDisableUser* = Call_AdminDisableUser_603129(name: "adminDisableUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDisableUser",
    validator: validate_AdminDisableUser_603130, base: "/",
    url: url_AdminDisableUser_603131, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminEnableUser_603144 = ref object of OpenApiRestCall_602433
proc url_AdminEnableUser_603146(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminEnableUser_603145(path: JsonNode; query: JsonNode;
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
  var valid_603147 = header.getOrDefault("X-Amz-Date")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "X-Amz-Date", valid_603147
  var valid_603148 = header.getOrDefault("X-Amz-Security-Token")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-Security-Token", valid_603148
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603149 = header.getOrDefault("X-Amz-Target")
  valid_603149 = validateParameter(valid_603149, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminEnableUser"))
  if valid_603149 != nil:
    section.add "X-Amz-Target", valid_603149
  var valid_603150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Content-Sha256", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Algorithm")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Algorithm", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Signature")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Signature", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-SignedHeaders", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Credential")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Credential", valid_603154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603156: Call_AdminEnableUser_603144; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the specified user as an administrator. Works on any user.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_603156.validator(path, query, header, formData, body)
  let scheme = call_603156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603156.url(scheme.get, call_603156.host, call_603156.base,
                         call_603156.route, valid.getOrDefault("path"))
  result = hook(call_603156, url, valid)

proc call*(call_603157: Call_AdminEnableUser_603144; body: JsonNode): Recallable =
  ## adminEnableUser
  ## <p>Enables the specified user as an administrator. Works on any user.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_603158 = newJObject()
  if body != nil:
    body_603158 = body
  result = call_603157.call(nil, nil, nil, nil, body_603158)

var adminEnableUser* = Call_AdminEnableUser_603144(name: "adminEnableUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminEnableUser",
    validator: validate_AdminEnableUser_603145, base: "/", url: url_AdminEnableUser_603146,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminForgetDevice_603159 = ref object of OpenApiRestCall_602433
proc url_AdminForgetDevice_603161(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminForgetDevice_603160(path: JsonNode; query: JsonNode;
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
  var valid_603162 = header.getOrDefault("X-Amz-Date")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "X-Amz-Date", valid_603162
  var valid_603163 = header.getOrDefault("X-Amz-Security-Token")
  valid_603163 = validateParameter(valid_603163, JString, required = false,
                                 default = nil)
  if valid_603163 != nil:
    section.add "X-Amz-Security-Token", valid_603163
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603164 = header.getOrDefault("X-Amz-Target")
  valid_603164 = validateParameter(valid_603164, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminForgetDevice"))
  if valid_603164 != nil:
    section.add "X-Amz-Target", valid_603164
  var valid_603165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Content-Sha256", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Algorithm")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Algorithm", valid_603166
  var valid_603167 = header.getOrDefault("X-Amz-Signature")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "X-Amz-Signature", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-SignedHeaders", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Credential")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Credential", valid_603169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603171: Call_AdminForgetDevice_603159; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Forgets the device, as an administrator.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_603171.validator(path, query, header, formData, body)
  let scheme = call_603171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603171.url(scheme.get, call_603171.host, call_603171.base,
                         call_603171.route, valid.getOrDefault("path"))
  result = hook(call_603171, url, valid)

proc call*(call_603172: Call_AdminForgetDevice_603159; body: JsonNode): Recallable =
  ## adminForgetDevice
  ## <p>Forgets the device, as an administrator.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_603173 = newJObject()
  if body != nil:
    body_603173 = body
  result = call_603172.call(nil, nil, nil, nil, body_603173)

var adminForgetDevice* = Call_AdminForgetDevice_603159(name: "adminForgetDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminForgetDevice",
    validator: validate_AdminForgetDevice_603160, base: "/",
    url: url_AdminForgetDevice_603161, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminGetDevice_603174 = ref object of OpenApiRestCall_602433
proc url_AdminGetDevice_603176(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminGetDevice_603175(path: JsonNode; query: JsonNode;
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
  var valid_603177 = header.getOrDefault("X-Amz-Date")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-Date", valid_603177
  var valid_603178 = header.getOrDefault("X-Amz-Security-Token")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "X-Amz-Security-Token", valid_603178
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603179 = header.getOrDefault("X-Amz-Target")
  valid_603179 = validateParameter(valid_603179, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminGetDevice"))
  if valid_603179 != nil:
    section.add "X-Amz-Target", valid_603179
  var valid_603180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Content-Sha256", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Algorithm")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Algorithm", valid_603181
  var valid_603182 = header.getOrDefault("X-Amz-Signature")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "X-Amz-Signature", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-SignedHeaders", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Credential")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Credential", valid_603184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603186: Call_AdminGetDevice_603174; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the device, as an administrator.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_603186.validator(path, query, header, formData, body)
  let scheme = call_603186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603186.url(scheme.get, call_603186.host, call_603186.base,
                         call_603186.route, valid.getOrDefault("path"))
  result = hook(call_603186, url, valid)

proc call*(call_603187: Call_AdminGetDevice_603174; body: JsonNode): Recallable =
  ## adminGetDevice
  ## <p>Gets the device, as an administrator.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_603188 = newJObject()
  if body != nil:
    body_603188 = body
  result = call_603187.call(nil, nil, nil, nil, body_603188)

var adminGetDevice* = Call_AdminGetDevice_603174(name: "adminGetDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminGetDevice",
    validator: validate_AdminGetDevice_603175, base: "/", url: url_AdminGetDevice_603176,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminGetUser_603189 = ref object of OpenApiRestCall_602433
proc url_AdminGetUser_603191(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminGetUser_603190(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603192 = header.getOrDefault("X-Amz-Date")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Date", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-Security-Token")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-Security-Token", valid_603193
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603194 = header.getOrDefault("X-Amz-Target")
  valid_603194 = validateParameter(valid_603194, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminGetUser"))
  if valid_603194 != nil:
    section.add "X-Amz-Target", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Content-Sha256", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Algorithm")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Algorithm", valid_603196
  var valid_603197 = header.getOrDefault("X-Amz-Signature")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-Signature", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-SignedHeaders", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Credential")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Credential", valid_603199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603201: Call_AdminGetUser_603189; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the specified user by user name in a user pool as an administrator. Works on any user.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_603201.validator(path, query, header, formData, body)
  let scheme = call_603201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603201.url(scheme.get, call_603201.host, call_603201.base,
                         call_603201.route, valid.getOrDefault("path"))
  result = hook(call_603201, url, valid)

proc call*(call_603202: Call_AdminGetUser_603189; body: JsonNode): Recallable =
  ## adminGetUser
  ## <p>Gets the specified user by user name in a user pool as an administrator. Works on any user.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_603203 = newJObject()
  if body != nil:
    body_603203 = body
  result = call_603202.call(nil, nil, nil, nil, body_603203)

var adminGetUser* = Call_AdminGetUser_603189(name: "adminGetUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminGetUser",
    validator: validate_AdminGetUser_603190, base: "/", url: url_AdminGetUser_603191,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminInitiateAuth_603204 = ref object of OpenApiRestCall_602433
proc url_AdminInitiateAuth_603206(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminInitiateAuth_603205(path: JsonNode; query: JsonNode;
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
  var valid_603207 = header.getOrDefault("X-Amz-Date")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-Date", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-Security-Token")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-Security-Token", valid_603208
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603209 = header.getOrDefault("X-Amz-Target")
  valid_603209 = validateParameter(valid_603209, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminInitiateAuth"))
  if valid_603209 != nil:
    section.add "X-Amz-Target", valid_603209
  var valid_603210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Content-Sha256", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Algorithm")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Algorithm", valid_603211
  var valid_603212 = header.getOrDefault("X-Amz-Signature")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "X-Amz-Signature", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-SignedHeaders", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Credential")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Credential", valid_603214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603216: Call_AdminInitiateAuth_603204; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates the authentication flow, as an administrator.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_603216.validator(path, query, header, formData, body)
  let scheme = call_603216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603216.url(scheme.get, call_603216.host, call_603216.base,
                         call_603216.route, valid.getOrDefault("path"))
  result = hook(call_603216, url, valid)

proc call*(call_603217: Call_AdminInitiateAuth_603204; body: JsonNode): Recallable =
  ## adminInitiateAuth
  ## <p>Initiates the authentication flow, as an administrator.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_603218 = newJObject()
  if body != nil:
    body_603218 = body
  result = call_603217.call(nil, nil, nil, nil, body_603218)

var adminInitiateAuth* = Call_AdminInitiateAuth_603204(name: "adminInitiateAuth",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminInitiateAuth",
    validator: validate_AdminInitiateAuth_603205, base: "/",
    url: url_AdminInitiateAuth_603206, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminLinkProviderForUser_603219 = ref object of OpenApiRestCall_602433
proc url_AdminLinkProviderForUser_603221(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminLinkProviderForUser_603220(path: JsonNode; query: JsonNode;
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
  var valid_603222 = header.getOrDefault("X-Amz-Date")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Date", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-Security-Token")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-Security-Token", valid_603223
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603224 = header.getOrDefault("X-Amz-Target")
  valid_603224 = validateParameter(valid_603224, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminLinkProviderForUser"))
  if valid_603224 != nil:
    section.add "X-Amz-Target", valid_603224
  var valid_603225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Content-Sha256", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Algorithm")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Algorithm", valid_603226
  var valid_603227 = header.getOrDefault("X-Amz-Signature")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-Signature", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-SignedHeaders", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Credential")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Credential", valid_603229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603231: Call_AdminLinkProviderForUser_603219; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Links an existing user account in a user pool (<code>DestinationUser</code>) to an identity from an external identity provider (<code>SourceUser</code>) based on a specified attribute name and value from the external identity provider. This allows you to create a link from the existing user account to an external federated user identity that has not yet been used to sign in, so that the federated user identity can be used to sign in as the existing user account. </p> <p> For example, if there is an existing user with a username and password, this API links that user to a federated user identity, so that when the federated user identity is used, the user signs in as the existing user account. </p> <important> <p>Because this API allows a user with an external federated identity to sign in as an existing user in the user pool, it is critical that it only be used with external identity providers and provider attributes that have been trusted by the application owner.</p> </important> <p>See also .</p> <p>This action is enabled only for admin access and requires developer credentials.</p>
  ## 
  let valid = call_603231.validator(path, query, header, formData, body)
  let scheme = call_603231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603231.url(scheme.get, call_603231.host, call_603231.base,
                         call_603231.route, valid.getOrDefault("path"))
  result = hook(call_603231, url, valid)

proc call*(call_603232: Call_AdminLinkProviderForUser_603219; body: JsonNode): Recallable =
  ## adminLinkProviderForUser
  ## <p>Links an existing user account in a user pool (<code>DestinationUser</code>) to an identity from an external identity provider (<code>SourceUser</code>) based on a specified attribute name and value from the external identity provider. This allows you to create a link from the existing user account to an external federated user identity that has not yet been used to sign in, so that the federated user identity can be used to sign in as the existing user account. </p> <p> For example, if there is an existing user with a username and password, this API links that user to a federated user identity, so that when the federated user identity is used, the user signs in as the existing user account. </p> <important> <p>Because this API allows a user with an external federated identity to sign in as an existing user in the user pool, it is critical that it only be used with external identity providers and provider attributes that have been trusted by the application owner.</p> </important> <p>See also .</p> <p>This action is enabled only for admin access and requires developer credentials.</p>
  ##   body: JObject (required)
  var body_603233 = newJObject()
  if body != nil:
    body_603233 = body
  result = call_603232.call(nil, nil, nil, nil, body_603233)

var adminLinkProviderForUser* = Call_AdminLinkProviderForUser_603219(
    name: "adminLinkProviderForUser", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminLinkProviderForUser",
    validator: validate_AdminLinkProviderForUser_603220, base: "/",
    url: url_AdminLinkProviderForUser_603221, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminListDevices_603234 = ref object of OpenApiRestCall_602433
proc url_AdminListDevices_603236(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminListDevices_603235(path: JsonNode; query: JsonNode;
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
  var valid_603237 = header.getOrDefault("X-Amz-Date")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-Date", valid_603237
  var valid_603238 = header.getOrDefault("X-Amz-Security-Token")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-Security-Token", valid_603238
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603239 = header.getOrDefault("X-Amz-Target")
  valid_603239 = validateParameter(valid_603239, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminListDevices"))
  if valid_603239 != nil:
    section.add "X-Amz-Target", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Content-Sha256", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Algorithm")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Algorithm", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-Signature")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Signature", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-SignedHeaders", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Credential")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Credential", valid_603244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603246: Call_AdminListDevices_603234; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists devices, as an administrator.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_603246.validator(path, query, header, formData, body)
  let scheme = call_603246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603246.url(scheme.get, call_603246.host, call_603246.base,
                         call_603246.route, valid.getOrDefault("path"))
  result = hook(call_603246, url, valid)

proc call*(call_603247: Call_AdminListDevices_603234; body: JsonNode): Recallable =
  ## adminListDevices
  ## <p>Lists devices, as an administrator.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_603248 = newJObject()
  if body != nil:
    body_603248 = body
  result = call_603247.call(nil, nil, nil, nil, body_603248)

var adminListDevices* = Call_AdminListDevices_603234(name: "adminListDevices",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminListDevices",
    validator: validate_AdminListDevices_603235, base: "/",
    url: url_AdminListDevices_603236, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminListGroupsForUser_603249 = ref object of OpenApiRestCall_602433
proc url_AdminListGroupsForUser_603251(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminListGroupsForUser_603250(path: JsonNode; query: JsonNode;
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
  var valid_603252 = query.getOrDefault("Limit")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "Limit", valid_603252
  var valid_603253 = query.getOrDefault("NextToken")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "NextToken", valid_603253
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
  var valid_603254 = header.getOrDefault("X-Amz-Date")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-Date", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-Security-Token")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Security-Token", valid_603255
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603256 = header.getOrDefault("X-Amz-Target")
  valid_603256 = validateParameter(valid_603256, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminListGroupsForUser"))
  if valid_603256 != nil:
    section.add "X-Amz-Target", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Content-Sha256", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Algorithm")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Algorithm", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Signature")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Signature", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-SignedHeaders", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-Credential")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-Credential", valid_603261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603263: Call_AdminListGroupsForUser_603249; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the groups that the user belongs to.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_603263.validator(path, query, header, formData, body)
  let scheme = call_603263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603263.url(scheme.get, call_603263.host, call_603263.base,
                         call_603263.route, valid.getOrDefault("path"))
  result = hook(call_603263, url, valid)

proc call*(call_603264: Call_AdminListGroupsForUser_603249; body: JsonNode;
          Limit: string = ""; NextToken: string = ""): Recallable =
  ## adminListGroupsForUser
  ## <p>Lists the groups that the user belongs to.</p> <p>Requires developer credentials.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603265 = newJObject()
  var body_603266 = newJObject()
  add(query_603265, "Limit", newJString(Limit))
  add(query_603265, "NextToken", newJString(NextToken))
  if body != nil:
    body_603266 = body
  result = call_603264.call(nil, query_603265, nil, nil, body_603266)

var adminListGroupsForUser* = Call_AdminListGroupsForUser_603249(
    name: "adminListGroupsForUser", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminListGroupsForUser",
    validator: validate_AdminListGroupsForUser_603250, base: "/",
    url: url_AdminListGroupsForUser_603251, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminListUserAuthEvents_603268 = ref object of OpenApiRestCall_602433
proc url_AdminListUserAuthEvents_603270(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminListUserAuthEvents_603269(path: JsonNode; query: JsonNode;
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
  var valid_603271 = query.getOrDefault("NextToken")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "NextToken", valid_603271
  var valid_603272 = query.getOrDefault("MaxResults")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "MaxResults", valid_603272
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
  var valid_603273 = header.getOrDefault("X-Amz-Date")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Date", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Security-Token")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Security-Token", valid_603274
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603275 = header.getOrDefault("X-Amz-Target")
  valid_603275 = validateParameter(valid_603275, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminListUserAuthEvents"))
  if valid_603275 != nil:
    section.add "X-Amz-Target", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-Content-Sha256", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Algorithm")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Algorithm", valid_603277
  var valid_603278 = header.getOrDefault("X-Amz-Signature")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-Signature", valid_603278
  var valid_603279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-SignedHeaders", valid_603279
  var valid_603280 = header.getOrDefault("X-Amz-Credential")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "X-Amz-Credential", valid_603280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603282: Call_AdminListUserAuthEvents_603268; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists a history of user activity and any risks detected as part of Amazon Cognito advanced security.
  ## 
  let valid = call_603282.validator(path, query, header, formData, body)
  let scheme = call_603282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603282.url(scheme.get, call_603282.host, call_603282.base,
                         call_603282.route, valid.getOrDefault("path"))
  result = hook(call_603282, url, valid)

proc call*(call_603283: Call_AdminListUserAuthEvents_603268; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## adminListUserAuthEvents
  ## Lists a history of user activity and any risks detected as part of Amazon Cognito advanced security.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603284 = newJObject()
  var body_603285 = newJObject()
  add(query_603284, "NextToken", newJString(NextToken))
  if body != nil:
    body_603285 = body
  add(query_603284, "MaxResults", newJString(MaxResults))
  result = call_603283.call(nil, query_603284, nil, nil, body_603285)

var adminListUserAuthEvents* = Call_AdminListUserAuthEvents_603268(
    name: "adminListUserAuthEvents", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminListUserAuthEvents",
    validator: validate_AdminListUserAuthEvents_603269, base: "/",
    url: url_AdminListUserAuthEvents_603270, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminRemoveUserFromGroup_603286 = ref object of OpenApiRestCall_602433
proc url_AdminRemoveUserFromGroup_603288(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminRemoveUserFromGroup_603287(path: JsonNode; query: JsonNode;
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
  var valid_603289 = header.getOrDefault("X-Amz-Date")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Date", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Security-Token")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Security-Token", valid_603290
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603291 = header.getOrDefault("X-Amz-Target")
  valid_603291 = validateParameter(valid_603291, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminRemoveUserFromGroup"))
  if valid_603291 != nil:
    section.add "X-Amz-Target", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Content-Sha256", valid_603292
  var valid_603293 = header.getOrDefault("X-Amz-Algorithm")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-Algorithm", valid_603293
  var valid_603294 = header.getOrDefault("X-Amz-Signature")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-Signature", valid_603294
  var valid_603295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "X-Amz-SignedHeaders", valid_603295
  var valid_603296 = header.getOrDefault("X-Amz-Credential")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "X-Amz-Credential", valid_603296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603298: Call_AdminRemoveUserFromGroup_603286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified user from the specified group.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_603298.validator(path, query, header, formData, body)
  let scheme = call_603298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603298.url(scheme.get, call_603298.host, call_603298.base,
                         call_603298.route, valid.getOrDefault("path"))
  result = hook(call_603298, url, valid)

proc call*(call_603299: Call_AdminRemoveUserFromGroup_603286; body: JsonNode): Recallable =
  ## adminRemoveUserFromGroup
  ## <p>Removes the specified user from the specified group.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_603300 = newJObject()
  if body != nil:
    body_603300 = body
  result = call_603299.call(nil, nil, nil, nil, body_603300)

var adminRemoveUserFromGroup* = Call_AdminRemoveUserFromGroup_603286(
    name: "adminRemoveUserFromGroup", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminRemoveUserFromGroup",
    validator: validate_AdminRemoveUserFromGroup_603287, base: "/",
    url: url_AdminRemoveUserFromGroup_603288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminResetUserPassword_603301 = ref object of OpenApiRestCall_602433
proc url_AdminResetUserPassword_603303(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminResetUserPassword_603302(path: JsonNode; query: JsonNode;
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
  var valid_603304 = header.getOrDefault("X-Amz-Date")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Date", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Security-Token")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Security-Token", valid_603305
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603306 = header.getOrDefault("X-Amz-Target")
  valid_603306 = validateParameter(valid_603306, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminResetUserPassword"))
  if valid_603306 != nil:
    section.add "X-Amz-Target", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Content-Sha256", valid_603307
  var valid_603308 = header.getOrDefault("X-Amz-Algorithm")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "X-Amz-Algorithm", valid_603308
  var valid_603309 = header.getOrDefault("X-Amz-Signature")
  valid_603309 = validateParameter(valid_603309, JString, required = false,
                                 default = nil)
  if valid_603309 != nil:
    section.add "X-Amz-Signature", valid_603309
  var valid_603310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "X-Amz-SignedHeaders", valid_603310
  var valid_603311 = header.getOrDefault("X-Amz-Credential")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "X-Amz-Credential", valid_603311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603313: Call_AdminResetUserPassword_603301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Resets the specified user's password in a user pool as an administrator. Works on any user.</p> <p>When a developer calls this API, the current password is invalidated, so it must be changed. If a user tries to sign in after the API is called, the app will get a PasswordResetRequiredException exception back and should direct the user down the flow to reset the password, which is the same as the forgot password flow. In addition, if the user pool has phone verification selected and a verified phone number exists for the user, or if email verification is selected and a verified email exists for the user, calling this API will also result in sending a message to the end user with the code to change their password.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_603313.validator(path, query, header, formData, body)
  let scheme = call_603313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603313.url(scheme.get, call_603313.host, call_603313.base,
                         call_603313.route, valid.getOrDefault("path"))
  result = hook(call_603313, url, valid)

proc call*(call_603314: Call_AdminResetUserPassword_603301; body: JsonNode): Recallable =
  ## adminResetUserPassword
  ## <p>Resets the specified user's password in a user pool as an administrator. Works on any user.</p> <p>When a developer calls this API, the current password is invalidated, so it must be changed. If a user tries to sign in after the API is called, the app will get a PasswordResetRequiredException exception back and should direct the user down the flow to reset the password, which is the same as the forgot password flow. In addition, if the user pool has phone verification selected and a verified phone number exists for the user, or if email verification is selected and a verified email exists for the user, calling this API will also result in sending a message to the end user with the code to change their password.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_603315 = newJObject()
  if body != nil:
    body_603315 = body
  result = call_603314.call(nil, nil, nil, nil, body_603315)

var adminResetUserPassword* = Call_AdminResetUserPassword_603301(
    name: "adminResetUserPassword", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminResetUserPassword",
    validator: validate_AdminResetUserPassword_603302, base: "/",
    url: url_AdminResetUserPassword_603303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminRespondToAuthChallenge_603316 = ref object of OpenApiRestCall_602433
proc url_AdminRespondToAuthChallenge_603318(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminRespondToAuthChallenge_603317(path: JsonNode; query: JsonNode;
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
  var valid_603319 = header.getOrDefault("X-Amz-Date")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Date", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Security-Token")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Security-Token", valid_603320
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603321 = header.getOrDefault("X-Amz-Target")
  valid_603321 = validateParameter(valid_603321, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminRespondToAuthChallenge"))
  if valid_603321 != nil:
    section.add "X-Amz-Target", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Content-Sha256", valid_603322
  var valid_603323 = header.getOrDefault("X-Amz-Algorithm")
  valid_603323 = validateParameter(valid_603323, JString, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "X-Amz-Algorithm", valid_603323
  var valid_603324 = header.getOrDefault("X-Amz-Signature")
  valid_603324 = validateParameter(valid_603324, JString, required = false,
                                 default = nil)
  if valid_603324 != nil:
    section.add "X-Amz-Signature", valid_603324
  var valid_603325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603325 = validateParameter(valid_603325, JString, required = false,
                                 default = nil)
  if valid_603325 != nil:
    section.add "X-Amz-SignedHeaders", valid_603325
  var valid_603326 = header.getOrDefault("X-Amz-Credential")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "X-Amz-Credential", valid_603326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603328: Call_AdminRespondToAuthChallenge_603316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Responds to an authentication challenge, as an administrator.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_603328.validator(path, query, header, formData, body)
  let scheme = call_603328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603328.url(scheme.get, call_603328.host, call_603328.base,
                         call_603328.route, valid.getOrDefault("path"))
  result = hook(call_603328, url, valid)

proc call*(call_603329: Call_AdminRespondToAuthChallenge_603316; body: JsonNode): Recallable =
  ## adminRespondToAuthChallenge
  ## <p>Responds to an authentication challenge, as an administrator.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_603330 = newJObject()
  if body != nil:
    body_603330 = body
  result = call_603329.call(nil, nil, nil, nil, body_603330)

var adminRespondToAuthChallenge* = Call_AdminRespondToAuthChallenge_603316(
    name: "adminRespondToAuthChallenge", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminRespondToAuthChallenge",
    validator: validate_AdminRespondToAuthChallenge_603317, base: "/",
    url: url_AdminRespondToAuthChallenge_603318,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminSetUserMFAPreference_603331 = ref object of OpenApiRestCall_602433
proc url_AdminSetUserMFAPreference_603333(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminSetUserMFAPreference_603332(path: JsonNode; query: JsonNode;
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
  var valid_603334 = header.getOrDefault("X-Amz-Date")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Date", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Security-Token")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Security-Token", valid_603335
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603336 = header.getOrDefault("X-Amz-Target")
  valid_603336 = validateParameter(valid_603336, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminSetUserMFAPreference"))
  if valid_603336 != nil:
    section.add "X-Amz-Target", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Content-Sha256", valid_603337
  var valid_603338 = header.getOrDefault("X-Amz-Algorithm")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "X-Amz-Algorithm", valid_603338
  var valid_603339 = header.getOrDefault("X-Amz-Signature")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "X-Amz-Signature", valid_603339
  var valid_603340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "X-Amz-SignedHeaders", valid_603340
  var valid_603341 = header.getOrDefault("X-Amz-Credential")
  valid_603341 = validateParameter(valid_603341, JString, required = false,
                                 default = nil)
  if valid_603341 != nil:
    section.add "X-Amz-Credential", valid_603341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603343: Call_AdminSetUserMFAPreference_603331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the user's multi-factor authentication (MFA) preference.
  ## 
  let valid = call_603343.validator(path, query, header, formData, body)
  let scheme = call_603343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603343.url(scheme.get, call_603343.host, call_603343.base,
                         call_603343.route, valid.getOrDefault("path"))
  result = hook(call_603343, url, valid)

proc call*(call_603344: Call_AdminSetUserMFAPreference_603331; body: JsonNode): Recallable =
  ## adminSetUserMFAPreference
  ## Sets the user's multi-factor authentication (MFA) preference.
  ##   body: JObject (required)
  var body_603345 = newJObject()
  if body != nil:
    body_603345 = body
  result = call_603344.call(nil, nil, nil, nil, body_603345)

var adminSetUserMFAPreference* = Call_AdminSetUserMFAPreference_603331(
    name: "adminSetUserMFAPreference", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminSetUserMFAPreference",
    validator: validate_AdminSetUserMFAPreference_603332, base: "/",
    url: url_AdminSetUserMFAPreference_603333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminSetUserPassword_603346 = ref object of OpenApiRestCall_602433
proc url_AdminSetUserPassword_603348(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminSetUserPassword_603347(path: JsonNode; query: JsonNode;
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
  var valid_603349 = header.getOrDefault("X-Amz-Date")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Date", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Security-Token")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Security-Token", valid_603350
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603351 = header.getOrDefault("X-Amz-Target")
  valid_603351 = validateParameter(valid_603351, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminSetUserPassword"))
  if valid_603351 != nil:
    section.add "X-Amz-Target", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Content-Sha256", valid_603352
  var valid_603353 = header.getOrDefault("X-Amz-Algorithm")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "X-Amz-Algorithm", valid_603353
  var valid_603354 = header.getOrDefault("X-Amz-Signature")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "X-Amz-Signature", valid_603354
  var valid_603355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "X-Amz-SignedHeaders", valid_603355
  var valid_603356 = header.getOrDefault("X-Amz-Credential")
  valid_603356 = validateParameter(valid_603356, JString, required = false,
                                 default = nil)
  if valid_603356 != nil:
    section.add "X-Amz-Credential", valid_603356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603358: Call_AdminSetUserPassword_603346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603358.validator(path, query, header, formData, body)
  let scheme = call_603358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603358.url(scheme.get, call_603358.host, call_603358.base,
                         call_603358.route, valid.getOrDefault("path"))
  result = hook(call_603358, url, valid)

proc call*(call_603359: Call_AdminSetUserPassword_603346; body: JsonNode): Recallable =
  ## adminSetUserPassword
  ##   body: JObject (required)
  var body_603360 = newJObject()
  if body != nil:
    body_603360 = body
  result = call_603359.call(nil, nil, nil, nil, body_603360)

var adminSetUserPassword* = Call_AdminSetUserPassword_603346(
    name: "adminSetUserPassword", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminSetUserPassword",
    validator: validate_AdminSetUserPassword_603347, base: "/",
    url: url_AdminSetUserPassword_603348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminSetUserSettings_603361 = ref object of OpenApiRestCall_602433
proc url_AdminSetUserSettings_603363(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminSetUserSettings_603362(path: JsonNode; query: JsonNode;
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
  var valid_603364 = header.getOrDefault("X-Amz-Date")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Date", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Security-Token")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Security-Token", valid_603365
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603366 = header.getOrDefault("X-Amz-Target")
  valid_603366 = validateParameter(valid_603366, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminSetUserSettings"))
  if valid_603366 != nil:
    section.add "X-Amz-Target", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Content-Sha256", valid_603367
  var valid_603368 = header.getOrDefault("X-Amz-Algorithm")
  valid_603368 = validateParameter(valid_603368, JString, required = false,
                                 default = nil)
  if valid_603368 != nil:
    section.add "X-Amz-Algorithm", valid_603368
  var valid_603369 = header.getOrDefault("X-Amz-Signature")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "X-Amz-Signature", valid_603369
  var valid_603370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-SignedHeaders", valid_603370
  var valid_603371 = header.getOrDefault("X-Amz-Credential")
  valid_603371 = validateParameter(valid_603371, JString, required = false,
                                 default = nil)
  if valid_603371 != nil:
    section.add "X-Amz-Credential", valid_603371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603373: Call_AdminSetUserSettings_603361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets all the user settings for a specified user name. Works on any user.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_603373.validator(path, query, header, formData, body)
  let scheme = call_603373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603373.url(scheme.get, call_603373.host, call_603373.base,
                         call_603373.route, valid.getOrDefault("path"))
  result = hook(call_603373, url, valid)

proc call*(call_603374: Call_AdminSetUserSettings_603361; body: JsonNode): Recallable =
  ## adminSetUserSettings
  ## <p>Sets all the user settings for a specified user name. Works on any user.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_603375 = newJObject()
  if body != nil:
    body_603375 = body
  result = call_603374.call(nil, nil, nil, nil, body_603375)

var adminSetUserSettings* = Call_AdminSetUserSettings_603361(
    name: "adminSetUserSettings", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminSetUserSettings",
    validator: validate_AdminSetUserSettings_603362, base: "/",
    url: url_AdminSetUserSettings_603363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUpdateAuthEventFeedback_603376 = ref object of OpenApiRestCall_602433
proc url_AdminUpdateAuthEventFeedback_603378(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminUpdateAuthEventFeedback_603377(path: JsonNode; query: JsonNode;
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
  var valid_603379 = header.getOrDefault("X-Amz-Date")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Date", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-Security-Token")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Security-Token", valid_603380
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603381 = header.getOrDefault("X-Amz-Target")
  valid_603381 = validateParameter(valid_603381, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUpdateAuthEventFeedback"))
  if valid_603381 != nil:
    section.add "X-Amz-Target", valid_603381
  var valid_603382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-Content-Sha256", valid_603382
  var valid_603383 = header.getOrDefault("X-Amz-Algorithm")
  valid_603383 = validateParameter(valid_603383, JString, required = false,
                                 default = nil)
  if valid_603383 != nil:
    section.add "X-Amz-Algorithm", valid_603383
  var valid_603384 = header.getOrDefault("X-Amz-Signature")
  valid_603384 = validateParameter(valid_603384, JString, required = false,
                                 default = nil)
  if valid_603384 != nil:
    section.add "X-Amz-Signature", valid_603384
  var valid_603385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603385 = validateParameter(valid_603385, JString, required = false,
                                 default = nil)
  if valid_603385 != nil:
    section.add "X-Amz-SignedHeaders", valid_603385
  var valid_603386 = header.getOrDefault("X-Amz-Credential")
  valid_603386 = validateParameter(valid_603386, JString, required = false,
                                 default = nil)
  if valid_603386 != nil:
    section.add "X-Amz-Credential", valid_603386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603388: Call_AdminUpdateAuthEventFeedback_603376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides feedback for an authentication event as to whether it was from a valid user. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ## 
  let valid = call_603388.validator(path, query, header, formData, body)
  let scheme = call_603388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603388.url(scheme.get, call_603388.host, call_603388.base,
                         call_603388.route, valid.getOrDefault("path"))
  result = hook(call_603388, url, valid)

proc call*(call_603389: Call_AdminUpdateAuthEventFeedback_603376; body: JsonNode): Recallable =
  ## adminUpdateAuthEventFeedback
  ## Provides feedback for an authentication event as to whether it was from a valid user. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ##   body: JObject (required)
  var body_603390 = newJObject()
  if body != nil:
    body_603390 = body
  result = call_603389.call(nil, nil, nil, nil, body_603390)

var adminUpdateAuthEventFeedback* = Call_AdminUpdateAuthEventFeedback_603376(
    name: "adminUpdateAuthEventFeedback", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUpdateAuthEventFeedback",
    validator: validate_AdminUpdateAuthEventFeedback_603377, base: "/",
    url: url_AdminUpdateAuthEventFeedback_603378,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUpdateDeviceStatus_603391 = ref object of OpenApiRestCall_602433
proc url_AdminUpdateDeviceStatus_603393(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminUpdateDeviceStatus_603392(path: JsonNode; query: JsonNode;
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
  var valid_603394 = header.getOrDefault("X-Amz-Date")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Date", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Security-Token")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Security-Token", valid_603395
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603396 = header.getOrDefault("X-Amz-Target")
  valid_603396 = validateParameter(valid_603396, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUpdateDeviceStatus"))
  if valid_603396 != nil:
    section.add "X-Amz-Target", valid_603396
  var valid_603397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Content-Sha256", valid_603397
  var valid_603398 = header.getOrDefault("X-Amz-Algorithm")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "X-Amz-Algorithm", valid_603398
  var valid_603399 = header.getOrDefault("X-Amz-Signature")
  valid_603399 = validateParameter(valid_603399, JString, required = false,
                                 default = nil)
  if valid_603399 != nil:
    section.add "X-Amz-Signature", valid_603399
  var valid_603400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603400 = validateParameter(valid_603400, JString, required = false,
                                 default = nil)
  if valid_603400 != nil:
    section.add "X-Amz-SignedHeaders", valid_603400
  var valid_603401 = header.getOrDefault("X-Amz-Credential")
  valid_603401 = validateParameter(valid_603401, JString, required = false,
                                 default = nil)
  if valid_603401 != nil:
    section.add "X-Amz-Credential", valid_603401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603403: Call_AdminUpdateDeviceStatus_603391; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the device status as an administrator.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_603403.validator(path, query, header, formData, body)
  let scheme = call_603403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603403.url(scheme.get, call_603403.host, call_603403.base,
                         call_603403.route, valid.getOrDefault("path"))
  result = hook(call_603403, url, valid)

proc call*(call_603404: Call_AdminUpdateDeviceStatus_603391; body: JsonNode): Recallable =
  ## adminUpdateDeviceStatus
  ## <p>Updates the device status as an administrator.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_603405 = newJObject()
  if body != nil:
    body_603405 = body
  result = call_603404.call(nil, nil, nil, nil, body_603405)

var adminUpdateDeviceStatus* = Call_AdminUpdateDeviceStatus_603391(
    name: "adminUpdateDeviceStatus", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUpdateDeviceStatus",
    validator: validate_AdminUpdateDeviceStatus_603392, base: "/",
    url: url_AdminUpdateDeviceStatus_603393, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUpdateUserAttributes_603406 = ref object of OpenApiRestCall_602433
proc url_AdminUpdateUserAttributes_603408(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminUpdateUserAttributes_603407(path: JsonNode; query: JsonNode;
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
  var valid_603409 = header.getOrDefault("X-Amz-Date")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Date", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Security-Token")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Security-Token", valid_603410
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603411 = header.getOrDefault("X-Amz-Target")
  valid_603411 = validateParameter(valid_603411, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUpdateUserAttributes"))
  if valid_603411 != nil:
    section.add "X-Amz-Target", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-Content-Sha256", valid_603412
  var valid_603413 = header.getOrDefault("X-Amz-Algorithm")
  valid_603413 = validateParameter(valid_603413, JString, required = false,
                                 default = nil)
  if valid_603413 != nil:
    section.add "X-Amz-Algorithm", valid_603413
  var valid_603414 = header.getOrDefault("X-Amz-Signature")
  valid_603414 = validateParameter(valid_603414, JString, required = false,
                                 default = nil)
  if valid_603414 != nil:
    section.add "X-Amz-Signature", valid_603414
  var valid_603415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603415 = validateParameter(valid_603415, JString, required = false,
                                 default = nil)
  if valid_603415 != nil:
    section.add "X-Amz-SignedHeaders", valid_603415
  var valid_603416 = header.getOrDefault("X-Amz-Credential")
  valid_603416 = validateParameter(valid_603416, JString, required = false,
                                 default = nil)
  if valid_603416 != nil:
    section.add "X-Amz-Credential", valid_603416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603418: Call_AdminUpdateUserAttributes_603406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified user's attributes, including developer attributes, as an administrator. Works on any user.</p> <p>For custom attributes, you must prepend the <code>custom:</code> prefix to the attribute name.</p> <p>In addition to updating user attributes, this API can also be used to mark phone and email as verified.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_603418.validator(path, query, header, formData, body)
  let scheme = call_603418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603418.url(scheme.get, call_603418.host, call_603418.base,
                         call_603418.route, valid.getOrDefault("path"))
  result = hook(call_603418, url, valid)

proc call*(call_603419: Call_AdminUpdateUserAttributes_603406; body: JsonNode): Recallable =
  ## adminUpdateUserAttributes
  ## <p>Updates the specified user's attributes, including developer attributes, as an administrator. Works on any user.</p> <p>For custom attributes, you must prepend the <code>custom:</code> prefix to the attribute name.</p> <p>In addition to updating user attributes, this API can also be used to mark phone and email as verified.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_603420 = newJObject()
  if body != nil:
    body_603420 = body
  result = call_603419.call(nil, nil, nil, nil, body_603420)

var adminUpdateUserAttributes* = Call_AdminUpdateUserAttributes_603406(
    name: "adminUpdateUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUpdateUserAttributes",
    validator: validate_AdminUpdateUserAttributes_603407, base: "/",
    url: url_AdminUpdateUserAttributes_603408,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUserGlobalSignOut_603421 = ref object of OpenApiRestCall_602433
proc url_AdminUserGlobalSignOut_603423(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AdminUserGlobalSignOut_603422(path: JsonNode; query: JsonNode;
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
  var valid_603424 = header.getOrDefault("X-Amz-Date")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Date", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Security-Token")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Security-Token", valid_603425
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603426 = header.getOrDefault("X-Amz-Target")
  valid_603426 = validateParameter(valid_603426, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUserGlobalSignOut"))
  if valid_603426 != nil:
    section.add "X-Amz-Target", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-Content-Sha256", valid_603427
  var valid_603428 = header.getOrDefault("X-Amz-Algorithm")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-Algorithm", valid_603428
  var valid_603429 = header.getOrDefault("X-Amz-Signature")
  valid_603429 = validateParameter(valid_603429, JString, required = false,
                                 default = nil)
  if valid_603429 != nil:
    section.add "X-Amz-Signature", valid_603429
  var valid_603430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603430 = validateParameter(valid_603430, JString, required = false,
                                 default = nil)
  if valid_603430 != nil:
    section.add "X-Amz-SignedHeaders", valid_603430
  var valid_603431 = header.getOrDefault("X-Amz-Credential")
  valid_603431 = validateParameter(valid_603431, JString, required = false,
                                 default = nil)
  if valid_603431 != nil:
    section.add "X-Amz-Credential", valid_603431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603433: Call_AdminUserGlobalSignOut_603421; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Signs out users from all devices, as an administrator.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_603433.validator(path, query, header, formData, body)
  let scheme = call_603433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603433.url(scheme.get, call_603433.host, call_603433.base,
                         call_603433.route, valid.getOrDefault("path"))
  result = hook(call_603433, url, valid)

proc call*(call_603434: Call_AdminUserGlobalSignOut_603421; body: JsonNode): Recallable =
  ## adminUserGlobalSignOut
  ## <p>Signs out users from all devices, as an administrator.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_603435 = newJObject()
  if body != nil:
    body_603435 = body
  result = call_603434.call(nil, nil, nil, nil, body_603435)

var adminUserGlobalSignOut* = Call_AdminUserGlobalSignOut_603421(
    name: "adminUserGlobalSignOut", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUserGlobalSignOut",
    validator: validate_AdminUserGlobalSignOut_603422, base: "/",
    url: url_AdminUserGlobalSignOut_603423, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSoftwareToken_603436 = ref object of OpenApiRestCall_602433
proc url_AssociateSoftwareToken_603438(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AssociateSoftwareToken_603437(path: JsonNode; query: JsonNode;
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
  var valid_603439 = header.getOrDefault("X-Amz-Date")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Date", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Security-Token")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Security-Token", valid_603440
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603441 = header.getOrDefault("X-Amz-Target")
  valid_603441 = validateParameter(valid_603441, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AssociateSoftwareToken"))
  if valid_603441 != nil:
    section.add "X-Amz-Target", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Content-Sha256", valid_603442
  var valid_603443 = header.getOrDefault("X-Amz-Algorithm")
  valid_603443 = validateParameter(valid_603443, JString, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "X-Amz-Algorithm", valid_603443
  var valid_603444 = header.getOrDefault("X-Amz-Signature")
  valid_603444 = validateParameter(valid_603444, JString, required = false,
                                 default = nil)
  if valid_603444 != nil:
    section.add "X-Amz-Signature", valid_603444
  var valid_603445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603445 = validateParameter(valid_603445, JString, required = false,
                                 default = nil)
  if valid_603445 != nil:
    section.add "X-Amz-SignedHeaders", valid_603445
  var valid_603446 = header.getOrDefault("X-Amz-Credential")
  valid_603446 = validateParameter(valid_603446, JString, required = false,
                                 default = nil)
  if valid_603446 != nil:
    section.add "X-Amz-Credential", valid_603446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603448: Call_AssociateSoftwareToken_603436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a unique generated shared secret key code for the user account. The request takes an access token or a session string, but not both.
  ## 
  let valid = call_603448.validator(path, query, header, formData, body)
  let scheme = call_603448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603448.url(scheme.get, call_603448.host, call_603448.base,
                         call_603448.route, valid.getOrDefault("path"))
  result = hook(call_603448, url, valid)

proc call*(call_603449: Call_AssociateSoftwareToken_603436; body: JsonNode): Recallable =
  ## associateSoftwareToken
  ## Returns a unique generated shared secret key code for the user account. The request takes an access token or a session string, but not both.
  ##   body: JObject (required)
  var body_603450 = newJObject()
  if body != nil:
    body_603450 = body
  result = call_603449.call(nil, nil, nil, nil, body_603450)

var associateSoftwareToken* = Call_AssociateSoftwareToken_603436(
    name: "associateSoftwareToken", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AssociateSoftwareToken",
    validator: validate_AssociateSoftwareToken_603437, base: "/",
    url: url_AssociateSoftwareToken_603438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ChangePassword_603451 = ref object of OpenApiRestCall_602433
proc url_ChangePassword_603453(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ChangePassword_603452(path: JsonNode; query: JsonNode;
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
  var valid_603454 = header.getOrDefault("X-Amz-Date")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Date", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-Security-Token")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Security-Token", valid_603455
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603456 = header.getOrDefault("X-Amz-Target")
  valid_603456 = validateParameter(valid_603456, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ChangePassword"))
  if valid_603456 != nil:
    section.add "X-Amz-Target", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Content-Sha256", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-Algorithm")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-Algorithm", valid_603458
  var valid_603459 = header.getOrDefault("X-Amz-Signature")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-Signature", valid_603459
  var valid_603460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-SignedHeaders", valid_603460
  var valid_603461 = header.getOrDefault("X-Amz-Credential")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-Credential", valid_603461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603463: Call_ChangePassword_603451; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the password for a specified user in a user pool.
  ## 
  let valid = call_603463.validator(path, query, header, formData, body)
  let scheme = call_603463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603463.url(scheme.get, call_603463.host, call_603463.base,
                         call_603463.route, valid.getOrDefault("path"))
  result = hook(call_603463, url, valid)

proc call*(call_603464: Call_ChangePassword_603451; body: JsonNode): Recallable =
  ## changePassword
  ## Changes the password for a specified user in a user pool.
  ##   body: JObject (required)
  var body_603465 = newJObject()
  if body != nil:
    body_603465 = body
  result = call_603464.call(nil, nil, nil, nil, body_603465)

var changePassword* = Call_ChangePassword_603451(name: "changePassword",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ChangePassword",
    validator: validate_ChangePassword_603452, base: "/", url: url_ChangePassword_603453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmDevice_603466 = ref object of OpenApiRestCall_602433
proc url_ConfirmDevice_603468(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ConfirmDevice_603467(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603469 = header.getOrDefault("X-Amz-Date")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-Date", valid_603469
  var valid_603470 = header.getOrDefault("X-Amz-Security-Token")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Security-Token", valid_603470
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603471 = header.getOrDefault("X-Amz-Target")
  valid_603471 = validateParameter(valid_603471, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ConfirmDevice"))
  if valid_603471 != nil:
    section.add "X-Amz-Target", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Content-Sha256", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-Algorithm")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-Algorithm", valid_603473
  var valid_603474 = header.getOrDefault("X-Amz-Signature")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "X-Amz-Signature", valid_603474
  var valid_603475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "X-Amz-SignedHeaders", valid_603475
  var valid_603476 = header.getOrDefault("X-Amz-Credential")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "X-Amz-Credential", valid_603476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603478: Call_ConfirmDevice_603466; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Confirms tracking of the device. This API call is the call that begins device tracking.
  ## 
  let valid = call_603478.validator(path, query, header, formData, body)
  let scheme = call_603478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603478.url(scheme.get, call_603478.host, call_603478.base,
                         call_603478.route, valid.getOrDefault("path"))
  result = hook(call_603478, url, valid)

proc call*(call_603479: Call_ConfirmDevice_603466; body: JsonNode): Recallable =
  ## confirmDevice
  ## Confirms tracking of the device. This API call is the call that begins device tracking.
  ##   body: JObject (required)
  var body_603480 = newJObject()
  if body != nil:
    body_603480 = body
  result = call_603479.call(nil, nil, nil, nil, body_603480)

var confirmDevice* = Call_ConfirmDevice_603466(name: "confirmDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ConfirmDevice",
    validator: validate_ConfirmDevice_603467, base: "/", url: url_ConfirmDevice_603468,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmForgotPassword_603481 = ref object of OpenApiRestCall_602433
proc url_ConfirmForgotPassword_603483(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ConfirmForgotPassword_603482(path: JsonNode; query: JsonNode;
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
  var valid_603484 = header.getOrDefault("X-Amz-Date")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-Date", valid_603484
  var valid_603485 = header.getOrDefault("X-Amz-Security-Token")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-Security-Token", valid_603485
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603486 = header.getOrDefault("X-Amz-Target")
  valid_603486 = validateParameter(valid_603486, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ConfirmForgotPassword"))
  if valid_603486 != nil:
    section.add "X-Amz-Target", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Content-Sha256", valid_603487
  var valid_603488 = header.getOrDefault("X-Amz-Algorithm")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "X-Amz-Algorithm", valid_603488
  var valid_603489 = header.getOrDefault("X-Amz-Signature")
  valid_603489 = validateParameter(valid_603489, JString, required = false,
                                 default = nil)
  if valid_603489 != nil:
    section.add "X-Amz-Signature", valid_603489
  var valid_603490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603490 = validateParameter(valid_603490, JString, required = false,
                                 default = nil)
  if valid_603490 != nil:
    section.add "X-Amz-SignedHeaders", valid_603490
  var valid_603491 = header.getOrDefault("X-Amz-Credential")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "X-Amz-Credential", valid_603491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603493: Call_ConfirmForgotPassword_603481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a user to enter a confirmation code to reset a forgotten password.
  ## 
  let valid = call_603493.validator(path, query, header, formData, body)
  let scheme = call_603493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603493.url(scheme.get, call_603493.host, call_603493.base,
                         call_603493.route, valid.getOrDefault("path"))
  result = hook(call_603493, url, valid)

proc call*(call_603494: Call_ConfirmForgotPassword_603481; body: JsonNode): Recallable =
  ## confirmForgotPassword
  ## Allows a user to enter a confirmation code to reset a forgotten password.
  ##   body: JObject (required)
  var body_603495 = newJObject()
  if body != nil:
    body_603495 = body
  result = call_603494.call(nil, nil, nil, nil, body_603495)

var confirmForgotPassword* = Call_ConfirmForgotPassword_603481(
    name: "confirmForgotPassword", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ConfirmForgotPassword",
    validator: validate_ConfirmForgotPassword_603482, base: "/",
    url: url_ConfirmForgotPassword_603483, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmSignUp_603496 = ref object of OpenApiRestCall_602433
proc url_ConfirmSignUp_603498(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ConfirmSignUp_603497(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603499 = header.getOrDefault("X-Amz-Date")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Date", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Security-Token")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Security-Token", valid_603500
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603501 = header.getOrDefault("X-Amz-Target")
  valid_603501 = validateParameter(valid_603501, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ConfirmSignUp"))
  if valid_603501 != nil:
    section.add "X-Amz-Target", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Content-Sha256", valid_603502
  var valid_603503 = header.getOrDefault("X-Amz-Algorithm")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "X-Amz-Algorithm", valid_603503
  var valid_603504 = header.getOrDefault("X-Amz-Signature")
  valid_603504 = validateParameter(valid_603504, JString, required = false,
                                 default = nil)
  if valid_603504 != nil:
    section.add "X-Amz-Signature", valid_603504
  var valid_603505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603505 = validateParameter(valid_603505, JString, required = false,
                                 default = nil)
  if valid_603505 != nil:
    section.add "X-Amz-SignedHeaders", valid_603505
  var valid_603506 = header.getOrDefault("X-Amz-Credential")
  valid_603506 = validateParameter(valid_603506, JString, required = false,
                                 default = nil)
  if valid_603506 != nil:
    section.add "X-Amz-Credential", valid_603506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603508: Call_ConfirmSignUp_603496; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Confirms registration of a user and handles the existing alias from a previous user.
  ## 
  let valid = call_603508.validator(path, query, header, formData, body)
  let scheme = call_603508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603508.url(scheme.get, call_603508.host, call_603508.base,
                         call_603508.route, valid.getOrDefault("path"))
  result = hook(call_603508, url, valid)

proc call*(call_603509: Call_ConfirmSignUp_603496; body: JsonNode): Recallable =
  ## confirmSignUp
  ## Confirms registration of a user and handles the existing alias from a previous user.
  ##   body: JObject (required)
  var body_603510 = newJObject()
  if body != nil:
    body_603510 = body
  result = call_603509.call(nil, nil, nil, nil, body_603510)

var confirmSignUp* = Call_ConfirmSignUp_603496(name: "confirmSignUp",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ConfirmSignUp",
    validator: validate_ConfirmSignUp_603497, base: "/", url: url_ConfirmSignUp_603498,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_603511 = ref object of OpenApiRestCall_602433
proc url_CreateGroup_603513(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateGroup_603512(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603514 = header.getOrDefault("X-Amz-Date")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Date", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Security-Token")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Security-Token", valid_603515
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603516 = header.getOrDefault("X-Amz-Target")
  valid_603516 = validateParameter(valid_603516, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateGroup"))
  if valid_603516 != nil:
    section.add "X-Amz-Target", valid_603516
  var valid_603517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Content-Sha256", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-Algorithm")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-Algorithm", valid_603518
  var valid_603519 = header.getOrDefault("X-Amz-Signature")
  valid_603519 = validateParameter(valid_603519, JString, required = false,
                                 default = nil)
  if valid_603519 != nil:
    section.add "X-Amz-Signature", valid_603519
  var valid_603520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603520 = validateParameter(valid_603520, JString, required = false,
                                 default = nil)
  if valid_603520 != nil:
    section.add "X-Amz-SignedHeaders", valid_603520
  var valid_603521 = header.getOrDefault("X-Amz-Credential")
  valid_603521 = validateParameter(valid_603521, JString, required = false,
                                 default = nil)
  if valid_603521 != nil:
    section.add "X-Amz-Credential", valid_603521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603523: Call_CreateGroup_603511; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new group in the specified user pool.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_603523.validator(path, query, header, formData, body)
  let scheme = call_603523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603523.url(scheme.get, call_603523.host, call_603523.base,
                         call_603523.route, valid.getOrDefault("path"))
  result = hook(call_603523, url, valid)

proc call*(call_603524: Call_CreateGroup_603511; body: JsonNode): Recallable =
  ## createGroup
  ## <p>Creates a new group in the specified user pool.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_603525 = newJObject()
  if body != nil:
    body_603525 = body
  result = call_603524.call(nil, nil, nil, nil, body_603525)

var createGroup* = Call_CreateGroup_603511(name: "createGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateGroup",
                                        validator: validate_CreateGroup_603512,
                                        base: "/", url: url_CreateGroup_603513,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIdentityProvider_603526 = ref object of OpenApiRestCall_602433
proc url_CreateIdentityProvider_603528(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateIdentityProvider_603527(path: JsonNode; query: JsonNode;
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
  var valid_603529 = header.getOrDefault("X-Amz-Date")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-Date", valid_603529
  var valid_603530 = header.getOrDefault("X-Amz-Security-Token")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Security-Token", valid_603530
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603531 = header.getOrDefault("X-Amz-Target")
  valid_603531 = validateParameter(valid_603531, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateIdentityProvider"))
  if valid_603531 != nil:
    section.add "X-Amz-Target", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-Content-Sha256", valid_603532
  var valid_603533 = header.getOrDefault("X-Amz-Algorithm")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "X-Amz-Algorithm", valid_603533
  var valid_603534 = header.getOrDefault("X-Amz-Signature")
  valid_603534 = validateParameter(valid_603534, JString, required = false,
                                 default = nil)
  if valid_603534 != nil:
    section.add "X-Amz-Signature", valid_603534
  var valid_603535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603535 = validateParameter(valid_603535, JString, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "X-Amz-SignedHeaders", valid_603535
  var valid_603536 = header.getOrDefault("X-Amz-Credential")
  valid_603536 = validateParameter(valid_603536, JString, required = false,
                                 default = nil)
  if valid_603536 != nil:
    section.add "X-Amz-Credential", valid_603536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603538: Call_CreateIdentityProvider_603526; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an identity provider for a user pool.
  ## 
  let valid = call_603538.validator(path, query, header, formData, body)
  let scheme = call_603538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603538.url(scheme.get, call_603538.host, call_603538.base,
                         call_603538.route, valid.getOrDefault("path"))
  result = hook(call_603538, url, valid)

proc call*(call_603539: Call_CreateIdentityProvider_603526; body: JsonNode): Recallable =
  ## createIdentityProvider
  ## Creates an identity provider for a user pool.
  ##   body: JObject (required)
  var body_603540 = newJObject()
  if body != nil:
    body_603540 = body
  result = call_603539.call(nil, nil, nil, nil, body_603540)

var createIdentityProvider* = Call_CreateIdentityProvider_603526(
    name: "createIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateIdentityProvider",
    validator: validate_CreateIdentityProvider_603527, base: "/",
    url: url_CreateIdentityProvider_603528, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceServer_603541 = ref object of OpenApiRestCall_602433
proc url_CreateResourceServer_603543(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateResourceServer_603542(path: JsonNode; query: JsonNode;
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
  var valid_603544 = header.getOrDefault("X-Amz-Date")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-Date", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Security-Token")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Security-Token", valid_603545
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603546 = header.getOrDefault("X-Amz-Target")
  valid_603546 = validateParameter(valid_603546, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateResourceServer"))
  if valid_603546 != nil:
    section.add "X-Amz-Target", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Content-Sha256", valid_603547
  var valid_603548 = header.getOrDefault("X-Amz-Algorithm")
  valid_603548 = validateParameter(valid_603548, JString, required = false,
                                 default = nil)
  if valid_603548 != nil:
    section.add "X-Amz-Algorithm", valid_603548
  var valid_603549 = header.getOrDefault("X-Amz-Signature")
  valid_603549 = validateParameter(valid_603549, JString, required = false,
                                 default = nil)
  if valid_603549 != nil:
    section.add "X-Amz-Signature", valid_603549
  var valid_603550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "X-Amz-SignedHeaders", valid_603550
  var valid_603551 = header.getOrDefault("X-Amz-Credential")
  valid_603551 = validateParameter(valid_603551, JString, required = false,
                                 default = nil)
  if valid_603551 != nil:
    section.add "X-Amz-Credential", valid_603551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603553: Call_CreateResourceServer_603541; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new OAuth2.0 resource server and defines custom scopes in it.
  ## 
  let valid = call_603553.validator(path, query, header, formData, body)
  let scheme = call_603553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603553.url(scheme.get, call_603553.host, call_603553.base,
                         call_603553.route, valid.getOrDefault("path"))
  result = hook(call_603553, url, valid)

proc call*(call_603554: Call_CreateResourceServer_603541; body: JsonNode): Recallable =
  ## createResourceServer
  ## Creates a new OAuth2.0 resource server and defines custom scopes in it.
  ##   body: JObject (required)
  var body_603555 = newJObject()
  if body != nil:
    body_603555 = body
  result = call_603554.call(nil, nil, nil, nil, body_603555)

var createResourceServer* = Call_CreateResourceServer_603541(
    name: "createResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateResourceServer",
    validator: validate_CreateResourceServer_603542, base: "/",
    url: url_CreateResourceServer_603543, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserImportJob_603556 = ref object of OpenApiRestCall_602433
proc url_CreateUserImportJob_603558(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateUserImportJob_603557(path: JsonNode; query: JsonNode;
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
  var valid_603559 = header.getOrDefault("X-Amz-Date")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "X-Amz-Date", valid_603559
  var valid_603560 = header.getOrDefault("X-Amz-Security-Token")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "X-Amz-Security-Token", valid_603560
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603561 = header.getOrDefault("X-Amz-Target")
  valid_603561 = validateParameter(valid_603561, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserImportJob"))
  if valid_603561 != nil:
    section.add "X-Amz-Target", valid_603561
  var valid_603562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-Content-Sha256", valid_603562
  var valid_603563 = header.getOrDefault("X-Amz-Algorithm")
  valid_603563 = validateParameter(valid_603563, JString, required = false,
                                 default = nil)
  if valid_603563 != nil:
    section.add "X-Amz-Algorithm", valid_603563
  var valid_603564 = header.getOrDefault("X-Amz-Signature")
  valid_603564 = validateParameter(valid_603564, JString, required = false,
                                 default = nil)
  if valid_603564 != nil:
    section.add "X-Amz-Signature", valid_603564
  var valid_603565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "X-Amz-SignedHeaders", valid_603565
  var valid_603566 = header.getOrDefault("X-Amz-Credential")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "X-Amz-Credential", valid_603566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603568: Call_CreateUserImportJob_603556; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates the user import job.
  ## 
  let valid = call_603568.validator(path, query, header, formData, body)
  let scheme = call_603568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603568.url(scheme.get, call_603568.host, call_603568.base,
                         call_603568.route, valid.getOrDefault("path"))
  result = hook(call_603568, url, valid)

proc call*(call_603569: Call_CreateUserImportJob_603556; body: JsonNode): Recallable =
  ## createUserImportJob
  ## Creates the user import job.
  ##   body: JObject (required)
  var body_603570 = newJObject()
  if body != nil:
    body_603570 = body
  result = call_603569.call(nil, nil, nil, nil, body_603570)

var createUserImportJob* = Call_CreateUserImportJob_603556(
    name: "createUserImportJob", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserImportJob",
    validator: validate_CreateUserImportJob_603557, base: "/",
    url: url_CreateUserImportJob_603558, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserPool_603571 = ref object of OpenApiRestCall_602433
proc url_CreateUserPool_603573(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateUserPool_603572(path: JsonNode; query: JsonNode;
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
  var valid_603574 = header.getOrDefault("X-Amz-Date")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-Date", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-Security-Token")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-Security-Token", valid_603575
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603576 = header.getOrDefault("X-Amz-Target")
  valid_603576 = validateParameter(valid_603576, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserPool"))
  if valid_603576 != nil:
    section.add "X-Amz-Target", valid_603576
  var valid_603577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-Content-Sha256", valid_603577
  var valid_603578 = header.getOrDefault("X-Amz-Algorithm")
  valid_603578 = validateParameter(valid_603578, JString, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "X-Amz-Algorithm", valid_603578
  var valid_603579 = header.getOrDefault("X-Amz-Signature")
  valid_603579 = validateParameter(valid_603579, JString, required = false,
                                 default = nil)
  if valid_603579 != nil:
    section.add "X-Amz-Signature", valid_603579
  var valid_603580 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603580 = validateParameter(valid_603580, JString, required = false,
                                 default = nil)
  if valid_603580 != nil:
    section.add "X-Amz-SignedHeaders", valid_603580
  var valid_603581 = header.getOrDefault("X-Amz-Credential")
  valid_603581 = validateParameter(valid_603581, JString, required = false,
                                 default = nil)
  if valid_603581 != nil:
    section.add "X-Amz-Credential", valid_603581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603583: Call_CreateUserPool_603571; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon Cognito user pool and sets the password policy for the pool.
  ## 
  let valid = call_603583.validator(path, query, header, formData, body)
  let scheme = call_603583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603583.url(scheme.get, call_603583.host, call_603583.base,
                         call_603583.route, valid.getOrDefault("path"))
  result = hook(call_603583, url, valid)

proc call*(call_603584: Call_CreateUserPool_603571; body: JsonNode): Recallable =
  ## createUserPool
  ## Creates a new Amazon Cognito user pool and sets the password policy for the pool.
  ##   body: JObject (required)
  var body_603585 = newJObject()
  if body != nil:
    body_603585 = body
  result = call_603584.call(nil, nil, nil, nil, body_603585)

var createUserPool* = Call_CreateUserPool_603571(name: "createUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserPool",
    validator: validate_CreateUserPool_603572, base: "/", url: url_CreateUserPool_603573,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserPoolClient_603586 = ref object of OpenApiRestCall_602433
proc url_CreateUserPoolClient_603588(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateUserPoolClient_603587(path: JsonNode; query: JsonNode;
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
  var valid_603589 = header.getOrDefault("X-Amz-Date")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-Date", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Security-Token")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Security-Token", valid_603590
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603591 = header.getOrDefault("X-Amz-Target")
  valid_603591 = validateParameter(valid_603591, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserPoolClient"))
  if valid_603591 != nil:
    section.add "X-Amz-Target", valid_603591
  var valid_603592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-Content-Sha256", valid_603592
  var valid_603593 = header.getOrDefault("X-Amz-Algorithm")
  valid_603593 = validateParameter(valid_603593, JString, required = false,
                                 default = nil)
  if valid_603593 != nil:
    section.add "X-Amz-Algorithm", valid_603593
  var valid_603594 = header.getOrDefault("X-Amz-Signature")
  valid_603594 = validateParameter(valid_603594, JString, required = false,
                                 default = nil)
  if valid_603594 != nil:
    section.add "X-Amz-Signature", valid_603594
  var valid_603595 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603595 = validateParameter(valid_603595, JString, required = false,
                                 default = nil)
  if valid_603595 != nil:
    section.add "X-Amz-SignedHeaders", valid_603595
  var valid_603596 = header.getOrDefault("X-Amz-Credential")
  valid_603596 = validateParameter(valid_603596, JString, required = false,
                                 default = nil)
  if valid_603596 != nil:
    section.add "X-Amz-Credential", valid_603596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603598: Call_CreateUserPoolClient_603586; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates the user pool client.
  ## 
  let valid = call_603598.validator(path, query, header, formData, body)
  let scheme = call_603598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603598.url(scheme.get, call_603598.host, call_603598.base,
                         call_603598.route, valid.getOrDefault("path"))
  result = hook(call_603598, url, valid)

proc call*(call_603599: Call_CreateUserPoolClient_603586; body: JsonNode): Recallable =
  ## createUserPoolClient
  ## Creates the user pool client.
  ##   body: JObject (required)
  var body_603600 = newJObject()
  if body != nil:
    body_603600 = body
  result = call_603599.call(nil, nil, nil, nil, body_603600)

var createUserPoolClient* = Call_CreateUserPoolClient_603586(
    name: "createUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserPoolClient",
    validator: validate_CreateUserPoolClient_603587, base: "/",
    url: url_CreateUserPoolClient_603588, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserPoolDomain_603601 = ref object of OpenApiRestCall_602433
proc url_CreateUserPoolDomain_603603(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateUserPoolDomain_603602(path: JsonNode; query: JsonNode;
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
  var valid_603604 = header.getOrDefault("X-Amz-Date")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "X-Amz-Date", valid_603604
  var valid_603605 = header.getOrDefault("X-Amz-Security-Token")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-Security-Token", valid_603605
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603606 = header.getOrDefault("X-Amz-Target")
  valid_603606 = validateParameter(valid_603606, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserPoolDomain"))
  if valid_603606 != nil:
    section.add "X-Amz-Target", valid_603606
  var valid_603607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-Content-Sha256", valid_603607
  var valid_603608 = header.getOrDefault("X-Amz-Algorithm")
  valid_603608 = validateParameter(valid_603608, JString, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "X-Amz-Algorithm", valid_603608
  var valid_603609 = header.getOrDefault("X-Amz-Signature")
  valid_603609 = validateParameter(valid_603609, JString, required = false,
                                 default = nil)
  if valid_603609 != nil:
    section.add "X-Amz-Signature", valid_603609
  var valid_603610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603610 = validateParameter(valid_603610, JString, required = false,
                                 default = nil)
  if valid_603610 != nil:
    section.add "X-Amz-SignedHeaders", valid_603610
  var valid_603611 = header.getOrDefault("X-Amz-Credential")
  valid_603611 = validateParameter(valid_603611, JString, required = false,
                                 default = nil)
  if valid_603611 != nil:
    section.add "X-Amz-Credential", valid_603611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603613: Call_CreateUserPoolDomain_603601; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new domain for a user pool.
  ## 
  let valid = call_603613.validator(path, query, header, formData, body)
  let scheme = call_603613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603613.url(scheme.get, call_603613.host, call_603613.base,
                         call_603613.route, valid.getOrDefault("path"))
  result = hook(call_603613, url, valid)

proc call*(call_603614: Call_CreateUserPoolDomain_603601; body: JsonNode): Recallable =
  ## createUserPoolDomain
  ## Creates a new domain for a user pool.
  ##   body: JObject (required)
  var body_603615 = newJObject()
  if body != nil:
    body_603615 = body
  result = call_603614.call(nil, nil, nil, nil, body_603615)

var createUserPoolDomain* = Call_CreateUserPoolDomain_603601(
    name: "createUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserPoolDomain",
    validator: validate_CreateUserPoolDomain_603602, base: "/",
    url: url_CreateUserPoolDomain_603603, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_603616 = ref object of OpenApiRestCall_602433
proc url_DeleteGroup_603618(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteGroup_603617(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603619 = header.getOrDefault("X-Amz-Date")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-Date", valid_603619
  var valid_603620 = header.getOrDefault("X-Amz-Security-Token")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-Security-Token", valid_603620
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603621 = header.getOrDefault("X-Amz-Target")
  valid_603621 = validateParameter(valid_603621, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteGroup"))
  if valid_603621 != nil:
    section.add "X-Amz-Target", valid_603621
  var valid_603622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "X-Amz-Content-Sha256", valid_603622
  var valid_603623 = header.getOrDefault("X-Amz-Algorithm")
  valid_603623 = validateParameter(valid_603623, JString, required = false,
                                 default = nil)
  if valid_603623 != nil:
    section.add "X-Amz-Algorithm", valid_603623
  var valid_603624 = header.getOrDefault("X-Amz-Signature")
  valid_603624 = validateParameter(valid_603624, JString, required = false,
                                 default = nil)
  if valid_603624 != nil:
    section.add "X-Amz-Signature", valid_603624
  var valid_603625 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603625 = validateParameter(valid_603625, JString, required = false,
                                 default = nil)
  if valid_603625 != nil:
    section.add "X-Amz-SignedHeaders", valid_603625
  var valid_603626 = header.getOrDefault("X-Amz-Credential")
  valid_603626 = validateParameter(valid_603626, JString, required = false,
                                 default = nil)
  if valid_603626 != nil:
    section.add "X-Amz-Credential", valid_603626
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603628: Call_DeleteGroup_603616; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a group. Currently only groups with no members can be deleted.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_603628.validator(path, query, header, formData, body)
  let scheme = call_603628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603628.url(scheme.get, call_603628.host, call_603628.base,
                         call_603628.route, valid.getOrDefault("path"))
  result = hook(call_603628, url, valid)

proc call*(call_603629: Call_DeleteGroup_603616; body: JsonNode): Recallable =
  ## deleteGroup
  ## <p>Deletes a group. Currently only groups with no members can be deleted.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_603630 = newJObject()
  if body != nil:
    body_603630 = body
  result = call_603629.call(nil, nil, nil, nil, body_603630)

var deleteGroup* = Call_DeleteGroup_603616(name: "deleteGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteGroup",
                                        validator: validate_DeleteGroup_603617,
                                        base: "/", url: url_DeleteGroup_603618,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIdentityProvider_603631 = ref object of OpenApiRestCall_602433
proc url_DeleteIdentityProvider_603633(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteIdentityProvider_603632(path: JsonNode; query: JsonNode;
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
  var valid_603634 = header.getOrDefault("X-Amz-Date")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-Date", valid_603634
  var valid_603635 = header.getOrDefault("X-Amz-Security-Token")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "X-Amz-Security-Token", valid_603635
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603636 = header.getOrDefault("X-Amz-Target")
  valid_603636 = validateParameter(valid_603636, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteIdentityProvider"))
  if valid_603636 != nil:
    section.add "X-Amz-Target", valid_603636
  var valid_603637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "X-Amz-Content-Sha256", valid_603637
  var valid_603638 = header.getOrDefault("X-Amz-Algorithm")
  valid_603638 = validateParameter(valid_603638, JString, required = false,
                                 default = nil)
  if valid_603638 != nil:
    section.add "X-Amz-Algorithm", valid_603638
  var valid_603639 = header.getOrDefault("X-Amz-Signature")
  valid_603639 = validateParameter(valid_603639, JString, required = false,
                                 default = nil)
  if valid_603639 != nil:
    section.add "X-Amz-Signature", valid_603639
  var valid_603640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603640 = validateParameter(valid_603640, JString, required = false,
                                 default = nil)
  if valid_603640 != nil:
    section.add "X-Amz-SignedHeaders", valid_603640
  var valid_603641 = header.getOrDefault("X-Amz-Credential")
  valid_603641 = validateParameter(valid_603641, JString, required = false,
                                 default = nil)
  if valid_603641 != nil:
    section.add "X-Amz-Credential", valid_603641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603643: Call_DeleteIdentityProvider_603631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an identity provider for a user pool.
  ## 
  let valid = call_603643.validator(path, query, header, formData, body)
  let scheme = call_603643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603643.url(scheme.get, call_603643.host, call_603643.base,
                         call_603643.route, valid.getOrDefault("path"))
  result = hook(call_603643, url, valid)

proc call*(call_603644: Call_DeleteIdentityProvider_603631; body: JsonNode): Recallable =
  ## deleteIdentityProvider
  ## Deletes an identity provider for a user pool.
  ##   body: JObject (required)
  var body_603645 = newJObject()
  if body != nil:
    body_603645 = body
  result = call_603644.call(nil, nil, nil, nil, body_603645)

var deleteIdentityProvider* = Call_DeleteIdentityProvider_603631(
    name: "deleteIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteIdentityProvider",
    validator: validate_DeleteIdentityProvider_603632, base: "/",
    url: url_DeleteIdentityProvider_603633, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceServer_603646 = ref object of OpenApiRestCall_602433
proc url_DeleteResourceServer_603648(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteResourceServer_603647(path: JsonNode; query: JsonNode;
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
  var valid_603649 = header.getOrDefault("X-Amz-Date")
  valid_603649 = validateParameter(valid_603649, JString, required = false,
                                 default = nil)
  if valid_603649 != nil:
    section.add "X-Amz-Date", valid_603649
  var valid_603650 = header.getOrDefault("X-Amz-Security-Token")
  valid_603650 = validateParameter(valid_603650, JString, required = false,
                                 default = nil)
  if valid_603650 != nil:
    section.add "X-Amz-Security-Token", valid_603650
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603651 = header.getOrDefault("X-Amz-Target")
  valid_603651 = validateParameter(valid_603651, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteResourceServer"))
  if valid_603651 != nil:
    section.add "X-Amz-Target", valid_603651
  var valid_603652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "X-Amz-Content-Sha256", valid_603652
  var valid_603653 = header.getOrDefault("X-Amz-Algorithm")
  valid_603653 = validateParameter(valid_603653, JString, required = false,
                                 default = nil)
  if valid_603653 != nil:
    section.add "X-Amz-Algorithm", valid_603653
  var valid_603654 = header.getOrDefault("X-Amz-Signature")
  valid_603654 = validateParameter(valid_603654, JString, required = false,
                                 default = nil)
  if valid_603654 != nil:
    section.add "X-Amz-Signature", valid_603654
  var valid_603655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603655 = validateParameter(valid_603655, JString, required = false,
                                 default = nil)
  if valid_603655 != nil:
    section.add "X-Amz-SignedHeaders", valid_603655
  var valid_603656 = header.getOrDefault("X-Amz-Credential")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = nil)
  if valid_603656 != nil:
    section.add "X-Amz-Credential", valid_603656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603658: Call_DeleteResourceServer_603646; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a resource server.
  ## 
  let valid = call_603658.validator(path, query, header, formData, body)
  let scheme = call_603658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603658.url(scheme.get, call_603658.host, call_603658.base,
                         call_603658.route, valid.getOrDefault("path"))
  result = hook(call_603658, url, valid)

proc call*(call_603659: Call_DeleteResourceServer_603646; body: JsonNode): Recallable =
  ## deleteResourceServer
  ## Deletes a resource server.
  ##   body: JObject (required)
  var body_603660 = newJObject()
  if body != nil:
    body_603660 = body
  result = call_603659.call(nil, nil, nil, nil, body_603660)

var deleteResourceServer* = Call_DeleteResourceServer_603646(
    name: "deleteResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteResourceServer",
    validator: validate_DeleteResourceServer_603647, base: "/",
    url: url_DeleteResourceServer_603648, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_603661 = ref object of OpenApiRestCall_602433
proc url_DeleteUser_603663(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteUser_603662(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603664 = header.getOrDefault("X-Amz-Date")
  valid_603664 = validateParameter(valid_603664, JString, required = false,
                                 default = nil)
  if valid_603664 != nil:
    section.add "X-Amz-Date", valid_603664
  var valid_603665 = header.getOrDefault("X-Amz-Security-Token")
  valid_603665 = validateParameter(valid_603665, JString, required = false,
                                 default = nil)
  if valid_603665 != nil:
    section.add "X-Amz-Security-Token", valid_603665
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603666 = header.getOrDefault("X-Amz-Target")
  valid_603666 = validateParameter(valid_603666, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUser"))
  if valid_603666 != nil:
    section.add "X-Amz-Target", valid_603666
  var valid_603667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603667 = validateParameter(valid_603667, JString, required = false,
                                 default = nil)
  if valid_603667 != nil:
    section.add "X-Amz-Content-Sha256", valid_603667
  var valid_603668 = header.getOrDefault("X-Amz-Algorithm")
  valid_603668 = validateParameter(valid_603668, JString, required = false,
                                 default = nil)
  if valid_603668 != nil:
    section.add "X-Amz-Algorithm", valid_603668
  var valid_603669 = header.getOrDefault("X-Amz-Signature")
  valid_603669 = validateParameter(valid_603669, JString, required = false,
                                 default = nil)
  if valid_603669 != nil:
    section.add "X-Amz-Signature", valid_603669
  var valid_603670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603670 = validateParameter(valid_603670, JString, required = false,
                                 default = nil)
  if valid_603670 != nil:
    section.add "X-Amz-SignedHeaders", valid_603670
  var valid_603671 = header.getOrDefault("X-Amz-Credential")
  valid_603671 = validateParameter(valid_603671, JString, required = false,
                                 default = nil)
  if valid_603671 != nil:
    section.add "X-Amz-Credential", valid_603671
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603673: Call_DeleteUser_603661; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a user to delete himself or herself.
  ## 
  let valid = call_603673.validator(path, query, header, formData, body)
  let scheme = call_603673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603673.url(scheme.get, call_603673.host, call_603673.base,
                         call_603673.route, valid.getOrDefault("path"))
  result = hook(call_603673, url, valid)

proc call*(call_603674: Call_DeleteUser_603661; body: JsonNode): Recallable =
  ## deleteUser
  ## Allows a user to delete himself or herself.
  ##   body: JObject (required)
  var body_603675 = newJObject()
  if body != nil:
    body_603675 = body
  result = call_603674.call(nil, nil, nil, nil, body_603675)

var deleteUser* = Call_DeleteUser_603661(name: "deleteUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUser",
                                      validator: validate_DeleteUser_603662,
                                      base: "/", url: url_DeleteUser_603663,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserAttributes_603676 = ref object of OpenApiRestCall_602433
proc url_DeleteUserAttributes_603678(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteUserAttributes_603677(path: JsonNode; query: JsonNode;
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
  var valid_603679 = header.getOrDefault("X-Amz-Date")
  valid_603679 = validateParameter(valid_603679, JString, required = false,
                                 default = nil)
  if valid_603679 != nil:
    section.add "X-Amz-Date", valid_603679
  var valid_603680 = header.getOrDefault("X-Amz-Security-Token")
  valid_603680 = validateParameter(valid_603680, JString, required = false,
                                 default = nil)
  if valid_603680 != nil:
    section.add "X-Amz-Security-Token", valid_603680
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603681 = header.getOrDefault("X-Amz-Target")
  valid_603681 = validateParameter(valid_603681, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUserAttributes"))
  if valid_603681 != nil:
    section.add "X-Amz-Target", valid_603681
  var valid_603682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603682 = validateParameter(valid_603682, JString, required = false,
                                 default = nil)
  if valid_603682 != nil:
    section.add "X-Amz-Content-Sha256", valid_603682
  var valid_603683 = header.getOrDefault("X-Amz-Algorithm")
  valid_603683 = validateParameter(valid_603683, JString, required = false,
                                 default = nil)
  if valid_603683 != nil:
    section.add "X-Amz-Algorithm", valid_603683
  var valid_603684 = header.getOrDefault("X-Amz-Signature")
  valid_603684 = validateParameter(valid_603684, JString, required = false,
                                 default = nil)
  if valid_603684 != nil:
    section.add "X-Amz-Signature", valid_603684
  var valid_603685 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603685 = validateParameter(valid_603685, JString, required = false,
                                 default = nil)
  if valid_603685 != nil:
    section.add "X-Amz-SignedHeaders", valid_603685
  var valid_603686 = header.getOrDefault("X-Amz-Credential")
  valid_603686 = validateParameter(valid_603686, JString, required = false,
                                 default = nil)
  if valid_603686 != nil:
    section.add "X-Amz-Credential", valid_603686
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603688: Call_DeleteUserAttributes_603676; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the attributes for a user.
  ## 
  let valid = call_603688.validator(path, query, header, formData, body)
  let scheme = call_603688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603688.url(scheme.get, call_603688.host, call_603688.base,
                         call_603688.route, valid.getOrDefault("path"))
  result = hook(call_603688, url, valid)

proc call*(call_603689: Call_DeleteUserAttributes_603676; body: JsonNode): Recallable =
  ## deleteUserAttributes
  ## Deletes the attributes for a user.
  ##   body: JObject (required)
  var body_603690 = newJObject()
  if body != nil:
    body_603690 = body
  result = call_603689.call(nil, nil, nil, nil, body_603690)

var deleteUserAttributes* = Call_DeleteUserAttributes_603676(
    name: "deleteUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserAttributes",
    validator: validate_DeleteUserAttributes_603677, base: "/",
    url: url_DeleteUserAttributes_603678, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserPool_603691 = ref object of OpenApiRestCall_602433
proc url_DeleteUserPool_603693(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteUserPool_603692(path: JsonNode; query: JsonNode;
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
  var valid_603694 = header.getOrDefault("X-Amz-Date")
  valid_603694 = validateParameter(valid_603694, JString, required = false,
                                 default = nil)
  if valid_603694 != nil:
    section.add "X-Amz-Date", valid_603694
  var valid_603695 = header.getOrDefault("X-Amz-Security-Token")
  valid_603695 = validateParameter(valid_603695, JString, required = false,
                                 default = nil)
  if valid_603695 != nil:
    section.add "X-Amz-Security-Token", valid_603695
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603696 = header.getOrDefault("X-Amz-Target")
  valid_603696 = validateParameter(valid_603696, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUserPool"))
  if valid_603696 != nil:
    section.add "X-Amz-Target", valid_603696
  var valid_603697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603697 = validateParameter(valid_603697, JString, required = false,
                                 default = nil)
  if valid_603697 != nil:
    section.add "X-Amz-Content-Sha256", valid_603697
  var valid_603698 = header.getOrDefault("X-Amz-Algorithm")
  valid_603698 = validateParameter(valid_603698, JString, required = false,
                                 default = nil)
  if valid_603698 != nil:
    section.add "X-Amz-Algorithm", valid_603698
  var valid_603699 = header.getOrDefault("X-Amz-Signature")
  valid_603699 = validateParameter(valid_603699, JString, required = false,
                                 default = nil)
  if valid_603699 != nil:
    section.add "X-Amz-Signature", valid_603699
  var valid_603700 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603700 = validateParameter(valid_603700, JString, required = false,
                                 default = nil)
  if valid_603700 != nil:
    section.add "X-Amz-SignedHeaders", valid_603700
  var valid_603701 = header.getOrDefault("X-Amz-Credential")
  valid_603701 = validateParameter(valid_603701, JString, required = false,
                                 default = nil)
  if valid_603701 != nil:
    section.add "X-Amz-Credential", valid_603701
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603703: Call_DeleteUserPool_603691; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Amazon Cognito user pool.
  ## 
  let valid = call_603703.validator(path, query, header, formData, body)
  let scheme = call_603703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603703.url(scheme.get, call_603703.host, call_603703.base,
                         call_603703.route, valid.getOrDefault("path"))
  result = hook(call_603703, url, valid)

proc call*(call_603704: Call_DeleteUserPool_603691; body: JsonNode): Recallable =
  ## deleteUserPool
  ## Deletes the specified Amazon Cognito user pool.
  ##   body: JObject (required)
  var body_603705 = newJObject()
  if body != nil:
    body_603705 = body
  result = call_603704.call(nil, nil, nil, nil, body_603705)

var deleteUserPool* = Call_DeleteUserPool_603691(name: "deleteUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserPool",
    validator: validate_DeleteUserPool_603692, base: "/", url: url_DeleteUserPool_603693,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserPoolClient_603706 = ref object of OpenApiRestCall_602433
proc url_DeleteUserPoolClient_603708(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteUserPoolClient_603707(path: JsonNode; query: JsonNode;
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
  var valid_603709 = header.getOrDefault("X-Amz-Date")
  valid_603709 = validateParameter(valid_603709, JString, required = false,
                                 default = nil)
  if valid_603709 != nil:
    section.add "X-Amz-Date", valid_603709
  var valid_603710 = header.getOrDefault("X-Amz-Security-Token")
  valid_603710 = validateParameter(valid_603710, JString, required = false,
                                 default = nil)
  if valid_603710 != nil:
    section.add "X-Amz-Security-Token", valid_603710
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603711 = header.getOrDefault("X-Amz-Target")
  valid_603711 = validateParameter(valid_603711, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUserPoolClient"))
  if valid_603711 != nil:
    section.add "X-Amz-Target", valid_603711
  var valid_603712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603712 = validateParameter(valid_603712, JString, required = false,
                                 default = nil)
  if valid_603712 != nil:
    section.add "X-Amz-Content-Sha256", valid_603712
  var valid_603713 = header.getOrDefault("X-Amz-Algorithm")
  valid_603713 = validateParameter(valid_603713, JString, required = false,
                                 default = nil)
  if valid_603713 != nil:
    section.add "X-Amz-Algorithm", valid_603713
  var valid_603714 = header.getOrDefault("X-Amz-Signature")
  valid_603714 = validateParameter(valid_603714, JString, required = false,
                                 default = nil)
  if valid_603714 != nil:
    section.add "X-Amz-Signature", valid_603714
  var valid_603715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603715 = validateParameter(valid_603715, JString, required = false,
                                 default = nil)
  if valid_603715 != nil:
    section.add "X-Amz-SignedHeaders", valid_603715
  var valid_603716 = header.getOrDefault("X-Amz-Credential")
  valid_603716 = validateParameter(valid_603716, JString, required = false,
                                 default = nil)
  if valid_603716 != nil:
    section.add "X-Amz-Credential", valid_603716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603718: Call_DeleteUserPoolClient_603706; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows the developer to delete the user pool client.
  ## 
  let valid = call_603718.validator(path, query, header, formData, body)
  let scheme = call_603718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603718.url(scheme.get, call_603718.host, call_603718.base,
                         call_603718.route, valid.getOrDefault("path"))
  result = hook(call_603718, url, valid)

proc call*(call_603719: Call_DeleteUserPoolClient_603706; body: JsonNode): Recallable =
  ## deleteUserPoolClient
  ## Allows the developer to delete the user pool client.
  ##   body: JObject (required)
  var body_603720 = newJObject()
  if body != nil:
    body_603720 = body
  result = call_603719.call(nil, nil, nil, nil, body_603720)

var deleteUserPoolClient* = Call_DeleteUserPoolClient_603706(
    name: "deleteUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserPoolClient",
    validator: validate_DeleteUserPoolClient_603707, base: "/",
    url: url_DeleteUserPoolClient_603708, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserPoolDomain_603721 = ref object of OpenApiRestCall_602433
proc url_DeleteUserPoolDomain_603723(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteUserPoolDomain_603722(path: JsonNode; query: JsonNode;
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
  var valid_603724 = header.getOrDefault("X-Amz-Date")
  valid_603724 = validateParameter(valid_603724, JString, required = false,
                                 default = nil)
  if valid_603724 != nil:
    section.add "X-Amz-Date", valid_603724
  var valid_603725 = header.getOrDefault("X-Amz-Security-Token")
  valid_603725 = validateParameter(valid_603725, JString, required = false,
                                 default = nil)
  if valid_603725 != nil:
    section.add "X-Amz-Security-Token", valid_603725
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603726 = header.getOrDefault("X-Amz-Target")
  valid_603726 = validateParameter(valid_603726, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUserPoolDomain"))
  if valid_603726 != nil:
    section.add "X-Amz-Target", valid_603726
  var valid_603727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603727 = validateParameter(valid_603727, JString, required = false,
                                 default = nil)
  if valid_603727 != nil:
    section.add "X-Amz-Content-Sha256", valid_603727
  var valid_603728 = header.getOrDefault("X-Amz-Algorithm")
  valid_603728 = validateParameter(valid_603728, JString, required = false,
                                 default = nil)
  if valid_603728 != nil:
    section.add "X-Amz-Algorithm", valid_603728
  var valid_603729 = header.getOrDefault("X-Amz-Signature")
  valid_603729 = validateParameter(valid_603729, JString, required = false,
                                 default = nil)
  if valid_603729 != nil:
    section.add "X-Amz-Signature", valid_603729
  var valid_603730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603730 = validateParameter(valid_603730, JString, required = false,
                                 default = nil)
  if valid_603730 != nil:
    section.add "X-Amz-SignedHeaders", valid_603730
  var valid_603731 = header.getOrDefault("X-Amz-Credential")
  valid_603731 = validateParameter(valid_603731, JString, required = false,
                                 default = nil)
  if valid_603731 != nil:
    section.add "X-Amz-Credential", valid_603731
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603733: Call_DeleteUserPoolDomain_603721; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a domain for a user pool.
  ## 
  let valid = call_603733.validator(path, query, header, formData, body)
  let scheme = call_603733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603733.url(scheme.get, call_603733.host, call_603733.base,
                         call_603733.route, valid.getOrDefault("path"))
  result = hook(call_603733, url, valid)

proc call*(call_603734: Call_DeleteUserPoolDomain_603721; body: JsonNode): Recallable =
  ## deleteUserPoolDomain
  ## Deletes a domain for a user pool.
  ##   body: JObject (required)
  var body_603735 = newJObject()
  if body != nil:
    body_603735 = body
  result = call_603734.call(nil, nil, nil, nil, body_603735)

var deleteUserPoolDomain* = Call_DeleteUserPoolDomain_603721(
    name: "deleteUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserPoolDomain",
    validator: validate_DeleteUserPoolDomain_603722, base: "/",
    url: url_DeleteUserPoolDomain_603723, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentityProvider_603736 = ref object of OpenApiRestCall_602433
proc url_DescribeIdentityProvider_603738(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeIdentityProvider_603737(path: JsonNode; query: JsonNode;
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
  var valid_603739 = header.getOrDefault("X-Amz-Date")
  valid_603739 = validateParameter(valid_603739, JString, required = false,
                                 default = nil)
  if valid_603739 != nil:
    section.add "X-Amz-Date", valid_603739
  var valid_603740 = header.getOrDefault("X-Amz-Security-Token")
  valid_603740 = validateParameter(valid_603740, JString, required = false,
                                 default = nil)
  if valid_603740 != nil:
    section.add "X-Amz-Security-Token", valid_603740
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603741 = header.getOrDefault("X-Amz-Target")
  valid_603741 = validateParameter(valid_603741, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeIdentityProvider"))
  if valid_603741 != nil:
    section.add "X-Amz-Target", valid_603741
  var valid_603742 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603742 = validateParameter(valid_603742, JString, required = false,
                                 default = nil)
  if valid_603742 != nil:
    section.add "X-Amz-Content-Sha256", valid_603742
  var valid_603743 = header.getOrDefault("X-Amz-Algorithm")
  valid_603743 = validateParameter(valid_603743, JString, required = false,
                                 default = nil)
  if valid_603743 != nil:
    section.add "X-Amz-Algorithm", valid_603743
  var valid_603744 = header.getOrDefault("X-Amz-Signature")
  valid_603744 = validateParameter(valid_603744, JString, required = false,
                                 default = nil)
  if valid_603744 != nil:
    section.add "X-Amz-Signature", valid_603744
  var valid_603745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603745 = validateParameter(valid_603745, JString, required = false,
                                 default = nil)
  if valid_603745 != nil:
    section.add "X-Amz-SignedHeaders", valid_603745
  var valid_603746 = header.getOrDefault("X-Amz-Credential")
  valid_603746 = validateParameter(valid_603746, JString, required = false,
                                 default = nil)
  if valid_603746 != nil:
    section.add "X-Amz-Credential", valid_603746
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603748: Call_DescribeIdentityProvider_603736; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specific identity provider.
  ## 
  let valid = call_603748.validator(path, query, header, formData, body)
  let scheme = call_603748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603748.url(scheme.get, call_603748.host, call_603748.base,
                         call_603748.route, valid.getOrDefault("path"))
  result = hook(call_603748, url, valid)

proc call*(call_603749: Call_DescribeIdentityProvider_603736; body: JsonNode): Recallable =
  ## describeIdentityProvider
  ## Gets information about a specific identity provider.
  ##   body: JObject (required)
  var body_603750 = newJObject()
  if body != nil:
    body_603750 = body
  result = call_603749.call(nil, nil, nil, nil, body_603750)

var describeIdentityProvider* = Call_DescribeIdentityProvider_603736(
    name: "describeIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeIdentityProvider",
    validator: validate_DescribeIdentityProvider_603737, base: "/",
    url: url_DescribeIdentityProvider_603738, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResourceServer_603751 = ref object of OpenApiRestCall_602433
proc url_DescribeResourceServer_603753(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeResourceServer_603752(path: JsonNode; query: JsonNode;
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
  var valid_603754 = header.getOrDefault("X-Amz-Date")
  valid_603754 = validateParameter(valid_603754, JString, required = false,
                                 default = nil)
  if valid_603754 != nil:
    section.add "X-Amz-Date", valid_603754
  var valid_603755 = header.getOrDefault("X-Amz-Security-Token")
  valid_603755 = validateParameter(valid_603755, JString, required = false,
                                 default = nil)
  if valid_603755 != nil:
    section.add "X-Amz-Security-Token", valid_603755
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603756 = header.getOrDefault("X-Amz-Target")
  valid_603756 = validateParameter(valid_603756, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeResourceServer"))
  if valid_603756 != nil:
    section.add "X-Amz-Target", valid_603756
  var valid_603757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603757 = validateParameter(valid_603757, JString, required = false,
                                 default = nil)
  if valid_603757 != nil:
    section.add "X-Amz-Content-Sha256", valid_603757
  var valid_603758 = header.getOrDefault("X-Amz-Algorithm")
  valid_603758 = validateParameter(valid_603758, JString, required = false,
                                 default = nil)
  if valid_603758 != nil:
    section.add "X-Amz-Algorithm", valid_603758
  var valid_603759 = header.getOrDefault("X-Amz-Signature")
  valid_603759 = validateParameter(valid_603759, JString, required = false,
                                 default = nil)
  if valid_603759 != nil:
    section.add "X-Amz-Signature", valid_603759
  var valid_603760 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603760 = validateParameter(valid_603760, JString, required = false,
                                 default = nil)
  if valid_603760 != nil:
    section.add "X-Amz-SignedHeaders", valid_603760
  var valid_603761 = header.getOrDefault("X-Amz-Credential")
  valid_603761 = validateParameter(valid_603761, JString, required = false,
                                 default = nil)
  if valid_603761 != nil:
    section.add "X-Amz-Credential", valid_603761
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603763: Call_DescribeResourceServer_603751; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a resource server.
  ## 
  let valid = call_603763.validator(path, query, header, formData, body)
  let scheme = call_603763.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603763.url(scheme.get, call_603763.host, call_603763.base,
                         call_603763.route, valid.getOrDefault("path"))
  result = hook(call_603763, url, valid)

proc call*(call_603764: Call_DescribeResourceServer_603751; body: JsonNode): Recallable =
  ## describeResourceServer
  ## Describes a resource server.
  ##   body: JObject (required)
  var body_603765 = newJObject()
  if body != nil:
    body_603765 = body
  result = call_603764.call(nil, nil, nil, nil, body_603765)

var describeResourceServer* = Call_DescribeResourceServer_603751(
    name: "describeResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeResourceServer",
    validator: validate_DescribeResourceServer_603752, base: "/",
    url: url_DescribeResourceServer_603753, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRiskConfiguration_603766 = ref object of OpenApiRestCall_602433
proc url_DescribeRiskConfiguration_603768(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeRiskConfiguration_603767(path: JsonNode; query: JsonNode;
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
  var valid_603769 = header.getOrDefault("X-Amz-Date")
  valid_603769 = validateParameter(valid_603769, JString, required = false,
                                 default = nil)
  if valid_603769 != nil:
    section.add "X-Amz-Date", valid_603769
  var valid_603770 = header.getOrDefault("X-Amz-Security-Token")
  valid_603770 = validateParameter(valid_603770, JString, required = false,
                                 default = nil)
  if valid_603770 != nil:
    section.add "X-Amz-Security-Token", valid_603770
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603771 = header.getOrDefault("X-Amz-Target")
  valid_603771 = validateParameter(valid_603771, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeRiskConfiguration"))
  if valid_603771 != nil:
    section.add "X-Amz-Target", valid_603771
  var valid_603772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603772 = validateParameter(valid_603772, JString, required = false,
                                 default = nil)
  if valid_603772 != nil:
    section.add "X-Amz-Content-Sha256", valid_603772
  var valid_603773 = header.getOrDefault("X-Amz-Algorithm")
  valid_603773 = validateParameter(valid_603773, JString, required = false,
                                 default = nil)
  if valid_603773 != nil:
    section.add "X-Amz-Algorithm", valid_603773
  var valid_603774 = header.getOrDefault("X-Amz-Signature")
  valid_603774 = validateParameter(valid_603774, JString, required = false,
                                 default = nil)
  if valid_603774 != nil:
    section.add "X-Amz-Signature", valid_603774
  var valid_603775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603775 = validateParameter(valid_603775, JString, required = false,
                                 default = nil)
  if valid_603775 != nil:
    section.add "X-Amz-SignedHeaders", valid_603775
  var valid_603776 = header.getOrDefault("X-Amz-Credential")
  valid_603776 = validateParameter(valid_603776, JString, required = false,
                                 default = nil)
  if valid_603776 != nil:
    section.add "X-Amz-Credential", valid_603776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603778: Call_DescribeRiskConfiguration_603766; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the risk configuration.
  ## 
  let valid = call_603778.validator(path, query, header, formData, body)
  let scheme = call_603778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603778.url(scheme.get, call_603778.host, call_603778.base,
                         call_603778.route, valid.getOrDefault("path"))
  result = hook(call_603778, url, valid)

proc call*(call_603779: Call_DescribeRiskConfiguration_603766; body: JsonNode): Recallable =
  ## describeRiskConfiguration
  ## Describes the risk configuration.
  ##   body: JObject (required)
  var body_603780 = newJObject()
  if body != nil:
    body_603780 = body
  result = call_603779.call(nil, nil, nil, nil, body_603780)

var describeRiskConfiguration* = Call_DescribeRiskConfiguration_603766(
    name: "describeRiskConfiguration", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeRiskConfiguration",
    validator: validate_DescribeRiskConfiguration_603767, base: "/",
    url: url_DescribeRiskConfiguration_603768,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserImportJob_603781 = ref object of OpenApiRestCall_602433
proc url_DescribeUserImportJob_603783(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeUserImportJob_603782(path: JsonNode; query: JsonNode;
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
  var valid_603784 = header.getOrDefault("X-Amz-Date")
  valid_603784 = validateParameter(valid_603784, JString, required = false,
                                 default = nil)
  if valid_603784 != nil:
    section.add "X-Amz-Date", valid_603784
  var valid_603785 = header.getOrDefault("X-Amz-Security-Token")
  valid_603785 = validateParameter(valid_603785, JString, required = false,
                                 default = nil)
  if valid_603785 != nil:
    section.add "X-Amz-Security-Token", valid_603785
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603786 = header.getOrDefault("X-Amz-Target")
  valid_603786 = validateParameter(valid_603786, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserImportJob"))
  if valid_603786 != nil:
    section.add "X-Amz-Target", valid_603786
  var valid_603787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603787 = validateParameter(valid_603787, JString, required = false,
                                 default = nil)
  if valid_603787 != nil:
    section.add "X-Amz-Content-Sha256", valid_603787
  var valid_603788 = header.getOrDefault("X-Amz-Algorithm")
  valid_603788 = validateParameter(valid_603788, JString, required = false,
                                 default = nil)
  if valid_603788 != nil:
    section.add "X-Amz-Algorithm", valid_603788
  var valid_603789 = header.getOrDefault("X-Amz-Signature")
  valid_603789 = validateParameter(valid_603789, JString, required = false,
                                 default = nil)
  if valid_603789 != nil:
    section.add "X-Amz-Signature", valid_603789
  var valid_603790 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603790 = validateParameter(valid_603790, JString, required = false,
                                 default = nil)
  if valid_603790 != nil:
    section.add "X-Amz-SignedHeaders", valid_603790
  var valid_603791 = header.getOrDefault("X-Amz-Credential")
  valid_603791 = validateParameter(valid_603791, JString, required = false,
                                 default = nil)
  if valid_603791 != nil:
    section.add "X-Amz-Credential", valid_603791
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603793: Call_DescribeUserImportJob_603781; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the user import job.
  ## 
  let valid = call_603793.validator(path, query, header, formData, body)
  let scheme = call_603793.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603793.url(scheme.get, call_603793.host, call_603793.base,
                         call_603793.route, valid.getOrDefault("path"))
  result = hook(call_603793, url, valid)

proc call*(call_603794: Call_DescribeUserImportJob_603781; body: JsonNode): Recallable =
  ## describeUserImportJob
  ## Describes the user import job.
  ##   body: JObject (required)
  var body_603795 = newJObject()
  if body != nil:
    body_603795 = body
  result = call_603794.call(nil, nil, nil, nil, body_603795)

var describeUserImportJob* = Call_DescribeUserImportJob_603781(
    name: "describeUserImportJob", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserImportJob",
    validator: validate_DescribeUserImportJob_603782, base: "/",
    url: url_DescribeUserImportJob_603783, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserPool_603796 = ref object of OpenApiRestCall_602433
proc url_DescribeUserPool_603798(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeUserPool_603797(path: JsonNode; query: JsonNode;
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
  var valid_603799 = header.getOrDefault("X-Amz-Date")
  valid_603799 = validateParameter(valid_603799, JString, required = false,
                                 default = nil)
  if valid_603799 != nil:
    section.add "X-Amz-Date", valid_603799
  var valid_603800 = header.getOrDefault("X-Amz-Security-Token")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "X-Amz-Security-Token", valid_603800
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603801 = header.getOrDefault("X-Amz-Target")
  valid_603801 = validateParameter(valid_603801, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserPool"))
  if valid_603801 != nil:
    section.add "X-Amz-Target", valid_603801
  var valid_603802 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603802 = validateParameter(valid_603802, JString, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "X-Amz-Content-Sha256", valid_603802
  var valid_603803 = header.getOrDefault("X-Amz-Algorithm")
  valid_603803 = validateParameter(valid_603803, JString, required = false,
                                 default = nil)
  if valid_603803 != nil:
    section.add "X-Amz-Algorithm", valid_603803
  var valid_603804 = header.getOrDefault("X-Amz-Signature")
  valid_603804 = validateParameter(valid_603804, JString, required = false,
                                 default = nil)
  if valid_603804 != nil:
    section.add "X-Amz-Signature", valid_603804
  var valid_603805 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603805 = validateParameter(valid_603805, JString, required = false,
                                 default = nil)
  if valid_603805 != nil:
    section.add "X-Amz-SignedHeaders", valid_603805
  var valid_603806 = header.getOrDefault("X-Amz-Credential")
  valid_603806 = validateParameter(valid_603806, JString, required = false,
                                 default = nil)
  if valid_603806 != nil:
    section.add "X-Amz-Credential", valid_603806
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603808: Call_DescribeUserPool_603796; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the configuration information and metadata of the specified user pool.
  ## 
  let valid = call_603808.validator(path, query, header, formData, body)
  let scheme = call_603808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603808.url(scheme.get, call_603808.host, call_603808.base,
                         call_603808.route, valid.getOrDefault("path"))
  result = hook(call_603808, url, valid)

proc call*(call_603809: Call_DescribeUserPool_603796; body: JsonNode): Recallable =
  ## describeUserPool
  ## Returns the configuration information and metadata of the specified user pool.
  ##   body: JObject (required)
  var body_603810 = newJObject()
  if body != nil:
    body_603810 = body
  result = call_603809.call(nil, nil, nil, nil, body_603810)

var describeUserPool* = Call_DescribeUserPool_603796(name: "describeUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserPool",
    validator: validate_DescribeUserPool_603797, base: "/",
    url: url_DescribeUserPool_603798, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserPoolClient_603811 = ref object of OpenApiRestCall_602433
proc url_DescribeUserPoolClient_603813(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeUserPoolClient_603812(path: JsonNode; query: JsonNode;
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
  var valid_603814 = header.getOrDefault("X-Amz-Date")
  valid_603814 = validateParameter(valid_603814, JString, required = false,
                                 default = nil)
  if valid_603814 != nil:
    section.add "X-Amz-Date", valid_603814
  var valid_603815 = header.getOrDefault("X-Amz-Security-Token")
  valid_603815 = validateParameter(valid_603815, JString, required = false,
                                 default = nil)
  if valid_603815 != nil:
    section.add "X-Amz-Security-Token", valid_603815
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603816 = header.getOrDefault("X-Amz-Target")
  valid_603816 = validateParameter(valid_603816, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserPoolClient"))
  if valid_603816 != nil:
    section.add "X-Amz-Target", valid_603816
  var valid_603817 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603817 = validateParameter(valid_603817, JString, required = false,
                                 default = nil)
  if valid_603817 != nil:
    section.add "X-Amz-Content-Sha256", valid_603817
  var valid_603818 = header.getOrDefault("X-Amz-Algorithm")
  valid_603818 = validateParameter(valid_603818, JString, required = false,
                                 default = nil)
  if valid_603818 != nil:
    section.add "X-Amz-Algorithm", valid_603818
  var valid_603819 = header.getOrDefault("X-Amz-Signature")
  valid_603819 = validateParameter(valid_603819, JString, required = false,
                                 default = nil)
  if valid_603819 != nil:
    section.add "X-Amz-Signature", valid_603819
  var valid_603820 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603820 = validateParameter(valid_603820, JString, required = false,
                                 default = nil)
  if valid_603820 != nil:
    section.add "X-Amz-SignedHeaders", valid_603820
  var valid_603821 = header.getOrDefault("X-Amz-Credential")
  valid_603821 = validateParameter(valid_603821, JString, required = false,
                                 default = nil)
  if valid_603821 != nil:
    section.add "X-Amz-Credential", valid_603821
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603823: Call_DescribeUserPoolClient_603811; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Client method for returning the configuration information and metadata of the specified user pool app client.
  ## 
  let valid = call_603823.validator(path, query, header, formData, body)
  let scheme = call_603823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603823.url(scheme.get, call_603823.host, call_603823.base,
                         call_603823.route, valid.getOrDefault("path"))
  result = hook(call_603823, url, valid)

proc call*(call_603824: Call_DescribeUserPoolClient_603811; body: JsonNode): Recallable =
  ## describeUserPoolClient
  ## Client method for returning the configuration information and metadata of the specified user pool app client.
  ##   body: JObject (required)
  var body_603825 = newJObject()
  if body != nil:
    body_603825 = body
  result = call_603824.call(nil, nil, nil, nil, body_603825)

var describeUserPoolClient* = Call_DescribeUserPoolClient_603811(
    name: "describeUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserPoolClient",
    validator: validate_DescribeUserPoolClient_603812, base: "/",
    url: url_DescribeUserPoolClient_603813, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserPoolDomain_603826 = ref object of OpenApiRestCall_602433
proc url_DescribeUserPoolDomain_603828(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeUserPoolDomain_603827(path: JsonNode; query: JsonNode;
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
  var valid_603829 = header.getOrDefault("X-Amz-Date")
  valid_603829 = validateParameter(valid_603829, JString, required = false,
                                 default = nil)
  if valid_603829 != nil:
    section.add "X-Amz-Date", valid_603829
  var valid_603830 = header.getOrDefault("X-Amz-Security-Token")
  valid_603830 = validateParameter(valid_603830, JString, required = false,
                                 default = nil)
  if valid_603830 != nil:
    section.add "X-Amz-Security-Token", valid_603830
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603831 = header.getOrDefault("X-Amz-Target")
  valid_603831 = validateParameter(valid_603831, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserPoolDomain"))
  if valid_603831 != nil:
    section.add "X-Amz-Target", valid_603831
  var valid_603832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603832 = validateParameter(valid_603832, JString, required = false,
                                 default = nil)
  if valid_603832 != nil:
    section.add "X-Amz-Content-Sha256", valid_603832
  var valid_603833 = header.getOrDefault("X-Amz-Algorithm")
  valid_603833 = validateParameter(valid_603833, JString, required = false,
                                 default = nil)
  if valid_603833 != nil:
    section.add "X-Amz-Algorithm", valid_603833
  var valid_603834 = header.getOrDefault("X-Amz-Signature")
  valid_603834 = validateParameter(valid_603834, JString, required = false,
                                 default = nil)
  if valid_603834 != nil:
    section.add "X-Amz-Signature", valid_603834
  var valid_603835 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603835 = validateParameter(valid_603835, JString, required = false,
                                 default = nil)
  if valid_603835 != nil:
    section.add "X-Amz-SignedHeaders", valid_603835
  var valid_603836 = header.getOrDefault("X-Amz-Credential")
  valid_603836 = validateParameter(valid_603836, JString, required = false,
                                 default = nil)
  if valid_603836 != nil:
    section.add "X-Amz-Credential", valid_603836
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603838: Call_DescribeUserPoolDomain_603826; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a domain.
  ## 
  let valid = call_603838.validator(path, query, header, formData, body)
  let scheme = call_603838.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603838.url(scheme.get, call_603838.host, call_603838.base,
                         call_603838.route, valid.getOrDefault("path"))
  result = hook(call_603838, url, valid)

proc call*(call_603839: Call_DescribeUserPoolDomain_603826; body: JsonNode): Recallable =
  ## describeUserPoolDomain
  ## Gets information about a domain.
  ##   body: JObject (required)
  var body_603840 = newJObject()
  if body != nil:
    body_603840 = body
  result = call_603839.call(nil, nil, nil, nil, body_603840)

var describeUserPoolDomain* = Call_DescribeUserPoolDomain_603826(
    name: "describeUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserPoolDomain",
    validator: validate_DescribeUserPoolDomain_603827, base: "/",
    url: url_DescribeUserPoolDomain_603828, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ForgetDevice_603841 = ref object of OpenApiRestCall_602433
proc url_ForgetDevice_603843(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ForgetDevice_603842(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603844 = header.getOrDefault("X-Amz-Date")
  valid_603844 = validateParameter(valid_603844, JString, required = false,
                                 default = nil)
  if valid_603844 != nil:
    section.add "X-Amz-Date", valid_603844
  var valid_603845 = header.getOrDefault("X-Amz-Security-Token")
  valid_603845 = validateParameter(valid_603845, JString, required = false,
                                 default = nil)
  if valid_603845 != nil:
    section.add "X-Amz-Security-Token", valid_603845
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603846 = header.getOrDefault("X-Amz-Target")
  valid_603846 = validateParameter(valid_603846, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ForgetDevice"))
  if valid_603846 != nil:
    section.add "X-Amz-Target", valid_603846
  var valid_603847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603847 = validateParameter(valid_603847, JString, required = false,
                                 default = nil)
  if valid_603847 != nil:
    section.add "X-Amz-Content-Sha256", valid_603847
  var valid_603848 = header.getOrDefault("X-Amz-Algorithm")
  valid_603848 = validateParameter(valid_603848, JString, required = false,
                                 default = nil)
  if valid_603848 != nil:
    section.add "X-Amz-Algorithm", valid_603848
  var valid_603849 = header.getOrDefault("X-Amz-Signature")
  valid_603849 = validateParameter(valid_603849, JString, required = false,
                                 default = nil)
  if valid_603849 != nil:
    section.add "X-Amz-Signature", valid_603849
  var valid_603850 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603850 = validateParameter(valid_603850, JString, required = false,
                                 default = nil)
  if valid_603850 != nil:
    section.add "X-Amz-SignedHeaders", valid_603850
  var valid_603851 = header.getOrDefault("X-Amz-Credential")
  valid_603851 = validateParameter(valid_603851, JString, required = false,
                                 default = nil)
  if valid_603851 != nil:
    section.add "X-Amz-Credential", valid_603851
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603853: Call_ForgetDevice_603841; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Forgets the specified device.
  ## 
  let valid = call_603853.validator(path, query, header, formData, body)
  let scheme = call_603853.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603853.url(scheme.get, call_603853.host, call_603853.base,
                         call_603853.route, valid.getOrDefault("path"))
  result = hook(call_603853, url, valid)

proc call*(call_603854: Call_ForgetDevice_603841; body: JsonNode): Recallable =
  ## forgetDevice
  ## Forgets the specified device.
  ##   body: JObject (required)
  var body_603855 = newJObject()
  if body != nil:
    body_603855 = body
  result = call_603854.call(nil, nil, nil, nil, body_603855)

var forgetDevice* = Call_ForgetDevice_603841(name: "forgetDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ForgetDevice",
    validator: validate_ForgetDevice_603842, base: "/", url: url_ForgetDevice_603843,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ForgotPassword_603856 = ref object of OpenApiRestCall_602433
proc url_ForgotPassword_603858(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ForgotPassword_603857(path: JsonNode; query: JsonNode;
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
  var valid_603859 = header.getOrDefault("X-Amz-Date")
  valid_603859 = validateParameter(valid_603859, JString, required = false,
                                 default = nil)
  if valid_603859 != nil:
    section.add "X-Amz-Date", valid_603859
  var valid_603860 = header.getOrDefault("X-Amz-Security-Token")
  valid_603860 = validateParameter(valid_603860, JString, required = false,
                                 default = nil)
  if valid_603860 != nil:
    section.add "X-Amz-Security-Token", valid_603860
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603861 = header.getOrDefault("X-Amz-Target")
  valid_603861 = validateParameter(valid_603861, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ForgotPassword"))
  if valid_603861 != nil:
    section.add "X-Amz-Target", valid_603861
  var valid_603862 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603862 = validateParameter(valid_603862, JString, required = false,
                                 default = nil)
  if valid_603862 != nil:
    section.add "X-Amz-Content-Sha256", valid_603862
  var valid_603863 = header.getOrDefault("X-Amz-Algorithm")
  valid_603863 = validateParameter(valid_603863, JString, required = false,
                                 default = nil)
  if valid_603863 != nil:
    section.add "X-Amz-Algorithm", valid_603863
  var valid_603864 = header.getOrDefault("X-Amz-Signature")
  valid_603864 = validateParameter(valid_603864, JString, required = false,
                                 default = nil)
  if valid_603864 != nil:
    section.add "X-Amz-Signature", valid_603864
  var valid_603865 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603865 = validateParameter(valid_603865, JString, required = false,
                                 default = nil)
  if valid_603865 != nil:
    section.add "X-Amz-SignedHeaders", valid_603865
  var valid_603866 = header.getOrDefault("X-Amz-Credential")
  valid_603866 = validateParameter(valid_603866, JString, required = false,
                                 default = nil)
  if valid_603866 != nil:
    section.add "X-Amz-Credential", valid_603866
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603868: Call_ForgotPassword_603856; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Calling this API causes a message to be sent to the end user with a confirmation code that is required to change the user's password. For the <code>Username</code> parameter, you can use the username or user alias. If a verified phone number exists for the user, the confirmation code is sent to the phone number. Otherwise, if a verified email exists, the confirmation code is sent to the email. If neither a verified phone number nor a verified email exists, <code>InvalidParameterException</code> is thrown. To use the confirmation code for resetting the password, call .
  ## 
  let valid = call_603868.validator(path, query, header, formData, body)
  let scheme = call_603868.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603868.url(scheme.get, call_603868.host, call_603868.base,
                         call_603868.route, valid.getOrDefault("path"))
  result = hook(call_603868, url, valid)

proc call*(call_603869: Call_ForgotPassword_603856; body: JsonNode): Recallable =
  ## forgotPassword
  ## Calling this API causes a message to be sent to the end user with a confirmation code that is required to change the user's password. For the <code>Username</code> parameter, you can use the username or user alias. If a verified phone number exists for the user, the confirmation code is sent to the phone number. Otherwise, if a verified email exists, the confirmation code is sent to the email. If neither a verified phone number nor a verified email exists, <code>InvalidParameterException</code> is thrown. To use the confirmation code for resetting the password, call .
  ##   body: JObject (required)
  var body_603870 = newJObject()
  if body != nil:
    body_603870 = body
  result = call_603869.call(nil, nil, nil, nil, body_603870)

var forgotPassword* = Call_ForgotPassword_603856(name: "forgotPassword",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ForgotPassword",
    validator: validate_ForgotPassword_603857, base: "/", url: url_ForgotPassword_603858,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCSVHeader_603871 = ref object of OpenApiRestCall_602433
proc url_GetCSVHeader_603873(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCSVHeader_603872(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603874 = header.getOrDefault("X-Amz-Date")
  valid_603874 = validateParameter(valid_603874, JString, required = false,
                                 default = nil)
  if valid_603874 != nil:
    section.add "X-Amz-Date", valid_603874
  var valid_603875 = header.getOrDefault("X-Amz-Security-Token")
  valid_603875 = validateParameter(valid_603875, JString, required = false,
                                 default = nil)
  if valid_603875 != nil:
    section.add "X-Amz-Security-Token", valid_603875
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603876 = header.getOrDefault("X-Amz-Target")
  valid_603876 = validateParameter(valid_603876, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetCSVHeader"))
  if valid_603876 != nil:
    section.add "X-Amz-Target", valid_603876
  var valid_603877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603877 = validateParameter(valid_603877, JString, required = false,
                                 default = nil)
  if valid_603877 != nil:
    section.add "X-Amz-Content-Sha256", valid_603877
  var valid_603878 = header.getOrDefault("X-Amz-Algorithm")
  valid_603878 = validateParameter(valid_603878, JString, required = false,
                                 default = nil)
  if valid_603878 != nil:
    section.add "X-Amz-Algorithm", valid_603878
  var valid_603879 = header.getOrDefault("X-Amz-Signature")
  valid_603879 = validateParameter(valid_603879, JString, required = false,
                                 default = nil)
  if valid_603879 != nil:
    section.add "X-Amz-Signature", valid_603879
  var valid_603880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603880 = validateParameter(valid_603880, JString, required = false,
                                 default = nil)
  if valid_603880 != nil:
    section.add "X-Amz-SignedHeaders", valid_603880
  var valid_603881 = header.getOrDefault("X-Amz-Credential")
  valid_603881 = validateParameter(valid_603881, JString, required = false,
                                 default = nil)
  if valid_603881 != nil:
    section.add "X-Amz-Credential", valid_603881
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603883: Call_GetCSVHeader_603871; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the header information for the .csv file to be used as input for the user import job.
  ## 
  let valid = call_603883.validator(path, query, header, formData, body)
  let scheme = call_603883.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603883.url(scheme.get, call_603883.host, call_603883.base,
                         call_603883.route, valid.getOrDefault("path"))
  result = hook(call_603883, url, valid)

proc call*(call_603884: Call_GetCSVHeader_603871; body: JsonNode): Recallable =
  ## getCSVHeader
  ## Gets the header information for the .csv file to be used as input for the user import job.
  ##   body: JObject (required)
  var body_603885 = newJObject()
  if body != nil:
    body_603885 = body
  result = call_603884.call(nil, nil, nil, nil, body_603885)

var getCSVHeader* = Call_GetCSVHeader_603871(name: "getCSVHeader",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetCSVHeader",
    validator: validate_GetCSVHeader_603872, base: "/", url: url_GetCSVHeader_603873,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevice_603886 = ref object of OpenApiRestCall_602433
proc url_GetDevice_603888(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDevice_603887(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603889 = header.getOrDefault("X-Amz-Date")
  valid_603889 = validateParameter(valid_603889, JString, required = false,
                                 default = nil)
  if valid_603889 != nil:
    section.add "X-Amz-Date", valid_603889
  var valid_603890 = header.getOrDefault("X-Amz-Security-Token")
  valid_603890 = validateParameter(valid_603890, JString, required = false,
                                 default = nil)
  if valid_603890 != nil:
    section.add "X-Amz-Security-Token", valid_603890
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603891 = header.getOrDefault("X-Amz-Target")
  valid_603891 = validateParameter(valid_603891, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetDevice"))
  if valid_603891 != nil:
    section.add "X-Amz-Target", valid_603891
  var valid_603892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603892 = validateParameter(valid_603892, JString, required = false,
                                 default = nil)
  if valid_603892 != nil:
    section.add "X-Amz-Content-Sha256", valid_603892
  var valid_603893 = header.getOrDefault("X-Amz-Algorithm")
  valid_603893 = validateParameter(valid_603893, JString, required = false,
                                 default = nil)
  if valid_603893 != nil:
    section.add "X-Amz-Algorithm", valid_603893
  var valid_603894 = header.getOrDefault("X-Amz-Signature")
  valid_603894 = validateParameter(valid_603894, JString, required = false,
                                 default = nil)
  if valid_603894 != nil:
    section.add "X-Amz-Signature", valid_603894
  var valid_603895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603895 = validateParameter(valid_603895, JString, required = false,
                                 default = nil)
  if valid_603895 != nil:
    section.add "X-Amz-SignedHeaders", valid_603895
  var valid_603896 = header.getOrDefault("X-Amz-Credential")
  valid_603896 = validateParameter(valid_603896, JString, required = false,
                                 default = nil)
  if valid_603896 != nil:
    section.add "X-Amz-Credential", valid_603896
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603898: Call_GetDevice_603886; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the device.
  ## 
  let valid = call_603898.validator(path, query, header, formData, body)
  let scheme = call_603898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603898.url(scheme.get, call_603898.host, call_603898.base,
                         call_603898.route, valid.getOrDefault("path"))
  result = hook(call_603898, url, valid)

proc call*(call_603899: Call_GetDevice_603886; body: JsonNode): Recallable =
  ## getDevice
  ## Gets the device.
  ##   body: JObject (required)
  var body_603900 = newJObject()
  if body != nil:
    body_603900 = body
  result = call_603899.call(nil, nil, nil, nil, body_603900)

var getDevice* = Call_GetDevice_603886(name: "getDevice", meth: HttpMethod.HttpPost,
                                    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetDevice",
                                    validator: validate_GetDevice_603887,
                                    base: "/", url: url_GetDevice_603888,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroup_603901 = ref object of OpenApiRestCall_602433
proc url_GetGroup_603903(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGroup_603902(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603904 = header.getOrDefault("X-Amz-Date")
  valid_603904 = validateParameter(valid_603904, JString, required = false,
                                 default = nil)
  if valid_603904 != nil:
    section.add "X-Amz-Date", valid_603904
  var valid_603905 = header.getOrDefault("X-Amz-Security-Token")
  valid_603905 = validateParameter(valid_603905, JString, required = false,
                                 default = nil)
  if valid_603905 != nil:
    section.add "X-Amz-Security-Token", valid_603905
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603906 = header.getOrDefault("X-Amz-Target")
  valid_603906 = validateParameter(valid_603906, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetGroup"))
  if valid_603906 != nil:
    section.add "X-Amz-Target", valid_603906
  var valid_603907 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603907 = validateParameter(valid_603907, JString, required = false,
                                 default = nil)
  if valid_603907 != nil:
    section.add "X-Amz-Content-Sha256", valid_603907
  var valid_603908 = header.getOrDefault("X-Amz-Algorithm")
  valid_603908 = validateParameter(valid_603908, JString, required = false,
                                 default = nil)
  if valid_603908 != nil:
    section.add "X-Amz-Algorithm", valid_603908
  var valid_603909 = header.getOrDefault("X-Amz-Signature")
  valid_603909 = validateParameter(valid_603909, JString, required = false,
                                 default = nil)
  if valid_603909 != nil:
    section.add "X-Amz-Signature", valid_603909
  var valid_603910 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603910 = validateParameter(valid_603910, JString, required = false,
                                 default = nil)
  if valid_603910 != nil:
    section.add "X-Amz-SignedHeaders", valid_603910
  var valid_603911 = header.getOrDefault("X-Amz-Credential")
  valid_603911 = validateParameter(valid_603911, JString, required = false,
                                 default = nil)
  if valid_603911 != nil:
    section.add "X-Amz-Credential", valid_603911
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603913: Call_GetGroup_603901; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a group.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_603913.validator(path, query, header, formData, body)
  let scheme = call_603913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603913.url(scheme.get, call_603913.host, call_603913.base,
                         call_603913.route, valid.getOrDefault("path"))
  result = hook(call_603913, url, valid)

proc call*(call_603914: Call_GetGroup_603901; body: JsonNode): Recallable =
  ## getGroup
  ## <p>Gets a group.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_603915 = newJObject()
  if body != nil:
    body_603915 = body
  result = call_603914.call(nil, nil, nil, nil, body_603915)

var getGroup* = Call_GetGroup_603901(name: "getGroup", meth: HttpMethod.HttpPost,
                                  host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetGroup",
                                  validator: validate_GetGroup_603902, base: "/",
                                  url: url_GetGroup_603903,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIdentityProviderByIdentifier_603916 = ref object of OpenApiRestCall_602433
proc url_GetIdentityProviderByIdentifier_603918(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetIdentityProviderByIdentifier_603917(path: JsonNode;
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
  var valid_603919 = header.getOrDefault("X-Amz-Date")
  valid_603919 = validateParameter(valid_603919, JString, required = false,
                                 default = nil)
  if valid_603919 != nil:
    section.add "X-Amz-Date", valid_603919
  var valid_603920 = header.getOrDefault("X-Amz-Security-Token")
  valid_603920 = validateParameter(valid_603920, JString, required = false,
                                 default = nil)
  if valid_603920 != nil:
    section.add "X-Amz-Security-Token", valid_603920
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603921 = header.getOrDefault("X-Amz-Target")
  valid_603921 = validateParameter(valid_603921, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetIdentityProviderByIdentifier"))
  if valid_603921 != nil:
    section.add "X-Amz-Target", valid_603921
  var valid_603922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603922 = validateParameter(valid_603922, JString, required = false,
                                 default = nil)
  if valid_603922 != nil:
    section.add "X-Amz-Content-Sha256", valid_603922
  var valid_603923 = header.getOrDefault("X-Amz-Algorithm")
  valid_603923 = validateParameter(valid_603923, JString, required = false,
                                 default = nil)
  if valid_603923 != nil:
    section.add "X-Amz-Algorithm", valid_603923
  var valid_603924 = header.getOrDefault("X-Amz-Signature")
  valid_603924 = validateParameter(valid_603924, JString, required = false,
                                 default = nil)
  if valid_603924 != nil:
    section.add "X-Amz-Signature", valid_603924
  var valid_603925 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603925 = validateParameter(valid_603925, JString, required = false,
                                 default = nil)
  if valid_603925 != nil:
    section.add "X-Amz-SignedHeaders", valid_603925
  var valid_603926 = header.getOrDefault("X-Amz-Credential")
  valid_603926 = validateParameter(valid_603926, JString, required = false,
                                 default = nil)
  if valid_603926 != nil:
    section.add "X-Amz-Credential", valid_603926
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603928: Call_GetIdentityProviderByIdentifier_603916;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the specified identity provider.
  ## 
  let valid = call_603928.validator(path, query, header, formData, body)
  let scheme = call_603928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603928.url(scheme.get, call_603928.host, call_603928.base,
                         call_603928.route, valid.getOrDefault("path"))
  result = hook(call_603928, url, valid)

proc call*(call_603929: Call_GetIdentityProviderByIdentifier_603916; body: JsonNode): Recallable =
  ## getIdentityProviderByIdentifier
  ## Gets the specified identity provider.
  ##   body: JObject (required)
  var body_603930 = newJObject()
  if body != nil:
    body_603930 = body
  result = call_603929.call(nil, nil, nil, nil, body_603930)

var getIdentityProviderByIdentifier* = Call_GetIdentityProviderByIdentifier_603916(
    name: "getIdentityProviderByIdentifier", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetIdentityProviderByIdentifier",
    validator: validate_GetIdentityProviderByIdentifier_603917, base: "/",
    url: url_GetIdentityProviderByIdentifier_603918,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSigningCertificate_603931 = ref object of OpenApiRestCall_602433
proc url_GetSigningCertificate_603933(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSigningCertificate_603932(path: JsonNode; query: JsonNode;
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
  var valid_603934 = header.getOrDefault("X-Amz-Date")
  valid_603934 = validateParameter(valid_603934, JString, required = false,
                                 default = nil)
  if valid_603934 != nil:
    section.add "X-Amz-Date", valid_603934
  var valid_603935 = header.getOrDefault("X-Amz-Security-Token")
  valid_603935 = validateParameter(valid_603935, JString, required = false,
                                 default = nil)
  if valid_603935 != nil:
    section.add "X-Amz-Security-Token", valid_603935
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603936 = header.getOrDefault("X-Amz-Target")
  valid_603936 = validateParameter(valid_603936, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetSigningCertificate"))
  if valid_603936 != nil:
    section.add "X-Amz-Target", valid_603936
  var valid_603937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603937 = validateParameter(valid_603937, JString, required = false,
                                 default = nil)
  if valid_603937 != nil:
    section.add "X-Amz-Content-Sha256", valid_603937
  var valid_603938 = header.getOrDefault("X-Amz-Algorithm")
  valid_603938 = validateParameter(valid_603938, JString, required = false,
                                 default = nil)
  if valid_603938 != nil:
    section.add "X-Amz-Algorithm", valid_603938
  var valid_603939 = header.getOrDefault("X-Amz-Signature")
  valid_603939 = validateParameter(valid_603939, JString, required = false,
                                 default = nil)
  if valid_603939 != nil:
    section.add "X-Amz-Signature", valid_603939
  var valid_603940 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603940 = validateParameter(valid_603940, JString, required = false,
                                 default = nil)
  if valid_603940 != nil:
    section.add "X-Amz-SignedHeaders", valid_603940
  var valid_603941 = header.getOrDefault("X-Amz-Credential")
  valid_603941 = validateParameter(valid_603941, JString, required = false,
                                 default = nil)
  if valid_603941 != nil:
    section.add "X-Amz-Credential", valid_603941
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603943: Call_GetSigningCertificate_603931; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This method takes a user pool ID, and returns the signing certificate.
  ## 
  let valid = call_603943.validator(path, query, header, formData, body)
  let scheme = call_603943.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603943.url(scheme.get, call_603943.host, call_603943.base,
                         call_603943.route, valid.getOrDefault("path"))
  result = hook(call_603943, url, valid)

proc call*(call_603944: Call_GetSigningCertificate_603931; body: JsonNode): Recallable =
  ## getSigningCertificate
  ## This method takes a user pool ID, and returns the signing certificate.
  ##   body: JObject (required)
  var body_603945 = newJObject()
  if body != nil:
    body_603945 = body
  result = call_603944.call(nil, nil, nil, nil, body_603945)

var getSigningCertificate* = Call_GetSigningCertificate_603931(
    name: "getSigningCertificate", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetSigningCertificate",
    validator: validate_GetSigningCertificate_603932, base: "/",
    url: url_GetSigningCertificate_603933, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUICustomization_603946 = ref object of OpenApiRestCall_602433
proc url_GetUICustomization_603948(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUICustomization_603947(path: JsonNode; query: JsonNode;
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
  var valid_603949 = header.getOrDefault("X-Amz-Date")
  valid_603949 = validateParameter(valid_603949, JString, required = false,
                                 default = nil)
  if valid_603949 != nil:
    section.add "X-Amz-Date", valid_603949
  var valid_603950 = header.getOrDefault("X-Amz-Security-Token")
  valid_603950 = validateParameter(valid_603950, JString, required = false,
                                 default = nil)
  if valid_603950 != nil:
    section.add "X-Amz-Security-Token", valid_603950
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603951 = header.getOrDefault("X-Amz-Target")
  valid_603951 = validateParameter(valid_603951, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUICustomization"))
  if valid_603951 != nil:
    section.add "X-Amz-Target", valid_603951
  var valid_603952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603952 = validateParameter(valid_603952, JString, required = false,
                                 default = nil)
  if valid_603952 != nil:
    section.add "X-Amz-Content-Sha256", valid_603952
  var valid_603953 = header.getOrDefault("X-Amz-Algorithm")
  valid_603953 = validateParameter(valid_603953, JString, required = false,
                                 default = nil)
  if valid_603953 != nil:
    section.add "X-Amz-Algorithm", valid_603953
  var valid_603954 = header.getOrDefault("X-Amz-Signature")
  valid_603954 = validateParameter(valid_603954, JString, required = false,
                                 default = nil)
  if valid_603954 != nil:
    section.add "X-Amz-Signature", valid_603954
  var valid_603955 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603955 = validateParameter(valid_603955, JString, required = false,
                                 default = nil)
  if valid_603955 != nil:
    section.add "X-Amz-SignedHeaders", valid_603955
  var valid_603956 = header.getOrDefault("X-Amz-Credential")
  valid_603956 = validateParameter(valid_603956, JString, required = false,
                                 default = nil)
  if valid_603956 != nil:
    section.add "X-Amz-Credential", valid_603956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603958: Call_GetUICustomization_603946; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the UI Customization information for a particular app client's app UI, if there is something set. If nothing is set for the particular client, but there is an existing pool level customization (app <code>clientId</code> will be <code>ALL</code>), then that is returned. If nothing is present, then an empty shape is returned.
  ## 
  let valid = call_603958.validator(path, query, header, formData, body)
  let scheme = call_603958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603958.url(scheme.get, call_603958.host, call_603958.base,
                         call_603958.route, valid.getOrDefault("path"))
  result = hook(call_603958, url, valid)

proc call*(call_603959: Call_GetUICustomization_603946; body: JsonNode): Recallable =
  ## getUICustomization
  ## Gets the UI Customization information for a particular app client's app UI, if there is something set. If nothing is set for the particular client, but there is an existing pool level customization (app <code>clientId</code> will be <code>ALL</code>), then that is returned. If nothing is present, then an empty shape is returned.
  ##   body: JObject (required)
  var body_603960 = newJObject()
  if body != nil:
    body_603960 = body
  result = call_603959.call(nil, nil, nil, nil, body_603960)

var getUICustomization* = Call_GetUICustomization_603946(
    name: "getUICustomization", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUICustomization",
    validator: validate_GetUICustomization_603947, base: "/",
    url: url_GetUICustomization_603948, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUser_603961 = ref object of OpenApiRestCall_602433
proc url_GetUser_603963(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUser_603962(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603964 = header.getOrDefault("X-Amz-Date")
  valid_603964 = validateParameter(valid_603964, JString, required = false,
                                 default = nil)
  if valid_603964 != nil:
    section.add "X-Amz-Date", valid_603964
  var valid_603965 = header.getOrDefault("X-Amz-Security-Token")
  valid_603965 = validateParameter(valid_603965, JString, required = false,
                                 default = nil)
  if valid_603965 != nil:
    section.add "X-Amz-Security-Token", valid_603965
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603966 = header.getOrDefault("X-Amz-Target")
  valid_603966 = validateParameter(valid_603966, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUser"))
  if valid_603966 != nil:
    section.add "X-Amz-Target", valid_603966
  var valid_603967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603967 = validateParameter(valid_603967, JString, required = false,
                                 default = nil)
  if valid_603967 != nil:
    section.add "X-Amz-Content-Sha256", valid_603967
  var valid_603968 = header.getOrDefault("X-Amz-Algorithm")
  valid_603968 = validateParameter(valid_603968, JString, required = false,
                                 default = nil)
  if valid_603968 != nil:
    section.add "X-Amz-Algorithm", valid_603968
  var valid_603969 = header.getOrDefault("X-Amz-Signature")
  valid_603969 = validateParameter(valid_603969, JString, required = false,
                                 default = nil)
  if valid_603969 != nil:
    section.add "X-Amz-Signature", valid_603969
  var valid_603970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603970 = validateParameter(valid_603970, JString, required = false,
                                 default = nil)
  if valid_603970 != nil:
    section.add "X-Amz-SignedHeaders", valid_603970
  var valid_603971 = header.getOrDefault("X-Amz-Credential")
  valid_603971 = validateParameter(valid_603971, JString, required = false,
                                 default = nil)
  if valid_603971 != nil:
    section.add "X-Amz-Credential", valid_603971
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603973: Call_GetUser_603961; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the user attributes and metadata for a user.
  ## 
  let valid = call_603973.validator(path, query, header, formData, body)
  let scheme = call_603973.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603973.url(scheme.get, call_603973.host, call_603973.base,
                         call_603973.route, valid.getOrDefault("path"))
  result = hook(call_603973, url, valid)

proc call*(call_603974: Call_GetUser_603961; body: JsonNode): Recallable =
  ## getUser
  ## Gets the user attributes and metadata for a user.
  ##   body: JObject (required)
  var body_603975 = newJObject()
  if body != nil:
    body_603975 = body
  result = call_603974.call(nil, nil, nil, nil, body_603975)

var getUser* = Call_GetUser_603961(name: "getUser", meth: HttpMethod.HttpPost,
                                host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUser",
                                validator: validate_GetUser_603962, base: "/",
                                url: url_GetUser_603963,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserAttributeVerificationCode_603976 = ref object of OpenApiRestCall_602433
proc url_GetUserAttributeVerificationCode_603978(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUserAttributeVerificationCode_603977(path: JsonNode;
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
  var valid_603979 = header.getOrDefault("X-Amz-Date")
  valid_603979 = validateParameter(valid_603979, JString, required = false,
                                 default = nil)
  if valid_603979 != nil:
    section.add "X-Amz-Date", valid_603979
  var valid_603980 = header.getOrDefault("X-Amz-Security-Token")
  valid_603980 = validateParameter(valid_603980, JString, required = false,
                                 default = nil)
  if valid_603980 != nil:
    section.add "X-Amz-Security-Token", valid_603980
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603981 = header.getOrDefault("X-Amz-Target")
  valid_603981 = validateParameter(valid_603981, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUserAttributeVerificationCode"))
  if valid_603981 != nil:
    section.add "X-Amz-Target", valid_603981
  var valid_603982 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603982 = validateParameter(valid_603982, JString, required = false,
                                 default = nil)
  if valid_603982 != nil:
    section.add "X-Amz-Content-Sha256", valid_603982
  var valid_603983 = header.getOrDefault("X-Amz-Algorithm")
  valid_603983 = validateParameter(valid_603983, JString, required = false,
                                 default = nil)
  if valid_603983 != nil:
    section.add "X-Amz-Algorithm", valid_603983
  var valid_603984 = header.getOrDefault("X-Amz-Signature")
  valid_603984 = validateParameter(valid_603984, JString, required = false,
                                 default = nil)
  if valid_603984 != nil:
    section.add "X-Amz-Signature", valid_603984
  var valid_603985 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603985 = validateParameter(valid_603985, JString, required = false,
                                 default = nil)
  if valid_603985 != nil:
    section.add "X-Amz-SignedHeaders", valid_603985
  var valid_603986 = header.getOrDefault("X-Amz-Credential")
  valid_603986 = validateParameter(valid_603986, JString, required = false,
                                 default = nil)
  if valid_603986 != nil:
    section.add "X-Amz-Credential", valid_603986
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603988: Call_GetUserAttributeVerificationCode_603976;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the user attribute verification code for the specified attribute name.
  ## 
  let valid = call_603988.validator(path, query, header, formData, body)
  let scheme = call_603988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603988.url(scheme.get, call_603988.host, call_603988.base,
                         call_603988.route, valid.getOrDefault("path"))
  result = hook(call_603988, url, valid)

proc call*(call_603989: Call_GetUserAttributeVerificationCode_603976;
          body: JsonNode): Recallable =
  ## getUserAttributeVerificationCode
  ## Gets the user attribute verification code for the specified attribute name.
  ##   body: JObject (required)
  var body_603990 = newJObject()
  if body != nil:
    body_603990 = body
  result = call_603989.call(nil, nil, nil, nil, body_603990)

var getUserAttributeVerificationCode* = Call_GetUserAttributeVerificationCode_603976(
    name: "getUserAttributeVerificationCode", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUserAttributeVerificationCode",
    validator: validate_GetUserAttributeVerificationCode_603977, base: "/",
    url: url_GetUserAttributeVerificationCode_603978,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserPoolMfaConfig_603991 = ref object of OpenApiRestCall_602433
proc url_GetUserPoolMfaConfig_603993(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUserPoolMfaConfig_603992(path: JsonNode; query: JsonNode;
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
  var valid_603994 = header.getOrDefault("X-Amz-Date")
  valid_603994 = validateParameter(valid_603994, JString, required = false,
                                 default = nil)
  if valid_603994 != nil:
    section.add "X-Amz-Date", valid_603994
  var valid_603995 = header.getOrDefault("X-Amz-Security-Token")
  valid_603995 = validateParameter(valid_603995, JString, required = false,
                                 default = nil)
  if valid_603995 != nil:
    section.add "X-Amz-Security-Token", valid_603995
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603996 = header.getOrDefault("X-Amz-Target")
  valid_603996 = validateParameter(valid_603996, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUserPoolMfaConfig"))
  if valid_603996 != nil:
    section.add "X-Amz-Target", valid_603996
  var valid_603997 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603997 = validateParameter(valid_603997, JString, required = false,
                                 default = nil)
  if valid_603997 != nil:
    section.add "X-Amz-Content-Sha256", valid_603997
  var valid_603998 = header.getOrDefault("X-Amz-Algorithm")
  valid_603998 = validateParameter(valid_603998, JString, required = false,
                                 default = nil)
  if valid_603998 != nil:
    section.add "X-Amz-Algorithm", valid_603998
  var valid_603999 = header.getOrDefault("X-Amz-Signature")
  valid_603999 = validateParameter(valid_603999, JString, required = false,
                                 default = nil)
  if valid_603999 != nil:
    section.add "X-Amz-Signature", valid_603999
  var valid_604000 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604000 = validateParameter(valid_604000, JString, required = false,
                                 default = nil)
  if valid_604000 != nil:
    section.add "X-Amz-SignedHeaders", valid_604000
  var valid_604001 = header.getOrDefault("X-Amz-Credential")
  valid_604001 = validateParameter(valid_604001, JString, required = false,
                                 default = nil)
  if valid_604001 != nil:
    section.add "X-Amz-Credential", valid_604001
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604003: Call_GetUserPoolMfaConfig_603991; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the user pool multi-factor authentication (MFA) configuration.
  ## 
  let valid = call_604003.validator(path, query, header, formData, body)
  let scheme = call_604003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604003.url(scheme.get, call_604003.host, call_604003.base,
                         call_604003.route, valid.getOrDefault("path"))
  result = hook(call_604003, url, valid)

proc call*(call_604004: Call_GetUserPoolMfaConfig_603991; body: JsonNode): Recallable =
  ## getUserPoolMfaConfig
  ## Gets the user pool multi-factor authentication (MFA) configuration.
  ##   body: JObject (required)
  var body_604005 = newJObject()
  if body != nil:
    body_604005 = body
  result = call_604004.call(nil, nil, nil, nil, body_604005)

var getUserPoolMfaConfig* = Call_GetUserPoolMfaConfig_603991(
    name: "getUserPoolMfaConfig", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUserPoolMfaConfig",
    validator: validate_GetUserPoolMfaConfig_603992, base: "/",
    url: url_GetUserPoolMfaConfig_603993, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GlobalSignOut_604006 = ref object of OpenApiRestCall_602433
proc url_GlobalSignOut_604008(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GlobalSignOut_604007(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604009 = header.getOrDefault("X-Amz-Date")
  valid_604009 = validateParameter(valid_604009, JString, required = false,
                                 default = nil)
  if valid_604009 != nil:
    section.add "X-Amz-Date", valid_604009
  var valid_604010 = header.getOrDefault("X-Amz-Security-Token")
  valid_604010 = validateParameter(valid_604010, JString, required = false,
                                 default = nil)
  if valid_604010 != nil:
    section.add "X-Amz-Security-Token", valid_604010
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604011 = header.getOrDefault("X-Amz-Target")
  valid_604011 = validateParameter(valid_604011, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GlobalSignOut"))
  if valid_604011 != nil:
    section.add "X-Amz-Target", valid_604011
  var valid_604012 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604012 = validateParameter(valid_604012, JString, required = false,
                                 default = nil)
  if valid_604012 != nil:
    section.add "X-Amz-Content-Sha256", valid_604012
  var valid_604013 = header.getOrDefault("X-Amz-Algorithm")
  valid_604013 = validateParameter(valid_604013, JString, required = false,
                                 default = nil)
  if valid_604013 != nil:
    section.add "X-Amz-Algorithm", valid_604013
  var valid_604014 = header.getOrDefault("X-Amz-Signature")
  valid_604014 = validateParameter(valid_604014, JString, required = false,
                                 default = nil)
  if valid_604014 != nil:
    section.add "X-Amz-Signature", valid_604014
  var valid_604015 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604015 = validateParameter(valid_604015, JString, required = false,
                                 default = nil)
  if valid_604015 != nil:
    section.add "X-Amz-SignedHeaders", valid_604015
  var valid_604016 = header.getOrDefault("X-Amz-Credential")
  valid_604016 = validateParameter(valid_604016, JString, required = false,
                                 default = nil)
  if valid_604016 != nil:
    section.add "X-Amz-Credential", valid_604016
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604018: Call_GlobalSignOut_604006; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Signs out users from all devices.
  ## 
  let valid = call_604018.validator(path, query, header, formData, body)
  let scheme = call_604018.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604018.url(scheme.get, call_604018.host, call_604018.base,
                         call_604018.route, valid.getOrDefault("path"))
  result = hook(call_604018, url, valid)

proc call*(call_604019: Call_GlobalSignOut_604006; body: JsonNode): Recallable =
  ## globalSignOut
  ## Signs out users from all devices.
  ##   body: JObject (required)
  var body_604020 = newJObject()
  if body != nil:
    body_604020 = body
  result = call_604019.call(nil, nil, nil, nil, body_604020)

var globalSignOut* = Call_GlobalSignOut_604006(name: "globalSignOut",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GlobalSignOut",
    validator: validate_GlobalSignOut_604007, base: "/", url: url_GlobalSignOut_604008,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateAuth_604021 = ref object of OpenApiRestCall_602433
proc url_InitiateAuth_604023(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_InitiateAuth_604022(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604024 = header.getOrDefault("X-Amz-Date")
  valid_604024 = validateParameter(valid_604024, JString, required = false,
                                 default = nil)
  if valid_604024 != nil:
    section.add "X-Amz-Date", valid_604024
  var valid_604025 = header.getOrDefault("X-Amz-Security-Token")
  valid_604025 = validateParameter(valid_604025, JString, required = false,
                                 default = nil)
  if valid_604025 != nil:
    section.add "X-Amz-Security-Token", valid_604025
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604026 = header.getOrDefault("X-Amz-Target")
  valid_604026 = validateParameter(valid_604026, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.InitiateAuth"))
  if valid_604026 != nil:
    section.add "X-Amz-Target", valid_604026
  var valid_604027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604027 = validateParameter(valid_604027, JString, required = false,
                                 default = nil)
  if valid_604027 != nil:
    section.add "X-Amz-Content-Sha256", valid_604027
  var valid_604028 = header.getOrDefault("X-Amz-Algorithm")
  valid_604028 = validateParameter(valid_604028, JString, required = false,
                                 default = nil)
  if valid_604028 != nil:
    section.add "X-Amz-Algorithm", valid_604028
  var valid_604029 = header.getOrDefault("X-Amz-Signature")
  valid_604029 = validateParameter(valid_604029, JString, required = false,
                                 default = nil)
  if valid_604029 != nil:
    section.add "X-Amz-Signature", valid_604029
  var valid_604030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604030 = validateParameter(valid_604030, JString, required = false,
                                 default = nil)
  if valid_604030 != nil:
    section.add "X-Amz-SignedHeaders", valid_604030
  var valid_604031 = header.getOrDefault("X-Amz-Credential")
  valid_604031 = validateParameter(valid_604031, JString, required = false,
                                 default = nil)
  if valid_604031 != nil:
    section.add "X-Amz-Credential", valid_604031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604033: Call_InitiateAuth_604021; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates the authentication flow.
  ## 
  let valid = call_604033.validator(path, query, header, formData, body)
  let scheme = call_604033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604033.url(scheme.get, call_604033.host, call_604033.base,
                         call_604033.route, valid.getOrDefault("path"))
  result = hook(call_604033, url, valid)

proc call*(call_604034: Call_InitiateAuth_604021; body: JsonNode): Recallable =
  ## initiateAuth
  ## Initiates the authentication flow.
  ##   body: JObject (required)
  var body_604035 = newJObject()
  if body != nil:
    body_604035 = body
  result = call_604034.call(nil, nil, nil, nil, body_604035)

var initiateAuth* = Call_InitiateAuth_604021(name: "initiateAuth",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.InitiateAuth",
    validator: validate_InitiateAuth_604022, base: "/", url: url_InitiateAuth_604023,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevices_604036 = ref object of OpenApiRestCall_602433
proc url_ListDevices_604038(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDevices_604037(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604039 = header.getOrDefault("X-Amz-Date")
  valid_604039 = validateParameter(valid_604039, JString, required = false,
                                 default = nil)
  if valid_604039 != nil:
    section.add "X-Amz-Date", valid_604039
  var valid_604040 = header.getOrDefault("X-Amz-Security-Token")
  valid_604040 = validateParameter(valid_604040, JString, required = false,
                                 default = nil)
  if valid_604040 != nil:
    section.add "X-Amz-Security-Token", valid_604040
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604041 = header.getOrDefault("X-Amz-Target")
  valid_604041 = validateParameter(valid_604041, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListDevices"))
  if valid_604041 != nil:
    section.add "X-Amz-Target", valid_604041
  var valid_604042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604042 = validateParameter(valid_604042, JString, required = false,
                                 default = nil)
  if valid_604042 != nil:
    section.add "X-Amz-Content-Sha256", valid_604042
  var valid_604043 = header.getOrDefault("X-Amz-Algorithm")
  valid_604043 = validateParameter(valid_604043, JString, required = false,
                                 default = nil)
  if valid_604043 != nil:
    section.add "X-Amz-Algorithm", valid_604043
  var valid_604044 = header.getOrDefault("X-Amz-Signature")
  valid_604044 = validateParameter(valid_604044, JString, required = false,
                                 default = nil)
  if valid_604044 != nil:
    section.add "X-Amz-Signature", valid_604044
  var valid_604045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604045 = validateParameter(valid_604045, JString, required = false,
                                 default = nil)
  if valid_604045 != nil:
    section.add "X-Amz-SignedHeaders", valid_604045
  var valid_604046 = header.getOrDefault("X-Amz-Credential")
  valid_604046 = validateParameter(valid_604046, JString, required = false,
                                 default = nil)
  if valid_604046 != nil:
    section.add "X-Amz-Credential", valid_604046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604048: Call_ListDevices_604036; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the devices.
  ## 
  let valid = call_604048.validator(path, query, header, formData, body)
  let scheme = call_604048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604048.url(scheme.get, call_604048.host, call_604048.base,
                         call_604048.route, valid.getOrDefault("path"))
  result = hook(call_604048, url, valid)

proc call*(call_604049: Call_ListDevices_604036; body: JsonNode): Recallable =
  ## listDevices
  ## Lists the devices.
  ##   body: JObject (required)
  var body_604050 = newJObject()
  if body != nil:
    body_604050 = body
  result = call_604049.call(nil, nil, nil, nil, body_604050)

var listDevices* = Call_ListDevices_604036(name: "listDevices",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListDevices",
                                        validator: validate_ListDevices_604037,
                                        base: "/", url: url_ListDevices_604038,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_604051 = ref object of OpenApiRestCall_602433
proc url_ListGroups_604053(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListGroups_604052(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604054 = query.getOrDefault("Limit")
  valid_604054 = validateParameter(valid_604054, JString, required = false,
                                 default = nil)
  if valid_604054 != nil:
    section.add "Limit", valid_604054
  var valid_604055 = query.getOrDefault("NextToken")
  valid_604055 = validateParameter(valid_604055, JString, required = false,
                                 default = nil)
  if valid_604055 != nil:
    section.add "NextToken", valid_604055
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
  var valid_604056 = header.getOrDefault("X-Amz-Date")
  valid_604056 = validateParameter(valid_604056, JString, required = false,
                                 default = nil)
  if valid_604056 != nil:
    section.add "X-Amz-Date", valid_604056
  var valid_604057 = header.getOrDefault("X-Amz-Security-Token")
  valid_604057 = validateParameter(valid_604057, JString, required = false,
                                 default = nil)
  if valid_604057 != nil:
    section.add "X-Amz-Security-Token", valid_604057
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604058 = header.getOrDefault("X-Amz-Target")
  valid_604058 = validateParameter(valid_604058, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListGroups"))
  if valid_604058 != nil:
    section.add "X-Amz-Target", valid_604058
  var valid_604059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604059 = validateParameter(valid_604059, JString, required = false,
                                 default = nil)
  if valid_604059 != nil:
    section.add "X-Amz-Content-Sha256", valid_604059
  var valid_604060 = header.getOrDefault("X-Amz-Algorithm")
  valid_604060 = validateParameter(valid_604060, JString, required = false,
                                 default = nil)
  if valid_604060 != nil:
    section.add "X-Amz-Algorithm", valid_604060
  var valid_604061 = header.getOrDefault("X-Amz-Signature")
  valid_604061 = validateParameter(valid_604061, JString, required = false,
                                 default = nil)
  if valid_604061 != nil:
    section.add "X-Amz-Signature", valid_604061
  var valid_604062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604062 = validateParameter(valid_604062, JString, required = false,
                                 default = nil)
  if valid_604062 != nil:
    section.add "X-Amz-SignedHeaders", valid_604062
  var valid_604063 = header.getOrDefault("X-Amz-Credential")
  valid_604063 = validateParameter(valid_604063, JString, required = false,
                                 default = nil)
  if valid_604063 != nil:
    section.add "X-Amz-Credential", valid_604063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604065: Call_ListGroups_604051; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the groups associated with a user pool.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_604065.validator(path, query, header, formData, body)
  let scheme = call_604065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604065.url(scheme.get, call_604065.host, call_604065.base,
                         call_604065.route, valid.getOrDefault("path"))
  result = hook(call_604065, url, valid)

proc call*(call_604066: Call_ListGroups_604051; body: JsonNode; Limit: string = "";
          NextToken: string = ""): Recallable =
  ## listGroups
  ## <p>Lists the groups associated with a user pool.</p> <p>Requires developer credentials.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_604067 = newJObject()
  var body_604068 = newJObject()
  add(query_604067, "Limit", newJString(Limit))
  add(query_604067, "NextToken", newJString(NextToken))
  if body != nil:
    body_604068 = body
  result = call_604066.call(nil, query_604067, nil, nil, body_604068)

var listGroups* = Call_ListGroups_604051(name: "listGroups",
                                      meth: HttpMethod.HttpPost,
                                      host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListGroups",
                                      validator: validate_ListGroups_604052,
                                      base: "/", url: url_ListGroups_604053,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIdentityProviders_604069 = ref object of OpenApiRestCall_602433
proc url_ListIdentityProviders_604071(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListIdentityProviders_604070(path: JsonNode; query: JsonNode;
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
  var valid_604072 = query.getOrDefault("NextToken")
  valid_604072 = validateParameter(valid_604072, JString, required = false,
                                 default = nil)
  if valid_604072 != nil:
    section.add "NextToken", valid_604072
  var valid_604073 = query.getOrDefault("MaxResults")
  valid_604073 = validateParameter(valid_604073, JString, required = false,
                                 default = nil)
  if valid_604073 != nil:
    section.add "MaxResults", valid_604073
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
  var valid_604074 = header.getOrDefault("X-Amz-Date")
  valid_604074 = validateParameter(valid_604074, JString, required = false,
                                 default = nil)
  if valid_604074 != nil:
    section.add "X-Amz-Date", valid_604074
  var valid_604075 = header.getOrDefault("X-Amz-Security-Token")
  valid_604075 = validateParameter(valid_604075, JString, required = false,
                                 default = nil)
  if valid_604075 != nil:
    section.add "X-Amz-Security-Token", valid_604075
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604076 = header.getOrDefault("X-Amz-Target")
  valid_604076 = validateParameter(valid_604076, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListIdentityProviders"))
  if valid_604076 != nil:
    section.add "X-Amz-Target", valid_604076
  var valid_604077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604077 = validateParameter(valid_604077, JString, required = false,
                                 default = nil)
  if valid_604077 != nil:
    section.add "X-Amz-Content-Sha256", valid_604077
  var valid_604078 = header.getOrDefault("X-Amz-Algorithm")
  valid_604078 = validateParameter(valid_604078, JString, required = false,
                                 default = nil)
  if valid_604078 != nil:
    section.add "X-Amz-Algorithm", valid_604078
  var valid_604079 = header.getOrDefault("X-Amz-Signature")
  valid_604079 = validateParameter(valid_604079, JString, required = false,
                                 default = nil)
  if valid_604079 != nil:
    section.add "X-Amz-Signature", valid_604079
  var valid_604080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604080 = validateParameter(valid_604080, JString, required = false,
                                 default = nil)
  if valid_604080 != nil:
    section.add "X-Amz-SignedHeaders", valid_604080
  var valid_604081 = header.getOrDefault("X-Amz-Credential")
  valid_604081 = validateParameter(valid_604081, JString, required = false,
                                 default = nil)
  if valid_604081 != nil:
    section.add "X-Amz-Credential", valid_604081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604083: Call_ListIdentityProviders_604069; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about all identity providers for a user pool.
  ## 
  let valid = call_604083.validator(path, query, header, formData, body)
  let scheme = call_604083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604083.url(scheme.get, call_604083.host, call_604083.base,
                         call_604083.route, valid.getOrDefault("path"))
  result = hook(call_604083, url, valid)

proc call*(call_604084: Call_ListIdentityProviders_604069; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listIdentityProviders
  ## Lists information about all identity providers for a user pool.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604085 = newJObject()
  var body_604086 = newJObject()
  add(query_604085, "NextToken", newJString(NextToken))
  if body != nil:
    body_604086 = body
  add(query_604085, "MaxResults", newJString(MaxResults))
  result = call_604084.call(nil, query_604085, nil, nil, body_604086)

var listIdentityProviders* = Call_ListIdentityProviders_604069(
    name: "listIdentityProviders", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListIdentityProviders",
    validator: validate_ListIdentityProviders_604070, base: "/",
    url: url_ListIdentityProviders_604071, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceServers_604087 = ref object of OpenApiRestCall_602433
proc url_ListResourceServers_604089(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListResourceServers_604088(path: JsonNode; query: JsonNode;
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
  var valid_604090 = query.getOrDefault("NextToken")
  valid_604090 = validateParameter(valid_604090, JString, required = false,
                                 default = nil)
  if valid_604090 != nil:
    section.add "NextToken", valid_604090
  var valid_604091 = query.getOrDefault("MaxResults")
  valid_604091 = validateParameter(valid_604091, JString, required = false,
                                 default = nil)
  if valid_604091 != nil:
    section.add "MaxResults", valid_604091
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
  var valid_604092 = header.getOrDefault("X-Amz-Date")
  valid_604092 = validateParameter(valid_604092, JString, required = false,
                                 default = nil)
  if valid_604092 != nil:
    section.add "X-Amz-Date", valid_604092
  var valid_604093 = header.getOrDefault("X-Amz-Security-Token")
  valid_604093 = validateParameter(valid_604093, JString, required = false,
                                 default = nil)
  if valid_604093 != nil:
    section.add "X-Amz-Security-Token", valid_604093
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604094 = header.getOrDefault("X-Amz-Target")
  valid_604094 = validateParameter(valid_604094, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListResourceServers"))
  if valid_604094 != nil:
    section.add "X-Amz-Target", valid_604094
  var valid_604095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604095 = validateParameter(valid_604095, JString, required = false,
                                 default = nil)
  if valid_604095 != nil:
    section.add "X-Amz-Content-Sha256", valid_604095
  var valid_604096 = header.getOrDefault("X-Amz-Algorithm")
  valid_604096 = validateParameter(valid_604096, JString, required = false,
                                 default = nil)
  if valid_604096 != nil:
    section.add "X-Amz-Algorithm", valid_604096
  var valid_604097 = header.getOrDefault("X-Amz-Signature")
  valid_604097 = validateParameter(valid_604097, JString, required = false,
                                 default = nil)
  if valid_604097 != nil:
    section.add "X-Amz-Signature", valid_604097
  var valid_604098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604098 = validateParameter(valid_604098, JString, required = false,
                                 default = nil)
  if valid_604098 != nil:
    section.add "X-Amz-SignedHeaders", valid_604098
  var valid_604099 = header.getOrDefault("X-Amz-Credential")
  valid_604099 = validateParameter(valid_604099, JString, required = false,
                                 default = nil)
  if valid_604099 != nil:
    section.add "X-Amz-Credential", valid_604099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604101: Call_ListResourceServers_604087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resource servers for a user pool.
  ## 
  let valid = call_604101.validator(path, query, header, formData, body)
  let scheme = call_604101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604101.url(scheme.get, call_604101.host, call_604101.base,
                         call_604101.route, valid.getOrDefault("path"))
  result = hook(call_604101, url, valid)

proc call*(call_604102: Call_ListResourceServers_604087; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listResourceServers
  ## Lists the resource servers for a user pool.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604103 = newJObject()
  var body_604104 = newJObject()
  add(query_604103, "NextToken", newJString(NextToken))
  if body != nil:
    body_604104 = body
  add(query_604103, "MaxResults", newJString(MaxResults))
  result = call_604102.call(nil, query_604103, nil, nil, body_604104)

var listResourceServers* = Call_ListResourceServers_604087(
    name: "listResourceServers", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListResourceServers",
    validator: validate_ListResourceServers_604088, base: "/",
    url: url_ListResourceServers_604089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_604105 = ref object of OpenApiRestCall_602433
proc url_ListTagsForResource_604107(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource_604106(path: JsonNode; query: JsonNode;
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
  var valid_604108 = header.getOrDefault("X-Amz-Date")
  valid_604108 = validateParameter(valid_604108, JString, required = false,
                                 default = nil)
  if valid_604108 != nil:
    section.add "X-Amz-Date", valid_604108
  var valid_604109 = header.getOrDefault("X-Amz-Security-Token")
  valid_604109 = validateParameter(valid_604109, JString, required = false,
                                 default = nil)
  if valid_604109 != nil:
    section.add "X-Amz-Security-Token", valid_604109
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604110 = header.getOrDefault("X-Amz-Target")
  valid_604110 = validateParameter(valid_604110, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListTagsForResource"))
  if valid_604110 != nil:
    section.add "X-Amz-Target", valid_604110
  var valid_604111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604111 = validateParameter(valid_604111, JString, required = false,
                                 default = nil)
  if valid_604111 != nil:
    section.add "X-Amz-Content-Sha256", valid_604111
  var valid_604112 = header.getOrDefault("X-Amz-Algorithm")
  valid_604112 = validateParameter(valid_604112, JString, required = false,
                                 default = nil)
  if valid_604112 != nil:
    section.add "X-Amz-Algorithm", valid_604112
  var valid_604113 = header.getOrDefault("X-Amz-Signature")
  valid_604113 = validateParameter(valid_604113, JString, required = false,
                                 default = nil)
  if valid_604113 != nil:
    section.add "X-Amz-Signature", valid_604113
  var valid_604114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604114 = validateParameter(valid_604114, JString, required = false,
                                 default = nil)
  if valid_604114 != nil:
    section.add "X-Amz-SignedHeaders", valid_604114
  var valid_604115 = header.getOrDefault("X-Amz-Credential")
  valid_604115 = validateParameter(valid_604115, JString, required = false,
                                 default = nil)
  if valid_604115 != nil:
    section.add "X-Amz-Credential", valid_604115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604117: Call_ListTagsForResource_604105; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the tags that are assigned to an Amazon Cognito user pool.</p> <p>A tag is a label that you can apply to user pools to categorize and manage them in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>You can use this action up to 10 times per second, per account.</p>
  ## 
  let valid = call_604117.validator(path, query, header, formData, body)
  let scheme = call_604117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604117.url(scheme.get, call_604117.host, call_604117.base,
                         call_604117.route, valid.getOrDefault("path"))
  result = hook(call_604117, url, valid)

proc call*(call_604118: Call_ListTagsForResource_604105; body: JsonNode): Recallable =
  ## listTagsForResource
  ## <p>Lists the tags that are assigned to an Amazon Cognito user pool.</p> <p>A tag is a label that you can apply to user pools to categorize and manage them in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>You can use this action up to 10 times per second, per account.</p>
  ##   body: JObject (required)
  var body_604119 = newJObject()
  if body != nil:
    body_604119 = body
  result = call_604118.call(nil, nil, nil, nil, body_604119)

var listTagsForResource* = Call_ListTagsForResource_604105(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListTagsForResource",
    validator: validate_ListTagsForResource_604106, base: "/",
    url: url_ListTagsForResource_604107, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserImportJobs_604120 = ref object of OpenApiRestCall_602433
proc url_ListUserImportJobs_604122(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListUserImportJobs_604121(path: JsonNode; query: JsonNode;
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
  var valid_604123 = header.getOrDefault("X-Amz-Date")
  valid_604123 = validateParameter(valid_604123, JString, required = false,
                                 default = nil)
  if valid_604123 != nil:
    section.add "X-Amz-Date", valid_604123
  var valid_604124 = header.getOrDefault("X-Amz-Security-Token")
  valid_604124 = validateParameter(valid_604124, JString, required = false,
                                 default = nil)
  if valid_604124 != nil:
    section.add "X-Amz-Security-Token", valid_604124
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604125 = header.getOrDefault("X-Amz-Target")
  valid_604125 = validateParameter(valid_604125, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUserImportJobs"))
  if valid_604125 != nil:
    section.add "X-Amz-Target", valid_604125
  var valid_604126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604126 = validateParameter(valid_604126, JString, required = false,
                                 default = nil)
  if valid_604126 != nil:
    section.add "X-Amz-Content-Sha256", valid_604126
  var valid_604127 = header.getOrDefault("X-Amz-Algorithm")
  valid_604127 = validateParameter(valid_604127, JString, required = false,
                                 default = nil)
  if valid_604127 != nil:
    section.add "X-Amz-Algorithm", valid_604127
  var valid_604128 = header.getOrDefault("X-Amz-Signature")
  valid_604128 = validateParameter(valid_604128, JString, required = false,
                                 default = nil)
  if valid_604128 != nil:
    section.add "X-Amz-Signature", valid_604128
  var valid_604129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604129 = validateParameter(valid_604129, JString, required = false,
                                 default = nil)
  if valid_604129 != nil:
    section.add "X-Amz-SignedHeaders", valid_604129
  var valid_604130 = header.getOrDefault("X-Amz-Credential")
  valid_604130 = validateParameter(valid_604130, JString, required = false,
                                 default = nil)
  if valid_604130 != nil:
    section.add "X-Amz-Credential", valid_604130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604132: Call_ListUserImportJobs_604120; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the user import jobs.
  ## 
  let valid = call_604132.validator(path, query, header, formData, body)
  let scheme = call_604132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604132.url(scheme.get, call_604132.host, call_604132.base,
                         call_604132.route, valid.getOrDefault("path"))
  result = hook(call_604132, url, valid)

proc call*(call_604133: Call_ListUserImportJobs_604120; body: JsonNode): Recallable =
  ## listUserImportJobs
  ## Lists the user import jobs.
  ##   body: JObject (required)
  var body_604134 = newJObject()
  if body != nil:
    body_604134 = body
  result = call_604133.call(nil, nil, nil, nil, body_604134)

var listUserImportJobs* = Call_ListUserImportJobs_604120(
    name: "listUserImportJobs", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUserImportJobs",
    validator: validate_ListUserImportJobs_604121, base: "/",
    url: url_ListUserImportJobs_604122, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserPoolClients_604135 = ref object of OpenApiRestCall_602433
proc url_ListUserPoolClients_604137(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListUserPoolClients_604136(path: JsonNode; query: JsonNode;
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
  var valid_604138 = query.getOrDefault("NextToken")
  valid_604138 = validateParameter(valid_604138, JString, required = false,
                                 default = nil)
  if valid_604138 != nil:
    section.add "NextToken", valid_604138
  var valid_604139 = query.getOrDefault("MaxResults")
  valid_604139 = validateParameter(valid_604139, JString, required = false,
                                 default = nil)
  if valid_604139 != nil:
    section.add "MaxResults", valid_604139
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
  var valid_604140 = header.getOrDefault("X-Amz-Date")
  valid_604140 = validateParameter(valid_604140, JString, required = false,
                                 default = nil)
  if valid_604140 != nil:
    section.add "X-Amz-Date", valid_604140
  var valid_604141 = header.getOrDefault("X-Amz-Security-Token")
  valid_604141 = validateParameter(valid_604141, JString, required = false,
                                 default = nil)
  if valid_604141 != nil:
    section.add "X-Amz-Security-Token", valid_604141
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604142 = header.getOrDefault("X-Amz-Target")
  valid_604142 = validateParameter(valid_604142, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUserPoolClients"))
  if valid_604142 != nil:
    section.add "X-Amz-Target", valid_604142
  var valid_604143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604143 = validateParameter(valid_604143, JString, required = false,
                                 default = nil)
  if valid_604143 != nil:
    section.add "X-Amz-Content-Sha256", valid_604143
  var valid_604144 = header.getOrDefault("X-Amz-Algorithm")
  valid_604144 = validateParameter(valid_604144, JString, required = false,
                                 default = nil)
  if valid_604144 != nil:
    section.add "X-Amz-Algorithm", valid_604144
  var valid_604145 = header.getOrDefault("X-Amz-Signature")
  valid_604145 = validateParameter(valid_604145, JString, required = false,
                                 default = nil)
  if valid_604145 != nil:
    section.add "X-Amz-Signature", valid_604145
  var valid_604146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604146 = validateParameter(valid_604146, JString, required = false,
                                 default = nil)
  if valid_604146 != nil:
    section.add "X-Amz-SignedHeaders", valid_604146
  var valid_604147 = header.getOrDefault("X-Amz-Credential")
  valid_604147 = validateParameter(valid_604147, JString, required = false,
                                 default = nil)
  if valid_604147 != nil:
    section.add "X-Amz-Credential", valid_604147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604149: Call_ListUserPoolClients_604135; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the clients that have been created for the specified user pool.
  ## 
  let valid = call_604149.validator(path, query, header, formData, body)
  let scheme = call_604149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604149.url(scheme.get, call_604149.host, call_604149.base,
                         call_604149.route, valid.getOrDefault("path"))
  result = hook(call_604149, url, valid)

proc call*(call_604150: Call_ListUserPoolClients_604135; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listUserPoolClients
  ## Lists the clients that have been created for the specified user pool.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604151 = newJObject()
  var body_604152 = newJObject()
  add(query_604151, "NextToken", newJString(NextToken))
  if body != nil:
    body_604152 = body
  add(query_604151, "MaxResults", newJString(MaxResults))
  result = call_604150.call(nil, query_604151, nil, nil, body_604152)

var listUserPoolClients* = Call_ListUserPoolClients_604135(
    name: "listUserPoolClients", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUserPoolClients",
    validator: validate_ListUserPoolClients_604136, base: "/",
    url: url_ListUserPoolClients_604137, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserPools_604153 = ref object of OpenApiRestCall_602433
proc url_ListUserPools_604155(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListUserPools_604154(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604156 = query.getOrDefault("NextToken")
  valid_604156 = validateParameter(valid_604156, JString, required = false,
                                 default = nil)
  if valid_604156 != nil:
    section.add "NextToken", valid_604156
  var valid_604157 = query.getOrDefault("MaxResults")
  valid_604157 = validateParameter(valid_604157, JString, required = false,
                                 default = nil)
  if valid_604157 != nil:
    section.add "MaxResults", valid_604157
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
  var valid_604158 = header.getOrDefault("X-Amz-Date")
  valid_604158 = validateParameter(valid_604158, JString, required = false,
                                 default = nil)
  if valid_604158 != nil:
    section.add "X-Amz-Date", valid_604158
  var valid_604159 = header.getOrDefault("X-Amz-Security-Token")
  valid_604159 = validateParameter(valid_604159, JString, required = false,
                                 default = nil)
  if valid_604159 != nil:
    section.add "X-Amz-Security-Token", valid_604159
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604160 = header.getOrDefault("X-Amz-Target")
  valid_604160 = validateParameter(valid_604160, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUserPools"))
  if valid_604160 != nil:
    section.add "X-Amz-Target", valid_604160
  var valid_604161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604161 = validateParameter(valid_604161, JString, required = false,
                                 default = nil)
  if valid_604161 != nil:
    section.add "X-Amz-Content-Sha256", valid_604161
  var valid_604162 = header.getOrDefault("X-Amz-Algorithm")
  valid_604162 = validateParameter(valid_604162, JString, required = false,
                                 default = nil)
  if valid_604162 != nil:
    section.add "X-Amz-Algorithm", valid_604162
  var valid_604163 = header.getOrDefault("X-Amz-Signature")
  valid_604163 = validateParameter(valid_604163, JString, required = false,
                                 default = nil)
  if valid_604163 != nil:
    section.add "X-Amz-Signature", valid_604163
  var valid_604164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604164 = validateParameter(valid_604164, JString, required = false,
                                 default = nil)
  if valid_604164 != nil:
    section.add "X-Amz-SignedHeaders", valid_604164
  var valid_604165 = header.getOrDefault("X-Amz-Credential")
  valid_604165 = validateParameter(valid_604165, JString, required = false,
                                 default = nil)
  if valid_604165 != nil:
    section.add "X-Amz-Credential", valid_604165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604167: Call_ListUserPools_604153; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the user pools associated with an AWS account.
  ## 
  let valid = call_604167.validator(path, query, header, formData, body)
  let scheme = call_604167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604167.url(scheme.get, call_604167.host, call_604167.base,
                         call_604167.route, valid.getOrDefault("path"))
  result = hook(call_604167, url, valid)

proc call*(call_604168: Call_ListUserPools_604153; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listUserPools
  ## Lists the user pools associated with an AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604169 = newJObject()
  var body_604170 = newJObject()
  add(query_604169, "NextToken", newJString(NextToken))
  if body != nil:
    body_604170 = body
  add(query_604169, "MaxResults", newJString(MaxResults))
  result = call_604168.call(nil, query_604169, nil, nil, body_604170)

var listUserPools* = Call_ListUserPools_604153(name: "listUserPools",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUserPools",
    validator: validate_ListUserPools_604154, base: "/", url: url_ListUserPools_604155,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_604171 = ref object of OpenApiRestCall_602433
proc url_ListUsers_604173(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListUsers_604172(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604174 = header.getOrDefault("X-Amz-Date")
  valid_604174 = validateParameter(valid_604174, JString, required = false,
                                 default = nil)
  if valid_604174 != nil:
    section.add "X-Amz-Date", valid_604174
  var valid_604175 = header.getOrDefault("X-Amz-Security-Token")
  valid_604175 = validateParameter(valid_604175, JString, required = false,
                                 default = nil)
  if valid_604175 != nil:
    section.add "X-Amz-Security-Token", valid_604175
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604176 = header.getOrDefault("X-Amz-Target")
  valid_604176 = validateParameter(valid_604176, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUsers"))
  if valid_604176 != nil:
    section.add "X-Amz-Target", valid_604176
  var valid_604177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604177 = validateParameter(valid_604177, JString, required = false,
                                 default = nil)
  if valid_604177 != nil:
    section.add "X-Amz-Content-Sha256", valid_604177
  var valid_604178 = header.getOrDefault("X-Amz-Algorithm")
  valid_604178 = validateParameter(valid_604178, JString, required = false,
                                 default = nil)
  if valid_604178 != nil:
    section.add "X-Amz-Algorithm", valid_604178
  var valid_604179 = header.getOrDefault("X-Amz-Signature")
  valid_604179 = validateParameter(valid_604179, JString, required = false,
                                 default = nil)
  if valid_604179 != nil:
    section.add "X-Amz-Signature", valid_604179
  var valid_604180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604180 = validateParameter(valid_604180, JString, required = false,
                                 default = nil)
  if valid_604180 != nil:
    section.add "X-Amz-SignedHeaders", valid_604180
  var valid_604181 = header.getOrDefault("X-Amz-Credential")
  valid_604181 = validateParameter(valid_604181, JString, required = false,
                                 default = nil)
  if valid_604181 != nil:
    section.add "X-Amz-Credential", valid_604181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604183: Call_ListUsers_604171; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the users in the Amazon Cognito user pool.
  ## 
  let valid = call_604183.validator(path, query, header, formData, body)
  let scheme = call_604183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604183.url(scheme.get, call_604183.host, call_604183.base,
                         call_604183.route, valid.getOrDefault("path"))
  result = hook(call_604183, url, valid)

proc call*(call_604184: Call_ListUsers_604171; body: JsonNode): Recallable =
  ## listUsers
  ## Lists the users in the Amazon Cognito user pool.
  ##   body: JObject (required)
  var body_604185 = newJObject()
  if body != nil:
    body_604185 = body
  result = call_604184.call(nil, nil, nil, nil, body_604185)

var listUsers* = Call_ListUsers_604171(name: "listUsers", meth: HttpMethod.HttpPost,
                                    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUsers",
                                    validator: validate_ListUsers_604172,
                                    base: "/", url: url_ListUsers_604173,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsersInGroup_604186 = ref object of OpenApiRestCall_602433
proc url_ListUsersInGroup_604188(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListUsersInGroup_604187(path: JsonNode; query: JsonNode;
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
  var valid_604189 = query.getOrDefault("Limit")
  valid_604189 = validateParameter(valid_604189, JString, required = false,
                                 default = nil)
  if valid_604189 != nil:
    section.add "Limit", valid_604189
  var valid_604190 = query.getOrDefault("NextToken")
  valid_604190 = validateParameter(valid_604190, JString, required = false,
                                 default = nil)
  if valid_604190 != nil:
    section.add "NextToken", valid_604190
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
  var valid_604191 = header.getOrDefault("X-Amz-Date")
  valid_604191 = validateParameter(valid_604191, JString, required = false,
                                 default = nil)
  if valid_604191 != nil:
    section.add "X-Amz-Date", valid_604191
  var valid_604192 = header.getOrDefault("X-Amz-Security-Token")
  valid_604192 = validateParameter(valid_604192, JString, required = false,
                                 default = nil)
  if valid_604192 != nil:
    section.add "X-Amz-Security-Token", valid_604192
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604193 = header.getOrDefault("X-Amz-Target")
  valid_604193 = validateParameter(valid_604193, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUsersInGroup"))
  if valid_604193 != nil:
    section.add "X-Amz-Target", valid_604193
  var valid_604194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604194 = validateParameter(valid_604194, JString, required = false,
                                 default = nil)
  if valid_604194 != nil:
    section.add "X-Amz-Content-Sha256", valid_604194
  var valid_604195 = header.getOrDefault("X-Amz-Algorithm")
  valid_604195 = validateParameter(valid_604195, JString, required = false,
                                 default = nil)
  if valid_604195 != nil:
    section.add "X-Amz-Algorithm", valid_604195
  var valid_604196 = header.getOrDefault("X-Amz-Signature")
  valid_604196 = validateParameter(valid_604196, JString, required = false,
                                 default = nil)
  if valid_604196 != nil:
    section.add "X-Amz-Signature", valid_604196
  var valid_604197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604197 = validateParameter(valid_604197, JString, required = false,
                                 default = nil)
  if valid_604197 != nil:
    section.add "X-Amz-SignedHeaders", valid_604197
  var valid_604198 = header.getOrDefault("X-Amz-Credential")
  valid_604198 = validateParameter(valid_604198, JString, required = false,
                                 default = nil)
  if valid_604198 != nil:
    section.add "X-Amz-Credential", valid_604198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604200: Call_ListUsersInGroup_604186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the users in the specified group.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_604200.validator(path, query, header, formData, body)
  let scheme = call_604200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604200.url(scheme.get, call_604200.host, call_604200.base,
                         call_604200.route, valid.getOrDefault("path"))
  result = hook(call_604200, url, valid)

proc call*(call_604201: Call_ListUsersInGroup_604186; body: JsonNode;
          Limit: string = ""; NextToken: string = ""): Recallable =
  ## listUsersInGroup
  ## <p>Lists the users in the specified group.</p> <p>Requires developer credentials.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_604202 = newJObject()
  var body_604203 = newJObject()
  add(query_604202, "Limit", newJString(Limit))
  add(query_604202, "NextToken", newJString(NextToken))
  if body != nil:
    body_604203 = body
  result = call_604201.call(nil, query_604202, nil, nil, body_604203)

var listUsersInGroup* = Call_ListUsersInGroup_604186(name: "listUsersInGroup",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUsersInGroup",
    validator: validate_ListUsersInGroup_604187, base: "/",
    url: url_ListUsersInGroup_604188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResendConfirmationCode_604204 = ref object of OpenApiRestCall_602433
proc url_ResendConfirmationCode_604206(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ResendConfirmationCode_604205(path: JsonNode; query: JsonNode;
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
  var valid_604207 = header.getOrDefault("X-Amz-Date")
  valid_604207 = validateParameter(valid_604207, JString, required = false,
                                 default = nil)
  if valid_604207 != nil:
    section.add "X-Amz-Date", valid_604207
  var valid_604208 = header.getOrDefault("X-Amz-Security-Token")
  valid_604208 = validateParameter(valid_604208, JString, required = false,
                                 default = nil)
  if valid_604208 != nil:
    section.add "X-Amz-Security-Token", valid_604208
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604209 = header.getOrDefault("X-Amz-Target")
  valid_604209 = validateParameter(valid_604209, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ResendConfirmationCode"))
  if valid_604209 != nil:
    section.add "X-Amz-Target", valid_604209
  var valid_604210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604210 = validateParameter(valid_604210, JString, required = false,
                                 default = nil)
  if valid_604210 != nil:
    section.add "X-Amz-Content-Sha256", valid_604210
  var valid_604211 = header.getOrDefault("X-Amz-Algorithm")
  valid_604211 = validateParameter(valid_604211, JString, required = false,
                                 default = nil)
  if valid_604211 != nil:
    section.add "X-Amz-Algorithm", valid_604211
  var valid_604212 = header.getOrDefault("X-Amz-Signature")
  valid_604212 = validateParameter(valid_604212, JString, required = false,
                                 default = nil)
  if valid_604212 != nil:
    section.add "X-Amz-Signature", valid_604212
  var valid_604213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604213 = validateParameter(valid_604213, JString, required = false,
                                 default = nil)
  if valid_604213 != nil:
    section.add "X-Amz-SignedHeaders", valid_604213
  var valid_604214 = header.getOrDefault("X-Amz-Credential")
  valid_604214 = validateParameter(valid_604214, JString, required = false,
                                 default = nil)
  if valid_604214 != nil:
    section.add "X-Amz-Credential", valid_604214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604216: Call_ResendConfirmationCode_604204; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resends the confirmation (for confirmation of registration) to a specific user in the user pool.
  ## 
  let valid = call_604216.validator(path, query, header, formData, body)
  let scheme = call_604216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604216.url(scheme.get, call_604216.host, call_604216.base,
                         call_604216.route, valid.getOrDefault("path"))
  result = hook(call_604216, url, valid)

proc call*(call_604217: Call_ResendConfirmationCode_604204; body: JsonNode): Recallable =
  ## resendConfirmationCode
  ## Resends the confirmation (for confirmation of registration) to a specific user in the user pool.
  ##   body: JObject (required)
  var body_604218 = newJObject()
  if body != nil:
    body_604218 = body
  result = call_604217.call(nil, nil, nil, nil, body_604218)

var resendConfirmationCode* = Call_ResendConfirmationCode_604204(
    name: "resendConfirmationCode", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ResendConfirmationCode",
    validator: validate_ResendConfirmationCode_604205, base: "/",
    url: url_ResendConfirmationCode_604206, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RespondToAuthChallenge_604219 = ref object of OpenApiRestCall_602433
proc url_RespondToAuthChallenge_604221(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RespondToAuthChallenge_604220(path: JsonNode; query: JsonNode;
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
  var valid_604222 = header.getOrDefault("X-Amz-Date")
  valid_604222 = validateParameter(valid_604222, JString, required = false,
                                 default = nil)
  if valid_604222 != nil:
    section.add "X-Amz-Date", valid_604222
  var valid_604223 = header.getOrDefault("X-Amz-Security-Token")
  valid_604223 = validateParameter(valid_604223, JString, required = false,
                                 default = nil)
  if valid_604223 != nil:
    section.add "X-Amz-Security-Token", valid_604223
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604224 = header.getOrDefault("X-Amz-Target")
  valid_604224 = validateParameter(valid_604224, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.RespondToAuthChallenge"))
  if valid_604224 != nil:
    section.add "X-Amz-Target", valid_604224
  var valid_604225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604225 = validateParameter(valid_604225, JString, required = false,
                                 default = nil)
  if valid_604225 != nil:
    section.add "X-Amz-Content-Sha256", valid_604225
  var valid_604226 = header.getOrDefault("X-Amz-Algorithm")
  valid_604226 = validateParameter(valid_604226, JString, required = false,
                                 default = nil)
  if valid_604226 != nil:
    section.add "X-Amz-Algorithm", valid_604226
  var valid_604227 = header.getOrDefault("X-Amz-Signature")
  valid_604227 = validateParameter(valid_604227, JString, required = false,
                                 default = nil)
  if valid_604227 != nil:
    section.add "X-Amz-Signature", valid_604227
  var valid_604228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604228 = validateParameter(valid_604228, JString, required = false,
                                 default = nil)
  if valid_604228 != nil:
    section.add "X-Amz-SignedHeaders", valid_604228
  var valid_604229 = header.getOrDefault("X-Amz-Credential")
  valid_604229 = validateParameter(valid_604229, JString, required = false,
                                 default = nil)
  if valid_604229 != nil:
    section.add "X-Amz-Credential", valid_604229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604231: Call_RespondToAuthChallenge_604219; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Responds to the authentication challenge.
  ## 
  let valid = call_604231.validator(path, query, header, formData, body)
  let scheme = call_604231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604231.url(scheme.get, call_604231.host, call_604231.base,
                         call_604231.route, valid.getOrDefault("path"))
  result = hook(call_604231, url, valid)

proc call*(call_604232: Call_RespondToAuthChallenge_604219; body: JsonNode): Recallable =
  ## respondToAuthChallenge
  ## Responds to the authentication challenge.
  ##   body: JObject (required)
  var body_604233 = newJObject()
  if body != nil:
    body_604233 = body
  result = call_604232.call(nil, nil, nil, nil, body_604233)

var respondToAuthChallenge* = Call_RespondToAuthChallenge_604219(
    name: "respondToAuthChallenge", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.RespondToAuthChallenge",
    validator: validate_RespondToAuthChallenge_604220, base: "/",
    url: url_RespondToAuthChallenge_604221, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetRiskConfiguration_604234 = ref object of OpenApiRestCall_602433
proc url_SetRiskConfiguration_604236(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SetRiskConfiguration_604235(path: JsonNode; query: JsonNode;
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
  var valid_604237 = header.getOrDefault("X-Amz-Date")
  valid_604237 = validateParameter(valid_604237, JString, required = false,
                                 default = nil)
  if valid_604237 != nil:
    section.add "X-Amz-Date", valid_604237
  var valid_604238 = header.getOrDefault("X-Amz-Security-Token")
  valid_604238 = validateParameter(valid_604238, JString, required = false,
                                 default = nil)
  if valid_604238 != nil:
    section.add "X-Amz-Security-Token", valid_604238
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604239 = header.getOrDefault("X-Amz-Target")
  valid_604239 = validateParameter(valid_604239, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetRiskConfiguration"))
  if valid_604239 != nil:
    section.add "X-Amz-Target", valid_604239
  var valid_604240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604240 = validateParameter(valid_604240, JString, required = false,
                                 default = nil)
  if valid_604240 != nil:
    section.add "X-Amz-Content-Sha256", valid_604240
  var valid_604241 = header.getOrDefault("X-Amz-Algorithm")
  valid_604241 = validateParameter(valid_604241, JString, required = false,
                                 default = nil)
  if valid_604241 != nil:
    section.add "X-Amz-Algorithm", valid_604241
  var valid_604242 = header.getOrDefault("X-Amz-Signature")
  valid_604242 = validateParameter(valid_604242, JString, required = false,
                                 default = nil)
  if valid_604242 != nil:
    section.add "X-Amz-Signature", valid_604242
  var valid_604243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604243 = validateParameter(valid_604243, JString, required = false,
                                 default = nil)
  if valid_604243 != nil:
    section.add "X-Amz-SignedHeaders", valid_604243
  var valid_604244 = header.getOrDefault("X-Amz-Credential")
  valid_604244 = validateParameter(valid_604244, JString, required = false,
                                 default = nil)
  if valid_604244 != nil:
    section.add "X-Amz-Credential", valid_604244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604246: Call_SetRiskConfiguration_604234; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configures actions on detected risks. To delete the risk configuration for <code>UserPoolId</code> or <code>ClientId</code>, pass null values for all four configuration types.</p> <p>To enable Amazon Cognito advanced security features, update the user pool to include the <code>UserPoolAddOns</code> key<code>AdvancedSecurityMode</code>.</p> <p>See .</p>
  ## 
  let valid = call_604246.validator(path, query, header, formData, body)
  let scheme = call_604246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604246.url(scheme.get, call_604246.host, call_604246.base,
                         call_604246.route, valid.getOrDefault("path"))
  result = hook(call_604246, url, valid)

proc call*(call_604247: Call_SetRiskConfiguration_604234; body: JsonNode): Recallable =
  ## setRiskConfiguration
  ## <p>Configures actions on detected risks. To delete the risk configuration for <code>UserPoolId</code> or <code>ClientId</code>, pass null values for all four configuration types.</p> <p>To enable Amazon Cognito advanced security features, update the user pool to include the <code>UserPoolAddOns</code> key<code>AdvancedSecurityMode</code>.</p> <p>See .</p>
  ##   body: JObject (required)
  var body_604248 = newJObject()
  if body != nil:
    body_604248 = body
  result = call_604247.call(nil, nil, nil, nil, body_604248)

var setRiskConfiguration* = Call_SetRiskConfiguration_604234(
    name: "setRiskConfiguration", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetRiskConfiguration",
    validator: validate_SetRiskConfiguration_604235, base: "/",
    url: url_SetRiskConfiguration_604236, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUICustomization_604249 = ref object of OpenApiRestCall_602433
proc url_SetUICustomization_604251(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SetUICustomization_604250(path: JsonNode; query: JsonNode;
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
  var valid_604252 = header.getOrDefault("X-Amz-Date")
  valid_604252 = validateParameter(valid_604252, JString, required = false,
                                 default = nil)
  if valid_604252 != nil:
    section.add "X-Amz-Date", valid_604252
  var valid_604253 = header.getOrDefault("X-Amz-Security-Token")
  valid_604253 = validateParameter(valid_604253, JString, required = false,
                                 default = nil)
  if valid_604253 != nil:
    section.add "X-Amz-Security-Token", valid_604253
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604254 = header.getOrDefault("X-Amz-Target")
  valid_604254 = validateParameter(valid_604254, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUICustomization"))
  if valid_604254 != nil:
    section.add "X-Amz-Target", valid_604254
  var valid_604255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604255 = validateParameter(valid_604255, JString, required = false,
                                 default = nil)
  if valid_604255 != nil:
    section.add "X-Amz-Content-Sha256", valid_604255
  var valid_604256 = header.getOrDefault("X-Amz-Algorithm")
  valid_604256 = validateParameter(valid_604256, JString, required = false,
                                 default = nil)
  if valid_604256 != nil:
    section.add "X-Amz-Algorithm", valid_604256
  var valid_604257 = header.getOrDefault("X-Amz-Signature")
  valid_604257 = validateParameter(valid_604257, JString, required = false,
                                 default = nil)
  if valid_604257 != nil:
    section.add "X-Amz-Signature", valid_604257
  var valid_604258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604258 = validateParameter(valid_604258, JString, required = false,
                                 default = nil)
  if valid_604258 != nil:
    section.add "X-Amz-SignedHeaders", valid_604258
  var valid_604259 = header.getOrDefault("X-Amz-Credential")
  valid_604259 = validateParameter(valid_604259, JString, required = false,
                                 default = nil)
  if valid_604259 != nil:
    section.add "X-Amz-Credential", valid_604259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604261: Call_SetUICustomization_604249; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the UI customization information for a user pool's built-in app UI.</p> <p>You can specify app UI customization settings for a single client (with a specific <code>clientId</code>) or for all clients (by setting the <code>clientId</code> to <code>ALL</code>). If you specify <code>ALL</code>, the default configuration will be used for every client that has no UI customization set previously. If you specify UI customization settings for a particular client, it will no longer fall back to the <code>ALL</code> configuration. </p> <note> <p>To use this API, your user pool must have a domain associated with it. Otherwise, there is no place to host the app's pages, and the service will throw an error.</p> </note>
  ## 
  let valid = call_604261.validator(path, query, header, formData, body)
  let scheme = call_604261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604261.url(scheme.get, call_604261.host, call_604261.base,
                         call_604261.route, valid.getOrDefault("path"))
  result = hook(call_604261, url, valid)

proc call*(call_604262: Call_SetUICustomization_604249; body: JsonNode): Recallable =
  ## setUICustomization
  ## <p>Sets the UI customization information for a user pool's built-in app UI.</p> <p>You can specify app UI customization settings for a single client (with a specific <code>clientId</code>) or for all clients (by setting the <code>clientId</code> to <code>ALL</code>). If you specify <code>ALL</code>, the default configuration will be used for every client that has no UI customization set previously. If you specify UI customization settings for a particular client, it will no longer fall back to the <code>ALL</code> configuration. </p> <note> <p>To use this API, your user pool must have a domain associated with it. Otherwise, there is no place to host the app's pages, and the service will throw an error.</p> </note>
  ##   body: JObject (required)
  var body_604263 = newJObject()
  if body != nil:
    body_604263 = body
  result = call_604262.call(nil, nil, nil, nil, body_604263)

var setUICustomization* = Call_SetUICustomization_604249(
    name: "setUICustomization", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUICustomization",
    validator: validate_SetUICustomization_604250, base: "/",
    url: url_SetUICustomization_604251, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUserMFAPreference_604264 = ref object of OpenApiRestCall_602433
proc url_SetUserMFAPreference_604266(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SetUserMFAPreference_604265(path: JsonNode; query: JsonNode;
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
  var valid_604267 = header.getOrDefault("X-Amz-Date")
  valid_604267 = validateParameter(valid_604267, JString, required = false,
                                 default = nil)
  if valid_604267 != nil:
    section.add "X-Amz-Date", valid_604267
  var valid_604268 = header.getOrDefault("X-Amz-Security-Token")
  valid_604268 = validateParameter(valid_604268, JString, required = false,
                                 default = nil)
  if valid_604268 != nil:
    section.add "X-Amz-Security-Token", valid_604268
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604269 = header.getOrDefault("X-Amz-Target")
  valid_604269 = validateParameter(valid_604269, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUserMFAPreference"))
  if valid_604269 != nil:
    section.add "X-Amz-Target", valid_604269
  var valid_604270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604270 = validateParameter(valid_604270, JString, required = false,
                                 default = nil)
  if valid_604270 != nil:
    section.add "X-Amz-Content-Sha256", valid_604270
  var valid_604271 = header.getOrDefault("X-Amz-Algorithm")
  valid_604271 = validateParameter(valid_604271, JString, required = false,
                                 default = nil)
  if valid_604271 != nil:
    section.add "X-Amz-Algorithm", valid_604271
  var valid_604272 = header.getOrDefault("X-Amz-Signature")
  valid_604272 = validateParameter(valid_604272, JString, required = false,
                                 default = nil)
  if valid_604272 != nil:
    section.add "X-Amz-Signature", valid_604272
  var valid_604273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604273 = validateParameter(valid_604273, JString, required = false,
                                 default = nil)
  if valid_604273 != nil:
    section.add "X-Amz-SignedHeaders", valid_604273
  var valid_604274 = header.getOrDefault("X-Amz-Credential")
  valid_604274 = validateParameter(valid_604274, JString, required = false,
                                 default = nil)
  if valid_604274 != nil:
    section.add "X-Amz-Credential", valid_604274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604276: Call_SetUserMFAPreference_604264; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the user's multi-factor authentication (MFA) method preference.
  ## 
  let valid = call_604276.validator(path, query, header, formData, body)
  let scheme = call_604276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604276.url(scheme.get, call_604276.host, call_604276.base,
                         call_604276.route, valid.getOrDefault("path"))
  result = hook(call_604276, url, valid)

proc call*(call_604277: Call_SetUserMFAPreference_604264; body: JsonNode): Recallable =
  ## setUserMFAPreference
  ## Set the user's multi-factor authentication (MFA) method preference.
  ##   body: JObject (required)
  var body_604278 = newJObject()
  if body != nil:
    body_604278 = body
  result = call_604277.call(nil, nil, nil, nil, body_604278)

var setUserMFAPreference* = Call_SetUserMFAPreference_604264(
    name: "setUserMFAPreference", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUserMFAPreference",
    validator: validate_SetUserMFAPreference_604265, base: "/",
    url: url_SetUserMFAPreference_604266, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUserPoolMfaConfig_604279 = ref object of OpenApiRestCall_602433
proc url_SetUserPoolMfaConfig_604281(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SetUserPoolMfaConfig_604280(path: JsonNode; query: JsonNode;
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
  var valid_604282 = header.getOrDefault("X-Amz-Date")
  valid_604282 = validateParameter(valid_604282, JString, required = false,
                                 default = nil)
  if valid_604282 != nil:
    section.add "X-Amz-Date", valid_604282
  var valid_604283 = header.getOrDefault("X-Amz-Security-Token")
  valid_604283 = validateParameter(valid_604283, JString, required = false,
                                 default = nil)
  if valid_604283 != nil:
    section.add "X-Amz-Security-Token", valid_604283
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604284 = header.getOrDefault("X-Amz-Target")
  valid_604284 = validateParameter(valid_604284, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUserPoolMfaConfig"))
  if valid_604284 != nil:
    section.add "X-Amz-Target", valid_604284
  var valid_604285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604285 = validateParameter(valid_604285, JString, required = false,
                                 default = nil)
  if valid_604285 != nil:
    section.add "X-Amz-Content-Sha256", valid_604285
  var valid_604286 = header.getOrDefault("X-Amz-Algorithm")
  valid_604286 = validateParameter(valid_604286, JString, required = false,
                                 default = nil)
  if valid_604286 != nil:
    section.add "X-Amz-Algorithm", valid_604286
  var valid_604287 = header.getOrDefault("X-Amz-Signature")
  valid_604287 = validateParameter(valid_604287, JString, required = false,
                                 default = nil)
  if valid_604287 != nil:
    section.add "X-Amz-Signature", valid_604287
  var valid_604288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604288 = validateParameter(valid_604288, JString, required = false,
                                 default = nil)
  if valid_604288 != nil:
    section.add "X-Amz-SignedHeaders", valid_604288
  var valid_604289 = header.getOrDefault("X-Amz-Credential")
  valid_604289 = validateParameter(valid_604289, JString, required = false,
                                 default = nil)
  if valid_604289 != nil:
    section.add "X-Amz-Credential", valid_604289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604291: Call_SetUserPoolMfaConfig_604279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the user pool MFA configuration.
  ## 
  let valid = call_604291.validator(path, query, header, formData, body)
  let scheme = call_604291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604291.url(scheme.get, call_604291.host, call_604291.base,
                         call_604291.route, valid.getOrDefault("path"))
  result = hook(call_604291, url, valid)

proc call*(call_604292: Call_SetUserPoolMfaConfig_604279; body: JsonNode): Recallable =
  ## setUserPoolMfaConfig
  ## Set the user pool MFA configuration.
  ##   body: JObject (required)
  var body_604293 = newJObject()
  if body != nil:
    body_604293 = body
  result = call_604292.call(nil, nil, nil, nil, body_604293)

var setUserPoolMfaConfig* = Call_SetUserPoolMfaConfig_604279(
    name: "setUserPoolMfaConfig", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUserPoolMfaConfig",
    validator: validate_SetUserPoolMfaConfig_604280, base: "/",
    url: url_SetUserPoolMfaConfig_604281, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUserSettings_604294 = ref object of OpenApiRestCall_602433
proc url_SetUserSettings_604296(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SetUserSettings_604295(path: JsonNode; query: JsonNode;
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
  var valid_604297 = header.getOrDefault("X-Amz-Date")
  valid_604297 = validateParameter(valid_604297, JString, required = false,
                                 default = nil)
  if valid_604297 != nil:
    section.add "X-Amz-Date", valid_604297
  var valid_604298 = header.getOrDefault("X-Amz-Security-Token")
  valid_604298 = validateParameter(valid_604298, JString, required = false,
                                 default = nil)
  if valid_604298 != nil:
    section.add "X-Amz-Security-Token", valid_604298
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604299 = header.getOrDefault("X-Amz-Target")
  valid_604299 = validateParameter(valid_604299, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUserSettings"))
  if valid_604299 != nil:
    section.add "X-Amz-Target", valid_604299
  var valid_604300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604300 = validateParameter(valid_604300, JString, required = false,
                                 default = nil)
  if valid_604300 != nil:
    section.add "X-Amz-Content-Sha256", valid_604300
  var valid_604301 = header.getOrDefault("X-Amz-Algorithm")
  valid_604301 = validateParameter(valid_604301, JString, required = false,
                                 default = nil)
  if valid_604301 != nil:
    section.add "X-Amz-Algorithm", valid_604301
  var valid_604302 = header.getOrDefault("X-Amz-Signature")
  valid_604302 = validateParameter(valid_604302, JString, required = false,
                                 default = nil)
  if valid_604302 != nil:
    section.add "X-Amz-Signature", valid_604302
  var valid_604303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604303 = validateParameter(valid_604303, JString, required = false,
                                 default = nil)
  if valid_604303 != nil:
    section.add "X-Amz-SignedHeaders", valid_604303
  var valid_604304 = header.getOrDefault("X-Amz-Credential")
  valid_604304 = validateParameter(valid_604304, JString, required = false,
                                 default = nil)
  if valid_604304 != nil:
    section.add "X-Amz-Credential", valid_604304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604306: Call_SetUserSettings_604294; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the user settings like multi-factor authentication (MFA). If MFA is to be removed for a particular attribute pass the attribute with code delivery as null. If null list is passed, all MFA options are removed.
  ## 
  let valid = call_604306.validator(path, query, header, formData, body)
  let scheme = call_604306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604306.url(scheme.get, call_604306.host, call_604306.base,
                         call_604306.route, valid.getOrDefault("path"))
  result = hook(call_604306, url, valid)

proc call*(call_604307: Call_SetUserSettings_604294; body: JsonNode): Recallable =
  ## setUserSettings
  ## Sets the user settings like multi-factor authentication (MFA). If MFA is to be removed for a particular attribute pass the attribute with code delivery as null. If null list is passed, all MFA options are removed.
  ##   body: JObject (required)
  var body_604308 = newJObject()
  if body != nil:
    body_604308 = body
  result = call_604307.call(nil, nil, nil, nil, body_604308)

var setUserSettings* = Call_SetUserSettings_604294(name: "setUserSettings",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUserSettings",
    validator: validate_SetUserSettings_604295, base: "/", url: url_SetUserSettings_604296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SignUp_604309 = ref object of OpenApiRestCall_602433
proc url_SignUp_604311(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SignUp_604310(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604312 = header.getOrDefault("X-Amz-Date")
  valid_604312 = validateParameter(valid_604312, JString, required = false,
                                 default = nil)
  if valid_604312 != nil:
    section.add "X-Amz-Date", valid_604312
  var valid_604313 = header.getOrDefault("X-Amz-Security-Token")
  valid_604313 = validateParameter(valid_604313, JString, required = false,
                                 default = nil)
  if valid_604313 != nil:
    section.add "X-Amz-Security-Token", valid_604313
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604314 = header.getOrDefault("X-Amz-Target")
  valid_604314 = validateParameter(valid_604314, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SignUp"))
  if valid_604314 != nil:
    section.add "X-Amz-Target", valid_604314
  var valid_604315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604315 = validateParameter(valid_604315, JString, required = false,
                                 default = nil)
  if valid_604315 != nil:
    section.add "X-Amz-Content-Sha256", valid_604315
  var valid_604316 = header.getOrDefault("X-Amz-Algorithm")
  valid_604316 = validateParameter(valid_604316, JString, required = false,
                                 default = nil)
  if valid_604316 != nil:
    section.add "X-Amz-Algorithm", valid_604316
  var valid_604317 = header.getOrDefault("X-Amz-Signature")
  valid_604317 = validateParameter(valid_604317, JString, required = false,
                                 default = nil)
  if valid_604317 != nil:
    section.add "X-Amz-Signature", valid_604317
  var valid_604318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604318 = validateParameter(valid_604318, JString, required = false,
                                 default = nil)
  if valid_604318 != nil:
    section.add "X-Amz-SignedHeaders", valid_604318
  var valid_604319 = header.getOrDefault("X-Amz-Credential")
  valid_604319 = validateParameter(valid_604319, JString, required = false,
                                 default = nil)
  if valid_604319 != nil:
    section.add "X-Amz-Credential", valid_604319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604321: Call_SignUp_604309; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers the user in the specified user pool and creates a user name, password, and user attributes.
  ## 
  let valid = call_604321.validator(path, query, header, formData, body)
  let scheme = call_604321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604321.url(scheme.get, call_604321.host, call_604321.base,
                         call_604321.route, valid.getOrDefault("path"))
  result = hook(call_604321, url, valid)

proc call*(call_604322: Call_SignUp_604309; body: JsonNode): Recallable =
  ## signUp
  ## Registers the user in the specified user pool and creates a user name, password, and user attributes.
  ##   body: JObject (required)
  var body_604323 = newJObject()
  if body != nil:
    body_604323 = body
  result = call_604322.call(nil, nil, nil, nil, body_604323)

var signUp* = Call_SignUp_604309(name: "signUp", meth: HttpMethod.HttpPost,
                              host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SignUp",
                              validator: validate_SignUp_604310, base: "/",
                              url: url_SignUp_604311,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartUserImportJob_604324 = ref object of OpenApiRestCall_602433
proc url_StartUserImportJob_604326(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartUserImportJob_604325(path: JsonNode; query: JsonNode;
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
  var valid_604327 = header.getOrDefault("X-Amz-Date")
  valid_604327 = validateParameter(valid_604327, JString, required = false,
                                 default = nil)
  if valid_604327 != nil:
    section.add "X-Amz-Date", valid_604327
  var valid_604328 = header.getOrDefault("X-Amz-Security-Token")
  valid_604328 = validateParameter(valid_604328, JString, required = false,
                                 default = nil)
  if valid_604328 != nil:
    section.add "X-Amz-Security-Token", valid_604328
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604329 = header.getOrDefault("X-Amz-Target")
  valid_604329 = validateParameter(valid_604329, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.StartUserImportJob"))
  if valid_604329 != nil:
    section.add "X-Amz-Target", valid_604329
  var valid_604330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604330 = validateParameter(valid_604330, JString, required = false,
                                 default = nil)
  if valid_604330 != nil:
    section.add "X-Amz-Content-Sha256", valid_604330
  var valid_604331 = header.getOrDefault("X-Amz-Algorithm")
  valid_604331 = validateParameter(valid_604331, JString, required = false,
                                 default = nil)
  if valid_604331 != nil:
    section.add "X-Amz-Algorithm", valid_604331
  var valid_604332 = header.getOrDefault("X-Amz-Signature")
  valid_604332 = validateParameter(valid_604332, JString, required = false,
                                 default = nil)
  if valid_604332 != nil:
    section.add "X-Amz-Signature", valid_604332
  var valid_604333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604333 = validateParameter(valid_604333, JString, required = false,
                                 default = nil)
  if valid_604333 != nil:
    section.add "X-Amz-SignedHeaders", valid_604333
  var valid_604334 = header.getOrDefault("X-Amz-Credential")
  valid_604334 = validateParameter(valid_604334, JString, required = false,
                                 default = nil)
  if valid_604334 != nil:
    section.add "X-Amz-Credential", valid_604334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604336: Call_StartUserImportJob_604324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the user import.
  ## 
  let valid = call_604336.validator(path, query, header, formData, body)
  let scheme = call_604336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604336.url(scheme.get, call_604336.host, call_604336.base,
                         call_604336.route, valid.getOrDefault("path"))
  result = hook(call_604336, url, valid)

proc call*(call_604337: Call_StartUserImportJob_604324; body: JsonNode): Recallable =
  ## startUserImportJob
  ## Starts the user import.
  ##   body: JObject (required)
  var body_604338 = newJObject()
  if body != nil:
    body_604338 = body
  result = call_604337.call(nil, nil, nil, nil, body_604338)

var startUserImportJob* = Call_StartUserImportJob_604324(
    name: "startUserImportJob", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.StartUserImportJob",
    validator: validate_StartUserImportJob_604325, base: "/",
    url: url_StartUserImportJob_604326, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopUserImportJob_604339 = ref object of OpenApiRestCall_602433
proc url_StopUserImportJob_604341(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopUserImportJob_604340(path: JsonNode; query: JsonNode;
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
  var valid_604342 = header.getOrDefault("X-Amz-Date")
  valid_604342 = validateParameter(valid_604342, JString, required = false,
                                 default = nil)
  if valid_604342 != nil:
    section.add "X-Amz-Date", valid_604342
  var valid_604343 = header.getOrDefault("X-Amz-Security-Token")
  valid_604343 = validateParameter(valid_604343, JString, required = false,
                                 default = nil)
  if valid_604343 != nil:
    section.add "X-Amz-Security-Token", valid_604343
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604344 = header.getOrDefault("X-Amz-Target")
  valid_604344 = validateParameter(valid_604344, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.StopUserImportJob"))
  if valid_604344 != nil:
    section.add "X-Amz-Target", valid_604344
  var valid_604345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604345 = validateParameter(valid_604345, JString, required = false,
                                 default = nil)
  if valid_604345 != nil:
    section.add "X-Amz-Content-Sha256", valid_604345
  var valid_604346 = header.getOrDefault("X-Amz-Algorithm")
  valid_604346 = validateParameter(valid_604346, JString, required = false,
                                 default = nil)
  if valid_604346 != nil:
    section.add "X-Amz-Algorithm", valid_604346
  var valid_604347 = header.getOrDefault("X-Amz-Signature")
  valid_604347 = validateParameter(valid_604347, JString, required = false,
                                 default = nil)
  if valid_604347 != nil:
    section.add "X-Amz-Signature", valid_604347
  var valid_604348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604348 = validateParameter(valid_604348, JString, required = false,
                                 default = nil)
  if valid_604348 != nil:
    section.add "X-Amz-SignedHeaders", valid_604348
  var valid_604349 = header.getOrDefault("X-Amz-Credential")
  valid_604349 = validateParameter(valid_604349, JString, required = false,
                                 default = nil)
  if valid_604349 != nil:
    section.add "X-Amz-Credential", valid_604349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604351: Call_StopUserImportJob_604339; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the user import job.
  ## 
  let valid = call_604351.validator(path, query, header, formData, body)
  let scheme = call_604351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604351.url(scheme.get, call_604351.host, call_604351.base,
                         call_604351.route, valid.getOrDefault("path"))
  result = hook(call_604351, url, valid)

proc call*(call_604352: Call_StopUserImportJob_604339; body: JsonNode): Recallable =
  ## stopUserImportJob
  ## Stops the user import job.
  ##   body: JObject (required)
  var body_604353 = newJObject()
  if body != nil:
    body_604353 = body
  result = call_604352.call(nil, nil, nil, nil, body_604353)

var stopUserImportJob* = Call_StopUserImportJob_604339(name: "stopUserImportJob",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.StopUserImportJob",
    validator: validate_StopUserImportJob_604340, base: "/",
    url: url_StopUserImportJob_604341, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_604354 = ref object of OpenApiRestCall_602433
proc url_TagResource_604356(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_604355(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604357 = header.getOrDefault("X-Amz-Date")
  valid_604357 = validateParameter(valid_604357, JString, required = false,
                                 default = nil)
  if valid_604357 != nil:
    section.add "X-Amz-Date", valid_604357
  var valid_604358 = header.getOrDefault("X-Amz-Security-Token")
  valid_604358 = validateParameter(valid_604358, JString, required = false,
                                 default = nil)
  if valid_604358 != nil:
    section.add "X-Amz-Security-Token", valid_604358
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604359 = header.getOrDefault("X-Amz-Target")
  valid_604359 = validateParameter(valid_604359, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.TagResource"))
  if valid_604359 != nil:
    section.add "X-Amz-Target", valid_604359
  var valid_604360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604360 = validateParameter(valid_604360, JString, required = false,
                                 default = nil)
  if valid_604360 != nil:
    section.add "X-Amz-Content-Sha256", valid_604360
  var valid_604361 = header.getOrDefault("X-Amz-Algorithm")
  valid_604361 = validateParameter(valid_604361, JString, required = false,
                                 default = nil)
  if valid_604361 != nil:
    section.add "X-Amz-Algorithm", valid_604361
  var valid_604362 = header.getOrDefault("X-Amz-Signature")
  valid_604362 = validateParameter(valid_604362, JString, required = false,
                                 default = nil)
  if valid_604362 != nil:
    section.add "X-Amz-Signature", valid_604362
  var valid_604363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604363 = validateParameter(valid_604363, JString, required = false,
                                 default = nil)
  if valid_604363 != nil:
    section.add "X-Amz-SignedHeaders", valid_604363
  var valid_604364 = header.getOrDefault("X-Amz-Credential")
  valid_604364 = validateParameter(valid_604364, JString, required = false,
                                 default = nil)
  if valid_604364 != nil:
    section.add "X-Amz-Credential", valid_604364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604366: Call_TagResource_604354; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns a set of tags to an Amazon Cognito user pool. A tag is a label that you can use to categorize and manage user pools in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>Each tag consists of a key and value, both of which you define. A key is a general category for more specific values. For example, if you have two versions of a user pool, one for testing and another for production, you might assign an <code>Environment</code> tag key to both user pools. The value of this key might be <code>Test</code> for one user pool and <code>Production</code> for the other.</p> <p>Tags are useful for cost tracking and access control. You can activate your tags so that they appear on the Billing and Cost Management console, where you can track the costs associated with your user pools. In an IAM policy, you can constrain permissions for user pools based on specific tags or tag values.</p> <p>You can use this action up to 5 times per second, per account. A user pool can have as many as 50 tags.</p>
  ## 
  let valid = call_604366.validator(path, query, header, formData, body)
  let scheme = call_604366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604366.url(scheme.get, call_604366.host, call_604366.base,
                         call_604366.route, valid.getOrDefault("path"))
  result = hook(call_604366, url, valid)

proc call*(call_604367: Call_TagResource_604354; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Assigns a set of tags to an Amazon Cognito user pool. A tag is a label that you can use to categorize and manage user pools in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>Each tag consists of a key and value, both of which you define. A key is a general category for more specific values. For example, if you have two versions of a user pool, one for testing and another for production, you might assign an <code>Environment</code> tag key to both user pools. The value of this key might be <code>Test</code> for one user pool and <code>Production</code> for the other.</p> <p>Tags are useful for cost tracking and access control. You can activate your tags so that they appear on the Billing and Cost Management console, where you can track the costs associated with your user pools. In an IAM policy, you can constrain permissions for user pools based on specific tags or tag values.</p> <p>You can use this action up to 5 times per second, per account. A user pool can have as many as 50 tags.</p>
  ##   body: JObject (required)
  var body_604368 = newJObject()
  if body != nil:
    body_604368 = body
  result = call_604367.call(nil, nil, nil, nil, body_604368)

var tagResource* = Call_TagResource_604354(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.TagResource",
                                        validator: validate_TagResource_604355,
                                        base: "/", url: url_TagResource_604356,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_604369 = ref object of OpenApiRestCall_602433
proc url_UntagResource_604371(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_604370(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604372 = header.getOrDefault("X-Amz-Date")
  valid_604372 = validateParameter(valid_604372, JString, required = false,
                                 default = nil)
  if valid_604372 != nil:
    section.add "X-Amz-Date", valid_604372
  var valid_604373 = header.getOrDefault("X-Amz-Security-Token")
  valid_604373 = validateParameter(valid_604373, JString, required = false,
                                 default = nil)
  if valid_604373 != nil:
    section.add "X-Amz-Security-Token", valid_604373
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604374 = header.getOrDefault("X-Amz-Target")
  valid_604374 = validateParameter(valid_604374, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UntagResource"))
  if valid_604374 != nil:
    section.add "X-Amz-Target", valid_604374
  var valid_604375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604375 = validateParameter(valid_604375, JString, required = false,
                                 default = nil)
  if valid_604375 != nil:
    section.add "X-Amz-Content-Sha256", valid_604375
  var valid_604376 = header.getOrDefault("X-Amz-Algorithm")
  valid_604376 = validateParameter(valid_604376, JString, required = false,
                                 default = nil)
  if valid_604376 != nil:
    section.add "X-Amz-Algorithm", valid_604376
  var valid_604377 = header.getOrDefault("X-Amz-Signature")
  valid_604377 = validateParameter(valid_604377, JString, required = false,
                                 default = nil)
  if valid_604377 != nil:
    section.add "X-Amz-Signature", valid_604377
  var valid_604378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604378 = validateParameter(valid_604378, JString, required = false,
                                 default = nil)
  if valid_604378 != nil:
    section.add "X-Amz-SignedHeaders", valid_604378
  var valid_604379 = header.getOrDefault("X-Amz-Credential")
  valid_604379 = validateParameter(valid_604379, JString, required = false,
                                 default = nil)
  if valid_604379 != nil:
    section.add "X-Amz-Credential", valid_604379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604381: Call_UntagResource_604369; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified tags from an Amazon Cognito user pool. You can use this action up to 5 times per second, per account
  ## 
  let valid = call_604381.validator(path, query, header, formData, body)
  let scheme = call_604381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604381.url(scheme.get, call_604381.host, call_604381.base,
                         call_604381.route, valid.getOrDefault("path"))
  result = hook(call_604381, url, valid)

proc call*(call_604382: Call_UntagResource_604369; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tags from an Amazon Cognito user pool. You can use this action up to 5 times per second, per account
  ##   body: JObject (required)
  var body_604383 = newJObject()
  if body != nil:
    body_604383 = body
  result = call_604382.call(nil, nil, nil, nil, body_604383)

var untagResource* = Call_UntagResource_604369(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UntagResource",
    validator: validate_UntagResource_604370, base: "/", url: url_UntagResource_604371,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthEventFeedback_604384 = ref object of OpenApiRestCall_602433
proc url_UpdateAuthEventFeedback_604386(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateAuthEventFeedback_604385(path: JsonNode; query: JsonNode;
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
  var valid_604387 = header.getOrDefault("X-Amz-Date")
  valid_604387 = validateParameter(valid_604387, JString, required = false,
                                 default = nil)
  if valid_604387 != nil:
    section.add "X-Amz-Date", valid_604387
  var valid_604388 = header.getOrDefault("X-Amz-Security-Token")
  valid_604388 = validateParameter(valid_604388, JString, required = false,
                                 default = nil)
  if valid_604388 != nil:
    section.add "X-Amz-Security-Token", valid_604388
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604389 = header.getOrDefault("X-Amz-Target")
  valid_604389 = validateParameter(valid_604389, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateAuthEventFeedback"))
  if valid_604389 != nil:
    section.add "X-Amz-Target", valid_604389
  var valid_604390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604390 = validateParameter(valid_604390, JString, required = false,
                                 default = nil)
  if valid_604390 != nil:
    section.add "X-Amz-Content-Sha256", valid_604390
  var valid_604391 = header.getOrDefault("X-Amz-Algorithm")
  valid_604391 = validateParameter(valid_604391, JString, required = false,
                                 default = nil)
  if valid_604391 != nil:
    section.add "X-Amz-Algorithm", valid_604391
  var valid_604392 = header.getOrDefault("X-Amz-Signature")
  valid_604392 = validateParameter(valid_604392, JString, required = false,
                                 default = nil)
  if valid_604392 != nil:
    section.add "X-Amz-Signature", valid_604392
  var valid_604393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604393 = validateParameter(valid_604393, JString, required = false,
                                 default = nil)
  if valid_604393 != nil:
    section.add "X-Amz-SignedHeaders", valid_604393
  var valid_604394 = header.getOrDefault("X-Amz-Credential")
  valid_604394 = validateParameter(valid_604394, JString, required = false,
                                 default = nil)
  if valid_604394 != nil:
    section.add "X-Amz-Credential", valid_604394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604396: Call_UpdateAuthEventFeedback_604384; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the feedback for an authentication event whether it was from a valid user or not. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ## 
  let valid = call_604396.validator(path, query, header, formData, body)
  let scheme = call_604396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604396.url(scheme.get, call_604396.host, call_604396.base,
                         call_604396.route, valid.getOrDefault("path"))
  result = hook(call_604396, url, valid)

proc call*(call_604397: Call_UpdateAuthEventFeedback_604384; body: JsonNode): Recallable =
  ## updateAuthEventFeedback
  ## Provides the feedback for an authentication event whether it was from a valid user or not. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ##   body: JObject (required)
  var body_604398 = newJObject()
  if body != nil:
    body_604398 = body
  result = call_604397.call(nil, nil, nil, nil, body_604398)

var updateAuthEventFeedback* = Call_UpdateAuthEventFeedback_604384(
    name: "updateAuthEventFeedback", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateAuthEventFeedback",
    validator: validate_UpdateAuthEventFeedback_604385, base: "/",
    url: url_UpdateAuthEventFeedback_604386, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceStatus_604399 = ref object of OpenApiRestCall_602433
proc url_UpdateDeviceStatus_604401(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateDeviceStatus_604400(path: JsonNode; query: JsonNode;
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
  var valid_604402 = header.getOrDefault("X-Amz-Date")
  valid_604402 = validateParameter(valid_604402, JString, required = false,
                                 default = nil)
  if valid_604402 != nil:
    section.add "X-Amz-Date", valid_604402
  var valid_604403 = header.getOrDefault("X-Amz-Security-Token")
  valid_604403 = validateParameter(valid_604403, JString, required = false,
                                 default = nil)
  if valid_604403 != nil:
    section.add "X-Amz-Security-Token", valid_604403
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604404 = header.getOrDefault("X-Amz-Target")
  valid_604404 = validateParameter(valid_604404, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateDeviceStatus"))
  if valid_604404 != nil:
    section.add "X-Amz-Target", valid_604404
  var valid_604405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604405 = validateParameter(valid_604405, JString, required = false,
                                 default = nil)
  if valid_604405 != nil:
    section.add "X-Amz-Content-Sha256", valid_604405
  var valid_604406 = header.getOrDefault("X-Amz-Algorithm")
  valid_604406 = validateParameter(valid_604406, JString, required = false,
                                 default = nil)
  if valid_604406 != nil:
    section.add "X-Amz-Algorithm", valid_604406
  var valid_604407 = header.getOrDefault("X-Amz-Signature")
  valid_604407 = validateParameter(valid_604407, JString, required = false,
                                 default = nil)
  if valid_604407 != nil:
    section.add "X-Amz-Signature", valid_604407
  var valid_604408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604408 = validateParameter(valid_604408, JString, required = false,
                                 default = nil)
  if valid_604408 != nil:
    section.add "X-Amz-SignedHeaders", valid_604408
  var valid_604409 = header.getOrDefault("X-Amz-Credential")
  valid_604409 = validateParameter(valid_604409, JString, required = false,
                                 default = nil)
  if valid_604409 != nil:
    section.add "X-Amz-Credential", valid_604409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604411: Call_UpdateDeviceStatus_604399; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the device status.
  ## 
  let valid = call_604411.validator(path, query, header, formData, body)
  let scheme = call_604411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604411.url(scheme.get, call_604411.host, call_604411.base,
                         call_604411.route, valid.getOrDefault("path"))
  result = hook(call_604411, url, valid)

proc call*(call_604412: Call_UpdateDeviceStatus_604399; body: JsonNode): Recallable =
  ## updateDeviceStatus
  ## Updates the device status.
  ##   body: JObject (required)
  var body_604413 = newJObject()
  if body != nil:
    body_604413 = body
  result = call_604412.call(nil, nil, nil, nil, body_604413)

var updateDeviceStatus* = Call_UpdateDeviceStatus_604399(
    name: "updateDeviceStatus", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateDeviceStatus",
    validator: validate_UpdateDeviceStatus_604400, base: "/",
    url: url_UpdateDeviceStatus_604401, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_604414 = ref object of OpenApiRestCall_602433
proc url_UpdateGroup_604416(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateGroup_604415(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604417 = header.getOrDefault("X-Amz-Date")
  valid_604417 = validateParameter(valid_604417, JString, required = false,
                                 default = nil)
  if valid_604417 != nil:
    section.add "X-Amz-Date", valid_604417
  var valid_604418 = header.getOrDefault("X-Amz-Security-Token")
  valid_604418 = validateParameter(valid_604418, JString, required = false,
                                 default = nil)
  if valid_604418 != nil:
    section.add "X-Amz-Security-Token", valid_604418
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604419 = header.getOrDefault("X-Amz-Target")
  valid_604419 = validateParameter(valid_604419, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateGroup"))
  if valid_604419 != nil:
    section.add "X-Amz-Target", valid_604419
  var valid_604420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604420 = validateParameter(valid_604420, JString, required = false,
                                 default = nil)
  if valid_604420 != nil:
    section.add "X-Amz-Content-Sha256", valid_604420
  var valid_604421 = header.getOrDefault("X-Amz-Algorithm")
  valid_604421 = validateParameter(valid_604421, JString, required = false,
                                 default = nil)
  if valid_604421 != nil:
    section.add "X-Amz-Algorithm", valid_604421
  var valid_604422 = header.getOrDefault("X-Amz-Signature")
  valid_604422 = validateParameter(valid_604422, JString, required = false,
                                 default = nil)
  if valid_604422 != nil:
    section.add "X-Amz-Signature", valid_604422
  var valid_604423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604423 = validateParameter(valid_604423, JString, required = false,
                                 default = nil)
  if valid_604423 != nil:
    section.add "X-Amz-SignedHeaders", valid_604423
  var valid_604424 = header.getOrDefault("X-Amz-Credential")
  valid_604424 = validateParameter(valid_604424, JString, required = false,
                                 default = nil)
  if valid_604424 != nil:
    section.add "X-Amz-Credential", valid_604424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604426: Call_UpdateGroup_604414; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified group with the specified attributes.</p> <p>Requires developer credentials.</p>
  ## 
  let valid = call_604426.validator(path, query, header, formData, body)
  let scheme = call_604426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604426.url(scheme.get, call_604426.host, call_604426.base,
                         call_604426.route, valid.getOrDefault("path"))
  result = hook(call_604426, url, valid)

proc call*(call_604427: Call_UpdateGroup_604414; body: JsonNode): Recallable =
  ## updateGroup
  ## <p>Updates the specified group with the specified attributes.</p> <p>Requires developer credentials.</p>
  ##   body: JObject (required)
  var body_604428 = newJObject()
  if body != nil:
    body_604428 = body
  result = call_604427.call(nil, nil, nil, nil, body_604428)

var updateGroup* = Call_UpdateGroup_604414(name: "updateGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateGroup",
                                        validator: validate_UpdateGroup_604415,
                                        base: "/", url: url_UpdateGroup_604416,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIdentityProvider_604429 = ref object of OpenApiRestCall_602433
proc url_UpdateIdentityProvider_604431(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateIdentityProvider_604430(path: JsonNode; query: JsonNode;
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
  var valid_604432 = header.getOrDefault("X-Amz-Date")
  valid_604432 = validateParameter(valid_604432, JString, required = false,
                                 default = nil)
  if valid_604432 != nil:
    section.add "X-Amz-Date", valid_604432
  var valid_604433 = header.getOrDefault("X-Amz-Security-Token")
  valid_604433 = validateParameter(valid_604433, JString, required = false,
                                 default = nil)
  if valid_604433 != nil:
    section.add "X-Amz-Security-Token", valid_604433
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604434 = header.getOrDefault("X-Amz-Target")
  valid_604434 = validateParameter(valid_604434, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateIdentityProvider"))
  if valid_604434 != nil:
    section.add "X-Amz-Target", valid_604434
  var valid_604435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604435 = validateParameter(valid_604435, JString, required = false,
                                 default = nil)
  if valid_604435 != nil:
    section.add "X-Amz-Content-Sha256", valid_604435
  var valid_604436 = header.getOrDefault("X-Amz-Algorithm")
  valid_604436 = validateParameter(valid_604436, JString, required = false,
                                 default = nil)
  if valid_604436 != nil:
    section.add "X-Amz-Algorithm", valid_604436
  var valid_604437 = header.getOrDefault("X-Amz-Signature")
  valid_604437 = validateParameter(valid_604437, JString, required = false,
                                 default = nil)
  if valid_604437 != nil:
    section.add "X-Amz-Signature", valid_604437
  var valid_604438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604438 = validateParameter(valid_604438, JString, required = false,
                                 default = nil)
  if valid_604438 != nil:
    section.add "X-Amz-SignedHeaders", valid_604438
  var valid_604439 = header.getOrDefault("X-Amz-Credential")
  valid_604439 = validateParameter(valid_604439, JString, required = false,
                                 default = nil)
  if valid_604439 != nil:
    section.add "X-Amz-Credential", valid_604439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604441: Call_UpdateIdentityProvider_604429; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates identity provider information for a user pool.
  ## 
  let valid = call_604441.validator(path, query, header, formData, body)
  let scheme = call_604441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604441.url(scheme.get, call_604441.host, call_604441.base,
                         call_604441.route, valid.getOrDefault("path"))
  result = hook(call_604441, url, valid)

proc call*(call_604442: Call_UpdateIdentityProvider_604429; body: JsonNode): Recallable =
  ## updateIdentityProvider
  ## Updates identity provider information for a user pool.
  ##   body: JObject (required)
  var body_604443 = newJObject()
  if body != nil:
    body_604443 = body
  result = call_604442.call(nil, nil, nil, nil, body_604443)

var updateIdentityProvider* = Call_UpdateIdentityProvider_604429(
    name: "updateIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateIdentityProvider",
    validator: validate_UpdateIdentityProvider_604430, base: "/",
    url: url_UpdateIdentityProvider_604431, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceServer_604444 = ref object of OpenApiRestCall_602433
proc url_UpdateResourceServer_604446(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateResourceServer_604445(path: JsonNode; query: JsonNode;
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
  var valid_604447 = header.getOrDefault("X-Amz-Date")
  valid_604447 = validateParameter(valid_604447, JString, required = false,
                                 default = nil)
  if valid_604447 != nil:
    section.add "X-Amz-Date", valid_604447
  var valid_604448 = header.getOrDefault("X-Amz-Security-Token")
  valid_604448 = validateParameter(valid_604448, JString, required = false,
                                 default = nil)
  if valid_604448 != nil:
    section.add "X-Amz-Security-Token", valid_604448
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604449 = header.getOrDefault("X-Amz-Target")
  valid_604449 = validateParameter(valid_604449, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateResourceServer"))
  if valid_604449 != nil:
    section.add "X-Amz-Target", valid_604449
  var valid_604450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604450 = validateParameter(valid_604450, JString, required = false,
                                 default = nil)
  if valid_604450 != nil:
    section.add "X-Amz-Content-Sha256", valid_604450
  var valid_604451 = header.getOrDefault("X-Amz-Algorithm")
  valid_604451 = validateParameter(valid_604451, JString, required = false,
                                 default = nil)
  if valid_604451 != nil:
    section.add "X-Amz-Algorithm", valid_604451
  var valid_604452 = header.getOrDefault("X-Amz-Signature")
  valid_604452 = validateParameter(valid_604452, JString, required = false,
                                 default = nil)
  if valid_604452 != nil:
    section.add "X-Amz-Signature", valid_604452
  var valid_604453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604453 = validateParameter(valid_604453, JString, required = false,
                                 default = nil)
  if valid_604453 != nil:
    section.add "X-Amz-SignedHeaders", valid_604453
  var valid_604454 = header.getOrDefault("X-Amz-Credential")
  valid_604454 = validateParameter(valid_604454, JString, required = false,
                                 default = nil)
  if valid_604454 != nil:
    section.add "X-Amz-Credential", valid_604454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604456: Call_UpdateResourceServer_604444; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the name and scopes of resource server. All other fields are read-only.
  ## 
  let valid = call_604456.validator(path, query, header, formData, body)
  let scheme = call_604456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604456.url(scheme.get, call_604456.host, call_604456.base,
                         call_604456.route, valid.getOrDefault("path"))
  result = hook(call_604456, url, valid)

proc call*(call_604457: Call_UpdateResourceServer_604444; body: JsonNode): Recallable =
  ## updateResourceServer
  ## Updates the name and scopes of resource server. All other fields are read-only.
  ##   body: JObject (required)
  var body_604458 = newJObject()
  if body != nil:
    body_604458 = body
  result = call_604457.call(nil, nil, nil, nil, body_604458)

var updateResourceServer* = Call_UpdateResourceServer_604444(
    name: "updateResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateResourceServer",
    validator: validate_UpdateResourceServer_604445, base: "/",
    url: url_UpdateResourceServer_604446, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserAttributes_604459 = ref object of OpenApiRestCall_602433
proc url_UpdateUserAttributes_604461(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateUserAttributes_604460(path: JsonNode; query: JsonNode;
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
  var valid_604462 = header.getOrDefault("X-Amz-Date")
  valid_604462 = validateParameter(valid_604462, JString, required = false,
                                 default = nil)
  if valid_604462 != nil:
    section.add "X-Amz-Date", valid_604462
  var valid_604463 = header.getOrDefault("X-Amz-Security-Token")
  valid_604463 = validateParameter(valid_604463, JString, required = false,
                                 default = nil)
  if valid_604463 != nil:
    section.add "X-Amz-Security-Token", valid_604463
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604464 = header.getOrDefault("X-Amz-Target")
  valid_604464 = validateParameter(valid_604464, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserAttributes"))
  if valid_604464 != nil:
    section.add "X-Amz-Target", valid_604464
  var valid_604465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604465 = validateParameter(valid_604465, JString, required = false,
                                 default = nil)
  if valid_604465 != nil:
    section.add "X-Amz-Content-Sha256", valid_604465
  var valid_604466 = header.getOrDefault("X-Amz-Algorithm")
  valid_604466 = validateParameter(valid_604466, JString, required = false,
                                 default = nil)
  if valid_604466 != nil:
    section.add "X-Amz-Algorithm", valid_604466
  var valid_604467 = header.getOrDefault("X-Amz-Signature")
  valid_604467 = validateParameter(valid_604467, JString, required = false,
                                 default = nil)
  if valid_604467 != nil:
    section.add "X-Amz-Signature", valid_604467
  var valid_604468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604468 = validateParameter(valid_604468, JString, required = false,
                                 default = nil)
  if valid_604468 != nil:
    section.add "X-Amz-SignedHeaders", valid_604468
  var valid_604469 = header.getOrDefault("X-Amz-Credential")
  valid_604469 = validateParameter(valid_604469, JString, required = false,
                                 default = nil)
  if valid_604469 != nil:
    section.add "X-Amz-Credential", valid_604469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604471: Call_UpdateUserAttributes_604459; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a user to update a specific attribute (one at a time).
  ## 
  let valid = call_604471.validator(path, query, header, formData, body)
  let scheme = call_604471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604471.url(scheme.get, call_604471.host, call_604471.base,
                         call_604471.route, valid.getOrDefault("path"))
  result = hook(call_604471, url, valid)

proc call*(call_604472: Call_UpdateUserAttributes_604459; body: JsonNode): Recallable =
  ## updateUserAttributes
  ## Allows a user to update a specific attribute (one at a time).
  ##   body: JObject (required)
  var body_604473 = newJObject()
  if body != nil:
    body_604473 = body
  result = call_604472.call(nil, nil, nil, nil, body_604473)

var updateUserAttributes* = Call_UpdateUserAttributes_604459(
    name: "updateUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserAttributes",
    validator: validate_UpdateUserAttributes_604460, base: "/",
    url: url_UpdateUserAttributes_604461, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPool_604474 = ref object of OpenApiRestCall_602433
proc url_UpdateUserPool_604476(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateUserPool_604475(path: JsonNode; query: JsonNode;
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
  var valid_604477 = header.getOrDefault("X-Amz-Date")
  valid_604477 = validateParameter(valid_604477, JString, required = false,
                                 default = nil)
  if valid_604477 != nil:
    section.add "X-Amz-Date", valid_604477
  var valid_604478 = header.getOrDefault("X-Amz-Security-Token")
  valid_604478 = validateParameter(valid_604478, JString, required = false,
                                 default = nil)
  if valid_604478 != nil:
    section.add "X-Amz-Security-Token", valid_604478
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604479 = header.getOrDefault("X-Amz-Target")
  valid_604479 = validateParameter(valid_604479, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserPool"))
  if valid_604479 != nil:
    section.add "X-Amz-Target", valid_604479
  var valid_604480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604480 = validateParameter(valid_604480, JString, required = false,
                                 default = nil)
  if valid_604480 != nil:
    section.add "X-Amz-Content-Sha256", valid_604480
  var valid_604481 = header.getOrDefault("X-Amz-Algorithm")
  valid_604481 = validateParameter(valid_604481, JString, required = false,
                                 default = nil)
  if valid_604481 != nil:
    section.add "X-Amz-Algorithm", valid_604481
  var valid_604482 = header.getOrDefault("X-Amz-Signature")
  valid_604482 = validateParameter(valid_604482, JString, required = false,
                                 default = nil)
  if valid_604482 != nil:
    section.add "X-Amz-Signature", valid_604482
  var valid_604483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604483 = validateParameter(valid_604483, JString, required = false,
                                 default = nil)
  if valid_604483 != nil:
    section.add "X-Amz-SignedHeaders", valid_604483
  var valid_604484 = header.getOrDefault("X-Amz-Credential")
  valid_604484 = validateParameter(valid_604484, JString, required = false,
                                 default = nil)
  if valid_604484 != nil:
    section.add "X-Amz-Credential", valid_604484
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604486: Call_UpdateUserPool_604474; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified user pool with the specified attributes. If you don't provide a value for an attribute, it will be set to the default value. You can get a list of the current user pool settings with .
  ## 
  let valid = call_604486.validator(path, query, header, formData, body)
  let scheme = call_604486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604486.url(scheme.get, call_604486.host, call_604486.base,
                         call_604486.route, valid.getOrDefault("path"))
  result = hook(call_604486, url, valid)

proc call*(call_604487: Call_UpdateUserPool_604474; body: JsonNode): Recallable =
  ## updateUserPool
  ## Updates the specified user pool with the specified attributes. If you don't provide a value for an attribute, it will be set to the default value. You can get a list of the current user pool settings with .
  ##   body: JObject (required)
  var body_604488 = newJObject()
  if body != nil:
    body_604488 = body
  result = call_604487.call(nil, nil, nil, nil, body_604488)

var updateUserPool* = Call_UpdateUserPool_604474(name: "updateUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserPool",
    validator: validate_UpdateUserPool_604475, base: "/", url: url_UpdateUserPool_604476,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPoolClient_604489 = ref object of OpenApiRestCall_602433
proc url_UpdateUserPoolClient_604491(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateUserPoolClient_604490(path: JsonNode; query: JsonNode;
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
  var valid_604492 = header.getOrDefault("X-Amz-Date")
  valid_604492 = validateParameter(valid_604492, JString, required = false,
                                 default = nil)
  if valid_604492 != nil:
    section.add "X-Amz-Date", valid_604492
  var valid_604493 = header.getOrDefault("X-Amz-Security-Token")
  valid_604493 = validateParameter(valid_604493, JString, required = false,
                                 default = nil)
  if valid_604493 != nil:
    section.add "X-Amz-Security-Token", valid_604493
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604494 = header.getOrDefault("X-Amz-Target")
  valid_604494 = validateParameter(valid_604494, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserPoolClient"))
  if valid_604494 != nil:
    section.add "X-Amz-Target", valid_604494
  var valid_604495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604495 = validateParameter(valid_604495, JString, required = false,
                                 default = nil)
  if valid_604495 != nil:
    section.add "X-Amz-Content-Sha256", valid_604495
  var valid_604496 = header.getOrDefault("X-Amz-Algorithm")
  valid_604496 = validateParameter(valid_604496, JString, required = false,
                                 default = nil)
  if valid_604496 != nil:
    section.add "X-Amz-Algorithm", valid_604496
  var valid_604497 = header.getOrDefault("X-Amz-Signature")
  valid_604497 = validateParameter(valid_604497, JString, required = false,
                                 default = nil)
  if valid_604497 != nil:
    section.add "X-Amz-Signature", valid_604497
  var valid_604498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604498 = validateParameter(valid_604498, JString, required = false,
                                 default = nil)
  if valid_604498 != nil:
    section.add "X-Amz-SignedHeaders", valid_604498
  var valid_604499 = header.getOrDefault("X-Amz-Credential")
  valid_604499 = validateParameter(valid_604499, JString, required = false,
                                 default = nil)
  if valid_604499 != nil:
    section.add "X-Amz-Credential", valid_604499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604501: Call_UpdateUserPoolClient_604489; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified user pool app client with the specified attributes. If you don't provide a value for an attribute, it will be set to the default value. You can get a list of the current user pool app client settings with .
  ## 
  let valid = call_604501.validator(path, query, header, formData, body)
  let scheme = call_604501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604501.url(scheme.get, call_604501.host, call_604501.base,
                         call_604501.route, valid.getOrDefault("path"))
  result = hook(call_604501, url, valid)

proc call*(call_604502: Call_UpdateUserPoolClient_604489; body: JsonNode): Recallable =
  ## updateUserPoolClient
  ## Updates the specified user pool app client with the specified attributes. If you don't provide a value for an attribute, it will be set to the default value. You can get a list of the current user pool app client settings with .
  ##   body: JObject (required)
  var body_604503 = newJObject()
  if body != nil:
    body_604503 = body
  result = call_604502.call(nil, nil, nil, nil, body_604503)

var updateUserPoolClient* = Call_UpdateUserPoolClient_604489(
    name: "updateUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserPoolClient",
    validator: validate_UpdateUserPoolClient_604490, base: "/",
    url: url_UpdateUserPoolClient_604491, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPoolDomain_604504 = ref object of OpenApiRestCall_602433
proc url_UpdateUserPoolDomain_604506(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateUserPoolDomain_604505(path: JsonNode; query: JsonNode;
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
  var valid_604507 = header.getOrDefault("X-Amz-Date")
  valid_604507 = validateParameter(valid_604507, JString, required = false,
                                 default = nil)
  if valid_604507 != nil:
    section.add "X-Amz-Date", valid_604507
  var valid_604508 = header.getOrDefault("X-Amz-Security-Token")
  valid_604508 = validateParameter(valid_604508, JString, required = false,
                                 default = nil)
  if valid_604508 != nil:
    section.add "X-Amz-Security-Token", valid_604508
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604509 = header.getOrDefault("X-Amz-Target")
  valid_604509 = validateParameter(valid_604509, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserPoolDomain"))
  if valid_604509 != nil:
    section.add "X-Amz-Target", valid_604509
  var valid_604510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604510 = validateParameter(valid_604510, JString, required = false,
                                 default = nil)
  if valid_604510 != nil:
    section.add "X-Amz-Content-Sha256", valid_604510
  var valid_604511 = header.getOrDefault("X-Amz-Algorithm")
  valid_604511 = validateParameter(valid_604511, JString, required = false,
                                 default = nil)
  if valid_604511 != nil:
    section.add "X-Amz-Algorithm", valid_604511
  var valid_604512 = header.getOrDefault("X-Amz-Signature")
  valid_604512 = validateParameter(valid_604512, JString, required = false,
                                 default = nil)
  if valid_604512 != nil:
    section.add "X-Amz-Signature", valid_604512
  var valid_604513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604513 = validateParameter(valid_604513, JString, required = false,
                                 default = nil)
  if valid_604513 != nil:
    section.add "X-Amz-SignedHeaders", valid_604513
  var valid_604514 = header.getOrDefault("X-Amz-Credential")
  valid_604514 = validateParameter(valid_604514, JString, required = false,
                                 default = nil)
  if valid_604514 != nil:
    section.add "X-Amz-Credential", valid_604514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604516: Call_UpdateUserPoolDomain_604504; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the Secure Sockets Layer (SSL) certificate for the custom domain for your user pool.</p> <p>You can use this operation to provide the Amazon Resource Name (ARN) of a new certificate to Amazon Cognito. You cannot use it to change the domain for a user pool.</p> <p>A custom domain is used to host the Amazon Cognito hosted UI, which provides sign-up and sign-in pages for your application. When you set up a custom domain, you provide a certificate that you manage with AWS Certificate Manager (ACM). When necessary, you can use this operation to change the certificate that you applied to your custom domain.</p> <p>Usually, this is unnecessary following routine certificate renewal with ACM. When you renew your existing certificate in ACM, the ARN for your certificate remains the same, and your custom domain uses the new certificate automatically.</p> <p>However, if you replace your existing certificate with a new one, ACM gives the new certificate a new ARN. To apply the new certificate to your custom domain, you must provide this ARN to Amazon Cognito.</p> <p>When you add your new certificate in ACM, you must choose US East (N. Virginia) as the AWS Region.</p> <p>After you submit your request, Amazon Cognito requires up to 1 hour to distribute your new certificate to your custom domain.</p> <p>For more information about adding a custom domain to your user pool, see <a href="https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-add-custom-domain.html">Using Your Own Domain for the Hosted UI</a>.</p>
  ## 
  let valid = call_604516.validator(path, query, header, formData, body)
  let scheme = call_604516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604516.url(scheme.get, call_604516.host, call_604516.base,
                         call_604516.route, valid.getOrDefault("path"))
  result = hook(call_604516, url, valid)

proc call*(call_604517: Call_UpdateUserPoolDomain_604504; body: JsonNode): Recallable =
  ## updateUserPoolDomain
  ## <p>Updates the Secure Sockets Layer (SSL) certificate for the custom domain for your user pool.</p> <p>You can use this operation to provide the Amazon Resource Name (ARN) of a new certificate to Amazon Cognito. You cannot use it to change the domain for a user pool.</p> <p>A custom domain is used to host the Amazon Cognito hosted UI, which provides sign-up and sign-in pages for your application. When you set up a custom domain, you provide a certificate that you manage with AWS Certificate Manager (ACM). When necessary, you can use this operation to change the certificate that you applied to your custom domain.</p> <p>Usually, this is unnecessary following routine certificate renewal with ACM. When you renew your existing certificate in ACM, the ARN for your certificate remains the same, and your custom domain uses the new certificate automatically.</p> <p>However, if you replace your existing certificate with a new one, ACM gives the new certificate a new ARN. To apply the new certificate to your custom domain, you must provide this ARN to Amazon Cognito.</p> <p>When you add your new certificate in ACM, you must choose US East (N. Virginia) as the AWS Region.</p> <p>After you submit your request, Amazon Cognito requires up to 1 hour to distribute your new certificate to your custom domain.</p> <p>For more information about adding a custom domain to your user pool, see <a href="https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-add-custom-domain.html">Using Your Own Domain for the Hosted UI</a>.</p>
  ##   body: JObject (required)
  var body_604518 = newJObject()
  if body != nil:
    body_604518 = body
  result = call_604517.call(nil, nil, nil, nil, body_604518)

var updateUserPoolDomain* = Call_UpdateUserPoolDomain_604504(
    name: "updateUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserPoolDomain",
    validator: validate_UpdateUserPoolDomain_604505, base: "/",
    url: url_UpdateUserPoolDomain_604506, schemes: {Scheme.Https, Scheme.Http})
type
  Call_VerifySoftwareToken_604519 = ref object of OpenApiRestCall_602433
proc url_VerifySoftwareToken_604521(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_VerifySoftwareToken_604520(path: JsonNode; query: JsonNode;
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
  var valid_604522 = header.getOrDefault("X-Amz-Date")
  valid_604522 = validateParameter(valid_604522, JString, required = false,
                                 default = nil)
  if valid_604522 != nil:
    section.add "X-Amz-Date", valid_604522
  var valid_604523 = header.getOrDefault("X-Amz-Security-Token")
  valid_604523 = validateParameter(valid_604523, JString, required = false,
                                 default = nil)
  if valid_604523 != nil:
    section.add "X-Amz-Security-Token", valid_604523
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604524 = header.getOrDefault("X-Amz-Target")
  valid_604524 = validateParameter(valid_604524, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.VerifySoftwareToken"))
  if valid_604524 != nil:
    section.add "X-Amz-Target", valid_604524
  var valid_604525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604525 = validateParameter(valid_604525, JString, required = false,
                                 default = nil)
  if valid_604525 != nil:
    section.add "X-Amz-Content-Sha256", valid_604525
  var valid_604526 = header.getOrDefault("X-Amz-Algorithm")
  valid_604526 = validateParameter(valid_604526, JString, required = false,
                                 default = nil)
  if valid_604526 != nil:
    section.add "X-Amz-Algorithm", valid_604526
  var valid_604527 = header.getOrDefault("X-Amz-Signature")
  valid_604527 = validateParameter(valid_604527, JString, required = false,
                                 default = nil)
  if valid_604527 != nil:
    section.add "X-Amz-Signature", valid_604527
  var valid_604528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604528 = validateParameter(valid_604528, JString, required = false,
                                 default = nil)
  if valid_604528 != nil:
    section.add "X-Amz-SignedHeaders", valid_604528
  var valid_604529 = header.getOrDefault("X-Amz-Credential")
  valid_604529 = validateParameter(valid_604529, JString, required = false,
                                 default = nil)
  if valid_604529 != nil:
    section.add "X-Amz-Credential", valid_604529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604531: Call_VerifySoftwareToken_604519; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Use this API to register a user's entered TOTP code and mark the user's software token MFA status as "verified" if successful. The request takes an access token or a session string, but not both.
  ## 
  let valid = call_604531.validator(path, query, header, formData, body)
  let scheme = call_604531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604531.url(scheme.get, call_604531.host, call_604531.base,
                         call_604531.route, valid.getOrDefault("path"))
  result = hook(call_604531, url, valid)

proc call*(call_604532: Call_VerifySoftwareToken_604519; body: JsonNode): Recallable =
  ## verifySoftwareToken
  ## Use this API to register a user's entered TOTP code and mark the user's software token MFA status as "verified" if successful. The request takes an access token or a session string, but not both.
  ##   body: JObject (required)
  var body_604533 = newJObject()
  if body != nil:
    body_604533 = body
  result = call_604532.call(nil, nil, nil, nil, body_604533)

var verifySoftwareToken* = Call_VerifySoftwareToken_604519(
    name: "verifySoftwareToken", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.VerifySoftwareToken",
    validator: validate_VerifySoftwareToken_604520, base: "/",
    url: url_VerifySoftwareToken_604521, schemes: {Scheme.Https, Scheme.Http})
type
  Call_VerifyUserAttribute_604534 = ref object of OpenApiRestCall_602433
proc url_VerifyUserAttribute_604536(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_VerifyUserAttribute_604535(path: JsonNode; query: JsonNode;
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
  var valid_604537 = header.getOrDefault("X-Amz-Date")
  valid_604537 = validateParameter(valid_604537, JString, required = false,
                                 default = nil)
  if valid_604537 != nil:
    section.add "X-Amz-Date", valid_604537
  var valid_604538 = header.getOrDefault("X-Amz-Security-Token")
  valid_604538 = validateParameter(valid_604538, JString, required = false,
                                 default = nil)
  if valid_604538 != nil:
    section.add "X-Amz-Security-Token", valid_604538
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604539 = header.getOrDefault("X-Amz-Target")
  valid_604539 = validateParameter(valid_604539, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.VerifyUserAttribute"))
  if valid_604539 != nil:
    section.add "X-Amz-Target", valid_604539
  var valid_604540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604540 = validateParameter(valid_604540, JString, required = false,
                                 default = nil)
  if valid_604540 != nil:
    section.add "X-Amz-Content-Sha256", valid_604540
  var valid_604541 = header.getOrDefault("X-Amz-Algorithm")
  valid_604541 = validateParameter(valid_604541, JString, required = false,
                                 default = nil)
  if valid_604541 != nil:
    section.add "X-Amz-Algorithm", valid_604541
  var valid_604542 = header.getOrDefault("X-Amz-Signature")
  valid_604542 = validateParameter(valid_604542, JString, required = false,
                                 default = nil)
  if valid_604542 != nil:
    section.add "X-Amz-Signature", valid_604542
  var valid_604543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604543 = validateParameter(valid_604543, JString, required = false,
                                 default = nil)
  if valid_604543 != nil:
    section.add "X-Amz-SignedHeaders", valid_604543
  var valid_604544 = header.getOrDefault("X-Amz-Credential")
  valid_604544 = validateParameter(valid_604544, JString, required = false,
                                 default = nil)
  if valid_604544 != nil:
    section.add "X-Amz-Credential", valid_604544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604546: Call_VerifyUserAttribute_604534; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Verifies the specified user attributes in the user pool.
  ## 
  let valid = call_604546.validator(path, query, header, formData, body)
  let scheme = call_604546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604546.url(scheme.get, call_604546.host, call_604546.base,
                         call_604546.route, valid.getOrDefault("path"))
  result = hook(call_604546, url, valid)

proc call*(call_604547: Call_VerifyUserAttribute_604534; body: JsonNode): Recallable =
  ## verifyUserAttribute
  ## Verifies the specified user attributes in the user pool.
  ##   body: JObject (required)
  var body_604548 = newJObject()
  if body != nil:
    body_604548 = body
  result = call_604547.call(nil, nil, nil, nil, body_604548)

var verifyUserAttribute* = Call_VerifyUserAttribute_604534(
    name: "verifyUserAttribute", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.VerifyUserAttribute",
    validator: validate_VerifyUserAttribute_604535, base: "/",
    url: url_VerifyUserAttribute_604536, schemes: {Scheme.Https, Scheme.Http})
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

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
