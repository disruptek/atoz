
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Cognito Identity
## version: 2014-06-30
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Cognito Federated Identities</fullname> <p>Amazon Cognito Federated Identities is a web service that delivers scoped temporary credentials to mobile devices and other untrusted environments. It uniquely identifies a device and supplies the user with a consistent identity over the lifetime of an application.</p> <p>Using Amazon Cognito Federated Identities, you can enable authentication with one or more third-party identity providers (Facebook, Google, or Login with Amazon) or an Amazon Cognito user pool, and you can also choose to support unauthenticated access from your app. Cognito delivers a unique identifier for each user and acts as an OpenID token provider trusted by AWS Security Token Service (STS) to access temporary, limited-privilege AWS credentials.</p> <p>For a description of the authentication flow from the Amazon Cognito Developer Guide see <a href="https://docs.aws.amazon.com/cognito/latest/developerguide/authentication-flow.html">Authentication Flow</a>.</p> <p>For more information see <a href="https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-identity.html">Amazon Cognito Federated Identities</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/cognito-identity/
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

  OpenApiRestCall_593389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593389): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "cognito-identity.ap-northeast-1.amazonaws.com", "ap-southeast-1": "cognito-identity.ap-southeast-1.amazonaws.com", "us-west-2": "cognito-identity.us-west-2.amazonaws.com", "eu-west-2": "cognito-identity.eu-west-2.amazonaws.com", "ap-northeast-3": "cognito-identity.ap-northeast-3.amazonaws.com", "eu-central-1": "cognito-identity.eu-central-1.amazonaws.com", "us-east-2": "cognito-identity.us-east-2.amazonaws.com", "us-east-1": "cognito-identity.us-east-1.amazonaws.com", "cn-northwest-1": "cognito-identity.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "cognito-identity.ap-south-1.amazonaws.com", "eu-north-1": "cognito-identity.eu-north-1.amazonaws.com", "ap-northeast-2": "cognito-identity.ap-northeast-2.amazonaws.com", "us-west-1": "cognito-identity.us-west-1.amazonaws.com", "us-gov-east-1": "cognito-identity.us-gov-east-1.amazonaws.com", "eu-west-3": "cognito-identity.eu-west-3.amazonaws.com", "cn-north-1": "cognito-identity.cn-north-1.amazonaws.com.cn", "sa-east-1": "cognito-identity.sa-east-1.amazonaws.com", "eu-west-1": "cognito-identity.eu-west-1.amazonaws.com", "us-gov-west-1": "cognito-identity.us-gov-west-1.amazonaws.com", "ap-southeast-2": "cognito-identity.ap-southeast-2.amazonaws.com", "ca-central-1": "cognito-identity.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "cognito-identity.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "cognito-identity.ap-southeast-1.amazonaws.com",
      "us-west-2": "cognito-identity.us-west-2.amazonaws.com",
      "eu-west-2": "cognito-identity.eu-west-2.amazonaws.com",
      "ap-northeast-3": "cognito-identity.ap-northeast-3.amazonaws.com",
      "eu-central-1": "cognito-identity.eu-central-1.amazonaws.com",
      "us-east-2": "cognito-identity.us-east-2.amazonaws.com",
      "us-east-1": "cognito-identity.us-east-1.amazonaws.com",
      "cn-northwest-1": "cognito-identity.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "cognito-identity.ap-south-1.amazonaws.com",
      "eu-north-1": "cognito-identity.eu-north-1.amazonaws.com",
      "ap-northeast-2": "cognito-identity.ap-northeast-2.amazonaws.com",
      "us-west-1": "cognito-identity.us-west-1.amazonaws.com",
      "us-gov-east-1": "cognito-identity.us-gov-east-1.amazonaws.com",
      "eu-west-3": "cognito-identity.eu-west-3.amazonaws.com",
      "cn-north-1": "cognito-identity.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "cognito-identity.sa-east-1.amazonaws.com",
      "eu-west-1": "cognito-identity.eu-west-1.amazonaws.com",
      "us-gov-west-1": "cognito-identity.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "cognito-identity.ap-southeast-2.amazonaws.com",
      "ca-central-1": "cognito-identity.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "cognito-identity"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateIdentityPool_593727 = ref object of OpenApiRestCall_593389
proc url_CreateIdentityPool_593729(protocol: Scheme; host: string; base: string;
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

proc validate_CreateIdentityPool_593728(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Creates a new identity pool. The identity pool is a store of user identity information that is specific to your AWS account. The keys for <code>SupportedLoginProviders</code> are as follows:</p> <ul> <li> <p>Facebook: <code>graph.facebook.com</code> </p> </li> <li> <p>Google: <code>accounts.google.com</code> </p> </li> <li> <p>Amazon: <code>www.amazon.com</code> </p> </li> <li> <p>Twitter: <code>api.twitter.com</code> </p> </li> <li> <p>Digits: <code>www.digits.com</code> </p> </li> </ul> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_593854 = header.getOrDefault("X-Amz-Target")
  valid_593854 = validateParameter(valid_593854, JString, required = true, default = newJString(
      "AWSCognitoIdentityService.CreateIdentityPool"))
  if valid_593854 != nil:
    section.add "X-Amz-Target", valid_593854
  var valid_593855 = header.getOrDefault("X-Amz-Signature")
  valid_593855 = validateParameter(valid_593855, JString, required = false,
                                 default = nil)
  if valid_593855 != nil:
    section.add "X-Amz-Signature", valid_593855
  var valid_593856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593856 = validateParameter(valid_593856, JString, required = false,
                                 default = nil)
  if valid_593856 != nil:
    section.add "X-Amz-Content-Sha256", valid_593856
  var valid_593857 = header.getOrDefault("X-Amz-Date")
  valid_593857 = validateParameter(valid_593857, JString, required = false,
                                 default = nil)
  if valid_593857 != nil:
    section.add "X-Amz-Date", valid_593857
  var valid_593858 = header.getOrDefault("X-Amz-Credential")
  valid_593858 = validateParameter(valid_593858, JString, required = false,
                                 default = nil)
  if valid_593858 != nil:
    section.add "X-Amz-Credential", valid_593858
  var valid_593859 = header.getOrDefault("X-Amz-Security-Token")
  valid_593859 = validateParameter(valid_593859, JString, required = false,
                                 default = nil)
  if valid_593859 != nil:
    section.add "X-Amz-Security-Token", valid_593859
  var valid_593860 = header.getOrDefault("X-Amz-Algorithm")
  valid_593860 = validateParameter(valid_593860, JString, required = false,
                                 default = nil)
  if valid_593860 != nil:
    section.add "X-Amz-Algorithm", valid_593860
  var valid_593861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593861 = validateParameter(valid_593861, JString, required = false,
                                 default = nil)
  if valid_593861 != nil:
    section.add "X-Amz-SignedHeaders", valid_593861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593885: Call_CreateIdentityPool_593727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new identity pool. The identity pool is a store of user identity information that is specific to your AWS account. The keys for <code>SupportedLoginProviders</code> are as follows:</p> <ul> <li> <p>Facebook: <code>graph.facebook.com</code> </p> </li> <li> <p>Google: <code>accounts.google.com</code> </p> </li> <li> <p>Amazon: <code>www.amazon.com</code> </p> </li> <li> <p>Twitter: <code>api.twitter.com</code> </p> </li> <li> <p>Digits: <code>www.digits.com</code> </p> </li> </ul> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  let valid = call_593885.validator(path, query, header, formData, body)
  let scheme = call_593885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593885.url(scheme.get, call_593885.host, call_593885.base,
                         call_593885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593885, url, valid)

proc call*(call_593956: Call_CreateIdentityPool_593727; body: JsonNode): Recallable =
  ## createIdentityPool
  ## <p>Creates a new identity pool. The identity pool is a store of user identity information that is specific to your AWS account. The keys for <code>SupportedLoginProviders</code> are as follows:</p> <ul> <li> <p>Facebook: <code>graph.facebook.com</code> </p> </li> <li> <p>Google: <code>accounts.google.com</code> </p> </li> <li> <p>Amazon: <code>www.amazon.com</code> </p> </li> <li> <p>Twitter: <code>api.twitter.com</code> </p> </li> <li> <p>Digits: <code>www.digits.com</code> </p> </li> </ul> <p>You must use AWS Developer credentials to call this API.</p>
  ##   body: JObject (required)
  var body_593957 = newJObject()
  if body != nil:
    body_593957 = body
  result = call_593956.call(nil, nil, nil, nil, body_593957)

var createIdentityPool* = Call_CreateIdentityPool_593727(
    name: "createIdentityPool", meth: HttpMethod.HttpPost,
    host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.CreateIdentityPool",
    validator: validate_CreateIdentityPool_593728, base: "/",
    url: url_CreateIdentityPool_593729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIdentities_593996 = ref object of OpenApiRestCall_593389
proc url_DeleteIdentities_593998(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteIdentities_593997(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes identities from an identity pool. You can specify a list of 1-60 identities that you want to delete.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_593999 = header.getOrDefault("X-Amz-Target")
  valid_593999 = validateParameter(valid_593999, JString, required = true, default = newJString(
      "AWSCognitoIdentityService.DeleteIdentities"))
  if valid_593999 != nil:
    section.add "X-Amz-Target", valid_593999
  var valid_594000 = header.getOrDefault("X-Amz-Signature")
  valid_594000 = validateParameter(valid_594000, JString, required = false,
                                 default = nil)
  if valid_594000 != nil:
    section.add "X-Amz-Signature", valid_594000
  var valid_594001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594001 = validateParameter(valid_594001, JString, required = false,
                                 default = nil)
  if valid_594001 != nil:
    section.add "X-Amz-Content-Sha256", valid_594001
  var valid_594002 = header.getOrDefault("X-Amz-Date")
  valid_594002 = validateParameter(valid_594002, JString, required = false,
                                 default = nil)
  if valid_594002 != nil:
    section.add "X-Amz-Date", valid_594002
  var valid_594003 = header.getOrDefault("X-Amz-Credential")
  valid_594003 = validateParameter(valid_594003, JString, required = false,
                                 default = nil)
  if valid_594003 != nil:
    section.add "X-Amz-Credential", valid_594003
  var valid_594004 = header.getOrDefault("X-Amz-Security-Token")
  valid_594004 = validateParameter(valid_594004, JString, required = false,
                                 default = nil)
  if valid_594004 != nil:
    section.add "X-Amz-Security-Token", valid_594004
  var valid_594005 = header.getOrDefault("X-Amz-Algorithm")
  valid_594005 = validateParameter(valid_594005, JString, required = false,
                                 default = nil)
  if valid_594005 != nil:
    section.add "X-Amz-Algorithm", valid_594005
  var valid_594006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594006 = validateParameter(valid_594006, JString, required = false,
                                 default = nil)
  if valid_594006 != nil:
    section.add "X-Amz-SignedHeaders", valid_594006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594008: Call_DeleteIdentities_593996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes identities from an identity pool. You can specify a list of 1-60 identities that you want to delete.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  let valid = call_594008.validator(path, query, header, formData, body)
  let scheme = call_594008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594008.url(scheme.get, call_594008.host, call_594008.base,
                         call_594008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594008, url, valid)

proc call*(call_594009: Call_DeleteIdentities_593996; body: JsonNode): Recallable =
  ## deleteIdentities
  ## <p>Deletes identities from an identity pool. You can specify a list of 1-60 identities that you want to delete.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ##   body: JObject (required)
  var body_594010 = newJObject()
  if body != nil:
    body_594010 = body
  result = call_594009.call(nil, nil, nil, nil, body_594010)

var deleteIdentities* = Call_DeleteIdentities_593996(name: "deleteIdentities",
    meth: HttpMethod.HttpPost, host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.DeleteIdentities",
    validator: validate_DeleteIdentities_593997, base: "/",
    url: url_DeleteIdentities_593998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIdentityPool_594011 = ref object of OpenApiRestCall_593389
proc url_DeleteIdentityPool_594013(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteIdentityPool_594012(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Deletes an identity pool. Once a pool is deleted, users will not be able to authenticate with the pool.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_594014 = header.getOrDefault("X-Amz-Target")
  valid_594014 = validateParameter(valid_594014, JString, required = true, default = newJString(
      "AWSCognitoIdentityService.DeleteIdentityPool"))
  if valid_594014 != nil:
    section.add "X-Amz-Target", valid_594014
  var valid_594015 = header.getOrDefault("X-Amz-Signature")
  valid_594015 = validateParameter(valid_594015, JString, required = false,
                                 default = nil)
  if valid_594015 != nil:
    section.add "X-Amz-Signature", valid_594015
  var valid_594016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594016 = validateParameter(valid_594016, JString, required = false,
                                 default = nil)
  if valid_594016 != nil:
    section.add "X-Amz-Content-Sha256", valid_594016
  var valid_594017 = header.getOrDefault("X-Amz-Date")
  valid_594017 = validateParameter(valid_594017, JString, required = false,
                                 default = nil)
  if valid_594017 != nil:
    section.add "X-Amz-Date", valid_594017
  var valid_594018 = header.getOrDefault("X-Amz-Credential")
  valid_594018 = validateParameter(valid_594018, JString, required = false,
                                 default = nil)
  if valid_594018 != nil:
    section.add "X-Amz-Credential", valid_594018
  var valid_594019 = header.getOrDefault("X-Amz-Security-Token")
  valid_594019 = validateParameter(valid_594019, JString, required = false,
                                 default = nil)
  if valid_594019 != nil:
    section.add "X-Amz-Security-Token", valid_594019
  var valid_594020 = header.getOrDefault("X-Amz-Algorithm")
  valid_594020 = validateParameter(valid_594020, JString, required = false,
                                 default = nil)
  if valid_594020 != nil:
    section.add "X-Amz-Algorithm", valid_594020
  var valid_594021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594021 = validateParameter(valid_594021, JString, required = false,
                                 default = nil)
  if valid_594021 != nil:
    section.add "X-Amz-SignedHeaders", valid_594021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594023: Call_DeleteIdentityPool_594011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an identity pool. Once a pool is deleted, users will not be able to authenticate with the pool.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  let valid = call_594023.validator(path, query, header, formData, body)
  let scheme = call_594023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594023.url(scheme.get, call_594023.host, call_594023.base,
                         call_594023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594023, url, valid)

proc call*(call_594024: Call_DeleteIdentityPool_594011; body: JsonNode): Recallable =
  ## deleteIdentityPool
  ## <p>Deletes an identity pool. Once a pool is deleted, users will not be able to authenticate with the pool.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ##   body: JObject (required)
  var body_594025 = newJObject()
  if body != nil:
    body_594025 = body
  result = call_594024.call(nil, nil, nil, nil, body_594025)

var deleteIdentityPool* = Call_DeleteIdentityPool_594011(
    name: "deleteIdentityPool", meth: HttpMethod.HttpPost,
    host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.DeleteIdentityPool",
    validator: validate_DeleteIdentityPool_594012, base: "/",
    url: url_DeleteIdentityPool_594013, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentity_594026 = ref object of OpenApiRestCall_593389
proc url_DescribeIdentity_594028(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeIdentity_594027(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Returns metadata related to the given identity, including when the identity was created and any associated linked logins.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_594029 = header.getOrDefault("X-Amz-Target")
  valid_594029 = validateParameter(valid_594029, JString, required = true, default = newJString(
      "AWSCognitoIdentityService.DescribeIdentity"))
  if valid_594029 != nil:
    section.add "X-Amz-Target", valid_594029
  var valid_594030 = header.getOrDefault("X-Amz-Signature")
  valid_594030 = validateParameter(valid_594030, JString, required = false,
                                 default = nil)
  if valid_594030 != nil:
    section.add "X-Amz-Signature", valid_594030
  var valid_594031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594031 = validateParameter(valid_594031, JString, required = false,
                                 default = nil)
  if valid_594031 != nil:
    section.add "X-Amz-Content-Sha256", valid_594031
  var valid_594032 = header.getOrDefault("X-Amz-Date")
  valid_594032 = validateParameter(valid_594032, JString, required = false,
                                 default = nil)
  if valid_594032 != nil:
    section.add "X-Amz-Date", valid_594032
  var valid_594033 = header.getOrDefault("X-Amz-Credential")
  valid_594033 = validateParameter(valid_594033, JString, required = false,
                                 default = nil)
  if valid_594033 != nil:
    section.add "X-Amz-Credential", valid_594033
  var valid_594034 = header.getOrDefault("X-Amz-Security-Token")
  valid_594034 = validateParameter(valid_594034, JString, required = false,
                                 default = nil)
  if valid_594034 != nil:
    section.add "X-Amz-Security-Token", valid_594034
  var valid_594035 = header.getOrDefault("X-Amz-Algorithm")
  valid_594035 = validateParameter(valid_594035, JString, required = false,
                                 default = nil)
  if valid_594035 != nil:
    section.add "X-Amz-Algorithm", valid_594035
  var valid_594036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594036 = validateParameter(valid_594036, JString, required = false,
                                 default = nil)
  if valid_594036 != nil:
    section.add "X-Amz-SignedHeaders", valid_594036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594038: Call_DescribeIdentity_594026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns metadata related to the given identity, including when the identity was created and any associated linked logins.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  let valid = call_594038.validator(path, query, header, formData, body)
  let scheme = call_594038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594038.url(scheme.get, call_594038.host, call_594038.base,
                         call_594038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594038, url, valid)

proc call*(call_594039: Call_DescribeIdentity_594026; body: JsonNode): Recallable =
  ## describeIdentity
  ## <p>Returns metadata related to the given identity, including when the identity was created and any associated linked logins.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ##   body: JObject (required)
  var body_594040 = newJObject()
  if body != nil:
    body_594040 = body
  result = call_594039.call(nil, nil, nil, nil, body_594040)

var describeIdentity* = Call_DescribeIdentity_594026(name: "describeIdentity",
    meth: HttpMethod.HttpPost, host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.DescribeIdentity",
    validator: validate_DescribeIdentity_594027, base: "/",
    url: url_DescribeIdentity_594028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentityPool_594041 = ref object of OpenApiRestCall_593389
proc url_DescribeIdentityPool_594043(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeIdentityPool_594042(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets details about a particular identity pool, including the pool name, ID description, creation date, and current number of users.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_594044 = header.getOrDefault("X-Amz-Target")
  valid_594044 = validateParameter(valid_594044, JString, required = true, default = newJString(
      "AWSCognitoIdentityService.DescribeIdentityPool"))
  if valid_594044 != nil:
    section.add "X-Amz-Target", valid_594044
  var valid_594045 = header.getOrDefault("X-Amz-Signature")
  valid_594045 = validateParameter(valid_594045, JString, required = false,
                                 default = nil)
  if valid_594045 != nil:
    section.add "X-Amz-Signature", valid_594045
  var valid_594046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "X-Amz-Content-Sha256", valid_594046
  var valid_594047 = header.getOrDefault("X-Amz-Date")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-Date", valid_594047
  var valid_594048 = header.getOrDefault("X-Amz-Credential")
  valid_594048 = validateParameter(valid_594048, JString, required = false,
                                 default = nil)
  if valid_594048 != nil:
    section.add "X-Amz-Credential", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Security-Token")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Security-Token", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Algorithm")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Algorithm", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-SignedHeaders", valid_594051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594053: Call_DescribeIdentityPool_594041; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets details about a particular identity pool, including the pool name, ID description, creation date, and current number of users.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  let valid = call_594053.validator(path, query, header, formData, body)
  let scheme = call_594053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594053.url(scheme.get, call_594053.host, call_594053.base,
                         call_594053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594053, url, valid)

proc call*(call_594054: Call_DescribeIdentityPool_594041; body: JsonNode): Recallable =
  ## describeIdentityPool
  ## <p>Gets details about a particular identity pool, including the pool name, ID description, creation date, and current number of users.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ##   body: JObject (required)
  var body_594055 = newJObject()
  if body != nil:
    body_594055 = body
  result = call_594054.call(nil, nil, nil, nil, body_594055)

var describeIdentityPool* = Call_DescribeIdentityPool_594041(
    name: "describeIdentityPool", meth: HttpMethod.HttpPost,
    host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.DescribeIdentityPool",
    validator: validate_DescribeIdentityPool_594042, base: "/",
    url: url_DescribeIdentityPool_594043, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCredentialsForIdentity_594056 = ref object of OpenApiRestCall_593389
proc url_GetCredentialsForIdentity_594058(protocol: Scheme; host: string;
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

proc validate_GetCredentialsForIdentity_594057(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns credentials for the provided identity ID. Any provided logins will be validated against supported login providers. If the token is for cognito-identity.amazonaws.com, it will be passed through to AWS Security Token Service with the appropriate role for the token.</p> <p>This is a public API. You do not need any credentials to call this API.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_594059 = header.getOrDefault("X-Amz-Target")
  valid_594059 = validateParameter(valid_594059, JString, required = true, default = newJString(
      "AWSCognitoIdentityService.GetCredentialsForIdentity"))
  if valid_594059 != nil:
    section.add "X-Amz-Target", valid_594059
  var valid_594060 = header.getOrDefault("X-Amz-Signature")
  valid_594060 = validateParameter(valid_594060, JString, required = false,
                                 default = nil)
  if valid_594060 != nil:
    section.add "X-Amz-Signature", valid_594060
  var valid_594061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-Content-Sha256", valid_594061
  var valid_594062 = header.getOrDefault("X-Amz-Date")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-Date", valid_594062
  var valid_594063 = header.getOrDefault("X-Amz-Credential")
  valid_594063 = validateParameter(valid_594063, JString, required = false,
                                 default = nil)
  if valid_594063 != nil:
    section.add "X-Amz-Credential", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Security-Token")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Security-Token", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Algorithm")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Algorithm", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-SignedHeaders", valid_594066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594068: Call_GetCredentialsForIdentity_594056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns credentials for the provided identity ID. Any provided logins will be validated against supported login providers. If the token is for cognito-identity.amazonaws.com, it will be passed through to AWS Security Token Service with the appropriate role for the token.</p> <p>This is a public API. You do not need any credentials to call this API.</p>
  ## 
  let valid = call_594068.validator(path, query, header, formData, body)
  let scheme = call_594068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594068.url(scheme.get, call_594068.host, call_594068.base,
                         call_594068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594068, url, valid)

proc call*(call_594069: Call_GetCredentialsForIdentity_594056; body: JsonNode): Recallable =
  ## getCredentialsForIdentity
  ## <p>Returns credentials for the provided identity ID. Any provided logins will be validated against supported login providers. If the token is for cognito-identity.amazonaws.com, it will be passed through to AWS Security Token Service with the appropriate role for the token.</p> <p>This is a public API. You do not need any credentials to call this API.</p>
  ##   body: JObject (required)
  var body_594070 = newJObject()
  if body != nil:
    body_594070 = body
  result = call_594069.call(nil, nil, nil, nil, body_594070)

var getCredentialsForIdentity* = Call_GetCredentialsForIdentity_594056(
    name: "getCredentialsForIdentity", meth: HttpMethod.HttpPost,
    host: "cognito-identity.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityService.GetCredentialsForIdentity",
    validator: validate_GetCredentialsForIdentity_594057, base: "/",
    url: url_GetCredentialsForIdentity_594058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetId_594071 = ref object of OpenApiRestCall_593389
proc url_GetId_594073(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetId_594072(path: JsonNode; query: JsonNode; header: JsonNode;
                          formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Generates (or retrieves) a Cognito ID. Supplying multiple logins will create an implicit linked account.</p> <p>This is a public API. You do not need any credentials to call this API.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_594074 = header.getOrDefault("X-Amz-Target")
  valid_594074 = validateParameter(valid_594074, JString, required = true, default = newJString(
      "AWSCognitoIdentityService.GetId"))
  if valid_594074 != nil:
    section.add "X-Amz-Target", valid_594074
  var valid_594075 = header.getOrDefault("X-Amz-Signature")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "X-Amz-Signature", valid_594075
  var valid_594076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Content-Sha256", valid_594076
  var valid_594077 = header.getOrDefault("X-Amz-Date")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Date", valid_594077
  var valid_594078 = header.getOrDefault("X-Amz-Credential")
  valid_594078 = validateParameter(valid_594078, JString, required = false,
                                 default = nil)
  if valid_594078 != nil:
    section.add "X-Amz-Credential", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Security-Token")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Security-Token", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Algorithm")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Algorithm", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-SignedHeaders", valid_594081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594083: Call_GetId_594071; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Generates (or retrieves) a Cognito ID. Supplying multiple logins will create an implicit linked account.</p> <p>This is a public API. You do not need any credentials to call this API.</p>
  ## 
  let valid = call_594083.validator(path, query, header, formData, body)
  let scheme = call_594083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594083.url(scheme.get, call_594083.host, call_594083.base,
                         call_594083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594083, url, valid)

proc call*(call_594084: Call_GetId_594071; body: JsonNode): Recallable =
  ## getId
  ## <p>Generates (or retrieves) a Cognito ID. Supplying multiple logins will create an implicit linked account.</p> <p>This is a public API. You do not need any credentials to call this API.</p>
  ##   body: JObject (required)
  var body_594085 = newJObject()
  if body != nil:
    body_594085 = body
  result = call_594084.call(nil, nil, nil, nil, body_594085)

var getId* = Call_GetId_594071(name: "getId", meth: HttpMethod.HttpPost,
                            host: "cognito-identity.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityService.GetId",
                            validator: validate_GetId_594072, base: "/",
                            url: url_GetId_594073,
                            schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIdentityPoolRoles_594086 = ref object of OpenApiRestCall_593389
proc url_GetIdentityPoolRoles_594088(protocol: Scheme; host: string; base: string;
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

proc validate_GetIdentityPoolRoles_594087(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets the roles for an identity pool.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_594089 = header.getOrDefault("X-Amz-Target")
  valid_594089 = validateParameter(valid_594089, JString, required = true, default = newJString(
      "AWSCognitoIdentityService.GetIdentityPoolRoles"))
  if valid_594089 != nil:
    section.add "X-Amz-Target", valid_594089
  var valid_594090 = header.getOrDefault("X-Amz-Signature")
  valid_594090 = validateParameter(valid_594090, JString, required = false,
                                 default = nil)
  if valid_594090 != nil:
    section.add "X-Amz-Signature", valid_594090
  var valid_594091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Content-Sha256", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Date")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Date", valid_594092
  var valid_594093 = header.getOrDefault("X-Amz-Credential")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "X-Amz-Credential", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Security-Token")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Security-Token", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Algorithm")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Algorithm", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-SignedHeaders", valid_594096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594098: Call_GetIdentityPoolRoles_594086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the roles for an identity pool.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  let valid = call_594098.validator(path, query, header, formData, body)
  let scheme = call_594098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594098.url(scheme.get, call_594098.host, call_594098.base,
                         call_594098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594098, url, valid)

proc call*(call_594099: Call_GetIdentityPoolRoles_594086; body: JsonNode): Recallable =
  ## getIdentityPoolRoles
  ## <p>Gets the roles for an identity pool.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ##   body: JObject (required)
  var body_594100 = newJObject()
  if body != nil:
    body_594100 = body
  result = call_594099.call(nil, nil, nil, nil, body_594100)

var getIdentityPoolRoles* = Call_GetIdentityPoolRoles_594086(
    name: "getIdentityPoolRoles", meth: HttpMethod.HttpPost,
    host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.GetIdentityPoolRoles",
    validator: validate_GetIdentityPoolRoles_594087, base: "/",
    url: url_GetIdentityPoolRoles_594088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOpenIdToken_594101 = ref object of OpenApiRestCall_593389
proc url_GetOpenIdToken_594103(protocol: Scheme; host: string; base: string;
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

proc validate_GetOpenIdToken_594102(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Gets an OpenID token, using a known Cognito ID. This known Cognito ID is returned by <a>GetId</a>. You can optionally add additional logins for the identity. Supplying multiple logins creates an implicit link.</p> <p>The OpenId token is valid for 10 minutes.</p> <p>This is a public API. You do not need any credentials to call this API.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_594104 = header.getOrDefault("X-Amz-Target")
  valid_594104 = validateParameter(valid_594104, JString, required = true, default = newJString(
      "AWSCognitoIdentityService.GetOpenIdToken"))
  if valid_594104 != nil:
    section.add "X-Amz-Target", valid_594104
  var valid_594105 = header.getOrDefault("X-Amz-Signature")
  valid_594105 = validateParameter(valid_594105, JString, required = false,
                                 default = nil)
  if valid_594105 != nil:
    section.add "X-Amz-Signature", valid_594105
  var valid_594106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-Content-Sha256", valid_594106
  var valid_594107 = header.getOrDefault("X-Amz-Date")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "X-Amz-Date", valid_594107
  var valid_594108 = header.getOrDefault("X-Amz-Credential")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = nil)
  if valid_594108 != nil:
    section.add "X-Amz-Credential", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Security-Token")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Security-Token", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Algorithm")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Algorithm", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-SignedHeaders", valid_594111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594113: Call_GetOpenIdToken_594101; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets an OpenID token, using a known Cognito ID. This known Cognito ID is returned by <a>GetId</a>. You can optionally add additional logins for the identity. Supplying multiple logins creates an implicit link.</p> <p>The OpenId token is valid for 10 minutes.</p> <p>This is a public API. You do not need any credentials to call this API.</p>
  ## 
  let valid = call_594113.validator(path, query, header, formData, body)
  let scheme = call_594113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594113.url(scheme.get, call_594113.host, call_594113.base,
                         call_594113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594113, url, valid)

proc call*(call_594114: Call_GetOpenIdToken_594101; body: JsonNode): Recallable =
  ## getOpenIdToken
  ## <p>Gets an OpenID token, using a known Cognito ID. This known Cognito ID is returned by <a>GetId</a>. You can optionally add additional logins for the identity. Supplying multiple logins creates an implicit link.</p> <p>The OpenId token is valid for 10 minutes.</p> <p>This is a public API. You do not need any credentials to call this API.</p>
  ##   body: JObject (required)
  var body_594115 = newJObject()
  if body != nil:
    body_594115 = body
  result = call_594114.call(nil, nil, nil, nil, body_594115)

var getOpenIdToken* = Call_GetOpenIdToken_594101(name: "getOpenIdToken",
    meth: HttpMethod.HttpPost, host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.GetOpenIdToken",
    validator: validate_GetOpenIdToken_594102, base: "/", url: url_GetOpenIdToken_594103,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOpenIdTokenForDeveloperIdentity_594116 = ref object of OpenApiRestCall_593389
proc url_GetOpenIdTokenForDeveloperIdentity_594118(protocol: Scheme; host: string;
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

proc validate_GetOpenIdTokenForDeveloperIdentity_594117(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Registers (or retrieves) a Cognito <code>IdentityId</code> and an OpenID Connect token for a user authenticated by your backend authentication process. Supplying multiple logins will create an implicit linked account. You can only specify one developer provider as part of the <code>Logins</code> map, which is linked to the identity pool. The developer provider is the "domain" by which Cognito will refer to your users.</p> <p>You can use <code>GetOpenIdTokenForDeveloperIdentity</code> to create a new identity and to link new logins (that is, user credentials issued by a public provider or developer provider) to an existing identity. When you want to create a new identity, the <code>IdentityId</code> should be null. When you want to associate a new login with an existing authenticated/unauthenticated identity, you can do so by providing the existing <code>IdentityId</code>. This API will create the identity in the specified <code>IdentityPoolId</code>.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_594119 = header.getOrDefault("X-Amz-Target")
  valid_594119 = validateParameter(valid_594119, JString, required = true, default = newJString(
      "AWSCognitoIdentityService.GetOpenIdTokenForDeveloperIdentity"))
  if valid_594119 != nil:
    section.add "X-Amz-Target", valid_594119
  var valid_594120 = header.getOrDefault("X-Amz-Signature")
  valid_594120 = validateParameter(valid_594120, JString, required = false,
                                 default = nil)
  if valid_594120 != nil:
    section.add "X-Amz-Signature", valid_594120
  var valid_594121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "X-Amz-Content-Sha256", valid_594121
  var valid_594122 = header.getOrDefault("X-Amz-Date")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "X-Amz-Date", valid_594122
  var valid_594123 = header.getOrDefault("X-Amz-Credential")
  valid_594123 = validateParameter(valid_594123, JString, required = false,
                                 default = nil)
  if valid_594123 != nil:
    section.add "X-Amz-Credential", valid_594123
  var valid_594124 = header.getOrDefault("X-Amz-Security-Token")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-Security-Token", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Algorithm")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Algorithm", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-SignedHeaders", valid_594126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594128: Call_GetOpenIdTokenForDeveloperIdentity_594116;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Registers (or retrieves) a Cognito <code>IdentityId</code> and an OpenID Connect token for a user authenticated by your backend authentication process. Supplying multiple logins will create an implicit linked account. You can only specify one developer provider as part of the <code>Logins</code> map, which is linked to the identity pool. The developer provider is the "domain" by which Cognito will refer to your users.</p> <p>You can use <code>GetOpenIdTokenForDeveloperIdentity</code> to create a new identity and to link new logins (that is, user credentials issued by a public provider or developer provider) to an existing identity. When you want to create a new identity, the <code>IdentityId</code> should be null. When you want to associate a new login with an existing authenticated/unauthenticated identity, you can do so by providing the existing <code>IdentityId</code>. This API will create the identity in the specified <code>IdentityPoolId</code>.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  let valid = call_594128.validator(path, query, header, formData, body)
  let scheme = call_594128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594128.url(scheme.get, call_594128.host, call_594128.base,
                         call_594128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594128, url, valid)

proc call*(call_594129: Call_GetOpenIdTokenForDeveloperIdentity_594116;
          body: JsonNode): Recallable =
  ## getOpenIdTokenForDeveloperIdentity
  ## <p>Registers (or retrieves) a Cognito <code>IdentityId</code> and an OpenID Connect token for a user authenticated by your backend authentication process. Supplying multiple logins will create an implicit linked account. You can only specify one developer provider as part of the <code>Logins</code> map, which is linked to the identity pool. The developer provider is the "domain" by which Cognito will refer to your users.</p> <p>You can use <code>GetOpenIdTokenForDeveloperIdentity</code> to create a new identity and to link new logins (that is, user credentials issued by a public provider or developer provider) to an existing identity. When you want to create a new identity, the <code>IdentityId</code> should be null. When you want to associate a new login with an existing authenticated/unauthenticated identity, you can do so by providing the existing <code>IdentityId</code>. This API will create the identity in the specified <code>IdentityPoolId</code>.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ##   body: JObject (required)
  var body_594130 = newJObject()
  if body != nil:
    body_594130 = body
  result = call_594129.call(nil, nil, nil, nil, body_594130)

var getOpenIdTokenForDeveloperIdentity* = Call_GetOpenIdTokenForDeveloperIdentity_594116(
    name: "getOpenIdTokenForDeveloperIdentity", meth: HttpMethod.HttpPost,
    host: "cognito-identity.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityService.GetOpenIdTokenForDeveloperIdentity",
    validator: validate_GetOpenIdTokenForDeveloperIdentity_594117, base: "/",
    url: url_GetOpenIdTokenForDeveloperIdentity_594118,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIdentities_594131 = ref object of OpenApiRestCall_593389
proc url_ListIdentities_594133(protocol: Scheme; host: string; base: string;
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

proc validate_ListIdentities_594132(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Lists the identities in an identity pool.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_594134 = header.getOrDefault("X-Amz-Target")
  valid_594134 = validateParameter(valid_594134, JString, required = true, default = newJString(
      "AWSCognitoIdentityService.ListIdentities"))
  if valid_594134 != nil:
    section.add "X-Amz-Target", valid_594134
  var valid_594135 = header.getOrDefault("X-Amz-Signature")
  valid_594135 = validateParameter(valid_594135, JString, required = false,
                                 default = nil)
  if valid_594135 != nil:
    section.add "X-Amz-Signature", valid_594135
  var valid_594136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Content-Sha256", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-Date")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-Date", valid_594137
  var valid_594138 = header.getOrDefault("X-Amz-Credential")
  valid_594138 = validateParameter(valid_594138, JString, required = false,
                                 default = nil)
  if valid_594138 != nil:
    section.add "X-Amz-Credential", valid_594138
  var valid_594139 = header.getOrDefault("X-Amz-Security-Token")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-Security-Token", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-Algorithm")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-Algorithm", valid_594140
  var valid_594141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "X-Amz-SignedHeaders", valid_594141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594143: Call_ListIdentities_594131; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the identities in an identity pool.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  let valid = call_594143.validator(path, query, header, formData, body)
  let scheme = call_594143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594143.url(scheme.get, call_594143.host, call_594143.base,
                         call_594143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594143, url, valid)

proc call*(call_594144: Call_ListIdentities_594131; body: JsonNode): Recallable =
  ## listIdentities
  ## <p>Lists the identities in an identity pool.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ##   body: JObject (required)
  var body_594145 = newJObject()
  if body != nil:
    body_594145 = body
  result = call_594144.call(nil, nil, nil, nil, body_594145)

var listIdentities* = Call_ListIdentities_594131(name: "listIdentities",
    meth: HttpMethod.HttpPost, host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.ListIdentities",
    validator: validate_ListIdentities_594132, base: "/", url: url_ListIdentities_594133,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIdentityPools_594146 = ref object of OpenApiRestCall_593389
proc url_ListIdentityPools_594148(protocol: Scheme; host: string; base: string;
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

proc validate_ListIdentityPools_594147(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Lists all of the Cognito identity pools registered for your account.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_594149 = header.getOrDefault("X-Amz-Target")
  valid_594149 = validateParameter(valid_594149, JString, required = true, default = newJString(
      "AWSCognitoIdentityService.ListIdentityPools"))
  if valid_594149 != nil:
    section.add "X-Amz-Target", valid_594149
  var valid_594150 = header.getOrDefault("X-Amz-Signature")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "X-Amz-Signature", valid_594150
  var valid_594151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Content-Sha256", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-Date")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Date", valid_594152
  var valid_594153 = header.getOrDefault("X-Amz-Credential")
  valid_594153 = validateParameter(valid_594153, JString, required = false,
                                 default = nil)
  if valid_594153 != nil:
    section.add "X-Amz-Credential", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Security-Token")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Security-Token", valid_594154
  var valid_594155 = header.getOrDefault("X-Amz-Algorithm")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-Algorithm", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-SignedHeaders", valid_594156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594158: Call_ListIdentityPools_594146; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all of the Cognito identity pools registered for your account.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  let valid = call_594158.validator(path, query, header, formData, body)
  let scheme = call_594158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594158.url(scheme.get, call_594158.host, call_594158.base,
                         call_594158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594158, url, valid)

proc call*(call_594159: Call_ListIdentityPools_594146; body: JsonNode): Recallable =
  ## listIdentityPools
  ## <p>Lists all of the Cognito identity pools registered for your account.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ##   body: JObject (required)
  var body_594160 = newJObject()
  if body != nil:
    body_594160 = body
  result = call_594159.call(nil, nil, nil, nil, body_594160)

var listIdentityPools* = Call_ListIdentityPools_594146(name: "listIdentityPools",
    meth: HttpMethod.HttpPost, host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.ListIdentityPools",
    validator: validate_ListIdentityPools_594147, base: "/",
    url: url_ListIdentityPools_594148, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_594161 = ref object of OpenApiRestCall_593389
proc url_ListTagsForResource_594163(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_594162(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Lists the tags that are assigned to an Amazon Cognito identity pool.</p> <p>A tag is a label that you can apply to identity pools to categorize and manage them in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>You can use this action up to 10 times per second, per account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_594164 = header.getOrDefault("X-Amz-Target")
  valid_594164 = validateParameter(valid_594164, JString, required = true, default = newJString(
      "AWSCognitoIdentityService.ListTagsForResource"))
  if valid_594164 != nil:
    section.add "X-Amz-Target", valid_594164
  var valid_594165 = header.getOrDefault("X-Amz-Signature")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "X-Amz-Signature", valid_594165
  var valid_594166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Content-Sha256", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Date")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Date", valid_594167
  var valid_594168 = header.getOrDefault("X-Amz-Credential")
  valid_594168 = validateParameter(valid_594168, JString, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "X-Amz-Credential", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Security-Token")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Security-Token", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Algorithm")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Algorithm", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-SignedHeaders", valid_594171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594173: Call_ListTagsForResource_594161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the tags that are assigned to an Amazon Cognito identity pool.</p> <p>A tag is a label that you can apply to identity pools to categorize and manage them in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>You can use this action up to 10 times per second, per account.</p>
  ## 
  let valid = call_594173.validator(path, query, header, formData, body)
  let scheme = call_594173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594173.url(scheme.get, call_594173.host, call_594173.base,
                         call_594173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594173, url, valid)

proc call*(call_594174: Call_ListTagsForResource_594161; body: JsonNode): Recallable =
  ## listTagsForResource
  ## <p>Lists the tags that are assigned to an Amazon Cognito identity pool.</p> <p>A tag is a label that you can apply to identity pools to categorize and manage them in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>You can use this action up to 10 times per second, per account.</p>
  ##   body: JObject (required)
  var body_594175 = newJObject()
  if body != nil:
    body_594175 = body
  result = call_594174.call(nil, nil, nil, nil, body_594175)

var listTagsForResource* = Call_ListTagsForResource_594161(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.ListTagsForResource",
    validator: validate_ListTagsForResource_594162, base: "/",
    url: url_ListTagsForResource_594163, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LookupDeveloperIdentity_594176 = ref object of OpenApiRestCall_593389
proc url_LookupDeveloperIdentity_594178(protocol: Scheme; host: string; base: string;
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

proc validate_LookupDeveloperIdentity_594177(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the <code>IdentityID</code> associated with a <code>DeveloperUserIdentifier</code> or the list of <code>DeveloperUserIdentifier</code> values associated with an <code>IdentityId</code> for an existing identity. Either <code>IdentityID</code> or <code>DeveloperUserIdentifier</code> must not be null. If you supply only one of these values, the other value will be searched in the database and returned as a part of the response. If you supply both, <code>DeveloperUserIdentifier</code> will be matched against <code>IdentityID</code>. If the values are verified against the database, the response returns both values and is the same as the request. Otherwise a <code>ResourceConflictException</code> is thrown.</p> <p> <code>LookupDeveloperIdentity</code> is intended for low-throughput control plane operations: for example, to enable customer service to locate an identity ID by username. If you are using it for higher-volume operations such as user authentication, your requests are likely to be throttled. <a>GetOpenIdTokenForDeveloperIdentity</a> is a better option for higher-volume operations for user authentication.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_594179 = header.getOrDefault("X-Amz-Target")
  valid_594179 = validateParameter(valid_594179, JString, required = true, default = newJString(
      "AWSCognitoIdentityService.LookupDeveloperIdentity"))
  if valid_594179 != nil:
    section.add "X-Amz-Target", valid_594179
  var valid_594180 = header.getOrDefault("X-Amz-Signature")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = nil)
  if valid_594180 != nil:
    section.add "X-Amz-Signature", valid_594180
  var valid_594181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Content-Sha256", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-Date")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Date", valid_594182
  var valid_594183 = header.getOrDefault("X-Amz-Credential")
  valid_594183 = validateParameter(valid_594183, JString, required = false,
                                 default = nil)
  if valid_594183 != nil:
    section.add "X-Amz-Credential", valid_594183
  var valid_594184 = header.getOrDefault("X-Amz-Security-Token")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-Security-Token", valid_594184
  var valid_594185 = header.getOrDefault("X-Amz-Algorithm")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Algorithm", valid_594185
  var valid_594186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-SignedHeaders", valid_594186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594188: Call_LookupDeveloperIdentity_594176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the <code>IdentityID</code> associated with a <code>DeveloperUserIdentifier</code> or the list of <code>DeveloperUserIdentifier</code> values associated with an <code>IdentityId</code> for an existing identity. Either <code>IdentityID</code> or <code>DeveloperUserIdentifier</code> must not be null. If you supply only one of these values, the other value will be searched in the database and returned as a part of the response. If you supply both, <code>DeveloperUserIdentifier</code> will be matched against <code>IdentityID</code>. If the values are verified against the database, the response returns both values and is the same as the request. Otherwise a <code>ResourceConflictException</code> is thrown.</p> <p> <code>LookupDeveloperIdentity</code> is intended for low-throughput control plane operations: for example, to enable customer service to locate an identity ID by username. If you are using it for higher-volume operations such as user authentication, your requests are likely to be throttled. <a>GetOpenIdTokenForDeveloperIdentity</a> is a better option for higher-volume operations for user authentication.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  let valid = call_594188.validator(path, query, header, formData, body)
  let scheme = call_594188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594188.url(scheme.get, call_594188.host, call_594188.base,
                         call_594188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594188, url, valid)

proc call*(call_594189: Call_LookupDeveloperIdentity_594176; body: JsonNode): Recallable =
  ## lookupDeveloperIdentity
  ## <p>Retrieves the <code>IdentityID</code> associated with a <code>DeveloperUserIdentifier</code> or the list of <code>DeveloperUserIdentifier</code> values associated with an <code>IdentityId</code> for an existing identity. Either <code>IdentityID</code> or <code>DeveloperUserIdentifier</code> must not be null. If you supply only one of these values, the other value will be searched in the database and returned as a part of the response. If you supply both, <code>DeveloperUserIdentifier</code> will be matched against <code>IdentityID</code>. If the values are verified against the database, the response returns both values and is the same as the request. Otherwise a <code>ResourceConflictException</code> is thrown.</p> <p> <code>LookupDeveloperIdentity</code> is intended for low-throughput control plane operations: for example, to enable customer service to locate an identity ID by username. If you are using it for higher-volume operations such as user authentication, your requests are likely to be throttled. <a>GetOpenIdTokenForDeveloperIdentity</a> is a better option for higher-volume operations for user authentication.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ##   body: JObject (required)
  var body_594190 = newJObject()
  if body != nil:
    body_594190 = body
  result = call_594189.call(nil, nil, nil, nil, body_594190)

var lookupDeveloperIdentity* = Call_LookupDeveloperIdentity_594176(
    name: "lookupDeveloperIdentity", meth: HttpMethod.HttpPost,
    host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.LookupDeveloperIdentity",
    validator: validate_LookupDeveloperIdentity_594177, base: "/",
    url: url_LookupDeveloperIdentity_594178, schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergeDeveloperIdentities_594191 = ref object of OpenApiRestCall_593389
proc url_MergeDeveloperIdentities_594193(protocol: Scheme; host: string;
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

proc validate_MergeDeveloperIdentities_594192(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Merges two users having different <code>IdentityId</code>s, existing in the same identity pool, and identified by the same developer provider. You can use this action to request that discrete users be merged and identified as a single user in the Cognito environment. Cognito associates the given source user (<code>SourceUserIdentifier</code>) with the <code>IdentityId</code> of the <code>DestinationUserIdentifier</code>. Only developer-authenticated users can be merged. If the users to be merged are associated with the same public provider, but as two different users, an exception will be thrown.</p> <p>The number of linked logins is limited to 20. So, the number of linked logins for the source user, <code>SourceUserIdentifier</code>, and the destination user, <code>DestinationUserIdentifier</code>, together should not be larger than 20. Otherwise, an exception will be thrown.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_594194 = header.getOrDefault("X-Amz-Target")
  valid_594194 = validateParameter(valid_594194, JString, required = true, default = newJString(
      "AWSCognitoIdentityService.MergeDeveloperIdentities"))
  if valid_594194 != nil:
    section.add "X-Amz-Target", valid_594194
  var valid_594195 = header.getOrDefault("X-Amz-Signature")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "X-Amz-Signature", valid_594195
  var valid_594196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Content-Sha256", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Date")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Date", valid_594197
  var valid_594198 = header.getOrDefault("X-Amz-Credential")
  valid_594198 = validateParameter(valid_594198, JString, required = false,
                                 default = nil)
  if valid_594198 != nil:
    section.add "X-Amz-Credential", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-Security-Token")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Security-Token", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-Algorithm")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Algorithm", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-SignedHeaders", valid_594201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594203: Call_MergeDeveloperIdentities_594191; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Merges two users having different <code>IdentityId</code>s, existing in the same identity pool, and identified by the same developer provider. You can use this action to request that discrete users be merged and identified as a single user in the Cognito environment. Cognito associates the given source user (<code>SourceUserIdentifier</code>) with the <code>IdentityId</code> of the <code>DestinationUserIdentifier</code>. Only developer-authenticated users can be merged. If the users to be merged are associated with the same public provider, but as two different users, an exception will be thrown.</p> <p>The number of linked logins is limited to 20. So, the number of linked logins for the source user, <code>SourceUserIdentifier</code>, and the destination user, <code>DestinationUserIdentifier</code>, together should not be larger than 20. Otherwise, an exception will be thrown.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  let valid = call_594203.validator(path, query, header, formData, body)
  let scheme = call_594203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594203.url(scheme.get, call_594203.host, call_594203.base,
                         call_594203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594203, url, valid)

proc call*(call_594204: Call_MergeDeveloperIdentities_594191; body: JsonNode): Recallable =
  ## mergeDeveloperIdentities
  ## <p>Merges two users having different <code>IdentityId</code>s, existing in the same identity pool, and identified by the same developer provider. You can use this action to request that discrete users be merged and identified as a single user in the Cognito environment. Cognito associates the given source user (<code>SourceUserIdentifier</code>) with the <code>IdentityId</code> of the <code>DestinationUserIdentifier</code>. Only developer-authenticated users can be merged. If the users to be merged are associated with the same public provider, but as two different users, an exception will be thrown.</p> <p>The number of linked logins is limited to 20. So, the number of linked logins for the source user, <code>SourceUserIdentifier</code>, and the destination user, <code>DestinationUserIdentifier</code>, together should not be larger than 20. Otherwise, an exception will be thrown.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ##   body: JObject (required)
  var body_594205 = newJObject()
  if body != nil:
    body_594205 = body
  result = call_594204.call(nil, nil, nil, nil, body_594205)

var mergeDeveloperIdentities* = Call_MergeDeveloperIdentities_594191(
    name: "mergeDeveloperIdentities", meth: HttpMethod.HttpPost,
    host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.MergeDeveloperIdentities",
    validator: validate_MergeDeveloperIdentities_594192, base: "/",
    url: url_MergeDeveloperIdentities_594193, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetIdentityPoolRoles_594206 = ref object of OpenApiRestCall_593389
proc url_SetIdentityPoolRoles_594208(protocol: Scheme; host: string; base: string;
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

proc validate_SetIdentityPoolRoles_594207(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sets the roles for an identity pool. These roles are used when making calls to <a>GetCredentialsForIdentity</a> action.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_594209 = header.getOrDefault("X-Amz-Target")
  valid_594209 = validateParameter(valid_594209, JString, required = true, default = newJString(
      "AWSCognitoIdentityService.SetIdentityPoolRoles"))
  if valid_594209 != nil:
    section.add "X-Amz-Target", valid_594209
  var valid_594210 = header.getOrDefault("X-Amz-Signature")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "X-Amz-Signature", valid_594210
  var valid_594211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Content-Sha256", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Date")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Date", valid_594212
  var valid_594213 = header.getOrDefault("X-Amz-Credential")
  valid_594213 = validateParameter(valid_594213, JString, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "X-Amz-Credential", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-Security-Token")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Security-Token", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-Algorithm")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Algorithm", valid_594215
  var valid_594216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-SignedHeaders", valid_594216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594218: Call_SetIdentityPoolRoles_594206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the roles for an identity pool. These roles are used when making calls to <a>GetCredentialsForIdentity</a> action.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  let valid = call_594218.validator(path, query, header, formData, body)
  let scheme = call_594218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594218.url(scheme.get, call_594218.host, call_594218.base,
                         call_594218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594218, url, valid)

proc call*(call_594219: Call_SetIdentityPoolRoles_594206; body: JsonNode): Recallable =
  ## setIdentityPoolRoles
  ## <p>Sets the roles for an identity pool. These roles are used when making calls to <a>GetCredentialsForIdentity</a> action.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ##   body: JObject (required)
  var body_594220 = newJObject()
  if body != nil:
    body_594220 = body
  result = call_594219.call(nil, nil, nil, nil, body_594220)

var setIdentityPoolRoles* = Call_SetIdentityPoolRoles_594206(
    name: "setIdentityPoolRoles", meth: HttpMethod.HttpPost,
    host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.SetIdentityPoolRoles",
    validator: validate_SetIdentityPoolRoles_594207, base: "/",
    url: url_SetIdentityPoolRoles_594208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_594221 = ref object of OpenApiRestCall_593389
proc url_TagResource_594223(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_594222(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Assigns a set of tags to an Amazon Cognito identity pool. A tag is a label that you can use to categorize and manage identity pools in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>Each tag consists of a key and value, both of which you define. A key is a general category for more specific values. For example, if you have two versions of an identity pool, one for testing and another for production, you might assign an <code>Environment</code> tag key to both identity pools. The value of this key might be <code>Test</code> for one identity pool and <code>Production</code> for the other.</p> <p>Tags are useful for cost tracking and access control. You can activate your tags so that they appear on the Billing and Cost Management console, where you can track the costs associated with your identity pools. In an IAM policy, you can constrain permissions for identity pools based on specific tags or tag values.</p> <p>You can use this action up to 5 times per second, per account. An identity pool can have as many as 50 tags.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_594224 = header.getOrDefault("X-Amz-Target")
  valid_594224 = validateParameter(valid_594224, JString, required = true, default = newJString(
      "AWSCognitoIdentityService.TagResource"))
  if valid_594224 != nil:
    section.add "X-Amz-Target", valid_594224
  var valid_594225 = header.getOrDefault("X-Amz-Signature")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "X-Amz-Signature", valid_594225
  var valid_594226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Content-Sha256", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-Date")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-Date", valid_594227
  var valid_594228 = header.getOrDefault("X-Amz-Credential")
  valid_594228 = validateParameter(valid_594228, JString, required = false,
                                 default = nil)
  if valid_594228 != nil:
    section.add "X-Amz-Credential", valid_594228
  var valid_594229 = header.getOrDefault("X-Amz-Security-Token")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "X-Amz-Security-Token", valid_594229
  var valid_594230 = header.getOrDefault("X-Amz-Algorithm")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "X-Amz-Algorithm", valid_594230
  var valid_594231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594231 = validateParameter(valid_594231, JString, required = false,
                                 default = nil)
  if valid_594231 != nil:
    section.add "X-Amz-SignedHeaders", valid_594231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594233: Call_TagResource_594221; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns a set of tags to an Amazon Cognito identity pool. A tag is a label that you can use to categorize and manage identity pools in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>Each tag consists of a key and value, both of which you define. A key is a general category for more specific values. For example, if you have two versions of an identity pool, one for testing and another for production, you might assign an <code>Environment</code> tag key to both identity pools. The value of this key might be <code>Test</code> for one identity pool and <code>Production</code> for the other.</p> <p>Tags are useful for cost tracking and access control. You can activate your tags so that they appear on the Billing and Cost Management console, where you can track the costs associated with your identity pools. In an IAM policy, you can constrain permissions for identity pools based on specific tags or tag values.</p> <p>You can use this action up to 5 times per second, per account. An identity pool can have as many as 50 tags.</p>
  ## 
  let valid = call_594233.validator(path, query, header, formData, body)
  let scheme = call_594233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594233.url(scheme.get, call_594233.host, call_594233.base,
                         call_594233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594233, url, valid)

proc call*(call_594234: Call_TagResource_594221; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Assigns a set of tags to an Amazon Cognito identity pool. A tag is a label that you can use to categorize and manage identity pools in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>Each tag consists of a key and value, both of which you define. A key is a general category for more specific values. For example, if you have two versions of an identity pool, one for testing and another for production, you might assign an <code>Environment</code> tag key to both identity pools. The value of this key might be <code>Test</code> for one identity pool and <code>Production</code> for the other.</p> <p>Tags are useful for cost tracking and access control. You can activate your tags so that they appear on the Billing and Cost Management console, where you can track the costs associated with your identity pools. In an IAM policy, you can constrain permissions for identity pools based on specific tags or tag values.</p> <p>You can use this action up to 5 times per second, per account. An identity pool can have as many as 50 tags.</p>
  ##   body: JObject (required)
  var body_594235 = newJObject()
  if body != nil:
    body_594235 = body
  result = call_594234.call(nil, nil, nil, nil, body_594235)

var tagResource* = Call_TagResource_594221(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-identity.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityService.TagResource",
                                        validator: validate_TagResource_594222,
                                        base: "/", url: url_TagResource_594223,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnlinkDeveloperIdentity_594236 = ref object of OpenApiRestCall_593389
proc url_UnlinkDeveloperIdentity_594238(protocol: Scheme; host: string; base: string;
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

proc validate_UnlinkDeveloperIdentity_594237(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Unlinks a <code>DeveloperUserIdentifier</code> from an existing identity. Unlinked developer users will be considered new identities next time they are seen. If, for a given Cognito identity, you remove all federated identities as well as the developer user identifier, the Cognito identity becomes inaccessible.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_594239 = header.getOrDefault("X-Amz-Target")
  valid_594239 = validateParameter(valid_594239, JString, required = true, default = newJString(
      "AWSCognitoIdentityService.UnlinkDeveloperIdentity"))
  if valid_594239 != nil:
    section.add "X-Amz-Target", valid_594239
  var valid_594240 = header.getOrDefault("X-Amz-Signature")
  valid_594240 = validateParameter(valid_594240, JString, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "X-Amz-Signature", valid_594240
  var valid_594241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-Content-Sha256", valid_594241
  var valid_594242 = header.getOrDefault("X-Amz-Date")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Date", valid_594242
  var valid_594243 = header.getOrDefault("X-Amz-Credential")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = nil)
  if valid_594243 != nil:
    section.add "X-Amz-Credential", valid_594243
  var valid_594244 = header.getOrDefault("X-Amz-Security-Token")
  valid_594244 = validateParameter(valid_594244, JString, required = false,
                                 default = nil)
  if valid_594244 != nil:
    section.add "X-Amz-Security-Token", valid_594244
  var valid_594245 = header.getOrDefault("X-Amz-Algorithm")
  valid_594245 = validateParameter(valid_594245, JString, required = false,
                                 default = nil)
  if valid_594245 != nil:
    section.add "X-Amz-Algorithm", valid_594245
  var valid_594246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "X-Amz-SignedHeaders", valid_594246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594248: Call_UnlinkDeveloperIdentity_594236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Unlinks a <code>DeveloperUserIdentifier</code> from an existing identity. Unlinked developer users will be considered new identities next time they are seen. If, for a given Cognito identity, you remove all federated identities as well as the developer user identifier, the Cognito identity becomes inaccessible.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  let valid = call_594248.validator(path, query, header, formData, body)
  let scheme = call_594248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594248.url(scheme.get, call_594248.host, call_594248.base,
                         call_594248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594248, url, valid)

proc call*(call_594249: Call_UnlinkDeveloperIdentity_594236; body: JsonNode): Recallable =
  ## unlinkDeveloperIdentity
  ## <p>Unlinks a <code>DeveloperUserIdentifier</code> from an existing identity. Unlinked developer users will be considered new identities next time they are seen. If, for a given Cognito identity, you remove all federated identities as well as the developer user identifier, the Cognito identity becomes inaccessible.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ##   body: JObject (required)
  var body_594250 = newJObject()
  if body != nil:
    body_594250 = body
  result = call_594249.call(nil, nil, nil, nil, body_594250)

var unlinkDeveloperIdentity* = Call_UnlinkDeveloperIdentity_594236(
    name: "unlinkDeveloperIdentity", meth: HttpMethod.HttpPost,
    host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.UnlinkDeveloperIdentity",
    validator: validate_UnlinkDeveloperIdentity_594237, base: "/",
    url: url_UnlinkDeveloperIdentity_594238, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnlinkIdentity_594251 = ref object of OpenApiRestCall_593389
proc url_UnlinkIdentity_594253(protocol: Scheme; host: string; base: string;
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

proc validate_UnlinkIdentity_594252(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Unlinks a federated identity from an existing account. Unlinked logins will be considered new identities next time they are seen. Removing the last linked login will make this identity inaccessible.</p> <p>This is a public API. You do not need any credentials to call this API.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_594254 = header.getOrDefault("X-Amz-Target")
  valid_594254 = validateParameter(valid_594254, JString, required = true, default = newJString(
      "AWSCognitoIdentityService.UnlinkIdentity"))
  if valid_594254 != nil:
    section.add "X-Amz-Target", valid_594254
  var valid_594255 = header.getOrDefault("X-Amz-Signature")
  valid_594255 = validateParameter(valid_594255, JString, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "X-Amz-Signature", valid_594255
  var valid_594256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Content-Sha256", valid_594256
  var valid_594257 = header.getOrDefault("X-Amz-Date")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-Date", valid_594257
  var valid_594258 = header.getOrDefault("X-Amz-Credential")
  valid_594258 = validateParameter(valid_594258, JString, required = false,
                                 default = nil)
  if valid_594258 != nil:
    section.add "X-Amz-Credential", valid_594258
  var valid_594259 = header.getOrDefault("X-Amz-Security-Token")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "X-Amz-Security-Token", valid_594259
  var valid_594260 = header.getOrDefault("X-Amz-Algorithm")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "X-Amz-Algorithm", valid_594260
  var valid_594261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594261 = validateParameter(valid_594261, JString, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "X-Amz-SignedHeaders", valid_594261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594263: Call_UnlinkIdentity_594251; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Unlinks a federated identity from an existing account. Unlinked logins will be considered new identities next time they are seen. Removing the last linked login will make this identity inaccessible.</p> <p>This is a public API. You do not need any credentials to call this API.</p>
  ## 
  let valid = call_594263.validator(path, query, header, formData, body)
  let scheme = call_594263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594263.url(scheme.get, call_594263.host, call_594263.base,
                         call_594263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594263, url, valid)

proc call*(call_594264: Call_UnlinkIdentity_594251; body: JsonNode): Recallable =
  ## unlinkIdentity
  ## <p>Unlinks a federated identity from an existing account. Unlinked logins will be considered new identities next time they are seen. Removing the last linked login will make this identity inaccessible.</p> <p>This is a public API. You do not need any credentials to call this API.</p>
  ##   body: JObject (required)
  var body_594265 = newJObject()
  if body != nil:
    body_594265 = body
  result = call_594264.call(nil, nil, nil, nil, body_594265)

var unlinkIdentity* = Call_UnlinkIdentity_594251(name: "unlinkIdentity",
    meth: HttpMethod.HttpPost, host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.UnlinkIdentity",
    validator: validate_UnlinkIdentity_594252, base: "/", url: url_UnlinkIdentity_594253,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_594266 = ref object of OpenApiRestCall_593389
proc url_UntagResource_594268(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_594267(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the specified tags from an Amazon Cognito identity pool. You can use this action up to 5 times per second, per account
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_594269 = header.getOrDefault("X-Amz-Target")
  valid_594269 = validateParameter(valid_594269, JString, required = true, default = newJString(
      "AWSCognitoIdentityService.UntagResource"))
  if valid_594269 != nil:
    section.add "X-Amz-Target", valid_594269
  var valid_594270 = header.getOrDefault("X-Amz-Signature")
  valid_594270 = validateParameter(valid_594270, JString, required = false,
                                 default = nil)
  if valid_594270 != nil:
    section.add "X-Amz-Signature", valid_594270
  var valid_594271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594271 = validateParameter(valid_594271, JString, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "X-Amz-Content-Sha256", valid_594271
  var valid_594272 = header.getOrDefault("X-Amz-Date")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "X-Amz-Date", valid_594272
  var valid_594273 = header.getOrDefault("X-Amz-Credential")
  valid_594273 = validateParameter(valid_594273, JString, required = false,
                                 default = nil)
  if valid_594273 != nil:
    section.add "X-Amz-Credential", valid_594273
  var valid_594274 = header.getOrDefault("X-Amz-Security-Token")
  valid_594274 = validateParameter(valid_594274, JString, required = false,
                                 default = nil)
  if valid_594274 != nil:
    section.add "X-Amz-Security-Token", valid_594274
  var valid_594275 = header.getOrDefault("X-Amz-Algorithm")
  valid_594275 = validateParameter(valid_594275, JString, required = false,
                                 default = nil)
  if valid_594275 != nil:
    section.add "X-Amz-Algorithm", valid_594275
  var valid_594276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594276 = validateParameter(valid_594276, JString, required = false,
                                 default = nil)
  if valid_594276 != nil:
    section.add "X-Amz-SignedHeaders", valid_594276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594278: Call_UntagResource_594266; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified tags from an Amazon Cognito identity pool. You can use this action up to 5 times per second, per account
  ## 
  let valid = call_594278.validator(path, query, header, formData, body)
  let scheme = call_594278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594278.url(scheme.get, call_594278.host, call_594278.base,
                         call_594278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594278, url, valid)

proc call*(call_594279: Call_UntagResource_594266; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tags from an Amazon Cognito identity pool. You can use this action up to 5 times per second, per account
  ##   body: JObject (required)
  var body_594280 = newJObject()
  if body != nil:
    body_594280 = body
  result = call_594279.call(nil, nil, nil, nil, body_594280)

var untagResource* = Call_UntagResource_594266(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.UntagResource",
    validator: validate_UntagResource_594267, base: "/", url: url_UntagResource_594268,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIdentityPool_594281 = ref object of OpenApiRestCall_593389
proc url_UpdateIdentityPool_594283(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateIdentityPool_594282(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Updates an identity pool.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_594284 = header.getOrDefault("X-Amz-Target")
  valid_594284 = validateParameter(valid_594284, JString, required = true, default = newJString(
      "AWSCognitoIdentityService.UpdateIdentityPool"))
  if valid_594284 != nil:
    section.add "X-Amz-Target", valid_594284
  var valid_594285 = header.getOrDefault("X-Amz-Signature")
  valid_594285 = validateParameter(valid_594285, JString, required = false,
                                 default = nil)
  if valid_594285 != nil:
    section.add "X-Amz-Signature", valid_594285
  var valid_594286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "X-Amz-Content-Sha256", valid_594286
  var valid_594287 = header.getOrDefault("X-Amz-Date")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-Date", valid_594287
  var valid_594288 = header.getOrDefault("X-Amz-Credential")
  valid_594288 = validateParameter(valid_594288, JString, required = false,
                                 default = nil)
  if valid_594288 != nil:
    section.add "X-Amz-Credential", valid_594288
  var valid_594289 = header.getOrDefault("X-Amz-Security-Token")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "X-Amz-Security-Token", valid_594289
  var valid_594290 = header.getOrDefault("X-Amz-Algorithm")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "X-Amz-Algorithm", valid_594290
  var valid_594291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-SignedHeaders", valid_594291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594293: Call_UpdateIdentityPool_594281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an identity pool.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  let valid = call_594293.validator(path, query, header, formData, body)
  let scheme = call_594293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594293.url(scheme.get, call_594293.host, call_594293.base,
                         call_594293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594293, url, valid)

proc call*(call_594294: Call_UpdateIdentityPool_594281; body: JsonNode): Recallable =
  ## updateIdentityPool
  ## <p>Updates an identity pool.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ##   body: JObject (required)
  var body_594295 = newJObject()
  if body != nil:
    body_594295 = body
  result = call_594294.call(nil, nil, nil, nil, body_594295)

var updateIdentityPool* = Call_UpdateIdentityPool_594281(
    name: "updateIdentityPool", meth: HttpMethod.HttpPost,
    host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.UpdateIdentityPool",
    validator: validate_UpdateIdentityPool_594282, base: "/",
    url: url_UpdateIdentityPool_594283, schemes: {Scheme.Https, Scheme.Http})
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

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
