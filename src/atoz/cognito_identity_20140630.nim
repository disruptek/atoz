
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateIdentityPool_602770 = ref object of OpenApiRestCall_602433
proc url_CreateIdentityPool_602772(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateIdentityPool_602771(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Creates a new identity pool. The identity pool is a store of user identity information that is specific to your AWS account. The limit on identity pools is 60 per account. The keys for <code>SupportedLoginProviders</code> are as follows:</p> <ul> <li> <p>Facebook: <code>graph.facebook.com</code> </p> </li> <li> <p>Google: <code>accounts.google.com</code> </p> </li> <li> <p>Amazon: <code>www.amazon.com</code> </p> </li> <li> <p>Twitter: <code>api.twitter.com</code> </p> </li> <li> <p>Digits: <code>www.digits.com</code> </p> </li> </ul> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
      "AWSCognitoIdentityService.CreateIdentityPool"))
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

proc call*(call_602928: Call_CreateIdentityPool_602770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new identity pool. The identity pool is a store of user identity information that is specific to your AWS account. The limit on identity pools is 60 per account. The keys for <code>SupportedLoginProviders</code> are as follows:</p> <ul> <li> <p>Facebook: <code>graph.facebook.com</code> </p> </li> <li> <p>Google: <code>accounts.google.com</code> </p> </li> <li> <p>Amazon: <code>www.amazon.com</code> </p> </li> <li> <p>Twitter: <code>api.twitter.com</code> </p> </li> <li> <p>Digits: <code>www.digits.com</code> </p> </li> </ul> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  let valid = call_602928.validator(path, query, header, formData, body)
  let scheme = call_602928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602928.url(scheme.get, call_602928.host, call_602928.base,
                         call_602928.route, valid.getOrDefault("path"))
  result = hook(call_602928, url, valid)

proc call*(call_602999: Call_CreateIdentityPool_602770; body: JsonNode): Recallable =
  ## createIdentityPool
  ## <p>Creates a new identity pool. The identity pool is a store of user identity information that is specific to your AWS account. The limit on identity pools is 60 per account. The keys for <code>SupportedLoginProviders</code> are as follows:</p> <ul> <li> <p>Facebook: <code>graph.facebook.com</code> </p> </li> <li> <p>Google: <code>accounts.google.com</code> </p> </li> <li> <p>Amazon: <code>www.amazon.com</code> </p> </li> <li> <p>Twitter: <code>api.twitter.com</code> </p> </li> <li> <p>Digits: <code>www.digits.com</code> </p> </li> </ul> <p>You must use AWS Developer credentials to call this API.</p>
  ##   body: JObject (required)
  var body_603000 = newJObject()
  if body != nil:
    body_603000 = body
  result = call_602999.call(nil, nil, nil, nil, body_603000)

var createIdentityPool* = Call_CreateIdentityPool_602770(
    name: "createIdentityPool", meth: HttpMethod.HttpPost,
    host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.CreateIdentityPool",
    validator: validate_CreateIdentityPool_602771, base: "/",
    url: url_CreateIdentityPool_602772, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIdentities_603039 = ref object of OpenApiRestCall_602433
proc url_DeleteIdentities_603041(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteIdentities_603040(path: JsonNode; query: JsonNode;
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
      "AWSCognitoIdentityService.DeleteIdentities"))
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

proc call*(call_603051: Call_DeleteIdentities_603039; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes identities from an identity pool. You can specify a list of 1-60 identities that you want to delete.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  let valid = call_603051.validator(path, query, header, formData, body)
  let scheme = call_603051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603051.url(scheme.get, call_603051.host, call_603051.base,
                         call_603051.route, valid.getOrDefault("path"))
  result = hook(call_603051, url, valid)

proc call*(call_603052: Call_DeleteIdentities_603039; body: JsonNode): Recallable =
  ## deleteIdentities
  ## <p>Deletes identities from an identity pool. You can specify a list of 1-60 identities that you want to delete.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ##   body: JObject (required)
  var body_603053 = newJObject()
  if body != nil:
    body_603053 = body
  result = call_603052.call(nil, nil, nil, nil, body_603053)

var deleteIdentities* = Call_DeleteIdentities_603039(name: "deleteIdentities",
    meth: HttpMethod.HttpPost, host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.DeleteIdentities",
    validator: validate_DeleteIdentities_603040, base: "/",
    url: url_DeleteIdentities_603041, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIdentityPool_603054 = ref object of OpenApiRestCall_602433
proc url_DeleteIdentityPool_603056(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteIdentityPool_603055(path: JsonNode; query: JsonNode;
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
      "AWSCognitoIdentityService.DeleteIdentityPool"))
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

proc call*(call_603066: Call_DeleteIdentityPool_603054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an identity pool. Once a pool is deleted, users will not be able to authenticate with the pool.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  let valid = call_603066.validator(path, query, header, formData, body)
  let scheme = call_603066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603066.url(scheme.get, call_603066.host, call_603066.base,
                         call_603066.route, valid.getOrDefault("path"))
  result = hook(call_603066, url, valid)

proc call*(call_603067: Call_DeleteIdentityPool_603054; body: JsonNode): Recallable =
  ## deleteIdentityPool
  ## <p>Deletes an identity pool. Once a pool is deleted, users will not be able to authenticate with the pool.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ##   body: JObject (required)
  var body_603068 = newJObject()
  if body != nil:
    body_603068 = body
  result = call_603067.call(nil, nil, nil, nil, body_603068)

var deleteIdentityPool* = Call_DeleteIdentityPool_603054(
    name: "deleteIdentityPool", meth: HttpMethod.HttpPost,
    host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.DeleteIdentityPool",
    validator: validate_DeleteIdentityPool_603055, base: "/",
    url: url_DeleteIdentityPool_603056, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentity_603069 = ref object of OpenApiRestCall_602433
proc url_DescribeIdentity_603071(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeIdentity_603070(path: JsonNode; query: JsonNode;
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
      "AWSCognitoIdentityService.DescribeIdentity"))
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

proc call*(call_603081: Call_DescribeIdentity_603069; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns metadata related to the given identity, including when the identity was created and any associated linked logins.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  let valid = call_603081.validator(path, query, header, formData, body)
  let scheme = call_603081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603081.url(scheme.get, call_603081.host, call_603081.base,
                         call_603081.route, valid.getOrDefault("path"))
  result = hook(call_603081, url, valid)

proc call*(call_603082: Call_DescribeIdentity_603069; body: JsonNode): Recallable =
  ## describeIdentity
  ## <p>Returns metadata related to the given identity, including when the identity was created and any associated linked logins.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ##   body: JObject (required)
  var body_603083 = newJObject()
  if body != nil:
    body_603083 = body
  result = call_603082.call(nil, nil, nil, nil, body_603083)

var describeIdentity* = Call_DescribeIdentity_603069(name: "describeIdentity",
    meth: HttpMethod.HttpPost, host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.DescribeIdentity",
    validator: validate_DescribeIdentity_603070, base: "/",
    url: url_DescribeIdentity_603071, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentityPool_603084 = ref object of OpenApiRestCall_602433
proc url_DescribeIdentityPool_603086(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeIdentityPool_603085(path: JsonNode; query: JsonNode;
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
      "AWSCognitoIdentityService.DescribeIdentityPool"))
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

proc call*(call_603096: Call_DescribeIdentityPool_603084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets details about a particular identity pool, including the pool name, ID description, creation date, and current number of users.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  let valid = call_603096.validator(path, query, header, formData, body)
  let scheme = call_603096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603096.url(scheme.get, call_603096.host, call_603096.base,
                         call_603096.route, valid.getOrDefault("path"))
  result = hook(call_603096, url, valid)

proc call*(call_603097: Call_DescribeIdentityPool_603084; body: JsonNode): Recallable =
  ## describeIdentityPool
  ## <p>Gets details about a particular identity pool, including the pool name, ID description, creation date, and current number of users.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ##   body: JObject (required)
  var body_603098 = newJObject()
  if body != nil:
    body_603098 = body
  result = call_603097.call(nil, nil, nil, nil, body_603098)

var describeIdentityPool* = Call_DescribeIdentityPool_603084(
    name: "describeIdentityPool", meth: HttpMethod.HttpPost,
    host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.DescribeIdentityPool",
    validator: validate_DescribeIdentityPool_603085, base: "/",
    url: url_DescribeIdentityPool_603086, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCredentialsForIdentity_603099 = ref object of OpenApiRestCall_602433
proc url_GetCredentialsForIdentity_603101(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCredentialsForIdentity_603100(path: JsonNode; query: JsonNode;
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
      "AWSCognitoIdentityService.GetCredentialsForIdentity"))
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

proc call*(call_603111: Call_GetCredentialsForIdentity_603099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns credentials for the provided identity ID. Any provided logins will be validated against supported login providers. If the token is for cognito-identity.amazonaws.com, it will be passed through to AWS Security Token Service with the appropriate role for the token.</p> <p>This is a public API. You do not need any credentials to call this API.</p>
  ## 
  let valid = call_603111.validator(path, query, header, formData, body)
  let scheme = call_603111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603111.url(scheme.get, call_603111.host, call_603111.base,
                         call_603111.route, valid.getOrDefault("path"))
  result = hook(call_603111, url, valid)

proc call*(call_603112: Call_GetCredentialsForIdentity_603099; body: JsonNode): Recallable =
  ## getCredentialsForIdentity
  ## <p>Returns credentials for the provided identity ID. Any provided logins will be validated against supported login providers. If the token is for cognito-identity.amazonaws.com, it will be passed through to AWS Security Token Service with the appropriate role for the token.</p> <p>This is a public API. You do not need any credentials to call this API.</p>
  ##   body: JObject (required)
  var body_603113 = newJObject()
  if body != nil:
    body_603113 = body
  result = call_603112.call(nil, nil, nil, nil, body_603113)

var getCredentialsForIdentity* = Call_GetCredentialsForIdentity_603099(
    name: "getCredentialsForIdentity", meth: HttpMethod.HttpPost,
    host: "cognito-identity.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityService.GetCredentialsForIdentity",
    validator: validate_GetCredentialsForIdentity_603100, base: "/",
    url: url_GetCredentialsForIdentity_603101,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetId_603114 = ref object of OpenApiRestCall_602433
proc url_GetId_603116(protocol: Scheme; host: string; base: string; route: string;
                     path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetId_603115(path: JsonNode; query: JsonNode; header: JsonNode;
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
      "AWSCognitoIdentityService.GetId"))
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

proc call*(call_603126: Call_GetId_603114; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Generates (or retrieves) a Cognito ID. Supplying multiple logins will create an implicit linked account.</p> <p>This is a public API. You do not need any credentials to call this API.</p>
  ## 
  let valid = call_603126.validator(path, query, header, formData, body)
  let scheme = call_603126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603126.url(scheme.get, call_603126.host, call_603126.base,
                         call_603126.route, valid.getOrDefault("path"))
  result = hook(call_603126, url, valid)

proc call*(call_603127: Call_GetId_603114; body: JsonNode): Recallable =
  ## getId
  ## <p>Generates (or retrieves) a Cognito ID. Supplying multiple logins will create an implicit linked account.</p> <p>This is a public API. You do not need any credentials to call this API.</p>
  ##   body: JObject (required)
  var body_603128 = newJObject()
  if body != nil:
    body_603128 = body
  result = call_603127.call(nil, nil, nil, nil, body_603128)

var getId* = Call_GetId_603114(name: "getId", meth: HttpMethod.HttpPost,
                            host: "cognito-identity.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityService.GetId",
                            validator: validate_GetId_603115, base: "/",
                            url: url_GetId_603116,
                            schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIdentityPoolRoles_603129 = ref object of OpenApiRestCall_602433
proc url_GetIdentityPoolRoles_603131(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetIdentityPoolRoles_603130(path: JsonNode; query: JsonNode;
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
      "AWSCognitoIdentityService.GetIdentityPoolRoles"))
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

proc call*(call_603141: Call_GetIdentityPoolRoles_603129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the roles for an identity pool.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  let valid = call_603141.validator(path, query, header, formData, body)
  let scheme = call_603141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603141.url(scheme.get, call_603141.host, call_603141.base,
                         call_603141.route, valid.getOrDefault("path"))
  result = hook(call_603141, url, valid)

proc call*(call_603142: Call_GetIdentityPoolRoles_603129; body: JsonNode): Recallable =
  ## getIdentityPoolRoles
  ## <p>Gets the roles for an identity pool.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ##   body: JObject (required)
  var body_603143 = newJObject()
  if body != nil:
    body_603143 = body
  result = call_603142.call(nil, nil, nil, nil, body_603143)

var getIdentityPoolRoles* = Call_GetIdentityPoolRoles_603129(
    name: "getIdentityPoolRoles", meth: HttpMethod.HttpPost,
    host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.GetIdentityPoolRoles",
    validator: validate_GetIdentityPoolRoles_603130, base: "/",
    url: url_GetIdentityPoolRoles_603131, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOpenIdToken_603144 = ref object of OpenApiRestCall_602433
proc url_GetOpenIdToken_603146(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetOpenIdToken_603145(path: JsonNode; query: JsonNode;
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
      "AWSCognitoIdentityService.GetOpenIdToken"))
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

proc call*(call_603156: Call_GetOpenIdToken_603144; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets an OpenID token, using a known Cognito ID. This known Cognito ID is returned by <a>GetId</a>. You can optionally add additional logins for the identity. Supplying multiple logins creates an implicit link.</p> <p>The OpenId token is valid for 10 minutes.</p> <p>This is a public API. You do not need any credentials to call this API.</p>
  ## 
  let valid = call_603156.validator(path, query, header, formData, body)
  let scheme = call_603156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603156.url(scheme.get, call_603156.host, call_603156.base,
                         call_603156.route, valid.getOrDefault("path"))
  result = hook(call_603156, url, valid)

proc call*(call_603157: Call_GetOpenIdToken_603144; body: JsonNode): Recallable =
  ## getOpenIdToken
  ## <p>Gets an OpenID token, using a known Cognito ID. This known Cognito ID is returned by <a>GetId</a>. You can optionally add additional logins for the identity. Supplying multiple logins creates an implicit link.</p> <p>The OpenId token is valid for 10 minutes.</p> <p>This is a public API. You do not need any credentials to call this API.</p>
  ##   body: JObject (required)
  var body_603158 = newJObject()
  if body != nil:
    body_603158 = body
  result = call_603157.call(nil, nil, nil, nil, body_603158)

var getOpenIdToken* = Call_GetOpenIdToken_603144(name: "getOpenIdToken",
    meth: HttpMethod.HttpPost, host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.GetOpenIdToken",
    validator: validate_GetOpenIdToken_603145, base: "/", url: url_GetOpenIdToken_603146,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOpenIdTokenForDeveloperIdentity_603159 = ref object of OpenApiRestCall_602433
proc url_GetOpenIdTokenForDeveloperIdentity_603161(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetOpenIdTokenForDeveloperIdentity_603160(path: JsonNode;
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
      "AWSCognitoIdentityService.GetOpenIdTokenForDeveloperIdentity"))
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

proc call*(call_603171: Call_GetOpenIdTokenForDeveloperIdentity_603159;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Registers (or retrieves) a Cognito <code>IdentityId</code> and an OpenID Connect token for a user authenticated by your backend authentication process. Supplying multiple logins will create an implicit linked account. You can only specify one developer provider as part of the <code>Logins</code> map, which is linked to the identity pool. The developer provider is the "domain" by which Cognito will refer to your users.</p> <p>You can use <code>GetOpenIdTokenForDeveloperIdentity</code> to create a new identity and to link new logins (that is, user credentials issued by a public provider or developer provider) to an existing identity. When you want to create a new identity, the <code>IdentityId</code> should be null. When you want to associate a new login with an existing authenticated/unauthenticated identity, you can do so by providing the existing <code>IdentityId</code>. This API will create the identity in the specified <code>IdentityPoolId</code>.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  let valid = call_603171.validator(path, query, header, formData, body)
  let scheme = call_603171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603171.url(scheme.get, call_603171.host, call_603171.base,
                         call_603171.route, valid.getOrDefault("path"))
  result = hook(call_603171, url, valid)

proc call*(call_603172: Call_GetOpenIdTokenForDeveloperIdentity_603159;
          body: JsonNode): Recallable =
  ## getOpenIdTokenForDeveloperIdentity
  ## <p>Registers (or retrieves) a Cognito <code>IdentityId</code> and an OpenID Connect token for a user authenticated by your backend authentication process. Supplying multiple logins will create an implicit linked account. You can only specify one developer provider as part of the <code>Logins</code> map, which is linked to the identity pool. The developer provider is the "domain" by which Cognito will refer to your users.</p> <p>You can use <code>GetOpenIdTokenForDeveloperIdentity</code> to create a new identity and to link new logins (that is, user credentials issued by a public provider or developer provider) to an existing identity. When you want to create a new identity, the <code>IdentityId</code> should be null. When you want to associate a new login with an existing authenticated/unauthenticated identity, you can do so by providing the existing <code>IdentityId</code>. This API will create the identity in the specified <code>IdentityPoolId</code>.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ##   body: JObject (required)
  var body_603173 = newJObject()
  if body != nil:
    body_603173 = body
  result = call_603172.call(nil, nil, nil, nil, body_603173)

var getOpenIdTokenForDeveloperIdentity* = Call_GetOpenIdTokenForDeveloperIdentity_603159(
    name: "getOpenIdTokenForDeveloperIdentity", meth: HttpMethod.HttpPost,
    host: "cognito-identity.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityService.GetOpenIdTokenForDeveloperIdentity",
    validator: validate_GetOpenIdTokenForDeveloperIdentity_603160, base: "/",
    url: url_GetOpenIdTokenForDeveloperIdentity_603161,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIdentities_603174 = ref object of OpenApiRestCall_602433
proc url_ListIdentities_603176(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListIdentities_603175(path: JsonNode; query: JsonNode;
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
      "AWSCognitoIdentityService.ListIdentities"))
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

proc call*(call_603186: Call_ListIdentities_603174; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the identities in an identity pool.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  let valid = call_603186.validator(path, query, header, formData, body)
  let scheme = call_603186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603186.url(scheme.get, call_603186.host, call_603186.base,
                         call_603186.route, valid.getOrDefault("path"))
  result = hook(call_603186, url, valid)

proc call*(call_603187: Call_ListIdentities_603174; body: JsonNode): Recallable =
  ## listIdentities
  ## <p>Lists the identities in an identity pool.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ##   body: JObject (required)
  var body_603188 = newJObject()
  if body != nil:
    body_603188 = body
  result = call_603187.call(nil, nil, nil, nil, body_603188)

var listIdentities* = Call_ListIdentities_603174(name: "listIdentities",
    meth: HttpMethod.HttpPost, host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.ListIdentities",
    validator: validate_ListIdentities_603175, base: "/", url: url_ListIdentities_603176,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIdentityPools_603189 = ref object of OpenApiRestCall_602433
proc url_ListIdentityPools_603191(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListIdentityPools_603190(path: JsonNode; query: JsonNode;
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
      "AWSCognitoIdentityService.ListIdentityPools"))
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

proc call*(call_603201: Call_ListIdentityPools_603189; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all of the Cognito identity pools registered for your account.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  let valid = call_603201.validator(path, query, header, formData, body)
  let scheme = call_603201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603201.url(scheme.get, call_603201.host, call_603201.base,
                         call_603201.route, valid.getOrDefault("path"))
  result = hook(call_603201, url, valid)

proc call*(call_603202: Call_ListIdentityPools_603189; body: JsonNode): Recallable =
  ## listIdentityPools
  ## <p>Lists all of the Cognito identity pools registered for your account.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ##   body: JObject (required)
  var body_603203 = newJObject()
  if body != nil:
    body_603203 = body
  result = call_603202.call(nil, nil, nil, nil, body_603203)

var listIdentityPools* = Call_ListIdentityPools_603189(name: "listIdentityPools",
    meth: HttpMethod.HttpPost, host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.ListIdentityPools",
    validator: validate_ListIdentityPools_603190, base: "/",
    url: url_ListIdentityPools_603191, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_603204 = ref object of OpenApiRestCall_602433
proc url_ListTagsForResource_603206(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource_603205(path: JsonNode; query: JsonNode;
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
      "AWSCognitoIdentityService.ListTagsForResource"))
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

proc call*(call_603216: Call_ListTagsForResource_603204; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the tags that are assigned to an Amazon Cognito identity pool.</p> <p>A tag is a label that you can apply to identity pools to categorize and manage them in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>You can use this action up to 10 times per second, per account.</p>
  ## 
  let valid = call_603216.validator(path, query, header, formData, body)
  let scheme = call_603216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603216.url(scheme.get, call_603216.host, call_603216.base,
                         call_603216.route, valid.getOrDefault("path"))
  result = hook(call_603216, url, valid)

proc call*(call_603217: Call_ListTagsForResource_603204; body: JsonNode): Recallable =
  ## listTagsForResource
  ## <p>Lists the tags that are assigned to an Amazon Cognito identity pool.</p> <p>A tag is a label that you can apply to identity pools to categorize and manage them in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>You can use this action up to 10 times per second, per account.</p>
  ##   body: JObject (required)
  var body_603218 = newJObject()
  if body != nil:
    body_603218 = body
  result = call_603217.call(nil, nil, nil, nil, body_603218)

var listTagsForResource* = Call_ListTagsForResource_603204(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.ListTagsForResource",
    validator: validate_ListTagsForResource_603205, base: "/",
    url: url_ListTagsForResource_603206, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LookupDeveloperIdentity_603219 = ref object of OpenApiRestCall_602433
proc url_LookupDeveloperIdentity_603221(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_LookupDeveloperIdentity_603220(path: JsonNode; query: JsonNode;
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
      "AWSCognitoIdentityService.LookupDeveloperIdentity"))
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

proc call*(call_603231: Call_LookupDeveloperIdentity_603219; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the <code>IdentityID</code> associated with a <code>DeveloperUserIdentifier</code> or the list of <code>DeveloperUserIdentifier</code> values associated with an <code>IdentityId</code> for an existing identity. Either <code>IdentityID</code> or <code>DeveloperUserIdentifier</code> must not be null. If you supply only one of these values, the other value will be searched in the database and returned as a part of the response. If you supply both, <code>DeveloperUserIdentifier</code> will be matched against <code>IdentityID</code>. If the values are verified against the database, the response returns both values and is the same as the request. Otherwise a <code>ResourceConflictException</code> is thrown.</p> <p> <code>LookupDeveloperIdentity</code> is intended for low-throughput control plane operations: for example, to enable customer service to locate an identity ID by username. If you are using it for higher-volume operations such as user authentication, your requests are likely to be throttled. <a>GetOpenIdTokenForDeveloperIdentity</a> is a better option for higher-volume operations for user authentication.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  let valid = call_603231.validator(path, query, header, formData, body)
  let scheme = call_603231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603231.url(scheme.get, call_603231.host, call_603231.base,
                         call_603231.route, valid.getOrDefault("path"))
  result = hook(call_603231, url, valid)

proc call*(call_603232: Call_LookupDeveloperIdentity_603219; body: JsonNode): Recallable =
  ## lookupDeveloperIdentity
  ## <p>Retrieves the <code>IdentityID</code> associated with a <code>DeveloperUserIdentifier</code> or the list of <code>DeveloperUserIdentifier</code> values associated with an <code>IdentityId</code> for an existing identity. Either <code>IdentityID</code> or <code>DeveloperUserIdentifier</code> must not be null. If you supply only one of these values, the other value will be searched in the database and returned as a part of the response. If you supply both, <code>DeveloperUserIdentifier</code> will be matched against <code>IdentityID</code>. If the values are verified against the database, the response returns both values and is the same as the request. Otherwise a <code>ResourceConflictException</code> is thrown.</p> <p> <code>LookupDeveloperIdentity</code> is intended for low-throughput control plane operations: for example, to enable customer service to locate an identity ID by username. If you are using it for higher-volume operations such as user authentication, your requests are likely to be throttled. <a>GetOpenIdTokenForDeveloperIdentity</a> is a better option for higher-volume operations for user authentication.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ##   body: JObject (required)
  var body_603233 = newJObject()
  if body != nil:
    body_603233 = body
  result = call_603232.call(nil, nil, nil, nil, body_603233)

var lookupDeveloperIdentity* = Call_LookupDeveloperIdentity_603219(
    name: "lookupDeveloperIdentity", meth: HttpMethod.HttpPost,
    host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.LookupDeveloperIdentity",
    validator: validate_LookupDeveloperIdentity_603220, base: "/",
    url: url_LookupDeveloperIdentity_603221, schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergeDeveloperIdentities_603234 = ref object of OpenApiRestCall_602433
proc url_MergeDeveloperIdentities_603236(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_MergeDeveloperIdentities_603235(path: JsonNode; query: JsonNode;
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
      "AWSCognitoIdentityService.MergeDeveloperIdentities"))
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

proc call*(call_603246: Call_MergeDeveloperIdentities_603234; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Merges two users having different <code>IdentityId</code>s, existing in the same identity pool, and identified by the same developer provider. You can use this action to request that discrete users be merged and identified as a single user in the Cognito environment. Cognito associates the given source user (<code>SourceUserIdentifier</code>) with the <code>IdentityId</code> of the <code>DestinationUserIdentifier</code>. Only developer-authenticated users can be merged. If the users to be merged are associated with the same public provider, but as two different users, an exception will be thrown.</p> <p>The number of linked logins is limited to 20. So, the number of linked logins for the source user, <code>SourceUserIdentifier</code>, and the destination user, <code>DestinationUserIdentifier</code>, together should not be larger than 20. Otherwise, an exception will be thrown.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  let valid = call_603246.validator(path, query, header, formData, body)
  let scheme = call_603246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603246.url(scheme.get, call_603246.host, call_603246.base,
                         call_603246.route, valid.getOrDefault("path"))
  result = hook(call_603246, url, valid)

proc call*(call_603247: Call_MergeDeveloperIdentities_603234; body: JsonNode): Recallable =
  ## mergeDeveloperIdentities
  ## <p>Merges two users having different <code>IdentityId</code>s, existing in the same identity pool, and identified by the same developer provider. You can use this action to request that discrete users be merged and identified as a single user in the Cognito environment. Cognito associates the given source user (<code>SourceUserIdentifier</code>) with the <code>IdentityId</code> of the <code>DestinationUserIdentifier</code>. Only developer-authenticated users can be merged. If the users to be merged are associated with the same public provider, but as two different users, an exception will be thrown.</p> <p>The number of linked logins is limited to 20. So, the number of linked logins for the source user, <code>SourceUserIdentifier</code>, and the destination user, <code>DestinationUserIdentifier</code>, together should not be larger than 20. Otherwise, an exception will be thrown.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ##   body: JObject (required)
  var body_603248 = newJObject()
  if body != nil:
    body_603248 = body
  result = call_603247.call(nil, nil, nil, nil, body_603248)

var mergeDeveloperIdentities* = Call_MergeDeveloperIdentities_603234(
    name: "mergeDeveloperIdentities", meth: HttpMethod.HttpPost,
    host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.MergeDeveloperIdentities",
    validator: validate_MergeDeveloperIdentities_603235, base: "/",
    url: url_MergeDeveloperIdentities_603236, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetIdentityPoolRoles_603249 = ref object of OpenApiRestCall_602433
proc url_SetIdentityPoolRoles_603251(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SetIdentityPoolRoles_603250(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603252 = header.getOrDefault("X-Amz-Date")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "X-Amz-Date", valid_603252
  var valid_603253 = header.getOrDefault("X-Amz-Security-Token")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-Security-Token", valid_603253
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603254 = header.getOrDefault("X-Amz-Target")
  valid_603254 = validateParameter(valid_603254, JString, required = true, default = newJString(
      "AWSCognitoIdentityService.SetIdentityPoolRoles"))
  if valid_603254 != nil:
    section.add "X-Amz-Target", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Content-Sha256", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Algorithm")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Algorithm", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-Signature")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Signature", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-SignedHeaders", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Credential")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Credential", valid_603259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603261: Call_SetIdentityPoolRoles_603249; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the roles for an identity pool. These roles are used when making calls to <a>GetCredentialsForIdentity</a> action.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  let valid = call_603261.validator(path, query, header, formData, body)
  let scheme = call_603261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603261.url(scheme.get, call_603261.host, call_603261.base,
                         call_603261.route, valid.getOrDefault("path"))
  result = hook(call_603261, url, valid)

proc call*(call_603262: Call_SetIdentityPoolRoles_603249; body: JsonNode): Recallable =
  ## setIdentityPoolRoles
  ## <p>Sets the roles for an identity pool. These roles are used when making calls to <a>GetCredentialsForIdentity</a> action.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ##   body: JObject (required)
  var body_603263 = newJObject()
  if body != nil:
    body_603263 = body
  result = call_603262.call(nil, nil, nil, nil, body_603263)

var setIdentityPoolRoles* = Call_SetIdentityPoolRoles_603249(
    name: "setIdentityPoolRoles", meth: HttpMethod.HttpPost,
    host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.SetIdentityPoolRoles",
    validator: validate_SetIdentityPoolRoles_603250, base: "/",
    url: url_SetIdentityPoolRoles_603251, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603264 = ref object of OpenApiRestCall_602433
proc url_TagResource_603266(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_603265(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603267 = header.getOrDefault("X-Amz-Date")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Date", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-Security-Token")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Security-Token", valid_603268
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603269 = header.getOrDefault("X-Amz-Target")
  valid_603269 = validateParameter(valid_603269, JString, required = true, default = newJString(
      "AWSCognitoIdentityService.TagResource"))
  if valid_603269 != nil:
    section.add "X-Amz-Target", valid_603269
  var valid_603270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Content-Sha256", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Algorithm")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Algorithm", valid_603271
  var valid_603272 = header.getOrDefault("X-Amz-Signature")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-Signature", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-SignedHeaders", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Credential")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Credential", valid_603274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603276: Call_TagResource_603264; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns a set of tags to an Amazon Cognito identity pool. A tag is a label that you can use to categorize and manage identity pools in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>Each tag consists of a key and value, both of which you define. A key is a general category for more specific values. For example, if you have two versions of an identity pool, one for testing and another for production, you might assign an <code>Environment</code> tag key to both identity pools. The value of this key might be <code>Test</code> for one identity pool and <code>Production</code> for the other.</p> <p>Tags are useful for cost tracking and access control. You can activate your tags so that they appear on the Billing and Cost Management console, where you can track the costs associated with your identity pools. In an IAM policy, you can constrain permissions for identity pools based on specific tags or tag values.</p> <p>You can use this action up to 5 times per second, per account. An identity pool can have as many as 50 tags.</p>
  ## 
  let valid = call_603276.validator(path, query, header, formData, body)
  let scheme = call_603276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603276.url(scheme.get, call_603276.host, call_603276.base,
                         call_603276.route, valid.getOrDefault("path"))
  result = hook(call_603276, url, valid)

proc call*(call_603277: Call_TagResource_603264; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Assigns a set of tags to an Amazon Cognito identity pool. A tag is a label that you can use to categorize and manage identity pools in different ways, such as by purpose, owner, environment, or other criteria.</p> <p>Each tag consists of a key and value, both of which you define. A key is a general category for more specific values. For example, if you have two versions of an identity pool, one for testing and another for production, you might assign an <code>Environment</code> tag key to both identity pools. The value of this key might be <code>Test</code> for one identity pool and <code>Production</code> for the other.</p> <p>Tags are useful for cost tracking and access control. You can activate your tags so that they appear on the Billing and Cost Management console, where you can track the costs associated with your identity pools. In an IAM policy, you can constrain permissions for identity pools based on specific tags or tag values.</p> <p>You can use this action up to 5 times per second, per account. An identity pool can have as many as 50 tags.</p>
  ##   body: JObject (required)
  var body_603278 = newJObject()
  if body != nil:
    body_603278 = body
  result = call_603277.call(nil, nil, nil, nil, body_603278)

var tagResource* = Call_TagResource_603264(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-identity.amazonaws.com", route: "/#X-Amz-Target=AWSCognitoIdentityService.TagResource",
                                        validator: validate_TagResource_603265,
                                        base: "/", url: url_TagResource_603266,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnlinkDeveloperIdentity_603279 = ref object of OpenApiRestCall_602433
proc url_UnlinkDeveloperIdentity_603281(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UnlinkDeveloperIdentity_603280(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603282 = header.getOrDefault("X-Amz-Date")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Date", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-Security-Token")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-Security-Token", valid_603283
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603284 = header.getOrDefault("X-Amz-Target")
  valid_603284 = validateParameter(valid_603284, JString, required = true, default = newJString(
      "AWSCognitoIdentityService.UnlinkDeveloperIdentity"))
  if valid_603284 != nil:
    section.add "X-Amz-Target", valid_603284
  var valid_603285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Content-Sha256", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Algorithm")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Algorithm", valid_603286
  var valid_603287 = header.getOrDefault("X-Amz-Signature")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-Signature", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-SignedHeaders", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Credential")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Credential", valid_603289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603291: Call_UnlinkDeveloperIdentity_603279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Unlinks a <code>DeveloperUserIdentifier</code> from an existing identity. Unlinked developer users will be considered new identities next time they are seen. If, for a given Cognito identity, you remove all federated identities as well as the developer user identifier, the Cognito identity becomes inaccessible.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  let valid = call_603291.validator(path, query, header, formData, body)
  let scheme = call_603291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603291.url(scheme.get, call_603291.host, call_603291.base,
                         call_603291.route, valid.getOrDefault("path"))
  result = hook(call_603291, url, valid)

proc call*(call_603292: Call_UnlinkDeveloperIdentity_603279; body: JsonNode): Recallable =
  ## unlinkDeveloperIdentity
  ## <p>Unlinks a <code>DeveloperUserIdentifier</code> from an existing identity. Unlinked developer users will be considered new identities next time they are seen. If, for a given Cognito identity, you remove all federated identities as well as the developer user identifier, the Cognito identity becomes inaccessible.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ##   body: JObject (required)
  var body_603293 = newJObject()
  if body != nil:
    body_603293 = body
  result = call_603292.call(nil, nil, nil, nil, body_603293)

var unlinkDeveloperIdentity* = Call_UnlinkDeveloperIdentity_603279(
    name: "unlinkDeveloperIdentity", meth: HttpMethod.HttpPost,
    host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.UnlinkDeveloperIdentity",
    validator: validate_UnlinkDeveloperIdentity_603280, base: "/",
    url: url_UnlinkDeveloperIdentity_603281, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnlinkIdentity_603294 = ref object of OpenApiRestCall_602433
proc url_UnlinkIdentity_603296(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UnlinkIdentity_603295(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603297 = header.getOrDefault("X-Amz-Date")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-Date", valid_603297
  var valid_603298 = header.getOrDefault("X-Amz-Security-Token")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-Security-Token", valid_603298
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603299 = header.getOrDefault("X-Amz-Target")
  valid_603299 = validateParameter(valid_603299, JString, required = true, default = newJString(
      "AWSCognitoIdentityService.UnlinkIdentity"))
  if valid_603299 != nil:
    section.add "X-Amz-Target", valid_603299
  var valid_603300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Content-Sha256", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Algorithm")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Algorithm", valid_603301
  var valid_603302 = header.getOrDefault("X-Amz-Signature")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-Signature", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-SignedHeaders", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Credential")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Credential", valid_603304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603306: Call_UnlinkIdentity_603294; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Unlinks a federated identity from an existing account. Unlinked logins will be considered new identities next time they are seen. Removing the last linked login will make this identity inaccessible.</p> <p>This is a public API. You do not need any credentials to call this API.</p>
  ## 
  let valid = call_603306.validator(path, query, header, formData, body)
  let scheme = call_603306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603306.url(scheme.get, call_603306.host, call_603306.base,
                         call_603306.route, valid.getOrDefault("path"))
  result = hook(call_603306, url, valid)

proc call*(call_603307: Call_UnlinkIdentity_603294; body: JsonNode): Recallable =
  ## unlinkIdentity
  ## <p>Unlinks a federated identity from an existing account. Unlinked logins will be considered new identities next time they are seen. Removing the last linked login will make this identity inaccessible.</p> <p>This is a public API. You do not need any credentials to call this API.</p>
  ##   body: JObject (required)
  var body_603308 = newJObject()
  if body != nil:
    body_603308 = body
  result = call_603307.call(nil, nil, nil, nil, body_603308)

var unlinkIdentity* = Call_UnlinkIdentity_603294(name: "unlinkIdentity",
    meth: HttpMethod.HttpPost, host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.UnlinkIdentity",
    validator: validate_UnlinkIdentity_603295, base: "/", url: url_UnlinkIdentity_603296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603309 = ref object of OpenApiRestCall_602433
proc url_UntagResource_603311(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_603310(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603312 = header.getOrDefault("X-Amz-Date")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "X-Amz-Date", valid_603312
  var valid_603313 = header.getOrDefault("X-Amz-Security-Token")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "X-Amz-Security-Token", valid_603313
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603314 = header.getOrDefault("X-Amz-Target")
  valid_603314 = validateParameter(valid_603314, JString, required = true, default = newJString(
      "AWSCognitoIdentityService.UntagResource"))
  if valid_603314 != nil:
    section.add "X-Amz-Target", valid_603314
  var valid_603315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Content-Sha256", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Algorithm")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Algorithm", valid_603316
  var valid_603317 = header.getOrDefault("X-Amz-Signature")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-Signature", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-SignedHeaders", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Credential")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Credential", valid_603319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603321: Call_UntagResource_603309; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified tags from an Amazon Cognito identity pool. You can use this action up to 5 times per second, per account
  ## 
  let valid = call_603321.validator(path, query, header, formData, body)
  let scheme = call_603321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603321.url(scheme.get, call_603321.host, call_603321.base,
                         call_603321.route, valid.getOrDefault("path"))
  result = hook(call_603321, url, valid)

proc call*(call_603322: Call_UntagResource_603309; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tags from an Amazon Cognito identity pool. You can use this action up to 5 times per second, per account
  ##   body: JObject (required)
  var body_603323 = newJObject()
  if body != nil:
    body_603323 = body
  result = call_603322.call(nil, nil, nil, nil, body_603323)

var untagResource* = Call_UntagResource_603309(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.UntagResource",
    validator: validate_UntagResource_603310, base: "/", url: url_UntagResource_603311,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIdentityPool_603324 = ref object of OpenApiRestCall_602433
proc url_UpdateIdentityPool_603326(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateIdentityPool_603325(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603327 = header.getOrDefault("X-Amz-Date")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "X-Amz-Date", valid_603327
  var valid_603328 = header.getOrDefault("X-Amz-Security-Token")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "X-Amz-Security-Token", valid_603328
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603329 = header.getOrDefault("X-Amz-Target")
  valid_603329 = validateParameter(valid_603329, JString, required = true, default = newJString(
      "AWSCognitoIdentityService.UpdateIdentityPool"))
  if valid_603329 != nil:
    section.add "X-Amz-Target", valid_603329
  var valid_603330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Content-Sha256", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Algorithm")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Algorithm", valid_603331
  var valid_603332 = header.getOrDefault("X-Amz-Signature")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "X-Amz-Signature", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-SignedHeaders", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Credential")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Credential", valid_603334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603336: Call_UpdateIdentityPool_603324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an identity pool.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ## 
  let valid = call_603336.validator(path, query, header, formData, body)
  let scheme = call_603336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603336.url(scheme.get, call_603336.host, call_603336.base,
                         call_603336.route, valid.getOrDefault("path"))
  result = hook(call_603336, url, valid)

proc call*(call_603337: Call_UpdateIdentityPool_603324; body: JsonNode): Recallable =
  ## updateIdentityPool
  ## <p>Updates an identity pool.</p> <p>You must use AWS Developer credentials to call this API.</p>
  ##   body: JObject (required)
  var body_603338 = newJObject()
  if body != nil:
    body_603338 = body
  result = call_603337.call(nil, nil, nil, nil, body_603338)

var updateIdentityPool* = Call_UpdateIdentityPool_603324(
    name: "updateIdentityPool", meth: HttpMethod.HttpPost,
    host: "cognito-identity.amazonaws.com",
    route: "/#X-Amz-Target=AWSCognitoIdentityService.UpdateIdentityPool",
    validator: validate_UpdateIdentityPool_603325, base: "/",
    url: url_UpdateIdentityPool_603326, schemes: {Scheme.Https, Scheme.Http})
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
