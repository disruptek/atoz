
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "cognito-idp.ap-northeast-1.amazonaws.com", "ap-southeast-1": "cognito-idp.ap-southeast-1.amazonaws.com", "us-west-2": "cognito-idp.us-west-2.amazonaws.com", "eu-west-2": "cognito-idp.eu-west-2.amazonaws.com", "ap-northeast-3": "cognito-idp.ap-northeast-3.amazonaws.com", "eu-central-1": "cognito-idp.eu-central-1.amazonaws.com", "us-east-2": "cognito-idp.us-east-2.amazonaws.com", "us-east-1": "cognito-idp.us-east-1.amazonaws.com", "cn-northwest-1": "cognito-idp.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "cognito-idp.ap-south-1.amazonaws.com", "eu-north-1": "cognito-idp.eu-north-1.amazonaws.com", "ap-northeast-2": "cognito-idp.ap-northeast-2.amazonaws.com", "us-west-1": "cognito-idp.us-west-1.amazonaws.com", "us-gov-east-1": "cognito-idp.us-gov-east-1.amazonaws.com", "eu-west-3": "cognito-idp.eu-west-3.amazonaws.com", "cn-north-1": "cognito-idp.cn-north-1.amazonaws.com.cn", "sa-east-1": "cognito-idp.sa-east-1.amazonaws.com", "eu-west-1": "cognito-idp.eu-west-1.amazonaws.com", "us-gov-west-1": "cognito-idp.us-gov-west-1.amazonaws.com", "ap-southeast-2": "cognito-idp.ap-southeast-2.amazonaws.com", "ca-central-1": "cognito-idp.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_AddCustomAttributes_402656294 = ref object of OpenApiRestCall_402656044
proc url_AddCustomAttributes_402656296(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddCustomAttributes_402656295(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656390 = header.getOrDefault("X-Amz-Target")
  valid_402656390 = validateParameter(valid_402656390, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AddCustomAttributes"))
  if valid_402656390 != nil:
    section.add "X-Amz-Target", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-Security-Token", valid_402656391
  var valid_402656392 = header.getOrDefault("X-Amz-Signature")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "X-Amz-Signature", valid_402656392
  var valid_402656393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656393 = validateParameter(valid_402656393, JString,
                                      required = false, default = nil)
  if valid_402656393 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656393
  var valid_402656394 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656394 = validateParameter(valid_402656394, JString,
                                      required = false, default = nil)
  if valid_402656394 != nil:
    section.add "X-Amz-Algorithm", valid_402656394
  var valid_402656395 = header.getOrDefault("X-Amz-Date")
  valid_402656395 = validateParameter(valid_402656395, JString,
                                      required = false, default = nil)
  if valid_402656395 != nil:
    section.add "X-Amz-Date", valid_402656395
  var valid_402656396 = header.getOrDefault("X-Amz-Credential")
  valid_402656396 = validateParameter(valid_402656396, JString,
                                      required = false, default = nil)
  if valid_402656396 != nil:
    section.add "X-Amz-Credential", valid_402656396
  var valid_402656397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656397 = validateParameter(valid_402656397, JString,
                                      required = false, default = nil)
  if valid_402656397 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656412: Call_AddCustomAttributes_402656294;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds additional user attributes to the user pool schema.
                                                                                         ## 
  let valid = call_402656412.validator(path, query, header, formData, body, _)
  let scheme = call_402656412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656412.makeUrl(scheme.get, call_402656412.host, call_402656412.base,
                                   call_402656412.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656412, uri, valid, _)

proc call*(call_402656461: Call_AddCustomAttributes_402656294; body: JsonNode): Recallable =
  ## addCustomAttributes
  ## Adds additional user attributes to the user pool schema.
  ##   body: JObject (required)
  var body_402656462 = newJObject()
  if body != nil:
    body_402656462 = body
  result = call_402656461.call(nil, nil, nil, nil, body_402656462)

var addCustomAttributes* = Call_AddCustomAttributes_402656294(
    name: "addCustomAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AddCustomAttributes",
    validator: validate_AddCustomAttributes_402656295, base: "/",
    makeUrl: url_AddCustomAttributes_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminAddUserToGroup_402656489 = ref object of OpenApiRestCall_402656044
proc url_AdminAddUserToGroup_402656491(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminAddUserToGroup_402656490(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656492 = header.getOrDefault("X-Amz-Target")
  valid_402656492 = validateParameter(valid_402656492, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminAddUserToGroup"))
  if valid_402656492 != nil:
    section.add "X-Amz-Target", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Security-Token", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Signature")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Signature", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Algorithm", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Date")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Date", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Credential")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Credential", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656501: Call_AdminAddUserToGroup_402656489;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds the specified user to the specified group.</p> <p>Calling this action requires developer credentials.</p>
                                                                                         ## 
  let valid = call_402656501.validator(path, query, header, formData, body, _)
  let scheme = call_402656501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656501.makeUrl(scheme.get, call_402656501.host, call_402656501.base,
                                   call_402656501.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656501, uri, valid, _)

proc call*(call_402656502: Call_AdminAddUserToGroup_402656489; body: JsonNode): Recallable =
  ## adminAddUserToGroup
  ## <p>Adds the specified user to the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ##   
                                                                                                                      ## body: JObject (required)
  var body_402656503 = newJObject()
  if body != nil:
    body_402656503 = body
  result = call_402656502.call(nil, nil, nil, nil, body_402656503)

var adminAddUserToGroup* = Call_AdminAddUserToGroup_402656489(
    name: "adminAddUserToGroup", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminAddUserToGroup",
    validator: validate_AdminAddUserToGroup_402656490, base: "/",
    makeUrl: url_AdminAddUserToGroup_402656491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminConfirmSignUp_402656504 = ref object of OpenApiRestCall_402656044
proc url_AdminConfirmSignUp_402656506(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminConfirmSignUp_402656505(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656507 = header.getOrDefault("X-Amz-Target")
  valid_402656507 = validateParameter(valid_402656507, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminConfirmSignUp"))
  if valid_402656507 != nil:
    section.add "X-Amz-Target", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Security-Token", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Signature")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Signature", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Algorithm", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Date")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Date", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Credential")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Credential", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656516: Call_AdminConfirmSignUp_402656504;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Confirms user registration as an admin without using a confirmation code. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
                                                                                         ## 
  let valid = call_402656516.validator(path, query, header, formData, body, _)
  let scheme = call_402656516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656516.makeUrl(scheme.get, call_402656516.host, call_402656516.base,
                                   call_402656516.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656516, uri, valid, _)

proc call*(call_402656517: Call_AdminConfirmSignUp_402656504; body: JsonNode): Recallable =
  ## adminConfirmSignUp
  ## <p>Confirms user registration as an admin without using a confirmation code. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   
                                                                                                                                                                   ## body: JObject (required)
  var body_402656518 = newJObject()
  if body != nil:
    body_402656518 = body
  result = call_402656517.call(nil, nil, nil, nil, body_402656518)

var adminConfirmSignUp* = Call_AdminConfirmSignUp_402656504(
    name: "adminConfirmSignUp", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminConfirmSignUp",
    validator: validate_AdminConfirmSignUp_402656505, base: "/",
    makeUrl: url_AdminConfirmSignUp_402656506,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminCreateUser_402656519 = ref object of OpenApiRestCall_402656044
proc url_AdminCreateUser_402656521(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminCreateUser_402656520(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656522 = header.getOrDefault("X-Amz-Target")
  valid_402656522 = validateParameter(valid_402656522, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminCreateUser"))
  if valid_402656522 != nil:
    section.add "X-Amz-Target", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Security-Token", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Signature")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Signature", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Algorithm", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Date")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Date", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Credential")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Credential", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656531: Call_AdminCreateUser_402656519; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new user in the specified user pool.</p> <p>If <code>MessageAction</code> is not set, the default is to send a welcome message via email or phone (SMS).</p> <note> <p>This message is based on a template that you configured in your call to or . This template includes your custom sign-up instructions and placeholders for user name and temporary password.</p> </note> <p>Alternatively, you can call AdminCreateUser with “SUPPRESS” for the <code>MessageAction</code> parameter, and Amazon Cognito will not send any email. </p> <p>In either case, the user will be in the <code>FORCE_CHANGE_PASSWORD</code> state until they sign in and change their password.</p> <p>AdminCreateUser requires developer credentials.</p>
                                                                                         ## 
  let valid = call_402656531.validator(path, query, header, formData, body, _)
  let scheme = call_402656531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656531.makeUrl(scheme.get, call_402656531.host, call_402656531.base,
                                   call_402656531.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656531, uri, valid, _)

proc call*(call_402656532: Call_AdminCreateUser_402656519; body: JsonNode): Recallable =
  ## adminCreateUser
  ## <p>Creates a new user in the specified user pool.</p> <p>If <code>MessageAction</code> is not set, the default is to send a welcome message via email or phone (SMS).</p> <note> <p>This message is based on a template that you configured in your call to or . This template includes your custom sign-up instructions and placeholders for user name and temporary password.</p> </note> <p>Alternatively, you can call AdminCreateUser with “SUPPRESS” for the <code>MessageAction</code> parameter, and Amazon Cognito will not send any email. </p> <p>In either case, the user will be in the <code>FORCE_CHANGE_PASSWORD</code> state until they sign in and change their password.</p> <p>AdminCreateUser requires developer credentials.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402656533 = newJObject()
  if body != nil:
    body_402656533 = body
  result = call_402656532.call(nil, nil, nil, nil, body_402656533)

var adminCreateUser* = Call_AdminCreateUser_402656519(name: "adminCreateUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminCreateUser",
    validator: validate_AdminCreateUser_402656520, base: "/",
    makeUrl: url_AdminCreateUser_402656521, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDeleteUser_402656534 = ref object of OpenApiRestCall_402656044
proc url_AdminDeleteUser_402656536(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminDeleteUser_402656535(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656537 = header.getOrDefault("X-Amz-Target")
  valid_402656537 = validateParameter(valid_402656537, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDeleteUser"))
  if valid_402656537 != nil:
    section.add "X-Amz-Target", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Security-Token", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Signature")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Signature", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Algorithm", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Date")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Date", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Credential")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Credential", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656546: Call_AdminDeleteUser_402656534; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a user as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
                                                                                         ## 
  let valid = call_402656546.validator(path, query, header, formData, body, _)
  let scheme = call_402656546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656546.makeUrl(scheme.get, call_402656546.host, call_402656546.base,
                                   call_402656546.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656546, uri, valid, _)

proc call*(call_402656547: Call_AdminDeleteUser_402656534; body: JsonNode): Recallable =
  ## adminDeleteUser
  ## <p>Deletes a user as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   
                                                                                                                             ## body: JObject (required)
  var body_402656548 = newJObject()
  if body != nil:
    body_402656548 = body
  result = call_402656547.call(nil, nil, nil, nil, body_402656548)

var adminDeleteUser* = Call_AdminDeleteUser_402656534(name: "adminDeleteUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDeleteUser",
    validator: validate_AdminDeleteUser_402656535, base: "/",
    makeUrl: url_AdminDeleteUser_402656536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDeleteUserAttributes_402656549 = ref object of OpenApiRestCall_402656044
proc url_AdminDeleteUserAttributes_402656551(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminDeleteUserAttributes_402656550(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656552 = header.getOrDefault("X-Amz-Target")
  valid_402656552 = validateParameter(valid_402656552, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDeleteUserAttributes"))
  if valid_402656552 != nil:
    section.add "X-Amz-Target", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Security-Token", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Signature")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Signature", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Algorithm", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Date")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Date", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Credential")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Credential", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656561: Call_AdminDeleteUserAttributes_402656549;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the user attributes in a user pool as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
                                                                                         ## 
  let valid = call_402656561.validator(path, query, header, formData, body, _)
  let scheme = call_402656561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656561.makeUrl(scheme.get, call_402656561.host, call_402656561.base,
                                   call_402656561.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656561, uri, valid, _)

proc call*(call_402656562: Call_AdminDeleteUserAttributes_402656549;
           body: JsonNode): Recallable =
  ## adminDeleteUserAttributes
  ## <p>Deletes the user attributes in a user pool as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   
                                                                                                                                                         ## body: JObject (required)
  var body_402656563 = newJObject()
  if body != nil:
    body_402656563 = body
  result = call_402656562.call(nil, nil, nil, nil, body_402656563)

var adminDeleteUserAttributes* = Call_AdminDeleteUserAttributes_402656549(
    name: "adminDeleteUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDeleteUserAttributes",
    validator: validate_AdminDeleteUserAttributes_402656550, base: "/",
    makeUrl: url_AdminDeleteUserAttributes_402656551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDisableProviderForUser_402656564 = ref object of OpenApiRestCall_402656044
proc url_AdminDisableProviderForUser_402656566(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminDisableProviderForUser_402656565(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656567 = header.getOrDefault("X-Amz-Target")
  valid_402656567 = validateParameter(valid_402656567, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDisableProviderForUser"))
  if valid_402656567 != nil:
    section.add "X-Amz-Target", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Security-Token", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Signature")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Signature", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Algorithm", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-Date")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Date", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Credential")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Credential", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656576: Call_AdminDisableProviderForUser_402656564;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Disables the user from signing in with the specified external (SAML or social) identity provider. If the user to disable is a Cognito User Pools native username + password user, they are not permitted to use their password to sign-in. If the user to disable is a linked external IdP user, any link between that user and an existing user is removed. The next time the external user (no longer attached to the previously linked <code>DestinationUser</code>) signs in, they must create a new user account. See .</p> <p>This action is enabled only for admin access and requires developer credentials.</p> <p>The <code>ProviderName</code> must match the value specified when creating an IdP for the pool. </p> <p>To disable a native username + password user, the <code>ProviderName</code> value must be <code>Cognito</code> and the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code>, with the <code>ProviderAttributeValue</code> being the name that is used in the user pool for the user.</p> <p>The <code>ProviderAttributeName</code> must always be <code>Cognito_Subject</code> for social identity providers. The <code>ProviderAttributeValue</code> must always be the exact subject that was used when the user was originally linked as a source user.</p> <p>For de-linking a SAML identity, there are two scenarios. If the linked identity has not yet been used to sign-in, the <code>ProviderAttributeName</code> and <code>ProviderAttributeValue</code> must be the same values that were used for the <code>SourceUser</code> when the identities were originally linked in the call. (If the linking was done with <code>ProviderAttributeName</code> set to <code>Cognito_Subject</code>, the same applies here). However, if the user has already signed in, the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code> and <code>ProviderAttributeValue</code> must be the subject of the SAML assertion.</p>
                                                                                         ## 
  let valid = call_402656576.validator(path, query, header, formData, body, _)
  let scheme = call_402656576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656576.makeUrl(scheme.get, call_402656576.host, call_402656576.base,
                                   call_402656576.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656576, uri, valid, _)

proc call*(call_402656577: Call_AdminDisableProviderForUser_402656564;
           body: JsonNode): Recallable =
  ## adminDisableProviderForUser
  ## <p>Disables the user from signing in with the specified external (SAML or social) identity provider. If the user to disable is a Cognito User Pools native username + password user, they are not permitted to use their password to sign-in. If the user to disable is a linked external IdP user, any link between that user and an existing user is removed. The next time the external user (no longer attached to the previously linked <code>DestinationUser</code>) signs in, they must create a new user account. See .</p> <p>This action is enabled only for admin access and requires developer credentials.</p> <p>The <code>ProviderName</code> must match the value specified when creating an IdP for the pool. </p> <p>To disable a native username + password user, the <code>ProviderName</code> value must be <code>Cognito</code> and the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code>, with the <code>ProviderAttributeValue</code> being the name that is used in the user pool for the user.</p> <p>The <code>ProviderAttributeName</code> must always be <code>Cognito_Subject</code> for social identity providers. The <code>ProviderAttributeValue</code> must always be the exact subject that was used when the user was originally linked as a source user.</p> <p>For de-linking a SAML identity, there are two scenarios. If the linked identity has not yet been used to sign-in, the <code>ProviderAttributeName</code> and <code>ProviderAttributeValue</code> must be the same values that were used for the <code>SourceUser</code> when the identities were originally linked in the call. (If the linking was done with <code>ProviderAttributeName</code> set to <code>Cognito_Subject</code>, the same applies here). However, if the user has already signed in, the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code> and <code>ProviderAttributeValue</code> must be the subject of the SAML assertion.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402656578 = newJObject()
  if body != nil:
    body_402656578 = body
  result = call_402656577.call(nil, nil, nil, nil, body_402656578)

var adminDisableProviderForUser* = Call_AdminDisableProviderForUser_402656564(
    name: "adminDisableProviderForUser", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDisableProviderForUser",
    validator: validate_AdminDisableProviderForUser_402656565, base: "/",
    makeUrl: url_AdminDisableProviderForUser_402656566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDisableUser_402656579 = ref object of OpenApiRestCall_402656044
proc url_AdminDisableUser_402656581(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminDisableUser_402656580(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656582 = header.getOrDefault("X-Amz-Target")
  valid_402656582 = validateParameter(valid_402656582, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDisableUser"))
  if valid_402656582 != nil:
    section.add "X-Amz-Target", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Security-Token", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Signature")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Signature", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Algorithm", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-Date")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Date", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Credential")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Credential", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656591: Call_AdminDisableUser_402656579;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Disables the specified user.</p> <p>Calling this action requires developer credentials.</p>
                                                                                         ## 
  let valid = call_402656591.validator(path, query, header, formData, body, _)
  let scheme = call_402656591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656591.makeUrl(scheme.get, call_402656591.host, call_402656591.base,
                                   call_402656591.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656591, uri, valid, _)

proc call*(call_402656592: Call_AdminDisableUser_402656579; body: JsonNode): Recallable =
  ## adminDisableUser
  ## <p>Disables the specified user.</p> <p>Calling this action requires developer credentials.</p>
  ##   
                                                                                                   ## body: JObject (required)
  var body_402656593 = newJObject()
  if body != nil:
    body_402656593 = body
  result = call_402656592.call(nil, nil, nil, nil, body_402656593)

var adminDisableUser* = Call_AdminDisableUser_402656579(
    name: "adminDisableUser", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDisableUser",
    validator: validate_AdminDisableUser_402656580, base: "/",
    makeUrl: url_AdminDisableUser_402656581,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminEnableUser_402656594 = ref object of OpenApiRestCall_402656044
proc url_AdminEnableUser_402656596(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminEnableUser_402656595(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656597 = header.getOrDefault("X-Amz-Target")
  valid_402656597 = validateParameter(valid_402656597, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminEnableUser"))
  if valid_402656597 != nil:
    section.add "X-Amz-Target", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Security-Token", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Signature")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Signature", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Algorithm", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Date")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Date", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Credential")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Credential", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656606: Call_AdminEnableUser_402656594; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Enables the specified user as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
                                                                                         ## 
  let valid = call_402656606.validator(path, query, header, formData, body, _)
  let scheme = call_402656606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656606.makeUrl(scheme.get, call_402656606.host, call_402656606.base,
                                   call_402656606.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656606, uri, valid, _)

proc call*(call_402656607: Call_AdminEnableUser_402656594; body: JsonNode): Recallable =
  ## adminEnableUser
  ## <p>Enables the specified user as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   
                                                                                                                                         ## body: JObject (required)
  var body_402656608 = newJObject()
  if body != nil:
    body_402656608 = body
  result = call_402656607.call(nil, nil, nil, nil, body_402656608)

var adminEnableUser* = Call_AdminEnableUser_402656594(name: "adminEnableUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminEnableUser",
    validator: validate_AdminEnableUser_402656595, base: "/",
    makeUrl: url_AdminEnableUser_402656596, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminForgetDevice_402656609 = ref object of OpenApiRestCall_402656044
proc url_AdminForgetDevice_402656611(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminForgetDevice_402656610(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656612 = header.getOrDefault("X-Amz-Target")
  valid_402656612 = validateParameter(valid_402656612, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminForgetDevice"))
  if valid_402656612 != nil:
    section.add "X-Amz-Target", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Security-Token", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Signature")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Signature", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Algorithm", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-Date")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Date", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Credential")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Credential", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656621: Call_AdminForgetDevice_402656609;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Forgets the device, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
                                                                                         ## 
  let valid = call_402656621.validator(path, query, header, formData, body, _)
  let scheme = call_402656621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656621.makeUrl(scheme.get, call_402656621.host, call_402656621.base,
                                   call_402656621.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656621, uri, valid, _)

proc call*(call_402656622: Call_AdminForgetDevice_402656609; body: JsonNode): Recallable =
  ## adminForgetDevice
  ## <p>Forgets the device, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   
                                                                                                               ## body: JObject (required)
  var body_402656623 = newJObject()
  if body != nil:
    body_402656623 = body
  result = call_402656622.call(nil, nil, nil, nil, body_402656623)

var adminForgetDevice* = Call_AdminForgetDevice_402656609(
    name: "adminForgetDevice", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminForgetDevice",
    validator: validate_AdminForgetDevice_402656610, base: "/",
    makeUrl: url_AdminForgetDevice_402656611,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminGetDevice_402656624 = ref object of OpenApiRestCall_402656044
proc url_AdminGetDevice_402656626(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminGetDevice_402656625(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656627 = header.getOrDefault("X-Amz-Target")
  valid_402656627 = validateParameter(valid_402656627, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminGetDevice"))
  if valid_402656627 != nil:
    section.add "X-Amz-Target", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Security-Token", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Signature")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Signature", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Algorithm", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Date")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Date", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Credential")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Credential", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656634
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656636: Call_AdminGetDevice_402656624; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets the device, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
                                                                                         ## 
  let valid = call_402656636.validator(path, query, header, formData, body, _)
  let scheme = call_402656636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656636.makeUrl(scheme.get, call_402656636.host, call_402656636.base,
                                   call_402656636.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656636, uri, valid, _)

proc call*(call_402656637: Call_AdminGetDevice_402656624; body: JsonNode): Recallable =
  ## adminGetDevice
  ## <p>Gets the device, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   
                                                                                                            ## body: JObject (required)
  var body_402656638 = newJObject()
  if body != nil:
    body_402656638 = body
  result = call_402656637.call(nil, nil, nil, nil, body_402656638)

var adminGetDevice* = Call_AdminGetDevice_402656624(name: "adminGetDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminGetDevice",
    validator: validate_AdminGetDevice_402656625, base: "/",
    makeUrl: url_AdminGetDevice_402656626, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminGetUser_402656639 = ref object of OpenApiRestCall_402656044
proc url_AdminGetUser_402656641(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminGetUser_402656640(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656642 = header.getOrDefault("X-Amz-Target")
  valid_402656642 = validateParameter(valid_402656642, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminGetUser"))
  if valid_402656642 != nil:
    section.add "X-Amz-Target", valid_402656642
  var valid_402656643 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Security-Token", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-Signature")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Signature", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Algorithm", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Date")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Date", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Credential")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Credential", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656651: Call_AdminGetUser_402656639; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets the specified user by user name in a user pool as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
                                                                                         ## 
  let valid = call_402656651.validator(path, query, header, formData, body, _)
  let scheme = call_402656651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656651.makeUrl(scheme.get, call_402656651.host, call_402656651.base,
                                   call_402656651.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656651, uri, valid, _)

proc call*(call_402656652: Call_AdminGetUser_402656639; body: JsonNode): Recallable =
  ## adminGetUser
  ## <p>Gets the specified user by user name in a user pool as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   
                                                                                                                                                                  ## body: JObject (required)
  var body_402656653 = newJObject()
  if body != nil:
    body_402656653 = body
  result = call_402656652.call(nil, nil, nil, nil, body_402656653)

var adminGetUser* = Call_AdminGetUser_402656639(name: "adminGetUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminGetUser",
    validator: validate_AdminGetUser_402656640, base: "/",
    makeUrl: url_AdminGetUser_402656641, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminInitiateAuth_402656654 = ref object of OpenApiRestCall_402656044
proc url_AdminInitiateAuth_402656656(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminInitiateAuth_402656655(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656657 = header.getOrDefault("X-Amz-Target")
  valid_402656657 = validateParameter(valid_402656657, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminInitiateAuth"))
  if valid_402656657 != nil:
    section.add "X-Amz-Target", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Security-Token", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-Signature")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Signature", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656660
  var valid_402656661 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Algorithm", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Date")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Date", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Credential")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Credential", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656666: Call_AdminInitiateAuth_402656654;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Initiates the authentication flow, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
                                                                                         ## 
  let valid = call_402656666.validator(path, query, header, formData, body, _)
  let scheme = call_402656666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656666.makeUrl(scheme.get, call_402656666.host, call_402656666.base,
                                   call_402656666.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656666, uri, valid, _)

proc call*(call_402656667: Call_AdminInitiateAuth_402656654; body: JsonNode): Recallable =
  ## adminInitiateAuth
  ## <p>Initiates the authentication flow, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   
                                                                                                                              ## body: JObject (required)
  var body_402656668 = newJObject()
  if body != nil:
    body_402656668 = body
  result = call_402656667.call(nil, nil, nil, nil, body_402656668)

var adminInitiateAuth* = Call_AdminInitiateAuth_402656654(
    name: "adminInitiateAuth", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminInitiateAuth",
    validator: validate_AdminInitiateAuth_402656655, base: "/",
    makeUrl: url_AdminInitiateAuth_402656656,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminLinkProviderForUser_402656669 = ref object of OpenApiRestCall_402656044
proc url_AdminLinkProviderForUser_402656671(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminLinkProviderForUser_402656670(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656672 = header.getOrDefault("X-Amz-Target")
  valid_402656672 = validateParameter(valid_402656672, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminLinkProviderForUser"))
  if valid_402656672 != nil:
    section.add "X-Amz-Target", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Security-Token", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-Signature")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-Signature", valid_402656674
  var valid_402656675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656675
  var valid_402656676 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Algorithm", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Date")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Date", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-Credential")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Credential", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656681: Call_AdminLinkProviderForUser_402656669;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Links an existing user account in a user pool (<code>DestinationUser</code>) to an identity from an external identity provider (<code>SourceUser</code>) based on a specified attribute name and value from the external identity provider. This allows you to create a link from the existing user account to an external federated user identity that has not yet been used to sign in, so that the federated user identity can be used to sign in as the existing user account. </p> <p> For example, if there is an existing user with a username and password, this API links that user to a federated user identity, so that when the federated user identity is used, the user signs in as the existing user account. </p> <important> <p>Because this API allows a user with an external federated identity to sign in as an existing user in the user pool, it is critical that it only be used with external identity providers and provider attributes that have been trusted by the application owner.</p> </important> <p>See also .</p> <p>This action is enabled only for admin access and requires developer credentials.</p>
                                                                                         ## 
  let valid = call_402656681.validator(path, query, header, formData, body, _)
  let scheme = call_402656681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656681.makeUrl(scheme.get, call_402656681.host, call_402656681.base,
                                   call_402656681.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656681, uri, valid, _)

proc call*(call_402656682: Call_AdminLinkProviderForUser_402656669;
           body: JsonNode): Recallable =
  ## adminLinkProviderForUser
  ## <p>Links an existing user account in a user pool (<code>DestinationUser</code>) to an identity from an external identity provider (<code>SourceUser</code>) based on a specified attribute name and value from the external identity provider. This allows you to create a link from the existing user account to an external federated user identity that has not yet been used to sign in, so that the federated user identity can be used to sign in as the existing user account. </p> <p> For example, if there is an existing user with a username and password, this API links that user to a federated user identity, so that when the federated user identity is used, the user signs in as the existing user account. </p> <important> <p>Because this API allows a user with an external federated identity to sign in as an existing user in the user pool, it is critical that it only be used with external identity providers and provider attributes that have been trusted by the application owner.</p> </important> <p>See also .</p> <p>This action is enabled only for admin access and requires developer credentials.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  var body_402656683 = newJObject()
  if body != nil:
    body_402656683 = body
  result = call_402656682.call(nil, nil, nil, nil, body_402656683)

var adminLinkProviderForUser* = Call_AdminLinkProviderForUser_402656669(
    name: "adminLinkProviderForUser", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminLinkProviderForUser",
    validator: validate_AdminLinkProviderForUser_402656670, base: "/",
    makeUrl: url_AdminLinkProviderForUser_402656671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminListDevices_402656684 = ref object of OpenApiRestCall_402656044
proc url_AdminListDevices_402656686(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminListDevices_402656685(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656687 = header.getOrDefault("X-Amz-Target")
  valid_402656687 = validateParameter(valid_402656687, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminListDevices"))
  if valid_402656687 != nil:
    section.add "X-Amz-Target", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Security-Token", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-Signature")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Signature", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Algorithm", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Date")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Date", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-Credential")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-Credential", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656694
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656696: Call_AdminListDevices_402656684;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists devices, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
                                                                                         ## 
  let valid = call_402656696.validator(path, query, header, formData, body, _)
  let scheme = call_402656696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656696.makeUrl(scheme.get, call_402656696.host, call_402656696.base,
                                   call_402656696.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656696, uri, valid, _)

proc call*(call_402656697: Call_AdminListDevices_402656684; body: JsonNode): Recallable =
  ## adminListDevices
  ## <p>Lists devices, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   
                                                                                                          ## body: JObject (required)
  var body_402656698 = newJObject()
  if body != nil:
    body_402656698 = body
  result = call_402656697.call(nil, nil, nil, nil, body_402656698)

var adminListDevices* = Call_AdminListDevices_402656684(
    name: "adminListDevices", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminListDevices",
    validator: validate_AdminListDevices_402656685, base: "/",
    makeUrl: url_AdminListDevices_402656686,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminListGroupsForUser_402656699 = ref object of OpenApiRestCall_402656044
proc url_AdminListGroupsForUser_402656701(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminListGroupsForUser_402656700(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656702 = query.getOrDefault("NextToken")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "NextToken", valid_402656702
  var valid_402656703 = query.getOrDefault("Limit")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "Limit", valid_402656703
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656704 = header.getOrDefault("X-Amz-Target")
  valid_402656704 = validateParameter(valid_402656704, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminListGroupsForUser"))
  if valid_402656704 != nil:
    section.add "X-Amz-Target", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Security-Token", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Signature")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Signature", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-Algorithm", valid_402656708
  var valid_402656709 = header.getOrDefault("X-Amz-Date")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-Date", valid_402656709
  var valid_402656710 = header.getOrDefault("X-Amz-Credential")
  valid_402656710 = validateParameter(valid_402656710, JString,
                                      required = false, default = nil)
  if valid_402656710 != nil:
    section.add "X-Amz-Credential", valid_402656710
  var valid_402656711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656711 = validateParameter(valid_402656711, JString,
                                      required = false, default = nil)
  if valid_402656711 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656711
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656713: Call_AdminListGroupsForUser_402656699;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists the groups that the user belongs to.</p> <p>Calling this action requires developer credentials.</p>
                                                                                         ## 
  let valid = call_402656713.validator(path, query, header, formData, body, _)
  let scheme = call_402656713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656713.makeUrl(scheme.get, call_402656713.host, call_402656713.base,
                                   call_402656713.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656713, uri, valid, _)

proc call*(call_402656714: Call_AdminListGroupsForUser_402656699;
           body: JsonNode; NextToken: string = ""; Limit: string = ""): Recallable =
  ## adminListGroupsForUser
  ## <p>Lists the groups that the user belongs to.</p> <p>Calling this action requires developer credentials.</p>
  ##   
                                                                                                                 ## body: JObject (required)
  ##   
                                                                                                                                            ## NextToken: string
                                                                                                                                            ##            
                                                                                                                                            ## : 
                                                                                                                                            ## Pagination 
                                                                                                                                            ## token
  ##   
                                                                                                                                                    ## Limit: string
                                                                                                                                                    ##        
                                                                                                                                                    ## : 
                                                                                                                                                    ## Pagination 
                                                                                                                                                    ## limit
  var query_402656715 = newJObject()
  var body_402656716 = newJObject()
  if body != nil:
    body_402656716 = body
  add(query_402656715, "NextToken", newJString(NextToken))
  add(query_402656715, "Limit", newJString(Limit))
  result = call_402656714.call(nil, query_402656715, nil, nil, body_402656716)

var adminListGroupsForUser* = Call_AdminListGroupsForUser_402656699(
    name: "adminListGroupsForUser", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminListGroupsForUser",
    validator: validate_AdminListGroupsForUser_402656700, base: "/",
    makeUrl: url_AdminListGroupsForUser_402656701,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminListUserAuthEvents_402656717 = ref object of OpenApiRestCall_402656044
proc url_AdminListUserAuthEvents_402656719(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminListUserAuthEvents_402656718(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656720 = query.getOrDefault("MaxResults")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "MaxResults", valid_402656720
  var valid_402656721 = query.getOrDefault("NextToken")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "NextToken", valid_402656721
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656722 = header.getOrDefault("X-Amz-Target")
  valid_402656722 = validateParameter(valid_402656722, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminListUserAuthEvents"))
  if valid_402656722 != nil:
    section.add "X-Amz-Target", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Security-Token", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-Signature")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-Signature", valid_402656724
  var valid_402656725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656725 = validateParameter(valid_402656725, JString,
                                      required = false, default = nil)
  if valid_402656725 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656725
  var valid_402656726 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656726 = validateParameter(valid_402656726, JString,
                                      required = false, default = nil)
  if valid_402656726 != nil:
    section.add "X-Amz-Algorithm", valid_402656726
  var valid_402656727 = header.getOrDefault("X-Amz-Date")
  valid_402656727 = validateParameter(valid_402656727, JString,
                                      required = false, default = nil)
  if valid_402656727 != nil:
    section.add "X-Amz-Date", valid_402656727
  var valid_402656728 = header.getOrDefault("X-Amz-Credential")
  valid_402656728 = validateParameter(valid_402656728, JString,
                                      required = false, default = nil)
  if valid_402656728 != nil:
    section.add "X-Amz-Credential", valid_402656728
  var valid_402656729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656729 = validateParameter(valid_402656729, JString,
                                      required = false, default = nil)
  if valid_402656729 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656731: Call_AdminListUserAuthEvents_402656717;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists a history of user activity and any risks detected as part of Amazon Cognito advanced security.
                                                                                         ## 
  let valid = call_402656731.validator(path, query, header, formData, body, _)
  let scheme = call_402656731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656731.makeUrl(scheme.get, call_402656731.host, call_402656731.base,
                                   call_402656731.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656731, uri, valid, _)

proc call*(call_402656732: Call_AdminListUserAuthEvents_402656717;
           body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## adminListUserAuthEvents
  ## Lists a history of user activity and any risks detected as part of Amazon Cognito advanced security.
  ##   
                                                                                                         ## MaxResults: string
                                                                                                         ##             
                                                                                                         ## : 
                                                                                                         ## Pagination 
                                                                                                         ## limit
  ##   
                                                                                                                 ## body: JObject (required)
  ##   
                                                                                                                                            ## NextToken: string
                                                                                                                                            ##            
                                                                                                                                            ## : 
                                                                                                                                            ## Pagination 
                                                                                                                                            ## token
  var query_402656733 = newJObject()
  var body_402656734 = newJObject()
  add(query_402656733, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656734 = body
  add(query_402656733, "NextToken", newJString(NextToken))
  result = call_402656732.call(nil, query_402656733, nil, nil, body_402656734)

var adminListUserAuthEvents* = Call_AdminListUserAuthEvents_402656717(
    name: "adminListUserAuthEvents", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminListUserAuthEvents",
    validator: validate_AdminListUserAuthEvents_402656718, base: "/",
    makeUrl: url_AdminListUserAuthEvents_402656719,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminRemoveUserFromGroup_402656735 = ref object of OpenApiRestCall_402656044
proc url_AdminRemoveUserFromGroup_402656737(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminRemoveUserFromGroup_402656736(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656738 = header.getOrDefault("X-Amz-Target")
  valid_402656738 = validateParameter(valid_402656738, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminRemoveUserFromGroup"))
  if valid_402656738 != nil:
    section.add "X-Amz-Target", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-Security-Token", valid_402656739
  var valid_402656740 = header.getOrDefault("X-Amz-Signature")
  valid_402656740 = validateParameter(valid_402656740, JString,
                                      required = false, default = nil)
  if valid_402656740 != nil:
    section.add "X-Amz-Signature", valid_402656740
  var valid_402656741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656741 = validateParameter(valid_402656741, JString,
                                      required = false, default = nil)
  if valid_402656741 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656741
  var valid_402656742 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656742 = validateParameter(valid_402656742, JString,
                                      required = false, default = nil)
  if valid_402656742 != nil:
    section.add "X-Amz-Algorithm", valid_402656742
  var valid_402656743 = header.getOrDefault("X-Amz-Date")
  valid_402656743 = validateParameter(valid_402656743, JString,
                                      required = false, default = nil)
  if valid_402656743 != nil:
    section.add "X-Amz-Date", valid_402656743
  var valid_402656744 = header.getOrDefault("X-Amz-Credential")
  valid_402656744 = validateParameter(valid_402656744, JString,
                                      required = false, default = nil)
  if valid_402656744 != nil:
    section.add "X-Amz-Credential", valid_402656744
  var valid_402656745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656745 = validateParameter(valid_402656745, JString,
                                      required = false, default = nil)
  if valid_402656745 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656745
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656747: Call_AdminRemoveUserFromGroup_402656735;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Removes the specified user from the specified group.</p> <p>Calling this action requires developer credentials.</p>
                                                                                         ## 
  let valid = call_402656747.validator(path, query, header, formData, body, _)
  let scheme = call_402656747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656747.makeUrl(scheme.get, call_402656747.host, call_402656747.base,
                                   call_402656747.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656747, uri, valid, _)

proc call*(call_402656748: Call_AdminRemoveUserFromGroup_402656735;
           body: JsonNode): Recallable =
  ## adminRemoveUserFromGroup
  ## <p>Removes the specified user from the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ##   
                                                                                                                           ## body: JObject (required)
  var body_402656749 = newJObject()
  if body != nil:
    body_402656749 = body
  result = call_402656748.call(nil, nil, nil, nil, body_402656749)

var adminRemoveUserFromGroup* = Call_AdminRemoveUserFromGroup_402656735(
    name: "adminRemoveUserFromGroup", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminRemoveUserFromGroup",
    validator: validate_AdminRemoveUserFromGroup_402656736, base: "/",
    makeUrl: url_AdminRemoveUserFromGroup_402656737,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminResetUserPassword_402656750 = ref object of OpenApiRestCall_402656044
proc url_AdminResetUserPassword_402656752(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminResetUserPassword_402656751(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656753 = header.getOrDefault("X-Amz-Target")
  valid_402656753 = validateParameter(valid_402656753, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminResetUserPassword"))
  if valid_402656753 != nil:
    section.add "X-Amz-Target", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-Security-Token", valid_402656754
  var valid_402656755 = header.getOrDefault("X-Amz-Signature")
  valid_402656755 = validateParameter(valid_402656755, JString,
                                      required = false, default = nil)
  if valid_402656755 != nil:
    section.add "X-Amz-Signature", valid_402656755
  var valid_402656756 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656756 = validateParameter(valid_402656756, JString,
                                      required = false, default = nil)
  if valid_402656756 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656756
  var valid_402656757 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656757 = validateParameter(valid_402656757, JString,
                                      required = false, default = nil)
  if valid_402656757 != nil:
    section.add "X-Amz-Algorithm", valid_402656757
  var valid_402656758 = header.getOrDefault("X-Amz-Date")
  valid_402656758 = validateParameter(valid_402656758, JString,
                                      required = false, default = nil)
  if valid_402656758 != nil:
    section.add "X-Amz-Date", valid_402656758
  var valid_402656759 = header.getOrDefault("X-Amz-Credential")
  valid_402656759 = validateParameter(valid_402656759, JString,
                                      required = false, default = nil)
  if valid_402656759 != nil:
    section.add "X-Amz-Credential", valid_402656759
  var valid_402656760 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656760 = validateParameter(valid_402656760, JString,
                                      required = false, default = nil)
  if valid_402656760 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656760
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656762: Call_AdminResetUserPassword_402656750;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Resets the specified user's password in a user pool as an administrator. Works on any user.</p> <p>When a developer calls this API, the current password is invalidated, so it must be changed. If a user tries to sign in after the API is called, the app will get a PasswordResetRequiredException exception back and should direct the user down the flow to reset the password, which is the same as the forgot password flow. In addition, if the user pool has phone verification selected and a verified phone number exists for the user, or if email verification is selected and a verified email exists for the user, calling this API will also result in sending a message to the end user with the code to change their password.</p> <p>Calling this action requires developer credentials.</p>
                                                                                         ## 
  let valid = call_402656762.validator(path, query, header, formData, body, _)
  let scheme = call_402656762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656762.makeUrl(scheme.get, call_402656762.host, call_402656762.base,
                                   call_402656762.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656762, uri, valid, _)

proc call*(call_402656763: Call_AdminResetUserPassword_402656750; body: JsonNode): Recallable =
  ## adminResetUserPassword
  ## <p>Resets the specified user's password in a user pool as an administrator. Works on any user.</p> <p>When a developer calls this API, the current password is invalidated, so it must be changed. If a user tries to sign in after the API is called, the app will get a PasswordResetRequiredException exception back and should direct the user down the flow to reset the password, which is the same as the forgot password flow. In addition, if the user pool has phone verification selected and a verified phone number exists for the user, or if email verification is selected and a verified email exists for the user, calling this API will also result in sending a message to the end user with the code to change their password.</p> <p>Calling this action requires developer credentials.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402656764 = newJObject()
  if body != nil:
    body_402656764 = body
  result = call_402656763.call(nil, nil, nil, nil, body_402656764)

var adminResetUserPassword* = Call_AdminResetUserPassword_402656750(
    name: "adminResetUserPassword", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminResetUserPassword",
    validator: validate_AdminResetUserPassword_402656751, base: "/",
    makeUrl: url_AdminResetUserPassword_402656752,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminRespondToAuthChallenge_402656765 = ref object of OpenApiRestCall_402656044
proc url_AdminRespondToAuthChallenge_402656767(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminRespondToAuthChallenge_402656766(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656768 = header.getOrDefault("X-Amz-Target")
  valid_402656768 = validateParameter(valid_402656768, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminRespondToAuthChallenge"))
  if valid_402656768 != nil:
    section.add "X-Amz-Target", valid_402656768
  var valid_402656769 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-Security-Token", valid_402656769
  var valid_402656770 = header.getOrDefault("X-Amz-Signature")
  valid_402656770 = validateParameter(valid_402656770, JString,
                                      required = false, default = nil)
  if valid_402656770 != nil:
    section.add "X-Amz-Signature", valid_402656770
  var valid_402656771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656771 = validateParameter(valid_402656771, JString,
                                      required = false, default = nil)
  if valid_402656771 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656771
  var valid_402656772 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656772 = validateParameter(valid_402656772, JString,
                                      required = false, default = nil)
  if valid_402656772 != nil:
    section.add "X-Amz-Algorithm", valid_402656772
  var valid_402656773 = header.getOrDefault("X-Amz-Date")
  valid_402656773 = validateParameter(valid_402656773, JString,
                                      required = false, default = nil)
  if valid_402656773 != nil:
    section.add "X-Amz-Date", valid_402656773
  var valid_402656774 = header.getOrDefault("X-Amz-Credential")
  valid_402656774 = validateParameter(valid_402656774, JString,
                                      required = false, default = nil)
  if valid_402656774 != nil:
    section.add "X-Amz-Credential", valid_402656774
  var valid_402656775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656775 = validateParameter(valid_402656775, JString,
                                      required = false, default = nil)
  if valid_402656775 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656775
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656777: Call_AdminRespondToAuthChallenge_402656765;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Responds to an authentication challenge, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
                                                                                         ## 
  let valid = call_402656777.validator(path, query, header, formData, body, _)
  let scheme = call_402656777.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656777.makeUrl(scheme.get, call_402656777.host, call_402656777.base,
                                   call_402656777.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656777, uri, valid, _)

proc call*(call_402656778: Call_AdminRespondToAuthChallenge_402656765;
           body: JsonNode): Recallable =
  ## adminRespondToAuthChallenge
  ## <p>Responds to an authentication challenge, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   
                                                                                                                                    ## body: JObject (required)
  var body_402656779 = newJObject()
  if body != nil:
    body_402656779 = body
  result = call_402656778.call(nil, nil, nil, nil, body_402656779)

var adminRespondToAuthChallenge* = Call_AdminRespondToAuthChallenge_402656765(
    name: "adminRespondToAuthChallenge", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminRespondToAuthChallenge",
    validator: validate_AdminRespondToAuthChallenge_402656766, base: "/",
    makeUrl: url_AdminRespondToAuthChallenge_402656767,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminSetUserMFAPreference_402656780 = ref object of OpenApiRestCall_402656044
proc url_AdminSetUserMFAPreference_402656782(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminSetUserMFAPreference_402656781(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656783 = header.getOrDefault("X-Amz-Target")
  valid_402656783 = validateParameter(valid_402656783, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminSetUserMFAPreference"))
  if valid_402656783 != nil:
    section.add "X-Amz-Target", valid_402656783
  var valid_402656784 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656784 = validateParameter(valid_402656784, JString,
                                      required = false, default = nil)
  if valid_402656784 != nil:
    section.add "X-Amz-Security-Token", valid_402656784
  var valid_402656785 = header.getOrDefault("X-Amz-Signature")
  valid_402656785 = validateParameter(valid_402656785, JString,
                                      required = false, default = nil)
  if valid_402656785 != nil:
    section.add "X-Amz-Signature", valid_402656785
  var valid_402656786 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656786 = validateParameter(valid_402656786, JString,
                                      required = false, default = nil)
  if valid_402656786 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656786
  var valid_402656787 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656787 = validateParameter(valid_402656787, JString,
                                      required = false, default = nil)
  if valid_402656787 != nil:
    section.add "X-Amz-Algorithm", valid_402656787
  var valid_402656788 = header.getOrDefault("X-Amz-Date")
  valid_402656788 = validateParameter(valid_402656788, JString,
                                      required = false, default = nil)
  if valid_402656788 != nil:
    section.add "X-Amz-Date", valid_402656788
  var valid_402656789 = header.getOrDefault("X-Amz-Credential")
  valid_402656789 = validateParameter(valid_402656789, JString,
                                      required = false, default = nil)
  if valid_402656789 != nil:
    section.add "X-Amz-Credential", valid_402656789
  var valid_402656790 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656790 = validateParameter(valid_402656790, JString,
                                      required = false, default = nil)
  if valid_402656790 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656790
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656792: Call_AdminSetUserMFAPreference_402656780;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Sets the user's multi-factor authentication (MFA) preference, including which MFA options are enabled and if any are preferred. Only one factor can be set as preferred. The preferred MFA factor will be used to authenticate a user if multiple factors are enabled. If multiple options are enabled and no preference is set, a challenge to choose an MFA option will be returned during sign in.
                                                                                         ## 
  let valid = call_402656792.validator(path, query, header, formData, body, _)
  let scheme = call_402656792.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656792.makeUrl(scheme.get, call_402656792.host, call_402656792.base,
                                   call_402656792.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656792, uri, valid, _)

proc call*(call_402656793: Call_AdminSetUserMFAPreference_402656780;
           body: JsonNode): Recallable =
  ## adminSetUserMFAPreference
  ## Sets the user's multi-factor authentication (MFA) preference, including which MFA options are enabled and if any are preferred. Only one factor can be set as preferred. The preferred MFA factor will be used to authenticate a user if multiple factors are enabled. If multiple options are enabled and no preference is set, a challenge to choose an MFA option will be returned during sign in.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402656794 = newJObject()
  if body != nil:
    body_402656794 = body
  result = call_402656793.call(nil, nil, nil, nil, body_402656794)

var adminSetUserMFAPreference* = Call_AdminSetUserMFAPreference_402656780(
    name: "adminSetUserMFAPreference", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminSetUserMFAPreference",
    validator: validate_AdminSetUserMFAPreference_402656781, base: "/",
    makeUrl: url_AdminSetUserMFAPreference_402656782,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminSetUserPassword_402656795 = ref object of OpenApiRestCall_402656044
proc url_AdminSetUserPassword_402656797(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminSetUserPassword_402656796(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656798 = header.getOrDefault("X-Amz-Target")
  valid_402656798 = validateParameter(valid_402656798, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminSetUserPassword"))
  if valid_402656798 != nil:
    section.add "X-Amz-Target", valid_402656798
  var valid_402656799 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656799 = validateParameter(valid_402656799, JString,
                                      required = false, default = nil)
  if valid_402656799 != nil:
    section.add "X-Amz-Security-Token", valid_402656799
  var valid_402656800 = header.getOrDefault("X-Amz-Signature")
  valid_402656800 = validateParameter(valid_402656800, JString,
                                      required = false, default = nil)
  if valid_402656800 != nil:
    section.add "X-Amz-Signature", valid_402656800
  var valid_402656801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656801 = validateParameter(valid_402656801, JString,
                                      required = false, default = nil)
  if valid_402656801 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656801
  var valid_402656802 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656802 = validateParameter(valid_402656802, JString,
                                      required = false, default = nil)
  if valid_402656802 != nil:
    section.add "X-Amz-Algorithm", valid_402656802
  var valid_402656803 = header.getOrDefault("X-Amz-Date")
  valid_402656803 = validateParameter(valid_402656803, JString,
                                      required = false, default = nil)
  if valid_402656803 != nil:
    section.add "X-Amz-Date", valid_402656803
  var valid_402656804 = header.getOrDefault("X-Amz-Credential")
  valid_402656804 = validateParameter(valid_402656804, JString,
                                      required = false, default = nil)
  if valid_402656804 != nil:
    section.add "X-Amz-Credential", valid_402656804
  var valid_402656805 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656805 = validateParameter(valid_402656805, JString,
                                      required = false, default = nil)
  if valid_402656805 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656805
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656807: Call_AdminSetUserPassword_402656795;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sets the specified user's password in a user pool as an administrator. Works on any user. </p> <p>The password can be temporary or permanent. If it is temporary, the user status will be placed into the <code>FORCE_CHANGE_PASSWORD</code> state. When the user next tries to sign in, the InitiateAuth/AdminInitiateAuth response will contain the <code>NEW_PASSWORD_REQUIRED</code> challenge. If the user does not sign in before it expires, the user will not be able to sign in and their password will need to be reset by an administrator. </p> <p>Once the user has set a new password, or the password is permanent, the user status will be set to <code>Confirmed</code>.</p>
                                                                                         ## 
  let valid = call_402656807.validator(path, query, header, formData, body, _)
  let scheme = call_402656807.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656807.makeUrl(scheme.get, call_402656807.host, call_402656807.base,
                                   call_402656807.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656807, uri, valid, _)

proc call*(call_402656808: Call_AdminSetUserPassword_402656795; body: JsonNode): Recallable =
  ## adminSetUserPassword
  ## <p>Sets the specified user's password in a user pool as an administrator. Works on any user. </p> <p>The password can be temporary or permanent. If it is temporary, the user status will be placed into the <code>FORCE_CHANGE_PASSWORD</code> state. When the user next tries to sign in, the InitiateAuth/AdminInitiateAuth response will contain the <code>NEW_PASSWORD_REQUIRED</code> challenge. If the user does not sign in before it expires, the user will not be able to sign in and their password will need to be reset by an administrator. </p> <p>Once the user has set a new password, or the password is permanent, the user status will be set to <code>Confirmed</code>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  var body_402656809 = newJObject()
  if body != nil:
    body_402656809 = body
  result = call_402656808.call(nil, nil, nil, nil, body_402656809)

var adminSetUserPassword* = Call_AdminSetUserPassword_402656795(
    name: "adminSetUserPassword", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminSetUserPassword",
    validator: validate_AdminSetUserPassword_402656796, base: "/",
    makeUrl: url_AdminSetUserPassword_402656797,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminSetUserSettings_402656810 = ref object of OpenApiRestCall_402656044
proc url_AdminSetUserSettings_402656812(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminSetUserSettings_402656811(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656813 = header.getOrDefault("X-Amz-Target")
  valid_402656813 = validateParameter(valid_402656813, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminSetUserSettings"))
  if valid_402656813 != nil:
    section.add "X-Amz-Target", valid_402656813
  var valid_402656814 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656814 = validateParameter(valid_402656814, JString,
                                      required = false, default = nil)
  if valid_402656814 != nil:
    section.add "X-Amz-Security-Token", valid_402656814
  var valid_402656815 = header.getOrDefault("X-Amz-Signature")
  valid_402656815 = validateParameter(valid_402656815, JString,
                                      required = false, default = nil)
  if valid_402656815 != nil:
    section.add "X-Amz-Signature", valid_402656815
  var valid_402656816 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656816 = validateParameter(valid_402656816, JString,
                                      required = false, default = nil)
  if valid_402656816 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656816
  var valid_402656817 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656817 = validateParameter(valid_402656817, JString,
                                      required = false, default = nil)
  if valid_402656817 != nil:
    section.add "X-Amz-Algorithm", valid_402656817
  var valid_402656818 = header.getOrDefault("X-Amz-Date")
  valid_402656818 = validateParameter(valid_402656818, JString,
                                      required = false, default = nil)
  if valid_402656818 != nil:
    section.add "X-Amz-Date", valid_402656818
  var valid_402656819 = header.getOrDefault("X-Amz-Credential")
  valid_402656819 = validateParameter(valid_402656819, JString,
                                      required = false, default = nil)
  if valid_402656819 != nil:
    section.add "X-Amz-Credential", valid_402656819
  var valid_402656820 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656820 = validateParameter(valid_402656820, JString,
                                      required = false, default = nil)
  if valid_402656820 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656820
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656822: Call_AdminSetUserSettings_402656810;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  <i>This action is no longer supported.</i> You can use it to configure only SMS MFA. You can't use it to configure TOTP software token MFA. To configure either type of MFA, use the <a>AdminSetUserMFAPreference</a> action instead.
                                                                                         ## 
  let valid = call_402656822.validator(path, query, header, formData, body, _)
  let scheme = call_402656822.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656822.makeUrl(scheme.get, call_402656822.host, call_402656822.base,
                                   call_402656822.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656822, uri, valid, _)

proc call*(call_402656823: Call_AdminSetUserSettings_402656810; body: JsonNode): Recallable =
  ## adminSetUserSettings
  ##  <i>This action is no longer supported.</i> You can use it to configure only SMS MFA. You can't use it to configure TOTP software token MFA. To configure either type of MFA, use the <a>AdminSetUserMFAPreference</a> action instead.
  ##   
                                                                                                                                                                                                                                           ## body: JObject (required)
  var body_402656824 = newJObject()
  if body != nil:
    body_402656824 = body
  result = call_402656823.call(nil, nil, nil, nil, body_402656824)

var adminSetUserSettings* = Call_AdminSetUserSettings_402656810(
    name: "adminSetUserSettings", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminSetUserSettings",
    validator: validate_AdminSetUserSettings_402656811, base: "/",
    makeUrl: url_AdminSetUserSettings_402656812,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUpdateAuthEventFeedback_402656825 = ref object of OpenApiRestCall_402656044
proc url_AdminUpdateAuthEventFeedback_402656827(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminUpdateAuthEventFeedback_402656826(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656828 = header.getOrDefault("X-Amz-Target")
  valid_402656828 = validateParameter(valid_402656828, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUpdateAuthEventFeedback"))
  if valid_402656828 != nil:
    section.add "X-Amz-Target", valid_402656828
  var valid_402656829 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656829 = validateParameter(valid_402656829, JString,
                                      required = false, default = nil)
  if valid_402656829 != nil:
    section.add "X-Amz-Security-Token", valid_402656829
  var valid_402656830 = header.getOrDefault("X-Amz-Signature")
  valid_402656830 = validateParameter(valid_402656830, JString,
                                      required = false, default = nil)
  if valid_402656830 != nil:
    section.add "X-Amz-Signature", valid_402656830
  var valid_402656831 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656831 = validateParameter(valid_402656831, JString,
                                      required = false, default = nil)
  if valid_402656831 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656831
  var valid_402656832 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656832 = validateParameter(valid_402656832, JString,
                                      required = false, default = nil)
  if valid_402656832 != nil:
    section.add "X-Amz-Algorithm", valid_402656832
  var valid_402656833 = header.getOrDefault("X-Amz-Date")
  valid_402656833 = validateParameter(valid_402656833, JString,
                                      required = false, default = nil)
  if valid_402656833 != nil:
    section.add "X-Amz-Date", valid_402656833
  var valid_402656834 = header.getOrDefault("X-Amz-Credential")
  valid_402656834 = validateParameter(valid_402656834, JString,
                                      required = false, default = nil)
  if valid_402656834 != nil:
    section.add "X-Amz-Credential", valid_402656834
  var valid_402656835 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656835 = validateParameter(valid_402656835, JString,
                                      required = false, default = nil)
  if valid_402656835 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656835
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656837: Call_AdminUpdateAuthEventFeedback_402656825;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides feedback for an authentication event as to whether it was from a valid user. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
                                                                                         ## 
  let valid = call_402656837.validator(path, query, header, formData, body, _)
  let scheme = call_402656837.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656837.makeUrl(scheme.get, call_402656837.host, call_402656837.base,
                                   call_402656837.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656837, uri, valid, _)

proc call*(call_402656838: Call_AdminUpdateAuthEventFeedback_402656825;
           body: JsonNode): Recallable =
  ## adminUpdateAuthEventFeedback
  ## Provides feedback for an authentication event as to whether it was from a valid user. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ##   
                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402656839 = newJObject()
  if body != nil:
    body_402656839 = body
  result = call_402656838.call(nil, nil, nil, nil, body_402656839)

var adminUpdateAuthEventFeedback* = Call_AdminUpdateAuthEventFeedback_402656825(
    name: "adminUpdateAuthEventFeedback", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUpdateAuthEventFeedback",
    validator: validate_AdminUpdateAuthEventFeedback_402656826, base: "/",
    makeUrl: url_AdminUpdateAuthEventFeedback_402656827,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUpdateDeviceStatus_402656840 = ref object of OpenApiRestCall_402656044
proc url_AdminUpdateDeviceStatus_402656842(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminUpdateDeviceStatus_402656841(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656843 = header.getOrDefault("X-Amz-Target")
  valid_402656843 = validateParameter(valid_402656843, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUpdateDeviceStatus"))
  if valid_402656843 != nil:
    section.add "X-Amz-Target", valid_402656843
  var valid_402656844 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656844 = validateParameter(valid_402656844, JString,
                                      required = false, default = nil)
  if valid_402656844 != nil:
    section.add "X-Amz-Security-Token", valid_402656844
  var valid_402656845 = header.getOrDefault("X-Amz-Signature")
  valid_402656845 = validateParameter(valid_402656845, JString,
                                      required = false, default = nil)
  if valid_402656845 != nil:
    section.add "X-Amz-Signature", valid_402656845
  var valid_402656846 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656846 = validateParameter(valid_402656846, JString,
                                      required = false, default = nil)
  if valid_402656846 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656846
  var valid_402656847 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656847 = validateParameter(valid_402656847, JString,
                                      required = false, default = nil)
  if valid_402656847 != nil:
    section.add "X-Amz-Algorithm", valid_402656847
  var valid_402656848 = header.getOrDefault("X-Amz-Date")
  valid_402656848 = validateParameter(valid_402656848, JString,
                                      required = false, default = nil)
  if valid_402656848 != nil:
    section.add "X-Amz-Date", valid_402656848
  var valid_402656849 = header.getOrDefault("X-Amz-Credential")
  valid_402656849 = validateParameter(valid_402656849, JString,
                                      required = false, default = nil)
  if valid_402656849 != nil:
    section.add "X-Amz-Credential", valid_402656849
  var valid_402656850 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656850 = validateParameter(valid_402656850, JString,
                                      required = false, default = nil)
  if valid_402656850 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656850
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656852: Call_AdminUpdateDeviceStatus_402656840;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the device status as an administrator.</p> <p>Calling this action requires developer credentials.</p>
                                                                                         ## 
  let valid = call_402656852.validator(path, query, header, formData, body, _)
  let scheme = call_402656852.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656852.makeUrl(scheme.get, call_402656852.host, call_402656852.base,
                                   call_402656852.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656852, uri, valid, _)

proc call*(call_402656853: Call_AdminUpdateDeviceStatus_402656840;
           body: JsonNode): Recallable =
  ## adminUpdateDeviceStatus
  ## <p>Updates the device status as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   
                                                                                                                     ## body: JObject (required)
  var body_402656854 = newJObject()
  if body != nil:
    body_402656854 = body
  result = call_402656853.call(nil, nil, nil, nil, body_402656854)

var adminUpdateDeviceStatus* = Call_AdminUpdateDeviceStatus_402656840(
    name: "adminUpdateDeviceStatus", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUpdateDeviceStatus",
    validator: validate_AdminUpdateDeviceStatus_402656841, base: "/",
    makeUrl: url_AdminUpdateDeviceStatus_402656842,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUpdateUserAttributes_402656855 = ref object of OpenApiRestCall_402656044
proc url_AdminUpdateUserAttributes_402656857(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminUpdateUserAttributes_402656856(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656858 = header.getOrDefault("X-Amz-Target")
  valid_402656858 = validateParameter(valid_402656858, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUpdateUserAttributes"))
  if valid_402656858 != nil:
    section.add "X-Amz-Target", valid_402656858
  var valid_402656859 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656859 = validateParameter(valid_402656859, JString,
                                      required = false, default = nil)
  if valid_402656859 != nil:
    section.add "X-Amz-Security-Token", valid_402656859
  var valid_402656860 = header.getOrDefault("X-Amz-Signature")
  valid_402656860 = validateParameter(valid_402656860, JString,
                                      required = false, default = nil)
  if valid_402656860 != nil:
    section.add "X-Amz-Signature", valid_402656860
  var valid_402656861 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656861 = validateParameter(valid_402656861, JString,
                                      required = false, default = nil)
  if valid_402656861 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656861
  var valid_402656862 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656862 = validateParameter(valid_402656862, JString,
                                      required = false, default = nil)
  if valid_402656862 != nil:
    section.add "X-Amz-Algorithm", valid_402656862
  var valid_402656863 = header.getOrDefault("X-Amz-Date")
  valid_402656863 = validateParameter(valid_402656863, JString,
                                      required = false, default = nil)
  if valid_402656863 != nil:
    section.add "X-Amz-Date", valid_402656863
  var valid_402656864 = header.getOrDefault("X-Amz-Credential")
  valid_402656864 = validateParameter(valid_402656864, JString,
                                      required = false, default = nil)
  if valid_402656864 != nil:
    section.add "X-Amz-Credential", valid_402656864
  var valid_402656865 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656865 = validateParameter(valid_402656865, JString,
                                      required = false, default = nil)
  if valid_402656865 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656865
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656867: Call_AdminUpdateUserAttributes_402656855;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the specified user's attributes, including developer attributes, as an administrator. Works on any user.</p> <p>For custom attributes, you must prepend the <code>custom:</code> prefix to the attribute name.</p> <p>In addition to updating user attributes, this API can also be used to mark phone and email as verified.</p> <p>Calling this action requires developer credentials.</p>
                                                                                         ## 
  let valid = call_402656867.validator(path, query, header, formData, body, _)
  let scheme = call_402656867.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656867.makeUrl(scheme.get, call_402656867.host, call_402656867.base,
                                   call_402656867.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656867, uri, valid, _)

proc call*(call_402656868: Call_AdminUpdateUserAttributes_402656855;
           body: JsonNode): Recallable =
  ## adminUpdateUserAttributes
  ## <p>Updates the specified user's attributes, including developer attributes, as an administrator. Works on any user.</p> <p>For custom attributes, you must prepend the <code>custom:</code> prefix to the attribute name.</p> <p>In addition to updating user attributes, this API can also be used to mark phone and email as verified.</p> <p>Calling this action requires developer credentials.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402656869 = newJObject()
  if body != nil:
    body_402656869 = body
  result = call_402656868.call(nil, nil, nil, nil, body_402656869)

var adminUpdateUserAttributes* = Call_AdminUpdateUserAttributes_402656855(
    name: "adminUpdateUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUpdateUserAttributes",
    validator: validate_AdminUpdateUserAttributes_402656856, base: "/",
    makeUrl: url_AdminUpdateUserAttributes_402656857,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUserGlobalSignOut_402656870 = ref object of OpenApiRestCall_402656044
proc url_AdminUserGlobalSignOut_402656872(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminUserGlobalSignOut_402656871(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656873 = header.getOrDefault("X-Amz-Target")
  valid_402656873 = validateParameter(valid_402656873, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUserGlobalSignOut"))
  if valid_402656873 != nil:
    section.add "X-Amz-Target", valid_402656873
  var valid_402656874 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656874 = validateParameter(valid_402656874, JString,
                                      required = false, default = nil)
  if valid_402656874 != nil:
    section.add "X-Amz-Security-Token", valid_402656874
  var valid_402656875 = header.getOrDefault("X-Amz-Signature")
  valid_402656875 = validateParameter(valid_402656875, JString,
                                      required = false, default = nil)
  if valid_402656875 != nil:
    section.add "X-Amz-Signature", valid_402656875
  var valid_402656876 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656876 = validateParameter(valid_402656876, JString,
                                      required = false, default = nil)
  if valid_402656876 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656876
  var valid_402656877 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656877 = validateParameter(valid_402656877, JString,
                                      required = false, default = nil)
  if valid_402656877 != nil:
    section.add "X-Amz-Algorithm", valid_402656877
  var valid_402656878 = header.getOrDefault("X-Amz-Date")
  valid_402656878 = validateParameter(valid_402656878, JString,
                                      required = false, default = nil)
  if valid_402656878 != nil:
    section.add "X-Amz-Date", valid_402656878
  var valid_402656879 = header.getOrDefault("X-Amz-Credential")
  valid_402656879 = validateParameter(valid_402656879, JString,
                                      required = false, default = nil)
  if valid_402656879 != nil:
    section.add "X-Amz-Credential", valid_402656879
  var valid_402656880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656880 = validateParameter(valid_402656880, JString,
                                      required = false, default = nil)
  if valid_402656880 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656880
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656882: Call_AdminUserGlobalSignOut_402656870;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Signs out users from all devices, as an administrator. It also invalidates all refresh tokens issued to a user. The user's current access and Id tokens remain valid until their expiry. Access and Id tokens expire one hour after they are issued.</p> <p>Calling this action requires developer credentials.</p>
                                                                                         ## 
  let valid = call_402656882.validator(path, query, header, formData, body, _)
  let scheme = call_402656882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656882.makeUrl(scheme.get, call_402656882.host, call_402656882.base,
                                   call_402656882.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656882, uri, valid, _)

proc call*(call_402656883: Call_AdminUserGlobalSignOut_402656870; body: JsonNode): Recallable =
  ## adminUserGlobalSignOut
  ## <p>Signs out users from all devices, as an administrator. It also invalidates all refresh tokens issued to a user. The user's current access and Id tokens remain valid until their expiry. Access and Id tokens expire one hour after they are issued.</p> <p>Calling this action requires developer credentials.</p>
  ##   
                                                                                                                                                                                                                                                                                                                           ## body: JObject (required)
  var body_402656884 = newJObject()
  if body != nil:
    body_402656884 = body
  result = call_402656883.call(nil, nil, nil, nil, body_402656884)

var adminUserGlobalSignOut* = Call_AdminUserGlobalSignOut_402656870(
    name: "adminUserGlobalSignOut", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUserGlobalSignOut",
    validator: validate_AdminUserGlobalSignOut_402656871, base: "/",
    makeUrl: url_AdminUserGlobalSignOut_402656872,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSoftwareToken_402656885 = ref object of OpenApiRestCall_402656044
proc url_AssociateSoftwareToken_402656887(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateSoftwareToken_402656886(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656888 = header.getOrDefault("X-Amz-Target")
  valid_402656888 = validateParameter(valid_402656888, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AssociateSoftwareToken"))
  if valid_402656888 != nil:
    section.add "X-Amz-Target", valid_402656888
  var valid_402656889 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656889 = validateParameter(valid_402656889, JString,
                                      required = false, default = nil)
  if valid_402656889 != nil:
    section.add "X-Amz-Security-Token", valid_402656889
  var valid_402656890 = header.getOrDefault("X-Amz-Signature")
  valid_402656890 = validateParameter(valid_402656890, JString,
                                      required = false, default = nil)
  if valid_402656890 != nil:
    section.add "X-Amz-Signature", valid_402656890
  var valid_402656891 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656891 = validateParameter(valid_402656891, JString,
                                      required = false, default = nil)
  if valid_402656891 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656891
  var valid_402656892 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656892 = validateParameter(valid_402656892, JString,
                                      required = false, default = nil)
  if valid_402656892 != nil:
    section.add "X-Amz-Algorithm", valid_402656892
  var valid_402656893 = header.getOrDefault("X-Amz-Date")
  valid_402656893 = validateParameter(valid_402656893, JString,
                                      required = false, default = nil)
  if valid_402656893 != nil:
    section.add "X-Amz-Date", valid_402656893
  var valid_402656894 = header.getOrDefault("X-Amz-Credential")
  valid_402656894 = validateParameter(valid_402656894, JString,
                                      required = false, default = nil)
  if valid_402656894 != nil:
    section.add "X-Amz-Credential", valid_402656894
  var valid_402656895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656895 = validateParameter(valid_402656895, JString,
                                      required = false, default = nil)
  if valid_402656895 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656895
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656897: Call_AssociateSoftwareToken_402656885;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a unique generated shared secret key code for the user account. The request takes an access token or a session string, but not both.
                                                                                         ## 
  let valid = call_402656897.validator(path, query, header, formData, body, _)
  let scheme = call_402656897.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656897.makeUrl(scheme.get, call_402656897.host, call_402656897.base,
                                   call_402656897.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656897, uri, valid, _)

proc call*(call_402656898: Call_AssociateSoftwareToken_402656885; body: JsonNode): Recallable =
  ## associateSoftwareToken
  ## Returns a unique generated shared secret key code for the user account. The request takes an access token or a session string, but not both.
  ##   
                                                                                                                                                 ## body: JObject (required)
  var body_402656899 = newJObject()
  if body != nil:
    body_402656899 = body
  result = call_402656898.call(nil, nil, nil, nil, body_402656899)

var associateSoftwareToken* = Call_AssociateSoftwareToken_402656885(
    name: "associateSoftwareToken", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AssociateSoftwareToken",
    validator: validate_AssociateSoftwareToken_402656886, base: "/",
    makeUrl: url_AssociateSoftwareToken_402656887,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ChangePassword_402656900 = ref object of OpenApiRestCall_402656044
proc url_ChangePassword_402656902(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ChangePassword_402656901(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656903 = header.getOrDefault("X-Amz-Target")
  valid_402656903 = validateParameter(valid_402656903, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ChangePassword"))
  if valid_402656903 != nil:
    section.add "X-Amz-Target", valid_402656903
  var valid_402656904 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656904 = validateParameter(valid_402656904, JString,
                                      required = false, default = nil)
  if valid_402656904 != nil:
    section.add "X-Amz-Security-Token", valid_402656904
  var valid_402656905 = header.getOrDefault("X-Amz-Signature")
  valid_402656905 = validateParameter(valid_402656905, JString,
                                      required = false, default = nil)
  if valid_402656905 != nil:
    section.add "X-Amz-Signature", valid_402656905
  var valid_402656906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656906 = validateParameter(valid_402656906, JString,
                                      required = false, default = nil)
  if valid_402656906 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656906
  var valid_402656907 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656907 = validateParameter(valid_402656907, JString,
                                      required = false, default = nil)
  if valid_402656907 != nil:
    section.add "X-Amz-Algorithm", valid_402656907
  var valid_402656908 = header.getOrDefault("X-Amz-Date")
  valid_402656908 = validateParameter(valid_402656908, JString,
                                      required = false, default = nil)
  if valid_402656908 != nil:
    section.add "X-Amz-Date", valid_402656908
  var valid_402656909 = header.getOrDefault("X-Amz-Credential")
  valid_402656909 = validateParameter(valid_402656909, JString,
                                      required = false, default = nil)
  if valid_402656909 != nil:
    section.add "X-Amz-Credential", valid_402656909
  var valid_402656910 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656910 = validateParameter(valid_402656910, JString,
                                      required = false, default = nil)
  if valid_402656910 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656912: Call_ChangePassword_402656900; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Changes the password for a specified user in a user pool.
                                                                                         ## 
  let valid = call_402656912.validator(path, query, header, formData, body, _)
  let scheme = call_402656912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656912.makeUrl(scheme.get, call_402656912.host, call_402656912.base,
                                   call_402656912.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656912, uri, valid, _)

proc call*(call_402656913: Call_ChangePassword_402656900; body: JsonNode): Recallable =
  ## changePassword
  ## Changes the password for a specified user in a user pool.
  ##   body: JObject (required)
  var body_402656914 = newJObject()
  if body != nil:
    body_402656914 = body
  result = call_402656913.call(nil, nil, nil, nil, body_402656914)

var changePassword* = Call_ChangePassword_402656900(name: "changePassword",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ChangePassword",
    validator: validate_ChangePassword_402656901, base: "/",
    makeUrl: url_ChangePassword_402656902, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmDevice_402656915 = ref object of OpenApiRestCall_402656044
proc url_ConfirmDevice_402656917(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ConfirmDevice_402656916(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656918 = header.getOrDefault("X-Amz-Target")
  valid_402656918 = validateParameter(valid_402656918, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ConfirmDevice"))
  if valid_402656918 != nil:
    section.add "X-Amz-Target", valid_402656918
  var valid_402656919 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656919 = validateParameter(valid_402656919, JString,
                                      required = false, default = nil)
  if valid_402656919 != nil:
    section.add "X-Amz-Security-Token", valid_402656919
  var valid_402656920 = header.getOrDefault("X-Amz-Signature")
  valid_402656920 = validateParameter(valid_402656920, JString,
                                      required = false, default = nil)
  if valid_402656920 != nil:
    section.add "X-Amz-Signature", valid_402656920
  var valid_402656921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656921 = validateParameter(valid_402656921, JString,
                                      required = false, default = nil)
  if valid_402656921 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656921
  var valid_402656922 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656922 = validateParameter(valid_402656922, JString,
                                      required = false, default = nil)
  if valid_402656922 != nil:
    section.add "X-Amz-Algorithm", valid_402656922
  var valid_402656923 = header.getOrDefault("X-Amz-Date")
  valid_402656923 = validateParameter(valid_402656923, JString,
                                      required = false, default = nil)
  if valid_402656923 != nil:
    section.add "X-Amz-Date", valid_402656923
  var valid_402656924 = header.getOrDefault("X-Amz-Credential")
  valid_402656924 = validateParameter(valid_402656924, JString,
                                      required = false, default = nil)
  if valid_402656924 != nil:
    section.add "X-Amz-Credential", valid_402656924
  var valid_402656925 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656925 = validateParameter(valid_402656925, JString,
                                      required = false, default = nil)
  if valid_402656925 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656925
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656927: Call_ConfirmDevice_402656915; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Confirms tracking of the device. This API call is the call that begins device tracking.
                                                                                         ## 
  let valid = call_402656927.validator(path, query, header, formData, body, _)
  let scheme = call_402656927.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656927.makeUrl(scheme.get, call_402656927.host, call_402656927.base,
                                   call_402656927.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656927, uri, valid, _)

proc call*(call_402656928: Call_ConfirmDevice_402656915; body: JsonNode): Recallable =
  ## confirmDevice
  ## Confirms tracking of the device. This API call is the call that begins device tracking.
  ##   
                                                                                            ## body: JObject (required)
  var body_402656929 = newJObject()
  if body != nil:
    body_402656929 = body
  result = call_402656928.call(nil, nil, nil, nil, body_402656929)

var confirmDevice* = Call_ConfirmDevice_402656915(name: "confirmDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ConfirmDevice",
    validator: validate_ConfirmDevice_402656916, base: "/",
    makeUrl: url_ConfirmDevice_402656917, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmForgotPassword_402656930 = ref object of OpenApiRestCall_402656044
proc url_ConfirmForgotPassword_402656932(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ConfirmForgotPassword_402656931(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656933 = header.getOrDefault("X-Amz-Target")
  valid_402656933 = validateParameter(valid_402656933, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ConfirmForgotPassword"))
  if valid_402656933 != nil:
    section.add "X-Amz-Target", valid_402656933
  var valid_402656934 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656934 = validateParameter(valid_402656934, JString,
                                      required = false, default = nil)
  if valid_402656934 != nil:
    section.add "X-Amz-Security-Token", valid_402656934
  var valid_402656935 = header.getOrDefault("X-Amz-Signature")
  valid_402656935 = validateParameter(valid_402656935, JString,
                                      required = false, default = nil)
  if valid_402656935 != nil:
    section.add "X-Amz-Signature", valid_402656935
  var valid_402656936 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656936 = validateParameter(valid_402656936, JString,
                                      required = false, default = nil)
  if valid_402656936 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656936
  var valid_402656937 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656937 = validateParameter(valid_402656937, JString,
                                      required = false, default = nil)
  if valid_402656937 != nil:
    section.add "X-Amz-Algorithm", valid_402656937
  var valid_402656938 = header.getOrDefault("X-Amz-Date")
  valid_402656938 = validateParameter(valid_402656938, JString,
                                      required = false, default = nil)
  if valid_402656938 != nil:
    section.add "X-Amz-Date", valid_402656938
  var valid_402656939 = header.getOrDefault("X-Amz-Credential")
  valid_402656939 = validateParameter(valid_402656939, JString,
                                      required = false, default = nil)
  if valid_402656939 != nil:
    section.add "X-Amz-Credential", valid_402656939
  var valid_402656940 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656940 = validateParameter(valid_402656940, JString,
                                      required = false, default = nil)
  if valid_402656940 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656940
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656942: Call_ConfirmForgotPassword_402656930;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Allows a user to enter a confirmation code to reset a forgotten password.
                                                                                         ## 
  let valid = call_402656942.validator(path, query, header, formData, body, _)
  let scheme = call_402656942.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656942.makeUrl(scheme.get, call_402656942.host, call_402656942.base,
                                   call_402656942.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656942, uri, valid, _)

proc call*(call_402656943: Call_ConfirmForgotPassword_402656930; body: JsonNode): Recallable =
  ## confirmForgotPassword
  ## Allows a user to enter a confirmation code to reset a forgotten password.
  ##   
                                                                              ## body: JObject (required)
  var body_402656944 = newJObject()
  if body != nil:
    body_402656944 = body
  result = call_402656943.call(nil, nil, nil, nil, body_402656944)

var confirmForgotPassword* = Call_ConfirmForgotPassword_402656930(
    name: "confirmForgotPassword", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ConfirmForgotPassword",
    validator: validate_ConfirmForgotPassword_402656931, base: "/",
    makeUrl: url_ConfirmForgotPassword_402656932,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmSignUp_402656945 = ref object of OpenApiRestCall_402656044
proc url_ConfirmSignUp_402656947(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ConfirmSignUp_402656946(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656948 = header.getOrDefault("X-Amz-Target")
  valid_402656948 = validateParameter(valid_402656948, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ConfirmSignUp"))
  if valid_402656948 != nil:
    section.add "X-Amz-Target", valid_402656948
  var valid_402656949 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656949 = validateParameter(valid_402656949, JString,
                                      required = false, default = nil)
  if valid_402656949 != nil:
    section.add "X-Amz-Security-Token", valid_402656949
  var valid_402656950 = header.getOrDefault("X-Amz-Signature")
  valid_402656950 = validateParameter(valid_402656950, JString,
                                      required = false, default = nil)
  if valid_402656950 != nil:
    section.add "X-Amz-Signature", valid_402656950
  var valid_402656951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656951 = validateParameter(valid_402656951, JString,
                                      required = false, default = nil)
  if valid_402656951 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656951
  var valid_402656952 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656952 = validateParameter(valid_402656952, JString,
                                      required = false, default = nil)
  if valid_402656952 != nil:
    section.add "X-Amz-Algorithm", valid_402656952
  var valid_402656953 = header.getOrDefault("X-Amz-Date")
  valid_402656953 = validateParameter(valid_402656953, JString,
                                      required = false, default = nil)
  if valid_402656953 != nil:
    section.add "X-Amz-Date", valid_402656953
  var valid_402656954 = header.getOrDefault("X-Amz-Credential")
  valid_402656954 = validateParameter(valid_402656954, JString,
                                      required = false, default = nil)
  if valid_402656954 != nil:
    section.add "X-Amz-Credential", valid_402656954
  var valid_402656955 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656955 = validateParameter(valid_402656955, JString,
                                      required = false, default = nil)
  if valid_402656955 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656955
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656957: Call_ConfirmSignUp_402656945; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Confirms registration of a user and handles the existing alias from a previous user.
                                                                                         ## 
  let valid = call_402656957.validator(path, query, header, formData, body, _)
  let scheme = call_402656957.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656957.makeUrl(scheme.get, call_402656957.host, call_402656957.base,
                                   call_402656957.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656957, uri, valid, _)

proc call*(call_402656958: Call_ConfirmSignUp_402656945; body: JsonNode): Recallable =
  ## confirmSignUp
  ## Confirms registration of a user and handles the existing alias from a previous user.
  ##   
                                                                                         ## body: JObject (required)
  var body_402656959 = newJObject()
  if body != nil:
    body_402656959 = body
  result = call_402656958.call(nil, nil, nil, nil, body_402656959)

var confirmSignUp* = Call_ConfirmSignUp_402656945(name: "confirmSignUp",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ConfirmSignUp",
    validator: validate_ConfirmSignUp_402656946, base: "/",
    makeUrl: url_ConfirmSignUp_402656947, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_402656960 = ref object of OpenApiRestCall_402656044
proc url_CreateGroup_402656962(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateGroup_402656961(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656963 = header.getOrDefault("X-Amz-Target")
  valid_402656963 = validateParameter(valid_402656963, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateGroup"))
  if valid_402656963 != nil:
    section.add "X-Amz-Target", valid_402656963
  var valid_402656964 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656964 = validateParameter(valid_402656964, JString,
                                      required = false, default = nil)
  if valid_402656964 != nil:
    section.add "X-Amz-Security-Token", valid_402656964
  var valid_402656965 = header.getOrDefault("X-Amz-Signature")
  valid_402656965 = validateParameter(valid_402656965, JString,
                                      required = false, default = nil)
  if valid_402656965 != nil:
    section.add "X-Amz-Signature", valid_402656965
  var valid_402656966 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656966 = validateParameter(valid_402656966, JString,
                                      required = false, default = nil)
  if valid_402656966 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656966
  var valid_402656967 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656967 = validateParameter(valid_402656967, JString,
                                      required = false, default = nil)
  if valid_402656967 != nil:
    section.add "X-Amz-Algorithm", valid_402656967
  var valid_402656968 = header.getOrDefault("X-Amz-Date")
  valid_402656968 = validateParameter(valid_402656968, JString,
                                      required = false, default = nil)
  if valid_402656968 != nil:
    section.add "X-Amz-Date", valid_402656968
  var valid_402656969 = header.getOrDefault("X-Amz-Credential")
  valid_402656969 = validateParameter(valid_402656969, JString,
                                      required = false, default = nil)
  if valid_402656969 != nil:
    section.add "X-Amz-Credential", valid_402656969
  var valid_402656970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656970 = validateParameter(valid_402656970, JString,
                                      required = false, default = nil)
  if valid_402656970 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656970
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656972: Call_CreateGroup_402656960; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new group in the specified user pool.</p> <p>Calling this action requires developer credentials.</p>
                                                                                         ## 
  let valid = call_402656972.validator(path, query, header, formData, body, _)
  let scheme = call_402656972.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656972.makeUrl(scheme.get, call_402656972.host, call_402656972.base,
                                   call_402656972.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656972, uri, valid, _)

proc call*(call_402656973: Call_CreateGroup_402656960; body: JsonNode): Recallable =
  ## createGroup
  ## <p>Creates a new group in the specified user pool.</p> <p>Calling this action requires developer credentials.</p>
  ##   
                                                                                                                      ## body: JObject (required)
  var body_402656974 = newJObject()
  if body != nil:
    body_402656974 = body
  result = call_402656973.call(nil, nil, nil, nil, body_402656974)

var createGroup* = Call_CreateGroup_402656960(name: "createGroup",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateGroup",
    validator: validate_CreateGroup_402656961, base: "/",
    makeUrl: url_CreateGroup_402656962, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIdentityProvider_402656975 = ref object of OpenApiRestCall_402656044
proc url_CreateIdentityProvider_402656977(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateIdentityProvider_402656976(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656978 = header.getOrDefault("X-Amz-Target")
  valid_402656978 = validateParameter(valid_402656978, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateIdentityProvider"))
  if valid_402656978 != nil:
    section.add "X-Amz-Target", valid_402656978
  var valid_402656979 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656979 = validateParameter(valid_402656979, JString,
                                      required = false, default = nil)
  if valid_402656979 != nil:
    section.add "X-Amz-Security-Token", valid_402656979
  var valid_402656980 = header.getOrDefault("X-Amz-Signature")
  valid_402656980 = validateParameter(valid_402656980, JString,
                                      required = false, default = nil)
  if valid_402656980 != nil:
    section.add "X-Amz-Signature", valid_402656980
  var valid_402656981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656981 = validateParameter(valid_402656981, JString,
                                      required = false, default = nil)
  if valid_402656981 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656981
  var valid_402656982 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656982 = validateParameter(valid_402656982, JString,
                                      required = false, default = nil)
  if valid_402656982 != nil:
    section.add "X-Amz-Algorithm", valid_402656982
  var valid_402656983 = header.getOrDefault("X-Amz-Date")
  valid_402656983 = validateParameter(valid_402656983, JString,
                                      required = false, default = nil)
  if valid_402656983 != nil:
    section.add "X-Amz-Date", valid_402656983
  var valid_402656984 = header.getOrDefault("X-Amz-Credential")
  valid_402656984 = validateParameter(valid_402656984, JString,
                                      required = false, default = nil)
  if valid_402656984 != nil:
    section.add "X-Amz-Credential", valid_402656984
  var valid_402656985 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656985 = validateParameter(valid_402656985, JString,
                                      required = false, default = nil)
  if valid_402656985 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656985
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656987: Call_CreateIdentityProvider_402656975;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an identity provider for a user pool.
                                                                                         ## 
  let valid = call_402656987.validator(path, query, header, formData, body, _)
  let scheme = call_402656987.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656987.makeUrl(scheme.get, call_402656987.host, call_402656987.base,
                                   call_402656987.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656987, uri, valid, _)

proc call*(call_402656988: Call_CreateIdentityProvider_402656975; body: JsonNode): Recallable =
  ## createIdentityProvider
  ## Creates an identity provider for a user pool.
  ##   body: JObject (required)
  var body_402656989 = newJObject()
  if body != nil:
    body_402656989 = body
  result = call_402656988.call(nil, nil, nil, nil, body_402656989)

var createIdentityProvider* = Call_CreateIdentityProvider_402656975(
    name: "createIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateIdentityProvider",
    validator: validate_CreateIdentityProvider_402656976, base: "/",
    makeUrl: url_CreateIdentityProvider_402656977,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceServer_402656990 = ref object of OpenApiRestCall_402656044
proc url_CreateResourceServer_402656992(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateResourceServer_402656991(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656993 = header.getOrDefault("X-Amz-Target")
  valid_402656993 = validateParameter(valid_402656993, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateResourceServer"))
  if valid_402656993 != nil:
    section.add "X-Amz-Target", valid_402656993
  var valid_402656994 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656994 = validateParameter(valid_402656994, JString,
                                      required = false, default = nil)
  if valid_402656994 != nil:
    section.add "X-Amz-Security-Token", valid_402656994
  var valid_402656995 = header.getOrDefault("X-Amz-Signature")
  valid_402656995 = validateParameter(valid_402656995, JString,
                                      required = false, default = nil)
  if valid_402656995 != nil:
    section.add "X-Amz-Signature", valid_402656995
  var valid_402656996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656996 = validateParameter(valid_402656996, JString,
                                      required = false, default = nil)
  if valid_402656996 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656996
  var valid_402656997 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656997 = validateParameter(valid_402656997, JString,
                                      required = false, default = nil)
  if valid_402656997 != nil:
    section.add "X-Amz-Algorithm", valid_402656997
  var valid_402656998 = header.getOrDefault("X-Amz-Date")
  valid_402656998 = validateParameter(valid_402656998, JString,
                                      required = false, default = nil)
  if valid_402656998 != nil:
    section.add "X-Amz-Date", valid_402656998
  var valid_402656999 = header.getOrDefault("X-Amz-Credential")
  valid_402656999 = validateParameter(valid_402656999, JString,
                                      required = false, default = nil)
  if valid_402656999 != nil:
    section.add "X-Amz-Credential", valid_402656999
  var valid_402657000 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657000 = validateParameter(valid_402657000, JString,
                                      required = false, default = nil)
  if valid_402657000 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657000
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657002: Call_CreateResourceServer_402656990;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new OAuth2.0 resource server and defines custom scopes in it.
                                                                                         ## 
  let valid = call_402657002.validator(path, query, header, formData, body, _)
  let scheme = call_402657002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657002.makeUrl(scheme.get, call_402657002.host, call_402657002.base,
                                   call_402657002.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657002, uri, valid, _)

proc call*(call_402657003: Call_CreateResourceServer_402656990; body: JsonNode): Recallable =
  ## createResourceServer
  ## Creates a new OAuth2.0 resource server and defines custom scopes in it.
  ##   
                                                                            ## body: JObject (required)
  var body_402657004 = newJObject()
  if body != nil:
    body_402657004 = body
  result = call_402657003.call(nil, nil, nil, nil, body_402657004)

var createResourceServer* = Call_CreateResourceServer_402656990(
    name: "createResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateResourceServer",
    validator: validate_CreateResourceServer_402656991, base: "/",
    makeUrl: url_CreateResourceServer_402656992,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserImportJob_402657005 = ref object of OpenApiRestCall_402656044
proc url_CreateUserImportJob_402657007(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUserImportJob_402657006(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657008 = header.getOrDefault("X-Amz-Target")
  valid_402657008 = validateParameter(valid_402657008, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserImportJob"))
  if valid_402657008 != nil:
    section.add "X-Amz-Target", valid_402657008
  var valid_402657009 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657009 = validateParameter(valid_402657009, JString,
                                      required = false, default = nil)
  if valid_402657009 != nil:
    section.add "X-Amz-Security-Token", valid_402657009
  var valid_402657010 = header.getOrDefault("X-Amz-Signature")
  valid_402657010 = validateParameter(valid_402657010, JString,
                                      required = false, default = nil)
  if valid_402657010 != nil:
    section.add "X-Amz-Signature", valid_402657010
  var valid_402657011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657011 = validateParameter(valid_402657011, JString,
                                      required = false, default = nil)
  if valid_402657011 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657011
  var valid_402657012 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657012 = validateParameter(valid_402657012, JString,
                                      required = false, default = nil)
  if valid_402657012 != nil:
    section.add "X-Amz-Algorithm", valid_402657012
  var valid_402657013 = header.getOrDefault("X-Amz-Date")
  valid_402657013 = validateParameter(valid_402657013, JString,
                                      required = false, default = nil)
  if valid_402657013 != nil:
    section.add "X-Amz-Date", valid_402657013
  var valid_402657014 = header.getOrDefault("X-Amz-Credential")
  valid_402657014 = validateParameter(valid_402657014, JString,
                                      required = false, default = nil)
  if valid_402657014 != nil:
    section.add "X-Amz-Credential", valid_402657014
  var valid_402657015 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657015 = validateParameter(valid_402657015, JString,
                                      required = false, default = nil)
  if valid_402657015 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657015
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657017: Call_CreateUserImportJob_402657005;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates the user import job.
                                                                                         ## 
  let valid = call_402657017.validator(path, query, header, formData, body, _)
  let scheme = call_402657017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657017.makeUrl(scheme.get, call_402657017.host, call_402657017.base,
                                   call_402657017.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657017, uri, valid, _)

proc call*(call_402657018: Call_CreateUserImportJob_402657005; body: JsonNode): Recallable =
  ## createUserImportJob
  ## Creates the user import job.
  ##   body: JObject (required)
  var body_402657019 = newJObject()
  if body != nil:
    body_402657019 = body
  result = call_402657018.call(nil, nil, nil, nil, body_402657019)

var createUserImportJob* = Call_CreateUserImportJob_402657005(
    name: "createUserImportJob", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserImportJob",
    validator: validate_CreateUserImportJob_402657006, base: "/",
    makeUrl: url_CreateUserImportJob_402657007,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserPool_402657020 = ref object of OpenApiRestCall_402656044
proc url_CreateUserPool_402657022(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUserPool_402657021(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657023 = header.getOrDefault("X-Amz-Target")
  valid_402657023 = validateParameter(valid_402657023, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserPool"))
  if valid_402657023 != nil:
    section.add "X-Amz-Target", valid_402657023
  var valid_402657024 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657024 = validateParameter(valid_402657024, JString,
                                      required = false, default = nil)
  if valid_402657024 != nil:
    section.add "X-Amz-Security-Token", valid_402657024
  var valid_402657025 = header.getOrDefault("X-Amz-Signature")
  valid_402657025 = validateParameter(valid_402657025, JString,
                                      required = false, default = nil)
  if valid_402657025 != nil:
    section.add "X-Amz-Signature", valid_402657025
  var valid_402657026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657026 = validateParameter(valid_402657026, JString,
                                      required = false, default = nil)
  if valid_402657026 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657026
  var valid_402657027 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657027 = validateParameter(valid_402657027, JString,
                                      required = false, default = nil)
  if valid_402657027 != nil:
    section.add "X-Amz-Algorithm", valid_402657027
  var valid_402657028 = header.getOrDefault("X-Amz-Date")
  valid_402657028 = validateParameter(valid_402657028, JString,
                                      required = false, default = nil)
  if valid_402657028 != nil:
    section.add "X-Amz-Date", valid_402657028
  var valid_402657029 = header.getOrDefault("X-Amz-Credential")
  valid_402657029 = validateParameter(valid_402657029, JString,
                                      required = false, default = nil)
  if valid_402657029 != nil:
    section.add "X-Amz-Credential", valid_402657029
  var valid_402657030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657030 = validateParameter(valid_402657030, JString,
                                      required = false, default = nil)
  if valid_402657030 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657032: Call_CreateUserPool_402657020; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new Amazon Cognito user pool and sets the password policy for the pool.
                                                                                         ## 
  let valid = call_402657032.validator(path, query, header, formData, body, _)
  let scheme = call_402657032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657032.makeUrl(scheme.get, call_402657032.host, call_402657032.base,
                                   call_402657032.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657032, uri, valid, _)

proc call*(call_402657033: Call_CreateUserPool_402657020; body: JsonNode): Recallable =
  ## createUserPool
  ## Creates a new Amazon Cognito user pool and sets the password policy for the pool.
  ##   
                                                                                      ## body: JObject (required)
  var body_402657034 = newJObject()
  if body != nil:
    body_402657034 = body
  result = call_402657033.call(nil, nil, nil, nil, body_402657034)

var createUserPool* = Call_CreateUserPool_402657020(name: "createUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserPool",
    validator: validate_CreateUserPool_402657021, base: "/",
    makeUrl: url_CreateUserPool_402657022, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserPoolClient_402657035 = ref object of OpenApiRestCall_402656044
proc url_CreateUserPoolClient_402657037(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUserPoolClient_402657036(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657038 = header.getOrDefault("X-Amz-Target")
  valid_402657038 = validateParameter(valid_402657038, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserPoolClient"))
  if valid_402657038 != nil:
    section.add "X-Amz-Target", valid_402657038
  var valid_402657039 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657039 = validateParameter(valid_402657039, JString,
                                      required = false, default = nil)
  if valid_402657039 != nil:
    section.add "X-Amz-Security-Token", valid_402657039
  var valid_402657040 = header.getOrDefault("X-Amz-Signature")
  valid_402657040 = validateParameter(valid_402657040, JString,
                                      required = false, default = nil)
  if valid_402657040 != nil:
    section.add "X-Amz-Signature", valid_402657040
  var valid_402657041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657041 = validateParameter(valid_402657041, JString,
                                      required = false, default = nil)
  if valid_402657041 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657041
  var valid_402657042 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657042 = validateParameter(valid_402657042, JString,
                                      required = false, default = nil)
  if valid_402657042 != nil:
    section.add "X-Amz-Algorithm", valid_402657042
  var valid_402657043 = header.getOrDefault("X-Amz-Date")
  valid_402657043 = validateParameter(valid_402657043, JString,
                                      required = false, default = nil)
  if valid_402657043 != nil:
    section.add "X-Amz-Date", valid_402657043
  var valid_402657044 = header.getOrDefault("X-Amz-Credential")
  valid_402657044 = validateParameter(valid_402657044, JString,
                                      required = false, default = nil)
  if valid_402657044 != nil:
    section.add "X-Amz-Credential", valid_402657044
  var valid_402657045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657045 = validateParameter(valid_402657045, JString,
                                      required = false, default = nil)
  if valid_402657045 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657047: Call_CreateUserPoolClient_402657035;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates the user pool client.
                                                                                         ## 
  let valid = call_402657047.validator(path, query, header, formData, body, _)
  let scheme = call_402657047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657047.makeUrl(scheme.get, call_402657047.host, call_402657047.base,
                                   call_402657047.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657047, uri, valid, _)

proc call*(call_402657048: Call_CreateUserPoolClient_402657035; body: JsonNode): Recallable =
  ## createUserPoolClient
  ## Creates the user pool client.
  ##   body: JObject (required)
  var body_402657049 = newJObject()
  if body != nil:
    body_402657049 = body
  result = call_402657048.call(nil, nil, nil, nil, body_402657049)

var createUserPoolClient* = Call_CreateUserPoolClient_402657035(
    name: "createUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserPoolClient",
    validator: validate_CreateUserPoolClient_402657036, base: "/",
    makeUrl: url_CreateUserPoolClient_402657037,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserPoolDomain_402657050 = ref object of OpenApiRestCall_402656044
proc url_CreateUserPoolDomain_402657052(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUserPoolDomain_402657051(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657053 = header.getOrDefault("X-Amz-Target")
  valid_402657053 = validateParameter(valid_402657053, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserPoolDomain"))
  if valid_402657053 != nil:
    section.add "X-Amz-Target", valid_402657053
  var valid_402657054 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657054 = validateParameter(valid_402657054, JString,
                                      required = false, default = nil)
  if valid_402657054 != nil:
    section.add "X-Amz-Security-Token", valid_402657054
  var valid_402657055 = header.getOrDefault("X-Amz-Signature")
  valid_402657055 = validateParameter(valid_402657055, JString,
                                      required = false, default = nil)
  if valid_402657055 != nil:
    section.add "X-Amz-Signature", valid_402657055
  var valid_402657056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657056 = validateParameter(valid_402657056, JString,
                                      required = false, default = nil)
  if valid_402657056 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657056
  var valid_402657057 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657057 = validateParameter(valid_402657057, JString,
                                      required = false, default = nil)
  if valid_402657057 != nil:
    section.add "X-Amz-Algorithm", valid_402657057
  var valid_402657058 = header.getOrDefault("X-Amz-Date")
  valid_402657058 = validateParameter(valid_402657058, JString,
                                      required = false, default = nil)
  if valid_402657058 != nil:
    section.add "X-Amz-Date", valid_402657058
  var valid_402657059 = header.getOrDefault("X-Amz-Credential")
  valid_402657059 = validateParameter(valid_402657059, JString,
                                      required = false, default = nil)
  if valid_402657059 != nil:
    section.add "X-Amz-Credential", valid_402657059
  var valid_402657060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657060 = validateParameter(valid_402657060, JString,
                                      required = false, default = nil)
  if valid_402657060 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657062: Call_CreateUserPoolDomain_402657050;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new domain for a user pool.
                                                                                         ## 
  let valid = call_402657062.validator(path, query, header, formData, body, _)
  let scheme = call_402657062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657062.makeUrl(scheme.get, call_402657062.host, call_402657062.base,
                                   call_402657062.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657062, uri, valid, _)

proc call*(call_402657063: Call_CreateUserPoolDomain_402657050; body: JsonNode): Recallable =
  ## createUserPoolDomain
  ## Creates a new domain for a user pool.
  ##   body: JObject (required)
  var body_402657064 = newJObject()
  if body != nil:
    body_402657064 = body
  result = call_402657063.call(nil, nil, nil, nil, body_402657064)

var createUserPoolDomain* = Call_CreateUserPoolDomain_402657050(
    name: "createUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserPoolDomain",
    validator: validate_CreateUserPoolDomain_402657051, base: "/",
    makeUrl: url_CreateUserPoolDomain_402657052,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_402657065 = ref object of OpenApiRestCall_402656044
proc url_DeleteGroup_402657067(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteGroup_402657066(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657068 = header.getOrDefault("X-Amz-Target")
  valid_402657068 = validateParameter(valid_402657068, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteGroup"))
  if valid_402657068 != nil:
    section.add "X-Amz-Target", valid_402657068
  var valid_402657069 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657069 = validateParameter(valid_402657069, JString,
                                      required = false, default = nil)
  if valid_402657069 != nil:
    section.add "X-Amz-Security-Token", valid_402657069
  var valid_402657070 = header.getOrDefault("X-Amz-Signature")
  valid_402657070 = validateParameter(valid_402657070, JString,
                                      required = false, default = nil)
  if valid_402657070 != nil:
    section.add "X-Amz-Signature", valid_402657070
  var valid_402657071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657071 = validateParameter(valid_402657071, JString,
                                      required = false, default = nil)
  if valid_402657071 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657071
  var valid_402657072 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657072 = validateParameter(valid_402657072, JString,
                                      required = false, default = nil)
  if valid_402657072 != nil:
    section.add "X-Amz-Algorithm", valid_402657072
  var valid_402657073 = header.getOrDefault("X-Amz-Date")
  valid_402657073 = validateParameter(valid_402657073, JString,
                                      required = false, default = nil)
  if valid_402657073 != nil:
    section.add "X-Amz-Date", valid_402657073
  var valid_402657074 = header.getOrDefault("X-Amz-Credential")
  valid_402657074 = validateParameter(valid_402657074, JString,
                                      required = false, default = nil)
  if valid_402657074 != nil:
    section.add "X-Amz-Credential", valid_402657074
  var valid_402657075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657075 = validateParameter(valid_402657075, JString,
                                      required = false, default = nil)
  if valid_402657075 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657077: Call_DeleteGroup_402657065; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a group. Currently only groups with no members can be deleted.</p> <p>Calling this action requires developer credentials.</p>
                                                                                         ## 
  let valid = call_402657077.validator(path, query, header, formData, body, _)
  let scheme = call_402657077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657077.makeUrl(scheme.get, call_402657077.host, call_402657077.base,
                                   call_402657077.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657077, uri, valid, _)

proc call*(call_402657078: Call_DeleteGroup_402657065; body: JsonNode): Recallable =
  ## deleteGroup
  ## <p>Deletes a group. Currently only groups with no members can be deleted.</p> <p>Calling this action requires developer credentials.</p>
  ##   
                                                                                                                                             ## body: JObject (required)
  var body_402657079 = newJObject()
  if body != nil:
    body_402657079 = body
  result = call_402657078.call(nil, nil, nil, nil, body_402657079)

var deleteGroup* = Call_DeleteGroup_402657065(name: "deleteGroup",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteGroup",
    validator: validate_DeleteGroup_402657066, base: "/",
    makeUrl: url_DeleteGroup_402657067, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIdentityProvider_402657080 = ref object of OpenApiRestCall_402656044
proc url_DeleteIdentityProvider_402657082(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteIdentityProvider_402657081(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657083 = header.getOrDefault("X-Amz-Target")
  valid_402657083 = validateParameter(valid_402657083, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteIdentityProvider"))
  if valid_402657083 != nil:
    section.add "X-Amz-Target", valid_402657083
  var valid_402657084 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657084 = validateParameter(valid_402657084, JString,
                                      required = false, default = nil)
  if valid_402657084 != nil:
    section.add "X-Amz-Security-Token", valid_402657084
  var valid_402657085 = header.getOrDefault("X-Amz-Signature")
  valid_402657085 = validateParameter(valid_402657085, JString,
                                      required = false, default = nil)
  if valid_402657085 != nil:
    section.add "X-Amz-Signature", valid_402657085
  var valid_402657086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657086 = validateParameter(valid_402657086, JString,
                                      required = false, default = nil)
  if valid_402657086 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657086
  var valid_402657087 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657087 = validateParameter(valid_402657087, JString,
                                      required = false, default = nil)
  if valid_402657087 != nil:
    section.add "X-Amz-Algorithm", valid_402657087
  var valid_402657088 = header.getOrDefault("X-Amz-Date")
  valid_402657088 = validateParameter(valid_402657088, JString,
                                      required = false, default = nil)
  if valid_402657088 != nil:
    section.add "X-Amz-Date", valid_402657088
  var valid_402657089 = header.getOrDefault("X-Amz-Credential")
  valid_402657089 = validateParameter(valid_402657089, JString,
                                      required = false, default = nil)
  if valid_402657089 != nil:
    section.add "X-Amz-Credential", valid_402657089
  var valid_402657090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657090 = validateParameter(valid_402657090, JString,
                                      required = false, default = nil)
  if valid_402657090 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657090
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657092: Call_DeleteIdentityProvider_402657080;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an identity provider for a user pool.
                                                                                         ## 
  let valid = call_402657092.validator(path, query, header, formData, body, _)
  let scheme = call_402657092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657092.makeUrl(scheme.get, call_402657092.host, call_402657092.base,
                                   call_402657092.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657092, uri, valid, _)

proc call*(call_402657093: Call_DeleteIdentityProvider_402657080; body: JsonNode): Recallable =
  ## deleteIdentityProvider
  ## Deletes an identity provider for a user pool.
  ##   body: JObject (required)
  var body_402657094 = newJObject()
  if body != nil:
    body_402657094 = body
  result = call_402657093.call(nil, nil, nil, nil, body_402657094)

var deleteIdentityProvider* = Call_DeleteIdentityProvider_402657080(
    name: "deleteIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteIdentityProvider",
    validator: validate_DeleteIdentityProvider_402657081, base: "/",
    makeUrl: url_DeleteIdentityProvider_402657082,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceServer_402657095 = ref object of OpenApiRestCall_402656044
proc url_DeleteResourceServer_402657097(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteResourceServer_402657096(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657098 = header.getOrDefault("X-Amz-Target")
  valid_402657098 = validateParameter(valid_402657098, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteResourceServer"))
  if valid_402657098 != nil:
    section.add "X-Amz-Target", valid_402657098
  var valid_402657099 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657099 = validateParameter(valid_402657099, JString,
                                      required = false, default = nil)
  if valid_402657099 != nil:
    section.add "X-Amz-Security-Token", valid_402657099
  var valid_402657100 = header.getOrDefault("X-Amz-Signature")
  valid_402657100 = validateParameter(valid_402657100, JString,
                                      required = false, default = nil)
  if valid_402657100 != nil:
    section.add "X-Amz-Signature", valid_402657100
  var valid_402657101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657101 = validateParameter(valid_402657101, JString,
                                      required = false, default = nil)
  if valid_402657101 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657101
  var valid_402657102 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657102 = validateParameter(valid_402657102, JString,
                                      required = false, default = nil)
  if valid_402657102 != nil:
    section.add "X-Amz-Algorithm", valid_402657102
  var valid_402657103 = header.getOrDefault("X-Amz-Date")
  valid_402657103 = validateParameter(valid_402657103, JString,
                                      required = false, default = nil)
  if valid_402657103 != nil:
    section.add "X-Amz-Date", valid_402657103
  var valid_402657104 = header.getOrDefault("X-Amz-Credential")
  valid_402657104 = validateParameter(valid_402657104, JString,
                                      required = false, default = nil)
  if valid_402657104 != nil:
    section.add "X-Amz-Credential", valid_402657104
  var valid_402657105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657105 = validateParameter(valid_402657105, JString,
                                      required = false, default = nil)
  if valid_402657105 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657107: Call_DeleteResourceServer_402657095;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a resource server.
                                                                                         ## 
  let valid = call_402657107.validator(path, query, header, formData, body, _)
  let scheme = call_402657107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657107.makeUrl(scheme.get, call_402657107.host, call_402657107.base,
                                   call_402657107.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657107, uri, valid, _)

proc call*(call_402657108: Call_DeleteResourceServer_402657095; body: JsonNode): Recallable =
  ## deleteResourceServer
  ## Deletes a resource server.
  ##   body: JObject (required)
  var body_402657109 = newJObject()
  if body != nil:
    body_402657109 = body
  result = call_402657108.call(nil, nil, nil, nil, body_402657109)

var deleteResourceServer* = Call_DeleteResourceServer_402657095(
    name: "deleteResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteResourceServer",
    validator: validate_DeleteResourceServer_402657096, base: "/",
    makeUrl: url_DeleteResourceServer_402657097,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_402657110 = ref object of OpenApiRestCall_402656044
proc url_DeleteUser_402657112(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUser_402657111(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657113 = header.getOrDefault("X-Amz-Target")
  valid_402657113 = validateParameter(valid_402657113, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUser"))
  if valid_402657113 != nil:
    section.add "X-Amz-Target", valid_402657113
  var valid_402657114 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657114 = validateParameter(valid_402657114, JString,
                                      required = false, default = nil)
  if valid_402657114 != nil:
    section.add "X-Amz-Security-Token", valid_402657114
  var valid_402657115 = header.getOrDefault("X-Amz-Signature")
  valid_402657115 = validateParameter(valid_402657115, JString,
                                      required = false, default = nil)
  if valid_402657115 != nil:
    section.add "X-Amz-Signature", valid_402657115
  var valid_402657116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657116 = validateParameter(valid_402657116, JString,
                                      required = false, default = nil)
  if valid_402657116 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657116
  var valid_402657117 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657117 = validateParameter(valid_402657117, JString,
                                      required = false, default = nil)
  if valid_402657117 != nil:
    section.add "X-Amz-Algorithm", valid_402657117
  var valid_402657118 = header.getOrDefault("X-Amz-Date")
  valid_402657118 = validateParameter(valid_402657118, JString,
                                      required = false, default = nil)
  if valid_402657118 != nil:
    section.add "X-Amz-Date", valid_402657118
  var valid_402657119 = header.getOrDefault("X-Amz-Credential")
  valid_402657119 = validateParameter(valid_402657119, JString,
                                      required = false, default = nil)
  if valid_402657119 != nil:
    section.add "X-Amz-Credential", valid_402657119
  var valid_402657120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657120 = validateParameter(valid_402657120, JString,
                                      required = false, default = nil)
  if valid_402657120 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657122: Call_DeleteUser_402657110; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Allows a user to delete himself or herself.
                                                                                         ## 
  let valid = call_402657122.validator(path, query, header, formData, body, _)
  let scheme = call_402657122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657122.makeUrl(scheme.get, call_402657122.host, call_402657122.base,
                                   call_402657122.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657122, uri, valid, _)

proc call*(call_402657123: Call_DeleteUser_402657110; body: JsonNode): Recallable =
  ## deleteUser
  ## Allows a user to delete himself or herself.
  ##   body: JObject (required)
  var body_402657124 = newJObject()
  if body != nil:
    body_402657124 = body
  result = call_402657123.call(nil, nil, nil, nil, body_402657124)

var deleteUser* = Call_DeleteUser_402657110(name: "deleteUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUser",
    validator: validate_DeleteUser_402657111, base: "/",
    makeUrl: url_DeleteUser_402657112, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserAttributes_402657125 = ref object of OpenApiRestCall_402656044
proc url_DeleteUserAttributes_402657127(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUserAttributes_402657126(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657128 = header.getOrDefault("X-Amz-Target")
  valid_402657128 = validateParameter(valid_402657128, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUserAttributes"))
  if valid_402657128 != nil:
    section.add "X-Amz-Target", valid_402657128
  var valid_402657129 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657129 = validateParameter(valid_402657129, JString,
                                      required = false, default = nil)
  if valid_402657129 != nil:
    section.add "X-Amz-Security-Token", valid_402657129
  var valid_402657130 = header.getOrDefault("X-Amz-Signature")
  valid_402657130 = validateParameter(valid_402657130, JString,
                                      required = false, default = nil)
  if valid_402657130 != nil:
    section.add "X-Amz-Signature", valid_402657130
  var valid_402657131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657131 = validateParameter(valid_402657131, JString,
                                      required = false, default = nil)
  if valid_402657131 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657131
  var valid_402657132 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657132 = validateParameter(valid_402657132, JString,
                                      required = false, default = nil)
  if valid_402657132 != nil:
    section.add "X-Amz-Algorithm", valid_402657132
  var valid_402657133 = header.getOrDefault("X-Amz-Date")
  valid_402657133 = validateParameter(valid_402657133, JString,
                                      required = false, default = nil)
  if valid_402657133 != nil:
    section.add "X-Amz-Date", valid_402657133
  var valid_402657134 = header.getOrDefault("X-Amz-Credential")
  valid_402657134 = validateParameter(valid_402657134, JString,
                                      required = false, default = nil)
  if valid_402657134 != nil:
    section.add "X-Amz-Credential", valid_402657134
  var valid_402657135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657135 = validateParameter(valid_402657135, JString,
                                      required = false, default = nil)
  if valid_402657135 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657137: Call_DeleteUserAttributes_402657125;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the attributes for a user.
                                                                                         ## 
  let valid = call_402657137.validator(path, query, header, formData, body, _)
  let scheme = call_402657137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657137.makeUrl(scheme.get, call_402657137.host, call_402657137.base,
                                   call_402657137.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657137, uri, valid, _)

proc call*(call_402657138: Call_DeleteUserAttributes_402657125; body: JsonNode): Recallable =
  ## deleteUserAttributes
  ## Deletes the attributes for a user.
  ##   body: JObject (required)
  var body_402657139 = newJObject()
  if body != nil:
    body_402657139 = body
  result = call_402657138.call(nil, nil, nil, nil, body_402657139)

var deleteUserAttributes* = Call_DeleteUserAttributes_402657125(
    name: "deleteUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserAttributes",
    validator: validate_DeleteUserAttributes_402657126, base: "/",
    makeUrl: url_DeleteUserAttributes_402657127,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserPool_402657140 = ref object of OpenApiRestCall_402656044
proc url_DeleteUserPool_402657142(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUserPool_402657141(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657143 = header.getOrDefault("X-Amz-Target")
  valid_402657143 = validateParameter(valid_402657143, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUserPool"))
  if valid_402657143 != nil:
    section.add "X-Amz-Target", valid_402657143
  var valid_402657144 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657144 = validateParameter(valid_402657144, JString,
                                      required = false, default = nil)
  if valid_402657144 != nil:
    section.add "X-Amz-Security-Token", valid_402657144
  var valid_402657145 = header.getOrDefault("X-Amz-Signature")
  valid_402657145 = validateParameter(valid_402657145, JString,
                                      required = false, default = nil)
  if valid_402657145 != nil:
    section.add "X-Amz-Signature", valid_402657145
  var valid_402657146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657146 = validateParameter(valid_402657146, JString,
                                      required = false, default = nil)
  if valid_402657146 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657146
  var valid_402657147 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657147 = validateParameter(valid_402657147, JString,
                                      required = false, default = nil)
  if valid_402657147 != nil:
    section.add "X-Amz-Algorithm", valid_402657147
  var valid_402657148 = header.getOrDefault("X-Amz-Date")
  valid_402657148 = validateParameter(valid_402657148, JString,
                                      required = false, default = nil)
  if valid_402657148 != nil:
    section.add "X-Amz-Date", valid_402657148
  var valid_402657149 = header.getOrDefault("X-Amz-Credential")
  valid_402657149 = validateParameter(valid_402657149, JString,
                                      required = false, default = nil)
  if valid_402657149 != nil:
    section.add "X-Amz-Credential", valid_402657149
  var valid_402657150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657150 = validateParameter(valid_402657150, JString,
                                      required = false, default = nil)
  if valid_402657150 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657152: Call_DeleteUserPool_402657140; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified Amazon Cognito user pool.
                                                                                         ## 
  let valid = call_402657152.validator(path, query, header, formData, body, _)
  let scheme = call_402657152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657152.makeUrl(scheme.get, call_402657152.host, call_402657152.base,
                                   call_402657152.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657152, uri, valid, _)

proc call*(call_402657153: Call_DeleteUserPool_402657140; body: JsonNode): Recallable =
  ## deleteUserPool
  ## Deletes the specified Amazon Cognito user pool.
  ##   body: JObject (required)
  var body_402657154 = newJObject()
  if body != nil:
    body_402657154 = body
  result = call_402657153.call(nil, nil, nil, nil, body_402657154)

var deleteUserPool* = Call_DeleteUserPool_402657140(name: "deleteUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserPool",
    validator: validate_DeleteUserPool_402657141, base: "/",
    makeUrl: url_DeleteUserPool_402657142, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserPoolClient_402657155 = ref object of OpenApiRestCall_402656044
proc url_DeleteUserPoolClient_402657157(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUserPoolClient_402657156(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657158 = header.getOrDefault("X-Amz-Target")
  valid_402657158 = validateParameter(valid_402657158, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUserPoolClient"))
  if valid_402657158 != nil:
    section.add "X-Amz-Target", valid_402657158
  var valid_402657159 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657159 = validateParameter(valid_402657159, JString,
                                      required = false, default = nil)
  if valid_402657159 != nil:
    section.add "X-Amz-Security-Token", valid_402657159
  var valid_402657160 = header.getOrDefault("X-Amz-Signature")
  valid_402657160 = validateParameter(valid_402657160, JString,
                                      required = false, default = nil)
  if valid_402657160 != nil:
    section.add "X-Amz-Signature", valid_402657160
  var valid_402657161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657161 = validateParameter(valid_402657161, JString,
                                      required = false, default = nil)
  if valid_402657161 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657161
  var valid_402657162 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657162 = validateParameter(valid_402657162, JString,
                                      required = false, default = nil)
  if valid_402657162 != nil:
    section.add "X-Amz-Algorithm", valid_402657162
  var valid_402657163 = header.getOrDefault("X-Amz-Date")
  valid_402657163 = validateParameter(valid_402657163, JString,
                                      required = false, default = nil)
  if valid_402657163 != nil:
    section.add "X-Amz-Date", valid_402657163
  var valid_402657164 = header.getOrDefault("X-Amz-Credential")
  valid_402657164 = validateParameter(valid_402657164, JString,
                                      required = false, default = nil)
  if valid_402657164 != nil:
    section.add "X-Amz-Credential", valid_402657164
  var valid_402657165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657165 = validateParameter(valid_402657165, JString,
                                      required = false, default = nil)
  if valid_402657165 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657167: Call_DeleteUserPoolClient_402657155;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Allows the developer to delete the user pool client.
                                                                                         ## 
  let valid = call_402657167.validator(path, query, header, formData, body, _)
  let scheme = call_402657167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657167.makeUrl(scheme.get, call_402657167.host, call_402657167.base,
                                   call_402657167.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657167, uri, valid, _)

proc call*(call_402657168: Call_DeleteUserPoolClient_402657155; body: JsonNode): Recallable =
  ## deleteUserPoolClient
  ## Allows the developer to delete the user pool client.
  ##   body: JObject (required)
  var body_402657169 = newJObject()
  if body != nil:
    body_402657169 = body
  result = call_402657168.call(nil, nil, nil, nil, body_402657169)

var deleteUserPoolClient* = Call_DeleteUserPoolClient_402657155(
    name: "deleteUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserPoolClient",
    validator: validate_DeleteUserPoolClient_402657156, base: "/",
    makeUrl: url_DeleteUserPoolClient_402657157,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserPoolDomain_402657170 = ref object of OpenApiRestCall_402656044
proc url_DeleteUserPoolDomain_402657172(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUserPoolDomain_402657171(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657173 = header.getOrDefault("X-Amz-Target")
  valid_402657173 = validateParameter(valid_402657173, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUserPoolDomain"))
  if valid_402657173 != nil:
    section.add "X-Amz-Target", valid_402657173
  var valid_402657174 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657174 = validateParameter(valid_402657174, JString,
                                      required = false, default = nil)
  if valid_402657174 != nil:
    section.add "X-Amz-Security-Token", valid_402657174
  var valid_402657175 = header.getOrDefault("X-Amz-Signature")
  valid_402657175 = validateParameter(valid_402657175, JString,
                                      required = false, default = nil)
  if valid_402657175 != nil:
    section.add "X-Amz-Signature", valid_402657175
  var valid_402657176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657176 = validateParameter(valid_402657176, JString,
                                      required = false, default = nil)
  if valid_402657176 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657176
  var valid_402657177 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657177 = validateParameter(valid_402657177, JString,
                                      required = false, default = nil)
  if valid_402657177 != nil:
    section.add "X-Amz-Algorithm", valid_402657177
  var valid_402657178 = header.getOrDefault("X-Amz-Date")
  valid_402657178 = validateParameter(valid_402657178, JString,
                                      required = false, default = nil)
  if valid_402657178 != nil:
    section.add "X-Amz-Date", valid_402657178
  var valid_402657179 = header.getOrDefault("X-Amz-Credential")
  valid_402657179 = validateParameter(valid_402657179, JString,
                                      required = false, default = nil)
  if valid_402657179 != nil:
    section.add "X-Amz-Credential", valid_402657179
  var valid_402657180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657180 = validateParameter(valid_402657180, JString,
                                      required = false, default = nil)
  if valid_402657180 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657182: Call_DeleteUserPoolDomain_402657170;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a domain for a user pool.
                                                                                         ## 
  let valid = call_402657182.validator(path, query, header, formData, body, _)
  let scheme = call_402657182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657182.makeUrl(scheme.get, call_402657182.host, call_402657182.base,
                                   call_402657182.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657182, uri, valid, _)

proc call*(call_402657183: Call_DeleteUserPoolDomain_402657170; body: JsonNode): Recallable =
  ## deleteUserPoolDomain
  ## Deletes a domain for a user pool.
  ##   body: JObject (required)
  var body_402657184 = newJObject()
  if body != nil:
    body_402657184 = body
  result = call_402657183.call(nil, nil, nil, nil, body_402657184)

var deleteUserPoolDomain* = Call_DeleteUserPoolDomain_402657170(
    name: "deleteUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserPoolDomain",
    validator: validate_DeleteUserPoolDomain_402657171, base: "/",
    makeUrl: url_DeleteUserPoolDomain_402657172,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentityProvider_402657185 = ref object of OpenApiRestCall_402656044
proc url_DescribeIdentityProvider_402657187(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeIdentityProvider_402657186(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657188 = header.getOrDefault("X-Amz-Target")
  valid_402657188 = validateParameter(valid_402657188, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeIdentityProvider"))
  if valid_402657188 != nil:
    section.add "X-Amz-Target", valid_402657188
  var valid_402657189 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657189 = validateParameter(valid_402657189, JString,
                                      required = false, default = nil)
  if valid_402657189 != nil:
    section.add "X-Amz-Security-Token", valid_402657189
  var valid_402657190 = header.getOrDefault("X-Amz-Signature")
  valid_402657190 = validateParameter(valid_402657190, JString,
                                      required = false, default = nil)
  if valid_402657190 != nil:
    section.add "X-Amz-Signature", valid_402657190
  var valid_402657191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657191 = validateParameter(valid_402657191, JString,
                                      required = false, default = nil)
  if valid_402657191 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657191
  var valid_402657192 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657192 = validateParameter(valid_402657192, JString,
                                      required = false, default = nil)
  if valid_402657192 != nil:
    section.add "X-Amz-Algorithm", valid_402657192
  var valid_402657193 = header.getOrDefault("X-Amz-Date")
  valid_402657193 = validateParameter(valid_402657193, JString,
                                      required = false, default = nil)
  if valid_402657193 != nil:
    section.add "X-Amz-Date", valid_402657193
  var valid_402657194 = header.getOrDefault("X-Amz-Credential")
  valid_402657194 = validateParameter(valid_402657194, JString,
                                      required = false, default = nil)
  if valid_402657194 != nil:
    section.add "X-Amz-Credential", valid_402657194
  var valid_402657195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657195 = validateParameter(valid_402657195, JString,
                                      required = false, default = nil)
  if valid_402657195 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657195
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657197: Call_DescribeIdentityProvider_402657185;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a specific identity provider.
                                                                                         ## 
  let valid = call_402657197.validator(path, query, header, formData, body, _)
  let scheme = call_402657197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657197.makeUrl(scheme.get, call_402657197.host, call_402657197.base,
                                   call_402657197.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657197, uri, valid, _)

proc call*(call_402657198: Call_DescribeIdentityProvider_402657185;
           body: JsonNode): Recallable =
  ## describeIdentityProvider
  ## Gets information about a specific identity provider.
  ##   body: JObject (required)
  var body_402657199 = newJObject()
  if body != nil:
    body_402657199 = body
  result = call_402657198.call(nil, nil, nil, nil, body_402657199)

var describeIdentityProvider* = Call_DescribeIdentityProvider_402657185(
    name: "describeIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeIdentityProvider",
    validator: validate_DescribeIdentityProvider_402657186, base: "/",
    makeUrl: url_DescribeIdentityProvider_402657187,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResourceServer_402657200 = ref object of OpenApiRestCall_402656044
proc url_DescribeResourceServer_402657202(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeResourceServer_402657201(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657203 = header.getOrDefault("X-Amz-Target")
  valid_402657203 = validateParameter(valid_402657203, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeResourceServer"))
  if valid_402657203 != nil:
    section.add "X-Amz-Target", valid_402657203
  var valid_402657204 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657204 = validateParameter(valid_402657204, JString,
                                      required = false, default = nil)
  if valid_402657204 != nil:
    section.add "X-Amz-Security-Token", valid_402657204
  var valid_402657205 = header.getOrDefault("X-Amz-Signature")
  valid_402657205 = validateParameter(valid_402657205, JString,
                                      required = false, default = nil)
  if valid_402657205 != nil:
    section.add "X-Amz-Signature", valid_402657205
  var valid_402657206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657206 = validateParameter(valid_402657206, JString,
                                      required = false, default = nil)
  if valid_402657206 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657206
  var valid_402657207 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657207 = validateParameter(valid_402657207, JString,
                                      required = false, default = nil)
  if valid_402657207 != nil:
    section.add "X-Amz-Algorithm", valid_402657207
  var valid_402657208 = header.getOrDefault("X-Amz-Date")
  valid_402657208 = validateParameter(valid_402657208, JString,
                                      required = false, default = nil)
  if valid_402657208 != nil:
    section.add "X-Amz-Date", valid_402657208
  var valid_402657209 = header.getOrDefault("X-Amz-Credential")
  valid_402657209 = validateParameter(valid_402657209, JString,
                                      required = false, default = nil)
  if valid_402657209 != nil:
    section.add "X-Amz-Credential", valid_402657209
  var valid_402657210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657210 = validateParameter(valid_402657210, JString,
                                      required = false, default = nil)
  if valid_402657210 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657210
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657212: Call_DescribeResourceServer_402657200;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes a resource server.
                                                                                         ## 
  let valid = call_402657212.validator(path, query, header, formData, body, _)
  let scheme = call_402657212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657212.makeUrl(scheme.get, call_402657212.host, call_402657212.base,
                                   call_402657212.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657212, uri, valid, _)

proc call*(call_402657213: Call_DescribeResourceServer_402657200; body: JsonNode): Recallable =
  ## describeResourceServer
  ## Describes a resource server.
  ##   body: JObject (required)
  var body_402657214 = newJObject()
  if body != nil:
    body_402657214 = body
  result = call_402657213.call(nil, nil, nil, nil, body_402657214)

var describeResourceServer* = Call_DescribeResourceServer_402657200(
    name: "describeResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeResourceServer",
    validator: validate_DescribeResourceServer_402657201, base: "/",
    makeUrl: url_DescribeResourceServer_402657202,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRiskConfiguration_402657215 = ref object of OpenApiRestCall_402656044
proc url_DescribeRiskConfiguration_402657217(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeRiskConfiguration_402657216(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657218 = header.getOrDefault("X-Amz-Target")
  valid_402657218 = validateParameter(valid_402657218, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeRiskConfiguration"))
  if valid_402657218 != nil:
    section.add "X-Amz-Target", valid_402657218
  var valid_402657219 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657219 = validateParameter(valid_402657219, JString,
                                      required = false, default = nil)
  if valid_402657219 != nil:
    section.add "X-Amz-Security-Token", valid_402657219
  var valid_402657220 = header.getOrDefault("X-Amz-Signature")
  valid_402657220 = validateParameter(valid_402657220, JString,
                                      required = false, default = nil)
  if valid_402657220 != nil:
    section.add "X-Amz-Signature", valid_402657220
  var valid_402657221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657221 = validateParameter(valid_402657221, JString,
                                      required = false, default = nil)
  if valid_402657221 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657221
  var valid_402657222 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657222 = validateParameter(valid_402657222, JString,
                                      required = false, default = nil)
  if valid_402657222 != nil:
    section.add "X-Amz-Algorithm", valid_402657222
  var valid_402657223 = header.getOrDefault("X-Amz-Date")
  valid_402657223 = validateParameter(valid_402657223, JString,
                                      required = false, default = nil)
  if valid_402657223 != nil:
    section.add "X-Amz-Date", valid_402657223
  var valid_402657224 = header.getOrDefault("X-Amz-Credential")
  valid_402657224 = validateParameter(valid_402657224, JString,
                                      required = false, default = nil)
  if valid_402657224 != nil:
    section.add "X-Amz-Credential", valid_402657224
  var valid_402657225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657225 = validateParameter(valid_402657225, JString,
                                      required = false, default = nil)
  if valid_402657225 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657227: Call_DescribeRiskConfiguration_402657215;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the risk configuration.
                                                                                         ## 
  let valid = call_402657227.validator(path, query, header, formData, body, _)
  let scheme = call_402657227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657227.makeUrl(scheme.get, call_402657227.host, call_402657227.base,
                                   call_402657227.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657227, uri, valid, _)

proc call*(call_402657228: Call_DescribeRiskConfiguration_402657215;
           body: JsonNode): Recallable =
  ## describeRiskConfiguration
  ## Describes the risk configuration.
  ##   body: JObject (required)
  var body_402657229 = newJObject()
  if body != nil:
    body_402657229 = body
  result = call_402657228.call(nil, nil, nil, nil, body_402657229)

var describeRiskConfiguration* = Call_DescribeRiskConfiguration_402657215(
    name: "describeRiskConfiguration", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeRiskConfiguration",
    validator: validate_DescribeRiskConfiguration_402657216, base: "/",
    makeUrl: url_DescribeRiskConfiguration_402657217,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserImportJob_402657230 = ref object of OpenApiRestCall_402656044
proc url_DescribeUserImportJob_402657232(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUserImportJob_402657231(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657233 = header.getOrDefault("X-Amz-Target")
  valid_402657233 = validateParameter(valid_402657233, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserImportJob"))
  if valid_402657233 != nil:
    section.add "X-Amz-Target", valid_402657233
  var valid_402657234 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657234 = validateParameter(valid_402657234, JString,
                                      required = false, default = nil)
  if valid_402657234 != nil:
    section.add "X-Amz-Security-Token", valid_402657234
  var valid_402657235 = header.getOrDefault("X-Amz-Signature")
  valid_402657235 = validateParameter(valid_402657235, JString,
                                      required = false, default = nil)
  if valid_402657235 != nil:
    section.add "X-Amz-Signature", valid_402657235
  var valid_402657236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657236 = validateParameter(valid_402657236, JString,
                                      required = false, default = nil)
  if valid_402657236 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657236
  var valid_402657237 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657237 = validateParameter(valid_402657237, JString,
                                      required = false, default = nil)
  if valid_402657237 != nil:
    section.add "X-Amz-Algorithm", valid_402657237
  var valid_402657238 = header.getOrDefault("X-Amz-Date")
  valid_402657238 = validateParameter(valid_402657238, JString,
                                      required = false, default = nil)
  if valid_402657238 != nil:
    section.add "X-Amz-Date", valid_402657238
  var valid_402657239 = header.getOrDefault("X-Amz-Credential")
  valid_402657239 = validateParameter(valid_402657239, JString,
                                      required = false, default = nil)
  if valid_402657239 != nil:
    section.add "X-Amz-Credential", valid_402657239
  var valid_402657240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657240 = validateParameter(valid_402657240, JString,
                                      required = false, default = nil)
  if valid_402657240 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657242: Call_DescribeUserImportJob_402657230;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the user import job.
                                                                                         ## 
  let valid = call_402657242.validator(path, query, header, formData, body, _)
  let scheme = call_402657242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657242.makeUrl(scheme.get, call_402657242.host, call_402657242.base,
                                   call_402657242.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657242, uri, valid, _)

proc call*(call_402657243: Call_DescribeUserImportJob_402657230; body: JsonNode): Recallable =
  ## describeUserImportJob
  ## Describes the user import job.
  ##   body: JObject (required)
  var body_402657244 = newJObject()
  if body != nil:
    body_402657244 = body
  result = call_402657243.call(nil, nil, nil, nil, body_402657244)

var describeUserImportJob* = Call_DescribeUserImportJob_402657230(
    name: "describeUserImportJob", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserImportJob",
    validator: validate_DescribeUserImportJob_402657231, base: "/",
    makeUrl: url_DescribeUserImportJob_402657232,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserPool_402657245 = ref object of OpenApiRestCall_402656044
proc url_DescribeUserPool_402657247(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUserPool_402657246(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657248 = header.getOrDefault("X-Amz-Target")
  valid_402657248 = validateParameter(valid_402657248, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserPool"))
  if valid_402657248 != nil:
    section.add "X-Amz-Target", valid_402657248
  var valid_402657249 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657249 = validateParameter(valid_402657249, JString,
                                      required = false, default = nil)
  if valid_402657249 != nil:
    section.add "X-Amz-Security-Token", valid_402657249
  var valid_402657250 = header.getOrDefault("X-Amz-Signature")
  valid_402657250 = validateParameter(valid_402657250, JString,
                                      required = false, default = nil)
  if valid_402657250 != nil:
    section.add "X-Amz-Signature", valid_402657250
  var valid_402657251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657251 = validateParameter(valid_402657251, JString,
                                      required = false, default = nil)
  if valid_402657251 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657251
  var valid_402657252 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657252 = validateParameter(valid_402657252, JString,
                                      required = false, default = nil)
  if valid_402657252 != nil:
    section.add "X-Amz-Algorithm", valid_402657252
  var valid_402657253 = header.getOrDefault("X-Amz-Date")
  valid_402657253 = validateParameter(valid_402657253, JString,
                                      required = false, default = nil)
  if valid_402657253 != nil:
    section.add "X-Amz-Date", valid_402657253
  var valid_402657254 = header.getOrDefault("X-Amz-Credential")
  valid_402657254 = validateParameter(valid_402657254, JString,
                                      required = false, default = nil)
  if valid_402657254 != nil:
    section.add "X-Amz-Credential", valid_402657254
  var valid_402657255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657255 = validateParameter(valid_402657255, JString,
                                      required = false, default = nil)
  if valid_402657255 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657255
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657257: Call_DescribeUserPool_402657245;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the configuration information and metadata of the specified user pool.
                                                                                         ## 
  let valid = call_402657257.validator(path, query, header, formData, body, _)
  let scheme = call_402657257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657257.makeUrl(scheme.get, call_402657257.host, call_402657257.base,
                                   call_402657257.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657257, uri, valid, _)

proc call*(call_402657258: Call_DescribeUserPool_402657245; body: JsonNode): Recallable =
  ## describeUserPool
  ## Returns the configuration information and metadata of the specified user pool.
  ##   
                                                                                   ## body: JObject (required)
  var body_402657259 = newJObject()
  if body != nil:
    body_402657259 = body
  result = call_402657258.call(nil, nil, nil, nil, body_402657259)

var describeUserPool* = Call_DescribeUserPool_402657245(
    name: "describeUserPool", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserPool",
    validator: validate_DescribeUserPool_402657246, base: "/",
    makeUrl: url_DescribeUserPool_402657247,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserPoolClient_402657260 = ref object of OpenApiRestCall_402656044
proc url_DescribeUserPoolClient_402657262(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUserPoolClient_402657261(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657263 = header.getOrDefault("X-Amz-Target")
  valid_402657263 = validateParameter(valid_402657263, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserPoolClient"))
  if valid_402657263 != nil:
    section.add "X-Amz-Target", valid_402657263
  var valid_402657264 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657264 = validateParameter(valid_402657264, JString,
                                      required = false, default = nil)
  if valid_402657264 != nil:
    section.add "X-Amz-Security-Token", valid_402657264
  var valid_402657265 = header.getOrDefault("X-Amz-Signature")
  valid_402657265 = validateParameter(valid_402657265, JString,
                                      required = false, default = nil)
  if valid_402657265 != nil:
    section.add "X-Amz-Signature", valid_402657265
  var valid_402657266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657266 = validateParameter(valid_402657266, JString,
                                      required = false, default = nil)
  if valid_402657266 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657266
  var valid_402657267 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657267 = validateParameter(valid_402657267, JString,
                                      required = false, default = nil)
  if valid_402657267 != nil:
    section.add "X-Amz-Algorithm", valid_402657267
  var valid_402657268 = header.getOrDefault("X-Amz-Date")
  valid_402657268 = validateParameter(valid_402657268, JString,
                                      required = false, default = nil)
  if valid_402657268 != nil:
    section.add "X-Amz-Date", valid_402657268
  var valid_402657269 = header.getOrDefault("X-Amz-Credential")
  valid_402657269 = validateParameter(valid_402657269, JString,
                                      required = false, default = nil)
  if valid_402657269 != nil:
    section.add "X-Amz-Credential", valid_402657269
  var valid_402657270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657270 = validateParameter(valid_402657270, JString,
                                      required = false, default = nil)
  if valid_402657270 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657272: Call_DescribeUserPoolClient_402657260;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Client method for returning the configuration information and metadata of the specified user pool app client.
                                                                                         ## 
  let valid = call_402657272.validator(path, query, header, formData, body, _)
  let scheme = call_402657272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657272.makeUrl(scheme.get, call_402657272.host, call_402657272.base,
                                   call_402657272.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657272, uri, valid, _)

proc call*(call_402657273: Call_DescribeUserPoolClient_402657260; body: JsonNode): Recallable =
  ## describeUserPoolClient
  ## Client method for returning the configuration information and metadata of the specified user pool app client.
  ##   
                                                                                                                  ## body: JObject (required)
  var body_402657274 = newJObject()
  if body != nil:
    body_402657274 = body
  result = call_402657273.call(nil, nil, nil, nil, body_402657274)

var describeUserPoolClient* = Call_DescribeUserPoolClient_402657260(
    name: "describeUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserPoolClient",
    validator: validate_DescribeUserPoolClient_402657261, base: "/",
    makeUrl: url_DescribeUserPoolClient_402657262,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserPoolDomain_402657275 = ref object of OpenApiRestCall_402656044
proc url_DescribeUserPoolDomain_402657277(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUserPoolDomain_402657276(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657278 = header.getOrDefault("X-Amz-Target")
  valid_402657278 = validateParameter(valid_402657278, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserPoolDomain"))
  if valid_402657278 != nil:
    section.add "X-Amz-Target", valid_402657278
  var valid_402657279 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657279 = validateParameter(valid_402657279, JString,
                                      required = false, default = nil)
  if valid_402657279 != nil:
    section.add "X-Amz-Security-Token", valid_402657279
  var valid_402657280 = header.getOrDefault("X-Amz-Signature")
  valid_402657280 = validateParameter(valid_402657280, JString,
                                      required = false, default = nil)
  if valid_402657280 != nil:
    section.add "X-Amz-Signature", valid_402657280
  var valid_402657281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657281 = validateParameter(valid_402657281, JString,
                                      required = false, default = nil)
  if valid_402657281 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657281
  var valid_402657282 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657282 = validateParameter(valid_402657282, JString,
                                      required = false, default = nil)
  if valid_402657282 != nil:
    section.add "X-Amz-Algorithm", valid_402657282
  var valid_402657283 = header.getOrDefault("X-Amz-Date")
  valid_402657283 = validateParameter(valid_402657283, JString,
                                      required = false, default = nil)
  if valid_402657283 != nil:
    section.add "X-Amz-Date", valid_402657283
  var valid_402657284 = header.getOrDefault("X-Amz-Credential")
  valid_402657284 = validateParameter(valid_402657284, JString,
                                      required = false, default = nil)
  if valid_402657284 != nil:
    section.add "X-Amz-Credential", valid_402657284
  var valid_402657285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657285 = validateParameter(valid_402657285, JString,
                                      required = false, default = nil)
  if valid_402657285 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657287: Call_DescribeUserPoolDomain_402657275;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a domain.
                                                                                         ## 
  let valid = call_402657287.validator(path, query, header, formData, body, _)
  let scheme = call_402657287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657287.makeUrl(scheme.get, call_402657287.host, call_402657287.base,
                                   call_402657287.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657287, uri, valid, _)

proc call*(call_402657288: Call_DescribeUserPoolDomain_402657275; body: JsonNode): Recallable =
  ## describeUserPoolDomain
  ## Gets information about a domain.
  ##   body: JObject (required)
  var body_402657289 = newJObject()
  if body != nil:
    body_402657289 = body
  result = call_402657288.call(nil, nil, nil, nil, body_402657289)

var describeUserPoolDomain* = Call_DescribeUserPoolDomain_402657275(
    name: "describeUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserPoolDomain",
    validator: validate_DescribeUserPoolDomain_402657276, base: "/",
    makeUrl: url_DescribeUserPoolDomain_402657277,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ForgetDevice_402657290 = ref object of OpenApiRestCall_402656044
proc url_ForgetDevice_402657292(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ForgetDevice_402657291(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657293 = header.getOrDefault("X-Amz-Target")
  valid_402657293 = validateParameter(valid_402657293, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ForgetDevice"))
  if valid_402657293 != nil:
    section.add "X-Amz-Target", valid_402657293
  var valid_402657294 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657294 = validateParameter(valid_402657294, JString,
                                      required = false, default = nil)
  if valid_402657294 != nil:
    section.add "X-Amz-Security-Token", valid_402657294
  var valid_402657295 = header.getOrDefault("X-Amz-Signature")
  valid_402657295 = validateParameter(valid_402657295, JString,
                                      required = false, default = nil)
  if valid_402657295 != nil:
    section.add "X-Amz-Signature", valid_402657295
  var valid_402657296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657296 = validateParameter(valid_402657296, JString,
                                      required = false, default = nil)
  if valid_402657296 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657296
  var valid_402657297 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657297 = validateParameter(valid_402657297, JString,
                                      required = false, default = nil)
  if valid_402657297 != nil:
    section.add "X-Amz-Algorithm", valid_402657297
  var valid_402657298 = header.getOrDefault("X-Amz-Date")
  valid_402657298 = validateParameter(valid_402657298, JString,
                                      required = false, default = nil)
  if valid_402657298 != nil:
    section.add "X-Amz-Date", valid_402657298
  var valid_402657299 = header.getOrDefault("X-Amz-Credential")
  valid_402657299 = validateParameter(valid_402657299, JString,
                                      required = false, default = nil)
  if valid_402657299 != nil:
    section.add "X-Amz-Credential", valid_402657299
  var valid_402657300 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657300 = validateParameter(valid_402657300, JString,
                                      required = false, default = nil)
  if valid_402657300 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657300
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657302: Call_ForgetDevice_402657290; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Forgets the specified device.
                                                                                         ## 
  let valid = call_402657302.validator(path, query, header, formData, body, _)
  let scheme = call_402657302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657302.makeUrl(scheme.get, call_402657302.host, call_402657302.base,
                                   call_402657302.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657302, uri, valid, _)

proc call*(call_402657303: Call_ForgetDevice_402657290; body: JsonNode): Recallable =
  ## forgetDevice
  ## Forgets the specified device.
  ##   body: JObject (required)
  var body_402657304 = newJObject()
  if body != nil:
    body_402657304 = body
  result = call_402657303.call(nil, nil, nil, nil, body_402657304)

var forgetDevice* = Call_ForgetDevice_402657290(name: "forgetDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ForgetDevice",
    validator: validate_ForgetDevice_402657291, base: "/",
    makeUrl: url_ForgetDevice_402657292, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ForgotPassword_402657305 = ref object of OpenApiRestCall_402656044
proc url_ForgotPassword_402657307(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ForgotPassword_402657306(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657308 = header.getOrDefault("X-Amz-Target")
  valid_402657308 = validateParameter(valid_402657308, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ForgotPassword"))
  if valid_402657308 != nil:
    section.add "X-Amz-Target", valid_402657308
  var valid_402657309 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657309 = validateParameter(valid_402657309, JString,
                                      required = false, default = nil)
  if valid_402657309 != nil:
    section.add "X-Amz-Security-Token", valid_402657309
  var valid_402657310 = header.getOrDefault("X-Amz-Signature")
  valid_402657310 = validateParameter(valid_402657310, JString,
                                      required = false, default = nil)
  if valid_402657310 != nil:
    section.add "X-Amz-Signature", valid_402657310
  var valid_402657311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657311 = validateParameter(valid_402657311, JString,
                                      required = false, default = nil)
  if valid_402657311 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657311
  var valid_402657312 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657312 = validateParameter(valid_402657312, JString,
                                      required = false, default = nil)
  if valid_402657312 != nil:
    section.add "X-Amz-Algorithm", valid_402657312
  var valid_402657313 = header.getOrDefault("X-Amz-Date")
  valid_402657313 = validateParameter(valid_402657313, JString,
                                      required = false, default = nil)
  if valid_402657313 != nil:
    section.add "X-Amz-Date", valid_402657313
  var valid_402657314 = header.getOrDefault("X-Amz-Credential")
  valid_402657314 = validateParameter(valid_402657314, JString,
                                      required = false, default = nil)
  if valid_402657314 != nil:
    section.add "X-Amz-Credential", valid_402657314
  var valid_402657315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657315 = validateParameter(valid_402657315, JString,
                                      required = false, default = nil)
  if valid_402657315 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657317: Call_ForgotPassword_402657305; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Calling this API causes a message to be sent to the end user with a confirmation code that is required to change the user's password. For the <code>Username</code> parameter, you can use the username or user alias. If a verified phone number exists for the user, the confirmation code is sent to the phone number. Otherwise, if a verified email exists, the confirmation code is sent to the email. If neither a verified phone number nor a verified email exists, <code>InvalidParameterException</code> is thrown. To use the confirmation code for resetting the password, call .
                                                                                         ## 
  let valid = call_402657317.validator(path, query, header, formData, body, _)
  let scheme = call_402657317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657317.makeUrl(scheme.get, call_402657317.host, call_402657317.base,
                                   call_402657317.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657317, uri, valid, _)

proc call*(call_402657318: Call_ForgotPassword_402657305; body: JsonNode): Recallable =
  ## forgotPassword
  ## Calling this API causes a message to be sent to the end user with a confirmation code that is required to change the user's password. For the <code>Username</code> parameter, you can use the username or user alias. If a verified phone number exists for the user, the confirmation code is sent to the phone number. Otherwise, if a verified email exists, the confirmation code is sent to the email. If neither a verified phone number nor a verified email exists, <code>InvalidParameterException</code> is thrown. To use the confirmation code for resetting the password, call .
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402657319 = newJObject()
  if body != nil:
    body_402657319 = body
  result = call_402657318.call(nil, nil, nil, nil, body_402657319)

var forgotPassword* = Call_ForgotPassword_402657305(name: "forgotPassword",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ForgotPassword",
    validator: validate_ForgotPassword_402657306, base: "/",
    makeUrl: url_ForgotPassword_402657307, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCSVHeader_402657320 = ref object of OpenApiRestCall_402656044
proc url_GetCSVHeader_402657322(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCSVHeader_402657321(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657323 = header.getOrDefault("X-Amz-Target")
  valid_402657323 = validateParameter(valid_402657323, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetCSVHeader"))
  if valid_402657323 != nil:
    section.add "X-Amz-Target", valid_402657323
  var valid_402657324 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657324 = validateParameter(valid_402657324, JString,
                                      required = false, default = nil)
  if valid_402657324 != nil:
    section.add "X-Amz-Security-Token", valid_402657324
  var valid_402657325 = header.getOrDefault("X-Amz-Signature")
  valid_402657325 = validateParameter(valid_402657325, JString,
                                      required = false, default = nil)
  if valid_402657325 != nil:
    section.add "X-Amz-Signature", valid_402657325
  var valid_402657326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657326 = validateParameter(valid_402657326, JString,
                                      required = false, default = nil)
  if valid_402657326 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657326
  var valid_402657327 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657327 = validateParameter(valid_402657327, JString,
                                      required = false, default = nil)
  if valid_402657327 != nil:
    section.add "X-Amz-Algorithm", valid_402657327
  var valid_402657328 = header.getOrDefault("X-Amz-Date")
  valid_402657328 = validateParameter(valid_402657328, JString,
                                      required = false, default = nil)
  if valid_402657328 != nil:
    section.add "X-Amz-Date", valid_402657328
  var valid_402657329 = header.getOrDefault("X-Amz-Credential")
  valid_402657329 = validateParameter(valid_402657329, JString,
                                      required = false, default = nil)
  if valid_402657329 != nil:
    section.add "X-Amz-Credential", valid_402657329
  var valid_402657330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657330 = validateParameter(valid_402657330, JString,
                                      required = false, default = nil)
  if valid_402657330 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657332: Call_GetCSVHeader_402657320; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the header information for the .csv file to be used as input for the user import job.
                                                                                         ## 
  let valid = call_402657332.validator(path, query, header, formData, body, _)
  let scheme = call_402657332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657332.makeUrl(scheme.get, call_402657332.host, call_402657332.base,
                                   call_402657332.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657332, uri, valid, _)

proc call*(call_402657333: Call_GetCSVHeader_402657320; body: JsonNode): Recallable =
  ## getCSVHeader
  ## Gets the header information for the .csv file to be used as input for the user import job.
  ##   
                                                                                               ## body: JObject (required)
  var body_402657334 = newJObject()
  if body != nil:
    body_402657334 = body
  result = call_402657333.call(nil, nil, nil, nil, body_402657334)

var getCSVHeader* = Call_GetCSVHeader_402657320(name: "getCSVHeader",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetCSVHeader",
    validator: validate_GetCSVHeader_402657321, base: "/",
    makeUrl: url_GetCSVHeader_402657322, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevice_402657335 = ref object of OpenApiRestCall_402656044
proc url_GetDevice_402657337(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevice_402657336(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657338 = header.getOrDefault("X-Amz-Target")
  valid_402657338 = validateParameter(valid_402657338, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetDevice"))
  if valid_402657338 != nil:
    section.add "X-Amz-Target", valid_402657338
  var valid_402657339 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657339 = validateParameter(valid_402657339, JString,
                                      required = false, default = nil)
  if valid_402657339 != nil:
    section.add "X-Amz-Security-Token", valid_402657339
  var valid_402657340 = header.getOrDefault("X-Amz-Signature")
  valid_402657340 = validateParameter(valid_402657340, JString,
                                      required = false, default = nil)
  if valid_402657340 != nil:
    section.add "X-Amz-Signature", valid_402657340
  var valid_402657341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657341 = validateParameter(valid_402657341, JString,
                                      required = false, default = nil)
  if valid_402657341 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657341
  var valid_402657342 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657342 = validateParameter(valid_402657342, JString,
                                      required = false, default = nil)
  if valid_402657342 != nil:
    section.add "X-Amz-Algorithm", valid_402657342
  var valid_402657343 = header.getOrDefault("X-Amz-Date")
  valid_402657343 = validateParameter(valid_402657343, JString,
                                      required = false, default = nil)
  if valid_402657343 != nil:
    section.add "X-Amz-Date", valid_402657343
  var valid_402657344 = header.getOrDefault("X-Amz-Credential")
  valid_402657344 = validateParameter(valid_402657344, JString,
                                      required = false, default = nil)
  if valid_402657344 != nil:
    section.add "X-Amz-Credential", valid_402657344
  var valid_402657345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657345 = validateParameter(valid_402657345, JString,
                                      required = false, default = nil)
  if valid_402657345 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657347: Call_GetDevice_402657335; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the device.
                                                                                         ## 
  let valid = call_402657347.validator(path, query, header, formData, body, _)
  let scheme = call_402657347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657347.makeUrl(scheme.get, call_402657347.host, call_402657347.base,
                                   call_402657347.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657347, uri, valid, _)

proc call*(call_402657348: Call_GetDevice_402657335; body: JsonNode): Recallable =
  ## getDevice
  ## Gets the device.
  ##   body: JObject (required)
  var body_402657349 = newJObject()
  if body != nil:
    body_402657349 = body
  result = call_402657348.call(nil, nil, nil, nil, body_402657349)

var getDevice* = Call_GetDevice_402657335(name: "getDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetDevice",
    validator: validate_GetDevice_402657336, base: "/", makeUrl: url_GetDevice_402657337,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroup_402657350 = ref object of OpenApiRestCall_402656044
proc url_GetGroup_402657352(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGroup_402657351(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657353 = header.getOrDefault("X-Amz-Target")
  valid_402657353 = validateParameter(valid_402657353, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetGroup"))
  if valid_402657353 != nil:
    section.add "X-Amz-Target", valid_402657353
  var valid_402657354 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657354 = validateParameter(valid_402657354, JString,
                                      required = false, default = nil)
  if valid_402657354 != nil:
    section.add "X-Amz-Security-Token", valid_402657354
  var valid_402657355 = header.getOrDefault("X-Amz-Signature")
  valid_402657355 = validateParameter(valid_402657355, JString,
                                      required = false, default = nil)
  if valid_402657355 != nil:
    section.add "X-Amz-Signature", valid_402657355
  var valid_402657356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657356 = validateParameter(valid_402657356, JString,
                                      required = false, default = nil)
  if valid_402657356 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657356
  var valid_402657357 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657357 = validateParameter(valid_402657357, JString,
                                      required = false, default = nil)
  if valid_402657357 != nil:
    section.add "X-Amz-Algorithm", valid_402657357
  var valid_402657358 = header.getOrDefault("X-Amz-Date")
  valid_402657358 = validateParameter(valid_402657358, JString,
                                      required = false, default = nil)
  if valid_402657358 != nil:
    section.add "X-Amz-Date", valid_402657358
  var valid_402657359 = header.getOrDefault("X-Amz-Credential")
  valid_402657359 = validateParameter(valid_402657359, JString,
                                      required = false, default = nil)
  if valid_402657359 != nil:
    section.add "X-Amz-Credential", valid_402657359
  var valid_402657360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657360 = validateParameter(valid_402657360, JString,
                                      required = false, default = nil)
  if valid_402657360 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657360
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657362: Call_GetGroup_402657350; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets a group.</p> <p>Calling this action requires developer credentials.</p>
                                                                                         ## 
  let valid = call_402657362.validator(path, query, header, formData, body, _)
  let scheme = call_402657362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657362.makeUrl(scheme.get, call_402657362.host, call_402657362.base,
                                   call_402657362.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657362, uri, valid, _)

proc call*(call_402657363: Call_GetGroup_402657350; body: JsonNode): Recallable =
  ## getGroup
  ## <p>Gets a group.</p> <p>Calling this action requires developer credentials.</p>
  ##   
                                                                                    ## body: JObject (required)
  var body_402657364 = newJObject()
  if body != nil:
    body_402657364 = body
  result = call_402657363.call(nil, nil, nil, nil, body_402657364)

var getGroup* = Call_GetGroup_402657350(name: "getGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetGroup",
                                        validator: validate_GetGroup_402657351,
                                        base: "/", makeUrl: url_GetGroup_402657352,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIdentityProviderByIdentifier_402657365 = ref object of OpenApiRestCall_402656044
proc url_GetIdentityProviderByIdentifier_402657367(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetIdentityProviderByIdentifier_402657366(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657368 = header.getOrDefault("X-Amz-Target")
  valid_402657368 = validateParameter(valid_402657368, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetIdentityProviderByIdentifier"))
  if valid_402657368 != nil:
    section.add "X-Amz-Target", valid_402657368
  var valid_402657369 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657369 = validateParameter(valid_402657369, JString,
                                      required = false, default = nil)
  if valid_402657369 != nil:
    section.add "X-Amz-Security-Token", valid_402657369
  var valid_402657370 = header.getOrDefault("X-Amz-Signature")
  valid_402657370 = validateParameter(valid_402657370, JString,
                                      required = false, default = nil)
  if valid_402657370 != nil:
    section.add "X-Amz-Signature", valid_402657370
  var valid_402657371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657371 = validateParameter(valid_402657371, JString,
                                      required = false, default = nil)
  if valid_402657371 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657371
  var valid_402657372 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657372 = validateParameter(valid_402657372, JString,
                                      required = false, default = nil)
  if valid_402657372 != nil:
    section.add "X-Amz-Algorithm", valid_402657372
  var valid_402657373 = header.getOrDefault("X-Amz-Date")
  valid_402657373 = validateParameter(valid_402657373, JString,
                                      required = false, default = nil)
  if valid_402657373 != nil:
    section.add "X-Amz-Date", valid_402657373
  var valid_402657374 = header.getOrDefault("X-Amz-Credential")
  valid_402657374 = validateParameter(valid_402657374, JString,
                                      required = false, default = nil)
  if valid_402657374 != nil:
    section.add "X-Amz-Credential", valid_402657374
  var valid_402657375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657375 = validateParameter(valid_402657375, JString,
                                      required = false, default = nil)
  if valid_402657375 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657375
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657377: Call_GetIdentityProviderByIdentifier_402657365;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the specified identity provider.
                                                                                         ## 
  let valid = call_402657377.validator(path, query, header, formData, body, _)
  let scheme = call_402657377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657377.makeUrl(scheme.get, call_402657377.host, call_402657377.base,
                                   call_402657377.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657377, uri, valid, _)

proc call*(call_402657378: Call_GetIdentityProviderByIdentifier_402657365;
           body: JsonNode): Recallable =
  ## getIdentityProviderByIdentifier
  ## Gets the specified identity provider.
  ##   body: JObject (required)
  var body_402657379 = newJObject()
  if body != nil:
    body_402657379 = body
  result = call_402657378.call(nil, nil, nil, nil, body_402657379)

var getIdentityProviderByIdentifier* = Call_GetIdentityProviderByIdentifier_402657365(
    name: "getIdentityProviderByIdentifier", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetIdentityProviderByIdentifier",
    validator: validate_GetIdentityProviderByIdentifier_402657366, base: "/",
    makeUrl: url_GetIdentityProviderByIdentifier_402657367,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSigningCertificate_402657380 = ref object of OpenApiRestCall_402656044
proc url_GetSigningCertificate_402657382(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSigningCertificate_402657381(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657383 = header.getOrDefault("X-Amz-Target")
  valid_402657383 = validateParameter(valid_402657383, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetSigningCertificate"))
  if valid_402657383 != nil:
    section.add "X-Amz-Target", valid_402657383
  var valid_402657384 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657384 = validateParameter(valid_402657384, JString,
                                      required = false, default = nil)
  if valid_402657384 != nil:
    section.add "X-Amz-Security-Token", valid_402657384
  var valid_402657385 = header.getOrDefault("X-Amz-Signature")
  valid_402657385 = validateParameter(valid_402657385, JString,
                                      required = false, default = nil)
  if valid_402657385 != nil:
    section.add "X-Amz-Signature", valid_402657385
  var valid_402657386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657386 = validateParameter(valid_402657386, JString,
                                      required = false, default = nil)
  if valid_402657386 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657386
  var valid_402657387 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657387 = validateParameter(valid_402657387, JString,
                                      required = false, default = nil)
  if valid_402657387 != nil:
    section.add "X-Amz-Algorithm", valid_402657387
  var valid_402657388 = header.getOrDefault("X-Amz-Date")
  valid_402657388 = validateParameter(valid_402657388, JString,
                                      required = false, default = nil)
  if valid_402657388 != nil:
    section.add "X-Amz-Date", valid_402657388
  var valid_402657389 = header.getOrDefault("X-Amz-Credential")
  valid_402657389 = validateParameter(valid_402657389, JString,
                                      required = false, default = nil)
  if valid_402657389 != nil:
    section.add "X-Amz-Credential", valid_402657389
  var valid_402657390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657390 = validateParameter(valid_402657390, JString,
                                      required = false, default = nil)
  if valid_402657390 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657392: Call_GetSigningCertificate_402657380;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This method takes a user pool ID, and returns the signing certificate.
                                                                                         ## 
  let valid = call_402657392.validator(path, query, header, formData, body, _)
  let scheme = call_402657392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657392.makeUrl(scheme.get, call_402657392.host, call_402657392.base,
                                   call_402657392.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657392, uri, valid, _)

proc call*(call_402657393: Call_GetSigningCertificate_402657380; body: JsonNode): Recallable =
  ## getSigningCertificate
  ## This method takes a user pool ID, and returns the signing certificate.
  ##   body: 
                                                                           ## JObject (required)
  var body_402657394 = newJObject()
  if body != nil:
    body_402657394 = body
  result = call_402657393.call(nil, nil, nil, nil, body_402657394)

var getSigningCertificate* = Call_GetSigningCertificate_402657380(
    name: "getSigningCertificate", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetSigningCertificate",
    validator: validate_GetSigningCertificate_402657381, base: "/",
    makeUrl: url_GetSigningCertificate_402657382,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUICustomization_402657395 = ref object of OpenApiRestCall_402656044
proc url_GetUICustomization_402657397(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUICustomization_402657396(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657398 = header.getOrDefault("X-Amz-Target")
  valid_402657398 = validateParameter(valid_402657398, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUICustomization"))
  if valid_402657398 != nil:
    section.add "X-Amz-Target", valid_402657398
  var valid_402657399 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657399 = validateParameter(valid_402657399, JString,
                                      required = false, default = nil)
  if valid_402657399 != nil:
    section.add "X-Amz-Security-Token", valid_402657399
  var valid_402657400 = header.getOrDefault("X-Amz-Signature")
  valid_402657400 = validateParameter(valid_402657400, JString,
                                      required = false, default = nil)
  if valid_402657400 != nil:
    section.add "X-Amz-Signature", valid_402657400
  var valid_402657401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657401 = validateParameter(valid_402657401, JString,
                                      required = false, default = nil)
  if valid_402657401 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657401
  var valid_402657402 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657402 = validateParameter(valid_402657402, JString,
                                      required = false, default = nil)
  if valid_402657402 != nil:
    section.add "X-Amz-Algorithm", valid_402657402
  var valid_402657403 = header.getOrDefault("X-Amz-Date")
  valid_402657403 = validateParameter(valid_402657403, JString,
                                      required = false, default = nil)
  if valid_402657403 != nil:
    section.add "X-Amz-Date", valid_402657403
  var valid_402657404 = header.getOrDefault("X-Amz-Credential")
  valid_402657404 = validateParameter(valid_402657404, JString,
                                      required = false, default = nil)
  if valid_402657404 != nil:
    section.add "X-Amz-Credential", valid_402657404
  var valid_402657405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657405 = validateParameter(valid_402657405, JString,
                                      required = false, default = nil)
  if valid_402657405 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657405
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657407: Call_GetUICustomization_402657395;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the UI Customization information for a particular app client's app UI, if there is something set. If nothing is set for the particular client, but there is an existing pool level customization (app <code>clientId</code> will be <code>ALL</code>), then that is returned. If nothing is present, then an empty shape is returned.
                                                                                         ## 
  let valid = call_402657407.validator(path, query, header, formData, body, _)
  let scheme = call_402657407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657407.makeUrl(scheme.get, call_402657407.host, call_402657407.base,
                                   call_402657407.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657407, uri, valid, _)

proc call*(call_402657408: Call_GetUICustomization_402657395; body: JsonNode): Recallable =
  ## getUICustomization
  ## Gets the UI Customization information for a particular app client's app UI, if there is something set. If nothing is set for the particular client, but there is an existing pool level customization (app <code>clientId</code> will be <code>ALL</code>), then that is returned. If nothing is present, then an empty shape is returned.
  ##   
                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402657409 = newJObject()
  if body != nil:
    body_402657409 = body
  result = call_402657408.call(nil, nil, nil, nil, body_402657409)

var getUICustomization* = Call_GetUICustomization_402657395(
    name: "getUICustomization", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUICustomization",
    validator: validate_GetUICustomization_402657396, base: "/",
    makeUrl: url_GetUICustomization_402657397,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUser_402657410 = ref object of OpenApiRestCall_402656044
proc url_GetUser_402657412(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUser_402657411(path: JsonNode; query: JsonNode;
                                header: JsonNode; formData: JsonNode;
                                body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657413 = header.getOrDefault("X-Amz-Target")
  valid_402657413 = validateParameter(valid_402657413, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUser"))
  if valid_402657413 != nil:
    section.add "X-Amz-Target", valid_402657413
  var valid_402657414 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657414 = validateParameter(valid_402657414, JString,
                                      required = false, default = nil)
  if valid_402657414 != nil:
    section.add "X-Amz-Security-Token", valid_402657414
  var valid_402657415 = header.getOrDefault("X-Amz-Signature")
  valid_402657415 = validateParameter(valid_402657415, JString,
                                      required = false, default = nil)
  if valid_402657415 != nil:
    section.add "X-Amz-Signature", valid_402657415
  var valid_402657416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657416 = validateParameter(valid_402657416, JString,
                                      required = false, default = nil)
  if valid_402657416 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657416
  var valid_402657417 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657417 = validateParameter(valid_402657417, JString,
                                      required = false, default = nil)
  if valid_402657417 != nil:
    section.add "X-Amz-Algorithm", valid_402657417
  var valid_402657418 = header.getOrDefault("X-Amz-Date")
  valid_402657418 = validateParameter(valid_402657418, JString,
                                      required = false, default = nil)
  if valid_402657418 != nil:
    section.add "X-Amz-Date", valid_402657418
  var valid_402657419 = header.getOrDefault("X-Amz-Credential")
  valid_402657419 = validateParameter(valid_402657419, JString,
                                      required = false, default = nil)
  if valid_402657419 != nil:
    section.add "X-Amz-Credential", valid_402657419
  var valid_402657420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657420 = validateParameter(valid_402657420, JString,
                                      required = false, default = nil)
  if valid_402657420 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657420
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657422: Call_GetUser_402657410; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the user attributes and metadata for a user.
                                                                                         ## 
  let valid = call_402657422.validator(path, query, header, formData, body, _)
  let scheme = call_402657422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657422.makeUrl(scheme.get, call_402657422.host, call_402657422.base,
                                   call_402657422.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657422, uri, valid, _)

proc call*(call_402657423: Call_GetUser_402657410; body: JsonNode): Recallable =
  ## getUser
  ## Gets the user attributes and metadata for a user.
  ##   body: JObject (required)
  var body_402657424 = newJObject()
  if body != nil:
    body_402657424 = body
  result = call_402657423.call(nil, nil, nil, nil, body_402657424)

var getUser* = Call_GetUser_402657410(name: "getUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUser",
                                      validator: validate_GetUser_402657411,
                                      base: "/", makeUrl: url_GetUser_402657412,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserAttributeVerificationCode_402657425 = ref object of OpenApiRestCall_402656044
proc url_GetUserAttributeVerificationCode_402657427(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUserAttributeVerificationCode_402657426(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657428 = header.getOrDefault("X-Amz-Target")
  valid_402657428 = validateParameter(valid_402657428, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUserAttributeVerificationCode"))
  if valid_402657428 != nil:
    section.add "X-Amz-Target", valid_402657428
  var valid_402657429 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657429 = validateParameter(valid_402657429, JString,
                                      required = false, default = nil)
  if valid_402657429 != nil:
    section.add "X-Amz-Security-Token", valid_402657429
  var valid_402657430 = header.getOrDefault("X-Amz-Signature")
  valid_402657430 = validateParameter(valid_402657430, JString,
                                      required = false, default = nil)
  if valid_402657430 != nil:
    section.add "X-Amz-Signature", valid_402657430
  var valid_402657431 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657431 = validateParameter(valid_402657431, JString,
                                      required = false, default = nil)
  if valid_402657431 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657431
  var valid_402657432 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657432 = validateParameter(valid_402657432, JString,
                                      required = false, default = nil)
  if valid_402657432 != nil:
    section.add "X-Amz-Algorithm", valid_402657432
  var valid_402657433 = header.getOrDefault("X-Amz-Date")
  valid_402657433 = validateParameter(valid_402657433, JString,
                                      required = false, default = nil)
  if valid_402657433 != nil:
    section.add "X-Amz-Date", valid_402657433
  var valid_402657434 = header.getOrDefault("X-Amz-Credential")
  valid_402657434 = validateParameter(valid_402657434, JString,
                                      required = false, default = nil)
  if valid_402657434 != nil:
    section.add "X-Amz-Credential", valid_402657434
  var valid_402657435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657435 = validateParameter(valid_402657435, JString,
                                      required = false, default = nil)
  if valid_402657435 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657435
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657437: Call_GetUserAttributeVerificationCode_402657425;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the user attribute verification code for the specified attribute name.
                                                                                         ## 
  let valid = call_402657437.validator(path, query, header, formData, body, _)
  let scheme = call_402657437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657437.makeUrl(scheme.get, call_402657437.host, call_402657437.base,
                                   call_402657437.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657437, uri, valid, _)

proc call*(call_402657438: Call_GetUserAttributeVerificationCode_402657425;
           body: JsonNode): Recallable =
  ## getUserAttributeVerificationCode
  ## Gets the user attribute verification code for the specified attribute name.
  ##   
                                                                                ## body: JObject (required)
  var body_402657439 = newJObject()
  if body != nil:
    body_402657439 = body
  result = call_402657438.call(nil, nil, nil, nil, body_402657439)

var getUserAttributeVerificationCode* = Call_GetUserAttributeVerificationCode_402657425(
    name: "getUserAttributeVerificationCode", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUserAttributeVerificationCode",
    validator: validate_GetUserAttributeVerificationCode_402657426, base: "/",
    makeUrl: url_GetUserAttributeVerificationCode_402657427,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserPoolMfaConfig_402657440 = ref object of OpenApiRestCall_402656044
proc url_GetUserPoolMfaConfig_402657442(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUserPoolMfaConfig_402657441(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657443 = header.getOrDefault("X-Amz-Target")
  valid_402657443 = validateParameter(valid_402657443, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUserPoolMfaConfig"))
  if valid_402657443 != nil:
    section.add "X-Amz-Target", valid_402657443
  var valid_402657444 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657444 = validateParameter(valid_402657444, JString,
                                      required = false, default = nil)
  if valid_402657444 != nil:
    section.add "X-Amz-Security-Token", valid_402657444
  var valid_402657445 = header.getOrDefault("X-Amz-Signature")
  valid_402657445 = validateParameter(valid_402657445, JString,
                                      required = false, default = nil)
  if valid_402657445 != nil:
    section.add "X-Amz-Signature", valid_402657445
  var valid_402657446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657446 = validateParameter(valid_402657446, JString,
                                      required = false, default = nil)
  if valid_402657446 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657446
  var valid_402657447 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657447 = validateParameter(valid_402657447, JString,
                                      required = false, default = nil)
  if valid_402657447 != nil:
    section.add "X-Amz-Algorithm", valid_402657447
  var valid_402657448 = header.getOrDefault("X-Amz-Date")
  valid_402657448 = validateParameter(valid_402657448, JString,
                                      required = false, default = nil)
  if valid_402657448 != nil:
    section.add "X-Amz-Date", valid_402657448
  var valid_402657449 = header.getOrDefault("X-Amz-Credential")
  valid_402657449 = validateParameter(valid_402657449, JString,
                                      required = false, default = nil)
  if valid_402657449 != nil:
    section.add "X-Amz-Credential", valid_402657449
  var valid_402657450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657450 = validateParameter(valid_402657450, JString,
                                      required = false, default = nil)
  if valid_402657450 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657452: Call_GetUserPoolMfaConfig_402657440;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the user pool multi-factor authentication (MFA) configuration.
                                                                                         ## 
  let valid = call_402657452.validator(path, query, header, formData, body, _)
  let scheme = call_402657452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657452.makeUrl(scheme.get, call_402657452.host, call_402657452.base,
                                   call_402657452.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657452, uri, valid, _)

proc call*(call_402657453: Call_GetUserPoolMfaConfig_402657440; body: JsonNode): Recallable =
  ## getUserPoolMfaConfig
  ## Gets the user pool multi-factor authentication (MFA) configuration.
  ##   body: JObject 
                                                                        ## (required)
  var body_402657454 = newJObject()
  if body != nil:
    body_402657454 = body
  result = call_402657453.call(nil, nil, nil, nil, body_402657454)

var getUserPoolMfaConfig* = Call_GetUserPoolMfaConfig_402657440(
    name: "getUserPoolMfaConfig", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUserPoolMfaConfig",
    validator: validate_GetUserPoolMfaConfig_402657441, base: "/",
    makeUrl: url_GetUserPoolMfaConfig_402657442,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GlobalSignOut_402657455 = ref object of OpenApiRestCall_402656044
proc url_GlobalSignOut_402657457(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GlobalSignOut_402657456(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657458 = header.getOrDefault("X-Amz-Target")
  valid_402657458 = validateParameter(valid_402657458, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GlobalSignOut"))
  if valid_402657458 != nil:
    section.add "X-Amz-Target", valid_402657458
  var valid_402657459 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657459 = validateParameter(valid_402657459, JString,
                                      required = false, default = nil)
  if valid_402657459 != nil:
    section.add "X-Amz-Security-Token", valid_402657459
  var valid_402657460 = header.getOrDefault("X-Amz-Signature")
  valid_402657460 = validateParameter(valid_402657460, JString,
                                      required = false, default = nil)
  if valid_402657460 != nil:
    section.add "X-Amz-Signature", valid_402657460
  var valid_402657461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657461 = validateParameter(valid_402657461, JString,
                                      required = false, default = nil)
  if valid_402657461 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657461
  var valid_402657462 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657462 = validateParameter(valid_402657462, JString,
                                      required = false, default = nil)
  if valid_402657462 != nil:
    section.add "X-Amz-Algorithm", valid_402657462
  var valid_402657463 = header.getOrDefault("X-Amz-Date")
  valid_402657463 = validateParameter(valid_402657463, JString,
                                      required = false, default = nil)
  if valid_402657463 != nil:
    section.add "X-Amz-Date", valid_402657463
  var valid_402657464 = header.getOrDefault("X-Amz-Credential")
  valid_402657464 = validateParameter(valid_402657464, JString,
                                      required = false, default = nil)
  if valid_402657464 != nil:
    section.add "X-Amz-Credential", valid_402657464
  var valid_402657465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657465 = validateParameter(valid_402657465, JString,
                                      required = false, default = nil)
  if valid_402657465 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657467: Call_GlobalSignOut_402657455; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Signs out users from all devices. It also invalidates all refresh tokens issued to a user. The user's current access and Id tokens remain valid until their expiry. Access and Id tokens expire one hour after they are issued.
                                                                                         ## 
  let valid = call_402657467.validator(path, query, header, formData, body, _)
  let scheme = call_402657467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657467.makeUrl(scheme.get, call_402657467.host, call_402657467.base,
                                   call_402657467.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657467, uri, valid, _)

proc call*(call_402657468: Call_GlobalSignOut_402657455; body: JsonNode): Recallable =
  ## globalSignOut
  ## Signs out users from all devices. It also invalidates all refresh tokens issued to a user. The user's current access and Id tokens remain valid until their expiry. Access and Id tokens expire one hour after they are issued.
  ##   
                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402657469 = newJObject()
  if body != nil:
    body_402657469 = body
  result = call_402657468.call(nil, nil, nil, nil, body_402657469)

var globalSignOut* = Call_GlobalSignOut_402657455(name: "globalSignOut",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GlobalSignOut",
    validator: validate_GlobalSignOut_402657456, base: "/",
    makeUrl: url_GlobalSignOut_402657457, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateAuth_402657470 = ref object of OpenApiRestCall_402656044
proc url_InitiateAuth_402657472(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_InitiateAuth_402657471(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657473 = header.getOrDefault("X-Amz-Target")
  valid_402657473 = validateParameter(valid_402657473, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.InitiateAuth"))
  if valid_402657473 != nil:
    section.add "X-Amz-Target", valid_402657473
  var valid_402657474 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657474 = validateParameter(valid_402657474, JString,
                                      required = false, default = nil)
  if valid_402657474 != nil:
    section.add "X-Amz-Security-Token", valid_402657474
  var valid_402657475 = header.getOrDefault("X-Amz-Signature")
  valid_402657475 = validateParameter(valid_402657475, JString,
                                      required = false, default = nil)
  if valid_402657475 != nil:
    section.add "X-Amz-Signature", valid_402657475
  var valid_402657476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657476 = validateParameter(valid_402657476, JString,
                                      required = false, default = nil)
  if valid_402657476 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657476
  var valid_402657477 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657477 = validateParameter(valid_402657477, JString,
                                      required = false, default = nil)
  if valid_402657477 != nil:
    section.add "X-Amz-Algorithm", valid_402657477
  var valid_402657478 = header.getOrDefault("X-Amz-Date")
  valid_402657478 = validateParameter(valid_402657478, JString,
                                      required = false, default = nil)
  if valid_402657478 != nil:
    section.add "X-Amz-Date", valid_402657478
  var valid_402657479 = header.getOrDefault("X-Amz-Credential")
  valid_402657479 = validateParameter(valid_402657479, JString,
                                      required = false, default = nil)
  if valid_402657479 != nil:
    section.add "X-Amz-Credential", valid_402657479
  var valid_402657480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657480 = validateParameter(valid_402657480, JString,
                                      required = false, default = nil)
  if valid_402657480 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657482: Call_InitiateAuth_402657470; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Initiates the authentication flow.
                                                                                         ## 
  let valid = call_402657482.validator(path, query, header, formData, body, _)
  let scheme = call_402657482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657482.makeUrl(scheme.get, call_402657482.host, call_402657482.base,
                                   call_402657482.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657482, uri, valid, _)

proc call*(call_402657483: Call_InitiateAuth_402657470; body: JsonNode): Recallable =
  ## initiateAuth
  ## Initiates the authentication flow.
  ##   body: JObject (required)
  var body_402657484 = newJObject()
  if body != nil:
    body_402657484 = body
  result = call_402657483.call(nil, nil, nil, nil, body_402657484)

var initiateAuth* = Call_InitiateAuth_402657470(name: "initiateAuth",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.InitiateAuth",
    validator: validate_InitiateAuth_402657471, base: "/",
    makeUrl: url_InitiateAuth_402657472, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevices_402657485 = ref object of OpenApiRestCall_402656044
proc url_ListDevices_402657487(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDevices_402657486(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657488 = header.getOrDefault("X-Amz-Target")
  valid_402657488 = validateParameter(valid_402657488, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListDevices"))
  if valid_402657488 != nil:
    section.add "X-Amz-Target", valid_402657488
  var valid_402657489 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657489 = validateParameter(valid_402657489, JString,
                                      required = false, default = nil)
  if valid_402657489 != nil:
    section.add "X-Amz-Security-Token", valid_402657489
  var valid_402657490 = header.getOrDefault("X-Amz-Signature")
  valid_402657490 = validateParameter(valid_402657490, JString,
                                      required = false, default = nil)
  if valid_402657490 != nil:
    section.add "X-Amz-Signature", valid_402657490
  var valid_402657491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657491 = validateParameter(valid_402657491, JString,
                                      required = false, default = nil)
  if valid_402657491 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657491
  var valid_402657492 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657492 = validateParameter(valid_402657492, JString,
                                      required = false, default = nil)
  if valid_402657492 != nil:
    section.add "X-Amz-Algorithm", valid_402657492
  var valid_402657493 = header.getOrDefault("X-Amz-Date")
  valid_402657493 = validateParameter(valid_402657493, JString,
                                      required = false, default = nil)
  if valid_402657493 != nil:
    section.add "X-Amz-Date", valid_402657493
  var valid_402657494 = header.getOrDefault("X-Amz-Credential")
  valid_402657494 = validateParameter(valid_402657494, JString,
                                      required = false, default = nil)
  if valid_402657494 != nil:
    section.add "X-Amz-Credential", valid_402657494
  var valid_402657495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657495 = validateParameter(valid_402657495, JString,
                                      required = false, default = nil)
  if valid_402657495 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657495
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657497: Call_ListDevices_402657485; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the devices.
                                                                                         ## 
  let valid = call_402657497.validator(path, query, header, formData, body, _)
  let scheme = call_402657497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657497.makeUrl(scheme.get, call_402657497.host, call_402657497.base,
                                   call_402657497.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657497, uri, valid, _)

proc call*(call_402657498: Call_ListDevices_402657485; body: JsonNode): Recallable =
  ## listDevices
  ## Lists the devices.
  ##   body: JObject (required)
  var body_402657499 = newJObject()
  if body != nil:
    body_402657499 = body
  result = call_402657498.call(nil, nil, nil, nil, body_402657499)

var listDevices* = Call_ListDevices_402657485(name: "listDevices",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListDevices",
    validator: validate_ListDevices_402657486, base: "/",
    makeUrl: url_ListDevices_402657487, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_402657500 = ref object of OpenApiRestCall_402656044
proc url_ListGroups_402657502(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGroups_402657501(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657503 = query.getOrDefault("NextToken")
  valid_402657503 = validateParameter(valid_402657503, JString,
                                      required = false, default = nil)
  if valid_402657503 != nil:
    section.add "NextToken", valid_402657503
  var valid_402657504 = query.getOrDefault("Limit")
  valid_402657504 = validateParameter(valid_402657504, JString,
                                      required = false, default = nil)
  if valid_402657504 != nil:
    section.add "Limit", valid_402657504
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657505 = header.getOrDefault("X-Amz-Target")
  valid_402657505 = validateParameter(valid_402657505, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListGroups"))
  if valid_402657505 != nil:
    section.add "X-Amz-Target", valid_402657505
  var valid_402657506 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657506 = validateParameter(valid_402657506, JString,
                                      required = false, default = nil)
  if valid_402657506 != nil:
    section.add "X-Amz-Security-Token", valid_402657506
  var valid_402657507 = header.getOrDefault("X-Amz-Signature")
  valid_402657507 = validateParameter(valid_402657507, JString,
                                      required = false, default = nil)
  if valid_402657507 != nil:
    section.add "X-Amz-Signature", valid_402657507
  var valid_402657508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657508 = validateParameter(valid_402657508, JString,
                                      required = false, default = nil)
  if valid_402657508 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657508
  var valid_402657509 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657509 = validateParameter(valid_402657509, JString,
                                      required = false, default = nil)
  if valid_402657509 != nil:
    section.add "X-Amz-Algorithm", valid_402657509
  var valid_402657510 = header.getOrDefault("X-Amz-Date")
  valid_402657510 = validateParameter(valid_402657510, JString,
                                      required = false, default = nil)
  if valid_402657510 != nil:
    section.add "X-Amz-Date", valid_402657510
  var valid_402657511 = header.getOrDefault("X-Amz-Credential")
  valid_402657511 = validateParameter(valid_402657511, JString,
                                      required = false, default = nil)
  if valid_402657511 != nil:
    section.add "X-Amz-Credential", valid_402657511
  var valid_402657512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657512 = validateParameter(valid_402657512, JString,
                                      required = false, default = nil)
  if valid_402657512 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657514: Call_ListGroups_402657500; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists the groups associated with a user pool.</p> <p>Calling this action requires developer credentials.</p>
                                                                                         ## 
  let valid = call_402657514.validator(path, query, header, formData, body, _)
  let scheme = call_402657514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657514.makeUrl(scheme.get, call_402657514.host, call_402657514.base,
                                   call_402657514.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657514, uri, valid, _)

proc call*(call_402657515: Call_ListGroups_402657500; body: JsonNode;
           NextToken: string = ""; Limit: string = ""): Recallable =
  ## listGroups
  ## <p>Lists the groups associated with a user pool.</p> <p>Calling this action requires developer credentials.</p>
  ##   
                                                                                                                    ## body: JObject (required)
  ##   
                                                                                                                                               ## NextToken: string
                                                                                                                                               ##            
                                                                                                                                               ## : 
                                                                                                                                               ## Pagination 
                                                                                                                                               ## token
  ##   
                                                                                                                                                       ## Limit: string
                                                                                                                                                       ##        
                                                                                                                                                       ## : 
                                                                                                                                                       ## Pagination 
                                                                                                                                                       ## limit
  var query_402657516 = newJObject()
  var body_402657517 = newJObject()
  if body != nil:
    body_402657517 = body
  add(query_402657516, "NextToken", newJString(NextToken))
  add(query_402657516, "Limit", newJString(Limit))
  result = call_402657515.call(nil, query_402657516, nil, nil, body_402657517)

var listGroups* = Call_ListGroups_402657500(name: "listGroups",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListGroups",
    validator: validate_ListGroups_402657501, base: "/",
    makeUrl: url_ListGroups_402657502, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIdentityProviders_402657518 = ref object of OpenApiRestCall_402656044
proc url_ListIdentityProviders_402657520(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListIdentityProviders_402657519(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657521 = query.getOrDefault("MaxResults")
  valid_402657521 = validateParameter(valid_402657521, JString,
                                      required = false, default = nil)
  if valid_402657521 != nil:
    section.add "MaxResults", valid_402657521
  var valid_402657522 = query.getOrDefault("NextToken")
  valid_402657522 = validateParameter(valid_402657522, JString,
                                      required = false, default = nil)
  if valid_402657522 != nil:
    section.add "NextToken", valid_402657522
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657523 = header.getOrDefault("X-Amz-Target")
  valid_402657523 = validateParameter(valid_402657523, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListIdentityProviders"))
  if valid_402657523 != nil:
    section.add "X-Amz-Target", valid_402657523
  var valid_402657524 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657524 = validateParameter(valid_402657524, JString,
                                      required = false, default = nil)
  if valid_402657524 != nil:
    section.add "X-Amz-Security-Token", valid_402657524
  var valid_402657525 = header.getOrDefault("X-Amz-Signature")
  valid_402657525 = validateParameter(valid_402657525, JString,
                                      required = false, default = nil)
  if valid_402657525 != nil:
    section.add "X-Amz-Signature", valid_402657525
  var valid_402657526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657526 = validateParameter(valid_402657526, JString,
                                      required = false, default = nil)
  if valid_402657526 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657526
  var valid_402657527 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657527 = validateParameter(valid_402657527, JString,
                                      required = false, default = nil)
  if valid_402657527 != nil:
    section.add "X-Amz-Algorithm", valid_402657527
  var valid_402657528 = header.getOrDefault("X-Amz-Date")
  valid_402657528 = validateParameter(valid_402657528, JString,
                                      required = false, default = nil)
  if valid_402657528 != nil:
    section.add "X-Amz-Date", valid_402657528
  var valid_402657529 = header.getOrDefault("X-Amz-Credential")
  valid_402657529 = validateParameter(valid_402657529, JString,
                                      required = false, default = nil)
  if valid_402657529 != nil:
    section.add "X-Amz-Credential", valid_402657529
  var valid_402657530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657530 = validateParameter(valid_402657530, JString,
                                      required = false, default = nil)
  if valid_402657530 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657532: Call_ListIdentityProviders_402657518;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists information about all identity providers for a user pool.
                                                                                         ## 
  let valid = call_402657532.validator(path, query, header, formData, body, _)
  let scheme = call_402657532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657532.makeUrl(scheme.get, call_402657532.host, call_402657532.base,
                                   call_402657532.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657532, uri, valid, _)

proc call*(call_402657533: Call_ListIdentityProviders_402657518; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listIdentityProviders
  ## Lists information about all identity providers for a user pool.
  ##   MaxResults: string
                                                                    ##             : Pagination limit
  ##   
                                                                                                     ## body: JObject (required)
  ##   
                                                                                                                                ## NextToken: string
                                                                                                                                ##            
                                                                                                                                ## : 
                                                                                                                                ## Pagination 
                                                                                                                                ## token
  var query_402657534 = newJObject()
  var body_402657535 = newJObject()
  add(query_402657534, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657535 = body
  add(query_402657534, "NextToken", newJString(NextToken))
  result = call_402657533.call(nil, query_402657534, nil, nil, body_402657535)

var listIdentityProviders* = Call_ListIdentityProviders_402657518(
    name: "listIdentityProviders", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListIdentityProviders",
    validator: validate_ListIdentityProviders_402657519, base: "/",
    makeUrl: url_ListIdentityProviders_402657520,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceServers_402657536 = ref object of OpenApiRestCall_402656044
proc url_ListResourceServers_402657538(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResourceServers_402657537(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657539 = query.getOrDefault("MaxResults")
  valid_402657539 = validateParameter(valid_402657539, JString,
                                      required = false, default = nil)
  if valid_402657539 != nil:
    section.add "MaxResults", valid_402657539
  var valid_402657540 = query.getOrDefault("NextToken")
  valid_402657540 = validateParameter(valid_402657540, JString,
                                      required = false, default = nil)
  if valid_402657540 != nil:
    section.add "NextToken", valid_402657540
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657541 = header.getOrDefault("X-Amz-Target")
  valid_402657541 = validateParameter(valid_402657541, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListResourceServers"))
  if valid_402657541 != nil:
    section.add "X-Amz-Target", valid_402657541
  var valid_402657542 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657542 = validateParameter(valid_402657542, JString,
                                      required = false, default = nil)
  if valid_402657542 != nil:
    section.add "X-Amz-Security-Token", valid_402657542
  var valid_402657543 = header.getOrDefault("X-Amz-Signature")
  valid_402657543 = validateParameter(valid_402657543, JString,
                                      required = false, default = nil)
  if valid_402657543 != nil:
    section.add "X-Amz-Signature", valid_402657543
  var valid_402657544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657544 = validateParameter(valid_402657544, JString,
                                      required = false, default = nil)
  if valid_402657544 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657544
  var valid_402657545 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657545 = validateParameter(valid_402657545, JString,
                                      required = false, default = nil)
  if valid_402657545 != nil:
    section.add "X-Amz-Algorithm", valid_402657545
  var valid_402657546 = header.getOrDefault("X-Amz-Date")
  valid_402657546 = validateParameter(valid_402657546, JString,
                                      required = false, default = nil)
  if valid_402657546 != nil:
    section.add "X-Amz-Date", valid_402657546
  var valid_402657547 = header.getOrDefault("X-Amz-Credential")
  valid_402657547 = validateParameter(valid_402657547, JString,
                                      required = false, default = nil)
  if valid_402657547 != nil:
    section.add "X-Amz-Credential", valid_402657547
  var valid_402657548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657548 = validateParameter(valid_402657548, JString,
                                      required = false, default = nil)
  if valid_402657548 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657550: Call_ListResourceServers_402657536;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the resource servers for a user pool.
                                                                                         ## 
  let valid = call_402657550.validator(path, query, header, formData, body, _)
  let scheme = call_402657550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657550.makeUrl(scheme.get, call_402657550.host, call_402657550.base,
                                   call_402657550.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657550, uri, valid, _)

proc call*(call_402657551: Call_ListResourceServers_402657536; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listResourceServers
  ## Lists the resource servers for a user pool.
  ##   MaxResults: string
                                                ##             : Pagination limit
  ##   
                                                                                 ## body: JObject (required)
  ##   
                                                                                                            ## NextToken: string
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## Pagination 
                                                                                                            ## token
  var query_402657552 = newJObject()
  var body_402657553 = newJObject()
  add(query_402657552, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657553 = body
  add(query_402657552, "NextToken", newJString(NextToken))
  result = call_402657551.call(nil, query_402657552, nil, nil, body_402657553)

var listResourceServers* = Call_ListResourceServers_402657536(
    name: "listResourceServers", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListResourceServers",
    validator: validate_ListResourceServers_402657537, base: "/",
    makeUrl: url_ListResourceServers_402657538,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402657554 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource_402657556(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_402657555(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657557 = header.getOrDefault("X-Amz-Target")
  valid_402657557 = validateParameter(valid_402657557, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListTagsForResource"))
  if valid_402657557 != nil:
    section.add "X-Amz-Target", valid_402657557
  var valid_402657558 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657558 = validateParameter(valid_402657558, JString,
                                      required = false, default = nil)
  if valid_402657558 != nil:
    section.add "X-Amz-Security-Token", valid_402657558
  var valid_402657559 = header.getOrDefault("X-Amz-Signature")
  valid_402657559 = validateParameter(valid_402657559, JString,
                                      required = false, default = nil)
  if valid_402657559 != nil:
    section.add "X-Amz-Signature", valid_402657559
  var valid_402657560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657560 = validateParameter(valid_402657560, JString,
                                      required = false, default = nil)
  if valid_402657560 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657560
  var valid_402657561 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657561 = validateParameter(valid_402657561, JString,
                                      required = false, default = nil)
  if valid_402657561 != nil:
    section.add "X-Amz-Algorithm", valid_402657561
  var valid_402657562 = header.getOrDefault("X-Amz-Date")
  valid_402657562 = validateParameter(valid_402657562, JString,
                                      required = false, default = nil)
  if valid_402657562 != nil:
    section.add "X-Amz-Date", valid_402657562
  var valid_402657563 = header.getOrDefault("X-Amz-Credential")
  valid_402657563 = validateParameter(valid_402657563, JString,
                                      required = false, default = nil)
  if valid_402657563 != nil:
    section.add "X-Amz-Credential", valid_402657563
  var valid_402657564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657564 = validateParameter(valid_402657564, JString,
                                      required = false, default = nil)
  if valid_402657564 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657566: Call_ListTagsForResource_402657554;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists the tags that are assigned to an Amazon Cognito user pool.</p> <p>A tag is a label that you can apply to user pools to categorize and manage them in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>You can use this action up to 10 times per second, per account.</p>
                                                                                         ## 
  let valid = call_402657566.validator(path, query, header, formData, body, _)
  let scheme = call_402657566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657566.makeUrl(scheme.get, call_402657566.host, call_402657566.base,
                                   call_402657566.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657566, uri, valid, _)

proc call*(call_402657567: Call_ListTagsForResource_402657554; body: JsonNode): Recallable =
  ## listTagsForResource
  ## <p>Lists the tags that are assigned to an Amazon Cognito user pool.</p> <p>A tag is a label that you can apply to user pools to categorize and manage them in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>You can use this action up to 10 times per second, per account.</p>
  ##   
                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402657568 = newJObject()
  if body != nil:
    body_402657568 = body
  result = call_402657567.call(nil, nil, nil, nil, body_402657568)

var listTagsForResource* = Call_ListTagsForResource_402657554(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListTagsForResource",
    validator: validate_ListTagsForResource_402657555, base: "/",
    makeUrl: url_ListTagsForResource_402657556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserImportJobs_402657569 = ref object of OpenApiRestCall_402656044
proc url_ListUserImportJobs_402657571(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUserImportJobs_402657570(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657572 = header.getOrDefault("X-Amz-Target")
  valid_402657572 = validateParameter(valid_402657572, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUserImportJobs"))
  if valid_402657572 != nil:
    section.add "X-Amz-Target", valid_402657572
  var valid_402657573 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657573 = validateParameter(valid_402657573, JString,
                                      required = false, default = nil)
  if valid_402657573 != nil:
    section.add "X-Amz-Security-Token", valid_402657573
  var valid_402657574 = header.getOrDefault("X-Amz-Signature")
  valid_402657574 = validateParameter(valid_402657574, JString,
                                      required = false, default = nil)
  if valid_402657574 != nil:
    section.add "X-Amz-Signature", valid_402657574
  var valid_402657575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657575 = validateParameter(valid_402657575, JString,
                                      required = false, default = nil)
  if valid_402657575 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657575
  var valid_402657576 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657576 = validateParameter(valid_402657576, JString,
                                      required = false, default = nil)
  if valid_402657576 != nil:
    section.add "X-Amz-Algorithm", valid_402657576
  var valid_402657577 = header.getOrDefault("X-Amz-Date")
  valid_402657577 = validateParameter(valid_402657577, JString,
                                      required = false, default = nil)
  if valid_402657577 != nil:
    section.add "X-Amz-Date", valid_402657577
  var valid_402657578 = header.getOrDefault("X-Amz-Credential")
  valid_402657578 = validateParameter(valid_402657578, JString,
                                      required = false, default = nil)
  if valid_402657578 != nil:
    section.add "X-Amz-Credential", valid_402657578
  var valid_402657579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657579 = validateParameter(valid_402657579, JString,
                                      required = false, default = nil)
  if valid_402657579 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657581: Call_ListUserImportJobs_402657569;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the user import jobs.
                                                                                         ## 
  let valid = call_402657581.validator(path, query, header, formData, body, _)
  let scheme = call_402657581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657581.makeUrl(scheme.get, call_402657581.host, call_402657581.base,
                                   call_402657581.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657581, uri, valid, _)

proc call*(call_402657582: Call_ListUserImportJobs_402657569; body: JsonNode): Recallable =
  ## listUserImportJobs
  ## Lists the user import jobs.
  ##   body: JObject (required)
  var body_402657583 = newJObject()
  if body != nil:
    body_402657583 = body
  result = call_402657582.call(nil, nil, nil, nil, body_402657583)

var listUserImportJobs* = Call_ListUserImportJobs_402657569(
    name: "listUserImportJobs", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUserImportJobs",
    validator: validate_ListUserImportJobs_402657570, base: "/",
    makeUrl: url_ListUserImportJobs_402657571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserPoolClients_402657584 = ref object of OpenApiRestCall_402656044
proc url_ListUserPoolClients_402657586(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUserPoolClients_402657585(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657587 = query.getOrDefault("MaxResults")
  valid_402657587 = validateParameter(valid_402657587, JString,
                                      required = false, default = nil)
  if valid_402657587 != nil:
    section.add "MaxResults", valid_402657587
  var valid_402657588 = query.getOrDefault("NextToken")
  valid_402657588 = validateParameter(valid_402657588, JString,
                                      required = false, default = nil)
  if valid_402657588 != nil:
    section.add "NextToken", valid_402657588
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657589 = header.getOrDefault("X-Amz-Target")
  valid_402657589 = validateParameter(valid_402657589, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUserPoolClients"))
  if valid_402657589 != nil:
    section.add "X-Amz-Target", valid_402657589
  var valid_402657590 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657590 = validateParameter(valid_402657590, JString,
                                      required = false, default = nil)
  if valid_402657590 != nil:
    section.add "X-Amz-Security-Token", valid_402657590
  var valid_402657591 = header.getOrDefault("X-Amz-Signature")
  valid_402657591 = validateParameter(valid_402657591, JString,
                                      required = false, default = nil)
  if valid_402657591 != nil:
    section.add "X-Amz-Signature", valid_402657591
  var valid_402657592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657592 = validateParameter(valid_402657592, JString,
                                      required = false, default = nil)
  if valid_402657592 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657592
  var valid_402657593 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657593 = validateParameter(valid_402657593, JString,
                                      required = false, default = nil)
  if valid_402657593 != nil:
    section.add "X-Amz-Algorithm", valid_402657593
  var valid_402657594 = header.getOrDefault("X-Amz-Date")
  valid_402657594 = validateParameter(valid_402657594, JString,
                                      required = false, default = nil)
  if valid_402657594 != nil:
    section.add "X-Amz-Date", valid_402657594
  var valid_402657595 = header.getOrDefault("X-Amz-Credential")
  valid_402657595 = validateParameter(valid_402657595, JString,
                                      required = false, default = nil)
  if valid_402657595 != nil:
    section.add "X-Amz-Credential", valid_402657595
  var valid_402657596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657596 = validateParameter(valid_402657596, JString,
                                      required = false, default = nil)
  if valid_402657596 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657598: Call_ListUserPoolClients_402657584;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the clients that have been created for the specified user pool.
                                                                                         ## 
  let valid = call_402657598.validator(path, query, header, formData, body, _)
  let scheme = call_402657598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657598.makeUrl(scheme.get, call_402657598.host, call_402657598.base,
                                   call_402657598.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657598, uri, valid, _)

proc call*(call_402657599: Call_ListUserPoolClients_402657584; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listUserPoolClients
  ## Lists the clients that have been created for the specified user pool.
  ##   
                                                                          ## MaxResults: string
                                                                          ##             
                                                                          ## : 
                                                                          ## Pagination 
                                                                          ## limit
  ##   
                                                                                  ## body: JObject (required)
  ##   
                                                                                                             ## NextToken: string
                                                                                                             ##            
                                                                                                             ## : 
                                                                                                             ## Pagination 
                                                                                                             ## token
  var query_402657600 = newJObject()
  var body_402657601 = newJObject()
  add(query_402657600, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657601 = body
  add(query_402657600, "NextToken", newJString(NextToken))
  result = call_402657599.call(nil, query_402657600, nil, nil, body_402657601)

var listUserPoolClients* = Call_ListUserPoolClients_402657584(
    name: "listUserPoolClients", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUserPoolClients",
    validator: validate_ListUserPoolClients_402657585, base: "/",
    makeUrl: url_ListUserPoolClients_402657586,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserPools_402657602 = ref object of OpenApiRestCall_402656044
proc url_ListUserPools_402657604(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUserPools_402657603(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657605 = query.getOrDefault("MaxResults")
  valid_402657605 = validateParameter(valid_402657605, JString,
                                      required = false, default = nil)
  if valid_402657605 != nil:
    section.add "MaxResults", valid_402657605
  var valid_402657606 = query.getOrDefault("NextToken")
  valid_402657606 = validateParameter(valid_402657606, JString,
                                      required = false, default = nil)
  if valid_402657606 != nil:
    section.add "NextToken", valid_402657606
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657607 = header.getOrDefault("X-Amz-Target")
  valid_402657607 = validateParameter(valid_402657607, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUserPools"))
  if valid_402657607 != nil:
    section.add "X-Amz-Target", valid_402657607
  var valid_402657608 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657608 = validateParameter(valid_402657608, JString,
                                      required = false, default = nil)
  if valid_402657608 != nil:
    section.add "X-Amz-Security-Token", valid_402657608
  var valid_402657609 = header.getOrDefault("X-Amz-Signature")
  valid_402657609 = validateParameter(valid_402657609, JString,
                                      required = false, default = nil)
  if valid_402657609 != nil:
    section.add "X-Amz-Signature", valid_402657609
  var valid_402657610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657610 = validateParameter(valid_402657610, JString,
                                      required = false, default = nil)
  if valid_402657610 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657610
  var valid_402657611 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657611 = validateParameter(valid_402657611, JString,
                                      required = false, default = nil)
  if valid_402657611 != nil:
    section.add "X-Amz-Algorithm", valid_402657611
  var valid_402657612 = header.getOrDefault("X-Amz-Date")
  valid_402657612 = validateParameter(valid_402657612, JString,
                                      required = false, default = nil)
  if valid_402657612 != nil:
    section.add "X-Amz-Date", valid_402657612
  var valid_402657613 = header.getOrDefault("X-Amz-Credential")
  valid_402657613 = validateParameter(valid_402657613, JString,
                                      required = false, default = nil)
  if valid_402657613 != nil:
    section.add "X-Amz-Credential", valid_402657613
  var valid_402657614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657614 = validateParameter(valid_402657614, JString,
                                      required = false, default = nil)
  if valid_402657614 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657616: Call_ListUserPools_402657602; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the user pools associated with an AWS account.
                                                                                         ## 
  let valid = call_402657616.validator(path, query, header, formData, body, _)
  let scheme = call_402657616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657616.makeUrl(scheme.get, call_402657616.host, call_402657616.base,
                                   call_402657616.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657616, uri, valid, _)

proc call*(call_402657617: Call_ListUserPools_402657602; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listUserPools
  ## Lists the user pools associated with an AWS account.
  ##   MaxResults: string
                                                         ##             : Pagination limit
  ##   
                                                                                          ## body: JObject (required)
  ##   
                                                                                                                     ## NextToken: string
                                                                                                                     ##            
                                                                                                                     ## : 
                                                                                                                     ## Pagination 
                                                                                                                     ## token
  var query_402657618 = newJObject()
  var body_402657619 = newJObject()
  add(query_402657618, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657619 = body
  add(query_402657618, "NextToken", newJString(NextToken))
  result = call_402657617.call(nil, query_402657618, nil, nil, body_402657619)

var listUserPools* = Call_ListUserPools_402657602(name: "listUserPools",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUserPools",
    validator: validate_ListUserPools_402657603, base: "/",
    makeUrl: url_ListUserPools_402657604, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_402657620 = ref object of OpenApiRestCall_402656044
proc url_ListUsers_402657622(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUsers_402657621(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the users in the Amazon Cognito user pool.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PaginationToken: JString
                                  ##                  : Pagination token
  ##   Limit: JString
                                                                        ##        : Pagination limit
  section = newJObject()
  var valid_402657623 = query.getOrDefault("PaginationToken")
  valid_402657623 = validateParameter(valid_402657623, JString,
                                      required = false, default = nil)
  if valid_402657623 != nil:
    section.add "PaginationToken", valid_402657623
  var valid_402657624 = query.getOrDefault("Limit")
  valid_402657624 = validateParameter(valid_402657624, JString,
                                      required = false, default = nil)
  if valid_402657624 != nil:
    section.add "Limit", valid_402657624
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657625 = header.getOrDefault("X-Amz-Target")
  valid_402657625 = validateParameter(valid_402657625, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUsers"))
  if valid_402657625 != nil:
    section.add "X-Amz-Target", valid_402657625
  var valid_402657626 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657626 = validateParameter(valid_402657626, JString,
                                      required = false, default = nil)
  if valid_402657626 != nil:
    section.add "X-Amz-Security-Token", valid_402657626
  var valid_402657627 = header.getOrDefault("X-Amz-Signature")
  valid_402657627 = validateParameter(valid_402657627, JString,
                                      required = false, default = nil)
  if valid_402657627 != nil:
    section.add "X-Amz-Signature", valid_402657627
  var valid_402657628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657628 = validateParameter(valid_402657628, JString,
                                      required = false, default = nil)
  if valid_402657628 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657628
  var valid_402657629 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657629 = validateParameter(valid_402657629, JString,
                                      required = false, default = nil)
  if valid_402657629 != nil:
    section.add "X-Amz-Algorithm", valid_402657629
  var valid_402657630 = header.getOrDefault("X-Amz-Date")
  valid_402657630 = validateParameter(valid_402657630, JString,
                                      required = false, default = nil)
  if valid_402657630 != nil:
    section.add "X-Amz-Date", valid_402657630
  var valid_402657631 = header.getOrDefault("X-Amz-Credential")
  valid_402657631 = validateParameter(valid_402657631, JString,
                                      required = false, default = nil)
  if valid_402657631 != nil:
    section.add "X-Amz-Credential", valid_402657631
  var valid_402657632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657632 = validateParameter(valid_402657632, JString,
                                      required = false, default = nil)
  if valid_402657632 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657634: Call_ListUsers_402657620; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the users in the Amazon Cognito user pool.
                                                                                         ## 
  let valid = call_402657634.validator(path, query, header, formData, body, _)
  let scheme = call_402657634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657634.makeUrl(scheme.get, call_402657634.host, call_402657634.base,
                                   call_402657634.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657634, uri, valid, _)

proc call*(call_402657635: Call_ListUsers_402657620; body: JsonNode;
           PaginationToken: string = ""; Limit: string = ""): Recallable =
  ## listUsers
  ## Lists the users in the Amazon Cognito user pool.
  ##   PaginationToken: string
                                                     ##                  : Pagination token
  ##   
                                                                                           ## body: JObject (required)
  ##   
                                                                                                                      ## Limit: string
                                                                                                                      ##        
                                                                                                                      ## : 
                                                                                                                      ## Pagination 
                                                                                                                      ## limit
  var query_402657636 = newJObject()
  var body_402657637 = newJObject()
  add(query_402657636, "PaginationToken", newJString(PaginationToken))
  if body != nil:
    body_402657637 = body
  add(query_402657636, "Limit", newJString(Limit))
  result = call_402657635.call(nil, query_402657636, nil, nil, body_402657637)

var listUsers* = Call_ListUsers_402657620(name: "listUsers",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUsers",
    validator: validate_ListUsers_402657621, base: "/", makeUrl: url_ListUsers_402657622,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsersInGroup_402657638 = ref object of OpenApiRestCall_402656044
proc url_ListUsersInGroup_402657640(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUsersInGroup_402657639(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657641 = query.getOrDefault("NextToken")
  valid_402657641 = validateParameter(valid_402657641, JString,
                                      required = false, default = nil)
  if valid_402657641 != nil:
    section.add "NextToken", valid_402657641
  var valid_402657642 = query.getOrDefault("Limit")
  valid_402657642 = validateParameter(valid_402657642, JString,
                                      required = false, default = nil)
  if valid_402657642 != nil:
    section.add "Limit", valid_402657642
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657643 = header.getOrDefault("X-Amz-Target")
  valid_402657643 = validateParameter(valid_402657643, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUsersInGroup"))
  if valid_402657643 != nil:
    section.add "X-Amz-Target", valid_402657643
  var valid_402657644 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657644 = validateParameter(valid_402657644, JString,
                                      required = false, default = nil)
  if valid_402657644 != nil:
    section.add "X-Amz-Security-Token", valid_402657644
  var valid_402657645 = header.getOrDefault("X-Amz-Signature")
  valid_402657645 = validateParameter(valid_402657645, JString,
                                      required = false, default = nil)
  if valid_402657645 != nil:
    section.add "X-Amz-Signature", valid_402657645
  var valid_402657646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657646 = validateParameter(valid_402657646, JString,
                                      required = false, default = nil)
  if valid_402657646 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657646
  var valid_402657647 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657647 = validateParameter(valid_402657647, JString,
                                      required = false, default = nil)
  if valid_402657647 != nil:
    section.add "X-Amz-Algorithm", valid_402657647
  var valid_402657648 = header.getOrDefault("X-Amz-Date")
  valid_402657648 = validateParameter(valid_402657648, JString,
                                      required = false, default = nil)
  if valid_402657648 != nil:
    section.add "X-Amz-Date", valid_402657648
  var valid_402657649 = header.getOrDefault("X-Amz-Credential")
  valid_402657649 = validateParameter(valid_402657649, JString,
                                      required = false, default = nil)
  if valid_402657649 != nil:
    section.add "X-Amz-Credential", valid_402657649
  var valid_402657650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657650 = validateParameter(valid_402657650, JString,
                                      required = false, default = nil)
  if valid_402657650 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657652: Call_ListUsersInGroup_402657638;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists the users in the specified group.</p> <p>Calling this action requires developer credentials.</p>
                                                                                         ## 
  let valid = call_402657652.validator(path, query, header, formData, body, _)
  let scheme = call_402657652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657652.makeUrl(scheme.get, call_402657652.host, call_402657652.base,
                                   call_402657652.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657652, uri, valid, _)

proc call*(call_402657653: Call_ListUsersInGroup_402657638; body: JsonNode;
           NextToken: string = ""; Limit: string = ""): Recallable =
  ## listUsersInGroup
  ## <p>Lists the users in the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ##   
                                                                                                              ## body: JObject (required)
  ##   
                                                                                                                                         ## NextToken: string
                                                                                                                                         ##            
                                                                                                                                         ## : 
                                                                                                                                         ## Pagination 
                                                                                                                                         ## token
  ##   
                                                                                                                                                 ## Limit: string
                                                                                                                                                 ##        
                                                                                                                                                 ## : 
                                                                                                                                                 ## Pagination 
                                                                                                                                                 ## limit
  var query_402657654 = newJObject()
  var body_402657655 = newJObject()
  if body != nil:
    body_402657655 = body
  add(query_402657654, "NextToken", newJString(NextToken))
  add(query_402657654, "Limit", newJString(Limit))
  result = call_402657653.call(nil, query_402657654, nil, nil, body_402657655)

var listUsersInGroup* = Call_ListUsersInGroup_402657638(
    name: "listUsersInGroup", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUsersInGroup",
    validator: validate_ListUsersInGroup_402657639, base: "/",
    makeUrl: url_ListUsersInGroup_402657640,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResendConfirmationCode_402657656 = ref object of OpenApiRestCall_402656044
proc url_ResendConfirmationCode_402657658(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ResendConfirmationCode_402657657(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657659 = header.getOrDefault("X-Amz-Target")
  valid_402657659 = validateParameter(valid_402657659, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ResendConfirmationCode"))
  if valid_402657659 != nil:
    section.add "X-Amz-Target", valid_402657659
  var valid_402657660 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657660 = validateParameter(valid_402657660, JString,
                                      required = false, default = nil)
  if valid_402657660 != nil:
    section.add "X-Amz-Security-Token", valid_402657660
  var valid_402657661 = header.getOrDefault("X-Amz-Signature")
  valid_402657661 = validateParameter(valid_402657661, JString,
                                      required = false, default = nil)
  if valid_402657661 != nil:
    section.add "X-Amz-Signature", valid_402657661
  var valid_402657662 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657662 = validateParameter(valid_402657662, JString,
                                      required = false, default = nil)
  if valid_402657662 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657662
  var valid_402657663 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657663 = validateParameter(valid_402657663, JString,
                                      required = false, default = nil)
  if valid_402657663 != nil:
    section.add "X-Amz-Algorithm", valid_402657663
  var valid_402657664 = header.getOrDefault("X-Amz-Date")
  valid_402657664 = validateParameter(valid_402657664, JString,
                                      required = false, default = nil)
  if valid_402657664 != nil:
    section.add "X-Amz-Date", valid_402657664
  var valid_402657665 = header.getOrDefault("X-Amz-Credential")
  valid_402657665 = validateParameter(valid_402657665, JString,
                                      required = false, default = nil)
  if valid_402657665 != nil:
    section.add "X-Amz-Credential", valid_402657665
  var valid_402657666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657666 = validateParameter(valid_402657666, JString,
                                      required = false, default = nil)
  if valid_402657666 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657668: Call_ResendConfirmationCode_402657656;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Resends the confirmation (for confirmation of registration) to a specific user in the user pool.
                                                                                         ## 
  let valid = call_402657668.validator(path, query, header, formData, body, _)
  let scheme = call_402657668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657668.makeUrl(scheme.get, call_402657668.host, call_402657668.base,
                                   call_402657668.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657668, uri, valid, _)

proc call*(call_402657669: Call_ResendConfirmationCode_402657656; body: JsonNode): Recallable =
  ## resendConfirmationCode
  ## Resends the confirmation (for confirmation of registration) to a specific user in the user pool.
  ##   
                                                                                                     ## body: JObject (required)
  var body_402657670 = newJObject()
  if body != nil:
    body_402657670 = body
  result = call_402657669.call(nil, nil, nil, nil, body_402657670)

var resendConfirmationCode* = Call_ResendConfirmationCode_402657656(
    name: "resendConfirmationCode", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ResendConfirmationCode",
    validator: validate_ResendConfirmationCode_402657657, base: "/",
    makeUrl: url_ResendConfirmationCode_402657658,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RespondToAuthChallenge_402657671 = ref object of OpenApiRestCall_402656044
proc url_RespondToAuthChallenge_402657673(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RespondToAuthChallenge_402657672(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657674 = header.getOrDefault("X-Amz-Target")
  valid_402657674 = validateParameter(valid_402657674, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.RespondToAuthChallenge"))
  if valid_402657674 != nil:
    section.add "X-Amz-Target", valid_402657674
  var valid_402657675 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657675 = validateParameter(valid_402657675, JString,
                                      required = false, default = nil)
  if valid_402657675 != nil:
    section.add "X-Amz-Security-Token", valid_402657675
  var valid_402657676 = header.getOrDefault("X-Amz-Signature")
  valid_402657676 = validateParameter(valid_402657676, JString,
                                      required = false, default = nil)
  if valid_402657676 != nil:
    section.add "X-Amz-Signature", valid_402657676
  var valid_402657677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657677 = validateParameter(valid_402657677, JString,
                                      required = false, default = nil)
  if valid_402657677 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657677
  var valid_402657678 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657678 = validateParameter(valid_402657678, JString,
                                      required = false, default = nil)
  if valid_402657678 != nil:
    section.add "X-Amz-Algorithm", valid_402657678
  var valid_402657679 = header.getOrDefault("X-Amz-Date")
  valid_402657679 = validateParameter(valid_402657679, JString,
                                      required = false, default = nil)
  if valid_402657679 != nil:
    section.add "X-Amz-Date", valid_402657679
  var valid_402657680 = header.getOrDefault("X-Amz-Credential")
  valid_402657680 = validateParameter(valid_402657680, JString,
                                      required = false, default = nil)
  if valid_402657680 != nil:
    section.add "X-Amz-Credential", valid_402657680
  var valid_402657681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657681 = validateParameter(valid_402657681, JString,
                                      required = false, default = nil)
  if valid_402657681 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657683: Call_RespondToAuthChallenge_402657671;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Responds to the authentication challenge.
                                                                                         ## 
  let valid = call_402657683.validator(path, query, header, formData, body, _)
  let scheme = call_402657683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657683.makeUrl(scheme.get, call_402657683.host, call_402657683.base,
                                   call_402657683.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657683, uri, valid, _)

proc call*(call_402657684: Call_RespondToAuthChallenge_402657671; body: JsonNode): Recallable =
  ## respondToAuthChallenge
  ## Responds to the authentication challenge.
  ##   body: JObject (required)
  var body_402657685 = newJObject()
  if body != nil:
    body_402657685 = body
  result = call_402657684.call(nil, nil, nil, nil, body_402657685)

var respondToAuthChallenge* = Call_RespondToAuthChallenge_402657671(
    name: "respondToAuthChallenge", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.RespondToAuthChallenge",
    validator: validate_RespondToAuthChallenge_402657672, base: "/",
    makeUrl: url_RespondToAuthChallenge_402657673,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetRiskConfiguration_402657686 = ref object of OpenApiRestCall_402656044
proc url_SetRiskConfiguration_402657688(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SetRiskConfiguration_402657687(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657689 = header.getOrDefault("X-Amz-Target")
  valid_402657689 = validateParameter(valid_402657689, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetRiskConfiguration"))
  if valid_402657689 != nil:
    section.add "X-Amz-Target", valid_402657689
  var valid_402657690 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657690 = validateParameter(valid_402657690, JString,
                                      required = false, default = nil)
  if valid_402657690 != nil:
    section.add "X-Amz-Security-Token", valid_402657690
  var valid_402657691 = header.getOrDefault("X-Amz-Signature")
  valid_402657691 = validateParameter(valid_402657691, JString,
                                      required = false, default = nil)
  if valid_402657691 != nil:
    section.add "X-Amz-Signature", valid_402657691
  var valid_402657692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657692 = validateParameter(valid_402657692, JString,
                                      required = false, default = nil)
  if valid_402657692 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657692
  var valid_402657693 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657693 = validateParameter(valid_402657693, JString,
                                      required = false, default = nil)
  if valid_402657693 != nil:
    section.add "X-Amz-Algorithm", valid_402657693
  var valid_402657694 = header.getOrDefault("X-Amz-Date")
  valid_402657694 = validateParameter(valid_402657694, JString,
                                      required = false, default = nil)
  if valid_402657694 != nil:
    section.add "X-Amz-Date", valid_402657694
  var valid_402657695 = header.getOrDefault("X-Amz-Credential")
  valid_402657695 = validateParameter(valid_402657695, JString,
                                      required = false, default = nil)
  if valid_402657695 != nil:
    section.add "X-Amz-Credential", valid_402657695
  var valid_402657696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657696 = validateParameter(valid_402657696, JString,
                                      required = false, default = nil)
  if valid_402657696 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657698: Call_SetRiskConfiguration_402657686;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Configures actions on detected risks. To delete the risk configuration for <code>UserPoolId</code> or <code>ClientId</code>, pass null values for all four configuration types.</p> <p>To enable Amazon Cognito advanced security features, update the user pool to include the <code>UserPoolAddOns</code> key<code>AdvancedSecurityMode</code>.</p> <p>See .</p>
                                                                                         ## 
  let valid = call_402657698.validator(path, query, header, formData, body, _)
  let scheme = call_402657698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657698.makeUrl(scheme.get, call_402657698.host, call_402657698.base,
                                   call_402657698.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657698, uri, valid, _)

proc call*(call_402657699: Call_SetRiskConfiguration_402657686; body: JsonNode): Recallable =
  ## setRiskConfiguration
  ## <p>Configures actions on detected risks. To delete the risk configuration for <code>UserPoolId</code> or <code>ClientId</code>, pass null values for all four configuration types.</p> <p>To enable Amazon Cognito advanced security features, update the user pool to include the <code>UserPoolAddOns</code> key<code>AdvancedSecurityMode</code>.</p> <p>See .</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402657700 = newJObject()
  if body != nil:
    body_402657700 = body
  result = call_402657699.call(nil, nil, nil, nil, body_402657700)

var setRiskConfiguration* = Call_SetRiskConfiguration_402657686(
    name: "setRiskConfiguration", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetRiskConfiguration",
    validator: validate_SetRiskConfiguration_402657687, base: "/",
    makeUrl: url_SetRiskConfiguration_402657688,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUICustomization_402657701 = ref object of OpenApiRestCall_402656044
proc url_SetUICustomization_402657703(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SetUICustomization_402657702(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657704 = header.getOrDefault("X-Amz-Target")
  valid_402657704 = validateParameter(valid_402657704, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUICustomization"))
  if valid_402657704 != nil:
    section.add "X-Amz-Target", valid_402657704
  var valid_402657705 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657705 = validateParameter(valid_402657705, JString,
                                      required = false, default = nil)
  if valid_402657705 != nil:
    section.add "X-Amz-Security-Token", valid_402657705
  var valid_402657706 = header.getOrDefault("X-Amz-Signature")
  valid_402657706 = validateParameter(valid_402657706, JString,
                                      required = false, default = nil)
  if valid_402657706 != nil:
    section.add "X-Amz-Signature", valid_402657706
  var valid_402657707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657707 = validateParameter(valid_402657707, JString,
                                      required = false, default = nil)
  if valid_402657707 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657707
  var valid_402657708 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657708 = validateParameter(valid_402657708, JString,
                                      required = false, default = nil)
  if valid_402657708 != nil:
    section.add "X-Amz-Algorithm", valid_402657708
  var valid_402657709 = header.getOrDefault("X-Amz-Date")
  valid_402657709 = validateParameter(valid_402657709, JString,
                                      required = false, default = nil)
  if valid_402657709 != nil:
    section.add "X-Amz-Date", valid_402657709
  var valid_402657710 = header.getOrDefault("X-Amz-Credential")
  valid_402657710 = validateParameter(valid_402657710, JString,
                                      required = false, default = nil)
  if valid_402657710 != nil:
    section.add "X-Amz-Credential", valid_402657710
  var valid_402657711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657711 = validateParameter(valid_402657711, JString,
                                      required = false, default = nil)
  if valid_402657711 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657711
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657713: Call_SetUICustomization_402657701;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sets the UI customization information for a user pool's built-in app UI.</p> <p>You can specify app UI customization settings for a single client (with a specific <code>clientId</code>) or for all clients (by setting the <code>clientId</code> to <code>ALL</code>). If you specify <code>ALL</code>, the default configuration will be used for every client that has no UI customization set previously. If you specify UI customization settings for a particular client, it will no longer fall back to the <code>ALL</code> configuration. </p> <note> <p>To use this API, your user pool must have a domain associated with it. Otherwise, there is no place to host the app's pages, and the service will throw an error.</p> </note>
                                                                                         ## 
  let valid = call_402657713.validator(path, query, header, formData, body, _)
  let scheme = call_402657713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657713.makeUrl(scheme.get, call_402657713.host, call_402657713.base,
                                   call_402657713.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657713, uri, valid, _)

proc call*(call_402657714: Call_SetUICustomization_402657701; body: JsonNode): Recallable =
  ## setUICustomization
  ## <p>Sets the UI customization information for a user pool's built-in app UI.</p> <p>You can specify app UI customization settings for a single client (with a specific <code>clientId</code>) or for all clients (by setting the <code>clientId</code> to <code>ALL</code>). If you specify <code>ALL</code>, the default configuration will be used for every client that has no UI customization set previously. If you specify UI customization settings for a particular client, it will no longer fall back to the <code>ALL</code> configuration. </p> <note> <p>To use this API, your user pool must have a domain associated with it. Otherwise, there is no place to host the app's pages, and the service will throw an error.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402657715 = newJObject()
  if body != nil:
    body_402657715 = body
  result = call_402657714.call(nil, nil, nil, nil, body_402657715)

var setUICustomization* = Call_SetUICustomization_402657701(
    name: "setUICustomization", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUICustomization",
    validator: validate_SetUICustomization_402657702, base: "/",
    makeUrl: url_SetUICustomization_402657703,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUserMFAPreference_402657716 = ref object of OpenApiRestCall_402656044
proc url_SetUserMFAPreference_402657718(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SetUserMFAPreference_402657717(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657719 = header.getOrDefault("X-Amz-Target")
  valid_402657719 = validateParameter(valid_402657719, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUserMFAPreference"))
  if valid_402657719 != nil:
    section.add "X-Amz-Target", valid_402657719
  var valid_402657720 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657720 = validateParameter(valid_402657720, JString,
                                      required = false, default = nil)
  if valid_402657720 != nil:
    section.add "X-Amz-Security-Token", valid_402657720
  var valid_402657721 = header.getOrDefault("X-Amz-Signature")
  valid_402657721 = validateParameter(valid_402657721, JString,
                                      required = false, default = nil)
  if valid_402657721 != nil:
    section.add "X-Amz-Signature", valid_402657721
  var valid_402657722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657722 = validateParameter(valid_402657722, JString,
                                      required = false, default = nil)
  if valid_402657722 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657722
  var valid_402657723 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657723 = validateParameter(valid_402657723, JString,
                                      required = false, default = nil)
  if valid_402657723 != nil:
    section.add "X-Amz-Algorithm", valid_402657723
  var valid_402657724 = header.getOrDefault("X-Amz-Date")
  valid_402657724 = validateParameter(valid_402657724, JString,
                                      required = false, default = nil)
  if valid_402657724 != nil:
    section.add "X-Amz-Date", valid_402657724
  var valid_402657725 = header.getOrDefault("X-Amz-Credential")
  valid_402657725 = validateParameter(valid_402657725, JString,
                                      required = false, default = nil)
  if valid_402657725 != nil:
    section.add "X-Amz-Credential", valid_402657725
  var valid_402657726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657726 = validateParameter(valid_402657726, JString,
                                      required = false, default = nil)
  if valid_402657726 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657726
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657728: Call_SetUserMFAPreference_402657716;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Set the user's multi-factor authentication (MFA) method preference, including which MFA factors are enabled and if any are preferred. Only one factor can be set as preferred. The preferred MFA factor will be used to authenticate a user if multiple factors are enabled. If multiple options are enabled and no preference is set, a challenge to choose an MFA option will be returned during sign in.
                                                                                         ## 
  let valid = call_402657728.validator(path, query, header, formData, body, _)
  let scheme = call_402657728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657728.makeUrl(scheme.get, call_402657728.host, call_402657728.base,
                                   call_402657728.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657728, uri, valid, _)

proc call*(call_402657729: Call_SetUserMFAPreference_402657716; body: JsonNode): Recallable =
  ## setUserMFAPreference
  ## Set the user's multi-factor authentication (MFA) method preference, including which MFA factors are enabled and if any are preferred. Only one factor can be set as preferred. The preferred MFA factor will be used to authenticate a user if multiple factors are enabled. If multiple options are enabled and no preference is set, a challenge to choose an MFA option will be returned during sign in.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                ## body: JObject (required)
  var body_402657730 = newJObject()
  if body != nil:
    body_402657730 = body
  result = call_402657729.call(nil, nil, nil, nil, body_402657730)

var setUserMFAPreference* = Call_SetUserMFAPreference_402657716(
    name: "setUserMFAPreference", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUserMFAPreference",
    validator: validate_SetUserMFAPreference_402657717, base: "/",
    makeUrl: url_SetUserMFAPreference_402657718,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUserPoolMfaConfig_402657731 = ref object of OpenApiRestCall_402656044
proc url_SetUserPoolMfaConfig_402657733(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SetUserPoolMfaConfig_402657732(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657734 = header.getOrDefault("X-Amz-Target")
  valid_402657734 = validateParameter(valid_402657734, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUserPoolMfaConfig"))
  if valid_402657734 != nil:
    section.add "X-Amz-Target", valid_402657734
  var valid_402657735 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657735 = validateParameter(valid_402657735, JString,
                                      required = false, default = nil)
  if valid_402657735 != nil:
    section.add "X-Amz-Security-Token", valid_402657735
  var valid_402657736 = header.getOrDefault("X-Amz-Signature")
  valid_402657736 = validateParameter(valid_402657736, JString,
                                      required = false, default = nil)
  if valid_402657736 != nil:
    section.add "X-Amz-Signature", valid_402657736
  var valid_402657737 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657737 = validateParameter(valid_402657737, JString,
                                      required = false, default = nil)
  if valid_402657737 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657737
  var valid_402657738 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657738 = validateParameter(valid_402657738, JString,
                                      required = false, default = nil)
  if valid_402657738 != nil:
    section.add "X-Amz-Algorithm", valid_402657738
  var valid_402657739 = header.getOrDefault("X-Amz-Date")
  valid_402657739 = validateParameter(valid_402657739, JString,
                                      required = false, default = nil)
  if valid_402657739 != nil:
    section.add "X-Amz-Date", valid_402657739
  var valid_402657740 = header.getOrDefault("X-Amz-Credential")
  valid_402657740 = validateParameter(valid_402657740, JString,
                                      required = false, default = nil)
  if valid_402657740 != nil:
    section.add "X-Amz-Credential", valid_402657740
  var valid_402657741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657741 = validateParameter(valid_402657741, JString,
                                      required = false, default = nil)
  if valid_402657741 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657741
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657743: Call_SetUserPoolMfaConfig_402657731;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Set the user pool multi-factor authentication (MFA) configuration.
                                                                                         ## 
  let valid = call_402657743.validator(path, query, header, formData, body, _)
  let scheme = call_402657743.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657743.makeUrl(scheme.get, call_402657743.host, call_402657743.base,
                                   call_402657743.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657743, uri, valid, _)

proc call*(call_402657744: Call_SetUserPoolMfaConfig_402657731; body: JsonNode): Recallable =
  ## setUserPoolMfaConfig
  ## Set the user pool multi-factor authentication (MFA) configuration.
  ##   body: JObject 
                                                                       ## (required)
  var body_402657745 = newJObject()
  if body != nil:
    body_402657745 = body
  result = call_402657744.call(nil, nil, nil, nil, body_402657745)

var setUserPoolMfaConfig* = Call_SetUserPoolMfaConfig_402657731(
    name: "setUserPoolMfaConfig", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUserPoolMfaConfig",
    validator: validate_SetUserPoolMfaConfig_402657732, base: "/",
    makeUrl: url_SetUserPoolMfaConfig_402657733,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUserSettings_402657746 = ref object of OpenApiRestCall_402656044
proc url_SetUserSettings_402657748(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SetUserSettings_402657747(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657749 = header.getOrDefault("X-Amz-Target")
  valid_402657749 = validateParameter(valid_402657749, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUserSettings"))
  if valid_402657749 != nil:
    section.add "X-Amz-Target", valid_402657749
  var valid_402657750 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657750 = validateParameter(valid_402657750, JString,
                                      required = false, default = nil)
  if valid_402657750 != nil:
    section.add "X-Amz-Security-Token", valid_402657750
  var valid_402657751 = header.getOrDefault("X-Amz-Signature")
  valid_402657751 = validateParameter(valid_402657751, JString,
                                      required = false, default = nil)
  if valid_402657751 != nil:
    section.add "X-Amz-Signature", valid_402657751
  var valid_402657752 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657752 = validateParameter(valid_402657752, JString,
                                      required = false, default = nil)
  if valid_402657752 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657752
  var valid_402657753 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657753 = validateParameter(valid_402657753, JString,
                                      required = false, default = nil)
  if valid_402657753 != nil:
    section.add "X-Amz-Algorithm", valid_402657753
  var valid_402657754 = header.getOrDefault("X-Amz-Date")
  valid_402657754 = validateParameter(valid_402657754, JString,
                                      required = false, default = nil)
  if valid_402657754 != nil:
    section.add "X-Amz-Date", valid_402657754
  var valid_402657755 = header.getOrDefault("X-Amz-Credential")
  valid_402657755 = validateParameter(valid_402657755, JString,
                                      required = false, default = nil)
  if valid_402657755 != nil:
    section.add "X-Amz-Credential", valid_402657755
  var valid_402657756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657756 = validateParameter(valid_402657756, JString,
                                      required = false, default = nil)
  if valid_402657756 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657756
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657758: Call_SetUserSettings_402657746; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  <i>This action is no longer supported.</i> You can use it to configure only SMS MFA. You can't use it to configure TOTP software token MFA. To configure either type of MFA, use the <a>SetUserMFAPreference</a> action instead.
                                                                                         ## 
  let valid = call_402657758.validator(path, query, header, formData, body, _)
  let scheme = call_402657758.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657758.makeUrl(scheme.get, call_402657758.host, call_402657758.base,
                                   call_402657758.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657758, uri, valid, _)

proc call*(call_402657759: Call_SetUserSettings_402657746; body: JsonNode): Recallable =
  ## setUserSettings
  ##  <i>This action is no longer supported.</i> You can use it to configure only SMS MFA. You can't use it to configure TOTP software token MFA. To configure either type of MFA, use the <a>SetUserMFAPreference</a> action instead.
  ##   
                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402657760 = newJObject()
  if body != nil:
    body_402657760 = body
  result = call_402657759.call(nil, nil, nil, nil, body_402657760)

var setUserSettings* = Call_SetUserSettings_402657746(name: "setUserSettings",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUserSettings",
    validator: validate_SetUserSettings_402657747, base: "/",
    makeUrl: url_SetUserSettings_402657748, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SignUp_402657761 = ref object of OpenApiRestCall_402656044
proc url_SignUp_402657763(protocol: Scheme; host: string; base: string;
                          route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SignUp_402657762(path: JsonNode; query: JsonNode;
                               header: JsonNode; formData: JsonNode;
                               body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657764 = header.getOrDefault("X-Amz-Target")
  valid_402657764 = validateParameter(valid_402657764, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SignUp"))
  if valid_402657764 != nil:
    section.add "X-Amz-Target", valid_402657764
  var valid_402657765 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657765 = validateParameter(valid_402657765, JString,
                                      required = false, default = nil)
  if valid_402657765 != nil:
    section.add "X-Amz-Security-Token", valid_402657765
  var valid_402657766 = header.getOrDefault("X-Amz-Signature")
  valid_402657766 = validateParameter(valid_402657766, JString,
                                      required = false, default = nil)
  if valid_402657766 != nil:
    section.add "X-Amz-Signature", valid_402657766
  var valid_402657767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657767 = validateParameter(valid_402657767, JString,
                                      required = false, default = nil)
  if valid_402657767 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657767
  var valid_402657768 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657768 = validateParameter(valid_402657768, JString,
                                      required = false, default = nil)
  if valid_402657768 != nil:
    section.add "X-Amz-Algorithm", valid_402657768
  var valid_402657769 = header.getOrDefault("X-Amz-Date")
  valid_402657769 = validateParameter(valid_402657769, JString,
                                      required = false, default = nil)
  if valid_402657769 != nil:
    section.add "X-Amz-Date", valid_402657769
  var valid_402657770 = header.getOrDefault("X-Amz-Credential")
  valid_402657770 = validateParameter(valid_402657770, JString,
                                      required = false, default = nil)
  if valid_402657770 != nil:
    section.add "X-Amz-Credential", valid_402657770
  var valid_402657771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657771 = validateParameter(valid_402657771, JString,
                                      required = false, default = nil)
  if valid_402657771 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657771
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657773: Call_SignUp_402657761; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Registers the user in the specified user pool and creates a user name, password, and user attributes.
                                                                                         ## 
  let valid = call_402657773.validator(path, query, header, formData, body, _)
  let scheme = call_402657773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657773.makeUrl(scheme.get, call_402657773.host, call_402657773.base,
                                   call_402657773.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657773, uri, valid, _)

proc call*(call_402657774: Call_SignUp_402657761; body: JsonNode): Recallable =
  ## signUp
  ## Registers the user in the specified user pool and creates a user name, password, and user attributes.
  ##   
                                                                                                          ## body: JObject (required)
  var body_402657775 = newJObject()
  if body != nil:
    body_402657775 = body
  result = call_402657774.call(nil, nil, nil, nil, body_402657775)

var signUp* = Call_SignUp_402657761(name: "signUp", meth: HttpMethod.HttpPost,
                                    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SignUp",
                                    validator: validate_SignUp_402657762,
                                    base: "/", makeUrl: url_SignUp_402657763,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartUserImportJob_402657776 = ref object of OpenApiRestCall_402656044
proc url_StartUserImportJob_402657778(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartUserImportJob_402657777(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657779 = header.getOrDefault("X-Amz-Target")
  valid_402657779 = validateParameter(valid_402657779, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.StartUserImportJob"))
  if valid_402657779 != nil:
    section.add "X-Amz-Target", valid_402657779
  var valid_402657780 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657780 = validateParameter(valid_402657780, JString,
                                      required = false, default = nil)
  if valid_402657780 != nil:
    section.add "X-Amz-Security-Token", valid_402657780
  var valid_402657781 = header.getOrDefault("X-Amz-Signature")
  valid_402657781 = validateParameter(valid_402657781, JString,
                                      required = false, default = nil)
  if valid_402657781 != nil:
    section.add "X-Amz-Signature", valid_402657781
  var valid_402657782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657782 = validateParameter(valid_402657782, JString,
                                      required = false, default = nil)
  if valid_402657782 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657782
  var valid_402657783 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657783 = validateParameter(valid_402657783, JString,
                                      required = false, default = nil)
  if valid_402657783 != nil:
    section.add "X-Amz-Algorithm", valid_402657783
  var valid_402657784 = header.getOrDefault("X-Amz-Date")
  valid_402657784 = validateParameter(valid_402657784, JString,
                                      required = false, default = nil)
  if valid_402657784 != nil:
    section.add "X-Amz-Date", valid_402657784
  var valid_402657785 = header.getOrDefault("X-Amz-Credential")
  valid_402657785 = validateParameter(valid_402657785, JString,
                                      required = false, default = nil)
  if valid_402657785 != nil:
    section.add "X-Amz-Credential", valid_402657785
  var valid_402657786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657786 = validateParameter(valid_402657786, JString,
                                      required = false, default = nil)
  if valid_402657786 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657786
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657788: Call_StartUserImportJob_402657776;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts the user import.
                                                                                         ## 
  let valid = call_402657788.validator(path, query, header, formData, body, _)
  let scheme = call_402657788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657788.makeUrl(scheme.get, call_402657788.host, call_402657788.base,
                                   call_402657788.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657788, uri, valid, _)

proc call*(call_402657789: Call_StartUserImportJob_402657776; body: JsonNode): Recallable =
  ## startUserImportJob
  ## Starts the user import.
  ##   body: JObject (required)
  var body_402657790 = newJObject()
  if body != nil:
    body_402657790 = body
  result = call_402657789.call(nil, nil, nil, nil, body_402657790)

var startUserImportJob* = Call_StartUserImportJob_402657776(
    name: "startUserImportJob", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.StartUserImportJob",
    validator: validate_StartUserImportJob_402657777, base: "/",
    makeUrl: url_StartUserImportJob_402657778,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopUserImportJob_402657791 = ref object of OpenApiRestCall_402656044
proc url_StopUserImportJob_402657793(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopUserImportJob_402657792(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657794 = header.getOrDefault("X-Amz-Target")
  valid_402657794 = validateParameter(valid_402657794, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.StopUserImportJob"))
  if valid_402657794 != nil:
    section.add "X-Amz-Target", valid_402657794
  var valid_402657795 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657795 = validateParameter(valid_402657795, JString,
                                      required = false, default = nil)
  if valid_402657795 != nil:
    section.add "X-Amz-Security-Token", valid_402657795
  var valid_402657796 = header.getOrDefault("X-Amz-Signature")
  valid_402657796 = validateParameter(valid_402657796, JString,
                                      required = false, default = nil)
  if valid_402657796 != nil:
    section.add "X-Amz-Signature", valid_402657796
  var valid_402657797 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657797 = validateParameter(valid_402657797, JString,
                                      required = false, default = nil)
  if valid_402657797 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657797
  var valid_402657798 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657798 = validateParameter(valid_402657798, JString,
                                      required = false, default = nil)
  if valid_402657798 != nil:
    section.add "X-Amz-Algorithm", valid_402657798
  var valid_402657799 = header.getOrDefault("X-Amz-Date")
  valid_402657799 = validateParameter(valid_402657799, JString,
                                      required = false, default = nil)
  if valid_402657799 != nil:
    section.add "X-Amz-Date", valid_402657799
  var valid_402657800 = header.getOrDefault("X-Amz-Credential")
  valid_402657800 = validateParameter(valid_402657800, JString,
                                      required = false, default = nil)
  if valid_402657800 != nil:
    section.add "X-Amz-Credential", valid_402657800
  var valid_402657801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657801 = validateParameter(valid_402657801, JString,
                                      required = false, default = nil)
  if valid_402657801 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657801
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657803: Call_StopUserImportJob_402657791;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops the user import job.
                                                                                         ## 
  let valid = call_402657803.validator(path, query, header, formData, body, _)
  let scheme = call_402657803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657803.makeUrl(scheme.get, call_402657803.host, call_402657803.base,
                                   call_402657803.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657803, uri, valid, _)

proc call*(call_402657804: Call_StopUserImportJob_402657791; body: JsonNode): Recallable =
  ## stopUserImportJob
  ## Stops the user import job.
  ##   body: JObject (required)
  var body_402657805 = newJObject()
  if body != nil:
    body_402657805 = body
  result = call_402657804.call(nil, nil, nil, nil, body_402657805)

var stopUserImportJob* = Call_StopUserImportJob_402657791(
    name: "stopUserImportJob", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.StopUserImportJob",
    validator: validate_StopUserImportJob_402657792, base: "/",
    makeUrl: url_StopUserImportJob_402657793,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402657806 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402657808(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_402657807(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657809 = header.getOrDefault("X-Amz-Target")
  valid_402657809 = validateParameter(valid_402657809, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.TagResource"))
  if valid_402657809 != nil:
    section.add "X-Amz-Target", valid_402657809
  var valid_402657810 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657810 = validateParameter(valid_402657810, JString,
                                      required = false, default = nil)
  if valid_402657810 != nil:
    section.add "X-Amz-Security-Token", valid_402657810
  var valid_402657811 = header.getOrDefault("X-Amz-Signature")
  valid_402657811 = validateParameter(valid_402657811, JString,
                                      required = false, default = nil)
  if valid_402657811 != nil:
    section.add "X-Amz-Signature", valid_402657811
  var valid_402657812 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657812 = validateParameter(valid_402657812, JString,
                                      required = false, default = nil)
  if valid_402657812 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657812
  var valid_402657813 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657813 = validateParameter(valid_402657813, JString,
                                      required = false, default = nil)
  if valid_402657813 != nil:
    section.add "X-Amz-Algorithm", valid_402657813
  var valid_402657814 = header.getOrDefault("X-Amz-Date")
  valid_402657814 = validateParameter(valid_402657814, JString,
                                      required = false, default = nil)
  if valid_402657814 != nil:
    section.add "X-Amz-Date", valid_402657814
  var valid_402657815 = header.getOrDefault("X-Amz-Credential")
  valid_402657815 = validateParameter(valid_402657815, JString,
                                      required = false, default = nil)
  if valid_402657815 != nil:
    section.add "X-Amz-Credential", valid_402657815
  var valid_402657816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657816 = validateParameter(valid_402657816, JString,
                                      required = false, default = nil)
  if valid_402657816 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657818: Call_TagResource_402657806; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Assigns a set of tags to an Amazon Cognito user pool. A tag is a label that you can use to categorize and manage user pools in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>Each tag consists of a key and value, both of which you define. A key is a general category for more specific values. For example, if you have two versions of a user pool, one for testing and another for production, you might assign an <code>Environment</code> tag key to both user pools. The value of this key might be <code>Test</code> for one user pool and <code>Production</code> for the other.</p> <p>Tags are useful for cost tracking and access control. You can activate your tags so that they appear on the Billing and Cost Management console, where you can track the costs associated with your user pools. In an IAM policy, you can constrain permissions for user pools based on specific tags or tag values.</p> <p>You can use this action up to 5 times per second, per account. A user pool can have as many as 50 tags.</p>
                                                                                         ## 
  let valid = call_402657818.validator(path, query, header, formData, body, _)
  let scheme = call_402657818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657818.makeUrl(scheme.get, call_402657818.host, call_402657818.base,
                                   call_402657818.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657818, uri, valid, _)

proc call*(call_402657819: Call_TagResource_402657806; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Assigns a set of tags to an Amazon Cognito user pool. A tag is a label that you can use to categorize and manage user pools in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>Each tag consists of a key and value, both of which you define. A key is a general category for more specific values. For example, if you have two versions of a user pool, one for testing and another for production, you might assign an <code>Environment</code> tag key to both user pools. The value of this key might be <code>Test</code> for one user pool and <code>Production</code> for the other.</p> <p>Tags are useful for cost tracking and access control. You can activate your tags so that they appear on the Billing and Cost Management console, where you can track the costs associated with your user pools. In an IAM policy, you can constrain permissions for user pools based on specific tags or tag values.</p> <p>You can use this action up to 5 times per second, per account. A user pool can have as many as 50 tags.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402657820 = newJObject()
  if body != nil:
    body_402657820 = body
  result = call_402657819.call(nil, nil, nil, nil, body_402657820)

var tagResource* = Call_TagResource_402657806(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.TagResource",
    validator: validate_TagResource_402657807, base: "/",
    makeUrl: url_TagResource_402657808, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402657821 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402657823(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_402657822(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657824 = header.getOrDefault("X-Amz-Target")
  valid_402657824 = validateParameter(valid_402657824, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UntagResource"))
  if valid_402657824 != nil:
    section.add "X-Amz-Target", valid_402657824
  var valid_402657825 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657825 = validateParameter(valid_402657825, JString,
                                      required = false, default = nil)
  if valid_402657825 != nil:
    section.add "X-Amz-Security-Token", valid_402657825
  var valid_402657826 = header.getOrDefault("X-Amz-Signature")
  valid_402657826 = validateParameter(valid_402657826, JString,
                                      required = false, default = nil)
  if valid_402657826 != nil:
    section.add "X-Amz-Signature", valid_402657826
  var valid_402657827 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657827 = validateParameter(valid_402657827, JString,
                                      required = false, default = nil)
  if valid_402657827 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657827
  var valid_402657828 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657828 = validateParameter(valid_402657828, JString,
                                      required = false, default = nil)
  if valid_402657828 != nil:
    section.add "X-Amz-Algorithm", valid_402657828
  var valid_402657829 = header.getOrDefault("X-Amz-Date")
  valid_402657829 = validateParameter(valid_402657829, JString,
                                      required = false, default = nil)
  if valid_402657829 != nil:
    section.add "X-Amz-Date", valid_402657829
  var valid_402657830 = header.getOrDefault("X-Amz-Credential")
  valid_402657830 = validateParameter(valid_402657830, JString,
                                      required = false, default = nil)
  if valid_402657830 != nil:
    section.add "X-Amz-Credential", valid_402657830
  var valid_402657831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657831 = validateParameter(valid_402657831, JString,
                                      required = false, default = nil)
  if valid_402657831 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657831
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657833: Call_UntagResource_402657821; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the specified tags from an Amazon Cognito user pool. You can use this action up to 5 times per second, per account
                                                                                         ## 
  let valid = call_402657833.validator(path, query, header, formData, body, _)
  let scheme = call_402657833.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657833.makeUrl(scheme.get, call_402657833.host, call_402657833.base,
                                   call_402657833.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657833, uri, valid, _)

proc call*(call_402657834: Call_UntagResource_402657821; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tags from an Amazon Cognito user pool. You can use this action up to 5 times per second, per account
  ##   
                                                                                                                               ## body: JObject (required)
  var body_402657835 = newJObject()
  if body != nil:
    body_402657835 = body
  result = call_402657834.call(nil, nil, nil, nil, body_402657835)

var untagResource* = Call_UntagResource_402657821(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UntagResource",
    validator: validate_UntagResource_402657822, base: "/",
    makeUrl: url_UntagResource_402657823, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthEventFeedback_402657836 = ref object of OpenApiRestCall_402656044
proc url_UpdateAuthEventFeedback_402657838(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateAuthEventFeedback_402657837(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657839 = header.getOrDefault("X-Amz-Target")
  valid_402657839 = validateParameter(valid_402657839, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateAuthEventFeedback"))
  if valid_402657839 != nil:
    section.add "X-Amz-Target", valid_402657839
  var valid_402657840 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657840 = validateParameter(valid_402657840, JString,
                                      required = false, default = nil)
  if valid_402657840 != nil:
    section.add "X-Amz-Security-Token", valid_402657840
  var valid_402657841 = header.getOrDefault("X-Amz-Signature")
  valid_402657841 = validateParameter(valid_402657841, JString,
                                      required = false, default = nil)
  if valid_402657841 != nil:
    section.add "X-Amz-Signature", valid_402657841
  var valid_402657842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657842 = validateParameter(valid_402657842, JString,
                                      required = false, default = nil)
  if valid_402657842 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657842
  var valid_402657843 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657843 = validateParameter(valid_402657843, JString,
                                      required = false, default = nil)
  if valid_402657843 != nil:
    section.add "X-Amz-Algorithm", valid_402657843
  var valid_402657844 = header.getOrDefault("X-Amz-Date")
  valid_402657844 = validateParameter(valid_402657844, JString,
                                      required = false, default = nil)
  if valid_402657844 != nil:
    section.add "X-Amz-Date", valid_402657844
  var valid_402657845 = header.getOrDefault("X-Amz-Credential")
  valid_402657845 = validateParameter(valid_402657845, JString,
                                      required = false, default = nil)
  if valid_402657845 != nil:
    section.add "X-Amz-Credential", valid_402657845
  var valid_402657846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657846 = validateParameter(valid_402657846, JString,
                                      required = false, default = nil)
  if valid_402657846 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657848: Call_UpdateAuthEventFeedback_402657836;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides the feedback for an authentication event whether it was from a valid user or not. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
                                                                                         ## 
  let valid = call_402657848.validator(path, query, header, formData, body, _)
  let scheme = call_402657848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657848.makeUrl(scheme.get, call_402657848.host, call_402657848.base,
                                   call_402657848.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657848, uri, valid, _)

proc call*(call_402657849: Call_UpdateAuthEventFeedback_402657836;
           body: JsonNode): Recallable =
  ## updateAuthEventFeedback
  ## Provides the feedback for an authentication event whether it was from a valid user or not. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ##   
                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402657850 = newJObject()
  if body != nil:
    body_402657850 = body
  result = call_402657849.call(nil, nil, nil, nil, body_402657850)

var updateAuthEventFeedback* = Call_UpdateAuthEventFeedback_402657836(
    name: "updateAuthEventFeedback", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateAuthEventFeedback",
    validator: validate_UpdateAuthEventFeedback_402657837, base: "/",
    makeUrl: url_UpdateAuthEventFeedback_402657838,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceStatus_402657851 = ref object of OpenApiRestCall_402656044
proc url_UpdateDeviceStatus_402657853(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDeviceStatus_402657852(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657854 = header.getOrDefault("X-Amz-Target")
  valid_402657854 = validateParameter(valid_402657854, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateDeviceStatus"))
  if valid_402657854 != nil:
    section.add "X-Amz-Target", valid_402657854
  var valid_402657855 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657855 = validateParameter(valid_402657855, JString,
                                      required = false, default = nil)
  if valid_402657855 != nil:
    section.add "X-Amz-Security-Token", valid_402657855
  var valid_402657856 = header.getOrDefault("X-Amz-Signature")
  valid_402657856 = validateParameter(valid_402657856, JString,
                                      required = false, default = nil)
  if valid_402657856 != nil:
    section.add "X-Amz-Signature", valid_402657856
  var valid_402657857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657857 = validateParameter(valid_402657857, JString,
                                      required = false, default = nil)
  if valid_402657857 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657857
  var valid_402657858 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657858 = validateParameter(valid_402657858, JString,
                                      required = false, default = nil)
  if valid_402657858 != nil:
    section.add "X-Amz-Algorithm", valid_402657858
  var valid_402657859 = header.getOrDefault("X-Amz-Date")
  valid_402657859 = validateParameter(valid_402657859, JString,
                                      required = false, default = nil)
  if valid_402657859 != nil:
    section.add "X-Amz-Date", valid_402657859
  var valid_402657860 = header.getOrDefault("X-Amz-Credential")
  valid_402657860 = validateParameter(valid_402657860, JString,
                                      required = false, default = nil)
  if valid_402657860 != nil:
    section.add "X-Amz-Credential", valid_402657860
  var valid_402657861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657861 = validateParameter(valid_402657861, JString,
                                      required = false, default = nil)
  if valid_402657861 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657863: Call_UpdateDeviceStatus_402657851;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the device status.
                                                                                         ## 
  let valid = call_402657863.validator(path, query, header, formData, body, _)
  let scheme = call_402657863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657863.makeUrl(scheme.get, call_402657863.host, call_402657863.base,
                                   call_402657863.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657863, uri, valid, _)

proc call*(call_402657864: Call_UpdateDeviceStatus_402657851; body: JsonNode): Recallable =
  ## updateDeviceStatus
  ## Updates the device status.
  ##   body: JObject (required)
  var body_402657865 = newJObject()
  if body != nil:
    body_402657865 = body
  result = call_402657864.call(nil, nil, nil, nil, body_402657865)

var updateDeviceStatus* = Call_UpdateDeviceStatus_402657851(
    name: "updateDeviceStatus", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateDeviceStatus",
    validator: validate_UpdateDeviceStatus_402657852, base: "/",
    makeUrl: url_UpdateDeviceStatus_402657853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_402657866 = ref object of OpenApiRestCall_402656044
proc url_UpdateGroup_402657868(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateGroup_402657867(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657869 = header.getOrDefault("X-Amz-Target")
  valid_402657869 = validateParameter(valid_402657869, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateGroup"))
  if valid_402657869 != nil:
    section.add "X-Amz-Target", valid_402657869
  var valid_402657870 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657870 = validateParameter(valid_402657870, JString,
                                      required = false, default = nil)
  if valid_402657870 != nil:
    section.add "X-Amz-Security-Token", valid_402657870
  var valid_402657871 = header.getOrDefault("X-Amz-Signature")
  valid_402657871 = validateParameter(valid_402657871, JString,
                                      required = false, default = nil)
  if valid_402657871 != nil:
    section.add "X-Amz-Signature", valid_402657871
  var valid_402657872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657872 = validateParameter(valid_402657872, JString,
                                      required = false, default = nil)
  if valid_402657872 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657872
  var valid_402657873 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657873 = validateParameter(valid_402657873, JString,
                                      required = false, default = nil)
  if valid_402657873 != nil:
    section.add "X-Amz-Algorithm", valid_402657873
  var valid_402657874 = header.getOrDefault("X-Amz-Date")
  valid_402657874 = validateParameter(valid_402657874, JString,
                                      required = false, default = nil)
  if valid_402657874 != nil:
    section.add "X-Amz-Date", valid_402657874
  var valid_402657875 = header.getOrDefault("X-Amz-Credential")
  valid_402657875 = validateParameter(valid_402657875, JString,
                                      required = false, default = nil)
  if valid_402657875 != nil:
    section.add "X-Amz-Credential", valid_402657875
  var valid_402657876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657876 = validateParameter(valid_402657876, JString,
                                      required = false, default = nil)
  if valid_402657876 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657876
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657878: Call_UpdateGroup_402657866; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the specified group with the specified attributes.</p> <p>Calling this action requires developer credentials.</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
                                                                                         ## 
  let valid = call_402657878.validator(path, query, header, formData, body, _)
  let scheme = call_402657878.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657878.makeUrl(scheme.get, call_402657878.host, call_402657878.base,
                                   call_402657878.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657878, uri, valid, _)

proc call*(call_402657879: Call_UpdateGroup_402657866; body: JsonNode): Recallable =
  ## updateGroup
  ## <p>Updates the specified group with the specified attributes.</p> <p>Calling this action requires developer credentials.</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ##   
                                                                                                                                                                                                                                                     ## body: JObject (required)
  var body_402657880 = newJObject()
  if body != nil:
    body_402657880 = body
  result = call_402657879.call(nil, nil, nil, nil, body_402657880)

var updateGroup* = Call_UpdateGroup_402657866(name: "updateGroup",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateGroup",
    validator: validate_UpdateGroup_402657867, base: "/",
    makeUrl: url_UpdateGroup_402657868, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIdentityProvider_402657881 = ref object of OpenApiRestCall_402656044
proc url_UpdateIdentityProvider_402657883(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateIdentityProvider_402657882(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657884 = header.getOrDefault("X-Amz-Target")
  valid_402657884 = validateParameter(valid_402657884, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateIdentityProvider"))
  if valid_402657884 != nil:
    section.add "X-Amz-Target", valid_402657884
  var valid_402657885 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657885 = validateParameter(valid_402657885, JString,
                                      required = false, default = nil)
  if valid_402657885 != nil:
    section.add "X-Amz-Security-Token", valid_402657885
  var valid_402657886 = header.getOrDefault("X-Amz-Signature")
  valid_402657886 = validateParameter(valid_402657886, JString,
                                      required = false, default = nil)
  if valid_402657886 != nil:
    section.add "X-Amz-Signature", valid_402657886
  var valid_402657887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657887 = validateParameter(valid_402657887, JString,
                                      required = false, default = nil)
  if valid_402657887 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657887
  var valid_402657888 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657888 = validateParameter(valid_402657888, JString,
                                      required = false, default = nil)
  if valid_402657888 != nil:
    section.add "X-Amz-Algorithm", valid_402657888
  var valid_402657889 = header.getOrDefault("X-Amz-Date")
  valid_402657889 = validateParameter(valid_402657889, JString,
                                      required = false, default = nil)
  if valid_402657889 != nil:
    section.add "X-Amz-Date", valid_402657889
  var valid_402657890 = header.getOrDefault("X-Amz-Credential")
  valid_402657890 = validateParameter(valid_402657890, JString,
                                      required = false, default = nil)
  if valid_402657890 != nil:
    section.add "X-Amz-Credential", valid_402657890
  var valid_402657891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657891 = validateParameter(valid_402657891, JString,
                                      required = false, default = nil)
  if valid_402657891 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657891
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657893: Call_UpdateIdentityProvider_402657881;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates identity provider information for a user pool.
                                                                                         ## 
  let valid = call_402657893.validator(path, query, header, formData, body, _)
  let scheme = call_402657893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657893.makeUrl(scheme.get, call_402657893.host, call_402657893.base,
                                   call_402657893.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657893, uri, valid, _)

proc call*(call_402657894: Call_UpdateIdentityProvider_402657881; body: JsonNode): Recallable =
  ## updateIdentityProvider
  ## Updates identity provider information for a user pool.
  ##   body: JObject (required)
  var body_402657895 = newJObject()
  if body != nil:
    body_402657895 = body
  result = call_402657894.call(nil, nil, nil, nil, body_402657895)

var updateIdentityProvider* = Call_UpdateIdentityProvider_402657881(
    name: "updateIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateIdentityProvider",
    validator: validate_UpdateIdentityProvider_402657882, base: "/",
    makeUrl: url_UpdateIdentityProvider_402657883,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceServer_402657896 = ref object of OpenApiRestCall_402656044
proc url_UpdateResourceServer_402657898(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateResourceServer_402657897(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657899 = header.getOrDefault("X-Amz-Target")
  valid_402657899 = validateParameter(valid_402657899, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateResourceServer"))
  if valid_402657899 != nil:
    section.add "X-Amz-Target", valid_402657899
  var valid_402657900 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657900 = validateParameter(valid_402657900, JString,
                                      required = false, default = nil)
  if valid_402657900 != nil:
    section.add "X-Amz-Security-Token", valid_402657900
  var valid_402657901 = header.getOrDefault("X-Amz-Signature")
  valid_402657901 = validateParameter(valid_402657901, JString,
                                      required = false, default = nil)
  if valid_402657901 != nil:
    section.add "X-Amz-Signature", valid_402657901
  var valid_402657902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657902 = validateParameter(valid_402657902, JString,
                                      required = false, default = nil)
  if valid_402657902 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657902
  var valid_402657903 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657903 = validateParameter(valid_402657903, JString,
                                      required = false, default = nil)
  if valid_402657903 != nil:
    section.add "X-Amz-Algorithm", valid_402657903
  var valid_402657904 = header.getOrDefault("X-Amz-Date")
  valid_402657904 = validateParameter(valid_402657904, JString,
                                      required = false, default = nil)
  if valid_402657904 != nil:
    section.add "X-Amz-Date", valid_402657904
  var valid_402657905 = header.getOrDefault("X-Amz-Credential")
  valid_402657905 = validateParameter(valid_402657905, JString,
                                      required = false, default = nil)
  if valid_402657905 != nil:
    section.add "X-Amz-Credential", valid_402657905
  var valid_402657906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657906 = validateParameter(valid_402657906, JString,
                                      required = false, default = nil)
  if valid_402657906 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657908: Call_UpdateResourceServer_402657896;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the name and scopes of resource server. All other fields are read-only.</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
                                                                                         ## 
  let valid = call_402657908.validator(path, query, header, formData, body, _)
  let scheme = call_402657908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657908.makeUrl(scheme.get, call_402657908.host, call_402657908.base,
                                   call_402657908.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657908, uri, valid, _)

proc call*(call_402657909: Call_UpdateResourceServer_402657896; body: JsonNode): Recallable =
  ## updateResourceServer
  ## <p>Updates the name and scopes of resource server. All other fields are read-only.</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ##   
                                                                                                                                                                                                               ## body: JObject (required)
  var body_402657910 = newJObject()
  if body != nil:
    body_402657910 = body
  result = call_402657909.call(nil, nil, nil, nil, body_402657910)

var updateResourceServer* = Call_UpdateResourceServer_402657896(
    name: "updateResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateResourceServer",
    validator: validate_UpdateResourceServer_402657897, base: "/",
    makeUrl: url_UpdateResourceServer_402657898,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserAttributes_402657911 = ref object of OpenApiRestCall_402656044
proc url_UpdateUserAttributes_402657913(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUserAttributes_402657912(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657914 = header.getOrDefault("X-Amz-Target")
  valid_402657914 = validateParameter(valid_402657914, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserAttributes"))
  if valid_402657914 != nil:
    section.add "X-Amz-Target", valid_402657914
  var valid_402657915 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657915 = validateParameter(valid_402657915, JString,
                                      required = false, default = nil)
  if valid_402657915 != nil:
    section.add "X-Amz-Security-Token", valid_402657915
  var valid_402657916 = header.getOrDefault("X-Amz-Signature")
  valid_402657916 = validateParameter(valid_402657916, JString,
                                      required = false, default = nil)
  if valid_402657916 != nil:
    section.add "X-Amz-Signature", valid_402657916
  var valid_402657917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657917 = validateParameter(valid_402657917, JString,
                                      required = false, default = nil)
  if valid_402657917 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657917
  var valid_402657918 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657918 = validateParameter(valid_402657918, JString,
                                      required = false, default = nil)
  if valid_402657918 != nil:
    section.add "X-Amz-Algorithm", valid_402657918
  var valid_402657919 = header.getOrDefault("X-Amz-Date")
  valid_402657919 = validateParameter(valid_402657919, JString,
                                      required = false, default = nil)
  if valid_402657919 != nil:
    section.add "X-Amz-Date", valid_402657919
  var valid_402657920 = header.getOrDefault("X-Amz-Credential")
  valid_402657920 = validateParameter(valid_402657920, JString,
                                      required = false, default = nil)
  if valid_402657920 != nil:
    section.add "X-Amz-Credential", valid_402657920
  var valid_402657921 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657921 = validateParameter(valid_402657921, JString,
                                      required = false, default = nil)
  if valid_402657921 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657921
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657923: Call_UpdateUserAttributes_402657911;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Allows a user to update a specific attribute (one at a time).
                                                                                         ## 
  let valid = call_402657923.validator(path, query, header, formData, body, _)
  let scheme = call_402657923.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657923.makeUrl(scheme.get, call_402657923.host, call_402657923.base,
                                   call_402657923.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657923, uri, valid, _)

proc call*(call_402657924: Call_UpdateUserAttributes_402657911; body: JsonNode): Recallable =
  ## updateUserAttributes
  ## Allows a user to update a specific attribute (one at a time).
  ##   body: JObject (required)
  var body_402657925 = newJObject()
  if body != nil:
    body_402657925 = body
  result = call_402657924.call(nil, nil, nil, nil, body_402657925)

var updateUserAttributes* = Call_UpdateUserAttributes_402657911(
    name: "updateUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserAttributes",
    validator: validate_UpdateUserAttributes_402657912, base: "/",
    makeUrl: url_UpdateUserAttributes_402657913,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPool_402657926 = ref object of OpenApiRestCall_402656044
proc url_UpdateUserPool_402657928(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUserPool_402657927(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657929 = header.getOrDefault("X-Amz-Target")
  valid_402657929 = validateParameter(valid_402657929, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserPool"))
  if valid_402657929 != nil:
    section.add "X-Amz-Target", valid_402657929
  var valid_402657930 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657930 = validateParameter(valid_402657930, JString,
                                      required = false, default = nil)
  if valid_402657930 != nil:
    section.add "X-Amz-Security-Token", valid_402657930
  var valid_402657931 = header.getOrDefault("X-Amz-Signature")
  valid_402657931 = validateParameter(valid_402657931, JString,
                                      required = false, default = nil)
  if valid_402657931 != nil:
    section.add "X-Amz-Signature", valid_402657931
  var valid_402657932 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657932 = validateParameter(valid_402657932, JString,
                                      required = false, default = nil)
  if valid_402657932 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657932
  var valid_402657933 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657933 = validateParameter(valid_402657933, JString,
                                      required = false, default = nil)
  if valid_402657933 != nil:
    section.add "X-Amz-Algorithm", valid_402657933
  var valid_402657934 = header.getOrDefault("X-Amz-Date")
  valid_402657934 = validateParameter(valid_402657934, JString,
                                      required = false, default = nil)
  if valid_402657934 != nil:
    section.add "X-Amz-Date", valid_402657934
  var valid_402657935 = header.getOrDefault("X-Amz-Credential")
  valid_402657935 = validateParameter(valid_402657935, JString,
                                      required = false, default = nil)
  if valid_402657935 != nil:
    section.add "X-Amz-Credential", valid_402657935
  var valid_402657936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657936 = validateParameter(valid_402657936, JString,
                                      required = false, default = nil)
  if valid_402657936 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657936
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657938: Call_UpdateUserPool_402657926; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the specified user pool with the specified attributes. You can get a list of the current user pool settings with .</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
                                                                                         ## 
  let valid = call_402657938.validator(path, query, header, formData, body, _)
  let scheme = call_402657938.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657938.makeUrl(scheme.get, call_402657938.host, call_402657938.base,
                                   call_402657938.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657938, uri, valid, _)

proc call*(call_402657939: Call_UpdateUserPool_402657926; body: JsonNode): Recallable =
  ## updateUserPool
  ## <p>Updates the specified user pool with the specified attributes. You can get a list of the current user pool settings with .</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ##   
                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402657940 = newJObject()
  if body != nil:
    body_402657940 = body
  result = call_402657939.call(nil, nil, nil, nil, body_402657940)

var updateUserPool* = Call_UpdateUserPool_402657926(name: "updateUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserPool",
    validator: validate_UpdateUserPool_402657927, base: "/",
    makeUrl: url_UpdateUserPool_402657928, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPoolClient_402657941 = ref object of OpenApiRestCall_402656044
proc url_UpdateUserPoolClient_402657943(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUserPoolClient_402657942(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657944 = header.getOrDefault("X-Amz-Target")
  valid_402657944 = validateParameter(valid_402657944, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserPoolClient"))
  if valid_402657944 != nil:
    section.add "X-Amz-Target", valid_402657944
  var valid_402657945 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657945 = validateParameter(valid_402657945, JString,
                                      required = false, default = nil)
  if valid_402657945 != nil:
    section.add "X-Amz-Security-Token", valid_402657945
  var valid_402657946 = header.getOrDefault("X-Amz-Signature")
  valid_402657946 = validateParameter(valid_402657946, JString,
                                      required = false, default = nil)
  if valid_402657946 != nil:
    section.add "X-Amz-Signature", valid_402657946
  var valid_402657947 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657947 = validateParameter(valid_402657947, JString,
                                      required = false, default = nil)
  if valid_402657947 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657947
  var valid_402657948 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657948 = validateParameter(valid_402657948, JString,
                                      required = false, default = nil)
  if valid_402657948 != nil:
    section.add "X-Amz-Algorithm", valid_402657948
  var valid_402657949 = header.getOrDefault("X-Amz-Date")
  valid_402657949 = validateParameter(valid_402657949, JString,
                                      required = false, default = nil)
  if valid_402657949 != nil:
    section.add "X-Amz-Date", valid_402657949
  var valid_402657950 = header.getOrDefault("X-Amz-Credential")
  valid_402657950 = validateParameter(valid_402657950, JString,
                                      required = false, default = nil)
  if valid_402657950 != nil:
    section.add "X-Amz-Credential", valid_402657950
  var valid_402657951 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657951 = validateParameter(valid_402657951, JString,
                                      required = false, default = nil)
  if valid_402657951 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657951
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657953: Call_UpdateUserPoolClient_402657941;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the specified user pool app client with the specified attributes. You can get a list of the current user pool app client settings with .</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
                                                                                         ## 
  let valid = call_402657953.validator(path, query, header, formData, body, _)
  let scheme = call_402657953.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657953.makeUrl(scheme.get, call_402657953.host, call_402657953.base,
                                   call_402657953.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657953, uri, valid, _)

proc call*(call_402657954: Call_UpdateUserPoolClient_402657941; body: JsonNode): Recallable =
  ## updateUserPoolClient
  ## <p>Updates the specified user pool app client with the specified attributes. You can get a list of the current user pool app client settings with .</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ##   
                                                                                                                                                                                                                                                                                ## body: JObject (required)
  var body_402657955 = newJObject()
  if body != nil:
    body_402657955 = body
  result = call_402657954.call(nil, nil, nil, nil, body_402657955)

var updateUserPoolClient* = Call_UpdateUserPoolClient_402657941(
    name: "updateUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserPoolClient",
    validator: validate_UpdateUserPoolClient_402657942, base: "/",
    makeUrl: url_UpdateUserPoolClient_402657943,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPoolDomain_402657956 = ref object of OpenApiRestCall_402656044
proc url_UpdateUserPoolDomain_402657958(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUserPoolDomain_402657957(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657959 = header.getOrDefault("X-Amz-Target")
  valid_402657959 = validateParameter(valid_402657959, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserPoolDomain"))
  if valid_402657959 != nil:
    section.add "X-Amz-Target", valid_402657959
  var valid_402657960 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657960 = validateParameter(valid_402657960, JString,
                                      required = false, default = nil)
  if valid_402657960 != nil:
    section.add "X-Amz-Security-Token", valid_402657960
  var valid_402657961 = header.getOrDefault("X-Amz-Signature")
  valid_402657961 = validateParameter(valid_402657961, JString,
                                      required = false, default = nil)
  if valid_402657961 != nil:
    section.add "X-Amz-Signature", valid_402657961
  var valid_402657962 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657962 = validateParameter(valid_402657962, JString,
                                      required = false, default = nil)
  if valid_402657962 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657962
  var valid_402657963 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657963 = validateParameter(valid_402657963, JString,
                                      required = false, default = nil)
  if valid_402657963 != nil:
    section.add "X-Amz-Algorithm", valid_402657963
  var valid_402657964 = header.getOrDefault("X-Amz-Date")
  valid_402657964 = validateParameter(valid_402657964, JString,
                                      required = false, default = nil)
  if valid_402657964 != nil:
    section.add "X-Amz-Date", valid_402657964
  var valid_402657965 = header.getOrDefault("X-Amz-Credential")
  valid_402657965 = validateParameter(valid_402657965, JString,
                                      required = false, default = nil)
  if valid_402657965 != nil:
    section.add "X-Amz-Credential", valid_402657965
  var valid_402657966 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657966 = validateParameter(valid_402657966, JString,
                                      required = false, default = nil)
  if valid_402657966 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657966
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657968: Call_UpdateUserPoolDomain_402657956;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the Secure Sockets Layer (SSL) certificate for the custom domain for your user pool.</p> <p>You can use this operation to provide the Amazon Resource Name (ARN) of a new certificate to Amazon Cognito. You cannot use it to change the domain for a user pool.</p> <p>A custom domain is used to host the Amazon Cognito hosted UI, which provides sign-up and sign-in pages for your application. When you set up a custom domain, you provide a certificate that you manage with AWS Certificate Manager (ACM). When necessary, you can use this operation to change the certificate that you applied to your custom domain.</p> <p>Usually, this is unnecessary following routine certificate renewal with ACM. When you renew your existing certificate in ACM, the ARN for your certificate remains the same, and your custom domain uses the new certificate automatically.</p> <p>However, if you replace your existing certificate with a new one, ACM gives the new certificate a new ARN. To apply the new certificate to your custom domain, you must provide this ARN to Amazon Cognito.</p> <p>When you add your new certificate in ACM, you must choose US East (N. Virginia) as the AWS Region.</p> <p>After you submit your request, Amazon Cognito requires up to 1 hour to distribute your new certificate to your custom domain.</p> <p>For more information about adding a custom domain to your user pool, see <a href="https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-add-custom-domain.html">Using Your Own Domain for the Hosted UI</a>.</p>
                                                                                         ## 
  let valid = call_402657968.validator(path, query, header, formData, body, _)
  let scheme = call_402657968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657968.makeUrl(scheme.get, call_402657968.host, call_402657968.base,
                                   call_402657968.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657968, uri, valid, _)

proc call*(call_402657969: Call_UpdateUserPoolDomain_402657956; body: JsonNode): Recallable =
  ## updateUserPoolDomain
  ## <p>Updates the Secure Sockets Layer (SSL) certificate for the custom domain for your user pool.</p> <p>You can use this operation to provide the Amazon Resource Name (ARN) of a new certificate to Amazon Cognito. You cannot use it to change the domain for a user pool.</p> <p>A custom domain is used to host the Amazon Cognito hosted UI, which provides sign-up and sign-in pages for your application. When you set up a custom domain, you provide a certificate that you manage with AWS Certificate Manager (ACM). When necessary, you can use this operation to change the certificate that you applied to your custom domain.</p> <p>Usually, this is unnecessary following routine certificate renewal with ACM. When you renew your existing certificate in ACM, the ARN for your certificate remains the same, and your custom domain uses the new certificate automatically.</p> <p>However, if you replace your existing certificate with a new one, ACM gives the new certificate a new ARN. To apply the new certificate to your custom domain, you must provide this ARN to Amazon Cognito.</p> <p>When you add your new certificate in ACM, you must choose US East (N. Virginia) as the AWS Region.</p> <p>After you submit your request, Amazon Cognito requires up to 1 hour to distribute your new certificate to your custom domain.</p> <p>For more information about adding a custom domain to your user pool, see <a href="https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-add-custom-domain.html">Using Your Own Domain for the Hosted UI</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402657970 = newJObject()
  if body != nil:
    body_402657970 = body
  result = call_402657969.call(nil, nil, nil, nil, body_402657970)

var updateUserPoolDomain* = Call_UpdateUserPoolDomain_402657956(
    name: "updateUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserPoolDomain",
    validator: validate_UpdateUserPoolDomain_402657957, base: "/",
    makeUrl: url_UpdateUserPoolDomain_402657958,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_VerifySoftwareToken_402657971 = ref object of OpenApiRestCall_402656044
proc url_VerifySoftwareToken_402657973(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_VerifySoftwareToken_402657972(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657974 = header.getOrDefault("X-Amz-Target")
  valid_402657974 = validateParameter(valid_402657974, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.VerifySoftwareToken"))
  if valid_402657974 != nil:
    section.add "X-Amz-Target", valid_402657974
  var valid_402657975 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657975 = validateParameter(valid_402657975, JString,
                                      required = false, default = nil)
  if valid_402657975 != nil:
    section.add "X-Amz-Security-Token", valid_402657975
  var valid_402657976 = header.getOrDefault("X-Amz-Signature")
  valid_402657976 = validateParameter(valid_402657976, JString,
                                      required = false, default = nil)
  if valid_402657976 != nil:
    section.add "X-Amz-Signature", valid_402657976
  var valid_402657977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657977 = validateParameter(valid_402657977, JString,
                                      required = false, default = nil)
  if valid_402657977 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657977
  var valid_402657978 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657978 = validateParameter(valid_402657978, JString,
                                      required = false, default = nil)
  if valid_402657978 != nil:
    section.add "X-Amz-Algorithm", valid_402657978
  var valid_402657979 = header.getOrDefault("X-Amz-Date")
  valid_402657979 = validateParameter(valid_402657979, JString,
                                      required = false, default = nil)
  if valid_402657979 != nil:
    section.add "X-Amz-Date", valid_402657979
  var valid_402657980 = header.getOrDefault("X-Amz-Credential")
  valid_402657980 = validateParameter(valid_402657980, JString,
                                      required = false, default = nil)
  if valid_402657980 != nil:
    section.add "X-Amz-Credential", valid_402657980
  var valid_402657981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657981 = validateParameter(valid_402657981, JString,
                                      required = false, default = nil)
  if valid_402657981 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657983: Call_VerifySoftwareToken_402657971;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Use this API to register a user's entered TOTP code and mark the user's software token MFA status as "verified" if successful. The request takes an access token or a session string, but not both.
                                                                                         ## 
  let valid = call_402657983.validator(path, query, header, formData, body, _)
  let scheme = call_402657983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657983.makeUrl(scheme.get, call_402657983.host, call_402657983.base,
                                   call_402657983.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657983, uri, valid, _)

proc call*(call_402657984: Call_VerifySoftwareToken_402657971; body: JsonNode): Recallable =
  ## verifySoftwareToken
  ## Use this API to register a user's entered TOTP code and mark the user's software token MFA status as "verified" if successful. The request takes an access token or a session string, but not both.
  ##   
                                                                                                                                                                                                        ## body: JObject (required)
  var body_402657985 = newJObject()
  if body != nil:
    body_402657985 = body
  result = call_402657984.call(nil, nil, nil, nil, body_402657985)

var verifySoftwareToken* = Call_VerifySoftwareToken_402657971(
    name: "verifySoftwareToken", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.VerifySoftwareToken",
    validator: validate_VerifySoftwareToken_402657972, base: "/",
    makeUrl: url_VerifySoftwareToken_402657973,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_VerifyUserAttribute_402657986 = ref object of OpenApiRestCall_402656044
proc url_VerifyUserAttribute_402657988(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_VerifyUserAttribute_402657987(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657989 = header.getOrDefault("X-Amz-Target")
  valid_402657989 = validateParameter(valid_402657989, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.VerifyUserAttribute"))
  if valid_402657989 != nil:
    section.add "X-Amz-Target", valid_402657989
  var valid_402657990 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657990 = validateParameter(valid_402657990, JString,
                                      required = false, default = nil)
  if valid_402657990 != nil:
    section.add "X-Amz-Security-Token", valid_402657990
  var valid_402657991 = header.getOrDefault("X-Amz-Signature")
  valid_402657991 = validateParameter(valid_402657991, JString,
                                      required = false, default = nil)
  if valid_402657991 != nil:
    section.add "X-Amz-Signature", valid_402657991
  var valid_402657992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657992 = validateParameter(valid_402657992, JString,
                                      required = false, default = nil)
  if valid_402657992 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657992
  var valid_402657993 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657993 = validateParameter(valid_402657993, JString,
                                      required = false, default = nil)
  if valid_402657993 != nil:
    section.add "X-Amz-Algorithm", valid_402657993
  var valid_402657994 = header.getOrDefault("X-Amz-Date")
  valid_402657994 = validateParameter(valid_402657994, JString,
                                      required = false, default = nil)
  if valid_402657994 != nil:
    section.add "X-Amz-Date", valid_402657994
  var valid_402657995 = header.getOrDefault("X-Amz-Credential")
  valid_402657995 = validateParameter(valid_402657995, JString,
                                      required = false, default = nil)
  if valid_402657995 != nil:
    section.add "X-Amz-Credential", valid_402657995
  var valid_402657996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657996 = validateParameter(valid_402657996, JString,
                                      required = false, default = nil)
  if valid_402657996 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657998: Call_VerifyUserAttribute_402657986;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Verifies the specified user attributes in the user pool.
                                                                                         ## 
  let valid = call_402657998.validator(path, query, header, formData, body, _)
  let scheme = call_402657998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657998.makeUrl(scheme.get, call_402657998.host, call_402657998.base,
                                   call_402657998.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657998, uri, valid, _)

proc call*(call_402657999: Call_VerifyUserAttribute_402657986; body: JsonNode): Recallable =
  ## verifyUserAttribute
  ## Verifies the specified user attributes in the user pool.
  ##   body: JObject (required)
  var body_402658000 = newJObject()
  if body != nil:
    body_402658000 = body
  result = call_402657999.call(nil, nil, nil, nil, body_402658000)

var verifyUserAttribute* = Call_VerifyUserAttribute_402657986(
    name: "verifyUserAttribute", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.VerifyUserAttribute",
    validator: validate_VerifyUserAttribute_402657987, base: "/",
    makeUrl: url_VerifyUserAttribute_402657988,
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