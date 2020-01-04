
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  Call_AddCustomAttributes_601727 = ref object of OpenApiRestCall_601389
proc url_AddCustomAttributes_601729(protocol: Scheme; host: string; base: string;
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

proc validate_AddCustomAttributes_601728(path: JsonNode; query: JsonNode;
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
  var valid_601854 = header.getOrDefault("X-Amz-Target")
  valid_601854 = validateParameter(valid_601854, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AddCustomAttributes"))
  if valid_601854 != nil:
    section.add "X-Amz-Target", valid_601854
  var valid_601855 = header.getOrDefault("X-Amz-Signature")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "X-Amz-Signature", valid_601855
  var valid_601856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Content-Sha256", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Date")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Date", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Credential")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Credential", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Security-Token")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Security-Token", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Algorithm")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Algorithm", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-SignedHeaders", valid_601861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601885: Call_AddCustomAttributes_601727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds additional user attributes to the user pool schema.
  ## 
  let valid = call_601885.validator(path, query, header, formData, body)
  let scheme = call_601885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601885.url(scheme.get, call_601885.host, call_601885.base,
                         call_601885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601885, url, valid)

proc call*(call_601956: Call_AddCustomAttributes_601727; body: JsonNode): Recallable =
  ## addCustomAttributes
  ## Adds additional user attributes to the user pool schema.
  ##   body: JObject (required)
  var body_601957 = newJObject()
  if body != nil:
    body_601957 = body
  result = call_601956.call(nil, nil, nil, nil, body_601957)

var addCustomAttributes* = Call_AddCustomAttributes_601727(
    name: "addCustomAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AddCustomAttributes",
    validator: validate_AddCustomAttributes_601728, base: "/",
    url: url_AddCustomAttributes_601729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminAddUserToGroup_601996 = ref object of OpenApiRestCall_601389
proc url_AdminAddUserToGroup_601998(protocol: Scheme; host: string; base: string;
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

proc validate_AdminAddUserToGroup_601997(path: JsonNode; query: JsonNode;
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
  var valid_601999 = header.getOrDefault("X-Amz-Target")
  valid_601999 = validateParameter(valid_601999, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminAddUserToGroup"))
  if valid_601999 != nil:
    section.add "X-Amz-Target", valid_601999
  var valid_602000 = header.getOrDefault("X-Amz-Signature")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Signature", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Content-Sha256", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Date")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Date", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Credential")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Credential", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Security-Token")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Security-Token", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Algorithm")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Algorithm", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-SignedHeaders", valid_602006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602008: Call_AdminAddUserToGroup_601996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified user to the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_602008.validator(path, query, header, formData, body)
  let scheme = call_602008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602008.url(scheme.get, call_602008.host, call_602008.base,
                         call_602008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602008, url, valid)

proc call*(call_602009: Call_AdminAddUserToGroup_601996; body: JsonNode): Recallable =
  ## adminAddUserToGroup
  ## <p>Adds the specified user to the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_602010 = newJObject()
  if body != nil:
    body_602010 = body
  result = call_602009.call(nil, nil, nil, nil, body_602010)

var adminAddUserToGroup* = Call_AdminAddUserToGroup_601996(
    name: "adminAddUserToGroup", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminAddUserToGroup",
    validator: validate_AdminAddUserToGroup_601997, base: "/",
    url: url_AdminAddUserToGroup_601998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminConfirmSignUp_602011 = ref object of OpenApiRestCall_601389
proc url_AdminConfirmSignUp_602013(protocol: Scheme; host: string; base: string;
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

proc validate_AdminConfirmSignUp_602012(path: JsonNode; query: JsonNode;
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
  var valid_602014 = header.getOrDefault("X-Amz-Target")
  valid_602014 = validateParameter(valid_602014, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminConfirmSignUp"))
  if valid_602014 != nil:
    section.add "X-Amz-Target", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-Signature")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Signature", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Content-Sha256", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Date")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Date", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Credential")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Credential", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Security-Token")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Security-Token", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Algorithm")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Algorithm", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-SignedHeaders", valid_602021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602023: Call_AdminConfirmSignUp_602011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Confirms user registration as an admin without using a confirmation code. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_602023.validator(path, query, header, formData, body)
  let scheme = call_602023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602023.url(scheme.get, call_602023.host, call_602023.base,
                         call_602023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602023, url, valid)

proc call*(call_602024: Call_AdminConfirmSignUp_602011; body: JsonNode): Recallable =
  ## adminConfirmSignUp
  ## <p>Confirms user registration as an admin without using a confirmation code. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_602025 = newJObject()
  if body != nil:
    body_602025 = body
  result = call_602024.call(nil, nil, nil, nil, body_602025)

var adminConfirmSignUp* = Call_AdminConfirmSignUp_602011(
    name: "adminConfirmSignUp", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminConfirmSignUp",
    validator: validate_AdminConfirmSignUp_602012, base: "/",
    url: url_AdminConfirmSignUp_602013, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminCreateUser_602026 = ref object of OpenApiRestCall_601389
proc url_AdminCreateUser_602028(protocol: Scheme; host: string; base: string;
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

proc validate_AdminCreateUser_602027(path: JsonNode; query: JsonNode;
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
  var valid_602029 = header.getOrDefault("X-Amz-Target")
  valid_602029 = validateParameter(valid_602029, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminCreateUser"))
  if valid_602029 != nil:
    section.add "X-Amz-Target", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Signature")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Signature", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Content-Sha256", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Date")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Date", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Credential")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Credential", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Security-Token")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Security-Token", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Algorithm")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Algorithm", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-SignedHeaders", valid_602036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602038: Call_AdminCreateUser_602026; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new user in the specified user pool.</p> <p>If <code>MessageAction</code> is not set, the default is to send a welcome message via email or phone (SMS).</p> <note> <p>This message is based on a template that you configured in your call to or . This template includes your custom sign-up instructions and placeholders for user name and temporary password.</p> </note> <p>Alternatively, you can call AdminCreateUser with “SUPPRESS” for the <code>MessageAction</code> parameter, and Amazon Cognito will not send any email. </p> <p>In either case, the user will be in the <code>FORCE_CHANGE_PASSWORD</code> state until they sign in and change their password.</p> <p>AdminCreateUser requires developer credentials.</p>
  ## 
  let valid = call_602038.validator(path, query, header, formData, body)
  let scheme = call_602038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602038.url(scheme.get, call_602038.host, call_602038.base,
                         call_602038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602038, url, valid)

proc call*(call_602039: Call_AdminCreateUser_602026; body: JsonNode): Recallable =
  ## adminCreateUser
  ## <p>Creates a new user in the specified user pool.</p> <p>If <code>MessageAction</code> is not set, the default is to send a welcome message via email or phone (SMS).</p> <note> <p>This message is based on a template that you configured in your call to or . This template includes your custom sign-up instructions and placeholders for user name and temporary password.</p> </note> <p>Alternatively, you can call AdminCreateUser with “SUPPRESS” for the <code>MessageAction</code> parameter, and Amazon Cognito will not send any email. </p> <p>In either case, the user will be in the <code>FORCE_CHANGE_PASSWORD</code> state until they sign in and change their password.</p> <p>AdminCreateUser requires developer credentials.</p>
  ##   body: JObject (required)
  var body_602040 = newJObject()
  if body != nil:
    body_602040 = body
  result = call_602039.call(nil, nil, nil, nil, body_602040)

var adminCreateUser* = Call_AdminCreateUser_602026(name: "adminCreateUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminCreateUser",
    validator: validate_AdminCreateUser_602027, base: "/", url: url_AdminCreateUser_602028,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDeleteUser_602041 = ref object of OpenApiRestCall_601389
proc url_AdminDeleteUser_602043(protocol: Scheme; host: string; base: string;
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

proc validate_AdminDeleteUser_602042(path: JsonNode; query: JsonNode;
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
  var valid_602044 = header.getOrDefault("X-Amz-Target")
  valid_602044 = validateParameter(valid_602044, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDeleteUser"))
  if valid_602044 != nil:
    section.add "X-Amz-Target", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Signature")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Signature", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Content-Sha256", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Date")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Date", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Credential")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Credential", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Security-Token")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Security-Token", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Algorithm")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Algorithm", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-SignedHeaders", valid_602051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602053: Call_AdminDeleteUser_602041; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a user as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_602053.validator(path, query, header, formData, body)
  let scheme = call_602053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602053.url(scheme.get, call_602053.host, call_602053.base,
                         call_602053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602053, url, valid)

proc call*(call_602054: Call_AdminDeleteUser_602041; body: JsonNode): Recallable =
  ## adminDeleteUser
  ## <p>Deletes a user as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_602055 = newJObject()
  if body != nil:
    body_602055 = body
  result = call_602054.call(nil, nil, nil, nil, body_602055)

var adminDeleteUser* = Call_AdminDeleteUser_602041(name: "adminDeleteUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDeleteUser",
    validator: validate_AdminDeleteUser_602042, base: "/", url: url_AdminDeleteUser_602043,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDeleteUserAttributes_602056 = ref object of OpenApiRestCall_601389
proc url_AdminDeleteUserAttributes_602058(protocol: Scheme; host: string;
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

proc validate_AdminDeleteUserAttributes_602057(path: JsonNode; query: JsonNode;
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
  var valid_602059 = header.getOrDefault("X-Amz-Target")
  valid_602059 = validateParameter(valid_602059, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDeleteUserAttributes"))
  if valid_602059 != nil:
    section.add "X-Amz-Target", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-Signature")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Signature", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Content-Sha256", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Date")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Date", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Credential")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Credential", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Security-Token")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Security-Token", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Algorithm")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Algorithm", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-SignedHeaders", valid_602066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602068: Call_AdminDeleteUserAttributes_602056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the user attributes in a user pool as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_602068.validator(path, query, header, formData, body)
  let scheme = call_602068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602068.url(scheme.get, call_602068.host, call_602068.base,
                         call_602068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602068, url, valid)

proc call*(call_602069: Call_AdminDeleteUserAttributes_602056; body: JsonNode): Recallable =
  ## adminDeleteUserAttributes
  ## <p>Deletes the user attributes in a user pool as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_602070 = newJObject()
  if body != nil:
    body_602070 = body
  result = call_602069.call(nil, nil, nil, nil, body_602070)

var adminDeleteUserAttributes* = Call_AdminDeleteUserAttributes_602056(
    name: "adminDeleteUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDeleteUserAttributes",
    validator: validate_AdminDeleteUserAttributes_602057, base: "/",
    url: url_AdminDeleteUserAttributes_602058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDisableProviderForUser_602071 = ref object of OpenApiRestCall_601389
proc url_AdminDisableProviderForUser_602073(protocol: Scheme; host: string;
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

proc validate_AdminDisableProviderForUser_602072(path: JsonNode; query: JsonNode;
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
  var valid_602074 = header.getOrDefault("X-Amz-Target")
  valid_602074 = validateParameter(valid_602074, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDisableProviderForUser"))
  if valid_602074 != nil:
    section.add "X-Amz-Target", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Signature")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Signature", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Content-Sha256", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Date")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Date", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Credential")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Credential", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Security-Token")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Security-Token", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Algorithm")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Algorithm", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-SignedHeaders", valid_602081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602083: Call_AdminDisableProviderForUser_602071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables the user from signing in with the specified external (SAML or social) identity provider. If the user to disable is a Cognito User Pools native username + password user, they are not permitted to use their password to sign-in. If the user to disable is a linked external IdP user, any link between that user and an existing user is removed. The next time the external user (no longer attached to the previously linked <code>DestinationUser</code>) signs in, they must create a new user account. See .</p> <p>This action is enabled only for admin access and requires developer credentials.</p> <p>The <code>ProviderName</code> must match the value specified when creating an IdP for the pool. </p> <p>To disable a native username + password user, the <code>ProviderName</code> value must be <code>Cognito</code> and the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code>, with the <code>ProviderAttributeValue</code> being the name that is used in the user pool for the user.</p> <p>The <code>ProviderAttributeName</code> must always be <code>Cognito_Subject</code> for social identity providers. The <code>ProviderAttributeValue</code> must always be the exact subject that was used when the user was originally linked as a source user.</p> <p>For de-linking a SAML identity, there are two scenarios. If the linked identity has not yet been used to sign-in, the <code>ProviderAttributeName</code> and <code>ProviderAttributeValue</code> must be the same values that were used for the <code>SourceUser</code> when the identities were originally linked in the call. (If the linking was done with <code>ProviderAttributeName</code> set to <code>Cognito_Subject</code>, the same applies here). However, if the user has already signed in, the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code> and <code>ProviderAttributeValue</code> must be the subject of the SAML assertion.</p>
  ## 
  let valid = call_602083.validator(path, query, header, formData, body)
  let scheme = call_602083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602083.url(scheme.get, call_602083.host, call_602083.base,
                         call_602083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602083, url, valid)

proc call*(call_602084: Call_AdminDisableProviderForUser_602071; body: JsonNode): Recallable =
  ## adminDisableProviderForUser
  ## <p>Disables the user from signing in with the specified external (SAML or social) identity provider. If the user to disable is a Cognito User Pools native username + password user, they are not permitted to use their password to sign-in. If the user to disable is a linked external IdP user, any link between that user and an existing user is removed. The next time the external user (no longer attached to the previously linked <code>DestinationUser</code>) signs in, they must create a new user account. See .</p> <p>This action is enabled only for admin access and requires developer credentials.</p> <p>The <code>ProviderName</code> must match the value specified when creating an IdP for the pool. </p> <p>To disable a native username + password user, the <code>ProviderName</code> value must be <code>Cognito</code> and the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code>, with the <code>ProviderAttributeValue</code> being the name that is used in the user pool for the user.</p> <p>The <code>ProviderAttributeName</code> must always be <code>Cognito_Subject</code> for social identity providers. The <code>ProviderAttributeValue</code> must always be the exact subject that was used when the user was originally linked as a source user.</p> <p>For de-linking a SAML identity, there are two scenarios. If the linked identity has not yet been used to sign-in, the <code>ProviderAttributeName</code> and <code>ProviderAttributeValue</code> must be the same values that were used for the <code>SourceUser</code> when the identities were originally linked in the call. (If the linking was done with <code>ProviderAttributeName</code> set to <code>Cognito_Subject</code>, the same applies here). However, if the user has already signed in, the <code>ProviderAttributeName</code> must be <code>Cognito_Subject</code> and <code>ProviderAttributeValue</code> must be the subject of the SAML assertion.</p>
  ##   body: JObject (required)
  var body_602085 = newJObject()
  if body != nil:
    body_602085 = body
  result = call_602084.call(nil, nil, nil, nil, body_602085)

var adminDisableProviderForUser* = Call_AdminDisableProviderForUser_602071(
    name: "adminDisableProviderForUser", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDisableProviderForUser",
    validator: validate_AdminDisableProviderForUser_602072, base: "/",
    url: url_AdminDisableProviderForUser_602073,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminDisableUser_602086 = ref object of OpenApiRestCall_601389
proc url_AdminDisableUser_602088(protocol: Scheme; host: string; base: string;
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

proc validate_AdminDisableUser_602087(path: JsonNode; query: JsonNode;
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
  var valid_602089 = header.getOrDefault("X-Amz-Target")
  valid_602089 = validateParameter(valid_602089, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminDisableUser"))
  if valid_602089 != nil:
    section.add "X-Amz-Target", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Signature")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Signature", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Content-Sha256", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Date")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Date", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Credential")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Credential", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Security-Token")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Security-Token", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Algorithm")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Algorithm", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-SignedHeaders", valid_602096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602098: Call_AdminDisableUser_602086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables the specified user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_602098.validator(path, query, header, formData, body)
  let scheme = call_602098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602098.url(scheme.get, call_602098.host, call_602098.base,
                         call_602098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602098, url, valid)

proc call*(call_602099: Call_AdminDisableUser_602086; body: JsonNode): Recallable =
  ## adminDisableUser
  ## <p>Disables the specified user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_602100 = newJObject()
  if body != nil:
    body_602100 = body
  result = call_602099.call(nil, nil, nil, nil, body_602100)

var adminDisableUser* = Call_AdminDisableUser_602086(name: "adminDisableUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminDisableUser",
    validator: validate_AdminDisableUser_602087, base: "/",
    url: url_AdminDisableUser_602088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminEnableUser_602101 = ref object of OpenApiRestCall_601389
proc url_AdminEnableUser_602103(protocol: Scheme; host: string; base: string;
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

proc validate_AdminEnableUser_602102(path: JsonNode; query: JsonNode;
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
  var valid_602104 = header.getOrDefault("X-Amz-Target")
  valid_602104 = validateParameter(valid_602104, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminEnableUser"))
  if valid_602104 != nil:
    section.add "X-Amz-Target", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Signature")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Signature", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Content-Sha256", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Date")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Date", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Credential")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Credential", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Security-Token")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Security-Token", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Algorithm")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Algorithm", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-SignedHeaders", valid_602111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602113: Call_AdminEnableUser_602101; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the specified user as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_602113.validator(path, query, header, formData, body)
  let scheme = call_602113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602113.url(scheme.get, call_602113.host, call_602113.base,
                         call_602113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602113, url, valid)

proc call*(call_602114: Call_AdminEnableUser_602101; body: JsonNode): Recallable =
  ## adminEnableUser
  ## <p>Enables the specified user as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_602115 = newJObject()
  if body != nil:
    body_602115 = body
  result = call_602114.call(nil, nil, nil, nil, body_602115)

var adminEnableUser* = Call_AdminEnableUser_602101(name: "adminEnableUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminEnableUser",
    validator: validate_AdminEnableUser_602102, base: "/", url: url_AdminEnableUser_602103,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminForgetDevice_602116 = ref object of OpenApiRestCall_601389
proc url_AdminForgetDevice_602118(protocol: Scheme; host: string; base: string;
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

proc validate_AdminForgetDevice_602117(path: JsonNode; query: JsonNode;
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
  var valid_602119 = header.getOrDefault("X-Amz-Target")
  valid_602119 = validateParameter(valid_602119, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminForgetDevice"))
  if valid_602119 != nil:
    section.add "X-Amz-Target", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Signature")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Signature", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Content-Sha256", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Date")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Date", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Credential")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Credential", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Security-Token")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Security-Token", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Algorithm")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Algorithm", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-SignedHeaders", valid_602126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602128: Call_AdminForgetDevice_602116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Forgets the device, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_602128.validator(path, query, header, formData, body)
  let scheme = call_602128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602128.url(scheme.get, call_602128.host, call_602128.base,
                         call_602128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602128, url, valid)

proc call*(call_602129: Call_AdminForgetDevice_602116; body: JsonNode): Recallable =
  ## adminForgetDevice
  ## <p>Forgets the device, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_602130 = newJObject()
  if body != nil:
    body_602130 = body
  result = call_602129.call(nil, nil, nil, nil, body_602130)

var adminForgetDevice* = Call_AdminForgetDevice_602116(name: "adminForgetDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminForgetDevice",
    validator: validate_AdminForgetDevice_602117, base: "/",
    url: url_AdminForgetDevice_602118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminGetDevice_602131 = ref object of OpenApiRestCall_601389
proc url_AdminGetDevice_602133(protocol: Scheme; host: string; base: string;
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

proc validate_AdminGetDevice_602132(path: JsonNode; query: JsonNode;
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
  var valid_602134 = header.getOrDefault("X-Amz-Target")
  valid_602134 = validateParameter(valid_602134, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminGetDevice"))
  if valid_602134 != nil:
    section.add "X-Amz-Target", valid_602134
  var valid_602135 = header.getOrDefault("X-Amz-Signature")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Signature", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Content-Sha256", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-Date")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Date", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-Credential")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Credential", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Security-Token")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Security-Token", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Algorithm")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Algorithm", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-SignedHeaders", valid_602141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602143: Call_AdminGetDevice_602131; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the device, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_602143.validator(path, query, header, formData, body)
  let scheme = call_602143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602143.url(scheme.get, call_602143.host, call_602143.base,
                         call_602143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602143, url, valid)

proc call*(call_602144: Call_AdminGetDevice_602131; body: JsonNode): Recallable =
  ## adminGetDevice
  ## <p>Gets the device, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_602145 = newJObject()
  if body != nil:
    body_602145 = body
  result = call_602144.call(nil, nil, nil, nil, body_602145)

var adminGetDevice* = Call_AdminGetDevice_602131(name: "adminGetDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminGetDevice",
    validator: validate_AdminGetDevice_602132, base: "/", url: url_AdminGetDevice_602133,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminGetUser_602146 = ref object of OpenApiRestCall_601389
proc url_AdminGetUser_602148(protocol: Scheme; host: string; base: string;
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

proc validate_AdminGetUser_602147(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602149 = header.getOrDefault("X-Amz-Target")
  valid_602149 = validateParameter(valid_602149, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminGetUser"))
  if valid_602149 != nil:
    section.add "X-Amz-Target", valid_602149
  var valid_602150 = header.getOrDefault("X-Amz-Signature")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-Signature", valid_602150
  var valid_602151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-Content-Sha256", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-Date")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-Date", valid_602152
  var valid_602153 = header.getOrDefault("X-Amz-Credential")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Credential", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Security-Token")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Security-Token", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-Algorithm")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Algorithm", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-SignedHeaders", valid_602156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602158: Call_AdminGetUser_602146; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the specified user by user name in a user pool as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_602158.validator(path, query, header, formData, body)
  let scheme = call_602158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602158.url(scheme.get, call_602158.host, call_602158.base,
                         call_602158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602158, url, valid)

proc call*(call_602159: Call_AdminGetUser_602146; body: JsonNode): Recallable =
  ## adminGetUser
  ## <p>Gets the specified user by user name in a user pool as an administrator. Works on any user.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_602160 = newJObject()
  if body != nil:
    body_602160 = body
  result = call_602159.call(nil, nil, nil, nil, body_602160)

var adminGetUser* = Call_AdminGetUser_602146(name: "adminGetUser",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminGetUser",
    validator: validate_AdminGetUser_602147, base: "/", url: url_AdminGetUser_602148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminInitiateAuth_602161 = ref object of OpenApiRestCall_601389
proc url_AdminInitiateAuth_602163(protocol: Scheme; host: string; base: string;
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

proc validate_AdminInitiateAuth_602162(path: JsonNode; query: JsonNode;
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
  var valid_602164 = header.getOrDefault("X-Amz-Target")
  valid_602164 = validateParameter(valid_602164, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminInitiateAuth"))
  if valid_602164 != nil:
    section.add "X-Amz-Target", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-Signature")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Signature", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Content-Sha256", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-Date")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Date", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-Credential")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-Credential", valid_602168
  var valid_602169 = header.getOrDefault("X-Amz-Security-Token")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-Security-Token", valid_602169
  var valid_602170 = header.getOrDefault("X-Amz-Algorithm")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-Algorithm", valid_602170
  var valid_602171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "X-Amz-SignedHeaders", valid_602171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602173: Call_AdminInitiateAuth_602161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates the authentication flow, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_602173.validator(path, query, header, formData, body)
  let scheme = call_602173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602173.url(scheme.get, call_602173.host, call_602173.base,
                         call_602173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602173, url, valid)

proc call*(call_602174: Call_AdminInitiateAuth_602161; body: JsonNode): Recallable =
  ## adminInitiateAuth
  ## <p>Initiates the authentication flow, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_602175 = newJObject()
  if body != nil:
    body_602175 = body
  result = call_602174.call(nil, nil, nil, nil, body_602175)

var adminInitiateAuth* = Call_AdminInitiateAuth_602161(name: "adminInitiateAuth",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminInitiateAuth",
    validator: validate_AdminInitiateAuth_602162, base: "/",
    url: url_AdminInitiateAuth_602163, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminLinkProviderForUser_602176 = ref object of OpenApiRestCall_601389
proc url_AdminLinkProviderForUser_602178(protocol: Scheme; host: string;
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

proc validate_AdminLinkProviderForUser_602177(path: JsonNode; query: JsonNode;
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
  var valid_602179 = header.getOrDefault("X-Amz-Target")
  valid_602179 = validateParameter(valid_602179, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminLinkProviderForUser"))
  if valid_602179 != nil:
    section.add "X-Amz-Target", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Signature")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Signature", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Content-Sha256", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-Date")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Date", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-Credential")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Credential", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-Security-Token")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-Security-Token", valid_602184
  var valid_602185 = header.getOrDefault("X-Amz-Algorithm")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "X-Amz-Algorithm", valid_602185
  var valid_602186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "X-Amz-SignedHeaders", valid_602186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602188: Call_AdminLinkProviderForUser_602176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Links an existing user account in a user pool (<code>DestinationUser</code>) to an identity from an external identity provider (<code>SourceUser</code>) based on a specified attribute name and value from the external identity provider. This allows you to create a link from the existing user account to an external federated user identity that has not yet been used to sign in, so that the federated user identity can be used to sign in as the existing user account. </p> <p> For example, if there is an existing user with a username and password, this API links that user to a federated user identity, so that when the federated user identity is used, the user signs in as the existing user account. </p> <important> <p>Because this API allows a user with an external federated identity to sign in as an existing user in the user pool, it is critical that it only be used with external identity providers and provider attributes that have been trusted by the application owner.</p> </important> <p>See also .</p> <p>This action is enabled only for admin access and requires developer credentials.</p>
  ## 
  let valid = call_602188.validator(path, query, header, formData, body)
  let scheme = call_602188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602188.url(scheme.get, call_602188.host, call_602188.base,
                         call_602188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602188, url, valid)

proc call*(call_602189: Call_AdminLinkProviderForUser_602176; body: JsonNode): Recallable =
  ## adminLinkProviderForUser
  ## <p>Links an existing user account in a user pool (<code>DestinationUser</code>) to an identity from an external identity provider (<code>SourceUser</code>) based on a specified attribute name and value from the external identity provider. This allows you to create a link from the existing user account to an external federated user identity that has not yet been used to sign in, so that the federated user identity can be used to sign in as the existing user account. </p> <p> For example, if there is an existing user with a username and password, this API links that user to a federated user identity, so that when the federated user identity is used, the user signs in as the existing user account. </p> <important> <p>Because this API allows a user with an external federated identity to sign in as an existing user in the user pool, it is critical that it only be used with external identity providers and provider attributes that have been trusted by the application owner.</p> </important> <p>See also .</p> <p>This action is enabled only for admin access and requires developer credentials.</p>
  ##   body: JObject (required)
  var body_602190 = newJObject()
  if body != nil:
    body_602190 = body
  result = call_602189.call(nil, nil, nil, nil, body_602190)

var adminLinkProviderForUser* = Call_AdminLinkProviderForUser_602176(
    name: "adminLinkProviderForUser", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminLinkProviderForUser",
    validator: validate_AdminLinkProviderForUser_602177, base: "/",
    url: url_AdminLinkProviderForUser_602178, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminListDevices_602191 = ref object of OpenApiRestCall_601389
proc url_AdminListDevices_602193(protocol: Scheme; host: string; base: string;
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

proc validate_AdminListDevices_602192(path: JsonNode; query: JsonNode;
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
  var valid_602194 = header.getOrDefault("X-Amz-Target")
  valid_602194 = validateParameter(valid_602194, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminListDevices"))
  if valid_602194 != nil:
    section.add "X-Amz-Target", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Signature")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Signature", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Content-Sha256", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Date")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Date", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Credential")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Credential", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-Security-Token")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Security-Token", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-Algorithm")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-Algorithm", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-SignedHeaders", valid_602201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602203: Call_AdminListDevices_602191; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists devices, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_602203.validator(path, query, header, formData, body)
  let scheme = call_602203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602203.url(scheme.get, call_602203.host, call_602203.base,
                         call_602203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602203, url, valid)

proc call*(call_602204: Call_AdminListDevices_602191; body: JsonNode): Recallable =
  ## adminListDevices
  ## <p>Lists devices, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_602205 = newJObject()
  if body != nil:
    body_602205 = body
  result = call_602204.call(nil, nil, nil, nil, body_602205)

var adminListDevices* = Call_AdminListDevices_602191(name: "adminListDevices",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminListDevices",
    validator: validate_AdminListDevices_602192, base: "/",
    url: url_AdminListDevices_602193, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminListGroupsForUser_602206 = ref object of OpenApiRestCall_601389
proc url_AdminListGroupsForUser_602208(protocol: Scheme; host: string; base: string;
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

proc validate_AdminListGroupsForUser_602207(path: JsonNode; query: JsonNode;
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
  var valid_602209 = query.getOrDefault("NextToken")
  valid_602209 = validateParameter(valid_602209, JString, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "NextToken", valid_602209
  var valid_602210 = query.getOrDefault("Limit")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "Limit", valid_602210
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
  var valid_602211 = header.getOrDefault("X-Amz-Target")
  valid_602211 = validateParameter(valid_602211, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminListGroupsForUser"))
  if valid_602211 != nil:
    section.add "X-Amz-Target", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-Signature")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-Signature", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Content-Sha256", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-Date")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-Date", valid_602214
  var valid_602215 = header.getOrDefault("X-Amz-Credential")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Credential", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-Security-Token")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-Security-Token", valid_602216
  var valid_602217 = header.getOrDefault("X-Amz-Algorithm")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "X-Amz-Algorithm", valid_602217
  var valid_602218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602218 = validateParameter(valid_602218, JString, required = false,
                                 default = nil)
  if valid_602218 != nil:
    section.add "X-Amz-SignedHeaders", valid_602218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602220: Call_AdminListGroupsForUser_602206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the groups that the user belongs to.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_602220.validator(path, query, header, formData, body)
  let scheme = call_602220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602220.url(scheme.get, call_602220.host, call_602220.base,
                         call_602220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602220, url, valid)

proc call*(call_602221: Call_AdminListGroupsForUser_602206; body: JsonNode;
          NextToken: string = ""; Limit: string = ""): Recallable =
  ## adminListGroupsForUser
  ## <p>Lists the groups that the user belongs to.</p> <p>Calling this action requires developer credentials.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_602222 = newJObject()
  var body_602223 = newJObject()
  add(query_602222, "NextToken", newJString(NextToken))
  add(query_602222, "Limit", newJString(Limit))
  if body != nil:
    body_602223 = body
  result = call_602221.call(nil, query_602222, nil, nil, body_602223)

var adminListGroupsForUser* = Call_AdminListGroupsForUser_602206(
    name: "adminListGroupsForUser", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminListGroupsForUser",
    validator: validate_AdminListGroupsForUser_602207, base: "/",
    url: url_AdminListGroupsForUser_602208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminListUserAuthEvents_602225 = ref object of OpenApiRestCall_601389
proc url_AdminListUserAuthEvents_602227(protocol: Scheme; host: string; base: string;
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

proc validate_AdminListUserAuthEvents_602226(path: JsonNode; query: JsonNode;
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
  var valid_602228 = query.getOrDefault("MaxResults")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "MaxResults", valid_602228
  var valid_602229 = query.getOrDefault("NextToken")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "NextToken", valid_602229
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
  var valid_602230 = header.getOrDefault("X-Amz-Target")
  valid_602230 = validateParameter(valid_602230, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminListUserAuthEvents"))
  if valid_602230 != nil:
    section.add "X-Amz-Target", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-Signature")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-Signature", valid_602231
  var valid_602232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "X-Amz-Content-Sha256", valid_602232
  var valid_602233 = header.getOrDefault("X-Amz-Date")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "X-Amz-Date", valid_602233
  var valid_602234 = header.getOrDefault("X-Amz-Credential")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "X-Amz-Credential", valid_602234
  var valid_602235 = header.getOrDefault("X-Amz-Security-Token")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-Security-Token", valid_602235
  var valid_602236 = header.getOrDefault("X-Amz-Algorithm")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "X-Amz-Algorithm", valid_602236
  var valid_602237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "X-Amz-SignedHeaders", valid_602237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602239: Call_AdminListUserAuthEvents_602225; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists a history of user activity and any risks detected as part of Amazon Cognito advanced security.
  ## 
  let valid = call_602239.validator(path, query, header, formData, body)
  let scheme = call_602239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602239.url(scheme.get, call_602239.host, call_602239.base,
                         call_602239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602239, url, valid)

proc call*(call_602240: Call_AdminListUserAuthEvents_602225; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## adminListUserAuthEvents
  ## Lists a history of user activity and any risks detected as part of Amazon Cognito advanced security.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602241 = newJObject()
  var body_602242 = newJObject()
  add(query_602241, "MaxResults", newJString(MaxResults))
  add(query_602241, "NextToken", newJString(NextToken))
  if body != nil:
    body_602242 = body
  result = call_602240.call(nil, query_602241, nil, nil, body_602242)

var adminListUserAuthEvents* = Call_AdminListUserAuthEvents_602225(
    name: "adminListUserAuthEvents", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminListUserAuthEvents",
    validator: validate_AdminListUserAuthEvents_602226, base: "/",
    url: url_AdminListUserAuthEvents_602227, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminRemoveUserFromGroup_602243 = ref object of OpenApiRestCall_601389
proc url_AdminRemoveUserFromGroup_602245(protocol: Scheme; host: string;
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

proc validate_AdminRemoveUserFromGroup_602244(path: JsonNode; query: JsonNode;
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
  var valid_602246 = header.getOrDefault("X-Amz-Target")
  valid_602246 = validateParameter(valid_602246, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminRemoveUserFromGroup"))
  if valid_602246 != nil:
    section.add "X-Amz-Target", valid_602246
  var valid_602247 = header.getOrDefault("X-Amz-Signature")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-Signature", valid_602247
  var valid_602248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "X-Amz-Content-Sha256", valid_602248
  var valid_602249 = header.getOrDefault("X-Amz-Date")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "X-Amz-Date", valid_602249
  var valid_602250 = header.getOrDefault("X-Amz-Credential")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-Credential", valid_602250
  var valid_602251 = header.getOrDefault("X-Amz-Security-Token")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "X-Amz-Security-Token", valid_602251
  var valid_602252 = header.getOrDefault("X-Amz-Algorithm")
  valid_602252 = validateParameter(valid_602252, JString, required = false,
                                 default = nil)
  if valid_602252 != nil:
    section.add "X-Amz-Algorithm", valid_602252
  var valid_602253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602253 = validateParameter(valid_602253, JString, required = false,
                                 default = nil)
  if valid_602253 != nil:
    section.add "X-Amz-SignedHeaders", valid_602253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602255: Call_AdminRemoveUserFromGroup_602243; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified user from the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_602255.validator(path, query, header, formData, body)
  let scheme = call_602255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602255.url(scheme.get, call_602255.host, call_602255.base,
                         call_602255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602255, url, valid)

proc call*(call_602256: Call_AdminRemoveUserFromGroup_602243; body: JsonNode): Recallable =
  ## adminRemoveUserFromGroup
  ## <p>Removes the specified user from the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_602257 = newJObject()
  if body != nil:
    body_602257 = body
  result = call_602256.call(nil, nil, nil, nil, body_602257)

var adminRemoveUserFromGroup* = Call_AdminRemoveUserFromGroup_602243(
    name: "adminRemoveUserFromGroup", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminRemoveUserFromGroup",
    validator: validate_AdminRemoveUserFromGroup_602244, base: "/",
    url: url_AdminRemoveUserFromGroup_602245, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminResetUserPassword_602258 = ref object of OpenApiRestCall_601389
proc url_AdminResetUserPassword_602260(protocol: Scheme; host: string; base: string;
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

proc validate_AdminResetUserPassword_602259(path: JsonNode; query: JsonNode;
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
  var valid_602261 = header.getOrDefault("X-Amz-Target")
  valid_602261 = validateParameter(valid_602261, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminResetUserPassword"))
  if valid_602261 != nil:
    section.add "X-Amz-Target", valid_602261
  var valid_602262 = header.getOrDefault("X-Amz-Signature")
  valid_602262 = validateParameter(valid_602262, JString, required = false,
                                 default = nil)
  if valid_602262 != nil:
    section.add "X-Amz-Signature", valid_602262
  var valid_602263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602263 = validateParameter(valid_602263, JString, required = false,
                                 default = nil)
  if valid_602263 != nil:
    section.add "X-Amz-Content-Sha256", valid_602263
  var valid_602264 = header.getOrDefault("X-Amz-Date")
  valid_602264 = validateParameter(valid_602264, JString, required = false,
                                 default = nil)
  if valid_602264 != nil:
    section.add "X-Amz-Date", valid_602264
  var valid_602265 = header.getOrDefault("X-Amz-Credential")
  valid_602265 = validateParameter(valid_602265, JString, required = false,
                                 default = nil)
  if valid_602265 != nil:
    section.add "X-Amz-Credential", valid_602265
  var valid_602266 = header.getOrDefault("X-Amz-Security-Token")
  valid_602266 = validateParameter(valid_602266, JString, required = false,
                                 default = nil)
  if valid_602266 != nil:
    section.add "X-Amz-Security-Token", valid_602266
  var valid_602267 = header.getOrDefault("X-Amz-Algorithm")
  valid_602267 = validateParameter(valid_602267, JString, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "X-Amz-Algorithm", valid_602267
  var valid_602268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602268 = validateParameter(valid_602268, JString, required = false,
                                 default = nil)
  if valid_602268 != nil:
    section.add "X-Amz-SignedHeaders", valid_602268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602270: Call_AdminResetUserPassword_602258; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Resets the specified user's password in a user pool as an administrator. Works on any user.</p> <p>When a developer calls this API, the current password is invalidated, so it must be changed. If a user tries to sign in after the API is called, the app will get a PasswordResetRequiredException exception back and should direct the user down the flow to reset the password, which is the same as the forgot password flow. In addition, if the user pool has phone verification selected and a verified phone number exists for the user, or if email verification is selected and a verified email exists for the user, calling this API will also result in sending a message to the end user with the code to change their password.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_602270.validator(path, query, header, formData, body)
  let scheme = call_602270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602270.url(scheme.get, call_602270.host, call_602270.base,
                         call_602270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602270, url, valid)

proc call*(call_602271: Call_AdminResetUserPassword_602258; body: JsonNode): Recallable =
  ## adminResetUserPassword
  ## <p>Resets the specified user's password in a user pool as an administrator. Works on any user.</p> <p>When a developer calls this API, the current password is invalidated, so it must be changed. If a user tries to sign in after the API is called, the app will get a PasswordResetRequiredException exception back and should direct the user down the flow to reset the password, which is the same as the forgot password flow. In addition, if the user pool has phone verification selected and a verified phone number exists for the user, or if email verification is selected and a verified email exists for the user, calling this API will also result in sending a message to the end user with the code to change their password.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_602272 = newJObject()
  if body != nil:
    body_602272 = body
  result = call_602271.call(nil, nil, nil, nil, body_602272)

var adminResetUserPassword* = Call_AdminResetUserPassword_602258(
    name: "adminResetUserPassword", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminResetUserPassword",
    validator: validate_AdminResetUserPassword_602259, base: "/",
    url: url_AdminResetUserPassword_602260, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminRespondToAuthChallenge_602273 = ref object of OpenApiRestCall_601389
proc url_AdminRespondToAuthChallenge_602275(protocol: Scheme; host: string;
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

proc validate_AdminRespondToAuthChallenge_602274(path: JsonNode; query: JsonNode;
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
  var valid_602276 = header.getOrDefault("X-Amz-Target")
  valid_602276 = validateParameter(valid_602276, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminRespondToAuthChallenge"))
  if valid_602276 != nil:
    section.add "X-Amz-Target", valid_602276
  var valid_602277 = header.getOrDefault("X-Amz-Signature")
  valid_602277 = validateParameter(valid_602277, JString, required = false,
                                 default = nil)
  if valid_602277 != nil:
    section.add "X-Amz-Signature", valid_602277
  var valid_602278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602278 = validateParameter(valid_602278, JString, required = false,
                                 default = nil)
  if valid_602278 != nil:
    section.add "X-Amz-Content-Sha256", valid_602278
  var valid_602279 = header.getOrDefault("X-Amz-Date")
  valid_602279 = validateParameter(valid_602279, JString, required = false,
                                 default = nil)
  if valid_602279 != nil:
    section.add "X-Amz-Date", valid_602279
  var valid_602280 = header.getOrDefault("X-Amz-Credential")
  valid_602280 = validateParameter(valid_602280, JString, required = false,
                                 default = nil)
  if valid_602280 != nil:
    section.add "X-Amz-Credential", valid_602280
  var valid_602281 = header.getOrDefault("X-Amz-Security-Token")
  valid_602281 = validateParameter(valid_602281, JString, required = false,
                                 default = nil)
  if valid_602281 != nil:
    section.add "X-Amz-Security-Token", valid_602281
  var valid_602282 = header.getOrDefault("X-Amz-Algorithm")
  valid_602282 = validateParameter(valid_602282, JString, required = false,
                                 default = nil)
  if valid_602282 != nil:
    section.add "X-Amz-Algorithm", valid_602282
  var valid_602283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "X-Amz-SignedHeaders", valid_602283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602285: Call_AdminRespondToAuthChallenge_602273; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Responds to an authentication challenge, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_602285.validator(path, query, header, formData, body)
  let scheme = call_602285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602285.url(scheme.get, call_602285.host, call_602285.base,
                         call_602285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602285, url, valid)

proc call*(call_602286: Call_AdminRespondToAuthChallenge_602273; body: JsonNode): Recallable =
  ## adminRespondToAuthChallenge
  ## <p>Responds to an authentication challenge, as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_602287 = newJObject()
  if body != nil:
    body_602287 = body
  result = call_602286.call(nil, nil, nil, nil, body_602287)

var adminRespondToAuthChallenge* = Call_AdminRespondToAuthChallenge_602273(
    name: "adminRespondToAuthChallenge", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminRespondToAuthChallenge",
    validator: validate_AdminRespondToAuthChallenge_602274, base: "/",
    url: url_AdminRespondToAuthChallenge_602275,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminSetUserMFAPreference_602288 = ref object of OpenApiRestCall_601389
proc url_AdminSetUserMFAPreference_602290(protocol: Scheme; host: string;
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

proc validate_AdminSetUserMFAPreference_602289(path: JsonNode; query: JsonNode;
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
  var valid_602291 = header.getOrDefault("X-Amz-Target")
  valid_602291 = validateParameter(valid_602291, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminSetUserMFAPreference"))
  if valid_602291 != nil:
    section.add "X-Amz-Target", valid_602291
  var valid_602292 = header.getOrDefault("X-Amz-Signature")
  valid_602292 = validateParameter(valid_602292, JString, required = false,
                                 default = nil)
  if valid_602292 != nil:
    section.add "X-Amz-Signature", valid_602292
  var valid_602293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602293 = validateParameter(valid_602293, JString, required = false,
                                 default = nil)
  if valid_602293 != nil:
    section.add "X-Amz-Content-Sha256", valid_602293
  var valid_602294 = header.getOrDefault("X-Amz-Date")
  valid_602294 = validateParameter(valid_602294, JString, required = false,
                                 default = nil)
  if valid_602294 != nil:
    section.add "X-Amz-Date", valid_602294
  var valid_602295 = header.getOrDefault("X-Amz-Credential")
  valid_602295 = validateParameter(valid_602295, JString, required = false,
                                 default = nil)
  if valid_602295 != nil:
    section.add "X-Amz-Credential", valid_602295
  var valid_602296 = header.getOrDefault("X-Amz-Security-Token")
  valid_602296 = validateParameter(valid_602296, JString, required = false,
                                 default = nil)
  if valid_602296 != nil:
    section.add "X-Amz-Security-Token", valid_602296
  var valid_602297 = header.getOrDefault("X-Amz-Algorithm")
  valid_602297 = validateParameter(valid_602297, JString, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "X-Amz-Algorithm", valid_602297
  var valid_602298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602298 = validateParameter(valid_602298, JString, required = false,
                                 default = nil)
  if valid_602298 != nil:
    section.add "X-Amz-SignedHeaders", valid_602298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602300: Call_AdminSetUserMFAPreference_602288; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the user's multi-factor authentication (MFA) preference, including which MFA options are enabled and if any are preferred. Only one factor can be set as preferred. The preferred MFA factor will be used to authenticate a user if multiple factors are enabled. If multiple options are enabled and no preference is set, a challenge to choose an MFA option will be returned during sign in.
  ## 
  let valid = call_602300.validator(path, query, header, formData, body)
  let scheme = call_602300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602300.url(scheme.get, call_602300.host, call_602300.base,
                         call_602300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602300, url, valid)

proc call*(call_602301: Call_AdminSetUserMFAPreference_602288; body: JsonNode): Recallable =
  ## adminSetUserMFAPreference
  ## Sets the user's multi-factor authentication (MFA) preference, including which MFA options are enabled and if any are preferred. Only one factor can be set as preferred. The preferred MFA factor will be used to authenticate a user if multiple factors are enabled. If multiple options are enabled and no preference is set, a challenge to choose an MFA option will be returned during sign in.
  ##   body: JObject (required)
  var body_602302 = newJObject()
  if body != nil:
    body_602302 = body
  result = call_602301.call(nil, nil, nil, nil, body_602302)

var adminSetUserMFAPreference* = Call_AdminSetUserMFAPreference_602288(
    name: "adminSetUserMFAPreference", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminSetUserMFAPreference",
    validator: validate_AdminSetUserMFAPreference_602289, base: "/",
    url: url_AdminSetUserMFAPreference_602290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminSetUserPassword_602303 = ref object of OpenApiRestCall_601389
proc url_AdminSetUserPassword_602305(protocol: Scheme; host: string; base: string;
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

proc validate_AdminSetUserPassword_602304(path: JsonNode; query: JsonNode;
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
  var valid_602306 = header.getOrDefault("X-Amz-Target")
  valid_602306 = validateParameter(valid_602306, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminSetUserPassword"))
  if valid_602306 != nil:
    section.add "X-Amz-Target", valid_602306
  var valid_602307 = header.getOrDefault("X-Amz-Signature")
  valid_602307 = validateParameter(valid_602307, JString, required = false,
                                 default = nil)
  if valid_602307 != nil:
    section.add "X-Amz-Signature", valid_602307
  var valid_602308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602308 = validateParameter(valid_602308, JString, required = false,
                                 default = nil)
  if valid_602308 != nil:
    section.add "X-Amz-Content-Sha256", valid_602308
  var valid_602309 = header.getOrDefault("X-Amz-Date")
  valid_602309 = validateParameter(valid_602309, JString, required = false,
                                 default = nil)
  if valid_602309 != nil:
    section.add "X-Amz-Date", valid_602309
  var valid_602310 = header.getOrDefault("X-Amz-Credential")
  valid_602310 = validateParameter(valid_602310, JString, required = false,
                                 default = nil)
  if valid_602310 != nil:
    section.add "X-Amz-Credential", valid_602310
  var valid_602311 = header.getOrDefault("X-Amz-Security-Token")
  valid_602311 = validateParameter(valid_602311, JString, required = false,
                                 default = nil)
  if valid_602311 != nil:
    section.add "X-Amz-Security-Token", valid_602311
  var valid_602312 = header.getOrDefault("X-Amz-Algorithm")
  valid_602312 = validateParameter(valid_602312, JString, required = false,
                                 default = nil)
  if valid_602312 != nil:
    section.add "X-Amz-Algorithm", valid_602312
  var valid_602313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "X-Amz-SignedHeaders", valid_602313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602315: Call_AdminSetUserPassword_602303; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the specified user's password in a user pool as an administrator. Works on any user. </p> <p>The password can be temporary or permanent. If it is temporary, the user status will be placed into the <code>FORCE_CHANGE_PASSWORD</code> state. When the user next tries to sign in, the InitiateAuth/AdminInitiateAuth response will contain the <code>NEW_PASSWORD_REQUIRED</code> challenge. If the user does not sign in before it expires, the user will not be able to sign in and their password will need to be reset by an administrator. </p> <p>Once the user has set a new password, or the password is permanent, the user status will be set to <code>Confirmed</code>.</p>
  ## 
  let valid = call_602315.validator(path, query, header, formData, body)
  let scheme = call_602315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602315.url(scheme.get, call_602315.host, call_602315.base,
                         call_602315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602315, url, valid)

proc call*(call_602316: Call_AdminSetUserPassword_602303; body: JsonNode): Recallable =
  ## adminSetUserPassword
  ## <p>Sets the specified user's password in a user pool as an administrator. Works on any user. </p> <p>The password can be temporary or permanent. If it is temporary, the user status will be placed into the <code>FORCE_CHANGE_PASSWORD</code> state. When the user next tries to sign in, the InitiateAuth/AdminInitiateAuth response will contain the <code>NEW_PASSWORD_REQUIRED</code> challenge. If the user does not sign in before it expires, the user will not be able to sign in and their password will need to be reset by an administrator. </p> <p>Once the user has set a new password, or the password is permanent, the user status will be set to <code>Confirmed</code>.</p>
  ##   body: JObject (required)
  var body_602317 = newJObject()
  if body != nil:
    body_602317 = body
  result = call_602316.call(nil, nil, nil, nil, body_602317)

var adminSetUserPassword* = Call_AdminSetUserPassword_602303(
    name: "adminSetUserPassword", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminSetUserPassword",
    validator: validate_AdminSetUserPassword_602304, base: "/",
    url: url_AdminSetUserPassword_602305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminSetUserSettings_602318 = ref object of OpenApiRestCall_601389
proc url_AdminSetUserSettings_602320(protocol: Scheme; host: string; base: string;
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

proc validate_AdminSetUserSettings_602319(path: JsonNode; query: JsonNode;
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
  var valid_602321 = header.getOrDefault("X-Amz-Target")
  valid_602321 = validateParameter(valid_602321, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminSetUserSettings"))
  if valid_602321 != nil:
    section.add "X-Amz-Target", valid_602321
  var valid_602322 = header.getOrDefault("X-Amz-Signature")
  valid_602322 = validateParameter(valid_602322, JString, required = false,
                                 default = nil)
  if valid_602322 != nil:
    section.add "X-Amz-Signature", valid_602322
  var valid_602323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602323 = validateParameter(valid_602323, JString, required = false,
                                 default = nil)
  if valid_602323 != nil:
    section.add "X-Amz-Content-Sha256", valid_602323
  var valid_602324 = header.getOrDefault("X-Amz-Date")
  valid_602324 = validateParameter(valid_602324, JString, required = false,
                                 default = nil)
  if valid_602324 != nil:
    section.add "X-Amz-Date", valid_602324
  var valid_602325 = header.getOrDefault("X-Amz-Credential")
  valid_602325 = validateParameter(valid_602325, JString, required = false,
                                 default = nil)
  if valid_602325 != nil:
    section.add "X-Amz-Credential", valid_602325
  var valid_602326 = header.getOrDefault("X-Amz-Security-Token")
  valid_602326 = validateParameter(valid_602326, JString, required = false,
                                 default = nil)
  if valid_602326 != nil:
    section.add "X-Amz-Security-Token", valid_602326
  var valid_602327 = header.getOrDefault("X-Amz-Algorithm")
  valid_602327 = validateParameter(valid_602327, JString, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "X-Amz-Algorithm", valid_602327
  var valid_602328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602328 = validateParameter(valid_602328, JString, required = false,
                                 default = nil)
  if valid_602328 != nil:
    section.add "X-Amz-SignedHeaders", valid_602328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602330: Call_AdminSetUserSettings_602318; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <i>This action is no longer supported.</i> You can use it to configure only SMS MFA. You can't use it to configure TOTP software token MFA. To configure either type of MFA, use the <a>AdminSetUserMFAPreference</a> action instead.
  ## 
  let valid = call_602330.validator(path, query, header, formData, body)
  let scheme = call_602330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602330.url(scheme.get, call_602330.host, call_602330.base,
                         call_602330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602330, url, valid)

proc call*(call_602331: Call_AdminSetUserSettings_602318; body: JsonNode): Recallable =
  ## adminSetUserSettings
  ##  <i>This action is no longer supported.</i> You can use it to configure only SMS MFA. You can't use it to configure TOTP software token MFA. To configure either type of MFA, use the <a>AdminSetUserMFAPreference</a> action instead.
  ##   body: JObject (required)
  var body_602332 = newJObject()
  if body != nil:
    body_602332 = body
  result = call_602331.call(nil, nil, nil, nil, body_602332)

var adminSetUserSettings* = Call_AdminSetUserSettings_602318(
    name: "adminSetUserSettings", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminSetUserSettings",
    validator: validate_AdminSetUserSettings_602319, base: "/",
    url: url_AdminSetUserSettings_602320, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUpdateAuthEventFeedback_602333 = ref object of OpenApiRestCall_601389
proc url_AdminUpdateAuthEventFeedback_602335(protocol: Scheme; host: string;
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

proc validate_AdminUpdateAuthEventFeedback_602334(path: JsonNode; query: JsonNode;
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
  var valid_602336 = header.getOrDefault("X-Amz-Target")
  valid_602336 = validateParameter(valid_602336, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUpdateAuthEventFeedback"))
  if valid_602336 != nil:
    section.add "X-Amz-Target", valid_602336
  var valid_602337 = header.getOrDefault("X-Amz-Signature")
  valid_602337 = validateParameter(valid_602337, JString, required = false,
                                 default = nil)
  if valid_602337 != nil:
    section.add "X-Amz-Signature", valid_602337
  var valid_602338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602338 = validateParameter(valid_602338, JString, required = false,
                                 default = nil)
  if valid_602338 != nil:
    section.add "X-Amz-Content-Sha256", valid_602338
  var valid_602339 = header.getOrDefault("X-Amz-Date")
  valid_602339 = validateParameter(valid_602339, JString, required = false,
                                 default = nil)
  if valid_602339 != nil:
    section.add "X-Amz-Date", valid_602339
  var valid_602340 = header.getOrDefault("X-Amz-Credential")
  valid_602340 = validateParameter(valid_602340, JString, required = false,
                                 default = nil)
  if valid_602340 != nil:
    section.add "X-Amz-Credential", valid_602340
  var valid_602341 = header.getOrDefault("X-Amz-Security-Token")
  valid_602341 = validateParameter(valid_602341, JString, required = false,
                                 default = nil)
  if valid_602341 != nil:
    section.add "X-Amz-Security-Token", valid_602341
  var valid_602342 = header.getOrDefault("X-Amz-Algorithm")
  valid_602342 = validateParameter(valid_602342, JString, required = false,
                                 default = nil)
  if valid_602342 != nil:
    section.add "X-Amz-Algorithm", valid_602342
  var valid_602343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602343 = validateParameter(valid_602343, JString, required = false,
                                 default = nil)
  if valid_602343 != nil:
    section.add "X-Amz-SignedHeaders", valid_602343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602345: Call_AdminUpdateAuthEventFeedback_602333; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides feedback for an authentication event as to whether it was from a valid user. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ## 
  let valid = call_602345.validator(path, query, header, formData, body)
  let scheme = call_602345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602345.url(scheme.get, call_602345.host, call_602345.base,
                         call_602345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602345, url, valid)

proc call*(call_602346: Call_AdminUpdateAuthEventFeedback_602333; body: JsonNode): Recallable =
  ## adminUpdateAuthEventFeedback
  ## Provides feedback for an authentication event as to whether it was from a valid user. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ##   body: JObject (required)
  var body_602347 = newJObject()
  if body != nil:
    body_602347 = body
  result = call_602346.call(nil, nil, nil, nil, body_602347)

var adminUpdateAuthEventFeedback* = Call_AdminUpdateAuthEventFeedback_602333(
    name: "adminUpdateAuthEventFeedback", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUpdateAuthEventFeedback",
    validator: validate_AdminUpdateAuthEventFeedback_602334, base: "/",
    url: url_AdminUpdateAuthEventFeedback_602335,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUpdateDeviceStatus_602348 = ref object of OpenApiRestCall_601389
proc url_AdminUpdateDeviceStatus_602350(protocol: Scheme; host: string; base: string;
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

proc validate_AdminUpdateDeviceStatus_602349(path: JsonNode; query: JsonNode;
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
  var valid_602351 = header.getOrDefault("X-Amz-Target")
  valid_602351 = validateParameter(valid_602351, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUpdateDeviceStatus"))
  if valid_602351 != nil:
    section.add "X-Amz-Target", valid_602351
  var valid_602352 = header.getOrDefault("X-Amz-Signature")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "X-Amz-Signature", valid_602352
  var valid_602353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602353 = validateParameter(valid_602353, JString, required = false,
                                 default = nil)
  if valid_602353 != nil:
    section.add "X-Amz-Content-Sha256", valid_602353
  var valid_602354 = header.getOrDefault("X-Amz-Date")
  valid_602354 = validateParameter(valid_602354, JString, required = false,
                                 default = nil)
  if valid_602354 != nil:
    section.add "X-Amz-Date", valid_602354
  var valid_602355 = header.getOrDefault("X-Amz-Credential")
  valid_602355 = validateParameter(valid_602355, JString, required = false,
                                 default = nil)
  if valid_602355 != nil:
    section.add "X-Amz-Credential", valid_602355
  var valid_602356 = header.getOrDefault("X-Amz-Security-Token")
  valid_602356 = validateParameter(valid_602356, JString, required = false,
                                 default = nil)
  if valid_602356 != nil:
    section.add "X-Amz-Security-Token", valid_602356
  var valid_602357 = header.getOrDefault("X-Amz-Algorithm")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "X-Amz-Algorithm", valid_602357
  var valid_602358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602358 = validateParameter(valid_602358, JString, required = false,
                                 default = nil)
  if valid_602358 != nil:
    section.add "X-Amz-SignedHeaders", valid_602358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602360: Call_AdminUpdateDeviceStatus_602348; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the device status as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_602360.validator(path, query, header, formData, body)
  let scheme = call_602360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602360.url(scheme.get, call_602360.host, call_602360.base,
                         call_602360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602360, url, valid)

proc call*(call_602361: Call_AdminUpdateDeviceStatus_602348; body: JsonNode): Recallable =
  ## adminUpdateDeviceStatus
  ## <p>Updates the device status as an administrator.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_602362 = newJObject()
  if body != nil:
    body_602362 = body
  result = call_602361.call(nil, nil, nil, nil, body_602362)

var adminUpdateDeviceStatus* = Call_AdminUpdateDeviceStatus_602348(
    name: "adminUpdateDeviceStatus", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUpdateDeviceStatus",
    validator: validate_AdminUpdateDeviceStatus_602349, base: "/",
    url: url_AdminUpdateDeviceStatus_602350, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUpdateUserAttributes_602363 = ref object of OpenApiRestCall_601389
proc url_AdminUpdateUserAttributes_602365(protocol: Scheme; host: string;
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

proc validate_AdminUpdateUserAttributes_602364(path: JsonNode; query: JsonNode;
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
  var valid_602366 = header.getOrDefault("X-Amz-Target")
  valid_602366 = validateParameter(valid_602366, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUpdateUserAttributes"))
  if valid_602366 != nil:
    section.add "X-Amz-Target", valid_602366
  var valid_602367 = header.getOrDefault("X-Amz-Signature")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-Signature", valid_602367
  var valid_602368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-Content-Sha256", valid_602368
  var valid_602369 = header.getOrDefault("X-Amz-Date")
  valid_602369 = validateParameter(valid_602369, JString, required = false,
                                 default = nil)
  if valid_602369 != nil:
    section.add "X-Amz-Date", valid_602369
  var valid_602370 = header.getOrDefault("X-Amz-Credential")
  valid_602370 = validateParameter(valid_602370, JString, required = false,
                                 default = nil)
  if valid_602370 != nil:
    section.add "X-Amz-Credential", valid_602370
  var valid_602371 = header.getOrDefault("X-Amz-Security-Token")
  valid_602371 = validateParameter(valid_602371, JString, required = false,
                                 default = nil)
  if valid_602371 != nil:
    section.add "X-Amz-Security-Token", valid_602371
  var valid_602372 = header.getOrDefault("X-Amz-Algorithm")
  valid_602372 = validateParameter(valid_602372, JString, required = false,
                                 default = nil)
  if valid_602372 != nil:
    section.add "X-Amz-Algorithm", valid_602372
  var valid_602373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602373 = validateParameter(valid_602373, JString, required = false,
                                 default = nil)
  if valid_602373 != nil:
    section.add "X-Amz-SignedHeaders", valid_602373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602375: Call_AdminUpdateUserAttributes_602363; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified user's attributes, including developer attributes, as an administrator. Works on any user.</p> <p>For custom attributes, you must prepend the <code>custom:</code> prefix to the attribute name.</p> <p>In addition to updating user attributes, this API can also be used to mark phone and email as verified.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_602375.validator(path, query, header, formData, body)
  let scheme = call_602375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602375.url(scheme.get, call_602375.host, call_602375.base,
                         call_602375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602375, url, valid)

proc call*(call_602376: Call_AdminUpdateUserAttributes_602363; body: JsonNode): Recallable =
  ## adminUpdateUserAttributes
  ## <p>Updates the specified user's attributes, including developer attributes, as an administrator. Works on any user.</p> <p>For custom attributes, you must prepend the <code>custom:</code> prefix to the attribute name.</p> <p>In addition to updating user attributes, this API can also be used to mark phone and email as verified.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_602377 = newJObject()
  if body != nil:
    body_602377 = body
  result = call_602376.call(nil, nil, nil, nil, body_602377)

var adminUpdateUserAttributes* = Call_AdminUpdateUserAttributes_602363(
    name: "adminUpdateUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUpdateUserAttributes",
    validator: validate_AdminUpdateUserAttributes_602364, base: "/",
    url: url_AdminUpdateUserAttributes_602365,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AdminUserGlobalSignOut_602378 = ref object of OpenApiRestCall_601389
proc url_AdminUserGlobalSignOut_602380(protocol: Scheme; host: string; base: string;
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

proc validate_AdminUserGlobalSignOut_602379(path: JsonNode; query: JsonNode;
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
  var valid_602381 = header.getOrDefault("X-Amz-Target")
  valid_602381 = validateParameter(valid_602381, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AdminUserGlobalSignOut"))
  if valid_602381 != nil:
    section.add "X-Amz-Target", valid_602381
  var valid_602382 = header.getOrDefault("X-Amz-Signature")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "X-Amz-Signature", valid_602382
  var valid_602383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602383 = validateParameter(valid_602383, JString, required = false,
                                 default = nil)
  if valid_602383 != nil:
    section.add "X-Amz-Content-Sha256", valid_602383
  var valid_602384 = header.getOrDefault("X-Amz-Date")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "X-Amz-Date", valid_602384
  var valid_602385 = header.getOrDefault("X-Amz-Credential")
  valid_602385 = validateParameter(valid_602385, JString, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "X-Amz-Credential", valid_602385
  var valid_602386 = header.getOrDefault("X-Amz-Security-Token")
  valid_602386 = validateParameter(valid_602386, JString, required = false,
                                 default = nil)
  if valid_602386 != nil:
    section.add "X-Amz-Security-Token", valid_602386
  var valid_602387 = header.getOrDefault("X-Amz-Algorithm")
  valid_602387 = validateParameter(valid_602387, JString, required = false,
                                 default = nil)
  if valid_602387 != nil:
    section.add "X-Amz-Algorithm", valid_602387
  var valid_602388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602388 = validateParameter(valid_602388, JString, required = false,
                                 default = nil)
  if valid_602388 != nil:
    section.add "X-Amz-SignedHeaders", valid_602388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602390: Call_AdminUserGlobalSignOut_602378; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Signs out users from all devices, as an administrator. It also invalidates all refresh tokens issued to a user. The user's current access and Id tokens remain valid until their expiry. Access and Id tokens expire one hour after they are issued.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_602390.validator(path, query, header, formData, body)
  let scheme = call_602390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602390.url(scheme.get, call_602390.host, call_602390.base,
                         call_602390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602390, url, valid)

proc call*(call_602391: Call_AdminUserGlobalSignOut_602378; body: JsonNode): Recallable =
  ## adminUserGlobalSignOut
  ## <p>Signs out users from all devices, as an administrator. It also invalidates all refresh tokens issued to a user. The user's current access and Id tokens remain valid until their expiry. Access and Id tokens expire one hour after they are issued.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_602392 = newJObject()
  if body != nil:
    body_602392 = body
  result = call_602391.call(nil, nil, nil, nil, body_602392)

var adminUserGlobalSignOut* = Call_AdminUserGlobalSignOut_602378(
    name: "adminUserGlobalSignOut", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AdminUserGlobalSignOut",
    validator: validate_AdminUserGlobalSignOut_602379, base: "/",
    url: url_AdminUserGlobalSignOut_602380, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSoftwareToken_602393 = ref object of OpenApiRestCall_601389
proc url_AssociateSoftwareToken_602395(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateSoftwareToken_602394(path: JsonNode; query: JsonNode;
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
  var valid_602396 = header.getOrDefault("X-Amz-Target")
  valid_602396 = validateParameter(valid_602396, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.AssociateSoftwareToken"))
  if valid_602396 != nil:
    section.add "X-Amz-Target", valid_602396
  var valid_602397 = header.getOrDefault("X-Amz-Signature")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "X-Amz-Signature", valid_602397
  var valid_602398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602398 = validateParameter(valid_602398, JString, required = false,
                                 default = nil)
  if valid_602398 != nil:
    section.add "X-Amz-Content-Sha256", valid_602398
  var valid_602399 = header.getOrDefault("X-Amz-Date")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "X-Amz-Date", valid_602399
  var valid_602400 = header.getOrDefault("X-Amz-Credential")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "X-Amz-Credential", valid_602400
  var valid_602401 = header.getOrDefault("X-Amz-Security-Token")
  valid_602401 = validateParameter(valid_602401, JString, required = false,
                                 default = nil)
  if valid_602401 != nil:
    section.add "X-Amz-Security-Token", valid_602401
  var valid_602402 = header.getOrDefault("X-Amz-Algorithm")
  valid_602402 = validateParameter(valid_602402, JString, required = false,
                                 default = nil)
  if valid_602402 != nil:
    section.add "X-Amz-Algorithm", valid_602402
  var valid_602403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "X-Amz-SignedHeaders", valid_602403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602405: Call_AssociateSoftwareToken_602393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a unique generated shared secret key code for the user account. The request takes an access token or a session string, but not both.
  ## 
  let valid = call_602405.validator(path, query, header, formData, body)
  let scheme = call_602405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602405.url(scheme.get, call_602405.host, call_602405.base,
                         call_602405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602405, url, valid)

proc call*(call_602406: Call_AssociateSoftwareToken_602393; body: JsonNode): Recallable =
  ## associateSoftwareToken
  ## Returns a unique generated shared secret key code for the user account. The request takes an access token or a session string, but not both.
  ##   body: JObject (required)
  var body_602407 = newJObject()
  if body != nil:
    body_602407 = body
  result = call_602406.call(nil, nil, nil, nil, body_602407)

var associateSoftwareToken* = Call_AssociateSoftwareToken_602393(
    name: "associateSoftwareToken", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.AssociateSoftwareToken",
    validator: validate_AssociateSoftwareToken_602394, base: "/",
    url: url_AssociateSoftwareToken_602395, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ChangePassword_602408 = ref object of OpenApiRestCall_601389
proc url_ChangePassword_602410(protocol: Scheme; host: string; base: string;
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

proc validate_ChangePassword_602409(path: JsonNode; query: JsonNode;
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
  var valid_602411 = header.getOrDefault("X-Amz-Target")
  valid_602411 = validateParameter(valid_602411, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ChangePassword"))
  if valid_602411 != nil:
    section.add "X-Amz-Target", valid_602411
  var valid_602412 = header.getOrDefault("X-Amz-Signature")
  valid_602412 = validateParameter(valid_602412, JString, required = false,
                                 default = nil)
  if valid_602412 != nil:
    section.add "X-Amz-Signature", valid_602412
  var valid_602413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602413 = validateParameter(valid_602413, JString, required = false,
                                 default = nil)
  if valid_602413 != nil:
    section.add "X-Amz-Content-Sha256", valid_602413
  var valid_602414 = header.getOrDefault("X-Amz-Date")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "X-Amz-Date", valid_602414
  var valid_602415 = header.getOrDefault("X-Amz-Credential")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "X-Amz-Credential", valid_602415
  var valid_602416 = header.getOrDefault("X-Amz-Security-Token")
  valid_602416 = validateParameter(valid_602416, JString, required = false,
                                 default = nil)
  if valid_602416 != nil:
    section.add "X-Amz-Security-Token", valid_602416
  var valid_602417 = header.getOrDefault("X-Amz-Algorithm")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "X-Amz-Algorithm", valid_602417
  var valid_602418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602418 = validateParameter(valid_602418, JString, required = false,
                                 default = nil)
  if valid_602418 != nil:
    section.add "X-Amz-SignedHeaders", valid_602418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602420: Call_ChangePassword_602408; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the password for a specified user in a user pool.
  ## 
  let valid = call_602420.validator(path, query, header, formData, body)
  let scheme = call_602420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602420.url(scheme.get, call_602420.host, call_602420.base,
                         call_602420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602420, url, valid)

proc call*(call_602421: Call_ChangePassword_602408; body: JsonNode): Recallable =
  ## changePassword
  ## Changes the password for a specified user in a user pool.
  ##   body: JObject (required)
  var body_602422 = newJObject()
  if body != nil:
    body_602422 = body
  result = call_602421.call(nil, nil, nil, nil, body_602422)

var changePassword* = Call_ChangePassword_602408(name: "changePassword",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ChangePassword",
    validator: validate_ChangePassword_602409, base: "/", url: url_ChangePassword_602410,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmDevice_602423 = ref object of OpenApiRestCall_601389
proc url_ConfirmDevice_602425(protocol: Scheme; host: string; base: string;
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

proc validate_ConfirmDevice_602424(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602426 = header.getOrDefault("X-Amz-Target")
  valid_602426 = validateParameter(valid_602426, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ConfirmDevice"))
  if valid_602426 != nil:
    section.add "X-Amz-Target", valid_602426
  var valid_602427 = header.getOrDefault("X-Amz-Signature")
  valid_602427 = validateParameter(valid_602427, JString, required = false,
                                 default = nil)
  if valid_602427 != nil:
    section.add "X-Amz-Signature", valid_602427
  var valid_602428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602428 = validateParameter(valid_602428, JString, required = false,
                                 default = nil)
  if valid_602428 != nil:
    section.add "X-Amz-Content-Sha256", valid_602428
  var valid_602429 = header.getOrDefault("X-Amz-Date")
  valid_602429 = validateParameter(valid_602429, JString, required = false,
                                 default = nil)
  if valid_602429 != nil:
    section.add "X-Amz-Date", valid_602429
  var valid_602430 = header.getOrDefault("X-Amz-Credential")
  valid_602430 = validateParameter(valid_602430, JString, required = false,
                                 default = nil)
  if valid_602430 != nil:
    section.add "X-Amz-Credential", valid_602430
  var valid_602431 = header.getOrDefault("X-Amz-Security-Token")
  valid_602431 = validateParameter(valid_602431, JString, required = false,
                                 default = nil)
  if valid_602431 != nil:
    section.add "X-Amz-Security-Token", valid_602431
  var valid_602432 = header.getOrDefault("X-Amz-Algorithm")
  valid_602432 = validateParameter(valid_602432, JString, required = false,
                                 default = nil)
  if valid_602432 != nil:
    section.add "X-Amz-Algorithm", valid_602432
  var valid_602433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602433 = validateParameter(valid_602433, JString, required = false,
                                 default = nil)
  if valid_602433 != nil:
    section.add "X-Amz-SignedHeaders", valid_602433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602435: Call_ConfirmDevice_602423; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Confirms tracking of the device. This API call is the call that begins device tracking.
  ## 
  let valid = call_602435.validator(path, query, header, formData, body)
  let scheme = call_602435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602435.url(scheme.get, call_602435.host, call_602435.base,
                         call_602435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602435, url, valid)

proc call*(call_602436: Call_ConfirmDevice_602423; body: JsonNode): Recallable =
  ## confirmDevice
  ## Confirms tracking of the device. This API call is the call that begins device tracking.
  ##   body: JObject (required)
  var body_602437 = newJObject()
  if body != nil:
    body_602437 = body
  result = call_602436.call(nil, nil, nil, nil, body_602437)

var confirmDevice* = Call_ConfirmDevice_602423(name: "confirmDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ConfirmDevice",
    validator: validate_ConfirmDevice_602424, base: "/", url: url_ConfirmDevice_602425,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmForgotPassword_602438 = ref object of OpenApiRestCall_601389
proc url_ConfirmForgotPassword_602440(protocol: Scheme; host: string; base: string;
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

proc validate_ConfirmForgotPassword_602439(path: JsonNode; query: JsonNode;
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
  var valid_602441 = header.getOrDefault("X-Amz-Target")
  valid_602441 = validateParameter(valid_602441, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ConfirmForgotPassword"))
  if valid_602441 != nil:
    section.add "X-Amz-Target", valid_602441
  var valid_602442 = header.getOrDefault("X-Amz-Signature")
  valid_602442 = validateParameter(valid_602442, JString, required = false,
                                 default = nil)
  if valid_602442 != nil:
    section.add "X-Amz-Signature", valid_602442
  var valid_602443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602443 = validateParameter(valid_602443, JString, required = false,
                                 default = nil)
  if valid_602443 != nil:
    section.add "X-Amz-Content-Sha256", valid_602443
  var valid_602444 = header.getOrDefault("X-Amz-Date")
  valid_602444 = validateParameter(valid_602444, JString, required = false,
                                 default = nil)
  if valid_602444 != nil:
    section.add "X-Amz-Date", valid_602444
  var valid_602445 = header.getOrDefault("X-Amz-Credential")
  valid_602445 = validateParameter(valid_602445, JString, required = false,
                                 default = nil)
  if valid_602445 != nil:
    section.add "X-Amz-Credential", valid_602445
  var valid_602446 = header.getOrDefault("X-Amz-Security-Token")
  valid_602446 = validateParameter(valid_602446, JString, required = false,
                                 default = nil)
  if valid_602446 != nil:
    section.add "X-Amz-Security-Token", valid_602446
  var valid_602447 = header.getOrDefault("X-Amz-Algorithm")
  valid_602447 = validateParameter(valid_602447, JString, required = false,
                                 default = nil)
  if valid_602447 != nil:
    section.add "X-Amz-Algorithm", valid_602447
  var valid_602448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602448 = validateParameter(valid_602448, JString, required = false,
                                 default = nil)
  if valid_602448 != nil:
    section.add "X-Amz-SignedHeaders", valid_602448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602450: Call_ConfirmForgotPassword_602438; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a user to enter a confirmation code to reset a forgotten password.
  ## 
  let valid = call_602450.validator(path, query, header, formData, body)
  let scheme = call_602450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602450.url(scheme.get, call_602450.host, call_602450.base,
                         call_602450.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602450, url, valid)

proc call*(call_602451: Call_ConfirmForgotPassword_602438; body: JsonNode): Recallable =
  ## confirmForgotPassword
  ## Allows a user to enter a confirmation code to reset a forgotten password.
  ##   body: JObject (required)
  var body_602452 = newJObject()
  if body != nil:
    body_602452 = body
  result = call_602451.call(nil, nil, nil, nil, body_602452)

var confirmForgotPassword* = Call_ConfirmForgotPassword_602438(
    name: "confirmForgotPassword", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ConfirmForgotPassword",
    validator: validate_ConfirmForgotPassword_602439, base: "/",
    url: url_ConfirmForgotPassword_602440, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmSignUp_602453 = ref object of OpenApiRestCall_601389
proc url_ConfirmSignUp_602455(protocol: Scheme; host: string; base: string;
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

proc validate_ConfirmSignUp_602454(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602456 = header.getOrDefault("X-Amz-Target")
  valid_602456 = validateParameter(valid_602456, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ConfirmSignUp"))
  if valid_602456 != nil:
    section.add "X-Amz-Target", valid_602456
  var valid_602457 = header.getOrDefault("X-Amz-Signature")
  valid_602457 = validateParameter(valid_602457, JString, required = false,
                                 default = nil)
  if valid_602457 != nil:
    section.add "X-Amz-Signature", valid_602457
  var valid_602458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602458 = validateParameter(valid_602458, JString, required = false,
                                 default = nil)
  if valid_602458 != nil:
    section.add "X-Amz-Content-Sha256", valid_602458
  var valid_602459 = header.getOrDefault("X-Amz-Date")
  valid_602459 = validateParameter(valid_602459, JString, required = false,
                                 default = nil)
  if valid_602459 != nil:
    section.add "X-Amz-Date", valid_602459
  var valid_602460 = header.getOrDefault("X-Amz-Credential")
  valid_602460 = validateParameter(valid_602460, JString, required = false,
                                 default = nil)
  if valid_602460 != nil:
    section.add "X-Amz-Credential", valid_602460
  var valid_602461 = header.getOrDefault("X-Amz-Security-Token")
  valid_602461 = validateParameter(valid_602461, JString, required = false,
                                 default = nil)
  if valid_602461 != nil:
    section.add "X-Amz-Security-Token", valid_602461
  var valid_602462 = header.getOrDefault("X-Amz-Algorithm")
  valid_602462 = validateParameter(valid_602462, JString, required = false,
                                 default = nil)
  if valid_602462 != nil:
    section.add "X-Amz-Algorithm", valid_602462
  var valid_602463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602463 = validateParameter(valid_602463, JString, required = false,
                                 default = nil)
  if valid_602463 != nil:
    section.add "X-Amz-SignedHeaders", valid_602463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602465: Call_ConfirmSignUp_602453; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Confirms registration of a user and handles the existing alias from a previous user.
  ## 
  let valid = call_602465.validator(path, query, header, formData, body)
  let scheme = call_602465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602465.url(scheme.get, call_602465.host, call_602465.base,
                         call_602465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602465, url, valid)

proc call*(call_602466: Call_ConfirmSignUp_602453; body: JsonNode): Recallable =
  ## confirmSignUp
  ## Confirms registration of a user and handles the existing alias from a previous user.
  ##   body: JObject (required)
  var body_602467 = newJObject()
  if body != nil:
    body_602467 = body
  result = call_602466.call(nil, nil, nil, nil, body_602467)

var confirmSignUp* = Call_ConfirmSignUp_602453(name: "confirmSignUp",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ConfirmSignUp",
    validator: validate_ConfirmSignUp_602454, base: "/", url: url_ConfirmSignUp_602455,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_602468 = ref object of OpenApiRestCall_601389
proc url_CreateGroup_602470(protocol: Scheme; host: string; base: string;
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

proc validate_CreateGroup_602469(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602471 = header.getOrDefault("X-Amz-Target")
  valid_602471 = validateParameter(valid_602471, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateGroup"))
  if valid_602471 != nil:
    section.add "X-Amz-Target", valid_602471
  var valid_602472 = header.getOrDefault("X-Amz-Signature")
  valid_602472 = validateParameter(valid_602472, JString, required = false,
                                 default = nil)
  if valid_602472 != nil:
    section.add "X-Amz-Signature", valid_602472
  var valid_602473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602473 = validateParameter(valid_602473, JString, required = false,
                                 default = nil)
  if valid_602473 != nil:
    section.add "X-Amz-Content-Sha256", valid_602473
  var valid_602474 = header.getOrDefault("X-Amz-Date")
  valid_602474 = validateParameter(valid_602474, JString, required = false,
                                 default = nil)
  if valid_602474 != nil:
    section.add "X-Amz-Date", valid_602474
  var valid_602475 = header.getOrDefault("X-Amz-Credential")
  valid_602475 = validateParameter(valid_602475, JString, required = false,
                                 default = nil)
  if valid_602475 != nil:
    section.add "X-Amz-Credential", valid_602475
  var valid_602476 = header.getOrDefault("X-Amz-Security-Token")
  valid_602476 = validateParameter(valid_602476, JString, required = false,
                                 default = nil)
  if valid_602476 != nil:
    section.add "X-Amz-Security-Token", valid_602476
  var valid_602477 = header.getOrDefault("X-Amz-Algorithm")
  valid_602477 = validateParameter(valid_602477, JString, required = false,
                                 default = nil)
  if valid_602477 != nil:
    section.add "X-Amz-Algorithm", valid_602477
  var valid_602478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602478 = validateParameter(valid_602478, JString, required = false,
                                 default = nil)
  if valid_602478 != nil:
    section.add "X-Amz-SignedHeaders", valid_602478
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602480: Call_CreateGroup_602468; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new group in the specified user pool.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_602480.validator(path, query, header, formData, body)
  let scheme = call_602480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602480.url(scheme.get, call_602480.host, call_602480.base,
                         call_602480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602480, url, valid)

proc call*(call_602481: Call_CreateGroup_602468; body: JsonNode): Recallable =
  ## createGroup
  ## <p>Creates a new group in the specified user pool.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_602482 = newJObject()
  if body != nil:
    body_602482 = body
  result = call_602481.call(nil, nil, nil, nil, body_602482)

var createGroup* = Call_CreateGroup_602468(name: "createGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateGroup",
                                        validator: validate_CreateGroup_602469,
                                        base: "/", url: url_CreateGroup_602470,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIdentityProvider_602483 = ref object of OpenApiRestCall_601389
proc url_CreateIdentityProvider_602485(protocol: Scheme; host: string; base: string;
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

proc validate_CreateIdentityProvider_602484(path: JsonNode; query: JsonNode;
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
  var valid_602486 = header.getOrDefault("X-Amz-Target")
  valid_602486 = validateParameter(valid_602486, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateIdentityProvider"))
  if valid_602486 != nil:
    section.add "X-Amz-Target", valid_602486
  var valid_602487 = header.getOrDefault("X-Amz-Signature")
  valid_602487 = validateParameter(valid_602487, JString, required = false,
                                 default = nil)
  if valid_602487 != nil:
    section.add "X-Amz-Signature", valid_602487
  var valid_602488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602488 = validateParameter(valid_602488, JString, required = false,
                                 default = nil)
  if valid_602488 != nil:
    section.add "X-Amz-Content-Sha256", valid_602488
  var valid_602489 = header.getOrDefault("X-Amz-Date")
  valid_602489 = validateParameter(valid_602489, JString, required = false,
                                 default = nil)
  if valid_602489 != nil:
    section.add "X-Amz-Date", valid_602489
  var valid_602490 = header.getOrDefault("X-Amz-Credential")
  valid_602490 = validateParameter(valid_602490, JString, required = false,
                                 default = nil)
  if valid_602490 != nil:
    section.add "X-Amz-Credential", valid_602490
  var valid_602491 = header.getOrDefault("X-Amz-Security-Token")
  valid_602491 = validateParameter(valid_602491, JString, required = false,
                                 default = nil)
  if valid_602491 != nil:
    section.add "X-Amz-Security-Token", valid_602491
  var valid_602492 = header.getOrDefault("X-Amz-Algorithm")
  valid_602492 = validateParameter(valid_602492, JString, required = false,
                                 default = nil)
  if valid_602492 != nil:
    section.add "X-Amz-Algorithm", valid_602492
  var valid_602493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602493 = validateParameter(valid_602493, JString, required = false,
                                 default = nil)
  if valid_602493 != nil:
    section.add "X-Amz-SignedHeaders", valid_602493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602495: Call_CreateIdentityProvider_602483; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an identity provider for a user pool.
  ## 
  let valid = call_602495.validator(path, query, header, formData, body)
  let scheme = call_602495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602495.url(scheme.get, call_602495.host, call_602495.base,
                         call_602495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602495, url, valid)

proc call*(call_602496: Call_CreateIdentityProvider_602483; body: JsonNode): Recallable =
  ## createIdentityProvider
  ## Creates an identity provider for a user pool.
  ##   body: JObject (required)
  var body_602497 = newJObject()
  if body != nil:
    body_602497 = body
  result = call_602496.call(nil, nil, nil, nil, body_602497)

var createIdentityProvider* = Call_CreateIdentityProvider_602483(
    name: "createIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateIdentityProvider",
    validator: validate_CreateIdentityProvider_602484, base: "/",
    url: url_CreateIdentityProvider_602485, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceServer_602498 = ref object of OpenApiRestCall_601389
proc url_CreateResourceServer_602500(protocol: Scheme; host: string; base: string;
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

proc validate_CreateResourceServer_602499(path: JsonNode; query: JsonNode;
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
  var valid_602501 = header.getOrDefault("X-Amz-Target")
  valid_602501 = validateParameter(valid_602501, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateResourceServer"))
  if valid_602501 != nil:
    section.add "X-Amz-Target", valid_602501
  var valid_602502 = header.getOrDefault("X-Amz-Signature")
  valid_602502 = validateParameter(valid_602502, JString, required = false,
                                 default = nil)
  if valid_602502 != nil:
    section.add "X-Amz-Signature", valid_602502
  var valid_602503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602503 = validateParameter(valid_602503, JString, required = false,
                                 default = nil)
  if valid_602503 != nil:
    section.add "X-Amz-Content-Sha256", valid_602503
  var valid_602504 = header.getOrDefault("X-Amz-Date")
  valid_602504 = validateParameter(valid_602504, JString, required = false,
                                 default = nil)
  if valid_602504 != nil:
    section.add "X-Amz-Date", valid_602504
  var valid_602505 = header.getOrDefault("X-Amz-Credential")
  valid_602505 = validateParameter(valid_602505, JString, required = false,
                                 default = nil)
  if valid_602505 != nil:
    section.add "X-Amz-Credential", valid_602505
  var valid_602506 = header.getOrDefault("X-Amz-Security-Token")
  valid_602506 = validateParameter(valid_602506, JString, required = false,
                                 default = nil)
  if valid_602506 != nil:
    section.add "X-Amz-Security-Token", valid_602506
  var valid_602507 = header.getOrDefault("X-Amz-Algorithm")
  valid_602507 = validateParameter(valid_602507, JString, required = false,
                                 default = nil)
  if valid_602507 != nil:
    section.add "X-Amz-Algorithm", valid_602507
  var valid_602508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602508 = validateParameter(valid_602508, JString, required = false,
                                 default = nil)
  if valid_602508 != nil:
    section.add "X-Amz-SignedHeaders", valid_602508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602510: Call_CreateResourceServer_602498; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new OAuth2.0 resource server and defines custom scopes in it.
  ## 
  let valid = call_602510.validator(path, query, header, formData, body)
  let scheme = call_602510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602510.url(scheme.get, call_602510.host, call_602510.base,
                         call_602510.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602510, url, valid)

proc call*(call_602511: Call_CreateResourceServer_602498; body: JsonNode): Recallable =
  ## createResourceServer
  ## Creates a new OAuth2.0 resource server and defines custom scopes in it.
  ##   body: JObject (required)
  var body_602512 = newJObject()
  if body != nil:
    body_602512 = body
  result = call_602511.call(nil, nil, nil, nil, body_602512)

var createResourceServer* = Call_CreateResourceServer_602498(
    name: "createResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateResourceServer",
    validator: validate_CreateResourceServer_602499, base: "/",
    url: url_CreateResourceServer_602500, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserImportJob_602513 = ref object of OpenApiRestCall_601389
proc url_CreateUserImportJob_602515(protocol: Scheme; host: string; base: string;
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

proc validate_CreateUserImportJob_602514(path: JsonNode; query: JsonNode;
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
  var valid_602516 = header.getOrDefault("X-Amz-Target")
  valid_602516 = validateParameter(valid_602516, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserImportJob"))
  if valid_602516 != nil:
    section.add "X-Amz-Target", valid_602516
  var valid_602517 = header.getOrDefault("X-Amz-Signature")
  valid_602517 = validateParameter(valid_602517, JString, required = false,
                                 default = nil)
  if valid_602517 != nil:
    section.add "X-Amz-Signature", valid_602517
  var valid_602518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602518 = validateParameter(valid_602518, JString, required = false,
                                 default = nil)
  if valid_602518 != nil:
    section.add "X-Amz-Content-Sha256", valid_602518
  var valid_602519 = header.getOrDefault("X-Amz-Date")
  valid_602519 = validateParameter(valid_602519, JString, required = false,
                                 default = nil)
  if valid_602519 != nil:
    section.add "X-Amz-Date", valid_602519
  var valid_602520 = header.getOrDefault("X-Amz-Credential")
  valid_602520 = validateParameter(valid_602520, JString, required = false,
                                 default = nil)
  if valid_602520 != nil:
    section.add "X-Amz-Credential", valid_602520
  var valid_602521 = header.getOrDefault("X-Amz-Security-Token")
  valid_602521 = validateParameter(valid_602521, JString, required = false,
                                 default = nil)
  if valid_602521 != nil:
    section.add "X-Amz-Security-Token", valid_602521
  var valid_602522 = header.getOrDefault("X-Amz-Algorithm")
  valid_602522 = validateParameter(valid_602522, JString, required = false,
                                 default = nil)
  if valid_602522 != nil:
    section.add "X-Amz-Algorithm", valid_602522
  var valid_602523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602523 = validateParameter(valid_602523, JString, required = false,
                                 default = nil)
  if valid_602523 != nil:
    section.add "X-Amz-SignedHeaders", valid_602523
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602525: Call_CreateUserImportJob_602513; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates the user import job.
  ## 
  let valid = call_602525.validator(path, query, header, formData, body)
  let scheme = call_602525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602525.url(scheme.get, call_602525.host, call_602525.base,
                         call_602525.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602525, url, valid)

proc call*(call_602526: Call_CreateUserImportJob_602513; body: JsonNode): Recallable =
  ## createUserImportJob
  ## Creates the user import job.
  ##   body: JObject (required)
  var body_602527 = newJObject()
  if body != nil:
    body_602527 = body
  result = call_602526.call(nil, nil, nil, nil, body_602527)

var createUserImportJob* = Call_CreateUserImportJob_602513(
    name: "createUserImportJob", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserImportJob",
    validator: validate_CreateUserImportJob_602514, base: "/",
    url: url_CreateUserImportJob_602515, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserPool_602528 = ref object of OpenApiRestCall_601389
proc url_CreateUserPool_602530(protocol: Scheme; host: string; base: string;
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

proc validate_CreateUserPool_602529(path: JsonNode; query: JsonNode;
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
  var valid_602531 = header.getOrDefault("X-Amz-Target")
  valid_602531 = validateParameter(valid_602531, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserPool"))
  if valid_602531 != nil:
    section.add "X-Amz-Target", valid_602531
  var valid_602532 = header.getOrDefault("X-Amz-Signature")
  valid_602532 = validateParameter(valid_602532, JString, required = false,
                                 default = nil)
  if valid_602532 != nil:
    section.add "X-Amz-Signature", valid_602532
  var valid_602533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602533 = validateParameter(valid_602533, JString, required = false,
                                 default = nil)
  if valid_602533 != nil:
    section.add "X-Amz-Content-Sha256", valid_602533
  var valid_602534 = header.getOrDefault("X-Amz-Date")
  valid_602534 = validateParameter(valid_602534, JString, required = false,
                                 default = nil)
  if valid_602534 != nil:
    section.add "X-Amz-Date", valid_602534
  var valid_602535 = header.getOrDefault("X-Amz-Credential")
  valid_602535 = validateParameter(valid_602535, JString, required = false,
                                 default = nil)
  if valid_602535 != nil:
    section.add "X-Amz-Credential", valid_602535
  var valid_602536 = header.getOrDefault("X-Amz-Security-Token")
  valid_602536 = validateParameter(valid_602536, JString, required = false,
                                 default = nil)
  if valid_602536 != nil:
    section.add "X-Amz-Security-Token", valid_602536
  var valid_602537 = header.getOrDefault("X-Amz-Algorithm")
  valid_602537 = validateParameter(valid_602537, JString, required = false,
                                 default = nil)
  if valid_602537 != nil:
    section.add "X-Amz-Algorithm", valid_602537
  var valid_602538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602538 = validateParameter(valid_602538, JString, required = false,
                                 default = nil)
  if valid_602538 != nil:
    section.add "X-Amz-SignedHeaders", valid_602538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602540: Call_CreateUserPool_602528; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon Cognito user pool and sets the password policy for the pool.
  ## 
  let valid = call_602540.validator(path, query, header, formData, body)
  let scheme = call_602540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602540.url(scheme.get, call_602540.host, call_602540.base,
                         call_602540.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602540, url, valid)

proc call*(call_602541: Call_CreateUserPool_602528; body: JsonNode): Recallable =
  ## createUserPool
  ## Creates a new Amazon Cognito user pool and sets the password policy for the pool.
  ##   body: JObject (required)
  var body_602542 = newJObject()
  if body != nil:
    body_602542 = body
  result = call_602541.call(nil, nil, nil, nil, body_602542)

var createUserPool* = Call_CreateUserPool_602528(name: "createUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserPool",
    validator: validate_CreateUserPool_602529, base: "/", url: url_CreateUserPool_602530,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserPoolClient_602543 = ref object of OpenApiRestCall_601389
proc url_CreateUserPoolClient_602545(protocol: Scheme; host: string; base: string;
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

proc validate_CreateUserPoolClient_602544(path: JsonNode; query: JsonNode;
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
  var valid_602546 = header.getOrDefault("X-Amz-Target")
  valid_602546 = validateParameter(valid_602546, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserPoolClient"))
  if valid_602546 != nil:
    section.add "X-Amz-Target", valid_602546
  var valid_602547 = header.getOrDefault("X-Amz-Signature")
  valid_602547 = validateParameter(valid_602547, JString, required = false,
                                 default = nil)
  if valid_602547 != nil:
    section.add "X-Amz-Signature", valid_602547
  var valid_602548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602548 = validateParameter(valid_602548, JString, required = false,
                                 default = nil)
  if valid_602548 != nil:
    section.add "X-Amz-Content-Sha256", valid_602548
  var valid_602549 = header.getOrDefault("X-Amz-Date")
  valid_602549 = validateParameter(valid_602549, JString, required = false,
                                 default = nil)
  if valid_602549 != nil:
    section.add "X-Amz-Date", valid_602549
  var valid_602550 = header.getOrDefault("X-Amz-Credential")
  valid_602550 = validateParameter(valid_602550, JString, required = false,
                                 default = nil)
  if valid_602550 != nil:
    section.add "X-Amz-Credential", valid_602550
  var valid_602551 = header.getOrDefault("X-Amz-Security-Token")
  valid_602551 = validateParameter(valid_602551, JString, required = false,
                                 default = nil)
  if valid_602551 != nil:
    section.add "X-Amz-Security-Token", valid_602551
  var valid_602552 = header.getOrDefault("X-Amz-Algorithm")
  valid_602552 = validateParameter(valid_602552, JString, required = false,
                                 default = nil)
  if valid_602552 != nil:
    section.add "X-Amz-Algorithm", valid_602552
  var valid_602553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602553 = validateParameter(valid_602553, JString, required = false,
                                 default = nil)
  if valid_602553 != nil:
    section.add "X-Amz-SignedHeaders", valid_602553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602555: Call_CreateUserPoolClient_602543; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates the user pool client.
  ## 
  let valid = call_602555.validator(path, query, header, formData, body)
  let scheme = call_602555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602555.url(scheme.get, call_602555.host, call_602555.base,
                         call_602555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602555, url, valid)

proc call*(call_602556: Call_CreateUserPoolClient_602543; body: JsonNode): Recallable =
  ## createUserPoolClient
  ## Creates the user pool client.
  ##   body: JObject (required)
  var body_602557 = newJObject()
  if body != nil:
    body_602557 = body
  result = call_602556.call(nil, nil, nil, nil, body_602557)

var createUserPoolClient* = Call_CreateUserPoolClient_602543(
    name: "createUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserPoolClient",
    validator: validate_CreateUserPoolClient_602544, base: "/",
    url: url_CreateUserPoolClient_602545, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserPoolDomain_602558 = ref object of OpenApiRestCall_601389
proc url_CreateUserPoolDomain_602560(protocol: Scheme; host: string; base: string;
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

proc validate_CreateUserPoolDomain_602559(path: JsonNode; query: JsonNode;
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
  var valid_602561 = header.getOrDefault("X-Amz-Target")
  valid_602561 = validateParameter(valid_602561, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.CreateUserPoolDomain"))
  if valid_602561 != nil:
    section.add "X-Amz-Target", valid_602561
  var valid_602562 = header.getOrDefault("X-Amz-Signature")
  valid_602562 = validateParameter(valid_602562, JString, required = false,
                                 default = nil)
  if valid_602562 != nil:
    section.add "X-Amz-Signature", valid_602562
  var valid_602563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602563 = validateParameter(valid_602563, JString, required = false,
                                 default = nil)
  if valid_602563 != nil:
    section.add "X-Amz-Content-Sha256", valid_602563
  var valid_602564 = header.getOrDefault("X-Amz-Date")
  valid_602564 = validateParameter(valid_602564, JString, required = false,
                                 default = nil)
  if valid_602564 != nil:
    section.add "X-Amz-Date", valid_602564
  var valid_602565 = header.getOrDefault("X-Amz-Credential")
  valid_602565 = validateParameter(valid_602565, JString, required = false,
                                 default = nil)
  if valid_602565 != nil:
    section.add "X-Amz-Credential", valid_602565
  var valid_602566 = header.getOrDefault("X-Amz-Security-Token")
  valid_602566 = validateParameter(valid_602566, JString, required = false,
                                 default = nil)
  if valid_602566 != nil:
    section.add "X-Amz-Security-Token", valid_602566
  var valid_602567 = header.getOrDefault("X-Amz-Algorithm")
  valid_602567 = validateParameter(valid_602567, JString, required = false,
                                 default = nil)
  if valid_602567 != nil:
    section.add "X-Amz-Algorithm", valid_602567
  var valid_602568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602568 = validateParameter(valid_602568, JString, required = false,
                                 default = nil)
  if valid_602568 != nil:
    section.add "X-Amz-SignedHeaders", valid_602568
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602570: Call_CreateUserPoolDomain_602558; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new domain for a user pool.
  ## 
  let valid = call_602570.validator(path, query, header, formData, body)
  let scheme = call_602570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602570.url(scheme.get, call_602570.host, call_602570.base,
                         call_602570.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602570, url, valid)

proc call*(call_602571: Call_CreateUserPoolDomain_602558; body: JsonNode): Recallable =
  ## createUserPoolDomain
  ## Creates a new domain for a user pool.
  ##   body: JObject (required)
  var body_602572 = newJObject()
  if body != nil:
    body_602572 = body
  result = call_602571.call(nil, nil, nil, nil, body_602572)

var createUserPoolDomain* = Call_CreateUserPoolDomain_602558(
    name: "createUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.CreateUserPoolDomain",
    validator: validate_CreateUserPoolDomain_602559, base: "/",
    url: url_CreateUserPoolDomain_602560, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_602573 = ref object of OpenApiRestCall_601389
proc url_DeleteGroup_602575(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGroup_602574(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602576 = header.getOrDefault("X-Amz-Target")
  valid_602576 = validateParameter(valid_602576, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteGroup"))
  if valid_602576 != nil:
    section.add "X-Amz-Target", valid_602576
  var valid_602577 = header.getOrDefault("X-Amz-Signature")
  valid_602577 = validateParameter(valid_602577, JString, required = false,
                                 default = nil)
  if valid_602577 != nil:
    section.add "X-Amz-Signature", valid_602577
  var valid_602578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602578 = validateParameter(valid_602578, JString, required = false,
                                 default = nil)
  if valid_602578 != nil:
    section.add "X-Amz-Content-Sha256", valid_602578
  var valid_602579 = header.getOrDefault("X-Amz-Date")
  valid_602579 = validateParameter(valid_602579, JString, required = false,
                                 default = nil)
  if valid_602579 != nil:
    section.add "X-Amz-Date", valid_602579
  var valid_602580 = header.getOrDefault("X-Amz-Credential")
  valid_602580 = validateParameter(valid_602580, JString, required = false,
                                 default = nil)
  if valid_602580 != nil:
    section.add "X-Amz-Credential", valid_602580
  var valid_602581 = header.getOrDefault("X-Amz-Security-Token")
  valid_602581 = validateParameter(valid_602581, JString, required = false,
                                 default = nil)
  if valid_602581 != nil:
    section.add "X-Amz-Security-Token", valid_602581
  var valid_602582 = header.getOrDefault("X-Amz-Algorithm")
  valid_602582 = validateParameter(valid_602582, JString, required = false,
                                 default = nil)
  if valid_602582 != nil:
    section.add "X-Amz-Algorithm", valid_602582
  var valid_602583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602583 = validateParameter(valid_602583, JString, required = false,
                                 default = nil)
  if valid_602583 != nil:
    section.add "X-Amz-SignedHeaders", valid_602583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602585: Call_DeleteGroup_602573; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a group. Currently only groups with no members can be deleted.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_602585.validator(path, query, header, formData, body)
  let scheme = call_602585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602585.url(scheme.get, call_602585.host, call_602585.base,
                         call_602585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602585, url, valid)

proc call*(call_602586: Call_DeleteGroup_602573; body: JsonNode): Recallable =
  ## deleteGroup
  ## <p>Deletes a group. Currently only groups with no members can be deleted.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_602587 = newJObject()
  if body != nil:
    body_602587 = body
  result = call_602586.call(nil, nil, nil, nil, body_602587)

var deleteGroup* = Call_DeleteGroup_602573(name: "deleteGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteGroup",
                                        validator: validate_DeleteGroup_602574,
                                        base: "/", url: url_DeleteGroup_602575,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIdentityProvider_602588 = ref object of OpenApiRestCall_601389
proc url_DeleteIdentityProvider_602590(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteIdentityProvider_602589(path: JsonNode; query: JsonNode;
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
  var valid_602591 = header.getOrDefault("X-Amz-Target")
  valid_602591 = validateParameter(valid_602591, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteIdentityProvider"))
  if valid_602591 != nil:
    section.add "X-Amz-Target", valid_602591
  var valid_602592 = header.getOrDefault("X-Amz-Signature")
  valid_602592 = validateParameter(valid_602592, JString, required = false,
                                 default = nil)
  if valid_602592 != nil:
    section.add "X-Amz-Signature", valid_602592
  var valid_602593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602593 = validateParameter(valid_602593, JString, required = false,
                                 default = nil)
  if valid_602593 != nil:
    section.add "X-Amz-Content-Sha256", valid_602593
  var valid_602594 = header.getOrDefault("X-Amz-Date")
  valid_602594 = validateParameter(valid_602594, JString, required = false,
                                 default = nil)
  if valid_602594 != nil:
    section.add "X-Amz-Date", valid_602594
  var valid_602595 = header.getOrDefault("X-Amz-Credential")
  valid_602595 = validateParameter(valid_602595, JString, required = false,
                                 default = nil)
  if valid_602595 != nil:
    section.add "X-Amz-Credential", valid_602595
  var valid_602596 = header.getOrDefault("X-Amz-Security-Token")
  valid_602596 = validateParameter(valid_602596, JString, required = false,
                                 default = nil)
  if valid_602596 != nil:
    section.add "X-Amz-Security-Token", valid_602596
  var valid_602597 = header.getOrDefault("X-Amz-Algorithm")
  valid_602597 = validateParameter(valid_602597, JString, required = false,
                                 default = nil)
  if valid_602597 != nil:
    section.add "X-Amz-Algorithm", valid_602597
  var valid_602598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602598 = validateParameter(valid_602598, JString, required = false,
                                 default = nil)
  if valid_602598 != nil:
    section.add "X-Amz-SignedHeaders", valid_602598
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602600: Call_DeleteIdentityProvider_602588; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an identity provider for a user pool.
  ## 
  let valid = call_602600.validator(path, query, header, formData, body)
  let scheme = call_602600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602600.url(scheme.get, call_602600.host, call_602600.base,
                         call_602600.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602600, url, valid)

proc call*(call_602601: Call_DeleteIdentityProvider_602588; body: JsonNode): Recallable =
  ## deleteIdentityProvider
  ## Deletes an identity provider for a user pool.
  ##   body: JObject (required)
  var body_602602 = newJObject()
  if body != nil:
    body_602602 = body
  result = call_602601.call(nil, nil, nil, nil, body_602602)

var deleteIdentityProvider* = Call_DeleteIdentityProvider_602588(
    name: "deleteIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteIdentityProvider",
    validator: validate_DeleteIdentityProvider_602589, base: "/",
    url: url_DeleteIdentityProvider_602590, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceServer_602603 = ref object of OpenApiRestCall_601389
proc url_DeleteResourceServer_602605(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteResourceServer_602604(path: JsonNode; query: JsonNode;
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
  var valid_602606 = header.getOrDefault("X-Amz-Target")
  valid_602606 = validateParameter(valid_602606, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteResourceServer"))
  if valid_602606 != nil:
    section.add "X-Amz-Target", valid_602606
  var valid_602607 = header.getOrDefault("X-Amz-Signature")
  valid_602607 = validateParameter(valid_602607, JString, required = false,
                                 default = nil)
  if valid_602607 != nil:
    section.add "X-Amz-Signature", valid_602607
  var valid_602608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602608 = validateParameter(valid_602608, JString, required = false,
                                 default = nil)
  if valid_602608 != nil:
    section.add "X-Amz-Content-Sha256", valid_602608
  var valid_602609 = header.getOrDefault("X-Amz-Date")
  valid_602609 = validateParameter(valid_602609, JString, required = false,
                                 default = nil)
  if valid_602609 != nil:
    section.add "X-Amz-Date", valid_602609
  var valid_602610 = header.getOrDefault("X-Amz-Credential")
  valid_602610 = validateParameter(valid_602610, JString, required = false,
                                 default = nil)
  if valid_602610 != nil:
    section.add "X-Amz-Credential", valid_602610
  var valid_602611 = header.getOrDefault("X-Amz-Security-Token")
  valid_602611 = validateParameter(valid_602611, JString, required = false,
                                 default = nil)
  if valid_602611 != nil:
    section.add "X-Amz-Security-Token", valid_602611
  var valid_602612 = header.getOrDefault("X-Amz-Algorithm")
  valid_602612 = validateParameter(valid_602612, JString, required = false,
                                 default = nil)
  if valid_602612 != nil:
    section.add "X-Amz-Algorithm", valid_602612
  var valid_602613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602613 = validateParameter(valid_602613, JString, required = false,
                                 default = nil)
  if valid_602613 != nil:
    section.add "X-Amz-SignedHeaders", valid_602613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602615: Call_DeleteResourceServer_602603; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a resource server.
  ## 
  let valid = call_602615.validator(path, query, header, formData, body)
  let scheme = call_602615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602615.url(scheme.get, call_602615.host, call_602615.base,
                         call_602615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602615, url, valid)

proc call*(call_602616: Call_DeleteResourceServer_602603; body: JsonNode): Recallable =
  ## deleteResourceServer
  ## Deletes a resource server.
  ##   body: JObject (required)
  var body_602617 = newJObject()
  if body != nil:
    body_602617 = body
  result = call_602616.call(nil, nil, nil, nil, body_602617)

var deleteResourceServer* = Call_DeleteResourceServer_602603(
    name: "deleteResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteResourceServer",
    validator: validate_DeleteResourceServer_602604, base: "/",
    url: url_DeleteResourceServer_602605, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_602618 = ref object of OpenApiRestCall_601389
proc url_DeleteUser_602620(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteUser_602619(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602621 = header.getOrDefault("X-Amz-Target")
  valid_602621 = validateParameter(valid_602621, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUser"))
  if valid_602621 != nil:
    section.add "X-Amz-Target", valid_602621
  var valid_602622 = header.getOrDefault("X-Amz-Signature")
  valid_602622 = validateParameter(valid_602622, JString, required = false,
                                 default = nil)
  if valid_602622 != nil:
    section.add "X-Amz-Signature", valid_602622
  var valid_602623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602623 = validateParameter(valid_602623, JString, required = false,
                                 default = nil)
  if valid_602623 != nil:
    section.add "X-Amz-Content-Sha256", valid_602623
  var valid_602624 = header.getOrDefault("X-Amz-Date")
  valid_602624 = validateParameter(valid_602624, JString, required = false,
                                 default = nil)
  if valid_602624 != nil:
    section.add "X-Amz-Date", valid_602624
  var valid_602625 = header.getOrDefault("X-Amz-Credential")
  valid_602625 = validateParameter(valid_602625, JString, required = false,
                                 default = nil)
  if valid_602625 != nil:
    section.add "X-Amz-Credential", valid_602625
  var valid_602626 = header.getOrDefault("X-Amz-Security-Token")
  valid_602626 = validateParameter(valid_602626, JString, required = false,
                                 default = nil)
  if valid_602626 != nil:
    section.add "X-Amz-Security-Token", valid_602626
  var valid_602627 = header.getOrDefault("X-Amz-Algorithm")
  valid_602627 = validateParameter(valid_602627, JString, required = false,
                                 default = nil)
  if valid_602627 != nil:
    section.add "X-Amz-Algorithm", valid_602627
  var valid_602628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602628 = validateParameter(valid_602628, JString, required = false,
                                 default = nil)
  if valid_602628 != nil:
    section.add "X-Amz-SignedHeaders", valid_602628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602630: Call_DeleteUser_602618; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a user to delete himself or herself.
  ## 
  let valid = call_602630.validator(path, query, header, formData, body)
  let scheme = call_602630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602630.url(scheme.get, call_602630.host, call_602630.base,
                         call_602630.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602630, url, valid)

proc call*(call_602631: Call_DeleteUser_602618; body: JsonNode): Recallable =
  ## deleteUser
  ## Allows a user to delete himself or herself.
  ##   body: JObject (required)
  var body_602632 = newJObject()
  if body != nil:
    body_602632 = body
  result = call_602631.call(nil, nil, nil, nil, body_602632)

var deleteUser* = Call_DeleteUser_602618(name: "deleteUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUser",
                                      validator: validate_DeleteUser_602619,
                                      base: "/", url: url_DeleteUser_602620,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserAttributes_602633 = ref object of OpenApiRestCall_601389
proc url_DeleteUserAttributes_602635(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUserAttributes_602634(path: JsonNode; query: JsonNode;
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
  var valid_602636 = header.getOrDefault("X-Amz-Target")
  valid_602636 = validateParameter(valid_602636, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUserAttributes"))
  if valid_602636 != nil:
    section.add "X-Amz-Target", valid_602636
  var valid_602637 = header.getOrDefault("X-Amz-Signature")
  valid_602637 = validateParameter(valid_602637, JString, required = false,
                                 default = nil)
  if valid_602637 != nil:
    section.add "X-Amz-Signature", valid_602637
  var valid_602638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602638 = validateParameter(valid_602638, JString, required = false,
                                 default = nil)
  if valid_602638 != nil:
    section.add "X-Amz-Content-Sha256", valid_602638
  var valid_602639 = header.getOrDefault("X-Amz-Date")
  valid_602639 = validateParameter(valid_602639, JString, required = false,
                                 default = nil)
  if valid_602639 != nil:
    section.add "X-Amz-Date", valid_602639
  var valid_602640 = header.getOrDefault("X-Amz-Credential")
  valid_602640 = validateParameter(valid_602640, JString, required = false,
                                 default = nil)
  if valid_602640 != nil:
    section.add "X-Amz-Credential", valid_602640
  var valid_602641 = header.getOrDefault("X-Amz-Security-Token")
  valid_602641 = validateParameter(valid_602641, JString, required = false,
                                 default = nil)
  if valid_602641 != nil:
    section.add "X-Amz-Security-Token", valid_602641
  var valid_602642 = header.getOrDefault("X-Amz-Algorithm")
  valid_602642 = validateParameter(valid_602642, JString, required = false,
                                 default = nil)
  if valid_602642 != nil:
    section.add "X-Amz-Algorithm", valid_602642
  var valid_602643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602643 = validateParameter(valid_602643, JString, required = false,
                                 default = nil)
  if valid_602643 != nil:
    section.add "X-Amz-SignedHeaders", valid_602643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602645: Call_DeleteUserAttributes_602633; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the attributes for a user.
  ## 
  let valid = call_602645.validator(path, query, header, formData, body)
  let scheme = call_602645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602645.url(scheme.get, call_602645.host, call_602645.base,
                         call_602645.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602645, url, valid)

proc call*(call_602646: Call_DeleteUserAttributes_602633; body: JsonNode): Recallable =
  ## deleteUserAttributes
  ## Deletes the attributes for a user.
  ##   body: JObject (required)
  var body_602647 = newJObject()
  if body != nil:
    body_602647 = body
  result = call_602646.call(nil, nil, nil, nil, body_602647)

var deleteUserAttributes* = Call_DeleteUserAttributes_602633(
    name: "deleteUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserAttributes",
    validator: validate_DeleteUserAttributes_602634, base: "/",
    url: url_DeleteUserAttributes_602635, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserPool_602648 = ref object of OpenApiRestCall_601389
proc url_DeleteUserPool_602650(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUserPool_602649(path: JsonNode; query: JsonNode;
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
  var valid_602651 = header.getOrDefault("X-Amz-Target")
  valid_602651 = validateParameter(valid_602651, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUserPool"))
  if valid_602651 != nil:
    section.add "X-Amz-Target", valid_602651
  var valid_602652 = header.getOrDefault("X-Amz-Signature")
  valid_602652 = validateParameter(valid_602652, JString, required = false,
                                 default = nil)
  if valid_602652 != nil:
    section.add "X-Amz-Signature", valid_602652
  var valid_602653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602653 = validateParameter(valid_602653, JString, required = false,
                                 default = nil)
  if valid_602653 != nil:
    section.add "X-Amz-Content-Sha256", valid_602653
  var valid_602654 = header.getOrDefault("X-Amz-Date")
  valid_602654 = validateParameter(valid_602654, JString, required = false,
                                 default = nil)
  if valid_602654 != nil:
    section.add "X-Amz-Date", valid_602654
  var valid_602655 = header.getOrDefault("X-Amz-Credential")
  valid_602655 = validateParameter(valid_602655, JString, required = false,
                                 default = nil)
  if valid_602655 != nil:
    section.add "X-Amz-Credential", valid_602655
  var valid_602656 = header.getOrDefault("X-Amz-Security-Token")
  valid_602656 = validateParameter(valid_602656, JString, required = false,
                                 default = nil)
  if valid_602656 != nil:
    section.add "X-Amz-Security-Token", valid_602656
  var valid_602657 = header.getOrDefault("X-Amz-Algorithm")
  valid_602657 = validateParameter(valid_602657, JString, required = false,
                                 default = nil)
  if valid_602657 != nil:
    section.add "X-Amz-Algorithm", valid_602657
  var valid_602658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602658 = validateParameter(valid_602658, JString, required = false,
                                 default = nil)
  if valid_602658 != nil:
    section.add "X-Amz-SignedHeaders", valid_602658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602660: Call_DeleteUserPool_602648; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Amazon Cognito user pool.
  ## 
  let valid = call_602660.validator(path, query, header, formData, body)
  let scheme = call_602660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602660.url(scheme.get, call_602660.host, call_602660.base,
                         call_602660.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602660, url, valid)

proc call*(call_602661: Call_DeleteUserPool_602648; body: JsonNode): Recallable =
  ## deleteUserPool
  ## Deletes the specified Amazon Cognito user pool.
  ##   body: JObject (required)
  var body_602662 = newJObject()
  if body != nil:
    body_602662 = body
  result = call_602661.call(nil, nil, nil, nil, body_602662)

var deleteUserPool* = Call_DeleteUserPool_602648(name: "deleteUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserPool",
    validator: validate_DeleteUserPool_602649, base: "/", url: url_DeleteUserPool_602650,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserPoolClient_602663 = ref object of OpenApiRestCall_601389
proc url_DeleteUserPoolClient_602665(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUserPoolClient_602664(path: JsonNode; query: JsonNode;
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
  var valid_602666 = header.getOrDefault("X-Amz-Target")
  valid_602666 = validateParameter(valid_602666, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUserPoolClient"))
  if valid_602666 != nil:
    section.add "X-Amz-Target", valid_602666
  var valid_602667 = header.getOrDefault("X-Amz-Signature")
  valid_602667 = validateParameter(valid_602667, JString, required = false,
                                 default = nil)
  if valid_602667 != nil:
    section.add "X-Amz-Signature", valid_602667
  var valid_602668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602668 = validateParameter(valid_602668, JString, required = false,
                                 default = nil)
  if valid_602668 != nil:
    section.add "X-Amz-Content-Sha256", valid_602668
  var valid_602669 = header.getOrDefault("X-Amz-Date")
  valid_602669 = validateParameter(valid_602669, JString, required = false,
                                 default = nil)
  if valid_602669 != nil:
    section.add "X-Amz-Date", valid_602669
  var valid_602670 = header.getOrDefault("X-Amz-Credential")
  valid_602670 = validateParameter(valid_602670, JString, required = false,
                                 default = nil)
  if valid_602670 != nil:
    section.add "X-Amz-Credential", valid_602670
  var valid_602671 = header.getOrDefault("X-Amz-Security-Token")
  valid_602671 = validateParameter(valid_602671, JString, required = false,
                                 default = nil)
  if valid_602671 != nil:
    section.add "X-Amz-Security-Token", valid_602671
  var valid_602672 = header.getOrDefault("X-Amz-Algorithm")
  valid_602672 = validateParameter(valid_602672, JString, required = false,
                                 default = nil)
  if valid_602672 != nil:
    section.add "X-Amz-Algorithm", valid_602672
  var valid_602673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602673 = validateParameter(valid_602673, JString, required = false,
                                 default = nil)
  if valid_602673 != nil:
    section.add "X-Amz-SignedHeaders", valid_602673
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602675: Call_DeleteUserPoolClient_602663; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows the developer to delete the user pool client.
  ## 
  let valid = call_602675.validator(path, query, header, formData, body)
  let scheme = call_602675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602675.url(scheme.get, call_602675.host, call_602675.base,
                         call_602675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602675, url, valid)

proc call*(call_602676: Call_DeleteUserPoolClient_602663; body: JsonNode): Recallable =
  ## deleteUserPoolClient
  ## Allows the developer to delete the user pool client.
  ##   body: JObject (required)
  var body_602677 = newJObject()
  if body != nil:
    body_602677 = body
  result = call_602676.call(nil, nil, nil, nil, body_602677)

var deleteUserPoolClient* = Call_DeleteUserPoolClient_602663(
    name: "deleteUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserPoolClient",
    validator: validate_DeleteUserPoolClient_602664, base: "/",
    url: url_DeleteUserPoolClient_602665, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserPoolDomain_602678 = ref object of OpenApiRestCall_601389
proc url_DeleteUserPoolDomain_602680(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUserPoolDomain_602679(path: JsonNode; query: JsonNode;
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
  var valid_602681 = header.getOrDefault("X-Amz-Target")
  valid_602681 = validateParameter(valid_602681, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DeleteUserPoolDomain"))
  if valid_602681 != nil:
    section.add "X-Amz-Target", valid_602681
  var valid_602682 = header.getOrDefault("X-Amz-Signature")
  valid_602682 = validateParameter(valid_602682, JString, required = false,
                                 default = nil)
  if valid_602682 != nil:
    section.add "X-Amz-Signature", valid_602682
  var valid_602683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602683 = validateParameter(valid_602683, JString, required = false,
                                 default = nil)
  if valid_602683 != nil:
    section.add "X-Amz-Content-Sha256", valid_602683
  var valid_602684 = header.getOrDefault("X-Amz-Date")
  valid_602684 = validateParameter(valid_602684, JString, required = false,
                                 default = nil)
  if valid_602684 != nil:
    section.add "X-Amz-Date", valid_602684
  var valid_602685 = header.getOrDefault("X-Amz-Credential")
  valid_602685 = validateParameter(valid_602685, JString, required = false,
                                 default = nil)
  if valid_602685 != nil:
    section.add "X-Amz-Credential", valid_602685
  var valid_602686 = header.getOrDefault("X-Amz-Security-Token")
  valid_602686 = validateParameter(valid_602686, JString, required = false,
                                 default = nil)
  if valid_602686 != nil:
    section.add "X-Amz-Security-Token", valid_602686
  var valid_602687 = header.getOrDefault("X-Amz-Algorithm")
  valid_602687 = validateParameter(valid_602687, JString, required = false,
                                 default = nil)
  if valid_602687 != nil:
    section.add "X-Amz-Algorithm", valid_602687
  var valid_602688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602688 = validateParameter(valid_602688, JString, required = false,
                                 default = nil)
  if valid_602688 != nil:
    section.add "X-Amz-SignedHeaders", valid_602688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602690: Call_DeleteUserPoolDomain_602678; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a domain for a user pool.
  ## 
  let valid = call_602690.validator(path, query, header, formData, body)
  let scheme = call_602690.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602690.url(scheme.get, call_602690.host, call_602690.base,
                         call_602690.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602690, url, valid)

proc call*(call_602691: Call_DeleteUserPoolDomain_602678; body: JsonNode): Recallable =
  ## deleteUserPoolDomain
  ## Deletes a domain for a user pool.
  ##   body: JObject (required)
  var body_602692 = newJObject()
  if body != nil:
    body_602692 = body
  result = call_602691.call(nil, nil, nil, nil, body_602692)

var deleteUserPoolDomain* = Call_DeleteUserPoolDomain_602678(
    name: "deleteUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DeleteUserPoolDomain",
    validator: validate_DeleteUserPoolDomain_602679, base: "/",
    url: url_DeleteUserPoolDomain_602680, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentityProvider_602693 = ref object of OpenApiRestCall_601389
proc url_DescribeIdentityProvider_602695(protocol: Scheme; host: string;
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

proc validate_DescribeIdentityProvider_602694(path: JsonNode; query: JsonNode;
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
  var valid_602696 = header.getOrDefault("X-Amz-Target")
  valid_602696 = validateParameter(valid_602696, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeIdentityProvider"))
  if valid_602696 != nil:
    section.add "X-Amz-Target", valid_602696
  var valid_602697 = header.getOrDefault("X-Amz-Signature")
  valid_602697 = validateParameter(valid_602697, JString, required = false,
                                 default = nil)
  if valid_602697 != nil:
    section.add "X-Amz-Signature", valid_602697
  var valid_602698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602698 = validateParameter(valid_602698, JString, required = false,
                                 default = nil)
  if valid_602698 != nil:
    section.add "X-Amz-Content-Sha256", valid_602698
  var valid_602699 = header.getOrDefault("X-Amz-Date")
  valid_602699 = validateParameter(valid_602699, JString, required = false,
                                 default = nil)
  if valid_602699 != nil:
    section.add "X-Amz-Date", valid_602699
  var valid_602700 = header.getOrDefault("X-Amz-Credential")
  valid_602700 = validateParameter(valid_602700, JString, required = false,
                                 default = nil)
  if valid_602700 != nil:
    section.add "X-Amz-Credential", valid_602700
  var valid_602701 = header.getOrDefault("X-Amz-Security-Token")
  valid_602701 = validateParameter(valid_602701, JString, required = false,
                                 default = nil)
  if valid_602701 != nil:
    section.add "X-Amz-Security-Token", valid_602701
  var valid_602702 = header.getOrDefault("X-Amz-Algorithm")
  valid_602702 = validateParameter(valid_602702, JString, required = false,
                                 default = nil)
  if valid_602702 != nil:
    section.add "X-Amz-Algorithm", valid_602702
  var valid_602703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602703 = validateParameter(valid_602703, JString, required = false,
                                 default = nil)
  if valid_602703 != nil:
    section.add "X-Amz-SignedHeaders", valid_602703
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602705: Call_DescribeIdentityProvider_602693; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specific identity provider.
  ## 
  let valid = call_602705.validator(path, query, header, formData, body)
  let scheme = call_602705.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602705.url(scheme.get, call_602705.host, call_602705.base,
                         call_602705.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602705, url, valid)

proc call*(call_602706: Call_DescribeIdentityProvider_602693; body: JsonNode): Recallable =
  ## describeIdentityProvider
  ## Gets information about a specific identity provider.
  ##   body: JObject (required)
  var body_602707 = newJObject()
  if body != nil:
    body_602707 = body
  result = call_602706.call(nil, nil, nil, nil, body_602707)

var describeIdentityProvider* = Call_DescribeIdentityProvider_602693(
    name: "describeIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeIdentityProvider",
    validator: validate_DescribeIdentityProvider_602694, base: "/",
    url: url_DescribeIdentityProvider_602695, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResourceServer_602708 = ref object of OpenApiRestCall_601389
proc url_DescribeResourceServer_602710(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeResourceServer_602709(path: JsonNode; query: JsonNode;
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
  var valid_602711 = header.getOrDefault("X-Amz-Target")
  valid_602711 = validateParameter(valid_602711, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeResourceServer"))
  if valid_602711 != nil:
    section.add "X-Amz-Target", valid_602711
  var valid_602712 = header.getOrDefault("X-Amz-Signature")
  valid_602712 = validateParameter(valid_602712, JString, required = false,
                                 default = nil)
  if valid_602712 != nil:
    section.add "X-Amz-Signature", valid_602712
  var valid_602713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602713 = validateParameter(valid_602713, JString, required = false,
                                 default = nil)
  if valid_602713 != nil:
    section.add "X-Amz-Content-Sha256", valid_602713
  var valid_602714 = header.getOrDefault("X-Amz-Date")
  valid_602714 = validateParameter(valid_602714, JString, required = false,
                                 default = nil)
  if valid_602714 != nil:
    section.add "X-Amz-Date", valid_602714
  var valid_602715 = header.getOrDefault("X-Amz-Credential")
  valid_602715 = validateParameter(valid_602715, JString, required = false,
                                 default = nil)
  if valid_602715 != nil:
    section.add "X-Amz-Credential", valid_602715
  var valid_602716 = header.getOrDefault("X-Amz-Security-Token")
  valid_602716 = validateParameter(valid_602716, JString, required = false,
                                 default = nil)
  if valid_602716 != nil:
    section.add "X-Amz-Security-Token", valid_602716
  var valid_602717 = header.getOrDefault("X-Amz-Algorithm")
  valid_602717 = validateParameter(valid_602717, JString, required = false,
                                 default = nil)
  if valid_602717 != nil:
    section.add "X-Amz-Algorithm", valid_602717
  var valid_602718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602718 = validateParameter(valid_602718, JString, required = false,
                                 default = nil)
  if valid_602718 != nil:
    section.add "X-Amz-SignedHeaders", valid_602718
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602720: Call_DescribeResourceServer_602708; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a resource server.
  ## 
  let valid = call_602720.validator(path, query, header, formData, body)
  let scheme = call_602720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602720.url(scheme.get, call_602720.host, call_602720.base,
                         call_602720.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602720, url, valid)

proc call*(call_602721: Call_DescribeResourceServer_602708; body: JsonNode): Recallable =
  ## describeResourceServer
  ## Describes a resource server.
  ##   body: JObject (required)
  var body_602722 = newJObject()
  if body != nil:
    body_602722 = body
  result = call_602721.call(nil, nil, nil, nil, body_602722)

var describeResourceServer* = Call_DescribeResourceServer_602708(
    name: "describeResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeResourceServer",
    validator: validate_DescribeResourceServer_602709, base: "/",
    url: url_DescribeResourceServer_602710, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRiskConfiguration_602723 = ref object of OpenApiRestCall_601389
proc url_DescribeRiskConfiguration_602725(protocol: Scheme; host: string;
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

proc validate_DescribeRiskConfiguration_602724(path: JsonNode; query: JsonNode;
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
  var valid_602726 = header.getOrDefault("X-Amz-Target")
  valid_602726 = validateParameter(valid_602726, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeRiskConfiguration"))
  if valid_602726 != nil:
    section.add "X-Amz-Target", valid_602726
  var valid_602727 = header.getOrDefault("X-Amz-Signature")
  valid_602727 = validateParameter(valid_602727, JString, required = false,
                                 default = nil)
  if valid_602727 != nil:
    section.add "X-Amz-Signature", valid_602727
  var valid_602728 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602728 = validateParameter(valid_602728, JString, required = false,
                                 default = nil)
  if valid_602728 != nil:
    section.add "X-Amz-Content-Sha256", valid_602728
  var valid_602729 = header.getOrDefault("X-Amz-Date")
  valid_602729 = validateParameter(valid_602729, JString, required = false,
                                 default = nil)
  if valid_602729 != nil:
    section.add "X-Amz-Date", valid_602729
  var valid_602730 = header.getOrDefault("X-Amz-Credential")
  valid_602730 = validateParameter(valid_602730, JString, required = false,
                                 default = nil)
  if valid_602730 != nil:
    section.add "X-Amz-Credential", valid_602730
  var valid_602731 = header.getOrDefault("X-Amz-Security-Token")
  valid_602731 = validateParameter(valid_602731, JString, required = false,
                                 default = nil)
  if valid_602731 != nil:
    section.add "X-Amz-Security-Token", valid_602731
  var valid_602732 = header.getOrDefault("X-Amz-Algorithm")
  valid_602732 = validateParameter(valid_602732, JString, required = false,
                                 default = nil)
  if valid_602732 != nil:
    section.add "X-Amz-Algorithm", valid_602732
  var valid_602733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602733 = validateParameter(valid_602733, JString, required = false,
                                 default = nil)
  if valid_602733 != nil:
    section.add "X-Amz-SignedHeaders", valid_602733
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602735: Call_DescribeRiskConfiguration_602723; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the risk configuration.
  ## 
  let valid = call_602735.validator(path, query, header, formData, body)
  let scheme = call_602735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602735.url(scheme.get, call_602735.host, call_602735.base,
                         call_602735.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602735, url, valid)

proc call*(call_602736: Call_DescribeRiskConfiguration_602723; body: JsonNode): Recallable =
  ## describeRiskConfiguration
  ## Describes the risk configuration.
  ##   body: JObject (required)
  var body_602737 = newJObject()
  if body != nil:
    body_602737 = body
  result = call_602736.call(nil, nil, nil, nil, body_602737)

var describeRiskConfiguration* = Call_DescribeRiskConfiguration_602723(
    name: "describeRiskConfiguration", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeRiskConfiguration",
    validator: validate_DescribeRiskConfiguration_602724, base: "/",
    url: url_DescribeRiskConfiguration_602725,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserImportJob_602738 = ref object of OpenApiRestCall_601389
proc url_DescribeUserImportJob_602740(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUserImportJob_602739(path: JsonNode; query: JsonNode;
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
  var valid_602741 = header.getOrDefault("X-Amz-Target")
  valid_602741 = validateParameter(valid_602741, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserImportJob"))
  if valid_602741 != nil:
    section.add "X-Amz-Target", valid_602741
  var valid_602742 = header.getOrDefault("X-Amz-Signature")
  valid_602742 = validateParameter(valid_602742, JString, required = false,
                                 default = nil)
  if valid_602742 != nil:
    section.add "X-Amz-Signature", valid_602742
  var valid_602743 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602743 = validateParameter(valid_602743, JString, required = false,
                                 default = nil)
  if valid_602743 != nil:
    section.add "X-Amz-Content-Sha256", valid_602743
  var valid_602744 = header.getOrDefault("X-Amz-Date")
  valid_602744 = validateParameter(valid_602744, JString, required = false,
                                 default = nil)
  if valid_602744 != nil:
    section.add "X-Amz-Date", valid_602744
  var valid_602745 = header.getOrDefault("X-Amz-Credential")
  valid_602745 = validateParameter(valid_602745, JString, required = false,
                                 default = nil)
  if valid_602745 != nil:
    section.add "X-Amz-Credential", valid_602745
  var valid_602746 = header.getOrDefault("X-Amz-Security-Token")
  valid_602746 = validateParameter(valid_602746, JString, required = false,
                                 default = nil)
  if valid_602746 != nil:
    section.add "X-Amz-Security-Token", valid_602746
  var valid_602747 = header.getOrDefault("X-Amz-Algorithm")
  valid_602747 = validateParameter(valid_602747, JString, required = false,
                                 default = nil)
  if valid_602747 != nil:
    section.add "X-Amz-Algorithm", valid_602747
  var valid_602748 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602748 = validateParameter(valid_602748, JString, required = false,
                                 default = nil)
  if valid_602748 != nil:
    section.add "X-Amz-SignedHeaders", valid_602748
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602750: Call_DescribeUserImportJob_602738; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the user import job.
  ## 
  let valid = call_602750.validator(path, query, header, formData, body)
  let scheme = call_602750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602750.url(scheme.get, call_602750.host, call_602750.base,
                         call_602750.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602750, url, valid)

proc call*(call_602751: Call_DescribeUserImportJob_602738; body: JsonNode): Recallable =
  ## describeUserImportJob
  ## Describes the user import job.
  ##   body: JObject (required)
  var body_602752 = newJObject()
  if body != nil:
    body_602752 = body
  result = call_602751.call(nil, nil, nil, nil, body_602752)

var describeUserImportJob* = Call_DescribeUserImportJob_602738(
    name: "describeUserImportJob", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserImportJob",
    validator: validate_DescribeUserImportJob_602739, base: "/",
    url: url_DescribeUserImportJob_602740, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserPool_602753 = ref object of OpenApiRestCall_601389
proc url_DescribeUserPool_602755(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUserPool_602754(path: JsonNode; query: JsonNode;
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
  var valid_602756 = header.getOrDefault("X-Amz-Target")
  valid_602756 = validateParameter(valid_602756, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserPool"))
  if valid_602756 != nil:
    section.add "X-Amz-Target", valid_602756
  var valid_602757 = header.getOrDefault("X-Amz-Signature")
  valid_602757 = validateParameter(valid_602757, JString, required = false,
                                 default = nil)
  if valid_602757 != nil:
    section.add "X-Amz-Signature", valid_602757
  var valid_602758 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602758 = validateParameter(valid_602758, JString, required = false,
                                 default = nil)
  if valid_602758 != nil:
    section.add "X-Amz-Content-Sha256", valid_602758
  var valid_602759 = header.getOrDefault("X-Amz-Date")
  valid_602759 = validateParameter(valid_602759, JString, required = false,
                                 default = nil)
  if valid_602759 != nil:
    section.add "X-Amz-Date", valid_602759
  var valid_602760 = header.getOrDefault("X-Amz-Credential")
  valid_602760 = validateParameter(valid_602760, JString, required = false,
                                 default = nil)
  if valid_602760 != nil:
    section.add "X-Amz-Credential", valid_602760
  var valid_602761 = header.getOrDefault("X-Amz-Security-Token")
  valid_602761 = validateParameter(valid_602761, JString, required = false,
                                 default = nil)
  if valid_602761 != nil:
    section.add "X-Amz-Security-Token", valid_602761
  var valid_602762 = header.getOrDefault("X-Amz-Algorithm")
  valid_602762 = validateParameter(valid_602762, JString, required = false,
                                 default = nil)
  if valid_602762 != nil:
    section.add "X-Amz-Algorithm", valid_602762
  var valid_602763 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602763 = validateParameter(valid_602763, JString, required = false,
                                 default = nil)
  if valid_602763 != nil:
    section.add "X-Amz-SignedHeaders", valid_602763
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602765: Call_DescribeUserPool_602753; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the configuration information and metadata of the specified user pool.
  ## 
  let valid = call_602765.validator(path, query, header, formData, body)
  let scheme = call_602765.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602765.url(scheme.get, call_602765.host, call_602765.base,
                         call_602765.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602765, url, valid)

proc call*(call_602766: Call_DescribeUserPool_602753; body: JsonNode): Recallable =
  ## describeUserPool
  ## Returns the configuration information and metadata of the specified user pool.
  ##   body: JObject (required)
  var body_602767 = newJObject()
  if body != nil:
    body_602767 = body
  result = call_602766.call(nil, nil, nil, nil, body_602767)

var describeUserPool* = Call_DescribeUserPool_602753(name: "describeUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserPool",
    validator: validate_DescribeUserPool_602754, base: "/",
    url: url_DescribeUserPool_602755, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserPoolClient_602768 = ref object of OpenApiRestCall_601389
proc url_DescribeUserPoolClient_602770(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUserPoolClient_602769(path: JsonNode; query: JsonNode;
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
  var valid_602771 = header.getOrDefault("X-Amz-Target")
  valid_602771 = validateParameter(valid_602771, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserPoolClient"))
  if valid_602771 != nil:
    section.add "X-Amz-Target", valid_602771
  var valid_602772 = header.getOrDefault("X-Amz-Signature")
  valid_602772 = validateParameter(valid_602772, JString, required = false,
                                 default = nil)
  if valid_602772 != nil:
    section.add "X-Amz-Signature", valid_602772
  var valid_602773 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602773 = validateParameter(valid_602773, JString, required = false,
                                 default = nil)
  if valid_602773 != nil:
    section.add "X-Amz-Content-Sha256", valid_602773
  var valid_602774 = header.getOrDefault("X-Amz-Date")
  valid_602774 = validateParameter(valid_602774, JString, required = false,
                                 default = nil)
  if valid_602774 != nil:
    section.add "X-Amz-Date", valid_602774
  var valid_602775 = header.getOrDefault("X-Amz-Credential")
  valid_602775 = validateParameter(valid_602775, JString, required = false,
                                 default = nil)
  if valid_602775 != nil:
    section.add "X-Amz-Credential", valid_602775
  var valid_602776 = header.getOrDefault("X-Amz-Security-Token")
  valid_602776 = validateParameter(valid_602776, JString, required = false,
                                 default = nil)
  if valid_602776 != nil:
    section.add "X-Amz-Security-Token", valid_602776
  var valid_602777 = header.getOrDefault("X-Amz-Algorithm")
  valid_602777 = validateParameter(valid_602777, JString, required = false,
                                 default = nil)
  if valid_602777 != nil:
    section.add "X-Amz-Algorithm", valid_602777
  var valid_602778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602778 = validateParameter(valid_602778, JString, required = false,
                                 default = nil)
  if valid_602778 != nil:
    section.add "X-Amz-SignedHeaders", valid_602778
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602780: Call_DescribeUserPoolClient_602768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Client method for returning the configuration information and metadata of the specified user pool app client.
  ## 
  let valid = call_602780.validator(path, query, header, formData, body)
  let scheme = call_602780.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602780.url(scheme.get, call_602780.host, call_602780.base,
                         call_602780.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602780, url, valid)

proc call*(call_602781: Call_DescribeUserPoolClient_602768; body: JsonNode): Recallable =
  ## describeUserPoolClient
  ## Client method for returning the configuration information and metadata of the specified user pool app client.
  ##   body: JObject (required)
  var body_602782 = newJObject()
  if body != nil:
    body_602782 = body
  result = call_602781.call(nil, nil, nil, nil, body_602782)

var describeUserPoolClient* = Call_DescribeUserPoolClient_602768(
    name: "describeUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserPoolClient",
    validator: validate_DescribeUserPoolClient_602769, base: "/",
    url: url_DescribeUserPoolClient_602770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserPoolDomain_602783 = ref object of OpenApiRestCall_601389
proc url_DescribeUserPoolDomain_602785(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUserPoolDomain_602784(path: JsonNode; query: JsonNode;
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
  var valid_602786 = header.getOrDefault("X-Amz-Target")
  valid_602786 = validateParameter(valid_602786, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.DescribeUserPoolDomain"))
  if valid_602786 != nil:
    section.add "X-Amz-Target", valid_602786
  var valid_602787 = header.getOrDefault("X-Amz-Signature")
  valid_602787 = validateParameter(valid_602787, JString, required = false,
                                 default = nil)
  if valid_602787 != nil:
    section.add "X-Amz-Signature", valid_602787
  var valid_602788 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602788 = validateParameter(valid_602788, JString, required = false,
                                 default = nil)
  if valid_602788 != nil:
    section.add "X-Amz-Content-Sha256", valid_602788
  var valid_602789 = header.getOrDefault("X-Amz-Date")
  valid_602789 = validateParameter(valid_602789, JString, required = false,
                                 default = nil)
  if valid_602789 != nil:
    section.add "X-Amz-Date", valid_602789
  var valid_602790 = header.getOrDefault("X-Amz-Credential")
  valid_602790 = validateParameter(valid_602790, JString, required = false,
                                 default = nil)
  if valid_602790 != nil:
    section.add "X-Amz-Credential", valid_602790
  var valid_602791 = header.getOrDefault("X-Amz-Security-Token")
  valid_602791 = validateParameter(valid_602791, JString, required = false,
                                 default = nil)
  if valid_602791 != nil:
    section.add "X-Amz-Security-Token", valid_602791
  var valid_602792 = header.getOrDefault("X-Amz-Algorithm")
  valid_602792 = validateParameter(valid_602792, JString, required = false,
                                 default = nil)
  if valid_602792 != nil:
    section.add "X-Amz-Algorithm", valid_602792
  var valid_602793 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602793 = validateParameter(valid_602793, JString, required = false,
                                 default = nil)
  if valid_602793 != nil:
    section.add "X-Amz-SignedHeaders", valid_602793
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602795: Call_DescribeUserPoolDomain_602783; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a domain.
  ## 
  let valid = call_602795.validator(path, query, header, formData, body)
  let scheme = call_602795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602795.url(scheme.get, call_602795.host, call_602795.base,
                         call_602795.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602795, url, valid)

proc call*(call_602796: Call_DescribeUserPoolDomain_602783; body: JsonNode): Recallable =
  ## describeUserPoolDomain
  ## Gets information about a domain.
  ##   body: JObject (required)
  var body_602797 = newJObject()
  if body != nil:
    body_602797 = body
  result = call_602796.call(nil, nil, nil, nil, body_602797)

var describeUserPoolDomain* = Call_DescribeUserPoolDomain_602783(
    name: "describeUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.DescribeUserPoolDomain",
    validator: validate_DescribeUserPoolDomain_602784, base: "/",
    url: url_DescribeUserPoolDomain_602785, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ForgetDevice_602798 = ref object of OpenApiRestCall_601389
proc url_ForgetDevice_602800(protocol: Scheme; host: string; base: string;
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

proc validate_ForgetDevice_602799(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602801 = header.getOrDefault("X-Amz-Target")
  valid_602801 = validateParameter(valid_602801, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ForgetDevice"))
  if valid_602801 != nil:
    section.add "X-Amz-Target", valid_602801
  var valid_602802 = header.getOrDefault("X-Amz-Signature")
  valid_602802 = validateParameter(valid_602802, JString, required = false,
                                 default = nil)
  if valid_602802 != nil:
    section.add "X-Amz-Signature", valid_602802
  var valid_602803 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602803 = validateParameter(valid_602803, JString, required = false,
                                 default = nil)
  if valid_602803 != nil:
    section.add "X-Amz-Content-Sha256", valid_602803
  var valid_602804 = header.getOrDefault("X-Amz-Date")
  valid_602804 = validateParameter(valid_602804, JString, required = false,
                                 default = nil)
  if valid_602804 != nil:
    section.add "X-Amz-Date", valid_602804
  var valid_602805 = header.getOrDefault("X-Amz-Credential")
  valid_602805 = validateParameter(valid_602805, JString, required = false,
                                 default = nil)
  if valid_602805 != nil:
    section.add "X-Amz-Credential", valid_602805
  var valid_602806 = header.getOrDefault("X-Amz-Security-Token")
  valid_602806 = validateParameter(valid_602806, JString, required = false,
                                 default = nil)
  if valid_602806 != nil:
    section.add "X-Amz-Security-Token", valid_602806
  var valid_602807 = header.getOrDefault("X-Amz-Algorithm")
  valid_602807 = validateParameter(valid_602807, JString, required = false,
                                 default = nil)
  if valid_602807 != nil:
    section.add "X-Amz-Algorithm", valid_602807
  var valid_602808 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602808 = validateParameter(valid_602808, JString, required = false,
                                 default = nil)
  if valid_602808 != nil:
    section.add "X-Amz-SignedHeaders", valid_602808
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602810: Call_ForgetDevice_602798; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Forgets the specified device.
  ## 
  let valid = call_602810.validator(path, query, header, formData, body)
  let scheme = call_602810.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602810.url(scheme.get, call_602810.host, call_602810.base,
                         call_602810.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602810, url, valid)

proc call*(call_602811: Call_ForgetDevice_602798; body: JsonNode): Recallable =
  ## forgetDevice
  ## Forgets the specified device.
  ##   body: JObject (required)
  var body_602812 = newJObject()
  if body != nil:
    body_602812 = body
  result = call_602811.call(nil, nil, nil, nil, body_602812)

var forgetDevice* = Call_ForgetDevice_602798(name: "forgetDevice",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ForgetDevice",
    validator: validate_ForgetDevice_602799, base: "/", url: url_ForgetDevice_602800,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ForgotPassword_602813 = ref object of OpenApiRestCall_601389
proc url_ForgotPassword_602815(protocol: Scheme; host: string; base: string;
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

proc validate_ForgotPassword_602814(path: JsonNode; query: JsonNode;
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
  var valid_602816 = header.getOrDefault("X-Amz-Target")
  valid_602816 = validateParameter(valid_602816, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ForgotPassword"))
  if valid_602816 != nil:
    section.add "X-Amz-Target", valid_602816
  var valid_602817 = header.getOrDefault("X-Amz-Signature")
  valid_602817 = validateParameter(valid_602817, JString, required = false,
                                 default = nil)
  if valid_602817 != nil:
    section.add "X-Amz-Signature", valid_602817
  var valid_602818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602818 = validateParameter(valid_602818, JString, required = false,
                                 default = nil)
  if valid_602818 != nil:
    section.add "X-Amz-Content-Sha256", valid_602818
  var valid_602819 = header.getOrDefault("X-Amz-Date")
  valid_602819 = validateParameter(valid_602819, JString, required = false,
                                 default = nil)
  if valid_602819 != nil:
    section.add "X-Amz-Date", valid_602819
  var valid_602820 = header.getOrDefault("X-Amz-Credential")
  valid_602820 = validateParameter(valid_602820, JString, required = false,
                                 default = nil)
  if valid_602820 != nil:
    section.add "X-Amz-Credential", valid_602820
  var valid_602821 = header.getOrDefault("X-Amz-Security-Token")
  valid_602821 = validateParameter(valid_602821, JString, required = false,
                                 default = nil)
  if valid_602821 != nil:
    section.add "X-Amz-Security-Token", valid_602821
  var valid_602822 = header.getOrDefault("X-Amz-Algorithm")
  valid_602822 = validateParameter(valid_602822, JString, required = false,
                                 default = nil)
  if valid_602822 != nil:
    section.add "X-Amz-Algorithm", valid_602822
  var valid_602823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602823 = validateParameter(valid_602823, JString, required = false,
                                 default = nil)
  if valid_602823 != nil:
    section.add "X-Amz-SignedHeaders", valid_602823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602825: Call_ForgotPassword_602813; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Calling this API causes a message to be sent to the end user with a confirmation code that is required to change the user's password. For the <code>Username</code> parameter, you can use the username or user alias. If a verified phone number exists for the user, the confirmation code is sent to the phone number. Otherwise, if a verified email exists, the confirmation code is sent to the email. If neither a verified phone number nor a verified email exists, <code>InvalidParameterException</code> is thrown. To use the confirmation code for resetting the password, call .
  ## 
  let valid = call_602825.validator(path, query, header, formData, body)
  let scheme = call_602825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602825.url(scheme.get, call_602825.host, call_602825.base,
                         call_602825.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602825, url, valid)

proc call*(call_602826: Call_ForgotPassword_602813; body: JsonNode): Recallable =
  ## forgotPassword
  ## Calling this API causes a message to be sent to the end user with a confirmation code that is required to change the user's password. For the <code>Username</code> parameter, you can use the username or user alias. If a verified phone number exists for the user, the confirmation code is sent to the phone number. Otherwise, if a verified email exists, the confirmation code is sent to the email. If neither a verified phone number nor a verified email exists, <code>InvalidParameterException</code> is thrown. To use the confirmation code for resetting the password, call .
  ##   body: JObject (required)
  var body_602827 = newJObject()
  if body != nil:
    body_602827 = body
  result = call_602826.call(nil, nil, nil, nil, body_602827)

var forgotPassword* = Call_ForgotPassword_602813(name: "forgotPassword",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ForgotPassword",
    validator: validate_ForgotPassword_602814, base: "/", url: url_ForgotPassword_602815,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCSVHeader_602828 = ref object of OpenApiRestCall_601389
proc url_GetCSVHeader_602830(protocol: Scheme; host: string; base: string;
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

proc validate_GetCSVHeader_602829(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602831 = header.getOrDefault("X-Amz-Target")
  valid_602831 = validateParameter(valid_602831, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetCSVHeader"))
  if valid_602831 != nil:
    section.add "X-Amz-Target", valid_602831
  var valid_602832 = header.getOrDefault("X-Amz-Signature")
  valid_602832 = validateParameter(valid_602832, JString, required = false,
                                 default = nil)
  if valid_602832 != nil:
    section.add "X-Amz-Signature", valid_602832
  var valid_602833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602833 = validateParameter(valid_602833, JString, required = false,
                                 default = nil)
  if valid_602833 != nil:
    section.add "X-Amz-Content-Sha256", valid_602833
  var valid_602834 = header.getOrDefault("X-Amz-Date")
  valid_602834 = validateParameter(valid_602834, JString, required = false,
                                 default = nil)
  if valid_602834 != nil:
    section.add "X-Amz-Date", valid_602834
  var valid_602835 = header.getOrDefault("X-Amz-Credential")
  valid_602835 = validateParameter(valid_602835, JString, required = false,
                                 default = nil)
  if valid_602835 != nil:
    section.add "X-Amz-Credential", valid_602835
  var valid_602836 = header.getOrDefault("X-Amz-Security-Token")
  valid_602836 = validateParameter(valid_602836, JString, required = false,
                                 default = nil)
  if valid_602836 != nil:
    section.add "X-Amz-Security-Token", valid_602836
  var valid_602837 = header.getOrDefault("X-Amz-Algorithm")
  valid_602837 = validateParameter(valid_602837, JString, required = false,
                                 default = nil)
  if valid_602837 != nil:
    section.add "X-Amz-Algorithm", valid_602837
  var valid_602838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602838 = validateParameter(valid_602838, JString, required = false,
                                 default = nil)
  if valid_602838 != nil:
    section.add "X-Amz-SignedHeaders", valid_602838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602840: Call_GetCSVHeader_602828; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the header information for the .csv file to be used as input for the user import job.
  ## 
  let valid = call_602840.validator(path, query, header, formData, body)
  let scheme = call_602840.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602840.url(scheme.get, call_602840.host, call_602840.base,
                         call_602840.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602840, url, valid)

proc call*(call_602841: Call_GetCSVHeader_602828; body: JsonNode): Recallable =
  ## getCSVHeader
  ## Gets the header information for the .csv file to be used as input for the user import job.
  ##   body: JObject (required)
  var body_602842 = newJObject()
  if body != nil:
    body_602842 = body
  result = call_602841.call(nil, nil, nil, nil, body_602842)

var getCSVHeader* = Call_GetCSVHeader_602828(name: "getCSVHeader",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetCSVHeader",
    validator: validate_GetCSVHeader_602829, base: "/", url: url_GetCSVHeader_602830,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevice_602843 = ref object of OpenApiRestCall_601389
proc url_GetDevice_602845(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetDevice_602844(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602846 = header.getOrDefault("X-Amz-Target")
  valid_602846 = validateParameter(valid_602846, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetDevice"))
  if valid_602846 != nil:
    section.add "X-Amz-Target", valid_602846
  var valid_602847 = header.getOrDefault("X-Amz-Signature")
  valid_602847 = validateParameter(valid_602847, JString, required = false,
                                 default = nil)
  if valid_602847 != nil:
    section.add "X-Amz-Signature", valid_602847
  var valid_602848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602848 = validateParameter(valid_602848, JString, required = false,
                                 default = nil)
  if valid_602848 != nil:
    section.add "X-Amz-Content-Sha256", valid_602848
  var valid_602849 = header.getOrDefault("X-Amz-Date")
  valid_602849 = validateParameter(valid_602849, JString, required = false,
                                 default = nil)
  if valid_602849 != nil:
    section.add "X-Amz-Date", valid_602849
  var valid_602850 = header.getOrDefault("X-Amz-Credential")
  valid_602850 = validateParameter(valid_602850, JString, required = false,
                                 default = nil)
  if valid_602850 != nil:
    section.add "X-Amz-Credential", valid_602850
  var valid_602851 = header.getOrDefault("X-Amz-Security-Token")
  valid_602851 = validateParameter(valid_602851, JString, required = false,
                                 default = nil)
  if valid_602851 != nil:
    section.add "X-Amz-Security-Token", valid_602851
  var valid_602852 = header.getOrDefault("X-Amz-Algorithm")
  valid_602852 = validateParameter(valid_602852, JString, required = false,
                                 default = nil)
  if valid_602852 != nil:
    section.add "X-Amz-Algorithm", valid_602852
  var valid_602853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602853 = validateParameter(valid_602853, JString, required = false,
                                 default = nil)
  if valid_602853 != nil:
    section.add "X-Amz-SignedHeaders", valid_602853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602855: Call_GetDevice_602843; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the device.
  ## 
  let valid = call_602855.validator(path, query, header, formData, body)
  let scheme = call_602855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602855.url(scheme.get, call_602855.host, call_602855.base,
                         call_602855.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602855, url, valid)

proc call*(call_602856: Call_GetDevice_602843; body: JsonNode): Recallable =
  ## getDevice
  ## Gets the device.
  ##   body: JObject (required)
  var body_602857 = newJObject()
  if body != nil:
    body_602857 = body
  result = call_602856.call(nil, nil, nil, nil, body_602857)

var getDevice* = Call_GetDevice_602843(name: "getDevice", meth: HttpMethod.HttpPost,
                                    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetDevice",
                                    validator: validate_GetDevice_602844,
                                    base: "/", url: url_GetDevice_602845,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroup_602858 = ref object of OpenApiRestCall_601389
proc url_GetGroup_602860(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetGroup_602859(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602861 = header.getOrDefault("X-Amz-Target")
  valid_602861 = validateParameter(valid_602861, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetGroup"))
  if valid_602861 != nil:
    section.add "X-Amz-Target", valid_602861
  var valid_602862 = header.getOrDefault("X-Amz-Signature")
  valid_602862 = validateParameter(valid_602862, JString, required = false,
                                 default = nil)
  if valid_602862 != nil:
    section.add "X-Amz-Signature", valid_602862
  var valid_602863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602863 = validateParameter(valid_602863, JString, required = false,
                                 default = nil)
  if valid_602863 != nil:
    section.add "X-Amz-Content-Sha256", valid_602863
  var valid_602864 = header.getOrDefault("X-Amz-Date")
  valid_602864 = validateParameter(valid_602864, JString, required = false,
                                 default = nil)
  if valid_602864 != nil:
    section.add "X-Amz-Date", valid_602864
  var valid_602865 = header.getOrDefault("X-Amz-Credential")
  valid_602865 = validateParameter(valid_602865, JString, required = false,
                                 default = nil)
  if valid_602865 != nil:
    section.add "X-Amz-Credential", valid_602865
  var valid_602866 = header.getOrDefault("X-Amz-Security-Token")
  valid_602866 = validateParameter(valid_602866, JString, required = false,
                                 default = nil)
  if valid_602866 != nil:
    section.add "X-Amz-Security-Token", valid_602866
  var valid_602867 = header.getOrDefault("X-Amz-Algorithm")
  valid_602867 = validateParameter(valid_602867, JString, required = false,
                                 default = nil)
  if valid_602867 != nil:
    section.add "X-Amz-Algorithm", valid_602867
  var valid_602868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602868 = validateParameter(valid_602868, JString, required = false,
                                 default = nil)
  if valid_602868 != nil:
    section.add "X-Amz-SignedHeaders", valid_602868
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602870: Call_GetGroup_602858; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a group.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_602870.validator(path, query, header, formData, body)
  let scheme = call_602870.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602870.url(scheme.get, call_602870.host, call_602870.base,
                         call_602870.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602870, url, valid)

proc call*(call_602871: Call_GetGroup_602858; body: JsonNode): Recallable =
  ## getGroup
  ## <p>Gets a group.</p> <p>Calling this action requires developer credentials.</p>
  ##   body: JObject (required)
  var body_602872 = newJObject()
  if body != nil:
    body_602872 = body
  result = call_602871.call(nil, nil, nil, nil, body_602872)

var getGroup* = Call_GetGroup_602858(name: "getGroup", meth: HttpMethod.HttpPost,
                                  host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetGroup",
                                  validator: validate_GetGroup_602859, base: "/",
                                  url: url_GetGroup_602860,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIdentityProviderByIdentifier_602873 = ref object of OpenApiRestCall_601389
proc url_GetIdentityProviderByIdentifier_602875(protocol: Scheme; host: string;
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

proc validate_GetIdentityProviderByIdentifier_602874(path: JsonNode;
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
  var valid_602876 = header.getOrDefault("X-Amz-Target")
  valid_602876 = validateParameter(valid_602876, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetIdentityProviderByIdentifier"))
  if valid_602876 != nil:
    section.add "X-Amz-Target", valid_602876
  var valid_602877 = header.getOrDefault("X-Amz-Signature")
  valid_602877 = validateParameter(valid_602877, JString, required = false,
                                 default = nil)
  if valid_602877 != nil:
    section.add "X-Amz-Signature", valid_602877
  var valid_602878 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602878 = validateParameter(valid_602878, JString, required = false,
                                 default = nil)
  if valid_602878 != nil:
    section.add "X-Amz-Content-Sha256", valid_602878
  var valid_602879 = header.getOrDefault("X-Amz-Date")
  valid_602879 = validateParameter(valid_602879, JString, required = false,
                                 default = nil)
  if valid_602879 != nil:
    section.add "X-Amz-Date", valid_602879
  var valid_602880 = header.getOrDefault("X-Amz-Credential")
  valid_602880 = validateParameter(valid_602880, JString, required = false,
                                 default = nil)
  if valid_602880 != nil:
    section.add "X-Amz-Credential", valid_602880
  var valid_602881 = header.getOrDefault("X-Amz-Security-Token")
  valid_602881 = validateParameter(valid_602881, JString, required = false,
                                 default = nil)
  if valid_602881 != nil:
    section.add "X-Amz-Security-Token", valid_602881
  var valid_602882 = header.getOrDefault("X-Amz-Algorithm")
  valid_602882 = validateParameter(valid_602882, JString, required = false,
                                 default = nil)
  if valid_602882 != nil:
    section.add "X-Amz-Algorithm", valid_602882
  var valid_602883 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602883 = validateParameter(valid_602883, JString, required = false,
                                 default = nil)
  if valid_602883 != nil:
    section.add "X-Amz-SignedHeaders", valid_602883
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602885: Call_GetIdentityProviderByIdentifier_602873;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the specified identity provider.
  ## 
  let valid = call_602885.validator(path, query, header, formData, body)
  let scheme = call_602885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602885.url(scheme.get, call_602885.host, call_602885.base,
                         call_602885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602885, url, valid)

proc call*(call_602886: Call_GetIdentityProviderByIdentifier_602873; body: JsonNode): Recallable =
  ## getIdentityProviderByIdentifier
  ## Gets the specified identity provider.
  ##   body: JObject (required)
  var body_602887 = newJObject()
  if body != nil:
    body_602887 = body
  result = call_602886.call(nil, nil, nil, nil, body_602887)

var getIdentityProviderByIdentifier* = Call_GetIdentityProviderByIdentifier_602873(
    name: "getIdentityProviderByIdentifier", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetIdentityProviderByIdentifier",
    validator: validate_GetIdentityProviderByIdentifier_602874, base: "/",
    url: url_GetIdentityProviderByIdentifier_602875,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSigningCertificate_602888 = ref object of OpenApiRestCall_601389
proc url_GetSigningCertificate_602890(protocol: Scheme; host: string; base: string;
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

proc validate_GetSigningCertificate_602889(path: JsonNode; query: JsonNode;
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
  var valid_602891 = header.getOrDefault("X-Amz-Target")
  valid_602891 = validateParameter(valid_602891, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetSigningCertificate"))
  if valid_602891 != nil:
    section.add "X-Amz-Target", valid_602891
  var valid_602892 = header.getOrDefault("X-Amz-Signature")
  valid_602892 = validateParameter(valid_602892, JString, required = false,
                                 default = nil)
  if valid_602892 != nil:
    section.add "X-Amz-Signature", valid_602892
  var valid_602893 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602893 = validateParameter(valid_602893, JString, required = false,
                                 default = nil)
  if valid_602893 != nil:
    section.add "X-Amz-Content-Sha256", valid_602893
  var valid_602894 = header.getOrDefault("X-Amz-Date")
  valid_602894 = validateParameter(valid_602894, JString, required = false,
                                 default = nil)
  if valid_602894 != nil:
    section.add "X-Amz-Date", valid_602894
  var valid_602895 = header.getOrDefault("X-Amz-Credential")
  valid_602895 = validateParameter(valid_602895, JString, required = false,
                                 default = nil)
  if valid_602895 != nil:
    section.add "X-Amz-Credential", valid_602895
  var valid_602896 = header.getOrDefault("X-Amz-Security-Token")
  valid_602896 = validateParameter(valid_602896, JString, required = false,
                                 default = nil)
  if valid_602896 != nil:
    section.add "X-Amz-Security-Token", valid_602896
  var valid_602897 = header.getOrDefault("X-Amz-Algorithm")
  valid_602897 = validateParameter(valid_602897, JString, required = false,
                                 default = nil)
  if valid_602897 != nil:
    section.add "X-Amz-Algorithm", valid_602897
  var valid_602898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602898 = validateParameter(valid_602898, JString, required = false,
                                 default = nil)
  if valid_602898 != nil:
    section.add "X-Amz-SignedHeaders", valid_602898
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602900: Call_GetSigningCertificate_602888; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This method takes a user pool ID, and returns the signing certificate.
  ## 
  let valid = call_602900.validator(path, query, header, formData, body)
  let scheme = call_602900.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602900.url(scheme.get, call_602900.host, call_602900.base,
                         call_602900.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602900, url, valid)

proc call*(call_602901: Call_GetSigningCertificate_602888; body: JsonNode): Recallable =
  ## getSigningCertificate
  ## This method takes a user pool ID, and returns the signing certificate.
  ##   body: JObject (required)
  var body_602902 = newJObject()
  if body != nil:
    body_602902 = body
  result = call_602901.call(nil, nil, nil, nil, body_602902)

var getSigningCertificate* = Call_GetSigningCertificate_602888(
    name: "getSigningCertificate", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetSigningCertificate",
    validator: validate_GetSigningCertificate_602889, base: "/",
    url: url_GetSigningCertificate_602890, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUICustomization_602903 = ref object of OpenApiRestCall_601389
proc url_GetUICustomization_602905(protocol: Scheme; host: string; base: string;
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

proc validate_GetUICustomization_602904(path: JsonNode; query: JsonNode;
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
  var valid_602906 = header.getOrDefault("X-Amz-Target")
  valid_602906 = validateParameter(valid_602906, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUICustomization"))
  if valid_602906 != nil:
    section.add "X-Amz-Target", valid_602906
  var valid_602907 = header.getOrDefault("X-Amz-Signature")
  valid_602907 = validateParameter(valid_602907, JString, required = false,
                                 default = nil)
  if valid_602907 != nil:
    section.add "X-Amz-Signature", valid_602907
  var valid_602908 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602908 = validateParameter(valid_602908, JString, required = false,
                                 default = nil)
  if valid_602908 != nil:
    section.add "X-Amz-Content-Sha256", valid_602908
  var valid_602909 = header.getOrDefault("X-Amz-Date")
  valid_602909 = validateParameter(valid_602909, JString, required = false,
                                 default = nil)
  if valid_602909 != nil:
    section.add "X-Amz-Date", valid_602909
  var valid_602910 = header.getOrDefault("X-Amz-Credential")
  valid_602910 = validateParameter(valid_602910, JString, required = false,
                                 default = nil)
  if valid_602910 != nil:
    section.add "X-Amz-Credential", valid_602910
  var valid_602911 = header.getOrDefault("X-Amz-Security-Token")
  valid_602911 = validateParameter(valid_602911, JString, required = false,
                                 default = nil)
  if valid_602911 != nil:
    section.add "X-Amz-Security-Token", valid_602911
  var valid_602912 = header.getOrDefault("X-Amz-Algorithm")
  valid_602912 = validateParameter(valid_602912, JString, required = false,
                                 default = nil)
  if valid_602912 != nil:
    section.add "X-Amz-Algorithm", valid_602912
  var valid_602913 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602913 = validateParameter(valid_602913, JString, required = false,
                                 default = nil)
  if valid_602913 != nil:
    section.add "X-Amz-SignedHeaders", valid_602913
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602915: Call_GetUICustomization_602903; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the UI Customization information for a particular app client's app UI, if there is something set. If nothing is set for the particular client, but there is an existing pool level customization (app <code>clientId</code> will be <code>ALL</code>), then that is returned. If nothing is present, then an empty shape is returned.
  ## 
  let valid = call_602915.validator(path, query, header, formData, body)
  let scheme = call_602915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602915.url(scheme.get, call_602915.host, call_602915.base,
                         call_602915.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602915, url, valid)

proc call*(call_602916: Call_GetUICustomization_602903; body: JsonNode): Recallable =
  ## getUICustomization
  ## Gets the UI Customization information for a particular app client's app UI, if there is something set. If nothing is set for the particular client, but there is an existing pool level customization (app <code>clientId</code> will be <code>ALL</code>), then that is returned. If nothing is present, then an empty shape is returned.
  ##   body: JObject (required)
  var body_602917 = newJObject()
  if body != nil:
    body_602917 = body
  result = call_602916.call(nil, nil, nil, nil, body_602917)

var getUICustomization* = Call_GetUICustomization_602903(
    name: "getUICustomization", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUICustomization",
    validator: validate_GetUICustomization_602904, base: "/",
    url: url_GetUICustomization_602905, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUser_602918 = ref object of OpenApiRestCall_601389
proc url_GetUser_602920(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetUser_602919(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602921 = header.getOrDefault("X-Amz-Target")
  valid_602921 = validateParameter(valid_602921, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUser"))
  if valid_602921 != nil:
    section.add "X-Amz-Target", valid_602921
  var valid_602922 = header.getOrDefault("X-Amz-Signature")
  valid_602922 = validateParameter(valid_602922, JString, required = false,
                                 default = nil)
  if valid_602922 != nil:
    section.add "X-Amz-Signature", valid_602922
  var valid_602923 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602923 = validateParameter(valid_602923, JString, required = false,
                                 default = nil)
  if valid_602923 != nil:
    section.add "X-Amz-Content-Sha256", valid_602923
  var valid_602924 = header.getOrDefault("X-Amz-Date")
  valid_602924 = validateParameter(valid_602924, JString, required = false,
                                 default = nil)
  if valid_602924 != nil:
    section.add "X-Amz-Date", valid_602924
  var valid_602925 = header.getOrDefault("X-Amz-Credential")
  valid_602925 = validateParameter(valid_602925, JString, required = false,
                                 default = nil)
  if valid_602925 != nil:
    section.add "X-Amz-Credential", valid_602925
  var valid_602926 = header.getOrDefault("X-Amz-Security-Token")
  valid_602926 = validateParameter(valid_602926, JString, required = false,
                                 default = nil)
  if valid_602926 != nil:
    section.add "X-Amz-Security-Token", valid_602926
  var valid_602927 = header.getOrDefault("X-Amz-Algorithm")
  valid_602927 = validateParameter(valid_602927, JString, required = false,
                                 default = nil)
  if valid_602927 != nil:
    section.add "X-Amz-Algorithm", valid_602927
  var valid_602928 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602928 = validateParameter(valid_602928, JString, required = false,
                                 default = nil)
  if valid_602928 != nil:
    section.add "X-Amz-SignedHeaders", valid_602928
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602930: Call_GetUser_602918; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the user attributes and metadata for a user.
  ## 
  let valid = call_602930.validator(path, query, header, formData, body)
  let scheme = call_602930.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602930.url(scheme.get, call_602930.host, call_602930.base,
                         call_602930.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602930, url, valid)

proc call*(call_602931: Call_GetUser_602918; body: JsonNode): Recallable =
  ## getUser
  ## Gets the user attributes and metadata for a user.
  ##   body: JObject (required)
  var body_602932 = newJObject()
  if body != nil:
    body_602932 = body
  result = call_602931.call(nil, nil, nil, nil, body_602932)

var getUser* = Call_GetUser_602918(name: "getUser", meth: HttpMethod.HttpPost,
                                host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUser",
                                validator: validate_GetUser_602919, base: "/",
                                url: url_GetUser_602920,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserAttributeVerificationCode_602933 = ref object of OpenApiRestCall_601389
proc url_GetUserAttributeVerificationCode_602935(protocol: Scheme; host: string;
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

proc validate_GetUserAttributeVerificationCode_602934(path: JsonNode;
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
  var valid_602936 = header.getOrDefault("X-Amz-Target")
  valid_602936 = validateParameter(valid_602936, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUserAttributeVerificationCode"))
  if valid_602936 != nil:
    section.add "X-Amz-Target", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Signature")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Signature", valid_602937
  var valid_602938 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602938 = validateParameter(valid_602938, JString, required = false,
                                 default = nil)
  if valid_602938 != nil:
    section.add "X-Amz-Content-Sha256", valid_602938
  var valid_602939 = header.getOrDefault("X-Amz-Date")
  valid_602939 = validateParameter(valid_602939, JString, required = false,
                                 default = nil)
  if valid_602939 != nil:
    section.add "X-Amz-Date", valid_602939
  var valid_602940 = header.getOrDefault("X-Amz-Credential")
  valid_602940 = validateParameter(valid_602940, JString, required = false,
                                 default = nil)
  if valid_602940 != nil:
    section.add "X-Amz-Credential", valid_602940
  var valid_602941 = header.getOrDefault("X-Amz-Security-Token")
  valid_602941 = validateParameter(valid_602941, JString, required = false,
                                 default = nil)
  if valid_602941 != nil:
    section.add "X-Amz-Security-Token", valid_602941
  var valid_602942 = header.getOrDefault("X-Amz-Algorithm")
  valid_602942 = validateParameter(valid_602942, JString, required = false,
                                 default = nil)
  if valid_602942 != nil:
    section.add "X-Amz-Algorithm", valid_602942
  var valid_602943 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602943 = validateParameter(valid_602943, JString, required = false,
                                 default = nil)
  if valid_602943 != nil:
    section.add "X-Amz-SignedHeaders", valid_602943
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602945: Call_GetUserAttributeVerificationCode_602933;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the user attribute verification code for the specified attribute name.
  ## 
  let valid = call_602945.validator(path, query, header, formData, body)
  let scheme = call_602945.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602945.url(scheme.get, call_602945.host, call_602945.base,
                         call_602945.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602945, url, valid)

proc call*(call_602946: Call_GetUserAttributeVerificationCode_602933;
          body: JsonNode): Recallable =
  ## getUserAttributeVerificationCode
  ## Gets the user attribute verification code for the specified attribute name.
  ##   body: JObject (required)
  var body_602947 = newJObject()
  if body != nil:
    body_602947 = body
  result = call_602946.call(nil, nil, nil, nil, body_602947)

var getUserAttributeVerificationCode* = Call_GetUserAttributeVerificationCode_602933(
    name: "getUserAttributeVerificationCode", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUserAttributeVerificationCode",
    validator: validate_GetUserAttributeVerificationCode_602934, base: "/",
    url: url_GetUserAttributeVerificationCode_602935,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserPoolMfaConfig_602948 = ref object of OpenApiRestCall_601389
proc url_GetUserPoolMfaConfig_602950(protocol: Scheme; host: string; base: string;
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

proc validate_GetUserPoolMfaConfig_602949(path: JsonNode; query: JsonNode;
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
  var valid_602951 = header.getOrDefault("X-Amz-Target")
  valid_602951 = validateParameter(valid_602951, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GetUserPoolMfaConfig"))
  if valid_602951 != nil:
    section.add "X-Amz-Target", valid_602951
  var valid_602952 = header.getOrDefault("X-Amz-Signature")
  valid_602952 = validateParameter(valid_602952, JString, required = false,
                                 default = nil)
  if valid_602952 != nil:
    section.add "X-Amz-Signature", valid_602952
  var valid_602953 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602953 = validateParameter(valid_602953, JString, required = false,
                                 default = nil)
  if valid_602953 != nil:
    section.add "X-Amz-Content-Sha256", valid_602953
  var valid_602954 = header.getOrDefault("X-Amz-Date")
  valid_602954 = validateParameter(valid_602954, JString, required = false,
                                 default = nil)
  if valid_602954 != nil:
    section.add "X-Amz-Date", valid_602954
  var valid_602955 = header.getOrDefault("X-Amz-Credential")
  valid_602955 = validateParameter(valid_602955, JString, required = false,
                                 default = nil)
  if valid_602955 != nil:
    section.add "X-Amz-Credential", valid_602955
  var valid_602956 = header.getOrDefault("X-Amz-Security-Token")
  valid_602956 = validateParameter(valid_602956, JString, required = false,
                                 default = nil)
  if valid_602956 != nil:
    section.add "X-Amz-Security-Token", valid_602956
  var valid_602957 = header.getOrDefault("X-Amz-Algorithm")
  valid_602957 = validateParameter(valid_602957, JString, required = false,
                                 default = nil)
  if valid_602957 != nil:
    section.add "X-Amz-Algorithm", valid_602957
  var valid_602958 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602958 = validateParameter(valid_602958, JString, required = false,
                                 default = nil)
  if valid_602958 != nil:
    section.add "X-Amz-SignedHeaders", valid_602958
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602960: Call_GetUserPoolMfaConfig_602948; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the user pool multi-factor authentication (MFA) configuration.
  ## 
  let valid = call_602960.validator(path, query, header, formData, body)
  let scheme = call_602960.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602960.url(scheme.get, call_602960.host, call_602960.base,
                         call_602960.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602960, url, valid)

proc call*(call_602961: Call_GetUserPoolMfaConfig_602948; body: JsonNode): Recallable =
  ## getUserPoolMfaConfig
  ## Gets the user pool multi-factor authentication (MFA) configuration.
  ##   body: JObject (required)
  var body_602962 = newJObject()
  if body != nil:
    body_602962 = body
  result = call_602961.call(nil, nil, nil, nil, body_602962)

var getUserPoolMfaConfig* = Call_GetUserPoolMfaConfig_602948(
    name: "getUserPoolMfaConfig", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GetUserPoolMfaConfig",
    validator: validate_GetUserPoolMfaConfig_602949, base: "/",
    url: url_GetUserPoolMfaConfig_602950, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GlobalSignOut_602963 = ref object of OpenApiRestCall_601389
proc url_GlobalSignOut_602965(protocol: Scheme; host: string; base: string;
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

proc validate_GlobalSignOut_602964(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602966 = header.getOrDefault("X-Amz-Target")
  valid_602966 = validateParameter(valid_602966, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.GlobalSignOut"))
  if valid_602966 != nil:
    section.add "X-Amz-Target", valid_602966
  var valid_602967 = header.getOrDefault("X-Amz-Signature")
  valid_602967 = validateParameter(valid_602967, JString, required = false,
                                 default = nil)
  if valid_602967 != nil:
    section.add "X-Amz-Signature", valid_602967
  var valid_602968 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602968 = validateParameter(valid_602968, JString, required = false,
                                 default = nil)
  if valid_602968 != nil:
    section.add "X-Amz-Content-Sha256", valid_602968
  var valid_602969 = header.getOrDefault("X-Amz-Date")
  valid_602969 = validateParameter(valid_602969, JString, required = false,
                                 default = nil)
  if valid_602969 != nil:
    section.add "X-Amz-Date", valid_602969
  var valid_602970 = header.getOrDefault("X-Amz-Credential")
  valid_602970 = validateParameter(valid_602970, JString, required = false,
                                 default = nil)
  if valid_602970 != nil:
    section.add "X-Amz-Credential", valid_602970
  var valid_602971 = header.getOrDefault("X-Amz-Security-Token")
  valid_602971 = validateParameter(valid_602971, JString, required = false,
                                 default = nil)
  if valid_602971 != nil:
    section.add "X-Amz-Security-Token", valid_602971
  var valid_602972 = header.getOrDefault("X-Amz-Algorithm")
  valid_602972 = validateParameter(valid_602972, JString, required = false,
                                 default = nil)
  if valid_602972 != nil:
    section.add "X-Amz-Algorithm", valid_602972
  var valid_602973 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602973 = validateParameter(valid_602973, JString, required = false,
                                 default = nil)
  if valid_602973 != nil:
    section.add "X-Amz-SignedHeaders", valid_602973
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602975: Call_GlobalSignOut_602963; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Signs out users from all devices. It also invalidates all refresh tokens issued to a user. The user's current access and Id tokens remain valid until their expiry. Access and Id tokens expire one hour after they are issued.
  ## 
  let valid = call_602975.validator(path, query, header, formData, body)
  let scheme = call_602975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602975.url(scheme.get, call_602975.host, call_602975.base,
                         call_602975.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602975, url, valid)

proc call*(call_602976: Call_GlobalSignOut_602963; body: JsonNode): Recallable =
  ## globalSignOut
  ## Signs out users from all devices. It also invalidates all refresh tokens issued to a user. The user's current access and Id tokens remain valid until their expiry. Access and Id tokens expire one hour after they are issued.
  ##   body: JObject (required)
  var body_602977 = newJObject()
  if body != nil:
    body_602977 = body
  result = call_602976.call(nil, nil, nil, nil, body_602977)

var globalSignOut* = Call_GlobalSignOut_602963(name: "globalSignOut",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.GlobalSignOut",
    validator: validate_GlobalSignOut_602964, base: "/", url: url_GlobalSignOut_602965,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateAuth_602978 = ref object of OpenApiRestCall_601389
proc url_InitiateAuth_602980(protocol: Scheme; host: string; base: string;
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

proc validate_InitiateAuth_602979(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602981 = header.getOrDefault("X-Amz-Target")
  valid_602981 = validateParameter(valid_602981, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.InitiateAuth"))
  if valid_602981 != nil:
    section.add "X-Amz-Target", valid_602981
  var valid_602982 = header.getOrDefault("X-Amz-Signature")
  valid_602982 = validateParameter(valid_602982, JString, required = false,
                                 default = nil)
  if valid_602982 != nil:
    section.add "X-Amz-Signature", valid_602982
  var valid_602983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602983 = validateParameter(valid_602983, JString, required = false,
                                 default = nil)
  if valid_602983 != nil:
    section.add "X-Amz-Content-Sha256", valid_602983
  var valid_602984 = header.getOrDefault("X-Amz-Date")
  valid_602984 = validateParameter(valid_602984, JString, required = false,
                                 default = nil)
  if valid_602984 != nil:
    section.add "X-Amz-Date", valid_602984
  var valid_602985 = header.getOrDefault("X-Amz-Credential")
  valid_602985 = validateParameter(valid_602985, JString, required = false,
                                 default = nil)
  if valid_602985 != nil:
    section.add "X-Amz-Credential", valid_602985
  var valid_602986 = header.getOrDefault("X-Amz-Security-Token")
  valid_602986 = validateParameter(valid_602986, JString, required = false,
                                 default = nil)
  if valid_602986 != nil:
    section.add "X-Amz-Security-Token", valid_602986
  var valid_602987 = header.getOrDefault("X-Amz-Algorithm")
  valid_602987 = validateParameter(valid_602987, JString, required = false,
                                 default = nil)
  if valid_602987 != nil:
    section.add "X-Amz-Algorithm", valid_602987
  var valid_602988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602988 = validateParameter(valid_602988, JString, required = false,
                                 default = nil)
  if valid_602988 != nil:
    section.add "X-Amz-SignedHeaders", valid_602988
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602990: Call_InitiateAuth_602978; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates the authentication flow.
  ## 
  let valid = call_602990.validator(path, query, header, formData, body)
  let scheme = call_602990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602990.url(scheme.get, call_602990.host, call_602990.base,
                         call_602990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602990, url, valid)

proc call*(call_602991: Call_InitiateAuth_602978; body: JsonNode): Recallable =
  ## initiateAuth
  ## Initiates the authentication flow.
  ##   body: JObject (required)
  var body_602992 = newJObject()
  if body != nil:
    body_602992 = body
  result = call_602991.call(nil, nil, nil, nil, body_602992)

var initiateAuth* = Call_InitiateAuth_602978(name: "initiateAuth",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.InitiateAuth",
    validator: validate_InitiateAuth_602979, base: "/", url: url_InitiateAuth_602980,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevices_602993 = ref object of OpenApiRestCall_601389
proc url_ListDevices_602995(protocol: Scheme; host: string; base: string;
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

proc validate_ListDevices_602994(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602996 = header.getOrDefault("X-Amz-Target")
  valid_602996 = validateParameter(valid_602996, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListDevices"))
  if valid_602996 != nil:
    section.add "X-Amz-Target", valid_602996
  var valid_602997 = header.getOrDefault("X-Amz-Signature")
  valid_602997 = validateParameter(valid_602997, JString, required = false,
                                 default = nil)
  if valid_602997 != nil:
    section.add "X-Amz-Signature", valid_602997
  var valid_602998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602998 = validateParameter(valid_602998, JString, required = false,
                                 default = nil)
  if valid_602998 != nil:
    section.add "X-Amz-Content-Sha256", valid_602998
  var valid_602999 = header.getOrDefault("X-Amz-Date")
  valid_602999 = validateParameter(valid_602999, JString, required = false,
                                 default = nil)
  if valid_602999 != nil:
    section.add "X-Amz-Date", valid_602999
  var valid_603000 = header.getOrDefault("X-Amz-Credential")
  valid_603000 = validateParameter(valid_603000, JString, required = false,
                                 default = nil)
  if valid_603000 != nil:
    section.add "X-Amz-Credential", valid_603000
  var valid_603001 = header.getOrDefault("X-Amz-Security-Token")
  valid_603001 = validateParameter(valid_603001, JString, required = false,
                                 default = nil)
  if valid_603001 != nil:
    section.add "X-Amz-Security-Token", valid_603001
  var valid_603002 = header.getOrDefault("X-Amz-Algorithm")
  valid_603002 = validateParameter(valid_603002, JString, required = false,
                                 default = nil)
  if valid_603002 != nil:
    section.add "X-Amz-Algorithm", valid_603002
  var valid_603003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603003 = validateParameter(valid_603003, JString, required = false,
                                 default = nil)
  if valid_603003 != nil:
    section.add "X-Amz-SignedHeaders", valid_603003
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603005: Call_ListDevices_602993; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the devices.
  ## 
  let valid = call_603005.validator(path, query, header, formData, body)
  let scheme = call_603005.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603005.url(scheme.get, call_603005.host, call_603005.base,
                         call_603005.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603005, url, valid)

proc call*(call_603006: Call_ListDevices_602993; body: JsonNode): Recallable =
  ## listDevices
  ## Lists the devices.
  ##   body: JObject (required)
  var body_603007 = newJObject()
  if body != nil:
    body_603007 = body
  result = call_603006.call(nil, nil, nil, nil, body_603007)

var listDevices* = Call_ListDevices_602993(name: "listDevices",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListDevices",
                                        validator: validate_ListDevices_602994,
                                        base: "/", url: url_ListDevices_602995,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_603008 = ref object of OpenApiRestCall_601389
proc url_ListGroups_603010(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListGroups_603009(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603011 = query.getOrDefault("NextToken")
  valid_603011 = validateParameter(valid_603011, JString, required = false,
                                 default = nil)
  if valid_603011 != nil:
    section.add "NextToken", valid_603011
  var valid_603012 = query.getOrDefault("Limit")
  valid_603012 = validateParameter(valid_603012, JString, required = false,
                                 default = nil)
  if valid_603012 != nil:
    section.add "Limit", valid_603012
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
  var valid_603013 = header.getOrDefault("X-Amz-Target")
  valid_603013 = validateParameter(valid_603013, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListGroups"))
  if valid_603013 != nil:
    section.add "X-Amz-Target", valid_603013
  var valid_603014 = header.getOrDefault("X-Amz-Signature")
  valid_603014 = validateParameter(valid_603014, JString, required = false,
                                 default = nil)
  if valid_603014 != nil:
    section.add "X-Amz-Signature", valid_603014
  var valid_603015 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603015 = validateParameter(valid_603015, JString, required = false,
                                 default = nil)
  if valid_603015 != nil:
    section.add "X-Amz-Content-Sha256", valid_603015
  var valid_603016 = header.getOrDefault("X-Amz-Date")
  valid_603016 = validateParameter(valid_603016, JString, required = false,
                                 default = nil)
  if valid_603016 != nil:
    section.add "X-Amz-Date", valid_603016
  var valid_603017 = header.getOrDefault("X-Amz-Credential")
  valid_603017 = validateParameter(valid_603017, JString, required = false,
                                 default = nil)
  if valid_603017 != nil:
    section.add "X-Amz-Credential", valid_603017
  var valid_603018 = header.getOrDefault("X-Amz-Security-Token")
  valid_603018 = validateParameter(valid_603018, JString, required = false,
                                 default = nil)
  if valid_603018 != nil:
    section.add "X-Amz-Security-Token", valid_603018
  var valid_603019 = header.getOrDefault("X-Amz-Algorithm")
  valid_603019 = validateParameter(valid_603019, JString, required = false,
                                 default = nil)
  if valid_603019 != nil:
    section.add "X-Amz-Algorithm", valid_603019
  var valid_603020 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603020 = validateParameter(valid_603020, JString, required = false,
                                 default = nil)
  if valid_603020 != nil:
    section.add "X-Amz-SignedHeaders", valid_603020
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603022: Call_ListGroups_603008; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the groups associated with a user pool.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_603022.validator(path, query, header, formData, body)
  let scheme = call_603022.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603022.url(scheme.get, call_603022.host, call_603022.base,
                         call_603022.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603022, url, valid)

proc call*(call_603023: Call_ListGroups_603008; body: JsonNode;
          NextToken: string = ""; Limit: string = ""): Recallable =
  ## listGroups
  ## <p>Lists the groups associated with a user pool.</p> <p>Calling this action requires developer credentials.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_603024 = newJObject()
  var body_603025 = newJObject()
  add(query_603024, "NextToken", newJString(NextToken))
  add(query_603024, "Limit", newJString(Limit))
  if body != nil:
    body_603025 = body
  result = call_603023.call(nil, query_603024, nil, nil, body_603025)

var listGroups* = Call_ListGroups_603008(name: "listGroups",
                                      meth: HttpMethod.HttpPost,
                                      host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListGroups",
                                      validator: validate_ListGroups_603009,
                                      base: "/", url: url_ListGroups_603010,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIdentityProviders_603026 = ref object of OpenApiRestCall_601389
proc url_ListIdentityProviders_603028(protocol: Scheme; host: string; base: string;
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

proc validate_ListIdentityProviders_603027(path: JsonNode; query: JsonNode;
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
  var valid_603029 = query.getOrDefault("MaxResults")
  valid_603029 = validateParameter(valid_603029, JString, required = false,
                                 default = nil)
  if valid_603029 != nil:
    section.add "MaxResults", valid_603029
  var valid_603030 = query.getOrDefault("NextToken")
  valid_603030 = validateParameter(valid_603030, JString, required = false,
                                 default = nil)
  if valid_603030 != nil:
    section.add "NextToken", valid_603030
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
  var valid_603031 = header.getOrDefault("X-Amz-Target")
  valid_603031 = validateParameter(valid_603031, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListIdentityProviders"))
  if valid_603031 != nil:
    section.add "X-Amz-Target", valid_603031
  var valid_603032 = header.getOrDefault("X-Amz-Signature")
  valid_603032 = validateParameter(valid_603032, JString, required = false,
                                 default = nil)
  if valid_603032 != nil:
    section.add "X-Amz-Signature", valid_603032
  var valid_603033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603033 = validateParameter(valid_603033, JString, required = false,
                                 default = nil)
  if valid_603033 != nil:
    section.add "X-Amz-Content-Sha256", valid_603033
  var valid_603034 = header.getOrDefault("X-Amz-Date")
  valid_603034 = validateParameter(valid_603034, JString, required = false,
                                 default = nil)
  if valid_603034 != nil:
    section.add "X-Amz-Date", valid_603034
  var valid_603035 = header.getOrDefault("X-Amz-Credential")
  valid_603035 = validateParameter(valid_603035, JString, required = false,
                                 default = nil)
  if valid_603035 != nil:
    section.add "X-Amz-Credential", valid_603035
  var valid_603036 = header.getOrDefault("X-Amz-Security-Token")
  valid_603036 = validateParameter(valid_603036, JString, required = false,
                                 default = nil)
  if valid_603036 != nil:
    section.add "X-Amz-Security-Token", valid_603036
  var valid_603037 = header.getOrDefault("X-Amz-Algorithm")
  valid_603037 = validateParameter(valid_603037, JString, required = false,
                                 default = nil)
  if valid_603037 != nil:
    section.add "X-Amz-Algorithm", valid_603037
  var valid_603038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603038 = validateParameter(valid_603038, JString, required = false,
                                 default = nil)
  if valid_603038 != nil:
    section.add "X-Amz-SignedHeaders", valid_603038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603040: Call_ListIdentityProviders_603026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about all identity providers for a user pool.
  ## 
  let valid = call_603040.validator(path, query, header, formData, body)
  let scheme = call_603040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603040.url(scheme.get, call_603040.host, call_603040.base,
                         call_603040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603040, url, valid)

proc call*(call_603041: Call_ListIdentityProviders_603026; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listIdentityProviders
  ## Lists information about all identity providers for a user pool.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603042 = newJObject()
  var body_603043 = newJObject()
  add(query_603042, "MaxResults", newJString(MaxResults))
  add(query_603042, "NextToken", newJString(NextToken))
  if body != nil:
    body_603043 = body
  result = call_603041.call(nil, query_603042, nil, nil, body_603043)

var listIdentityProviders* = Call_ListIdentityProviders_603026(
    name: "listIdentityProviders", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListIdentityProviders",
    validator: validate_ListIdentityProviders_603027, base: "/",
    url: url_ListIdentityProviders_603028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceServers_603044 = ref object of OpenApiRestCall_601389
proc url_ListResourceServers_603046(protocol: Scheme; host: string; base: string;
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

proc validate_ListResourceServers_603045(path: JsonNode; query: JsonNode;
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
  var valid_603047 = query.getOrDefault("MaxResults")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "MaxResults", valid_603047
  var valid_603048 = query.getOrDefault("NextToken")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "NextToken", valid_603048
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
  var valid_603049 = header.getOrDefault("X-Amz-Target")
  valid_603049 = validateParameter(valid_603049, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListResourceServers"))
  if valid_603049 != nil:
    section.add "X-Amz-Target", valid_603049
  var valid_603050 = header.getOrDefault("X-Amz-Signature")
  valid_603050 = validateParameter(valid_603050, JString, required = false,
                                 default = nil)
  if valid_603050 != nil:
    section.add "X-Amz-Signature", valid_603050
  var valid_603051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "X-Amz-Content-Sha256", valid_603051
  var valid_603052 = header.getOrDefault("X-Amz-Date")
  valid_603052 = validateParameter(valid_603052, JString, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "X-Amz-Date", valid_603052
  var valid_603053 = header.getOrDefault("X-Amz-Credential")
  valid_603053 = validateParameter(valid_603053, JString, required = false,
                                 default = nil)
  if valid_603053 != nil:
    section.add "X-Amz-Credential", valid_603053
  var valid_603054 = header.getOrDefault("X-Amz-Security-Token")
  valid_603054 = validateParameter(valid_603054, JString, required = false,
                                 default = nil)
  if valid_603054 != nil:
    section.add "X-Amz-Security-Token", valid_603054
  var valid_603055 = header.getOrDefault("X-Amz-Algorithm")
  valid_603055 = validateParameter(valid_603055, JString, required = false,
                                 default = nil)
  if valid_603055 != nil:
    section.add "X-Amz-Algorithm", valid_603055
  var valid_603056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603056 = validateParameter(valid_603056, JString, required = false,
                                 default = nil)
  if valid_603056 != nil:
    section.add "X-Amz-SignedHeaders", valid_603056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603058: Call_ListResourceServers_603044; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resource servers for a user pool.
  ## 
  let valid = call_603058.validator(path, query, header, formData, body)
  let scheme = call_603058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603058.url(scheme.get, call_603058.host, call_603058.base,
                         call_603058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603058, url, valid)

proc call*(call_603059: Call_ListResourceServers_603044; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listResourceServers
  ## Lists the resource servers for a user pool.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603060 = newJObject()
  var body_603061 = newJObject()
  add(query_603060, "MaxResults", newJString(MaxResults))
  add(query_603060, "NextToken", newJString(NextToken))
  if body != nil:
    body_603061 = body
  result = call_603059.call(nil, query_603060, nil, nil, body_603061)

var listResourceServers* = Call_ListResourceServers_603044(
    name: "listResourceServers", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListResourceServers",
    validator: validate_ListResourceServers_603045, base: "/",
    url: url_ListResourceServers_603046, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_603062 = ref object of OpenApiRestCall_601389
proc url_ListTagsForResource_603064(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_603063(path: JsonNode; query: JsonNode;
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
  var valid_603065 = header.getOrDefault("X-Amz-Target")
  valid_603065 = validateParameter(valid_603065, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListTagsForResource"))
  if valid_603065 != nil:
    section.add "X-Amz-Target", valid_603065
  var valid_603066 = header.getOrDefault("X-Amz-Signature")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-Signature", valid_603066
  var valid_603067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Content-Sha256", valid_603067
  var valid_603068 = header.getOrDefault("X-Amz-Date")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-Date", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-Credential")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-Credential", valid_603069
  var valid_603070 = header.getOrDefault("X-Amz-Security-Token")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-Security-Token", valid_603070
  var valid_603071 = header.getOrDefault("X-Amz-Algorithm")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "X-Amz-Algorithm", valid_603071
  var valid_603072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-SignedHeaders", valid_603072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603074: Call_ListTagsForResource_603062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the tags that are assigned to an Amazon Cognito user pool.</p> <p>A tag is a label that you can apply to user pools to categorize and manage them in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>You can use this action up to 10 times per second, per account.</p>
  ## 
  let valid = call_603074.validator(path, query, header, formData, body)
  let scheme = call_603074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603074.url(scheme.get, call_603074.host, call_603074.base,
                         call_603074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603074, url, valid)

proc call*(call_603075: Call_ListTagsForResource_603062; body: JsonNode): Recallable =
  ## listTagsForResource
  ## <p>Lists the tags that are assigned to an Amazon Cognito user pool.</p> <p>A tag is a label that you can apply to user pools to categorize and manage them in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>You can use this action up to 10 times per second, per account.</p>
  ##   body: JObject (required)
  var body_603076 = newJObject()
  if body != nil:
    body_603076 = body
  result = call_603075.call(nil, nil, nil, nil, body_603076)

var listTagsForResource* = Call_ListTagsForResource_603062(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListTagsForResource",
    validator: validate_ListTagsForResource_603063, base: "/",
    url: url_ListTagsForResource_603064, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserImportJobs_603077 = ref object of OpenApiRestCall_601389
proc url_ListUserImportJobs_603079(protocol: Scheme; host: string; base: string;
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

proc validate_ListUserImportJobs_603078(path: JsonNode; query: JsonNode;
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
  var valid_603080 = header.getOrDefault("X-Amz-Target")
  valid_603080 = validateParameter(valid_603080, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUserImportJobs"))
  if valid_603080 != nil:
    section.add "X-Amz-Target", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-Signature")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Signature", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Content-Sha256", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Date")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Date", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-Credential")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Credential", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-Security-Token")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Security-Token", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-Algorithm")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-Algorithm", valid_603086
  var valid_603087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-SignedHeaders", valid_603087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603089: Call_ListUserImportJobs_603077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the user import jobs.
  ## 
  let valid = call_603089.validator(path, query, header, formData, body)
  let scheme = call_603089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603089.url(scheme.get, call_603089.host, call_603089.base,
                         call_603089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603089, url, valid)

proc call*(call_603090: Call_ListUserImportJobs_603077; body: JsonNode): Recallable =
  ## listUserImportJobs
  ## Lists the user import jobs.
  ##   body: JObject (required)
  var body_603091 = newJObject()
  if body != nil:
    body_603091 = body
  result = call_603090.call(nil, nil, nil, nil, body_603091)

var listUserImportJobs* = Call_ListUserImportJobs_603077(
    name: "listUserImportJobs", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUserImportJobs",
    validator: validate_ListUserImportJobs_603078, base: "/",
    url: url_ListUserImportJobs_603079, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserPoolClients_603092 = ref object of OpenApiRestCall_601389
proc url_ListUserPoolClients_603094(protocol: Scheme; host: string; base: string;
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

proc validate_ListUserPoolClients_603093(path: JsonNode; query: JsonNode;
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
  var valid_603095 = query.getOrDefault("MaxResults")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "MaxResults", valid_603095
  var valid_603096 = query.getOrDefault("NextToken")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "NextToken", valid_603096
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
  var valid_603097 = header.getOrDefault("X-Amz-Target")
  valid_603097 = validateParameter(valid_603097, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUserPoolClients"))
  if valid_603097 != nil:
    section.add "X-Amz-Target", valid_603097
  var valid_603098 = header.getOrDefault("X-Amz-Signature")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-Signature", valid_603098
  var valid_603099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-Content-Sha256", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-Date")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Date", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-Credential")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-Credential", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Security-Token")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Security-Token", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Algorithm")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Algorithm", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-SignedHeaders", valid_603104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603106: Call_ListUserPoolClients_603092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the clients that have been created for the specified user pool.
  ## 
  let valid = call_603106.validator(path, query, header, formData, body)
  let scheme = call_603106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603106.url(scheme.get, call_603106.host, call_603106.base,
                         call_603106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603106, url, valid)

proc call*(call_603107: Call_ListUserPoolClients_603092; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listUserPoolClients
  ## Lists the clients that have been created for the specified user pool.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603108 = newJObject()
  var body_603109 = newJObject()
  add(query_603108, "MaxResults", newJString(MaxResults))
  add(query_603108, "NextToken", newJString(NextToken))
  if body != nil:
    body_603109 = body
  result = call_603107.call(nil, query_603108, nil, nil, body_603109)

var listUserPoolClients* = Call_ListUserPoolClients_603092(
    name: "listUserPoolClients", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUserPoolClients",
    validator: validate_ListUserPoolClients_603093, base: "/",
    url: url_ListUserPoolClients_603094, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserPools_603110 = ref object of OpenApiRestCall_601389
proc url_ListUserPools_603112(protocol: Scheme; host: string; base: string;
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

proc validate_ListUserPools_603111(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603113 = query.getOrDefault("MaxResults")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "MaxResults", valid_603113
  var valid_603114 = query.getOrDefault("NextToken")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "NextToken", valid_603114
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
  var valid_603115 = header.getOrDefault("X-Amz-Target")
  valid_603115 = validateParameter(valid_603115, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUserPools"))
  if valid_603115 != nil:
    section.add "X-Amz-Target", valid_603115
  var valid_603116 = header.getOrDefault("X-Amz-Signature")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-Signature", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Content-Sha256", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Date")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Date", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-Credential")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Credential", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-Security-Token")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Security-Token", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Algorithm")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Algorithm", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-SignedHeaders", valid_603122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603124: Call_ListUserPools_603110; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the user pools associated with an AWS account.
  ## 
  let valid = call_603124.validator(path, query, header, formData, body)
  let scheme = call_603124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603124.url(scheme.get, call_603124.host, call_603124.base,
                         call_603124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603124, url, valid)

proc call*(call_603125: Call_ListUserPools_603110; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listUserPools
  ## Lists the user pools associated with an AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603126 = newJObject()
  var body_603127 = newJObject()
  add(query_603126, "MaxResults", newJString(MaxResults))
  add(query_603126, "NextToken", newJString(NextToken))
  if body != nil:
    body_603127 = body
  result = call_603125.call(nil, query_603126, nil, nil, body_603127)

var listUserPools* = Call_ListUserPools_603110(name: "listUserPools",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUserPools",
    validator: validate_ListUserPools_603111, base: "/", url: url_ListUserPools_603112,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_603128 = ref object of OpenApiRestCall_601389
proc url_ListUsers_603130(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListUsers_603129(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603131 = query.getOrDefault("Limit")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "Limit", valid_603131
  var valid_603132 = query.getOrDefault("PaginationToken")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "PaginationToken", valid_603132
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
  var valid_603133 = header.getOrDefault("X-Amz-Target")
  valid_603133 = validateParameter(valid_603133, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUsers"))
  if valid_603133 != nil:
    section.add "X-Amz-Target", valid_603133
  var valid_603134 = header.getOrDefault("X-Amz-Signature")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "X-Amz-Signature", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Content-Sha256", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Date")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Date", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Credential")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Credential", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Security-Token")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Security-Token", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Algorithm")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Algorithm", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-SignedHeaders", valid_603140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603142: Call_ListUsers_603128; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the users in the Amazon Cognito user pool.
  ## 
  let valid = call_603142.validator(path, query, header, formData, body)
  let scheme = call_603142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603142.url(scheme.get, call_603142.host, call_603142.base,
                         call_603142.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603142, url, valid)

proc call*(call_603143: Call_ListUsers_603128; body: JsonNode; Limit: string = "";
          PaginationToken: string = ""): Recallable =
  ## listUsers
  ## Lists the users in the Amazon Cognito user pool.
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  ##   PaginationToken: string
  ##                  : Pagination token
  var query_603144 = newJObject()
  var body_603145 = newJObject()
  add(query_603144, "Limit", newJString(Limit))
  if body != nil:
    body_603145 = body
  add(query_603144, "PaginationToken", newJString(PaginationToken))
  result = call_603143.call(nil, query_603144, nil, nil, body_603145)

var listUsers* = Call_ListUsers_603128(name: "listUsers", meth: HttpMethod.HttpPost,
                                    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUsers",
                                    validator: validate_ListUsers_603129,
                                    base: "/", url: url_ListUsers_603130,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsersInGroup_603146 = ref object of OpenApiRestCall_601389
proc url_ListUsersInGroup_603148(protocol: Scheme; host: string; base: string;
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

proc validate_ListUsersInGroup_603147(path: JsonNode; query: JsonNode;
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
  var valid_603149 = query.getOrDefault("NextToken")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "NextToken", valid_603149
  var valid_603150 = query.getOrDefault("Limit")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "Limit", valid_603150
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
  var valid_603151 = header.getOrDefault("X-Amz-Target")
  valid_603151 = validateParameter(valid_603151, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ListUsersInGroup"))
  if valid_603151 != nil:
    section.add "X-Amz-Target", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Signature")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Signature", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Content-Sha256", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Date")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Date", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Credential")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Credential", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-Security-Token")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Security-Token", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Algorithm")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Algorithm", valid_603157
  var valid_603158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "X-Amz-SignedHeaders", valid_603158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603160: Call_ListUsersInGroup_603146; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the users in the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ## 
  let valid = call_603160.validator(path, query, header, formData, body)
  let scheme = call_603160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603160.url(scheme.get, call_603160.host, call_603160.base,
                         call_603160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603160, url, valid)

proc call*(call_603161: Call_ListUsersInGroup_603146; body: JsonNode;
          NextToken: string = ""; Limit: string = ""): Recallable =
  ## listUsersInGroup
  ## <p>Lists the users in the specified group.</p> <p>Calling this action requires developer credentials.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_603162 = newJObject()
  var body_603163 = newJObject()
  add(query_603162, "NextToken", newJString(NextToken))
  add(query_603162, "Limit", newJString(Limit))
  if body != nil:
    body_603163 = body
  result = call_603161.call(nil, query_603162, nil, nil, body_603163)

var listUsersInGroup* = Call_ListUsersInGroup_603146(name: "listUsersInGroup",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ListUsersInGroup",
    validator: validate_ListUsersInGroup_603147, base: "/",
    url: url_ListUsersInGroup_603148, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResendConfirmationCode_603164 = ref object of OpenApiRestCall_601389
proc url_ResendConfirmationCode_603166(protocol: Scheme; host: string; base: string;
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

proc validate_ResendConfirmationCode_603165(path: JsonNode; query: JsonNode;
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
  var valid_603167 = header.getOrDefault("X-Amz-Target")
  valid_603167 = validateParameter(valid_603167, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.ResendConfirmationCode"))
  if valid_603167 != nil:
    section.add "X-Amz-Target", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-Signature")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Signature", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Content-Sha256", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Date")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Date", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-Credential")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-Credential", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Security-Token")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Security-Token", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-Algorithm")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Algorithm", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-SignedHeaders", valid_603174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603176: Call_ResendConfirmationCode_603164; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resends the confirmation (for confirmation of registration) to a specific user in the user pool.
  ## 
  let valid = call_603176.validator(path, query, header, formData, body)
  let scheme = call_603176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603176.url(scheme.get, call_603176.host, call_603176.base,
                         call_603176.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603176, url, valid)

proc call*(call_603177: Call_ResendConfirmationCode_603164; body: JsonNode): Recallable =
  ## resendConfirmationCode
  ## Resends the confirmation (for confirmation of registration) to a specific user in the user pool.
  ##   body: JObject (required)
  var body_603178 = newJObject()
  if body != nil:
    body_603178 = body
  result = call_603177.call(nil, nil, nil, nil, body_603178)

var resendConfirmationCode* = Call_ResendConfirmationCode_603164(
    name: "resendConfirmationCode", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.ResendConfirmationCode",
    validator: validate_ResendConfirmationCode_603165, base: "/",
    url: url_ResendConfirmationCode_603166, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RespondToAuthChallenge_603179 = ref object of OpenApiRestCall_601389
proc url_RespondToAuthChallenge_603181(protocol: Scheme; host: string; base: string;
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

proc validate_RespondToAuthChallenge_603180(path: JsonNode; query: JsonNode;
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
  var valid_603182 = header.getOrDefault("X-Amz-Target")
  valid_603182 = validateParameter(valid_603182, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.RespondToAuthChallenge"))
  if valid_603182 != nil:
    section.add "X-Amz-Target", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Signature")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Signature", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Content-Sha256", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Date")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Date", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-Credential")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-Credential", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Security-Token")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Security-Token", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Algorithm")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Algorithm", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-SignedHeaders", valid_603189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603191: Call_RespondToAuthChallenge_603179; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Responds to the authentication challenge.
  ## 
  let valid = call_603191.validator(path, query, header, formData, body)
  let scheme = call_603191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603191.url(scheme.get, call_603191.host, call_603191.base,
                         call_603191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603191, url, valid)

proc call*(call_603192: Call_RespondToAuthChallenge_603179; body: JsonNode): Recallable =
  ## respondToAuthChallenge
  ## Responds to the authentication challenge.
  ##   body: JObject (required)
  var body_603193 = newJObject()
  if body != nil:
    body_603193 = body
  result = call_603192.call(nil, nil, nil, nil, body_603193)

var respondToAuthChallenge* = Call_RespondToAuthChallenge_603179(
    name: "respondToAuthChallenge", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.RespondToAuthChallenge",
    validator: validate_RespondToAuthChallenge_603180, base: "/",
    url: url_RespondToAuthChallenge_603181, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetRiskConfiguration_603194 = ref object of OpenApiRestCall_601389
proc url_SetRiskConfiguration_603196(protocol: Scheme; host: string; base: string;
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

proc validate_SetRiskConfiguration_603195(path: JsonNode; query: JsonNode;
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
  var valid_603197 = header.getOrDefault("X-Amz-Target")
  valid_603197 = validateParameter(valid_603197, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetRiskConfiguration"))
  if valid_603197 != nil:
    section.add "X-Amz-Target", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Signature")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Signature", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Content-Sha256", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Date")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Date", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-Credential")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Credential", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Security-Token")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Security-Token", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Algorithm")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Algorithm", valid_603203
  var valid_603204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-SignedHeaders", valid_603204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603206: Call_SetRiskConfiguration_603194; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configures actions on detected risks. To delete the risk configuration for <code>UserPoolId</code> or <code>ClientId</code>, pass null values for all four configuration types.</p> <p>To enable Amazon Cognito advanced security features, update the user pool to include the <code>UserPoolAddOns</code> key<code>AdvancedSecurityMode</code>.</p> <p>See .</p>
  ## 
  let valid = call_603206.validator(path, query, header, formData, body)
  let scheme = call_603206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603206.url(scheme.get, call_603206.host, call_603206.base,
                         call_603206.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603206, url, valid)

proc call*(call_603207: Call_SetRiskConfiguration_603194; body: JsonNode): Recallable =
  ## setRiskConfiguration
  ## <p>Configures actions on detected risks. To delete the risk configuration for <code>UserPoolId</code> or <code>ClientId</code>, pass null values for all four configuration types.</p> <p>To enable Amazon Cognito advanced security features, update the user pool to include the <code>UserPoolAddOns</code> key<code>AdvancedSecurityMode</code>.</p> <p>See .</p>
  ##   body: JObject (required)
  var body_603208 = newJObject()
  if body != nil:
    body_603208 = body
  result = call_603207.call(nil, nil, nil, nil, body_603208)

var setRiskConfiguration* = Call_SetRiskConfiguration_603194(
    name: "setRiskConfiguration", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetRiskConfiguration",
    validator: validate_SetRiskConfiguration_603195, base: "/",
    url: url_SetRiskConfiguration_603196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUICustomization_603209 = ref object of OpenApiRestCall_601389
proc url_SetUICustomization_603211(protocol: Scheme; host: string; base: string;
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

proc validate_SetUICustomization_603210(path: JsonNode; query: JsonNode;
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
  var valid_603212 = header.getOrDefault("X-Amz-Target")
  valid_603212 = validateParameter(valid_603212, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUICustomization"))
  if valid_603212 != nil:
    section.add "X-Amz-Target", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-Signature")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-Signature", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Content-Sha256", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Date")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Date", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-Credential")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-Credential", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Security-Token")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Security-Token", valid_603217
  var valid_603218 = header.getOrDefault("X-Amz-Algorithm")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Algorithm", valid_603218
  var valid_603219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-SignedHeaders", valid_603219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603221: Call_SetUICustomization_603209; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the UI customization information for a user pool's built-in app UI.</p> <p>You can specify app UI customization settings for a single client (with a specific <code>clientId</code>) or for all clients (by setting the <code>clientId</code> to <code>ALL</code>). If you specify <code>ALL</code>, the default configuration will be used for every client that has no UI customization set previously. If you specify UI customization settings for a particular client, it will no longer fall back to the <code>ALL</code> configuration. </p> <note> <p>To use this API, your user pool must have a domain associated with it. Otherwise, there is no place to host the app's pages, and the service will throw an error.</p> </note>
  ## 
  let valid = call_603221.validator(path, query, header, formData, body)
  let scheme = call_603221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603221.url(scheme.get, call_603221.host, call_603221.base,
                         call_603221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603221, url, valid)

proc call*(call_603222: Call_SetUICustomization_603209; body: JsonNode): Recallable =
  ## setUICustomization
  ## <p>Sets the UI customization information for a user pool's built-in app UI.</p> <p>You can specify app UI customization settings for a single client (with a specific <code>clientId</code>) or for all clients (by setting the <code>clientId</code> to <code>ALL</code>). If you specify <code>ALL</code>, the default configuration will be used for every client that has no UI customization set previously. If you specify UI customization settings for a particular client, it will no longer fall back to the <code>ALL</code> configuration. </p> <note> <p>To use this API, your user pool must have a domain associated with it. Otherwise, there is no place to host the app's pages, and the service will throw an error.</p> </note>
  ##   body: JObject (required)
  var body_603223 = newJObject()
  if body != nil:
    body_603223 = body
  result = call_603222.call(nil, nil, nil, nil, body_603223)

var setUICustomization* = Call_SetUICustomization_603209(
    name: "setUICustomization", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUICustomization",
    validator: validate_SetUICustomization_603210, base: "/",
    url: url_SetUICustomization_603211, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUserMFAPreference_603224 = ref object of OpenApiRestCall_601389
proc url_SetUserMFAPreference_603226(protocol: Scheme; host: string; base: string;
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

proc validate_SetUserMFAPreference_603225(path: JsonNode; query: JsonNode;
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
  var valid_603227 = header.getOrDefault("X-Amz-Target")
  valid_603227 = validateParameter(valid_603227, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUserMFAPreference"))
  if valid_603227 != nil:
    section.add "X-Amz-Target", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Signature")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Signature", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Content-Sha256", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Date")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Date", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-Credential")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-Credential", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Security-Token")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Security-Token", valid_603232
  var valid_603233 = header.getOrDefault("X-Amz-Algorithm")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "X-Amz-Algorithm", valid_603233
  var valid_603234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "X-Amz-SignedHeaders", valid_603234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603236: Call_SetUserMFAPreference_603224; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the user's multi-factor authentication (MFA) method preference, including which MFA factors are enabled and if any are preferred. Only one factor can be set as preferred. The preferred MFA factor will be used to authenticate a user if multiple factors are enabled. If multiple options are enabled and no preference is set, a challenge to choose an MFA option will be returned during sign in.
  ## 
  let valid = call_603236.validator(path, query, header, formData, body)
  let scheme = call_603236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603236.url(scheme.get, call_603236.host, call_603236.base,
                         call_603236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603236, url, valid)

proc call*(call_603237: Call_SetUserMFAPreference_603224; body: JsonNode): Recallable =
  ## setUserMFAPreference
  ## Set the user's multi-factor authentication (MFA) method preference, including which MFA factors are enabled and if any are preferred. Only one factor can be set as preferred. The preferred MFA factor will be used to authenticate a user if multiple factors are enabled. If multiple options are enabled and no preference is set, a challenge to choose an MFA option will be returned during sign in.
  ##   body: JObject (required)
  var body_603238 = newJObject()
  if body != nil:
    body_603238 = body
  result = call_603237.call(nil, nil, nil, nil, body_603238)

var setUserMFAPreference* = Call_SetUserMFAPreference_603224(
    name: "setUserMFAPreference", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUserMFAPreference",
    validator: validate_SetUserMFAPreference_603225, base: "/",
    url: url_SetUserMFAPreference_603226, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUserPoolMfaConfig_603239 = ref object of OpenApiRestCall_601389
proc url_SetUserPoolMfaConfig_603241(protocol: Scheme; host: string; base: string;
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

proc validate_SetUserPoolMfaConfig_603240(path: JsonNode; query: JsonNode;
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
  var valid_603242 = header.getOrDefault("X-Amz-Target")
  valid_603242 = validateParameter(valid_603242, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUserPoolMfaConfig"))
  if valid_603242 != nil:
    section.add "X-Amz-Target", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Signature")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Signature", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Content-Sha256", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Date")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Date", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-Credential")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-Credential", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Security-Token")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Security-Token", valid_603247
  var valid_603248 = header.getOrDefault("X-Amz-Algorithm")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-Algorithm", valid_603248
  var valid_603249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "X-Amz-SignedHeaders", valid_603249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603251: Call_SetUserPoolMfaConfig_603239; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the user pool multi-factor authentication (MFA) configuration.
  ## 
  let valid = call_603251.validator(path, query, header, formData, body)
  let scheme = call_603251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603251.url(scheme.get, call_603251.host, call_603251.base,
                         call_603251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603251, url, valid)

proc call*(call_603252: Call_SetUserPoolMfaConfig_603239; body: JsonNode): Recallable =
  ## setUserPoolMfaConfig
  ## Set the user pool multi-factor authentication (MFA) configuration.
  ##   body: JObject (required)
  var body_603253 = newJObject()
  if body != nil:
    body_603253 = body
  result = call_603252.call(nil, nil, nil, nil, body_603253)

var setUserPoolMfaConfig* = Call_SetUserPoolMfaConfig_603239(
    name: "setUserPoolMfaConfig", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUserPoolMfaConfig",
    validator: validate_SetUserPoolMfaConfig_603240, base: "/",
    url: url_SetUserPoolMfaConfig_603241, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetUserSettings_603254 = ref object of OpenApiRestCall_601389
proc url_SetUserSettings_603256(protocol: Scheme; host: string; base: string;
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

proc validate_SetUserSettings_603255(path: JsonNode; query: JsonNode;
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
  var valid_603257 = header.getOrDefault("X-Amz-Target")
  valid_603257 = validateParameter(valid_603257, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SetUserSettings"))
  if valid_603257 != nil:
    section.add "X-Amz-Target", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Signature")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Signature", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Content-Sha256", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Date")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Date", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-Credential")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-Credential", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Security-Token")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Security-Token", valid_603262
  var valid_603263 = header.getOrDefault("X-Amz-Algorithm")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "X-Amz-Algorithm", valid_603263
  var valid_603264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-SignedHeaders", valid_603264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603266: Call_SetUserSettings_603254; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <i>This action is no longer supported.</i> You can use it to configure only SMS MFA. You can't use it to configure TOTP software token MFA. To configure either type of MFA, use the <a>SetUserMFAPreference</a> action instead.
  ## 
  let valid = call_603266.validator(path, query, header, formData, body)
  let scheme = call_603266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603266.url(scheme.get, call_603266.host, call_603266.base,
                         call_603266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603266, url, valid)

proc call*(call_603267: Call_SetUserSettings_603254; body: JsonNode): Recallable =
  ## setUserSettings
  ##  <i>This action is no longer supported.</i> You can use it to configure only SMS MFA. You can't use it to configure TOTP software token MFA. To configure either type of MFA, use the <a>SetUserMFAPreference</a> action instead.
  ##   body: JObject (required)
  var body_603268 = newJObject()
  if body != nil:
    body_603268 = body
  result = call_603267.call(nil, nil, nil, nil, body_603268)

var setUserSettings* = Call_SetUserSettings_603254(name: "setUserSettings",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SetUserSettings",
    validator: validate_SetUserSettings_603255, base: "/", url: url_SetUserSettings_603256,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SignUp_603269 = ref object of OpenApiRestCall_601389
proc url_SignUp_603271(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_SignUp_603270(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603272 = header.getOrDefault("X-Amz-Target")
  valid_603272 = validateParameter(valid_603272, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.SignUp"))
  if valid_603272 != nil:
    section.add "X-Amz-Target", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-Signature")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Signature", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Content-Sha256", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Date")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Date", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-Credential")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-Credential", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Security-Token")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Security-Token", valid_603277
  var valid_603278 = header.getOrDefault("X-Amz-Algorithm")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-Algorithm", valid_603278
  var valid_603279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-SignedHeaders", valid_603279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603281: Call_SignUp_603269; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers the user in the specified user pool and creates a user name, password, and user attributes.
  ## 
  let valid = call_603281.validator(path, query, header, formData, body)
  let scheme = call_603281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603281.url(scheme.get, call_603281.host, call_603281.base,
                         call_603281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603281, url, valid)

proc call*(call_603282: Call_SignUp_603269; body: JsonNode): Recallable =
  ## signUp
  ## Registers the user in the specified user pool and creates a user name, password, and user attributes.
  ##   body: JObject (required)
  var body_603283 = newJObject()
  if body != nil:
    body_603283 = body
  result = call_603282.call(nil, nil, nil, nil, body_603283)

var signUp* = Call_SignUp_603269(name: "signUp", meth: HttpMethod.HttpPost,
                              host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.SignUp",
                              validator: validate_SignUp_603270, base: "/",
                              url: url_SignUp_603271,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartUserImportJob_603284 = ref object of OpenApiRestCall_601389
proc url_StartUserImportJob_603286(protocol: Scheme; host: string; base: string;
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

proc validate_StartUserImportJob_603285(path: JsonNode; query: JsonNode;
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
  var valid_603287 = header.getOrDefault("X-Amz-Target")
  valid_603287 = validateParameter(valid_603287, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.StartUserImportJob"))
  if valid_603287 != nil:
    section.add "X-Amz-Target", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Signature")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Signature", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Content-Sha256", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Date")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Date", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-Credential")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-Credential", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Security-Token")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Security-Token", valid_603292
  var valid_603293 = header.getOrDefault("X-Amz-Algorithm")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-Algorithm", valid_603293
  var valid_603294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-SignedHeaders", valid_603294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603296: Call_StartUserImportJob_603284; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the user import.
  ## 
  let valid = call_603296.validator(path, query, header, formData, body)
  let scheme = call_603296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603296.url(scheme.get, call_603296.host, call_603296.base,
                         call_603296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603296, url, valid)

proc call*(call_603297: Call_StartUserImportJob_603284; body: JsonNode): Recallable =
  ## startUserImportJob
  ## Starts the user import.
  ##   body: JObject (required)
  var body_603298 = newJObject()
  if body != nil:
    body_603298 = body
  result = call_603297.call(nil, nil, nil, nil, body_603298)

var startUserImportJob* = Call_StartUserImportJob_603284(
    name: "startUserImportJob", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.StartUserImportJob",
    validator: validate_StartUserImportJob_603285, base: "/",
    url: url_StartUserImportJob_603286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopUserImportJob_603299 = ref object of OpenApiRestCall_601389
proc url_StopUserImportJob_603301(protocol: Scheme; host: string; base: string;
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

proc validate_StopUserImportJob_603300(path: JsonNode; query: JsonNode;
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
  var valid_603302 = header.getOrDefault("X-Amz-Target")
  valid_603302 = validateParameter(valid_603302, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.StopUserImportJob"))
  if valid_603302 != nil:
    section.add "X-Amz-Target", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-Signature")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Signature", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Content-Sha256", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Date")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Date", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-Credential")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-Credential", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-Security-Token")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Security-Token", valid_603307
  var valid_603308 = header.getOrDefault("X-Amz-Algorithm")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "X-Amz-Algorithm", valid_603308
  var valid_603309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603309 = validateParameter(valid_603309, JString, required = false,
                                 default = nil)
  if valid_603309 != nil:
    section.add "X-Amz-SignedHeaders", valid_603309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603311: Call_StopUserImportJob_603299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the user import job.
  ## 
  let valid = call_603311.validator(path, query, header, formData, body)
  let scheme = call_603311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603311.url(scheme.get, call_603311.host, call_603311.base,
                         call_603311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603311, url, valid)

proc call*(call_603312: Call_StopUserImportJob_603299; body: JsonNode): Recallable =
  ## stopUserImportJob
  ## Stops the user import job.
  ##   body: JObject (required)
  var body_603313 = newJObject()
  if body != nil:
    body_603313 = body
  result = call_603312.call(nil, nil, nil, nil, body_603313)

var stopUserImportJob* = Call_StopUserImportJob_603299(name: "stopUserImportJob",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.StopUserImportJob",
    validator: validate_StopUserImportJob_603300, base: "/",
    url: url_StopUserImportJob_603301, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603314 = ref object of OpenApiRestCall_601389
proc url_TagResource_603316(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_603315(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603317 = header.getOrDefault("X-Amz-Target")
  valid_603317 = validateParameter(valid_603317, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.TagResource"))
  if valid_603317 != nil:
    section.add "X-Amz-Target", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-Signature")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Signature", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Content-Sha256", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Date")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Date", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-Credential")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-Credential", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Security-Token")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Security-Token", valid_603322
  var valid_603323 = header.getOrDefault("X-Amz-Algorithm")
  valid_603323 = validateParameter(valid_603323, JString, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "X-Amz-Algorithm", valid_603323
  var valid_603324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603324 = validateParameter(valid_603324, JString, required = false,
                                 default = nil)
  if valid_603324 != nil:
    section.add "X-Amz-SignedHeaders", valid_603324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603326: Call_TagResource_603314; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns a set of tags to an Amazon Cognito user pool. A tag is a label that you can use to categorize and manage user pools in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>Each tag consists of a key and value, both of which you define. A key is a general category for more specific values. For example, if you have two versions of a user pool, one for testing and another for production, you might assign an <code>Environment</code> tag key to both user pools. The value of this key might be <code>Test</code> for one user pool and <code>Production</code> for the other.</p> <p>Tags are useful for cost tracking and access control. You can activate your tags so that they appear on the Billing and Cost Management console, where you can track the costs associated with your user pools. In an IAM policy, you can constrain permissions for user pools based on specific tags or tag values.</p> <p>You can use this action up to 5 times per second, per account. A user pool can have as many as 50 tags.</p>
  ## 
  let valid = call_603326.validator(path, query, header, formData, body)
  let scheme = call_603326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603326.url(scheme.get, call_603326.host, call_603326.base,
                         call_603326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603326, url, valid)

proc call*(call_603327: Call_TagResource_603314; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Assigns a set of tags to an Amazon Cognito user pool. A tag is a label that you can use to categorize and manage user pools in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>Each tag consists of a key and value, both of which you define. A key is a general category for more specific values. For example, if you have two versions of a user pool, one for testing and another for production, you might assign an <code>Environment</code> tag key to both user pools. The value of this key might be <code>Test</code> for one user pool and <code>Production</code> for the other.</p> <p>Tags are useful for cost tracking and access control. You can activate your tags so that they appear on the Billing and Cost Management console, where you can track the costs associated with your user pools. In an IAM policy, you can constrain permissions for user pools based on specific tags or tag values.</p> <p>You can use this action up to 5 times per second, per account. A user pool can have as many as 50 tags.</p>
  ##   body: JObject (required)
  var body_603328 = newJObject()
  if body != nil:
    body_603328 = body
  result = call_603327.call(nil, nil, nil, nil, body_603328)

var tagResource* = Call_TagResource_603314(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.TagResource",
                                        validator: validate_TagResource_603315,
                                        base: "/", url: url_TagResource_603316,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603329 = ref object of OpenApiRestCall_601389
proc url_UntagResource_603331(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_603330(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603332 = header.getOrDefault("X-Amz-Target")
  valid_603332 = validateParameter(valid_603332, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UntagResource"))
  if valid_603332 != nil:
    section.add "X-Amz-Target", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-Signature")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Signature", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Content-Sha256", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Date")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Date", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-Credential")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-Credential", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Security-Token")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Security-Token", valid_603337
  var valid_603338 = header.getOrDefault("X-Amz-Algorithm")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "X-Amz-Algorithm", valid_603338
  var valid_603339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "X-Amz-SignedHeaders", valid_603339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603341: Call_UntagResource_603329; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified tags from an Amazon Cognito user pool. You can use this action up to 5 times per second, per account
  ## 
  let valid = call_603341.validator(path, query, header, formData, body)
  let scheme = call_603341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603341.url(scheme.get, call_603341.host, call_603341.base,
                         call_603341.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603341, url, valid)

proc call*(call_603342: Call_UntagResource_603329; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tags from an Amazon Cognito user pool. You can use this action up to 5 times per second, per account
  ##   body: JObject (required)
  var body_603343 = newJObject()
  if body != nil:
    body_603343 = body
  result = call_603342.call(nil, nil, nil, nil, body_603343)

var untagResource* = Call_UntagResource_603329(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UntagResource",
    validator: validate_UntagResource_603330, base: "/", url: url_UntagResource_603331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthEventFeedback_603344 = ref object of OpenApiRestCall_601389
proc url_UpdateAuthEventFeedback_603346(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAuthEventFeedback_603345(path: JsonNode; query: JsonNode;
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
  var valid_603347 = header.getOrDefault("X-Amz-Target")
  valid_603347 = validateParameter(valid_603347, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateAuthEventFeedback"))
  if valid_603347 != nil:
    section.add "X-Amz-Target", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-Signature")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-Signature", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Content-Sha256", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Date")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Date", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-Credential")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-Credential", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Security-Token")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Security-Token", valid_603352
  var valid_603353 = header.getOrDefault("X-Amz-Algorithm")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "X-Amz-Algorithm", valid_603353
  var valid_603354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "X-Amz-SignedHeaders", valid_603354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603356: Call_UpdateAuthEventFeedback_603344; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the feedback for an authentication event whether it was from a valid user or not. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ## 
  let valid = call_603356.validator(path, query, header, formData, body)
  let scheme = call_603356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603356.url(scheme.get, call_603356.host, call_603356.base,
                         call_603356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603356, url, valid)

proc call*(call_603357: Call_UpdateAuthEventFeedback_603344; body: JsonNode): Recallable =
  ## updateAuthEventFeedback
  ## Provides the feedback for an authentication event whether it was from a valid user or not. This feedback is used for improving the risk evaluation decision for the user pool as part of Amazon Cognito advanced security.
  ##   body: JObject (required)
  var body_603358 = newJObject()
  if body != nil:
    body_603358 = body
  result = call_603357.call(nil, nil, nil, nil, body_603358)

var updateAuthEventFeedback* = Call_UpdateAuthEventFeedback_603344(
    name: "updateAuthEventFeedback", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateAuthEventFeedback",
    validator: validate_UpdateAuthEventFeedback_603345, base: "/",
    url: url_UpdateAuthEventFeedback_603346, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceStatus_603359 = ref object of OpenApiRestCall_601389
proc url_UpdateDeviceStatus_603361(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDeviceStatus_603360(path: JsonNode; query: JsonNode;
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
  var valid_603362 = header.getOrDefault("X-Amz-Target")
  valid_603362 = validateParameter(valid_603362, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateDeviceStatus"))
  if valid_603362 != nil:
    section.add "X-Amz-Target", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-Signature")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Signature", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Content-Sha256", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Date")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Date", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-Credential")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-Credential", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-Security-Token")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Security-Token", valid_603367
  var valid_603368 = header.getOrDefault("X-Amz-Algorithm")
  valid_603368 = validateParameter(valid_603368, JString, required = false,
                                 default = nil)
  if valid_603368 != nil:
    section.add "X-Amz-Algorithm", valid_603368
  var valid_603369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "X-Amz-SignedHeaders", valid_603369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603371: Call_UpdateDeviceStatus_603359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the device status.
  ## 
  let valid = call_603371.validator(path, query, header, formData, body)
  let scheme = call_603371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603371.url(scheme.get, call_603371.host, call_603371.base,
                         call_603371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603371, url, valid)

proc call*(call_603372: Call_UpdateDeviceStatus_603359; body: JsonNode): Recallable =
  ## updateDeviceStatus
  ## Updates the device status.
  ##   body: JObject (required)
  var body_603373 = newJObject()
  if body != nil:
    body_603373 = body
  result = call_603372.call(nil, nil, nil, nil, body_603373)

var updateDeviceStatus* = Call_UpdateDeviceStatus_603359(
    name: "updateDeviceStatus", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateDeviceStatus",
    validator: validate_UpdateDeviceStatus_603360, base: "/",
    url: url_UpdateDeviceStatus_603361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_603374 = ref object of OpenApiRestCall_601389
proc url_UpdateGroup_603376(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGroup_603375(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603377 = header.getOrDefault("X-Amz-Target")
  valid_603377 = validateParameter(valid_603377, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateGroup"))
  if valid_603377 != nil:
    section.add "X-Amz-Target", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-Signature")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-Signature", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Content-Sha256", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-Date")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Date", valid_603380
  var valid_603381 = header.getOrDefault("X-Amz-Credential")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-Credential", valid_603381
  var valid_603382 = header.getOrDefault("X-Amz-Security-Token")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-Security-Token", valid_603382
  var valid_603383 = header.getOrDefault("X-Amz-Algorithm")
  valid_603383 = validateParameter(valid_603383, JString, required = false,
                                 default = nil)
  if valid_603383 != nil:
    section.add "X-Amz-Algorithm", valid_603383
  var valid_603384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603384 = validateParameter(valid_603384, JString, required = false,
                                 default = nil)
  if valid_603384 != nil:
    section.add "X-Amz-SignedHeaders", valid_603384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603386: Call_UpdateGroup_603374; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified group with the specified attributes.</p> <p>Calling this action requires developer credentials.</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ## 
  let valid = call_603386.validator(path, query, header, formData, body)
  let scheme = call_603386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603386.url(scheme.get, call_603386.host, call_603386.base,
                         call_603386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603386, url, valid)

proc call*(call_603387: Call_UpdateGroup_603374; body: JsonNode): Recallable =
  ## updateGroup
  ## <p>Updates the specified group with the specified attributes.</p> <p>Calling this action requires developer credentials.</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ##   body: JObject (required)
  var body_603388 = newJObject()
  if body != nil:
    body_603388 = body
  result = call_603387.call(nil, nil, nil, nil, body_603388)

var updateGroup* = Call_UpdateGroup_603374(name: "updateGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateGroup",
                                        validator: validate_UpdateGroup_603375,
                                        base: "/", url: url_UpdateGroup_603376,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIdentityProvider_603389 = ref object of OpenApiRestCall_601389
proc url_UpdateIdentityProvider_603391(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateIdentityProvider_603390(path: JsonNode; query: JsonNode;
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
  var valid_603392 = header.getOrDefault("X-Amz-Target")
  valid_603392 = validateParameter(valid_603392, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateIdentityProvider"))
  if valid_603392 != nil:
    section.add "X-Amz-Target", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Signature")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Signature", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Content-Sha256", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Date")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Date", valid_603395
  var valid_603396 = header.getOrDefault("X-Amz-Credential")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-Credential", valid_603396
  var valid_603397 = header.getOrDefault("X-Amz-Security-Token")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Security-Token", valid_603397
  var valid_603398 = header.getOrDefault("X-Amz-Algorithm")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "X-Amz-Algorithm", valid_603398
  var valid_603399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603399 = validateParameter(valid_603399, JString, required = false,
                                 default = nil)
  if valid_603399 != nil:
    section.add "X-Amz-SignedHeaders", valid_603399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603401: Call_UpdateIdentityProvider_603389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates identity provider information for a user pool.
  ## 
  let valid = call_603401.validator(path, query, header, formData, body)
  let scheme = call_603401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603401.url(scheme.get, call_603401.host, call_603401.base,
                         call_603401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603401, url, valid)

proc call*(call_603402: Call_UpdateIdentityProvider_603389; body: JsonNode): Recallable =
  ## updateIdentityProvider
  ## Updates identity provider information for a user pool.
  ##   body: JObject (required)
  var body_603403 = newJObject()
  if body != nil:
    body_603403 = body
  result = call_603402.call(nil, nil, nil, nil, body_603403)

var updateIdentityProvider* = Call_UpdateIdentityProvider_603389(
    name: "updateIdentityProvider", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateIdentityProvider",
    validator: validate_UpdateIdentityProvider_603390, base: "/",
    url: url_UpdateIdentityProvider_603391, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceServer_603404 = ref object of OpenApiRestCall_601389
proc url_UpdateResourceServer_603406(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateResourceServer_603405(path: JsonNode; query: JsonNode;
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
  var valid_603407 = header.getOrDefault("X-Amz-Target")
  valid_603407 = validateParameter(valid_603407, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateResourceServer"))
  if valid_603407 != nil:
    section.add "X-Amz-Target", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-Signature")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-Signature", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Content-Sha256", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Date")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Date", valid_603410
  var valid_603411 = header.getOrDefault("X-Amz-Credential")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-Credential", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-Security-Token")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-Security-Token", valid_603412
  var valid_603413 = header.getOrDefault("X-Amz-Algorithm")
  valid_603413 = validateParameter(valid_603413, JString, required = false,
                                 default = nil)
  if valid_603413 != nil:
    section.add "X-Amz-Algorithm", valid_603413
  var valid_603414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603414 = validateParameter(valid_603414, JString, required = false,
                                 default = nil)
  if valid_603414 != nil:
    section.add "X-Amz-SignedHeaders", valid_603414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603416: Call_UpdateResourceServer_603404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the name and scopes of resource server. All other fields are read-only.</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ## 
  let valid = call_603416.validator(path, query, header, formData, body)
  let scheme = call_603416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603416.url(scheme.get, call_603416.host, call_603416.base,
                         call_603416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603416, url, valid)

proc call*(call_603417: Call_UpdateResourceServer_603404; body: JsonNode): Recallable =
  ## updateResourceServer
  ## <p>Updates the name and scopes of resource server. All other fields are read-only.</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ##   body: JObject (required)
  var body_603418 = newJObject()
  if body != nil:
    body_603418 = body
  result = call_603417.call(nil, nil, nil, nil, body_603418)

var updateResourceServer* = Call_UpdateResourceServer_603404(
    name: "updateResourceServer", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateResourceServer",
    validator: validate_UpdateResourceServer_603405, base: "/",
    url: url_UpdateResourceServer_603406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserAttributes_603419 = ref object of OpenApiRestCall_601389
proc url_UpdateUserAttributes_603421(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserAttributes_603420(path: JsonNode; query: JsonNode;
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
  var valid_603422 = header.getOrDefault("X-Amz-Target")
  valid_603422 = validateParameter(valid_603422, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserAttributes"))
  if valid_603422 != nil:
    section.add "X-Amz-Target", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-Signature")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Signature", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Content-Sha256", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Date")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Date", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-Credential")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-Credential", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-Security-Token")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-Security-Token", valid_603427
  var valid_603428 = header.getOrDefault("X-Amz-Algorithm")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-Algorithm", valid_603428
  var valid_603429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603429 = validateParameter(valid_603429, JString, required = false,
                                 default = nil)
  if valid_603429 != nil:
    section.add "X-Amz-SignedHeaders", valid_603429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603431: Call_UpdateUserAttributes_603419; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a user to update a specific attribute (one at a time).
  ## 
  let valid = call_603431.validator(path, query, header, formData, body)
  let scheme = call_603431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603431.url(scheme.get, call_603431.host, call_603431.base,
                         call_603431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603431, url, valid)

proc call*(call_603432: Call_UpdateUserAttributes_603419; body: JsonNode): Recallable =
  ## updateUserAttributes
  ## Allows a user to update a specific attribute (one at a time).
  ##   body: JObject (required)
  var body_603433 = newJObject()
  if body != nil:
    body_603433 = body
  result = call_603432.call(nil, nil, nil, nil, body_603433)

var updateUserAttributes* = Call_UpdateUserAttributes_603419(
    name: "updateUserAttributes", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserAttributes",
    validator: validate_UpdateUserAttributes_603420, base: "/",
    url: url_UpdateUserAttributes_603421, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPool_603434 = ref object of OpenApiRestCall_601389
proc url_UpdateUserPool_603436(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserPool_603435(path: JsonNode; query: JsonNode;
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
  var valid_603437 = header.getOrDefault("X-Amz-Target")
  valid_603437 = validateParameter(valid_603437, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserPool"))
  if valid_603437 != nil:
    section.add "X-Amz-Target", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-Signature")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Signature", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Content-Sha256", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Date")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Date", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-Credential")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-Credential", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-Security-Token")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Security-Token", valid_603442
  var valid_603443 = header.getOrDefault("X-Amz-Algorithm")
  valid_603443 = validateParameter(valid_603443, JString, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "X-Amz-Algorithm", valid_603443
  var valid_603444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603444 = validateParameter(valid_603444, JString, required = false,
                                 default = nil)
  if valid_603444 != nil:
    section.add "X-Amz-SignedHeaders", valid_603444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603446: Call_UpdateUserPool_603434; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified user pool with the specified attributes. You can get a list of the current user pool settings with .</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ## 
  let valid = call_603446.validator(path, query, header, formData, body)
  let scheme = call_603446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603446.url(scheme.get, call_603446.host, call_603446.base,
                         call_603446.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603446, url, valid)

proc call*(call_603447: Call_UpdateUserPool_603434; body: JsonNode): Recallable =
  ## updateUserPool
  ## <p>Updates the specified user pool with the specified attributes. You can get a list of the current user pool settings with .</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ##   body: JObject (required)
  var body_603448 = newJObject()
  if body != nil:
    body_603448 = body
  result = call_603447.call(nil, nil, nil, nil, body_603448)

var updateUserPool* = Call_UpdateUserPool_603434(name: "updateUserPool",
    meth: HttpMethod.HttpPost, host: "cognito-idp.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserPool",
    validator: validate_UpdateUserPool_603435, base: "/", url: url_UpdateUserPool_603436,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPoolClient_603449 = ref object of OpenApiRestCall_601389
proc url_UpdateUserPoolClient_603451(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserPoolClient_603450(path: JsonNode; query: JsonNode;
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
  var valid_603452 = header.getOrDefault("X-Amz-Target")
  valid_603452 = validateParameter(valid_603452, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserPoolClient"))
  if valid_603452 != nil:
    section.add "X-Amz-Target", valid_603452
  var valid_603453 = header.getOrDefault("X-Amz-Signature")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-Signature", valid_603453
  var valid_603454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Content-Sha256", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-Date")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Date", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-Credential")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-Credential", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Security-Token")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Security-Token", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-Algorithm")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-Algorithm", valid_603458
  var valid_603459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-SignedHeaders", valid_603459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603461: Call_UpdateUserPoolClient_603449; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified user pool app client with the specified attributes. You can get a list of the current user pool app client settings with .</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ## 
  let valid = call_603461.validator(path, query, header, formData, body)
  let scheme = call_603461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603461.url(scheme.get, call_603461.host, call_603461.base,
                         call_603461.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603461, url, valid)

proc call*(call_603462: Call_UpdateUserPoolClient_603449; body: JsonNode): Recallable =
  ## updateUserPoolClient
  ## <p>Updates the specified user pool app client with the specified attributes. You can get a list of the current user pool app client settings with .</p> <important> <p>If you don't provide a value for an attribute, it will be set to the default value.</p> </important>
  ##   body: JObject (required)
  var body_603463 = newJObject()
  if body != nil:
    body_603463 = body
  result = call_603462.call(nil, nil, nil, nil, body_603463)

var updateUserPoolClient* = Call_UpdateUserPoolClient_603449(
    name: "updateUserPoolClient", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserPoolClient",
    validator: validate_UpdateUserPoolClient_603450, base: "/",
    url: url_UpdateUserPoolClient_603451, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPoolDomain_603464 = ref object of OpenApiRestCall_601389
proc url_UpdateUserPoolDomain_603466(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserPoolDomain_603465(path: JsonNode; query: JsonNode;
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
  var valid_603467 = header.getOrDefault("X-Amz-Target")
  valid_603467 = validateParameter(valid_603467, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.UpdateUserPoolDomain"))
  if valid_603467 != nil:
    section.add "X-Amz-Target", valid_603467
  var valid_603468 = header.getOrDefault("X-Amz-Signature")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "X-Amz-Signature", valid_603468
  var valid_603469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-Content-Sha256", valid_603469
  var valid_603470 = header.getOrDefault("X-Amz-Date")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Date", valid_603470
  var valid_603471 = header.getOrDefault("X-Amz-Credential")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-Credential", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-Security-Token")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Security-Token", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-Algorithm")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-Algorithm", valid_603473
  var valid_603474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "X-Amz-SignedHeaders", valid_603474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603476: Call_UpdateUserPoolDomain_603464; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the Secure Sockets Layer (SSL) certificate for the custom domain for your user pool.</p> <p>You can use this operation to provide the Amazon Resource Name (ARN) of a new certificate to Amazon Cognito. You cannot use it to change the domain for a user pool.</p> <p>A custom domain is used to host the Amazon Cognito hosted UI, which provides sign-up and sign-in pages for your application. When you set up a custom domain, you provide a certificate that you manage with AWS Certificate Manager (ACM). When necessary, you can use this operation to change the certificate that you applied to your custom domain.</p> <p>Usually, this is unnecessary following routine certificate renewal with ACM. When you renew your existing certificate in ACM, the ARN for your certificate remains the same, and your custom domain uses the new certificate automatically.</p> <p>However, if you replace your existing certificate with a new one, ACM gives the new certificate a new ARN. To apply the new certificate to your custom domain, you must provide this ARN to Amazon Cognito.</p> <p>When you add your new certificate in ACM, you must choose US East (N. Virginia) as the AWS Region.</p> <p>After you submit your request, Amazon Cognito requires up to 1 hour to distribute your new certificate to your custom domain.</p> <p>For more information about adding a custom domain to your user pool, see <a href="https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-add-custom-domain.html">Using Your Own Domain for the Hosted UI</a>.</p>
  ## 
  let valid = call_603476.validator(path, query, header, formData, body)
  let scheme = call_603476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603476.url(scheme.get, call_603476.host, call_603476.base,
                         call_603476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603476, url, valid)

proc call*(call_603477: Call_UpdateUserPoolDomain_603464; body: JsonNode): Recallable =
  ## updateUserPoolDomain
  ## <p>Updates the Secure Sockets Layer (SSL) certificate for the custom domain for your user pool.</p> <p>You can use this operation to provide the Amazon Resource Name (ARN) of a new certificate to Amazon Cognito. You cannot use it to change the domain for a user pool.</p> <p>A custom domain is used to host the Amazon Cognito hosted UI, which provides sign-up and sign-in pages for your application. When you set up a custom domain, you provide a certificate that you manage with AWS Certificate Manager (ACM). When necessary, you can use this operation to change the certificate that you applied to your custom domain.</p> <p>Usually, this is unnecessary following routine certificate renewal with ACM. When you renew your existing certificate in ACM, the ARN for your certificate remains the same, and your custom domain uses the new certificate automatically.</p> <p>However, if you replace your existing certificate with a new one, ACM gives the new certificate a new ARN. To apply the new certificate to your custom domain, you must provide this ARN to Amazon Cognito.</p> <p>When you add your new certificate in ACM, you must choose US East (N. Virginia) as the AWS Region.</p> <p>After you submit your request, Amazon Cognito requires up to 1 hour to distribute your new certificate to your custom domain.</p> <p>For more information about adding a custom domain to your user pool, see <a href="https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-add-custom-domain.html">Using Your Own Domain for the Hosted UI</a>.</p>
  ##   body: JObject (required)
  var body_603478 = newJObject()
  if body != nil:
    body_603478 = body
  result = call_603477.call(nil, nil, nil, nil, body_603478)

var updateUserPoolDomain* = Call_UpdateUserPoolDomain_603464(
    name: "updateUserPoolDomain", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.UpdateUserPoolDomain",
    validator: validate_UpdateUserPoolDomain_603465, base: "/",
    url: url_UpdateUserPoolDomain_603466, schemes: {Scheme.Https, Scheme.Http})
type
  Call_VerifySoftwareToken_603479 = ref object of OpenApiRestCall_601389
proc url_VerifySoftwareToken_603481(protocol: Scheme; host: string; base: string;
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

proc validate_VerifySoftwareToken_603480(path: JsonNode; query: JsonNode;
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
  var valid_603482 = header.getOrDefault("X-Amz-Target")
  valid_603482 = validateParameter(valid_603482, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.VerifySoftwareToken"))
  if valid_603482 != nil:
    section.add "X-Amz-Target", valid_603482
  var valid_603483 = header.getOrDefault("X-Amz-Signature")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "X-Amz-Signature", valid_603483
  var valid_603484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-Content-Sha256", valid_603484
  var valid_603485 = header.getOrDefault("X-Amz-Date")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-Date", valid_603485
  var valid_603486 = header.getOrDefault("X-Amz-Credential")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-Credential", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-Security-Token")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Security-Token", valid_603487
  var valid_603488 = header.getOrDefault("X-Amz-Algorithm")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "X-Amz-Algorithm", valid_603488
  var valid_603489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603489 = validateParameter(valid_603489, JString, required = false,
                                 default = nil)
  if valid_603489 != nil:
    section.add "X-Amz-SignedHeaders", valid_603489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603491: Call_VerifySoftwareToken_603479; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Use this API to register a user's entered TOTP code and mark the user's software token MFA status as "verified" if successful. The request takes an access token or a session string, but not both.
  ## 
  let valid = call_603491.validator(path, query, header, formData, body)
  let scheme = call_603491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603491.url(scheme.get, call_603491.host, call_603491.base,
                         call_603491.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603491, url, valid)

proc call*(call_603492: Call_VerifySoftwareToken_603479; body: JsonNode): Recallable =
  ## verifySoftwareToken
  ## Use this API to register a user's entered TOTP code and mark the user's software token MFA status as "verified" if successful. The request takes an access token or a session string, but not both.
  ##   body: JObject (required)
  var body_603493 = newJObject()
  if body != nil:
    body_603493 = body
  result = call_603492.call(nil, nil, nil, nil, body_603493)

var verifySoftwareToken* = Call_VerifySoftwareToken_603479(
    name: "verifySoftwareToken", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.VerifySoftwareToken",
    validator: validate_VerifySoftwareToken_603480, base: "/",
    url: url_VerifySoftwareToken_603481, schemes: {Scheme.Https, Scheme.Http})
type
  Call_VerifyUserAttribute_603494 = ref object of OpenApiRestCall_601389
proc url_VerifyUserAttribute_603496(protocol: Scheme; host: string; base: string;
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

proc validate_VerifyUserAttribute_603495(path: JsonNode; query: JsonNode;
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
  var valid_603497 = header.getOrDefault("X-Amz-Target")
  valid_603497 = validateParameter(valid_603497, JString, required = true, default = newJString(
      "AWSCognitoIdentityProviderService.VerifyUserAttribute"))
  if valid_603497 != nil:
    section.add "X-Amz-Target", valid_603497
  var valid_603498 = header.getOrDefault("X-Amz-Signature")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-Signature", valid_603498
  var valid_603499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Content-Sha256", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Date")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Date", valid_603500
  var valid_603501 = header.getOrDefault("X-Amz-Credential")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-Credential", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-Security-Token")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Security-Token", valid_603502
  var valid_603503 = header.getOrDefault("X-Amz-Algorithm")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "X-Amz-Algorithm", valid_603503
  var valid_603504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603504 = validateParameter(valid_603504, JString, required = false,
                                 default = nil)
  if valid_603504 != nil:
    section.add "X-Amz-SignedHeaders", valid_603504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603506: Call_VerifyUserAttribute_603494; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Verifies the specified user attributes in the user pool.
  ## 
  let valid = call_603506.validator(path, query, header, formData, body)
  let scheme = call_603506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603506.url(scheme.get, call_603506.host, call_603506.base,
                         call_603506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603506, url, valid)

proc call*(call_603507: Call_VerifyUserAttribute_603494; body: JsonNode): Recallable =
  ## verifyUserAttribute
  ## Verifies the specified user attributes in the user pool.
  ##   body: JObject (required)
  var body_603508 = newJObject()
  if body != nil:
    body_603508 = body
  result = call_603507.call(nil, nil, nil, nil, body_603508)

var verifyUserAttribute* = Call_VerifyUserAttribute_603494(
    name: "verifyUserAttribute", meth: HttpMethod.HttpPost,
    host: "cognito-idp.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityProviderService.VerifyUserAttribute",
    validator: validate_VerifyUserAttribute_603495, base: "/",
    url: url_VerifyUserAttribute_603496, schemes: {Scheme.Https, Scheme.Http})
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
