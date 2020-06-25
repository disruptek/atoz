
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_AddCustomAttributes_21625779 = ref object of OpenApiRestCall_21625435
proc url_AddCustomAttributes_21625781(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddCustomAttributes_21625780(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625882 = header.getOrDefault("X-Amz-Date")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "X-Amz-Date", valid_21625882
  var valid_21625883 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "X-Amz-Security-Token", valid_21625883
  var valid_21625898 = header.getOrDefault("X-Amz-Target")
  valid_21625898 = validateParameter(valid_21625898, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AddCustomAttributes"))
  if valid_21625898 != nil:
    section.add "X-Amz-Target", valid_21625898
  var valid_21625899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Algorithm", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Signature")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Signature", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Credential")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Credential", valid_21625903
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

proc call*(call_21625929: Call_AddCustomAttributes_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds additional user attributes to the user pool schema.
  ## 
  let valid = call_21625929.validator(path, query, header, formData, body, _)
  let scheme = call_21625929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625929.makeUrl(scheme.get, call_21625929.host, call_21625929.base,
                               call_21625929.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625929, uri, valid, _)

proc call*(call_21625992: Call_AddCustomAttributes_21625779; body: JsonNode): Recallable =
  ## addCustomAttributes
  ## Adds additional user attributes to the user pool schema.
  ##   body: JObject (required)
  var body_21625993 = newJObject()
  if body != nil:
    body_21625993 = body
  result = call_21625992.call(nil, nil, nil, nil, body_21625993)

var addCustomAttributes* = Call_AddCustomAttributes_21625779(
    name: "addCustomAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AddCustomAttributes",
    validator: validate_AddCustomAttributes_21625780, base: "/",
    makeUrl: url_AddCustomAttributes_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminAddUserToGroup_21626029 = ref object of OpenApiRestCall_21625435
proc url_AdminAddUserToGroup_21626031(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminAddUserToGroup_21626030(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626032 = header.getOrDefault("X-Amz-Date")
  valid_21626032 = validateParameter(valid_21626032, JString, required = false,
                                   default = nil)
  if valid_21626032 != nil:
    section.add "X-Amz-Date", valid_21626032
  var valid_21626033 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626033 = validateParameter(valid_21626033, JString, required = false,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "X-Amz-Security-Token", valid_21626033
  var valid_21626034 = header.getOrDefault("X-Amz-Target")
  valid_21626034 = validateParameter(valid_21626034, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminAddUserToGroup"))
  if valid_21626034 != nil:
    section.add "X-Amz-Target", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Algorithm", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Signature")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Signature", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Credential")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Credential", valid_21626039
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

proc call*(call_21626041: Call_AdminAddUserToGroup_21626029; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds the specified user to the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_21626041.validator(path, query, header, formData, body, _)
  let scheme = call_21626041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626041.makeUrl(scheme.get, call_21626041.host, call_21626041.base,
                               call_21626041.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626041, uri, valid, _)

proc call*(call_21626042: Call_AdminAddUserToGroup_21626029; body: JsonNode): Recallable =
  ## adminAddUserToGroup
  ## <p>Adds the specified user to the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_21626043 = newJObject()
  if body != nil:
    body_21626043 = body
  result = call_21626042.call(nil, nil, nil, nil, body_21626043)

var adminAddUserToGroup* = Call_AdminAddUserToGroup_21626029(
    name: "adminAddUserToGroup", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminAddUserToGroup",
    validator: validate_AdminAddUserToGroup_21626030, base: "/",
    makeUrl: url_AdminAddUserToGroup_21626031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminConfirmSignUp_21626044 = ref object of OpenApiRestCall_21625435
proc url_AdminConfirmSignUp_21626046(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminConfirmSignUp_21626045(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626047 = header.getOrDefault("X-Amz-Date")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Date", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Security-Token", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Target")
  valid_21626049 = validateParameter(valid_21626049, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminConfirmSignUp"))
  if valid_21626049 != nil:
    section.add "X-Amz-Target", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Algorithm", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Signature")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Signature", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Credential")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Credential", valid_21626054
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

proc call*(call_21626056: Call_AdminConfirmSignUp_21626044; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Confirms user registration as an admin without using a confirmation code. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_21626056.validator(path, query, header, formData, body, _)
  let scheme = call_21626056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626056.makeUrl(scheme.get, call_21626056.host, call_21626056.base,
                               call_21626056.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626056, uri, valid, _)

proc call*(call_21626057: Call_AdminConfirmSignUp_21626044; body: JsonNode): Recallable =
  ## adminConfirmSignUp
  ## <p>Confirms user registration as an admin without using a confirmation code. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_21626058 = newJObject()
  if body != nil:
    body_21626058 = body
  result = call_21626057.call(nil, nil, nil, nil, body_21626058)

var adminConfirmSignUp* = Call_AdminConfirmSignUp_21626044(
    name: "adminConfirmSignUp", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminConfirmSignUp",
    validator: validate_AdminConfirmSignUp_21626045, base: "/",
    makeUrl: url_AdminConfirmSignUp_21626046, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminCreateUser_21626059 = ref object of OpenApiRestCall_21625435
proc url_AdminCreateUser_21626061(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminCreateUser_21626060(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626062 = header.getOrDefault("X-Amz-Date")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Date", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Security-Token", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Target")
  valid_21626064 = validateParameter(valid_21626064, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminCreateUser"))
  if valid_21626064 != nil:
    section.add "X-Amz-Target", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Algorithm", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Signature")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Signature", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Credential")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Credential", valid_21626069
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

proc call*(call_21626071: Call_AdminCreateUser_21626059; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new user in the specified user pool.</p> <p>If <code>MessageAction</code> is not set, the default is to send a welcome message via email or phone (SMS).</p> <note> <p>This message is based on a template that you configured in your call to or . This template includes your custom sign-up instructions and placeholders for user name and temporary password.</p> </note> <p>Alternatively, you can call AdminCreateUser with “SUPPRESS” for the <code>MessageAction</code> parameter, and Amazon Cognito will not send any email. </p> <p>In either case, the user will be in the <code>FORCE_CHANGE_PASSWORD</code> state until they sign in and change their password.</p> <p>AdminCreateUser requires developer credentials.</p>
  ## 
  let valid = call_21626071.validator(path, query, header, formData, body, _)
  let scheme = call_21626071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626071.makeUrl(scheme.get, call_21626071.host, call_21626071.base,
                               call_21626071.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626071, uri, valid, _)

proc call*(call_21626072: Call_AdminCreateUser_21626059; body: JsonNode): Recallable =
  ## adminCreateUser
  ## <p>Creates a new user in the specified user pool.</p> <p>If <code>MessageAction</code> is not set, the default is to send a welcome message via email or phone (SMS).</p> <note> <p>This message is based on a template that you configured in your call to or . This template includes your custom sign-up instructions and placeholders for user name and temporary password.</p> </note> <p>Alternatively, you can call AdminCreateUser with “SUPPRESS” for the <code>MessageAction</code> parameter, and Amazon Cognito will not send any email. </p> <p>In either case, the user will be in the <code>FORCE_CHANGE_PASSWORD</code> state until they sign in and change their password.</p> <p>AdminCreateUser requires developer credentials.</p>
  ##   body: JObject (required)
  var body_21626073 = newJObject()
  if body != nil:
    body_21626073 = body
  result = call_21626072.call(nil, nil, nil, nil, body_21626073)

var adminCreateUser* = Call_AdminCreateUser_21626059(name: "adminCreateUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminCreateUser",
    validator: validate_AdminCreateUser_21626060, base: "/",
    makeUrl: url_AdminCreateUser_21626061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDeleteUser_21626074 = ref object of OpenApiRestCall_21625435
proc url_AdminDeleteUser_21626076(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminDeleteUser_21626075(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626077 = header.getOrDefault("X-Amz-Date")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Date", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Security-Token", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Target")
  valid_21626079 = validateParameter(valid_21626079, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDeleteUser"))
  if valid_21626079 != nil:
    section.add "X-Amz-Target", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Algorithm", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Signature")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Signature", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Credential")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Credential", valid_21626084
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

proc call*(call_21626086: Call_AdminDeleteUser_21626074; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a user as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_21626086.validator(path, query, header, formData, body, _)
  let scheme = call_21626086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626086.makeUrl(scheme.get, call_21626086.host, call_21626086.base,
                               call_21626086.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626086, uri, valid, _)

proc call*(call_21626087: Call_AdminDeleteUser_21626074; body: JsonNode): Recallable =
  ## adminDeleteUser
  ## <p>Deletes a user as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_21626088 = newJObject()
  if body != nil:
    body_21626088 = body
  result = call_21626087.call(nil, nil, nil, nil, body_21626088)

var adminDeleteUser* = Call_AdminDeleteUser_21626074(name: "adminDeleteUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDeleteUser",
    validator: validate_AdminDeleteUser_21626075, base: "/",
    makeUrl: url_AdminDeleteUser_21626076, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDeleteUserAttributes_21626089 = ref object of OpenApiRestCall_21625435
proc url_AdminDeleteUserAttributes_21626091(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminDeleteUserAttributes_21626090(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626092 = header.getOrDefault("X-Amz-Date")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Date", valid_21626092
  var valid_21626093 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Security-Token", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-Target")
  valid_21626094 = validateParameter(valid_21626094, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDeleteUserAttributes"))
  if valid_21626094 != nil:
    section.add "X-Amz-Target", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Algorithm", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Signature")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Signature", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Credential")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Credential", valid_21626099
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

proc call*(call_21626101: Call_AdminDeleteUserAttributes_21626089;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the user attributes in a user pool as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_21626101.validator(path, query, header, formData, body, _)
  let scheme = call_21626101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626101.makeUrl(scheme.get, call_21626101.host, call_21626101.base,
                               call_21626101.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626101, uri, valid, _)

proc call*(call_21626102: Call_AdminDeleteUserAttributes_21626089; body: JsonNode): Recallable =
  ## adminDeleteUserAttributes
  ## <p>Deletes the user attributes in a user pool as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_21626103 = newJObject()
  if body != nil:
    body_21626103 = body
  result = call_21626102.call(nil, nil, nil, nil, body_21626103)

var adminDeleteUserAttributes* = Call_AdminDeleteUserAttributes_21626089(
    name: "adminDeleteUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDeleteUserAttributes",
    validator: validate_AdminDeleteUserAttributes_21626090, base: "/",
    makeUrl: url_AdminDeleteUserAttributes_21626091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDisableProviderForUser_21626104 = ref object of OpenApiRestCall_21625435
proc url_AdminDisableProviderForUser_21626106(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminDisableProviderForUser_21626105(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626107 = header.getOrDefault("X-Amz-Date")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-Date", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Security-Token", valid_21626108
  var valid_21626109 = header.getOrDefault("X-Amz-Target")
  valid_21626109 = validateParameter(valid_21626109, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDisableProviderForUser"))
  if valid_21626109 != nil:
    section.add "X-Amz-Target", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-Algorithm", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Signature")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Signature", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Credential")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Credential", valid_21626114
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

proc call*(call_21626116: Call_AdminDisableProviderForUser_21626104;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Disables the user from signing in with the specified external (SAML or social) identity provider. If the user to disable is a Cognito User Pools native username + password user, they are not permitted to use their password to sign-in. If the user to disable is a linked external IdP user, any link between that user and an existing user is removed. The next time the external user (no longer attached to the previously linked <code>DestinationUser</code>) signs in, they must create a new user account. See .</p> <p>This action is enabled only for admin access and requires developer credentials.</p> <p>The <code>ProviderName</code> must match the value specified when creating an IdP for the pool. </p> <p>To disable a native username + password user, the <code>ProviderName</code> value must be <code>Cognito</code> and the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code>, with the <code>ProviderAttributeValue</code> being the name that is used in the user pool for the user.</p> <p>The <code>ProviderAttributeName</code> must always be <code>Cognito_Subject</code> for social identity providers. The <code>ProviderAttributeValue</code> must always be the exact subject that was used when the user was originally linked as a source user.</p> <p>For de-linking a SAML identity, there are two scenarios. If the linked identity has not yet been used to sign-in, the <code>ProviderAttributeName</code> and <code>ProviderAttributeValue</code> must be the same values that were used for the <code>SourceUser</code> when the identities were originally linked in the call. (If the linking was done with <code>ProviderAttributeName</code> set to <code>Cognito_Subject</code>, the same applies here). However, if the user has already signed in, the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code> and <code>ProviderAttributeValue</code> must be the subject of the SAML assertion.</p>
  ## 
  let valid = call_21626116.validator(path, query, header, formData, body, _)
  let scheme = call_21626116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626116.makeUrl(scheme.get, call_21626116.host, call_21626116.base,
                               call_21626116.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626116, uri, valid, _)

proc call*(call_21626117: Call_AdminDisableProviderForUser_21626104; body: JsonNode): Recallable =
  ## adminDisableProviderForUser
  ## <p>Disables the user from signing in with the specified external (SAML or social) identity provider. If the user to disable is a Cognito User Pools native username + password user, they are not permitted to use their password to sign-in. If the user to disable is a linked external IdP user, any link between that user and an existing user is removed. The next time the external user (no longer attached to the previously linked <code>DestinationUser</code>) signs in, they must create a new user account. See .</p> <p>This action is enabled only for admin access and requires developer credentials.</p> <p>The <code>ProviderName</code> must match the value specified when creating an IdP for the pool. </p> <p>To disable a native username + password user, the <code>ProviderName</code> value must be <code>Cognito</code> and the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code>, with the <code>ProviderAttributeValue</code> being the name that is used in the user pool for the user.</p> <p>The <code>ProviderAttributeName</code> must always be <code>Cognito_Subject</code> for social identity providers. The <code>ProviderAttributeValue</code> must always be the exact subject that was used when the user was originally linked as a source user.</p> <p>For de-linking a SAML identity, there are two scenarios. If the linked identity has not yet been used to sign-in, the <code>ProviderAttributeName</code> and <code>ProviderAttributeValue</code> must be the same values that were used for the <code>SourceUser</code> when the identities were originally linked in the call. (If the linking was done with <code>ProviderAttributeName</code> set to <code>Cognito_Subject</code>, the same applies here). However, if the user has already signed in, the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code> and <code>ProviderAttributeValue</code> must be the subject of the SAML assertion.</p>
  ##   body: JObject (required)
  var body_21626118 = newJObject()
  if body != nil:
    body_21626118 = body
  result = call_21626117.call(nil, nil, nil, nil, body_21626118)

var adminDisableProviderForUser* = Call_AdminDisableProviderForUser_21626104(
    name: "adminDisableProviderForUser", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDisableProviderForUser",
    validator: validate_AdminDisableProviderForUser_21626105, base: "/",
    makeUrl: url_AdminDisableProviderForUser_21626106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDisableUser_21626119 = ref object of OpenApiRestCall_21625435
proc url_AdminDisableUser_21626121(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminDisableUser_21626120(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626122 = header.getOrDefault("X-Amz-Date")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Date", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Security-Token", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Target")
  valid_21626124 = validateParameter(valid_21626124, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDisableUser"))
  if valid_21626124 != nil:
    section.add "X-Amz-Target", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-Algorithm", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-Signature")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Signature", valid_21626127
  var valid_21626128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-Credential")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Credential", valid_21626129
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

proc call*(call_21626131: Call_AdminDisableUser_21626119; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Disables the specified user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_21626131.validator(path, query, header, formData, body, _)
  let scheme = call_21626131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626131.makeUrl(scheme.get, call_21626131.host, call_21626131.base,
                               call_21626131.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626131, uri, valid, _)

proc call*(call_21626132: Call_AdminDisableUser_21626119; body: JsonNode): Recallable =
  ## adminDisableUser
  ## <p>Disables the specified user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_21626133 = newJObject()
  if body != nil:
    body_21626133 = body
  result = call_21626132.call(nil, nil, nil, nil, body_21626133)

var adminDisableUser* = Call_AdminDisableUser_21626119(name: "adminDisableUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDisableUser",
    validator: validate_AdminDisableUser_21626120, base: "/",
    makeUrl: url_AdminDisableUser_21626121, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminEnableUser_21626134 = ref object of OpenApiRestCall_21625435
proc url_AdminEnableUser_21626136(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminEnableUser_21626135(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626137 = header.getOrDefault("X-Amz-Date")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Date", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Security-Token", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-Target")
  valid_21626139 = validateParameter(valid_21626139, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminEnableUser"))
  if valid_21626139 != nil:
    section.add "X-Amz-Target", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-Algorithm", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-Signature")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Signature", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-Credential")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Credential", valid_21626144
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

proc call*(call_21626146: Call_AdminEnableUser_21626134; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Enables the specified user as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_21626146.validator(path, query, header, formData, body, _)
  let scheme = call_21626146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626146.makeUrl(scheme.get, call_21626146.host, call_21626146.base,
                               call_21626146.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626146, uri, valid, _)

proc call*(call_21626147: Call_AdminEnableUser_21626134; body: JsonNode): Recallable =
  ## adminEnableUser
  ## <p>Enables the specified user as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_21626148 = newJObject()
  if body != nil:
    body_21626148 = body
  result = call_21626147.call(nil, nil, nil, nil, body_21626148)

var adminEnableUser* = Call_AdminEnableUser_21626134(name: "adminEnableUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminEnableUser",
    validator: validate_AdminEnableUser_21626135, base: "/",
    makeUrl: url_AdminEnableUser_21626136, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminForgetDevice_21626149 = ref object of OpenApiRestCall_21625435
proc url_AdminForgetDevice_21626151(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminForgetDevice_21626150(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626152 = header.getOrDefault("X-Amz-Date")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Date", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Security-Token", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Target")
  valid_21626154 = validateParameter(valid_21626154, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminForgetDevice"))
  if valid_21626154 != nil:
    section.add "X-Amz-Target", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-Algorithm", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-Signature")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Signature", valid_21626157
  var valid_21626158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626158
  var valid_21626159 = header.getOrDefault("X-Amz-Credential")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "X-Amz-Credential", valid_21626159
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

proc call*(call_21626161: Call_AdminForgetDevice_21626149; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Forgets the device, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_21626161.validator(path, query, header, formData, body, _)
  let scheme = call_21626161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626161.makeUrl(scheme.get, call_21626161.host, call_21626161.base,
                               call_21626161.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626161, uri, valid, _)

proc call*(call_21626162: Call_AdminForgetDevice_21626149; body: JsonNode): Recallable =
  ## adminForgetDevice
  ## <p>Forgets the device, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_21626163 = newJObject()
  if body != nil:
    body_21626163 = body
  result = call_21626162.call(nil, nil, nil, nil, body_21626163)

var adminForgetDevice* = Call_AdminForgetDevice_21626149(name: "adminForgetDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminForgetDevice",
    validator: validate_AdminForgetDevice_21626150, base: "/",
    makeUrl: url_AdminForgetDevice_21626151, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminGetDevice_21626164 = ref object of OpenApiRestCall_21625435
proc url_AdminGetDevice_21626166(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminGetDevice_21626165(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626167 = header.getOrDefault("X-Amz-Date")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-Date", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Security-Token", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Target")
  valid_21626169 = validateParameter(valid_21626169, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminGetDevice"))
  if valid_21626169 != nil:
    section.add "X-Amz-Target", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Algorithm", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-Signature")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-Signature", valid_21626172
  var valid_21626173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626173
  var valid_21626174 = header.getOrDefault("X-Amz-Credential")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Credential", valid_21626174
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

proc call*(call_21626176: Call_AdminGetDevice_21626164; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets the device, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_21626176.validator(path, query, header, formData, body, _)
  let scheme = call_21626176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626176.makeUrl(scheme.get, call_21626176.host, call_21626176.base,
                               call_21626176.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626176, uri, valid, _)

proc call*(call_21626177: Call_AdminGetDevice_21626164; body: JsonNode): Recallable =
  ## adminGetDevice
  ## <p>Gets the device, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_21626178 = newJObject()
  if body != nil:
    body_21626178 = body
  result = call_21626177.call(nil, nil, nil, nil, body_21626178)

var adminGetDevice* = Call_AdminGetDevice_21626164(name: "adminGetDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminGetDevice",
    validator: validate_AdminGetDevice_21626165, base: "/",
    makeUrl: url_AdminGetDevice_21626166, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminGetUser_21626179 = ref object of OpenApiRestCall_21625435
proc url_AdminGetUser_21626181(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminGetUser_21626180(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626182 = header.getOrDefault("X-Amz-Date")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Date", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Security-Token", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Target")
  valid_21626184 = validateParameter(valid_21626184, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminGetUser"))
  if valid_21626184 != nil:
    section.add "X-Amz-Target", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Algorithm", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Signature")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Signature", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-Credential")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-Credential", valid_21626189
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

proc call*(call_21626191: Call_AdminGetUser_21626179; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets the specified user by user name in a user pool as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_21626191.validator(path, query, header, formData, body, _)
  let scheme = call_21626191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626191.makeUrl(scheme.get, call_21626191.host, call_21626191.base,
                               call_21626191.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626191, uri, valid, _)

proc call*(call_21626192: Call_AdminGetUser_21626179; body: JsonNode): Recallable =
  ## adminGetUser
  ## <p>Gets the specified user by user name in a user pool as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_21626193 = newJObject()
  if body != nil:
    body_21626193 = body
  result = call_21626192.call(nil, nil, nil, nil, body_21626193)

var adminGetUser* = Call_AdminGetUser_21626179(name: "adminGetUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminGetUser",
    validator: validate_AdminGetUser_21626180, base: "/", makeUrl: url_AdminGetUser_21626181,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminInitiateAuth_21626194 = ref object of OpenApiRestCall_21625435
proc url_AdminInitiateAuth_21626196(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminInitiateAuth_21626195(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626197 = header.getOrDefault("X-Amz-Date")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Date", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Security-Token", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Target")
  valid_21626199 = validateParameter(valid_21626199, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminInitiateAuth"))
  if valid_21626199 != nil:
    section.add "X-Amz-Target", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-Algorithm", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Signature")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Signature", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626203
  var valid_21626204 = header.getOrDefault("X-Amz-Credential")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Credential", valid_21626204
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

proc call*(call_21626206: Call_AdminInitiateAuth_21626194; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Initiates the authentication flow, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_21626206.validator(path, query, header, formData, body, _)
  let scheme = call_21626206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626206.makeUrl(scheme.get, call_21626206.host, call_21626206.base,
                               call_21626206.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626206, uri, valid, _)

proc call*(call_21626207: Call_AdminInitiateAuth_21626194; body: JsonNode): Recallable =
  ## adminInitiateAuth
  ## <p>Initiates the authentication flow, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_21626208 = newJObject()
  if body != nil:
    body_21626208 = body
  result = call_21626207.call(nil, nil, nil, nil, body_21626208)

var adminInitiateAuth* = Call_AdminInitiateAuth_21626194(name: "adminInitiateAuth",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminInitiateAuth",
    validator: validate_AdminInitiateAuth_21626195, base: "/",
    makeUrl: url_AdminInitiateAuth_21626196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminLinkProviderForUser_21626209 = ref object of OpenApiRestCall_21625435
proc url_AdminLinkProviderForUser_21626211(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminLinkProviderForUser_21626210(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626212 = header.getOrDefault("X-Amz-Date")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Date", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Security-Token", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Target")
  valid_21626214 = validateParameter(valid_21626214, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminLinkProviderForUser"))
  if valid_21626214 != nil:
    section.add "X-Amz-Target", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Algorithm", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Signature")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Signature", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Credential")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Credential", valid_21626219
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

proc call*(call_21626221: Call_AdminLinkProviderForUser_21626209;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Links an existing user account in a user pool (<code>DestinationUser</code>) to an identity from an external identity provider (<code>SourceUser</code>) based on a specified attribute name and value from the external identity provider. This allows you to create a link from the existing user account to an external federated user identity that has not yet been used to sign in, so that the federated user identity can be used to sign in as the existing user account. </p> <p> For example, if there is an existing user with a username and password, this API links that user to a federated user identity, so that when the federated user identity is used, the user signs in as the existing user account. </p> <important> <p>Because this API allows a user with an external federated identity to sign in as an existing user in the user pool, it is critical that it only be used with external identity providers and provider attributes that have been trusted by the application owner.</p> </important> <p>See also .</p> <p>This action is enabled only for admin access and requires developer credentials.</p>
  ## 
  let valid = call_21626221.validator(path, query, header, formData, body, _)
  let scheme = call_21626221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626221.makeUrl(scheme.get, call_21626221.host, call_21626221.base,
                               call_21626221.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626221, uri, valid, _)

proc call*(call_21626222: Call_AdminLinkProviderForUser_21626209; body: JsonNode): Recallable =
  ## adminLinkProviderForUser
  ## <p>Links an existing user account in a user pool (<code>DestinationUser</code>) to an identity from an external identity provider (<code>SourceUser</code>) based on a specified attribute name and value from the external identity provider. This allows you to create a link from the existing user account to an external federated user identity that has not yet been used to sign in, so that the federated user identity can be used to sign in as the existing user account. </p> <p> For example, if there is an existing user with a username and password, this API links that user to a federated user identity, so that when the federated user identity is used, the user signs in as the existing user account. </p> <important> <p>Because this API allows a user with an external federated identity to sign in as an existing user in the user pool, it is critical that it only be used with external identity providers and provider attributes that have been trusted by the application owner.</p> </important> <p>See also .</p> <p>This action is enabled only for admin access and requires developer credentials.</p>
  ##   body: JObject (required)
  var body_21626223 = newJObject()
  if body != nil:
    body_21626223 = body
  result = call_21626222.call(nil, nil, nil, nil, body_21626223)

var adminLinkProviderForUser* = Call_AdminLinkProviderForUser_21626209(
    name: "adminLinkProviderForUser", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminLinkProviderForUser",
    validator: validate_AdminLinkProviderForUser_21626210, base: "/",
    makeUrl: url_AdminLinkProviderForUser_21626211,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminListDevices_21626224 = ref object of OpenApiRestCall_21625435
proc url_AdminListDevices_21626226(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminListDevices_21626225(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626227 = header.getOrDefault("X-Amz-Date")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-Date", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Security-Token", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Target")
  valid_21626229 = validateParameter(valid_21626229, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminListDevices"))
  if valid_21626229 != nil:
    section.add "X-Amz-Target", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Algorithm", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Signature")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Signature", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Credential")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Credential", valid_21626234
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

proc call*(call_21626236: Call_AdminListDevices_21626224; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists devices, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_21626236.validator(path, query, header, formData, body, _)
  let scheme = call_21626236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626236.makeUrl(scheme.get, call_21626236.host, call_21626236.base,
                               call_21626236.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626236, uri, valid, _)

proc call*(call_21626237: Call_AdminListDevices_21626224; body: JsonNode): Recallable =
  ## adminListDevices
  ## <p>Lists devices, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_21626238 = newJObject()
  if body != nil:
    body_21626238 = body
  result = call_21626237.call(nil, nil, nil, nil, body_21626238)

var adminListDevices* = Call_AdminListDevices_21626224(name: "adminListDevices",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminListDevices",
    validator: validate_AdminListDevices_21626225, base: "/",
    makeUrl: url_AdminListDevices_21626226, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminListGroupsForUser_21626239 = ref object of OpenApiRestCall_21625435
proc url_AdminListGroupsForUser_21626241(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminListGroupsForUser_21626240(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626242 = query.getOrDefault("Limit")
  valid_21626242 = validateParameter(valid_21626242, JString, required = false,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "Limit", valid_21626242
  var valid_21626243 = query.getOrDefault("NextToken")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "NextToken", valid_21626243
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626244 = header.getOrDefault("X-Amz-Date")
  valid_21626244 = validateParameter(valid_21626244, JString, required = false,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "X-Amz-Date", valid_21626244
  var valid_21626245 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Security-Token", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Target")
  valid_21626246 = validateParameter(valid_21626246, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminListGroupsForUser"))
  if valid_21626246 != nil:
    section.add "X-Amz-Target", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-Algorithm", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Signature")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Signature", valid_21626249
  var valid_21626250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626250
  var valid_21626251 = header.getOrDefault("X-Amz-Credential")
  valid_21626251 = validateParameter(valid_21626251, JString, required = false,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "X-Amz-Credential", valid_21626251
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

proc call*(call_21626253: Call_AdminListGroupsForUser_21626239;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists the groups that the user belongs to.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_21626253.validator(path, query, header, formData, body, _)
  let scheme = call_21626253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626253.makeUrl(scheme.get, call_21626253.host, call_21626253.base,
                               call_21626253.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626253, uri, valid, _)

proc call*(call_21626254: Call_AdminListGroupsForUser_21626239; body: JsonNode;
          Limit: string = ""; NextToken: string = ""): Recallable =
  ## adminListGroupsForUser
  ## <p>Lists the groups that the user belongs to.</p> <p>Calling this action requires developer credentials.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626256 = newJObject()
  var body_21626257 = newJObject()
  add(query_21626256, "Limit", newJString(Limit))
  add(query_21626256, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626257 = body
  result = call_21626254.call(nil, query_21626256, nil, nil, body_21626257)

var adminListGroupsForUser* = Call_AdminListGroupsForUser_21626239(
    name: "adminListGroupsForUser", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminListGroupsForUser",
    validator: validate_AdminListGroupsForUser_21626240, base: "/",
    makeUrl: url_AdminListGroupsForUser_21626241,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminListUserAuthEvents_21626261 = ref object of OpenApiRestCall_21625435
proc url_AdminListUserAuthEvents_21626263(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminListUserAuthEvents_21626262(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626264 = query.getOrDefault("NextToken")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "NextToken", valid_21626264
  var valid_21626265 = query.getOrDefault("MaxResults")
  valid_21626265 = validateParameter(valid_21626265, JString, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "MaxResults", valid_21626265
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626266 = header.getOrDefault("X-Amz-Date")
  valid_21626266 = validateParameter(valid_21626266, JString, required = false,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "X-Amz-Date", valid_21626266
  var valid_21626267 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626267 = validateParameter(valid_21626267, JString, required = false,
                                   default = nil)
  if valid_21626267 != nil:
    section.add "X-Amz-Security-Token", valid_21626267
  var valid_21626268 = header.getOrDefault("X-Amz-Target")
  valid_21626268 = validateParameter(valid_21626268, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminListUserAuthEvents"))
  if valid_21626268 != nil:
    section.add "X-Amz-Target", valid_21626268
  var valid_21626269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626269 = validateParameter(valid_21626269, JString, required = false,
                                   default = nil)
  if valid_21626269 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626269
  var valid_21626270 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626270 = validateParameter(valid_21626270, JString, required = false,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "X-Amz-Algorithm", valid_21626270
  var valid_21626271 = header.getOrDefault("X-Amz-Signature")
  valid_21626271 = validateParameter(valid_21626271, JString, required = false,
                                   default = nil)
  if valid_21626271 != nil:
    section.add "X-Amz-Signature", valid_21626271
  var valid_21626272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626272
  var valid_21626273 = header.getOrDefault("X-Amz-Credential")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-Credential", valid_21626273
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

proc call*(call_21626275: Call_AdminListUserAuthEvents_21626261;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists a history of user activity and any risks detected as part of Amazon Cognito advanced security.
  ## 
  let valid = call_21626275.validator(path, query, header, formData, body, _)
  let scheme = call_21626275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626275.makeUrl(scheme.get, call_21626275.host, call_21626275.base,
                               call_21626275.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626275, uri, valid, _)

proc call*(call_21626276: Call_AdminListUserAuthEvents_21626261; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## adminListUserAuthEvents
  ## Lists a history of user activity and any risks detected as part of Amazon Cognito advanced security.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626277 = newJObject()
  var body_21626278 = newJObject()
  add(query_21626277, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626278 = body
  add(query_21626277, "MaxResults", newJString(MaxResults))
  result = call_21626276.call(nil, query_21626277, nil, nil, body_21626278)

var adminListUserAuthEvents* = Call_AdminListUserAuthEvents_21626261(
    name: "adminListUserAuthEvents", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminListUserAuthEvents",
    validator: validate_AdminListUserAuthEvents_21626262, base: "/",
    makeUrl: url_AdminListUserAuthEvents_21626263,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminRemoveUserFromGroup_21626279 = ref object of OpenApiRestCall_21625435
proc url_AdminRemoveUserFromGroup_21626281(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminRemoveUserFromGroup_21626280(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626282 = header.getOrDefault("X-Amz-Date")
  valid_21626282 = validateParameter(valid_21626282, JString, required = false,
                                   default = nil)
  if valid_21626282 != nil:
    section.add "X-Amz-Date", valid_21626282
  var valid_21626283 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626283 = validateParameter(valid_21626283, JString, required = false,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "X-Amz-Security-Token", valid_21626283
  var valid_21626284 = header.getOrDefault("X-Amz-Target")
  valid_21626284 = validateParameter(valid_21626284, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminRemoveUserFromGroup"))
  if valid_21626284 != nil:
    section.add "X-Amz-Target", valid_21626284
  var valid_21626285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626285 = validateParameter(valid_21626285, JString, required = false,
                                   default = nil)
  if valid_21626285 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626285
  var valid_21626286 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626286 = validateParameter(valid_21626286, JString, required = false,
                                   default = nil)
  if valid_21626286 != nil:
    section.add "X-Amz-Algorithm", valid_21626286
  var valid_21626287 = header.getOrDefault("X-Amz-Signature")
  valid_21626287 = validateParameter(valid_21626287, JString, required = false,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "X-Amz-Signature", valid_21626287
  var valid_21626288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626288 = validateParameter(valid_21626288, JString, required = false,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626288
  var valid_21626289 = header.getOrDefault("X-Amz-Credential")
  valid_21626289 = validateParameter(valid_21626289, JString, required = false,
                                   default = nil)
  if valid_21626289 != nil:
    section.add "X-Amz-Credential", valid_21626289
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

proc call*(call_21626291: Call_AdminRemoveUserFromGroup_21626279;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Removes the specified user from the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_21626291.validator(path, query, header, formData, body, _)
  let scheme = call_21626291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626291.makeUrl(scheme.get, call_21626291.host, call_21626291.base,
                               call_21626291.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626291, uri, valid, _)

proc call*(call_21626292: Call_AdminRemoveUserFromGroup_21626279; body: JsonNode): Recallable =
  ## adminRemoveUserFromGroup
  ## <p>Removes the specified user from the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_21626293 = newJObject()
  if body != nil:
    body_21626293 = body
  result = call_21626292.call(nil, nil, nil, nil, body_21626293)

var adminRemoveUserFromGroup* = Call_AdminRemoveUserFromGroup_21626279(
    name: "adminRemoveUserFromGroup", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminRemoveUserFromGroup",
    validator: validate_AdminRemoveUserFromGroup_21626280, base: "/",
    makeUrl: url_AdminRemoveUserFromGroup_21626281,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminResetUserPassword_21626294 = ref object of OpenApiRestCall_21625435
proc url_AdminResetUserPassword_21626296(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminResetUserPassword_21626295(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626297 = header.getOrDefault("X-Amz-Date")
  valid_21626297 = validateParameter(valid_21626297, JString, required = false,
                                   default = nil)
  if valid_21626297 != nil:
    section.add "X-Amz-Date", valid_21626297
  var valid_21626298 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626298 = validateParameter(valid_21626298, JString, required = false,
                                   default = nil)
  if valid_21626298 != nil:
    section.add "X-Amz-Security-Token", valid_21626298
  var valid_21626299 = header.getOrDefault("X-Amz-Target")
  valid_21626299 = validateParameter(valid_21626299, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminResetUserPassword"))
  if valid_21626299 != nil:
    section.add "X-Amz-Target", valid_21626299
  var valid_21626300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626300 = validateParameter(valid_21626300, JString, required = false,
                                   default = nil)
  if valid_21626300 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626300
  var valid_21626301 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626301 = validateParameter(valid_21626301, JString, required = false,
                                   default = nil)
  if valid_21626301 != nil:
    section.add "X-Amz-Algorithm", valid_21626301
  var valid_21626302 = header.getOrDefault("X-Amz-Signature")
  valid_21626302 = validateParameter(valid_21626302, JString, required = false,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "X-Amz-Signature", valid_21626302
  var valid_21626303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626303
  var valid_21626304 = header.getOrDefault("X-Amz-Credential")
  valid_21626304 = validateParameter(valid_21626304, JString, required = false,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "X-Amz-Credential", valid_21626304
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

proc call*(call_21626306: Call_AdminResetUserPassword_21626294;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Resets the specified user's password in a user pool as an administrator. Works on any user.</p> <p>When a developer calls this API, the current password is invalidated, so it must be changed. If a user tries to sign in after the API is called, the app will get a PasswordResetRequiredException exception back and should direct the user down the flow to reset the password, which is the same as the forgot password flow. In addition, if the user pool has phone verification selected and a verified phone number exists for the user, or if email verification is selected and a verified email exists for the user, calling this API will also result in sending a message to the end user with the code to change their password.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_21626306.validator(path, query, header, formData, body, _)
  let scheme = call_21626306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626306.makeUrl(scheme.get, call_21626306.host, call_21626306.base,
                               call_21626306.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626306, uri, valid, _)

proc call*(call_21626307: Call_AdminResetUserPassword_21626294; body: JsonNode): Recallable =
  ## adminResetUserPassword
  ## <p>Resets the specified user's password in a user pool as an administrator. Works on any user.</p> <p>When a developer calls this API, the current password is invalidated, so it must be changed. If a user tries to sign in after the API is called, the app will get a PasswordResetRequiredException exception back and should direct the user down the flow to reset the password, which is the same as the forgot password flow. In addition, if the user pool has phone verification selected and a verified phone number exists for the user, or if email verification is selected and a verified email exists for the user, calling this API will also result in sending a message to the end user with the code to change their password.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_21626308 = newJObject()
  if body != nil:
    body_21626308 = body
  result = call_21626307.call(nil, nil, nil, nil, body_21626308)

var adminResetUserPassword* = Call_AdminResetUserPassword_21626294(
    name: "adminResetUserPassword", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminResetUserPassword",
    validator: validate_AdminResetUserPassword_21626295, base: "/",
    makeUrl: url_AdminResetUserPassword_21626296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminRespondToAuthChallenge_21626309 = ref object of OpenApiRestCall_21625435
proc url_AdminRespondToAuthChallenge_21626311(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminRespondToAuthChallenge_21626310(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626312 = header.getOrDefault("X-Amz-Date")
  valid_21626312 = validateParameter(valid_21626312, JString, required = false,
                                   default = nil)
  if valid_21626312 != nil:
    section.add "X-Amz-Date", valid_21626312
  var valid_21626313 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626313 = validateParameter(valid_21626313, JString, required = false,
                                   default = nil)
  if valid_21626313 != nil:
    section.add "X-Amz-Security-Token", valid_21626313
  var valid_21626314 = header.getOrDefault("X-Amz-Target")
  valid_21626314 = validateParameter(valid_21626314, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminRespondToAuthChallenge"))
  if valid_21626314 != nil:
    section.add "X-Amz-Target", valid_21626314
  var valid_21626315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626315 = validateParameter(valid_21626315, JString, required = false,
                                   default = nil)
  if valid_21626315 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626315
  var valid_21626316 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626316 = validateParameter(valid_21626316, JString, required = false,
                                   default = nil)
  if valid_21626316 != nil:
    section.add "X-Amz-Algorithm", valid_21626316
  var valid_21626317 = header.getOrDefault("X-Amz-Signature")
  valid_21626317 = validateParameter(valid_21626317, JString, required = false,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "X-Amz-Signature", valid_21626317
  var valid_21626318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Credential")
  valid_21626319 = validateParameter(valid_21626319, JString, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "X-Amz-Credential", valid_21626319
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

proc call*(call_21626321: Call_AdminRespondToAuthChallenge_21626309;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Responds to an authentication challenge, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_21626321.validator(path, query, header, formData, body, _)
  let scheme = call_21626321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626321.makeUrl(scheme.get, call_21626321.host, call_21626321.base,
                               call_21626321.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626321, uri, valid, _)

proc call*(call_21626322: Call_AdminRespondToAuthChallenge_21626309; body: JsonNode): Recallable =
  ## adminRespondToAuthChallenge
  ## <p>Responds to an authentication challenge, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_21626323 = newJObject()
  if body != nil:
    body_21626323 = body
  result = call_21626322.call(nil, nil, nil, nil, body_21626323)

var adminRespondToAuthChallenge* = Call_AdminRespondToAuthChallenge_21626309(
    name: "adminRespondToAuthChallenge", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminRespondToAuthChallenge",
    validator: validate_AdminRespondToAuthChallenge_21626310, base: "/",
    makeUrl: url_AdminRespondToAuthChallenge_21626311,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminSetUserMFAPreference_21626324 = ref object of OpenApiRestCall_21625435
proc url_AdminSetUserMFAPreference_21626326(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminSetUserMFAPreference_21626325(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626327 = header.getOrDefault("X-Amz-Date")
  valid_21626327 = validateParameter(valid_21626327, JString, required = false,
                                   default = nil)
  if valid_21626327 != nil:
    section.add "X-Amz-Date", valid_21626327
  var valid_21626328 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626328 = validateParameter(valid_21626328, JString, required = false,
                                   default = nil)
  if valid_21626328 != nil:
    section.add "X-Amz-Security-Token", valid_21626328
  var valid_21626329 = header.getOrDefault("X-Amz-Target")
  valid_21626329 = validateParameter(valid_21626329, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminSetUserMFAPreference"))
  if valid_21626329 != nil:
    section.add "X-Amz-Target", valid_21626329
  var valid_21626330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626330 = validateParameter(valid_21626330, JString, required = false,
                                   default = nil)
  if valid_21626330 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626330
  var valid_21626331 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626331 = validateParameter(valid_21626331, JString, required = false,
                                   default = nil)
  if valid_21626331 != nil:
    section.add "X-Amz-Algorithm", valid_21626331
  var valid_21626332 = header.getOrDefault("X-Amz-Signature")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "X-Amz-Signature", valid_21626332
  var valid_21626333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626333
  var valid_21626334 = header.getOrDefault("X-Amz-Credential")
  valid_21626334 = validateParameter(valid_21626334, JString, required = false,
                                   default = nil)
  if valid_21626334 != nil:
    section.add "X-Amz-Credential", valid_21626334
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

proc call*(call_21626336: Call_AdminSetUserMFAPreference_21626324;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Sets the user's multi-factor authentication (MFA) preference, including which MFA options are enabled and if any are preferred. Only one factor can be set as preferred. The preferred MFA factor will be used to authenticate a user if multiple factors are enabled. If multiple options are enabled and no preference is set, a challenge to choose an MFA option will be returned during sign in.
  ## 
  let valid = call_21626336.validator(path, query, header, formData, body, _)
  let scheme = call_21626336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626336.makeUrl(scheme.get, call_21626336.host, call_21626336.base,
                               call_21626336.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626336, uri, valid, _)

proc call*(call_21626337: Call_AdminSetUserMFAPreference_21626324; body: JsonNode): Recallable =
  ## adminSetUserMFAPreference
  ## Sets the user's multi-factor authentication (MFA) preference, including which MFA options are enabled and if any are preferred. Only one factor can be set as preferred. The preferred MFA factor will be used to authenticate a user if multiple factors are enabled. If multiple options are enabled and no preference is set, a challenge to choose an MFA option will be returned during sign in.
  ##   body: JObject (required)
  var body_21626338 = newJObject()
  if body != nil:
    body_21626338 = body
  result = call_21626337.call(nil, nil, nil, nil, body_21626338)

var adminSetUserMFAPreference* = Call_AdminSetUserMFAPreference_21626324(
    name: "adminSetUserMFAPreference", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminSetUserMFAPreference",
    validator: validate_AdminSetUserMFAPreference_21626325, base: "/",
    makeUrl: url_AdminSetUserMFAPreference_21626326,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminSetUserPassword_21626339 = ref object of OpenApiRestCall_21625435
proc url_AdminSetUserPassword_21626341(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminSetUserPassword_21626340(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626342 = header.getOrDefault("X-Amz-Date")
  valid_21626342 = validateParameter(valid_21626342, JString, required = false,
                                   default = nil)
  if valid_21626342 != nil:
    section.add "X-Amz-Date", valid_21626342
  var valid_21626343 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626343 = validateParameter(valid_21626343, JString, required = false,
                                   default = nil)
  if valid_21626343 != nil:
    section.add "X-Amz-Security-Token", valid_21626343
  var valid_21626344 = header.getOrDefault("X-Amz-Target")
  valid_21626344 = validateParameter(valid_21626344, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminSetUserPassword"))
  if valid_21626344 != nil:
    section.add "X-Amz-Target", valid_21626344
  var valid_21626345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626345 = validateParameter(valid_21626345, JString, required = false,
                                   default = nil)
  if valid_21626345 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626345
  var valid_21626346 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626346 = validateParameter(valid_21626346, JString, required = false,
                                   default = nil)
  if valid_21626346 != nil:
    section.add "X-Amz-Algorithm", valid_21626346
  var valid_21626347 = header.getOrDefault("X-Amz-Signature")
  valid_21626347 = validateParameter(valid_21626347, JString, required = false,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "X-Amz-Signature", valid_21626347
  var valid_21626348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626348
  var valid_21626349 = header.getOrDefault("X-Amz-Credential")
  valid_21626349 = validateParameter(valid_21626349, JString, required = false,
                                   default = nil)
  if valid_21626349 != nil:
    section.add "X-Amz-Credential", valid_21626349
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

proc call*(call_21626351: Call_AdminSetUserPassword_21626339; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sets the specified user's password in a user pool as an administrator. Works on any user. </p> <p>The password can be temporary or permanent. If it is temporary, the user status will be placed into the <code>FORCE_CHANGE_PASSWORD</code> state. When the user next tries to sign in, the InitiateAuth/AdminInitiateAuth response will contain the <code>NEW_PASSWORD_REQUIRED</code> challenge. If the user does not sign in before it expires, the user will not be able to sign in and their password will need to be reset by an administrator. </p> <p>Once the user has set a new password, or the password is permanent, the user status will be set to <code>Confirmed</code>.</p>
  ## 
  let valid = call_21626351.validator(path, query, header, formData, body, _)
  let scheme = call_21626351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626351.makeUrl(scheme.get, call_21626351.host, call_21626351.base,
                               call_21626351.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626351, uri, valid, _)

proc call*(call_21626352: Call_AdminSetUserPassword_21626339; body: JsonNode): Recallable =
  ## adminSetUserPassword
  ## <p>Sets the specified user's password in a user pool as an administrator. Works on any user. </p> <p>The password can be temporary or permanent. If it is temporary, the user status will be placed into the <code>FORCE_CHANGE_PASSWORD</code> state. When the user next tries to sign in, the InitiateAuth/AdminInitiateAuth response will contain the <code>NEW_PASSWORD_REQUIRED</code> challenge. If the user does not sign in before it expires, the user will not be able to sign in and their password will need to be reset by an administrator. </p> <p>Once the user has set a new password, or the password is permanent, the user status will be set to <code>Confirmed</code>.</p>
  ##   body: JObject (required)
  var body_21626353 = newJObject()
  if body != nil:
    body_21626353 = body
  result = call_21626352.call(nil, nil, nil, nil, body_21626353)

var adminSetUserPassword* = Call_AdminSetUserPassword_21626339(
    name: "adminSetUserPassword", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminSetUserPassword",
    validator: validate_AdminSetUserPassword_21626340, base: "/",
    makeUrl: url_AdminSetUserPassword_21626341,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminSetUserSettings_21626354 = ref object of OpenApiRestCall_21625435
proc url_AdminSetUserSettings_21626356(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminSetUserSettings_21626355(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626357 = header.getOrDefault("X-Amz-Date")
  valid_21626357 = validateParameter(valid_21626357, JString, required = false,
                                   default = nil)
  if valid_21626357 != nil:
    section.add "X-Amz-Date", valid_21626357
  var valid_21626358 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626358 = validateParameter(valid_21626358, JString, required = false,
                                   default = nil)
  if valid_21626358 != nil:
    section.add "X-Amz-Security-Token", valid_21626358
  var valid_21626359 = header.getOrDefault("X-Amz-Target")
  valid_21626359 = validateParameter(valid_21626359, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminSetUserSettings"))
  if valid_21626359 != nil:
    section.add "X-Amz-Target", valid_21626359
  var valid_21626360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626360 = validateParameter(valid_21626360, JString, required = false,
                                   default = nil)
  if valid_21626360 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626360
  var valid_21626361 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626361 = validateParameter(valid_21626361, JString, required = false,
                                   default = nil)
  if valid_21626361 != nil:
    section.add "X-Amz-Algorithm", valid_21626361
  var valid_21626362 = header.getOrDefault("X-Amz-Signature")
  valid_21626362 = validateParameter(valid_21626362, JString, required = false,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "X-Amz-Signature", valid_21626362
  var valid_21626363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626363 = validateParameter(valid_21626363, JString, required = false,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626363
  var valid_21626364 = header.getOrDefault("X-Amz-Credential")
  valid_21626364 = validateParameter(valid_21626364, JString, required = false,
                                   default = nil)
  if valid_21626364 != nil:
    section.add "X-Amz-Credential", valid_21626364
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

proc call*(call_21626366: Call_AdminSetUserSettings_21626354; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  <i>This action is no longer supported.</i> You can use it to configure only SMS MFA. You can't use it to configure TOTP software token MFA. To configure either type of MFA, use the <a>AdminSetUserMFAPreference</a> action instead.
  ## 
  let valid = call_21626366.validator(path, query, header, formData, body, _)
  let scheme = call_21626366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626366.makeUrl(scheme.get, call_21626366.host, call_21626366.base,
                               call_21626366.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626366, uri, valid, _)

proc call*(call_21626367: Call_AdminSetUserSettings_21626354; body: JsonNode): Recallable =
  ## adminSetUserSettings
  ##  <i>This action is no longer supported.</i> You can use it to configure only SMS MFA. You can't use it to configure TOTP software token MFA. To configure either type of MFA, use the <a>AdminSetUserMFAPreference</a> action instead.
  ##   body: JObject (required)
  var body_21626368 = newJObject()
  if body != nil:
    body_21626368 = body
  result = call_21626367.call(nil, nil, nil, nil, body_21626368)

var adminSetUserSettings* = Call_AdminSetUserSettings_21626354(
    name: "adminSetUserSettings", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminSetUserSettings",
    validator: validate_AdminSetUserSettings_21626355, base: "/",
    makeUrl: url_AdminSetUserSettings_21626356,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUpdateAuthEventFeedback_21626369 = ref object of OpenApiRestCall_21625435
proc url_AdminUpdateAuthEventFeedback_21626371(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminUpdateAuthEventFeedback_21626370(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626372 = header.getOrDefault("X-Amz-Date")
  valid_21626372 = validateParameter(valid_21626372, JString, required = false,
                                   default = nil)
  if valid_21626372 != nil:
    section.add "X-Amz-Date", valid_21626372
  var valid_21626373 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626373 = validateParameter(valid_21626373, JString, required = false,
                                   default = nil)
  if valid_21626373 != nil:
    section.add "X-Amz-Security-Token", valid_21626373
  var valid_21626374 = header.getOrDefault("X-Amz-Target")
  valid_21626374 = validateParameter(valid_21626374, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUpdateAuthEventFeedback"))
  if valid_21626374 != nil:
    section.add "X-Amz-Target", valid_21626374
  var valid_21626375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626375 = validateParameter(valid_21626375, JString, required = false,
                                   default = nil)
  if valid_21626375 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626375
  var valid_21626376 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626376 = validateParameter(valid_21626376, JString, required = false,
                                   default = nil)
  if valid_21626376 != nil:
    section.add "X-Amz-Algorithm", valid_21626376
  var valid_21626377 = header.getOrDefault("X-Amz-Signature")
  valid_21626377 = validateParameter(valid_21626377, JString, required = false,
                                   default = nil)
  if valid_21626377 != nil:
    section.add "X-Amz-Signature", valid_21626377
  var valid_21626378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626378 = validateParameter(valid_21626378, JString, required = false,
                                   default = nil)
  if valid_21626378 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626378
  var valid_21626379 = header.getOrDefault("X-Amz-Credential")
  valid_21626379 = validateParameter(valid_21626379, JString, required = false,
                                   default = nil)
  if valid_21626379 != nil:
    section.add "X-Amz-Credential", valid_21626379
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

proc call*(call_21626381: Call_AdminUpdateAuthEventFeedback_21626369;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides feedback for an authentication event as to whether it was from a valid user. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ## 
  let valid = call_21626381.validator(path, query, header, formData, body, _)
  let scheme = call_21626381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626381.makeUrl(scheme.get, call_21626381.host, call_21626381.base,
                               call_21626381.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626381, uri, valid, _)

proc call*(call_21626382: Call_AdminUpdateAuthEventFeedback_21626369;
          body: JsonNode): Recallable =
  ## adminUpdateAuthEventFeedback
  ## Provides feedback for an authentication event as to whether it was from a valid user. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ##   body: JObject (required)
  var body_21626383 = newJObject()
  if body != nil:
    body_21626383 = body
  result = call_21626382.call(nil, nil, nil, nil, body_21626383)

var adminUpdateAuthEventFeedback* = Call_AdminUpdateAuthEventFeedback_21626369(
    name: "adminUpdateAuthEventFeedback", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUpdateAuthEventFeedback",
    validator: validate_AdminUpdateAuthEventFeedback_21626370, base: "/",
    makeUrl: url_AdminUpdateAuthEventFeedback_21626371,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUpdateDeviceStatus_21626384 = ref object of OpenApiRestCall_21625435
proc url_AdminUpdateDeviceStatus_21626386(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminUpdateDeviceStatus_21626385(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626387 = header.getOrDefault("X-Amz-Date")
  valid_21626387 = validateParameter(valid_21626387, JString, required = false,
                                   default = nil)
  if valid_21626387 != nil:
    section.add "X-Amz-Date", valid_21626387
  var valid_21626388 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626388 = validateParameter(valid_21626388, JString, required = false,
                                   default = nil)
  if valid_21626388 != nil:
    section.add "X-Amz-Security-Token", valid_21626388
  var valid_21626389 = header.getOrDefault("X-Amz-Target")
  valid_21626389 = validateParameter(valid_21626389, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUpdateDeviceStatus"))
  if valid_21626389 != nil:
    section.add "X-Amz-Target", valid_21626389
  var valid_21626390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626390 = validateParameter(valid_21626390, JString, required = false,
                                   default = nil)
  if valid_21626390 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626390
  var valid_21626391 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626391 = validateParameter(valid_21626391, JString, required = false,
                                   default = nil)
  if valid_21626391 != nil:
    section.add "X-Amz-Algorithm", valid_21626391
  var valid_21626392 = header.getOrDefault("X-Amz-Signature")
  valid_21626392 = validateParameter(valid_21626392, JString, required = false,
                                   default = nil)
  if valid_21626392 != nil:
    section.add "X-Amz-Signature", valid_21626392
  var valid_21626393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626393 = validateParameter(valid_21626393, JString, required = false,
                                   default = nil)
  if valid_21626393 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626393
  var valid_21626394 = header.getOrDefault("X-Amz-Credential")
  valid_21626394 = validateParameter(valid_21626394, JString, required = false,
                                   default = nil)
  if valid_21626394 != nil:
    section.add "X-Amz-Credential", valid_21626394
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

proc call*(call_21626396: Call_AdminUpdateDeviceStatus_21626384;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the device status as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_21626396.validator(path, query, header, formData, body, _)
  let scheme = call_21626396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626396.makeUrl(scheme.get, call_21626396.host, call_21626396.base,
                               call_21626396.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626396, uri, valid, _)

proc call*(call_21626397: Call_AdminUpdateDeviceStatus_21626384; body: JsonNode): Recallable =
  ## adminUpdateDeviceStatus
  ## <p>Updates the device status as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_21626398 = newJObject()
  if body != nil:
    body_21626398 = body
  result = call_21626397.call(nil, nil, nil, nil, body_21626398)

var adminUpdateDeviceStatus* = Call_AdminUpdateDeviceStatus_21626384(
    name: "adminUpdateDeviceStatus", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUpdateDeviceStatus",
    validator: validate_AdminUpdateDeviceStatus_21626385, base: "/",
    makeUrl: url_AdminUpdateDeviceStatus_21626386,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUpdateUserAttributes_21626399 = ref object of OpenApiRestCall_21625435
proc url_AdminUpdateUserAttributes_21626401(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminUpdateUserAttributes_21626400(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626402 = header.getOrDefault("X-Amz-Date")
  valid_21626402 = validateParameter(valid_21626402, JString, required = false,
                                   default = nil)
  if valid_21626402 != nil:
    section.add "X-Amz-Date", valid_21626402
  var valid_21626403 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626403 = validateParameter(valid_21626403, JString, required = false,
                                   default = nil)
  if valid_21626403 != nil:
    section.add "X-Amz-Security-Token", valid_21626403
  var valid_21626404 = header.getOrDefault("X-Amz-Target")
  valid_21626404 = validateParameter(valid_21626404, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUpdateUserAttributes"))
  if valid_21626404 != nil:
    section.add "X-Amz-Target", valid_21626404
  var valid_21626405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626405 = validateParameter(valid_21626405, JString, required = false,
                                   default = nil)
  if valid_21626405 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626405
  var valid_21626406 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626406 = validateParameter(valid_21626406, JString, required = false,
                                   default = nil)
  if valid_21626406 != nil:
    section.add "X-Amz-Algorithm", valid_21626406
  var valid_21626407 = header.getOrDefault("X-Amz-Signature")
  valid_21626407 = validateParameter(valid_21626407, JString, required = false,
                                   default = nil)
  if valid_21626407 != nil:
    section.add "X-Amz-Signature", valid_21626407
  var valid_21626408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626408 = validateParameter(valid_21626408, JString, required = false,
                                   default = nil)
  if valid_21626408 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626408
  var valid_21626409 = header.getOrDefault("X-Amz-Credential")
  valid_21626409 = validateParameter(valid_21626409, JString, required = false,
                                   default = nil)
  if valid_21626409 != nil:
    section.add "X-Amz-Credential", valid_21626409
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

proc call*(call_21626411: Call_AdminUpdateUserAttributes_21626399;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the specified user's attributes, including developer attributes, as an administrator. Works on any user.</p> <p>For custom attributes, you must prepend the <code>custom:</code> prefix to the attribute name.</p> <p>In addition to updating user attributes, this API can also be used to mark phone and email as verified.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_21626411.validator(path, query, header, formData, body, _)
  let scheme = call_21626411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626411.makeUrl(scheme.get, call_21626411.host, call_21626411.base,
                               call_21626411.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626411, uri, valid, _)

proc call*(call_21626412: Call_AdminUpdateUserAttributes_21626399; body: JsonNode): Recallable =
  ## adminUpdateUserAttributes
  ## <p>Updates the specified user's attributes, including developer attributes, as an administrator. Works on any user.</p> <p>For custom attributes, you must prepend the <code>custom:</code> prefix to the attribute name.</p> <p>In addition to updating user attributes, this API can also be used to mark phone and email as verified.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_21626413 = newJObject()
  if body != nil:
    body_21626413 = body
  result = call_21626412.call(nil, nil, nil, nil, body_21626413)

var adminUpdateUserAttributes* = Call_AdminUpdateUserAttributes_21626399(
    name: "adminUpdateUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUpdateUserAttributes",
    validator: validate_AdminUpdateUserAttributes_21626400, base: "/",
    makeUrl: url_AdminUpdateUserAttributes_21626401,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUserGlobalSignOut_21626414 = ref object of OpenApiRestCall_21625435
proc url_AdminUserGlobalSignOut_21626416(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AdminUserGlobalSignOut_21626415(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626417 = header.getOrDefault("X-Amz-Date")
  valid_21626417 = validateParameter(valid_21626417, JString, required = false,
                                   default = nil)
  if valid_21626417 != nil:
    section.add "X-Amz-Date", valid_21626417
  var valid_21626418 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626418 = validateParameter(valid_21626418, JString, required = false,
                                   default = nil)
  if valid_21626418 != nil:
    section.add "X-Amz-Security-Token", valid_21626418
  var valid_21626419 = header.getOrDefault("X-Amz-Target")
  valid_21626419 = validateParameter(valid_21626419, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUserGlobalSignOut"))
  if valid_21626419 != nil:
    section.add "X-Amz-Target", valid_21626419
  var valid_21626420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626420 = validateParameter(valid_21626420, JString, required = false,
                                   default = nil)
  if valid_21626420 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626420
  var valid_21626421 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626421 = validateParameter(valid_21626421, JString, required = false,
                                   default = nil)
  if valid_21626421 != nil:
    section.add "X-Amz-Algorithm", valid_21626421
  var valid_21626422 = header.getOrDefault("X-Amz-Signature")
  valid_21626422 = validateParameter(valid_21626422, JString, required = false,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "X-Amz-Signature", valid_21626422
  var valid_21626423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626423 = validateParameter(valid_21626423, JString, required = false,
                                   default = nil)
  if valid_21626423 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626423
  var valid_21626424 = header.getOrDefault("X-Amz-Credential")
  valid_21626424 = validateParameter(valid_21626424, JString, required = false,
                                   default = nil)
  if valid_21626424 != nil:
    section.add "X-Amz-Credential", valid_21626424
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

proc call*(call_21626426: Call_AdminUserGlobalSignOut_21626414;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Signs out users from all devices, as an administrator. It also invalidates all refresh tokens issued to a user. The user's current access and Id tokens remain valid until their expiry. Access and Id tokens expire one hour after they are issued.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_21626426.validator(path, query, header, formData, body, _)
  let scheme = call_21626426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626426.makeUrl(scheme.get, call_21626426.host, call_21626426.base,
                               call_21626426.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626426, uri, valid, _)

proc call*(call_21626427: Call_AdminUserGlobalSignOut_21626414; body: JsonNode): Recallable =
  ## adminUserGlobalSignOut
  ## <p>Signs out users from all devices, as an administrator. It also invalidates all refresh tokens issued to a user. The user's current access and Id tokens remain valid until their expiry. Access and Id tokens expire one hour after they are issued.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_21626428 = newJObject()
  if body != nil:
    body_21626428 = body
  result = call_21626427.call(nil, nil, nil, nil, body_21626428)

var adminUserGlobalSignOut* = Call_AdminUserGlobalSignOut_21626414(
    name: "adminUserGlobalSignOut", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUserGlobalSignOut",
    validator: validate_AdminUserGlobalSignOut_21626415, base: "/",
    makeUrl: url_AdminUserGlobalSignOut_21626416,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSoftwareToken_21626429 = ref object of OpenApiRestCall_21625435
proc url_AssociateSoftwareToken_21626431(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateSoftwareToken_21626430(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626432 = header.getOrDefault("X-Amz-Date")
  valid_21626432 = validateParameter(valid_21626432, JString, required = false,
                                   default = nil)
  if valid_21626432 != nil:
    section.add "X-Amz-Date", valid_21626432
  var valid_21626433 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626433 = validateParameter(valid_21626433, JString, required = false,
                                   default = nil)
  if valid_21626433 != nil:
    section.add "X-Amz-Security-Token", valid_21626433
  var valid_21626434 = header.getOrDefault("X-Amz-Target")
  valid_21626434 = validateParameter(valid_21626434, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AssociateSoftwareToken"))
  if valid_21626434 != nil:
    section.add "X-Amz-Target", valid_21626434
  var valid_21626435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626435 = validateParameter(valid_21626435, JString, required = false,
                                   default = nil)
  if valid_21626435 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626435
  var valid_21626436 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626436 = validateParameter(valid_21626436, JString, required = false,
                                   default = nil)
  if valid_21626436 != nil:
    section.add "X-Amz-Algorithm", valid_21626436
  var valid_21626437 = header.getOrDefault("X-Amz-Signature")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-Signature", valid_21626437
  var valid_21626438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626438 = validateParameter(valid_21626438, JString, required = false,
                                   default = nil)
  if valid_21626438 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626438
  var valid_21626439 = header.getOrDefault("X-Amz-Credential")
  valid_21626439 = validateParameter(valid_21626439, JString, required = false,
                                   default = nil)
  if valid_21626439 != nil:
    section.add "X-Amz-Credential", valid_21626439
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

proc call*(call_21626441: Call_AssociateSoftwareToken_21626429;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a unique generated shared secret key code for the user account. The request takes an access token or a session string, but not both.
  ## 
  let valid = call_21626441.validator(path, query, header, formData, body, _)
  let scheme = call_21626441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626441.makeUrl(scheme.get, call_21626441.host, call_21626441.base,
                               call_21626441.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626441, uri, valid, _)

proc call*(call_21626442: Call_AssociateSoftwareToken_21626429; body: JsonNode): Recallable =
  ## associateSoftwareToken
  ## Returns a unique generated shared secret key code for the user account. The request takes an access token or a session string, but not both.
  ##   body: JObject (required)
  var body_21626443 = newJObject()
  if body != nil:
    body_21626443 = body
  result = call_21626442.call(nil, nil, nil, nil, body_21626443)

var associateSoftwareToken* = Call_AssociateSoftwareToken_21626429(
    name: "associateSoftwareToken", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AssociateSoftwareToken",
    validator: validate_AssociateSoftwareToken_21626430, base: "/",
    makeUrl: url_AssociateSoftwareToken_21626431,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ChangePassword_21626444 = ref object of OpenApiRestCall_21625435
proc url_ChangePassword_21626446(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ChangePassword_21626445(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626447 = header.getOrDefault("X-Amz-Date")
  valid_21626447 = validateParameter(valid_21626447, JString, required = false,
                                   default = nil)
  if valid_21626447 != nil:
    section.add "X-Amz-Date", valid_21626447
  var valid_21626448 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626448 = validateParameter(valid_21626448, JString, required = false,
                                   default = nil)
  if valid_21626448 != nil:
    section.add "X-Amz-Security-Token", valid_21626448
  var valid_21626449 = header.getOrDefault("X-Amz-Target")
  valid_21626449 = validateParameter(valid_21626449, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ChangePassword"))
  if valid_21626449 != nil:
    section.add "X-Amz-Target", valid_21626449
  var valid_21626450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626450 = validateParameter(valid_21626450, JString, required = false,
                                   default = nil)
  if valid_21626450 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626450
  var valid_21626451 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626451 = validateParameter(valid_21626451, JString, required = false,
                                   default = nil)
  if valid_21626451 != nil:
    section.add "X-Amz-Algorithm", valid_21626451
  var valid_21626452 = header.getOrDefault("X-Amz-Signature")
  valid_21626452 = validateParameter(valid_21626452, JString, required = false,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "X-Amz-Signature", valid_21626452
  var valid_21626453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626453 = validateParameter(valid_21626453, JString, required = false,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626453
  var valid_21626454 = header.getOrDefault("X-Amz-Credential")
  valid_21626454 = validateParameter(valid_21626454, JString, required = false,
                                   default = nil)
  if valid_21626454 != nil:
    section.add "X-Amz-Credential", valid_21626454
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

proc call*(call_21626456: Call_ChangePassword_21626444; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Changes the password for a specified user in a user pool.
  ## 
  let valid = call_21626456.validator(path, query, header, formData, body, _)
  let scheme = call_21626456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626456.makeUrl(scheme.get, call_21626456.host, call_21626456.base,
                               call_21626456.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626456, uri, valid, _)

proc call*(call_21626457: Call_ChangePassword_21626444; body: JsonNode): Recallable =
  ## changePassword
  ## Changes the password for a specified user in a user pool.
  ##   body: JObject (required)
  var body_21626458 = newJObject()
  if body != nil:
    body_21626458 = body
  result = call_21626457.call(nil, nil, nil, nil, body_21626458)

var changePassword* = Call_ChangePassword_21626444(name: "changePassword",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ChangePassword",
    validator: validate_ChangePassword_21626445, base: "/",
    makeUrl: url_ChangePassword_21626446, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmDevice_21626459 = ref object of OpenApiRestCall_21625435
proc url_ConfirmDevice_21626461(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ConfirmDevice_21626460(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626462 = header.getOrDefault("X-Amz-Date")
  valid_21626462 = validateParameter(valid_21626462, JString, required = false,
                                   default = nil)
  if valid_21626462 != nil:
    section.add "X-Amz-Date", valid_21626462
  var valid_21626463 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626463 = validateParameter(valid_21626463, JString, required = false,
                                   default = nil)
  if valid_21626463 != nil:
    section.add "X-Amz-Security-Token", valid_21626463
  var valid_21626464 = header.getOrDefault("X-Amz-Target")
  valid_21626464 = validateParameter(valid_21626464, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ConfirmDevice"))
  if valid_21626464 != nil:
    section.add "X-Amz-Target", valid_21626464
  var valid_21626465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626465 = validateParameter(valid_21626465, JString, required = false,
                                   default = nil)
  if valid_21626465 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626465
  var valid_21626466 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626466 = validateParameter(valid_21626466, JString, required = false,
                                   default = nil)
  if valid_21626466 != nil:
    section.add "X-Amz-Algorithm", valid_21626466
  var valid_21626467 = header.getOrDefault("X-Amz-Signature")
  valid_21626467 = validateParameter(valid_21626467, JString, required = false,
                                   default = nil)
  if valid_21626467 != nil:
    section.add "X-Amz-Signature", valid_21626467
  var valid_21626468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626468 = validateParameter(valid_21626468, JString, required = false,
                                   default = nil)
  if valid_21626468 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626468
  var valid_21626469 = header.getOrDefault("X-Amz-Credential")
  valid_21626469 = validateParameter(valid_21626469, JString, required = false,
                                   default = nil)
  if valid_21626469 != nil:
    section.add "X-Amz-Credential", valid_21626469
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

proc call*(call_21626471: Call_ConfirmDevice_21626459; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Confirms tracking of the device. This API call is the call that begins device tracking.
  ## 
  let valid = call_21626471.validator(path, query, header, formData, body, _)
  let scheme = call_21626471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626471.makeUrl(scheme.get, call_21626471.host, call_21626471.base,
                               call_21626471.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626471, uri, valid, _)

proc call*(call_21626472: Call_ConfirmDevice_21626459; body: JsonNode): Recallable =
  ## confirmDevice
  ## Confirms tracking of the device. This API call is the call that begins device tracking.
  ##   body: JObject (required)
  var body_21626473 = newJObject()
  if body != nil:
    body_21626473 = body
  result = call_21626472.call(nil, nil, nil, nil, body_21626473)

var confirmDevice* = Call_ConfirmDevice_21626459(name: "confirmDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ConfirmDevice",
    validator: validate_ConfirmDevice_21626460, base: "/",
    makeUrl: url_ConfirmDevice_21626461, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmForgotPassword_21626474 = ref object of OpenApiRestCall_21625435
proc url_ConfirmForgotPassword_21626476(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ConfirmForgotPassword_21626475(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626477 = header.getOrDefault("X-Amz-Date")
  valid_21626477 = validateParameter(valid_21626477, JString, required = false,
                                   default = nil)
  if valid_21626477 != nil:
    section.add "X-Amz-Date", valid_21626477
  var valid_21626478 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626478 = validateParameter(valid_21626478, JString, required = false,
                                   default = nil)
  if valid_21626478 != nil:
    section.add "X-Amz-Security-Token", valid_21626478
  var valid_21626479 = header.getOrDefault("X-Amz-Target")
  valid_21626479 = validateParameter(valid_21626479, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ConfirmForgotPassword"))
  if valid_21626479 != nil:
    section.add "X-Amz-Target", valid_21626479
  var valid_21626480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626480 = validateParameter(valid_21626480, JString, required = false,
                                   default = nil)
  if valid_21626480 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626480
  var valid_21626481 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626481 = validateParameter(valid_21626481, JString, required = false,
                                   default = nil)
  if valid_21626481 != nil:
    section.add "X-Amz-Algorithm", valid_21626481
  var valid_21626482 = header.getOrDefault("X-Amz-Signature")
  valid_21626482 = validateParameter(valid_21626482, JString, required = false,
                                   default = nil)
  if valid_21626482 != nil:
    section.add "X-Amz-Signature", valid_21626482
  var valid_21626483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626483 = validateParameter(valid_21626483, JString, required = false,
                                   default = nil)
  if valid_21626483 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626483
  var valid_21626484 = header.getOrDefault("X-Amz-Credential")
  valid_21626484 = validateParameter(valid_21626484, JString, required = false,
                                   default = nil)
  if valid_21626484 != nil:
    section.add "X-Amz-Credential", valid_21626484
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

proc call*(call_21626486: Call_ConfirmForgotPassword_21626474;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Allows a user to enter a confirmation code to reset a forgotten password.
  ## 
  let valid = call_21626486.validator(path, query, header, formData, body, _)
  let scheme = call_21626486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626486.makeUrl(scheme.get, call_21626486.host, call_21626486.base,
                               call_21626486.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626486, uri, valid, _)

proc call*(call_21626487: Call_ConfirmForgotPassword_21626474; body: JsonNode): Recallable =
  ## confirmForgotPassword
  ## Allows a user to enter a confirmation code to reset a forgotten password.
  ##   body: JObject (required)
  var body_21626488 = newJObject()
  if body != nil:
    body_21626488 = body
  result = call_21626487.call(nil, nil, nil, nil, body_21626488)

var confirmForgotPassword* = Call_ConfirmForgotPassword_21626474(
    name: "confirmForgotPassword", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ConfirmForgotPassword",
    validator: validate_ConfirmForgotPassword_21626475, base: "/",
    makeUrl: url_ConfirmForgotPassword_21626476,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmSignUp_21626489 = ref object of OpenApiRestCall_21625435
proc url_ConfirmSignUp_21626491(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ConfirmSignUp_21626490(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626492 = header.getOrDefault("X-Amz-Date")
  valid_21626492 = validateParameter(valid_21626492, JString, required = false,
                                   default = nil)
  if valid_21626492 != nil:
    section.add "X-Amz-Date", valid_21626492
  var valid_21626493 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626493 = validateParameter(valid_21626493, JString, required = false,
                                   default = nil)
  if valid_21626493 != nil:
    section.add "X-Amz-Security-Token", valid_21626493
  var valid_21626494 = header.getOrDefault("X-Amz-Target")
  valid_21626494 = validateParameter(valid_21626494, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ConfirmSignUp"))
  if valid_21626494 != nil:
    section.add "X-Amz-Target", valid_21626494
  var valid_21626495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626495 = validateParameter(valid_21626495, JString, required = false,
                                   default = nil)
  if valid_21626495 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626495
  var valid_21626496 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626496 = validateParameter(valid_21626496, JString, required = false,
                                   default = nil)
  if valid_21626496 != nil:
    section.add "X-Amz-Algorithm", valid_21626496
  var valid_21626497 = header.getOrDefault("X-Amz-Signature")
  valid_21626497 = validateParameter(valid_21626497, JString, required = false,
                                   default = nil)
  if valid_21626497 != nil:
    section.add "X-Amz-Signature", valid_21626497
  var valid_21626498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626498 = validateParameter(valid_21626498, JString, required = false,
                                   default = nil)
  if valid_21626498 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626498
  var valid_21626499 = header.getOrDefault("X-Amz-Credential")
  valid_21626499 = validateParameter(valid_21626499, JString, required = false,
                                   default = nil)
  if valid_21626499 != nil:
    section.add "X-Amz-Credential", valid_21626499
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

proc call*(call_21626501: Call_ConfirmSignUp_21626489; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Confirms registration of a user and handles the existing alias from a previous user.
  ## 
  let valid = call_21626501.validator(path, query, header, formData, body, _)
  let scheme = call_21626501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626501.makeUrl(scheme.get, call_21626501.host, call_21626501.base,
                               call_21626501.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626501, uri, valid, _)

proc call*(call_21626502: Call_ConfirmSignUp_21626489; body: JsonNode): Recallable =
  ## confirmSignUp
  ## Confirms registration of a user and handles the existing alias from a previous user.
  ##   body: JObject (required)
  var body_21626503 = newJObject()
  if body != nil:
    body_21626503 = body
  result = call_21626502.call(nil, nil, nil, nil, body_21626503)

var confirmSignUp* = Call_ConfirmSignUp_21626489(name: "confirmSignUp",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ConfirmSignUp",
    validator: validate_ConfirmSignUp_21626490, base: "/",
    makeUrl: url_ConfirmSignUp_21626491, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_21626504 = ref object of OpenApiRestCall_21625435
proc url_CreateGroup_21626506(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateGroup_21626505(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626507 = header.getOrDefault("X-Amz-Date")
  valid_21626507 = validateParameter(valid_21626507, JString, required = false,
                                   default = nil)
  if valid_21626507 != nil:
    section.add "X-Amz-Date", valid_21626507
  var valid_21626508 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626508 = validateParameter(valid_21626508, JString, required = false,
                                   default = nil)
  if valid_21626508 != nil:
    section.add "X-Amz-Security-Token", valid_21626508
  var valid_21626509 = header.getOrDefault("X-Amz-Target")
  valid_21626509 = validateParameter(valid_21626509, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateGroup"))
  if valid_21626509 != nil:
    section.add "X-Amz-Target", valid_21626509
  var valid_21626510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626510 = validateParameter(valid_21626510, JString, required = false,
                                   default = nil)
  if valid_21626510 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626510
  var valid_21626511 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626511 = validateParameter(valid_21626511, JString, required = false,
                                   default = nil)
  if valid_21626511 != nil:
    section.add "X-Amz-Algorithm", valid_21626511
  var valid_21626512 = header.getOrDefault("X-Amz-Signature")
  valid_21626512 = validateParameter(valid_21626512, JString, required = false,
                                   default = nil)
  if valid_21626512 != nil:
    section.add "X-Amz-Signature", valid_21626512
  var valid_21626513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626513 = validateParameter(valid_21626513, JString, required = false,
                                   default = nil)
  if valid_21626513 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626513
  var valid_21626514 = header.getOrDefault("X-Amz-Credential")
  valid_21626514 = validateParameter(valid_21626514, JString, required = false,
                                   default = nil)
  if valid_21626514 != nil:
    section.add "X-Amz-Credential", valid_21626514
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

proc call*(call_21626516: Call_CreateGroup_21626504; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new group in the specified user pool.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_21626516.validator(path, query, header, formData, body, _)
  let scheme = call_21626516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626516.makeUrl(scheme.get, call_21626516.host, call_21626516.base,
                               call_21626516.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626516, uri, valid, _)

proc call*(call_21626517: Call_CreateGroup_21626504; body: JsonNode): Recallable =
  ## createGroup
  ## <p>Creates a new group in the specified user pool.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_21626518 = newJObject()
  if body != nil:
    body_21626518 = body
  result = call_21626517.call(nil, nil, nil, nil, body_21626518)

var createGroup* = Call_CreateGroup_21626504(name: "createGroup",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateGroup",
    validator: validate_CreateGroup_21626505, base: "/", makeUrl: url_CreateGroup_21626506,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIdentityProvider_21626519 = ref object of OpenApiRestCall_21625435
proc url_CreateIdentityProvider_21626521(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateIdentityProvider_21626520(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626522 = header.getOrDefault("X-Amz-Date")
  valid_21626522 = validateParameter(valid_21626522, JString, required = false,
                                   default = nil)
  if valid_21626522 != nil:
    section.add "X-Amz-Date", valid_21626522
  var valid_21626523 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626523 = validateParameter(valid_21626523, JString, required = false,
                                   default = nil)
  if valid_21626523 != nil:
    section.add "X-Amz-Security-Token", valid_21626523
  var valid_21626524 = header.getOrDefault("X-Amz-Target")
  valid_21626524 = validateParameter(valid_21626524, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateIdentityProvider"))
  if valid_21626524 != nil:
    section.add "X-Amz-Target", valid_21626524
  var valid_21626525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626525 = validateParameter(valid_21626525, JString, required = false,
                                   default = nil)
  if valid_21626525 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626525
  var valid_21626526 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626526 = validateParameter(valid_21626526, JString, required = false,
                                   default = nil)
  if valid_21626526 != nil:
    section.add "X-Amz-Algorithm", valid_21626526
  var valid_21626527 = header.getOrDefault("X-Amz-Signature")
  valid_21626527 = validateParameter(valid_21626527, JString, required = false,
                                   default = nil)
  if valid_21626527 != nil:
    section.add "X-Amz-Signature", valid_21626527
  var valid_21626528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626528 = validateParameter(valid_21626528, JString, required = false,
                                   default = nil)
  if valid_21626528 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626528
  var valid_21626529 = header.getOrDefault("X-Amz-Credential")
  valid_21626529 = validateParameter(valid_21626529, JString, required = false,
                                   default = nil)
  if valid_21626529 != nil:
    section.add "X-Amz-Credential", valid_21626529
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

proc call*(call_21626531: Call_CreateIdentityProvider_21626519;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an identity provider for a user pool.
  ## 
  let valid = call_21626531.validator(path, query, header, formData, body, _)
  let scheme = call_21626531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626531.makeUrl(scheme.get, call_21626531.host, call_21626531.base,
                               call_21626531.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626531, uri, valid, _)

proc call*(call_21626532: Call_CreateIdentityProvider_21626519; body: JsonNode): Recallable =
  ## createIdentityProvider
  ## Creates an identity provider for a user pool.
  ##   body: JObject (required)
  var body_21626533 = newJObject()
  if body != nil:
    body_21626533 = body
  result = call_21626532.call(nil, nil, nil, nil, body_21626533)

var createIdentityProvider* = Call_CreateIdentityProvider_21626519(
    name: "createIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateIdentityProvider",
    validator: validate_CreateIdentityProvider_21626520, base: "/",
    makeUrl: url_CreateIdentityProvider_21626521,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceServer_21626534 = ref object of OpenApiRestCall_21625435
proc url_CreateResourceServer_21626536(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateResourceServer_21626535(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626537 = header.getOrDefault("X-Amz-Date")
  valid_21626537 = validateParameter(valid_21626537, JString, required = false,
                                   default = nil)
  if valid_21626537 != nil:
    section.add "X-Amz-Date", valid_21626537
  var valid_21626538 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626538 = validateParameter(valid_21626538, JString, required = false,
                                   default = nil)
  if valid_21626538 != nil:
    section.add "X-Amz-Security-Token", valid_21626538
  var valid_21626539 = header.getOrDefault("X-Amz-Target")
  valid_21626539 = validateParameter(valid_21626539, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateResourceServer"))
  if valid_21626539 != nil:
    section.add "X-Amz-Target", valid_21626539
  var valid_21626540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626540 = validateParameter(valid_21626540, JString, required = false,
                                   default = nil)
  if valid_21626540 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626540
  var valid_21626541 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626541 = validateParameter(valid_21626541, JString, required = false,
                                   default = nil)
  if valid_21626541 != nil:
    section.add "X-Amz-Algorithm", valid_21626541
  var valid_21626542 = header.getOrDefault("X-Amz-Signature")
  valid_21626542 = validateParameter(valid_21626542, JString, required = false,
                                   default = nil)
  if valid_21626542 != nil:
    section.add "X-Amz-Signature", valid_21626542
  var valid_21626543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626543 = validateParameter(valid_21626543, JString, required = false,
                                   default = nil)
  if valid_21626543 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626543
  var valid_21626544 = header.getOrDefault("X-Amz-Credential")
  valid_21626544 = validateParameter(valid_21626544, JString, required = false,
                                   default = nil)
  if valid_21626544 != nil:
    section.add "X-Amz-Credential", valid_21626544
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

proc call*(call_21626546: Call_CreateResourceServer_21626534; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new OAuth2.0 resource server and defines custom scopes in it.
  ## 
  let valid = call_21626546.validator(path, query, header, formData, body, _)
  let scheme = call_21626546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626546.makeUrl(scheme.get, call_21626546.host, call_21626546.base,
                               call_21626546.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626546, uri, valid, _)

proc call*(call_21626547: Call_CreateResourceServer_21626534; body: JsonNode): Recallable =
  ## createResourceServer
  ## Creates a new OAuth2.0 resource server and defines custom scopes in it.
  ##   body: JObject (required)
  var body_21626548 = newJObject()
  if body != nil:
    body_21626548 = body
  result = call_21626547.call(nil, nil, nil, nil, body_21626548)

var createResourceServer* = Call_CreateResourceServer_21626534(
    name: "createResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateResourceServer",
    validator: validate_CreateResourceServer_21626535, base: "/",
    makeUrl: url_CreateResourceServer_21626536,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserImportJob_21626549 = ref object of OpenApiRestCall_21625435
proc url_CreateUserImportJob_21626551(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUserImportJob_21626550(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626552 = header.getOrDefault("X-Amz-Date")
  valid_21626552 = validateParameter(valid_21626552, JString, required = false,
                                   default = nil)
  if valid_21626552 != nil:
    section.add "X-Amz-Date", valid_21626552
  var valid_21626553 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626553 = validateParameter(valid_21626553, JString, required = false,
                                   default = nil)
  if valid_21626553 != nil:
    section.add "X-Amz-Security-Token", valid_21626553
  var valid_21626554 = header.getOrDefault("X-Amz-Target")
  valid_21626554 = validateParameter(valid_21626554, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserImportJob"))
  if valid_21626554 != nil:
    section.add "X-Amz-Target", valid_21626554
  var valid_21626555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626555 = validateParameter(valid_21626555, JString, required = false,
                                   default = nil)
  if valid_21626555 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626555
  var valid_21626556 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626556 = validateParameter(valid_21626556, JString, required = false,
                                   default = nil)
  if valid_21626556 != nil:
    section.add "X-Amz-Algorithm", valid_21626556
  var valid_21626557 = header.getOrDefault("X-Amz-Signature")
  valid_21626557 = validateParameter(valid_21626557, JString, required = false,
                                   default = nil)
  if valid_21626557 != nil:
    section.add "X-Amz-Signature", valid_21626557
  var valid_21626558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626558 = validateParameter(valid_21626558, JString, required = false,
                                   default = nil)
  if valid_21626558 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626558
  var valid_21626559 = header.getOrDefault("X-Amz-Credential")
  valid_21626559 = validateParameter(valid_21626559, JString, required = false,
                                   default = nil)
  if valid_21626559 != nil:
    section.add "X-Amz-Credential", valid_21626559
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

proc call*(call_21626561: Call_CreateUserImportJob_21626549; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates the user import job.
  ## 
  let valid = call_21626561.validator(path, query, header, formData, body, _)
  let scheme = call_21626561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626561.makeUrl(scheme.get, call_21626561.host, call_21626561.base,
                               call_21626561.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626561, uri, valid, _)

proc call*(call_21626562: Call_CreateUserImportJob_21626549; body: JsonNode): Recallable =
  ## createUserImportJob
  ## Creates the user import job.
  ##   body: JObject (required)
  var body_21626563 = newJObject()
  if body != nil:
    body_21626563 = body
  result = call_21626562.call(nil, nil, nil, nil, body_21626563)

var createUserImportJob* = Call_CreateUserImportJob_21626549(
    name: "createUserImportJob", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserImportJob",
    validator: validate_CreateUserImportJob_21626550, base: "/",
    makeUrl: url_CreateUserImportJob_21626551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserPool_21626564 = ref object of OpenApiRestCall_21625435
proc url_CreateUserPool_21626566(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUserPool_21626565(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626567 = header.getOrDefault("X-Amz-Date")
  valid_21626567 = validateParameter(valid_21626567, JString, required = false,
                                   default = nil)
  if valid_21626567 != nil:
    section.add "X-Amz-Date", valid_21626567
  var valid_21626568 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626568 = validateParameter(valid_21626568, JString, required = false,
                                   default = nil)
  if valid_21626568 != nil:
    section.add "X-Amz-Security-Token", valid_21626568
  var valid_21626569 = header.getOrDefault("X-Amz-Target")
  valid_21626569 = validateParameter(valid_21626569, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserPool"))
  if valid_21626569 != nil:
    section.add "X-Amz-Target", valid_21626569
  var valid_21626570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626570 = validateParameter(valid_21626570, JString, required = false,
                                   default = nil)
  if valid_21626570 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626570
  var valid_21626571 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626571 = validateParameter(valid_21626571, JString, required = false,
                                   default = nil)
  if valid_21626571 != nil:
    section.add "X-Amz-Algorithm", valid_21626571
  var valid_21626572 = header.getOrDefault("X-Amz-Signature")
  valid_21626572 = validateParameter(valid_21626572, JString, required = false,
                                   default = nil)
  if valid_21626572 != nil:
    section.add "X-Amz-Signature", valid_21626572
  var valid_21626573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626573 = validateParameter(valid_21626573, JString, required = false,
                                   default = nil)
  if valid_21626573 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626573
  var valid_21626574 = header.getOrDefault("X-Amz-Credential")
  valid_21626574 = validateParameter(valid_21626574, JString, required = false,
                                   default = nil)
  if valid_21626574 != nil:
    section.add "X-Amz-Credential", valid_21626574
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

proc call*(call_21626576: Call_CreateUserPool_21626564; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new Amazon Cognito user pool and sets the password policy for the pool.
  ## 
  let valid = call_21626576.validator(path, query, header, formData, body, _)
  let scheme = call_21626576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626576.makeUrl(scheme.get, call_21626576.host, call_21626576.base,
                               call_21626576.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626576, uri, valid, _)

proc call*(call_21626577: Call_CreateUserPool_21626564; body: JsonNode): Recallable =
  ## createUserPool
  ## Creates a new Amazon Cognito user pool and sets the password policy for the pool.
  ##   body: JObject (required)
  var body_21626578 = newJObject()
  if body != nil:
    body_21626578 = body
  result = call_21626577.call(nil, nil, nil, nil, body_21626578)

var createUserPool* = Call_CreateUserPool_21626564(name: "createUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserPool",
    validator: validate_CreateUserPool_21626565, base: "/",
    makeUrl: url_CreateUserPool_21626566, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserPoolClient_21626579 = ref object of OpenApiRestCall_21625435
proc url_CreateUserPoolClient_21626581(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUserPoolClient_21626580(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626582 = header.getOrDefault("X-Amz-Date")
  valid_21626582 = validateParameter(valid_21626582, JString, required = false,
                                   default = nil)
  if valid_21626582 != nil:
    section.add "X-Amz-Date", valid_21626582
  var valid_21626583 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626583 = validateParameter(valid_21626583, JString, required = false,
                                   default = nil)
  if valid_21626583 != nil:
    section.add "X-Amz-Security-Token", valid_21626583
  var valid_21626584 = header.getOrDefault("X-Amz-Target")
  valid_21626584 = validateParameter(valid_21626584, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserPoolClient"))
  if valid_21626584 != nil:
    section.add "X-Amz-Target", valid_21626584
  var valid_21626585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626585 = validateParameter(valid_21626585, JString, required = false,
                                   default = nil)
  if valid_21626585 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626585
  var valid_21626586 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626586 = validateParameter(valid_21626586, JString, required = false,
                                   default = nil)
  if valid_21626586 != nil:
    section.add "X-Amz-Algorithm", valid_21626586
  var valid_21626587 = header.getOrDefault("X-Amz-Signature")
  valid_21626587 = validateParameter(valid_21626587, JString, required = false,
                                   default = nil)
  if valid_21626587 != nil:
    section.add "X-Amz-Signature", valid_21626587
  var valid_21626588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626588 = validateParameter(valid_21626588, JString, required = false,
                                   default = nil)
  if valid_21626588 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626588
  var valid_21626589 = header.getOrDefault("X-Amz-Credential")
  valid_21626589 = validateParameter(valid_21626589, JString, required = false,
                                   default = nil)
  if valid_21626589 != nil:
    section.add "X-Amz-Credential", valid_21626589
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

proc call*(call_21626591: Call_CreateUserPoolClient_21626579; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates the user pool client.
  ## 
  let valid = call_21626591.validator(path, query, header, formData, body, _)
  let scheme = call_21626591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626591.makeUrl(scheme.get, call_21626591.host, call_21626591.base,
                               call_21626591.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626591, uri, valid, _)

proc call*(call_21626592: Call_CreateUserPoolClient_21626579; body: JsonNode): Recallable =
  ## createUserPoolClient
  ## Creates the user pool client.
  ##   body: JObject (required)
  var body_21626593 = newJObject()
  if body != nil:
    body_21626593 = body
  result = call_21626592.call(nil, nil, nil, nil, body_21626593)

var createUserPoolClient* = Call_CreateUserPoolClient_21626579(
    name: "createUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserPoolClient",
    validator: validate_CreateUserPoolClient_21626580, base: "/",
    makeUrl: url_CreateUserPoolClient_21626581,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserPoolDomain_21626594 = ref object of OpenApiRestCall_21625435
proc url_CreateUserPoolDomain_21626596(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUserPoolDomain_21626595(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626597 = header.getOrDefault("X-Amz-Date")
  valid_21626597 = validateParameter(valid_21626597, JString, required = false,
                                   default = nil)
  if valid_21626597 != nil:
    section.add "X-Amz-Date", valid_21626597
  var valid_21626598 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626598 = validateParameter(valid_21626598, JString, required = false,
                                   default = nil)
  if valid_21626598 != nil:
    section.add "X-Amz-Security-Token", valid_21626598
  var valid_21626599 = header.getOrDefault("X-Amz-Target")
  valid_21626599 = validateParameter(valid_21626599, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserPoolDomain"))
  if valid_21626599 != nil:
    section.add "X-Amz-Target", valid_21626599
  var valid_21626600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626600 = validateParameter(valid_21626600, JString, required = false,
                                   default = nil)
  if valid_21626600 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626600
  var valid_21626601 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626601 = validateParameter(valid_21626601, JString, required = false,
                                   default = nil)
  if valid_21626601 != nil:
    section.add "X-Amz-Algorithm", valid_21626601
  var valid_21626602 = header.getOrDefault("X-Amz-Signature")
  valid_21626602 = validateParameter(valid_21626602, JString, required = false,
                                   default = nil)
  if valid_21626602 != nil:
    section.add "X-Amz-Signature", valid_21626602
  var valid_21626603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626603 = validateParameter(valid_21626603, JString, required = false,
                                   default = nil)
  if valid_21626603 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626603
  var valid_21626604 = header.getOrDefault("X-Amz-Credential")
  valid_21626604 = validateParameter(valid_21626604, JString, required = false,
                                   default = nil)
  if valid_21626604 != nil:
    section.add "X-Amz-Credential", valid_21626604
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

proc call*(call_21626606: Call_CreateUserPoolDomain_21626594; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new domain for a user pool.
  ## 
  let valid = call_21626606.validator(path, query, header, formData, body, _)
  let scheme = call_21626606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626606.makeUrl(scheme.get, call_21626606.host, call_21626606.base,
                               call_21626606.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626606, uri, valid, _)

proc call*(call_21626607: Call_CreateUserPoolDomain_21626594; body: JsonNode): Recallable =
  ## createUserPoolDomain
  ## Creates a new domain for a user pool.
  ##   body: JObject (required)
  var body_21626608 = newJObject()
  if body != nil:
    body_21626608 = body
  result = call_21626607.call(nil, nil, nil, nil, body_21626608)

var createUserPoolDomain* = Call_CreateUserPoolDomain_21626594(
    name: "createUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserPoolDomain",
    validator: validate_CreateUserPoolDomain_21626595, base: "/",
    makeUrl: url_CreateUserPoolDomain_21626596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_21626609 = ref object of OpenApiRestCall_21625435
proc url_DeleteGroup_21626611(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteGroup_21626610(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626612 = header.getOrDefault("X-Amz-Date")
  valid_21626612 = validateParameter(valid_21626612, JString, required = false,
                                   default = nil)
  if valid_21626612 != nil:
    section.add "X-Amz-Date", valid_21626612
  var valid_21626613 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626613 = validateParameter(valid_21626613, JString, required = false,
                                   default = nil)
  if valid_21626613 != nil:
    section.add "X-Amz-Security-Token", valid_21626613
  var valid_21626614 = header.getOrDefault("X-Amz-Target")
  valid_21626614 = validateParameter(valid_21626614, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteGroup"))
  if valid_21626614 != nil:
    section.add "X-Amz-Target", valid_21626614
  var valid_21626615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626615 = validateParameter(valid_21626615, JString, required = false,
                                   default = nil)
  if valid_21626615 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626615
  var valid_21626616 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626616 = validateParameter(valid_21626616, JString, required = false,
                                   default = nil)
  if valid_21626616 != nil:
    section.add "X-Amz-Algorithm", valid_21626616
  var valid_21626617 = header.getOrDefault("X-Amz-Signature")
  valid_21626617 = validateParameter(valid_21626617, JString, required = false,
                                   default = nil)
  if valid_21626617 != nil:
    section.add "X-Amz-Signature", valid_21626617
  var valid_21626618 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626618 = validateParameter(valid_21626618, JString, required = false,
                                   default = nil)
  if valid_21626618 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626618
  var valid_21626619 = header.getOrDefault("X-Amz-Credential")
  valid_21626619 = validateParameter(valid_21626619, JString, required = false,
                                   default = nil)
  if valid_21626619 != nil:
    section.add "X-Amz-Credential", valid_21626619
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

proc call*(call_21626621: Call_DeleteGroup_21626609; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a group. Currently only groups with no members can be deleted.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_21626621.validator(path, query, header, formData, body, _)
  let scheme = call_21626621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626621.makeUrl(scheme.get, call_21626621.host, call_21626621.base,
                               call_21626621.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626621, uri, valid, _)

proc call*(call_21626622: Call_DeleteGroup_21626609; body: JsonNode): Recallable =
  ## deleteGroup
  ## <p>Deletes a group. Currently only groups with no members can be deleted.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_21626623 = newJObject()
  if body != nil:
    body_21626623 = body
  result = call_21626622.call(nil, nil, nil, nil, body_21626623)

var deleteGroup* = Call_DeleteGroup_21626609(name: "deleteGroup",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteGroup",
    validator: validate_DeleteGroup_21626610, base: "/", makeUrl: url_DeleteGroup_21626611,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIdentityProvider_21626624 = ref object of OpenApiRestCall_21625435
proc url_DeleteIdentityProvider_21626626(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteIdentityProvider_21626625(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626627 = header.getOrDefault("X-Amz-Date")
  valid_21626627 = validateParameter(valid_21626627, JString, required = false,
                                   default = nil)
  if valid_21626627 != nil:
    section.add "X-Amz-Date", valid_21626627
  var valid_21626628 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626628 = validateParameter(valid_21626628, JString, required = false,
                                   default = nil)
  if valid_21626628 != nil:
    section.add "X-Amz-Security-Token", valid_21626628
  var valid_21626629 = header.getOrDefault("X-Amz-Target")
  valid_21626629 = validateParameter(valid_21626629, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteIdentityProvider"))
  if valid_21626629 != nil:
    section.add "X-Amz-Target", valid_21626629
  var valid_21626630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626630 = validateParameter(valid_21626630, JString, required = false,
                                   default = nil)
  if valid_21626630 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626630
  var valid_21626631 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626631 = validateParameter(valid_21626631, JString, required = false,
                                   default = nil)
  if valid_21626631 != nil:
    section.add "X-Amz-Algorithm", valid_21626631
  var valid_21626632 = header.getOrDefault("X-Amz-Signature")
  valid_21626632 = validateParameter(valid_21626632, JString, required = false,
                                   default = nil)
  if valid_21626632 != nil:
    section.add "X-Amz-Signature", valid_21626632
  var valid_21626633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626633 = validateParameter(valid_21626633, JString, required = false,
                                   default = nil)
  if valid_21626633 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626633
  var valid_21626634 = header.getOrDefault("X-Amz-Credential")
  valid_21626634 = validateParameter(valid_21626634, JString, required = false,
                                   default = nil)
  if valid_21626634 != nil:
    section.add "X-Amz-Credential", valid_21626634
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

proc call*(call_21626636: Call_DeleteIdentityProvider_21626624;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an identity provider for a user pool.
  ## 
  let valid = call_21626636.validator(path, query, header, formData, body, _)
  let scheme = call_21626636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626636.makeUrl(scheme.get, call_21626636.host, call_21626636.base,
                               call_21626636.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626636, uri, valid, _)

proc call*(call_21626637: Call_DeleteIdentityProvider_21626624; body: JsonNode): Recallable =
  ## deleteIdentityProvider
  ## Deletes an identity provider for a user pool.
  ##   body: JObject (required)
  var body_21626638 = newJObject()
  if body != nil:
    body_21626638 = body
  result = call_21626637.call(nil, nil, nil, nil, body_21626638)

var deleteIdentityProvider* = Call_DeleteIdentityProvider_21626624(
    name: "deleteIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteIdentityProvider",
    validator: validate_DeleteIdentityProvider_21626625, base: "/",
    makeUrl: url_DeleteIdentityProvider_21626626,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceServer_21626639 = ref object of OpenApiRestCall_21625435
proc url_DeleteResourceServer_21626641(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteResourceServer_21626640(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626642 = header.getOrDefault("X-Amz-Date")
  valid_21626642 = validateParameter(valid_21626642, JString, required = false,
                                   default = nil)
  if valid_21626642 != nil:
    section.add "X-Amz-Date", valid_21626642
  var valid_21626643 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626643 = validateParameter(valid_21626643, JString, required = false,
                                   default = nil)
  if valid_21626643 != nil:
    section.add "X-Amz-Security-Token", valid_21626643
  var valid_21626644 = header.getOrDefault("X-Amz-Target")
  valid_21626644 = validateParameter(valid_21626644, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteResourceServer"))
  if valid_21626644 != nil:
    section.add "X-Amz-Target", valid_21626644
  var valid_21626645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626645 = validateParameter(valid_21626645, JString, required = false,
                                   default = nil)
  if valid_21626645 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626645
  var valid_21626646 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626646 = validateParameter(valid_21626646, JString, required = false,
                                   default = nil)
  if valid_21626646 != nil:
    section.add "X-Amz-Algorithm", valid_21626646
  var valid_21626647 = header.getOrDefault("X-Amz-Signature")
  valid_21626647 = validateParameter(valid_21626647, JString, required = false,
                                   default = nil)
  if valid_21626647 != nil:
    section.add "X-Amz-Signature", valid_21626647
  var valid_21626648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626648 = validateParameter(valid_21626648, JString, required = false,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626648
  var valid_21626649 = header.getOrDefault("X-Amz-Credential")
  valid_21626649 = validateParameter(valid_21626649, JString, required = false,
                                   default = nil)
  if valid_21626649 != nil:
    section.add "X-Amz-Credential", valid_21626649
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

proc call*(call_21626651: Call_DeleteResourceServer_21626639; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a resource server.
  ## 
  let valid = call_21626651.validator(path, query, header, formData, body, _)
  let scheme = call_21626651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626651.makeUrl(scheme.get, call_21626651.host, call_21626651.base,
                               call_21626651.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626651, uri, valid, _)

proc call*(call_21626652: Call_DeleteResourceServer_21626639; body: JsonNode): Recallable =
  ## deleteResourceServer
  ## Deletes a resource server.
  ##   body: JObject (required)
  var body_21626653 = newJObject()
  if body != nil:
    body_21626653 = body
  result = call_21626652.call(nil, nil, nil, nil, body_21626653)

var deleteResourceServer* = Call_DeleteResourceServer_21626639(
    name: "deleteResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteResourceServer",
    validator: validate_DeleteResourceServer_21626640, base: "/",
    makeUrl: url_DeleteResourceServer_21626641,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_21626654 = ref object of OpenApiRestCall_21625435
proc url_DeleteUser_21626656(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUser_21626655(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626657 = header.getOrDefault("X-Amz-Date")
  valid_21626657 = validateParameter(valid_21626657, JString, required = false,
                                   default = nil)
  if valid_21626657 != nil:
    section.add "X-Amz-Date", valid_21626657
  var valid_21626658 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626658 = validateParameter(valid_21626658, JString, required = false,
                                   default = nil)
  if valid_21626658 != nil:
    section.add "X-Amz-Security-Token", valid_21626658
  var valid_21626659 = header.getOrDefault("X-Amz-Target")
  valid_21626659 = validateParameter(valid_21626659, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUser"))
  if valid_21626659 != nil:
    section.add "X-Amz-Target", valid_21626659
  var valid_21626660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626660 = validateParameter(valid_21626660, JString, required = false,
                                   default = nil)
  if valid_21626660 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626660
  var valid_21626661 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626661 = validateParameter(valid_21626661, JString, required = false,
                                   default = nil)
  if valid_21626661 != nil:
    section.add "X-Amz-Algorithm", valid_21626661
  var valid_21626662 = header.getOrDefault("X-Amz-Signature")
  valid_21626662 = validateParameter(valid_21626662, JString, required = false,
                                   default = nil)
  if valid_21626662 != nil:
    section.add "X-Amz-Signature", valid_21626662
  var valid_21626663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626663 = validateParameter(valid_21626663, JString, required = false,
                                   default = nil)
  if valid_21626663 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626663
  var valid_21626664 = header.getOrDefault("X-Amz-Credential")
  valid_21626664 = validateParameter(valid_21626664, JString, required = false,
                                   default = nil)
  if valid_21626664 != nil:
    section.add "X-Amz-Credential", valid_21626664
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

proc call*(call_21626666: Call_DeleteUser_21626654; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Allows a user to delete himself or herself.
  ## 
  let valid = call_21626666.validator(path, query, header, formData, body, _)
  let scheme = call_21626666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626666.makeUrl(scheme.get, call_21626666.host, call_21626666.base,
                               call_21626666.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626666, uri, valid, _)

proc call*(call_21626667: Call_DeleteUser_21626654; body: JsonNode): Recallable =
  ## deleteUser
  ## Allows a user to delete himself or herself.
  ##   body: JObject (required)
  var body_21626668 = newJObject()
  if body != nil:
    body_21626668 = body
  result = call_21626667.call(nil, nil, nil, nil, body_21626668)

var deleteUser* = Call_DeleteUser_21626654(name: "deleteUser",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUser",
                                        validator: validate_DeleteUser_21626655,
                                        base: "/", makeUrl: url_DeleteUser_21626656,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserAttributes_21626669 = ref object of OpenApiRestCall_21625435
proc url_DeleteUserAttributes_21626671(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUserAttributes_21626670(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626672 = header.getOrDefault("X-Amz-Date")
  valid_21626672 = validateParameter(valid_21626672, JString, required = false,
                                   default = nil)
  if valid_21626672 != nil:
    section.add "X-Amz-Date", valid_21626672
  var valid_21626673 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626673 = validateParameter(valid_21626673, JString, required = false,
                                   default = nil)
  if valid_21626673 != nil:
    section.add "X-Amz-Security-Token", valid_21626673
  var valid_21626674 = header.getOrDefault("X-Amz-Target")
  valid_21626674 = validateParameter(valid_21626674, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUserAttributes"))
  if valid_21626674 != nil:
    section.add "X-Amz-Target", valid_21626674
  var valid_21626675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626675 = validateParameter(valid_21626675, JString, required = false,
                                   default = nil)
  if valid_21626675 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626675
  var valid_21626676 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626676 = validateParameter(valid_21626676, JString, required = false,
                                   default = nil)
  if valid_21626676 != nil:
    section.add "X-Amz-Algorithm", valid_21626676
  var valid_21626677 = header.getOrDefault("X-Amz-Signature")
  valid_21626677 = validateParameter(valid_21626677, JString, required = false,
                                   default = nil)
  if valid_21626677 != nil:
    section.add "X-Amz-Signature", valid_21626677
  var valid_21626678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626678 = validateParameter(valid_21626678, JString, required = false,
                                   default = nil)
  if valid_21626678 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626678
  var valid_21626679 = header.getOrDefault("X-Amz-Credential")
  valid_21626679 = validateParameter(valid_21626679, JString, required = false,
                                   default = nil)
  if valid_21626679 != nil:
    section.add "X-Amz-Credential", valid_21626679
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

proc call*(call_21626681: Call_DeleteUserAttributes_21626669; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the attributes for a user.
  ## 
  let valid = call_21626681.validator(path, query, header, formData, body, _)
  let scheme = call_21626681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626681.makeUrl(scheme.get, call_21626681.host, call_21626681.base,
                               call_21626681.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626681, uri, valid, _)

proc call*(call_21626682: Call_DeleteUserAttributes_21626669; body: JsonNode): Recallable =
  ## deleteUserAttributes
  ## Deletes the attributes for a user.
  ##   body: JObject (required)
  var body_21626683 = newJObject()
  if body != nil:
    body_21626683 = body
  result = call_21626682.call(nil, nil, nil, nil, body_21626683)

var deleteUserAttributes* = Call_DeleteUserAttributes_21626669(
    name: "deleteUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserAttributes",
    validator: validate_DeleteUserAttributes_21626670, base: "/",
    makeUrl: url_DeleteUserAttributes_21626671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserPool_21626684 = ref object of OpenApiRestCall_21625435
proc url_DeleteUserPool_21626686(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUserPool_21626685(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626687 = header.getOrDefault("X-Amz-Date")
  valid_21626687 = validateParameter(valid_21626687, JString, required = false,
                                   default = nil)
  if valid_21626687 != nil:
    section.add "X-Amz-Date", valid_21626687
  var valid_21626688 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626688 = validateParameter(valid_21626688, JString, required = false,
                                   default = nil)
  if valid_21626688 != nil:
    section.add "X-Amz-Security-Token", valid_21626688
  var valid_21626689 = header.getOrDefault("X-Amz-Target")
  valid_21626689 = validateParameter(valid_21626689, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUserPool"))
  if valid_21626689 != nil:
    section.add "X-Amz-Target", valid_21626689
  var valid_21626690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626690 = validateParameter(valid_21626690, JString, required = false,
                                   default = nil)
  if valid_21626690 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626690
  var valid_21626691 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626691 = validateParameter(valid_21626691, JString, required = false,
                                   default = nil)
  if valid_21626691 != nil:
    section.add "X-Amz-Algorithm", valid_21626691
  var valid_21626692 = header.getOrDefault("X-Amz-Signature")
  valid_21626692 = validateParameter(valid_21626692, JString, required = false,
                                   default = nil)
  if valid_21626692 != nil:
    section.add "X-Amz-Signature", valid_21626692
  var valid_21626693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626693 = validateParameter(valid_21626693, JString, required = false,
                                   default = nil)
  if valid_21626693 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626693
  var valid_21626694 = header.getOrDefault("X-Amz-Credential")
  valid_21626694 = validateParameter(valid_21626694, JString, required = false,
                                   default = nil)
  if valid_21626694 != nil:
    section.add "X-Amz-Credential", valid_21626694
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

proc call*(call_21626696: Call_DeleteUserPool_21626684; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified Amazon Cognito user pool.
  ## 
  let valid = call_21626696.validator(path, query, header, formData, body, _)
  let scheme = call_21626696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626696.makeUrl(scheme.get, call_21626696.host, call_21626696.base,
                               call_21626696.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626696, uri, valid, _)

proc call*(call_21626697: Call_DeleteUserPool_21626684; body: JsonNode): Recallable =
  ## deleteUserPool
  ## Deletes the specified Amazon Cognito user pool.
  ##   body: JObject (required)
  var body_21626698 = newJObject()
  if body != nil:
    body_21626698 = body
  result = call_21626697.call(nil, nil, nil, nil, body_21626698)

var deleteUserPool* = Call_DeleteUserPool_21626684(name: "deleteUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserPool",
    validator: validate_DeleteUserPool_21626685, base: "/",
    makeUrl: url_DeleteUserPool_21626686, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserPoolClient_21626699 = ref object of OpenApiRestCall_21625435
proc url_DeleteUserPoolClient_21626701(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUserPoolClient_21626700(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626702 = header.getOrDefault("X-Amz-Date")
  valid_21626702 = validateParameter(valid_21626702, JString, required = false,
                                   default = nil)
  if valid_21626702 != nil:
    section.add "X-Amz-Date", valid_21626702
  var valid_21626703 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626703 = validateParameter(valid_21626703, JString, required = false,
                                   default = nil)
  if valid_21626703 != nil:
    section.add "X-Amz-Security-Token", valid_21626703
  var valid_21626704 = header.getOrDefault("X-Amz-Target")
  valid_21626704 = validateParameter(valid_21626704, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUserPoolClient"))
  if valid_21626704 != nil:
    section.add "X-Amz-Target", valid_21626704
  var valid_21626705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626705 = validateParameter(valid_21626705, JString, required = false,
                                   default = nil)
  if valid_21626705 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626705
  var valid_21626706 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626706 = validateParameter(valid_21626706, JString, required = false,
                                   default = nil)
  if valid_21626706 != nil:
    section.add "X-Amz-Algorithm", valid_21626706
  var valid_21626707 = header.getOrDefault("X-Amz-Signature")
  valid_21626707 = validateParameter(valid_21626707, JString, required = false,
                                   default = nil)
  if valid_21626707 != nil:
    section.add "X-Amz-Signature", valid_21626707
  var valid_21626708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626708 = validateParameter(valid_21626708, JString, required = false,
                                   default = nil)
  if valid_21626708 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626708
  var valid_21626709 = header.getOrDefault("X-Amz-Credential")
  valid_21626709 = validateParameter(valid_21626709, JString, required = false,
                                   default = nil)
  if valid_21626709 != nil:
    section.add "X-Amz-Credential", valid_21626709
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

proc call*(call_21626711: Call_DeleteUserPoolClient_21626699; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Allows the developer to delete the user pool client.
  ## 
  let valid = call_21626711.validator(path, query, header, formData, body, _)
  let scheme = call_21626711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626711.makeUrl(scheme.get, call_21626711.host, call_21626711.base,
                               call_21626711.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626711, uri, valid, _)

proc call*(call_21626712: Call_DeleteUserPoolClient_21626699; body: JsonNode): Recallable =
  ## deleteUserPoolClient
  ## Allows the developer to delete the user pool client.
  ##   body: JObject (required)
  var body_21626713 = newJObject()
  if body != nil:
    body_21626713 = body
  result = call_21626712.call(nil, nil, nil, nil, body_21626713)

var deleteUserPoolClient* = Call_DeleteUserPoolClient_21626699(
    name: "deleteUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserPoolClient",
    validator: validate_DeleteUserPoolClient_21626700, base: "/",
    makeUrl: url_DeleteUserPoolClient_21626701,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserPoolDomain_21626714 = ref object of OpenApiRestCall_21625435
proc url_DeleteUserPoolDomain_21626716(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUserPoolDomain_21626715(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626717 = header.getOrDefault("X-Amz-Date")
  valid_21626717 = validateParameter(valid_21626717, JString, required = false,
                                   default = nil)
  if valid_21626717 != nil:
    section.add "X-Amz-Date", valid_21626717
  var valid_21626718 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626718 = validateParameter(valid_21626718, JString, required = false,
                                   default = nil)
  if valid_21626718 != nil:
    section.add "X-Amz-Security-Token", valid_21626718
  var valid_21626719 = header.getOrDefault("X-Amz-Target")
  valid_21626719 = validateParameter(valid_21626719, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUserPoolDomain"))
  if valid_21626719 != nil:
    section.add "X-Amz-Target", valid_21626719
  var valid_21626720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626720 = validateParameter(valid_21626720, JString, required = false,
                                   default = nil)
  if valid_21626720 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626720
  var valid_21626721 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626721 = validateParameter(valid_21626721, JString, required = false,
                                   default = nil)
  if valid_21626721 != nil:
    section.add "X-Amz-Algorithm", valid_21626721
  var valid_21626722 = header.getOrDefault("X-Amz-Signature")
  valid_21626722 = validateParameter(valid_21626722, JString, required = false,
                                   default = nil)
  if valid_21626722 != nil:
    section.add "X-Amz-Signature", valid_21626722
  var valid_21626723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626723 = validateParameter(valid_21626723, JString, required = false,
                                   default = nil)
  if valid_21626723 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626723
  var valid_21626724 = header.getOrDefault("X-Amz-Credential")
  valid_21626724 = validateParameter(valid_21626724, JString, required = false,
                                   default = nil)
  if valid_21626724 != nil:
    section.add "X-Amz-Credential", valid_21626724
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

proc call*(call_21626726: Call_DeleteUserPoolDomain_21626714; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a domain for a user pool.
  ## 
  let valid = call_21626726.validator(path, query, header, formData, body, _)
  let scheme = call_21626726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626726.makeUrl(scheme.get, call_21626726.host, call_21626726.base,
                               call_21626726.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626726, uri, valid, _)

proc call*(call_21626727: Call_DeleteUserPoolDomain_21626714; body: JsonNode): Recallable =
  ## deleteUserPoolDomain
  ## Deletes a domain for a user pool.
  ##   body: JObject (required)
  var body_21626728 = newJObject()
  if body != nil:
    body_21626728 = body
  result = call_21626727.call(nil, nil, nil, nil, body_21626728)

var deleteUserPoolDomain* = Call_DeleteUserPoolDomain_21626714(
    name: "deleteUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserPoolDomain",
    validator: validate_DeleteUserPoolDomain_21626715, base: "/",
    makeUrl: url_DeleteUserPoolDomain_21626716,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentityProvider_21626729 = ref object of OpenApiRestCall_21625435
proc url_DescribeIdentityProvider_21626731(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeIdentityProvider_21626730(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626732 = header.getOrDefault("X-Amz-Date")
  valid_21626732 = validateParameter(valid_21626732, JString, required = false,
                                   default = nil)
  if valid_21626732 != nil:
    section.add "X-Amz-Date", valid_21626732
  var valid_21626733 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626733 = validateParameter(valid_21626733, JString, required = false,
                                   default = nil)
  if valid_21626733 != nil:
    section.add "X-Amz-Security-Token", valid_21626733
  var valid_21626734 = header.getOrDefault("X-Amz-Target")
  valid_21626734 = validateParameter(valid_21626734, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeIdentityProvider"))
  if valid_21626734 != nil:
    section.add "X-Amz-Target", valid_21626734
  var valid_21626735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626735 = validateParameter(valid_21626735, JString, required = false,
                                   default = nil)
  if valid_21626735 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626735
  var valid_21626736 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626736 = validateParameter(valid_21626736, JString, required = false,
                                   default = nil)
  if valid_21626736 != nil:
    section.add "X-Amz-Algorithm", valid_21626736
  var valid_21626737 = header.getOrDefault("X-Amz-Signature")
  valid_21626737 = validateParameter(valid_21626737, JString, required = false,
                                   default = nil)
  if valid_21626737 != nil:
    section.add "X-Amz-Signature", valid_21626737
  var valid_21626738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626738 = validateParameter(valid_21626738, JString, required = false,
                                   default = nil)
  if valid_21626738 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626738
  var valid_21626739 = header.getOrDefault("X-Amz-Credential")
  valid_21626739 = validateParameter(valid_21626739, JString, required = false,
                                   default = nil)
  if valid_21626739 != nil:
    section.add "X-Amz-Credential", valid_21626739
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

proc call*(call_21626741: Call_DescribeIdentityProvider_21626729;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a specific identity provider.
  ## 
  let valid = call_21626741.validator(path, query, header, formData, body, _)
  let scheme = call_21626741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626741.makeUrl(scheme.get, call_21626741.host, call_21626741.base,
                               call_21626741.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626741, uri, valid, _)

proc call*(call_21626742: Call_DescribeIdentityProvider_21626729; body: JsonNode): Recallable =
  ## describeIdentityProvider
  ## Gets information about a specific identity provider.
  ##   body: JObject (required)
  var body_21626743 = newJObject()
  if body != nil:
    body_21626743 = body
  result = call_21626742.call(nil, nil, nil, nil, body_21626743)

var describeIdentityProvider* = Call_DescribeIdentityProvider_21626729(
    name: "describeIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeIdentityProvider",
    validator: validate_DescribeIdentityProvider_21626730, base: "/",
    makeUrl: url_DescribeIdentityProvider_21626731,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResourceServer_21626744 = ref object of OpenApiRestCall_21625435
proc url_DescribeResourceServer_21626746(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeResourceServer_21626745(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626747 = header.getOrDefault("X-Amz-Date")
  valid_21626747 = validateParameter(valid_21626747, JString, required = false,
                                   default = nil)
  if valid_21626747 != nil:
    section.add "X-Amz-Date", valid_21626747
  var valid_21626748 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626748 = validateParameter(valid_21626748, JString, required = false,
                                   default = nil)
  if valid_21626748 != nil:
    section.add "X-Amz-Security-Token", valid_21626748
  var valid_21626749 = header.getOrDefault("X-Amz-Target")
  valid_21626749 = validateParameter(valid_21626749, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeResourceServer"))
  if valid_21626749 != nil:
    section.add "X-Amz-Target", valid_21626749
  var valid_21626750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626750 = validateParameter(valid_21626750, JString, required = false,
                                   default = nil)
  if valid_21626750 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626750
  var valid_21626751 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626751 = validateParameter(valid_21626751, JString, required = false,
                                   default = nil)
  if valid_21626751 != nil:
    section.add "X-Amz-Algorithm", valid_21626751
  var valid_21626752 = header.getOrDefault("X-Amz-Signature")
  valid_21626752 = validateParameter(valid_21626752, JString, required = false,
                                   default = nil)
  if valid_21626752 != nil:
    section.add "X-Amz-Signature", valid_21626752
  var valid_21626753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626753 = validateParameter(valid_21626753, JString, required = false,
                                   default = nil)
  if valid_21626753 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626753
  var valid_21626754 = header.getOrDefault("X-Amz-Credential")
  valid_21626754 = validateParameter(valid_21626754, JString, required = false,
                                   default = nil)
  if valid_21626754 != nil:
    section.add "X-Amz-Credential", valid_21626754
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

proc call*(call_21626756: Call_DescribeResourceServer_21626744;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes a resource server.
  ## 
  let valid = call_21626756.validator(path, query, header, formData, body, _)
  let scheme = call_21626756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626756.makeUrl(scheme.get, call_21626756.host, call_21626756.base,
                               call_21626756.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626756, uri, valid, _)

proc call*(call_21626757: Call_DescribeResourceServer_21626744; body: JsonNode): Recallable =
  ## describeResourceServer
  ## Describes a resource server.
  ##   body: JObject (required)
  var body_21626758 = newJObject()
  if body != nil:
    body_21626758 = body
  result = call_21626757.call(nil, nil, nil, nil, body_21626758)

var describeResourceServer* = Call_DescribeResourceServer_21626744(
    name: "describeResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeResourceServer",
    validator: validate_DescribeResourceServer_21626745, base: "/",
    makeUrl: url_DescribeResourceServer_21626746,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRiskConfiguration_21626759 = ref object of OpenApiRestCall_21625435
proc url_DescribeRiskConfiguration_21626761(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeRiskConfiguration_21626760(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626762 = header.getOrDefault("X-Amz-Date")
  valid_21626762 = validateParameter(valid_21626762, JString, required = false,
                                   default = nil)
  if valid_21626762 != nil:
    section.add "X-Amz-Date", valid_21626762
  var valid_21626763 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626763 = validateParameter(valid_21626763, JString, required = false,
                                   default = nil)
  if valid_21626763 != nil:
    section.add "X-Amz-Security-Token", valid_21626763
  var valid_21626764 = header.getOrDefault("X-Amz-Target")
  valid_21626764 = validateParameter(valid_21626764, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeRiskConfiguration"))
  if valid_21626764 != nil:
    section.add "X-Amz-Target", valid_21626764
  var valid_21626765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626765 = validateParameter(valid_21626765, JString, required = false,
                                   default = nil)
  if valid_21626765 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626765
  var valid_21626766 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626766 = validateParameter(valid_21626766, JString, required = false,
                                   default = nil)
  if valid_21626766 != nil:
    section.add "X-Amz-Algorithm", valid_21626766
  var valid_21626767 = header.getOrDefault("X-Amz-Signature")
  valid_21626767 = validateParameter(valid_21626767, JString, required = false,
                                   default = nil)
  if valid_21626767 != nil:
    section.add "X-Amz-Signature", valid_21626767
  var valid_21626768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626768 = validateParameter(valid_21626768, JString, required = false,
                                   default = nil)
  if valid_21626768 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626768
  var valid_21626769 = header.getOrDefault("X-Amz-Credential")
  valid_21626769 = validateParameter(valid_21626769, JString, required = false,
                                   default = nil)
  if valid_21626769 != nil:
    section.add "X-Amz-Credential", valid_21626769
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

proc call*(call_21626771: Call_DescribeRiskConfiguration_21626759;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the risk configuration.
  ## 
  let valid = call_21626771.validator(path, query, header, formData, body, _)
  let scheme = call_21626771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626771.makeUrl(scheme.get, call_21626771.host, call_21626771.base,
                               call_21626771.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626771, uri, valid, _)

proc call*(call_21626772: Call_DescribeRiskConfiguration_21626759; body: JsonNode): Recallable =
  ## describeRiskConfiguration
  ## Describes the risk configuration.
  ##   body: JObject (required)
  var body_21626773 = newJObject()
  if body != nil:
    body_21626773 = body
  result = call_21626772.call(nil, nil, nil, nil, body_21626773)

var describeRiskConfiguration* = Call_DescribeRiskConfiguration_21626759(
    name: "describeRiskConfiguration", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeRiskConfiguration",
    validator: validate_DescribeRiskConfiguration_21626760, base: "/",
    makeUrl: url_DescribeRiskConfiguration_21626761,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserImportJob_21626774 = ref object of OpenApiRestCall_21625435
proc url_DescribeUserImportJob_21626776(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUserImportJob_21626775(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626777 = header.getOrDefault("X-Amz-Date")
  valid_21626777 = validateParameter(valid_21626777, JString, required = false,
                                   default = nil)
  if valid_21626777 != nil:
    section.add "X-Amz-Date", valid_21626777
  var valid_21626778 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626778 = validateParameter(valid_21626778, JString, required = false,
                                   default = nil)
  if valid_21626778 != nil:
    section.add "X-Amz-Security-Token", valid_21626778
  var valid_21626779 = header.getOrDefault("X-Amz-Target")
  valid_21626779 = validateParameter(valid_21626779, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserImportJob"))
  if valid_21626779 != nil:
    section.add "X-Amz-Target", valid_21626779
  var valid_21626780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626780 = validateParameter(valid_21626780, JString, required = false,
                                   default = nil)
  if valid_21626780 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626780
  var valid_21626781 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626781 = validateParameter(valid_21626781, JString, required = false,
                                   default = nil)
  if valid_21626781 != nil:
    section.add "X-Amz-Algorithm", valid_21626781
  var valid_21626782 = header.getOrDefault("X-Amz-Signature")
  valid_21626782 = validateParameter(valid_21626782, JString, required = false,
                                   default = nil)
  if valid_21626782 != nil:
    section.add "X-Amz-Signature", valid_21626782
  var valid_21626783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626783 = validateParameter(valid_21626783, JString, required = false,
                                   default = nil)
  if valid_21626783 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626783
  var valid_21626784 = header.getOrDefault("X-Amz-Credential")
  valid_21626784 = validateParameter(valid_21626784, JString, required = false,
                                   default = nil)
  if valid_21626784 != nil:
    section.add "X-Amz-Credential", valid_21626784
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

proc call*(call_21626786: Call_DescribeUserImportJob_21626774;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the user import job.
  ## 
  let valid = call_21626786.validator(path, query, header, formData, body, _)
  let scheme = call_21626786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626786.makeUrl(scheme.get, call_21626786.host, call_21626786.base,
                               call_21626786.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626786, uri, valid, _)

proc call*(call_21626787: Call_DescribeUserImportJob_21626774; body: JsonNode): Recallable =
  ## describeUserImportJob
  ## Describes the user import job.
  ##   body: JObject (required)
  var body_21626788 = newJObject()
  if body != nil:
    body_21626788 = body
  result = call_21626787.call(nil, nil, nil, nil, body_21626788)

var describeUserImportJob* = Call_DescribeUserImportJob_21626774(
    name: "describeUserImportJob", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserImportJob",
    validator: validate_DescribeUserImportJob_21626775, base: "/",
    makeUrl: url_DescribeUserImportJob_21626776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserPool_21626789 = ref object of OpenApiRestCall_21625435
proc url_DescribeUserPool_21626791(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUserPool_21626790(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626792 = header.getOrDefault("X-Amz-Date")
  valid_21626792 = validateParameter(valid_21626792, JString, required = false,
                                   default = nil)
  if valid_21626792 != nil:
    section.add "X-Amz-Date", valid_21626792
  var valid_21626793 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626793 = validateParameter(valid_21626793, JString, required = false,
                                   default = nil)
  if valid_21626793 != nil:
    section.add "X-Amz-Security-Token", valid_21626793
  var valid_21626794 = header.getOrDefault("X-Amz-Target")
  valid_21626794 = validateParameter(valid_21626794, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserPool"))
  if valid_21626794 != nil:
    section.add "X-Amz-Target", valid_21626794
  var valid_21626795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626795 = validateParameter(valid_21626795, JString, required = false,
                                   default = nil)
  if valid_21626795 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626795
  var valid_21626796 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626796 = validateParameter(valid_21626796, JString, required = false,
                                   default = nil)
  if valid_21626796 != nil:
    section.add "X-Amz-Algorithm", valid_21626796
  var valid_21626797 = header.getOrDefault("X-Amz-Signature")
  valid_21626797 = validateParameter(valid_21626797, JString, required = false,
                                   default = nil)
  if valid_21626797 != nil:
    section.add "X-Amz-Signature", valid_21626797
  var valid_21626798 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626798 = validateParameter(valid_21626798, JString, required = false,
                                   default = nil)
  if valid_21626798 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626798
  var valid_21626799 = header.getOrDefault("X-Amz-Credential")
  valid_21626799 = validateParameter(valid_21626799, JString, required = false,
                                   default = nil)
  if valid_21626799 != nil:
    section.add "X-Amz-Credential", valid_21626799
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

proc call*(call_21626801: Call_DescribeUserPool_21626789; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the configuration information and metadata of the specified user pool.
  ## 
  let valid = call_21626801.validator(path, query, header, formData, body, _)
  let scheme = call_21626801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626801.makeUrl(scheme.get, call_21626801.host, call_21626801.base,
                               call_21626801.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626801, uri, valid, _)

proc call*(call_21626802: Call_DescribeUserPool_21626789; body: JsonNode): Recallable =
  ## describeUserPool
  ## Returns the configuration information and metadata of the specified user pool.
  ##   body: JObject (required)
  var body_21626803 = newJObject()
  if body != nil:
    body_21626803 = body
  result = call_21626802.call(nil, nil, nil, nil, body_21626803)

var describeUserPool* = Call_DescribeUserPool_21626789(name: "describeUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserPool",
    validator: validate_DescribeUserPool_21626790, base: "/",
    makeUrl: url_DescribeUserPool_21626791, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserPoolClient_21626804 = ref object of OpenApiRestCall_21625435
proc url_DescribeUserPoolClient_21626806(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUserPoolClient_21626805(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626807 = header.getOrDefault("X-Amz-Date")
  valid_21626807 = validateParameter(valid_21626807, JString, required = false,
                                   default = nil)
  if valid_21626807 != nil:
    section.add "X-Amz-Date", valid_21626807
  var valid_21626808 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626808 = validateParameter(valid_21626808, JString, required = false,
                                   default = nil)
  if valid_21626808 != nil:
    section.add "X-Amz-Security-Token", valid_21626808
  var valid_21626809 = header.getOrDefault("X-Amz-Target")
  valid_21626809 = validateParameter(valid_21626809, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserPoolClient"))
  if valid_21626809 != nil:
    section.add "X-Amz-Target", valid_21626809
  var valid_21626810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626810 = validateParameter(valid_21626810, JString, required = false,
                                   default = nil)
  if valid_21626810 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626810
  var valid_21626811 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626811 = validateParameter(valid_21626811, JString, required = false,
                                   default = nil)
  if valid_21626811 != nil:
    section.add "X-Amz-Algorithm", valid_21626811
  var valid_21626812 = header.getOrDefault("X-Amz-Signature")
  valid_21626812 = validateParameter(valid_21626812, JString, required = false,
                                   default = nil)
  if valid_21626812 != nil:
    section.add "X-Amz-Signature", valid_21626812
  var valid_21626813 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626813 = validateParameter(valid_21626813, JString, required = false,
                                   default = nil)
  if valid_21626813 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626813
  var valid_21626814 = header.getOrDefault("X-Amz-Credential")
  valid_21626814 = validateParameter(valid_21626814, JString, required = false,
                                   default = nil)
  if valid_21626814 != nil:
    section.add "X-Amz-Credential", valid_21626814
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

proc call*(call_21626816: Call_DescribeUserPoolClient_21626804;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Client method for returning the configuration information and metadata of the specified user pool app client.
  ## 
  let valid = call_21626816.validator(path, query, header, formData, body, _)
  let scheme = call_21626816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626816.makeUrl(scheme.get, call_21626816.host, call_21626816.base,
                               call_21626816.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626816, uri, valid, _)

proc call*(call_21626817: Call_DescribeUserPoolClient_21626804; body: JsonNode): Recallable =
  ## describeUserPoolClient
  ## Client method for returning the configuration information and metadata of the specified user pool app client.
  ##   body: JObject (required)
  var body_21626818 = newJObject()
  if body != nil:
    body_21626818 = body
  result = call_21626817.call(nil, nil, nil, nil, body_21626818)

var describeUserPoolClient* = Call_DescribeUserPoolClient_21626804(
    name: "describeUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserPoolClient",
    validator: validate_DescribeUserPoolClient_21626805, base: "/",
    makeUrl: url_DescribeUserPoolClient_21626806,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserPoolDomain_21626819 = ref object of OpenApiRestCall_21625435
proc url_DescribeUserPoolDomain_21626821(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUserPoolDomain_21626820(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626822 = header.getOrDefault("X-Amz-Date")
  valid_21626822 = validateParameter(valid_21626822, JString, required = false,
                                   default = nil)
  if valid_21626822 != nil:
    section.add "X-Amz-Date", valid_21626822
  var valid_21626823 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626823 = validateParameter(valid_21626823, JString, required = false,
                                   default = nil)
  if valid_21626823 != nil:
    section.add "X-Amz-Security-Token", valid_21626823
  var valid_21626824 = header.getOrDefault("X-Amz-Target")
  valid_21626824 = validateParameter(valid_21626824, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserPoolDomain"))
  if valid_21626824 != nil:
    section.add "X-Amz-Target", valid_21626824
  var valid_21626825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626825 = validateParameter(valid_21626825, JString, required = false,
                                   default = nil)
  if valid_21626825 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626825
  var valid_21626826 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626826 = validateParameter(valid_21626826, JString, required = false,
                                   default = nil)
  if valid_21626826 != nil:
    section.add "X-Amz-Algorithm", valid_21626826
  var valid_21626827 = header.getOrDefault("X-Amz-Signature")
  valid_21626827 = validateParameter(valid_21626827, JString, required = false,
                                   default = nil)
  if valid_21626827 != nil:
    section.add "X-Amz-Signature", valid_21626827
  var valid_21626828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626828 = validateParameter(valid_21626828, JString, required = false,
                                   default = nil)
  if valid_21626828 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626828
  var valid_21626829 = header.getOrDefault("X-Amz-Credential")
  valid_21626829 = validateParameter(valid_21626829, JString, required = false,
                                   default = nil)
  if valid_21626829 != nil:
    section.add "X-Amz-Credential", valid_21626829
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

proc call*(call_21626831: Call_DescribeUserPoolDomain_21626819;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a domain.
  ## 
  let valid = call_21626831.validator(path, query, header, formData, body, _)
  let scheme = call_21626831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626831.makeUrl(scheme.get, call_21626831.host, call_21626831.base,
                               call_21626831.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626831, uri, valid, _)

proc call*(call_21626832: Call_DescribeUserPoolDomain_21626819; body: JsonNode): Recallable =
  ## describeUserPoolDomain
  ## Gets information about a domain.
  ##   body: JObject (required)
  var body_21626833 = newJObject()
  if body != nil:
    body_21626833 = body
  result = call_21626832.call(nil, nil, nil, nil, body_21626833)

var describeUserPoolDomain* = Call_DescribeUserPoolDomain_21626819(
    name: "describeUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserPoolDomain",
    validator: validate_DescribeUserPoolDomain_21626820, base: "/",
    makeUrl: url_DescribeUserPoolDomain_21626821,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ForgetDevice_21626834 = ref object of OpenApiRestCall_21625435
proc url_ForgetDevice_21626836(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ForgetDevice_21626835(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626837 = header.getOrDefault("X-Amz-Date")
  valid_21626837 = validateParameter(valid_21626837, JString, required = false,
                                   default = nil)
  if valid_21626837 != nil:
    section.add "X-Amz-Date", valid_21626837
  var valid_21626838 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626838 = validateParameter(valid_21626838, JString, required = false,
                                   default = nil)
  if valid_21626838 != nil:
    section.add "X-Amz-Security-Token", valid_21626838
  var valid_21626839 = header.getOrDefault("X-Amz-Target")
  valid_21626839 = validateParameter(valid_21626839, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ForgetDevice"))
  if valid_21626839 != nil:
    section.add "X-Amz-Target", valid_21626839
  var valid_21626840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626840 = validateParameter(valid_21626840, JString, required = false,
                                   default = nil)
  if valid_21626840 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626840
  var valid_21626841 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626841 = validateParameter(valid_21626841, JString, required = false,
                                   default = nil)
  if valid_21626841 != nil:
    section.add "X-Amz-Algorithm", valid_21626841
  var valid_21626842 = header.getOrDefault("X-Amz-Signature")
  valid_21626842 = validateParameter(valid_21626842, JString, required = false,
                                   default = nil)
  if valid_21626842 != nil:
    section.add "X-Amz-Signature", valid_21626842
  var valid_21626843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626843 = validateParameter(valid_21626843, JString, required = false,
                                   default = nil)
  if valid_21626843 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626843
  var valid_21626844 = header.getOrDefault("X-Amz-Credential")
  valid_21626844 = validateParameter(valid_21626844, JString, required = false,
                                   default = nil)
  if valid_21626844 != nil:
    section.add "X-Amz-Credential", valid_21626844
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

proc call*(call_21626846: Call_ForgetDevice_21626834; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Forgets the specified device.
  ## 
  let valid = call_21626846.validator(path, query, header, formData, body, _)
  let scheme = call_21626846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626846.makeUrl(scheme.get, call_21626846.host, call_21626846.base,
                               call_21626846.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626846, uri, valid, _)

proc call*(call_21626847: Call_ForgetDevice_21626834; body: JsonNode): Recallable =
  ## forgetDevice
  ## Forgets the specified device.
  ##   body: JObject (required)
  var body_21626848 = newJObject()
  if body != nil:
    body_21626848 = body
  result = call_21626847.call(nil, nil, nil, nil, body_21626848)

var forgetDevice* = Call_ForgetDevice_21626834(name: "forgetDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ForgetDevice",
    validator: validate_ForgetDevice_21626835, base: "/", makeUrl: url_ForgetDevice_21626836,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ForgotPassword_21626849 = ref object of OpenApiRestCall_21625435
proc url_ForgotPassword_21626851(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ForgotPassword_21626850(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626852 = header.getOrDefault("X-Amz-Date")
  valid_21626852 = validateParameter(valid_21626852, JString, required = false,
                                   default = nil)
  if valid_21626852 != nil:
    section.add "X-Amz-Date", valid_21626852
  var valid_21626853 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626853 = validateParameter(valid_21626853, JString, required = false,
                                   default = nil)
  if valid_21626853 != nil:
    section.add "X-Amz-Security-Token", valid_21626853
  var valid_21626854 = header.getOrDefault("X-Amz-Target")
  valid_21626854 = validateParameter(valid_21626854, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ForgotPassword"))
  if valid_21626854 != nil:
    section.add "X-Amz-Target", valid_21626854
  var valid_21626855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626855 = validateParameter(valid_21626855, JString, required = false,
                                   default = nil)
  if valid_21626855 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626855
  var valid_21626856 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626856 = validateParameter(valid_21626856, JString, required = false,
                                   default = nil)
  if valid_21626856 != nil:
    section.add "X-Amz-Algorithm", valid_21626856
  var valid_21626857 = header.getOrDefault("X-Amz-Signature")
  valid_21626857 = validateParameter(valid_21626857, JString, required = false,
                                   default = nil)
  if valid_21626857 != nil:
    section.add "X-Amz-Signature", valid_21626857
  var valid_21626858 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626858 = validateParameter(valid_21626858, JString, required = false,
                                   default = nil)
  if valid_21626858 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626858
  var valid_21626859 = header.getOrDefault("X-Amz-Credential")
  valid_21626859 = validateParameter(valid_21626859, JString, required = false,
                                   default = nil)
  if valid_21626859 != nil:
    section.add "X-Amz-Credential", valid_21626859
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

proc call*(call_21626861: Call_ForgotPassword_21626849; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Calling this API causes a message to be sent to the end user with a confirmation code that is required to change the user's password. For the <code>Username</code> parameter, you can use the username or user alias. If a verified phone number exists for the user, the confirmation code is sent to the phone number. Otherwise, if a verified email exists, the confirmation code is sent to the email. If neither a verified phone number nor a verified email exists, <code>InvalidParameterException</code> is thrown. To use the confirmation code for resetting the password, call .
  ## 
  let valid = call_21626861.validator(path, query, header, formData, body, _)
  let scheme = call_21626861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626861.makeUrl(scheme.get, call_21626861.host, call_21626861.base,
                               call_21626861.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626861, uri, valid, _)

proc call*(call_21626862: Call_ForgotPassword_21626849; body: JsonNode): Recallable =
  ## forgotPassword
  ## Calling this API causes a message to be sent to the end user with a confirmation code that is required to change the user's password. For the <code>Username</code> parameter, you can use the username or user alias. If a verified phone number exists for the user, the confirmation code is sent to the phone number. Otherwise, if a verified email exists, the confirmation code is sent to the email. If neither a verified phone number nor a verified email exists, <code>InvalidParameterException</code> is thrown. To use the confirmation code for resetting the password, call .
  ##   body: JObject (required)
  var body_21626863 = newJObject()
  if body != nil:
    body_21626863 = body
  result = call_21626862.call(nil, nil, nil, nil, body_21626863)

var forgotPassword* = Call_ForgotPassword_21626849(name: "forgotPassword",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ForgotPassword",
    validator: validate_ForgotPassword_21626850, base: "/",
    makeUrl: url_ForgotPassword_21626851, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCSVHeader_21626864 = ref object of OpenApiRestCall_21625435
proc url_GetCSVHeader_21626866(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCSVHeader_21626865(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626867 = header.getOrDefault("X-Amz-Date")
  valid_21626867 = validateParameter(valid_21626867, JString, required = false,
                                   default = nil)
  if valid_21626867 != nil:
    section.add "X-Amz-Date", valid_21626867
  var valid_21626868 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626868 = validateParameter(valid_21626868, JString, required = false,
                                   default = nil)
  if valid_21626868 != nil:
    section.add "X-Amz-Security-Token", valid_21626868
  var valid_21626869 = header.getOrDefault("X-Amz-Target")
  valid_21626869 = validateParameter(valid_21626869, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetCSVHeader"))
  if valid_21626869 != nil:
    section.add "X-Amz-Target", valid_21626869
  var valid_21626870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626870 = validateParameter(valid_21626870, JString, required = false,
                                   default = nil)
  if valid_21626870 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626870
  var valid_21626871 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626871 = validateParameter(valid_21626871, JString, required = false,
                                   default = nil)
  if valid_21626871 != nil:
    section.add "X-Amz-Algorithm", valid_21626871
  var valid_21626872 = header.getOrDefault("X-Amz-Signature")
  valid_21626872 = validateParameter(valid_21626872, JString, required = false,
                                   default = nil)
  if valid_21626872 != nil:
    section.add "X-Amz-Signature", valid_21626872
  var valid_21626873 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626873 = validateParameter(valid_21626873, JString, required = false,
                                   default = nil)
  if valid_21626873 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626873
  var valid_21626874 = header.getOrDefault("X-Amz-Credential")
  valid_21626874 = validateParameter(valid_21626874, JString, required = false,
                                   default = nil)
  if valid_21626874 != nil:
    section.add "X-Amz-Credential", valid_21626874
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

proc call*(call_21626876: Call_GetCSVHeader_21626864; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the header information for the .csv file to be used as input for the user import job.
  ## 
  let valid = call_21626876.validator(path, query, header, formData, body, _)
  let scheme = call_21626876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626876.makeUrl(scheme.get, call_21626876.host, call_21626876.base,
                               call_21626876.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626876, uri, valid, _)

proc call*(call_21626877: Call_GetCSVHeader_21626864; body: JsonNode): Recallable =
  ## getCSVHeader
  ## Gets the header information for the .csv file to be used as input for the user import job.
  ##   body: JObject (required)
  var body_21626878 = newJObject()
  if body != nil:
    body_21626878 = body
  result = call_21626877.call(nil, nil, nil, nil, body_21626878)

var getCSVHeader* = Call_GetCSVHeader_21626864(name: "getCSVHeader",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetCSVHeader",
    validator: validate_GetCSVHeader_21626865, base: "/", makeUrl: url_GetCSVHeader_21626866,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevice_21626879 = ref object of OpenApiRestCall_21625435
proc url_GetDevice_21626881(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevice_21626880(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626882 = header.getOrDefault("X-Amz-Date")
  valid_21626882 = validateParameter(valid_21626882, JString, required = false,
                                   default = nil)
  if valid_21626882 != nil:
    section.add "X-Amz-Date", valid_21626882
  var valid_21626883 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626883 = validateParameter(valid_21626883, JString, required = false,
                                   default = nil)
  if valid_21626883 != nil:
    section.add "X-Amz-Security-Token", valid_21626883
  var valid_21626884 = header.getOrDefault("X-Amz-Target")
  valid_21626884 = validateParameter(valid_21626884, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetDevice"))
  if valid_21626884 != nil:
    section.add "X-Amz-Target", valid_21626884
  var valid_21626885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626885 = validateParameter(valid_21626885, JString, required = false,
                                   default = nil)
  if valid_21626885 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626885
  var valid_21626886 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626886 = validateParameter(valid_21626886, JString, required = false,
                                   default = nil)
  if valid_21626886 != nil:
    section.add "X-Amz-Algorithm", valid_21626886
  var valid_21626887 = header.getOrDefault("X-Amz-Signature")
  valid_21626887 = validateParameter(valid_21626887, JString, required = false,
                                   default = nil)
  if valid_21626887 != nil:
    section.add "X-Amz-Signature", valid_21626887
  var valid_21626888 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626888 = validateParameter(valid_21626888, JString, required = false,
                                   default = nil)
  if valid_21626888 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626888
  var valid_21626889 = header.getOrDefault("X-Amz-Credential")
  valid_21626889 = validateParameter(valid_21626889, JString, required = false,
                                   default = nil)
  if valid_21626889 != nil:
    section.add "X-Amz-Credential", valid_21626889
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

proc call*(call_21626891: Call_GetDevice_21626879; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the device.
  ## 
  let valid = call_21626891.validator(path, query, header, formData, body, _)
  let scheme = call_21626891.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626891.makeUrl(scheme.get, call_21626891.host, call_21626891.base,
                               call_21626891.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626891, uri, valid, _)

proc call*(call_21626892: Call_GetDevice_21626879; body: JsonNode): Recallable =
  ## getDevice
  ## Gets the device.
  ##   body: JObject (required)
  var body_21626893 = newJObject()
  if body != nil:
    body_21626893 = body
  result = call_21626892.call(nil, nil, nil, nil, body_21626893)

var getDevice* = Call_GetDevice_21626879(name: "getDevice",
                                      meth: HttpMethod.HttpPost,
                                      host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetDevice",
                                      validator: validate_GetDevice_21626880,
                                      base: "/", makeUrl: url_GetDevice_21626881,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroup_21626894 = ref object of OpenApiRestCall_21625435
proc url_GetGroup_21626896(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGroup_21626895(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626897 = header.getOrDefault("X-Amz-Date")
  valid_21626897 = validateParameter(valid_21626897, JString, required = false,
                                   default = nil)
  if valid_21626897 != nil:
    section.add "X-Amz-Date", valid_21626897
  var valid_21626898 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626898 = validateParameter(valid_21626898, JString, required = false,
                                   default = nil)
  if valid_21626898 != nil:
    section.add "X-Amz-Security-Token", valid_21626898
  var valid_21626899 = header.getOrDefault("X-Amz-Target")
  valid_21626899 = validateParameter(valid_21626899, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetGroup"))
  if valid_21626899 != nil:
    section.add "X-Amz-Target", valid_21626899
  var valid_21626900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626900 = validateParameter(valid_21626900, JString, required = false,
                                   default = nil)
  if valid_21626900 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626900
  var valid_21626901 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626901 = validateParameter(valid_21626901, JString, required = false,
                                   default = nil)
  if valid_21626901 != nil:
    section.add "X-Amz-Algorithm", valid_21626901
  var valid_21626902 = header.getOrDefault("X-Amz-Signature")
  valid_21626902 = validateParameter(valid_21626902, JString, required = false,
                                   default = nil)
  if valid_21626902 != nil:
    section.add "X-Amz-Signature", valid_21626902
  var valid_21626903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626903 = validateParameter(valid_21626903, JString, required = false,
                                   default = nil)
  if valid_21626903 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626903
  var valid_21626904 = header.getOrDefault("X-Amz-Credential")
  valid_21626904 = validateParameter(valid_21626904, JString, required = false,
                                   default = nil)
  if valid_21626904 != nil:
    section.add "X-Amz-Credential", valid_21626904
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

proc call*(call_21626906: Call_GetGroup_21626894; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets a group.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_21626906.validator(path, query, header, formData, body, _)
  let scheme = call_21626906.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626906.makeUrl(scheme.get, call_21626906.host, call_21626906.base,
                               call_21626906.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626906, uri, valid, _)

proc call*(call_21626907: Call_GetGroup_21626894; body: JsonNode): Recallable =
  ## getGroup
  ## <p>Gets a group.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_21626908 = newJObject()
  if body != nil:
    body_21626908 = body
  result = call_21626907.call(nil, nil, nil, nil, body_21626908)

var getGroup* = Call_GetGroup_21626894(name: "getGroup", meth: HttpMethod.HttpPost,
                                    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetGroup",
                                    validator: validate_GetGroup_21626895,
                                    base: "/", makeUrl: url_GetGroup_21626896,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIdentityProviderByIdentifier_21626909 = ref object of OpenApiRestCall_21625435
proc url_GetIdentityProviderByIdentifier_21626911(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetIdentityProviderByIdentifier_21626910(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626912 = header.getOrDefault("X-Amz-Date")
  valid_21626912 = validateParameter(valid_21626912, JString, required = false,
                                   default = nil)
  if valid_21626912 != nil:
    section.add "X-Amz-Date", valid_21626912
  var valid_21626913 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626913 = validateParameter(valid_21626913, JString, required = false,
                                   default = nil)
  if valid_21626913 != nil:
    section.add "X-Amz-Security-Token", valid_21626913
  var valid_21626914 = header.getOrDefault("X-Amz-Target")
  valid_21626914 = validateParameter(valid_21626914, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetIdentityProviderByIdentifier"))
  if valid_21626914 != nil:
    section.add "X-Amz-Target", valid_21626914
  var valid_21626915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626915 = validateParameter(valid_21626915, JString, required = false,
                                   default = nil)
  if valid_21626915 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626915
  var valid_21626916 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626916 = validateParameter(valid_21626916, JString, required = false,
                                   default = nil)
  if valid_21626916 != nil:
    section.add "X-Amz-Algorithm", valid_21626916
  var valid_21626917 = header.getOrDefault("X-Amz-Signature")
  valid_21626917 = validateParameter(valid_21626917, JString, required = false,
                                   default = nil)
  if valid_21626917 != nil:
    section.add "X-Amz-Signature", valid_21626917
  var valid_21626918 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626918 = validateParameter(valid_21626918, JString, required = false,
                                   default = nil)
  if valid_21626918 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626918
  var valid_21626919 = header.getOrDefault("X-Amz-Credential")
  valid_21626919 = validateParameter(valid_21626919, JString, required = false,
                                   default = nil)
  if valid_21626919 != nil:
    section.add "X-Amz-Credential", valid_21626919
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

proc call*(call_21626921: Call_GetIdentityProviderByIdentifier_21626909;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the specified identity provider.
  ## 
  let valid = call_21626921.validator(path, query, header, formData, body, _)
  let scheme = call_21626921.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626921.makeUrl(scheme.get, call_21626921.host, call_21626921.base,
                               call_21626921.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626921, uri, valid, _)

proc call*(call_21626922: Call_GetIdentityProviderByIdentifier_21626909;
          body: JsonNode): Recallable =
  ## getIdentityProviderByIdentifier
  ## Gets the specified identity provider.
  ##   body: JObject (required)
  var body_21626923 = newJObject()
  if body != nil:
    body_21626923 = body
  result = call_21626922.call(nil, nil, nil, nil, body_21626923)

var getIdentityProviderByIdentifier* = Call_GetIdentityProviderByIdentifier_21626909(
    name: "getIdentityProviderByIdentifier", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetIdentityProviderByIdentifier",
    validator: validate_GetIdentityProviderByIdentifier_21626910, base: "/",
    makeUrl: url_GetIdentityProviderByIdentifier_21626911,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSigningCertificate_21626924 = ref object of OpenApiRestCall_21625435
proc url_GetSigningCertificate_21626926(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSigningCertificate_21626925(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626927 = header.getOrDefault("X-Amz-Date")
  valid_21626927 = validateParameter(valid_21626927, JString, required = false,
                                   default = nil)
  if valid_21626927 != nil:
    section.add "X-Amz-Date", valid_21626927
  var valid_21626928 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626928 = validateParameter(valid_21626928, JString, required = false,
                                   default = nil)
  if valid_21626928 != nil:
    section.add "X-Amz-Security-Token", valid_21626928
  var valid_21626929 = header.getOrDefault("X-Amz-Target")
  valid_21626929 = validateParameter(valid_21626929, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetSigningCertificate"))
  if valid_21626929 != nil:
    section.add "X-Amz-Target", valid_21626929
  var valid_21626930 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626930 = validateParameter(valid_21626930, JString, required = false,
                                   default = nil)
  if valid_21626930 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626930
  var valid_21626931 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626931 = validateParameter(valid_21626931, JString, required = false,
                                   default = nil)
  if valid_21626931 != nil:
    section.add "X-Amz-Algorithm", valid_21626931
  var valid_21626932 = header.getOrDefault("X-Amz-Signature")
  valid_21626932 = validateParameter(valid_21626932, JString, required = false,
                                   default = nil)
  if valid_21626932 != nil:
    section.add "X-Amz-Signature", valid_21626932
  var valid_21626933 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626933 = validateParameter(valid_21626933, JString, required = false,
                                   default = nil)
  if valid_21626933 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626933
  var valid_21626934 = header.getOrDefault("X-Amz-Credential")
  valid_21626934 = validateParameter(valid_21626934, JString, required = false,
                                   default = nil)
  if valid_21626934 != nil:
    section.add "X-Amz-Credential", valid_21626934
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

proc call*(call_21626936: Call_GetSigningCertificate_21626924;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This method takes a user pool ID, and returns the signing certificate.
  ## 
  let valid = call_21626936.validator(path, query, header, formData, body, _)
  let scheme = call_21626936.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626936.makeUrl(scheme.get, call_21626936.host, call_21626936.base,
                               call_21626936.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626936, uri, valid, _)

proc call*(call_21626937: Call_GetSigningCertificate_21626924; body: JsonNode): Recallable =
  ## getSigningCertificate
  ## This method takes a user pool ID, and returns the signing certificate.
  ##   body: JObject (required)
  var body_21626938 = newJObject()
  if body != nil:
    body_21626938 = body
  result = call_21626937.call(nil, nil, nil, nil, body_21626938)

var getSigningCertificate* = Call_GetSigningCertificate_21626924(
    name: "getSigningCertificate", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetSigningCertificate",
    validator: validate_GetSigningCertificate_21626925, base: "/",
    makeUrl: url_GetSigningCertificate_21626926,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUICustomization_21626939 = ref object of OpenApiRestCall_21625435
proc url_GetUICustomization_21626941(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUICustomization_21626940(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626942 = header.getOrDefault("X-Amz-Date")
  valid_21626942 = validateParameter(valid_21626942, JString, required = false,
                                   default = nil)
  if valid_21626942 != nil:
    section.add "X-Amz-Date", valid_21626942
  var valid_21626943 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626943 = validateParameter(valid_21626943, JString, required = false,
                                   default = nil)
  if valid_21626943 != nil:
    section.add "X-Amz-Security-Token", valid_21626943
  var valid_21626944 = header.getOrDefault("X-Amz-Target")
  valid_21626944 = validateParameter(valid_21626944, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUICustomization"))
  if valid_21626944 != nil:
    section.add "X-Amz-Target", valid_21626944
  var valid_21626945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626945 = validateParameter(valid_21626945, JString, required = false,
                                   default = nil)
  if valid_21626945 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626945
  var valid_21626946 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626946 = validateParameter(valid_21626946, JString, required = false,
                                   default = nil)
  if valid_21626946 != nil:
    section.add "X-Amz-Algorithm", valid_21626946
  var valid_21626947 = header.getOrDefault("X-Amz-Signature")
  valid_21626947 = validateParameter(valid_21626947, JString, required = false,
                                   default = nil)
  if valid_21626947 != nil:
    section.add "X-Amz-Signature", valid_21626947
  var valid_21626948 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626948 = validateParameter(valid_21626948, JString, required = false,
                                   default = nil)
  if valid_21626948 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626948
  var valid_21626949 = header.getOrDefault("X-Amz-Credential")
  valid_21626949 = validateParameter(valid_21626949, JString, required = false,
                                   default = nil)
  if valid_21626949 != nil:
    section.add "X-Amz-Credential", valid_21626949
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

proc call*(call_21626951: Call_GetUICustomization_21626939; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the UI Customization information for a particular app client's app UI, if there is something set. If nothing is set for the particular client, but there is an existing pool level customization (app <code>clientId</code> will be <code>ALL</code>), then that is returned. If nothing is present, then an empty shape is returned.
  ## 
  let valid = call_21626951.validator(path, query, header, formData, body, _)
  let scheme = call_21626951.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626951.makeUrl(scheme.get, call_21626951.host, call_21626951.base,
                               call_21626951.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626951, uri, valid, _)

proc call*(call_21626952: Call_GetUICustomization_21626939; body: JsonNode): Recallable =
  ## getUICustomization
  ## Gets the UI Customization information for a particular app client's app UI, if there is something set. If nothing is set for the particular client, but there is an existing pool level customization (app <code>clientId</code> will be <code>ALL</code>), then that is returned. If nothing is present, then an empty shape is returned.
  ##   body: JObject (required)
  var body_21626953 = newJObject()
  if body != nil:
    body_21626953 = body
  result = call_21626952.call(nil, nil, nil, nil, body_21626953)

var getUICustomization* = Call_GetUICustomization_21626939(
    name: "getUICustomization", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUICustomization",
    validator: validate_GetUICustomization_21626940, base: "/",
    makeUrl: url_GetUICustomization_21626941, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUser_21626954 = ref object of OpenApiRestCall_21625435
proc url_GetUser_21626956(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUser_21626955(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626957 = header.getOrDefault("X-Amz-Date")
  valid_21626957 = validateParameter(valid_21626957, JString, required = false,
                                   default = nil)
  if valid_21626957 != nil:
    section.add "X-Amz-Date", valid_21626957
  var valid_21626958 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626958 = validateParameter(valid_21626958, JString, required = false,
                                   default = nil)
  if valid_21626958 != nil:
    section.add "X-Amz-Security-Token", valid_21626958
  var valid_21626959 = header.getOrDefault("X-Amz-Target")
  valid_21626959 = validateParameter(valid_21626959, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUser"))
  if valid_21626959 != nil:
    section.add "X-Amz-Target", valid_21626959
  var valid_21626960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626960 = validateParameter(valid_21626960, JString, required = false,
                                   default = nil)
  if valid_21626960 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626960
  var valid_21626961 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626961 = validateParameter(valid_21626961, JString, required = false,
                                   default = nil)
  if valid_21626961 != nil:
    section.add "X-Amz-Algorithm", valid_21626961
  var valid_21626962 = header.getOrDefault("X-Amz-Signature")
  valid_21626962 = validateParameter(valid_21626962, JString, required = false,
                                   default = nil)
  if valid_21626962 != nil:
    section.add "X-Amz-Signature", valid_21626962
  var valid_21626963 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626963 = validateParameter(valid_21626963, JString, required = false,
                                   default = nil)
  if valid_21626963 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626963
  var valid_21626964 = header.getOrDefault("X-Amz-Credential")
  valid_21626964 = validateParameter(valid_21626964, JString, required = false,
                                   default = nil)
  if valid_21626964 != nil:
    section.add "X-Amz-Credential", valid_21626964
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

proc call*(call_21626966: Call_GetUser_21626954; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the user attributes and metadata for a user.
  ## 
  let valid = call_21626966.validator(path, query, header, formData, body, _)
  let scheme = call_21626966.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626966.makeUrl(scheme.get, call_21626966.host, call_21626966.base,
                               call_21626966.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626966, uri, valid, _)

proc call*(call_21626967: Call_GetUser_21626954; body: JsonNode): Recallable =
  ## getUser
  ## Gets the user attributes and metadata for a user.
  ##   body: JObject (required)
  var body_21626968 = newJObject()
  if body != nil:
    body_21626968 = body
  result = call_21626967.call(nil, nil, nil, nil, body_21626968)

var getUser* = Call_GetUser_21626954(name: "getUser", meth: HttpMethod.HttpPost,
                                  host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUser",
                                  validator: validate_GetUser_21626955, base: "/",
                                  makeUrl: url_GetUser_21626956,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserAttributeVerificationCode_21626969 = ref object of OpenApiRestCall_21625435
proc url_GetUserAttributeVerificationCode_21626971(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUserAttributeVerificationCode_21626970(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626972 = header.getOrDefault("X-Amz-Date")
  valid_21626972 = validateParameter(valid_21626972, JString, required = false,
                                   default = nil)
  if valid_21626972 != nil:
    section.add "X-Amz-Date", valid_21626972
  var valid_21626973 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626973 = validateParameter(valid_21626973, JString, required = false,
                                   default = nil)
  if valid_21626973 != nil:
    section.add "X-Amz-Security-Token", valid_21626973
  var valid_21626974 = header.getOrDefault("X-Amz-Target")
  valid_21626974 = validateParameter(valid_21626974, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUserAttributeVerificationCode"))
  if valid_21626974 != nil:
    section.add "X-Amz-Target", valid_21626974
  var valid_21626975 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626975 = validateParameter(valid_21626975, JString, required = false,
                                   default = nil)
  if valid_21626975 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626975
  var valid_21626976 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626976 = validateParameter(valid_21626976, JString, required = false,
                                   default = nil)
  if valid_21626976 != nil:
    section.add "X-Amz-Algorithm", valid_21626976
  var valid_21626977 = header.getOrDefault("X-Amz-Signature")
  valid_21626977 = validateParameter(valid_21626977, JString, required = false,
                                   default = nil)
  if valid_21626977 != nil:
    section.add "X-Amz-Signature", valid_21626977
  var valid_21626978 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626978 = validateParameter(valid_21626978, JString, required = false,
                                   default = nil)
  if valid_21626978 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626978
  var valid_21626979 = header.getOrDefault("X-Amz-Credential")
  valid_21626979 = validateParameter(valid_21626979, JString, required = false,
                                   default = nil)
  if valid_21626979 != nil:
    section.add "X-Amz-Credential", valid_21626979
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

proc call*(call_21626981: Call_GetUserAttributeVerificationCode_21626969;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the user attribute verification code for the specified attribute name.
  ## 
  let valid = call_21626981.validator(path, query, header, formData, body, _)
  let scheme = call_21626981.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626981.makeUrl(scheme.get, call_21626981.host, call_21626981.base,
                               call_21626981.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626981, uri, valid, _)

proc call*(call_21626982: Call_GetUserAttributeVerificationCode_21626969;
          body: JsonNode): Recallable =
  ## getUserAttributeVerificationCode
  ## Gets the user attribute verification code for the specified attribute name.
  ##   body: JObject (required)
  var body_21626983 = newJObject()
  if body != nil:
    body_21626983 = body
  result = call_21626982.call(nil, nil, nil, nil, body_21626983)

var getUserAttributeVerificationCode* = Call_GetUserAttributeVerificationCode_21626969(
    name: "getUserAttributeVerificationCode", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUserAttributeVerificationCode",
    validator: validate_GetUserAttributeVerificationCode_21626970, base: "/",
    makeUrl: url_GetUserAttributeVerificationCode_21626971,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserPoolMfaConfig_21626984 = ref object of OpenApiRestCall_21625435
proc url_GetUserPoolMfaConfig_21626986(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUserPoolMfaConfig_21626985(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626987 = header.getOrDefault("X-Amz-Date")
  valid_21626987 = validateParameter(valid_21626987, JString, required = false,
                                   default = nil)
  if valid_21626987 != nil:
    section.add "X-Amz-Date", valid_21626987
  var valid_21626988 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626988 = validateParameter(valid_21626988, JString, required = false,
                                   default = nil)
  if valid_21626988 != nil:
    section.add "X-Amz-Security-Token", valid_21626988
  var valid_21626989 = header.getOrDefault("X-Amz-Target")
  valid_21626989 = validateParameter(valid_21626989, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUserPoolMfaConfig"))
  if valid_21626989 != nil:
    section.add "X-Amz-Target", valid_21626989
  var valid_21626990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626990 = validateParameter(valid_21626990, JString, required = false,
                                   default = nil)
  if valid_21626990 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626990
  var valid_21626991 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626991 = validateParameter(valid_21626991, JString, required = false,
                                   default = nil)
  if valid_21626991 != nil:
    section.add "X-Amz-Algorithm", valid_21626991
  var valid_21626992 = header.getOrDefault("X-Amz-Signature")
  valid_21626992 = validateParameter(valid_21626992, JString, required = false,
                                   default = nil)
  if valid_21626992 != nil:
    section.add "X-Amz-Signature", valid_21626992
  var valid_21626993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626993 = validateParameter(valid_21626993, JString, required = false,
                                   default = nil)
  if valid_21626993 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626993
  var valid_21626994 = header.getOrDefault("X-Amz-Credential")
  valid_21626994 = validateParameter(valid_21626994, JString, required = false,
                                   default = nil)
  if valid_21626994 != nil:
    section.add "X-Amz-Credential", valid_21626994
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

proc call*(call_21626996: Call_GetUserPoolMfaConfig_21626984; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the user pool multi-factor authentication (MFA) configuration.
  ## 
  let valid = call_21626996.validator(path, query, header, formData, body, _)
  let scheme = call_21626996.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626996.makeUrl(scheme.get, call_21626996.host, call_21626996.base,
                               call_21626996.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626996, uri, valid, _)

proc call*(call_21626997: Call_GetUserPoolMfaConfig_21626984; body: JsonNode): Recallable =
  ## getUserPoolMfaConfig
  ## Gets the user pool multi-factor authentication (MFA) configuration.
  ##   body: JObject (required)
  var body_21626998 = newJObject()
  if body != nil:
    body_21626998 = body
  result = call_21626997.call(nil, nil, nil, nil, body_21626998)

var getUserPoolMfaConfig* = Call_GetUserPoolMfaConfig_21626984(
    name: "getUserPoolMfaConfig", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUserPoolMfaConfig",
    validator: validate_GetUserPoolMfaConfig_21626985, base: "/",
    makeUrl: url_GetUserPoolMfaConfig_21626986,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GlobalSignOut_21626999 = ref object of OpenApiRestCall_21625435
proc url_GlobalSignOut_21627001(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GlobalSignOut_21627000(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627002 = header.getOrDefault("X-Amz-Date")
  valid_21627002 = validateParameter(valid_21627002, JString, required = false,
                                   default = nil)
  if valid_21627002 != nil:
    section.add "X-Amz-Date", valid_21627002
  var valid_21627003 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627003 = validateParameter(valid_21627003, JString, required = false,
                                   default = nil)
  if valid_21627003 != nil:
    section.add "X-Amz-Security-Token", valid_21627003
  var valid_21627004 = header.getOrDefault("X-Amz-Target")
  valid_21627004 = validateParameter(valid_21627004, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GlobalSignOut"))
  if valid_21627004 != nil:
    section.add "X-Amz-Target", valid_21627004
  var valid_21627005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627005 = validateParameter(valid_21627005, JString, required = false,
                                   default = nil)
  if valid_21627005 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627005
  var valid_21627006 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627006 = validateParameter(valid_21627006, JString, required = false,
                                   default = nil)
  if valid_21627006 != nil:
    section.add "X-Amz-Algorithm", valid_21627006
  var valid_21627007 = header.getOrDefault("X-Amz-Signature")
  valid_21627007 = validateParameter(valid_21627007, JString, required = false,
                                   default = nil)
  if valid_21627007 != nil:
    section.add "X-Amz-Signature", valid_21627007
  var valid_21627008 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627008 = validateParameter(valid_21627008, JString, required = false,
                                   default = nil)
  if valid_21627008 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627008
  var valid_21627009 = header.getOrDefault("X-Amz-Credential")
  valid_21627009 = validateParameter(valid_21627009, JString, required = false,
                                   default = nil)
  if valid_21627009 != nil:
    section.add "X-Amz-Credential", valid_21627009
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

proc call*(call_21627011: Call_GlobalSignOut_21626999; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Signs out users from all devices. It also invalidates all refresh tokens issued to a user. The user's current access and Id tokens remain valid until their expiry. Access and Id tokens expire one hour after they are issued.
  ## 
  let valid = call_21627011.validator(path, query, header, formData, body, _)
  let scheme = call_21627011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627011.makeUrl(scheme.get, call_21627011.host, call_21627011.base,
                               call_21627011.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627011, uri, valid, _)

proc call*(call_21627012: Call_GlobalSignOut_21626999; body: JsonNode): Recallable =
  ## globalSignOut
  ## Signs out users from all devices. It also invalidates all refresh tokens issued to a user. The user's current access and Id tokens remain valid until their expiry. Access and Id tokens expire one hour after they are issued.
  ##   body: JObject (required)
  var body_21627013 = newJObject()
  if body != nil:
    body_21627013 = body
  result = call_21627012.call(nil, nil, nil, nil, body_21627013)

var globalSignOut* = Call_GlobalSignOut_21626999(name: "globalSignOut",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GlobalSignOut",
    validator: validate_GlobalSignOut_21627000, base: "/",
    makeUrl: url_GlobalSignOut_21627001, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateAuth_21627014 = ref object of OpenApiRestCall_21625435
proc url_InitiateAuth_21627016(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_InitiateAuth_21627015(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627017 = header.getOrDefault("X-Amz-Date")
  valid_21627017 = validateParameter(valid_21627017, JString, required = false,
                                   default = nil)
  if valid_21627017 != nil:
    section.add "X-Amz-Date", valid_21627017
  var valid_21627018 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627018 = validateParameter(valid_21627018, JString, required = false,
                                   default = nil)
  if valid_21627018 != nil:
    section.add "X-Amz-Security-Token", valid_21627018
  var valid_21627019 = header.getOrDefault("X-Amz-Target")
  valid_21627019 = validateParameter(valid_21627019, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.InitiateAuth"))
  if valid_21627019 != nil:
    section.add "X-Amz-Target", valid_21627019
  var valid_21627020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627020 = validateParameter(valid_21627020, JString, required = false,
                                   default = nil)
  if valid_21627020 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627020
  var valid_21627021 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627021 = validateParameter(valid_21627021, JString, required = false,
                                   default = nil)
  if valid_21627021 != nil:
    section.add "X-Amz-Algorithm", valid_21627021
  var valid_21627022 = header.getOrDefault("X-Amz-Signature")
  valid_21627022 = validateParameter(valid_21627022, JString, required = false,
                                   default = nil)
  if valid_21627022 != nil:
    section.add "X-Amz-Signature", valid_21627022
  var valid_21627023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627023 = validateParameter(valid_21627023, JString, required = false,
                                   default = nil)
  if valid_21627023 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627023
  var valid_21627024 = header.getOrDefault("X-Amz-Credential")
  valid_21627024 = validateParameter(valid_21627024, JString, required = false,
                                   default = nil)
  if valid_21627024 != nil:
    section.add "X-Amz-Credential", valid_21627024
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

proc call*(call_21627026: Call_InitiateAuth_21627014; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Initiates the authentication flow.
  ## 
  let valid = call_21627026.validator(path, query, header, formData, body, _)
  let scheme = call_21627026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627026.makeUrl(scheme.get, call_21627026.host, call_21627026.base,
                               call_21627026.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627026, uri, valid, _)

proc call*(call_21627027: Call_InitiateAuth_21627014; body: JsonNode): Recallable =
  ## initiateAuth
  ## Initiates the authentication flow.
  ##   body: JObject (required)
  var body_21627028 = newJObject()
  if body != nil:
    body_21627028 = body
  result = call_21627027.call(nil, nil, nil, nil, body_21627028)

var initiateAuth* = Call_InitiateAuth_21627014(name: "initiateAuth",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.InitiateAuth",
    validator: validate_InitiateAuth_21627015, base: "/", makeUrl: url_InitiateAuth_21627016,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevices_21627029 = ref object of OpenApiRestCall_21625435
proc url_ListDevices_21627031(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDevices_21627030(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627032 = header.getOrDefault("X-Amz-Date")
  valid_21627032 = validateParameter(valid_21627032, JString, required = false,
                                   default = nil)
  if valid_21627032 != nil:
    section.add "X-Amz-Date", valid_21627032
  var valid_21627033 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627033 = validateParameter(valid_21627033, JString, required = false,
                                   default = nil)
  if valid_21627033 != nil:
    section.add "X-Amz-Security-Token", valid_21627033
  var valid_21627034 = header.getOrDefault("X-Amz-Target")
  valid_21627034 = validateParameter(valid_21627034, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListDevices"))
  if valid_21627034 != nil:
    section.add "X-Amz-Target", valid_21627034
  var valid_21627035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627035 = validateParameter(valid_21627035, JString, required = false,
                                   default = nil)
  if valid_21627035 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627035
  var valid_21627036 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627036 = validateParameter(valid_21627036, JString, required = false,
                                   default = nil)
  if valid_21627036 != nil:
    section.add "X-Amz-Algorithm", valid_21627036
  var valid_21627037 = header.getOrDefault("X-Amz-Signature")
  valid_21627037 = validateParameter(valid_21627037, JString, required = false,
                                   default = nil)
  if valid_21627037 != nil:
    section.add "X-Amz-Signature", valid_21627037
  var valid_21627038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627038 = validateParameter(valid_21627038, JString, required = false,
                                   default = nil)
  if valid_21627038 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627038
  var valid_21627039 = header.getOrDefault("X-Amz-Credential")
  valid_21627039 = validateParameter(valid_21627039, JString, required = false,
                                   default = nil)
  if valid_21627039 != nil:
    section.add "X-Amz-Credential", valid_21627039
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

proc call*(call_21627041: Call_ListDevices_21627029; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the devices.
  ## 
  let valid = call_21627041.validator(path, query, header, formData, body, _)
  let scheme = call_21627041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627041.makeUrl(scheme.get, call_21627041.host, call_21627041.base,
                               call_21627041.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627041, uri, valid, _)

proc call*(call_21627042: Call_ListDevices_21627029; body: JsonNode): Recallable =
  ## listDevices
  ## Lists the devices.
  ##   body: JObject (required)
  var body_21627043 = newJObject()
  if body != nil:
    body_21627043 = body
  result = call_21627042.call(nil, nil, nil, nil, body_21627043)

var listDevices* = Call_ListDevices_21627029(name: "listDevices",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListDevices",
    validator: validate_ListDevices_21627030, base: "/", makeUrl: url_ListDevices_21627031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_21627044 = ref object of OpenApiRestCall_21625435
proc url_ListGroups_21627046(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGroups_21627045(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627047 = query.getOrDefault("Limit")
  valid_21627047 = validateParameter(valid_21627047, JString, required = false,
                                   default = nil)
  if valid_21627047 != nil:
    section.add "Limit", valid_21627047
  var valid_21627048 = query.getOrDefault("NextToken")
  valid_21627048 = validateParameter(valid_21627048, JString, required = false,
                                   default = nil)
  if valid_21627048 != nil:
    section.add "NextToken", valid_21627048
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627049 = header.getOrDefault("X-Amz-Date")
  valid_21627049 = validateParameter(valid_21627049, JString, required = false,
                                   default = nil)
  if valid_21627049 != nil:
    section.add "X-Amz-Date", valid_21627049
  var valid_21627050 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627050 = validateParameter(valid_21627050, JString, required = false,
                                   default = nil)
  if valid_21627050 != nil:
    section.add "X-Amz-Security-Token", valid_21627050
  var valid_21627051 = header.getOrDefault("X-Amz-Target")
  valid_21627051 = validateParameter(valid_21627051, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListGroups"))
  if valid_21627051 != nil:
    section.add "X-Amz-Target", valid_21627051
  var valid_21627052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627052 = validateParameter(valid_21627052, JString, required = false,
                                   default = nil)
  if valid_21627052 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627052
  var valid_21627053 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627053 = validateParameter(valid_21627053, JString, required = false,
                                   default = nil)
  if valid_21627053 != nil:
    section.add "X-Amz-Algorithm", valid_21627053
  var valid_21627054 = header.getOrDefault("X-Amz-Signature")
  valid_21627054 = validateParameter(valid_21627054, JString, required = false,
                                   default = nil)
  if valid_21627054 != nil:
    section.add "X-Amz-Signature", valid_21627054
  var valid_21627055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627055 = validateParameter(valid_21627055, JString, required = false,
                                   default = nil)
  if valid_21627055 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627055
  var valid_21627056 = header.getOrDefault("X-Amz-Credential")
  valid_21627056 = validateParameter(valid_21627056, JString, required = false,
                                   default = nil)
  if valid_21627056 != nil:
    section.add "X-Amz-Credential", valid_21627056
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

proc call*(call_21627058: Call_ListGroups_21627044; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists the groups associated with a user pool.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_21627058.validator(path, query, header, formData, body, _)
  let scheme = call_21627058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627058.makeUrl(scheme.get, call_21627058.host, call_21627058.base,
                               call_21627058.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627058, uri, valid, _)

proc call*(call_21627059: Call_ListGroups_21627044; body: JsonNode;
          Limit: string = ""; NextToken: string = ""): Recallable =
  ## listGroups
  ## <p>Lists the groups associated with a user pool.</p> <p>Calling this action requires developer credentials.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21627060 = newJObject()
  var body_21627061 = newJObject()
  add(query_21627060, "Limit", newJString(Limit))
  add(query_21627060, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627061 = body
  result = call_21627059.call(nil, query_21627060, nil, nil, body_21627061)

var listGroups* = Call_ListGroups_21627044(name: "listGroups",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListGroups",
                                        validator: validate_ListGroups_21627045,
                                        base: "/", makeUrl: url_ListGroups_21627046,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIdentityProviders_21627062 = ref object of OpenApiRestCall_21625435
proc url_ListIdentityProviders_21627064(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListIdentityProviders_21627063(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627065 = query.getOrDefault("NextToken")
  valid_21627065 = validateParameter(valid_21627065, JString, required = false,
                                   default = nil)
  if valid_21627065 != nil:
    section.add "NextToken", valid_21627065
  var valid_21627066 = query.getOrDefault("MaxResults")
  valid_21627066 = validateParameter(valid_21627066, JString, required = false,
                                   default = nil)
  if valid_21627066 != nil:
    section.add "MaxResults", valid_21627066
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627067 = header.getOrDefault("X-Amz-Date")
  valid_21627067 = validateParameter(valid_21627067, JString, required = false,
                                   default = nil)
  if valid_21627067 != nil:
    section.add "X-Amz-Date", valid_21627067
  var valid_21627068 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627068 = validateParameter(valid_21627068, JString, required = false,
                                   default = nil)
  if valid_21627068 != nil:
    section.add "X-Amz-Security-Token", valid_21627068
  var valid_21627069 = header.getOrDefault("X-Amz-Target")
  valid_21627069 = validateParameter(valid_21627069, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListIdentityProviders"))
  if valid_21627069 != nil:
    section.add "X-Amz-Target", valid_21627069
  var valid_21627070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627070 = validateParameter(valid_21627070, JString, required = false,
                                   default = nil)
  if valid_21627070 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627070
  var valid_21627071 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627071 = validateParameter(valid_21627071, JString, required = false,
                                   default = nil)
  if valid_21627071 != nil:
    section.add "X-Amz-Algorithm", valid_21627071
  var valid_21627072 = header.getOrDefault("X-Amz-Signature")
  valid_21627072 = validateParameter(valid_21627072, JString, required = false,
                                   default = nil)
  if valid_21627072 != nil:
    section.add "X-Amz-Signature", valid_21627072
  var valid_21627073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627073 = validateParameter(valid_21627073, JString, required = false,
                                   default = nil)
  if valid_21627073 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627073
  var valid_21627074 = header.getOrDefault("X-Amz-Credential")
  valid_21627074 = validateParameter(valid_21627074, JString, required = false,
                                   default = nil)
  if valid_21627074 != nil:
    section.add "X-Amz-Credential", valid_21627074
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

proc call*(call_21627076: Call_ListIdentityProviders_21627062;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists information about all identity providers for a user pool.
  ## 
  let valid = call_21627076.validator(path, query, header, formData, body, _)
  let scheme = call_21627076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627076.makeUrl(scheme.get, call_21627076.host, call_21627076.base,
                               call_21627076.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627076, uri, valid, _)

proc call*(call_21627077: Call_ListIdentityProviders_21627062; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listIdentityProviders
  ## Lists information about all identity providers for a user pool.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627078 = newJObject()
  var body_21627079 = newJObject()
  add(query_21627078, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627079 = body
  add(query_21627078, "MaxResults", newJString(MaxResults))
  result = call_21627077.call(nil, query_21627078, nil, nil, body_21627079)

var listIdentityProviders* = Call_ListIdentityProviders_21627062(
    name: "listIdentityProviders", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListIdentityProviders",
    validator: validate_ListIdentityProviders_21627063, base: "/",
    makeUrl: url_ListIdentityProviders_21627064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceServers_21627080 = ref object of OpenApiRestCall_21625435
proc url_ListResourceServers_21627082(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResourceServers_21627081(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627083 = query.getOrDefault("NextToken")
  valid_21627083 = validateParameter(valid_21627083, JString, required = false,
                                   default = nil)
  if valid_21627083 != nil:
    section.add "NextToken", valid_21627083
  var valid_21627084 = query.getOrDefault("MaxResults")
  valid_21627084 = validateParameter(valid_21627084, JString, required = false,
                                   default = nil)
  if valid_21627084 != nil:
    section.add "MaxResults", valid_21627084
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627085 = header.getOrDefault("X-Amz-Date")
  valid_21627085 = validateParameter(valid_21627085, JString, required = false,
                                   default = nil)
  if valid_21627085 != nil:
    section.add "X-Amz-Date", valid_21627085
  var valid_21627086 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627086 = validateParameter(valid_21627086, JString, required = false,
                                   default = nil)
  if valid_21627086 != nil:
    section.add "X-Amz-Security-Token", valid_21627086
  var valid_21627087 = header.getOrDefault("X-Amz-Target")
  valid_21627087 = validateParameter(valid_21627087, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListResourceServers"))
  if valid_21627087 != nil:
    section.add "X-Amz-Target", valid_21627087
  var valid_21627088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627088 = validateParameter(valid_21627088, JString, required = false,
                                   default = nil)
  if valid_21627088 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627088
  var valid_21627089 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627089 = validateParameter(valid_21627089, JString, required = false,
                                   default = nil)
  if valid_21627089 != nil:
    section.add "X-Amz-Algorithm", valid_21627089
  var valid_21627090 = header.getOrDefault("X-Amz-Signature")
  valid_21627090 = validateParameter(valid_21627090, JString, required = false,
                                   default = nil)
  if valid_21627090 != nil:
    section.add "X-Amz-Signature", valid_21627090
  var valid_21627091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627091 = validateParameter(valid_21627091, JString, required = false,
                                   default = nil)
  if valid_21627091 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627091
  var valid_21627092 = header.getOrDefault("X-Amz-Credential")
  valid_21627092 = validateParameter(valid_21627092, JString, required = false,
                                   default = nil)
  if valid_21627092 != nil:
    section.add "X-Amz-Credential", valid_21627092
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

proc call*(call_21627094: Call_ListResourceServers_21627080; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the resource servers for a user pool.
  ## 
  let valid = call_21627094.validator(path, query, header, formData, body, _)
  let scheme = call_21627094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627094.makeUrl(scheme.get, call_21627094.host, call_21627094.base,
                               call_21627094.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627094, uri, valid, _)

proc call*(call_21627095: Call_ListResourceServers_21627080; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listResourceServers
  ## Lists the resource servers for a user pool.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627096 = newJObject()
  var body_21627097 = newJObject()
  add(query_21627096, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627097 = body
  add(query_21627096, "MaxResults", newJString(MaxResults))
  result = call_21627095.call(nil, query_21627096, nil, nil, body_21627097)

var listResourceServers* = Call_ListResourceServers_21627080(
    name: "listResourceServers", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListResourceServers",
    validator: validate_ListResourceServers_21627081, base: "/",
    makeUrl: url_ListResourceServers_21627082,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21627098 = ref object of OpenApiRestCall_21625435
proc url_ListTagsForResource_21627100(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_21627099(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627101 = header.getOrDefault("X-Amz-Date")
  valid_21627101 = validateParameter(valid_21627101, JString, required = false,
                                   default = nil)
  if valid_21627101 != nil:
    section.add "X-Amz-Date", valid_21627101
  var valid_21627102 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627102 = validateParameter(valid_21627102, JString, required = false,
                                   default = nil)
  if valid_21627102 != nil:
    section.add "X-Amz-Security-Token", valid_21627102
  var valid_21627103 = header.getOrDefault("X-Amz-Target")
  valid_21627103 = validateParameter(valid_21627103, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListTagsForResource"))
  if valid_21627103 != nil:
    section.add "X-Amz-Target", valid_21627103
  var valid_21627104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627104 = validateParameter(valid_21627104, JString, required = false,
                                   default = nil)
  if valid_21627104 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627104
  var valid_21627105 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627105 = validateParameter(valid_21627105, JString, required = false,
                                   default = nil)
  if valid_21627105 != nil:
    section.add "X-Amz-Algorithm", valid_21627105
  var valid_21627106 = header.getOrDefault("X-Amz-Signature")
  valid_21627106 = validateParameter(valid_21627106, JString, required = false,
                                   default = nil)
  if valid_21627106 != nil:
    section.add "X-Amz-Signature", valid_21627106
  var valid_21627107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627107 = validateParameter(valid_21627107, JString, required = false,
                                   default = nil)
  if valid_21627107 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627107
  var valid_21627108 = header.getOrDefault("X-Amz-Credential")
  valid_21627108 = validateParameter(valid_21627108, JString, required = false,
                                   default = nil)
  if valid_21627108 != nil:
    section.add "X-Amz-Credential", valid_21627108
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

proc call*(call_21627110: Call_ListTagsForResource_21627098; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists the tags that are assigned to an Amazon Cognito user pool.</p> <p>A tag is a label that you can apply to user pools to categorize and manage them in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>You can use this action up to 10 times per second, per account.</p>
  ## 
  let valid = call_21627110.validator(path, query, header, formData, body, _)
  let scheme = call_21627110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627110.makeUrl(scheme.get, call_21627110.host, call_21627110.base,
                               call_21627110.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627110, uri, valid, _)

proc call*(call_21627111: Call_ListTagsForResource_21627098; body: JsonNode): Recallable =
  ## listTagsForResource
  ## <p>Lists the tags that are assigned to an Amazon Cognito user pool.</p> <p>A tag is a label that you can apply to user pools to categorize and manage them in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>You can use this action up to 10 times per second, per account.</p>
  ##   body: JObject (required)
  var body_21627112 = newJObject()
  if body != nil:
    body_21627112 = body
  result = call_21627111.call(nil, nil, nil, nil, body_21627112)

var listTagsForResource* = Call_ListTagsForResource_21627098(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListTagsForResource",
    validator: validate_ListTagsForResource_21627099, base: "/",
    makeUrl: url_ListTagsForResource_21627100,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserImportJobs_21627113 = ref object of OpenApiRestCall_21625435
proc url_ListUserImportJobs_21627115(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUserImportJobs_21627114(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627116 = header.getOrDefault("X-Amz-Date")
  valid_21627116 = validateParameter(valid_21627116, JString, required = false,
                                   default = nil)
  if valid_21627116 != nil:
    section.add "X-Amz-Date", valid_21627116
  var valid_21627117 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627117 = validateParameter(valid_21627117, JString, required = false,
                                   default = nil)
  if valid_21627117 != nil:
    section.add "X-Amz-Security-Token", valid_21627117
  var valid_21627118 = header.getOrDefault("X-Amz-Target")
  valid_21627118 = validateParameter(valid_21627118, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUserImportJobs"))
  if valid_21627118 != nil:
    section.add "X-Amz-Target", valid_21627118
  var valid_21627119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627119 = validateParameter(valid_21627119, JString, required = false,
                                   default = nil)
  if valid_21627119 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627119
  var valid_21627120 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627120 = validateParameter(valid_21627120, JString, required = false,
                                   default = nil)
  if valid_21627120 != nil:
    section.add "X-Amz-Algorithm", valid_21627120
  var valid_21627121 = header.getOrDefault("X-Amz-Signature")
  valid_21627121 = validateParameter(valid_21627121, JString, required = false,
                                   default = nil)
  if valid_21627121 != nil:
    section.add "X-Amz-Signature", valid_21627121
  var valid_21627122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627122 = validateParameter(valid_21627122, JString, required = false,
                                   default = nil)
  if valid_21627122 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627122
  var valid_21627123 = header.getOrDefault("X-Amz-Credential")
  valid_21627123 = validateParameter(valid_21627123, JString, required = false,
                                   default = nil)
  if valid_21627123 != nil:
    section.add "X-Amz-Credential", valid_21627123
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

proc call*(call_21627125: Call_ListUserImportJobs_21627113; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the user import jobs.
  ## 
  let valid = call_21627125.validator(path, query, header, formData, body, _)
  let scheme = call_21627125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627125.makeUrl(scheme.get, call_21627125.host, call_21627125.base,
                               call_21627125.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627125, uri, valid, _)

proc call*(call_21627126: Call_ListUserImportJobs_21627113; body: JsonNode): Recallable =
  ## listUserImportJobs
  ## Lists the user import jobs.
  ##   body: JObject (required)
  var body_21627127 = newJObject()
  if body != nil:
    body_21627127 = body
  result = call_21627126.call(nil, nil, nil, nil, body_21627127)

var listUserImportJobs* = Call_ListUserImportJobs_21627113(
    name: "listUserImportJobs", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUserImportJobs",
    validator: validate_ListUserImportJobs_21627114, base: "/",
    makeUrl: url_ListUserImportJobs_21627115, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserPoolClients_21627128 = ref object of OpenApiRestCall_21625435
proc url_ListUserPoolClients_21627130(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUserPoolClients_21627129(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627131 = query.getOrDefault("NextToken")
  valid_21627131 = validateParameter(valid_21627131, JString, required = false,
                                   default = nil)
  if valid_21627131 != nil:
    section.add "NextToken", valid_21627131
  var valid_21627132 = query.getOrDefault("MaxResults")
  valid_21627132 = validateParameter(valid_21627132, JString, required = false,
                                   default = nil)
  if valid_21627132 != nil:
    section.add "MaxResults", valid_21627132
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627133 = header.getOrDefault("X-Amz-Date")
  valid_21627133 = validateParameter(valid_21627133, JString, required = false,
                                   default = nil)
  if valid_21627133 != nil:
    section.add "X-Amz-Date", valid_21627133
  var valid_21627134 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627134 = validateParameter(valid_21627134, JString, required = false,
                                   default = nil)
  if valid_21627134 != nil:
    section.add "X-Amz-Security-Token", valid_21627134
  var valid_21627135 = header.getOrDefault("X-Amz-Target")
  valid_21627135 = validateParameter(valid_21627135, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUserPoolClients"))
  if valid_21627135 != nil:
    section.add "X-Amz-Target", valid_21627135
  var valid_21627136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627136 = validateParameter(valid_21627136, JString, required = false,
                                   default = nil)
  if valid_21627136 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627136
  var valid_21627137 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627137 = validateParameter(valid_21627137, JString, required = false,
                                   default = nil)
  if valid_21627137 != nil:
    section.add "X-Amz-Algorithm", valid_21627137
  var valid_21627138 = header.getOrDefault("X-Amz-Signature")
  valid_21627138 = validateParameter(valid_21627138, JString, required = false,
                                   default = nil)
  if valid_21627138 != nil:
    section.add "X-Amz-Signature", valid_21627138
  var valid_21627139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627139 = validateParameter(valid_21627139, JString, required = false,
                                   default = nil)
  if valid_21627139 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627139
  var valid_21627140 = header.getOrDefault("X-Amz-Credential")
  valid_21627140 = validateParameter(valid_21627140, JString, required = false,
                                   default = nil)
  if valid_21627140 != nil:
    section.add "X-Amz-Credential", valid_21627140
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

proc call*(call_21627142: Call_ListUserPoolClients_21627128; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the clients that have been created for the specified user pool.
  ## 
  let valid = call_21627142.validator(path, query, header, formData, body, _)
  let scheme = call_21627142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627142.makeUrl(scheme.get, call_21627142.host, call_21627142.base,
                               call_21627142.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627142, uri, valid, _)

proc call*(call_21627143: Call_ListUserPoolClients_21627128; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listUserPoolClients
  ## Lists the clients that have been created for the specified user pool.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627144 = newJObject()
  var body_21627145 = newJObject()
  add(query_21627144, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627145 = body
  add(query_21627144, "MaxResults", newJString(MaxResults))
  result = call_21627143.call(nil, query_21627144, nil, nil, body_21627145)

var listUserPoolClients* = Call_ListUserPoolClients_21627128(
    name: "listUserPoolClients", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUserPoolClients",
    validator: validate_ListUserPoolClients_21627129, base: "/",
    makeUrl: url_ListUserPoolClients_21627130,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserPools_21627146 = ref object of OpenApiRestCall_21625435
proc url_ListUserPools_21627148(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUserPools_21627147(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627149 = query.getOrDefault("NextToken")
  valid_21627149 = validateParameter(valid_21627149, JString, required = false,
                                   default = nil)
  if valid_21627149 != nil:
    section.add "NextToken", valid_21627149
  var valid_21627150 = query.getOrDefault("MaxResults")
  valid_21627150 = validateParameter(valid_21627150, JString, required = false,
                                   default = nil)
  if valid_21627150 != nil:
    section.add "MaxResults", valid_21627150
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627151 = header.getOrDefault("X-Amz-Date")
  valid_21627151 = validateParameter(valid_21627151, JString, required = false,
                                   default = nil)
  if valid_21627151 != nil:
    section.add "X-Amz-Date", valid_21627151
  var valid_21627152 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627152 = validateParameter(valid_21627152, JString, required = false,
                                   default = nil)
  if valid_21627152 != nil:
    section.add "X-Amz-Security-Token", valid_21627152
  var valid_21627153 = header.getOrDefault("X-Amz-Target")
  valid_21627153 = validateParameter(valid_21627153, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUserPools"))
  if valid_21627153 != nil:
    section.add "X-Amz-Target", valid_21627153
  var valid_21627154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627154 = validateParameter(valid_21627154, JString, required = false,
                                   default = nil)
  if valid_21627154 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627154
  var valid_21627155 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627155 = validateParameter(valid_21627155, JString, required = false,
                                   default = nil)
  if valid_21627155 != nil:
    section.add "X-Amz-Algorithm", valid_21627155
  var valid_21627156 = header.getOrDefault("X-Amz-Signature")
  valid_21627156 = validateParameter(valid_21627156, JString, required = false,
                                   default = nil)
  if valid_21627156 != nil:
    section.add "X-Amz-Signature", valid_21627156
  var valid_21627157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627157 = validateParameter(valid_21627157, JString, required = false,
                                   default = nil)
  if valid_21627157 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627157
  var valid_21627158 = header.getOrDefault("X-Amz-Credential")
  valid_21627158 = validateParameter(valid_21627158, JString, required = false,
                                   default = nil)
  if valid_21627158 != nil:
    section.add "X-Amz-Credential", valid_21627158
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

proc call*(call_21627160: Call_ListUserPools_21627146; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the user pools associated with an AWS account.
  ## 
  let valid = call_21627160.validator(path, query, header, formData, body, _)
  let scheme = call_21627160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627160.makeUrl(scheme.get, call_21627160.host, call_21627160.base,
                               call_21627160.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627160, uri, valid, _)

proc call*(call_21627161: Call_ListUserPools_21627146; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listUserPools
  ## Lists the user pools associated with an AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627162 = newJObject()
  var body_21627163 = newJObject()
  add(query_21627162, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627163 = body
  add(query_21627162, "MaxResults", newJString(MaxResults))
  result = call_21627161.call(nil, query_21627162, nil, nil, body_21627163)

var listUserPools* = Call_ListUserPools_21627146(name: "listUserPools",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUserPools",
    validator: validate_ListUserPools_21627147, base: "/",
    makeUrl: url_ListUserPools_21627148, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_21627164 = ref object of OpenApiRestCall_21625435
proc url_ListUsers_21627166(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUsers_21627165(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627167 = query.getOrDefault("Limit")
  valid_21627167 = validateParameter(valid_21627167, JString, required = false,
                                   default = nil)
  if valid_21627167 != nil:
    section.add "Limit", valid_21627167
  var valid_21627168 = query.getOrDefault("PaginationToken")
  valid_21627168 = validateParameter(valid_21627168, JString, required = false,
                                   default = nil)
  if valid_21627168 != nil:
    section.add "PaginationToken", valid_21627168
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627169 = header.getOrDefault("X-Amz-Date")
  valid_21627169 = validateParameter(valid_21627169, JString, required = false,
                                   default = nil)
  if valid_21627169 != nil:
    section.add "X-Amz-Date", valid_21627169
  var valid_21627170 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627170 = validateParameter(valid_21627170, JString, required = false,
                                   default = nil)
  if valid_21627170 != nil:
    section.add "X-Amz-Security-Token", valid_21627170
  var valid_21627171 = header.getOrDefault("X-Amz-Target")
  valid_21627171 = validateParameter(valid_21627171, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUsers"))
  if valid_21627171 != nil:
    section.add "X-Amz-Target", valid_21627171
  var valid_21627172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627172 = validateParameter(valid_21627172, JString, required = false,
                                   default = nil)
  if valid_21627172 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627172
  var valid_21627173 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627173 = validateParameter(valid_21627173, JString, required = false,
                                   default = nil)
  if valid_21627173 != nil:
    section.add "X-Amz-Algorithm", valid_21627173
  var valid_21627174 = header.getOrDefault("X-Amz-Signature")
  valid_21627174 = validateParameter(valid_21627174, JString, required = false,
                                   default = nil)
  if valid_21627174 != nil:
    section.add "X-Amz-Signature", valid_21627174
  var valid_21627175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627175 = validateParameter(valid_21627175, JString, required = false,
                                   default = nil)
  if valid_21627175 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627175
  var valid_21627176 = header.getOrDefault("X-Amz-Credential")
  valid_21627176 = validateParameter(valid_21627176, JString, required = false,
                                   default = nil)
  if valid_21627176 != nil:
    section.add "X-Amz-Credential", valid_21627176
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

proc call*(call_21627178: Call_ListUsers_21627164; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the users in the Amazon Cognito user pool.
  ## 
  let valid = call_21627178.validator(path, query, header, formData, body, _)
  let scheme = call_21627178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627178.makeUrl(scheme.get, call_21627178.host, call_21627178.base,
                               call_21627178.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627178, uri, valid, _)

proc call*(call_21627179: Call_ListUsers_21627164; body: JsonNode;
          Limit: string = ""; PaginationToken: string = ""): Recallable =
  ## listUsers
  ## Lists the users in the Amazon Cognito user pool.
  ##   Limit: string
  ##        : Pagination limit
  ##   PaginationToken: string
  ##                  : Pagination token
  ##   body: JObject (required)
  var query_21627180 = newJObject()
  var body_21627181 = newJObject()
  add(query_21627180, "Limit", newJString(Limit))
  add(query_21627180, "PaginationToken", newJString(PaginationToken))
  if body != nil:
    body_21627181 = body
  result = call_21627179.call(nil, query_21627180, nil, nil, body_21627181)

var listUsers* = Call_ListUsers_21627164(name: "listUsers",
                                      meth: HttpMethod.HttpPost,
                                      host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUsers",
                                      validator: validate_ListUsers_21627165,
                                      base: "/", makeUrl: url_ListUsers_21627166,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsersInGroup_21627182 = ref object of OpenApiRestCall_21625435
proc url_ListUsersInGroup_21627184(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUsersInGroup_21627183(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627185 = query.getOrDefault("Limit")
  valid_21627185 = validateParameter(valid_21627185, JString, required = false,
                                   default = nil)
  if valid_21627185 != nil:
    section.add "Limit", valid_21627185
  var valid_21627186 = query.getOrDefault("NextToken")
  valid_21627186 = validateParameter(valid_21627186, JString, required = false,
                                   default = nil)
  if valid_21627186 != nil:
    section.add "NextToken", valid_21627186
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627187 = header.getOrDefault("X-Amz-Date")
  valid_21627187 = validateParameter(valid_21627187, JString, required = false,
                                   default = nil)
  if valid_21627187 != nil:
    section.add "X-Amz-Date", valid_21627187
  var valid_21627188 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627188 = validateParameter(valid_21627188, JString, required = false,
                                   default = nil)
  if valid_21627188 != nil:
    section.add "X-Amz-Security-Token", valid_21627188
  var valid_21627189 = header.getOrDefault("X-Amz-Target")
  valid_21627189 = validateParameter(valid_21627189, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUsersInGroup"))
  if valid_21627189 != nil:
    section.add "X-Amz-Target", valid_21627189
  var valid_21627190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627190 = validateParameter(valid_21627190, JString, required = false,
                                   default = nil)
  if valid_21627190 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627190
  var valid_21627191 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627191 = validateParameter(valid_21627191, JString, required = false,
                                   default = nil)
  if valid_21627191 != nil:
    section.add "X-Amz-Algorithm", valid_21627191
  var valid_21627192 = header.getOrDefault("X-Amz-Signature")
  valid_21627192 = validateParameter(valid_21627192, JString, required = false,
                                   default = nil)
  if valid_21627192 != nil:
    section.add "X-Amz-Signature", valid_21627192
  var valid_21627193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627193 = validateParameter(valid_21627193, JString, required = false,
                                   default = nil)
  if valid_21627193 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627193
  var valid_21627194 = header.getOrDefault("X-Amz-Credential")
  valid_21627194 = validateParameter(valid_21627194, JString, required = false,
                                   default = nil)
  if valid_21627194 != nil:
    section.add "X-Amz-Credential", valid_21627194
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

proc call*(call_21627196: Call_ListUsersInGroup_21627182; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists the users in the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_21627196.validator(path, query, header, formData, body, _)
  let scheme = call_21627196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627196.makeUrl(scheme.get, call_21627196.host, call_21627196.base,
                               call_21627196.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627196, uri, valid, _)

proc call*(call_21627197: Call_ListUsersInGroup_21627182; body: JsonNode;
          Limit: string = ""; NextToken: string = ""): Recallable =
  ## listUsersInGroup
  ## <p>Lists the users in the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21627198 = newJObject()
  var body_21627199 = newJObject()
  add(query_21627198, "Limit", newJString(Limit))
  add(query_21627198, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627199 = body
  result = call_21627197.call(nil, query_21627198, nil, nil, body_21627199)

var listUsersInGroup* = Call_ListUsersInGroup_21627182(name: "listUsersInGroup",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUsersInGroup",
    validator: validate_ListUsersInGroup_21627183, base: "/",
    makeUrl: url_ListUsersInGroup_21627184, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResendConfirmationCode_21627200 = ref object of OpenApiRestCall_21625435
proc url_ResendConfirmationCode_21627202(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ResendConfirmationCode_21627201(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627203 = header.getOrDefault("X-Amz-Date")
  valid_21627203 = validateParameter(valid_21627203, JString, required = false,
                                   default = nil)
  if valid_21627203 != nil:
    section.add "X-Amz-Date", valid_21627203
  var valid_21627204 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627204 = validateParameter(valid_21627204, JString, required = false,
                                   default = nil)
  if valid_21627204 != nil:
    section.add "X-Amz-Security-Token", valid_21627204
  var valid_21627205 = header.getOrDefault("X-Amz-Target")
  valid_21627205 = validateParameter(valid_21627205, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ResendConfirmationCode"))
  if valid_21627205 != nil:
    section.add "X-Amz-Target", valid_21627205
  var valid_21627206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627206 = validateParameter(valid_21627206, JString, required = false,
                                   default = nil)
  if valid_21627206 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627206
  var valid_21627207 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627207 = validateParameter(valid_21627207, JString, required = false,
                                   default = nil)
  if valid_21627207 != nil:
    section.add "X-Amz-Algorithm", valid_21627207
  var valid_21627208 = header.getOrDefault("X-Amz-Signature")
  valid_21627208 = validateParameter(valid_21627208, JString, required = false,
                                   default = nil)
  if valid_21627208 != nil:
    section.add "X-Amz-Signature", valid_21627208
  var valid_21627209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627209 = validateParameter(valid_21627209, JString, required = false,
                                   default = nil)
  if valid_21627209 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627209
  var valid_21627210 = header.getOrDefault("X-Amz-Credential")
  valid_21627210 = validateParameter(valid_21627210, JString, required = false,
                                   default = nil)
  if valid_21627210 != nil:
    section.add "X-Amz-Credential", valid_21627210
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

proc call*(call_21627212: Call_ResendConfirmationCode_21627200;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Resends the confirmation (for confirmation of registration) to a specific user in the user pool.
  ## 
  let valid = call_21627212.validator(path, query, header, formData, body, _)
  let scheme = call_21627212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627212.makeUrl(scheme.get, call_21627212.host, call_21627212.base,
                               call_21627212.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627212, uri, valid, _)

proc call*(call_21627213: Call_ResendConfirmationCode_21627200; body: JsonNode): Recallable =
  ## resendConfirmationCode
  ## Resends the confirmation (for confirmation of registration) to a specific user in the user pool.
  ##   body: JObject (required)
  var body_21627214 = newJObject()
  if body != nil:
    body_21627214 = body
  result = call_21627213.call(nil, nil, nil, nil, body_21627214)

var resendConfirmationCode* = Call_ResendConfirmationCode_21627200(
    name: "resendConfirmationCode", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ResendConfirmationCode",
    validator: validate_ResendConfirmationCode_21627201, base: "/",
    makeUrl: url_ResendConfirmationCode_21627202,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RespondToAuthChallenge_21627215 = ref object of OpenApiRestCall_21625435
proc url_RespondToAuthChallenge_21627217(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RespondToAuthChallenge_21627216(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627218 = header.getOrDefault("X-Amz-Date")
  valid_21627218 = validateParameter(valid_21627218, JString, required = false,
                                   default = nil)
  if valid_21627218 != nil:
    section.add "X-Amz-Date", valid_21627218
  var valid_21627219 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627219 = validateParameter(valid_21627219, JString, required = false,
                                   default = nil)
  if valid_21627219 != nil:
    section.add "X-Amz-Security-Token", valid_21627219
  var valid_21627220 = header.getOrDefault("X-Amz-Target")
  valid_21627220 = validateParameter(valid_21627220, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.RespondToAuthChallenge"))
  if valid_21627220 != nil:
    section.add "X-Amz-Target", valid_21627220
  var valid_21627221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627221 = validateParameter(valid_21627221, JString, required = false,
                                   default = nil)
  if valid_21627221 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627221
  var valid_21627222 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627222 = validateParameter(valid_21627222, JString, required = false,
                                   default = nil)
  if valid_21627222 != nil:
    section.add "X-Amz-Algorithm", valid_21627222
  var valid_21627223 = header.getOrDefault("X-Amz-Signature")
  valid_21627223 = validateParameter(valid_21627223, JString, required = false,
                                   default = nil)
  if valid_21627223 != nil:
    section.add "X-Amz-Signature", valid_21627223
  var valid_21627224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627224 = validateParameter(valid_21627224, JString, required = false,
                                   default = nil)
  if valid_21627224 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627224
  var valid_21627225 = header.getOrDefault("X-Amz-Credential")
  valid_21627225 = validateParameter(valid_21627225, JString, required = false,
                                   default = nil)
  if valid_21627225 != nil:
    section.add "X-Amz-Credential", valid_21627225
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

proc call*(call_21627227: Call_RespondToAuthChallenge_21627215;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Responds to the authentication challenge.
  ## 
  let valid = call_21627227.validator(path, query, header, formData, body, _)
  let scheme = call_21627227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627227.makeUrl(scheme.get, call_21627227.host, call_21627227.base,
                               call_21627227.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627227, uri, valid, _)

proc call*(call_21627228: Call_RespondToAuthChallenge_21627215; body: JsonNode): Recallable =
  ## respondToAuthChallenge
  ## Responds to the authentication challenge.
  ##   body: JObject (required)
  var body_21627229 = newJObject()
  if body != nil:
    body_21627229 = body
  result = call_21627228.call(nil, nil, nil, nil, body_21627229)

var respondToAuthChallenge* = Call_RespondToAuthChallenge_21627215(
    name: "respondToAuthChallenge", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.RespondToAuthChallenge",
    validator: validate_RespondToAuthChallenge_21627216, base: "/",
    makeUrl: url_RespondToAuthChallenge_21627217,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetRiskConfiguration_21627230 = ref object of OpenApiRestCall_21625435
proc url_SetRiskConfiguration_21627232(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SetRiskConfiguration_21627231(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627233 = header.getOrDefault("X-Amz-Date")
  valid_21627233 = validateParameter(valid_21627233, JString, required = false,
                                   default = nil)
  if valid_21627233 != nil:
    section.add "X-Amz-Date", valid_21627233
  var valid_21627234 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627234 = validateParameter(valid_21627234, JString, required = false,
                                   default = nil)
  if valid_21627234 != nil:
    section.add "X-Amz-Security-Token", valid_21627234
  var valid_21627235 = header.getOrDefault("X-Amz-Target")
  valid_21627235 = validateParameter(valid_21627235, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetRiskConfiguration"))
  if valid_21627235 != nil:
    section.add "X-Amz-Target", valid_21627235
  var valid_21627236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627236 = validateParameter(valid_21627236, JString, required = false,
                                   default = nil)
  if valid_21627236 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627236
  var valid_21627237 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627237 = validateParameter(valid_21627237, JString, required = false,
                                   default = nil)
  if valid_21627237 != nil:
    section.add "X-Amz-Algorithm", valid_21627237
  var valid_21627238 = header.getOrDefault("X-Amz-Signature")
  valid_21627238 = validateParameter(valid_21627238, JString, required = false,
                                   default = nil)
  if valid_21627238 != nil:
    section.add "X-Amz-Signature", valid_21627238
  var valid_21627239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627239 = validateParameter(valid_21627239, JString, required = false,
                                   default = nil)
  if valid_21627239 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627239
  var valid_21627240 = header.getOrDefault("X-Amz-Credential")
  valid_21627240 = validateParameter(valid_21627240, JString, required = false,
                                   default = nil)
  if valid_21627240 != nil:
    section.add "X-Amz-Credential", valid_21627240
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

proc call*(call_21627242: Call_SetRiskConfiguration_21627230; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Configures actions on detected risks. To delete the risk configuration for <code>UserPoolId</code> or <code>ClientId</code>, pass null values for all four configuration types.</p> <p>To enable Amazon Cognito advanced security features, update the user pool to include the <code>UserPoolAddOns</code> key<code>AdvancedSecurityMode</code>.</p> <p>See .</p>
  ## 
  let valid = call_21627242.validator(path, query, header, formData, body, _)
  let scheme = call_21627242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627242.makeUrl(scheme.get, call_21627242.host, call_21627242.base,
                               call_21627242.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627242, uri, valid, _)

proc call*(call_21627243: Call_SetRiskConfiguration_21627230; body: JsonNode): Recallable =
  ## setRiskConfiguration
  ## <p>Configures actions on detected risks. To delete the risk configuration for <code>UserPoolId</code> or <code>ClientId</code>, pass null values for all four configuration types.</p> <p>To enable Amazon Cognito advanced security features, update the user pool to include the <code>UserPoolAddOns</code> key<code>AdvancedSecurityMode</code>.</p> <p>See .</p>
  ##   body: JObject (required)
  var body_21627244 = newJObject()
  if body != nil:
    body_21627244 = body
  result = call_21627243.call(nil, nil, nil, nil, body_21627244)

var setRiskConfiguration* = Call_SetRiskConfiguration_21627230(
    name: "setRiskConfiguration", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetRiskConfiguration",
    validator: validate_SetRiskConfiguration_21627231, base: "/",
    makeUrl: url_SetRiskConfiguration_21627232,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUICustomization_21627245 = ref object of OpenApiRestCall_21625435
proc url_SetUICustomization_21627247(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SetUICustomization_21627246(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627248 = header.getOrDefault("X-Amz-Date")
  valid_21627248 = validateParameter(valid_21627248, JString, required = false,
                                   default = nil)
  if valid_21627248 != nil:
    section.add "X-Amz-Date", valid_21627248
  var valid_21627249 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627249 = validateParameter(valid_21627249, JString, required = false,
                                   default = nil)
  if valid_21627249 != nil:
    section.add "X-Amz-Security-Token", valid_21627249
  var valid_21627250 = header.getOrDefault("X-Amz-Target")
  valid_21627250 = validateParameter(valid_21627250, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUICustomization"))
  if valid_21627250 != nil:
    section.add "X-Amz-Target", valid_21627250
  var valid_21627251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627251 = validateParameter(valid_21627251, JString, required = false,
                                   default = nil)
  if valid_21627251 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627251
  var valid_21627252 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627252 = validateParameter(valid_21627252, JString, required = false,
                                   default = nil)
  if valid_21627252 != nil:
    section.add "X-Amz-Algorithm", valid_21627252
  var valid_21627253 = header.getOrDefault("X-Amz-Signature")
  valid_21627253 = validateParameter(valid_21627253, JString, required = false,
                                   default = nil)
  if valid_21627253 != nil:
    section.add "X-Amz-Signature", valid_21627253
  var valid_21627254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627254 = validateParameter(valid_21627254, JString, required = false,
                                   default = nil)
  if valid_21627254 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627254
  var valid_21627255 = header.getOrDefault("X-Amz-Credential")
  valid_21627255 = validateParameter(valid_21627255, JString, required = false,
                                   default = nil)
  if valid_21627255 != nil:
    section.add "X-Amz-Credential", valid_21627255
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

proc call*(call_21627257: Call_SetUICustomization_21627245; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sets the UI customization information for a user pool's built-in app UI.</p> <p>You can specify app UI customization settings for a single client (with a specific <code>clientId</code>) or for all clients (by setting the <code>clientId</code> to <code>ALL</code>). If you specify <code>ALL</code>, the default configuration will be used for every client that has no UI customization set previously. If you specify UI customization settings for a particular client, it will no longer fall back to the <code>ALL</code> configuration. </p> <note> <p>To use this API, your user pool must have a domain associated with it. Otherwise, there is no place to host the app's pages, and the service will throw an error.</p> </note>
  ## 
  let valid = call_21627257.validator(path, query, header, formData, body, _)
  let scheme = call_21627257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627257.makeUrl(scheme.get, call_21627257.host, call_21627257.base,
                               call_21627257.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627257, uri, valid, _)

proc call*(call_21627258: Call_SetUICustomization_21627245; body: JsonNode): Recallable =
  ## setUICustomization
  ## <p>Sets the UI customization information for a user pool's built-in app UI.</p> <p>You can specify app UI customization settings for a single client (with a specific <code>clientId</code>) or for all clients (by setting the <code>clientId</code> to <code>ALL</code>). If you specify <code>ALL</code>, the default configuration will be used for every client that has no UI customization set previously. If you specify UI customization settings for a particular client, it will no longer fall back to the <code>ALL</code> configuration. </p> <note> <p>To use this API, your user pool must have a domain associated with it. Otherwise, there is no place to host the app's pages, and the service will throw an error.</p> </note>
  ##   body: JObject (required)
  var body_21627259 = newJObject()
  if body != nil:
    body_21627259 = body
  result = call_21627258.call(nil, nil, nil, nil, body_21627259)

var setUICustomization* = Call_SetUICustomization_21627245(
    name: "setUICustomization", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUICustomization",
    validator: validate_SetUICustomization_21627246, base: "/",
    makeUrl: url_SetUICustomization_21627247, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUserMFAPreference_21627260 = ref object of OpenApiRestCall_21625435
proc url_SetUserMFAPreference_21627262(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SetUserMFAPreference_21627261(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627263 = header.getOrDefault("X-Amz-Date")
  valid_21627263 = validateParameter(valid_21627263, JString, required = false,
                                   default = nil)
  if valid_21627263 != nil:
    section.add "X-Amz-Date", valid_21627263
  var valid_21627264 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627264 = validateParameter(valid_21627264, JString, required = false,
                                   default = nil)
  if valid_21627264 != nil:
    section.add "X-Amz-Security-Token", valid_21627264
  var valid_21627265 = header.getOrDefault("X-Amz-Target")
  valid_21627265 = validateParameter(valid_21627265, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUserMFAPreference"))
  if valid_21627265 != nil:
    section.add "X-Amz-Target", valid_21627265
  var valid_21627266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627266 = validateParameter(valid_21627266, JString, required = false,
                                   default = nil)
  if valid_21627266 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627266
  var valid_21627267 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627267 = validateParameter(valid_21627267, JString, required = false,
                                   default = nil)
  if valid_21627267 != nil:
    section.add "X-Amz-Algorithm", valid_21627267
  var valid_21627268 = header.getOrDefault("X-Amz-Signature")
  valid_21627268 = validateParameter(valid_21627268, JString, required = false,
                                   default = nil)
  if valid_21627268 != nil:
    section.add "X-Amz-Signature", valid_21627268
  var valid_21627269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627269 = validateParameter(valid_21627269, JString, required = false,
                                   default = nil)
  if valid_21627269 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627269
  var valid_21627270 = header.getOrDefault("X-Amz-Credential")
  valid_21627270 = validateParameter(valid_21627270, JString, required = false,
                                   default = nil)
  if valid_21627270 != nil:
    section.add "X-Amz-Credential", valid_21627270
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

proc call*(call_21627272: Call_SetUserMFAPreference_21627260; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Set the user's multi-factor authentication (MFA) method preference, including which MFA factors are enabled and if any are preferred. Only one factor can be set as preferred. The preferred MFA factor will be used to authenticate a user if multiple factors are enabled. If multiple options are enabled and no preference is set, a challenge to choose an MFA option will be returned during sign in.
  ## 
  let valid = call_21627272.validator(path, query, header, formData, body, _)
  let scheme = call_21627272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627272.makeUrl(scheme.get, call_21627272.host, call_21627272.base,
                               call_21627272.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627272, uri, valid, _)

proc call*(call_21627273: Call_SetUserMFAPreference_21627260; body: JsonNode): Recallable =
  ## setUserMFAPreference
  ## Set the user's multi-factor authentication (MFA) method preference, including which MFA factors are enabled and if any are preferred. Only one factor can be set as preferred. The preferred MFA factor will be used to authenticate a user if multiple factors are enabled. If multiple options are enabled and no preference is set, a challenge to choose an MFA option will be returned during sign in.
  ##   body: JObject (required)
  var body_21627274 = newJObject()
  if body != nil:
    body_21627274 = body
  result = call_21627273.call(nil, nil, nil, nil, body_21627274)

var setUserMFAPreference* = Call_SetUserMFAPreference_21627260(
    name: "setUserMFAPreference", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUserMFAPreference",
    validator: validate_SetUserMFAPreference_21627261, base: "/",
    makeUrl: url_SetUserMFAPreference_21627262,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUserPoolMfaConfig_21627275 = ref object of OpenApiRestCall_21625435
proc url_SetUserPoolMfaConfig_21627277(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SetUserPoolMfaConfig_21627276(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627278 = header.getOrDefault("X-Amz-Date")
  valid_21627278 = validateParameter(valid_21627278, JString, required = false,
                                   default = nil)
  if valid_21627278 != nil:
    section.add "X-Amz-Date", valid_21627278
  var valid_21627279 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627279 = validateParameter(valid_21627279, JString, required = false,
                                   default = nil)
  if valid_21627279 != nil:
    section.add "X-Amz-Security-Token", valid_21627279
  var valid_21627280 = header.getOrDefault("X-Amz-Target")
  valid_21627280 = validateParameter(valid_21627280, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUserPoolMfaConfig"))
  if valid_21627280 != nil:
    section.add "X-Amz-Target", valid_21627280
  var valid_21627281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627281 = validateParameter(valid_21627281, JString, required = false,
                                   default = nil)
  if valid_21627281 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627281
  var valid_21627282 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627282 = validateParameter(valid_21627282, JString, required = false,
                                   default = nil)
  if valid_21627282 != nil:
    section.add "X-Amz-Algorithm", valid_21627282
  var valid_21627283 = header.getOrDefault("X-Amz-Signature")
  valid_21627283 = validateParameter(valid_21627283, JString, required = false,
                                   default = nil)
  if valid_21627283 != nil:
    section.add "X-Amz-Signature", valid_21627283
  var valid_21627284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627284 = validateParameter(valid_21627284, JString, required = false,
                                   default = nil)
  if valid_21627284 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627284
  var valid_21627285 = header.getOrDefault("X-Amz-Credential")
  valid_21627285 = validateParameter(valid_21627285, JString, required = false,
                                   default = nil)
  if valid_21627285 != nil:
    section.add "X-Amz-Credential", valid_21627285
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

proc call*(call_21627287: Call_SetUserPoolMfaConfig_21627275; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Set the user pool multi-factor authentication (MFA) configuration.
  ## 
  let valid = call_21627287.validator(path, query, header, formData, body, _)
  let scheme = call_21627287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627287.makeUrl(scheme.get, call_21627287.host, call_21627287.base,
                               call_21627287.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627287, uri, valid, _)

proc call*(call_21627288: Call_SetUserPoolMfaConfig_21627275; body: JsonNode): Recallable =
  ## setUserPoolMfaConfig
  ## Set the user pool multi-factor authentication (MFA) configuration.
  ##   body: JObject (required)
  var body_21627289 = newJObject()
  if body != nil:
    body_21627289 = body
  result = call_21627288.call(nil, nil, nil, nil, body_21627289)

var setUserPoolMfaConfig* = Call_SetUserPoolMfaConfig_21627275(
    name: "setUserPoolMfaConfig", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUserPoolMfaConfig",
    validator: validate_SetUserPoolMfaConfig_21627276, base: "/",
    makeUrl: url_SetUserPoolMfaConfig_21627277,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUserSettings_21627290 = ref object of OpenApiRestCall_21625435
proc url_SetUserSettings_21627292(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SetUserSettings_21627291(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627293 = header.getOrDefault("X-Amz-Date")
  valid_21627293 = validateParameter(valid_21627293, JString, required = false,
                                   default = nil)
  if valid_21627293 != nil:
    section.add "X-Amz-Date", valid_21627293
  var valid_21627294 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627294 = validateParameter(valid_21627294, JString, required = false,
                                   default = nil)
  if valid_21627294 != nil:
    section.add "X-Amz-Security-Token", valid_21627294
  var valid_21627295 = header.getOrDefault("X-Amz-Target")
  valid_21627295 = validateParameter(valid_21627295, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUserSettings"))
  if valid_21627295 != nil:
    section.add "X-Amz-Target", valid_21627295
  var valid_21627296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627296 = validateParameter(valid_21627296, JString, required = false,
                                   default = nil)
  if valid_21627296 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627296
  var valid_21627297 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627297 = validateParameter(valid_21627297, JString, required = false,
                                   default = nil)
  if valid_21627297 != nil:
    section.add "X-Amz-Algorithm", valid_21627297
  var valid_21627298 = header.getOrDefault("X-Amz-Signature")
  valid_21627298 = validateParameter(valid_21627298, JString, required = false,
                                   default = nil)
  if valid_21627298 != nil:
    section.add "X-Amz-Signature", valid_21627298
  var valid_21627299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627299 = validateParameter(valid_21627299, JString, required = false,
                                   default = nil)
  if valid_21627299 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627299
  var valid_21627300 = header.getOrDefault("X-Amz-Credential")
  valid_21627300 = validateParameter(valid_21627300, JString, required = false,
                                   default = nil)
  if valid_21627300 != nil:
    section.add "X-Amz-Credential", valid_21627300
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

proc call*(call_21627302: Call_SetUserSettings_21627290; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  <i>This action is no longer supported.</i> You can use it to configure only SMS MFA. You can't use it to configure TOTP software token MFA. To configure either type of MFA, use the <a>SetUserMFAPreference</a> action instead.
  ## 
  let valid = call_21627302.validator(path, query, header, formData, body, _)
  let scheme = call_21627302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627302.makeUrl(scheme.get, call_21627302.host, call_21627302.base,
                               call_21627302.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627302, uri, valid, _)

proc call*(call_21627303: Call_SetUserSettings_21627290; body: JsonNode): Recallable =
  ## setUserSettings
  ##  <i>This action is no longer supported.</i> You can use it to configure only SMS MFA. You can't use it to configure TOTP software token MFA. To configure either type of MFA, use the <a>SetUserMFAPreference</a> action instead.
  ##   body: JObject (required)
  var body_21627304 = newJObject()
  if body != nil:
    body_21627304 = body
  result = call_21627303.call(nil, nil, nil, nil, body_21627304)

var setUserSettings* = Call_SetUserSettings_21627290(name: "setUserSettings",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUserSettings",
    validator: validate_SetUserSettings_21627291, base: "/",
    makeUrl: url_SetUserSettings_21627292, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SignUp_21627305 = ref object of OpenApiRestCall_21625435
proc url_SignUp_21627307(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SignUp_21627306(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627308 = header.getOrDefault("X-Amz-Date")
  valid_21627308 = validateParameter(valid_21627308, JString, required = false,
                                   default = nil)
  if valid_21627308 != nil:
    section.add "X-Amz-Date", valid_21627308
  var valid_21627309 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627309 = validateParameter(valid_21627309, JString, required = false,
                                   default = nil)
  if valid_21627309 != nil:
    section.add "X-Amz-Security-Token", valid_21627309
  var valid_21627310 = header.getOrDefault("X-Amz-Target")
  valid_21627310 = validateParameter(valid_21627310, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SignUp"))
  if valid_21627310 != nil:
    section.add "X-Amz-Target", valid_21627310
  var valid_21627311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627311 = validateParameter(valid_21627311, JString, required = false,
                                   default = nil)
  if valid_21627311 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627311
  var valid_21627312 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627312 = validateParameter(valid_21627312, JString, required = false,
                                   default = nil)
  if valid_21627312 != nil:
    section.add "X-Amz-Algorithm", valid_21627312
  var valid_21627313 = header.getOrDefault("X-Amz-Signature")
  valid_21627313 = validateParameter(valid_21627313, JString, required = false,
                                   default = nil)
  if valid_21627313 != nil:
    section.add "X-Amz-Signature", valid_21627313
  var valid_21627314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627314 = validateParameter(valid_21627314, JString, required = false,
                                   default = nil)
  if valid_21627314 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627314
  var valid_21627315 = header.getOrDefault("X-Amz-Credential")
  valid_21627315 = validateParameter(valid_21627315, JString, required = false,
                                   default = nil)
  if valid_21627315 != nil:
    section.add "X-Amz-Credential", valid_21627315
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

proc call*(call_21627317: Call_SignUp_21627305; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Registers the user in the specified user pool and creates a user name, password, and user attributes.
  ## 
  let valid = call_21627317.validator(path, query, header, formData, body, _)
  let scheme = call_21627317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627317.makeUrl(scheme.get, call_21627317.host, call_21627317.base,
                               call_21627317.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627317, uri, valid, _)

proc call*(call_21627318: Call_SignUp_21627305; body: JsonNode): Recallable =
  ## signUp
  ## Registers the user in the specified user pool and creates a user name, password, and user attributes.
  ##   body: JObject (required)
  var body_21627319 = newJObject()
  if body != nil:
    body_21627319 = body
  result = call_21627318.call(nil, nil, nil, nil, body_21627319)

var signUp* = Call_SignUp_21627305(name: "signUp", meth: HttpMethod.HttpPost,
                                host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SignUp",
                                validator: validate_SignUp_21627306, base: "/",
                                makeUrl: url_SignUp_21627307,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartUserImportJob_21627320 = ref object of OpenApiRestCall_21625435
proc url_StartUserImportJob_21627322(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartUserImportJob_21627321(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627323 = header.getOrDefault("X-Amz-Date")
  valid_21627323 = validateParameter(valid_21627323, JString, required = false,
                                   default = nil)
  if valid_21627323 != nil:
    section.add "X-Amz-Date", valid_21627323
  var valid_21627324 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627324 = validateParameter(valid_21627324, JString, required = false,
                                   default = nil)
  if valid_21627324 != nil:
    section.add "X-Amz-Security-Token", valid_21627324
  var valid_21627325 = header.getOrDefault("X-Amz-Target")
  valid_21627325 = validateParameter(valid_21627325, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.StartUserImportJob"))
  if valid_21627325 != nil:
    section.add "X-Amz-Target", valid_21627325
  var valid_21627326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627326 = validateParameter(valid_21627326, JString, required = false,
                                   default = nil)
  if valid_21627326 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627326
  var valid_21627327 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627327 = validateParameter(valid_21627327, JString, required = false,
                                   default = nil)
  if valid_21627327 != nil:
    section.add "X-Amz-Algorithm", valid_21627327
  var valid_21627328 = header.getOrDefault("X-Amz-Signature")
  valid_21627328 = validateParameter(valid_21627328, JString, required = false,
                                   default = nil)
  if valid_21627328 != nil:
    section.add "X-Amz-Signature", valid_21627328
  var valid_21627329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627329 = validateParameter(valid_21627329, JString, required = false,
                                   default = nil)
  if valid_21627329 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627329
  var valid_21627330 = header.getOrDefault("X-Amz-Credential")
  valid_21627330 = validateParameter(valid_21627330, JString, required = false,
                                   default = nil)
  if valid_21627330 != nil:
    section.add "X-Amz-Credential", valid_21627330
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

proc call*(call_21627332: Call_StartUserImportJob_21627320; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts the user import.
  ## 
  let valid = call_21627332.validator(path, query, header, formData, body, _)
  let scheme = call_21627332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627332.makeUrl(scheme.get, call_21627332.host, call_21627332.base,
                               call_21627332.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627332, uri, valid, _)

proc call*(call_21627333: Call_StartUserImportJob_21627320; body: JsonNode): Recallable =
  ## startUserImportJob
  ## Starts the user import.
  ##   body: JObject (required)
  var body_21627334 = newJObject()
  if body != nil:
    body_21627334 = body
  result = call_21627333.call(nil, nil, nil, nil, body_21627334)

var startUserImportJob* = Call_StartUserImportJob_21627320(
    name: "startUserImportJob", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.StartUserImportJob",
    validator: validate_StartUserImportJob_21627321, base: "/",
    makeUrl: url_StartUserImportJob_21627322, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopUserImportJob_21627335 = ref object of OpenApiRestCall_21625435
proc url_StopUserImportJob_21627337(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopUserImportJob_21627336(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627338 = header.getOrDefault("X-Amz-Date")
  valid_21627338 = validateParameter(valid_21627338, JString, required = false,
                                   default = nil)
  if valid_21627338 != nil:
    section.add "X-Amz-Date", valid_21627338
  var valid_21627339 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627339 = validateParameter(valid_21627339, JString, required = false,
                                   default = nil)
  if valid_21627339 != nil:
    section.add "X-Amz-Security-Token", valid_21627339
  var valid_21627340 = header.getOrDefault("X-Amz-Target")
  valid_21627340 = validateParameter(valid_21627340, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.StopUserImportJob"))
  if valid_21627340 != nil:
    section.add "X-Amz-Target", valid_21627340
  var valid_21627341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627341 = validateParameter(valid_21627341, JString, required = false,
                                   default = nil)
  if valid_21627341 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627341
  var valid_21627342 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627342 = validateParameter(valid_21627342, JString, required = false,
                                   default = nil)
  if valid_21627342 != nil:
    section.add "X-Amz-Algorithm", valid_21627342
  var valid_21627343 = header.getOrDefault("X-Amz-Signature")
  valid_21627343 = validateParameter(valid_21627343, JString, required = false,
                                   default = nil)
  if valid_21627343 != nil:
    section.add "X-Amz-Signature", valid_21627343
  var valid_21627344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627344 = validateParameter(valid_21627344, JString, required = false,
                                   default = nil)
  if valid_21627344 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627344
  var valid_21627345 = header.getOrDefault("X-Amz-Credential")
  valid_21627345 = validateParameter(valid_21627345, JString, required = false,
                                   default = nil)
  if valid_21627345 != nil:
    section.add "X-Amz-Credential", valid_21627345
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

proc call*(call_21627347: Call_StopUserImportJob_21627335; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops the user import job.
  ## 
  let valid = call_21627347.validator(path, query, header, formData, body, _)
  let scheme = call_21627347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627347.makeUrl(scheme.get, call_21627347.host, call_21627347.base,
                               call_21627347.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627347, uri, valid, _)

proc call*(call_21627348: Call_StopUserImportJob_21627335; body: JsonNode): Recallable =
  ## stopUserImportJob
  ## Stops the user import job.
  ##   body: JObject (required)
  var body_21627349 = newJObject()
  if body != nil:
    body_21627349 = body
  result = call_21627348.call(nil, nil, nil, nil, body_21627349)

var stopUserImportJob* = Call_StopUserImportJob_21627335(name: "stopUserImportJob",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.StopUserImportJob",
    validator: validate_StopUserImportJob_21627336, base: "/",
    makeUrl: url_StopUserImportJob_21627337, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21627350 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21627352(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_21627351(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627353 = header.getOrDefault("X-Amz-Date")
  valid_21627353 = validateParameter(valid_21627353, JString, required = false,
                                   default = nil)
  if valid_21627353 != nil:
    section.add "X-Amz-Date", valid_21627353
  var valid_21627354 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627354 = validateParameter(valid_21627354, JString, required = false,
                                   default = nil)
  if valid_21627354 != nil:
    section.add "X-Amz-Security-Token", valid_21627354
  var valid_21627355 = header.getOrDefault("X-Amz-Target")
  valid_21627355 = validateParameter(valid_21627355, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.TagResource"))
  if valid_21627355 != nil:
    section.add "X-Amz-Target", valid_21627355
  var valid_21627356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627356 = validateParameter(valid_21627356, JString, required = false,
                                   default = nil)
  if valid_21627356 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627356
  var valid_21627357 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627357 = validateParameter(valid_21627357, JString, required = false,
                                   default = nil)
  if valid_21627357 != nil:
    section.add "X-Amz-Algorithm", valid_21627357
  var valid_21627358 = header.getOrDefault("X-Amz-Signature")
  valid_21627358 = validateParameter(valid_21627358, JString, required = false,
                                   default = nil)
  if valid_21627358 != nil:
    section.add "X-Amz-Signature", valid_21627358
  var valid_21627359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627359 = validateParameter(valid_21627359, JString, required = false,
                                   default = nil)
  if valid_21627359 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627359
  var valid_21627360 = header.getOrDefault("X-Amz-Credential")
  valid_21627360 = validateParameter(valid_21627360, JString, required = false,
                                   default = nil)
  if valid_21627360 != nil:
    section.add "X-Amz-Credential", valid_21627360
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

proc call*(call_21627362: Call_TagResource_21627350; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Assigns a set of tags to an Amazon Cognito user pool. A tag is a label that you can use to categorize and manage user pools in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>Each tag consists of a key and value, both of which you define. A key is a general category for more specific values. For example, if you have two versions of a user pool, one for testing and another for production, you might assign an <code>Environment</code> tag key to both user pools. The value of this key might be <code>Test</code> for one user pool and <code>Production</code> for the other.</p> <p>Tags are useful for cost tracking and access control. You can activate your tags so that they appear on the Billing and Cost Management console, where you can track the costs associated with your user pools. In an IAM policy, you can constrain permissions for user pools based on specific tags or tag values.</p> <p>You can use this action up to 5 times per second, per account. A user pool can have as many as 50 tags.</p>
  ## 
  let valid = call_21627362.validator(path, query, header, formData, body, _)
  let scheme = call_21627362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627362.makeUrl(scheme.get, call_21627362.host, call_21627362.base,
                               call_21627362.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627362, uri, valid, _)

proc call*(call_21627363: Call_TagResource_21627350; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Assigns a set of tags to an Amazon Cognito user pool. A tag is a label that you can use to categorize and manage user pools in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>Each tag consists of a key and value, both of which you define. A key is a general category for more specific values. For example, if you have two versions of a user pool, one for testing and another for production, you might assign an <code>Environment</code> tag key to both user pools. The value of this key might be <code>Test</code> for one user pool and <code>Production</code> for the other.</p> <p>Tags are useful for cost tracking and access control. You can activate your tags so that they appear on the Billing and Cost Management console, where you can track the costs associated with your user pools. In an IAM policy, you can constrain permissions for user pools based on specific tags or tag values.</p> <p>You can use this action up to 5 times per second, per account. A user pool can have as many as 50 tags.</p>
  ##   body: JObject (required)
  var body_21627364 = newJObject()
  if body != nil:
    body_21627364 = body
  result = call_21627363.call(nil, nil, nil, nil, body_21627364)

var tagResource* = Call_TagResource_21627350(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.TagResource",
    validator: validate_TagResource_21627351, base: "/", makeUrl: url_TagResource_21627352,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21627365 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21627367(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_21627366(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627368 = header.getOrDefault("X-Amz-Date")
  valid_21627368 = validateParameter(valid_21627368, JString, required = false,
                                   default = nil)
  if valid_21627368 != nil:
    section.add "X-Amz-Date", valid_21627368
  var valid_21627369 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627369 = validateParameter(valid_21627369, JString, required = false,
                                   default = nil)
  if valid_21627369 != nil:
    section.add "X-Amz-Security-Token", valid_21627369
  var valid_21627370 = header.getOrDefault("X-Amz-Target")
  valid_21627370 = validateParameter(valid_21627370, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UntagResource"))
  if valid_21627370 != nil:
    section.add "X-Amz-Target", valid_21627370
  var valid_21627371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627371 = validateParameter(valid_21627371, JString, required = false,
                                   default = nil)
  if valid_21627371 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627371
  var valid_21627372 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627372 = validateParameter(valid_21627372, JString, required = false,
                                   default = nil)
  if valid_21627372 != nil:
    section.add "X-Amz-Algorithm", valid_21627372
  var valid_21627373 = header.getOrDefault("X-Amz-Signature")
  valid_21627373 = validateParameter(valid_21627373, JString, required = false,
                                   default = nil)
  if valid_21627373 != nil:
    section.add "X-Amz-Signature", valid_21627373
  var valid_21627374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627374 = validateParameter(valid_21627374, JString, required = false,
                                   default = nil)
  if valid_21627374 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627374
  var valid_21627375 = header.getOrDefault("X-Amz-Credential")
  valid_21627375 = validateParameter(valid_21627375, JString, required = false,
                                   default = nil)
  if valid_21627375 != nil:
    section.add "X-Amz-Credential", valid_21627375
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

proc call*(call_21627377: Call_UntagResource_21627365; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the specified tags from an Amazon Cognito user pool. You can use this action up to 5 times per second, per account
  ## 
  let valid = call_21627377.validator(path, query, header, formData, body, _)
  let scheme = call_21627377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627377.makeUrl(scheme.get, call_21627377.host, call_21627377.base,
                               call_21627377.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627377, uri, valid, _)

proc call*(call_21627378: Call_UntagResource_21627365; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tags from an Amazon Cognito user pool. You can use this action up to 5 times per second, per account
  ##   body: JObject (required)
  var body_21627379 = newJObject()
  if body != nil:
    body_21627379 = body
  result = call_21627378.call(nil, nil, nil, nil, body_21627379)

var untagResource* = Call_UntagResource_21627365(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UntagResource",
    validator: validate_UntagResource_21627366, base: "/",
    makeUrl: url_UntagResource_21627367, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthEventFeedback_21627380 = ref object of OpenApiRestCall_21625435
proc url_UpdateAuthEventFeedback_21627382(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateAuthEventFeedback_21627381(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627383 = header.getOrDefault("X-Amz-Date")
  valid_21627383 = validateParameter(valid_21627383, JString, required = false,
                                   default = nil)
  if valid_21627383 != nil:
    section.add "X-Amz-Date", valid_21627383
  var valid_21627384 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627384 = validateParameter(valid_21627384, JString, required = false,
                                   default = nil)
  if valid_21627384 != nil:
    section.add "X-Amz-Security-Token", valid_21627384
  var valid_21627385 = header.getOrDefault("X-Amz-Target")
  valid_21627385 = validateParameter(valid_21627385, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateAuthEventFeedback"))
  if valid_21627385 != nil:
    section.add "X-Amz-Target", valid_21627385
  var valid_21627386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627386 = validateParameter(valid_21627386, JString, required = false,
                                   default = nil)
  if valid_21627386 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627386
  var valid_21627387 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627387 = validateParameter(valid_21627387, JString, required = false,
                                   default = nil)
  if valid_21627387 != nil:
    section.add "X-Amz-Algorithm", valid_21627387
  var valid_21627388 = header.getOrDefault("X-Amz-Signature")
  valid_21627388 = validateParameter(valid_21627388, JString, required = false,
                                   default = nil)
  if valid_21627388 != nil:
    section.add "X-Amz-Signature", valid_21627388
  var valid_21627389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627389 = validateParameter(valid_21627389, JString, required = false,
                                   default = nil)
  if valid_21627389 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627389
  var valid_21627390 = header.getOrDefault("X-Amz-Credential")
  valid_21627390 = validateParameter(valid_21627390, JString, required = false,
                                   default = nil)
  if valid_21627390 != nil:
    section.add "X-Amz-Credential", valid_21627390
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

proc call*(call_21627392: Call_UpdateAuthEventFeedback_21627380;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides the feedback for an authentication event whether it was from a valid user or not. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ## 
  let valid = call_21627392.validator(path, query, header, formData, body, _)
  let scheme = call_21627392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627392.makeUrl(scheme.get, call_21627392.host, call_21627392.base,
                               call_21627392.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627392, uri, valid, _)

proc call*(call_21627393: Call_UpdateAuthEventFeedback_21627380; body: JsonNode): Recallable =
  ## updateAuthEventFeedback
  ## Provides the feedback for an authentication event whether it was from a valid user or not. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ##   body: JObject (required)
  var body_21627394 = newJObject()
  if body != nil:
    body_21627394 = body
  result = call_21627393.call(nil, nil, nil, nil, body_21627394)

var updateAuthEventFeedback* = Call_UpdateAuthEventFeedback_21627380(
    name: "updateAuthEventFeedback", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateAuthEventFeedback",
    validator: validate_UpdateAuthEventFeedback_21627381, base: "/",
    makeUrl: url_UpdateAuthEventFeedback_21627382,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceStatus_21627395 = ref object of OpenApiRestCall_21625435
proc url_UpdateDeviceStatus_21627397(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDeviceStatus_21627396(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627398 = header.getOrDefault("X-Amz-Date")
  valid_21627398 = validateParameter(valid_21627398, JString, required = false,
                                   default = nil)
  if valid_21627398 != nil:
    section.add "X-Amz-Date", valid_21627398
  var valid_21627399 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627399 = validateParameter(valid_21627399, JString, required = false,
                                   default = nil)
  if valid_21627399 != nil:
    section.add "X-Amz-Security-Token", valid_21627399
  var valid_21627400 = header.getOrDefault("X-Amz-Target")
  valid_21627400 = validateParameter(valid_21627400, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateDeviceStatus"))
  if valid_21627400 != nil:
    section.add "X-Amz-Target", valid_21627400
  var valid_21627401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627401 = validateParameter(valid_21627401, JString, required = false,
                                   default = nil)
  if valid_21627401 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627401
  var valid_21627402 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627402 = validateParameter(valid_21627402, JString, required = false,
                                   default = nil)
  if valid_21627402 != nil:
    section.add "X-Amz-Algorithm", valid_21627402
  var valid_21627403 = header.getOrDefault("X-Amz-Signature")
  valid_21627403 = validateParameter(valid_21627403, JString, required = false,
                                   default = nil)
  if valid_21627403 != nil:
    section.add "X-Amz-Signature", valid_21627403
  var valid_21627404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627404 = validateParameter(valid_21627404, JString, required = false,
                                   default = nil)
  if valid_21627404 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627404
  var valid_21627405 = header.getOrDefault("X-Amz-Credential")
  valid_21627405 = validateParameter(valid_21627405, JString, required = false,
                                   default = nil)
  if valid_21627405 != nil:
    section.add "X-Amz-Credential", valid_21627405
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

proc call*(call_21627407: Call_UpdateDeviceStatus_21627395; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the device status.
  ## 
  let valid = call_21627407.validator(path, query, header, formData, body, _)
  let scheme = call_21627407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627407.makeUrl(scheme.get, call_21627407.host, call_21627407.base,
                               call_21627407.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627407, uri, valid, _)

proc call*(call_21627408: Call_UpdateDeviceStatus_21627395; body: JsonNode): Recallable =
  ## updateDeviceStatus
  ## Updates the device status.
  ##   body: JObject (required)
  var body_21627409 = newJObject()
  if body != nil:
    body_21627409 = body
  result = call_21627408.call(nil, nil, nil, nil, body_21627409)

var updateDeviceStatus* = Call_UpdateDeviceStatus_21627395(
    name: "updateDeviceStatus", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateDeviceStatus",
    validator: validate_UpdateDeviceStatus_21627396, base: "/",
    makeUrl: url_UpdateDeviceStatus_21627397, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_21627410 = ref object of OpenApiRestCall_21625435
proc url_UpdateGroup_21627412(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateGroup_21627411(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627413 = header.getOrDefault("X-Amz-Date")
  valid_21627413 = validateParameter(valid_21627413, JString, required = false,
                                   default = nil)
  if valid_21627413 != nil:
    section.add "X-Amz-Date", valid_21627413
  var valid_21627414 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627414 = validateParameter(valid_21627414, JString, required = false,
                                   default = nil)
  if valid_21627414 != nil:
    section.add "X-Amz-Security-Token", valid_21627414
  var valid_21627415 = header.getOrDefault("X-Amz-Target")
  valid_21627415 = validateParameter(valid_21627415, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateGroup"))
  if valid_21627415 != nil:
    section.add "X-Amz-Target", valid_21627415
  var valid_21627416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627416 = validateParameter(valid_21627416, JString, required = false,
                                   default = nil)
  if valid_21627416 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627416
  var valid_21627417 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627417 = validateParameter(valid_21627417, JString, required = false,
                                   default = nil)
  if valid_21627417 != nil:
    section.add "X-Amz-Algorithm", valid_21627417
  var valid_21627418 = header.getOrDefault("X-Amz-Signature")
  valid_21627418 = validateParameter(valid_21627418, JString, required = false,
                                   default = nil)
  if valid_21627418 != nil:
    section.add "X-Amz-Signature", valid_21627418
  var valid_21627419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627419 = validateParameter(valid_21627419, JString, required = false,
                                   default = nil)
  if valid_21627419 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627419
  var valid_21627420 = header.getOrDefault("X-Amz-Credential")
  valid_21627420 = validateParameter(valid_21627420, JString, required = false,
                                   default = nil)
  if valid_21627420 != nil:
    section.add "X-Amz-Credential", valid_21627420
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

proc call*(call_21627422: Call_UpdateGroup_21627410; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the specified group with the specified attributes.</p> <p>Calling this action requires developer credentials.</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ## 
  let valid = call_21627422.validator(path, query, header, formData, body, _)
  let scheme = call_21627422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627422.makeUrl(scheme.get, call_21627422.host, call_21627422.base,
                               call_21627422.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627422, uri, valid, _)

proc call*(call_21627423: Call_UpdateGroup_21627410; body: JsonNode): Recallable =
  ## updateGroup
  ## <p>Updates the specified group with the specified attributes.</p> <p>Calling this action requires developer credentials.</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ##   body: JObject (required)
  var body_21627424 = newJObject()
  if body != nil:
    body_21627424 = body
  result = call_21627423.call(nil, nil, nil, nil, body_21627424)

var updateGroup* = Call_UpdateGroup_21627410(name: "updateGroup",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateGroup",
    validator: validate_UpdateGroup_21627411, base: "/", makeUrl: url_UpdateGroup_21627412,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIdentityProvider_21627425 = ref object of OpenApiRestCall_21625435
proc url_UpdateIdentityProvider_21627427(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateIdentityProvider_21627426(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627428 = header.getOrDefault("X-Amz-Date")
  valid_21627428 = validateParameter(valid_21627428, JString, required = false,
                                   default = nil)
  if valid_21627428 != nil:
    section.add "X-Amz-Date", valid_21627428
  var valid_21627429 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627429 = validateParameter(valid_21627429, JString, required = false,
                                   default = nil)
  if valid_21627429 != nil:
    section.add "X-Amz-Security-Token", valid_21627429
  var valid_21627430 = header.getOrDefault("X-Amz-Target")
  valid_21627430 = validateParameter(valid_21627430, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateIdentityProvider"))
  if valid_21627430 != nil:
    section.add "X-Amz-Target", valid_21627430
  var valid_21627431 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627431 = validateParameter(valid_21627431, JString, required = false,
                                   default = nil)
  if valid_21627431 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627431
  var valid_21627432 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627432 = validateParameter(valid_21627432, JString, required = false,
                                   default = nil)
  if valid_21627432 != nil:
    section.add "X-Amz-Algorithm", valid_21627432
  var valid_21627433 = header.getOrDefault("X-Amz-Signature")
  valid_21627433 = validateParameter(valid_21627433, JString, required = false,
                                   default = nil)
  if valid_21627433 != nil:
    section.add "X-Amz-Signature", valid_21627433
  var valid_21627434 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627434 = validateParameter(valid_21627434, JString, required = false,
                                   default = nil)
  if valid_21627434 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627434
  var valid_21627435 = header.getOrDefault("X-Amz-Credential")
  valid_21627435 = validateParameter(valid_21627435, JString, required = false,
                                   default = nil)
  if valid_21627435 != nil:
    section.add "X-Amz-Credential", valid_21627435
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

proc call*(call_21627437: Call_UpdateIdentityProvider_21627425;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates identity provider information for a user pool.
  ## 
  let valid = call_21627437.validator(path, query, header, formData, body, _)
  let scheme = call_21627437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627437.makeUrl(scheme.get, call_21627437.host, call_21627437.base,
                               call_21627437.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627437, uri, valid, _)

proc call*(call_21627438: Call_UpdateIdentityProvider_21627425; body: JsonNode): Recallable =
  ## updateIdentityProvider
  ## Updates identity provider information for a user pool.
  ##   body: JObject (required)
  var body_21627439 = newJObject()
  if body != nil:
    body_21627439 = body
  result = call_21627438.call(nil, nil, nil, nil, body_21627439)

var updateIdentityProvider* = Call_UpdateIdentityProvider_21627425(
    name: "updateIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateIdentityProvider",
    validator: validate_UpdateIdentityProvider_21627426, base: "/",
    makeUrl: url_UpdateIdentityProvider_21627427,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceServer_21627440 = ref object of OpenApiRestCall_21625435
proc url_UpdateResourceServer_21627442(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateResourceServer_21627441(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627443 = header.getOrDefault("X-Amz-Date")
  valid_21627443 = validateParameter(valid_21627443, JString, required = false,
                                   default = nil)
  if valid_21627443 != nil:
    section.add "X-Amz-Date", valid_21627443
  var valid_21627444 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627444 = validateParameter(valid_21627444, JString, required = false,
                                   default = nil)
  if valid_21627444 != nil:
    section.add "X-Amz-Security-Token", valid_21627444
  var valid_21627445 = header.getOrDefault("X-Amz-Target")
  valid_21627445 = validateParameter(valid_21627445, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateResourceServer"))
  if valid_21627445 != nil:
    section.add "X-Amz-Target", valid_21627445
  var valid_21627446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627446 = validateParameter(valid_21627446, JString, required = false,
                                   default = nil)
  if valid_21627446 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627446
  var valid_21627447 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627447 = validateParameter(valid_21627447, JString, required = false,
                                   default = nil)
  if valid_21627447 != nil:
    section.add "X-Amz-Algorithm", valid_21627447
  var valid_21627448 = header.getOrDefault("X-Amz-Signature")
  valid_21627448 = validateParameter(valid_21627448, JString, required = false,
                                   default = nil)
  if valid_21627448 != nil:
    section.add "X-Amz-Signature", valid_21627448
  var valid_21627449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627449 = validateParameter(valid_21627449, JString, required = false,
                                   default = nil)
  if valid_21627449 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627449
  var valid_21627450 = header.getOrDefault("X-Amz-Credential")
  valid_21627450 = validateParameter(valid_21627450, JString, required = false,
                                   default = nil)
  if valid_21627450 != nil:
    section.add "X-Amz-Credential", valid_21627450
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

proc call*(call_21627452: Call_UpdateResourceServer_21627440; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the name and scopes of resource server. All other fields are read-only.</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ## 
  let valid = call_21627452.validator(path, query, header, formData, body, _)
  let scheme = call_21627452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627452.makeUrl(scheme.get, call_21627452.host, call_21627452.base,
                               call_21627452.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627452, uri, valid, _)

proc call*(call_21627453: Call_UpdateResourceServer_21627440; body: JsonNode): Recallable =
  ## updateResourceServer
  ## <p>Updates the name and scopes of resource server. All other fields are read-only.</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ##   body: JObject (required)
  var body_21627454 = newJObject()
  if body != nil:
    body_21627454 = body
  result = call_21627453.call(nil, nil, nil, nil, body_21627454)

var updateResourceServer* = Call_UpdateResourceServer_21627440(
    name: "updateResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateResourceServer",
    validator: validate_UpdateResourceServer_21627441, base: "/",
    makeUrl: url_UpdateResourceServer_21627442,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserAttributes_21627455 = ref object of OpenApiRestCall_21625435
proc url_UpdateUserAttributes_21627457(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUserAttributes_21627456(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627458 = header.getOrDefault("X-Amz-Date")
  valid_21627458 = validateParameter(valid_21627458, JString, required = false,
                                   default = nil)
  if valid_21627458 != nil:
    section.add "X-Amz-Date", valid_21627458
  var valid_21627459 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627459 = validateParameter(valid_21627459, JString, required = false,
                                   default = nil)
  if valid_21627459 != nil:
    section.add "X-Amz-Security-Token", valid_21627459
  var valid_21627460 = header.getOrDefault("X-Amz-Target")
  valid_21627460 = validateParameter(valid_21627460, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserAttributes"))
  if valid_21627460 != nil:
    section.add "X-Amz-Target", valid_21627460
  var valid_21627461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627461 = validateParameter(valid_21627461, JString, required = false,
                                   default = nil)
  if valid_21627461 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627461
  var valid_21627462 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627462 = validateParameter(valid_21627462, JString, required = false,
                                   default = nil)
  if valid_21627462 != nil:
    section.add "X-Amz-Algorithm", valid_21627462
  var valid_21627463 = header.getOrDefault("X-Amz-Signature")
  valid_21627463 = validateParameter(valid_21627463, JString, required = false,
                                   default = nil)
  if valid_21627463 != nil:
    section.add "X-Amz-Signature", valid_21627463
  var valid_21627464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627464 = validateParameter(valid_21627464, JString, required = false,
                                   default = nil)
  if valid_21627464 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627464
  var valid_21627465 = header.getOrDefault("X-Amz-Credential")
  valid_21627465 = validateParameter(valid_21627465, JString, required = false,
                                   default = nil)
  if valid_21627465 != nil:
    section.add "X-Amz-Credential", valid_21627465
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

proc call*(call_21627467: Call_UpdateUserAttributes_21627455; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Allows a user to update a specific attribute (one at a time).
  ## 
  let valid = call_21627467.validator(path, query, header, formData, body, _)
  let scheme = call_21627467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627467.makeUrl(scheme.get, call_21627467.host, call_21627467.base,
                               call_21627467.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627467, uri, valid, _)

proc call*(call_21627468: Call_UpdateUserAttributes_21627455; body: JsonNode): Recallable =
  ## updateUserAttributes
  ## Allows a user to update a specific attribute (one at a time).
  ##   body: JObject (required)
  var body_21627469 = newJObject()
  if body != nil:
    body_21627469 = body
  result = call_21627468.call(nil, nil, nil, nil, body_21627469)

var updateUserAttributes* = Call_UpdateUserAttributes_21627455(
    name: "updateUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserAttributes",
    validator: validate_UpdateUserAttributes_21627456, base: "/",
    makeUrl: url_UpdateUserAttributes_21627457,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPool_21627470 = ref object of OpenApiRestCall_21625435
proc url_UpdateUserPool_21627472(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUserPool_21627471(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627473 = header.getOrDefault("X-Amz-Date")
  valid_21627473 = validateParameter(valid_21627473, JString, required = false,
                                   default = nil)
  if valid_21627473 != nil:
    section.add "X-Amz-Date", valid_21627473
  var valid_21627474 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627474 = validateParameter(valid_21627474, JString, required = false,
                                   default = nil)
  if valid_21627474 != nil:
    section.add "X-Amz-Security-Token", valid_21627474
  var valid_21627475 = header.getOrDefault("X-Amz-Target")
  valid_21627475 = validateParameter(valid_21627475, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserPool"))
  if valid_21627475 != nil:
    section.add "X-Amz-Target", valid_21627475
  var valid_21627476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627476 = validateParameter(valid_21627476, JString, required = false,
                                   default = nil)
  if valid_21627476 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627476
  var valid_21627477 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627477 = validateParameter(valid_21627477, JString, required = false,
                                   default = nil)
  if valid_21627477 != nil:
    section.add "X-Amz-Algorithm", valid_21627477
  var valid_21627478 = header.getOrDefault("X-Amz-Signature")
  valid_21627478 = validateParameter(valid_21627478, JString, required = false,
                                   default = nil)
  if valid_21627478 != nil:
    section.add "X-Amz-Signature", valid_21627478
  var valid_21627479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627479 = validateParameter(valid_21627479, JString, required = false,
                                   default = nil)
  if valid_21627479 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627479
  var valid_21627480 = header.getOrDefault("X-Amz-Credential")
  valid_21627480 = validateParameter(valid_21627480, JString, required = false,
                                   default = nil)
  if valid_21627480 != nil:
    section.add "X-Amz-Credential", valid_21627480
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

proc call*(call_21627482: Call_UpdateUserPool_21627470; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the specified user pool with the specified attributes. You can get a list of the current user pool settings with .</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ## 
  let valid = call_21627482.validator(path, query, header, formData, body, _)
  let scheme = call_21627482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627482.makeUrl(scheme.get, call_21627482.host, call_21627482.base,
                               call_21627482.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627482, uri, valid, _)

proc call*(call_21627483: Call_UpdateUserPool_21627470; body: JsonNode): Recallable =
  ## updateUserPool
  ## <p>Updates the specified user pool with the specified attributes. You can get a list of the current user pool settings with .</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ##   body: JObject (required)
  var body_21627484 = newJObject()
  if body != nil:
    body_21627484 = body
  result = call_21627483.call(nil, nil, nil, nil, body_21627484)

var updateUserPool* = Call_UpdateUserPool_21627470(name: "updateUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserPool",
    validator: validate_UpdateUserPool_21627471, base: "/",
    makeUrl: url_UpdateUserPool_21627472, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPoolClient_21627485 = ref object of OpenApiRestCall_21625435
proc url_UpdateUserPoolClient_21627487(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUserPoolClient_21627486(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627488 = header.getOrDefault("X-Amz-Date")
  valid_21627488 = validateParameter(valid_21627488, JString, required = false,
                                   default = nil)
  if valid_21627488 != nil:
    section.add "X-Amz-Date", valid_21627488
  var valid_21627489 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627489 = validateParameter(valid_21627489, JString, required = false,
                                   default = nil)
  if valid_21627489 != nil:
    section.add "X-Amz-Security-Token", valid_21627489
  var valid_21627490 = header.getOrDefault("X-Amz-Target")
  valid_21627490 = validateParameter(valid_21627490, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserPoolClient"))
  if valid_21627490 != nil:
    section.add "X-Amz-Target", valid_21627490
  var valid_21627491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627491 = validateParameter(valid_21627491, JString, required = false,
                                   default = nil)
  if valid_21627491 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627491
  var valid_21627492 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627492 = validateParameter(valid_21627492, JString, required = false,
                                   default = nil)
  if valid_21627492 != nil:
    section.add "X-Amz-Algorithm", valid_21627492
  var valid_21627493 = header.getOrDefault("X-Amz-Signature")
  valid_21627493 = validateParameter(valid_21627493, JString, required = false,
                                   default = nil)
  if valid_21627493 != nil:
    section.add "X-Amz-Signature", valid_21627493
  var valid_21627494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627494 = validateParameter(valid_21627494, JString, required = false,
                                   default = nil)
  if valid_21627494 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627494
  var valid_21627495 = header.getOrDefault("X-Amz-Credential")
  valid_21627495 = validateParameter(valid_21627495, JString, required = false,
                                   default = nil)
  if valid_21627495 != nil:
    section.add "X-Amz-Credential", valid_21627495
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

proc call*(call_21627497: Call_UpdateUserPoolClient_21627485; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the specified user pool app client with the specified attributes. You can get a list of the current user pool app client settings with .</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ## 
  let valid = call_21627497.validator(path, query, header, formData, body, _)
  let scheme = call_21627497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627497.makeUrl(scheme.get, call_21627497.host, call_21627497.base,
                               call_21627497.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627497, uri, valid, _)

proc call*(call_21627498: Call_UpdateUserPoolClient_21627485; body: JsonNode): Recallable =
  ## updateUserPoolClient
  ## <p>Updates the specified user pool app client with the specified attributes. You can get a list of the current user pool app client settings with .</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ##   body: JObject (required)
  var body_21627499 = newJObject()
  if body != nil:
    body_21627499 = body
  result = call_21627498.call(nil, nil, nil, nil, body_21627499)

var updateUserPoolClient* = Call_UpdateUserPoolClient_21627485(
    name: "updateUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserPoolClient",
    validator: validate_UpdateUserPoolClient_21627486, base: "/",
    makeUrl: url_UpdateUserPoolClient_21627487,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPoolDomain_21627500 = ref object of OpenApiRestCall_21625435
proc url_UpdateUserPoolDomain_21627502(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUserPoolDomain_21627501(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627503 = header.getOrDefault("X-Amz-Date")
  valid_21627503 = validateParameter(valid_21627503, JString, required = false,
                                   default = nil)
  if valid_21627503 != nil:
    section.add "X-Amz-Date", valid_21627503
  var valid_21627504 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627504 = validateParameter(valid_21627504, JString, required = false,
                                   default = nil)
  if valid_21627504 != nil:
    section.add "X-Amz-Security-Token", valid_21627504
  var valid_21627505 = header.getOrDefault("X-Amz-Target")
  valid_21627505 = validateParameter(valid_21627505, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserPoolDomain"))
  if valid_21627505 != nil:
    section.add "X-Amz-Target", valid_21627505
  var valid_21627506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627506 = validateParameter(valid_21627506, JString, required = false,
                                   default = nil)
  if valid_21627506 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627506
  var valid_21627507 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627507 = validateParameter(valid_21627507, JString, required = false,
                                   default = nil)
  if valid_21627507 != nil:
    section.add "X-Amz-Algorithm", valid_21627507
  var valid_21627508 = header.getOrDefault("X-Amz-Signature")
  valid_21627508 = validateParameter(valid_21627508, JString, required = false,
                                   default = nil)
  if valid_21627508 != nil:
    section.add "X-Amz-Signature", valid_21627508
  var valid_21627509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627509 = validateParameter(valid_21627509, JString, required = false,
                                   default = nil)
  if valid_21627509 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627509
  var valid_21627510 = header.getOrDefault("X-Amz-Credential")
  valid_21627510 = validateParameter(valid_21627510, JString, required = false,
                                   default = nil)
  if valid_21627510 != nil:
    section.add "X-Amz-Credential", valid_21627510
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

proc call*(call_21627512: Call_UpdateUserPoolDomain_21627500; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the Secure Sockets Layer (SSL) certificate for the custom domain for your user pool.</p> <p>You can use this operation to provide the Amazon Resource Name (ARN) of a new certificate to Amazon Cognito. You cannot use it to change the domain for a user pool.</p> <p>A custom domain is used to host the Amazon Cognito hosted UI, which provides sign-up and sign-in pages for your application. When you set up a custom domain, you provide a certificate that you manage with AWS Certificate Manager (ACM). When necessary, you can use this operation to change the certificate that you applied to your custom domain.</p> <p>Usually, this is unnecessary following routine certificate renewal with ACM. When you renew your existing certificate in ACM, the ARN for your certificate remains the same, and your custom domain uses the new certificate automatically.</p> <p>However, if you replace your existing certificate with a new one, ACM gives the new certificate a new ARN. To apply the new certificate to your custom domain, you must provide this ARN to Amazon Cognito.</p> <p>When you add your new certificate in ACM, you must choose US East (N. Virginia) as the AWS Region.</p> <p>After you submit your request, Amazon Cognito requires up to 1 hour to distribute your new certificate to your custom domain.</p> <p>For more information about adding a custom domain to your user pool, see <a href="https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-add-custom-domain.html">Using Your Own Domain for the Hosted UI</a>.</p>
  ## 
  let valid = call_21627512.validator(path, query, header, formData, body, _)
  let scheme = call_21627512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627512.makeUrl(scheme.get, call_21627512.host, call_21627512.base,
                               call_21627512.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627512, uri, valid, _)

proc call*(call_21627513: Call_UpdateUserPoolDomain_21627500; body: JsonNode): Recallable =
  ## updateUserPoolDomain
  ## <p>Updates the Secure Sockets Layer (SSL) certificate for the custom domain for your user pool.</p> <p>You can use this operation to provide the Amazon Resource Name (ARN) of a new certificate to Amazon Cognito. You cannot use it to change the domain for a user pool.</p> <p>A custom domain is used to host the Amazon Cognito hosted UI, which provides sign-up and sign-in pages for your application. When you set up a custom domain, you provide a certificate that you manage with AWS Certificate Manager (ACM). When necessary, you can use this operation to change the certificate that you applied to your custom domain.</p> <p>Usually, this is unnecessary following routine certificate renewal with ACM. When you renew your existing certificate in ACM, the ARN for your certificate remains the same, and your custom domain uses the new certificate automatically.</p> <p>However, if you replace your existing certificate with a new one, ACM gives the new certificate a new ARN. To apply the new certificate to your custom domain, you must provide this ARN to Amazon Cognito.</p> <p>When you add your new certificate in ACM, you must choose US East (N. Virginia) as the AWS Region.</p> <p>After you submit your request, Amazon Cognito requires up to 1 hour to distribute your new certificate to your custom domain.</p> <p>For more information about adding a custom domain to your user pool, see <a href="https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-add-custom-domain.html">Using Your Own Domain for the Hosted UI</a>.</p>
  ##   body: JObject (required)
  var body_21627514 = newJObject()
  if body != nil:
    body_21627514 = body
  result = call_21627513.call(nil, nil, nil, nil, body_21627514)

var updateUserPoolDomain* = Call_UpdateUserPoolDomain_21627500(
    name: "updateUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserPoolDomain",
    validator: validate_UpdateUserPoolDomain_21627501, base: "/",
    makeUrl: url_UpdateUserPoolDomain_21627502,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_VerifySoftwareToken_21627515 = ref object of OpenApiRestCall_21625435
proc url_VerifySoftwareToken_21627517(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_VerifySoftwareToken_21627516(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627518 = header.getOrDefault("X-Amz-Date")
  valid_21627518 = validateParameter(valid_21627518, JString, required = false,
                                   default = nil)
  if valid_21627518 != nil:
    section.add "X-Amz-Date", valid_21627518
  var valid_21627519 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627519 = validateParameter(valid_21627519, JString, required = false,
                                   default = nil)
  if valid_21627519 != nil:
    section.add "X-Amz-Security-Token", valid_21627519
  var valid_21627520 = header.getOrDefault("X-Amz-Target")
  valid_21627520 = validateParameter(valid_21627520, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.VerifySoftwareToken"))
  if valid_21627520 != nil:
    section.add "X-Amz-Target", valid_21627520
  var valid_21627521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627521 = validateParameter(valid_21627521, JString, required = false,
                                   default = nil)
  if valid_21627521 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627521
  var valid_21627522 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627522 = validateParameter(valid_21627522, JString, required = false,
                                   default = nil)
  if valid_21627522 != nil:
    section.add "X-Amz-Algorithm", valid_21627522
  var valid_21627523 = header.getOrDefault("X-Amz-Signature")
  valid_21627523 = validateParameter(valid_21627523, JString, required = false,
                                   default = nil)
  if valid_21627523 != nil:
    section.add "X-Amz-Signature", valid_21627523
  var valid_21627524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627524 = validateParameter(valid_21627524, JString, required = false,
                                   default = nil)
  if valid_21627524 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627524
  var valid_21627525 = header.getOrDefault("X-Amz-Credential")
  valid_21627525 = validateParameter(valid_21627525, JString, required = false,
                                   default = nil)
  if valid_21627525 != nil:
    section.add "X-Amz-Credential", valid_21627525
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

proc call*(call_21627527: Call_VerifySoftwareToken_21627515; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Use this API to register a user's entered TOTP code and mark the user's software token MFA status as "verified" if successful. The request takes an access token or a session string, but not both.
  ## 
  let valid = call_21627527.validator(path, query, header, formData, body, _)
  let scheme = call_21627527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627527.makeUrl(scheme.get, call_21627527.host, call_21627527.base,
                               call_21627527.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627527, uri, valid, _)

proc call*(call_21627528: Call_VerifySoftwareToken_21627515; body: JsonNode): Recallable =
  ## verifySoftwareToken
  ## Use this API to register a user's entered TOTP code and mark the user's software token MFA status as "verified" if successful. The request takes an access token or a session string, but not both.
  ##   body: JObject (required)
  var body_21627529 = newJObject()
  if body != nil:
    body_21627529 = body
  result = call_21627528.call(nil, nil, nil, nil, body_21627529)

var verifySoftwareToken* = Call_VerifySoftwareToken_21627515(
    name: "verifySoftwareToken", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.VerifySoftwareToken",
    validator: validate_VerifySoftwareToken_21627516, base: "/",
    makeUrl: url_VerifySoftwareToken_21627517,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_VerifyUserAttribute_21627530 = ref object of OpenApiRestCall_21625435
proc url_VerifyUserAttribute_21627532(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_VerifyUserAttribute_21627531(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627533 = header.getOrDefault("X-Amz-Date")
  valid_21627533 = validateParameter(valid_21627533, JString, required = false,
                                   default = nil)
  if valid_21627533 != nil:
    section.add "X-Amz-Date", valid_21627533
  var valid_21627534 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627534 = validateParameter(valid_21627534, JString, required = false,
                                   default = nil)
  if valid_21627534 != nil:
    section.add "X-Amz-Security-Token", valid_21627534
  var valid_21627535 = header.getOrDefault("X-Amz-Target")
  valid_21627535 = validateParameter(valid_21627535, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.VerifyUserAttribute"))
  if valid_21627535 != nil:
    section.add "X-Amz-Target", valid_21627535
  var valid_21627536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627536 = validateParameter(valid_21627536, JString, required = false,
                                   default = nil)
  if valid_21627536 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627536
  var valid_21627537 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627537 = validateParameter(valid_21627537, JString, required = false,
                                   default = nil)
  if valid_21627537 != nil:
    section.add "X-Amz-Algorithm", valid_21627537
  var valid_21627538 = header.getOrDefault("X-Amz-Signature")
  valid_21627538 = validateParameter(valid_21627538, JString, required = false,
                                   default = nil)
  if valid_21627538 != nil:
    section.add "X-Amz-Signature", valid_21627538
  var valid_21627539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627539 = validateParameter(valid_21627539, JString, required = false,
                                   default = nil)
  if valid_21627539 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627539
  var valid_21627540 = header.getOrDefault("X-Amz-Credential")
  valid_21627540 = validateParameter(valid_21627540, JString, required = false,
                                   default = nil)
  if valid_21627540 != nil:
    section.add "X-Amz-Credential", valid_21627540
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

proc call*(call_21627542: Call_VerifyUserAttribute_21627530; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Verifies the specified user attributes in the user pool.
  ## 
  let valid = call_21627542.validator(path, query, header, formData, body, _)
  let scheme = call_21627542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627542.makeUrl(scheme.get, call_21627542.host, call_21627542.base,
                               call_21627542.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627542, uri, valid, _)

proc call*(call_21627543: Call_VerifyUserAttribute_21627530; body: JsonNode): Recallable =
  ## verifyUserAttribute
  ## Verifies the specified user attributes in the user pool.
  ##   body: JObject (required)
  var body_21627544 = newJObject()
  if body != nil:
    body_21627544 = body
  result = call_21627543.call(nil, nil, nil, nil, body_21627544)

var verifyUserAttribute* = Call_VerifyUserAttribute_21627530(
    name: "verifyUserAttribute", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.VerifyUserAttribute",
    validator: validate_VerifyUserAttribute_21627531, base: "/",
    makeUrl: url_VerifyUserAttribute_21627532,
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