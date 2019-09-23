
import
  json, options, hashes, uri, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_600437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600437): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateDomain_600774 = ref object of OpenApiRestCall_600437
proc url_AssociateDomain_600776(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateDomain_600775(path: JsonNode; query: JsonNode;
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
  var valid_600888 = header.getOrDefault("X-Amz-Date")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Date", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-Security-Token")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Security-Token", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Content-Sha256", valid_600890
  var valid_600891 = header.getOrDefault("X-Amz-Algorithm")
  valid_600891 = validateParameter(valid_600891, JString, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "X-Amz-Algorithm", valid_600891
  var valid_600892 = header.getOrDefault("X-Amz-Signature")
  valid_600892 = validateParameter(valid_600892, JString, required = false,
                                 default = nil)
  if valid_600892 != nil:
    section.add "X-Amz-Signature", valid_600892
  var valid_600893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600893 = validateParameter(valid_600893, JString, required = false,
                                 default = nil)
  if valid_600893 != nil:
    section.add "X-Amz-SignedHeaders", valid_600893
  var valid_600894 = header.getOrDefault("X-Amz-Credential")
  valid_600894 = validateParameter(valid_600894, JString, required = false,
                                 default = nil)
  if valid_600894 != nil:
    section.add "X-Amz-Credential", valid_600894
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600918: Call_AssociateDomain_600774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Specifies a domain to be associated to Amazon WorkLink.
  ## 
  let valid = call_600918.validator(path, query, header, formData, body)
  let scheme = call_600918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600918.url(scheme.get, call_600918.host, call_600918.base,
                         call_600918.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_600918, url, valid)

proc call*(call_600989: Call_AssociateDomain_600774; body: JsonNode): Recallable =
  ## associateDomain
  ## Specifies a domain to be associated to Amazon WorkLink.
  ##   body: JObject (required)
  var body_600990 = newJObject()
  if body != nil:
    body_600990 = body
  result = call_600989.call(nil, nil, nil, nil, body_600990)

var associateDomain* = Call_AssociateDomain_600774(name: "associateDomain",
    meth: HttpMethod.HttpPost, host: "worklink.amazonaws.com",
    route: "/associateDomain", validator: validate_AssociateDomain_600775,
    base: "/", url: url_AssociateDomain_600776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateWebsiteAuthorizationProvider_601029 = ref object of OpenApiRestCall_600437
proc url_AssociateWebsiteAuthorizationProvider_601031(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateWebsiteAuthorizationProvider_601030(path: JsonNode;
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
  var valid_601032 = header.getOrDefault("X-Amz-Date")
  valid_601032 = validateParameter(valid_601032, JString, required = false,
                                 default = nil)
  if valid_601032 != nil:
    section.add "X-Amz-Date", valid_601032
  var valid_601033 = header.getOrDefault("X-Amz-Security-Token")
  valid_601033 = validateParameter(valid_601033, JString, required = false,
                                 default = nil)
  if valid_601033 != nil:
    section.add "X-Amz-Security-Token", valid_601033
  var valid_601034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601034 = validateParameter(valid_601034, JString, required = false,
                                 default = nil)
  if valid_601034 != nil:
    section.add "X-Amz-Content-Sha256", valid_601034
  var valid_601035 = header.getOrDefault("X-Amz-Algorithm")
  valid_601035 = validateParameter(valid_601035, JString, required = false,
                                 default = nil)
  if valid_601035 != nil:
    section.add "X-Amz-Algorithm", valid_601035
  var valid_601036 = header.getOrDefault("X-Amz-Signature")
  valid_601036 = validateParameter(valid_601036, JString, required = false,
                                 default = nil)
  if valid_601036 != nil:
    section.add "X-Amz-Signature", valid_601036
  var valid_601037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601037 = validateParameter(valid_601037, JString, required = false,
                                 default = nil)
  if valid_601037 != nil:
    section.add "X-Amz-SignedHeaders", valid_601037
  var valid_601038 = header.getOrDefault("X-Amz-Credential")
  valid_601038 = validateParameter(valid_601038, JString, required = false,
                                 default = nil)
  if valid_601038 != nil:
    section.add "X-Amz-Credential", valid_601038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601040: Call_AssociateWebsiteAuthorizationProvider_601029;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a website authorization provider with a specified fleet. This is used to authorize users against associated websites in the company network.
  ## 
  let valid = call_601040.validator(path, query, header, formData, body)
  let scheme = call_601040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601040.url(scheme.get, call_601040.host, call_601040.base,
                         call_601040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601040, url, valid)

proc call*(call_601041: Call_AssociateWebsiteAuthorizationProvider_601029;
          body: JsonNode): Recallable =
  ## associateWebsiteAuthorizationProvider
  ## Associates a website authorization provider with a specified fleet. This is used to authorize users against associated websites in the company network.
  ##   body: JObject (required)
  var body_601042 = newJObject()
  if body != nil:
    body_601042 = body
  result = call_601041.call(nil, nil, nil, nil, body_601042)

var associateWebsiteAuthorizationProvider* = Call_AssociateWebsiteAuthorizationProvider_601029(
    name: "associateWebsiteAuthorizationProvider", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com",
    route: "/associateWebsiteAuthorizationProvider",
    validator: validate_AssociateWebsiteAuthorizationProvider_601030, base: "/",
    url: url_AssociateWebsiteAuthorizationProvider_601031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateWebsiteCertificateAuthority_601043 = ref object of OpenApiRestCall_600437
proc url_AssociateWebsiteCertificateAuthority_601045(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateWebsiteCertificateAuthority_601044(path: JsonNode;
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
  var valid_601046 = header.getOrDefault("X-Amz-Date")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Date", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Security-Token")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Security-Token", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Content-Sha256", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-Algorithm")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-Algorithm", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-Signature")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Signature", valid_601050
  var valid_601051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-SignedHeaders", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-Credential")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-Credential", valid_601052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601054: Call_AssociateWebsiteCertificateAuthority_601043;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Imports the root certificate of a certificate authority (CA) used to obtain TLS certificates used by associated websites within the company network.
  ## 
  let valid = call_601054.validator(path, query, header, formData, body)
  let scheme = call_601054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601054.url(scheme.get, call_601054.host, call_601054.base,
                         call_601054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601054, url, valid)

proc call*(call_601055: Call_AssociateWebsiteCertificateAuthority_601043;
          body: JsonNode): Recallable =
  ## associateWebsiteCertificateAuthority
  ## Imports the root certificate of a certificate authority (CA) used to obtain TLS certificates used by associated websites within the company network.
  ##   body: JObject (required)
  var body_601056 = newJObject()
  if body != nil:
    body_601056 = body
  result = call_601055.call(nil, nil, nil, nil, body_601056)

var associateWebsiteCertificateAuthority* = Call_AssociateWebsiteCertificateAuthority_601043(
    name: "associateWebsiteCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com",
    route: "/associateWebsiteCertificateAuthority",
    validator: validate_AssociateWebsiteCertificateAuthority_601044, base: "/",
    url: url_AssociateWebsiteCertificateAuthority_601045,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFleet_601057 = ref object of OpenApiRestCall_600437
proc url_CreateFleet_601059(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateFleet_601058(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601060 = header.getOrDefault("X-Amz-Date")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Date", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-Security-Token")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Security-Token", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Content-Sha256", valid_601062
  var valid_601063 = header.getOrDefault("X-Amz-Algorithm")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-Algorithm", valid_601063
  var valid_601064 = header.getOrDefault("X-Amz-Signature")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-Signature", valid_601064
  var valid_601065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-SignedHeaders", valid_601065
  var valid_601066 = header.getOrDefault("X-Amz-Credential")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-Credential", valid_601066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601068: Call_CreateFleet_601057; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a fleet. A fleet consists of resources and the configuration that delivers associated websites to authorized users who download and set up the Amazon WorkLink app.
  ## 
  let valid = call_601068.validator(path, query, header, formData, body)
  let scheme = call_601068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601068.url(scheme.get, call_601068.host, call_601068.base,
                         call_601068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601068, url, valid)

proc call*(call_601069: Call_CreateFleet_601057; body: JsonNode): Recallable =
  ## createFleet
  ## Creates a fleet. A fleet consists of resources and the configuration that delivers associated websites to authorized users who download and set up the Amazon WorkLink app.
  ##   body: JObject (required)
  var body_601070 = newJObject()
  if body != nil:
    body_601070 = body
  result = call_601069.call(nil, nil, nil, nil, body_601070)

var createFleet* = Call_CreateFleet_601057(name: "createFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "worklink.amazonaws.com",
                                        route: "/createFleet",
                                        validator: validate_CreateFleet_601058,
                                        base: "/", url: url_CreateFleet_601059,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFleet_601071 = ref object of OpenApiRestCall_600437
proc url_DeleteFleet_601073(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteFleet_601072(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601074 = header.getOrDefault("X-Amz-Date")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Date", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Security-Token")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Security-Token", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Content-Sha256", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Algorithm")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Algorithm", valid_601077
  var valid_601078 = header.getOrDefault("X-Amz-Signature")
  valid_601078 = validateParameter(valid_601078, JString, required = false,
                                 default = nil)
  if valid_601078 != nil:
    section.add "X-Amz-Signature", valid_601078
  var valid_601079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "X-Amz-SignedHeaders", valid_601079
  var valid_601080 = header.getOrDefault("X-Amz-Credential")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "X-Amz-Credential", valid_601080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601082: Call_DeleteFleet_601071; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a fleet. Prevents users from accessing previously associated websites. 
  ## 
  let valid = call_601082.validator(path, query, header, formData, body)
  let scheme = call_601082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601082.url(scheme.get, call_601082.host, call_601082.base,
                         call_601082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601082, url, valid)

proc call*(call_601083: Call_DeleteFleet_601071; body: JsonNode): Recallable =
  ## deleteFleet
  ## Deletes a fleet. Prevents users from accessing previously associated websites. 
  ##   body: JObject (required)
  var body_601084 = newJObject()
  if body != nil:
    body_601084 = body
  result = call_601083.call(nil, nil, nil, nil, body_601084)

var deleteFleet* = Call_DeleteFleet_601071(name: "deleteFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "worklink.amazonaws.com",
                                        route: "/deleteFleet",
                                        validator: validate_DeleteFleet_601072,
                                        base: "/", url: url_DeleteFleet_601073,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAuditStreamConfiguration_601085 = ref object of OpenApiRestCall_600437
proc url_DescribeAuditStreamConfiguration_601087(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAuditStreamConfiguration_601086(path: JsonNode;
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
  var valid_601088 = header.getOrDefault("X-Amz-Date")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Date", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Security-Token")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Security-Token", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Content-Sha256", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-Algorithm")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Algorithm", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Signature")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Signature", valid_601092
  var valid_601093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-SignedHeaders", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-Credential")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Credential", valid_601094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601096: Call_DescribeAuditStreamConfiguration_601085;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration for delivering audit streams to the customer account.
  ## 
  let valid = call_601096.validator(path, query, header, formData, body)
  let scheme = call_601096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601096.url(scheme.get, call_601096.host, call_601096.base,
                         call_601096.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601096, url, valid)

proc call*(call_601097: Call_DescribeAuditStreamConfiguration_601085;
          body: JsonNode): Recallable =
  ## describeAuditStreamConfiguration
  ## Describes the configuration for delivering audit streams to the customer account.
  ##   body: JObject (required)
  var body_601098 = newJObject()
  if body != nil:
    body_601098 = body
  result = call_601097.call(nil, nil, nil, nil, body_601098)

var describeAuditStreamConfiguration* = Call_DescribeAuditStreamConfiguration_601085(
    name: "describeAuditStreamConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/describeAuditStreamConfiguration",
    validator: validate_DescribeAuditStreamConfiguration_601086, base: "/",
    url: url_DescribeAuditStreamConfiguration_601087,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCompanyNetworkConfiguration_601099 = ref object of OpenApiRestCall_600437
proc url_DescribeCompanyNetworkConfiguration_601101(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeCompanyNetworkConfiguration_601100(path: JsonNode;
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
  var valid_601102 = header.getOrDefault("X-Amz-Date")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "X-Amz-Date", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Security-Token")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Security-Token", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Content-Sha256", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Algorithm")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Algorithm", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-Signature")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Signature", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-SignedHeaders", valid_601107
  var valid_601108 = header.getOrDefault("X-Amz-Credential")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-Credential", valid_601108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601110: Call_DescribeCompanyNetworkConfiguration_601099;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the networking configuration to access the internal websites associated with the specified fleet.
  ## 
  let valid = call_601110.validator(path, query, header, formData, body)
  let scheme = call_601110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601110.url(scheme.get, call_601110.host, call_601110.base,
                         call_601110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601110, url, valid)

proc call*(call_601111: Call_DescribeCompanyNetworkConfiguration_601099;
          body: JsonNode): Recallable =
  ## describeCompanyNetworkConfiguration
  ## Describes the networking configuration to access the internal websites associated with the specified fleet.
  ##   body: JObject (required)
  var body_601112 = newJObject()
  if body != nil:
    body_601112 = body
  result = call_601111.call(nil, nil, nil, nil, body_601112)

var describeCompanyNetworkConfiguration* = Call_DescribeCompanyNetworkConfiguration_601099(
    name: "describeCompanyNetworkConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/describeCompanyNetworkConfiguration",
    validator: validate_DescribeCompanyNetworkConfiguration_601100, base: "/",
    url: url_DescribeCompanyNetworkConfiguration_601101,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDevice_601113 = ref object of OpenApiRestCall_600437
proc url_DescribeDevice_601115(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDevice_601114(path: JsonNode; query: JsonNode;
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
  var valid_601116 = header.getOrDefault("X-Amz-Date")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Date", valid_601116
  var valid_601117 = header.getOrDefault("X-Amz-Security-Token")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "X-Amz-Security-Token", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Content-Sha256", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-Algorithm")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Algorithm", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Signature")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Signature", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-SignedHeaders", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Credential")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Credential", valid_601122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601124: Call_DescribeDevice_601113; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about a user's device.
  ## 
  let valid = call_601124.validator(path, query, header, formData, body)
  let scheme = call_601124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601124.url(scheme.get, call_601124.host, call_601124.base,
                         call_601124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601124, url, valid)

proc call*(call_601125: Call_DescribeDevice_601113; body: JsonNode): Recallable =
  ## describeDevice
  ## Provides information about a user's device.
  ##   body: JObject (required)
  var body_601126 = newJObject()
  if body != nil:
    body_601126 = body
  result = call_601125.call(nil, nil, nil, nil, body_601126)

var describeDevice* = Call_DescribeDevice_601113(name: "describeDevice",
    meth: HttpMethod.HttpPost, host: "worklink.amazonaws.com",
    route: "/describeDevice", validator: validate_DescribeDevice_601114, base: "/",
    url: url_DescribeDevice_601115, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDevicePolicyConfiguration_601127 = ref object of OpenApiRestCall_600437
proc url_DescribeDevicePolicyConfiguration_601129(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDevicePolicyConfiguration_601128(path: JsonNode;
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
  var valid_601130 = header.getOrDefault("X-Amz-Date")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Date", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Security-Token")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Security-Token", valid_601131
  var valid_601132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "X-Amz-Content-Sha256", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Algorithm")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Algorithm", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Signature")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Signature", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-SignedHeaders", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-Credential")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Credential", valid_601136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601138: Call_DescribeDevicePolicyConfiguration_601127;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the device policy configuration for the specified fleet.
  ## 
  let valid = call_601138.validator(path, query, header, formData, body)
  let scheme = call_601138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601138.url(scheme.get, call_601138.host, call_601138.base,
                         call_601138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601138, url, valid)

proc call*(call_601139: Call_DescribeDevicePolicyConfiguration_601127;
          body: JsonNode): Recallable =
  ## describeDevicePolicyConfiguration
  ## Describes the device policy configuration for the specified fleet.
  ##   body: JObject (required)
  var body_601140 = newJObject()
  if body != nil:
    body_601140 = body
  result = call_601139.call(nil, nil, nil, nil, body_601140)

var describeDevicePolicyConfiguration* = Call_DescribeDevicePolicyConfiguration_601127(
    name: "describeDevicePolicyConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/describeDevicePolicyConfiguration",
    validator: validate_DescribeDevicePolicyConfiguration_601128, base: "/",
    url: url_DescribeDevicePolicyConfiguration_601129,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDomain_601141 = ref object of OpenApiRestCall_600437
proc url_DescribeDomain_601143(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDomain_601142(path: JsonNode; query: JsonNode;
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
  var valid_601144 = header.getOrDefault("X-Amz-Date")
  valid_601144 = validateParameter(valid_601144, JString, required = false,
                                 default = nil)
  if valid_601144 != nil:
    section.add "X-Amz-Date", valid_601144
  var valid_601145 = header.getOrDefault("X-Amz-Security-Token")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-Security-Token", valid_601145
  var valid_601146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Content-Sha256", valid_601146
  var valid_601147 = header.getOrDefault("X-Amz-Algorithm")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-Algorithm", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Signature")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Signature", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-SignedHeaders", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Credential")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Credential", valid_601150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601152: Call_DescribeDomain_601141; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about the domain.
  ## 
  let valid = call_601152.validator(path, query, header, formData, body)
  let scheme = call_601152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601152.url(scheme.get, call_601152.host, call_601152.base,
                         call_601152.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601152, url, valid)

proc call*(call_601153: Call_DescribeDomain_601141; body: JsonNode): Recallable =
  ## describeDomain
  ## Provides information about the domain.
  ##   body: JObject (required)
  var body_601154 = newJObject()
  if body != nil:
    body_601154 = body
  result = call_601153.call(nil, nil, nil, nil, body_601154)

var describeDomain* = Call_DescribeDomain_601141(name: "describeDomain",
    meth: HttpMethod.HttpPost, host: "worklink.amazonaws.com",
    route: "/describeDomain", validator: validate_DescribeDomain_601142, base: "/",
    url: url_DescribeDomain_601143, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFleetMetadata_601155 = ref object of OpenApiRestCall_600437
proc url_DescribeFleetMetadata_601157(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeFleetMetadata_601156(path: JsonNode; query: JsonNode;
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
  var valid_601158 = header.getOrDefault("X-Amz-Date")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "X-Amz-Date", valid_601158
  var valid_601159 = header.getOrDefault("X-Amz-Security-Token")
  valid_601159 = validateParameter(valid_601159, JString, required = false,
                                 default = nil)
  if valid_601159 != nil:
    section.add "X-Amz-Security-Token", valid_601159
  var valid_601160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "X-Amz-Content-Sha256", valid_601160
  var valid_601161 = header.getOrDefault("X-Amz-Algorithm")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-Algorithm", valid_601161
  var valid_601162 = header.getOrDefault("X-Amz-Signature")
  valid_601162 = validateParameter(valid_601162, JString, required = false,
                                 default = nil)
  if valid_601162 != nil:
    section.add "X-Amz-Signature", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-SignedHeaders", valid_601163
  var valid_601164 = header.getOrDefault("X-Amz-Credential")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Credential", valid_601164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601166: Call_DescribeFleetMetadata_601155; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides basic information for the specified fleet, excluding identity provider, networking, and device configuration details.
  ## 
  let valid = call_601166.validator(path, query, header, formData, body)
  let scheme = call_601166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601166.url(scheme.get, call_601166.host, call_601166.base,
                         call_601166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601166, url, valid)

proc call*(call_601167: Call_DescribeFleetMetadata_601155; body: JsonNode): Recallable =
  ## describeFleetMetadata
  ## Provides basic information for the specified fleet, excluding identity provider, networking, and device configuration details.
  ##   body: JObject (required)
  var body_601168 = newJObject()
  if body != nil:
    body_601168 = body
  result = call_601167.call(nil, nil, nil, nil, body_601168)

var describeFleetMetadata* = Call_DescribeFleetMetadata_601155(
    name: "describeFleetMetadata", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/describeFleetMetadata",
    validator: validate_DescribeFleetMetadata_601156, base: "/",
    url: url_DescribeFleetMetadata_601157, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentityProviderConfiguration_601169 = ref object of OpenApiRestCall_600437
proc url_DescribeIdentityProviderConfiguration_601171(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeIdentityProviderConfiguration_601170(path: JsonNode;
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
  var valid_601172 = header.getOrDefault("X-Amz-Date")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-Date", valid_601172
  var valid_601173 = header.getOrDefault("X-Amz-Security-Token")
  valid_601173 = validateParameter(valid_601173, JString, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "X-Amz-Security-Token", valid_601173
  var valid_601174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601174 = validateParameter(valid_601174, JString, required = false,
                                 default = nil)
  if valid_601174 != nil:
    section.add "X-Amz-Content-Sha256", valid_601174
  var valid_601175 = header.getOrDefault("X-Amz-Algorithm")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "X-Amz-Algorithm", valid_601175
  var valid_601176 = header.getOrDefault("X-Amz-Signature")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "X-Amz-Signature", valid_601176
  var valid_601177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601177 = validateParameter(valid_601177, JString, required = false,
                                 default = nil)
  if valid_601177 != nil:
    section.add "X-Amz-SignedHeaders", valid_601177
  var valid_601178 = header.getOrDefault("X-Amz-Credential")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "X-Amz-Credential", valid_601178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601180: Call_DescribeIdentityProviderConfiguration_601169;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the identity provider configuration of the specified fleet.
  ## 
  let valid = call_601180.validator(path, query, header, formData, body)
  let scheme = call_601180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601180.url(scheme.get, call_601180.host, call_601180.base,
                         call_601180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601180, url, valid)

proc call*(call_601181: Call_DescribeIdentityProviderConfiguration_601169;
          body: JsonNode): Recallable =
  ## describeIdentityProviderConfiguration
  ## Describes the identity provider configuration of the specified fleet.
  ##   body: JObject (required)
  var body_601182 = newJObject()
  if body != nil:
    body_601182 = body
  result = call_601181.call(nil, nil, nil, nil, body_601182)

var describeIdentityProviderConfiguration* = Call_DescribeIdentityProviderConfiguration_601169(
    name: "describeIdentityProviderConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com",
    route: "/describeIdentityProviderConfiguration",
    validator: validate_DescribeIdentityProviderConfiguration_601170, base: "/",
    url: url_DescribeIdentityProviderConfiguration_601171,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWebsiteCertificateAuthority_601183 = ref object of OpenApiRestCall_600437
proc url_DescribeWebsiteCertificateAuthority_601185(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeWebsiteCertificateAuthority_601184(path: JsonNode;
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
  var valid_601186 = header.getOrDefault("X-Amz-Date")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Date", valid_601186
  var valid_601187 = header.getOrDefault("X-Amz-Security-Token")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-Security-Token", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-Content-Sha256", valid_601188
  var valid_601189 = header.getOrDefault("X-Amz-Algorithm")
  valid_601189 = validateParameter(valid_601189, JString, required = false,
                                 default = nil)
  if valid_601189 != nil:
    section.add "X-Amz-Algorithm", valid_601189
  var valid_601190 = header.getOrDefault("X-Amz-Signature")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "X-Amz-Signature", valid_601190
  var valid_601191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "X-Amz-SignedHeaders", valid_601191
  var valid_601192 = header.getOrDefault("X-Amz-Credential")
  valid_601192 = validateParameter(valid_601192, JString, required = false,
                                 default = nil)
  if valid_601192 != nil:
    section.add "X-Amz-Credential", valid_601192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601194: Call_DescribeWebsiteCertificateAuthority_601183;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Provides information about the certificate authority.
  ## 
  let valid = call_601194.validator(path, query, header, formData, body)
  let scheme = call_601194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601194.url(scheme.get, call_601194.host, call_601194.base,
                         call_601194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601194, url, valid)

proc call*(call_601195: Call_DescribeWebsiteCertificateAuthority_601183;
          body: JsonNode): Recallable =
  ## describeWebsiteCertificateAuthority
  ## Provides information about the certificate authority.
  ##   body: JObject (required)
  var body_601196 = newJObject()
  if body != nil:
    body_601196 = body
  result = call_601195.call(nil, nil, nil, nil, body_601196)

var describeWebsiteCertificateAuthority* = Call_DescribeWebsiteCertificateAuthority_601183(
    name: "describeWebsiteCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/describeWebsiteCertificateAuthority",
    validator: validate_DescribeWebsiteCertificateAuthority_601184, base: "/",
    url: url_DescribeWebsiteCertificateAuthority_601185,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateDomain_601197 = ref object of OpenApiRestCall_600437
proc url_DisassociateDomain_601199(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateDomain_601198(path: JsonNode; query: JsonNode;
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
  var valid_601200 = header.getOrDefault("X-Amz-Date")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Date", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Security-Token")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Security-Token", valid_601201
  var valid_601202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-Content-Sha256", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-Algorithm")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Algorithm", valid_601203
  var valid_601204 = header.getOrDefault("X-Amz-Signature")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "X-Amz-Signature", valid_601204
  var valid_601205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "X-Amz-SignedHeaders", valid_601205
  var valid_601206 = header.getOrDefault("X-Amz-Credential")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Credential", valid_601206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601208: Call_DisassociateDomain_601197; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a domain from Amazon WorkLink. End users lose the ability to access the domain with Amazon WorkLink. 
  ## 
  let valid = call_601208.validator(path, query, header, formData, body)
  let scheme = call_601208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601208.url(scheme.get, call_601208.host, call_601208.base,
                         call_601208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601208, url, valid)

proc call*(call_601209: Call_DisassociateDomain_601197; body: JsonNode): Recallable =
  ## disassociateDomain
  ## Disassociates a domain from Amazon WorkLink. End users lose the ability to access the domain with Amazon WorkLink. 
  ##   body: JObject (required)
  var body_601210 = newJObject()
  if body != nil:
    body_601210 = body
  result = call_601209.call(nil, nil, nil, nil, body_601210)

var disassociateDomain* = Call_DisassociateDomain_601197(
    name: "disassociateDomain", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/disassociateDomain",
    validator: validate_DisassociateDomain_601198, base: "/",
    url: url_DisassociateDomain_601199, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateWebsiteAuthorizationProvider_601211 = ref object of OpenApiRestCall_600437
proc url_DisassociateWebsiteAuthorizationProvider_601213(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateWebsiteAuthorizationProvider_601212(path: JsonNode;
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
  var valid_601214 = header.getOrDefault("X-Amz-Date")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "X-Amz-Date", valid_601214
  var valid_601215 = header.getOrDefault("X-Amz-Security-Token")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-Security-Token", valid_601215
  var valid_601216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Content-Sha256", valid_601216
  var valid_601217 = header.getOrDefault("X-Amz-Algorithm")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-Algorithm", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-Signature")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-Signature", valid_601218
  var valid_601219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "X-Amz-SignedHeaders", valid_601219
  var valid_601220 = header.getOrDefault("X-Amz-Credential")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Credential", valid_601220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601222: Call_DisassociateWebsiteAuthorizationProvider_601211;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a website authorization provider from a specified fleet. After the disassociation, users can't load any associated websites that require this authorization provider.
  ## 
  let valid = call_601222.validator(path, query, header, formData, body)
  let scheme = call_601222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601222.url(scheme.get, call_601222.host, call_601222.base,
                         call_601222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601222, url, valid)

proc call*(call_601223: Call_DisassociateWebsiteAuthorizationProvider_601211;
          body: JsonNode): Recallable =
  ## disassociateWebsiteAuthorizationProvider
  ## Disassociates a website authorization provider from a specified fleet. After the disassociation, users can't load any associated websites that require this authorization provider.
  ##   body: JObject (required)
  var body_601224 = newJObject()
  if body != nil:
    body_601224 = body
  result = call_601223.call(nil, nil, nil, nil, body_601224)

var disassociateWebsiteAuthorizationProvider* = Call_DisassociateWebsiteAuthorizationProvider_601211(
    name: "disassociateWebsiteAuthorizationProvider", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com",
    route: "/disassociateWebsiteAuthorizationProvider",
    validator: validate_DisassociateWebsiteAuthorizationProvider_601212,
    base: "/", url: url_DisassociateWebsiteAuthorizationProvider_601213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateWebsiteCertificateAuthority_601225 = ref object of OpenApiRestCall_600437
proc url_DisassociateWebsiteCertificateAuthority_601227(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateWebsiteCertificateAuthority_601226(path: JsonNode;
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
  var valid_601228 = header.getOrDefault("X-Amz-Date")
  valid_601228 = validateParameter(valid_601228, JString, required = false,
                                 default = nil)
  if valid_601228 != nil:
    section.add "X-Amz-Date", valid_601228
  var valid_601229 = header.getOrDefault("X-Amz-Security-Token")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "X-Amz-Security-Token", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-Content-Sha256", valid_601230
  var valid_601231 = header.getOrDefault("X-Amz-Algorithm")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Algorithm", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-Signature")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-Signature", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-SignedHeaders", valid_601233
  var valid_601234 = header.getOrDefault("X-Amz-Credential")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "X-Amz-Credential", valid_601234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601236: Call_DisassociateWebsiteCertificateAuthority_601225;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a certificate authority (CA).
  ## 
  let valid = call_601236.validator(path, query, header, formData, body)
  let scheme = call_601236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601236.url(scheme.get, call_601236.host, call_601236.base,
                         call_601236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601236, url, valid)

proc call*(call_601237: Call_DisassociateWebsiteCertificateAuthority_601225;
          body: JsonNode): Recallable =
  ## disassociateWebsiteCertificateAuthority
  ## Removes a certificate authority (CA).
  ##   body: JObject (required)
  var body_601238 = newJObject()
  if body != nil:
    body_601238 = body
  result = call_601237.call(nil, nil, nil, nil, body_601238)

var disassociateWebsiteCertificateAuthority* = Call_DisassociateWebsiteCertificateAuthority_601225(
    name: "disassociateWebsiteCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com",
    route: "/disassociateWebsiteCertificateAuthority",
    validator: validate_DisassociateWebsiteCertificateAuthority_601226, base: "/",
    url: url_DisassociateWebsiteCertificateAuthority_601227,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevices_601239 = ref object of OpenApiRestCall_600437
proc url_ListDevices_601241(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDevices_601240(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601242 = query.getOrDefault("NextToken")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "NextToken", valid_601242
  var valid_601243 = query.getOrDefault("MaxResults")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "MaxResults", valid_601243
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
  var valid_601244 = header.getOrDefault("X-Amz-Date")
  valid_601244 = validateParameter(valid_601244, JString, required = false,
                                 default = nil)
  if valid_601244 != nil:
    section.add "X-Amz-Date", valid_601244
  var valid_601245 = header.getOrDefault("X-Amz-Security-Token")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-Security-Token", valid_601245
  var valid_601246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-Content-Sha256", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-Algorithm")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-Algorithm", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-Signature")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-Signature", valid_601248
  var valid_601249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-SignedHeaders", valid_601249
  var valid_601250 = header.getOrDefault("X-Amz-Credential")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-Credential", valid_601250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601252: Call_ListDevices_601239; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of devices registered with the specified fleet.
  ## 
  let valid = call_601252.validator(path, query, header, formData, body)
  let scheme = call_601252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601252.url(scheme.get, call_601252.host, call_601252.base,
                         call_601252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601252, url, valid)

proc call*(call_601253: Call_ListDevices_601239; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDevices
  ## Retrieves a list of devices registered with the specified fleet.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601254 = newJObject()
  var body_601255 = newJObject()
  add(query_601254, "NextToken", newJString(NextToken))
  if body != nil:
    body_601255 = body
  add(query_601254, "MaxResults", newJString(MaxResults))
  result = call_601253.call(nil, query_601254, nil, nil, body_601255)

var listDevices* = Call_ListDevices_601239(name: "listDevices",
                                        meth: HttpMethod.HttpPost,
                                        host: "worklink.amazonaws.com",
                                        route: "/listDevices",
                                        validator: validate_ListDevices_601240,
                                        base: "/", url: url_ListDevices_601241,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomains_601257 = ref object of OpenApiRestCall_600437
proc url_ListDomains_601259(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDomains_601258(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601260 = query.getOrDefault("NextToken")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "NextToken", valid_601260
  var valid_601261 = query.getOrDefault("MaxResults")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "MaxResults", valid_601261
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
  var valid_601262 = header.getOrDefault("X-Amz-Date")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-Date", valid_601262
  var valid_601263 = header.getOrDefault("X-Amz-Security-Token")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-Security-Token", valid_601263
  var valid_601264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-Content-Sha256", valid_601264
  var valid_601265 = header.getOrDefault("X-Amz-Algorithm")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Algorithm", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-Signature")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-Signature", valid_601266
  var valid_601267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "X-Amz-SignedHeaders", valid_601267
  var valid_601268 = header.getOrDefault("X-Amz-Credential")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-Credential", valid_601268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601270: Call_ListDomains_601257; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of domains associated to a specified fleet.
  ## 
  let valid = call_601270.validator(path, query, header, formData, body)
  let scheme = call_601270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601270.url(scheme.get, call_601270.host, call_601270.base,
                         call_601270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601270, url, valid)

proc call*(call_601271: Call_ListDomains_601257; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDomains
  ## Retrieves a list of domains associated to a specified fleet.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601272 = newJObject()
  var body_601273 = newJObject()
  add(query_601272, "NextToken", newJString(NextToken))
  if body != nil:
    body_601273 = body
  add(query_601272, "MaxResults", newJString(MaxResults))
  result = call_601271.call(nil, query_601272, nil, nil, body_601273)

var listDomains* = Call_ListDomains_601257(name: "listDomains",
                                        meth: HttpMethod.HttpPost,
                                        host: "worklink.amazonaws.com",
                                        route: "/listDomains",
                                        validator: validate_ListDomains_601258,
                                        base: "/", url: url_ListDomains_601259,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFleets_601274 = ref object of OpenApiRestCall_600437
proc url_ListFleets_601276(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListFleets_601275(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601277 = query.getOrDefault("NextToken")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "NextToken", valid_601277
  var valid_601278 = query.getOrDefault("MaxResults")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "MaxResults", valid_601278
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
  var valid_601279 = header.getOrDefault("X-Amz-Date")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "X-Amz-Date", valid_601279
  var valid_601280 = header.getOrDefault("X-Amz-Security-Token")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "X-Amz-Security-Token", valid_601280
  var valid_601281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-Content-Sha256", valid_601281
  var valid_601282 = header.getOrDefault("X-Amz-Algorithm")
  valid_601282 = validateParameter(valid_601282, JString, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "X-Amz-Algorithm", valid_601282
  var valid_601283 = header.getOrDefault("X-Amz-Signature")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "X-Amz-Signature", valid_601283
  var valid_601284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "X-Amz-SignedHeaders", valid_601284
  var valid_601285 = header.getOrDefault("X-Amz-Credential")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "X-Amz-Credential", valid_601285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601287: Call_ListFleets_601274; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of fleets for the current account and Region.
  ## 
  let valid = call_601287.validator(path, query, header, formData, body)
  let scheme = call_601287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601287.url(scheme.get, call_601287.host, call_601287.base,
                         call_601287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601287, url, valid)

proc call*(call_601288: Call_ListFleets_601274; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listFleets
  ## Retrieves a list of fleets for the current account and Region.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601289 = newJObject()
  var body_601290 = newJObject()
  add(query_601289, "NextToken", newJString(NextToken))
  if body != nil:
    body_601290 = body
  add(query_601289, "MaxResults", newJString(MaxResults))
  result = call_601288.call(nil, query_601289, nil, nil, body_601290)

var listFleets* = Call_ListFleets_601274(name: "listFleets",
                                      meth: HttpMethod.HttpPost,
                                      host: "worklink.amazonaws.com",
                                      route: "/listFleets",
                                      validator: validate_ListFleets_601275,
                                      base: "/", url: url_ListFleets_601276,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWebsiteAuthorizationProviders_601291 = ref object of OpenApiRestCall_600437
proc url_ListWebsiteAuthorizationProviders_601293(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListWebsiteAuthorizationProviders_601292(path: JsonNode;
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
  var valid_601294 = query.getOrDefault("NextToken")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "NextToken", valid_601294
  var valid_601295 = query.getOrDefault("MaxResults")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "MaxResults", valid_601295
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
  var valid_601296 = header.getOrDefault("X-Amz-Date")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-Date", valid_601296
  var valid_601297 = header.getOrDefault("X-Amz-Security-Token")
  valid_601297 = validateParameter(valid_601297, JString, required = false,
                                 default = nil)
  if valid_601297 != nil:
    section.add "X-Amz-Security-Token", valid_601297
  var valid_601298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "X-Amz-Content-Sha256", valid_601298
  var valid_601299 = header.getOrDefault("X-Amz-Algorithm")
  valid_601299 = validateParameter(valid_601299, JString, required = false,
                                 default = nil)
  if valid_601299 != nil:
    section.add "X-Amz-Algorithm", valid_601299
  var valid_601300 = header.getOrDefault("X-Amz-Signature")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "X-Amz-Signature", valid_601300
  var valid_601301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "X-Amz-SignedHeaders", valid_601301
  var valid_601302 = header.getOrDefault("X-Amz-Credential")
  valid_601302 = validateParameter(valid_601302, JString, required = false,
                                 default = nil)
  if valid_601302 != nil:
    section.add "X-Amz-Credential", valid_601302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601304: Call_ListWebsiteAuthorizationProviders_601291;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves a list of website authorization providers associated with a specified fleet.
  ## 
  let valid = call_601304.validator(path, query, header, formData, body)
  let scheme = call_601304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601304.url(scheme.get, call_601304.host, call_601304.base,
                         call_601304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601304, url, valid)

proc call*(call_601305: Call_ListWebsiteAuthorizationProviders_601291;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listWebsiteAuthorizationProviders
  ## Retrieves a list of website authorization providers associated with a specified fleet.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601306 = newJObject()
  var body_601307 = newJObject()
  add(query_601306, "NextToken", newJString(NextToken))
  if body != nil:
    body_601307 = body
  add(query_601306, "MaxResults", newJString(MaxResults))
  result = call_601305.call(nil, query_601306, nil, nil, body_601307)

var listWebsiteAuthorizationProviders* = Call_ListWebsiteAuthorizationProviders_601291(
    name: "listWebsiteAuthorizationProviders", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/listWebsiteAuthorizationProviders",
    validator: validate_ListWebsiteAuthorizationProviders_601292, base: "/",
    url: url_ListWebsiteAuthorizationProviders_601293,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWebsiteCertificateAuthorities_601308 = ref object of OpenApiRestCall_600437
proc url_ListWebsiteCertificateAuthorities_601310(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListWebsiteCertificateAuthorities_601309(path: JsonNode;
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
  var valid_601311 = query.getOrDefault("NextToken")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "NextToken", valid_601311
  var valid_601312 = query.getOrDefault("MaxResults")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "MaxResults", valid_601312
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
  var valid_601313 = header.getOrDefault("X-Amz-Date")
  valid_601313 = validateParameter(valid_601313, JString, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "X-Amz-Date", valid_601313
  var valid_601314 = header.getOrDefault("X-Amz-Security-Token")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "X-Amz-Security-Token", valid_601314
  var valid_601315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "X-Amz-Content-Sha256", valid_601315
  var valid_601316 = header.getOrDefault("X-Amz-Algorithm")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "X-Amz-Algorithm", valid_601316
  var valid_601317 = header.getOrDefault("X-Amz-Signature")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "X-Amz-Signature", valid_601317
  var valid_601318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601318 = validateParameter(valid_601318, JString, required = false,
                                 default = nil)
  if valid_601318 != nil:
    section.add "X-Amz-SignedHeaders", valid_601318
  var valid_601319 = header.getOrDefault("X-Amz-Credential")
  valid_601319 = validateParameter(valid_601319, JString, required = false,
                                 default = nil)
  if valid_601319 != nil:
    section.add "X-Amz-Credential", valid_601319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601321: Call_ListWebsiteCertificateAuthorities_601308;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves a list of certificate authorities added for the current account and Region.
  ## 
  let valid = call_601321.validator(path, query, header, formData, body)
  let scheme = call_601321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601321.url(scheme.get, call_601321.host, call_601321.base,
                         call_601321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601321, url, valid)

proc call*(call_601322: Call_ListWebsiteCertificateAuthorities_601308;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listWebsiteCertificateAuthorities
  ## Retrieves a list of certificate authorities added for the current account and Region.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601323 = newJObject()
  var body_601324 = newJObject()
  add(query_601323, "NextToken", newJString(NextToken))
  if body != nil:
    body_601324 = body
  add(query_601323, "MaxResults", newJString(MaxResults))
  result = call_601322.call(nil, query_601323, nil, nil, body_601324)

var listWebsiteCertificateAuthorities* = Call_ListWebsiteCertificateAuthorities_601308(
    name: "listWebsiteCertificateAuthorities", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/listWebsiteCertificateAuthorities",
    validator: validate_ListWebsiteCertificateAuthorities_601309, base: "/",
    url: url_ListWebsiteCertificateAuthorities_601310,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreDomainAccess_601325 = ref object of OpenApiRestCall_600437
proc url_RestoreDomainAccess_601327(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RestoreDomainAccess_601326(path: JsonNode; query: JsonNode;
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
  var valid_601328 = header.getOrDefault("X-Amz-Date")
  valid_601328 = validateParameter(valid_601328, JString, required = false,
                                 default = nil)
  if valid_601328 != nil:
    section.add "X-Amz-Date", valid_601328
  var valid_601329 = header.getOrDefault("X-Amz-Security-Token")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "X-Amz-Security-Token", valid_601329
  var valid_601330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "X-Amz-Content-Sha256", valid_601330
  var valid_601331 = header.getOrDefault("X-Amz-Algorithm")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-Algorithm", valid_601331
  var valid_601332 = header.getOrDefault("X-Amz-Signature")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "X-Amz-Signature", valid_601332
  var valid_601333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601333 = validateParameter(valid_601333, JString, required = false,
                                 default = nil)
  if valid_601333 != nil:
    section.add "X-Amz-SignedHeaders", valid_601333
  var valid_601334 = header.getOrDefault("X-Amz-Credential")
  valid_601334 = validateParameter(valid_601334, JString, required = false,
                                 default = nil)
  if valid_601334 != nil:
    section.add "X-Amz-Credential", valid_601334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601336: Call_RestoreDomainAccess_601325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Moves a domain to ACTIVE status if it was in the INACTIVE status.
  ## 
  let valid = call_601336.validator(path, query, header, formData, body)
  let scheme = call_601336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601336.url(scheme.get, call_601336.host, call_601336.base,
                         call_601336.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601336, url, valid)

proc call*(call_601337: Call_RestoreDomainAccess_601325; body: JsonNode): Recallable =
  ## restoreDomainAccess
  ## Moves a domain to ACTIVE status if it was in the INACTIVE status.
  ##   body: JObject (required)
  var body_601338 = newJObject()
  if body != nil:
    body_601338 = body
  result = call_601337.call(nil, nil, nil, nil, body_601338)

var restoreDomainAccess* = Call_RestoreDomainAccess_601325(
    name: "restoreDomainAccess", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/restoreDomainAccess",
    validator: validate_RestoreDomainAccess_601326, base: "/",
    url: url_RestoreDomainAccess_601327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeDomainAccess_601339 = ref object of OpenApiRestCall_600437
proc url_RevokeDomainAccess_601341(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RevokeDomainAccess_601340(path: JsonNode; query: JsonNode;
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
  var valid_601342 = header.getOrDefault("X-Amz-Date")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "X-Amz-Date", valid_601342
  var valid_601343 = header.getOrDefault("X-Amz-Security-Token")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-Security-Token", valid_601343
  var valid_601344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-Content-Sha256", valid_601344
  var valid_601345 = header.getOrDefault("X-Amz-Algorithm")
  valid_601345 = validateParameter(valid_601345, JString, required = false,
                                 default = nil)
  if valid_601345 != nil:
    section.add "X-Amz-Algorithm", valid_601345
  var valid_601346 = header.getOrDefault("X-Amz-Signature")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-Signature", valid_601346
  var valid_601347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-SignedHeaders", valid_601347
  var valid_601348 = header.getOrDefault("X-Amz-Credential")
  valid_601348 = validateParameter(valid_601348, JString, required = false,
                                 default = nil)
  if valid_601348 != nil:
    section.add "X-Amz-Credential", valid_601348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601350: Call_RevokeDomainAccess_601339; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Moves a domain to INACTIVE status if it was in the ACTIVE status.
  ## 
  let valid = call_601350.validator(path, query, header, formData, body)
  let scheme = call_601350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601350.url(scheme.get, call_601350.host, call_601350.base,
                         call_601350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601350, url, valid)

proc call*(call_601351: Call_RevokeDomainAccess_601339; body: JsonNode): Recallable =
  ## revokeDomainAccess
  ## Moves a domain to INACTIVE status if it was in the ACTIVE status.
  ##   body: JObject (required)
  var body_601352 = newJObject()
  if body != nil:
    body_601352 = body
  result = call_601351.call(nil, nil, nil, nil, body_601352)

var revokeDomainAccess* = Call_RevokeDomainAccess_601339(
    name: "revokeDomainAccess", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/revokeDomainAccess",
    validator: validate_RevokeDomainAccess_601340, base: "/",
    url: url_RevokeDomainAccess_601341, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SignOutUser_601353 = ref object of OpenApiRestCall_600437
proc url_SignOutUser_601355(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SignOutUser_601354(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601356 = header.getOrDefault("X-Amz-Date")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "X-Amz-Date", valid_601356
  var valid_601357 = header.getOrDefault("X-Amz-Security-Token")
  valid_601357 = validateParameter(valid_601357, JString, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "X-Amz-Security-Token", valid_601357
  var valid_601358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-Content-Sha256", valid_601358
  var valid_601359 = header.getOrDefault("X-Amz-Algorithm")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "X-Amz-Algorithm", valid_601359
  var valid_601360 = header.getOrDefault("X-Amz-Signature")
  valid_601360 = validateParameter(valid_601360, JString, required = false,
                                 default = nil)
  if valid_601360 != nil:
    section.add "X-Amz-Signature", valid_601360
  var valid_601361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "X-Amz-SignedHeaders", valid_601361
  var valid_601362 = header.getOrDefault("X-Amz-Credential")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-Credential", valid_601362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601364: Call_SignOutUser_601353; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Signs the user out from all of their devices. The user can sign in again if they have valid credentials.
  ## 
  let valid = call_601364.validator(path, query, header, formData, body)
  let scheme = call_601364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601364.url(scheme.get, call_601364.host, call_601364.base,
                         call_601364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601364, url, valid)

proc call*(call_601365: Call_SignOutUser_601353; body: JsonNode): Recallable =
  ## signOutUser
  ## Signs the user out from all of their devices. The user can sign in again if they have valid credentials.
  ##   body: JObject (required)
  var body_601366 = newJObject()
  if body != nil:
    body_601366 = body
  result = call_601365.call(nil, nil, nil, nil, body_601366)

var signOutUser* = Call_SignOutUser_601353(name: "signOutUser",
                                        meth: HttpMethod.HttpPost,
                                        host: "worklink.amazonaws.com",
                                        route: "/signOutUser",
                                        validator: validate_SignOutUser_601354,
                                        base: "/", url: url_SignOutUser_601355,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuditStreamConfiguration_601367 = ref object of OpenApiRestCall_600437
proc url_UpdateAuditStreamConfiguration_601369(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateAuditStreamConfiguration_601368(path: JsonNode;
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
  var valid_601370 = header.getOrDefault("X-Amz-Date")
  valid_601370 = validateParameter(valid_601370, JString, required = false,
                                 default = nil)
  if valid_601370 != nil:
    section.add "X-Amz-Date", valid_601370
  var valid_601371 = header.getOrDefault("X-Amz-Security-Token")
  valid_601371 = validateParameter(valid_601371, JString, required = false,
                                 default = nil)
  if valid_601371 != nil:
    section.add "X-Amz-Security-Token", valid_601371
  var valid_601372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601372 = validateParameter(valid_601372, JString, required = false,
                                 default = nil)
  if valid_601372 != nil:
    section.add "X-Amz-Content-Sha256", valid_601372
  var valid_601373 = header.getOrDefault("X-Amz-Algorithm")
  valid_601373 = validateParameter(valid_601373, JString, required = false,
                                 default = nil)
  if valid_601373 != nil:
    section.add "X-Amz-Algorithm", valid_601373
  var valid_601374 = header.getOrDefault("X-Amz-Signature")
  valid_601374 = validateParameter(valid_601374, JString, required = false,
                                 default = nil)
  if valid_601374 != nil:
    section.add "X-Amz-Signature", valid_601374
  var valid_601375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601375 = validateParameter(valid_601375, JString, required = false,
                                 default = nil)
  if valid_601375 != nil:
    section.add "X-Amz-SignedHeaders", valid_601375
  var valid_601376 = header.getOrDefault("X-Amz-Credential")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "X-Amz-Credential", valid_601376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601378: Call_UpdateAuditStreamConfiguration_601367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the audit stream configuration for the fleet.
  ## 
  let valid = call_601378.validator(path, query, header, formData, body)
  let scheme = call_601378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601378.url(scheme.get, call_601378.host, call_601378.base,
                         call_601378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601378, url, valid)

proc call*(call_601379: Call_UpdateAuditStreamConfiguration_601367; body: JsonNode): Recallable =
  ## updateAuditStreamConfiguration
  ## Updates the audit stream configuration for the fleet.
  ##   body: JObject (required)
  var body_601380 = newJObject()
  if body != nil:
    body_601380 = body
  result = call_601379.call(nil, nil, nil, nil, body_601380)

var updateAuditStreamConfiguration* = Call_UpdateAuditStreamConfiguration_601367(
    name: "updateAuditStreamConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/updateAuditStreamConfiguration",
    validator: validate_UpdateAuditStreamConfiguration_601368, base: "/",
    url: url_UpdateAuditStreamConfiguration_601369,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCompanyNetworkConfiguration_601381 = ref object of OpenApiRestCall_600437
proc url_UpdateCompanyNetworkConfiguration_601383(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateCompanyNetworkConfiguration_601382(path: JsonNode;
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
  var valid_601384 = header.getOrDefault("X-Amz-Date")
  valid_601384 = validateParameter(valid_601384, JString, required = false,
                                 default = nil)
  if valid_601384 != nil:
    section.add "X-Amz-Date", valid_601384
  var valid_601385 = header.getOrDefault("X-Amz-Security-Token")
  valid_601385 = validateParameter(valid_601385, JString, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "X-Amz-Security-Token", valid_601385
  var valid_601386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601386 = validateParameter(valid_601386, JString, required = false,
                                 default = nil)
  if valid_601386 != nil:
    section.add "X-Amz-Content-Sha256", valid_601386
  var valid_601387 = header.getOrDefault("X-Amz-Algorithm")
  valid_601387 = validateParameter(valid_601387, JString, required = false,
                                 default = nil)
  if valid_601387 != nil:
    section.add "X-Amz-Algorithm", valid_601387
  var valid_601388 = header.getOrDefault("X-Amz-Signature")
  valid_601388 = validateParameter(valid_601388, JString, required = false,
                                 default = nil)
  if valid_601388 != nil:
    section.add "X-Amz-Signature", valid_601388
  var valid_601389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601389 = validateParameter(valid_601389, JString, required = false,
                                 default = nil)
  if valid_601389 != nil:
    section.add "X-Amz-SignedHeaders", valid_601389
  var valid_601390 = header.getOrDefault("X-Amz-Credential")
  valid_601390 = validateParameter(valid_601390, JString, required = false,
                                 default = nil)
  if valid_601390 != nil:
    section.add "X-Amz-Credential", valid_601390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601392: Call_UpdateCompanyNetworkConfiguration_601381;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the company network configuration for the fleet.
  ## 
  let valid = call_601392.validator(path, query, header, formData, body)
  let scheme = call_601392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601392.url(scheme.get, call_601392.host, call_601392.base,
                         call_601392.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601392, url, valid)

proc call*(call_601393: Call_UpdateCompanyNetworkConfiguration_601381;
          body: JsonNode): Recallable =
  ## updateCompanyNetworkConfiguration
  ## Updates the company network configuration for the fleet.
  ##   body: JObject (required)
  var body_601394 = newJObject()
  if body != nil:
    body_601394 = body
  result = call_601393.call(nil, nil, nil, nil, body_601394)

var updateCompanyNetworkConfiguration* = Call_UpdateCompanyNetworkConfiguration_601381(
    name: "updateCompanyNetworkConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/updateCompanyNetworkConfiguration",
    validator: validate_UpdateCompanyNetworkConfiguration_601382, base: "/",
    url: url_UpdateCompanyNetworkConfiguration_601383,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevicePolicyConfiguration_601395 = ref object of OpenApiRestCall_600437
proc url_UpdateDevicePolicyConfiguration_601397(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDevicePolicyConfiguration_601396(path: JsonNode;
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
  var valid_601398 = header.getOrDefault("X-Amz-Date")
  valid_601398 = validateParameter(valid_601398, JString, required = false,
                                 default = nil)
  if valid_601398 != nil:
    section.add "X-Amz-Date", valid_601398
  var valid_601399 = header.getOrDefault("X-Amz-Security-Token")
  valid_601399 = validateParameter(valid_601399, JString, required = false,
                                 default = nil)
  if valid_601399 != nil:
    section.add "X-Amz-Security-Token", valid_601399
  var valid_601400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601400 = validateParameter(valid_601400, JString, required = false,
                                 default = nil)
  if valid_601400 != nil:
    section.add "X-Amz-Content-Sha256", valid_601400
  var valid_601401 = header.getOrDefault("X-Amz-Algorithm")
  valid_601401 = validateParameter(valid_601401, JString, required = false,
                                 default = nil)
  if valid_601401 != nil:
    section.add "X-Amz-Algorithm", valid_601401
  var valid_601402 = header.getOrDefault("X-Amz-Signature")
  valid_601402 = validateParameter(valid_601402, JString, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "X-Amz-Signature", valid_601402
  var valid_601403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601403 = validateParameter(valid_601403, JString, required = false,
                                 default = nil)
  if valid_601403 != nil:
    section.add "X-Amz-SignedHeaders", valid_601403
  var valid_601404 = header.getOrDefault("X-Amz-Credential")
  valid_601404 = validateParameter(valid_601404, JString, required = false,
                                 default = nil)
  if valid_601404 != nil:
    section.add "X-Amz-Credential", valid_601404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601406: Call_UpdateDevicePolicyConfiguration_601395;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the device policy configuration for the fleet.
  ## 
  let valid = call_601406.validator(path, query, header, formData, body)
  let scheme = call_601406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601406.url(scheme.get, call_601406.host, call_601406.base,
                         call_601406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601406, url, valid)

proc call*(call_601407: Call_UpdateDevicePolicyConfiguration_601395; body: JsonNode): Recallable =
  ## updateDevicePolicyConfiguration
  ## Updates the device policy configuration for the fleet.
  ##   body: JObject (required)
  var body_601408 = newJObject()
  if body != nil:
    body_601408 = body
  result = call_601407.call(nil, nil, nil, nil, body_601408)

var updateDevicePolicyConfiguration* = Call_UpdateDevicePolicyConfiguration_601395(
    name: "updateDevicePolicyConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/updateDevicePolicyConfiguration",
    validator: validate_UpdateDevicePolicyConfiguration_601396, base: "/",
    url: url_UpdateDevicePolicyConfiguration_601397,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainMetadata_601409 = ref object of OpenApiRestCall_600437
proc url_UpdateDomainMetadata_601411(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDomainMetadata_601410(path: JsonNode; query: JsonNode;
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
  var valid_601412 = header.getOrDefault("X-Amz-Date")
  valid_601412 = validateParameter(valid_601412, JString, required = false,
                                 default = nil)
  if valid_601412 != nil:
    section.add "X-Amz-Date", valid_601412
  var valid_601413 = header.getOrDefault("X-Amz-Security-Token")
  valid_601413 = validateParameter(valid_601413, JString, required = false,
                                 default = nil)
  if valid_601413 != nil:
    section.add "X-Amz-Security-Token", valid_601413
  var valid_601414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601414 = validateParameter(valid_601414, JString, required = false,
                                 default = nil)
  if valid_601414 != nil:
    section.add "X-Amz-Content-Sha256", valid_601414
  var valid_601415 = header.getOrDefault("X-Amz-Algorithm")
  valid_601415 = validateParameter(valid_601415, JString, required = false,
                                 default = nil)
  if valid_601415 != nil:
    section.add "X-Amz-Algorithm", valid_601415
  var valid_601416 = header.getOrDefault("X-Amz-Signature")
  valid_601416 = validateParameter(valid_601416, JString, required = false,
                                 default = nil)
  if valid_601416 != nil:
    section.add "X-Amz-Signature", valid_601416
  var valid_601417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "X-Amz-SignedHeaders", valid_601417
  var valid_601418 = header.getOrDefault("X-Amz-Credential")
  valid_601418 = validateParameter(valid_601418, JString, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "X-Amz-Credential", valid_601418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601420: Call_UpdateDomainMetadata_601409; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates domain metadata, such as DisplayName.
  ## 
  let valid = call_601420.validator(path, query, header, formData, body)
  let scheme = call_601420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601420.url(scheme.get, call_601420.host, call_601420.base,
                         call_601420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601420, url, valid)

proc call*(call_601421: Call_UpdateDomainMetadata_601409; body: JsonNode): Recallable =
  ## updateDomainMetadata
  ## Updates domain metadata, such as DisplayName.
  ##   body: JObject (required)
  var body_601422 = newJObject()
  if body != nil:
    body_601422 = body
  result = call_601421.call(nil, nil, nil, nil, body_601422)

var updateDomainMetadata* = Call_UpdateDomainMetadata_601409(
    name: "updateDomainMetadata", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/updateDomainMetadata",
    validator: validate_UpdateDomainMetadata_601410, base: "/",
    url: url_UpdateDomainMetadata_601411, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFleetMetadata_601423 = ref object of OpenApiRestCall_600437
proc url_UpdateFleetMetadata_601425(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateFleetMetadata_601424(path: JsonNode; query: JsonNode;
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
  var valid_601426 = header.getOrDefault("X-Amz-Date")
  valid_601426 = validateParameter(valid_601426, JString, required = false,
                                 default = nil)
  if valid_601426 != nil:
    section.add "X-Amz-Date", valid_601426
  var valid_601427 = header.getOrDefault("X-Amz-Security-Token")
  valid_601427 = validateParameter(valid_601427, JString, required = false,
                                 default = nil)
  if valid_601427 != nil:
    section.add "X-Amz-Security-Token", valid_601427
  var valid_601428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601428 = validateParameter(valid_601428, JString, required = false,
                                 default = nil)
  if valid_601428 != nil:
    section.add "X-Amz-Content-Sha256", valid_601428
  var valid_601429 = header.getOrDefault("X-Amz-Algorithm")
  valid_601429 = validateParameter(valid_601429, JString, required = false,
                                 default = nil)
  if valid_601429 != nil:
    section.add "X-Amz-Algorithm", valid_601429
  var valid_601430 = header.getOrDefault("X-Amz-Signature")
  valid_601430 = validateParameter(valid_601430, JString, required = false,
                                 default = nil)
  if valid_601430 != nil:
    section.add "X-Amz-Signature", valid_601430
  var valid_601431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601431 = validateParameter(valid_601431, JString, required = false,
                                 default = nil)
  if valid_601431 != nil:
    section.add "X-Amz-SignedHeaders", valid_601431
  var valid_601432 = header.getOrDefault("X-Amz-Credential")
  valid_601432 = validateParameter(valid_601432, JString, required = false,
                                 default = nil)
  if valid_601432 != nil:
    section.add "X-Amz-Credential", valid_601432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601434: Call_UpdateFleetMetadata_601423; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates fleet metadata, such as DisplayName.
  ## 
  let valid = call_601434.validator(path, query, header, formData, body)
  let scheme = call_601434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601434.url(scheme.get, call_601434.host, call_601434.base,
                         call_601434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601434, url, valid)

proc call*(call_601435: Call_UpdateFleetMetadata_601423; body: JsonNode): Recallable =
  ## updateFleetMetadata
  ## Updates fleet metadata, such as DisplayName.
  ##   body: JObject (required)
  var body_601436 = newJObject()
  if body != nil:
    body_601436 = body
  result = call_601435.call(nil, nil, nil, nil, body_601436)

var updateFleetMetadata* = Call_UpdateFleetMetadata_601423(
    name: "updateFleetMetadata", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/UpdateFleetMetadata",
    validator: validate_UpdateFleetMetadata_601424, base: "/",
    url: url_UpdateFleetMetadata_601425, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIdentityProviderConfiguration_601437 = ref object of OpenApiRestCall_600437
proc url_UpdateIdentityProviderConfiguration_601439(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateIdentityProviderConfiguration_601438(path: JsonNode;
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
  var valid_601440 = header.getOrDefault("X-Amz-Date")
  valid_601440 = validateParameter(valid_601440, JString, required = false,
                                 default = nil)
  if valid_601440 != nil:
    section.add "X-Amz-Date", valid_601440
  var valid_601441 = header.getOrDefault("X-Amz-Security-Token")
  valid_601441 = validateParameter(valid_601441, JString, required = false,
                                 default = nil)
  if valid_601441 != nil:
    section.add "X-Amz-Security-Token", valid_601441
  var valid_601442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601442 = validateParameter(valid_601442, JString, required = false,
                                 default = nil)
  if valid_601442 != nil:
    section.add "X-Amz-Content-Sha256", valid_601442
  var valid_601443 = header.getOrDefault("X-Amz-Algorithm")
  valid_601443 = validateParameter(valid_601443, JString, required = false,
                                 default = nil)
  if valid_601443 != nil:
    section.add "X-Amz-Algorithm", valid_601443
  var valid_601444 = header.getOrDefault("X-Amz-Signature")
  valid_601444 = validateParameter(valid_601444, JString, required = false,
                                 default = nil)
  if valid_601444 != nil:
    section.add "X-Amz-Signature", valid_601444
  var valid_601445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601445 = validateParameter(valid_601445, JString, required = false,
                                 default = nil)
  if valid_601445 != nil:
    section.add "X-Amz-SignedHeaders", valid_601445
  var valid_601446 = header.getOrDefault("X-Amz-Credential")
  valid_601446 = validateParameter(valid_601446, JString, required = false,
                                 default = nil)
  if valid_601446 != nil:
    section.add "X-Amz-Credential", valid_601446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601448: Call_UpdateIdentityProviderConfiguration_601437;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the identity provider configuration for the fleet.
  ## 
  let valid = call_601448.validator(path, query, header, formData, body)
  let scheme = call_601448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601448.url(scheme.get, call_601448.host, call_601448.base,
                         call_601448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601448, url, valid)

proc call*(call_601449: Call_UpdateIdentityProviderConfiguration_601437;
          body: JsonNode): Recallable =
  ## updateIdentityProviderConfiguration
  ## Updates the identity provider configuration for the fleet.
  ##   body: JObject (required)
  var body_601450 = newJObject()
  if body != nil:
    body_601450 = body
  result = call_601449.call(nil, nil, nil, nil, body_601450)

var updateIdentityProviderConfiguration* = Call_UpdateIdentityProviderConfiguration_601437(
    name: "updateIdentityProviderConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/updateIdentityProviderConfiguration",
    validator: validate_UpdateIdentityProviderConfiguration_601438, base: "/",
    url: url_UpdateIdentityProviderConfiguration_601439,
    schemes: {Scheme.Https, Scheme.Http})
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
