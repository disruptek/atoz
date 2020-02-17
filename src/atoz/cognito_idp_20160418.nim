
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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
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
  Call_AddCustomAttributes_610996 = ref object of OpenApiRestCall_610658
proc url_AddCustomAttributes_610998(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddCustomAttributes_610997(path: JsonNode; query: JsonNode;
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
  var valid_611123 = header.getOrDefault("X-Amz-Target")
  valid_611123 = validateParameter(valid_611123, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AddCustomAttributes"))
  if valid_611123 != nil:
    section.add "X-Amz-Target", valid_611123
  var valid_611124 = header.getOrDefault("X-Amz-Signature")
  valid_611124 = validateParameter(valid_611124, JString, required = false,
                                 default = nil)
  if valid_611124 != nil:
    section.add "X-Amz-Signature", valid_611124
  var valid_611125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611125 = validateParameter(valid_611125, JString, required = false,
                                 default = nil)
  if valid_611125 != nil:
    section.add "X-Amz-Content-Sha256", valid_611125
  var valid_611126 = header.getOrDefault("X-Amz-Date")
  valid_611126 = validateParameter(valid_611126, JString, required = false,
                                 default = nil)
  if valid_611126 != nil:
    section.add "X-Amz-Date", valid_611126
  var valid_611127 = header.getOrDefault("X-Amz-Credential")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "X-Amz-Credential", valid_611127
  var valid_611128 = header.getOrDefault("X-Amz-Security-Token")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "X-Amz-Security-Token", valid_611128
  var valid_611129 = header.getOrDefault("X-Amz-Algorithm")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Algorithm", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-SignedHeaders", valid_611130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611154: Call_AddCustomAttributes_610996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds additional user attributes to the user pool schema.
  ## 
  let valid = call_611154.validator(path, query, header, formData, body)
  let scheme = call_611154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611154.url(scheme.get, call_611154.host, call_611154.base,
                         call_611154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611154, url, valid)

proc call*(call_611225: Call_AddCustomAttributes_610996; body: JsonNode): Recallable =
  ## addCustomAttributes
  ## Adds additional user attributes to the user pool schema.
  ##   body: JObject (required)
  var body_611226 = newJObject()
  if body != nil:
    body_611226 = body
  result = call_611225.call(nil, nil, nil, nil, body_611226)

var addCustomAttributes* = Call_AddCustomAttributes_610996(
    name: "addCustomAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AddCustomAttributes",
    validator: validate_AddCustomAttributes_610997, base: "/",
    url: url_AddCustomAttributes_610998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminAddUserToGroup_611265 = ref object of OpenApiRestCall_610658
proc url_AdminAddUserToGroup_611267(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminAddUserToGroup_611266(path: JsonNode; query: JsonNode;
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
  var valid_611268 = header.getOrDefault("X-Amz-Target")
  valid_611268 = validateParameter(valid_611268, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminAddUserToGroup"))
  if valid_611268 != nil:
    section.add "X-Amz-Target", valid_611268
  var valid_611269 = header.getOrDefault("X-Amz-Signature")
  valid_611269 = validateParameter(valid_611269, JString, required = false,
                                 default = nil)
  if valid_611269 != nil:
    section.add "X-Amz-Signature", valid_611269
  var valid_611270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "X-Amz-Content-Sha256", valid_611270
  var valid_611271 = header.getOrDefault("X-Amz-Date")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Date", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-Credential")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Credential", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Security-Token")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Security-Token", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Algorithm")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Algorithm", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-SignedHeaders", valid_611275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611277: Call_AdminAddUserToGroup_611265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified user to the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_611277.validator(path, query, header, formData, body)
  let scheme = call_611277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611277.url(scheme.get, call_611277.host, call_611277.base,
                         call_611277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611277, url, valid)

proc call*(call_611278: Call_AdminAddUserToGroup_611265; body: JsonNode): Recallable =
  ## adminAddUserToGroup
  ## <p>Adds the specified user to the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_611279 = newJObject()
  if body != nil:
    body_611279 = body
  result = call_611278.call(nil, nil, nil, nil, body_611279)

var adminAddUserToGroup* = Call_AdminAddUserToGroup_611265(
    name: "adminAddUserToGroup", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminAddUserToGroup",
    validator: validate_AdminAddUserToGroup_611266, base: "/",
    url: url_AdminAddUserToGroup_611267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminConfirmSignUp_611280 = ref object of OpenApiRestCall_610658
proc url_AdminConfirmSignUp_611282(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminConfirmSignUp_611281(path: JsonNode; query: JsonNode;
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
  var valid_611283 = header.getOrDefault("X-Amz-Target")
  valid_611283 = validateParameter(valid_611283, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminConfirmSignUp"))
  if valid_611283 != nil:
    section.add "X-Amz-Target", valid_611283
  var valid_611284 = header.getOrDefault("X-Amz-Signature")
  valid_611284 = validateParameter(valid_611284, JString, required = false,
                                 default = nil)
  if valid_611284 != nil:
    section.add "X-Amz-Signature", valid_611284
  var valid_611285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611285 = validateParameter(valid_611285, JString, required = false,
                                 default = nil)
  if valid_611285 != nil:
    section.add "X-Amz-Content-Sha256", valid_611285
  var valid_611286 = header.getOrDefault("X-Amz-Date")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-Date", valid_611286
  var valid_611287 = header.getOrDefault("X-Amz-Credential")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Credential", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-Security-Token")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Security-Token", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Algorithm")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Algorithm", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-SignedHeaders", valid_611290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611292: Call_AdminConfirmSignUp_611280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Confirms user registration as an admin without using a confirmation code. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_611292.validator(path, query, header, formData, body)
  let scheme = call_611292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611292.url(scheme.get, call_611292.host, call_611292.base,
                         call_611292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611292, url, valid)

proc call*(call_611293: Call_AdminConfirmSignUp_611280; body: JsonNode): Recallable =
  ## adminConfirmSignUp
  ## <p>Confirms user registration as an admin without using a confirmation code. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_611294 = newJObject()
  if body != nil:
    body_611294 = body
  result = call_611293.call(nil, nil, nil, nil, body_611294)

var adminConfirmSignUp* = Call_AdminConfirmSignUp_611280(
    name: "adminConfirmSignUp", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminConfirmSignUp",
    validator: validate_AdminConfirmSignUp_611281, base: "/",
    url: url_AdminConfirmSignUp_611282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminCreateUser_611295 = ref object of OpenApiRestCall_610658
proc url_AdminCreateUser_611297(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminCreateUser_611296(path: JsonNode; query: JsonNode;
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
  var valid_611298 = header.getOrDefault("X-Amz-Target")
  valid_611298 = validateParameter(valid_611298, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminCreateUser"))
  if valid_611298 != nil:
    section.add "X-Amz-Target", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-Signature")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-Signature", valid_611299
  var valid_611300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-Content-Sha256", valid_611300
  var valid_611301 = header.getOrDefault("X-Amz-Date")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-Date", valid_611301
  var valid_611302 = header.getOrDefault("X-Amz-Credential")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-Credential", valid_611302
  var valid_611303 = header.getOrDefault("X-Amz-Security-Token")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-Security-Token", valid_611303
  var valid_611304 = header.getOrDefault("X-Amz-Algorithm")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-Algorithm", valid_611304
  var valid_611305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-SignedHeaders", valid_611305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611307: Call_AdminCreateUser_611295; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new user in the specified user pool.</p> <p>If <code>MessageAction</code> is not set, the default is to send a welcome message via email or phone (SMS).</p> <note> <p>This message is based on a template that you configured in your call to or . This template includes your custom sign-up instructions and placeholders for user name and temporary password.</p> </note> <p>Alternatively, you can call AdminCreateUser with “SUPPRESS” for the <code>MessageAction</code> parameter, and Amazon Cognito will not send any email. </p> <p>In either case, the user will be in the <code>FORCE_CHANGE_PASSWORD</code> state until they sign in and change their password.</p> <p>AdminCreateUser requires developer credentials.</p>
  ## 
  let valid = call_611307.validator(path, query, header, formData, body)
  let scheme = call_611307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611307.url(scheme.get, call_611307.host, call_611307.base,
                         call_611307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611307, url, valid)

proc call*(call_611308: Call_AdminCreateUser_611295; body: JsonNode): Recallable =
  ## adminCreateUser
  ## <p>Creates a new user in the specified user pool.</p> <p>If <code>MessageAction</code> is not set, the default is to send a welcome message via email or phone (SMS).</p> <note> <p>This message is based on a template that you configured in your call to or . This template includes your custom sign-up instructions and placeholders for user name and temporary password.</p> </note> <p>Alternatively, you can call AdminCreateUser with “SUPPRESS” for the <code>MessageAction</code> parameter, and Amazon Cognito will not send any email. </p> <p>In either case, the user will be in the <code>FORCE_CHANGE_PASSWORD</code> state until they sign in and change their password.</p> <p>AdminCreateUser requires developer credentials.</p>
  ##   body: JObject (required)
  var body_611309 = newJObject()
  if body != nil:
    body_611309 = body
  result = call_611308.call(nil, nil, nil, nil, body_611309)

var adminCreateUser* = Call_AdminCreateUser_611295(name: "adminCreateUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminCreateUser",
    validator: validate_AdminCreateUser_611296, base: "/", url: url_AdminCreateUser_611297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDeleteUser_611310 = ref object of OpenApiRestCall_610658
proc url_AdminDeleteUser_611312(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminDeleteUser_611311(path: JsonNode; query: JsonNode;
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
  var valid_611313 = header.getOrDefault("X-Amz-Target")
  valid_611313 = validateParameter(valid_611313, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDeleteUser"))
  if valid_611313 != nil:
    section.add "X-Amz-Target", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-Signature")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-Signature", valid_611314
  var valid_611315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Content-Sha256", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-Date")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Date", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-Credential")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Credential", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Security-Token")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Security-Token", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-Algorithm")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Algorithm", valid_611319
  var valid_611320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-SignedHeaders", valid_611320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611322: Call_AdminDeleteUser_611310; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a user as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_611322.validator(path, query, header, formData, body)
  let scheme = call_611322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611322.url(scheme.get, call_611322.host, call_611322.base,
                         call_611322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611322, url, valid)

proc call*(call_611323: Call_AdminDeleteUser_611310; body: JsonNode): Recallable =
  ## adminDeleteUser
  ## <p>Deletes a user as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_611324 = newJObject()
  if body != nil:
    body_611324 = body
  result = call_611323.call(nil, nil, nil, nil, body_611324)

var adminDeleteUser* = Call_AdminDeleteUser_611310(name: "adminDeleteUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDeleteUser",
    validator: validate_AdminDeleteUser_611311, base: "/", url: url_AdminDeleteUser_611312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDeleteUserAttributes_611325 = ref object of OpenApiRestCall_610658
proc url_AdminDeleteUserAttributes_611327(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminDeleteUserAttributes_611326(path: JsonNode; query: JsonNode;
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
  var valid_611328 = header.getOrDefault("X-Amz-Target")
  valid_611328 = validateParameter(valid_611328, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDeleteUserAttributes"))
  if valid_611328 != nil:
    section.add "X-Amz-Target", valid_611328
  var valid_611329 = header.getOrDefault("X-Amz-Signature")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "X-Amz-Signature", valid_611329
  var valid_611330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "X-Amz-Content-Sha256", valid_611330
  var valid_611331 = header.getOrDefault("X-Amz-Date")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-Date", valid_611331
  var valid_611332 = header.getOrDefault("X-Amz-Credential")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-Credential", valid_611332
  var valid_611333 = header.getOrDefault("X-Amz-Security-Token")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "X-Amz-Security-Token", valid_611333
  var valid_611334 = header.getOrDefault("X-Amz-Algorithm")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "X-Amz-Algorithm", valid_611334
  var valid_611335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "X-Amz-SignedHeaders", valid_611335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611337: Call_AdminDeleteUserAttributes_611325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the user attributes in a user pool as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_611337.validator(path, query, header, formData, body)
  let scheme = call_611337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611337.url(scheme.get, call_611337.host, call_611337.base,
                         call_611337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611337, url, valid)

proc call*(call_611338: Call_AdminDeleteUserAttributes_611325; body: JsonNode): Recallable =
  ## adminDeleteUserAttributes
  ## <p>Deletes the user attributes in a user pool as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_611339 = newJObject()
  if body != nil:
    body_611339 = body
  result = call_611338.call(nil, nil, nil, nil, body_611339)

var adminDeleteUserAttributes* = Call_AdminDeleteUserAttributes_611325(
    name: "adminDeleteUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDeleteUserAttributes",
    validator: validate_AdminDeleteUserAttributes_611326, base: "/",
    url: url_AdminDeleteUserAttributes_611327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDisableProviderForUser_611340 = ref object of OpenApiRestCall_610658
proc url_AdminDisableProviderForUser_611342(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminDisableProviderForUser_611341(path: JsonNode; query: JsonNode;
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
  var valid_611343 = header.getOrDefault("X-Amz-Target")
  valid_611343 = validateParameter(valid_611343, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDisableProviderForUser"))
  if valid_611343 != nil:
    section.add "X-Amz-Target", valid_611343
  var valid_611344 = header.getOrDefault("X-Amz-Signature")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "X-Amz-Signature", valid_611344
  var valid_611345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "X-Amz-Content-Sha256", valid_611345
  var valid_611346 = header.getOrDefault("X-Amz-Date")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "X-Amz-Date", valid_611346
  var valid_611347 = header.getOrDefault("X-Amz-Credential")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "X-Amz-Credential", valid_611347
  var valid_611348 = header.getOrDefault("X-Amz-Security-Token")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-Security-Token", valid_611348
  var valid_611349 = header.getOrDefault("X-Amz-Algorithm")
  valid_611349 = validateParameter(valid_611349, JString, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "X-Amz-Algorithm", valid_611349
  var valid_611350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-SignedHeaders", valid_611350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611352: Call_AdminDisableProviderForUser_611340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables the user from signing in with the specified external (SAML or social) identity provider. If the user to disable is a Cognito User Pools native username + password user, they are not permitted to use their password to sign-in. If the user to disable is a linked external IdP user, any link between that user and an existing user is removed. The next time the external user (no longer attached to the previously linked <code>DestinationUser</code>) signs in, they must create a new user account. See .</p> <p>This action is enabled only for admin access and requires developer credentials.</p> <p>The <code>ProviderName</code> must match the value specified when creating an IdP for the pool. </p> <p>To disable a native username + password user, the <code>ProviderName</code> value must be <code>Cognito</code> and the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code>, with the <code>ProviderAttributeValue</code> being the name that is used in the user pool for the user.</p> <p>The <code>ProviderAttributeName</code> must always be <code>Cognito_Subject</code> for social identity providers. The <code>ProviderAttributeValue</code> must always be the exact subject that was used when the user was originally linked as a source user.</p> <p>For de-linking a SAML identity, there are two scenarios. If the linked identity has not yet been used to sign-in, the <code>ProviderAttributeName</code> and <code>ProviderAttributeValue</code> must be the same values that were used for the <code>SourceUser</code> when the identities were originally linked in the call. (If the linking was done with <code>ProviderAttributeName</code> set to <code>Cognito_Subject</code>, the same applies here). However, if the user has already signed in, the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code> and <code>ProviderAttributeValue</code> must be the subject of the SAML assertion.</p>
  ## 
  let valid = call_611352.validator(path, query, header, formData, body)
  let scheme = call_611352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611352.url(scheme.get, call_611352.host, call_611352.base,
                         call_611352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611352, url, valid)

proc call*(call_611353: Call_AdminDisableProviderForUser_611340; body: JsonNode): Recallable =
  ## adminDisableProviderForUser
  ## <p>Disables the user from signing in with the specified external (SAML or social) identity provider. If the user to disable is a Cognito User Pools native username + password user, they are not permitted to use their password to sign-in. If the user to disable is a linked external IdP user, any link between that user and an existing user is removed. The next time the external user (no longer attached to the previously linked <code>DestinationUser</code>) signs in, they must create a new user account. See .</p> <p>This action is enabled only for admin access and requires developer credentials.</p> <p>The <code>ProviderName</code> must match the value specified when creating an IdP for the pool. </p> <p>To disable a native username + password user, the <code>ProviderName</code> value must be <code>Cognito</code> and the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code>, with the <code>ProviderAttributeValue</code> being the name that is used in the user pool for the user.</p> <p>The <code>ProviderAttributeName</code> must always be <code>Cognito_Subject</code> for social identity providers. The <code>ProviderAttributeValue</code> must always be the exact subject that was used when the user was originally linked as a source user.</p> <p>For de-linking a SAML identity, there are two scenarios. If the linked identity has not yet been used to sign-in, the <code>ProviderAttributeName</code> and <code>ProviderAttributeValue</code> must be the same values that were used for the <code>SourceUser</code> when the identities were originally linked in the call. (If the linking was done with <code>ProviderAttributeName</code> set to <code>Cognito_Subject</code>, the same applies here). However, if the user has already signed in, the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code> and <code>ProviderAttributeValue</code> must be the subject of the SAML assertion.</p>
  ##   body: JObject (required)
  var body_611354 = newJObject()
  if body != nil:
    body_611354 = body
  result = call_611353.call(nil, nil, nil, nil, body_611354)

var adminDisableProviderForUser* = Call_AdminDisableProviderForUser_611340(
    name: "adminDisableProviderForUser", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDisableProviderForUser",
    validator: validate_AdminDisableProviderForUser_611341, base: "/",
    url: url_AdminDisableProviderForUser_611342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDisableUser_611355 = ref object of OpenApiRestCall_610658
proc url_AdminDisableUser_611357(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminDisableUser_611356(path: JsonNode; query: JsonNode;
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
  var valid_611358 = header.getOrDefault("X-Amz-Target")
  valid_611358 = validateParameter(valid_611358, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDisableUser"))
  if valid_611358 != nil:
    section.add "X-Amz-Target", valid_611358
  var valid_611359 = header.getOrDefault("X-Amz-Signature")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "X-Amz-Signature", valid_611359
  var valid_611360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "X-Amz-Content-Sha256", valid_611360
  var valid_611361 = header.getOrDefault("X-Amz-Date")
  valid_611361 = validateParameter(valid_611361, JString, required = false,
                                 default = nil)
  if valid_611361 != nil:
    section.add "X-Amz-Date", valid_611361
  var valid_611362 = header.getOrDefault("X-Amz-Credential")
  valid_611362 = validateParameter(valid_611362, JString, required = false,
                                 default = nil)
  if valid_611362 != nil:
    section.add "X-Amz-Credential", valid_611362
  var valid_611363 = header.getOrDefault("X-Amz-Security-Token")
  valid_611363 = validateParameter(valid_611363, JString, required = false,
                                 default = nil)
  if valid_611363 != nil:
    section.add "X-Amz-Security-Token", valid_611363
  var valid_611364 = header.getOrDefault("X-Amz-Algorithm")
  valid_611364 = validateParameter(valid_611364, JString, required = false,
                                 default = nil)
  if valid_611364 != nil:
    section.add "X-Amz-Algorithm", valid_611364
  var valid_611365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "X-Amz-SignedHeaders", valid_611365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611367: Call_AdminDisableUser_611355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables the specified user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_611367.validator(path, query, header, formData, body)
  let scheme = call_611367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611367.url(scheme.get, call_611367.host, call_611367.base,
                         call_611367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611367, url, valid)

proc call*(call_611368: Call_AdminDisableUser_611355; body: JsonNode): Recallable =
  ## adminDisableUser
  ## <p>Disables the specified user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_611369 = newJObject()
  if body != nil:
    body_611369 = body
  result = call_611368.call(nil, nil, nil, nil, body_611369)

var adminDisableUser* = Call_AdminDisableUser_611355(name: "adminDisableUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDisableUser",
    validator: validate_AdminDisableUser_611356, base: "/",
    url: url_AdminDisableUser_611357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminEnableUser_611370 = ref object of OpenApiRestCall_610658
proc url_AdminEnableUser_611372(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminEnableUser_611371(path: JsonNode; query: JsonNode;
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
  var valid_611373 = header.getOrDefault("X-Amz-Target")
  valid_611373 = validateParameter(valid_611373, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminEnableUser"))
  if valid_611373 != nil:
    section.add "X-Amz-Target", valid_611373
  var valid_611374 = header.getOrDefault("X-Amz-Signature")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-Signature", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Content-Sha256", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-Date")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-Date", valid_611376
  var valid_611377 = header.getOrDefault("X-Amz-Credential")
  valid_611377 = validateParameter(valid_611377, JString, required = false,
                                 default = nil)
  if valid_611377 != nil:
    section.add "X-Amz-Credential", valid_611377
  var valid_611378 = header.getOrDefault("X-Amz-Security-Token")
  valid_611378 = validateParameter(valid_611378, JString, required = false,
                                 default = nil)
  if valid_611378 != nil:
    section.add "X-Amz-Security-Token", valid_611378
  var valid_611379 = header.getOrDefault("X-Amz-Algorithm")
  valid_611379 = validateParameter(valid_611379, JString, required = false,
                                 default = nil)
  if valid_611379 != nil:
    section.add "X-Amz-Algorithm", valid_611379
  var valid_611380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "X-Amz-SignedHeaders", valid_611380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611382: Call_AdminEnableUser_611370; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the specified user as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_611382.validator(path, query, header, formData, body)
  let scheme = call_611382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611382.url(scheme.get, call_611382.host, call_611382.base,
                         call_611382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611382, url, valid)

proc call*(call_611383: Call_AdminEnableUser_611370; body: JsonNode): Recallable =
  ## adminEnableUser
  ## <p>Enables the specified user as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_611384 = newJObject()
  if body != nil:
    body_611384 = body
  result = call_611383.call(nil, nil, nil, nil, body_611384)

var adminEnableUser* = Call_AdminEnableUser_611370(name: "adminEnableUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminEnableUser",
    validator: validate_AdminEnableUser_611371, base: "/", url: url_AdminEnableUser_611372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminForgetDevice_611385 = ref object of OpenApiRestCall_610658
proc url_AdminForgetDevice_611387(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminForgetDevice_611386(path: JsonNode; query: JsonNode;
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
  var valid_611388 = header.getOrDefault("X-Amz-Target")
  valid_611388 = validateParameter(valid_611388, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminForgetDevice"))
  if valid_611388 != nil:
    section.add "X-Amz-Target", valid_611388
  var valid_611389 = header.getOrDefault("X-Amz-Signature")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "X-Amz-Signature", valid_611389
  var valid_611390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "X-Amz-Content-Sha256", valid_611390
  var valid_611391 = header.getOrDefault("X-Amz-Date")
  valid_611391 = validateParameter(valid_611391, JString, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "X-Amz-Date", valid_611391
  var valid_611392 = header.getOrDefault("X-Amz-Credential")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "X-Amz-Credential", valid_611392
  var valid_611393 = header.getOrDefault("X-Amz-Security-Token")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "X-Amz-Security-Token", valid_611393
  var valid_611394 = header.getOrDefault("X-Amz-Algorithm")
  valid_611394 = validateParameter(valid_611394, JString, required = false,
                                 default = nil)
  if valid_611394 != nil:
    section.add "X-Amz-Algorithm", valid_611394
  var valid_611395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611395 = validateParameter(valid_611395, JString, required = false,
                                 default = nil)
  if valid_611395 != nil:
    section.add "X-Amz-SignedHeaders", valid_611395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611397: Call_AdminForgetDevice_611385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Forgets the device, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_611397.validator(path, query, header, formData, body)
  let scheme = call_611397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611397.url(scheme.get, call_611397.host, call_611397.base,
                         call_611397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611397, url, valid)

proc call*(call_611398: Call_AdminForgetDevice_611385; body: JsonNode): Recallable =
  ## adminForgetDevice
  ## <p>Forgets the device, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_611399 = newJObject()
  if body != nil:
    body_611399 = body
  result = call_611398.call(nil, nil, nil, nil, body_611399)

var adminForgetDevice* = Call_AdminForgetDevice_611385(name: "adminForgetDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminForgetDevice",
    validator: validate_AdminForgetDevice_611386, base: "/",
    url: url_AdminForgetDevice_611387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminGetDevice_611400 = ref object of OpenApiRestCall_610658
proc url_AdminGetDevice_611402(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminGetDevice_611401(path: JsonNode; query: JsonNode;
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
  var valid_611403 = header.getOrDefault("X-Amz-Target")
  valid_611403 = validateParameter(valid_611403, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminGetDevice"))
  if valid_611403 != nil:
    section.add "X-Amz-Target", valid_611403
  var valid_611404 = header.getOrDefault("X-Amz-Signature")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "X-Amz-Signature", valid_611404
  var valid_611405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611405 = validateParameter(valid_611405, JString, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "X-Amz-Content-Sha256", valid_611405
  var valid_611406 = header.getOrDefault("X-Amz-Date")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "X-Amz-Date", valid_611406
  var valid_611407 = header.getOrDefault("X-Amz-Credential")
  valid_611407 = validateParameter(valid_611407, JString, required = false,
                                 default = nil)
  if valid_611407 != nil:
    section.add "X-Amz-Credential", valid_611407
  var valid_611408 = header.getOrDefault("X-Amz-Security-Token")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "X-Amz-Security-Token", valid_611408
  var valid_611409 = header.getOrDefault("X-Amz-Algorithm")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "X-Amz-Algorithm", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-SignedHeaders", valid_611410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611412: Call_AdminGetDevice_611400; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the device, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_611412.validator(path, query, header, formData, body)
  let scheme = call_611412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611412.url(scheme.get, call_611412.host, call_611412.base,
                         call_611412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611412, url, valid)

proc call*(call_611413: Call_AdminGetDevice_611400; body: JsonNode): Recallable =
  ## adminGetDevice
  ## <p>Gets the device, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_611414 = newJObject()
  if body != nil:
    body_611414 = body
  result = call_611413.call(nil, nil, nil, nil, body_611414)

var adminGetDevice* = Call_AdminGetDevice_611400(name: "adminGetDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminGetDevice",
    validator: validate_AdminGetDevice_611401, base: "/", url: url_AdminGetDevice_611402,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminGetUser_611415 = ref object of OpenApiRestCall_610658
proc url_AdminGetUser_611417(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminGetUser_611416(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611418 = header.getOrDefault("X-Amz-Target")
  valid_611418 = validateParameter(valid_611418, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminGetUser"))
  if valid_611418 != nil:
    section.add "X-Amz-Target", valid_611418
  var valid_611419 = header.getOrDefault("X-Amz-Signature")
  valid_611419 = validateParameter(valid_611419, JString, required = false,
                                 default = nil)
  if valid_611419 != nil:
    section.add "X-Amz-Signature", valid_611419
  var valid_611420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611420 = validateParameter(valid_611420, JString, required = false,
                                 default = nil)
  if valid_611420 != nil:
    section.add "X-Amz-Content-Sha256", valid_611420
  var valid_611421 = header.getOrDefault("X-Amz-Date")
  valid_611421 = validateParameter(valid_611421, JString, required = false,
                                 default = nil)
  if valid_611421 != nil:
    section.add "X-Amz-Date", valid_611421
  var valid_611422 = header.getOrDefault("X-Amz-Credential")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "X-Amz-Credential", valid_611422
  var valid_611423 = header.getOrDefault("X-Amz-Security-Token")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "X-Amz-Security-Token", valid_611423
  var valid_611424 = header.getOrDefault("X-Amz-Algorithm")
  valid_611424 = validateParameter(valid_611424, JString, required = false,
                                 default = nil)
  if valid_611424 != nil:
    section.add "X-Amz-Algorithm", valid_611424
  var valid_611425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "X-Amz-SignedHeaders", valid_611425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611427: Call_AdminGetUser_611415; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the specified user by user name in a user pool as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_611427.validator(path, query, header, formData, body)
  let scheme = call_611427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611427.url(scheme.get, call_611427.host, call_611427.base,
                         call_611427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611427, url, valid)

proc call*(call_611428: Call_AdminGetUser_611415; body: JsonNode): Recallable =
  ## adminGetUser
  ## <p>Gets the specified user by user name in a user pool as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_611429 = newJObject()
  if body != nil:
    body_611429 = body
  result = call_611428.call(nil, nil, nil, nil, body_611429)

var adminGetUser* = Call_AdminGetUser_611415(name: "adminGetUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminGetUser",
    validator: validate_AdminGetUser_611416, base: "/", url: url_AdminGetUser_611417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminInitiateAuth_611430 = ref object of OpenApiRestCall_610658
proc url_AdminInitiateAuth_611432(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminInitiateAuth_611431(path: JsonNode; query: JsonNode;
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
  var valid_611433 = header.getOrDefault("X-Amz-Target")
  valid_611433 = validateParameter(valid_611433, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminInitiateAuth"))
  if valid_611433 != nil:
    section.add "X-Amz-Target", valid_611433
  var valid_611434 = header.getOrDefault("X-Amz-Signature")
  valid_611434 = validateParameter(valid_611434, JString, required = false,
                                 default = nil)
  if valid_611434 != nil:
    section.add "X-Amz-Signature", valid_611434
  var valid_611435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "X-Amz-Content-Sha256", valid_611435
  var valid_611436 = header.getOrDefault("X-Amz-Date")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Date", valid_611436
  var valid_611437 = header.getOrDefault("X-Amz-Credential")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-Credential", valid_611437
  var valid_611438 = header.getOrDefault("X-Amz-Security-Token")
  valid_611438 = validateParameter(valid_611438, JString, required = false,
                                 default = nil)
  if valid_611438 != nil:
    section.add "X-Amz-Security-Token", valid_611438
  var valid_611439 = header.getOrDefault("X-Amz-Algorithm")
  valid_611439 = validateParameter(valid_611439, JString, required = false,
                                 default = nil)
  if valid_611439 != nil:
    section.add "X-Amz-Algorithm", valid_611439
  var valid_611440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "X-Amz-SignedHeaders", valid_611440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611442: Call_AdminInitiateAuth_611430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates the authentication flow, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_611442.validator(path, query, header, formData, body)
  let scheme = call_611442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611442.url(scheme.get, call_611442.host, call_611442.base,
                         call_611442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611442, url, valid)

proc call*(call_611443: Call_AdminInitiateAuth_611430; body: JsonNode): Recallable =
  ## adminInitiateAuth
  ## <p>Initiates the authentication flow, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_611444 = newJObject()
  if body != nil:
    body_611444 = body
  result = call_611443.call(nil, nil, nil, nil, body_611444)

var adminInitiateAuth* = Call_AdminInitiateAuth_611430(name: "adminInitiateAuth",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminInitiateAuth",
    validator: validate_AdminInitiateAuth_611431, base: "/",
    url: url_AdminInitiateAuth_611432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminLinkProviderForUser_611445 = ref object of OpenApiRestCall_610658
proc url_AdminLinkProviderForUser_611447(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminLinkProviderForUser_611446(path: JsonNode; query: JsonNode;
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
  var valid_611448 = header.getOrDefault("X-Amz-Target")
  valid_611448 = validateParameter(valid_611448, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminLinkProviderForUser"))
  if valid_611448 != nil:
    section.add "X-Amz-Target", valid_611448
  var valid_611449 = header.getOrDefault("X-Amz-Signature")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "X-Amz-Signature", valid_611449
  var valid_611450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "X-Amz-Content-Sha256", valid_611450
  var valid_611451 = header.getOrDefault("X-Amz-Date")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "X-Amz-Date", valid_611451
  var valid_611452 = header.getOrDefault("X-Amz-Credential")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "X-Amz-Credential", valid_611452
  var valid_611453 = header.getOrDefault("X-Amz-Security-Token")
  valid_611453 = validateParameter(valid_611453, JString, required = false,
                                 default = nil)
  if valid_611453 != nil:
    section.add "X-Amz-Security-Token", valid_611453
  var valid_611454 = header.getOrDefault("X-Amz-Algorithm")
  valid_611454 = validateParameter(valid_611454, JString, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "X-Amz-Algorithm", valid_611454
  var valid_611455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611455 = validateParameter(valid_611455, JString, required = false,
                                 default = nil)
  if valid_611455 != nil:
    section.add "X-Amz-SignedHeaders", valid_611455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611457: Call_AdminLinkProviderForUser_611445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Links an existing user account in a user pool (<code>DestinationUser</code>) to an identity from an external identity provider (<code>SourceUser</code>) based on a specified attribute name and value from the external identity provider. This allows you to create a link from the existing user account to an external federated user identity that has not yet been used to sign in, so that the federated user identity can be used to sign in as the existing user account. </p> <p> For example, if there is an existing user with a username and password, this API links that user to a federated user identity, so that when the federated user identity is used, the user signs in as the existing user account. </p> <important> <p>Because this API allows a user with an external federated identity to sign in as an existing user in the user pool, it is critical that it only be used with external identity providers and provider attributes that have been trusted by the application owner.</p> </important> <p>See also .</p> <p>This action is enabled only for admin access and requires developer credentials.</p>
  ## 
  let valid = call_611457.validator(path, query, header, formData, body)
  let scheme = call_611457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611457.url(scheme.get, call_611457.host, call_611457.base,
                         call_611457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611457, url, valid)

proc call*(call_611458: Call_AdminLinkProviderForUser_611445; body: JsonNode): Recallable =
  ## adminLinkProviderForUser
  ## <p>Links an existing user account in a user pool (<code>DestinationUser</code>) to an identity from an external identity provider (<code>SourceUser</code>) based on a specified attribute name and value from the external identity provider. This allows you to create a link from the existing user account to an external federated user identity that has not yet been used to sign in, so that the federated user identity can be used to sign in as the existing user account. </p> <p> For example, if there is an existing user with a username and password, this API links that user to a federated user identity, so that when the federated user identity is used, the user signs in as the existing user account. </p> <important> <p>Because this API allows a user with an external federated identity to sign in as an existing user in the user pool, it is critical that it only be used with external identity providers and provider attributes that have been trusted by the application owner.</p> </important> <p>See also .</p> <p>This action is enabled only for admin access and requires developer credentials.</p>
  ##   body: JObject (required)
  var body_611459 = newJObject()
  if body != nil:
    body_611459 = body
  result = call_611458.call(nil, nil, nil, nil, body_611459)

var adminLinkProviderForUser* = Call_AdminLinkProviderForUser_611445(
    name: "adminLinkProviderForUser", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminLinkProviderForUser",
    validator: validate_AdminLinkProviderForUser_611446, base: "/",
    url: url_AdminLinkProviderForUser_611447, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminListDevices_611460 = ref object of OpenApiRestCall_610658
proc url_AdminListDevices_611462(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminListDevices_611461(path: JsonNode; query: JsonNode;
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
  var valid_611463 = header.getOrDefault("X-Amz-Target")
  valid_611463 = validateParameter(valid_611463, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminListDevices"))
  if valid_611463 != nil:
    section.add "X-Amz-Target", valid_611463
  var valid_611464 = header.getOrDefault("X-Amz-Signature")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "X-Amz-Signature", valid_611464
  var valid_611465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = nil)
  if valid_611465 != nil:
    section.add "X-Amz-Content-Sha256", valid_611465
  var valid_611466 = header.getOrDefault("X-Amz-Date")
  valid_611466 = validateParameter(valid_611466, JString, required = false,
                                 default = nil)
  if valid_611466 != nil:
    section.add "X-Amz-Date", valid_611466
  var valid_611467 = header.getOrDefault("X-Amz-Credential")
  valid_611467 = validateParameter(valid_611467, JString, required = false,
                                 default = nil)
  if valid_611467 != nil:
    section.add "X-Amz-Credential", valid_611467
  var valid_611468 = header.getOrDefault("X-Amz-Security-Token")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "X-Amz-Security-Token", valid_611468
  var valid_611469 = header.getOrDefault("X-Amz-Algorithm")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "X-Amz-Algorithm", valid_611469
  var valid_611470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "X-Amz-SignedHeaders", valid_611470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611472: Call_AdminListDevices_611460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists devices, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_611472.validator(path, query, header, formData, body)
  let scheme = call_611472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611472.url(scheme.get, call_611472.host, call_611472.base,
                         call_611472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611472, url, valid)

proc call*(call_611473: Call_AdminListDevices_611460; body: JsonNode): Recallable =
  ## adminListDevices
  ## <p>Lists devices, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_611474 = newJObject()
  if body != nil:
    body_611474 = body
  result = call_611473.call(nil, nil, nil, nil, body_611474)

var adminListDevices* = Call_AdminListDevices_611460(name: "adminListDevices",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminListDevices",
    validator: validate_AdminListDevices_611461, base: "/",
    url: url_AdminListDevices_611462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminListGroupsForUser_611475 = ref object of OpenApiRestCall_610658
proc url_AdminListGroupsForUser_611477(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminListGroupsForUser_611476(path: JsonNode; query: JsonNode;
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
  var valid_611478 = query.getOrDefault("NextToken")
  valid_611478 = validateParameter(valid_611478, JString, required = false,
                                 default = nil)
  if valid_611478 != nil:
    section.add "NextToken", valid_611478
  var valid_611479 = query.getOrDefault("Limit")
  valid_611479 = validateParameter(valid_611479, JString, required = false,
                                 default = nil)
  if valid_611479 != nil:
    section.add "Limit", valid_611479
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
  var valid_611480 = header.getOrDefault("X-Amz-Target")
  valid_611480 = validateParameter(valid_611480, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminListGroupsForUser"))
  if valid_611480 != nil:
    section.add "X-Amz-Target", valid_611480
  var valid_611481 = header.getOrDefault("X-Amz-Signature")
  valid_611481 = validateParameter(valid_611481, JString, required = false,
                                 default = nil)
  if valid_611481 != nil:
    section.add "X-Amz-Signature", valid_611481
  var valid_611482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611482 = validateParameter(valid_611482, JString, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "X-Amz-Content-Sha256", valid_611482
  var valid_611483 = header.getOrDefault("X-Amz-Date")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "X-Amz-Date", valid_611483
  var valid_611484 = header.getOrDefault("X-Amz-Credential")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "X-Amz-Credential", valid_611484
  var valid_611485 = header.getOrDefault("X-Amz-Security-Token")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "X-Amz-Security-Token", valid_611485
  var valid_611486 = header.getOrDefault("X-Amz-Algorithm")
  valid_611486 = validateParameter(valid_611486, JString, required = false,
                                 default = nil)
  if valid_611486 != nil:
    section.add "X-Amz-Algorithm", valid_611486
  var valid_611487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611487 = validateParameter(valid_611487, JString, required = false,
                                 default = nil)
  if valid_611487 != nil:
    section.add "X-Amz-SignedHeaders", valid_611487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611489: Call_AdminListGroupsForUser_611475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the groups that the user belongs to.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_611489.validator(path, query, header, formData, body)
  let scheme = call_611489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611489.url(scheme.get, call_611489.host, call_611489.base,
                         call_611489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611489, url, valid)

proc call*(call_611490: Call_AdminListGroupsForUser_611475; body: JsonNode;
          NextToken: string = ""; Limit: string = ""): Recallable =
  ## adminListGroupsForUser
  ## <p>Lists the groups that the user belongs to.</p> <p>Calling this action requires developer credentials.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_611491 = newJObject()
  var body_611492 = newJObject()
  add(query_611491, "NextToken", newJString(NextToken))
  add(query_611491, "Limit", newJString(Limit))
  if body != nil:
    body_611492 = body
  result = call_611490.call(nil, query_611491, nil, nil, body_611492)

var adminListGroupsForUser* = Call_AdminListGroupsForUser_611475(
    name: "adminListGroupsForUser", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminListGroupsForUser",
    validator: validate_AdminListGroupsForUser_611476, base: "/",
    url: url_AdminListGroupsForUser_611477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminListUserAuthEvents_611494 = ref object of OpenApiRestCall_610658
proc url_AdminListUserAuthEvents_611496(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminListUserAuthEvents_611495(path: JsonNode; query: JsonNode;
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
  var valid_611497 = query.getOrDefault("MaxResults")
  valid_611497 = validateParameter(valid_611497, JString, required = false,
                                 default = nil)
  if valid_611497 != nil:
    section.add "MaxResults", valid_611497
  var valid_611498 = query.getOrDefault("NextToken")
  valid_611498 = validateParameter(valid_611498, JString, required = false,
                                 default = nil)
  if valid_611498 != nil:
    section.add "NextToken", valid_611498
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
  var valid_611499 = header.getOrDefault("X-Amz-Target")
  valid_611499 = validateParameter(valid_611499, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminListUserAuthEvents"))
  if valid_611499 != nil:
    section.add "X-Amz-Target", valid_611499
  var valid_611500 = header.getOrDefault("X-Amz-Signature")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "X-Amz-Signature", valid_611500
  var valid_611501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611501 = validateParameter(valid_611501, JString, required = false,
                                 default = nil)
  if valid_611501 != nil:
    section.add "X-Amz-Content-Sha256", valid_611501
  var valid_611502 = header.getOrDefault("X-Amz-Date")
  valid_611502 = validateParameter(valid_611502, JString, required = false,
                                 default = nil)
  if valid_611502 != nil:
    section.add "X-Amz-Date", valid_611502
  var valid_611503 = header.getOrDefault("X-Amz-Credential")
  valid_611503 = validateParameter(valid_611503, JString, required = false,
                                 default = nil)
  if valid_611503 != nil:
    section.add "X-Amz-Credential", valid_611503
  var valid_611504 = header.getOrDefault("X-Amz-Security-Token")
  valid_611504 = validateParameter(valid_611504, JString, required = false,
                                 default = nil)
  if valid_611504 != nil:
    section.add "X-Amz-Security-Token", valid_611504
  var valid_611505 = header.getOrDefault("X-Amz-Algorithm")
  valid_611505 = validateParameter(valid_611505, JString, required = false,
                                 default = nil)
  if valid_611505 != nil:
    section.add "X-Amz-Algorithm", valid_611505
  var valid_611506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611506 = validateParameter(valid_611506, JString, required = false,
                                 default = nil)
  if valid_611506 != nil:
    section.add "X-Amz-SignedHeaders", valid_611506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611508: Call_AdminListUserAuthEvents_611494; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists a history of user activity and any risks detected as part of Amazon Cognito advanced security.
  ## 
  let valid = call_611508.validator(path, query, header, formData, body)
  let scheme = call_611508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611508.url(scheme.get, call_611508.host, call_611508.base,
                         call_611508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611508, url, valid)

proc call*(call_611509: Call_AdminListUserAuthEvents_611494; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## adminListUserAuthEvents
  ## Lists a history of user activity and any risks detected as part of Amazon Cognito advanced security.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611510 = newJObject()
  var body_611511 = newJObject()
  add(query_611510, "MaxResults", newJString(MaxResults))
  add(query_611510, "NextToken", newJString(NextToken))
  if body != nil:
    body_611511 = body
  result = call_611509.call(nil, query_611510, nil, nil, body_611511)

var adminListUserAuthEvents* = Call_AdminListUserAuthEvents_611494(
    name: "adminListUserAuthEvents", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminListUserAuthEvents",
    validator: validate_AdminListUserAuthEvents_611495, base: "/",
    url: url_AdminListUserAuthEvents_611496, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminRemoveUserFromGroup_611512 = ref object of OpenApiRestCall_610658
proc url_AdminRemoveUserFromGroup_611514(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminRemoveUserFromGroup_611513(path: JsonNode; query: JsonNode;
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
  var valid_611515 = header.getOrDefault("X-Amz-Target")
  valid_611515 = validateParameter(valid_611515, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminRemoveUserFromGroup"))
  if valid_611515 != nil:
    section.add "X-Amz-Target", valid_611515
  var valid_611516 = header.getOrDefault("X-Amz-Signature")
  valid_611516 = validateParameter(valid_611516, JString, required = false,
                                 default = nil)
  if valid_611516 != nil:
    section.add "X-Amz-Signature", valid_611516
  var valid_611517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611517 = validateParameter(valid_611517, JString, required = false,
                                 default = nil)
  if valid_611517 != nil:
    section.add "X-Amz-Content-Sha256", valid_611517
  var valid_611518 = header.getOrDefault("X-Amz-Date")
  valid_611518 = validateParameter(valid_611518, JString, required = false,
                                 default = nil)
  if valid_611518 != nil:
    section.add "X-Amz-Date", valid_611518
  var valid_611519 = header.getOrDefault("X-Amz-Credential")
  valid_611519 = validateParameter(valid_611519, JString, required = false,
                                 default = nil)
  if valid_611519 != nil:
    section.add "X-Amz-Credential", valid_611519
  var valid_611520 = header.getOrDefault("X-Amz-Security-Token")
  valid_611520 = validateParameter(valid_611520, JString, required = false,
                                 default = nil)
  if valid_611520 != nil:
    section.add "X-Amz-Security-Token", valid_611520
  var valid_611521 = header.getOrDefault("X-Amz-Algorithm")
  valid_611521 = validateParameter(valid_611521, JString, required = false,
                                 default = nil)
  if valid_611521 != nil:
    section.add "X-Amz-Algorithm", valid_611521
  var valid_611522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611522 = validateParameter(valid_611522, JString, required = false,
                                 default = nil)
  if valid_611522 != nil:
    section.add "X-Amz-SignedHeaders", valid_611522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611524: Call_AdminRemoveUserFromGroup_611512; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified user from the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_611524.validator(path, query, header, formData, body)
  let scheme = call_611524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611524.url(scheme.get, call_611524.host, call_611524.base,
                         call_611524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611524, url, valid)

proc call*(call_611525: Call_AdminRemoveUserFromGroup_611512; body: JsonNode): Recallable =
  ## adminRemoveUserFromGroup
  ## <p>Removes the specified user from the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_611526 = newJObject()
  if body != nil:
    body_611526 = body
  result = call_611525.call(nil, nil, nil, nil, body_611526)

var adminRemoveUserFromGroup* = Call_AdminRemoveUserFromGroup_611512(
    name: "adminRemoveUserFromGroup", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminRemoveUserFromGroup",
    validator: validate_AdminRemoveUserFromGroup_611513, base: "/",
    url: url_AdminRemoveUserFromGroup_611514, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminResetUserPassword_611527 = ref object of OpenApiRestCall_610658
proc url_AdminResetUserPassword_611529(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminResetUserPassword_611528(path: JsonNode; query: JsonNode;
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
  var valid_611530 = header.getOrDefault("X-Amz-Target")
  valid_611530 = validateParameter(valid_611530, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminResetUserPassword"))
  if valid_611530 != nil:
    section.add "X-Amz-Target", valid_611530
  var valid_611531 = header.getOrDefault("X-Amz-Signature")
  valid_611531 = validateParameter(valid_611531, JString, required = false,
                                 default = nil)
  if valid_611531 != nil:
    section.add "X-Amz-Signature", valid_611531
  var valid_611532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611532 = validateParameter(valid_611532, JString, required = false,
                                 default = nil)
  if valid_611532 != nil:
    section.add "X-Amz-Content-Sha256", valid_611532
  var valid_611533 = header.getOrDefault("X-Amz-Date")
  valid_611533 = validateParameter(valid_611533, JString, required = false,
                                 default = nil)
  if valid_611533 != nil:
    section.add "X-Amz-Date", valid_611533
  var valid_611534 = header.getOrDefault("X-Amz-Credential")
  valid_611534 = validateParameter(valid_611534, JString, required = false,
                                 default = nil)
  if valid_611534 != nil:
    section.add "X-Amz-Credential", valid_611534
  var valid_611535 = header.getOrDefault("X-Amz-Security-Token")
  valid_611535 = validateParameter(valid_611535, JString, required = false,
                                 default = nil)
  if valid_611535 != nil:
    section.add "X-Amz-Security-Token", valid_611535
  var valid_611536 = header.getOrDefault("X-Amz-Algorithm")
  valid_611536 = validateParameter(valid_611536, JString, required = false,
                                 default = nil)
  if valid_611536 != nil:
    section.add "X-Amz-Algorithm", valid_611536
  var valid_611537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611537 = validateParameter(valid_611537, JString, required = false,
                                 default = nil)
  if valid_611537 != nil:
    section.add "X-Amz-SignedHeaders", valid_611537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611539: Call_AdminResetUserPassword_611527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Resets the specified user's password in a user pool as an administrator. Works on any user.</p> <p>When a developer calls this API, the current password is invalidated, so it must be changed. If a user tries to sign in after the API is called, the app will get a PasswordResetRequiredException exception back and should direct the user down the flow to reset the password, which is the same as the forgot password flow. In addition, if the user pool has phone verification selected and a verified phone number exists for the user, or if email verification is selected and a verified email exists for the user, calling this API will also result in sending a message to the end user with the code to change their password.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_611539.validator(path, query, header, formData, body)
  let scheme = call_611539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611539.url(scheme.get, call_611539.host, call_611539.base,
                         call_611539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611539, url, valid)

proc call*(call_611540: Call_AdminResetUserPassword_611527; body: JsonNode): Recallable =
  ## adminResetUserPassword
  ## <p>Resets the specified user's password in a user pool as an administrator. Works on any user.</p> <p>When a developer calls this API, the current password is invalidated, so it must be changed. If a user tries to sign in after the API is called, the app will get a PasswordResetRequiredException exception back and should direct the user down the flow to reset the password, which is the same as the forgot password flow. In addition, if the user pool has phone verification selected and a verified phone number exists for the user, or if email verification is selected and a verified email exists for the user, calling this API will also result in sending a message to the end user with the code to change their password.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_611541 = newJObject()
  if body != nil:
    body_611541 = body
  result = call_611540.call(nil, nil, nil, nil, body_611541)

var adminResetUserPassword* = Call_AdminResetUserPassword_611527(
    name: "adminResetUserPassword", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminResetUserPassword",
    validator: validate_AdminResetUserPassword_611528, base: "/",
    url: url_AdminResetUserPassword_611529, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminRespondToAuthChallenge_611542 = ref object of OpenApiRestCall_610658
proc url_AdminRespondToAuthChallenge_611544(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminRespondToAuthChallenge_611543(path: JsonNode; query: JsonNode;
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
  var valid_611545 = header.getOrDefault("X-Amz-Target")
  valid_611545 = validateParameter(valid_611545, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminRespondToAuthChallenge"))
  if valid_611545 != nil:
    section.add "X-Amz-Target", valid_611545
  var valid_611546 = header.getOrDefault("X-Amz-Signature")
  valid_611546 = validateParameter(valid_611546, JString, required = false,
                                 default = nil)
  if valid_611546 != nil:
    section.add "X-Amz-Signature", valid_611546
  var valid_611547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611547 = validateParameter(valid_611547, JString, required = false,
                                 default = nil)
  if valid_611547 != nil:
    section.add "X-Amz-Content-Sha256", valid_611547
  var valid_611548 = header.getOrDefault("X-Amz-Date")
  valid_611548 = validateParameter(valid_611548, JString, required = false,
                                 default = nil)
  if valid_611548 != nil:
    section.add "X-Amz-Date", valid_611548
  var valid_611549 = header.getOrDefault("X-Amz-Credential")
  valid_611549 = validateParameter(valid_611549, JString, required = false,
                                 default = nil)
  if valid_611549 != nil:
    section.add "X-Amz-Credential", valid_611549
  var valid_611550 = header.getOrDefault("X-Amz-Security-Token")
  valid_611550 = validateParameter(valid_611550, JString, required = false,
                                 default = nil)
  if valid_611550 != nil:
    section.add "X-Amz-Security-Token", valid_611550
  var valid_611551 = header.getOrDefault("X-Amz-Algorithm")
  valid_611551 = validateParameter(valid_611551, JString, required = false,
                                 default = nil)
  if valid_611551 != nil:
    section.add "X-Amz-Algorithm", valid_611551
  var valid_611552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611552 = validateParameter(valid_611552, JString, required = false,
                                 default = nil)
  if valid_611552 != nil:
    section.add "X-Amz-SignedHeaders", valid_611552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611554: Call_AdminRespondToAuthChallenge_611542; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Responds to an authentication challenge, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_611554.validator(path, query, header, formData, body)
  let scheme = call_611554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611554.url(scheme.get, call_611554.host, call_611554.base,
                         call_611554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611554, url, valid)

proc call*(call_611555: Call_AdminRespondToAuthChallenge_611542; body: JsonNode): Recallable =
  ## adminRespondToAuthChallenge
  ## <p>Responds to an authentication challenge, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_611556 = newJObject()
  if body != nil:
    body_611556 = body
  result = call_611555.call(nil, nil, nil, nil, body_611556)

var adminRespondToAuthChallenge* = Call_AdminRespondToAuthChallenge_611542(
    name: "adminRespondToAuthChallenge", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminRespondToAuthChallenge",
    validator: validate_AdminRespondToAuthChallenge_611543, base: "/",
    url: url_AdminRespondToAuthChallenge_611544,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminSetUserMFAPreference_611557 = ref object of OpenApiRestCall_610658
proc url_AdminSetUserMFAPreference_611559(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminSetUserMFAPreference_611558(path: JsonNode; query: JsonNode;
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
  var valid_611560 = header.getOrDefault("X-Amz-Target")
  valid_611560 = validateParameter(valid_611560, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminSetUserMFAPreference"))
  if valid_611560 != nil:
    section.add "X-Amz-Target", valid_611560
  var valid_611561 = header.getOrDefault("X-Amz-Signature")
  valid_611561 = validateParameter(valid_611561, JString, required = false,
                                 default = nil)
  if valid_611561 != nil:
    section.add "X-Amz-Signature", valid_611561
  var valid_611562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611562 = validateParameter(valid_611562, JString, required = false,
                                 default = nil)
  if valid_611562 != nil:
    section.add "X-Amz-Content-Sha256", valid_611562
  var valid_611563 = header.getOrDefault("X-Amz-Date")
  valid_611563 = validateParameter(valid_611563, JString, required = false,
                                 default = nil)
  if valid_611563 != nil:
    section.add "X-Amz-Date", valid_611563
  var valid_611564 = header.getOrDefault("X-Amz-Credential")
  valid_611564 = validateParameter(valid_611564, JString, required = false,
                                 default = nil)
  if valid_611564 != nil:
    section.add "X-Amz-Credential", valid_611564
  var valid_611565 = header.getOrDefault("X-Amz-Security-Token")
  valid_611565 = validateParameter(valid_611565, JString, required = false,
                                 default = nil)
  if valid_611565 != nil:
    section.add "X-Amz-Security-Token", valid_611565
  var valid_611566 = header.getOrDefault("X-Amz-Algorithm")
  valid_611566 = validateParameter(valid_611566, JString, required = false,
                                 default = nil)
  if valid_611566 != nil:
    section.add "X-Amz-Algorithm", valid_611566
  var valid_611567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611567 = validateParameter(valid_611567, JString, required = false,
                                 default = nil)
  if valid_611567 != nil:
    section.add "X-Amz-SignedHeaders", valid_611567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611569: Call_AdminSetUserMFAPreference_611557; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the user's multi-factor authentication (MFA) preference, including which MFA options are enabled and if any are preferred. Only one factor can be set as preferred. The preferred MFA factor will be used to authenticate a user if multiple factors are enabled. If multiple options are enabled and no preference is set, a challenge to choose an MFA option will be returned during sign in.
  ## 
  let valid = call_611569.validator(path, query, header, formData, body)
  let scheme = call_611569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611569.url(scheme.get, call_611569.host, call_611569.base,
                         call_611569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611569, url, valid)

proc call*(call_611570: Call_AdminSetUserMFAPreference_611557; body: JsonNode): Recallable =
  ## adminSetUserMFAPreference
  ## Sets the user's multi-factor authentication (MFA) preference, including which MFA options are enabled and if any are preferred. Only one factor can be set as preferred. The preferred MFA factor will be used to authenticate a user if multiple factors are enabled. If multiple options are enabled and no preference is set, a challenge to choose an MFA option will be returned during sign in.
  ##   body: JObject (required)
  var body_611571 = newJObject()
  if body != nil:
    body_611571 = body
  result = call_611570.call(nil, nil, nil, nil, body_611571)

var adminSetUserMFAPreference* = Call_AdminSetUserMFAPreference_611557(
    name: "adminSetUserMFAPreference", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminSetUserMFAPreference",
    validator: validate_AdminSetUserMFAPreference_611558, base: "/",
    url: url_AdminSetUserMFAPreference_611559,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminSetUserPassword_611572 = ref object of OpenApiRestCall_610658
proc url_AdminSetUserPassword_611574(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminSetUserPassword_611573(path: JsonNode; query: JsonNode;
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
  var valid_611575 = header.getOrDefault("X-Amz-Target")
  valid_611575 = validateParameter(valid_611575, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminSetUserPassword"))
  if valid_611575 != nil:
    section.add "X-Amz-Target", valid_611575
  var valid_611576 = header.getOrDefault("X-Amz-Signature")
  valid_611576 = validateParameter(valid_611576, JString, required = false,
                                 default = nil)
  if valid_611576 != nil:
    section.add "X-Amz-Signature", valid_611576
  var valid_611577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611577 = validateParameter(valid_611577, JString, required = false,
                                 default = nil)
  if valid_611577 != nil:
    section.add "X-Amz-Content-Sha256", valid_611577
  var valid_611578 = header.getOrDefault("X-Amz-Date")
  valid_611578 = validateParameter(valid_611578, JString, required = false,
                                 default = nil)
  if valid_611578 != nil:
    section.add "X-Amz-Date", valid_611578
  var valid_611579 = header.getOrDefault("X-Amz-Credential")
  valid_611579 = validateParameter(valid_611579, JString, required = false,
                                 default = nil)
  if valid_611579 != nil:
    section.add "X-Amz-Credential", valid_611579
  var valid_611580 = header.getOrDefault("X-Amz-Security-Token")
  valid_611580 = validateParameter(valid_611580, JString, required = false,
                                 default = nil)
  if valid_611580 != nil:
    section.add "X-Amz-Security-Token", valid_611580
  var valid_611581 = header.getOrDefault("X-Amz-Algorithm")
  valid_611581 = validateParameter(valid_611581, JString, required = false,
                                 default = nil)
  if valid_611581 != nil:
    section.add "X-Amz-Algorithm", valid_611581
  var valid_611582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611582 = validateParameter(valid_611582, JString, required = false,
                                 default = nil)
  if valid_611582 != nil:
    section.add "X-Amz-SignedHeaders", valid_611582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611584: Call_AdminSetUserPassword_611572; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the specified user's password in a user pool as an administrator. Works on any user. </p> <p>The password can be temporary or permanent. If it is temporary, the user status will be placed into the <code>FORCE_CHANGE_PASSWORD</code> state. When the user next tries to sign in, the InitiateAuth/AdminInitiateAuth response will contain the <code>NEW_PASSWORD_REQUIRED</code> challenge. If the user does not sign in before it expires, the user will not be able to sign in and their password will need to be reset by an administrator. </p> <p>Once the user has set a new password, or the password is permanent, the user status will be set to <code>Confirmed</code>.</p>
  ## 
  let valid = call_611584.validator(path, query, header, formData, body)
  let scheme = call_611584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611584.url(scheme.get, call_611584.host, call_611584.base,
                         call_611584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611584, url, valid)

proc call*(call_611585: Call_AdminSetUserPassword_611572; body: JsonNode): Recallable =
  ## adminSetUserPassword
  ## <p>Sets the specified user's password in a user pool as an administrator. Works on any user. </p> <p>The password can be temporary or permanent. If it is temporary, the user status will be placed into the <code>FORCE_CHANGE_PASSWORD</code> state. When the user next tries to sign in, the InitiateAuth/AdminInitiateAuth response will contain the <code>NEW_PASSWORD_REQUIRED</code> challenge. If the user does not sign in before it expires, the user will not be able to sign in and their password will need to be reset by an administrator. </p> <p>Once the user has set a new password, or the password is permanent, the user status will be set to <code>Confirmed</code>.</p>
  ##   body: JObject (required)
  var body_611586 = newJObject()
  if body != nil:
    body_611586 = body
  result = call_611585.call(nil, nil, nil, nil, body_611586)

var adminSetUserPassword* = Call_AdminSetUserPassword_611572(
    name: "adminSetUserPassword", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminSetUserPassword",
    validator: validate_AdminSetUserPassword_611573, base: "/",
    url: url_AdminSetUserPassword_611574, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminSetUserSettings_611587 = ref object of OpenApiRestCall_610658
proc url_AdminSetUserSettings_611589(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminSetUserSettings_611588(path: JsonNode; query: JsonNode;
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
  var valid_611590 = header.getOrDefault("X-Amz-Target")
  valid_611590 = validateParameter(valid_611590, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminSetUserSettings"))
  if valid_611590 != nil:
    section.add "X-Amz-Target", valid_611590
  var valid_611591 = header.getOrDefault("X-Amz-Signature")
  valid_611591 = validateParameter(valid_611591, JString, required = false,
                                 default = nil)
  if valid_611591 != nil:
    section.add "X-Amz-Signature", valid_611591
  var valid_611592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611592 = validateParameter(valid_611592, JString, required = false,
                                 default = nil)
  if valid_611592 != nil:
    section.add "X-Amz-Content-Sha256", valid_611592
  var valid_611593 = header.getOrDefault("X-Amz-Date")
  valid_611593 = validateParameter(valid_611593, JString, required = false,
                                 default = nil)
  if valid_611593 != nil:
    section.add "X-Amz-Date", valid_611593
  var valid_611594 = header.getOrDefault("X-Amz-Credential")
  valid_611594 = validateParameter(valid_611594, JString, required = false,
                                 default = nil)
  if valid_611594 != nil:
    section.add "X-Amz-Credential", valid_611594
  var valid_611595 = header.getOrDefault("X-Amz-Security-Token")
  valid_611595 = validateParameter(valid_611595, JString, required = false,
                                 default = nil)
  if valid_611595 != nil:
    section.add "X-Amz-Security-Token", valid_611595
  var valid_611596 = header.getOrDefault("X-Amz-Algorithm")
  valid_611596 = validateParameter(valid_611596, JString, required = false,
                                 default = nil)
  if valid_611596 != nil:
    section.add "X-Amz-Algorithm", valid_611596
  var valid_611597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611597 = validateParameter(valid_611597, JString, required = false,
                                 default = nil)
  if valid_611597 != nil:
    section.add "X-Amz-SignedHeaders", valid_611597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611599: Call_AdminSetUserSettings_611587; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <i>This action is no longer supported.</i> You can use it to configure only SMS MFA. You can't use it to configure TOTP software token MFA. To configure either type of MFA, use the <a>AdminSetUserMFAPreference</a> action instead.
  ## 
  let valid = call_611599.validator(path, query, header, formData, body)
  let scheme = call_611599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611599.url(scheme.get, call_611599.host, call_611599.base,
                         call_611599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611599, url, valid)

proc call*(call_611600: Call_AdminSetUserSettings_611587; body: JsonNode): Recallable =
  ## adminSetUserSettings
  ##  <i>This action is no longer supported.</i> You can use it to configure only SMS MFA. You can't use it to configure TOTP software token MFA. To configure either type of MFA, use the <a>AdminSetUserMFAPreference</a> action instead.
  ##   body: JObject (required)
  var body_611601 = newJObject()
  if body != nil:
    body_611601 = body
  result = call_611600.call(nil, nil, nil, nil, body_611601)

var adminSetUserSettings* = Call_AdminSetUserSettings_611587(
    name: "adminSetUserSettings", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminSetUserSettings",
    validator: validate_AdminSetUserSettings_611588, base: "/",
    url: url_AdminSetUserSettings_611589, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUpdateAuthEventFeedback_611602 = ref object of OpenApiRestCall_610658
proc url_AdminUpdateAuthEventFeedback_611604(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminUpdateAuthEventFeedback_611603(path: JsonNode; query: JsonNode;
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
  var valid_611605 = header.getOrDefault("X-Amz-Target")
  valid_611605 = validateParameter(valid_611605, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUpdateAuthEventFeedback"))
  if valid_611605 != nil:
    section.add "X-Amz-Target", valid_611605
  var valid_611606 = header.getOrDefault("X-Amz-Signature")
  valid_611606 = validateParameter(valid_611606, JString, required = false,
                                 default = nil)
  if valid_611606 != nil:
    section.add "X-Amz-Signature", valid_611606
  var valid_611607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611607 = validateParameter(valid_611607, JString, required = false,
                                 default = nil)
  if valid_611607 != nil:
    section.add "X-Amz-Content-Sha256", valid_611607
  var valid_611608 = header.getOrDefault("X-Amz-Date")
  valid_611608 = validateParameter(valid_611608, JString, required = false,
                                 default = nil)
  if valid_611608 != nil:
    section.add "X-Amz-Date", valid_611608
  var valid_611609 = header.getOrDefault("X-Amz-Credential")
  valid_611609 = validateParameter(valid_611609, JString, required = false,
                                 default = nil)
  if valid_611609 != nil:
    section.add "X-Amz-Credential", valid_611609
  var valid_611610 = header.getOrDefault("X-Amz-Security-Token")
  valid_611610 = validateParameter(valid_611610, JString, required = false,
                                 default = nil)
  if valid_611610 != nil:
    section.add "X-Amz-Security-Token", valid_611610
  var valid_611611 = header.getOrDefault("X-Amz-Algorithm")
  valid_611611 = validateParameter(valid_611611, JString, required = false,
                                 default = nil)
  if valid_611611 != nil:
    section.add "X-Amz-Algorithm", valid_611611
  var valid_611612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611612 = validateParameter(valid_611612, JString, required = false,
                                 default = nil)
  if valid_611612 != nil:
    section.add "X-Amz-SignedHeaders", valid_611612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611614: Call_AdminUpdateAuthEventFeedback_611602; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides feedback for an authentication event as to whether it was from a valid user. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ## 
  let valid = call_611614.validator(path, query, header, formData, body)
  let scheme = call_611614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611614.url(scheme.get, call_611614.host, call_611614.base,
                         call_611614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611614, url, valid)

proc call*(call_611615: Call_AdminUpdateAuthEventFeedback_611602; body: JsonNode): Recallable =
  ## adminUpdateAuthEventFeedback
  ## Provides feedback for an authentication event as to whether it was from a valid user. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ##   body: JObject (required)
  var body_611616 = newJObject()
  if body != nil:
    body_611616 = body
  result = call_611615.call(nil, nil, nil, nil, body_611616)

var adminUpdateAuthEventFeedback* = Call_AdminUpdateAuthEventFeedback_611602(
    name: "adminUpdateAuthEventFeedback", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUpdateAuthEventFeedback",
    validator: validate_AdminUpdateAuthEventFeedback_611603, base: "/",
    url: url_AdminUpdateAuthEventFeedback_611604,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUpdateDeviceStatus_611617 = ref object of OpenApiRestCall_610658
proc url_AdminUpdateDeviceStatus_611619(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminUpdateDeviceStatus_611618(path: JsonNode; query: JsonNode;
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
  var valid_611620 = header.getOrDefault("X-Amz-Target")
  valid_611620 = validateParameter(valid_611620, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUpdateDeviceStatus"))
  if valid_611620 != nil:
    section.add "X-Amz-Target", valid_611620
  var valid_611621 = header.getOrDefault("X-Amz-Signature")
  valid_611621 = validateParameter(valid_611621, JString, required = false,
                                 default = nil)
  if valid_611621 != nil:
    section.add "X-Amz-Signature", valid_611621
  var valid_611622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611622 = validateParameter(valid_611622, JString, required = false,
                                 default = nil)
  if valid_611622 != nil:
    section.add "X-Amz-Content-Sha256", valid_611622
  var valid_611623 = header.getOrDefault("X-Amz-Date")
  valid_611623 = validateParameter(valid_611623, JString, required = false,
                                 default = nil)
  if valid_611623 != nil:
    section.add "X-Amz-Date", valid_611623
  var valid_611624 = header.getOrDefault("X-Amz-Credential")
  valid_611624 = validateParameter(valid_611624, JString, required = false,
                                 default = nil)
  if valid_611624 != nil:
    section.add "X-Amz-Credential", valid_611624
  var valid_611625 = header.getOrDefault("X-Amz-Security-Token")
  valid_611625 = validateParameter(valid_611625, JString, required = false,
                                 default = nil)
  if valid_611625 != nil:
    section.add "X-Amz-Security-Token", valid_611625
  var valid_611626 = header.getOrDefault("X-Amz-Algorithm")
  valid_611626 = validateParameter(valid_611626, JString, required = false,
                                 default = nil)
  if valid_611626 != nil:
    section.add "X-Amz-Algorithm", valid_611626
  var valid_611627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611627 = validateParameter(valid_611627, JString, required = false,
                                 default = nil)
  if valid_611627 != nil:
    section.add "X-Amz-SignedHeaders", valid_611627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611629: Call_AdminUpdateDeviceStatus_611617; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the device status as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_611629.validator(path, query, header, formData, body)
  let scheme = call_611629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611629.url(scheme.get, call_611629.host, call_611629.base,
                         call_611629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611629, url, valid)

proc call*(call_611630: Call_AdminUpdateDeviceStatus_611617; body: JsonNode): Recallable =
  ## adminUpdateDeviceStatus
  ## <p>Updates the device status as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_611631 = newJObject()
  if body != nil:
    body_611631 = body
  result = call_611630.call(nil, nil, nil, nil, body_611631)

var adminUpdateDeviceStatus* = Call_AdminUpdateDeviceStatus_611617(
    name: "adminUpdateDeviceStatus", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUpdateDeviceStatus",
    validator: validate_AdminUpdateDeviceStatus_611618, base: "/",
    url: url_AdminUpdateDeviceStatus_611619, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUpdateUserAttributes_611632 = ref object of OpenApiRestCall_610658
proc url_AdminUpdateUserAttributes_611634(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminUpdateUserAttributes_611633(path: JsonNode; query: JsonNode;
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
  var valid_611635 = header.getOrDefault("X-Amz-Target")
  valid_611635 = validateParameter(valid_611635, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUpdateUserAttributes"))
  if valid_611635 != nil:
    section.add "X-Amz-Target", valid_611635
  var valid_611636 = header.getOrDefault("X-Amz-Signature")
  valid_611636 = validateParameter(valid_611636, JString, required = false,
                                 default = nil)
  if valid_611636 != nil:
    section.add "X-Amz-Signature", valid_611636
  var valid_611637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611637 = validateParameter(valid_611637, JString, required = false,
                                 default = nil)
  if valid_611637 != nil:
    section.add "X-Amz-Content-Sha256", valid_611637
  var valid_611638 = header.getOrDefault("X-Amz-Date")
  valid_611638 = validateParameter(valid_611638, JString, required = false,
                                 default = nil)
  if valid_611638 != nil:
    section.add "X-Amz-Date", valid_611638
  var valid_611639 = header.getOrDefault("X-Amz-Credential")
  valid_611639 = validateParameter(valid_611639, JString, required = false,
                                 default = nil)
  if valid_611639 != nil:
    section.add "X-Amz-Credential", valid_611639
  var valid_611640 = header.getOrDefault("X-Amz-Security-Token")
  valid_611640 = validateParameter(valid_611640, JString, required = false,
                                 default = nil)
  if valid_611640 != nil:
    section.add "X-Amz-Security-Token", valid_611640
  var valid_611641 = header.getOrDefault("X-Amz-Algorithm")
  valid_611641 = validateParameter(valid_611641, JString, required = false,
                                 default = nil)
  if valid_611641 != nil:
    section.add "X-Amz-Algorithm", valid_611641
  var valid_611642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611642 = validateParameter(valid_611642, JString, required = false,
                                 default = nil)
  if valid_611642 != nil:
    section.add "X-Amz-SignedHeaders", valid_611642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611644: Call_AdminUpdateUserAttributes_611632; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified user's attributes, including developer attributes, as an administrator. Works on any user.</p> <p>For custom attributes, you must prepend the <code>custom:</code> prefix to the attribute name.</p> <p>In addition to updating user attributes, this API can also be used to mark phone and email as verified.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_611644.validator(path, query, header, formData, body)
  let scheme = call_611644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611644.url(scheme.get, call_611644.host, call_611644.base,
                         call_611644.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611644, url, valid)

proc call*(call_611645: Call_AdminUpdateUserAttributes_611632; body: JsonNode): Recallable =
  ## adminUpdateUserAttributes
  ## <p>Updates the specified user's attributes, including developer attributes, as an administrator. Works on any user.</p> <p>For custom attributes, you must prepend the <code>custom:</code> prefix to the attribute name.</p> <p>In addition to updating user attributes, this API can also be used to mark phone and email as verified.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_611646 = newJObject()
  if body != nil:
    body_611646 = body
  result = call_611645.call(nil, nil, nil, nil, body_611646)

var adminUpdateUserAttributes* = Call_AdminUpdateUserAttributes_611632(
    name: "adminUpdateUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUpdateUserAttributes",
    validator: validate_AdminUpdateUserAttributes_611633, base: "/",
    url: url_AdminUpdateUserAttributes_611634,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUserGlobalSignOut_611647 = ref object of OpenApiRestCall_610658
proc url_AdminUserGlobalSignOut_611649(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminUserGlobalSignOut_611648(path: JsonNode; query: JsonNode;
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
  var valid_611650 = header.getOrDefault("X-Amz-Target")
  valid_611650 = validateParameter(valid_611650, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUserGlobalSignOut"))
  if valid_611650 != nil:
    section.add "X-Amz-Target", valid_611650
  var valid_611651 = header.getOrDefault("X-Amz-Signature")
  valid_611651 = validateParameter(valid_611651, JString, required = false,
                                 default = nil)
  if valid_611651 != nil:
    section.add "X-Amz-Signature", valid_611651
  var valid_611652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611652 = validateParameter(valid_611652, JString, required = false,
                                 default = nil)
  if valid_611652 != nil:
    section.add "X-Amz-Content-Sha256", valid_611652
  var valid_611653 = header.getOrDefault("X-Amz-Date")
  valid_611653 = validateParameter(valid_611653, JString, required = false,
                                 default = nil)
  if valid_611653 != nil:
    section.add "X-Amz-Date", valid_611653
  var valid_611654 = header.getOrDefault("X-Amz-Credential")
  valid_611654 = validateParameter(valid_611654, JString, required = false,
                                 default = nil)
  if valid_611654 != nil:
    section.add "X-Amz-Credential", valid_611654
  var valid_611655 = header.getOrDefault("X-Amz-Security-Token")
  valid_611655 = validateParameter(valid_611655, JString, required = false,
                                 default = nil)
  if valid_611655 != nil:
    section.add "X-Amz-Security-Token", valid_611655
  var valid_611656 = header.getOrDefault("X-Amz-Algorithm")
  valid_611656 = validateParameter(valid_611656, JString, required = false,
                                 default = nil)
  if valid_611656 != nil:
    section.add "X-Amz-Algorithm", valid_611656
  var valid_611657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611657 = validateParameter(valid_611657, JString, required = false,
                                 default = nil)
  if valid_611657 != nil:
    section.add "X-Amz-SignedHeaders", valid_611657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611659: Call_AdminUserGlobalSignOut_611647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Signs out users from all devices, as an administrator. It also invalidates all refresh tokens issued to a user. The user's current access and Id tokens remain valid until their expiry. Access and Id tokens expire one hour after they are issued.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_611659.validator(path, query, header, formData, body)
  let scheme = call_611659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611659.url(scheme.get, call_611659.host, call_611659.base,
                         call_611659.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611659, url, valid)

proc call*(call_611660: Call_AdminUserGlobalSignOut_611647; body: JsonNode): Recallable =
  ## adminUserGlobalSignOut
  ## <p>Signs out users from all devices, as an administrator. It also invalidates all refresh tokens issued to a user. The user's current access and Id tokens remain valid until their expiry. Access and Id tokens expire one hour after they are issued.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_611661 = newJObject()
  if body != nil:
    body_611661 = body
  result = call_611660.call(nil, nil, nil, nil, body_611661)

var adminUserGlobalSignOut* = Call_AdminUserGlobalSignOut_611647(
    name: "adminUserGlobalSignOut", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUserGlobalSignOut",
    validator: validate_AdminUserGlobalSignOut_611648, base: "/",
    url: url_AdminUserGlobalSignOut_611649, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSoftwareToken_611662 = ref object of OpenApiRestCall_610658
proc url_AssociateSoftwareToken_611664(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateSoftwareToken_611663(path: JsonNode; query: JsonNode;
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
  var valid_611665 = header.getOrDefault("X-Amz-Target")
  valid_611665 = validateParameter(valid_611665, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AssociateSoftwareToken"))
  if valid_611665 != nil:
    section.add "X-Amz-Target", valid_611665
  var valid_611666 = header.getOrDefault("X-Amz-Signature")
  valid_611666 = validateParameter(valid_611666, JString, required = false,
                                 default = nil)
  if valid_611666 != nil:
    section.add "X-Amz-Signature", valid_611666
  var valid_611667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611667 = validateParameter(valid_611667, JString, required = false,
                                 default = nil)
  if valid_611667 != nil:
    section.add "X-Amz-Content-Sha256", valid_611667
  var valid_611668 = header.getOrDefault("X-Amz-Date")
  valid_611668 = validateParameter(valid_611668, JString, required = false,
                                 default = nil)
  if valid_611668 != nil:
    section.add "X-Amz-Date", valid_611668
  var valid_611669 = header.getOrDefault("X-Amz-Credential")
  valid_611669 = validateParameter(valid_611669, JString, required = false,
                                 default = nil)
  if valid_611669 != nil:
    section.add "X-Amz-Credential", valid_611669
  var valid_611670 = header.getOrDefault("X-Amz-Security-Token")
  valid_611670 = validateParameter(valid_611670, JString, required = false,
                                 default = nil)
  if valid_611670 != nil:
    section.add "X-Amz-Security-Token", valid_611670
  var valid_611671 = header.getOrDefault("X-Amz-Algorithm")
  valid_611671 = validateParameter(valid_611671, JString, required = false,
                                 default = nil)
  if valid_611671 != nil:
    section.add "X-Amz-Algorithm", valid_611671
  var valid_611672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611672 = validateParameter(valid_611672, JString, required = false,
                                 default = nil)
  if valid_611672 != nil:
    section.add "X-Amz-SignedHeaders", valid_611672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611674: Call_AssociateSoftwareToken_611662; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a unique generated shared secret key code for the user account. The request takes an access token or a session string, but not both.
  ## 
  let valid = call_611674.validator(path, query, header, formData, body)
  let scheme = call_611674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611674.url(scheme.get, call_611674.host, call_611674.base,
                         call_611674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611674, url, valid)

proc call*(call_611675: Call_AssociateSoftwareToken_611662; body: JsonNode): Recallable =
  ## associateSoftwareToken
  ## Returns a unique generated shared secret key code for the user account. The request takes an access token or a session string, but not both.
  ##   body: JObject (required)
  var body_611676 = newJObject()
  if body != nil:
    body_611676 = body
  result = call_611675.call(nil, nil, nil, nil, body_611676)

var associateSoftwareToken* = Call_AssociateSoftwareToken_611662(
    name: "associateSoftwareToken", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AssociateSoftwareToken",
    validator: validate_AssociateSoftwareToken_611663, base: "/",
    url: url_AssociateSoftwareToken_611664, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ChangePassword_611677 = ref object of OpenApiRestCall_610658
proc url_ChangePassword_611679(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ChangePassword_611678(path: JsonNode; query: JsonNode;
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
  var valid_611680 = header.getOrDefault("X-Amz-Target")
  valid_611680 = validateParameter(valid_611680, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ChangePassword"))
  if valid_611680 != nil:
    section.add "X-Amz-Target", valid_611680
  var valid_611681 = header.getOrDefault("X-Amz-Signature")
  valid_611681 = validateParameter(valid_611681, JString, required = false,
                                 default = nil)
  if valid_611681 != nil:
    section.add "X-Amz-Signature", valid_611681
  var valid_611682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611682 = validateParameter(valid_611682, JString, required = false,
                                 default = nil)
  if valid_611682 != nil:
    section.add "X-Amz-Content-Sha256", valid_611682
  var valid_611683 = header.getOrDefault("X-Amz-Date")
  valid_611683 = validateParameter(valid_611683, JString, required = false,
                                 default = nil)
  if valid_611683 != nil:
    section.add "X-Amz-Date", valid_611683
  var valid_611684 = header.getOrDefault("X-Amz-Credential")
  valid_611684 = validateParameter(valid_611684, JString, required = false,
                                 default = nil)
  if valid_611684 != nil:
    section.add "X-Amz-Credential", valid_611684
  var valid_611685 = header.getOrDefault("X-Amz-Security-Token")
  valid_611685 = validateParameter(valid_611685, JString, required = false,
                                 default = nil)
  if valid_611685 != nil:
    section.add "X-Amz-Security-Token", valid_611685
  var valid_611686 = header.getOrDefault("X-Amz-Algorithm")
  valid_611686 = validateParameter(valid_611686, JString, required = false,
                                 default = nil)
  if valid_611686 != nil:
    section.add "X-Amz-Algorithm", valid_611686
  var valid_611687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611687 = validateParameter(valid_611687, JString, required = false,
                                 default = nil)
  if valid_611687 != nil:
    section.add "X-Amz-SignedHeaders", valid_611687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611689: Call_ChangePassword_611677; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the password for a specified user in a user pool.
  ## 
  let valid = call_611689.validator(path, query, header, formData, body)
  let scheme = call_611689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611689.url(scheme.get, call_611689.host, call_611689.base,
                         call_611689.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611689, url, valid)

proc call*(call_611690: Call_ChangePassword_611677; body: JsonNode): Recallable =
  ## changePassword
  ## Changes the password for a specified user in a user pool.
  ##   body: JObject (required)
  var body_611691 = newJObject()
  if body != nil:
    body_611691 = body
  result = call_611690.call(nil, nil, nil, nil, body_611691)

var changePassword* = Call_ChangePassword_611677(name: "changePassword",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ChangePassword",
    validator: validate_ChangePassword_611678, base: "/", url: url_ChangePassword_611679,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmDevice_611692 = ref object of OpenApiRestCall_610658
proc url_ConfirmDevice_611694(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ConfirmDevice_611693(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611695 = header.getOrDefault("X-Amz-Target")
  valid_611695 = validateParameter(valid_611695, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ConfirmDevice"))
  if valid_611695 != nil:
    section.add "X-Amz-Target", valid_611695
  var valid_611696 = header.getOrDefault("X-Amz-Signature")
  valid_611696 = validateParameter(valid_611696, JString, required = false,
                                 default = nil)
  if valid_611696 != nil:
    section.add "X-Amz-Signature", valid_611696
  var valid_611697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611697 = validateParameter(valid_611697, JString, required = false,
                                 default = nil)
  if valid_611697 != nil:
    section.add "X-Amz-Content-Sha256", valid_611697
  var valid_611698 = header.getOrDefault("X-Amz-Date")
  valid_611698 = validateParameter(valid_611698, JString, required = false,
                                 default = nil)
  if valid_611698 != nil:
    section.add "X-Amz-Date", valid_611698
  var valid_611699 = header.getOrDefault("X-Amz-Credential")
  valid_611699 = validateParameter(valid_611699, JString, required = false,
                                 default = nil)
  if valid_611699 != nil:
    section.add "X-Amz-Credential", valid_611699
  var valid_611700 = header.getOrDefault("X-Amz-Security-Token")
  valid_611700 = validateParameter(valid_611700, JString, required = false,
                                 default = nil)
  if valid_611700 != nil:
    section.add "X-Amz-Security-Token", valid_611700
  var valid_611701 = header.getOrDefault("X-Amz-Algorithm")
  valid_611701 = validateParameter(valid_611701, JString, required = false,
                                 default = nil)
  if valid_611701 != nil:
    section.add "X-Amz-Algorithm", valid_611701
  var valid_611702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611702 = validateParameter(valid_611702, JString, required = false,
                                 default = nil)
  if valid_611702 != nil:
    section.add "X-Amz-SignedHeaders", valid_611702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611704: Call_ConfirmDevice_611692; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Confirms tracking of the device. This API call is the call that begins device tracking.
  ## 
  let valid = call_611704.validator(path, query, header, formData, body)
  let scheme = call_611704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611704.url(scheme.get, call_611704.host, call_611704.base,
                         call_611704.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611704, url, valid)

proc call*(call_611705: Call_ConfirmDevice_611692; body: JsonNode): Recallable =
  ## confirmDevice
  ## Confirms tracking of the device. This API call is the call that begins device tracking.
  ##   body: JObject (required)
  var body_611706 = newJObject()
  if body != nil:
    body_611706 = body
  result = call_611705.call(nil, nil, nil, nil, body_611706)

var confirmDevice* = Call_ConfirmDevice_611692(name: "confirmDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ConfirmDevice",
    validator: validate_ConfirmDevice_611693, base: "/", url: url_ConfirmDevice_611694,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmForgotPassword_611707 = ref object of OpenApiRestCall_610658
proc url_ConfirmForgotPassword_611709(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ConfirmForgotPassword_611708(path: JsonNode; query: JsonNode;
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
  var valid_611710 = header.getOrDefault("X-Amz-Target")
  valid_611710 = validateParameter(valid_611710, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ConfirmForgotPassword"))
  if valid_611710 != nil:
    section.add "X-Amz-Target", valid_611710
  var valid_611711 = header.getOrDefault("X-Amz-Signature")
  valid_611711 = validateParameter(valid_611711, JString, required = false,
                                 default = nil)
  if valid_611711 != nil:
    section.add "X-Amz-Signature", valid_611711
  var valid_611712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611712 = validateParameter(valid_611712, JString, required = false,
                                 default = nil)
  if valid_611712 != nil:
    section.add "X-Amz-Content-Sha256", valid_611712
  var valid_611713 = header.getOrDefault("X-Amz-Date")
  valid_611713 = validateParameter(valid_611713, JString, required = false,
                                 default = nil)
  if valid_611713 != nil:
    section.add "X-Amz-Date", valid_611713
  var valid_611714 = header.getOrDefault("X-Amz-Credential")
  valid_611714 = validateParameter(valid_611714, JString, required = false,
                                 default = nil)
  if valid_611714 != nil:
    section.add "X-Amz-Credential", valid_611714
  var valid_611715 = header.getOrDefault("X-Amz-Security-Token")
  valid_611715 = validateParameter(valid_611715, JString, required = false,
                                 default = nil)
  if valid_611715 != nil:
    section.add "X-Amz-Security-Token", valid_611715
  var valid_611716 = header.getOrDefault("X-Amz-Algorithm")
  valid_611716 = validateParameter(valid_611716, JString, required = false,
                                 default = nil)
  if valid_611716 != nil:
    section.add "X-Amz-Algorithm", valid_611716
  var valid_611717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611717 = validateParameter(valid_611717, JString, required = false,
                                 default = nil)
  if valid_611717 != nil:
    section.add "X-Amz-SignedHeaders", valid_611717
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611719: Call_ConfirmForgotPassword_611707; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a user to enter a confirmation code to reset a forgotten password.
  ## 
  let valid = call_611719.validator(path, query, header, formData, body)
  let scheme = call_611719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611719.url(scheme.get, call_611719.host, call_611719.base,
                         call_611719.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611719, url, valid)

proc call*(call_611720: Call_ConfirmForgotPassword_611707; body: JsonNode): Recallable =
  ## confirmForgotPassword
  ## Allows a user to enter a confirmation code to reset a forgotten password.
  ##   body: JObject (required)
  var body_611721 = newJObject()
  if body != nil:
    body_611721 = body
  result = call_611720.call(nil, nil, nil, nil, body_611721)

var confirmForgotPassword* = Call_ConfirmForgotPassword_611707(
    name: "confirmForgotPassword", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ConfirmForgotPassword",
    validator: validate_ConfirmForgotPassword_611708, base: "/",
    url: url_ConfirmForgotPassword_611709, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmSignUp_611722 = ref object of OpenApiRestCall_610658
proc url_ConfirmSignUp_611724(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ConfirmSignUp_611723(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611725 = header.getOrDefault("X-Amz-Target")
  valid_611725 = validateParameter(valid_611725, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ConfirmSignUp"))
  if valid_611725 != nil:
    section.add "X-Amz-Target", valid_611725
  var valid_611726 = header.getOrDefault("X-Amz-Signature")
  valid_611726 = validateParameter(valid_611726, JString, required = false,
                                 default = nil)
  if valid_611726 != nil:
    section.add "X-Amz-Signature", valid_611726
  var valid_611727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611727 = validateParameter(valid_611727, JString, required = false,
                                 default = nil)
  if valid_611727 != nil:
    section.add "X-Amz-Content-Sha256", valid_611727
  var valid_611728 = header.getOrDefault("X-Amz-Date")
  valid_611728 = validateParameter(valid_611728, JString, required = false,
                                 default = nil)
  if valid_611728 != nil:
    section.add "X-Amz-Date", valid_611728
  var valid_611729 = header.getOrDefault("X-Amz-Credential")
  valid_611729 = validateParameter(valid_611729, JString, required = false,
                                 default = nil)
  if valid_611729 != nil:
    section.add "X-Amz-Credential", valid_611729
  var valid_611730 = header.getOrDefault("X-Amz-Security-Token")
  valid_611730 = validateParameter(valid_611730, JString, required = false,
                                 default = nil)
  if valid_611730 != nil:
    section.add "X-Amz-Security-Token", valid_611730
  var valid_611731 = header.getOrDefault("X-Amz-Algorithm")
  valid_611731 = validateParameter(valid_611731, JString, required = false,
                                 default = nil)
  if valid_611731 != nil:
    section.add "X-Amz-Algorithm", valid_611731
  var valid_611732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611732 = validateParameter(valid_611732, JString, required = false,
                                 default = nil)
  if valid_611732 != nil:
    section.add "X-Amz-SignedHeaders", valid_611732
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611734: Call_ConfirmSignUp_611722; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Confirms registration of a user and handles the existing alias from a previous user.
  ## 
  let valid = call_611734.validator(path, query, header, formData, body)
  let scheme = call_611734.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611734.url(scheme.get, call_611734.host, call_611734.base,
                         call_611734.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611734, url, valid)

proc call*(call_611735: Call_ConfirmSignUp_611722; body: JsonNode): Recallable =
  ## confirmSignUp
  ## Confirms registration of a user and handles the existing alias from a previous user.
  ##   body: JObject (required)
  var body_611736 = newJObject()
  if body != nil:
    body_611736 = body
  result = call_611735.call(nil, nil, nil, nil, body_611736)

var confirmSignUp* = Call_ConfirmSignUp_611722(name: "confirmSignUp",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ConfirmSignUp",
    validator: validate_ConfirmSignUp_611723, base: "/", url: url_ConfirmSignUp_611724,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_611737 = ref object of OpenApiRestCall_610658
proc url_CreateGroup_611739(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateGroup_611738(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611740 = header.getOrDefault("X-Amz-Target")
  valid_611740 = validateParameter(valid_611740, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateGroup"))
  if valid_611740 != nil:
    section.add "X-Amz-Target", valid_611740
  var valid_611741 = header.getOrDefault("X-Amz-Signature")
  valid_611741 = validateParameter(valid_611741, JString, required = false,
                                 default = nil)
  if valid_611741 != nil:
    section.add "X-Amz-Signature", valid_611741
  var valid_611742 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611742 = validateParameter(valid_611742, JString, required = false,
                                 default = nil)
  if valid_611742 != nil:
    section.add "X-Amz-Content-Sha256", valid_611742
  var valid_611743 = header.getOrDefault("X-Amz-Date")
  valid_611743 = validateParameter(valid_611743, JString, required = false,
                                 default = nil)
  if valid_611743 != nil:
    section.add "X-Amz-Date", valid_611743
  var valid_611744 = header.getOrDefault("X-Amz-Credential")
  valid_611744 = validateParameter(valid_611744, JString, required = false,
                                 default = nil)
  if valid_611744 != nil:
    section.add "X-Amz-Credential", valid_611744
  var valid_611745 = header.getOrDefault("X-Amz-Security-Token")
  valid_611745 = validateParameter(valid_611745, JString, required = false,
                                 default = nil)
  if valid_611745 != nil:
    section.add "X-Amz-Security-Token", valid_611745
  var valid_611746 = header.getOrDefault("X-Amz-Algorithm")
  valid_611746 = validateParameter(valid_611746, JString, required = false,
                                 default = nil)
  if valid_611746 != nil:
    section.add "X-Amz-Algorithm", valid_611746
  var valid_611747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611747 = validateParameter(valid_611747, JString, required = false,
                                 default = nil)
  if valid_611747 != nil:
    section.add "X-Amz-SignedHeaders", valid_611747
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611749: Call_CreateGroup_611737; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new group in the specified user pool.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_611749.validator(path, query, header, formData, body)
  let scheme = call_611749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611749.url(scheme.get, call_611749.host, call_611749.base,
                         call_611749.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611749, url, valid)

proc call*(call_611750: Call_CreateGroup_611737; body: JsonNode): Recallable =
  ## createGroup
  ## <p>Creates a new group in the specified user pool.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_611751 = newJObject()
  if body != nil:
    body_611751 = body
  result = call_611750.call(nil, nil, nil, nil, body_611751)

var createGroup* = Call_CreateGroup_611737(name: "createGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateGroup",
                                        validator: validate_CreateGroup_611738,
                                        base: "/", url: url_CreateGroup_611739,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIdentityProvider_611752 = ref object of OpenApiRestCall_610658
proc url_CreateIdentityProvider_611754(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateIdentityProvider_611753(path: JsonNode; query: JsonNode;
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
  var valid_611755 = header.getOrDefault("X-Amz-Target")
  valid_611755 = validateParameter(valid_611755, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateIdentityProvider"))
  if valid_611755 != nil:
    section.add "X-Amz-Target", valid_611755
  var valid_611756 = header.getOrDefault("X-Amz-Signature")
  valid_611756 = validateParameter(valid_611756, JString, required = false,
                                 default = nil)
  if valid_611756 != nil:
    section.add "X-Amz-Signature", valid_611756
  var valid_611757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611757 = validateParameter(valid_611757, JString, required = false,
                                 default = nil)
  if valid_611757 != nil:
    section.add "X-Amz-Content-Sha256", valid_611757
  var valid_611758 = header.getOrDefault("X-Amz-Date")
  valid_611758 = validateParameter(valid_611758, JString, required = false,
                                 default = nil)
  if valid_611758 != nil:
    section.add "X-Amz-Date", valid_611758
  var valid_611759 = header.getOrDefault("X-Amz-Credential")
  valid_611759 = validateParameter(valid_611759, JString, required = false,
                                 default = nil)
  if valid_611759 != nil:
    section.add "X-Amz-Credential", valid_611759
  var valid_611760 = header.getOrDefault("X-Amz-Security-Token")
  valid_611760 = validateParameter(valid_611760, JString, required = false,
                                 default = nil)
  if valid_611760 != nil:
    section.add "X-Amz-Security-Token", valid_611760
  var valid_611761 = header.getOrDefault("X-Amz-Algorithm")
  valid_611761 = validateParameter(valid_611761, JString, required = false,
                                 default = nil)
  if valid_611761 != nil:
    section.add "X-Amz-Algorithm", valid_611761
  var valid_611762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611762 = validateParameter(valid_611762, JString, required = false,
                                 default = nil)
  if valid_611762 != nil:
    section.add "X-Amz-SignedHeaders", valid_611762
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611764: Call_CreateIdentityProvider_611752; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an identity provider for a user pool.
  ## 
  let valid = call_611764.validator(path, query, header, formData, body)
  let scheme = call_611764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611764.url(scheme.get, call_611764.host, call_611764.base,
                         call_611764.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611764, url, valid)

proc call*(call_611765: Call_CreateIdentityProvider_611752; body: JsonNode): Recallable =
  ## createIdentityProvider
  ## Creates an identity provider for a user pool.
  ##   body: JObject (required)
  var body_611766 = newJObject()
  if body != nil:
    body_611766 = body
  result = call_611765.call(nil, nil, nil, nil, body_611766)

var createIdentityProvider* = Call_CreateIdentityProvider_611752(
    name: "createIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateIdentityProvider",
    validator: validate_CreateIdentityProvider_611753, base: "/",
    url: url_CreateIdentityProvider_611754, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceServer_611767 = ref object of OpenApiRestCall_610658
proc url_CreateResourceServer_611769(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateResourceServer_611768(path: JsonNode; query: JsonNode;
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
  var valid_611770 = header.getOrDefault("X-Amz-Target")
  valid_611770 = validateParameter(valid_611770, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateResourceServer"))
  if valid_611770 != nil:
    section.add "X-Amz-Target", valid_611770
  var valid_611771 = header.getOrDefault("X-Amz-Signature")
  valid_611771 = validateParameter(valid_611771, JString, required = false,
                                 default = nil)
  if valid_611771 != nil:
    section.add "X-Amz-Signature", valid_611771
  var valid_611772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611772 = validateParameter(valid_611772, JString, required = false,
                                 default = nil)
  if valid_611772 != nil:
    section.add "X-Amz-Content-Sha256", valid_611772
  var valid_611773 = header.getOrDefault("X-Amz-Date")
  valid_611773 = validateParameter(valid_611773, JString, required = false,
                                 default = nil)
  if valid_611773 != nil:
    section.add "X-Amz-Date", valid_611773
  var valid_611774 = header.getOrDefault("X-Amz-Credential")
  valid_611774 = validateParameter(valid_611774, JString, required = false,
                                 default = nil)
  if valid_611774 != nil:
    section.add "X-Amz-Credential", valid_611774
  var valid_611775 = header.getOrDefault("X-Amz-Security-Token")
  valid_611775 = validateParameter(valid_611775, JString, required = false,
                                 default = nil)
  if valid_611775 != nil:
    section.add "X-Amz-Security-Token", valid_611775
  var valid_611776 = header.getOrDefault("X-Amz-Algorithm")
  valid_611776 = validateParameter(valid_611776, JString, required = false,
                                 default = nil)
  if valid_611776 != nil:
    section.add "X-Amz-Algorithm", valid_611776
  var valid_611777 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611777 = validateParameter(valid_611777, JString, required = false,
                                 default = nil)
  if valid_611777 != nil:
    section.add "X-Amz-SignedHeaders", valid_611777
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611779: Call_CreateResourceServer_611767; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new OAuth2.0 resource server and defines custom scopes in it.
  ## 
  let valid = call_611779.validator(path, query, header, formData, body)
  let scheme = call_611779.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611779.url(scheme.get, call_611779.host, call_611779.base,
                         call_611779.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611779, url, valid)

proc call*(call_611780: Call_CreateResourceServer_611767; body: JsonNode): Recallable =
  ## createResourceServer
  ## Creates a new OAuth2.0 resource server and defines custom scopes in it.
  ##   body: JObject (required)
  var body_611781 = newJObject()
  if body != nil:
    body_611781 = body
  result = call_611780.call(nil, nil, nil, nil, body_611781)

var createResourceServer* = Call_CreateResourceServer_611767(
    name: "createResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateResourceServer",
    validator: validate_CreateResourceServer_611768, base: "/",
    url: url_CreateResourceServer_611769, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserImportJob_611782 = ref object of OpenApiRestCall_610658
proc url_CreateUserImportJob_611784(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUserImportJob_611783(path: JsonNode; query: JsonNode;
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
  var valid_611785 = header.getOrDefault("X-Amz-Target")
  valid_611785 = validateParameter(valid_611785, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserImportJob"))
  if valid_611785 != nil:
    section.add "X-Amz-Target", valid_611785
  var valid_611786 = header.getOrDefault("X-Amz-Signature")
  valid_611786 = validateParameter(valid_611786, JString, required = false,
                                 default = nil)
  if valid_611786 != nil:
    section.add "X-Amz-Signature", valid_611786
  var valid_611787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611787 = validateParameter(valid_611787, JString, required = false,
                                 default = nil)
  if valid_611787 != nil:
    section.add "X-Amz-Content-Sha256", valid_611787
  var valid_611788 = header.getOrDefault("X-Amz-Date")
  valid_611788 = validateParameter(valid_611788, JString, required = false,
                                 default = nil)
  if valid_611788 != nil:
    section.add "X-Amz-Date", valid_611788
  var valid_611789 = header.getOrDefault("X-Amz-Credential")
  valid_611789 = validateParameter(valid_611789, JString, required = false,
                                 default = nil)
  if valid_611789 != nil:
    section.add "X-Amz-Credential", valid_611789
  var valid_611790 = header.getOrDefault("X-Amz-Security-Token")
  valid_611790 = validateParameter(valid_611790, JString, required = false,
                                 default = nil)
  if valid_611790 != nil:
    section.add "X-Amz-Security-Token", valid_611790
  var valid_611791 = header.getOrDefault("X-Amz-Algorithm")
  valid_611791 = validateParameter(valid_611791, JString, required = false,
                                 default = nil)
  if valid_611791 != nil:
    section.add "X-Amz-Algorithm", valid_611791
  var valid_611792 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611792 = validateParameter(valid_611792, JString, required = false,
                                 default = nil)
  if valid_611792 != nil:
    section.add "X-Amz-SignedHeaders", valid_611792
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611794: Call_CreateUserImportJob_611782; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates the user import job.
  ## 
  let valid = call_611794.validator(path, query, header, formData, body)
  let scheme = call_611794.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611794.url(scheme.get, call_611794.host, call_611794.base,
                         call_611794.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611794, url, valid)

proc call*(call_611795: Call_CreateUserImportJob_611782; body: JsonNode): Recallable =
  ## createUserImportJob
  ## Creates the user import job.
  ##   body: JObject (required)
  var body_611796 = newJObject()
  if body != nil:
    body_611796 = body
  result = call_611795.call(nil, nil, nil, nil, body_611796)

var createUserImportJob* = Call_CreateUserImportJob_611782(
    name: "createUserImportJob", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserImportJob",
    validator: validate_CreateUserImportJob_611783, base: "/",
    url: url_CreateUserImportJob_611784, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserPool_611797 = ref object of OpenApiRestCall_610658
proc url_CreateUserPool_611799(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUserPool_611798(path: JsonNode; query: JsonNode;
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
  var valid_611800 = header.getOrDefault("X-Amz-Target")
  valid_611800 = validateParameter(valid_611800, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserPool"))
  if valid_611800 != nil:
    section.add "X-Amz-Target", valid_611800
  var valid_611801 = header.getOrDefault("X-Amz-Signature")
  valid_611801 = validateParameter(valid_611801, JString, required = false,
                                 default = nil)
  if valid_611801 != nil:
    section.add "X-Amz-Signature", valid_611801
  var valid_611802 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611802 = validateParameter(valid_611802, JString, required = false,
                                 default = nil)
  if valid_611802 != nil:
    section.add "X-Amz-Content-Sha256", valid_611802
  var valid_611803 = header.getOrDefault("X-Amz-Date")
  valid_611803 = validateParameter(valid_611803, JString, required = false,
                                 default = nil)
  if valid_611803 != nil:
    section.add "X-Amz-Date", valid_611803
  var valid_611804 = header.getOrDefault("X-Amz-Credential")
  valid_611804 = validateParameter(valid_611804, JString, required = false,
                                 default = nil)
  if valid_611804 != nil:
    section.add "X-Amz-Credential", valid_611804
  var valid_611805 = header.getOrDefault("X-Amz-Security-Token")
  valid_611805 = validateParameter(valid_611805, JString, required = false,
                                 default = nil)
  if valid_611805 != nil:
    section.add "X-Amz-Security-Token", valid_611805
  var valid_611806 = header.getOrDefault("X-Amz-Algorithm")
  valid_611806 = validateParameter(valid_611806, JString, required = false,
                                 default = nil)
  if valid_611806 != nil:
    section.add "X-Amz-Algorithm", valid_611806
  var valid_611807 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611807 = validateParameter(valid_611807, JString, required = false,
                                 default = nil)
  if valid_611807 != nil:
    section.add "X-Amz-SignedHeaders", valid_611807
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611809: Call_CreateUserPool_611797; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon Cognito user pool and sets the password policy for the pool.
  ## 
  let valid = call_611809.validator(path, query, header, formData, body)
  let scheme = call_611809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611809.url(scheme.get, call_611809.host, call_611809.base,
                         call_611809.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611809, url, valid)

proc call*(call_611810: Call_CreateUserPool_611797; body: JsonNode): Recallable =
  ## createUserPool
  ## Creates a new Amazon Cognito user pool and sets the password policy for the pool.
  ##   body: JObject (required)
  var body_611811 = newJObject()
  if body != nil:
    body_611811 = body
  result = call_611810.call(nil, nil, nil, nil, body_611811)

var createUserPool* = Call_CreateUserPool_611797(name: "createUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserPool",
    validator: validate_CreateUserPool_611798, base: "/", url: url_CreateUserPool_611799,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserPoolClient_611812 = ref object of OpenApiRestCall_610658
proc url_CreateUserPoolClient_611814(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUserPoolClient_611813(path: JsonNode; query: JsonNode;
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
  var valid_611815 = header.getOrDefault("X-Amz-Target")
  valid_611815 = validateParameter(valid_611815, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserPoolClient"))
  if valid_611815 != nil:
    section.add "X-Amz-Target", valid_611815
  var valid_611816 = header.getOrDefault("X-Amz-Signature")
  valid_611816 = validateParameter(valid_611816, JString, required = false,
                                 default = nil)
  if valid_611816 != nil:
    section.add "X-Amz-Signature", valid_611816
  var valid_611817 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611817 = validateParameter(valid_611817, JString, required = false,
                                 default = nil)
  if valid_611817 != nil:
    section.add "X-Amz-Content-Sha256", valid_611817
  var valid_611818 = header.getOrDefault("X-Amz-Date")
  valid_611818 = validateParameter(valid_611818, JString, required = false,
                                 default = nil)
  if valid_611818 != nil:
    section.add "X-Amz-Date", valid_611818
  var valid_611819 = header.getOrDefault("X-Amz-Credential")
  valid_611819 = validateParameter(valid_611819, JString, required = false,
                                 default = nil)
  if valid_611819 != nil:
    section.add "X-Amz-Credential", valid_611819
  var valid_611820 = header.getOrDefault("X-Amz-Security-Token")
  valid_611820 = validateParameter(valid_611820, JString, required = false,
                                 default = nil)
  if valid_611820 != nil:
    section.add "X-Amz-Security-Token", valid_611820
  var valid_611821 = header.getOrDefault("X-Amz-Algorithm")
  valid_611821 = validateParameter(valid_611821, JString, required = false,
                                 default = nil)
  if valid_611821 != nil:
    section.add "X-Amz-Algorithm", valid_611821
  var valid_611822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611822 = validateParameter(valid_611822, JString, required = false,
                                 default = nil)
  if valid_611822 != nil:
    section.add "X-Amz-SignedHeaders", valid_611822
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611824: Call_CreateUserPoolClient_611812; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates the user pool client.
  ## 
  let valid = call_611824.validator(path, query, header, formData, body)
  let scheme = call_611824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611824.url(scheme.get, call_611824.host, call_611824.base,
                         call_611824.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611824, url, valid)

proc call*(call_611825: Call_CreateUserPoolClient_611812; body: JsonNode): Recallable =
  ## createUserPoolClient
  ## Creates the user pool client.
  ##   body: JObject (required)
  var body_611826 = newJObject()
  if body != nil:
    body_611826 = body
  result = call_611825.call(nil, nil, nil, nil, body_611826)

var createUserPoolClient* = Call_CreateUserPoolClient_611812(
    name: "createUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserPoolClient",
    validator: validate_CreateUserPoolClient_611813, base: "/",
    url: url_CreateUserPoolClient_611814, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserPoolDomain_611827 = ref object of OpenApiRestCall_610658
proc url_CreateUserPoolDomain_611829(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUserPoolDomain_611828(path: JsonNode; query: JsonNode;
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
  var valid_611830 = header.getOrDefault("X-Amz-Target")
  valid_611830 = validateParameter(valid_611830, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserPoolDomain"))
  if valid_611830 != nil:
    section.add "X-Amz-Target", valid_611830
  var valid_611831 = header.getOrDefault("X-Amz-Signature")
  valid_611831 = validateParameter(valid_611831, JString, required = false,
                                 default = nil)
  if valid_611831 != nil:
    section.add "X-Amz-Signature", valid_611831
  var valid_611832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611832 = validateParameter(valid_611832, JString, required = false,
                                 default = nil)
  if valid_611832 != nil:
    section.add "X-Amz-Content-Sha256", valid_611832
  var valid_611833 = header.getOrDefault("X-Amz-Date")
  valid_611833 = validateParameter(valid_611833, JString, required = false,
                                 default = nil)
  if valid_611833 != nil:
    section.add "X-Amz-Date", valid_611833
  var valid_611834 = header.getOrDefault("X-Amz-Credential")
  valid_611834 = validateParameter(valid_611834, JString, required = false,
                                 default = nil)
  if valid_611834 != nil:
    section.add "X-Amz-Credential", valid_611834
  var valid_611835 = header.getOrDefault("X-Amz-Security-Token")
  valid_611835 = validateParameter(valid_611835, JString, required = false,
                                 default = nil)
  if valid_611835 != nil:
    section.add "X-Amz-Security-Token", valid_611835
  var valid_611836 = header.getOrDefault("X-Amz-Algorithm")
  valid_611836 = validateParameter(valid_611836, JString, required = false,
                                 default = nil)
  if valid_611836 != nil:
    section.add "X-Amz-Algorithm", valid_611836
  var valid_611837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611837 = validateParameter(valid_611837, JString, required = false,
                                 default = nil)
  if valid_611837 != nil:
    section.add "X-Amz-SignedHeaders", valid_611837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611839: Call_CreateUserPoolDomain_611827; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new domain for a user pool.
  ## 
  let valid = call_611839.validator(path, query, header, formData, body)
  let scheme = call_611839.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611839.url(scheme.get, call_611839.host, call_611839.base,
                         call_611839.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611839, url, valid)

proc call*(call_611840: Call_CreateUserPoolDomain_611827; body: JsonNode): Recallable =
  ## createUserPoolDomain
  ## Creates a new domain for a user pool.
  ##   body: JObject (required)
  var body_611841 = newJObject()
  if body != nil:
    body_611841 = body
  result = call_611840.call(nil, nil, nil, nil, body_611841)

var createUserPoolDomain* = Call_CreateUserPoolDomain_611827(
    name: "createUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserPoolDomain",
    validator: validate_CreateUserPoolDomain_611828, base: "/",
    url: url_CreateUserPoolDomain_611829, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_611842 = ref object of OpenApiRestCall_610658
proc url_DeleteGroup_611844(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteGroup_611843(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611845 = header.getOrDefault("X-Amz-Target")
  valid_611845 = validateParameter(valid_611845, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteGroup"))
  if valid_611845 != nil:
    section.add "X-Amz-Target", valid_611845
  var valid_611846 = header.getOrDefault("X-Amz-Signature")
  valid_611846 = validateParameter(valid_611846, JString, required = false,
                                 default = nil)
  if valid_611846 != nil:
    section.add "X-Amz-Signature", valid_611846
  var valid_611847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611847 = validateParameter(valid_611847, JString, required = false,
                                 default = nil)
  if valid_611847 != nil:
    section.add "X-Amz-Content-Sha256", valid_611847
  var valid_611848 = header.getOrDefault("X-Amz-Date")
  valid_611848 = validateParameter(valid_611848, JString, required = false,
                                 default = nil)
  if valid_611848 != nil:
    section.add "X-Amz-Date", valid_611848
  var valid_611849 = header.getOrDefault("X-Amz-Credential")
  valid_611849 = validateParameter(valid_611849, JString, required = false,
                                 default = nil)
  if valid_611849 != nil:
    section.add "X-Amz-Credential", valid_611849
  var valid_611850 = header.getOrDefault("X-Amz-Security-Token")
  valid_611850 = validateParameter(valid_611850, JString, required = false,
                                 default = nil)
  if valid_611850 != nil:
    section.add "X-Amz-Security-Token", valid_611850
  var valid_611851 = header.getOrDefault("X-Amz-Algorithm")
  valid_611851 = validateParameter(valid_611851, JString, required = false,
                                 default = nil)
  if valid_611851 != nil:
    section.add "X-Amz-Algorithm", valid_611851
  var valid_611852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611852 = validateParameter(valid_611852, JString, required = false,
                                 default = nil)
  if valid_611852 != nil:
    section.add "X-Amz-SignedHeaders", valid_611852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611854: Call_DeleteGroup_611842; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a group. Currently only groups with no members can be deleted.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_611854.validator(path, query, header, formData, body)
  let scheme = call_611854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611854.url(scheme.get, call_611854.host, call_611854.base,
                         call_611854.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611854, url, valid)

proc call*(call_611855: Call_DeleteGroup_611842; body: JsonNode): Recallable =
  ## deleteGroup
  ## <p>Deletes a group. Currently only groups with no members can be deleted.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_611856 = newJObject()
  if body != nil:
    body_611856 = body
  result = call_611855.call(nil, nil, nil, nil, body_611856)

var deleteGroup* = Call_DeleteGroup_611842(name: "deleteGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteGroup",
                                        validator: validate_DeleteGroup_611843,
                                        base: "/", url: url_DeleteGroup_611844,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIdentityProvider_611857 = ref object of OpenApiRestCall_610658
proc url_DeleteIdentityProvider_611859(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteIdentityProvider_611858(path: JsonNode; query: JsonNode;
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
  var valid_611860 = header.getOrDefault("X-Amz-Target")
  valid_611860 = validateParameter(valid_611860, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteIdentityProvider"))
  if valid_611860 != nil:
    section.add "X-Amz-Target", valid_611860
  var valid_611861 = header.getOrDefault("X-Amz-Signature")
  valid_611861 = validateParameter(valid_611861, JString, required = false,
                                 default = nil)
  if valid_611861 != nil:
    section.add "X-Amz-Signature", valid_611861
  var valid_611862 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611862 = validateParameter(valid_611862, JString, required = false,
                                 default = nil)
  if valid_611862 != nil:
    section.add "X-Amz-Content-Sha256", valid_611862
  var valid_611863 = header.getOrDefault("X-Amz-Date")
  valid_611863 = validateParameter(valid_611863, JString, required = false,
                                 default = nil)
  if valid_611863 != nil:
    section.add "X-Amz-Date", valid_611863
  var valid_611864 = header.getOrDefault("X-Amz-Credential")
  valid_611864 = validateParameter(valid_611864, JString, required = false,
                                 default = nil)
  if valid_611864 != nil:
    section.add "X-Amz-Credential", valid_611864
  var valid_611865 = header.getOrDefault("X-Amz-Security-Token")
  valid_611865 = validateParameter(valid_611865, JString, required = false,
                                 default = nil)
  if valid_611865 != nil:
    section.add "X-Amz-Security-Token", valid_611865
  var valid_611866 = header.getOrDefault("X-Amz-Algorithm")
  valid_611866 = validateParameter(valid_611866, JString, required = false,
                                 default = nil)
  if valid_611866 != nil:
    section.add "X-Amz-Algorithm", valid_611866
  var valid_611867 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611867 = validateParameter(valid_611867, JString, required = false,
                                 default = nil)
  if valid_611867 != nil:
    section.add "X-Amz-SignedHeaders", valid_611867
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611869: Call_DeleteIdentityProvider_611857; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an identity provider for a user pool.
  ## 
  let valid = call_611869.validator(path, query, header, formData, body)
  let scheme = call_611869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611869.url(scheme.get, call_611869.host, call_611869.base,
                         call_611869.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611869, url, valid)

proc call*(call_611870: Call_DeleteIdentityProvider_611857; body: JsonNode): Recallable =
  ## deleteIdentityProvider
  ## Deletes an identity provider for a user pool.
  ##   body: JObject (required)
  var body_611871 = newJObject()
  if body != nil:
    body_611871 = body
  result = call_611870.call(nil, nil, nil, nil, body_611871)

var deleteIdentityProvider* = Call_DeleteIdentityProvider_611857(
    name: "deleteIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteIdentityProvider",
    validator: validate_DeleteIdentityProvider_611858, base: "/",
    url: url_DeleteIdentityProvider_611859, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceServer_611872 = ref object of OpenApiRestCall_610658
proc url_DeleteResourceServer_611874(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteResourceServer_611873(path: JsonNode; query: JsonNode;
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
  var valid_611875 = header.getOrDefault("X-Amz-Target")
  valid_611875 = validateParameter(valid_611875, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteResourceServer"))
  if valid_611875 != nil:
    section.add "X-Amz-Target", valid_611875
  var valid_611876 = header.getOrDefault("X-Amz-Signature")
  valid_611876 = validateParameter(valid_611876, JString, required = false,
                                 default = nil)
  if valid_611876 != nil:
    section.add "X-Amz-Signature", valid_611876
  var valid_611877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611877 = validateParameter(valid_611877, JString, required = false,
                                 default = nil)
  if valid_611877 != nil:
    section.add "X-Amz-Content-Sha256", valid_611877
  var valid_611878 = header.getOrDefault("X-Amz-Date")
  valid_611878 = validateParameter(valid_611878, JString, required = false,
                                 default = nil)
  if valid_611878 != nil:
    section.add "X-Amz-Date", valid_611878
  var valid_611879 = header.getOrDefault("X-Amz-Credential")
  valid_611879 = validateParameter(valid_611879, JString, required = false,
                                 default = nil)
  if valid_611879 != nil:
    section.add "X-Amz-Credential", valid_611879
  var valid_611880 = header.getOrDefault("X-Amz-Security-Token")
  valid_611880 = validateParameter(valid_611880, JString, required = false,
                                 default = nil)
  if valid_611880 != nil:
    section.add "X-Amz-Security-Token", valid_611880
  var valid_611881 = header.getOrDefault("X-Amz-Algorithm")
  valid_611881 = validateParameter(valid_611881, JString, required = false,
                                 default = nil)
  if valid_611881 != nil:
    section.add "X-Amz-Algorithm", valid_611881
  var valid_611882 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611882 = validateParameter(valid_611882, JString, required = false,
                                 default = nil)
  if valid_611882 != nil:
    section.add "X-Amz-SignedHeaders", valid_611882
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611884: Call_DeleteResourceServer_611872; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a resource server.
  ## 
  let valid = call_611884.validator(path, query, header, formData, body)
  let scheme = call_611884.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611884.url(scheme.get, call_611884.host, call_611884.base,
                         call_611884.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611884, url, valid)

proc call*(call_611885: Call_DeleteResourceServer_611872; body: JsonNode): Recallable =
  ## deleteResourceServer
  ## Deletes a resource server.
  ##   body: JObject (required)
  var body_611886 = newJObject()
  if body != nil:
    body_611886 = body
  result = call_611885.call(nil, nil, nil, nil, body_611886)

var deleteResourceServer* = Call_DeleteResourceServer_611872(
    name: "deleteResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteResourceServer",
    validator: validate_DeleteResourceServer_611873, base: "/",
    url: url_DeleteResourceServer_611874, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_611887 = ref object of OpenApiRestCall_610658
proc url_DeleteUser_611889(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUser_611888(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611890 = header.getOrDefault("X-Amz-Target")
  valid_611890 = validateParameter(valid_611890, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUser"))
  if valid_611890 != nil:
    section.add "X-Amz-Target", valid_611890
  var valid_611891 = header.getOrDefault("X-Amz-Signature")
  valid_611891 = validateParameter(valid_611891, JString, required = false,
                                 default = nil)
  if valid_611891 != nil:
    section.add "X-Amz-Signature", valid_611891
  var valid_611892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611892 = validateParameter(valid_611892, JString, required = false,
                                 default = nil)
  if valid_611892 != nil:
    section.add "X-Amz-Content-Sha256", valid_611892
  var valid_611893 = header.getOrDefault("X-Amz-Date")
  valid_611893 = validateParameter(valid_611893, JString, required = false,
                                 default = nil)
  if valid_611893 != nil:
    section.add "X-Amz-Date", valid_611893
  var valid_611894 = header.getOrDefault("X-Amz-Credential")
  valid_611894 = validateParameter(valid_611894, JString, required = false,
                                 default = nil)
  if valid_611894 != nil:
    section.add "X-Amz-Credential", valid_611894
  var valid_611895 = header.getOrDefault("X-Amz-Security-Token")
  valid_611895 = validateParameter(valid_611895, JString, required = false,
                                 default = nil)
  if valid_611895 != nil:
    section.add "X-Amz-Security-Token", valid_611895
  var valid_611896 = header.getOrDefault("X-Amz-Algorithm")
  valid_611896 = validateParameter(valid_611896, JString, required = false,
                                 default = nil)
  if valid_611896 != nil:
    section.add "X-Amz-Algorithm", valid_611896
  var valid_611897 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611897 = validateParameter(valid_611897, JString, required = false,
                                 default = nil)
  if valid_611897 != nil:
    section.add "X-Amz-SignedHeaders", valid_611897
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611899: Call_DeleteUser_611887; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a user to delete himself or herself.
  ## 
  let valid = call_611899.validator(path, query, header, formData, body)
  let scheme = call_611899.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611899.url(scheme.get, call_611899.host, call_611899.base,
                         call_611899.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611899, url, valid)

proc call*(call_611900: Call_DeleteUser_611887; body: JsonNode): Recallable =
  ## deleteUser
  ## Allows a user to delete himself or herself.
  ##   body: JObject (required)
  var body_611901 = newJObject()
  if body != nil:
    body_611901 = body
  result = call_611900.call(nil, nil, nil, nil, body_611901)

var deleteUser* = Call_DeleteUser_611887(name: "deleteUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUser",
                                      validator: validate_DeleteUser_611888,
                                      base: "/", url: url_DeleteUser_611889,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserAttributes_611902 = ref object of OpenApiRestCall_610658
proc url_DeleteUserAttributes_611904(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUserAttributes_611903(path: JsonNode; query: JsonNode;
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
  var valid_611905 = header.getOrDefault("X-Amz-Target")
  valid_611905 = validateParameter(valid_611905, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUserAttributes"))
  if valid_611905 != nil:
    section.add "X-Amz-Target", valid_611905
  var valid_611906 = header.getOrDefault("X-Amz-Signature")
  valid_611906 = validateParameter(valid_611906, JString, required = false,
                                 default = nil)
  if valid_611906 != nil:
    section.add "X-Amz-Signature", valid_611906
  var valid_611907 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611907 = validateParameter(valid_611907, JString, required = false,
                                 default = nil)
  if valid_611907 != nil:
    section.add "X-Amz-Content-Sha256", valid_611907
  var valid_611908 = header.getOrDefault("X-Amz-Date")
  valid_611908 = validateParameter(valid_611908, JString, required = false,
                                 default = nil)
  if valid_611908 != nil:
    section.add "X-Amz-Date", valid_611908
  var valid_611909 = header.getOrDefault("X-Amz-Credential")
  valid_611909 = validateParameter(valid_611909, JString, required = false,
                                 default = nil)
  if valid_611909 != nil:
    section.add "X-Amz-Credential", valid_611909
  var valid_611910 = header.getOrDefault("X-Amz-Security-Token")
  valid_611910 = validateParameter(valid_611910, JString, required = false,
                                 default = nil)
  if valid_611910 != nil:
    section.add "X-Amz-Security-Token", valid_611910
  var valid_611911 = header.getOrDefault("X-Amz-Algorithm")
  valid_611911 = validateParameter(valid_611911, JString, required = false,
                                 default = nil)
  if valid_611911 != nil:
    section.add "X-Amz-Algorithm", valid_611911
  var valid_611912 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611912 = validateParameter(valid_611912, JString, required = false,
                                 default = nil)
  if valid_611912 != nil:
    section.add "X-Amz-SignedHeaders", valid_611912
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611914: Call_DeleteUserAttributes_611902; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the attributes for a user.
  ## 
  let valid = call_611914.validator(path, query, header, formData, body)
  let scheme = call_611914.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611914.url(scheme.get, call_611914.host, call_611914.base,
                         call_611914.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611914, url, valid)

proc call*(call_611915: Call_DeleteUserAttributes_611902; body: JsonNode): Recallable =
  ## deleteUserAttributes
  ## Deletes the attributes for a user.
  ##   body: JObject (required)
  var body_611916 = newJObject()
  if body != nil:
    body_611916 = body
  result = call_611915.call(nil, nil, nil, nil, body_611916)

var deleteUserAttributes* = Call_DeleteUserAttributes_611902(
    name: "deleteUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserAttributes",
    validator: validate_DeleteUserAttributes_611903, base: "/",
    url: url_DeleteUserAttributes_611904, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserPool_611917 = ref object of OpenApiRestCall_610658
proc url_DeleteUserPool_611919(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUserPool_611918(path: JsonNode; query: JsonNode;
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
  var valid_611920 = header.getOrDefault("X-Amz-Target")
  valid_611920 = validateParameter(valid_611920, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUserPool"))
  if valid_611920 != nil:
    section.add "X-Amz-Target", valid_611920
  var valid_611921 = header.getOrDefault("X-Amz-Signature")
  valid_611921 = validateParameter(valid_611921, JString, required = false,
                                 default = nil)
  if valid_611921 != nil:
    section.add "X-Amz-Signature", valid_611921
  var valid_611922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611922 = validateParameter(valid_611922, JString, required = false,
                                 default = nil)
  if valid_611922 != nil:
    section.add "X-Amz-Content-Sha256", valid_611922
  var valid_611923 = header.getOrDefault("X-Amz-Date")
  valid_611923 = validateParameter(valid_611923, JString, required = false,
                                 default = nil)
  if valid_611923 != nil:
    section.add "X-Amz-Date", valid_611923
  var valid_611924 = header.getOrDefault("X-Amz-Credential")
  valid_611924 = validateParameter(valid_611924, JString, required = false,
                                 default = nil)
  if valid_611924 != nil:
    section.add "X-Amz-Credential", valid_611924
  var valid_611925 = header.getOrDefault("X-Amz-Security-Token")
  valid_611925 = validateParameter(valid_611925, JString, required = false,
                                 default = nil)
  if valid_611925 != nil:
    section.add "X-Amz-Security-Token", valid_611925
  var valid_611926 = header.getOrDefault("X-Amz-Algorithm")
  valid_611926 = validateParameter(valid_611926, JString, required = false,
                                 default = nil)
  if valid_611926 != nil:
    section.add "X-Amz-Algorithm", valid_611926
  var valid_611927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611927 = validateParameter(valid_611927, JString, required = false,
                                 default = nil)
  if valid_611927 != nil:
    section.add "X-Amz-SignedHeaders", valid_611927
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611929: Call_DeleteUserPool_611917; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Amazon Cognito user pool.
  ## 
  let valid = call_611929.validator(path, query, header, formData, body)
  let scheme = call_611929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611929.url(scheme.get, call_611929.host, call_611929.base,
                         call_611929.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611929, url, valid)

proc call*(call_611930: Call_DeleteUserPool_611917; body: JsonNode): Recallable =
  ## deleteUserPool
  ## Deletes the specified Amazon Cognito user pool.
  ##   body: JObject (required)
  var body_611931 = newJObject()
  if body != nil:
    body_611931 = body
  result = call_611930.call(nil, nil, nil, nil, body_611931)

var deleteUserPool* = Call_DeleteUserPool_611917(name: "deleteUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserPool",
    validator: validate_DeleteUserPool_611918, base: "/", url: url_DeleteUserPool_611919,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserPoolClient_611932 = ref object of OpenApiRestCall_610658
proc url_DeleteUserPoolClient_611934(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUserPoolClient_611933(path: JsonNode; query: JsonNode;
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
  var valid_611935 = header.getOrDefault("X-Amz-Target")
  valid_611935 = validateParameter(valid_611935, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUserPoolClient"))
  if valid_611935 != nil:
    section.add "X-Amz-Target", valid_611935
  var valid_611936 = header.getOrDefault("X-Amz-Signature")
  valid_611936 = validateParameter(valid_611936, JString, required = false,
                                 default = nil)
  if valid_611936 != nil:
    section.add "X-Amz-Signature", valid_611936
  var valid_611937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611937 = validateParameter(valid_611937, JString, required = false,
                                 default = nil)
  if valid_611937 != nil:
    section.add "X-Amz-Content-Sha256", valid_611937
  var valid_611938 = header.getOrDefault("X-Amz-Date")
  valid_611938 = validateParameter(valid_611938, JString, required = false,
                                 default = nil)
  if valid_611938 != nil:
    section.add "X-Amz-Date", valid_611938
  var valid_611939 = header.getOrDefault("X-Amz-Credential")
  valid_611939 = validateParameter(valid_611939, JString, required = false,
                                 default = nil)
  if valid_611939 != nil:
    section.add "X-Amz-Credential", valid_611939
  var valid_611940 = header.getOrDefault("X-Amz-Security-Token")
  valid_611940 = validateParameter(valid_611940, JString, required = false,
                                 default = nil)
  if valid_611940 != nil:
    section.add "X-Amz-Security-Token", valid_611940
  var valid_611941 = header.getOrDefault("X-Amz-Algorithm")
  valid_611941 = validateParameter(valid_611941, JString, required = false,
                                 default = nil)
  if valid_611941 != nil:
    section.add "X-Amz-Algorithm", valid_611941
  var valid_611942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611942 = validateParameter(valid_611942, JString, required = false,
                                 default = nil)
  if valid_611942 != nil:
    section.add "X-Amz-SignedHeaders", valid_611942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611944: Call_DeleteUserPoolClient_611932; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows the developer to delete the user pool client.
  ## 
  let valid = call_611944.validator(path, query, header, formData, body)
  let scheme = call_611944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611944.url(scheme.get, call_611944.host, call_611944.base,
                         call_611944.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611944, url, valid)

proc call*(call_611945: Call_DeleteUserPoolClient_611932; body: JsonNode): Recallable =
  ## deleteUserPoolClient
  ## Allows the developer to delete the user pool client.
  ##   body: JObject (required)
  var body_611946 = newJObject()
  if body != nil:
    body_611946 = body
  result = call_611945.call(nil, nil, nil, nil, body_611946)

var deleteUserPoolClient* = Call_DeleteUserPoolClient_611932(
    name: "deleteUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserPoolClient",
    validator: validate_DeleteUserPoolClient_611933, base: "/",
    url: url_DeleteUserPoolClient_611934, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserPoolDomain_611947 = ref object of OpenApiRestCall_610658
proc url_DeleteUserPoolDomain_611949(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUserPoolDomain_611948(path: JsonNode; query: JsonNode;
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
  var valid_611950 = header.getOrDefault("X-Amz-Target")
  valid_611950 = validateParameter(valid_611950, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUserPoolDomain"))
  if valid_611950 != nil:
    section.add "X-Amz-Target", valid_611950
  var valid_611951 = header.getOrDefault("X-Amz-Signature")
  valid_611951 = validateParameter(valid_611951, JString, required = false,
                                 default = nil)
  if valid_611951 != nil:
    section.add "X-Amz-Signature", valid_611951
  var valid_611952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611952 = validateParameter(valid_611952, JString, required = false,
                                 default = nil)
  if valid_611952 != nil:
    section.add "X-Amz-Content-Sha256", valid_611952
  var valid_611953 = header.getOrDefault("X-Amz-Date")
  valid_611953 = validateParameter(valid_611953, JString, required = false,
                                 default = nil)
  if valid_611953 != nil:
    section.add "X-Amz-Date", valid_611953
  var valid_611954 = header.getOrDefault("X-Amz-Credential")
  valid_611954 = validateParameter(valid_611954, JString, required = false,
                                 default = nil)
  if valid_611954 != nil:
    section.add "X-Amz-Credential", valid_611954
  var valid_611955 = header.getOrDefault("X-Amz-Security-Token")
  valid_611955 = validateParameter(valid_611955, JString, required = false,
                                 default = nil)
  if valid_611955 != nil:
    section.add "X-Amz-Security-Token", valid_611955
  var valid_611956 = header.getOrDefault("X-Amz-Algorithm")
  valid_611956 = validateParameter(valid_611956, JString, required = false,
                                 default = nil)
  if valid_611956 != nil:
    section.add "X-Amz-Algorithm", valid_611956
  var valid_611957 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611957 = validateParameter(valid_611957, JString, required = false,
                                 default = nil)
  if valid_611957 != nil:
    section.add "X-Amz-SignedHeaders", valid_611957
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611959: Call_DeleteUserPoolDomain_611947; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a domain for a user pool.
  ## 
  let valid = call_611959.validator(path, query, header, formData, body)
  let scheme = call_611959.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611959.url(scheme.get, call_611959.host, call_611959.base,
                         call_611959.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611959, url, valid)

proc call*(call_611960: Call_DeleteUserPoolDomain_611947; body: JsonNode): Recallable =
  ## deleteUserPoolDomain
  ## Deletes a domain for a user pool.
  ##   body: JObject (required)
  var body_611961 = newJObject()
  if body != nil:
    body_611961 = body
  result = call_611960.call(nil, nil, nil, nil, body_611961)

var deleteUserPoolDomain* = Call_DeleteUserPoolDomain_611947(
    name: "deleteUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserPoolDomain",
    validator: validate_DeleteUserPoolDomain_611948, base: "/",
    url: url_DeleteUserPoolDomain_611949, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentityProvider_611962 = ref object of OpenApiRestCall_610658
proc url_DescribeIdentityProvider_611964(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeIdentityProvider_611963(path: JsonNode; query: JsonNode;
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
  var valid_611965 = header.getOrDefault("X-Amz-Target")
  valid_611965 = validateParameter(valid_611965, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeIdentityProvider"))
  if valid_611965 != nil:
    section.add "X-Amz-Target", valid_611965
  var valid_611966 = header.getOrDefault("X-Amz-Signature")
  valid_611966 = validateParameter(valid_611966, JString, required = false,
                                 default = nil)
  if valid_611966 != nil:
    section.add "X-Amz-Signature", valid_611966
  var valid_611967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611967 = validateParameter(valid_611967, JString, required = false,
                                 default = nil)
  if valid_611967 != nil:
    section.add "X-Amz-Content-Sha256", valid_611967
  var valid_611968 = header.getOrDefault("X-Amz-Date")
  valid_611968 = validateParameter(valid_611968, JString, required = false,
                                 default = nil)
  if valid_611968 != nil:
    section.add "X-Amz-Date", valid_611968
  var valid_611969 = header.getOrDefault("X-Amz-Credential")
  valid_611969 = validateParameter(valid_611969, JString, required = false,
                                 default = nil)
  if valid_611969 != nil:
    section.add "X-Amz-Credential", valid_611969
  var valid_611970 = header.getOrDefault("X-Amz-Security-Token")
  valid_611970 = validateParameter(valid_611970, JString, required = false,
                                 default = nil)
  if valid_611970 != nil:
    section.add "X-Amz-Security-Token", valid_611970
  var valid_611971 = header.getOrDefault("X-Amz-Algorithm")
  valid_611971 = validateParameter(valid_611971, JString, required = false,
                                 default = nil)
  if valid_611971 != nil:
    section.add "X-Amz-Algorithm", valid_611971
  var valid_611972 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611972 = validateParameter(valid_611972, JString, required = false,
                                 default = nil)
  if valid_611972 != nil:
    section.add "X-Amz-SignedHeaders", valid_611972
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611974: Call_DescribeIdentityProvider_611962; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specific identity provider.
  ## 
  let valid = call_611974.validator(path, query, header, formData, body)
  let scheme = call_611974.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611974.url(scheme.get, call_611974.host, call_611974.base,
                         call_611974.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611974, url, valid)

proc call*(call_611975: Call_DescribeIdentityProvider_611962; body: JsonNode): Recallable =
  ## describeIdentityProvider
  ## Gets information about a specific identity provider.
  ##   body: JObject (required)
  var body_611976 = newJObject()
  if body != nil:
    body_611976 = body
  result = call_611975.call(nil, nil, nil, nil, body_611976)

var describeIdentityProvider* = Call_DescribeIdentityProvider_611962(
    name: "describeIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeIdentityProvider",
    validator: validate_DescribeIdentityProvider_611963, base: "/",
    url: url_DescribeIdentityProvider_611964, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResourceServer_611977 = ref object of OpenApiRestCall_610658
proc url_DescribeResourceServer_611979(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeResourceServer_611978(path: JsonNode; query: JsonNode;
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
  var valid_611980 = header.getOrDefault("X-Amz-Target")
  valid_611980 = validateParameter(valid_611980, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeResourceServer"))
  if valid_611980 != nil:
    section.add "X-Amz-Target", valid_611980
  var valid_611981 = header.getOrDefault("X-Amz-Signature")
  valid_611981 = validateParameter(valid_611981, JString, required = false,
                                 default = nil)
  if valid_611981 != nil:
    section.add "X-Amz-Signature", valid_611981
  var valid_611982 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611982 = validateParameter(valid_611982, JString, required = false,
                                 default = nil)
  if valid_611982 != nil:
    section.add "X-Amz-Content-Sha256", valid_611982
  var valid_611983 = header.getOrDefault("X-Amz-Date")
  valid_611983 = validateParameter(valid_611983, JString, required = false,
                                 default = nil)
  if valid_611983 != nil:
    section.add "X-Amz-Date", valid_611983
  var valid_611984 = header.getOrDefault("X-Amz-Credential")
  valid_611984 = validateParameter(valid_611984, JString, required = false,
                                 default = nil)
  if valid_611984 != nil:
    section.add "X-Amz-Credential", valid_611984
  var valid_611985 = header.getOrDefault("X-Amz-Security-Token")
  valid_611985 = validateParameter(valid_611985, JString, required = false,
                                 default = nil)
  if valid_611985 != nil:
    section.add "X-Amz-Security-Token", valid_611985
  var valid_611986 = header.getOrDefault("X-Amz-Algorithm")
  valid_611986 = validateParameter(valid_611986, JString, required = false,
                                 default = nil)
  if valid_611986 != nil:
    section.add "X-Amz-Algorithm", valid_611986
  var valid_611987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611987 = validateParameter(valid_611987, JString, required = false,
                                 default = nil)
  if valid_611987 != nil:
    section.add "X-Amz-SignedHeaders", valid_611987
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611989: Call_DescribeResourceServer_611977; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a resource server.
  ## 
  let valid = call_611989.validator(path, query, header, formData, body)
  let scheme = call_611989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611989.url(scheme.get, call_611989.host, call_611989.base,
                         call_611989.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611989, url, valid)

proc call*(call_611990: Call_DescribeResourceServer_611977; body: JsonNode): Recallable =
  ## describeResourceServer
  ## Describes a resource server.
  ##   body: JObject (required)
  var body_611991 = newJObject()
  if body != nil:
    body_611991 = body
  result = call_611990.call(nil, nil, nil, nil, body_611991)

var describeResourceServer* = Call_DescribeResourceServer_611977(
    name: "describeResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeResourceServer",
    validator: validate_DescribeResourceServer_611978, base: "/",
    url: url_DescribeResourceServer_611979, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRiskConfiguration_611992 = ref object of OpenApiRestCall_610658
proc url_DescribeRiskConfiguration_611994(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeRiskConfiguration_611993(path: JsonNode; query: JsonNode;
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
  var valid_611995 = header.getOrDefault("X-Amz-Target")
  valid_611995 = validateParameter(valid_611995, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeRiskConfiguration"))
  if valid_611995 != nil:
    section.add "X-Amz-Target", valid_611995
  var valid_611996 = header.getOrDefault("X-Amz-Signature")
  valid_611996 = validateParameter(valid_611996, JString, required = false,
                                 default = nil)
  if valid_611996 != nil:
    section.add "X-Amz-Signature", valid_611996
  var valid_611997 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611997 = validateParameter(valid_611997, JString, required = false,
                                 default = nil)
  if valid_611997 != nil:
    section.add "X-Amz-Content-Sha256", valid_611997
  var valid_611998 = header.getOrDefault("X-Amz-Date")
  valid_611998 = validateParameter(valid_611998, JString, required = false,
                                 default = nil)
  if valid_611998 != nil:
    section.add "X-Amz-Date", valid_611998
  var valid_611999 = header.getOrDefault("X-Amz-Credential")
  valid_611999 = validateParameter(valid_611999, JString, required = false,
                                 default = nil)
  if valid_611999 != nil:
    section.add "X-Amz-Credential", valid_611999
  var valid_612000 = header.getOrDefault("X-Amz-Security-Token")
  valid_612000 = validateParameter(valid_612000, JString, required = false,
                                 default = nil)
  if valid_612000 != nil:
    section.add "X-Amz-Security-Token", valid_612000
  var valid_612001 = header.getOrDefault("X-Amz-Algorithm")
  valid_612001 = validateParameter(valid_612001, JString, required = false,
                                 default = nil)
  if valid_612001 != nil:
    section.add "X-Amz-Algorithm", valid_612001
  var valid_612002 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612002 = validateParameter(valid_612002, JString, required = false,
                                 default = nil)
  if valid_612002 != nil:
    section.add "X-Amz-SignedHeaders", valid_612002
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612004: Call_DescribeRiskConfiguration_611992; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the risk configuration.
  ## 
  let valid = call_612004.validator(path, query, header, formData, body)
  let scheme = call_612004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612004.url(scheme.get, call_612004.host, call_612004.base,
                         call_612004.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612004, url, valid)

proc call*(call_612005: Call_DescribeRiskConfiguration_611992; body: JsonNode): Recallable =
  ## describeRiskConfiguration
  ## Describes the risk configuration.
  ##   body: JObject (required)
  var body_612006 = newJObject()
  if body != nil:
    body_612006 = body
  result = call_612005.call(nil, nil, nil, nil, body_612006)

var describeRiskConfiguration* = Call_DescribeRiskConfiguration_611992(
    name: "describeRiskConfiguration", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeRiskConfiguration",
    validator: validate_DescribeRiskConfiguration_611993, base: "/",
    url: url_DescribeRiskConfiguration_611994,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserImportJob_612007 = ref object of OpenApiRestCall_610658
proc url_DescribeUserImportJob_612009(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUserImportJob_612008(path: JsonNode; query: JsonNode;
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
  var valid_612010 = header.getOrDefault("X-Amz-Target")
  valid_612010 = validateParameter(valid_612010, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserImportJob"))
  if valid_612010 != nil:
    section.add "X-Amz-Target", valid_612010
  var valid_612011 = header.getOrDefault("X-Amz-Signature")
  valid_612011 = validateParameter(valid_612011, JString, required = false,
                                 default = nil)
  if valid_612011 != nil:
    section.add "X-Amz-Signature", valid_612011
  var valid_612012 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612012 = validateParameter(valid_612012, JString, required = false,
                                 default = nil)
  if valid_612012 != nil:
    section.add "X-Amz-Content-Sha256", valid_612012
  var valid_612013 = header.getOrDefault("X-Amz-Date")
  valid_612013 = validateParameter(valid_612013, JString, required = false,
                                 default = nil)
  if valid_612013 != nil:
    section.add "X-Amz-Date", valid_612013
  var valid_612014 = header.getOrDefault("X-Amz-Credential")
  valid_612014 = validateParameter(valid_612014, JString, required = false,
                                 default = nil)
  if valid_612014 != nil:
    section.add "X-Amz-Credential", valid_612014
  var valid_612015 = header.getOrDefault("X-Amz-Security-Token")
  valid_612015 = validateParameter(valid_612015, JString, required = false,
                                 default = nil)
  if valid_612015 != nil:
    section.add "X-Amz-Security-Token", valid_612015
  var valid_612016 = header.getOrDefault("X-Amz-Algorithm")
  valid_612016 = validateParameter(valid_612016, JString, required = false,
                                 default = nil)
  if valid_612016 != nil:
    section.add "X-Amz-Algorithm", valid_612016
  var valid_612017 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612017 = validateParameter(valid_612017, JString, required = false,
                                 default = nil)
  if valid_612017 != nil:
    section.add "X-Amz-SignedHeaders", valid_612017
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612019: Call_DescribeUserImportJob_612007; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the user import job.
  ## 
  let valid = call_612019.validator(path, query, header, formData, body)
  let scheme = call_612019.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612019.url(scheme.get, call_612019.host, call_612019.base,
                         call_612019.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612019, url, valid)

proc call*(call_612020: Call_DescribeUserImportJob_612007; body: JsonNode): Recallable =
  ## describeUserImportJob
  ## Describes the user import job.
  ##   body: JObject (required)
  var body_612021 = newJObject()
  if body != nil:
    body_612021 = body
  result = call_612020.call(nil, nil, nil, nil, body_612021)

var describeUserImportJob* = Call_DescribeUserImportJob_612007(
    name: "describeUserImportJob", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserImportJob",
    validator: validate_DescribeUserImportJob_612008, base: "/",
    url: url_DescribeUserImportJob_612009, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserPool_612022 = ref object of OpenApiRestCall_610658
proc url_DescribeUserPool_612024(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUserPool_612023(path: JsonNode; query: JsonNode;
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
  var valid_612025 = header.getOrDefault("X-Amz-Target")
  valid_612025 = validateParameter(valid_612025, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserPool"))
  if valid_612025 != nil:
    section.add "X-Amz-Target", valid_612025
  var valid_612026 = header.getOrDefault("X-Amz-Signature")
  valid_612026 = validateParameter(valid_612026, JString, required = false,
                                 default = nil)
  if valid_612026 != nil:
    section.add "X-Amz-Signature", valid_612026
  var valid_612027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612027 = validateParameter(valid_612027, JString, required = false,
                                 default = nil)
  if valid_612027 != nil:
    section.add "X-Amz-Content-Sha256", valid_612027
  var valid_612028 = header.getOrDefault("X-Amz-Date")
  valid_612028 = validateParameter(valid_612028, JString, required = false,
                                 default = nil)
  if valid_612028 != nil:
    section.add "X-Amz-Date", valid_612028
  var valid_612029 = header.getOrDefault("X-Amz-Credential")
  valid_612029 = validateParameter(valid_612029, JString, required = false,
                                 default = nil)
  if valid_612029 != nil:
    section.add "X-Amz-Credential", valid_612029
  var valid_612030 = header.getOrDefault("X-Amz-Security-Token")
  valid_612030 = validateParameter(valid_612030, JString, required = false,
                                 default = nil)
  if valid_612030 != nil:
    section.add "X-Amz-Security-Token", valid_612030
  var valid_612031 = header.getOrDefault("X-Amz-Algorithm")
  valid_612031 = validateParameter(valid_612031, JString, required = false,
                                 default = nil)
  if valid_612031 != nil:
    section.add "X-Amz-Algorithm", valid_612031
  var valid_612032 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612032 = validateParameter(valid_612032, JString, required = false,
                                 default = nil)
  if valid_612032 != nil:
    section.add "X-Amz-SignedHeaders", valid_612032
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612034: Call_DescribeUserPool_612022; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the configuration information and metadata of the specified user pool.
  ## 
  let valid = call_612034.validator(path, query, header, formData, body)
  let scheme = call_612034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612034.url(scheme.get, call_612034.host, call_612034.base,
                         call_612034.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612034, url, valid)

proc call*(call_612035: Call_DescribeUserPool_612022; body: JsonNode): Recallable =
  ## describeUserPool
  ## Returns the configuration information and metadata of the specified user pool.
  ##   body: JObject (required)
  var body_612036 = newJObject()
  if body != nil:
    body_612036 = body
  result = call_612035.call(nil, nil, nil, nil, body_612036)

var describeUserPool* = Call_DescribeUserPool_612022(name: "describeUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserPool",
    validator: validate_DescribeUserPool_612023, base: "/",
    url: url_DescribeUserPool_612024, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserPoolClient_612037 = ref object of OpenApiRestCall_610658
proc url_DescribeUserPoolClient_612039(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUserPoolClient_612038(path: JsonNode; query: JsonNode;
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
  var valid_612040 = header.getOrDefault("X-Amz-Target")
  valid_612040 = validateParameter(valid_612040, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserPoolClient"))
  if valid_612040 != nil:
    section.add "X-Amz-Target", valid_612040
  var valid_612041 = header.getOrDefault("X-Amz-Signature")
  valid_612041 = validateParameter(valid_612041, JString, required = false,
                                 default = nil)
  if valid_612041 != nil:
    section.add "X-Amz-Signature", valid_612041
  var valid_612042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612042 = validateParameter(valid_612042, JString, required = false,
                                 default = nil)
  if valid_612042 != nil:
    section.add "X-Amz-Content-Sha256", valid_612042
  var valid_612043 = header.getOrDefault("X-Amz-Date")
  valid_612043 = validateParameter(valid_612043, JString, required = false,
                                 default = nil)
  if valid_612043 != nil:
    section.add "X-Amz-Date", valid_612043
  var valid_612044 = header.getOrDefault("X-Amz-Credential")
  valid_612044 = validateParameter(valid_612044, JString, required = false,
                                 default = nil)
  if valid_612044 != nil:
    section.add "X-Amz-Credential", valid_612044
  var valid_612045 = header.getOrDefault("X-Amz-Security-Token")
  valid_612045 = validateParameter(valid_612045, JString, required = false,
                                 default = nil)
  if valid_612045 != nil:
    section.add "X-Amz-Security-Token", valid_612045
  var valid_612046 = header.getOrDefault("X-Amz-Algorithm")
  valid_612046 = validateParameter(valid_612046, JString, required = false,
                                 default = nil)
  if valid_612046 != nil:
    section.add "X-Amz-Algorithm", valid_612046
  var valid_612047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612047 = validateParameter(valid_612047, JString, required = false,
                                 default = nil)
  if valid_612047 != nil:
    section.add "X-Amz-SignedHeaders", valid_612047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612049: Call_DescribeUserPoolClient_612037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Client method for returning the configuration information and metadata of the specified user pool app client.
  ## 
  let valid = call_612049.validator(path, query, header, formData, body)
  let scheme = call_612049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612049.url(scheme.get, call_612049.host, call_612049.base,
                         call_612049.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612049, url, valid)

proc call*(call_612050: Call_DescribeUserPoolClient_612037; body: JsonNode): Recallable =
  ## describeUserPoolClient
  ## Client method for returning the configuration information and metadata of the specified user pool app client.
  ##   body: JObject (required)
  var body_612051 = newJObject()
  if body != nil:
    body_612051 = body
  result = call_612050.call(nil, nil, nil, nil, body_612051)

var describeUserPoolClient* = Call_DescribeUserPoolClient_612037(
    name: "describeUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserPoolClient",
    validator: validate_DescribeUserPoolClient_612038, base: "/",
    url: url_DescribeUserPoolClient_612039, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserPoolDomain_612052 = ref object of OpenApiRestCall_610658
proc url_DescribeUserPoolDomain_612054(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUserPoolDomain_612053(path: JsonNode; query: JsonNode;
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
  var valid_612055 = header.getOrDefault("X-Amz-Target")
  valid_612055 = validateParameter(valid_612055, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserPoolDomain"))
  if valid_612055 != nil:
    section.add "X-Amz-Target", valid_612055
  var valid_612056 = header.getOrDefault("X-Amz-Signature")
  valid_612056 = validateParameter(valid_612056, JString, required = false,
                                 default = nil)
  if valid_612056 != nil:
    section.add "X-Amz-Signature", valid_612056
  var valid_612057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612057 = validateParameter(valid_612057, JString, required = false,
                                 default = nil)
  if valid_612057 != nil:
    section.add "X-Amz-Content-Sha256", valid_612057
  var valid_612058 = header.getOrDefault("X-Amz-Date")
  valid_612058 = validateParameter(valid_612058, JString, required = false,
                                 default = nil)
  if valid_612058 != nil:
    section.add "X-Amz-Date", valid_612058
  var valid_612059 = header.getOrDefault("X-Amz-Credential")
  valid_612059 = validateParameter(valid_612059, JString, required = false,
                                 default = nil)
  if valid_612059 != nil:
    section.add "X-Amz-Credential", valid_612059
  var valid_612060 = header.getOrDefault("X-Amz-Security-Token")
  valid_612060 = validateParameter(valid_612060, JString, required = false,
                                 default = nil)
  if valid_612060 != nil:
    section.add "X-Amz-Security-Token", valid_612060
  var valid_612061 = header.getOrDefault("X-Amz-Algorithm")
  valid_612061 = validateParameter(valid_612061, JString, required = false,
                                 default = nil)
  if valid_612061 != nil:
    section.add "X-Amz-Algorithm", valid_612061
  var valid_612062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612062 = validateParameter(valid_612062, JString, required = false,
                                 default = nil)
  if valid_612062 != nil:
    section.add "X-Amz-SignedHeaders", valid_612062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612064: Call_DescribeUserPoolDomain_612052; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a domain.
  ## 
  let valid = call_612064.validator(path, query, header, formData, body)
  let scheme = call_612064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612064.url(scheme.get, call_612064.host, call_612064.base,
                         call_612064.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612064, url, valid)

proc call*(call_612065: Call_DescribeUserPoolDomain_612052; body: JsonNode): Recallable =
  ## describeUserPoolDomain
  ## Gets information about a domain.
  ##   body: JObject (required)
  var body_612066 = newJObject()
  if body != nil:
    body_612066 = body
  result = call_612065.call(nil, nil, nil, nil, body_612066)

var describeUserPoolDomain* = Call_DescribeUserPoolDomain_612052(
    name: "describeUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserPoolDomain",
    validator: validate_DescribeUserPoolDomain_612053, base: "/",
    url: url_DescribeUserPoolDomain_612054, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ForgetDevice_612067 = ref object of OpenApiRestCall_610658
proc url_ForgetDevice_612069(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ForgetDevice_612068(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612070 = header.getOrDefault("X-Amz-Target")
  valid_612070 = validateParameter(valid_612070, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ForgetDevice"))
  if valid_612070 != nil:
    section.add "X-Amz-Target", valid_612070
  var valid_612071 = header.getOrDefault("X-Amz-Signature")
  valid_612071 = validateParameter(valid_612071, JString, required = false,
                                 default = nil)
  if valid_612071 != nil:
    section.add "X-Amz-Signature", valid_612071
  var valid_612072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612072 = validateParameter(valid_612072, JString, required = false,
                                 default = nil)
  if valid_612072 != nil:
    section.add "X-Amz-Content-Sha256", valid_612072
  var valid_612073 = header.getOrDefault("X-Amz-Date")
  valid_612073 = validateParameter(valid_612073, JString, required = false,
                                 default = nil)
  if valid_612073 != nil:
    section.add "X-Amz-Date", valid_612073
  var valid_612074 = header.getOrDefault("X-Amz-Credential")
  valid_612074 = validateParameter(valid_612074, JString, required = false,
                                 default = nil)
  if valid_612074 != nil:
    section.add "X-Amz-Credential", valid_612074
  var valid_612075 = header.getOrDefault("X-Amz-Security-Token")
  valid_612075 = validateParameter(valid_612075, JString, required = false,
                                 default = nil)
  if valid_612075 != nil:
    section.add "X-Amz-Security-Token", valid_612075
  var valid_612076 = header.getOrDefault("X-Amz-Algorithm")
  valid_612076 = validateParameter(valid_612076, JString, required = false,
                                 default = nil)
  if valid_612076 != nil:
    section.add "X-Amz-Algorithm", valid_612076
  var valid_612077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612077 = validateParameter(valid_612077, JString, required = false,
                                 default = nil)
  if valid_612077 != nil:
    section.add "X-Amz-SignedHeaders", valid_612077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612079: Call_ForgetDevice_612067; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Forgets the specified device.
  ## 
  let valid = call_612079.validator(path, query, header, formData, body)
  let scheme = call_612079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612079.url(scheme.get, call_612079.host, call_612079.base,
                         call_612079.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612079, url, valid)

proc call*(call_612080: Call_ForgetDevice_612067; body: JsonNode): Recallable =
  ## forgetDevice
  ## Forgets the specified device.
  ##   body: JObject (required)
  var body_612081 = newJObject()
  if body != nil:
    body_612081 = body
  result = call_612080.call(nil, nil, nil, nil, body_612081)

var forgetDevice* = Call_ForgetDevice_612067(name: "forgetDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ForgetDevice",
    validator: validate_ForgetDevice_612068, base: "/", url: url_ForgetDevice_612069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ForgotPassword_612082 = ref object of OpenApiRestCall_610658
proc url_ForgotPassword_612084(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ForgotPassword_612083(path: JsonNode; query: JsonNode;
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
  var valid_612085 = header.getOrDefault("X-Amz-Target")
  valid_612085 = validateParameter(valid_612085, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ForgotPassword"))
  if valid_612085 != nil:
    section.add "X-Amz-Target", valid_612085
  var valid_612086 = header.getOrDefault("X-Amz-Signature")
  valid_612086 = validateParameter(valid_612086, JString, required = false,
                                 default = nil)
  if valid_612086 != nil:
    section.add "X-Amz-Signature", valid_612086
  var valid_612087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612087 = validateParameter(valid_612087, JString, required = false,
                                 default = nil)
  if valid_612087 != nil:
    section.add "X-Amz-Content-Sha256", valid_612087
  var valid_612088 = header.getOrDefault("X-Amz-Date")
  valid_612088 = validateParameter(valid_612088, JString, required = false,
                                 default = nil)
  if valid_612088 != nil:
    section.add "X-Amz-Date", valid_612088
  var valid_612089 = header.getOrDefault("X-Amz-Credential")
  valid_612089 = validateParameter(valid_612089, JString, required = false,
                                 default = nil)
  if valid_612089 != nil:
    section.add "X-Amz-Credential", valid_612089
  var valid_612090 = header.getOrDefault("X-Amz-Security-Token")
  valid_612090 = validateParameter(valid_612090, JString, required = false,
                                 default = nil)
  if valid_612090 != nil:
    section.add "X-Amz-Security-Token", valid_612090
  var valid_612091 = header.getOrDefault("X-Amz-Algorithm")
  valid_612091 = validateParameter(valid_612091, JString, required = false,
                                 default = nil)
  if valid_612091 != nil:
    section.add "X-Amz-Algorithm", valid_612091
  var valid_612092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612092 = validateParameter(valid_612092, JString, required = false,
                                 default = nil)
  if valid_612092 != nil:
    section.add "X-Amz-SignedHeaders", valid_612092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612094: Call_ForgotPassword_612082; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Calling this API causes a message to be sent to the end user with a confirmation code that is required to change the user's password. For the <code>Username</code> parameter, you can use the username or user alias. If a verified phone number exists for the user, the confirmation code is sent to the phone number. Otherwise, if a verified email exists, the confirmation code is sent to the email. If neither a verified phone number nor a verified email exists, <code>InvalidParameterException</code> is thrown. To use the confirmation code for resetting the password, call .
  ## 
  let valid = call_612094.validator(path, query, header, formData, body)
  let scheme = call_612094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612094.url(scheme.get, call_612094.host, call_612094.base,
                         call_612094.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612094, url, valid)

proc call*(call_612095: Call_ForgotPassword_612082; body: JsonNode): Recallable =
  ## forgotPassword
  ## Calling this API causes a message to be sent to the end user with a confirmation code that is required to change the user's password. For the <code>Username</code> parameter, you can use the username or user alias. If a verified phone number exists for the user, the confirmation code is sent to the phone number. Otherwise, if a verified email exists, the confirmation code is sent to the email. If neither a verified phone number nor a verified email exists, <code>InvalidParameterException</code> is thrown. To use the confirmation code for resetting the password, call .
  ##   body: JObject (required)
  var body_612096 = newJObject()
  if body != nil:
    body_612096 = body
  result = call_612095.call(nil, nil, nil, nil, body_612096)

var forgotPassword* = Call_ForgotPassword_612082(name: "forgotPassword",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ForgotPassword",
    validator: validate_ForgotPassword_612083, base: "/", url: url_ForgotPassword_612084,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCSVHeader_612097 = ref object of OpenApiRestCall_610658
proc url_GetCSVHeader_612099(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCSVHeader_612098(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612100 = header.getOrDefault("X-Amz-Target")
  valid_612100 = validateParameter(valid_612100, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetCSVHeader"))
  if valid_612100 != nil:
    section.add "X-Amz-Target", valid_612100
  var valid_612101 = header.getOrDefault("X-Amz-Signature")
  valid_612101 = validateParameter(valid_612101, JString, required = false,
                                 default = nil)
  if valid_612101 != nil:
    section.add "X-Amz-Signature", valid_612101
  var valid_612102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612102 = validateParameter(valid_612102, JString, required = false,
                                 default = nil)
  if valid_612102 != nil:
    section.add "X-Amz-Content-Sha256", valid_612102
  var valid_612103 = header.getOrDefault("X-Amz-Date")
  valid_612103 = validateParameter(valid_612103, JString, required = false,
                                 default = nil)
  if valid_612103 != nil:
    section.add "X-Amz-Date", valid_612103
  var valid_612104 = header.getOrDefault("X-Amz-Credential")
  valid_612104 = validateParameter(valid_612104, JString, required = false,
                                 default = nil)
  if valid_612104 != nil:
    section.add "X-Amz-Credential", valid_612104
  var valid_612105 = header.getOrDefault("X-Amz-Security-Token")
  valid_612105 = validateParameter(valid_612105, JString, required = false,
                                 default = nil)
  if valid_612105 != nil:
    section.add "X-Amz-Security-Token", valid_612105
  var valid_612106 = header.getOrDefault("X-Amz-Algorithm")
  valid_612106 = validateParameter(valid_612106, JString, required = false,
                                 default = nil)
  if valid_612106 != nil:
    section.add "X-Amz-Algorithm", valid_612106
  var valid_612107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612107 = validateParameter(valid_612107, JString, required = false,
                                 default = nil)
  if valid_612107 != nil:
    section.add "X-Amz-SignedHeaders", valid_612107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612109: Call_GetCSVHeader_612097; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the header information for the .csv file to be used as input for the user import job.
  ## 
  let valid = call_612109.validator(path, query, header, formData, body)
  let scheme = call_612109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612109.url(scheme.get, call_612109.host, call_612109.base,
                         call_612109.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612109, url, valid)

proc call*(call_612110: Call_GetCSVHeader_612097; body: JsonNode): Recallable =
  ## getCSVHeader
  ## Gets the header information for the .csv file to be used as input for the user import job.
  ##   body: JObject (required)
  var body_612111 = newJObject()
  if body != nil:
    body_612111 = body
  result = call_612110.call(nil, nil, nil, nil, body_612111)

var getCSVHeader* = Call_GetCSVHeader_612097(name: "getCSVHeader",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetCSVHeader",
    validator: validate_GetCSVHeader_612098, base: "/", url: url_GetCSVHeader_612099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevice_612112 = ref object of OpenApiRestCall_610658
proc url_GetDevice_612114(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevice_612113(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612115 = header.getOrDefault("X-Amz-Target")
  valid_612115 = validateParameter(valid_612115, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetDevice"))
  if valid_612115 != nil:
    section.add "X-Amz-Target", valid_612115
  var valid_612116 = header.getOrDefault("X-Amz-Signature")
  valid_612116 = validateParameter(valid_612116, JString, required = false,
                                 default = nil)
  if valid_612116 != nil:
    section.add "X-Amz-Signature", valid_612116
  var valid_612117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612117 = validateParameter(valid_612117, JString, required = false,
                                 default = nil)
  if valid_612117 != nil:
    section.add "X-Amz-Content-Sha256", valid_612117
  var valid_612118 = header.getOrDefault("X-Amz-Date")
  valid_612118 = validateParameter(valid_612118, JString, required = false,
                                 default = nil)
  if valid_612118 != nil:
    section.add "X-Amz-Date", valid_612118
  var valid_612119 = header.getOrDefault("X-Amz-Credential")
  valid_612119 = validateParameter(valid_612119, JString, required = false,
                                 default = nil)
  if valid_612119 != nil:
    section.add "X-Amz-Credential", valid_612119
  var valid_612120 = header.getOrDefault("X-Amz-Security-Token")
  valid_612120 = validateParameter(valid_612120, JString, required = false,
                                 default = nil)
  if valid_612120 != nil:
    section.add "X-Amz-Security-Token", valid_612120
  var valid_612121 = header.getOrDefault("X-Amz-Algorithm")
  valid_612121 = validateParameter(valid_612121, JString, required = false,
                                 default = nil)
  if valid_612121 != nil:
    section.add "X-Amz-Algorithm", valid_612121
  var valid_612122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612122 = validateParameter(valid_612122, JString, required = false,
                                 default = nil)
  if valid_612122 != nil:
    section.add "X-Amz-SignedHeaders", valid_612122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612124: Call_GetDevice_612112; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the device.
  ## 
  let valid = call_612124.validator(path, query, header, formData, body)
  let scheme = call_612124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612124.url(scheme.get, call_612124.host, call_612124.base,
                         call_612124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612124, url, valid)

proc call*(call_612125: Call_GetDevice_612112; body: JsonNode): Recallable =
  ## getDevice
  ## Gets the device.
  ##   body: JObject (required)
  var body_612126 = newJObject()
  if body != nil:
    body_612126 = body
  result = call_612125.call(nil, nil, nil, nil, body_612126)

var getDevice* = Call_GetDevice_612112(name: "getDevice", meth: HttpMethod.HttpPost,
                                    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetDevice",
                                    validator: validate_GetDevice_612113,
                                    base: "/", url: url_GetDevice_612114,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroup_612127 = ref object of OpenApiRestCall_610658
proc url_GetGroup_612129(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGroup_612128(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612130 = header.getOrDefault("X-Amz-Target")
  valid_612130 = validateParameter(valid_612130, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetGroup"))
  if valid_612130 != nil:
    section.add "X-Amz-Target", valid_612130
  var valid_612131 = header.getOrDefault("X-Amz-Signature")
  valid_612131 = validateParameter(valid_612131, JString, required = false,
                                 default = nil)
  if valid_612131 != nil:
    section.add "X-Amz-Signature", valid_612131
  var valid_612132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612132 = validateParameter(valid_612132, JString, required = false,
                                 default = nil)
  if valid_612132 != nil:
    section.add "X-Amz-Content-Sha256", valid_612132
  var valid_612133 = header.getOrDefault("X-Amz-Date")
  valid_612133 = validateParameter(valid_612133, JString, required = false,
                                 default = nil)
  if valid_612133 != nil:
    section.add "X-Amz-Date", valid_612133
  var valid_612134 = header.getOrDefault("X-Amz-Credential")
  valid_612134 = validateParameter(valid_612134, JString, required = false,
                                 default = nil)
  if valid_612134 != nil:
    section.add "X-Amz-Credential", valid_612134
  var valid_612135 = header.getOrDefault("X-Amz-Security-Token")
  valid_612135 = validateParameter(valid_612135, JString, required = false,
                                 default = nil)
  if valid_612135 != nil:
    section.add "X-Amz-Security-Token", valid_612135
  var valid_612136 = header.getOrDefault("X-Amz-Algorithm")
  valid_612136 = validateParameter(valid_612136, JString, required = false,
                                 default = nil)
  if valid_612136 != nil:
    section.add "X-Amz-Algorithm", valid_612136
  var valid_612137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612137 = validateParameter(valid_612137, JString, required = false,
                                 default = nil)
  if valid_612137 != nil:
    section.add "X-Amz-SignedHeaders", valid_612137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612139: Call_GetGroup_612127; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a group.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_612139.validator(path, query, header, formData, body)
  let scheme = call_612139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612139.url(scheme.get, call_612139.host, call_612139.base,
                         call_612139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612139, url, valid)

proc call*(call_612140: Call_GetGroup_612127; body: JsonNode): Recallable =
  ## getGroup
  ## <p>Gets a group.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_612141 = newJObject()
  if body != nil:
    body_612141 = body
  result = call_612140.call(nil, nil, nil, nil, body_612141)

var getGroup* = Call_GetGroup_612127(name: "getGroup", meth: HttpMethod.HttpPost,
                                  host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetGroup",
                                  validator: validate_GetGroup_612128, base: "/",
                                  url: url_GetGroup_612129,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIdentityProviderByIdentifier_612142 = ref object of OpenApiRestCall_610658
proc url_GetIdentityProviderByIdentifier_612144(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetIdentityProviderByIdentifier_612143(path: JsonNode;
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
  var valid_612145 = header.getOrDefault("X-Amz-Target")
  valid_612145 = validateParameter(valid_612145, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetIdentityProviderByIdentifier"))
  if valid_612145 != nil:
    section.add "X-Amz-Target", valid_612145
  var valid_612146 = header.getOrDefault("X-Amz-Signature")
  valid_612146 = validateParameter(valid_612146, JString, required = false,
                                 default = nil)
  if valid_612146 != nil:
    section.add "X-Amz-Signature", valid_612146
  var valid_612147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612147 = validateParameter(valid_612147, JString, required = false,
                                 default = nil)
  if valid_612147 != nil:
    section.add "X-Amz-Content-Sha256", valid_612147
  var valid_612148 = header.getOrDefault("X-Amz-Date")
  valid_612148 = validateParameter(valid_612148, JString, required = false,
                                 default = nil)
  if valid_612148 != nil:
    section.add "X-Amz-Date", valid_612148
  var valid_612149 = header.getOrDefault("X-Amz-Credential")
  valid_612149 = validateParameter(valid_612149, JString, required = false,
                                 default = nil)
  if valid_612149 != nil:
    section.add "X-Amz-Credential", valid_612149
  var valid_612150 = header.getOrDefault("X-Amz-Security-Token")
  valid_612150 = validateParameter(valid_612150, JString, required = false,
                                 default = nil)
  if valid_612150 != nil:
    section.add "X-Amz-Security-Token", valid_612150
  var valid_612151 = header.getOrDefault("X-Amz-Algorithm")
  valid_612151 = validateParameter(valid_612151, JString, required = false,
                                 default = nil)
  if valid_612151 != nil:
    section.add "X-Amz-Algorithm", valid_612151
  var valid_612152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612152 = validateParameter(valid_612152, JString, required = false,
                                 default = nil)
  if valid_612152 != nil:
    section.add "X-Amz-SignedHeaders", valid_612152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612154: Call_GetIdentityProviderByIdentifier_612142;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the specified identity provider.
  ## 
  let valid = call_612154.validator(path, query, header, formData, body)
  let scheme = call_612154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612154.url(scheme.get, call_612154.host, call_612154.base,
                         call_612154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612154, url, valid)

proc call*(call_612155: Call_GetIdentityProviderByIdentifier_612142; body: JsonNode): Recallable =
  ## getIdentityProviderByIdentifier
  ## Gets the specified identity provider.
  ##   body: JObject (required)
  var body_612156 = newJObject()
  if body != nil:
    body_612156 = body
  result = call_612155.call(nil, nil, nil, nil, body_612156)

var getIdentityProviderByIdentifier* = Call_GetIdentityProviderByIdentifier_612142(
    name: "getIdentityProviderByIdentifier", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetIdentityProviderByIdentifier",
    validator: validate_GetIdentityProviderByIdentifier_612143, base: "/",
    url: url_GetIdentityProviderByIdentifier_612144,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSigningCertificate_612157 = ref object of OpenApiRestCall_610658
proc url_GetSigningCertificate_612159(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSigningCertificate_612158(path: JsonNode; query: JsonNode;
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
  var valid_612160 = header.getOrDefault("X-Amz-Target")
  valid_612160 = validateParameter(valid_612160, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetSigningCertificate"))
  if valid_612160 != nil:
    section.add "X-Amz-Target", valid_612160
  var valid_612161 = header.getOrDefault("X-Amz-Signature")
  valid_612161 = validateParameter(valid_612161, JString, required = false,
                                 default = nil)
  if valid_612161 != nil:
    section.add "X-Amz-Signature", valid_612161
  var valid_612162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612162 = validateParameter(valid_612162, JString, required = false,
                                 default = nil)
  if valid_612162 != nil:
    section.add "X-Amz-Content-Sha256", valid_612162
  var valid_612163 = header.getOrDefault("X-Amz-Date")
  valid_612163 = validateParameter(valid_612163, JString, required = false,
                                 default = nil)
  if valid_612163 != nil:
    section.add "X-Amz-Date", valid_612163
  var valid_612164 = header.getOrDefault("X-Amz-Credential")
  valid_612164 = validateParameter(valid_612164, JString, required = false,
                                 default = nil)
  if valid_612164 != nil:
    section.add "X-Amz-Credential", valid_612164
  var valid_612165 = header.getOrDefault("X-Amz-Security-Token")
  valid_612165 = validateParameter(valid_612165, JString, required = false,
                                 default = nil)
  if valid_612165 != nil:
    section.add "X-Amz-Security-Token", valid_612165
  var valid_612166 = header.getOrDefault("X-Amz-Algorithm")
  valid_612166 = validateParameter(valid_612166, JString, required = false,
                                 default = nil)
  if valid_612166 != nil:
    section.add "X-Amz-Algorithm", valid_612166
  var valid_612167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612167 = validateParameter(valid_612167, JString, required = false,
                                 default = nil)
  if valid_612167 != nil:
    section.add "X-Amz-SignedHeaders", valid_612167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612169: Call_GetSigningCertificate_612157; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This method takes a user pool ID, and returns the signing certificate.
  ## 
  let valid = call_612169.validator(path, query, header, formData, body)
  let scheme = call_612169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612169.url(scheme.get, call_612169.host, call_612169.base,
                         call_612169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612169, url, valid)

proc call*(call_612170: Call_GetSigningCertificate_612157; body: JsonNode): Recallable =
  ## getSigningCertificate
  ## This method takes a user pool ID, and returns the signing certificate.
  ##   body: JObject (required)
  var body_612171 = newJObject()
  if body != nil:
    body_612171 = body
  result = call_612170.call(nil, nil, nil, nil, body_612171)

var getSigningCertificate* = Call_GetSigningCertificate_612157(
    name: "getSigningCertificate", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetSigningCertificate",
    validator: validate_GetSigningCertificate_612158, base: "/",
    url: url_GetSigningCertificate_612159, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUICustomization_612172 = ref object of OpenApiRestCall_610658
proc url_GetUICustomization_612174(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUICustomization_612173(path: JsonNode; query: JsonNode;
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
  var valid_612175 = header.getOrDefault("X-Amz-Target")
  valid_612175 = validateParameter(valid_612175, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUICustomization"))
  if valid_612175 != nil:
    section.add "X-Amz-Target", valid_612175
  var valid_612176 = header.getOrDefault("X-Amz-Signature")
  valid_612176 = validateParameter(valid_612176, JString, required = false,
                                 default = nil)
  if valid_612176 != nil:
    section.add "X-Amz-Signature", valid_612176
  var valid_612177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612177 = validateParameter(valid_612177, JString, required = false,
                                 default = nil)
  if valid_612177 != nil:
    section.add "X-Amz-Content-Sha256", valid_612177
  var valid_612178 = header.getOrDefault("X-Amz-Date")
  valid_612178 = validateParameter(valid_612178, JString, required = false,
                                 default = nil)
  if valid_612178 != nil:
    section.add "X-Amz-Date", valid_612178
  var valid_612179 = header.getOrDefault("X-Amz-Credential")
  valid_612179 = validateParameter(valid_612179, JString, required = false,
                                 default = nil)
  if valid_612179 != nil:
    section.add "X-Amz-Credential", valid_612179
  var valid_612180 = header.getOrDefault("X-Amz-Security-Token")
  valid_612180 = validateParameter(valid_612180, JString, required = false,
                                 default = nil)
  if valid_612180 != nil:
    section.add "X-Amz-Security-Token", valid_612180
  var valid_612181 = header.getOrDefault("X-Amz-Algorithm")
  valid_612181 = validateParameter(valid_612181, JString, required = false,
                                 default = nil)
  if valid_612181 != nil:
    section.add "X-Amz-Algorithm", valid_612181
  var valid_612182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612182 = validateParameter(valid_612182, JString, required = false,
                                 default = nil)
  if valid_612182 != nil:
    section.add "X-Amz-SignedHeaders", valid_612182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612184: Call_GetUICustomization_612172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the UI Customization information for a particular app client's app UI, if there is something set. If nothing is set for the particular client, but there is an existing pool level customization (app <code>clientId</code> will be <code>ALL</code>), then that is returned. If nothing is present, then an empty shape is returned.
  ## 
  let valid = call_612184.validator(path, query, header, formData, body)
  let scheme = call_612184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612184.url(scheme.get, call_612184.host, call_612184.base,
                         call_612184.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612184, url, valid)

proc call*(call_612185: Call_GetUICustomization_612172; body: JsonNode): Recallable =
  ## getUICustomization
  ## Gets the UI Customization information for a particular app client's app UI, if there is something set. If nothing is set for the particular client, but there is an existing pool level customization (app <code>clientId</code> will be <code>ALL</code>), then that is returned. If nothing is present, then an empty shape is returned.
  ##   body: JObject (required)
  var body_612186 = newJObject()
  if body != nil:
    body_612186 = body
  result = call_612185.call(nil, nil, nil, nil, body_612186)

var getUICustomization* = Call_GetUICustomization_612172(
    name: "getUICustomization", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUICustomization",
    validator: validate_GetUICustomization_612173, base: "/",
    url: url_GetUICustomization_612174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUser_612187 = ref object of OpenApiRestCall_610658
proc url_GetUser_612189(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUser_612188(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612190 = header.getOrDefault("X-Amz-Target")
  valid_612190 = validateParameter(valid_612190, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUser"))
  if valid_612190 != nil:
    section.add "X-Amz-Target", valid_612190
  var valid_612191 = header.getOrDefault("X-Amz-Signature")
  valid_612191 = validateParameter(valid_612191, JString, required = false,
                                 default = nil)
  if valid_612191 != nil:
    section.add "X-Amz-Signature", valid_612191
  var valid_612192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612192 = validateParameter(valid_612192, JString, required = false,
                                 default = nil)
  if valid_612192 != nil:
    section.add "X-Amz-Content-Sha256", valid_612192
  var valid_612193 = header.getOrDefault("X-Amz-Date")
  valid_612193 = validateParameter(valid_612193, JString, required = false,
                                 default = nil)
  if valid_612193 != nil:
    section.add "X-Amz-Date", valid_612193
  var valid_612194 = header.getOrDefault("X-Amz-Credential")
  valid_612194 = validateParameter(valid_612194, JString, required = false,
                                 default = nil)
  if valid_612194 != nil:
    section.add "X-Amz-Credential", valid_612194
  var valid_612195 = header.getOrDefault("X-Amz-Security-Token")
  valid_612195 = validateParameter(valid_612195, JString, required = false,
                                 default = nil)
  if valid_612195 != nil:
    section.add "X-Amz-Security-Token", valid_612195
  var valid_612196 = header.getOrDefault("X-Amz-Algorithm")
  valid_612196 = validateParameter(valid_612196, JString, required = false,
                                 default = nil)
  if valid_612196 != nil:
    section.add "X-Amz-Algorithm", valid_612196
  var valid_612197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612197 = validateParameter(valid_612197, JString, required = false,
                                 default = nil)
  if valid_612197 != nil:
    section.add "X-Amz-SignedHeaders", valid_612197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612199: Call_GetUser_612187; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the user attributes and metadata for a user.
  ## 
  let valid = call_612199.validator(path, query, header, formData, body)
  let scheme = call_612199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612199.url(scheme.get, call_612199.host, call_612199.base,
                         call_612199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612199, url, valid)

proc call*(call_612200: Call_GetUser_612187; body: JsonNode): Recallable =
  ## getUser
  ## Gets the user attributes and metadata for a user.
  ##   body: JObject (required)
  var body_612201 = newJObject()
  if body != nil:
    body_612201 = body
  result = call_612200.call(nil, nil, nil, nil, body_612201)

var getUser* = Call_GetUser_612187(name: "getUser", meth: HttpMethod.HttpPost,
                                host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUser",
                                validator: validate_GetUser_612188, base: "/",
                                url: url_GetUser_612189,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserAttributeVerificationCode_612202 = ref object of OpenApiRestCall_610658
proc url_GetUserAttributeVerificationCode_612204(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUserAttributeVerificationCode_612203(path: JsonNode;
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
  var valid_612205 = header.getOrDefault("X-Amz-Target")
  valid_612205 = validateParameter(valid_612205, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUserAttributeVerificationCode"))
  if valid_612205 != nil:
    section.add "X-Amz-Target", valid_612205
  var valid_612206 = header.getOrDefault("X-Amz-Signature")
  valid_612206 = validateParameter(valid_612206, JString, required = false,
                                 default = nil)
  if valid_612206 != nil:
    section.add "X-Amz-Signature", valid_612206
  var valid_612207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612207 = validateParameter(valid_612207, JString, required = false,
                                 default = nil)
  if valid_612207 != nil:
    section.add "X-Amz-Content-Sha256", valid_612207
  var valid_612208 = header.getOrDefault("X-Amz-Date")
  valid_612208 = validateParameter(valid_612208, JString, required = false,
                                 default = nil)
  if valid_612208 != nil:
    section.add "X-Amz-Date", valid_612208
  var valid_612209 = header.getOrDefault("X-Amz-Credential")
  valid_612209 = validateParameter(valid_612209, JString, required = false,
                                 default = nil)
  if valid_612209 != nil:
    section.add "X-Amz-Credential", valid_612209
  var valid_612210 = header.getOrDefault("X-Amz-Security-Token")
  valid_612210 = validateParameter(valid_612210, JString, required = false,
                                 default = nil)
  if valid_612210 != nil:
    section.add "X-Amz-Security-Token", valid_612210
  var valid_612211 = header.getOrDefault("X-Amz-Algorithm")
  valid_612211 = validateParameter(valid_612211, JString, required = false,
                                 default = nil)
  if valid_612211 != nil:
    section.add "X-Amz-Algorithm", valid_612211
  var valid_612212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612212 = validateParameter(valid_612212, JString, required = false,
                                 default = nil)
  if valid_612212 != nil:
    section.add "X-Amz-SignedHeaders", valid_612212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612214: Call_GetUserAttributeVerificationCode_612202;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the user attribute verification code for the specified attribute name.
  ## 
  let valid = call_612214.validator(path, query, header, formData, body)
  let scheme = call_612214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612214.url(scheme.get, call_612214.host, call_612214.base,
                         call_612214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612214, url, valid)

proc call*(call_612215: Call_GetUserAttributeVerificationCode_612202;
          body: JsonNode): Recallable =
  ## getUserAttributeVerificationCode
  ## Gets the user attribute verification code for the specified attribute name.
  ##   body: JObject (required)
  var body_612216 = newJObject()
  if body != nil:
    body_612216 = body
  result = call_612215.call(nil, nil, nil, nil, body_612216)

var getUserAttributeVerificationCode* = Call_GetUserAttributeVerificationCode_612202(
    name: "getUserAttributeVerificationCode", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUserAttributeVerificationCode",
    validator: validate_GetUserAttributeVerificationCode_612203, base: "/",
    url: url_GetUserAttributeVerificationCode_612204,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserPoolMfaConfig_612217 = ref object of OpenApiRestCall_610658
proc url_GetUserPoolMfaConfig_612219(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUserPoolMfaConfig_612218(path: JsonNode; query: JsonNode;
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
  var valid_612220 = header.getOrDefault("X-Amz-Target")
  valid_612220 = validateParameter(valid_612220, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUserPoolMfaConfig"))
  if valid_612220 != nil:
    section.add "X-Amz-Target", valid_612220
  var valid_612221 = header.getOrDefault("X-Amz-Signature")
  valid_612221 = validateParameter(valid_612221, JString, required = false,
                                 default = nil)
  if valid_612221 != nil:
    section.add "X-Amz-Signature", valid_612221
  var valid_612222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612222 = validateParameter(valid_612222, JString, required = false,
                                 default = nil)
  if valid_612222 != nil:
    section.add "X-Amz-Content-Sha256", valid_612222
  var valid_612223 = header.getOrDefault("X-Amz-Date")
  valid_612223 = validateParameter(valid_612223, JString, required = false,
                                 default = nil)
  if valid_612223 != nil:
    section.add "X-Amz-Date", valid_612223
  var valid_612224 = header.getOrDefault("X-Amz-Credential")
  valid_612224 = validateParameter(valid_612224, JString, required = false,
                                 default = nil)
  if valid_612224 != nil:
    section.add "X-Amz-Credential", valid_612224
  var valid_612225 = header.getOrDefault("X-Amz-Security-Token")
  valid_612225 = validateParameter(valid_612225, JString, required = false,
                                 default = nil)
  if valid_612225 != nil:
    section.add "X-Amz-Security-Token", valid_612225
  var valid_612226 = header.getOrDefault("X-Amz-Algorithm")
  valid_612226 = validateParameter(valid_612226, JString, required = false,
                                 default = nil)
  if valid_612226 != nil:
    section.add "X-Amz-Algorithm", valid_612226
  var valid_612227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612227 = validateParameter(valid_612227, JString, required = false,
                                 default = nil)
  if valid_612227 != nil:
    section.add "X-Amz-SignedHeaders", valid_612227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612229: Call_GetUserPoolMfaConfig_612217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the user pool multi-factor authentication (MFA) configuration.
  ## 
  let valid = call_612229.validator(path, query, header, formData, body)
  let scheme = call_612229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612229.url(scheme.get, call_612229.host, call_612229.base,
                         call_612229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612229, url, valid)

proc call*(call_612230: Call_GetUserPoolMfaConfig_612217; body: JsonNode): Recallable =
  ## getUserPoolMfaConfig
  ## Gets the user pool multi-factor authentication (MFA) configuration.
  ##   body: JObject (required)
  var body_612231 = newJObject()
  if body != nil:
    body_612231 = body
  result = call_612230.call(nil, nil, nil, nil, body_612231)

var getUserPoolMfaConfig* = Call_GetUserPoolMfaConfig_612217(
    name: "getUserPoolMfaConfig", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUserPoolMfaConfig",
    validator: validate_GetUserPoolMfaConfig_612218, base: "/",
    url: url_GetUserPoolMfaConfig_612219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GlobalSignOut_612232 = ref object of OpenApiRestCall_610658
proc url_GlobalSignOut_612234(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GlobalSignOut_612233(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612235 = header.getOrDefault("X-Amz-Target")
  valid_612235 = validateParameter(valid_612235, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GlobalSignOut"))
  if valid_612235 != nil:
    section.add "X-Amz-Target", valid_612235
  var valid_612236 = header.getOrDefault("X-Amz-Signature")
  valid_612236 = validateParameter(valid_612236, JString, required = false,
                                 default = nil)
  if valid_612236 != nil:
    section.add "X-Amz-Signature", valid_612236
  var valid_612237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612237 = validateParameter(valid_612237, JString, required = false,
                                 default = nil)
  if valid_612237 != nil:
    section.add "X-Amz-Content-Sha256", valid_612237
  var valid_612238 = header.getOrDefault("X-Amz-Date")
  valid_612238 = validateParameter(valid_612238, JString, required = false,
                                 default = nil)
  if valid_612238 != nil:
    section.add "X-Amz-Date", valid_612238
  var valid_612239 = header.getOrDefault("X-Amz-Credential")
  valid_612239 = validateParameter(valid_612239, JString, required = false,
                                 default = nil)
  if valid_612239 != nil:
    section.add "X-Amz-Credential", valid_612239
  var valid_612240 = header.getOrDefault("X-Amz-Security-Token")
  valid_612240 = validateParameter(valid_612240, JString, required = false,
                                 default = nil)
  if valid_612240 != nil:
    section.add "X-Amz-Security-Token", valid_612240
  var valid_612241 = header.getOrDefault("X-Amz-Algorithm")
  valid_612241 = validateParameter(valid_612241, JString, required = false,
                                 default = nil)
  if valid_612241 != nil:
    section.add "X-Amz-Algorithm", valid_612241
  var valid_612242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612242 = validateParameter(valid_612242, JString, required = false,
                                 default = nil)
  if valid_612242 != nil:
    section.add "X-Amz-SignedHeaders", valid_612242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612244: Call_GlobalSignOut_612232; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Signs out users from all devices. It also invalidates all refresh tokens issued to a user. The user's current access and Id tokens remain valid until their expiry. Access and Id tokens expire one hour after they are issued.
  ## 
  let valid = call_612244.validator(path, query, header, formData, body)
  let scheme = call_612244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612244.url(scheme.get, call_612244.host, call_612244.base,
                         call_612244.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612244, url, valid)

proc call*(call_612245: Call_GlobalSignOut_612232; body: JsonNode): Recallable =
  ## globalSignOut
  ## Signs out users from all devices. It also invalidates all refresh tokens issued to a user. The user's current access and Id tokens remain valid until their expiry. Access and Id tokens expire one hour after they are issued.
  ##   body: JObject (required)
  var body_612246 = newJObject()
  if body != nil:
    body_612246 = body
  result = call_612245.call(nil, nil, nil, nil, body_612246)

var globalSignOut* = Call_GlobalSignOut_612232(name: "globalSignOut",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GlobalSignOut",
    validator: validate_GlobalSignOut_612233, base: "/", url: url_GlobalSignOut_612234,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateAuth_612247 = ref object of OpenApiRestCall_610658
proc url_InitiateAuth_612249(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_InitiateAuth_612248(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612250 = header.getOrDefault("X-Amz-Target")
  valid_612250 = validateParameter(valid_612250, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.InitiateAuth"))
  if valid_612250 != nil:
    section.add "X-Amz-Target", valid_612250
  var valid_612251 = header.getOrDefault("X-Amz-Signature")
  valid_612251 = validateParameter(valid_612251, JString, required = false,
                                 default = nil)
  if valid_612251 != nil:
    section.add "X-Amz-Signature", valid_612251
  var valid_612252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612252 = validateParameter(valid_612252, JString, required = false,
                                 default = nil)
  if valid_612252 != nil:
    section.add "X-Amz-Content-Sha256", valid_612252
  var valid_612253 = header.getOrDefault("X-Amz-Date")
  valid_612253 = validateParameter(valid_612253, JString, required = false,
                                 default = nil)
  if valid_612253 != nil:
    section.add "X-Amz-Date", valid_612253
  var valid_612254 = header.getOrDefault("X-Amz-Credential")
  valid_612254 = validateParameter(valid_612254, JString, required = false,
                                 default = nil)
  if valid_612254 != nil:
    section.add "X-Amz-Credential", valid_612254
  var valid_612255 = header.getOrDefault("X-Amz-Security-Token")
  valid_612255 = validateParameter(valid_612255, JString, required = false,
                                 default = nil)
  if valid_612255 != nil:
    section.add "X-Amz-Security-Token", valid_612255
  var valid_612256 = header.getOrDefault("X-Amz-Algorithm")
  valid_612256 = validateParameter(valid_612256, JString, required = false,
                                 default = nil)
  if valid_612256 != nil:
    section.add "X-Amz-Algorithm", valid_612256
  var valid_612257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612257 = validateParameter(valid_612257, JString, required = false,
                                 default = nil)
  if valid_612257 != nil:
    section.add "X-Amz-SignedHeaders", valid_612257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612259: Call_InitiateAuth_612247; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates the authentication flow.
  ## 
  let valid = call_612259.validator(path, query, header, formData, body)
  let scheme = call_612259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612259.url(scheme.get, call_612259.host, call_612259.base,
                         call_612259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612259, url, valid)

proc call*(call_612260: Call_InitiateAuth_612247; body: JsonNode): Recallable =
  ## initiateAuth
  ## Initiates the authentication flow.
  ##   body: JObject (required)
  var body_612261 = newJObject()
  if body != nil:
    body_612261 = body
  result = call_612260.call(nil, nil, nil, nil, body_612261)

var initiateAuth* = Call_InitiateAuth_612247(name: "initiateAuth",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.InitiateAuth",
    validator: validate_InitiateAuth_612248, base: "/", url: url_InitiateAuth_612249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevices_612262 = ref object of OpenApiRestCall_610658
proc url_ListDevices_612264(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDevices_612263(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612265 = header.getOrDefault("X-Amz-Target")
  valid_612265 = validateParameter(valid_612265, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListDevices"))
  if valid_612265 != nil:
    section.add "X-Amz-Target", valid_612265
  var valid_612266 = header.getOrDefault("X-Amz-Signature")
  valid_612266 = validateParameter(valid_612266, JString, required = false,
                                 default = nil)
  if valid_612266 != nil:
    section.add "X-Amz-Signature", valid_612266
  var valid_612267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612267 = validateParameter(valid_612267, JString, required = false,
                                 default = nil)
  if valid_612267 != nil:
    section.add "X-Amz-Content-Sha256", valid_612267
  var valid_612268 = header.getOrDefault("X-Amz-Date")
  valid_612268 = validateParameter(valid_612268, JString, required = false,
                                 default = nil)
  if valid_612268 != nil:
    section.add "X-Amz-Date", valid_612268
  var valid_612269 = header.getOrDefault("X-Amz-Credential")
  valid_612269 = validateParameter(valid_612269, JString, required = false,
                                 default = nil)
  if valid_612269 != nil:
    section.add "X-Amz-Credential", valid_612269
  var valid_612270 = header.getOrDefault("X-Amz-Security-Token")
  valid_612270 = validateParameter(valid_612270, JString, required = false,
                                 default = nil)
  if valid_612270 != nil:
    section.add "X-Amz-Security-Token", valid_612270
  var valid_612271 = header.getOrDefault("X-Amz-Algorithm")
  valid_612271 = validateParameter(valid_612271, JString, required = false,
                                 default = nil)
  if valid_612271 != nil:
    section.add "X-Amz-Algorithm", valid_612271
  var valid_612272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612272 = validateParameter(valid_612272, JString, required = false,
                                 default = nil)
  if valid_612272 != nil:
    section.add "X-Amz-SignedHeaders", valid_612272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612274: Call_ListDevices_612262; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the devices.
  ## 
  let valid = call_612274.validator(path, query, header, formData, body)
  let scheme = call_612274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612274.url(scheme.get, call_612274.host, call_612274.base,
                         call_612274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612274, url, valid)

proc call*(call_612275: Call_ListDevices_612262; body: JsonNode): Recallable =
  ## listDevices
  ## Lists the devices.
  ##   body: JObject (required)
  var body_612276 = newJObject()
  if body != nil:
    body_612276 = body
  result = call_612275.call(nil, nil, nil, nil, body_612276)

var listDevices* = Call_ListDevices_612262(name: "listDevices",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListDevices",
                                        validator: validate_ListDevices_612263,
                                        base: "/", url: url_ListDevices_612264,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_612277 = ref object of OpenApiRestCall_610658
proc url_ListGroups_612279(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGroups_612278(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612280 = query.getOrDefault("NextToken")
  valid_612280 = validateParameter(valid_612280, JString, required = false,
                                 default = nil)
  if valid_612280 != nil:
    section.add "NextToken", valid_612280
  var valid_612281 = query.getOrDefault("Limit")
  valid_612281 = validateParameter(valid_612281, JString, required = false,
                                 default = nil)
  if valid_612281 != nil:
    section.add "Limit", valid_612281
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
  var valid_612282 = header.getOrDefault("X-Amz-Target")
  valid_612282 = validateParameter(valid_612282, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListGroups"))
  if valid_612282 != nil:
    section.add "X-Amz-Target", valid_612282
  var valid_612283 = header.getOrDefault("X-Amz-Signature")
  valid_612283 = validateParameter(valid_612283, JString, required = false,
                                 default = nil)
  if valid_612283 != nil:
    section.add "X-Amz-Signature", valid_612283
  var valid_612284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612284 = validateParameter(valid_612284, JString, required = false,
                                 default = nil)
  if valid_612284 != nil:
    section.add "X-Amz-Content-Sha256", valid_612284
  var valid_612285 = header.getOrDefault("X-Amz-Date")
  valid_612285 = validateParameter(valid_612285, JString, required = false,
                                 default = nil)
  if valid_612285 != nil:
    section.add "X-Amz-Date", valid_612285
  var valid_612286 = header.getOrDefault("X-Amz-Credential")
  valid_612286 = validateParameter(valid_612286, JString, required = false,
                                 default = nil)
  if valid_612286 != nil:
    section.add "X-Amz-Credential", valid_612286
  var valid_612287 = header.getOrDefault("X-Amz-Security-Token")
  valid_612287 = validateParameter(valid_612287, JString, required = false,
                                 default = nil)
  if valid_612287 != nil:
    section.add "X-Amz-Security-Token", valid_612287
  var valid_612288 = header.getOrDefault("X-Amz-Algorithm")
  valid_612288 = validateParameter(valid_612288, JString, required = false,
                                 default = nil)
  if valid_612288 != nil:
    section.add "X-Amz-Algorithm", valid_612288
  var valid_612289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612289 = validateParameter(valid_612289, JString, required = false,
                                 default = nil)
  if valid_612289 != nil:
    section.add "X-Amz-SignedHeaders", valid_612289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612291: Call_ListGroups_612277; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the groups associated with a user pool.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_612291.validator(path, query, header, formData, body)
  let scheme = call_612291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612291.url(scheme.get, call_612291.host, call_612291.base,
                         call_612291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612291, url, valid)

proc call*(call_612292: Call_ListGroups_612277; body: JsonNode;
          NextToken: string = ""; Limit: string = ""): Recallable =
  ## listGroups
  ## <p>Lists the groups associated with a user pool.</p> <p>Calling this action requires developer credentials.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_612293 = newJObject()
  var body_612294 = newJObject()
  add(query_612293, "NextToken", newJString(NextToken))
  add(query_612293, "Limit", newJString(Limit))
  if body != nil:
    body_612294 = body
  result = call_612292.call(nil, query_612293, nil, nil, body_612294)

var listGroups* = Call_ListGroups_612277(name: "listGroups",
                                      meth: HttpMethod.HttpPost,
                                      host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListGroups",
                                      validator: validate_ListGroups_612278,
                                      base: "/", url: url_ListGroups_612279,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIdentityProviders_612295 = ref object of OpenApiRestCall_610658
proc url_ListIdentityProviders_612297(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListIdentityProviders_612296(path: JsonNode; query: JsonNode;
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
  var valid_612298 = query.getOrDefault("MaxResults")
  valid_612298 = validateParameter(valid_612298, JString, required = false,
                                 default = nil)
  if valid_612298 != nil:
    section.add "MaxResults", valid_612298
  var valid_612299 = query.getOrDefault("NextToken")
  valid_612299 = validateParameter(valid_612299, JString, required = false,
                                 default = nil)
  if valid_612299 != nil:
    section.add "NextToken", valid_612299
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
  var valid_612300 = header.getOrDefault("X-Amz-Target")
  valid_612300 = validateParameter(valid_612300, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListIdentityProviders"))
  if valid_612300 != nil:
    section.add "X-Amz-Target", valid_612300
  var valid_612301 = header.getOrDefault("X-Amz-Signature")
  valid_612301 = validateParameter(valid_612301, JString, required = false,
                                 default = nil)
  if valid_612301 != nil:
    section.add "X-Amz-Signature", valid_612301
  var valid_612302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612302 = validateParameter(valid_612302, JString, required = false,
                                 default = nil)
  if valid_612302 != nil:
    section.add "X-Amz-Content-Sha256", valid_612302
  var valid_612303 = header.getOrDefault("X-Amz-Date")
  valid_612303 = validateParameter(valid_612303, JString, required = false,
                                 default = nil)
  if valid_612303 != nil:
    section.add "X-Amz-Date", valid_612303
  var valid_612304 = header.getOrDefault("X-Amz-Credential")
  valid_612304 = validateParameter(valid_612304, JString, required = false,
                                 default = nil)
  if valid_612304 != nil:
    section.add "X-Amz-Credential", valid_612304
  var valid_612305 = header.getOrDefault("X-Amz-Security-Token")
  valid_612305 = validateParameter(valid_612305, JString, required = false,
                                 default = nil)
  if valid_612305 != nil:
    section.add "X-Amz-Security-Token", valid_612305
  var valid_612306 = header.getOrDefault("X-Amz-Algorithm")
  valid_612306 = validateParameter(valid_612306, JString, required = false,
                                 default = nil)
  if valid_612306 != nil:
    section.add "X-Amz-Algorithm", valid_612306
  var valid_612307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612307 = validateParameter(valid_612307, JString, required = false,
                                 default = nil)
  if valid_612307 != nil:
    section.add "X-Amz-SignedHeaders", valid_612307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612309: Call_ListIdentityProviders_612295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about all identity providers for a user pool.
  ## 
  let valid = call_612309.validator(path, query, header, formData, body)
  let scheme = call_612309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612309.url(scheme.get, call_612309.host, call_612309.base,
                         call_612309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612309, url, valid)

proc call*(call_612310: Call_ListIdentityProviders_612295; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listIdentityProviders
  ## Lists information about all identity providers for a user pool.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612311 = newJObject()
  var body_612312 = newJObject()
  add(query_612311, "MaxResults", newJString(MaxResults))
  add(query_612311, "NextToken", newJString(NextToken))
  if body != nil:
    body_612312 = body
  result = call_612310.call(nil, query_612311, nil, nil, body_612312)

var listIdentityProviders* = Call_ListIdentityProviders_612295(
    name: "listIdentityProviders", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListIdentityProviders",
    validator: validate_ListIdentityProviders_612296, base: "/",
    url: url_ListIdentityProviders_612297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceServers_612313 = ref object of OpenApiRestCall_610658
proc url_ListResourceServers_612315(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResourceServers_612314(path: JsonNode; query: JsonNode;
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
  var valid_612316 = query.getOrDefault("MaxResults")
  valid_612316 = validateParameter(valid_612316, JString, required = false,
                                 default = nil)
  if valid_612316 != nil:
    section.add "MaxResults", valid_612316
  var valid_612317 = query.getOrDefault("NextToken")
  valid_612317 = validateParameter(valid_612317, JString, required = false,
                                 default = nil)
  if valid_612317 != nil:
    section.add "NextToken", valid_612317
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
  var valid_612318 = header.getOrDefault("X-Amz-Target")
  valid_612318 = validateParameter(valid_612318, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListResourceServers"))
  if valid_612318 != nil:
    section.add "X-Amz-Target", valid_612318
  var valid_612319 = header.getOrDefault("X-Amz-Signature")
  valid_612319 = validateParameter(valid_612319, JString, required = false,
                                 default = nil)
  if valid_612319 != nil:
    section.add "X-Amz-Signature", valid_612319
  var valid_612320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612320 = validateParameter(valid_612320, JString, required = false,
                                 default = nil)
  if valid_612320 != nil:
    section.add "X-Amz-Content-Sha256", valid_612320
  var valid_612321 = header.getOrDefault("X-Amz-Date")
  valid_612321 = validateParameter(valid_612321, JString, required = false,
                                 default = nil)
  if valid_612321 != nil:
    section.add "X-Amz-Date", valid_612321
  var valid_612322 = header.getOrDefault("X-Amz-Credential")
  valid_612322 = validateParameter(valid_612322, JString, required = false,
                                 default = nil)
  if valid_612322 != nil:
    section.add "X-Amz-Credential", valid_612322
  var valid_612323 = header.getOrDefault("X-Amz-Security-Token")
  valid_612323 = validateParameter(valid_612323, JString, required = false,
                                 default = nil)
  if valid_612323 != nil:
    section.add "X-Amz-Security-Token", valid_612323
  var valid_612324 = header.getOrDefault("X-Amz-Algorithm")
  valid_612324 = validateParameter(valid_612324, JString, required = false,
                                 default = nil)
  if valid_612324 != nil:
    section.add "X-Amz-Algorithm", valid_612324
  var valid_612325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612325 = validateParameter(valid_612325, JString, required = false,
                                 default = nil)
  if valid_612325 != nil:
    section.add "X-Amz-SignedHeaders", valid_612325
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612327: Call_ListResourceServers_612313; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resource servers for a user pool.
  ## 
  let valid = call_612327.validator(path, query, header, formData, body)
  let scheme = call_612327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612327.url(scheme.get, call_612327.host, call_612327.base,
                         call_612327.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612327, url, valid)

proc call*(call_612328: Call_ListResourceServers_612313; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listResourceServers
  ## Lists the resource servers for a user pool.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612329 = newJObject()
  var body_612330 = newJObject()
  add(query_612329, "MaxResults", newJString(MaxResults))
  add(query_612329, "NextToken", newJString(NextToken))
  if body != nil:
    body_612330 = body
  result = call_612328.call(nil, query_612329, nil, nil, body_612330)

var listResourceServers* = Call_ListResourceServers_612313(
    name: "listResourceServers", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListResourceServers",
    validator: validate_ListResourceServers_612314, base: "/",
    url: url_ListResourceServers_612315, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_612331 = ref object of OpenApiRestCall_610658
proc url_ListTagsForResource_612333(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_612332(path: JsonNode; query: JsonNode;
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
  var valid_612334 = header.getOrDefault("X-Amz-Target")
  valid_612334 = validateParameter(valid_612334, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListTagsForResource"))
  if valid_612334 != nil:
    section.add "X-Amz-Target", valid_612334
  var valid_612335 = header.getOrDefault("X-Amz-Signature")
  valid_612335 = validateParameter(valid_612335, JString, required = false,
                                 default = nil)
  if valid_612335 != nil:
    section.add "X-Amz-Signature", valid_612335
  var valid_612336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612336 = validateParameter(valid_612336, JString, required = false,
                                 default = nil)
  if valid_612336 != nil:
    section.add "X-Amz-Content-Sha256", valid_612336
  var valid_612337 = header.getOrDefault("X-Amz-Date")
  valid_612337 = validateParameter(valid_612337, JString, required = false,
                                 default = nil)
  if valid_612337 != nil:
    section.add "X-Amz-Date", valid_612337
  var valid_612338 = header.getOrDefault("X-Amz-Credential")
  valid_612338 = validateParameter(valid_612338, JString, required = false,
                                 default = nil)
  if valid_612338 != nil:
    section.add "X-Amz-Credential", valid_612338
  var valid_612339 = header.getOrDefault("X-Amz-Security-Token")
  valid_612339 = validateParameter(valid_612339, JString, required = false,
                                 default = nil)
  if valid_612339 != nil:
    section.add "X-Amz-Security-Token", valid_612339
  var valid_612340 = header.getOrDefault("X-Amz-Algorithm")
  valid_612340 = validateParameter(valid_612340, JString, required = false,
                                 default = nil)
  if valid_612340 != nil:
    section.add "X-Amz-Algorithm", valid_612340
  var valid_612341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612341 = validateParameter(valid_612341, JString, required = false,
                                 default = nil)
  if valid_612341 != nil:
    section.add "X-Amz-SignedHeaders", valid_612341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612343: Call_ListTagsForResource_612331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the tags that are assigned to an Amazon Cognito user pool.</p> <p>A tag is a label that you can apply to user pools to categorize and manage them in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>You can use this action up to 10 times per second, per account.</p>
  ## 
  let valid = call_612343.validator(path, query, header, formData, body)
  let scheme = call_612343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612343.url(scheme.get, call_612343.host, call_612343.base,
                         call_612343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612343, url, valid)

proc call*(call_612344: Call_ListTagsForResource_612331; body: JsonNode): Recallable =
  ## listTagsForResource
  ## <p>Lists the tags that are assigned to an Amazon Cognito user pool.</p> <p>A tag is a label that you can apply to user pools to categorize and manage them in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>You can use this action up to 10 times per second, per account.</p>
  ##   body: JObject (required)
  var body_612345 = newJObject()
  if body != nil:
    body_612345 = body
  result = call_612344.call(nil, nil, nil, nil, body_612345)

var listTagsForResource* = Call_ListTagsForResource_612331(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListTagsForResource",
    validator: validate_ListTagsForResource_612332, base: "/",
    url: url_ListTagsForResource_612333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserImportJobs_612346 = ref object of OpenApiRestCall_610658
proc url_ListUserImportJobs_612348(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUserImportJobs_612347(path: JsonNode; query: JsonNode;
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
  var valid_612349 = header.getOrDefault("X-Amz-Target")
  valid_612349 = validateParameter(valid_612349, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUserImportJobs"))
  if valid_612349 != nil:
    section.add "X-Amz-Target", valid_612349
  var valid_612350 = header.getOrDefault("X-Amz-Signature")
  valid_612350 = validateParameter(valid_612350, JString, required = false,
                                 default = nil)
  if valid_612350 != nil:
    section.add "X-Amz-Signature", valid_612350
  var valid_612351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612351 = validateParameter(valid_612351, JString, required = false,
                                 default = nil)
  if valid_612351 != nil:
    section.add "X-Amz-Content-Sha256", valid_612351
  var valid_612352 = header.getOrDefault("X-Amz-Date")
  valid_612352 = validateParameter(valid_612352, JString, required = false,
                                 default = nil)
  if valid_612352 != nil:
    section.add "X-Amz-Date", valid_612352
  var valid_612353 = header.getOrDefault("X-Amz-Credential")
  valid_612353 = validateParameter(valid_612353, JString, required = false,
                                 default = nil)
  if valid_612353 != nil:
    section.add "X-Amz-Credential", valid_612353
  var valid_612354 = header.getOrDefault("X-Amz-Security-Token")
  valid_612354 = validateParameter(valid_612354, JString, required = false,
                                 default = nil)
  if valid_612354 != nil:
    section.add "X-Amz-Security-Token", valid_612354
  var valid_612355 = header.getOrDefault("X-Amz-Algorithm")
  valid_612355 = validateParameter(valid_612355, JString, required = false,
                                 default = nil)
  if valid_612355 != nil:
    section.add "X-Amz-Algorithm", valid_612355
  var valid_612356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612356 = validateParameter(valid_612356, JString, required = false,
                                 default = nil)
  if valid_612356 != nil:
    section.add "X-Amz-SignedHeaders", valid_612356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612358: Call_ListUserImportJobs_612346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the user import jobs.
  ## 
  let valid = call_612358.validator(path, query, header, formData, body)
  let scheme = call_612358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612358.url(scheme.get, call_612358.host, call_612358.base,
                         call_612358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612358, url, valid)

proc call*(call_612359: Call_ListUserImportJobs_612346; body: JsonNode): Recallable =
  ## listUserImportJobs
  ## Lists the user import jobs.
  ##   body: JObject (required)
  var body_612360 = newJObject()
  if body != nil:
    body_612360 = body
  result = call_612359.call(nil, nil, nil, nil, body_612360)

var listUserImportJobs* = Call_ListUserImportJobs_612346(
    name: "listUserImportJobs", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUserImportJobs",
    validator: validate_ListUserImportJobs_612347, base: "/",
    url: url_ListUserImportJobs_612348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserPoolClients_612361 = ref object of OpenApiRestCall_610658
proc url_ListUserPoolClients_612363(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUserPoolClients_612362(path: JsonNode; query: JsonNode;
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
  var valid_612364 = query.getOrDefault("MaxResults")
  valid_612364 = validateParameter(valid_612364, JString, required = false,
                                 default = nil)
  if valid_612364 != nil:
    section.add "MaxResults", valid_612364
  var valid_612365 = query.getOrDefault("NextToken")
  valid_612365 = validateParameter(valid_612365, JString, required = false,
                                 default = nil)
  if valid_612365 != nil:
    section.add "NextToken", valid_612365
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
  var valid_612366 = header.getOrDefault("X-Amz-Target")
  valid_612366 = validateParameter(valid_612366, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUserPoolClients"))
  if valid_612366 != nil:
    section.add "X-Amz-Target", valid_612366
  var valid_612367 = header.getOrDefault("X-Amz-Signature")
  valid_612367 = validateParameter(valid_612367, JString, required = false,
                                 default = nil)
  if valid_612367 != nil:
    section.add "X-Amz-Signature", valid_612367
  var valid_612368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612368 = validateParameter(valid_612368, JString, required = false,
                                 default = nil)
  if valid_612368 != nil:
    section.add "X-Amz-Content-Sha256", valid_612368
  var valid_612369 = header.getOrDefault("X-Amz-Date")
  valid_612369 = validateParameter(valid_612369, JString, required = false,
                                 default = nil)
  if valid_612369 != nil:
    section.add "X-Amz-Date", valid_612369
  var valid_612370 = header.getOrDefault("X-Amz-Credential")
  valid_612370 = validateParameter(valid_612370, JString, required = false,
                                 default = nil)
  if valid_612370 != nil:
    section.add "X-Amz-Credential", valid_612370
  var valid_612371 = header.getOrDefault("X-Amz-Security-Token")
  valid_612371 = validateParameter(valid_612371, JString, required = false,
                                 default = nil)
  if valid_612371 != nil:
    section.add "X-Amz-Security-Token", valid_612371
  var valid_612372 = header.getOrDefault("X-Amz-Algorithm")
  valid_612372 = validateParameter(valid_612372, JString, required = false,
                                 default = nil)
  if valid_612372 != nil:
    section.add "X-Amz-Algorithm", valid_612372
  var valid_612373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612373 = validateParameter(valid_612373, JString, required = false,
                                 default = nil)
  if valid_612373 != nil:
    section.add "X-Amz-SignedHeaders", valid_612373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612375: Call_ListUserPoolClients_612361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the clients that have been created for the specified user pool.
  ## 
  let valid = call_612375.validator(path, query, header, formData, body)
  let scheme = call_612375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612375.url(scheme.get, call_612375.host, call_612375.base,
                         call_612375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612375, url, valid)

proc call*(call_612376: Call_ListUserPoolClients_612361; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listUserPoolClients
  ## Lists the clients that have been created for the specified user pool.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612377 = newJObject()
  var body_612378 = newJObject()
  add(query_612377, "MaxResults", newJString(MaxResults))
  add(query_612377, "NextToken", newJString(NextToken))
  if body != nil:
    body_612378 = body
  result = call_612376.call(nil, query_612377, nil, nil, body_612378)

var listUserPoolClients* = Call_ListUserPoolClients_612361(
    name: "listUserPoolClients", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUserPoolClients",
    validator: validate_ListUserPoolClients_612362, base: "/",
    url: url_ListUserPoolClients_612363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserPools_612379 = ref object of OpenApiRestCall_610658
proc url_ListUserPools_612381(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUserPools_612380(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612382 = query.getOrDefault("MaxResults")
  valid_612382 = validateParameter(valid_612382, JString, required = false,
                                 default = nil)
  if valid_612382 != nil:
    section.add "MaxResults", valid_612382
  var valid_612383 = query.getOrDefault("NextToken")
  valid_612383 = validateParameter(valid_612383, JString, required = false,
                                 default = nil)
  if valid_612383 != nil:
    section.add "NextToken", valid_612383
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
  var valid_612384 = header.getOrDefault("X-Amz-Target")
  valid_612384 = validateParameter(valid_612384, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUserPools"))
  if valid_612384 != nil:
    section.add "X-Amz-Target", valid_612384
  var valid_612385 = header.getOrDefault("X-Amz-Signature")
  valid_612385 = validateParameter(valid_612385, JString, required = false,
                                 default = nil)
  if valid_612385 != nil:
    section.add "X-Amz-Signature", valid_612385
  var valid_612386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612386 = validateParameter(valid_612386, JString, required = false,
                                 default = nil)
  if valid_612386 != nil:
    section.add "X-Amz-Content-Sha256", valid_612386
  var valid_612387 = header.getOrDefault("X-Amz-Date")
  valid_612387 = validateParameter(valid_612387, JString, required = false,
                                 default = nil)
  if valid_612387 != nil:
    section.add "X-Amz-Date", valid_612387
  var valid_612388 = header.getOrDefault("X-Amz-Credential")
  valid_612388 = validateParameter(valid_612388, JString, required = false,
                                 default = nil)
  if valid_612388 != nil:
    section.add "X-Amz-Credential", valid_612388
  var valid_612389 = header.getOrDefault("X-Amz-Security-Token")
  valid_612389 = validateParameter(valid_612389, JString, required = false,
                                 default = nil)
  if valid_612389 != nil:
    section.add "X-Amz-Security-Token", valid_612389
  var valid_612390 = header.getOrDefault("X-Amz-Algorithm")
  valid_612390 = validateParameter(valid_612390, JString, required = false,
                                 default = nil)
  if valid_612390 != nil:
    section.add "X-Amz-Algorithm", valid_612390
  var valid_612391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612391 = validateParameter(valid_612391, JString, required = false,
                                 default = nil)
  if valid_612391 != nil:
    section.add "X-Amz-SignedHeaders", valid_612391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612393: Call_ListUserPools_612379; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the user pools associated with an AWS account.
  ## 
  let valid = call_612393.validator(path, query, header, formData, body)
  let scheme = call_612393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612393.url(scheme.get, call_612393.host, call_612393.base,
                         call_612393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612393, url, valid)

proc call*(call_612394: Call_ListUserPools_612379; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listUserPools
  ## Lists the user pools associated with an AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612395 = newJObject()
  var body_612396 = newJObject()
  add(query_612395, "MaxResults", newJString(MaxResults))
  add(query_612395, "NextToken", newJString(NextToken))
  if body != nil:
    body_612396 = body
  result = call_612394.call(nil, query_612395, nil, nil, body_612396)

var listUserPools* = Call_ListUserPools_612379(name: "listUserPools",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUserPools",
    validator: validate_ListUserPools_612380, base: "/", url: url_ListUserPools_612381,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_612397 = ref object of OpenApiRestCall_610658
proc url_ListUsers_612399(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUsers_612398(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612400 = query.getOrDefault("Limit")
  valid_612400 = validateParameter(valid_612400, JString, required = false,
                                 default = nil)
  if valid_612400 != nil:
    section.add "Limit", valid_612400
  var valid_612401 = query.getOrDefault("PaginationToken")
  valid_612401 = validateParameter(valid_612401, JString, required = false,
                                 default = nil)
  if valid_612401 != nil:
    section.add "PaginationToken", valid_612401
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
  var valid_612402 = header.getOrDefault("X-Amz-Target")
  valid_612402 = validateParameter(valid_612402, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUsers"))
  if valid_612402 != nil:
    section.add "X-Amz-Target", valid_612402
  var valid_612403 = header.getOrDefault("X-Amz-Signature")
  valid_612403 = validateParameter(valid_612403, JString, required = false,
                                 default = nil)
  if valid_612403 != nil:
    section.add "X-Amz-Signature", valid_612403
  var valid_612404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612404 = validateParameter(valid_612404, JString, required = false,
                                 default = nil)
  if valid_612404 != nil:
    section.add "X-Amz-Content-Sha256", valid_612404
  var valid_612405 = header.getOrDefault("X-Amz-Date")
  valid_612405 = validateParameter(valid_612405, JString, required = false,
                                 default = nil)
  if valid_612405 != nil:
    section.add "X-Amz-Date", valid_612405
  var valid_612406 = header.getOrDefault("X-Amz-Credential")
  valid_612406 = validateParameter(valid_612406, JString, required = false,
                                 default = nil)
  if valid_612406 != nil:
    section.add "X-Amz-Credential", valid_612406
  var valid_612407 = header.getOrDefault("X-Amz-Security-Token")
  valid_612407 = validateParameter(valid_612407, JString, required = false,
                                 default = nil)
  if valid_612407 != nil:
    section.add "X-Amz-Security-Token", valid_612407
  var valid_612408 = header.getOrDefault("X-Amz-Algorithm")
  valid_612408 = validateParameter(valid_612408, JString, required = false,
                                 default = nil)
  if valid_612408 != nil:
    section.add "X-Amz-Algorithm", valid_612408
  var valid_612409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612409 = validateParameter(valid_612409, JString, required = false,
                                 default = nil)
  if valid_612409 != nil:
    section.add "X-Amz-SignedHeaders", valid_612409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612411: Call_ListUsers_612397; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the users in the Amazon Cognito user pool.
  ## 
  let valid = call_612411.validator(path, query, header, formData, body)
  let scheme = call_612411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612411.url(scheme.get, call_612411.host, call_612411.base,
                         call_612411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612411, url, valid)

proc call*(call_612412: Call_ListUsers_612397; body: JsonNode; Limit: string = "";
          PaginationToken: string = ""): Recallable =
  ## listUsers
  ## Lists the users in the Amazon Cognito user pool.
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  ##   PaginationToken: string
  ##                  : Pagination token
  var query_612413 = newJObject()
  var body_612414 = newJObject()
  add(query_612413, "Limit", newJString(Limit))
  if body != nil:
    body_612414 = body
  add(query_612413, "PaginationToken", newJString(PaginationToken))
  result = call_612412.call(nil, query_612413, nil, nil, body_612414)

var listUsers* = Call_ListUsers_612397(name: "listUsers", meth: HttpMethod.HttpPost,
                                    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUsers",
                                    validator: validate_ListUsers_612398,
                                    base: "/", url: url_ListUsers_612399,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsersInGroup_612415 = ref object of OpenApiRestCall_610658
proc url_ListUsersInGroup_612417(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUsersInGroup_612416(path: JsonNode; query: JsonNode;
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
  var valid_612418 = query.getOrDefault("NextToken")
  valid_612418 = validateParameter(valid_612418, JString, required = false,
                                 default = nil)
  if valid_612418 != nil:
    section.add "NextToken", valid_612418
  var valid_612419 = query.getOrDefault("Limit")
  valid_612419 = validateParameter(valid_612419, JString, required = false,
                                 default = nil)
  if valid_612419 != nil:
    section.add "Limit", valid_612419
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
  var valid_612420 = header.getOrDefault("X-Amz-Target")
  valid_612420 = validateParameter(valid_612420, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUsersInGroup"))
  if valid_612420 != nil:
    section.add "X-Amz-Target", valid_612420
  var valid_612421 = header.getOrDefault("X-Amz-Signature")
  valid_612421 = validateParameter(valid_612421, JString, required = false,
                                 default = nil)
  if valid_612421 != nil:
    section.add "X-Amz-Signature", valid_612421
  var valid_612422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612422 = validateParameter(valid_612422, JString, required = false,
                                 default = nil)
  if valid_612422 != nil:
    section.add "X-Amz-Content-Sha256", valid_612422
  var valid_612423 = header.getOrDefault("X-Amz-Date")
  valid_612423 = validateParameter(valid_612423, JString, required = false,
                                 default = nil)
  if valid_612423 != nil:
    section.add "X-Amz-Date", valid_612423
  var valid_612424 = header.getOrDefault("X-Amz-Credential")
  valid_612424 = validateParameter(valid_612424, JString, required = false,
                                 default = nil)
  if valid_612424 != nil:
    section.add "X-Amz-Credential", valid_612424
  var valid_612425 = header.getOrDefault("X-Amz-Security-Token")
  valid_612425 = validateParameter(valid_612425, JString, required = false,
                                 default = nil)
  if valid_612425 != nil:
    section.add "X-Amz-Security-Token", valid_612425
  var valid_612426 = header.getOrDefault("X-Amz-Algorithm")
  valid_612426 = validateParameter(valid_612426, JString, required = false,
                                 default = nil)
  if valid_612426 != nil:
    section.add "X-Amz-Algorithm", valid_612426
  var valid_612427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612427 = validateParameter(valid_612427, JString, required = false,
                                 default = nil)
  if valid_612427 != nil:
    section.add "X-Amz-SignedHeaders", valid_612427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612429: Call_ListUsersInGroup_612415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the users in the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_612429.validator(path, query, header, formData, body)
  let scheme = call_612429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612429.url(scheme.get, call_612429.host, call_612429.base,
                         call_612429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612429, url, valid)

proc call*(call_612430: Call_ListUsersInGroup_612415; body: JsonNode;
          NextToken: string = ""; Limit: string = ""): Recallable =
  ## listUsersInGroup
  ## <p>Lists the users in the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_612431 = newJObject()
  var body_612432 = newJObject()
  add(query_612431, "NextToken", newJString(NextToken))
  add(query_612431, "Limit", newJString(Limit))
  if body != nil:
    body_612432 = body
  result = call_612430.call(nil, query_612431, nil, nil, body_612432)

var listUsersInGroup* = Call_ListUsersInGroup_612415(name: "listUsersInGroup",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUsersInGroup",
    validator: validate_ListUsersInGroup_612416, base: "/",
    url: url_ListUsersInGroup_612417, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResendConfirmationCode_612433 = ref object of OpenApiRestCall_610658
proc url_ResendConfirmationCode_612435(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ResendConfirmationCode_612434(path: JsonNode; query: JsonNode;
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
  var valid_612436 = header.getOrDefault("X-Amz-Target")
  valid_612436 = validateParameter(valid_612436, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ResendConfirmationCode"))
  if valid_612436 != nil:
    section.add "X-Amz-Target", valid_612436
  var valid_612437 = header.getOrDefault("X-Amz-Signature")
  valid_612437 = validateParameter(valid_612437, JString, required = false,
                                 default = nil)
  if valid_612437 != nil:
    section.add "X-Amz-Signature", valid_612437
  var valid_612438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612438 = validateParameter(valid_612438, JString, required = false,
                                 default = nil)
  if valid_612438 != nil:
    section.add "X-Amz-Content-Sha256", valid_612438
  var valid_612439 = header.getOrDefault("X-Amz-Date")
  valid_612439 = validateParameter(valid_612439, JString, required = false,
                                 default = nil)
  if valid_612439 != nil:
    section.add "X-Amz-Date", valid_612439
  var valid_612440 = header.getOrDefault("X-Amz-Credential")
  valid_612440 = validateParameter(valid_612440, JString, required = false,
                                 default = nil)
  if valid_612440 != nil:
    section.add "X-Amz-Credential", valid_612440
  var valid_612441 = header.getOrDefault("X-Amz-Security-Token")
  valid_612441 = validateParameter(valid_612441, JString, required = false,
                                 default = nil)
  if valid_612441 != nil:
    section.add "X-Amz-Security-Token", valid_612441
  var valid_612442 = header.getOrDefault("X-Amz-Algorithm")
  valid_612442 = validateParameter(valid_612442, JString, required = false,
                                 default = nil)
  if valid_612442 != nil:
    section.add "X-Amz-Algorithm", valid_612442
  var valid_612443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612443 = validateParameter(valid_612443, JString, required = false,
                                 default = nil)
  if valid_612443 != nil:
    section.add "X-Amz-SignedHeaders", valid_612443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612445: Call_ResendConfirmationCode_612433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resends the confirmation (for confirmation of registration) to a specific user in the user pool.
  ## 
  let valid = call_612445.validator(path, query, header, formData, body)
  let scheme = call_612445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612445.url(scheme.get, call_612445.host, call_612445.base,
                         call_612445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612445, url, valid)

proc call*(call_612446: Call_ResendConfirmationCode_612433; body: JsonNode): Recallable =
  ## resendConfirmationCode
  ## Resends the confirmation (for confirmation of registration) to a specific user in the user pool.
  ##   body: JObject (required)
  var body_612447 = newJObject()
  if body != nil:
    body_612447 = body
  result = call_612446.call(nil, nil, nil, nil, body_612447)

var resendConfirmationCode* = Call_ResendConfirmationCode_612433(
    name: "resendConfirmationCode", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ResendConfirmationCode",
    validator: validate_ResendConfirmationCode_612434, base: "/",
    url: url_ResendConfirmationCode_612435, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RespondToAuthChallenge_612448 = ref object of OpenApiRestCall_610658
proc url_RespondToAuthChallenge_612450(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RespondToAuthChallenge_612449(path: JsonNode; query: JsonNode;
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
  var valid_612451 = header.getOrDefault("X-Amz-Target")
  valid_612451 = validateParameter(valid_612451, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.RespondToAuthChallenge"))
  if valid_612451 != nil:
    section.add "X-Amz-Target", valid_612451
  var valid_612452 = header.getOrDefault("X-Amz-Signature")
  valid_612452 = validateParameter(valid_612452, JString, required = false,
                                 default = nil)
  if valid_612452 != nil:
    section.add "X-Amz-Signature", valid_612452
  var valid_612453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612453 = validateParameter(valid_612453, JString, required = false,
                                 default = nil)
  if valid_612453 != nil:
    section.add "X-Amz-Content-Sha256", valid_612453
  var valid_612454 = header.getOrDefault("X-Amz-Date")
  valid_612454 = validateParameter(valid_612454, JString, required = false,
                                 default = nil)
  if valid_612454 != nil:
    section.add "X-Amz-Date", valid_612454
  var valid_612455 = header.getOrDefault("X-Amz-Credential")
  valid_612455 = validateParameter(valid_612455, JString, required = false,
                                 default = nil)
  if valid_612455 != nil:
    section.add "X-Amz-Credential", valid_612455
  var valid_612456 = header.getOrDefault("X-Amz-Security-Token")
  valid_612456 = validateParameter(valid_612456, JString, required = false,
                                 default = nil)
  if valid_612456 != nil:
    section.add "X-Amz-Security-Token", valid_612456
  var valid_612457 = header.getOrDefault("X-Amz-Algorithm")
  valid_612457 = validateParameter(valid_612457, JString, required = false,
                                 default = nil)
  if valid_612457 != nil:
    section.add "X-Amz-Algorithm", valid_612457
  var valid_612458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612458 = validateParameter(valid_612458, JString, required = false,
                                 default = nil)
  if valid_612458 != nil:
    section.add "X-Amz-SignedHeaders", valid_612458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612460: Call_RespondToAuthChallenge_612448; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Responds to the authentication challenge.
  ## 
  let valid = call_612460.validator(path, query, header, formData, body)
  let scheme = call_612460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612460.url(scheme.get, call_612460.host, call_612460.base,
                         call_612460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612460, url, valid)

proc call*(call_612461: Call_RespondToAuthChallenge_612448; body: JsonNode): Recallable =
  ## respondToAuthChallenge
  ## Responds to the authentication challenge.
  ##   body: JObject (required)
  var body_612462 = newJObject()
  if body != nil:
    body_612462 = body
  result = call_612461.call(nil, nil, nil, nil, body_612462)

var respondToAuthChallenge* = Call_RespondToAuthChallenge_612448(
    name: "respondToAuthChallenge", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.RespondToAuthChallenge",
    validator: validate_RespondToAuthChallenge_612449, base: "/",
    url: url_RespondToAuthChallenge_612450, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetRiskConfiguration_612463 = ref object of OpenApiRestCall_610658
proc url_SetRiskConfiguration_612465(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SetRiskConfiguration_612464(path: JsonNode; query: JsonNode;
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
  var valid_612466 = header.getOrDefault("X-Amz-Target")
  valid_612466 = validateParameter(valid_612466, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetRiskConfiguration"))
  if valid_612466 != nil:
    section.add "X-Amz-Target", valid_612466
  var valid_612467 = header.getOrDefault("X-Amz-Signature")
  valid_612467 = validateParameter(valid_612467, JString, required = false,
                                 default = nil)
  if valid_612467 != nil:
    section.add "X-Amz-Signature", valid_612467
  var valid_612468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612468 = validateParameter(valid_612468, JString, required = false,
                                 default = nil)
  if valid_612468 != nil:
    section.add "X-Amz-Content-Sha256", valid_612468
  var valid_612469 = header.getOrDefault("X-Amz-Date")
  valid_612469 = validateParameter(valid_612469, JString, required = false,
                                 default = nil)
  if valid_612469 != nil:
    section.add "X-Amz-Date", valid_612469
  var valid_612470 = header.getOrDefault("X-Amz-Credential")
  valid_612470 = validateParameter(valid_612470, JString, required = false,
                                 default = nil)
  if valid_612470 != nil:
    section.add "X-Amz-Credential", valid_612470
  var valid_612471 = header.getOrDefault("X-Amz-Security-Token")
  valid_612471 = validateParameter(valid_612471, JString, required = false,
                                 default = nil)
  if valid_612471 != nil:
    section.add "X-Amz-Security-Token", valid_612471
  var valid_612472 = header.getOrDefault("X-Amz-Algorithm")
  valid_612472 = validateParameter(valid_612472, JString, required = false,
                                 default = nil)
  if valid_612472 != nil:
    section.add "X-Amz-Algorithm", valid_612472
  var valid_612473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612473 = validateParameter(valid_612473, JString, required = false,
                                 default = nil)
  if valid_612473 != nil:
    section.add "X-Amz-SignedHeaders", valid_612473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612475: Call_SetRiskConfiguration_612463; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configures actions on detected risks. To delete the risk configuration for <code>UserPoolId</code> or <code>ClientId</code>, pass null values for all four configuration types.</p> <p>To enable Amazon Cognito advanced security features, update the user pool to include the <code>UserPoolAddOns</code> key<code>AdvancedSecurityMode</code>.</p> <p>See .</p>
  ## 
  let valid = call_612475.validator(path, query, header, formData, body)
  let scheme = call_612475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612475.url(scheme.get, call_612475.host, call_612475.base,
                         call_612475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612475, url, valid)

proc call*(call_612476: Call_SetRiskConfiguration_612463; body: JsonNode): Recallable =
  ## setRiskConfiguration
  ## <p>Configures actions on detected risks. To delete the risk configuration for <code>UserPoolId</code> or <code>ClientId</code>, pass null values for all four configuration types.</p> <p>To enable Amazon Cognito advanced security features, update the user pool to include the <code>UserPoolAddOns</code> key<code>AdvancedSecurityMode</code>.</p> <p>See .</p>
  ##   body: JObject (required)
  var body_612477 = newJObject()
  if body != nil:
    body_612477 = body
  result = call_612476.call(nil, nil, nil, nil, body_612477)

var setRiskConfiguration* = Call_SetRiskConfiguration_612463(
    name: "setRiskConfiguration", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetRiskConfiguration",
    validator: validate_SetRiskConfiguration_612464, base: "/",
    url: url_SetRiskConfiguration_612465, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUICustomization_612478 = ref object of OpenApiRestCall_610658
proc url_SetUICustomization_612480(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SetUICustomization_612479(path: JsonNode; query: JsonNode;
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
  var valid_612481 = header.getOrDefault("X-Amz-Target")
  valid_612481 = validateParameter(valid_612481, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUICustomization"))
  if valid_612481 != nil:
    section.add "X-Amz-Target", valid_612481
  var valid_612482 = header.getOrDefault("X-Amz-Signature")
  valid_612482 = validateParameter(valid_612482, JString, required = false,
                                 default = nil)
  if valid_612482 != nil:
    section.add "X-Amz-Signature", valid_612482
  var valid_612483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612483 = validateParameter(valid_612483, JString, required = false,
                                 default = nil)
  if valid_612483 != nil:
    section.add "X-Amz-Content-Sha256", valid_612483
  var valid_612484 = header.getOrDefault("X-Amz-Date")
  valid_612484 = validateParameter(valid_612484, JString, required = false,
                                 default = nil)
  if valid_612484 != nil:
    section.add "X-Amz-Date", valid_612484
  var valid_612485 = header.getOrDefault("X-Amz-Credential")
  valid_612485 = validateParameter(valid_612485, JString, required = false,
                                 default = nil)
  if valid_612485 != nil:
    section.add "X-Amz-Credential", valid_612485
  var valid_612486 = header.getOrDefault("X-Amz-Security-Token")
  valid_612486 = validateParameter(valid_612486, JString, required = false,
                                 default = nil)
  if valid_612486 != nil:
    section.add "X-Amz-Security-Token", valid_612486
  var valid_612487 = header.getOrDefault("X-Amz-Algorithm")
  valid_612487 = validateParameter(valid_612487, JString, required = false,
                                 default = nil)
  if valid_612487 != nil:
    section.add "X-Amz-Algorithm", valid_612487
  var valid_612488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612488 = validateParameter(valid_612488, JString, required = false,
                                 default = nil)
  if valid_612488 != nil:
    section.add "X-Amz-SignedHeaders", valid_612488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612490: Call_SetUICustomization_612478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the UI customization information for a user pool's built-in app UI.</p> <p>You can specify app UI customization settings for a single client (with a specific <code>clientId</code>) or for all clients (by setting the <code>clientId</code> to <code>ALL</code>). If you specify <code>ALL</code>, the default configuration will be used for every client that has no UI customization set previously. If you specify UI customization settings for a particular client, it will no longer fall back to the <code>ALL</code> configuration. </p> <note> <p>To use this API, your user pool must have a domain associated with it. Otherwise, there is no place to host the app's pages, and the service will throw an error.</p> </note>
  ## 
  let valid = call_612490.validator(path, query, header, formData, body)
  let scheme = call_612490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612490.url(scheme.get, call_612490.host, call_612490.base,
                         call_612490.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612490, url, valid)

proc call*(call_612491: Call_SetUICustomization_612478; body: JsonNode): Recallable =
  ## setUICustomization
  ## <p>Sets the UI customization information for a user pool's built-in app UI.</p> <p>You can specify app UI customization settings for a single client (with a specific <code>clientId</code>) or for all clients (by setting the <code>clientId</code> to <code>ALL</code>). If you specify <code>ALL</code>, the default configuration will be used for every client that has no UI customization set previously. If you specify UI customization settings for a particular client, it will no longer fall back to the <code>ALL</code> configuration. </p> <note> <p>To use this API, your user pool must have a domain associated with it. Otherwise, there is no place to host the app's pages, and the service will throw an error.</p> </note>
  ##   body: JObject (required)
  var body_612492 = newJObject()
  if body != nil:
    body_612492 = body
  result = call_612491.call(nil, nil, nil, nil, body_612492)

var setUICustomization* = Call_SetUICustomization_612478(
    name: "setUICustomization", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUICustomization",
    validator: validate_SetUICustomization_612479, base: "/",
    url: url_SetUICustomization_612480, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUserMFAPreference_612493 = ref object of OpenApiRestCall_610658
proc url_SetUserMFAPreference_612495(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SetUserMFAPreference_612494(path: JsonNode; query: JsonNode;
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
  var valid_612496 = header.getOrDefault("X-Amz-Target")
  valid_612496 = validateParameter(valid_612496, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUserMFAPreference"))
  if valid_612496 != nil:
    section.add "X-Amz-Target", valid_612496
  var valid_612497 = header.getOrDefault("X-Amz-Signature")
  valid_612497 = validateParameter(valid_612497, JString, required = false,
                                 default = nil)
  if valid_612497 != nil:
    section.add "X-Amz-Signature", valid_612497
  var valid_612498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612498 = validateParameter(valid_612498, JString, required = false,
                                 default = nil)
  if valid_612498 != nil:
    section.add "X-Amz-Content-Sha256", valid_612498
  var valid_612499 = header.getOrDefault("X-Amz-Date")
  valid_612499 = validateParameter(valid_612499, JString, required = false,
                                 default = nil)
  if valid_612499 != nil:
    section.add "X-Amz-Date", valid_612499
  var valid_612500 = header.getOrDefault("X-Amz-Credential")
  valid_612500 = validateParameter(valid_612500, JString, required = false,
                                 default = nil)
  if valid_612500 != nil:
    section.add "X-Amz-Credential", valid_612500
  var valid_612501 = header.getOrDefault("X-Amz-Security-Token")
  valid_612501 = validateParameter(valid_612501, JString, required = false,
                                 default = nil)
  if valid_612501 != nil:
    section.add "X-Amz-Security-Token", valid_612501
  var valid_612502 = header.getOrDefault("X-Amz-Algorithm")
  valid_612502 = validateParameter(valid_612502, JString, required = false,
                                 default = nil)
  if valid_612502 != nil:
    section.add "X-Amz-Algorithm", valid_612502
  var valid_612503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612503 = validateParameter(valid_612503, JString, required = false,
                                 default = nil)
  if valid_612503 != nil:
    section.add "X-Amz-SignedHeaders", valid_612503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612505: Call_SetUserMFAPreference_612493; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the user's multi-factor authentication (MFA) method preference, including which MFA factors are enabled and if any are preferred. Only one factor can be set as preferred. The preferred MFA factor will be used to authenticate a user if multiple factors are enabled. If multiple options are enabled and no preference is set, a challenge to choose an MFA option will be returned during sign in.
  ## 
  let valid = call_612505.validator(path, query, header, formData, body)
  let scheme = call_612505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612505.url(scheme.get, call_612505.host, call_612505.base,
                         call_612505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612505, url, valid)

proc call*(call_612506: Call_SetUserMFAPreference_612493; body: JsonNode): Recallable =
  ## setUserMFAPreference
  ## Set the user's multi-factor authentication (MFA) method preference, including which MFA factors are enabled and if any are preferred. Only one factor can be set as preferred. The preferred MFA factor will be used to authenticate a user if multiple factors are enabled. If multiple options are enabled and no preference is set, a challenge to choose an MFA option will be returned during sign in.
  ##   body: JObject (required)
  var body_612507 = newJObject()
  if body != nil:
    body_612507 = body
  result = call_612506.call(nil, nil, nil, nil, body_612507)

var setUserMFAPreference* = Call_SetUserMFAPreference_612493(
    name: "setUserMFAPreference", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUserMFAPreference",
    validator: validate_SetUserMFAPreference_612494, base: "/",
    url: url_SetUserMFAPreference_612495, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUserPoolMfaConfig_612508 = ref object of OpenApiRestCall_610658
proc url_SetUserPoolMfaConfig_612510(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SetUserPoolMfaConfig_612509(path: JsonNode; query: JsonNode;
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
  var valid_612511 = header.getOrDefault("X-Amz-Target")
  valid_612511 = validateParameter(valid_612511, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUserPoolMfaConfig"))
  if valid_612511 != nil:
    section.add "X-Amz-Target", valid_612511
  var valid_612512 = header.getOrDefault("X-Amz-Signature")
  valid_612512 = validateParameter(valid_612512, JString, required = false,
                                 default = nil)
  if valid_612512 != nil:
    section.add "X-Amz-Signature", valid_612512
  var valid_612513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612513 = validateParameter(valid_612513, JString, required = false,
                                 default = nil)
  if valid_612513 != nil:
    section.add "X-Amz-Content-Sha256", valid_612513
  var valid_612514 = header.getOrDefault("X-Amz-Date")
  valid_612514 = validateParameter(valid_612514, JString, required = false,
                                 default = nil)
  if valid_612514 != nil:
    section.add "X-Amz-Date", valid_612514
  var valid_612515 = header.getOrDefault("X-Amz-Credential")
  valid_612515 = validateParameter(valid_612515, JString, required = false,
                                 default = nil)
  if valid_612515 != nil:
    section.add "X-Amz-Credential", valid_612515
  var valid_612516 = header.getOrDefault("X-Amz-Security-Token")
  valid_612516 = validateParameter(valid_612516, JString, required = false,
                                 default = nil)
  if valid_612516 != nil:
    section.add "X-Amz-Security-Token", valid_612516
  var valid_612517 = header.getOrDefault("X-Amz-Algorithm")
  valid_612517 = validateParameter(valid_612517, JString, required = false,
                                 default = nil)
  if valid_612517 != nil:
    section.add "X-Amz-Algorithm", valid_612517
  var valid_612518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612518 = validateParameter(valid_612518, JString, required = false,
                                 default = nil)
  if valid_612518 != nil:
    section.add "X-Amz-SignedHeaders", valid_612518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612520: Call_SetUserPoolMfaConfig_612508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the user pool multi-factor authentication (MFA) configuration.
  ## 
  let valid = call_612520.validator(path, query, header, formData, body)
  let scheme = call_612520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612520.url(scheme.get, call_612520.host, call_612520.base,
                         call_612520.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612520, url, valid)

proc call*(call_612521: Call_SetUserPoolMfaConfig_612508; body: JsonNode): Recallable =
  ## setUserPoolMfaConfig
  ## Set the user pool multi-factor authentication (MFA) configuration.
  ##   body: JObject (required)
  var body_612522 = newJObject()
  if body != nil:
    body_612522 = body
  result = call_612521.call(nil, nil, nil, nil, body_612522)

var setUserPoolMfaConfig* = Call_SetUserPoolMfaConfig_612508(
    name: "setUserPoolMfaConfig", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUserPoolMfaConfig",
    validator: validate_SetUserPoolMfaConfig_612509, base: "/",
    url: url_SetUserPoolMfaConfig_612510, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUserSettings_612523 = ref object of OpenApiRestCall_610658
proc url_SetUserSettings_612525(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SetUserSettings_612524(path: JsonNode; query: JsonNode;
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
  var valid_612526 = header.getOrDefault("X-Amz-Target")
  valid_612526 = validateParameter(valid_612526, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUserSettings"))
  if valid_612526 != nil:
    section.add "X-Amz-Target", valid_612526
  var valid_612527 = header.getOrDefault("X-Amz-Signature")
  valid_612527 = validateParameter(valid_612527, JString, required = false,
                                 default = nil)
  if valid_612527 != nil:
    section.add "X-Amz-Signature", valid_612527
  var valid_612528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612528 = validateParameter(valid_612528, JString, required = false,
                                 default = nil)
  if valid_612528 != nil:
    section.add "X-Amz-Content-Sha256", valid_612528
  var valid_612529 = header.getOrDefault("X-Amz-Date")
  valid_612529 = validateParameter(valid_612529, JString, required = false,
                                 default = nil)
  if valid_612529 != nil:
    section.add "X-Amz-Date", valid_612529
  var valid_612530 = header.getOrDefault("X-Amz-Credential")
  valid_612530 = validateParameter(valid_612530, JString, required = false,
                                 default = nil)
  if valid_612530 != nil:
    section.add "X-Amz-Credential", valid_612530
  var valid_612531 = header.getOrDefault("X-Amz-Security-Token")
  valid_612531 = validateParameter(valid_612531, JString, required = false,
                                 default = nil)
  if valid_612531 != nil:
    section.add "X-Amz-Security-Token", valid_612531
  var valid_612532 = header.getOrDefault("X-Amz-Algorithm")
  valid_612532 = validateParameter(valid_612532, JString, required = false,
                                 default = nil)
  if valid_612532 != nil:
    section.add "X-Amz-Algorithm", valid_612532
  var valid_612533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612533 = validateParameter(valid_612533, JString, required = false,
                                 default = nil)
  if valid_612533 != nil:
    section.add "X-Amz-SignedHeaders", valid_612533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612535: Call_SetUserSettings_612523; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <i>This action is no longer supported.</i> You can use it to configure only SMS MFA. You can't use it to configure TOTP software token MFA. To configure either type of MFA, use the <a>SetUserMFAPreference</a> action instead.
  ## 
  let valid = call_612535.validator(path, query, header, formData, body)
  let scheme = call_612535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612535.url(scheme.get, call_612535.host, call_612535.base,
                         call_612535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612535, url, valid)

proc call*(call_612536: Call_SetUserSettings_612523; body: JsonNode): Recallable =
  ## setUserSettings
  ##  <i>This action is no longer supported.</i> You can use it to configure only SMS MFA. You can't use it to configure TOTP software token MFA. To configure either type of MFA, use the <a>SetUserMFAPreference</a> action instead.
  ##   body: JObject (required)
  var body_612537 = newJObject()
  if body != nil:
    body_612537 = body
  result = call_612536.call(nil, nil, nil, nil, body_612537)

var setUserSettings* = Call_SetUserSettings_612523(name: "setUserSettings",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUserSettings",
    validator: validate_SetUserSettings_612524, base: "/", url: url_SetUserSettings_612525,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SignUp_612538 = ref object of OpenApiRestCall_610658
proc url_SignUp_612540(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SignUp_612539(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612541 = header.getOrDefault("X-Amz-Target")
  valid_612541 = validateParameter(valid_612541, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SignUp"))
  if valid_612541 != nil:
    section.add "X-Amz-Target", valid_612541
  var valid_612542 = header.getOrDefault("X-Amz-Signature")
  valid_612542 = validateParameter(valid_612542, JString, required = false,
                                 default = nil)
  if valid_612542 != nil:
    section.add "X-Amz-Signature", valid_612542
  var valid_612543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612543 = validateParameter(valid_612543, JString, required = false,
                                 default = nil)
  if valid_612543 != nil:
    section.add "X-Amz-Content-Sha256", valid_612543
  var valid_612544 = header.getOrDefault("X-Amz-Date")
  valid_612544 = validateParameter(valid_612544, JString, required = false,
                                 default = nil)
  if valid_612544 != nil:
    section.add "X-Amz-Date", valid_612544
  var valid_612545 = header.getOrDefault("X-Amz-Credential")
  valid_612545 = validateParameter(valid_612545, JString, required = false,
                                 default = nil)
  if valid_612545 != nil:
    section.add "X-Amz-Credential", valid_612545
  var valid_612546 = header.getOrDefault("X-Amz-Security-Token")
  valid_612546 = validateParameter(valid_612546, JString, required = false,
                                 default = nil)
  if valid_612546 != nil:
    section.add "X-Amz-Security-Token", valid_612546
  var valid_612547 = header.getOrDefault("X-Amz-Algorithm")
  valid_612547 = validateParameter(valid_612547, JString, required = false,
                                 default = nil)
  if valid_612547 != nil:
    section.add "X-Amz-Algorithm", valid_612547
  var valid_612548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612548 = validateParameter(valid_612548, JString, required = false,
                                 default = nil)
  if valid_612548 != nil:
    section.add "X-Amz-SignedHeaders", valid_612548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612550: Call_SignUp_612538; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers the user in the specified user pool and creates a user name, password, and user attributes.
  ## 
  let valid = call_612550.validator(path, query, header, formData, body)
  let scheme = call_612550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612550.url(scheme.get, call_612550.host, call_612550.base,
                         call_612550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612550, url, valid)

proc call*(call_612551: Call_SignUp_612538; body: JsonNode): Recallable =
  ## signUp
  ## Registers the user in the specified user pool and creates a user name, password, and user attributes.
  ##   body: JObject (required)
  var body_612552 = newJObject()
  if body != nil:
    body_612552 = body
  result = call_612551.call(nil, nil, nil, nil, body_612552)

var signUp* = Call_SignUp_612538(name: "signUp", meth: HttpMethod.HttpPost,
                              host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SignUp",
                              validator: validate_SignUp_612539, base: "/",
                              url: url_SignUp_612540,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartUserImportJob_612553 = ref object of OpenApiRestCall_610658
proc url_StartUserImportJob_612555(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartUserImportJob_612554(path: JsonNode; query: JsonNode;
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
  var valid_612556 = header.getOrDefault("X-Amz-Target")
  valid_612556 = validateParameter(valid_612556, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.StartUserImportJob"))
  if valid_612556 != nil:
    section.add "X-Amz-Target", valid_612556
  var valid_612557 = header.getOrDefault("X-Amz-Signature")
  valid_612557 = validateParameter(valid_612557, JString, required = false,
                                 default = nil)
  if valid_612557 != nil:
    section.add "X-Amz-Signature", valid_612557
  var valid_612558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612558 = validateParameter(valid_612558, JString, required = false,
                                 default = nil)
  if valid_612558 != nil:
    section.add "X-Amz-Content-Sha256", valid_612558
  var valid_612559 = header.getOrDefault("X-Amz-Date")
  valid_612559 = validateParameter(valid_612559, JString, required = false,
                                 default = nil)
  if valid_612559 != nil:
    section.add "X-Amz-Date", valid_612559
  var valid_612560 = header.getOrDefault("X-Amz-Credential")
  valid_612560 = validateParameter(valid_612560, JString, required = false,
                                 default = nil)
  if valid_612560 != nil:
    section.add "X-Amz-Credential", valid_612560
  var valid_612561 = header.getOrDefault("X-Amz-Security-Token")
  valid_612561 = validateParameter(valid_612561, JString, required = false,
                                 default = nil)
  if valid_612561 != nil:
    section.add "X-Amz-Security-Token", valid_612561
  var valid_612562 = header.getOrDefault("X-Amz-Algorithm")
  valid_612562 = validateParameter(valid_612562, JString, required = false,
                                 default = nil)
  if valid_612562 != nil:
    section.add "X-Amz-Algorithm", valid_612562
  var valid_612563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612563 = validateParameter(valid_612563, JString, required = false,
                                 default = nil)
  if valid_612563 != nil:
    section.add "X-Amz-SignedHeaders", valid_612563
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612565: Call_StartUserImportJob_612553; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the user import.
  ## 
  let valid = call_612565.validator(path, query, header, formData, body)
  let scheme = call_612565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612565.url(scheme.get, call_612565.host, call_612565.base,
                         call_612565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612565, url, valid)

proc call*(call_612566: Call_StartUserImportJob_612553; body: JsonNode): Recallable =
  ## startUserImportJob
  ## Starts the user import.
  ##   body: JObject (required)
  var body_612567 = newJObject()
  if body != nil:
    body_612567 = body
  result = call_612566.call(nil, nil, nil, nil, body_612567)

var startUserImportJob* = Call_StartUserImportJob_612553(
    name: "startUserImportJob", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.StartUserImportJob",
    validator: validate_StartUserImportJob_612554, base: "/",
    url: url_StartUserImportJob_612555, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopUserImportJob_612568 = ref object of OpenApiRestCall_610658
proc url_StopUserImportJob_612570(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopUserImportJob_612569(path: JsonNode; query: JsonNode;
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
  var valid_612571 = header.getOrDefault("X-Amz-Target")
  valid_612571 = validateParameter(valid_612571, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.StopUserImportJob"))
  if valid_612571 != nil:
    section.add "X-Amz-Target", valid_612571
  var valid_612572 = header.getOrDefault("X-Amz-Signature")
  valid_612572 = validateParameter(valid_612572, JString, required = false,
                                 default = nil)
  if valid_612572 != nil:
    section.add "X-Amz-Signature", valid_612572
  var valid_612573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612573 = validateParameter(valid_612573, JString, required = false,
                                 default = nil)
  if valid_612573 != nil:
    section.add "X-Amz-Content-Sha256", valid_612573
  var valid_612574 = header.getOrDefault("X-Amz-Date")
  valid_612574 = validateParameter(valid_612574, JString, required = false,
                                 default = nil)
  if valid_612574 != nil:
    section.add "X-Amz-Date", valid_612574
  var valid_612575 = header.getOrDefault("X-Amz-Credential")
  valid_612575 = validateParameter(valid_612575, JString, required = false,
                                 default = nil)
  if valid_612575 != nil:
    section.add "X-Amz-Credential", valid_612575
  var valid_612576 = header.getOrDefault("X-Amz-Security-Token")
  valid_612576 = validateParameter(valid_612576, JString, required = false,
                                 default = nil)
  if valid_612576 != nil:
    section.add "X-Amz-Security-Token", valid_612576
  var valid_612577 = header.getOrDefault("X-Amz-Algorithm")
  valid_612577 = validateParameter(valid_612577, JString, required = false,
                                 default = nil)
  if valid_612577 != nil:
    section.add "X-Amz-Algorithm", valid_612577
  var valid_612578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612578 = validateParameter(valid_612578, JString, required = false,
                                 default = nil)
  if valid_612578 != nil:
    section.add "X-Amz-SignedHeaders", valid_612578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612580: Call_StopUserImportJob_612568; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the user import job.
  ## 
  let valid = call_612580.validator(path, query, header, formData, body)
  let scheme = call_612580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612580.url(scheme.get, call_612580.host, call_612580.base,
                         call_612580.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612580, url, valid)

proc call*(call_612581: Call_StopUserImportJob_612568; body: JsonNode): Recallable =
  ## stopUserImportJob
  ## Stops the user import job.
  ##   body: JObject (required)
  var body_612582 = newJObject()
  if body != nil:
    body_612582 = body
  result = call_612581.call(nil, nil, nil, nil, body_612582)

var stopUserImportJob* = Call_StopUserImportJob_612568(name: "stopUserImportJob",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.StopUserImportJob",
    validator: validate_StopUserImportJob_612569, base: "/",
    url: url_StopUserImportJob_612570, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_612583 = ref object of OpenApiRestCall_610658
proc url_TagResource_612585(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_612584(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612586 = header.getOrDefault("X-Amz-Target")
  valid_612586 = validateParameter(valid_612586, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.TagResource"))
  if valid_612586 != nil:
    section.add "X-Amz-Target", valid_612586
  var valid_612587 = header.getOrDefault("X-Amz-Signature")
  valid_612587 = validateParameter(valid_612587, JString, required = false,
                                 default = nil)
  if valid_612587 != nil:
    section.add "X-Amz-Signature", valid_612587
  var valid_612588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612588 = validateParameter(valid_612588, JString, required = false,
                                 default = nil)
  if valid_612588 != nil:
    section.add "X-Amz-Content-Sha256", valid_612588
  var valid_612589 = header.getOrDefault("X-Amz-Date")
  valid_612589 = validateParameter(valid_612589, JString, required = false,
                                 default = nil)
  if valid_612589 != nil:
    section.add "X-Amz-Date", valid_612589
  var valid_612590 = header.getOrDefault("X-Amz-Credential")
  valid_612590 = validateParameter(valid_612590, JString, required = false,
                                 default = nil)
  if valid_612590 != nil:
    section.add "X-Amz-Credential", valid_612590
  var valid_612591 = header.getOrDefault("X-Amz-Security-Token")
  valid_612591 = validateParameter(valid_612591, JString, required = false,
                                 default = nil)
  if valid_612591 != nil:
    section.add "X-Amz-Security-Token", valid_612591
  var valid_612592 = header.getOrDefault("X-Amz-Algorithm")
  valid_612592 = validateParameter(valid_612592, JString, required = false,
                                 default = nil)
  if valid_612592 != nil:
    section.add "X-Amz-Algorithm", valid_612592
  var valid_612593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612593 = validateParameter(valid_612593, JString, required = false,
                                 default = nil)
  if valid_612593 != nil:
    section.add "X-Amz-SignedHeaders", valid_612593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612595: Call_TagResource_612583; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns a set of tags to an Amazon Cognito user pool. A tag is a label that you can use to categorize and manage user pools in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>Each tag consists of a key and value, both of which you define. A key is a general category for more specific values. For example, if you have two versions of a user pool, one for testing and another for production, you might assign an <code>Environment</code> tag key to both user pools. The value of this key might be <code>Test</code> for one user pool and <code>Production</code> for the other.</p> <p>Tags are useful for cost tracking and access control. You can activate your tags so that they appear on the Billing and Cost Management console, where you can track the costs associated with your user pools. In an IAM policy, you can constrain permissions for user pools based on specific tags or tag values.</p> <p>You can use this action up to 5 times per second, per account. A user pool can have as many as 50 tags.</p>
  ## 
  let valid = call_612595.validator(path, query, header, formData, body)
  let scheme = call_612595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612595.url(scheme.get, call_612595.host, call_612595.base,
                         call_612595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612595, url, valid)

proc call*(call_612596: Call_TagResource_612583; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Assigns a set of tags to an Amazon Cognito user pool. A tag is a label that you can use to categorize and manage user pools in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>Each tag consists of a key and value, both of which you define. A key is a general category for more specific values. For example, if you have two versions of a user pool, one for testing and another for production, you might assign an <code>Environment</code> tag key to both user pools. The value of this key might be <code>Test</code> for one user pool and <code>Production</code> for the other.</p> <p>Tags are useful for cost tracking and access control. You can activate your tags so that they appear on the Billing and Cost Management console, where you can track the costs associated with your user pools. In an IAM policy, you can constrain permissions for user pools based on specific tags or tag values.</p> <p>You can use this action up to 5 times per second, per account. A user pool can have as many as 50 tags.</p>
  ##   body: JObject (required)
  var body_612597 = newJObject()
  if body != nil:
    body_612597 = body
  result = call_612596.call(nil, nil, nil, nil, body_612597)

var tagResource* = Call_TagResource_612583(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.TagResource",
                                        validator: validate_TagResource_612584,
                                        base: "/", url: url_TagResource_612585,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_612598 = ref object of OpenApiRestCall_610658
proc url_UntagResource_612600(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_612599(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612601 = header.getOrDefault("X-Amz-Target")
  valid_612601 = validateParameter(valid_612601, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UntagResource"))
  if valid_612601 != nil:
    section.add "X-Amz-Target", valid_612601
  var valid_612602 = header.getOrDefault("X-Amz-Signature")
  valid_612602 = validateParameter(valid_612602, JString, required = false,
                                 default = nil)
  if valid_612602 != nil:
    section.add "X-Amz-Signature", valid_612602
  var valid_612603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612603 = validateParameter(valid_612603, JString, required = false,
                                 default = nil)
  if valid_612603 != nil:
    section.add "X-Amz-Content-Sha256", valid_612603
  var valid_612604 = header.getOrDefault("X-Amz-Date")
  valid_612604 = validateParameter(valid_612604, JString, required = false,
                                 default = nil)
  if valid_612604 != nil:
    section.add "X-Amz-Date", valid_612604
  var valid_612605 = header.getOrDefault("X-Amz-Credential")
  valid_612605 = validateParameter(valid_612605, JString, required = false,
                                 default = nil)
  if valid_612605 != nil:
    section.add "X-Amz-Credential", valid_612605
  var valid_612606 = header.getOrDefault("X-Amz-Security-Token")
  valid_612606 = validateParameter(valid_612606, JString, required = false,
                                 default = nil)
  if valid_612606 != nil:
    section.add "X-Amz-Security-Token", valid_612606
  var valid_612607 = header.getOrDefault("X-Amz-Algorithm")
  valid_612607 = validateParameter(valid_612607, JString, required = false,
                                 default = nil)
  if valid_612607 != nil:
    section.add "X-Amz-Algorithm", valid_612607
  var valid_612608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612608 = validateParameter(valid_612608, JString, required = false,
                                 default = nil)
  if valid_612608 != nil:
    section.add "X-Amz-SignedHeaders", valid_612608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612610: Call_UntagResource_612598; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified tags from an Amazon Cognito user pool. You can use this action up to 5 times per second, per account
  ## 
  let valid = call_612610.validator(path, query, header, formData, body)
  let scheme = call_612610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612610.url(scheme.get, call_612610.host, call_612610.base,
                         call_612610.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612610, url, valid)

proc call*(call_612611: Call_UntagResource_612598; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tags from an Amazon Cognito user pool. You can use this action up to 5 times per second, per account
  ##   body: JObject (required)
  var body_612612 = newJObject()
  if body != nil:
    body_612612 = body
  result = call_612611.call(nil, nil, nil, nil, body_612612)

var untagResource* = Call_UntagResource_612598(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UntagResource",
    validator: validate_UntagResource_612599, base: "/", url: url_UntagResource_612600,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthEventFeedback_612613 = ref object of OpenApiRestCall_610658
proc url_UpdateAuthEventFeedback_612615(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateAuthEventFeedback_612614(path: JsonNode; query: JsonNode;
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
  var valid_612616 = header.getOrDefault("X-Amz-Target")
  valid_612616 = validateParameter(valid_612616, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateAuthEventFeedback"))
  if valid_612616 != nil:
    section.add "X-Amz-Target", valid_612616
  var valid_612617 = header.getOrDefault("X-Amz-Signature")
  valid_612617 = validateParameter(valid_612617, JString, required = false,
                                 default = nil)
  if valid_612617 != nil:
    section.add "X-Amz-Signature", valid_612617
  var valid_612618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612618 = validateParameter(valid_612618, JString, required = false,
                                 default = nil)
  if valid_612618 != nil:
    section.add "X-Amz-Content-Sha256", valid_612618
  var valid_612619 = header.getOrDefault("X-Amz-Date")
  valid_612619 = validateParameter(valid_612619, JString, required = false,
                                 default = nil)
  if valid_612619 != nil:
    section.add "X-Amz-Date", valid_612619
  var valid_612620 = header.getOrDefault("X-Amz-Credential")
  valid_612620 = validateParameter(valid_612620, JString, required = false,
                                 default = nil)
  if valid_612620 != nil:
    section.add "X-Amz-Credential", valid_612620
  var valid_612621 = header.getOrDefault("X-Amz-Security-Token")
  valid_612621 = validateParameter(valid_612621, JString, required = false,
                                 default = nil)
  if valid_612621 != nil:
    section.add "X-Amz-Security-Token", valid_612621
  var valid_612622 = header.getOrDefault("X-Amz-Algorithm")
  valid_612622 = validateParameter(valid_612622, JString, required = false,
                                 default = nil)
  if valid_612622 != nil:
    section.add "X-Amz-Algorithm", valid_612622
  var valid_612623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612623 = validateParameter(valid_612623, JString, required = false,
                                 default = nil)
  if valid_612623 != nil:
    section.add "X-Amz-SignedHeaders", valid_612623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612625: Call_UpdateAuthEventFeedback_612613; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the feedback for an authentication event whether it was from a valid user or not. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ## 
  let valid = call_612625.validator(path, query, header, formData, body)
  let scheme = call_612625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612625.url(scheme.get, call_612625.host, call_612625.base,
                         call_612625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612625, url, valid)

proc call*(call_612626: Call_UpdateAuthEventFeedback_612613; body: JsonNode): Recallable =
  ## updateAuthEventFeedback
  ## Provides the feedback for an authentication event whether it was from a valid user or not. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ##   body: JObject (required)
  var body_612627 = newJObject()
  if body != nil:
    body_612627 = body
  result = call_612626.call(nil, nil, nil, nil, body_612627)

var updateAuthEventFeedback* = Call_UpdateAuthEventFeedback_612613(
    name: "updateAuthEventFeedback", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateAuthEventFeedback",
    validator: validate_UpdateAuthEventFeedback_612614, base: "/",
    url: url_UpdateAuthEventFeedback_612615, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceStatus_612628 = ref object of OpenApiRestCall_610658
proc url_UpdateDeviceStatus_612630(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDeviceStatus_612629(path: JsonNode; query: JsonNode;
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
  var valid_612631 = header.getOrDefault("X-Amz-Target")
  valid_612631 = validateParameter(valid_612631, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateDeviceStatus"))
  if valid_612631 != nil:
    section.add "X-Amz-Target", valid_612631
  var valid_612632 = header.getOrDefault("X-Amz-Signature")
  valid_612632 = validateParameter(valid_612632, JString, required = false,
                                 default = nil)
  if valid_612632 != nil:
    section.add "X-Amz-Signature", valid_612632
  var valid_612633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612633 = validateParameter(valid_612633, JString, required = false,
                                 default = nil)
  if valid_612633 != nil:
    section.add "X-Amz-Content-Sha256", valid_612633
  var valid_612634 = header.getOrDefault("X-Amz-Date")
  valid_612634 = validateParameter(valid_612634, JString, required = false,
                                 default = nil)
  if valid_612634 != nil:
    section.add "X-Amz-Date", valid_612634
  var valid_612635 = header.getOrDefault("X-Amz-Credential")
  valid_612635 = validateParameter(valid_612635, JString, required = false,
                                 default = nil)
  if valid_612635 != nil:
    section.add "X-Amz-Credential", valid_612635
  var valid_612636 = header.getOrDefault("X-Amz-Security-Token")
  valid_612636 = validateParameter(valid_612636, JString, required = false,
                                 default = nil)
  if valid_612636 != nil:
    section.add "X-Amz-Security-Token", valid_612636
  var valid_612637 = header.getOrDefault("X-Amz-Algorithm")
  valid_612637 = validateParameter(valid_612637, JString, required = false,
                                 default = nil)
  if valid_612637 != nil:
    section.add "X-Amz-Algorithm", valid_612637
  var valid_612638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612638 = validateParameter(valid_612638, JString, required = false,
                                 default = nil)
  if valid_612638 != nil:
    section.add "X-Amz-SignedHeaders", valid_612638
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612640: Call_UpdateDeviceStatus_612628; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the device status.
  ## 
  let valid = call_612640.validator(path, query, header, formData, body)
  let scheme = call_612640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612640.url(scheme.get, call_612640.host, call_612640.base,
                         call_612640.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612640, url, valid)

proc call*(call_612641: Call_UpdateDeviceStatus_612628; body: JsonNode): Recallable =
  ## updateDeviceStatus
  ## Updates the device status.
  ##   body: JObject (required)
  var body_612642 = newJObject()
  if body != nil:
    body_612642 = body
  result = call_612641.call(nil, nil, nil, nil, body_612642)

var updateDeviceStatus* = Call_UpdateDeviceStatus_612628(
    name: "updateDeviceStatus", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateDeviceStatus",
    validator: validate_UpdateDeviceStatus_612629, base: "/",
    url: url_UpdateDeviceStatus_612630, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_612643 = ref object of OpenApiRestCall_610658
proc url_UpdateGroup_612645(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateGroup_612644(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612646 = header.getOrDefault("X-Amz-Target")
  valid_612646 = validateParameter(valid_612646, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateGroup"))
  if valid_612646 != nil:
    section.add "X-Amz-Target", valid_612646
  var valid_612647 = header.getOrDefault("X-Amz-Signature")
  valid_612647 = validateParameter(valid_612647, JString, required = false,
                                 default = nil)
  if valid_612647 != nil:
    section.add "X-Amz-Signature", valid_612647
  var valid_612648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612648 = validateParameter(valid_612648, JString, required = false,
                                 default = nil)
  if valid_612648 != nil:
    section.add "X-Amz-Content-Sha256", valid_612648
  var valid_612649 = header.getOrDefault("X-Amz-Date")
  valid_612649 = validateParameter(valid_612649, JString, required = false,
                                 default = nil)
  if valid_612649 != nil:
    section.add "X-Amz-Date", valid_612649
  var valid_612650 = header.getOrDefault("X-Amz-Credential")
  valid_612650 = validateParameter(valid_612650, JString, required = false,
                                 default = nil)
  if valid_612650 != nil:
    section.add "X-Amz-Credential", valid_612650
  var valid_612651 = header.getOrDefault("X-Amz-Security-Token")
  valid_612651 = validateParameter(valid_612651, JString, required = false,
                                 default = nil)
  if valid_612651 != nil:
    section.add "X-Amz-Security-Token", valid_612651
  var valid_612652 = header.getOrDefault("X-Amz-Algorithm")
  valid_612652 = validateParameter(valid_612652, JString, required = false,
                                 default = nil)
  if valid_612652 != nil:
    section.add "X-Amz-Algorithm", valid_612652
  var valid_612653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612653 = validateParameter(valid_612653, JString, required = false,
                                 default = nil)
  if valid_612653 != nil:
    section.add "X-Amz-SignedHeaders", valid_612653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612655: Call_UpdateGroup_612643; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified group with the specified attributes.</p> <p>Calling this action requires developer credentials.</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ## 
  let valid = call_612655.validator(path, query, header, formData, body)
  let scheme = call_612655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612655.url(scheme.get, call_612655.host, call_612655.base,
                         call_612655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612655, url, valid)

proc call*(call_612656: Call_UpdateGroup_612643; body: JsonNode): Recallable =
  ## updateGroup
  ## <p>Updates the specified group with the specified attributes.</p> <p>Calling this action requires developer credentials.</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ##   body: JObject (required)
  var body_612657 = newJObject()
  if body != nil:
    body_612657 = body
  result = call_612656.call(nil, nil, nil, nil, body_612657)

var updateGroup* = Call_UpdateGroup_612643(name: "updateGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateGroup",
                                        validator: validate_UpdateGroup_612644,
                                        base: "/", url: url_UpdateGroup_612645,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIdentityProvider_612658 = ref object of OpenApiRestCall_610658
proc url_UpdateIdentityProvider_612660(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateIdentityProvider_612659(path: JsonNode; query: JsonNode;
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
  var valid_612661 = header.getOrDefault("X-Amz-Target")
  valid_612661 = validateParameter(valid_612661, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateIdentityProvider"))
  if valid_612661 != nil:
    section.add "X-Amz-Target", valid_612661
  var valid_612662 = header.getOrDefault("X-Amz-Signature")
  valid_612662 = validateParameter(valid_612662, JString, required = false,
                                 default = nil)
  if valid_612662 != nil:
    section.add "X-Amz-Signature", valid_612662
  var valid_612663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612663 = validateParameter(valid_612663, JString, required = false,
                                 default = nil)
  if valid_612663 != nil:
    section.add "X-Amz-Content-Sha256", valid_612663
  var valid_612664 = header.getOrDefault("X-Amz-Date")
  valid_612664 = validateParameter(valid_612664, JString, required = false,
                                 default = nil)
  if valid_612664 != nil:
    section.add "X-Amz-Date", valid_612664
  var valid_612665 = header.getOrDefault("X-Amz-Credential")
  valid_612665 = validateParameter(valid_612665, JString, required = false,
                                 default = nil)
  if valid_612665 != nil:
    section.add "X-Amz-Credential", valid_612665
  var valid_612666 = header.getOrDefault("X-Amz-Security-Token")
  valid_612666 = validateParameter(valid_612666, JString, required = false,
                                 default = nil)
  if valid_612666 != nil:
    section.add "X-Amz-Security-Token", valid_612666
  var valid_612667 = header.getOrDefault("X-Amz-Algorithm")
  valid_612667 = validateParameter(valid_612667, JString, required = false,
                                 default = nil)
  if valid_612667 != nil:
    section.add "X-Amz-Algorithm", valid_612667
  var valid_612668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612668 = validateParameter(valid_612668, JString, required = false,
                                 default = nil)
  if valid_612668 != nil:
    section.add "X-Amz-SignedHeaders", valid_612668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612670: Call_UpdateIdentityProvider_612658; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates identity provider information for a user pool.
  ## 
  let valid = call_612670.validator(path, query, header, formData, body)
  let scheme = call_612670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612670.url(scheme.get, call_612670.host, call_612670.base,
                         call_612670.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612670, url, valid)

proc call*(call_612671: Call_UpdateIdentityProvider_612658; body: JsonNode): Recallable =
  ## updateIdentityProvider
  ## Updates identity provider information for a user pool.
  ##   body: JObject (required)
  var body_612672 = newJObject()
  if body != nil:
    body_612672 = body
  result = call_612671.call(nil, nil, nil, nil, body_612672)

var updateIdentityProvider* = Call_UpdateIdentityProvider_612658(
    name: "updateIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateIdentityProvider",
    validator: validate_UpdateIdentityProvider_612659, base: "/",
    url: url_UpdateIdentityProvider_612660, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceServer_612673 = ref object of OpenApiRestCall_610658
proc url_UpdateResourceServer_612675(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateResourceServer_612674(path: JsonNode; query: JsonNode;
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
  var valid_612676 = header.getOrDefault("X-Amz-Target")
  valid_612676 = validateParameter(valid_612676, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateResourceServer"))
  if valid_612676 != nil:
    section.add "X-Amz-Target", valid_612676
  var valid_612677 = header.getOrDefault("X-Amz-Signature")
  valid_612677 = validateParameter(valid_612677, JString, required = false,
                                 default = nil)
  if valid_612677 != nil:
    section.add "X-Amz-Signature", valid_612677
  var valid_612678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612678 = validateParameter(valid_612678, JString, required = false,
                                 default = nil)
  if valid_612678 != nil:
    section.add "X-Amz-Content-Sha256", valid_612678
  var valid_612679 = header.getOrDefault("X-Amz-Date")
  valid_612679 = validateParameter(valid_612679, JString, required = false,
                                 default = nil)
  if valid_612679 != nil:
    section.add "X-Amz-Date", valid_612679
  var valid_612680 = header.getOrDefault("X-Amz-Credential")
  valid_612680 = validateParameter(valid_612680, JString, required = false,
                                 default = nil)
  if valid_612680 != nil:
    section.add "X-Amz-Credential", valid_612680
  var valid_612681 = header.getOrDefault("X-Amz-Security-Token")
  valid_612681 = validateParameter(valid_612681, JString, required = false,
                                 default = nil)
  if valid_612681 != nil:
    section.add "X-Amz-Security-Token", valid_612681
  var valid_612682 = header.getOrDefault("X-Amz-Algorithm")
  valid_612682 = validateParameter(valid_612682, JString, required = false,
                                 default = nil)
  if valid_612682 != nil:
    section.add "X-Amz-Algorithm", valid_612682
  var valid_612683 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612683 = validateParameter(valid_612683, JString, required = false,
                                 default = nil)
  if valid_612683 != nil:
    section.add "X-Amz-SignedHeaders", valid_612683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612685: Call_UpdateResourceServer_612673; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the name and scopes of resource server. All other fields are read-only.</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ## 
  let valid = call_612685.validator(path, query, header, formData, body)
  let scheme = call_612685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612685.url(scheme.get, call_612685.host, call_612685.base,
                         call_612685.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612685, url, valid)

proc call*(call_612686: Call_UpdateResourceServer_612673; body: JsonNode): Recallable =
  ## updateResourceServer
  ## <p>Updates the name and scopes of resource server. All other fields are read-only.</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ##   body: JObject (required)
  var body_612687 = newJObject()
  if body != nil:
    body_612687 = body
  result = call_612686.call(nil, nil, nil, nil, body_612687)

var updateResourceServer* = Call_UpdateResourceServer_612673(
    name: "updateResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateResourceServer",
    validator: validate_UpdateResourceServer_612674, base: "/",
    url: url_UpdateResourceServer_612675, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserAttributes_612688 = ref object of OpenApiRestCall_610658
proc url_UpdateUserAttributes_612690(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUserAttributes_612689(path: JsonNode; query: JsonNode;
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
  var valid_612691 = header.getOrDefault("X-Amz-Target")
  valid_612691 = validateParameter(valid_612691, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserAttributes"))
  if valid_612691 != nil:
    section.add "X-Amz-Target", valid_612691
  var valid_612692 = header.getOrDefault("X-Amz-Signature")
  valid_612692 = validateParameter(valid_612692, JString, required = false,
                                 default = nil)
  if valid_612692 != nil:
    section.add "X-Amz-Signature", valid_612692
  var valid_612693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612693 = validateParameter(valid_612693, JString, required = false,
                                 default = nil)
  if valid_612693 != nil:
    section.add "X-Amz-Content-Sha256", valid_612693
  var valid_612694 = header.getOrDefault("X-Amz-Date")
  valid_612694 = validateParameter(valid_612694, JString, required = false,
                                 default = nil)
  if valid_612694 != nil:
    section.add "X-Amz-Date", valid_612694
  var valid_612695 = header.getOrDefault("X-Amz-Credential")
  valid_612695 = validateParameter(valid_612695, JString, required = false,
                                 default = nil)
  if valid_612695 != nil:
    section.add "X-Amz-Credential", valid_612695
  var valid_612696 = header.getOrDefault("X-Amz-Security-Token")
  valid_612696 = validateParameter(valid_612696, JString, required = false,
                                 default = nil)
  if valid_612696 != nil:
    section.add "X-Amz-Security-Token", valid_612696
  var valid_612697 = header.getOrDefault("X-Amz-Algorithm")
  valid_612697 = validateParameter(valid_612697, JString, required = false,
                                 default = nil)
  if valid_612697 != nil:
    section.add "X-Amz-Algorithm", valid_612697
  var valid_612698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612698 = validateParameter(valid_612698, JString, required = false,
                                 default = nil)
  if valid_612698 != nil:
    section.add "X-Amz-SignedHeaders", valid_612698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612700: Call_UpdateUserAttributes_612688; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a user to update a specific attribute (one at a time).
  ## 
  let valid = call_612700.validator(path, query, header, formData, body)
  let scheme = call_612700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612700.url(scheme.get, call_612700.host, call_612700.base,
                         call_612700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612700, url, valid)

proc call*(call_612701: Call_UpdateUserAttributes_612688; body: JsonNode): Recallable =
  ## updateUserAttributes
  ## Allows a user to update a specific attribute (one at a time).
  ##   body: JObject (required)
  var body_612702 = newJObject()
  if body != nil:
    body_612702 = body
  result = call_612701.call(nil, nil, nil, nil, body_612702)

var updateUserAttributes* = Call_UpdateUserAttributes_612688(
    name: "updateUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserAttributes",
    validator: validate_UpdateUserAttributes_612689, base: "/",
    url: url_UpdateUserAttributes_612690, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPool_612703 = ref object of OpenApiRestCall_610658
proc url_UpdateUserPool_612705(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUserPool_612704(path: JsonNode; query: JsonNode;
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
  var valid_612706 = header.getOrDefault("X-Amz-Target")
  valid_612706 = validateParameter(valid_612706, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserPool"))
  if valid_612706 != nil:
    section.add "X-Amz-Target", valid_612706
  var valid_612707 = header.getOrDefault("X-Amz-Signature")
  valid_612707 = validateParameter(valid_612707, JString, required = false,
                                 default = nil)
  if valid_612707 != nil:
    section.add "X-Amz-Signature", valid_612707
  var valid_612708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612708 = validateParameter(valid_612708, JString, required = false,
                                 default = nil)
  if valid_612708 != nil:
    section.add "X-Amz-Content-Sha256", valid_612708
  var valid_612709 = header.getOrDefault("X-Amz-Date")
  valid_612709 = validateParameter(valid_612709, JString, required = false,
                                 default = nil)
  if valid_612709 != nil:
    section.add "X-Amz-Date", valid_612709
  var valid_612710 = header.getOrDefault("X-Amz-Credential")
  valid_612710 = validateParameter(valid_612710, JString, required = false,
                                 default = nil)
  if valid_612710 != nil:
    section.add "X-Amz-Credential", valid_612710
  var valid_612711 = header.getOrDefault("X-Amz-Security-Token")
  valid_612711 = validateParameter(valid_612711, JString, required = false,
                                 default = nil)
  if valid_612711 != nil:
    section.add "X-Amz-Security-Token", valid_612711
  var valid_612712 = header.getOrDefault("X-Amz-Algorithm")
  valid_612712 = validateParameter(valid_612712, JString, required = false,
                                 default = nil)
  if valid_612712 != nil:
    section.add "X-Amz-Algorithm", valid_612712
  var valid_612713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612713 = validateParameter(valid_612713, JString, required = false,
                                 default = nil)
  if valid_612713 != nil:
    section.add "X-Amz-SignedHeaders", valid_612713
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612715: Call_UpdateUserPool_612703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified user pool with the specified attributes. You can get a list of the current user pool settings with .</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ## 
  let valid = call_612715.validator(path, query, header, formData, body)
  let scheme = call_612715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612715.url(scheme.get, call_612715.host, call_612715.base,
                         call_612715.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612715, url, valid)

proc call*(call_612716: Call_UpdateUserPool_612703; body: JsonNode): Recallable =
  ## updateUserPool
  ## <p>Updates the specified user pool with the specified attributes. You can get a list of the current user pool settings with .</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ##   body: JObject (required)
  var body_612717 = newJObject()
  if body != nil:
    body_612717 = body
  result = call_612716.call(nil, nil, nil, nil, body_612717)

var updateUserPool* = Call_UpdateUserPool_612703(name: "updateUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserPool",
    validator: validate_UpdateUserPool_612704, base: "/", url: url_UpdateUserPool_612705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPoolClient_612718 = ref object of OpenApiRestCall_610658
proc url_UpdateUserPoolClient_612720(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUserPoolClient_612719(path: JsonNode; query: JsonNode;
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
  var valid_612721 = header.getOrDefault("X-Amz-Target")
  valid_612721 = validateParameter(valid_612721, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserPoolClient"))
  if valid_612721 != nil:
    section.add "X-Amz-Target", valid_612721
  var valid_612722 = header.getOrDefault("X-Amz-Signature")
  valid_612722 = validateParameter(valid_612722, JString, required = false,
                                 default = nil)
  if valid_612722 != nil:
    section.add "X-Amz-Signature", valid_612722
  var valid_612723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612723 = validateParameter(valid_612723, JString, required = false,
                                 default = nil)
  if valid_612723 != nil:
    section.add "X-Amz-Content-Sha256", valid_612723
  var valid_612724 = header.getOrDefault("X-Amz-Date")
  valid_612724 = validateParameter(valid_612724, JString, required = false,
                                 default = nil)
  if valid_612724 != nil:
    section.add "X-Amz-Date", valid_612724
  var valid_612725 = header.getOrDefault("X-Amz-Credential")
  valid_612725 = validateParameter(valid_612725, JString, required = false,
                                 default = nil)
  if valid_612725 != nil:
    section.add "X-Amz-Credential", valid_612725
  var valid_612726 = header.getOrDefault("X-Amz-Security-Token")
  valid_612726 = validateParameter(valid_612726, JString, required = false,
                                 default = nil)
  if valid_612726 != nil:
    section.add "X-Amz-Security-Token", valid_612726
  var valid_612727 = header.getOrDefault("X-Amz-Algorithm")
  valid_612727 = validateParameter(valid_612727, JString, required = false,
                                 default = nil)
  if valid_612727 != nil:
    section.add "X-Amz-Algorithm", valid_612727
  var valid_612728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612728 = validateParameter(valid_612728, JString, required = false,
                                 default = nil)
  if valid_612728 != nil:
    section.add "X-Amz-SignedHeaders", valid_612728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612730: Call_UpdateUserPoolClient_612718; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified user pool app client with the specified attributes. You can get a list of the current user pool app client settings with .</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ## 
  let valid = call_612730.validator(path, query, header, formData, body)
  let scheme = call_612730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612730.url(scheme.get, call_612730.host, call_612730.base,
                         call_612730.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612730, url, valid)

proc call*(call_612731: Call_UpdateUserPoolClient_612718; body: JsonNode): Recallable =
  ## updateUserPoolClient
  ## <p>Updates the specified user pool app client with the specified attributes. You can get a list of the current user pool app client settings with .</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ##   body: JObject (required)
  var body_612732 = newJObject()
  if body != nil:
    body_612732 = body
  result = call_612731.call(nil, nil, nil, nil, body_612732)

var updateUserPoolClient* = Call_UpdateUserPoolClient_612718(
    name: "updateUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserPoolClient",
    validator: validate_UpdateUserPoolClient_612719, base: "/",
    url: url_UpdateUserPoolClient_612720, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPoolDomain_612733 = ref object of OpenApiRestCall_610658
proc url_UpdateUserPoolDomain_612735(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUserPoolDomain_612734(path: JsonNode; query: JsonNode;
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
  var valid_612736 = header.getOrDefault("X-Amz-Target")
  valid_612736 = validateParameter(valid_612736, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserPoolDomain"))
  if valid_612736 != nil:
    section.add "X-Amz-Target", valid_612736
  var valid_612737 = header.getOrDefault("X-Amz-Signature")
  valid_612737 = validateParameter(valid_612737, JString, required = false,
                                 default = nil)
  if valid_612737 != nil:
    section.add "X-Amz-Signature", valid_612737
  var valid_612738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612738 = validateParameter(valid_612738, JString, required = false,
                                 default = nil)
  if valid_612738 != nil:
    section.add "X-Amz-Content-Sha256", valid_612738
  var valid_612739 = header.getOrDefault("X-Amz-Date")
  valid_612739 = validateParameter(valid_612739, JString, required = false,
                                 default = nil)
  if valid_612739 != nil:
    section.add "X-Amz-Date", valid_612739
  var valid_612740 = header.getOrDefault("X-Amz-Credential")
  valid_612740 = validateParameter(valid_612740, JString, required = false,
                                 default = nil)
  if valid_612740 != nil:
    section.add "X-Amz-Credential", valid_612740
  var valid_612741 = header.getOrDefault("X-Amz-Security-Token")
  valid_612741 = validateParameter(valid_612741, JString, required = false,
                                 default = nil)
  if valid_612741 != nil:
    section.add "X-Amz-Security-Token", valid_612741
  var valid_612742 = header.getOrDefault("X-Amz-Algorithm")
  valid_612742 = validateParameter(valid_612742, JString, required = false,
                                 default = nil)
  if valid_612742 != nil:
    section.add "X-Amz-Algorithm", valid_612742
  var valid_612743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612743 = validateParameter(valid_612743, JString, required = false,
                                 default = nil)
  if valid_612743 != nil:
    section.add "X-Amz-SignedHeaders", valid_612743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612745: Call_UpdateUserPoolDomain_612733; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the Secure Sockets Layer (SSL) certificate for the custom domain for your user pool.</p> <p>You can use this operation to provide the Amazon Resource Name (ARN) of a new certificate to Amazon Cognito. You cannot use it to change the domain for a user pool.</p> <p>A custom domain is used to host the Amazon Cognito hosted UI, which provides sign-up and sign-in pages for your application. When you set up a custom domain, you provide a certificate that you manage with AWS Certificate Manager (ACM). When necessary, you can use this operation to change the certificate that you applied to your custom domain.</p> <p>Usually, this is unnecessary following routine certificate renewal with ACM. When you renew your existing certificate in ACM, the ARN for your certificate remains the same, and your custom domain uses the new certificate automatically.</p> <p>However, if you replace your existing certificate with a new one, ACM gives the new certificate a new ARN. To apply the new certificate to your custom domain, you must provide this ARN to Amazon Cognito.</p> <p>When you add your new certificate in ACM, you must choose US East (N. Virginia) as the AWS Region.</p> <p>After you submit your request, Amazon Cognito requires up to 1 hour to distribute your new certificate to your custom domain.</p> <p>For more information about adding a custom domain to your user pool, see <a href="https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-add-custom-domain.html">Using Your Own Domain for the Hosted UI</a>.</p>
  ## 
  let valid = call_612745.validator(path, query, header, formData, body)
  let scheme = call_612745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612745.url(scheme.get, call_612745.host, call_612745.base,
                         call_612745.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612745, url, valid)

proc call*(call_612746: Call_UpdateUserPoolDomain_612733; body: JsonNode): Recallable =
  ## updateUserPoolDomain
  ## <p>Updates the Secure Sockets Layer (SSL) certificate for the custom domain for your user pool.</p> <p>You can use this operation to provide the Amazon Resource Name (ARN) of a new certificate to Amazon Cognito. You cannot use it to change the domain for a user pool.</p> <p>A custom domain is used to host the Amazon Cognito hosted UI, which provides sign-up and sign-in pages for your application. When you set up a custom domain, you provide a certificate that you manage with AWS Certificate Manager (ACM). When necessary, you can use this operation to change the certificate that you applied to your custom domain.</p> <p>Usually, this is unnecessary following routine certificate renewal with ACM. When you renew your existing certificate in ACM, the ARN for your certificate remains the same, and your custom domain uses the new certificate automatically.</p> <p>However, if you replace your existing certificate with a new one, ACM gives the new certificate a new ARN. To apply the new certificate to your custom domain, you must provide this ARN to Amazon Cognito.</p> <p>When you add your new certificate in ACM, you must choose US East (N. Virginia) as the AWS Region.</p> <p>After you submit your request, Amazon Cognito requires up to 1 hour to distribute your new certificate to your custom domain.</p> <p>For more information about adding a custom domain to your user pool, see <a href="https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-add-custom-domain.html">Using Your Own Domain for the Hosted UI</a>.</p>
  ##   body: JObject (required)
  var body_612747 = newJObject()
  if body != nil:
    body_612747 = body
  result = call_612746.call(nil, nil, nil, nil, body_612747)

var updateUserPoolDomain* = Call_UpdateUserPoolDomain_612733(
    name: "updateUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserPoolDomain",
    validator: validate_UpdateUserPoolDomain_612734, base: "/",
    url: url_UpdateUserPoolDomain_612735, schemes: {Scheme.Https, Scheme.Http})
type
  Call_VerifySoftwareToken_612748 = ref object of OpenApiRestCall_610658
proc url_VerifySoftwareToken_612750(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_VerifySoftwareToken_612749(path: JsonNode; query: JsonNode;
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
  var valid_612751 = header.getOrDefault("X-Amz-Target")
  valid_612751 = validateParameter(valid_612751, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.VerifySoftwareToken"))
  if valid_612751 != nil:
    section.add "X-Amz-Target", valid_612751
  var valid_612752 = header.getOrDefault("X-Amz-Signature")
  valid_612752 = validateParameter(valid_612752, JString, required = false,
                                 default = nil)
  if valid_612752 != nil:
    section.add "X-Amz-Signature", valid_612752
  var valid_612753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612753 = validateParameter(valid_612753, JString, required = false,
                                 default = nil)
  if valid_612753 != nil:
    section.add "X-Amz-Content-Sha256", valid_612753
  var valid_612754 = header.getOrDefault("X-Amz-Date")
  valid_612754 = validateParameter(valid_612754, JString, required = false,
                                 default = nil)
  if valid_612754 != nil:
    section.add "X-Amz-Date", valid_612754
  var valid_612755 = header.getOrDefault("X-Amz-Credential")
  valid_612755 = validateParameter(valid_612755, JString, required = false,
                                 default = nil)
  if valid_612755 != nil:
    section.add "X-Amz-Credential", valid_612755
  var valid_612756 = header.getOrDefault("X-Amz-Security-Token")
  valid_612756 = validateParameter(valid_612756, JString, required = false,
                                 default = nil)
  if valid_612756 != nil:
    section.add "X-Amz-Security-Token", valid_612756
  var valid_612757 = header.getOrDefault("X-Amz-Algorithm")
  valid_612757 = validateParameter(valid_612757, JString, required = false,
                                 default = nil)
  if valid_612757 != nil:
    section.add "X-Amz-Algorithm", valid_612757
  var valid_612758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612758 = validateParameter(valid_612758, JString, required = false,
                                 default = nil)
  if valid_612758 != nil:
    section.add "X-Amz-SignedHeaders", valid_612758
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612760: Call_VerifySoftwareToken_612748; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Use this API to register a user's entered TOTP code and mark the user's software token MFA status as "verified" if successful. The request takes an access token or a session string, but not both.
  ## 
  let valid = call_612760.validator(path, query, header, formData, body)
  let scheme = call_612760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612760.url(scheme.get, call_612760.host, call_612760.base,
                         call_612760.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612760, url, valid)

proc call*(call_612761: Call_VerifySoftwareToken_612748; body: JsonNode): Recallable =
  ## verifySoftwareToken
  ## Use this API to register a user's entered TOTP code and mark the user's software token MFA status as "verified" if successful. The request takes an access token or a session string, but not both.
  ##   body: JObject (required)
  var body_612762 = newJObject()
  if body != nil:
    body_612762 = body
  result = call_612761.call(nil, nil, nil, nil, body_612762)

var verifySoftwareToken* = Call_VerifySoftwareToken_612748(
    name: "verifySoftwareToken", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.VerifySoftwareToken",
    validator: validate_VerifySoftwareToken_612749, base: "/",
    url: url_VerifySoftwareToken_612750, schemes: {Scheme.Https, Scheme.Http})
type
  Call_VerifyUserAttribute_612763 = ref object of OpenApiRestCall_610658
proc url_VerifyUserAttribute_612765(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_VerifyUserAttribute_612764(path: JsonNode; query: JsonNode;
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
  var valid_612766 = header.getOrDefault("X-Amz-Target")
  valid_612766 = validateParameter(valid_612766, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.VerifyUserAttribute"))
  if valid_612766 != nil:
    section.add "X-Amz-Target", valid_612766
  var valid_612767 = header.getOrDefault("X-Amz-Signature")
  valid_612767 = validateParameter(valid_612767, JString, required = false,
                                 default = nil)
  if valid_612767 != nil:
    section.add "X-Amz-Signature", valid_612767
  var valid_612768 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612768 = validateParameter(valid_612768, JString, required = false,
                                 default = nil)
  if valid_612768 != nil:
    section.add "X-Amz-Content-Sha256", valid_612768
  var valid_612769 = header.getOrDefault("X-Amz-Date")
  valid_612769 = validateParameter(valid_612769, JString, required = false,
                                 default = nil)
  if valid_612769 != nil:
    section.add "X-Amz-Date", valid_612769
  var valid_612770 = header.getOrDefault("X-Amz-Credential")
  valid_612770 = validateParameter(valid_612770, JString, required = false,
                                 default = nil)
  if valid_612770 != nil:
    section.add "X-Amz-Credential", valid_612770
  var valid_612771 = header.getOrDefault("X-Amz-Security-Token")
  valid_612771 = validateParameter(valid_612771, JString, required = false,
                                 default = nil)
  if valid_612771 != nil:
    section.add "X-Amz-Security-Token", valid_612771
  var valid_612772 = header.getOrDefault("X-Amz-Algorithm")
  valid_612772 = validateParameter(valid_612772, JString, required = false,
                                 default = nil)
  if valid_612772 != nil:
    section.add "X-Amz-Algorithm", valid_612772
  var valid_612773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612773 = validateParameter(valid_612773, JString, required = false,
                                 default = nil)
  if valid_612773 != nil:
    section.add "X-Amz-SignedHeaders", valid_612773
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612775: Call_VerifyUserAttribute_612763; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Verifies the specified user attributes in the user pool.
  ## 
  let valid = call_612775.validator(path, query, header, formData, body)
  let scheme = call_612775.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612775.url(scheme.get, call_612775.host, call_612775.base,
                         call_612775.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612775, url, valid)

proc call*(call_612776: Call_VerifyUserAttribute_612763; body: JsonNode): Recallable =
  ## verifyUserAttribute
  ## Verifies the specified user attributes in the user pool.
  ##   body: JObject (required)
  var body_612777 = newJObject()
  if body != nil:
    body_612777 = body
  result = call_612776.call(nil, nil, nil, nil, body_612777)

var verifyUserAttribute* = Call_VerifyUserAttribute_612763(
    name: "verifyUserAttribute", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.VerifyUserAttribute",
    validator: validate_VerifyUserAttribute_612764, base: "/",
    url: url_VerifyUserAttribute_612765, schemes: {Scheme.Https, Scheme.Http})
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
