
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateDomain_592703 = ref object of OpenApiRestCall_592364
proc url_AssociateDomain_592705(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateDomain_592704(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592817 = header.getOrDefault("X-Amz-Signature")
  valid_592817 = validateParameter(valid_592817, JString, required = false,
                                 default = nil)
  if valid_592817 != nil:
    section.add "X-Amz-Signature", valid_592817
  var valid_592818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592818 = validateParameter(valid_592818, JString, required = false,
                                 default = nil)
  if valid_592818 != nil:
    section.add "X-Amz-Content-Sha256", valid_592818
  var valid_592819 = header.getOrDefault("X-Amz-Date")
  valid_592819 = validateParameter(valid_592819, JString, required = false,
                                 default = nil)
  if valid_592819 != nil:
    section.add "X-Amz-Date", valid_592819
  var valid_592820 = header.getOrDefault("X-Amz-Credential")
  valid_592820 = validateParameter(valid_592820, JString, required = false,
                                 default = nil)
  if valid_592820 != nil:
    section.add "X-Amz-Credential", valid_592820
  var valid_592821 = header.getOrDefault("X-Amz-Security-Token")
  valid_592821 = validateParameter(valid_592821, JString, required = false,
                                 default = nil)
  if valid_592821 != nil:
    section.add "X-Amz-Security-Token", valid_592821
  var valid_592822 = header.getOrDefault("X-Amz-Algorithm")
  valid_592822 = validateParameter(valid_592822, JString, required = false,
                                 default = nil)
  if valid_592822 != nil:
    section.add "X-Amz-Algorithm", valid_592822
  var valid_592823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592823 = validateParameter(valid_592823, JString, required = false,
                                 default = nil)
  if valid_592823 != nil:
    section.add "X-Amz-SignedHeaders", valid_592823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592847: Call_AssociateDomain_592703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Specifies a domain to be associated to Amazon WorkLink.
  ## 
  let valid = call_592847.validator(path, query, header, formData, body)
  let scheme = call_592847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592847.url(scheme.get, call_592847.host, call_592847.base,
                         call_592847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592847, url, valid)

proc call*(call_592918: Call_AssociateDomain_592703; body: JsonNode): Recallable =
  ## associateDomain
  ## Specifies a domain to be associated to Amazon WorkLink.
  ##   body: JObject (required)
  var body_592919 = newJObject()
  if body != nil:
    body_592919 = body
  result = call_592918.call(nil, nil, nil, nil, body_592919)

var associateDomain* = Call_AssociateDomain_592703(name: "associateDomain",
    meth: HttpMethod.HttpPost, host: "worklink.amazonaws.com",
    route: "/associateDomain", validator: validate_AssociateDomain_592704,
    base: "/", url: url_AssociateDomain_592705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateWebsiteAuthorizationProvider_592958 = ref object of OpenApiRestCall_592364
proc url_AssociateWebsiteAuthorizationProvider_592960(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateWebsiteAuthorizationProvider_592959(path: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592961 = header.getOrDefault("X-Amz-Signature")
  valid_592961 = validateParameter(valid_592961, JString, required = false,
                                 default = nil)
  if valid_592961 != nil:
    section.add "X-Amz-Signature", valid_592961
  var valid_592962 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592962 = validateParameter(valid_592962, JString, required = false,
                                 default = nil)
  if valid_592962 != nil:
    section.add "X-Amz-Content-Sha256", valid_592962
  var valid_592963 = header.getOrDefault("X-Amz-Date")
  valid_592963 = validateParameter(valid_592963, JString, required = false,
                                 default = nil)
  if valid_592963 != nil:
    section.add "X-Amz-Date", valid_592963
  var valid_592964 = header.getOrDefault("X-Amz-Credential")
  valid_592964 = validateParameter(valid_592964, JString, required = false,
                                 default = nil)
  if valid_592964 != nil:
    section.add "X-Amz-Credential", valid_592964
  var valid_592965 = header.getOrDefault("X-Amz-Security-Token")
  valid_592965 = validateParameter(valid_592965, JString, required = false,
                                 default = nil)
  if valid_592965 != nil:
    section.add "X-Amz-Security-Token", valid_592965
  var valid_592966 = header.getOrDefault("X-Amz-Algorithm")
  valid_592966 = validateParameter(valid_592966, JString, required = false,
                                 default = nil)
  if valid_592966 != nil:
    section.add "X-Amz-Algorithm", valid_592966
  var valid_592967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592967 = validateParameter(valid_592967, JString, required = false,
                                 default = nil)
  if valid_592967 != nil:
    section.add "X-Amz-SignedHeaders", valid_592967
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592969: Call_AssociateWebsiteAuthorizationProvider_592958;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a website authorization provider with a specified fleet. This is used to authorize users against associated websites in the company network.
  ## 
  let valid = call_592969.validator(path, query, header, formData, body)
  let scheme = call_592969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592969.url(scheme.get, call_592969.host, call_592969.base,
                         call_592969.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592969, url, valid)

proc call*(call_592970: Call_AssociateWebsiteAuthorizationProvider_592958;
          body: JsonNode): Recallable =
  ## associateWebsiteAuthorizationProvider
  ## Associates a website authorization provider with a specified fleet. This is used to authorize users against associated websites in the company network.
  ##   body: JObject (required)
  var body_592971 = newJObject()
  if body != nil:
    body_592971 = body
  result = call_592970.call(nil, nil, nil, nil, body_592971)

var associateWebsiteAuthorizationProvider* = Call_AssociateWebsiteAuthorizationProvider_592958(
    name: "associateWebsiteAuthorizationProvider", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com",
    route: "/associateWebsiteAuthorizationProvider",
    validator: validate_AssociateWebsiteAuthorizationProvider_592959, base: "/",
    url: url_AssociateWebsiteAuthorizationProvider_592960,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateWebsiteCertificateAuthority_592972 = ref object of OpenApiRestCall_592364
proc url_AssociateWebsiteCertificateAuthority_592974(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateWebsiteCertificateAuthority_592973(path: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592975 = header.getOrDefault("X-Amz-Signature")
  valid_592975 = validateParameter(valid_592975, JString, required = false,
                                 default = nil)
  if valid_592975 != nil:
    section.add "X-Amz-Signature", valid_592975
  var valid_592976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592976 = validateParameter(valid_592976, JString, required = false,
                                 default = nil)
  if valid_592976 != nil:
    section.add "X-Amz-Content-Sha256", valid_592976
  var valid_592977 = header.getOrDefault("X-Amz-Date")
  valid_592977 = validateParameter(valid_592977, JString, required = false,
                                 default = nil)
  if valid_592977 != nil:
    section.add "X-Amz-Date", valid_592977
  var valid_592978 = header.getOrDefault("X-Amz-Credential")
  valid_592978 = validateParameter(valid_592978, JString, required = false,
                                 default = nil)
  if valid_592978 != nil:
    section.add "X-Amz-Credential", valid_592978
  var valid_592979 = header.getOrDefault("X-Amz-Security-Token")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Security-Token", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Algorithm")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Algorithm", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-SignedHeaders", valid_592981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592983: Call_AssociateWebsiteCertificateAuthority_592972;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Imports the root certificate of a certificate authority (CA) used to obtain TLS certificates used by associated websites within the company network.
  ## 
  let valid = call_592983.validator(path, query, header, formData, body)
  let scheme = call_592983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592983.url(scheme.get, call_592983.host, call_592983.base,
                         call_592983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592983, url, valid)

proc call*(call_592984: Call_AssociateWebsiteCertificateAuthority_592972;
          body: JsonNode): Recallable =
  ## associateWebsiteCertificateAuthority
  ## Imports the root certificate of a certificate authority (CA) used to obtain TLS certificates used by associated websites within the company network.
  ##   body: JObject (required)
  var body_592985 = newJObject()
  if body != nil:
    body_592985 = body
  result = call_592984.call(nil, nil, nil, nil, body_592985)

var associateWebsiteCertificateAuthority* = Call_AssociateWebsiteCertificateAuthority_592972(
    name: "associateWebsiteCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com",
    route: "/associateWebsiteCertificateAuthority",
    validator: validate_AssociateWebsiteCertificateAuthority_592973, base: "/",
    url: url_AssociateWebsiteCertificateAuthority_592974,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFleet_592986 = ref object of OpenApiRestCall_592364
proc url_CreateFleet_592988(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateFleet_592987(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592989 = header.getOrDefault("X-Amz-Signature")
  valid_592989 = validateParameter(valid_592989, JString, required = false,
                                 default = nil)
  if valid_592989 != nil:
    section.add "X-Amz-Signature", valid_592989
  var valid_592990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592990 = validateParameter(valid_592990, JString, required = false,
                                 default = nil)
  if valid_592990 != nil:
    section.add "X-Amz-Content-Sha256", valid_592990
  var valid_592991 = header.getOrDefault("X-Amz-Date")
  valid_592991 = validateParameter(valid_592991, JString, required = false,
                                 default = nil)
  if valid_592991 != nil:
    section.add "X-Amz-Date", valid_592991
  var valid_592992 = header.getOrDefault("X-Amz-Credential")
  valid_592992 = validateParameter(valid_592992, JString, required = false,
                                 default = nil)
  if valid_592992 != nil:
    section.add "X-Amz-Credential", valid_592992
  var valid_592993 = header.getOrDefault("X-Amz-Security-Token")
  valid_592993 = validateParameter(valid_592993, JString, required = false,
                                 default = nil)
  if valid_592993 != nil:
    section.add "X-Amz-Security-Token", valid_592993
  var valid_592994 = header.getOrDefault("X-Amz-Algorithm")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "X-Amz-Algorithm", valid_592994
  var valid_592995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-SignedHeaders", valid_592995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592997: Call_CreateFleet_592986; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a fleet. A fleet consists of resources and the configuration that delivers associated websites to authorized users who download and set up the Amazon WorkLink app.
  ## 
  let valid = call_592997.validator(path, query, header, formData, body)
  let scheme = call_592997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592997.url(scheme.get, call_592997.host, call_592997.base,
                         call_592997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592997, url, valid)

proc call*(call_592998: Call_CreateFleet_592986; body: JsonNode): Recallable =
  ## createFleet
  ## Creates a fleet. A fleet consists of resources and the configuration that delivers associated websites to authorized users who download and set up the Amazon WorkLink app.
  ##   body: JObject (required)
  var body_592999 = newJObject()
  if body != nil:
    body_592999 = body
  result = call_592998.call(nil, nil, nil, nil, body_592999)

var createFleet* = Call_CreateFleet_592986(name: "createFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "worklink.amazonaws.com",
                                        route: "/createFleet",
                                        validator: validate_CreateFleet_592987,
                                        base: "/", url: url_CreateFleet_592988,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFleet_593000 = ref object of OpenApiRestCall_592364
proc url_DeleteFleet_593002(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteFleet_593001(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593003 = header.getOrDefault("X-Amz-Signature")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "X-Amz-Signature", valid_593003
  var valid_593004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "X-Amz-Content-Sha256", valid_593004
  var valid_593005 = header.getOrDefault("X-Amz-Date")
  valid_593005 = validateParameter(valid_593005, JString, required = false,
                                 default = nil)
  if valid_593005 != nil:
    section.add "X-Amz-Date", valid_593005
  var valid_593006 = header.getOrDefault("X-Amz-Credential")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-Credential", valid_593006
  var valid_593007 = header.getOrDefault("X-Amz-Security-Token")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-Security-Token", valid_593007
  var valid_593008 = header.getOrDefault("X-Amz-Algorithm")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-Algorithm", valid_593008
  var valid_593009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-SignedHeaders", valid_593009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593011: Call_DeleteFleet_593000; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a fleet. Prevents users from accessing previously associated websites. 
  ## 
  let valid = call_593011.validator(path, query, header, formData, body)
  let scheme = call_593011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593011.url(scheme.get, call_593011.host, call_593011.base,
                         call_593011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593011, url, valid)

proc call*(call_593012: Call_DeleteFleet_593000; body: JsonNode): Recallable =
  ## deleteFleet
  ## Deletes a fleet. Prevents users from accessing previously associated websites. 
  ##   body: JObject (required)
  var body_593013 = newJObject()
  if body != nil:
    body_593013 = body
  result = call_593012.call(nil, nil, nil, nil, body_593013)

var deleteFleet* = Call_DeleteFleet_593000(name: "deleteFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "worklink.amazonaws.com",
                                        route: "/deleteFleet",
                                        validator: validate_DeleteFleet_593001,
                                        base: "/", url: url_DeleteFleet_593002,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAuditStreamConfiguration_593014 = ref object of OpenApiRestCall_592364
proc url_DescribeAuditStreamConfiguration_593016(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAuditStreamConfiguration_593015(path: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593017 = header.getOrDefault("X-Amz-Signature")
  valid_593017 = validateParameter(valid_593017, JString, required = false,
                                 default = nil)
  if valid_593017 != nil:
    section.add "X-Amz-Signature", valid_593017
  var valid_593018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593018 = validateParameter(valid_593018, JString, required = false,
                                 default = nil)
  if valid_593018 != nil:
    section.add "X-Amz-Content-Sha256", valid_593018
  var valid_593019 = header.getOrDefault("X-Amz-Date")
  valid_593019 = validateParameter(valid_593019, JString, required = false,
                                 default = nil)
  if valid_593019 != nil:
    section.add "X-Amz-Date", valid_593019
  var valid_593020 = header.getOrDefault("X-Amz-Credential")
  valid_593020 = validateParameter(valid_593020, JString, required = false,
                                 default = nil)
  if valid_593020 != nil:
    section.add "X-Amz-Credential", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-Security-Token")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-Security-Token", valid_593021
  var valid_593022 = header.getOrDefault("X-Amz-Algorithm")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Algorithm", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-SignedHeaders", valid_593023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593025: Call_DescribeAuditStreamConfiguration_593014;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration for delivering audit streams to the customer account.
  ## 
  let valid = call_593025.validator(path, query, header, formData, body)
  let scheme = call_593025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593025.url(scheme.get, call_593025.host, call_593025.base,
                         call_593025.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593025, url, valid)

proc call*(call_593026: Call_DescribeAuditStreamConfiguration_593014;
          body: JsonNode): Recallable =
  ## describeAuditStreamConfiguration
  ## Describes the configuration for delivering audit streams to the customer account.
  ##   body: JObject (required)
  var body_593027 = newJObject()
  if body != nil:
    body_593027 = body
  result = call_593026.call(nil, nil, nil, nil, body_593027)

var describeAuditStreamConfiguration* = Call_DescribeAuditStreamConfiguration_593014(
    name: "describeAuditStreamConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/describeAuditStreamConfiguration",
    validator: validate_DescribeAuditStreamConfiguration_593015, base: "/",
    url: url_DescribeAuditStreamConfiguration_593016,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCompanyNetworkConfiguration_593028 = ref object of OpenApiRestCall_592364
proc url_DescribeCompanyNetworkConfiguration_593030(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeCompanyNetworkConfiguration_593029(path: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593031 = header.getOrDefault("X-Amz-Signature")
  valid_593031 = validateParameter(valid_593031, JString, required = false,
                                 default = nil)
  if valid_593031 != nil:
    section.add "X-Amz-Signature", valid_593031
  var valid_593032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593032 = validateParameter(valid_593032, JString, required = false,
                                 default = nil)
  if valid_593032 != nil:
    section.add "X-Amz-Content-Sha256", valid_593032
  var valid_593033 = header.getOrDefault("X-Amz-Date")
  valid_593033 = validateParameter(valid_593033, JString, required = false,
                                 default = nil)
  if valid_593033 != nil:
    section.add "X-Amz-Date", valid_593033
  var valid_593034 = header.getOrDefault("X-Amz-Credential")
  valid_593034 = validateParameter(valid_593034, JString, required = false,
                                 default = nil)
  if valid_593034 != nil:
    section.add "X-Amz-Credential", valid_593034
  var valid_593035 = header.getOrDefault("X-Amz-Security-Token")
  valid_593035 = validateParameter(valid_593035, JString, required = false,
                                 default = nil)
  if valid_593035 != nil:
    section.add "X-Amz-Security-Token", valid_593035
  var valid_593036 = header.getOrDefault("X-Amz-Algorithm")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "X-Amz-Algorithm", valid_593036
  var valid_593037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-SignedHeaders", valid_593037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593039: Call_DescribeCompanyNetworkConfiguration_593028;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the networking configuration to access the internal websites associated with the specified fleet.
  ## 
  let valid = call_593039.validator(path, query, header, formData, body)
  let scheme = call_593039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593039.url(scheme.get, call_593039.host, call_593039.base,
                         call_593039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593039, url, valid)

proc call*(call_593040: Call_DescribeCompanyNetworkConfiguration_593028;
          body: JsonNode): Recallable =
  ## describeCompanyNetworkConfiguration
  ## Describes the networking configuration to access the internal websites associated with the specified fleet.
  ##   body: JObject (required)
  var body_593041 = newJObject()
  if body != nil:
    body_593041 = body
  result = call_593040.call(nil, nil, nil, nil, body_593041)

var describeCompanyNetworkConfiguration* = Call_DescribeCompanyNetworkConfiguration_593028(
    name: "describeCompanyNetworkConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/describeCompanyNetworkConfiguration",
    validator: validate_DescribeCompanyNetworkConfiguration_593029, base: "/",
    url: url_DescribeCompanyNetworkConfiguration_593030,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDevice_593042 = ref object of OpenApiRestCall_592364
proc url_DescribeDevice_593044(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDevice_593043(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593045 = header.getOrDefault("X-Amz-Signature")
  valid_593045 = validateParameter(valid_593045, JString, required = false,
                                 default = nil)
  if valid_593045 != nil:
    section.add "X-Amz-Signature", valid_593045
  var valid_593046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593046 = validateParameter(valid_593046, JString, required = false,
                                 default = nil)
  if valid_593046 != nil:
    section.add "X-Amz-Content-Sha256", valid_593046
  var valid_593047 = header.getOrDefault("X-Amz-Date")
  valid_593047 = validateParameter(valid_593047, JString, required = false,
                                 default = nil)
  if valid_593047 != nil:
    section.add "X-Amz-Date", valid_593047
  var valid_593048 = header.getOrDefault("X-Amz-Credential")
  valid_593048 = validateParameter(valid_593048, JString, required = false,
                                 default = nil)
  if valid_593048 != nil:
    section.add "X-Amz-Credential", valid_593048
  var valid_593049 = header.getOrDefault("X-Amz-Security-Token")
  valid_593049 = validateParameter(valid_593049, JString, required = false,
                                 default = nil)
  if valid_593049 != nil:
    section.add "X-Amz-Security-Token", valid_593049
  var valid_593050 = header.getOrDefault("X-Amz-Algorithm")
  valid_593050 = validateParameter(valid_593050, JString, required = false,
                                 default = nil)
  if valid_593050 != nil:
    section.add "X-Amz-Algorithm", valid_593050
  var valid_593051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "X-Amz-SignedHeaders", valid_593051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593053: Call_DescribeDevice_593042; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about a user's device.
  ## 
  let valid = call_593053.validator(path, query, header, formData, body)
  let scheme = call_593053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593053.url(scheme.get, call_593053.host, call_593053.base,
                         call_593053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593053, url, valid)

proc call*(call_593054: Call_DescribeDevice_593042; body: JsonNode): Recallable =
  ## describeDevice
  ## Provides information about a user's device.
  ##   body: JObject (required)
  var body_593055 = newJObject()
  if body != nil:
    body_593055 = body
  result = call_593054.call(nil, nil, nil, nil, body_593055)

var describeDevice* = Call_DescribeDevice_593042(name: "describeDevice",
    meth: HttpMethod.HttpPost, host: "worklink.amazonaws.com",
    route: "/describeDevice", validator: validate_DescribeDevice_593043, base: "/",
    url: url_DescribeDevice_593044, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDevicePolicyConfiguration_593056 = ref object of OpenApiRestCall_592364
proc url_DescribeDevicePolicyConfiguration_593058(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDevicePolicyConfiguration_593057(path: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593059 = header.getOrDefault("X-Amz-Signature")
  valid_593059 = validateParameter(valid_593059, JString, required = false,
                                 default = nil)
  if valid_593059 != nil:
    section.add "X-Amz-Signature", valid_593059
  var valid_593060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = nil)
  if valid_593060 != nil:
    section.add "X-Amz-Content-Sha256", valid_593060
  var valid_593061 = header.getOrDefault("X-Amz-Date")
  valid_593061 = validateParameter(valid_593061, JString, required = false,
                                 default = nil)
  if valid_593061 != nil:
    section.add "X-Amz-Date", valid_593061
  var valid_593062 = header.getOrDefault("X-Amz-Credential")
  valid_593062 = validateParameter(valid_593062, JString, required = false,
                                 default = nil)
  if valid_593062 != nil:
    section.add "X-Amz-Credential", valid_593062
  var valid_593063 = header.getOrDefault("X-Amz-Security-Token")
  valid_593063 = validateParameter(valid_593063, JString, required = false,
                                 default = nil)
  if valid_593063 != nil:
    section.add "X-Amz-Security-Token", valid_593063
  var valid_593064 = header.getOrDefault("X-Amz-Algorithm")
  valid_593064 = validateParameter(valid_593064, JString, required = false,
                                 default = nil)
  if valid_593064 != nil:
    section.add "X-Amz-Algorithm", valid_593064
  var valid_593065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "X-Amz-SignedHeaders", valid_593065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593067: Call_DescribeDevicePolicyConfiguration_593056;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the device policy configuration for the specified fleet.
  ## 
  let valid = call_593067.validator(path, query, header, formData, body)
  let scheme = call_593067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593067.url(scheme.get, call_593067.host, call_593067.base,
                         call_593067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593067, url, valid)

proc call*(call_593068: Call_DescribeDevicePolicyConfiguration_593056;
          body: JsonNode): Recallable =
  ## describeDevicePolicyConfiguration
  ## Describes the device policy configuration for the specified fleet.
  ##   body: JObject (required)
  var body_593069 = newJObject()
  if body != nil:
    body_593069 = body
  result = call_593068.call(nil, nil, nil, nil, body_593069)

var describeDevicePolicyConfiguration* = Call_DescribeDevicePolicyConfiguration_593056(
    name: "describeDevicePolicyConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/describeDevicePolicyConfiguration",
    validator: validate_DescribeDevicePolicyConfiguration_593057, base: "/",
    url: url_DescribeDevicePolicyConfiguration_593058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDomain_593070 = ref object of OpenApiRestCall_592364
proc url_DescribeDomain_593072(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDomain_593071(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593073 = header.getOrDefault("X-Amz-Signature")
  valid_593073 = validateParameter(valid_593073, JString, required = false,
                                 default = nil)
  if valid_593073 != nil:
    section.add "X-Amz-Signature", valid_593073
  var valid_593074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593074 = validateParameter(valid_593074, JString, required = false,
                                 default = nil)
  if valid_593074 != nil:
    section.add "X-Amz-Content-Sha256", valid_593074
  var valid_593075 = header.getOrDefault("X-Amz-Date")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = nil)
  if valid_593075 != nil:
    section.add "X-Amz-Date", valid_593075
  var valid_593076 = header.getOrDefault("X-Amz-Credential")
  valid_593076 = validateParameter(valid_593076, JString, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "X-Amz-Credential", valid_593076
  var valid_593077 = header.getOrDefault("X-Amz-Security-Token")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-Security-Token", valid_593077
  var valid_593078 = header.getOrDefault("X-Amz-Algorithm")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = nil)
  if valid_593078 != nil:
    section.add "X-Amz-Algorithm", valid_593078
  var valid_593079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593079 = validateParameter(valid_593079, JString, required = false,
                                 default = nil)
  if valid_593079 != nil:
    section.add "X-Amz-SignedHeaders", valid_593079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593081: Call_DescribeDomain_593070; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about the domain.
  ## 
  let valid = call_593081.validator(path, query, header, formData, body)
  let scheme = call_593081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593081.url(scheme.get, call_593081.host, call_593081.base,
                         call_593081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593081, url, valid)

proc call*(call_593082: Call_DescribeDomain_593070; body: JsonNode): Recallable =
  ## describeDomain
  ## Provides information about the domain.
  ##   body: JObject (required)
  var body_593083 = newJObject()
  if body != nil:
    body_593083 = body
  result = call_593082.call(nil, nil, nil, nil, body_593083)

var describeDomain* = Call_DescribeDomain_593070(name: "describeDomain",
    meth: HttpMethod.HttpPost, host: "worklink.amazonaws.com",
    route: "/describeDomain", validator: validate_DescribeDomain_593071, base: "/",
    url: url_DescribeDomain_593072, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFleetMetadata_593084 = ref object of OpenApiRestCall_592364
proc url_DescribeFleetMetadata_593086(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeFleetMetadata_593085(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593087 = header.getOrDefault("X-Amz-Signature")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "X-Amz-Signature", valid_593087
  var valid_593088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593088 = validateParameter(valid_593088, JString, required = false,
                                 default = nil)
  if valid_593088 != nil:
    section.add "X-Amz-Content-Sha256", valid_593088
  var valid_593089 = header.getOrDefault("X-Amz-Date")
  valid_593089 = validateParameter(valid_593089, JString, required = false,
                                 default = nil)
  if valid_593089 != nil:
    section.add "X-Amz-Date", valid_593089
  var valid_593090 = header.getOrDefault("X-Amz-Credential")
  valid_593090 = validateParameter(valid_593090, JString, required = false,
                                 default = nil)
  if valid_593090 != nil:
    section.add "X-Amz-Credential", valid_593090
  var valid_593091 = header.getOrDefault("X-Amz-Security-Token")
  valid_593091 = validateParameter(valid_593091, JString, required = false,
                                 default = nil)
  if valid_593091 != nil:
    section.add "X-Amz-Security-Token", valid_593091
  var valid_593092 = header.getOrDefault("X-Amz-Algorithm")
  valid_593092 = validateParameter(valid_593092, JString, required = false,
                                 default = nil)
  if valid_593092 != nil:
    section.add "X-Amz-Algorithm", valid_593092
  var valid_593093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593093 = validateParameter(valid_593093, JString, required = false,
                                 default = nil)
  if valid_593093 != nil:
    section.add "X-Amz-SignedHeaders", valid_593093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593095: Call_DescribeFleetMetadata_593084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides basic information for the specified fleet, excluding identity provider, networking, and device configuration details.
  ## 
  let valid = call_593095.validator(path, query, header, formData, body)
  let scheme = call_593095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593095.url(scheme.get, call_593095.host, call_593095.base,
                         call_593095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593095, url, valid)

proc call*(call_593096: Call_DescribeFleetMetadata_593084; body: JsonNode): Recallable =
  ## describeFleetMetadata
  ## Provides basic information for the specified fleet, excluding identity provider, networking, and device configuration details.
  ##   body: JObject (required)
  var body_593097 = newJObject()
  if body != nil:
    body_593097 = body
  result = call_593096.call(nil, nil, nil, nil, body_593097)

var describeFleetMetadata* = Call_DescribeFleetMetadata_593084(
    name: "describeFleetMetadata", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/describeFleetMetadata",
    validator: validate_DescribeFleetMetadata_593085, base: "/",
    url: url_DescribeFleetMetadata_593086, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentityProviderConfiguration_593098 = ref object of OpenApiRestCall_592364
proc url_DescribeIdentityProviderConfiguration_593100(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeIdentityProviderConfiguration_593099(path: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593101 = header.getOrDefault("X-Amz-Signature")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "X-Amz-Signature", valid_593101
  var valid_593102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593102 = validateParameter(valid_593102, JString, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "X-Amz-Content-Sha256", valid_593102
  var valid_593103 = header.getOrDefault("X-Amz-Date")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "X-Amz-Date", valid_593103
  var valid_593104 = header.getOrDefault("X-Amz-Credential")
  valid_593104 = validateParameter(valid_593104, JString, required = false,
                                 default = nil)
  if valid_593104 != nil:
    section.add "X-Amz-Credential", valid_593104
  var valid_593105 = header.getOrDefault("X-Amz-Security-Token")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "X-Amz-Security-Token", valid_593105
  var valid_593106 = header.getOrDefault("X-Amz-Algorithm")
  valid_593106 = validateParameter(valid_593106, JString, required = false,
                                 default = nil)
  if valid_593106 != nil:
    section.add "X-Amz-Algorithm", valid_593106
  var valid_593107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593107 = validateParameter(valid_593107, JString, required = false,
                                 default = nil)
  if valid_593107 != nil:
    section.add "X-Amz-SignedHeaders", valid_593107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593109: Call_DescribeIdentityProviderConfiguration_593098;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the identity provider configuration of the specified fleet.
  ## 
  let valid = call_593109.validator(path, query, header, formData, body)
  let scheme = call_593109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593109.url(scheme.get, call_593109.host, call_593109.base,
                         call_593109.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593109, url, valid)

proc call*(call_593110: Call_DescribeIdentityProviderConfiguration_593098;
          body: JsonNode): Recallable =
  ## describeIdentityProviderConfiguration
  ## Describes the identity provider configuration of the specified fleet.
  ##   body: JObject (required)
  var body_593111 = newJObject()
  if body != nil:
    body_593111 = body
  result = call_593110.call(nil, nil, nil, nil, body_593111)

var describeIdentityProviderConfiguration* = Call_DescribeIdentityProviderConfiguration_593098(
    name: "describeIdentityProviderConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com",
    route: "/describeIdentityProviderConfiguration",
    validator: validate_DescribeIdentityProviderConfiguration_593099, base: "/",
    url: url_DescribeIdentityProviderConfiguration_593100,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWebsiteCertificateAuthority_593112 = ref object of OpenApiRestCall_592364
proc url_DescribeWebsiteCertificateAuthority_593114(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeWebsiteCertificateAuthority_593113(path: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593115 = header.getOrDefault("X-Amz-Signature")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "X-Amz-Signature", valid_593115
  var valid_593116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593116 = validateParameter(valid_593116, JString, required = false,
                                 default = nil)
  if valid_593116 != nil:
    section.add "X-Amz-Content-Sha256", valid_593116
  var valid_593117 = header.getOrDefault("X-Amz-Date")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "X-Amz-Date", valid_593117
  var valid_593118 = header.getOrDefault("X-Amz-Credential")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "X-Amz-Credential", valid_593118
  var valid_593119 = header.getOrDefault("X-Amz-Security-Token")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "X-Amz-Security-Token", valid_593119
  var valid_593120 = header.getOrDefault("X-Amz-Algorithm")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "X-Amz-Algorithm", valid_593120
  var valid_593121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "X-Amz-SignedHeaders", valid_593121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593123: Call_DescribeWebsiteCertificateAuthority_593112;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Provides information about the certificate authority.
  ## 
  let valid = call_593123.validator(path, query, header, formData, body)
  let scheme = call_593123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593123.url(scheme.get, call_593123.host, call_593123.base,
                         call_593123.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593123, url, valid)

proc call*(call_593124: Call_DescribeWebsiteCertificateAuthority_593112;
          body: JsonNode): Recallable =
  ## describeWebsiteCertificateAuthority
  ## Provides information about the certificate authority.
  ##   body: JObject (required)
  var body_593125 = newJObject()
  if body != nil:
    body_593125 = body
  result = call_593124.call(nil, nil, nil, nil, body_593125)

var describeWebsiteCertificateAuthority* = Call_DescribeWebsiteCertificateAuthority_593112(
    name: "describeWebsiteCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/describeWebsiteCertificateAuthority",
    validator: validate_DescribeWebsiteCertificateAuthority_593113, base: "/",
    url: url_DescribeWebsiteCertificateAuthority_593114,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateDomain_593126 = ref object of OpenApiRestCall_592364
proc url_DisassociateDomain_593128(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateDomain_593127(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593129 = header.getOrDefault("X-Amz-Signature")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "X-Amz-Signature", valid_593129
  var valid_593130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "X-Amz-Content-Sha256", valid_593130
  var valid_593131 = header.getOrDefault("X-Amz-Date")
  valid_593131 = validateParameter(valid_593131, JString, required = false,
                                 default = nil)
  if valid_593131 != nil:
    section.add "X-Amz-Date", valid_593131
  var valid_593132 = header.getOrDefault("X-Amz-Credential")
  valid_593132 = validateParameter(valid_593132, JString, required = false,
                                 default = nil)
  if valid_593132 != nil:
    section.add "X-Amz-Credential", valid_593132
  var valid_593133 = header.getOrDefault("X-Amz-Security-Token")
  valid_593133 = validateParameter(valid_593133, JString, required = false,
                                 default = nil)
  if valid_593133 != nil:
    section.add "X-Amz-Security-Token", valid_593133
  var valid_593134 = header.getOrDefault("X-Amz-Algorithm")
  valid_593134 = validateParameter(valid_593134, JString, required = false,
                                 default = nil)
  if valid_593134 != nil:
    section.add "X-Amz-Algorithm", valid_593134
  var valid_593135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593135 = validateParameter(valid_593135, JString, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "X-Amz-SignedHeaders", valid_593135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593137: Call_DisassociateDomain_593126; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a domain from Amazon WorkLink. End users lose the ability to access the domain with Amazon WorkLink. 
  ## 
  let valid = call_593137.validator(path, query, header, formData, body)
  let scheme = call_593137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593137.url(scheme.get, call_593137.host, call_593137.base,
                         call_593137.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593137, url, valid)

proc call*(call_593138: Call_DisassociateDomain_593126; body: JsonNode): Recallable =
  ## disassociateDomain
  ## Disassociates a domain from Amazon WorkLink. End users lose the ability to access the domain with Amazon WorkLink. 
  ##   body: JObject (required)
  var body_593139 = newJObject()
  if body != nil:
    body_593139 = body
  result = call_593138.call(nil, nil, nil, nil, body_593139)

var disassociateDomain* = Call_DisassociateDomain_593126(
    name: "disassociateDomain", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/disassociateDomain",
    validator: validate_DisassociateDomain_593127, base: "/",
    url: url_DisassociateDomain_593128, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateWebsiteAuthorizationProvider_593140 = ref object of OpenApiRestCall_592364
proc url_DisassociateWebsiteAuthorizationProvider_593142(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateWebsiteAuthorizationProvider_593141(path: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593143 = header.getOrDefault("X-Amz-Signature")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-Signature", valid_593143
  var valid_593144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "X-Amz-Content-Sha256", valid_593144
  var valid_593145 = header.getOrDefault("X-Amz-Date")
  valid_593145 = validateParameter(valid_593145, JString, required = false,
                                 default = nil)
  if valid_593145 != nil:
    section.add "X-Amz-Date", valid_593145
  var valid_593146 = header.getOrDefault("X-Amz-Credential")
  valid_593146 = validateParameter(valid_593146, JString, required = false,
                                 default = nil)
  if valid_593146 != nil:
    section.add "X-Amz-Credential", valid_593146
  var valid_593147 = header.getOrDefault("X-Amz-Security-Token")
  valid_593147 = validateParameter(valid_593147, JString, required = false,
                                 default = nil)
  if valid_593147 != nil:
    section.add "X-Amz-Security-Token", valid_593147
  var valid_593148 = header.getOrDefault("X-Amz-Algorithm")
  valid_593148 = validateParameter(valid_593148, JString, required = false,
                                 default = nil)
  if valid_593148 != nil:
    section.add "X-Amz-Algorithm", valid_593148
  var valid_593149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593149 = validateParameter(valid_593149, JString, required = false,
                                 default = nil)
  if valid_593149 != nil:
    section.add "X-Amz-SignedHeaders", valid_593149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593151: Call_DisassociateWebsiteAuthorizationProvider_593140;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a website authorization provider from a specified fleet. After the disassociation, users can't load any associated websites that require this authorization provider.
  ## 
  let valid = call_593151.validator(path, query, header, formData, body)
  let scheme = call_593151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593151.url(scheme.get, call_593151.host, call_593151.base,
                         call_593151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593151, url, valid)

proc call*(call_593152: Call_DisassociateWebsiteAuthorizationProvider_593140;
          body: JsonNode): Recallable =
  ## disassociateWebsiteAuthorizationProvider
  ## Disassociates a website authorization provider from a specified fleet. After the disassociation, users can't load any associated websites that require this authorization provider.
  ##   body: JObject (required)
  var body_593153 = newJObject()
  if body != nil:
    body_593153 = body
  result = call_593152.call(nil, nil, nil, nil, body_593153)

var disassociateWebsiteAuthorizationProvider* = Call_DisassociateWebsiteAuthorizationProvider_593140(
    name: "disassociateWebsiteAuthorizationProvider", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com",
    route: "/disassociateWebsiteAuthorizationProvider",
    validator: validate_DisassociateWebsiteAuthorizationProvider_593141,
    base: "/", url: url_DisassociateWebsiteAuthorizationProvider_593142,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateWebsiteCertificateAuthority_593154 = ref object of OpenApiRestCall_592364
proc url_DisassociateWebsiteCertificateAuthority_593156(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateWebsiteCertificateAuthority_593155(path: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593157 = header.getOrDefault("X-Amz-Signature")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-Signature", valid_593157
  var valid_593158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "X-Amz-Content-Sha256", valid_593158
  var valid_593159 = header.getOrDefault("X-Amz-Date")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "X-Amz-Date", valid_593159
  var valid_593160 = header.getOrDefault("X-Amz-Credential")
  valid_593160 = validateParameter(valid_593160, JString, required = false,
                                 default = nil)
  if valid_593160 != nil:
    section.add "X-Amz-Credential", valid_593160
  var valid_593161 = header.getOrDefault("X-Amz-Security-Token")
  valid_593161 = validateParameter(valid_593161, JString, required = false,
                                 default = nil)
  if valid_593161 != nil:
    section.add "X-Amz-Security-Token", valid_593161
  var valid_593162 = header.getOrDefault("X-Amz-Algorithm")
  valid_593162 = validateParameter(valid_593162, JString, required = false,
                                 default = nil)
  if valid_593162 != nil:
    section.add "X-Amz-Algorithm", valid_593162
  var valid_593163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593163 = validateParameter(valid_593163, JString, required = false,
                                 default = nil)
  if valid_593163 != nil:
    section.add "X-Amz-SignedHeaders", valid_593163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593165: Call_DisassociateWebsiteCertificateAuthority_593154;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a certificate authority (CA).
  ## 
  let valid = call_593165.validator(path, query, header, formData, body)
  let scheme = call_593165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593165.url(scheme.get, call_593165.host, call_593165.base,
                         call_593165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593165, url, valid)

proc call*(call_593166: Call_DisassociateWebsiteCertificateAuthority_593154;
          body: JsonNode): Recallable =
  ## disassociateWebsiteCertificateAuthority
  ## Removes a certificate authority (CA).
  ##   body: JObject (required)
  var body_593167 = newJObject()
  if body != nil:
    body_593167 = body
  result = call_593166.call(nil, nil, nil, nil, body_593167)

var disassociateWebsiteCertificateAuthority* = Call_DisassociateWebsiteCertificateAuthority_593154(
    name: "disassociateWebsiteCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com",
    route: "/disassociateWebsiteCertificateAuthority",
    validator: validate_DisassociateWebsiteCertificateAuthority_593155, base: "/",
    url: url_DisassociateWebsiteCertificateAuthority_593156,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevices_593168 = ref object of OpenApiRestCall_592364
proc url_ListDevices_593170(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDevices_593169(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of devices registered with the specified fleet.
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
  var valid_593171 = query.getOrDefault("MaxResults")
  valid_593171 = validateParameter(valid_593171, JString, required = false,
                                 default = nil)
  if valid_593171 != nil:
    section.add "MaxResults", valid_593171
  var valid_593172 = query.getOrDefault("NextToken")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "NextToken", valid_593172
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593173 = header.getOrDefault("X-Amz-Signature")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "X-Amz-Signature", valid_593173
  var valid_593174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593174 = validateParameter(valid_593174, JString, required = false,
                                 default = nil)
  if valid_593174 != nil:
    section.add "X-Amz-Content-Sha256", valid_593174
  var valid_593175 = header.getOrDefault("X-Amz-Date")
  valid_593175 = validateParameter(valid_593175, JString, required = false,
                                 default = nil)
  if valid_593175 != nil:
    section.add "X-Amz-Date", valid_593175
  var valid_593176 = header.getOrDefault("X-Amz-Credential")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "X-Amz-Credential", valid_593176
  var valid_593177 = header.getOrDefault("X-Amz-Security-Token")
  valid_593177 = validateParameter(valid_593177, JString, required = false,
                                 default = nil)
  if valid_593177 != nil:
    section.add "X-Amz-Security-Token", valid_593177
  var valid_593178 = header.getOrDefault("X-Amz-Algorithm")
  valid_593178 = validateParameter(valid_593178, JString, required = false,
                                 default = nil)
  if valid_593178 != nil:
    section.add "X-Amz-Algorithm", valid_593178
  var valid_593179 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593179 = validateParameter(valid_593179, JString, required = false,
                                 default = nil)
  if valid_593179 != nil:
    section.add "X-Amz-SignedHeaders", valid_593179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593181: Call_ListDevices_593168; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of devices registered with the specified fleet.
  ## 
  let valid = call_593181.validator(path, query, header, formData, body)
  let scheme = call_593181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593181.url(scheme.get, call_593181.host, call_593181.base,
                         call_593181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593181, url, valid)

proc call*(call_593182: Call_ListDevices_593168; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDevices
  ## Retrieves a list of devices registered with the specified fleet.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593183 = newJObject()
  var body_593184 = newJObject()
  add(query_593183, "MaxResults", newJString(MaxResults))
  add(query_593183, "NextToken", newJString(NextToken))
  if body != nil:
    body_593184 = body
  result = call_593182.call(nil, query_593183, nil, nil, body_593184)

var listDevices* = Call_ListDevices_593168(name: "listDevices",
                                        meth: HttpMethod.HttpPost,
                                        host: "worklink.amazonaws.com",
                                        route: "/listDevices",
                                        validator: validate_ListDevices_593169,
                                        base: "/", url: url_ListDevices_593170,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomains_593186 = ref object of OpenApiRestCall_592364
proc url_ListDomains_593188(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDomains_593187(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of domains associated to a specified fleet.
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
  var valid_593189 = query.getOrDefault("MaxResults")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "MaxResults", valid_593189
  var valid_593190 = query.getOrDefault("NextToken")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "NextToken", valid_593190
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593191 = header.getOrDefault("X-Amz-Signature")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "X-Amz-Signature", valid_593191
  var valid_593192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "X-Amz-Content-Sha256", valid_593192
  var valid_593193 = header.getOrDefault("X-Amz-Date")
  valid_593193 = validateParameter(valid_593193, JString, required = false,
                                 default = nil)
  if valid_593193 != nil:
    section.add "X-Amz-Date", valid_593193
  var valid_593194 = header.getOrDefault("X-Amz-Credential")
  valid_593194 = validateParameter(valid_593194, JString, required = false,
                                 default = nil)
  if valid_593194 != nil:
    section.add "X-Amz-Credential", valid_593194
  var valid_593195 = header.getOrDefault("X-Amz-Security-Token")
  valid_593195 = validateParameter(valid_593195, JString, required = false,
                                 default = nil)
  if valid_593195 != nil:
    section.add "X-Amz-Security-Token", valid_593195
  var valid_593196 = header.getOrDefault("X-Amz-Algorithm")
  valid_593196 = validateParameter(valid_593196, JString, required = false,
                                 default = nil)
  if valid_593196 != nil:
    section.add "X-Amz-Algorithm", valid_593196
  var valid_593197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593197 = validateParameter(valid_593197, JString, required = false,
                                 default = nil)
  if valid_593197 != nil:
    section.add "X-Amz-SignedHeaders", valid_593197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593199: Call_ListDomains_593186; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of domains associated to a specified fleet.
  ## 
  let valid = call_593199.validator(path, query, header, formData, body)
  let scheme = call_593199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593199.url(scheme.get, call_593199.host, call_593199.base,
                         call_593199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593199, url, valid)

proc call*(call_593200: Call_ListDomains_593186; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDomains
  ## Retrieves a list of domains associated to a specified fleet.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593201 = newJObject()
  var body_593202 = newJObject()
  add(query_593201, "MaxResults", newJString(MaxResults))
  add(query_593201, "NextToken", newJString(NextToken))
  if body != nil:
    body_593202 = body
  result = call_593200.call(nil, query_593201, nil, nil, body_593202)

var listDomains* = Call_ListDomains_593186(name: "listDomains",
                                        meth: HttpMethod.HttpPost,
                                        host: "worklink.amazonaws.com",
                                        route: "/listDomains",
                                        validator: validate_ListDomains_593187,
                                        base: "/", url: url_ListDomains_593188,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFleets_593203 = ref object of OpenApiRestCall_592364
proc url_ListFleets_593205(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListFleets_593204(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of fleets for the current account and Region.
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
  var valid_593206 = query.getOrDefault("MaxResults")
  valid_593206 = validateParameter(valid_593206, JString, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "MaxResults", valid_593206
  var valid_593207 = query.getOrDefault("NextToken")
  valid_593207 = validateParameter(valid_593207, JString, required = false,
                                 default = nil)
  if valid_593207 != nil:
    section.add "NextToken", valid_593207
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593208 = header.getOrDefault("X-Amz-Signature")
  valid_593208 = validateParameter(valid_593208, JString, required = false,
                                 default = nil)
  if valid_593208 != nil:
    section.add "X-Amz-Signature", valid_593208
  var valid_593209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593209 = validateParameter(valid_593209, JString, required = false,
                                 default = nil)
  if valid_593209 != nil:
    section.add "X-Amz-Content-Sha256", valid_593209
  var valid_593210 = header.getOrDefault("X-Amz-Date")
  valid_593210 = validateParameter(valid_593210, JString, required = false,
                                 default = nil)
  if valid_593210 != nil:
    section.add "X-Amz-Date", valid_593210
  var valid_593211 = header.getOrDefault("X-Amz-Credential")
  valid_593211 = validateParameter(valid_593211, JString, required = false,
                                 default = nil)
  if valid_593211 != nil:
    section.add "X-Amz-Credential", valid_593211
  var valid_593212 = header.getOrDefault("X-Amz-Security-Token")
  valid_593212 = validateParameter(valid_593212, JString, required = false,
                                 default = nil)
  if valid_593212 != nil:
    section.add "X-Amz-Security-Token", valid_593212
  var valid_593213 = header.getOrDefault("X-Amz-Algorithm")
  valid_593213 = validateParameter(valid_593213, JString, required = false,
                                 default = nil)
  if valid_593213 != nil:
    section.add "X-Amz-Algorithm", valid_593213
  var valid_593214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593214 = validateParameter(valid_593214, JString, required = false,
                                 default = nil)
  if valid_593214 != nil:
    section.add "X-Amz-SignedHeaders", valid_593214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593216: Call_ListFleets_593203; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of fleets for the current account and Region.
  ## 
  let valid = call_593216.validator(path, query, header, formData, body)
  let scheme = call_593216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593216.url(scheme.get, call_593216.host, call_593216.base,
                         call_593216.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593216, url, valid)

proc call*(call_593217: Call_ListFleets_593203; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFleets
  ## Retrieves a list of fleets for the current account and Region.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593218 = newJObject()
  var body_593219 = newJObject()
  add(query_593218, "MaxResults", newJString(MaxResults))
  add(query_593218, "NextToken", newJString(NextToken))
  if body != nil:
    body_593219 = body
  result = call_593217.call(nil, query_593218, nil, nil, body_593219)

var listFleets* = Call_ListFleets_593203(name: "listFleets",
                                      meth: HttpMethod.HttpPost,
                                      host: "worklink.amazonaws.com",
                                      route: "/listFleets",
                                      validator: validate_ListFleets_593204,
                                      base: "/", url: url_ListFleets_593205,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWebsiteAuthorizationProviders_593220 = ref object of OpenApiRestCall_592364
proc url_ListWebsiteAuthorizationProviders_593222(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListWebsiteAuthorizationProviders_593221(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of website authorization providers associated with a specified fleet.
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
  var valid_593223 = query.getOrDefault("MaxResults")
  valid_593223 = validateParameter(valid_593223, JString, required = false,
                                 default = nil)
  if valid_593223 != nil:
    section.add "MaxResults", valid_593223
  var valid_593224 = query.getOrDefault("NextToken")
  valid_593224 = validateParameter(valid_593224, JString, required = false,
                                 default = nil)
  if valid_593224 != nil:
    section.add "NextToken", valid_593224
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593225 = header.getOrDefault("X-Amz-Signature")
  valid_593225 = validateParameter(valid_593225, JString, required = false,
                                 default = nil)
  if valid_593225 != nil:
    section.add "X-Amz-Signature", valid_593225
  var valid_593226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593226 = validateParameter(valid_593226, JString, required = false,
                                 default = nil)
  if valid_593226 != nil:
    section.add "X-Amz-Content-Sha256", valid_593226
  var valid_593227 = header.getOrDefault("X-Amz-Date")
  valid_593227 = validateParameter(valid_593227, JString, required = false,
                                 default = nil)
  if valid_593227 != nil:
    section.add "X-Amz-Date", valid_593227
  var valid_593228 = header.getOrDefault("X-Amz-Credential")
  valid_593228 = validateParameter(valid_593228, JString, required = false,
                                 default = nil)
  if valid_593228 != nil:
    section.add "X-Amz-Credential", valid_593228
  var valid_593229 = header.getOrDefault("X-Amz-Security-Token")
  valid_593229 = validateParameter(valid_593229, JString, required = false,
                                 default = nil)
  if valid_593229 != nil:
    section.add "X-Amz-Security-Token", valid_593229
  var valid_593230 = header.getOrDefault("X-Amz-Algorithm")
  valid_593230 = validateParameter(valid_593230, JString, required = false,
                                 default = nil)
  if valid_593230 != nil:
    section.add "X-Amz-Algorithm", valid_593230
  var valid_593231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593231 = validateParameter(valid_593231, JString, required = false,
                                 default = nil)
  if valid_593231 != nil:
    section.add "X-Amz-SignedHeaders", valid_593231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593233: Call_ListWebsiteAuthorizationProviders_593220;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves a list of website authorization providers associated with a specified fleet.
  ## 
  let valid = call_593233.validator(path, query, header, formData, body)
  let scheme = call_593233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593233.url(scheme.get, call_593233.host, call_593233.base,
                         call_593233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593233, url, valid)

proc call*(call_593234: Call_ListWebsiteAuthorizationProviders_593220;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listWebsiteAuthorizationProviders
  ## Retrieves a list of website authorization providers associated with a specified fleet.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593235 = newJObject()
  var body_593236 = newJObject()
  add(query_593235, "MaxResults", newJString(MaxResults))
  add(query_593235, "NextToken", newJString(NextToken))
  if body != nil:
    body_593236 = body
  result = call_593234.call(nil, query_593235, nil, nil, body_593236)

var listWebsiteAuthorizationProviders* = Call_ListWebsiteAuthorizationProviders_593220(
    name: "listWebsiteAuthorizationProviders", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/listWebsiteAuthorizationProviders",
    validator: validate_ListWebsiteAuthorizationProviders_593221, base: "/",
    url: url_ListWebsiteAuthorizationProviders_593222,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWebsiteCertificateAuthorities_593237 = ref object of OpenApiRestCall_592364
proc url_ListWebsiteCertificateAuthorities_593239(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListWebsiteCertificateAuthorities_593238(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of certificate authorities added for the current account and Region.
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
  var valid_593240 = query.getOrDefault("MaxResults")
  valid_593240 = validateParameter(valid_593240, JString, required = false,
                                 default = nil)
  if valid_593240 != nil:
    section.add "MaxResults", valid_593240
  var valid_593241 = query.getOrDefault("NextToken")
  valid_593241 = validateParameter(valid_593241, JString, required = false,
                                 default = nil)
  if valid_593241 != nil:
    section.add "NextToken", valid_593241
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593242 = header.getOrDefault("X-Amz-Signature")
  valid_593242 = validateParameter(valid_593242, JString, required = false,
                                 default = nil)
  if valid_593242 != nil:
    section.add "X-Amz-Signature", valid_593242
  var valid_593243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593243 = validateParameter(valid_593243, JString, required = false,
                                 default = nil)
  if valid_593243 != nil:
    section.add "X-Amz-Content-Sha256", valid_593243
  var valid_593244 = header.getOrDefault("X-Amz-Date")
  valid_593244 = validateParameter(valid_593244, JString, required = false,
                                 default = nil)
  if valid_593244 != nil:
    section.add "X-Amz-Date", valid_593244
  var valid_593245 = header.getOrDefault("X-Amz-Credential")
  valid_593245 = validateParameter(valid_593245, JString, required = false,
                                 default = nil)
  if valid_593245 != nil:
    section.add "X-Amz-Credential", valid_593245
  var valid_593246 = header.getOrDefault("X-Amz-Security-Token")
  valid_593246 = validateParameter(valid_593246, JString, required = false,
                                 default = nil)
  if valid_593246 != nil:
    section.add "X-Amz-Security-Token", valid_593246
  var valid_593247 = header.getOrDefault("X-Amz-Algorithm")
  valid_593247 = validateParameter(valid_593247, JString, required = false,
                                 default = nil)
  if valid_593247 != nil:
    section.add "X-Amz-Algorithm", valid_593247
  var valid_593248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593248 = validateParameter(valid_593248, JString, required = false,
                                 default = nil)
  if valid_593248 != nil:
    section.add "X-Amz-SignedHeaders", valid_593248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593250: Call_ListWebsiteCertificateAuthorities_593237;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves a list of certificate authorities added for the current account and Region.
  ## 
  let valid = call_593250.validator(path, query, header, formData, body)
  let scheme = call_593250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593250.url(scheme.get, call_593250.host, call_593250.base,
                         call_593250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593250, url, valid)

proc call*(call_593251: Call_ListWebsiteCertificateAuthorities_593237;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listWebsiteCertificateAuthorities
  ## Retrieves a list of certificate authorities added for the current account and Region.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593252 = newJObject()
  var body_593253 = newJObject()
  add(query_593252, "MaxResults", newJString(MaxResults))
  add(query_593252, "NextToken", newJString(NextToken))
  if body != nil:
    body_593253 = body
  result = call_593251.call(nil, query_593252, nil, nil, body_593253)

var listWebsiteCertificateAuthorities* = Call_ListWebsiteCertificateAuthorities_593237(
    name: "listWebsiteCertificateAuthorities", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/listWebsiteCertificateAuthorities",
    validator: validate_ListWebsiteCertificateAuthorities_593238, base: "/",
    url: url_ListWebsiteCertificateAuthorities_593239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreDomainAccess_593254 = ref object of OpenApiRestCall_592364
proc url_RestoreDomainAccess_593256(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RestoreDomainAccess_593255(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593257 = header.getOrDefault("X-Amz-Signature")
  valid_593257 = validateParameter(valid_593257, JString, required = false,
                                 default = nil)
  if valid_593257 != nil:
    section.add "X-Amz-Signature", valid_593257
  var valid_593258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593258 = validateParameter(valid_593258, JString, required = false,
                                 default = nil)
  if valid_593258 != nil:
    section.add "X-Amz-Content-Sha256", valid_593258
  var valid_593259 = header.getOrDefault("X-Amz-Date")
  valid_593259 = validateParameter(valid_593259, JString, required = false,
                                 default = nil)
  if valid_593259 != nil:
    section.add "X-Amz-Date", valid_593259
  var valid_593260 = header.getOrDefault("X-Amz-Credential")
  valid_593260 = validateParameter(valid_593260, JString, required = false,
                                 default = nil)
  if valid_593260 != nil:
    section.add "X-Amz-Credential", valid_593260
  var valid_593261 = header.getOrDefault("X-Amz-Security-Token")
  valid_593261 = validateParameter(valid_593261, JString, required = false,
                                 default = nil)
  if valid_593261 != nil:
    section.add "X-Amz-Security-Token", valid_593261
  var valid_593262 = header.getOrDefault("X-Amz-Algorithm")
  valid_593262 = validateParameter(valid_593262, JString, required = false,
                                 default = nil)
  if valid_593262 != nil:
    section.add "X-Amz-Algorithm", valid_593262
  var valid_593263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593263 = validateParameter(valid_593263, JString, required = false,
                                 default = nil)
  if valid_593263 != nil:
    section.add "X-Amz-SignedHeaders", valid_593263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593265: Call_RestoreDomainAccess_593254; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Moves a domain to ACTIVE status if it was in the INACTIVE status.
  ## 
  let valid = call_593265.validator(path, query, header, formData, body)
  let scheme = call_593265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593265.url(scheme.get, call_593265.host, call_593265.base,
                         call_593265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593265, url, valid)

proc call*(call_593266: Call_RestoreDomainAccess_593254; body: JsonNode): Recallable =
  ## restoreDomainAccess
  ## Moves a domain to ACTIVE status if it was in the INACTIVE status.
  ##   body: JObject (required)
  var body_593267 = newJObject()
  if body != nil:
    body_593267 = body
  result = call_593266.call(nil, nil, nil, nil, body_593267)

var restoreDomainAccess* = Call_RestoreDomainAccess_593254(
    name: "restoreDomainAccess", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/restoreDomainAccess",
    validator: validate_RestoreDomainAccess_593255, base: "/",
    url: url_RestoreDomainAccess_593256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeDomainAccess_593268 = ref object of OpenApiRestCall_592364
proc url_RevokeDomainAccess_593270(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RevokeDomainAccess_593269(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593271 = header.getOrDefault("X-Amz-Signature")
  valid_593271 = validateParameter(valid_593271, JString, required = false,
                                 default = nil)
  if valid_593271 != nil:
    section.add "X-Amz-Signature", valid_593271
  var valid_593272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593272 = validateParameter(valid_593272, JString, required = false,
                                 default = nil)
  if valid_593272 != nil:
    section.add "X-Amz-Content-Sha256", valid_593272
  var valid_593273 = header.getOrDefault("X-Amz-Date")
  valid_593273 = validateParameter(valid_593273, JString, required = false,
                                 default = nil)
  if valid_593273 != nil:
    section.add "X-Amz-Date", valid_593273
  var valid_593274 = header.getOrDefault("X-Amz-Credential")
  valid_593274 = validateParameter(valid_593274, JString, required = false,
                                 default = nil)
  if valid_593274 != nil:
    section.add "X-Amz-Credential", valid_593274
  var valid_593275 = header.getOrDefault("X-Amz-Security-Token")
  valid_593275 = validateParameter(valid_593275, JString, required = false,
                                 default = nil)
  if valid_593275 != nil:
    section.add "X-Amz-Security-Token", valid_593275
  var valid_593276 = header.getOrDefault("X-Amz-Algorithm")
  valid_593276 = validateParameter(valid_593276, JString, required = false,
                                 default = nil)
  if valid_593276 != nil:
    section.add "X-Amz-Algorithm", valid_593276
  var valid_593277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593277 = validateParameter(valid_593277, JString, required = false,
                                 default = nil)
  if valid_593277 != nil:
    section.add "X-Amz-SignedHeaders", valid_593277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593279: Call_RevokeDomainAccess_593268; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Moves a domain to INACTIVE status if it was in the ACTIVE status.
  ## 
  let valid = call_593279.validator(path, query, header, formData, body)
  let scheme = call_593279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593279.url(scheme.get, call_593279.host, call_593279.base,
                         call_593279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593279, url, valid)

proc call*(call_593280: Call_RevokeDomainAccess_593268; body: JsonNode): Recallable =
  ## revokeDomainAccess
  ## Moves a domain to INACTIVE status if it was in the ACTIVE status.
  ##   body: JObject (required)
  var body_593281 = newJObject()
  if body != nil:
    body_593281 = body
  result = call_593280.call(nil, nil, nil, nil, body_593281)

var revokeDomainAccess* = Call_RevokeDomainAccess_593268(
    name: "revokeDomainAccess", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/revokeDomainAccess",
    validator: validate_RevokeDomainAccess_593269, base: "/",
    url: url_RevokeDomainAccess_593270, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SignOutUser_593282 = ref object of OpenApiRestCall_592364
proc url_SignOutUser_593284(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SignOutUser_593283(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593285 = header.getOrDefault("X-Amz-Signature")
  valid_593285 = validateParameter(valid_593285, JString, required = false,
                                 default = nil)
  if valid_593285 != nil:
    section.add "X-Amz-Signature", valid_593285
  var valid_593286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593286 = validateParameter(valid_593286, JString, required = false,
                                 default = nil)
  if valid_593286 != nil:
    section.add "X-Amz-Content-Sha256", valid_593286
  var valid_593287 = header.getOrDefault("X-Amz-Date")
  valid_593287 = validateParameter(valid_593287, JString, required = false,
                                 default = nil)
  if valid_593287 != nil:
    section.add "X-Amz-Date", valid_593287
  var valid_593288 = header.getOrDefault("X-Amz-Credential")
  valid_593288 = validateParameter(valid_593288, JString, required = false,
                                 default = nil)
  if valid_593288 != nil:
    section.add "X-Amz-Credential", valid_593288
  var valid_593289 = header.getOrDefault("X-Amz-Security-Token")
  valid_593289 = validateParameter(valid_593289, JString, required = false,
                                 default = nil)
  if valid_593289 != nil:
    section.add "X-Amz-Security-Token", valid_593289
  var valid_593290 = header.getOrDefault("X-Amz-Algorithm")
  valid_593290 = validateParameter(valid_593290, JString, required = false,
                                 default = nil)
  if valid_593290 != nil:
    section.add "X-Amz-Algorithm", valid_593290
  var valid_593291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593291 = validateParameter(valid_593291, JString, required = false,
                                 default = nil)
  if valid_593291 != nil:
    section.add "X-Amz-SignedHeaders", valid_593291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593293: Call_SignOutUser_593282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Signs the user out from all of their devices. The user can sign in again if they have valid credentials.
  ## 
  let valid = call_593293.validator(path, query, header, formData, body)
  let scheme = call_593293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593293.url(scheme.get, call_593293.host, call_593293.base,
                         call_593293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593293, url, valid)

proc call*(call_593294: Call_SignOutUser_593282; body: JsonNode): Recallable =
  ## signOutUser
  ## Signs the user out from all of their devices. The user can sign in again if they have valid credentials.
  ##   body: JObject (required)
  var body_593295 = newJObject()
  if body != nil:
    body_593295 = body
  result = call_593294.call(nil, nil, nil, nil, body_593295)

var signOutUser* = Call_SignOutUser_593282(name: "signOutUser",
                                        meth: HttpMethod.HttpPost,
                                        host: "worklink.amazonaws.com",
                                        route: "/signOutUser",
                                        validator: validate_SignOutUser_593283,
                                        base: "/", url: url_SignOutUser_593284,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuditStreamConfiguration_593296 = ref object of OpenApiRestCall_592364
proc url_UpdateAuditStreamConfiguration_593298(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateAuditStreamConfiguration_593297(path: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593299 = header.getOrDefault("X-Amz-Signature")
  valid_593299 = validateParameter(valid_593299, JString, required = false,
                                 default = nil)
  if valid_593299 != nil:
    section.add "X-Amz-Signature", valid_593299
  var valid_593300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593300 = validateParameter(valid_593300, JString, required = false,
                                 default = nil)
  if valid_593300 != nil:
    section.add "X-Amz-Content-Sha256", valid_593300
  var valid_593301 = header.getOrDefault("X-Amz-Date")
  valid_593301 = validateParameter(valid_593301, JString, required = false,
                                 default = nil)
  if valid_593301 != nil:
    section.add "X-Amz-Date", valid_593301
  var valid_593302 = header.getOrDefault("X-Amz-Credential")
  valid_593302 = validateParameter(valid_593302, JString, required = false,
                                 default = nil)
  if valid_593302 != nil:
    section.add "X-Amz-Credential", valid_593302
  var valid_593303 = header.getOrDefault("X-Amz-Security-Token")
  valid_593303 = validateParameter(valid_593303, JString, required = false,
                                 default = nil)
  if valid_593303 != nil:
    section.add "X-Amz-Security-Token", valid_593303
  var valid_593304 = header.getOrDefault("X-Amz-Algorithm")
  valid_593304 = validateParameter(valid_593304, JString, required = false,
                                 default = nil)
  if valid_593304 != nil:
    section.add "X-Amz-Algorithm", valid_593304
  var valid_593305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593305 = validateParameter(valid_593305, JString, required = false,
                                 default = nil)
  if valid_593305 != nil:
    section.add "X-Amz-SignedHeaders", valid_593305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593307: Call_UpdateAuditStreamConfiguration_593296; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the audit stream configuration for the fleet.
  ## 
  let valid = call_593307.validator(path, query, header, formData, body)
  let scheme = call_593307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593307.url(scheme.get, call_593307.host, call_593307.base,
                         call_593307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593307, url, valid)

proc call*(call_593308: Call_UpdateAuditStreamConfiguration_593296; body: JsonNode): Recallable =
  ## updateAuditStreamConfiguration
  ## Updates the audit stream configuration for the fleet.
  ##   body: JObject (required)
  var body_593309 = newJObject()
  if body != nil:
    body_593309 = body
  result = call_593308.call(nil, nil, nil, nil, body_593309)

var updateAuditStreamConfiguration* = Call_UpdateAuditStreamConfiguration_593296(
    name: "updateAuditStreamConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/updateAuditStreamConfiguration",
    validator: validate_UpdateAuditStreamConfiguration_593297, base: "/",
    url: url_UpdateAuditStreamConfiguration_593298,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCompanyNetworkConfiguration_593310 = ref object of OpenApiRestCall_592364
proc url_UpdateCompanyNetworkConfiguration_593312(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateCompanyNetworkConfiguration_593311(path: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593313 = header.getOrDefault("X-Amz-Signature")
  valid_593313 = validateParameter(valid_593313, JString, required = false,
                                 default = nil)
  if valid_593313 != nil:
    section.add "X-Amz-Signature", valid_593313
  var valid_593314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593314 = validateParameter(valid_593314, JString, required = false,
                                 default = nil)
  if valid_593314 != nil:
    section.add "X-Amz-Content-Sha256", valid_593314
  var valid_593315 = header.getOrDefault("X-Amz-Date")
  valid_593315 = validateParameter(valid_593315, JString, required = false,
                                 default = nil)
  if valid_593315 != nil:
    section.add "X-Amz-Date", valid_593315
  var valid_593316 = header.getOrDefault("X-Amz-Credential")
  valid_593316 = validateParameter(valid_593316, JString, required = false,
                                 default = nil)
  if valid_593316 != nil:
    section.add "X-Amz-Credential", valid_593316
  var valid_593317 = header.getOrDefault("X-Amz-Security-Token")
  valid_593317 = validateParameter(valid_593317, JString, required = false,
                                 default = nil)
  if valid_593317 != nil:
    section.add "X-Amz-Security-Token", valid_593317
  var valid_593318 = header.getOrDefault("X-Amz-Algorithm")
  valid_593318 = validateParameter(valid_593318, JString, required = false,
                                 default = nil)
  if valid_593318 != nil:
    section.add "X-Amz-Algorithm", valid_593318
  var valid_593319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593319 = validateParameter(valid_593319, JString, required = false,
                                 default = nil)
  if valid_593319 != nil:
    section.add "X-Amz-SignedHeaders", valid_593319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593321: Call_UpdateCompanyNetworkConfiguration_593310;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the company network configuration for the fleet.
  ## 
  let valid = call_593321.validator(path, query, header, formData, body)
  let scheme = call_593321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593321.url(scheme.get, call_593321.host, call_593321.base,
                         call_593321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593321, url, valid)

proc call*(call_593322: Call_UpdateCompanyNetworkConfiguration_593310;
          body: JsonNode): Recallable =
  ## updateCompanyNetworkConfiguration
  ## Updates the company network configuration for the fleet.
  ##   body: JObject (required)
  var body_593323 = newJObject()
  if body != nil:
    body_593323 = body
  result = call_593322.call(nil, nil, nil, nil, body_593323)

var updateCompanyNetworkConfiguration* = Call_UpdateCompanyNetworkConfiguration_593310(
    name: "updateCompanyNetworkConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/updateCompanyNetworkConfiguration",
    validator: validate_UpdateCompanyNetworkConfiguration_593311, base: "/",
    url: url_UpdateCompanyNetworkConfiguration_593312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevicePolicyConfiguration_593324 = ref object of OpenApiRestCall_592364
proc url_UpdateDevicePolicyConfiguration_593326(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDevicePolicyConfiguration_593325(path: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593327 = header.getOrDefault("X-Amz-Signature")
  valid_593327 = validateParameter(valid_593327, JString, required = false,
                                 default = nil)
  if valid_593327 != nil:
    section.add "X-Amz-Signature", valid_593327
  var valid_593328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593328 = validateParameter(valid_593328, JString, required = false,
                                 default = nil)
  if valid_593328 != nil:
    section.add "X-Amz-Content-Sha256", valid_593328
  var valid_593329 = header.getOrDefault("X-Amz-Date")
  valid_593329 = validateParameter(valid_593329, JString, required = false,
                                 default = nil)
  if valid_593329 != nil:
    section.add "X-Amz-Date", valid_593329
  var valid_593330 = header.getOrDefault("X-Amz-Credential")
  valid_593330 = validateParameter(valid_593330, JString, required = false,
                                 default = nil)
  if valid_593330 != nil:
    section.add "X-Amz-Credential", valid_593330
  var valid_593331 = header.getOrDefault("X-Amz-Security-Token")
  valid_593331 = validateParameter(valid_593331, JString, required = false,
                                 default = nil)
  if valid_593331 != nil:
    section.add "X-Amz-Security-Token", valid_593331
  var valid_593332 = header.getOrDefault("X-Amz-Algorithm")
  valid_593332 = validateParameter(valid_593332, JString, required = false,
                                 default = nil)
  if valid_593332 != nil:
    section.add "X-Amz-Algorithm", valid_593332
  var valid_593333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593333 = validateParameter(valid_593333, JString, required = false,
                                 default = nil)
  if valid_593333 != nil:
    section.add "X-Amz-SignedHeaders", valid_593333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593335: Call_UpdateDevicePolicyConfiguration_593324;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the device policy configuration for the fleet.
  ## 
  let valid = call_593335.validator(path, query, header, formData, body)
  let scheme = call_593335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593335.url(scheme.get, call_593335.host, call_593335.base,
                         call_593335.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593335, url, valid)

proc call*(call_593336: Call_UpdateDevicePolicyConfiguration_593324; body: JsonNode): Recallable =
  ## updateDevicePolicyConfiguration
  ## Updates the device policy configuration for the fleet.
  ##   body: JObject (required)
  var body_593337 = newJObject()
  if body != nil:
    body_593337 = body
  result = call_593336.call(nil, nil, nil, nil, body_593337)

var updateDevicePolicyConfiguration* = Call_UpdateDevicePolicyConfiguration_593324(
    name: "updateDevicePolicyConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/updateDevicePolicyConfiguration",
    validator: validate_UpdateDevicePolicyConfiguration_593325, base: "/",
    url: url_UpdateDevicePolicyConfiguration_593326,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainMetadata_593338 = ref object of OpenApiRestCall_592364
proc url_UpdateDomainMetadata_593340(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDomainMetadata_593339(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593341 = header.getOrDefault("X-Amz-Signature")
  valid_593341 = validateParameter(valid_593341, JString, required = false,
                                 default = nil)
  if valid_593341 != nil:
    section.add "X-Amz-Signature", valid_593341
  var valid_593342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593342 = validateParameter(valid_593342, JString, required = false,
                                 default = nil)
  if valid_593342 != nil:
    section.add "X-Amz-Content-Sha256", valid_593342
  var valid_593343 = header.getOrDefault("X-Amz-Date")
  valid_593343 = validateParameter(valid_593343, JString, required = false,
                                 default = nil)
  if valid_593343 != nil:
    section.add "X-Amz-Date", valid_593343
  var valid_593344 = header.getOrDefault("X-Amz-Credential")
  valid_593344 = validateParameter(valid_593344, JString, required = false,
                                 default = nil)
  if valid_593344 != nil:
    section.add "X-Amz-Credential", valid_593344
  var valid_593345 = header.getOrDefault("X-Amz-Security-Token")
  valid_593345 = validateParameter(valid_593345, JString, required = false,
                                 default = nil)
  if valid_593345 != nil:
    section.add "X-Amz-Security-Token", valid_593345
  var valid_593346 = header.getOrDefault("X-Amz-Algorithm")
  valid_593346 = validateParameter(valid_593346, JString, required = false,
                                 default = nil)
  if valid_593346 != nil:
    section.add "X-Amz-Algorithm", valid_593346
  var valid_593347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593347 = validateParameter(valid_593347, JString, required = false,
                                 default = nil)
  if valid_593347 != nil:
    section.add "X-Amz-SignedHeaders", valid_593347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593349: Call_UpdateDomainMetadata_593338; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates domain metadata, such as DisplayName.
  ## 
  let valid = call_593349.validator(path, query, header, formData, body)
  let scheme = call_593349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593349.url(scheme.get, call_593349.host, call_593349.base,
                         call_593349.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593349, url, valid)

proc call*(call_593350: Call_UpdateDomainMetadata_593338; body: JsonNode): Recallable =
  ## updateDomainMetadata
  ## Updates domain metadata, such as DisplayName.
  ##   body: JObject (required)
  var body_593351 = newJObject()
  if body != nil:
    body_593351 = body
  result = call_593350.call(nil, nil, nil, nil, body_593351)

var updateDomainMetadata* = Call_UpdateDomainMetadata_593338(
    name: "updateDomainMetadata", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/updateDomainMetadata",
    validator: validate_UpdateDomainMetadata_593339, base: "/",
    url: url_UpdateDomainMetadata_593340, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFleetMetadata_593352 = ref object of OpenApiRestCall_592364
proc url_UpdateFleetMetadata_593354(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateFleetMetadata_593353(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593355 = header.getOrDefault("X-Amz-Signature")
  valid_593355 = validateParameter(valid_593355, JString, required = false,
                                 default = nil)
  if valid_593355 != nil:
    section.add "X-Amz-Signature", valid_593355
  var valid_593356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593356 = validateParameter(valid_593356, JString, required = false,
                                 default = nil)
  if valid_593356 != nil:
    section.add "X-Amz-Content-Sha256", valid_593356
  var valid_593357 = header.getOrDefault("X-Amz-Date")
  valid_593357 = validateParameter(valid_593357, JString, required = false,
                                 default = nil)
  if valid_593357 != nil:
    section.add "X-Amz-Date", valid_593357
  var valid_593358 = header.getOrDefault("X-Amz-Credential")
  valid_593358 = validateParameter(valid_593358, JString, required = false,
                                 default = nil)
  if valid_593358 != nil:
    section.add "X-Amz-Credential", valid_593358
  var valid_593359 = header.getOrDefault("X-Amz-Security-Token")
  valid_593359 = validateParameter(valid_593359, JString, required = false,
                                 default = nil)
  if valid_593359 != nil:
    section.add "X-Amz-Security-Token", valid_593359
  var valid_593360 = header.getOrDefault("X-Amz-Algorithm")
  valid_593360 = validateParameter(valid_593360, JString, required = false,
                                 default = nil)
  if valid_593360 != nil:
    section.add "X-Amz-Algorithm", valid_593360
  var valid_593361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593361 = validateParameter(valid_593361, JString, required = false,
                                 default = nil)
  if valid_593361 != nil:
    section.add "X-Amz-SignedHeaders", valid_593361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593363: Call_UpdateFleetMetadata_593352; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates fleet metadata, such as DisplayName.
  ## 
  let valid = call_593363.validator(path, query, header, formData, body)
  let scheme = call_593363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593363.url(scheme.get, call_593363.host, call_593363.base,
                         call_593363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593363, url, valid)

proc call*(call_593364: Call_UpdateFleetMetadata_593352; body: JsonNode): Recallable =
  ## updateFleetMetadata
  ## Updates fleet metadata, such as DisplayName.
  ##   body: JObject (required)
  var body_593365 = newJObject()
  if body != nil:
    body_593365 = body
  result = call_593364.call(nil, nil, nil, nil, body_593365)

var updateFleetMetadata* = Call_UpdateFleetMetadata_593352(
    name: "updateFleetMetadata", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/UpdateFleetMetadata",
    validator: validate_UpdateFleetMetadata_593353, base: "/",
    url: url_UpdateFleetMetadata_593354, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIdentityProviderConfiguration_593366 = ref object of OpenApiRestCall_592364
proc url_UpdateIdentityProviderConfiguration_593368(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateIdentityProviderConfiguration_593367(path: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593369 = header.getOrDefault("X-Amz-Signature")
  valid_593369 = validateParameter(valid_593369, JString, required = false,
                                 default = nil)
  if valid_593369 != nil:
    section.add "X-Amz-Signature", valid_593369
  var valid_593370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593370 = validateParameter(valid_593370, JString, required = false,
                                 default = nil)
  if valid_593370 != nil:
    section.add "X-Amz-Content-Sha256", valid_593370
  var valid_593371 = header.getOrDefault("X-Amz-Date")
  valid_593371 = validateParameter(valid_593371, JString, required = false,
                                 default = nil)
  if valid_593371 != nil:
    section.add "X-Amz-Date", valid_593371
  var valid_593372 = header.getOrDefault("X-Amz-Credential")
  valid_593372 = validateParameter(valid_593372, JString, required = false,
                                 default = nil)
  if valid_593372 != nil:
    section.add "X-Amz-Credential", valid_593372
  var valid_593373 = header.getOrDefault("X-Amz-Security-Token")
  valid_593373 = validateParameter(valid_593373, JString, required = false,
                                 default = nil)
  if valid_593373 != nil:
    section.add "X-Amz-Security-Token", valid_593373
  var valid_593374 = header.getOrDefault("X-Amz-Algorithm")
  valid_593374 = validateParameter(valid_593374, JString, required = false,
                                 default = nil)
  if valid_593374 != nil:
    section.add "X-Amz-Algorithm", valid_593374
  var valid_593375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593375 = validateParameter(valid_593375, JString, required = false,
                                 default = nil)
  if valid_593375 != nil:
    section.add "X-Amz-SignedHeaders", valid_593375
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593377: Call_UpdateIdentityProviderConfiguration_593366;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the identity provider configuration for the fleet.
  ## 
  let valid = call_593377.validator(path, query, header, formData, body)
  let scheme = call_593377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593377.url(scheme.get, call_593377.host, call_593377.base,
                         call_593377.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593377, url, valid)

proc call*(call_593378: Call_UpdateIdentityProviderConfiguration_593366;
          body: JsonNode): Recallable =
  ## updateIdentityProviderConfiguration
  ## Updates the identity provider configuration for the fleet.
  ##   body: JObject (required)
  var body_593379 = newJObject()
  if body != nil:
    body_593379 = body
  result = call_593378.call(nil, nil, nil, nil, body_593379)

var updateIdentityProviderConfiguration* = Call_UpdateIdentityProviderConfiguration_593366(
    name: "updateIdentityProviderConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/updateIdentityProviderConfiguration",
    validator: validate_UpdateIdentityProviderConfiguration_593367, base: "/",
    url: url_UpdateIdentityProviderConfiguration_593368,
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
