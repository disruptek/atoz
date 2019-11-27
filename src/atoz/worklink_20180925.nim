
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon WorkLink
## version: 2018-09-25
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Amazon WorkLink is a cloud-based service that provides secure access to internal websites and web apps from iOS phones. In a single step, your users, such as employees, can access internal websites as efficiently as they access any other public website. They enter a URL in their web browser, or choose a link to an internal website in an email. Amazon WorkLink authenticates the user's access and securely renders authorized internal web content in a secure rendering service in the AWS cloud. Amazon WorkLink doesn't download or store any internal web content on mobile devices.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/worklink/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "worklink.ap-northeast-1.amazonaws.com", "ap-southeast-1": "worklink.ap-southeast-1.amazonaws.com",
                           "us-west-2": "worklink.us-west-2.amazonaws.com",
                           "eu-west-2": "worklink.eu-west-2.amazonaws.com", "ap-northeast-3": "worklink.ap-northeast-3.amazonaws.com", "eu-central-1": "worklink.eu-central-1.amazonaws.com",
                           "us-east-2": "worklink.us-east-2.amazonaws.com",
                           "us-east-1": "worklink.us-east-1.amazonaws.com", "cn-northwest-1": "worklink.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "worklink.ap-south-1.amazonaws.com",
                           "eu-north-1": "worklink.eu-north-1.amazonaws.com", "ap-northeast-2": "worklink.ap-northeast-2.amazonaws.com",
                           "us-west-1": "worklink.us-west-1.amazonaws.com", "us-gov-east-1": "worklink.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "worklink.eu-west-3.amazonaws.com", "cn-north-1": "worklink.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "worklink.sa-east-1.amazonaws.com",
                           "eu-west-1": "worklink.eu-west-1.amazonaws.com", "us-gov-west-1": "worklink.us-gov-west-1.amazonaws.com", "ap-southeast-2": "worklink.ap-southeast-2.amazonaws.com", "ca-central-1": "worklink.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "worklink.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "worklink.ap-southeast-1.amazonaws.com",
      "us-west-2": "worklink.us-west-2.amazonaws.com",
      "eu-west-2": "worklink.eu-west-2.amazonaws.com",
      "ap-northeast-3": "worklink.ap-northeast-3.amazonaws.com",
      "eu-central-1": "worklink.eu-central-1.amazonaws.com",
      "us-east-2": "worklink.us-east-2.amazonaws.com",
      "us-east-1": "worklink.us-east-1.amazonaws.com",
      "cn-northwest-1": "worklink.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "worklink.ap-south-1.amazonaws.com",
      "eu-north-1": "worklink.eu-north-1.amazonaws.com",
      "ap-northeast-2": "worklink.ap-northeast-2.amazonaws.com",
      "us-west-1": "worklink.us-west-1.amazonaws.com",
      "us-gov-east-1": "worklink.us-gov-east-1.amazonaws.com",
      "eu-west-3": "worklink.eu-west-3.amazonaws.com",
      "cn-north-1": "worklink.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "worklink.sa-east-1.amazonaws.com",
      "eu-west-1": "worklink.eu-west-1.amazonaws.com",
      "us-gov-west-1": "worklink.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "worklink.ap-southeast-2.amazonaws.com",
      "ca-central-1": "worklink.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "worklink"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateDomain_599705 = ref object of OpenApiRestCall_599368
proc url_AssociateDomain_599707(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateDomain_599706(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Specifies a domain to be associated to Amazon WorkLink.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
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
  var valid_599821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599821 = validateParameter(valid_599821, JString, required = false,
                                 default = nil)
  if valid_599821 != nil:
    section.add "X-Amz-Content-Sha256", valid_599821
  var valid_599822 = header.getOrDefault("X-Amz-Algorithm")
  valid_599822 = validateParameter(valid_599822, JString, required = false,
                                 default = nil)
  if valid_599822 != nil:
    section.add "X-Amz-Algorithm", valid_599822
  var valid_599823 = header.getOrDefault("X-Amz-Signature")
  valid_599823 = validateParameter(valid_599823, JString, required = false,
                                 default = nil)
  if valid_599823 != nil:
    section.add "X-Amz-Signature", valid_599823
  var valid_599824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599824 = validateParameter(valid_599824, JString, required = false,
                                 default = nil)
  if valid_599824 != nil:
    section.add "X-Amz-SignedHeaders", valid_599824
  var valid_599825 = header.getOrDefault("X-Amz-Credential")
  valid_599825 = validateParameter(valid_599825, JString, required = false,
                                 default = nil)
  if valid_599825 != nil:
    section.add "X-Amz-Credential", valid_599825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599849: Call_AssociateDomain_599705; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Specifies a domain to be associated to Amazon WorkLink.
  ## 
  let valid = call_599849.validator(path, query, header, formData, body)
  let scheme = call_599849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599849.url(scheme.get, call_599849.host, call_599849.base,
                         call_599849.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599849, url, valid)

proc call*(call_599920: Call_AssociateDomain_599705; body: JsonNode): Recallable =
  ## associateDomain
  ## Specifies a domain to be associated to Amazon WorkLink.
  ##   body: JObject (required)
  var body_599921 = newJObject()
  if body != nil:
    body_599921 = body
  result = call_599920.call(nil, nil, nil, nil, body_599921)

var associateDomain* = Call_AssociateDomain_599705(name: "associateDomain",
    meth: HttpMethod.HttpPost, host: "worklink.amazonaws.com",
    route: "/associateDomain", validator: validate_AssociateDomain_599706,
    base: "/", url: url_AssociateDomain_599707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateWebsiteAuthorizationProvider_599960 = ref object of OpenApiRestCall_599368
proc url_AssociateWebsiteAuthorizationProvider_599962(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateWebsiteAuthorizationProvider_599961(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates a website authorization provider with a specified fleet. This is used to authorize users against associated websites in the company network.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599963 = header.getOrDefault("X-Amz-Date")
  valid_599963 = validateParameter(valid_599963, JString, required = false,
                                 default = nil)
  if valid_599963 != nil:
    section.add "X-Amz-Date", valid_599963
  var valid_599964 = header.getOrDefault("X-Amz-Security-Token")
  valid_599964 = validateParameter(valid_599964, JString, required = false,
                                 default = nil)
  if valid_599964 != nil:
    section.add "X-Amz-Security-Token", valid_599964
  var valid_599965 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599965 = validateParameter(valid_599965, JString, required = false,
                                 default = nil)
  if valid_599965 != nil:
    section.add "X-Amz-Content-Sha256", valid_599965
  var valid_599966 = header.getOrDefault("X-Amz-Algorithm")
  valid_599966 = validateParameter(valid_599966, JString, required = false,
                                 default = nil)
  if valid_599966 != nil:
    section.add "X-Amz-Algorithm", valid_599966
  var valid_599967 = header.getOrDefault("X-Amz-Signature")
  valid_599967 = validateParameter(valid_599967, JString, required = false,
                                 default = nil)
  if valid_599967 != nil:
    section.add "X-Amz-Signature", valid_599967
  var valid_599968 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599968 = validateParameter(valid_599968, JString, required = false,
                                 default = nil)
  if valid_599968 != nil:
    section.add "X-Amz-SignedHeaders", valid_599968
  var valid_599969 = header.getOrDefault("X-Amz-Credential")
  valid_599969 = validateParameter(valid_599969, JString, required = false,
                                 default = nil)
  if valid_599969 != nil:
    section.add "X-Amz-Credential", valid_599969
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599971: Call_AssociateWebsiteAuthorizationProvider_599960;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a website authorization provider with a specified fleet. This is used to authorize users against associated websites in the company network.
  ## 
  let valid = call_599971.validator(path, query, header, formData, body)
  let scheme = call_599971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599971.url(scheme.get, call_599971.host, call_599971.base,
                         call_599971.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599971, url, valid)

proc call*(call_599972: Call_AssociateWebsiteAuthorizationProvider_599960;
          body: JsonNode): Recallable =
  ## associateWebsiteAuthorizationProvider
  ## Associates a website authorization provider with a specified fleet. This is used to authorize users against associated websites in the company network.
  ##   body: JObject (required)
  var body_599973 = newJObject()
  if body != nil:
    body_599973 = body
  result = call_599972.call(nil, nil, nil, nil, body_599973)

var associateWebsiteAuthorizationProvider* = Call_AssociateWebsiteAuthorizationProvider_599960(
    name: "associateWebsiteAuthorizationProvider", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com",
    route: "/associateWebsiteAuthorizationProvider",
    validator: validate_AssociateWebsiteAuthorizationProvider_599961, base: "/",
    url: url_AssociateWebsiteAuthorizationProvider_599962,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateWebsiteCertificateAuthority_599974 = ref object of OpenApiRestCall_599368
proc url_AssociateWebsiteCertificateAuthority_599976(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateWebsiteCertificateAuthority_599975(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Imports the root certificate of a certificate authority (CA) used to obtain TLS certificates used by associated websites within the company network.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
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
  var valid_599979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599979 = validateParameter(valid_599979, JString, required = false,
                                 default = nil)
  if valid_599979 != nil:
    section.add "X-Amz-Content-Sha256", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Algorithm")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Algorithm", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Signature")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Signature", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-SignedHeaders", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-Credential")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Credential", valid_599983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599985: Call_AssociateWebsiteCertificateAuthority_599974;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Imports the root certificate of a certificate authority (CA) used to obtain TLS certificates used by associated websites within the company network.
  ## 
  let valid = call_599985.validator(path, query, header, formData, body)
  let scheme = call_599985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599985.url(scheme.get, call_599985.host, call_599985.base,
                         call_599985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599985, url, valid)

proc call*(call_599986: Call_AssociateWebsiteCertificateAuthority_599974;
          body: JsonNode): Recallable =
  ## associateWebsiteCertificateAuthority
  ## Imports the root certificate of a certificate authority (CA) used to obtain TLS certificates used by associated websites within the company network.
  ##   body: JObject (required)
  var body_599987 = newJObject()
  if body != nil:
    body_599987 = body
  result = call_599986.call(nil, nil, nil, nil, body_599987)

var associateWebsiteCertificateAuthority* = Call_AssociateWebsiteCertificateAuthority_599974(
    name: "associateWebsiteCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com",
    route: "/associateWebsiteCertificateAuthority",
    validator: validate_AssociateWebsiteCertificateAuthority_599975, base: "/",
    url: url_AssociateWebsiteCertificateAuthority_599976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFleet_599988 = ref object of OpenApiRestCall_599368
proc url_CreateFleet_599990(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFleet_599989(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a fleet. A fleet consists of resources and the configuration that delivers associated websites to authorized users who download and set up the Amazon WorkLink app.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599991 = header.getOrDefault("X-Amz-Date")
  valid_599991 = validateParameter(valid_599991, JString, required = false,
                                 default = nil)
  if valid_599991 != nil:
    section.add "X-Amz-Date", valid_599991
  var valid_599992 = header.getOrDefault("X-Amz-Security-Token")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Security-Token", valid_599992
  var valid_599993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Content-Sha256", valid_599993
  var valid_599994 = header.getOrDefault("X-Amz-Algorithm")
  valid_599994 = validateParameter(valid_599994, JString, required = false,
                                 default = nil)
  if valid_599994 != nil:
    section.add "X-Amz-Algorithm", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Signature")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Signature", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-SignedHeaders", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Credential")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Credential", valid_599997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599999: Call_CreateFleet_599988; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a fleet. A fleet consists of resources and the configuration that delivers associated websites to authorized users who download and set up the Amazon WorkLink app.
  ## 
  let valid = call_599999.validator(path, query, header, formData, body)
  let scheme = call_599999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599999.url(scheme.get, call_599999.host, call_599999.base,
                         call_599999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599999, url, valid)

proc call*(call_600000: Call_CreateFleet_599988; body: JsonNode): Recallable =
  ## createFleet
  ## Creates a fleet. A fleet consists of resources and the configuration that delivers associated websites to authorized users who download and set up the Amazon WorkLink app.
  ##   body: JObject (required)
  var body_600001 = newJObject()
  if body != nil:
    body_600001 = body
  result = call_600000.call(nil, nil, nil, nil, body_600001)

var createFleet* = Call_CreateFleet_599988(name: "createFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "worklink.amazonaws.com",
                                        route: "/createFleet",
                                        validator: validate_CreateFleet_599989,
                                        base: "/", url: url_CreateFleet_599990,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFleet_600002 = ref object of OpenApiRestCall_599368
proc url_DeleteFleet_600004(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteFleet_600003(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a fleet. Prevents users from accessing previously associated websites. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600005 = header.getOrDefault("X-Amz-Date")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-Date", valid_600005
  var valid_600006 = header.getOrDefault("X-Amz-Security-Token")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "X-Amz-Security-Token", valid_600006
  var valid_600007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Content-Sha256", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Algorithm")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Algorithm", valid_600008
  var valid_600009 = header.getOrDefault("X-Amz-Signature")
  valid_600009 = validateParameter(valid_600009, JString, required = false,
                                 default = nil)
  if valid_600009 != nil:
    section.add "X-Amz-Signature", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-SignedHeaders", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Credential")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Credential", valid_600011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600013: Call_DeleteFleet_600002; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a fleet. Prevents users from accessing previously associated websites. 
  ## 
  let valid = call_600013.validator(path, query, header, formData, body)
  let scheme = call_600013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600013.url(scheme.get, call_600013.host, call_600013.base,
                         call_600013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600013, url, valid)

proc call*(call_600014: Call_DeleteFleet_600002; body: JsonNode): Recallable =
  ## deleteFleet
  ## Deletes a fleet. Prevents users from accessing previously associated websites. 
  ##   body: JObject (required)
  var body_600015 = newJObject()
  if body != nil:
    body_600015 = body
  result = call_600014.call(nil, nil, nil, nil, body_600015)

var deleteFleet* = Call_DeleteFleet_600002(name: "deleteFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "worklink.amazonaws.com",
                                        route: "/deleteFleet",
                                        validator: validate_DeleteFleet_600003,
                                        base: "/", url: url_DeleteFleet_600004,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAuditStreamConfiguration_600016 = ref object of OpenApiRestCall_599368
proc url_DescribeAuditStreamConfiguration_600018(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAuditStreamConfiguration_600017(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the configuration for delivering audit streams to the customer account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600019 = header.getOrDefault("X-Amz-Date")
  valid_600019 = validateParameter(valid_600019, JString, required = false,
                                 default = nil)
  if valid_600019 != nil:
    section.add "X-Amz-Date", valid_600019
  var valid_600020 = header.getOrDefault("X-Amz-Security-Token")
  valid_600020 = validateParameter(valid_600020, JString, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "X-Amz-Security-Token", valid_600020
  var valid_600021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600021 = validateParameter(valid_600021, JString, required = false,
                                 default = nil)
  if valid_600021 != nil:
    section.add "X-Amz-Content-Sha256", valid_600021
  var valid_600022 = header.getOrDefault("X-Amz-Algorithm")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Algorithm", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-Signature")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Signature", valid_600023
  var valid_600024 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600024 = validateParameter(valid_600024, JString, required = false,
                                 default = nil)
  if valid_600024 != nil:
    section.add "X-Amz-SignedHeaders", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Credential")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Credential", valid_600025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600027: Call_DescribeAuditStreamConfiguration_600016;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration for delivering audit streams to the customer account.
  ## 
  let valid = call_600027.validator(path, query, header, formData, body)
  let scheme = call_600027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600027.url(scheme.get, call_600027.host, call_600027.base,
                         call_600027.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600027, url, valid)

proc call*(call_600028: Call_DescribeAuditStreamConfiguration_600016;
          body: JsonNode): Recallable =
  ## describeAuditStreamConfiguration
  ## Describes the configuration for delivering audit streams to the customer account.
  ##   body: JObject (required)
  var body_600029 = newJObject()
  if body != nil:
    body_600029 = body
  result = call_600028.call(nil, nil, nil, nil, body_600029)

var describeAuditStreamConfiguration* = Call_DescribeAuditStreamConfiguration_600016(
    name: "describeAuditStreamConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/describeAuditStreamConfiguration",
    validator: validate_DescribeAuditStreamConfiguration_600017, base: "/",
    url: url_DescribeAuditStreamConfiguration_600018,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCompanyNetworkConfiguration_600030 = ref object of OpenApiRestCall_599368
proc url_DescribeCompanyNetworkConfiguration_600032(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCompanyNetworkConfiguration_600031(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the networking configuration to access the internal websites associated with the specified fleet.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600033 = header.getOrDefault("X-Amz-Date")
  valid_600033 = validateParameter(valid_600033, JString, required = false,
                                 default = nil)
  if valid_600033 != nil:
    section.add "X-Amz-Date", valid_600033
  var valid_600034 = header.getOrDefault("X-Amz-Security-Token")
  valid_600034 = validateParameter(valid_600034, JString, required = false,
                                 default = nil)
  if valid_600034 != nil:
    section.add "X-Amz-Security-Token", valid_600034
  var valid_600035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600035 = validateParameter(valid_600035, JString, required = false,
                                 default = nil)
  if valid_600035 != nil:
    section.add "X-Amz-Content-Sha256", valid_600035
  var valid_600036 = header.getOrDefault("X-Amz-Algorithm")
  valid_600036 = validateParameter(valid_600036, JString, required = false,
                                 default = nil)
  if valid_600036 != nil:
    section.add "X-Amz-Algorithm", valid_600036
  var valid_600037 = header.getOrDefault("X-Amz-Signature")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Signature", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-SignedHeaders", valid_600038
  var valid_600039 = header.getOrDefault("X-Amz-Credential")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "X-Amz-Credential", valid_600039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600041: Call_DescribeCompanyNetworkConfiguration_600030;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the networking configuration to access the internal websites associated with the specified fleet.
  ## 
  let valid = call_600041.validator(path, query, header, formData, body)
  let scheme = call_600041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600041.url(scheme.get, call_600041.host, call_600041.base,
                         call_600041.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600041, url, valid)

proc call*(call_600042: Call_DescribeCompanyNetworkConfiguration_600030;
          body: JsonNode): Recallable =
  ## describeCompanyNetworkConfiguration
  ## Describes the networking configuration to access the internal websites associated with the specified fleet.
  ##   body: JObject (required)
  var body_600043 = newJObject()
  if body != nil:
    body_600043 = body
  result = call_600042.call(nil, nil, nil, nil, body_600043)

var describeCompanyNetworkConfiguration* = Call_DescribeCompanyNetworkConfiguration_600030(
    name: "describeCompanyNetworkConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/describeCompanyNetworkConfiguration",
    validator: validate_DescribeCompanyNetworkConfiguration_600031, base: "/",
    url: url_DescribeCompanyNetworkConfiguration_600032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDevice_600044 = ref object of OpenApiRestCall_599368
proc url_DescribeDevice_600046(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDevice_600045(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Provides information about a user's device.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600047 = header.getOrDefault("X-Amz-Date")
  valid_600047 = validateParameter(valid_600047, JString, required = false,
                                 default = nil)
  if valid_600047 != nil:
    section.add "X-Amz-Date", valid_600047
  var valid_600048 = header.getOrDefault("X-Amz-Security-Token")
  valid_600048 = validateParameter(valid_600048, JString, required = false,
                                 default = nil)
  if valid_600048 != nil:
    section.add "X-Amz-Security-Token", valid_600048
  var valid_600049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600049 = validateParameter(valid_600049, JString, required = false,
                                 default = nil)
  if valid_600049 != nil:
    section.add "X-Amz-Content-Sha256", valid_600049
  var valid_600050 = header.getOrDefault("X-Amz-Algorithm")
  valid_600050 = validateParameter(valid_600050, JString, required = false,
                                 default = nil)
  if valid_600050 != nil:
    section.add "X-Amz-Algorithm", valid_600050
  var valid_600051 = header.getOrDefault("X-Amz-Signature")
  valid_600051 = validateParameter(valid_600051, JString, required = false,
                                 default = nil)
  if valid_600051 != nil:
    section.add "X-Amz-Signature", valid_600051
  var valid_600052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-SignedHeaders", valid_600052
  var valid_600053 = header.getOrDefault("X-Amz-Credential")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Credential", valid_600053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600055: Call_DescribeDevice_600044; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about a user's device.
  ## 
  let valid = call_600055.validator(path, query, header, formData, body)
  let scheme = call_600055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600055.url(scheme.get, call_600055.host, call_600055.base,
                         call_600055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600055, url, valid)

proc call*(call_600056: Call_DescribeDevice_600044; body: JsonNode): Recallable =
  ## describeDevice
  ## Provides information about a user's device.
  ##   body: JObject (required)
  var body_600057 = newJObject()
  if body != nil:
    body_600057 = body
  result = call_600056.call(nil, nil, nil, nil, body_600057)

var describeDevice* = Call_DescribeDevice_600044(name: "describeDevice",
    meth: HttpMethod.HttpPost, host: "worklink.amazonaws.com",
    route: "/describeDevice", validator: validate_DescribeDevice_600045, base: "/",
    url: url_DescribeDevice_600046, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDevicePolicyConfiguration_600058 = ref object of OpenApiRestCall_599368
proc url_DescribeDevicePolicyConfiguration_600060(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDevicePolicyConfiguration_600059(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the device policy configuration for the specified fleet.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600061 = header.getOrDefault("X-Amz-Date")
  valid_600061 = validateParameter(valid_600061, JString, required = false,
                                 default = nil)
  if valid_600061 != nil:
    section.add "X-Amz-Date", valid_600061
  var valid_600062 = header.getOrDefault("X-Amz-Security-Token")
  valid_600062 = validateParameter(valid_600062, JString, required = false,
                                 default = nil)
  if valid_600062 != nil:
    section.add "X-Amz-Security-Token", valid_600062
  var valid_600063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600063 = validateParameter(valid_600063, JString, required = false,
                                 default = nil)
  if valid_600063 != nil:
    section.add "X-Amz-Content-Sha256", valid_600063
  var valid_600064 = header.getOrDefault("X-Amz-Algorithm")
  valid_600064 = validateParameter(valid_600064, JString, required = false,
                                 default = nil)
  if valid_600064 != nil:
    section.add "X-Amz-Algorithm", valid_600064
  var valid_600065 = header.getOrDefault("X-Amz-Signature")
  valid_600065 = validateParameter(valid_600065, JString, required = false,
                                 default = nil)
  if valid_600065 != nil:
    section.add "X-Amz-Signature", valid_600065
  var valid_600066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600066 = validateParameter(valid_600066, JString, required = false,
                                 default = nil)
  if valid_600066 != nil:
    section.add "X-Amz-SignedHeaders", valid_600066
  var valid_600067 = header.getOrDefault("X-Amz-Credential")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Credential", valid_600067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600069: Call_DescribeDevicePolicyConfiguration_600058;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the device policy configuration for the specified fleet.
  ## 
  let valid = call_600069.validator(path, query, header, formData, body)
  let scheme = call_600069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600069.url(scheme.get, call_600069.host, call_600069.base,
                         call_600069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600069, url, valid)

proc call*(call_600070: Call_DescribeDevicePolicyConfiguration_600058;
          body: JsonNode): Recallable =
  ## describeDevicePolicyConfiguration
  ## Describes the device policy configuration for the specified fleet.
  ##   body: JObject (required)
  var body_600071 = newJObject()
  if body != nil:
    body_600071 = body
  result = call_600070.call(nil, nil, nil, nil, body_600071)

var describeDevicePolicyConfiguration* = Call_DescribeDevicePolicyConfiguration_600058(
    name: "describeDevicePolicyConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/describeDevicePolicyConfiguration",
    validator: validate_DescribeDevicePolicyConfiguration_600059, base: "/",
    url: url_DescribeDevicePolicyConfiguration_600060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDomain_600072 = ref object of OpenApiRestCall_599368
proc url_DescribeDomain_600074(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDomain_600073(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Provides information about the domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600075 = header.getOrDefault("X-Amz-Date")
  valid_600075 = validateParameter(valid_600075, JString, required = false,
                                 default = nil)
  if valid_600075 != nil:
    section.add "X-Amz-Date", valid_600075
  var valid_600076 = header.getOrDefault("X-Amz-Security-Token")
  valid_600076 = validateParameter(valid_600076, JString, required = false,
                                 default = nil)
  if valid_600076 != nil:
    section.add "X-Amz-Security-Token", valid_600076
  var valid_600077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600077 = validateParameter(valid_600077, JString, required = false,
                                 default = nil)
  if valid_600077 != nil:
    section.add "X-Amz-Content-Sha256", valid_600077
  var valid_600078 = header.getOrDefault("X-Amz-Algorithm")
  valid_600078 = validateParameter(valid_600078, JString, required = false,
                                 default = nil)
  if valid_600078 != nil:
    section.add "X-Amz-Algorithm", valid_600078
  var valid_600079 = header.getOrDefault("X-Amz-Signature")
  valid_600079 = validateParameter(valid_600079, JString, required = false,
                                 default = nil)
  if valid_600079 != nil:
    section.add "X-Amz-Signature", valid_600079
  var valid_600080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600080 = validateParameter(valid_600080, JString, required = false,
                                 default = nil)
  if valid_600080 != nil:
    section.add "X-Amz-SignedHeaders", valid_600080
  var valid_600081 = header.getOrDefault("X-Amz-Credential")
  valid_600081 = validateParameter(valid_600081, JString, required = false,
                                 default = nil)
  if valid_600081 != nil:
    section.add "X-Amz-Credential", valid_600081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600083: Call_DescribeDomain_600072; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about the domain.
  ## 
  let valid = call_600083.validator(path, query, header, formData, body)
  let scheme = call_600083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600083.url(scheme.get, call_600083.host, call_600083.base,
                         call_600083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600083, url, valid)

proc call*(call_600084: Call_DescribeDomain_600072; body: JsonNode): Recallable =
  ## describeDomain
  ## Provides information about the domain.
  ##   body: JObject (required)
  var body_600085 = newJObject()
  if body != nil:
    body_600085 = body
  result = call_600084.call(nil, nil, nil, nil, body_600085)

var describeDomain* = Call_DescribeDomain_600072(name: "describeDomain",
    meth: HttpMethod.HttpPost, host: "worklink.amazonaws.com",
    route: "/describeDomain", validator: validate_DescribeDomain_600073, base: "/",
    url: url_DescribeDomain_600074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFleetMetadata_600086 = ref object of OpenApiRestCall_599368
proc url_DescribeFleetMetadata_600088(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeFleetMetadata_600087(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Provides basic information for the specified fleet, excluding identity provider, networking, and device configuration details.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600089 = header.getOrDefault("X-Amz-Date")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Date", valid_600089
  var valid_600090 = header.getOrDefault("X-Amz-Security-Token")
  valid_600090 = validateParameter(valid_600090, JString, required = false,
                                 default = nil)
  if valid_600090 != nil:
    section.add "X-Amz-Security-Token", valid_600090
  var valid_600091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600091 = validateParameter(valid_600091, JString, required = false,
                                 default = nil)
  if valid_600091 != nil:
    section.add "X-Amz-Content-Sha256", valid_600091
  var valid_600092 = header.getOrDefault("X-Amz-Algorithm")
  valid_600092 = validateParameter(valid_600092, JString, required = false,
                                 default = nil)
  if valid_600092 != nil:
    section.add "X-Amz-Algorithm", valid_600092
  var valid_600093 = header.getOrDefault("X-Amz-Signature")
  valid_600093 = validateParameter(valid_600093, JString, required = false,
                                 default = nil)
  if valid_600093 != nil:
    section.add "X-Amz-Signature", valid_600093
  var valid_600094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600094 = validateParameter(valid_600094, JString, required = false,
                                 default = nil)
  if valid_600094 != nil:
    section.add "X-Amz-SignedHeaders", valid_600094
  var valid_600095 = header.getOrDefault("X-Amz-Credential")
  valid_600095 = validateParameter(valid_600095, JString, required = false,
                                 default = nil)
  if valid_600095 != nil:
    section.add "X-Amz-Credential", valid_600095
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600097: Call_DescribeFleetMetadata_600086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides basic information for the specified fleet, excluding identity provider, networking, and device configuration details.
  ## 
  let valid = call_600097.validator(path, query, header, formData, body)
  let scheme = call_600097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600097.url(scheme.get, call_600097.host, call_600097.base,
                         call_600097.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600097, url, valid)

proc call*(call_600098: Call_DescribeFleetMetadata_600086; body: JsonNode): Recallable =
  ## describeFleetMetadata
  ## Provides basic information for the specified fleet, excluding identity provider, networking, and device configuration details.
  ##   body: JObject (required)
  var body_600099 = newJObject()
  if body != nil:
    body_600099 = body
  result = call_600098.call(nil, nil, nil, nil, body_600099)

var describeFleetMetadata* = Call_DescribeFleetMetadata_600086(
    name: "describeFleetMetadata", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/describeFleetMetadata",
    validator: validate_DescribeFleetMetadata_600087, base: "/",
    url: url_DescribeFleetMetadata_600088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentityProviderConfiguration_600100 = ref object of OpenApiRestCall_599368
proc url_DescribeIdentityProviderConfiguration_600102(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeIdentityProviderConfiguration_600101(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the identity provider configuration of the specified fleet.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600103 = header.getOrDefault("X-Amz-Date")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-Date", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-Security-Token")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-Security-Token", valid_600104
  var valid_600105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "X-Amz-Content-Sha256", valid_600105
  var valid_600106 = header.getOrDefault("X-Amz-Algorithm")
  valid_600106 = validateParameter(valid_600106, JString, required = false,
                                 default = nil)
  if valid_600106 != nil:
    section.add "X-Amz-Algorithm", valid_600106
  var valid_600107 = header.getOrDefault("X-Amz-Signature")
  valid_600107 = validateParameter(valid_600107, JString, required = false,
                                 default = nil)
  if valid_600107 != nil:
    section.add "X-Amz-Signature", valid_600107
  var valid_600108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600108 = validateParameter(valid_600108, JString, required = false,
                                 default = nil)
  if valid_600108 != nil:
    section.add "X-Amz-SignedHeaders", valid_600108
  var valid_600109 = header.getOrDefault("X-Amz-Credential")
  valid_600109 = validateParameter(valid_600109, JString, required = false,
                                 default = nil)
  if valid_600109 != nil:
    section.add "X-Amz-Credential", valid_600109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600111: Call_DescribeIdentityProviderConfiguration_600100;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the identity provider configuration of the specified fleet.
  ## 
  let valid = call_600111.validator(path, query, header, formData, body)
  let scheme = call_600111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600111.url(scheme.get, call_600111.host, call_600111.base,
                         call_600111.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600111, url, valid)

proc call*(call_600112: Call_DescribeIdentityProviderConfiguration_600100;
          body: JsonNode): Recallable =
  ## describeIdentityProviderConfiguration
  ## Describes the identity provider configuration of the specified fleet.
  ##   body: JObject (required)
  var body_600113 = newJObject()
  if body != nil:
    body_600113 = body
  result = call_600112.call(nil, nil, nil, nil, body_600113)

var describeIdentityProviderConfiguration* = Call_DescribeIdentityProviderConfiguration_600100(
    name: "describeIdentityProviderConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com",
    route: "/describeIdentityProviderConfiguration",
    validator: validate_DescribeIdentityProviderConfiguration_600101, base: "/",
    url: url_DescribeIdentityProviderConfiguration_600102,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWebsiteCertificateAuthority_600114 = ref object of OpenApiRestCall_599368
proc url_DescribeWebsiteCertificateAuthority_600116(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeWebsiteCertificateAuthority_600115(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Provides information about the certificate authority.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600117 = header.getOrDefault("X-Amz-Date")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-Date", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-Security-Token")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-Security-Token", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Content-Sha256", valid_600119
  var valid_600120 = header.getOrDefault("X-Amz-Algorithm")
  valid_600120 = validateParameter(valid_600120, JString, required = false,
                                 default = nil)
  if valid_600120 != nil:
    section.add "X-Amz-Algorithm", valid_600120
  var valid_600121 = header.getOrDefault("X-Amz-Signature")
  valid_600121 = validateParameter(valid_600121, JString, required = false,
                                 default = nil)
  if valid_600121 != nil:
    section.add "X-Amz-Signature", valid_600121
  var valid_600122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "X-Amz-SignedHeaders", valid_600122
  var valid_600123 = header.getOrDefault("X-Amz-Credential")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "X-Amz-Credential", valid_600123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600125: Call_DescribeWebsiteCertificateAuthority_600114;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Provides information about the certificate authority.
  ## 
  let valid = call_600125.validator(path, query, header, formData, body)
  let scheme = call_600125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600125.url(scheme.get, call_600125.host, call_600125.base,
                         call_600125.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600125, url, valid)

proc call*(call_600126: Call_DescribeWebsiteCertificateAuthority_600114;
          body: JsonNode): Recallable =
  ## describeWebsiteCertificateAuthority
  ## Provides information about the certificate authority.
  ##   body: JObject (required)
  var body_600127 = newJObject()
  if body != nil:
    body_600127 = body
  result = call_600126.call(nil, nil, nil, nil, body_600127)

var describeWebsiteCertificateAuthority* = Call_DescribeWebsiteCertificateAuthority_600114(
    name: "describeWebsiteCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/describeWebsiteCertificateAuthority",
    validator: validate_DescribeWebsiteCertificateAuthority_600115, base: "/",
    url: url_DescribeWebsiteCertificateAuthority_600116,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateDomain_600128 = ref object of OpenApiRestCall_599368
proc url_DisassociateDomain_600130(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateDomain_600129(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Disassociates a domain from Amazon WorkLink. End users lose the ability to access the domain with Amazon WorkLink. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600131 = header.getOrDefault("X-Amz-Date")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Date", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-Security-Token")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Security-Token", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-Content-Sha256", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-Algorithm")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Algorithm", valid_600134
  var valid_600135 = header.getOrDefault("X-Amz-Signature")
  valid_600135 = validateParameter(valid_600135, JString, required = false,
                                 default = nil)
  if valid_600135 != nil:
    section.add "X-Amz-Signature", valid_600135
  var valid_600136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600136 = validateParameter(valid_600136, JString, required = false,
                                 default = nil)
  if valid_600136 != nil:
    section.add "X-Amz-SignedHeaders", valid_600136
  var valid_600137 = header.getOrDefault("X-Amz-Credential")
  valid_600137 = validateParameter(valid_600137, JString, required = false,
                                 default = nil)
  if valid_600137 != nil:
    section.add "X-Amz-Credential", valid_600137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600139: Call_DisassociateDomain_600128; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a domain from Amazon WorkLink. End users lose the ability to access the domain with Amazon WorkLink. 
  ## 
  let valid = call_600139.validator(path, query, header, formData, body)
  let scheme = call_600139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600139.url(scheme.get, call_600139.host, call_600139.base,
                         call_600139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600139, url, valid)

proc call*(call_600140: Call_DisassociateDomain_600128; body: JsonNode): Recallable =
  ## disassociateDomain
  ## Disassociates a domain from Amazon WorkLink. End users lose the ability to access the domain with Amazon WorkLink. 
  ##   body: JObject (required)
  var body_600141 = newJObject()
  if body != nil:
    body_600141 = body
  result = call_600140.call(nil, nil, nil, nil, body_600141)

var disassociateDomain* = Call_DisassociateDomain_600128(
    name: "disassociateDomain", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/disassociateDomain",
    validator: validate_DisassociateDomain_600129, base: "/",
    url: url_DisassociateDomain_600130, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateWebsiteAuthorizationProvider_600142 = ref object of OpenApiRestCall_599368
proc url_DisassociateWebsiteAuthorizationProvider_600144(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateWebsiteAuthorizationProvider_600143(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disassociates a website authorization provider from a specified fleet. After the disassociation, users can't load any associated websites that require this authorization provider.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600145 = header.getOrDefault("X-Amz-Date")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Date", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Security-Token")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Security-Token", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Content-Sha256", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-Algorithm")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-Algorithm", valid_600148
  var valid_600149 = header.getOrDefault("X-Amz-Signature")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-Signature", valid_600149
  var valid_600150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600150 = validateParameter(valid_600150, JString, required = false,
                                 default = nil)
  if valid_600150 != nil:
    section.add "X-Amz-SignedHeaders", valid_600150
  var valid_600151 = header.getOrDefault("X-Amz-Credential")
  valid_600151 = validateParameter(valid_600151, JString, required = false,
                                 default = nil)
  if valid_600151 != nil:
    section.add "X-Amz-Credential", valid_600151
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600153: Call_DisassociateWebsiteAuthorizationProvider_600142;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a website authorization provider from a specified fleet. After the disassociation, users can't load any associated websites that require this authorization provider.
  ## 
  let valid = call_600153.validator(path, query, header, formData, body)
  let scheme = call_600153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600153.url(scheme.get, call_600153.host, call_600153.base,
                         call_600153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600153, url, valid)

proc call*(call_600154: Call_DisassociateWebsiteAuthorizationProvider_600142;
          body: JsonNode): Recallable =
  ## disassociateWebsiteAuthorizationProvider
  ## Disassociates a website authorization provider from a specified fleet. After the disassociation, users can't load any associated websites that require this authorization provider.
  ##   body: JObject (required)
  var body_600155 = newJObject()
  if body != nil:
    body_600155 = body
  result = call_600154.call(nil, nil, nil, nil, body_600155)

var disassociateWebsiteAuthorizationProvider* = Call_DisassociateWebsiteAuthorizationProvider_600142(
    name: "disassociateWebsiteAuthorizationProvider", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com",
    route: "/disassociateWebsiteAuthorizationProvider",
    validator: validate_DisassociateWebsiteAuthorizationProvider_600143,
    base: "/", url: url_DisassociateWebsiteAuthorizationProvider_600144,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateWebsiteCertificateAuthority_600156 = ref object of OpenApiRestCall_599368
proc url_DisassociateWebsiteCertificateAuthority_600158(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateWebsiteCertificateAuthority_600157(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a certificate authority (CA).
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600159 = header.getOrDefault("X-Amz-Date")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "X-Amz-Date", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-Security-Token")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-Security-Token", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Content-Sha256", valid_600161
  var valid_600162 = header.getOrDefault("X-Amz-Algorithm")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-Algorithm", valid_600162
  var valid_600163 = header.getOrDefault("X-Amz-Signature")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-Signature", valid_600163
  var valid_600164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600164 = validateParameter(valid_600164, JString, required = false,
                                 default = nil)
  if valid_600164 != nil:
    section.add "X-Amz-SignedHeaders", valid_600164
  var valid_600165 = header.getOrDefault("X-Amz-Credential")
  valid_600165 = validateParameter(valid_600165, JString, required = false,
                                 default = nil)
  if valid_600165 != nil:
    section.add "X-Amz-Credential", valid_600165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600167: Call_DisassociateWebsiteCertificateAuthority_600156;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a certificate authority (CA).
  ## 
  let valid = call_600167.validator(path, query, header, formData, body)
  let scheme = call_600167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600167.url(scheme.get, call_600167.host, call_600167.base,
                         call_600167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600167, url, valid)

proc call*(call_600168: Call_DisassociateWebsiteCertificateAuthority_600156;
          body: JsonNode): Recallable =
  ## disassociateWebsiteCertificateAuthority
  ## Removes a certificate authority (CA).
  ##   body: JObject (required)
  var body_600169 = newJObject()
  if body != nil:
    body_600169 = body
  result = call_600168.call(nil, nil, nil, nil, body_600169)

var disassociateWebsiteCertificateAuthority* = Call_DisassociateWebsiteCertificateAuthority_600156(
    name: "disassociateWebsiteCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com",
    route: "/disassociateWebsiteCertificateAuthority",
    validator: validate_DisassociateWebsiteCertificateAuthority_600157, base: "/",
    url: url_DisassociateWebsiteCertificateAuthority_600158,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevices_600170 = ref object of OpenApiRestCall_599368
proc url_ListDevices_600172(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDevices_600171(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of devices registered with the specified fleet.
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
  var valid_600173 = query.getOrDefault("NextToken")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "NextToken", valid_600173
  var valid_600174 = query.getOrDefault("MaxResults")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "MaxResults", valid_600174
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600175 = header.getOrDefault("X-Amz-Date")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-Date", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-Security-Token")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-Security-Token", valid_600176
  var valid_600177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "X-Amz-Content-Sha256", valid_600177
  var valid_600178 = header.getOrDefault("X-Amz-Algorithm")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "X-Amz-Algorithm", valid_600178
  var valid_600179 = header.getOrDefault("X-Amz-Signature")
  valid_600179 = validateParameter(valid_600179, JString, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "X-Amz-Signature", valid_600179
  var valid_600180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600180 = validateParameter(valid_600180, JString, required = false,
                                 default = nil)
  if valid_600180 != nil:
    section.add "X-Amz-SignedHeaders", valid_600180
  var valid_600181 = header.getOrDefault("X-Amz-Credential")
  valid_600181 = validateParameter(valid_600181, JString, required = false,
                                 default = nil)
  if valid_600181 != nil:
    section.add "X-Amz-Credential", valid_600181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600183: Call_ListDevices_600170; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of devices registered with the specified fleet.
  ## 
  let valid = call_600183.validator(path, query, header, formData, body)
  let scheme = call_600183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600183.url(scheme.get, call_600183.host, call_600183.base,
                         call_600183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600183, url, valid)

proc call*(call_600184: Call_ListDevices_600170; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDevices
  ## Retrieves a list of devices registered with the specified fleet.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600185 = newJObject()
  var body_600186 = newJObject()
  add(query_600185, "NextToken", newJString(NextToken))
  if body != nil:
    body_600186 = body
  add(query_600185, "MaxResults", newJString(MaxResults))
  result = call_600184.call(nil, query_600185, nil, nil, body_600186)

var listDevices* = Call_ListDevices_600170(name: "listDevices",
                                        meth: HttpMethod.HttpPost,
                                        host: "worklink.amazonaws.com",
                                        route: "/listDevices",
                                        validator: validate_ListDevices_600171,
                                        base: "/", url: url_ListDevices_600172,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomains_600188 = ref object of OpenApiRestCall_599368
proc url_ListDomains_600190(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDomains_600189(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of domains associated to a specified fleet.
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
  var valid_600191 = query.getOrDefault("NextToken")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "NextToken", valid_600191
  var valid_600192 = query.getOrDefault("MaxResults")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "MaxResults", valid_600192
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600193 = header.getOrDefault("X-Amz-Date")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-Date", valid_600193
  var valid_600194 = header.getOrDefault("X-Amz-Security-Token")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-Security-Token", valid_600194
  var valid_600195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600195 = validateParameter(valid_600195, JString, required = false,
                                 default = nil)
  if valid_600195 != nil:
    section.add "X-Amz-Content-Sha256", valid_600195
  var valid_600196 = header.getOrDefault("X-Amz-Algorithm")
  valid_600196 = validateParameter(valid_600196, JString, required = false,
                                 default = nil)
  if valid_600196 != nil:
    section.add "X-Amz-Algorithm", valid_600196
  var valid_600197 = header.getOrDefault("X-Amz-Signature")
  valid_600197 = validateParameter(valid_600197, JString, required = false,
                                 default = nil)
  if valid_600197 != nil:
    section.add "X-Amz-Signature", valid_600197
  var valid_600198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600198 = validateParameter(valid_600198, JString, required = false,
                                 default = nil)
  if valid_600198 != nil:
    section.add "X-Amz-SignedHeaders", valid_600198
  var valid_600199 = header.getOrDefault("X-Amz-Credential")
  valid_600199 = validateParameter(valid_600199, JString, required = false,
                                 default = nil)
  if valid_600199 != nil:
    section.add "X-Amz-Credential", valid_600199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600201: Call_ListDomains_600188; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of domains associated to a specified fleet.
  ## 
  let valid = call_600201.validator(path, query, header, formData, body)
  let scheme = call_600201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600201.url(scheme.get, call_600201.host, call_600201.base,
                         call_600201.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600201, url, valid)

proc call*(call_600202: Call_ListDomains_600188; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDomains
  ## Retrieves a list of domains associated to a specified fleet.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600203 = newJObject()
  var body_600204 = newJObject()
  add(query_600203, "NextToken", newJString(NextToken))
  if body != nil:
    body_600204 = body
  add(query_600203, "MaxResults", newJString(MaxResults))
  result = call_600202.call(nil, query_600203, nil, nil, body_600204)

var listDomains* = Call_ListDomains_600188(name: "listDomains",
                                        meth: HttpMethod.HttpPost,
                                        host: "worklink.amazonaws.com",
                                        route: "/listDomains",
                                        validator: validate_ListDomains_600189,
                                        base: "/", url: url_ListDomains_600190,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFleets_600205 = ref object of OpenApiRestCall_599368
proc url_ListFleets_600207(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFleets_600206(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of fleets for the current account and Region.
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
  var valid_600208 = query.getOrDefault("NextToken")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "NextToken", valid_600208
  var valid_600209 = query.getOrDefault("MaxResults")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "MaxResults", valid_600209
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600210 = header.getOrDefault("X-Amz-Date")
  valid_600210 = validateParameter(valid_600210, JString, required = false,
                                 default = nil)
  if valid_600210 != nil:
    section.add "X-Amz-Date", valid_600210
  var valid_600211 = header.getOrDefault("X-Amz-Security-Token")
  valid_600211 = validateParameter(valid_600211, JString, required = false,
                                 default = nil)
  if valid_600211 != nil:
    section.add "X-Amz-Security-Token", valid_600211
  var valid_600212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600212 = validateParameter(valid_600212, JString, required = false,
                                 default = nil)
  if valid_600212 != nil:
    section.add "X-Amz-Content-Sha256", valid_600212
  var valid_600213 = header.getOrDefault("X-Amz-Algorithm")
  valid_600213 = validateParameter(valid_600213, JString, required = false,
                                 default = nil)
  if valid_600213 != nil:
    section.add "X-Amz-Algorithm", valid_600213
  var valid_600214 = header.getOrDefault("X-Amz-Signature")
  valid_600214 = validateParameter(valid_600214, JString, required = false,
                                 default = nil)
  if valid_600214 != nil:
    section.add "X-Amz-Signature", valid_600214
  var valid_600215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600215 = validateParameter(valid_600215, JString, required = false,
                                 default = nil)
  if valid_600215 != nil:
    section.add "X-Amz-SignedHeaders", valid_600215
  var valid_600216 = header.getOrDefault("X-Amz-Credential")
  valid_600216 = validateParameter(valid_600216, JString, required = false,
                                 default = nil)
  if valid_600216 != nil:
    section.add "X-Amz-Credential", valid_600216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600218: Call_ListFleets_600205; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of fleets for the current account and Region.
  ## 
  let valid = call_600218.validator(path, query, header, formData, body)
  let scheme = call_600218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600218.url(scheme.get, call_600218.host, call_600218.base,
                         call_600218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600218, url, valid)

proc call*(call_600219: Call_ListFleets_600205; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listFleets
  ## Retrieves a list of fleets for the current account and Region.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600220 = newJObject()
  var body_600221 = newJObject()
  add(query_600220, "NextToken", newJString(NextToken))
  if body != nil:
    body_600221 = body
  add(query_600220, "MaxResults", newJString(MaxResults))
  result = call_600219.call(nil, query_600220, nil, nil, body_600221)

var listFleets* = Call_ListFleets_600205(name: "listFleets",
                                      meth: HttpMethod.HttpPost,
                                      host: "worklink.amazonaws.com",
                                      route: "/listFleets",
                                      validator: validate_ListFleets_600206,
                                      base: "/", url: url_ListFleets_600207,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWebsiteAuthorizationProviders_600222 = ref object of OpenApiRestCall_599368
proc url_ListWebsiteAuthorizationProviders_600224(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListWebsiteAuthorizationProviders_600223(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of website authorization providers associated with a specified fleet.
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
  var valid_600225 = query.getOrDefault("NextToken")
  valid_600225 = validateParameter(valid_600225, JString, required = false,
                                 default = nil)
  if valid_600225 != nil:
    section.add "NextToken", valid_600225
  var valid_600226 = query.getOrDefault("MaxResults")
  valid_600226 = validateParameter(valid_600226, JString, required = false,
                                 default = nil)
  if valid_600226 != nil:
    section.add "MaxResults", valid_600226
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600227 = header.getOrDefault("X-Amz-Date")
  valid_600227 = validateParameter(valid_600227, JString, required = false,
                                 default = nil)
  if valid_600227 != nil:
    section.add "X-Amz-Date", valid_600227
  var valid_600228 = header.getOrDefault("X-Amz-Security-Token")
  valid_600228 = validateParameter(valid_600228, JString, required = false,
                                 default = nil)
  if valid_600228 != nil:
    section.add "X-Amz-Security-Token", valid_600228
  var valid_600229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600229 = validateParameter(valid_600229, JString, required = false,
                                 default = nil)
  if valid_600229 != nil:
    section.add "X-Amz-Content-Sha256", valid_600229
  var valid_600230 = header.getOrDefault("X-Amz-Algorithm")
  valid_600230 = validateParameter(valid_600230, JString, required = false,
                                 default = nil)
  if valid_600230 != nil:
    section.add "X-Amz-Algorithm", valid_600230
  var valid_600231 = header.getOrDefault("X-Amz-Signature")
  valid_600231 = validateParameter(valid_600231, JString, required = false,
                                 default = nil)
  if valid_600231 != nil:
    section.add "X-Amz-Signature", valid_600231
  var valid_600232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "X-Amz-SignedHeaders", valid_600232
  var valid_600233 = header.getOrDefault("X-Amz-Credential")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-Credential", valid_600233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600235: Call_ListWebsiteAuthorizationProviders_600222;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves a list of website authorization providers associated with a specified fleet.
  ## 
  let valid = call_600235.validator(path, query, header, formData, body)
  let scheme = call_600235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600235.url(scheme.get, call_600235.host, call_600235.base,
                         call_600235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600235, url, valid)

proc call*(call_600236: Call_ListWebsiteAuthorizationProviders_600222;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listWebsiteAuthorizationProviders
  ## Retrieves a list of website authorization providers associated with a specified fleet.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600237 = newJObject()
  var body_600238 = newJObject()
  add(query_600237, "NextToken", newJString(NextToken))
  if body != nil:
    body_600238 = body
  add(query_600237, "MaxResults", newJString(MaxResults))
  result = call_600236.call(nil, query_600237, nil, nil, body_600238)

var listWebsiteAuthorizationProviders* = Call_ListWebsiteAuthorizationProviders_600222(
    name: "listWebsiteAuthorizationProviders", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/listWebsiteAuthorizationProviders",
    validator: validate_ListWebsiteAuthorizationProviders_600223, base: "/",
    url: url_ListWebsiteAuthorizationProviders_600224,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWebsiteCertificateAuthorities_600239 = ref object of OpenApiRestCall_599368
proc url_ListWebsiteCertificateAuthorities_600241(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListWebsiteCertificateAuthorities_600240(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of certificate authorities added for the current account and Region.
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
  var valid_600242 = query.getOrDefault("NextToken")
  valid_600242 = validateParameter(valid_600242, JString, required = false,
                                 default = nil)
  if valid_600242 != nil:
    section.add "NextToken", valid_600242
  var valid_600243 = query.getOrDefault("MaxResults")
  valid_600243 = validateParameter(valid_600243, JString, required = false,
                                 default = nil)
  if valid_600243 != nil:
    section.add "MaxResults", valid_600243
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600244 = header.getOrDefault("X-Amz-Date")
  valid_600244 = validateParameter(valid_600244, JString, required = false,
                                 default = nil)
  if valid_600244 != nil:
    section.add "X-Amz-Date", valid_600244
  var valid_600245 = header.getOrDefault("X-Amz-Security-Token")
  valid_600245 = validateParameter(valid_600245, JString, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "X-Amz-Security-Token", valid_600245
  var valid_600246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600246 = validateParameter(valid_600246, JString, required = false,
                                 default = nil)
  if valid_600246 != nil:
    section.add "X-Amz-Content-Sha256", valid_600246
  var valid_600247 = header.getOrDefault("X-Amz-Algorithm")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "X-Amz-Algorithm", valid_600247
  var valid_600248 = header.getOrDefault("X-Amz-Signature")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "X-Amz-Signature", valid_600248
  var valid_600249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600249 = validateParameter(valid_600249, JString, required = false,
                                 default = nil)
  if valid_600249 != nil:
    section.add "X-Amz-SignedHeaders", valid_600249
  var valid_600250 = header.getOrDefault("X-Amz-Credential")
  valid_600250 = validateParameter(valid_600250, JString, required = false,
                                 default = nil)
  if valid_600250 != nil:
    section.add "X-Amz-Credential", valid_600250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600252: Call_ListWebsiteCertificateAuthorities_600239;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves a list of certificate authorities added for the current account and Region.
  ## 
  let valid = call_600252.validator(path, query, header, formData, body)
  let scheme = call_600252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600252.url(scheme.get, call_600252.host, call_600252.base,
                         call_600252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600252, url, valid)

proc call*(call_600253: Call_ListWebsiteCertificateAuthorities_600239;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listWebsiteCertificateAuthorities
  ## Retrieves a list of certificate authorities added for the current account and Region.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600254 = newJObject()
  var body_600255 = newJObject()
  add(query_600254, "NextToken", newJString(NextToken))
  if body != nil:
    body_600255 = body
  add(query_600254, "MaxResults", newJString(MaxResults))
  result = call_600253.call(nil, query_600254, nil, nil, body_600255)

var listWebsiteCertificateAuthorities* = Call_ListWebsiteCertificateAuthorities_600239(
    name: "listWebsiteCertificateAuthorities", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/listWebsiteCertificateAuthorities",
    validator: validate_ListWebsiteCertificateAuthorities_600240, base: "/",
    url: url_ListWebsiteCertificateAuthorities_600241,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreDomainAccess_600256 = ref object of OpenApiRestCall_599368
proc url_RestoreDomainAccess_600258(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RestoreDomainAccess_600257(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Moves a domain to ACTIVE status if it was in the INACTIVE status.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600259 = header.getOrDefault("X-Amz-Date")
  valid_600259 = validateParameter(valid_600259, JString, required = false,
                                 default = nil)
  if valid_600259 != nil:
    section.add "X-Amz-Date", valid_600259
  var valid_600260 = header.getOrDefault("X-Amz-Security-Token")
  valid_600260 = validateParameter(valid_600260, JString, required = false,
                                 default = nil)
  if valid_600260 != nil:
    section.add "X-Amz-Security-Token", valid_600260
  var valid_600261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600261 = validateParameter(valid_600261, JString, required = false,
                                 default = nil)
  if valid_600261 != nil:
    section.add "X-Amz-Content-Sha256", valid_600261
  var valid_600262 = header.getOrDefault("X-Amz-Algorithm")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "X-Amz-Algorithm", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-Signature")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Signature", valid_600263
  var valid_600264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600264 = validateParameter(valid_600264, JString, required = false,
                                 default = nil)
  if valid_600264 != nil:
    section.add "X-Amz-SignedHeaders", valid_600264
  var valid_600265 = header.getOrDefault("X-Amz-Credential")
  valid_600265 = validateParameter(valid_600265, JString, required = false,
                                 default = nil)
  if valid_600265 != nil:
    section.add "X-Amz-Credential", valid_600265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600267: Call_RestoreDomainAccess_600256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Moves a domain to ACTIVE status if it was in the INACTIVE status.
  ## 
  let valid = call_600267.validator(path, query, header, formData, body)
  let scheme = call_600267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600267.url(scheme.get, call_600267.host, call_600267.base,
                         call_600267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600267, url, valid)

proc call*(call_600268: Call_RestoreDomainAccess_600256; body: JsonNode): Recallable =
  ## restoreDomainAccess
  ## Moves a domain to ACTIVE status if it was in the INACTIVE status.
  ##   body: JObject (required)
  var body_600269 = newJObject()
  if body != nil:
    body_600269 = body
  result = call_600268.call(nil, nil, nil, nil, body_600269)

var restoreDomainAccess* = Call_RestoreDomainAccess_600256(
    name: "restoreDomainAccess", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/restoreDomainAccess",
    validator: validate_RestoreDomainAccess_600257, base: "/",
    url: url_RestoreDomainAccess_600258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeDomainAccess_600270 = ref object of OpenApiRestCall_599368
proc url_RevokeDomainAccess_600272(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RevokeDomainAccess_600271(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Moves a domain to INACTIVE status if it was in the ACTIVE status.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600273 = header.getOrDefault("X-Amz-Date")
  valid_600273 = validateParameter(valid_600273, JString, required = false,
                                 default = nil)
  if valid_600273 != nil:
    section.add "X-Amz-Date", valid_600273
  var valid_600274 = header.getOrDefault("X-Amz-Security-Token")
  valid_600274 = validateParameter(valid_600274, JString, required = false,
                                 default = nil)
  if valid_600274 != nil:
    section.add "X-Amz-Security-Token", valid_600274
  var valid_600275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600275 = validateParameter(valid_600275, JString, required = false,
                                 default = nil)
  if valid_600275 != nil:
    section.add "X-Amz-Content-Sha256", valid_600275
  var valid_600276 = header.getOrDefault("X-Amz-Algorithm")
  valid_600276 = validateParameter(valid_600276, JString, required = false,
                                 default = nil)
  if valid_600276 != nil:
    section.add "X-Amz-Algorithm", valid_600276
  var valid_600277 = header.getOrDefault("X-Amz-Signature")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "X-Amz-Signature", valid_600277
  var valid_600278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-SignedHeaders", valid_600278
  var valid_600279 = header.getOrDefault("X-Amz-Credential")
  valid_600279 = validateParameter(valid_600279, JString, required = false,
                                 default = nil)
  if valid_600279 != nil:
    section.add "X-Amz-Credential", valid_600279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600281: Call_RevokeDomainAccess_600270; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Moves a domain to INACTIVE status if it was in the ACTIVE status.
  ## 
  let valid = call_600281.validator(path, query, header, formData, body)
  let scheme = call_600281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600281.url(scheme.get, call_600281.host, call_600281.base,
                         call_600281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600281, url, valid)

proc call*(call_600282: Call_RevokeDomainAccess_600270; body: JsonNode): Recallable =
  ## revokeDomainAccess
  ## Moves a domain to INACTIVE status if it was in the ACTIVE status.
  ##   body: JObject (required)
  var body_600283 = newJObject()
  if body != nil:
    body_600283 = body
  result = call_600282.call(nil, nil, nil, nil, body_600283)

var revokeDomainAccess* = Call_RevokeDomainAccess_600270(
    name: "revokeDomainAccess", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/revokeDomainAccess",
    validator: validate_RevokeDomainAccess_600271, base: "/",
    url: url_RevokeDomainAccess_600272, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SignOutUser_600284 = ref object of OpenApiRestCall_599368
proc url_SignOutUser_600286(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SignOutUser_600285(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Signs the user out from all of their devices. The user can sign in again if they have valid credentials.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600287 = header.getOrDefault("X-Amz-Date")
  valid_600287 = validateParameter(valid_600287, JString, required = false,
                                 default = nil)
  if valid_600287 != nil:
    section.add "X-Amz-Date", valid_600287
  var valid_600288 = header.getOrDefault("X-Amz-Security-Token")
  valid_600288 = validateParameter(valid_600288, JString, required = false,
                                 default = nil)
  if valid_600288 != nil:
    section.add "X-Amz-Security-Token", valid_600288
  var valid_600289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600289 = validateParameter(valid_600289, JString, required = false,
                                 default = nil)
  if valid_600289 != nil:
    section.add "X-Amz-Content-Sha256", valid_600289
  var valid_600290 = header.getOrDefault("X-Amz-Algorithm")
  valid_600290 = validateParameter(valid_600290, JString, required = false,
                                 default = nil)
  if valid_600290 != nil:
    section.add "X-Amz-Algorithm", valid_600290
  var valid_600291 = header.getOrDefault("X-Amz-Signature")
  valid_600291 = validateParameter(valid_600291, JString, required = false,
                                 default = nil)
  if valid_600291 != nil:
    section.add "X-Amz-Signature", valid_600291
  var valid_600292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600292 = validateParameter(valid_600292, JString, required = false,
                                 default = nil)
  if valid_600292 != nil:
    section.add "X-Amz-SignedHeaders", valid_600292
  var valid_600293 = header.getOrDefault("X-Amz-Credential")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Credential", valid_600293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600295: Call_SignOutUser_600284; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Signs the user out from all of their devices. The user can sign in again if they have valid credentials.
  ## 
  let valid = call_600295.validator(path, query, header, formData, body)
  let scheme = call_600295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600295.url(scheme.get, call_600295.host, call_600295.base,
                         call_600295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600295, url, valid)

proc call*(call_600296: Call_SignOutUser_600284; body: JsonNode): Recallable =
  ## signOutUser
  ## Signs the user out from all of their devices. The user can sign in again if they have valid credentials.
  ##   body: JObject (required)
  var body_600297 = newJObject()
  if body != nil:
    body_600297 = body
  result = call_600296.call(nil, nil, nil, nil, body_600297)

var signOutUser* = Call_SignOutUser_600284(name: "signOutUser",
                                        meth: HttpMethod.HttpPost,
                                        host: "worklink.amazonaws.com",
                                        route: "/signOutUser",
                                        validator: validate_SignOutUser_600285,
                                        base: "/", url: url_SignOutUser_600286,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuditStreamConfiguration_600298 = ref object of OpenApiRestCall_599368
proc url_UpdateAuditStreamConfiguration_600300(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateAuditStreamConfiguration_600299(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the audit stream configuration for the fleet.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600301 = header.getOrDefault("X-Amz-Date")
  valid_600301 = validateParameter(valid_600301, JString, required = false,
                                 default = nil)
  if valid_600301 != nil:
    section.add "X-Amz-Date", valid_600301
  var valid_600302 = header.getOrDefault("X-Amz-Security-Token")
  valid_600302 = validateParameter(valid_600302, JString, required = false,
                                 default = nil)
  if valid_600302 != nil:
    section.add "X-Amz-Security-Token", valid_600302
  var valid_600303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600303 = validateParameter(valid_600303, JString, required = false,
                                 default = nil)
  if valid_600303 != nil:
    section.add "X-Amz-Content-Sha256", valid_600303
  var valid_600304 = header.getOrDefault("X-Amz-Algorithm")
  valid_600304 = validateParameter(valid_600304, JString, required = false,
                                 default = nil)
  if valid_600304 != nil:
    section.add "X-Amz-Algorithm", valid_600304
  var valid_600305 = header.getOrDefault("X-Amz-Signature")
  valid_600305 = validateParameter(valid_600305, JString, required = false,
                                 default = nil)
  if valid_600305 != nil:
    section.add "X-Amz-Signature", valid_600305
  var valid_600306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600306 = validateParameter(valid_600306, JString, required = false,
                                 default = nil)
  if valid_600306 != nil:
    section.add "X-Amz-SignedHeaders", valid_600306
  var valid_600307 = header.getOrDefault("X-Amz-Credential")
  valid_600307 = validateParameter(valid_600307, JString, required = false,
                                 default = nil)
  if valid_600307 != nil:
    section.add "X-Amz-Credential", valid_600307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600309: Call_UpdateAuditStreamConfiguration_600298; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the audit stream configuration for the fleet.
  ## 
  let valid = call_600309.validator(path, query, header, formData, body)
  let scheme = call_600309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600309.url(scheme.get, call_600309.host, call_600309.base,
                         call_600309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600309, url, valid)

proc call*(call_600310: Call_UpdateAuditStreamConfiguration_600298; body: JsonNode): Recallable =
  ## updateAuditStreamConfiguration
  ## Updates the audit stream configuration for the fleet.
  ##   body: JObject (required)
  var body_600311 = newJObject()
  if body != nil:
    body_600311 = body
  result = call_600310.call(nil, nil, nil, nil, body_600311)

var updateAuditStreamConfiguration* = Call_UpdateAuditStreamConfiguration_600298(
    name: "updateAuditStreamConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/updateAuditStreamConfiguration",
    validator: validate_UpdateAuditStreamConfiguration_600299, base: "/",
    url: url_UpdateAuditStreamConfiguration_600300,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCompanyNetworkConfiguration_600312 = ref object of OpenApiRestCall_599368
proc url_UpdateCompanyNetworkConfiguration_600314(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateCompanyNetworkConfiguration_600313(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the company network configuration for the fleet.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600315 = header.getOrDefault("X-Amz-Date")
  valid_600315 = validateParameter(valid_600315, JString, required = false,
                                 default = nil)
  if valid_600315 != nil:
    section.add "X-Amz-Date", valid_600315
  var valid_600316 = header.getOrDefault("X-Amz-Security-Token")
  valid_600316 = validateParameter(valid_600316, JString, required = false,
                                 default = nil)
  if valid_600316 != nil:
    section.add "X-Amz-Security-Token", valid_600316
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

proc call*(call_600323: Call_UpdateCompanyNetworkConfiguration_600312;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the company network configuration for the fleet.
  ## 
  let valid = call_600323.validator(path, query, header, formData, body)
  let scheme = call_600323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600323.url(scheme.get, call_600323.host, call_600323.base,
                         call_600323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600323, url, valid)

proc call*(call_600324: Call_UpdateCompanyNetworkConfiguration_600312;
          body: JsonNode): Recallable =
  ## updateCompanyNetworkConfiguration
  ## Updates the company network configuration for the fleet.
  ##   body: JObject (required)
  var body_600325 = newJObject()
  if body != nil:
    body_600325 = body
  result = call_600324.call(nil, nil, nil, nil, body_600325)

var updateCompanyNetworkConfiguration* = Call_UpdateCompanyNetworkConfiguration_600312(
    name: "updateCompanyNetworkConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/updateCompanyNetworkConfiguration",
    validator: validate_UpdateCompanyNetworkConfiguration_600313, base: "/",
    url: url_UpdateCompanyNetworkConfiguration_600314,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevicePolicyConfiguration_600326 = ref object of OpenApiRestCall_599368
proc url_UpdateDevicePolicyConfiguration_600328(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDevicePolicyConfiguration_600327(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the device policy configuration for the fleet.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
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
  var valid_600331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600331 = validateParameter(valid_600331, JString, required = false,
                                 default = nil)
  if valid_600331 != nil:
    section.add "X-Amz-Content-Sha256", valid_600331
  var valid_600332 = header.getOrDefault("X-Amz-Algorithm")
  valid_600332 = validateParameter(valid_600332, JString, required = false,
                                 default = nil)
  if valid_600332 != nil:
    section.add "X-Amz-Algorithm", valid_600332
  var valid_600333 = header.getOrDefault("X-Amz-Signature")
  valid_600333 = validateParameter(valid_600333, JString, required = false,
                                 default = nil)
  if valid_600333 != nil:
    section.add "X-Amz-Signature", valid_600333
  var valid_600334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600334 = validateParameter(valid_600334, JString, required = false,
                                 default = nil)
  if valid_600334 != nil:
    section.add "X-Amz-SignedHeaders", valid_600334
  var valid_600335 = header.getOrDefault("X-Amz-Credential")
  valid_600335 = validateParameter(valid_600335, JString, required = false,
                                 default = nil)
  if valid_600335 != nil:
    section.add "X-Amz-Credential", valid_600335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600337: Call_UpdateDevicePolicyConfiguration_600326;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the device policy configuration for the fleet.
  ## 
  let valid = call_600337.validator(path, query, header, formData, body)
  let scheme = call_600337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600337.url(scheme.get, call_600337.host, call_600337.base,
                         call_600337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600337, url, valid)

proc call*(call_600338: Call_UpdateDevicePolicyConfiguration_600326; body: JsonNode): Recallable =
  ## updateDevicePolicyConfiguration
  ## Updates the device policy configuration for the fleet.
  ##   body: JObject (required)
  var body_600339 = newJObject()
  if body != nil:
    body_600339 = body
  result = call_600338.call(nil, nil, nil, nil, body_600339)

var updateDevicePolicyConfiguration* = Call_UpdateDevicePolicyConfiguration_600326(
    name: "updateDevicePolicyConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/updateDevicePolicyConfiguration",
    validator: validate_UpdateDevicePolicyConfiguration_600327, base: "/",
    url: url_UpdateDevicePolicyConfiguration_600328,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainMetadata_600340 = ref object of OpenApiRestCall_599368
proc url_UpdateDomainMetadata_600342(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDomainMetadata_600341(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates domain metadata, such as DisplayName.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600343 = header.getOrDefault("X-Amz-Date")
  valid_600343 = validateParameter(valid_600343, JString, required = false,
                                 default = nil)
  if valid_600343 != nil:
    section.add "X-Amz-Date", valid_600343
  var valid_600344 = header.getOrDefault("X-Amz-Security-Token")
  valid_600344 = validateParameter(valid_600344, JString, required = false,
                                 default = nil)
  if valid_600344 != nil:
    section.add "X-Amz-Security-Token", valid_600344
  var valid_600345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600345 = validateParameter(valid_600345, JString, required = false,
                                 default = nil)
  if valid_600345 != nil:
    section.add "X-Amz-Content-Sha256", valid_600345
  var valid_600346 = header.getOrDefault("X-Amz-Algorithm")
  valid_600346 = validateParameter(valid_600346, JString, required = false,
                                 default = nil)
  if valid_600346 != nil:
    section.add "X-Amz-Algorithm", valid_600346
  var valid_600347 = header.getOrDefault("X-Amz-Signature")
  valid_600347 = validateParameter(valid_600347, JString, required = false,
                                 default = nil)
  if valid_600347 != nil:
    section.add "X-Amz-Signature", valid_600347
  var valid_600348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600348 = validateParameter(valid_600348, JString, required = false,
                                 default = nil)
  if valid_600348 != nil:
    section.add "X-Amz-SignedHeaders", valid_600348
  var valid_600349 = header.getOrDefault("X-Amz-Credential")
  valid_600349 = validateParameter(valid_600349, JString, required = false,
                                 default = nil)
  if valid_600349 != nil:
    section.add "X-Amz-Credential", valid_600349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600351: Call_UpdateDomainMetadata_600340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates domain metadata, such as DisplayName.
  ## 
  let valid = call_600351.validator(path, query, header, formData, body)
  let scheme = call_600351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600351.url(scheme.get, call_600351.host, call_600351.base,
                         call_600351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600351, url, valid)

proc call*(call_600352: Call_UpdateDomainMetadata_600340; body: JsonNode): Recallable =
  ## updateDomainMetadata
  ## Updates domain metadata, such as DisplayName.
  ##   body: JObject (required)
  var body_600353 = newJObject()
  if body != nil:
    body_600353 = body
  result = call_600352.call(nil, nil, nil, nil, body_600353)

var updateDomainMetadata* = Call_UpdateDomainMetadata_600340(
    name: "updateDomainMetadata", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/updateDomainMetadata",
    validator: validate_UpdateDomainMetadata_600341, base: "/",
    url: url_UpdateDomainMetadata_600342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFleetMetadata_600354 = ref object of OpenApiRestCall_599368
proc url_UpdateFleetMetadata_600356(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateFleetMetadata_600355(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Updates fleet metadata, such as DisplayName.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600357 = header.getOrDefault("X-Amz-Date")
  valid_600357 = validateParameter(valid_600357, JString, required = false,
                                 default = nil)
  if valid_600357 != nil:
    section.add "X-Amz-Date", valid_600357
  var valid_600358 = header.getOrDefault("X-Amz-Security-Token")
  valid_600358 = validateParameter(valid_600358, JString, required = false,
                                 default = nil)
  if valid_600358 != nil:
    section.add "X-Amz-Security-Token", valid_600358
  var valid_600359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600359 = validateParameter(valid_600359, JString, required = false,
                                 default = nil)
  if valid_600359 != nil:
    section.add "X-Amz-Content-Sha256", valid_600359
  var valid_600360 = header.getOrDefault("X-Amz-Algorithm")
  valid_600360 = validateParameter(valid_600360, JString, required = false,
                                 default = nil)
  if valid_600360 != nil:
    section.add "X-Amz-Algorithm", valid_600360
  var valid_600361 = header.getOrDefault("X-Amz-Signature")
  valid_600361 = validateParameter(valid_600361, JString, required = false,
                                 default = nil)
  if valid_600361 != nil:
    section.add "X-Amz-Signature", valid_600361
  var valid_600362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600362 = validateParameter(valid_600362, JString, required = false,
                                 default = nil)
  if valid_600362 != nil:
    section.add "X-Amz-SignedHeaders", valid_600362
  var valid_600363 = header.getOrDefault("X-Amz-Credential")
  valid_600363 = validateParameter(valid_600363, JString, required = false,
                                 default = nil)
  if valid_600363 != nil:
    section.add "X-Amz-Credential", valid_600363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600365: Call_UpdateFleetMetadata_600354; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates fleet metadata, such as DisplayName.
  ## 
  let valid = call_600365.validator(path, query, header, formData, body)
  let scheme = call_600365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600365.url(scheme.get, call_600365.host, call_600365.base,
                         call_600365.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600365, url, valid)

proc call*(call_600366: Call_UpdateFleetMetadata_600354; body: JsonNode): Recallable =
  ## updateFleetMetadata
  ## Updates fleet metadata, such as DisplayName.
  ##   body: JObject (required)
  var body_600367 = newJObject()
  if body != nil:
    body_600367 = body
  result = call_600366.call(nil, nil, nil, nil, body_600367)

var updateFleetMetadata* = Call_UpdateFleetMetadata_600354(
    name: "updateFleetMetadata", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/UpdateFleetMetadata",
    validator: validate_UpdateFleetMetadata_600355, base: "/",
    url: url_UpdateFleetMetadata_600356, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIdentityProviderConfiguration_600368 = ref object of OpenApiRestCall_599368
proc url_UpdateIdentityProviderConfiguration_600370(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateIdentityProviderConfiguration_600369(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the identity provider configuration for the fleet.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600371 = header.getOrDefault("X-Amz-Date")
  valid_600371 = validateParameter(valid_600371, JString, required = false,
                                 default = nil)
  if valid_600371 != nil:
    section.add "X-Amz-Date", valid_600371
  var valid_600372 = header.getOrDefault("X-Amz-Security-Token")
  valid_600372 = validateParameter(valid_600372, JString, required = false,
                                 default = nil)
  if valid_600372 != nil:
    section.add "X-Amz-Security-Token", valid_600372
  var valid_600373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600373 = validateParameter(valid_600373, JString, required = false,
                                 default = nil)
  if valid_600373 != nil:
    section.add "X-Amz-Content-Sha256", valid_600373
  var valid_600374 = header.getOrDefault("X-Amz-Algorithm")
  valid_600374 = validateParameter(valid_600374, JString, required = false,
                                 default = nil)
  if valid_600374 != nil:
    section.add "X-Amz-Algorithm", valid_600374
  var valid_600375 = header.getOrDefault("X-Amz-Signature")
  valid_600375 = validateParameter(valid_600375, JString, required = false,
                                 default = nil)
  if valid_600375 != nil:
    section.add "X-Amz-Signature", valid_600375
  var valid_600376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600376 = validateParameter(valid_600376, JString, required = false,
                                 default = nil)
  if valid_600376 != nil:
    section.add "X-Amz-SignedHeaders", valid_600376
  var valid_600377 = header.getOrDefault("X-Amz-Credential")
  valid_600377 = validateParameter(valid_600377, JString, required = false,
                                 default = nil)
  if valid_600377 != nil:
    section.add "X-Amz-Credential", valid_600377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600379: Call_UpdateIdentityProviderConfiguration_600368;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the identity provider configuration for the fleet.
  ## 
  let valid = call_600379.validator(path, query, header, formData, body)
  let scheme = call_600379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600379.url(scheme.get, call_600379.host, call_600379.base,
                         call_600379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600379, url, valid)

proc call*(call_600380: Call_UpdateIdentityProviderConfiguration_600368;
          body: JsonNode): Recallable =
  ## updateIdentityProviderConfiguration
  ## Updates the identity provider configuration for the fleet.
  ##   body: JObject (required)
  var body_600381 = newJObject()
  if body != nil:
    body_600381 = body
  result = call_600380.call(nil, nil, nil, nil, body_600381)

var updateIdentityProviderConfiguration* = Call_UpdateIdentityProviderConfiguration_600368(
    name: "updateIdentityProviderConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/updateIdentityProviderConfiguration",
    validator: validate_UpdateIdentityProviderConfiguration_600369, base: "/",
    url: url_UpdateIdentityProviderConfiguration_600370,
    schemes: {Scheme.Https, Scheme.Http})
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
