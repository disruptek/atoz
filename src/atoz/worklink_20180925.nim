
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
  Call_AssociateDomain_610996 = ref object of OpenApiRestCall_610658
proc url_AssociateDomain_610998(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateDomain_610997(path: JsonNode; query: JsonNode;
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
  var valid_611110 = header.getOrDefault("X-Amz-Signature")
  valid_611110 = validateParameter(valid_611110, JString, required = false,
                                 default = nil)
  if valid_611110 != nil:
    section.add "X-Amz-Signature", valid_611110
  var valid_611111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611111 = validateParameter(valid_611111, JString, required = false,
                                 default = nil)
  if valid_611111 != nil:
    section.add "X-Amz-Content-Sha256", valid_611111
  var valid_611112 = header.getOrDefault("X-Amz-Date")
  valid_611112 = validateParameter(valid_611112, JString, required = false,
                                 default = nil)
  if valid_611112 != nil:
    section.add "X-Amz-Date", valid_611112
  var valid_611113 = header.getOrDefault("X-Amz-Credential")
  valid_611113 = validateParameter(valid_611113, JString, required = false,
                                 default = nil)
  if valid_611113 != nil:
    section.add "X-Amz-Credential", valid_611113
  var valid_611114 = header.getOrDefault("X-Amz-Security-Token")
  valid_611114 = validateParameter(valid_611114, JString, required = false,
                                 default = nil)
  if valid_611114 != nil:
    section.add "X-Amz-Security-Token", valid_611114
  var valid_611115 = header.getOrDefault("X-Amz-Algorithm")
  valid_611115 = validateParameter(valid_611115, JString, required = false,
                                 default = nil)
  if valid_611115 != nil:
    section.add "X-Amz-Algorithm", valid_611115
  var valid_611116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611116 = validateParameter(valid_611116, JString, required = false,
                                 default = nil)
  if valid_611116 != nil:
    section.add "X-Amz-SignedHeaders", valid_611116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611140: Call_AssociateDomain_610996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Specifies a domain to be associated to Amazon WorkLink.
  ## 
  let valid = call_611140.validator(path, query, header, formData, body)
  let scheme = call_611140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611140.url(scheme.get, call_611140.host, call_611140.base,
                         call_611140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611140, url, valid)

proc call*(call_611211: Call_AssociateDomain_610996; body: JsonNode): Recallable =
  ## associateDomain
  ## Specifies a domain to be associated to Amazon WorkLink.
  ##   body: JObject (required)
  var body_611212 = newJObject()
  if body != nil:
    body_611212 = body
  result = call_611211.call(nil, nil, nil, nil, body_611212)

var associateDomain* = Call_AssociateDomain_610996(name: "associateDomain",
    meth: HttpMethod.HttpPost, host: "worklink.amazonaws.com",
    route: "/associateDomain", validator: validate_AssociateDomain_610997,
    base: "/", url: url_AssociateDomain_610998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateWebsiteAuthorizationProvider_611251 = ref object of OpenApiRestCall_610658
proc url_AssociateWebsiteAuthorizationProvider_611253(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateWebsiteAuthorizationProvider_611252(path: JsonNode;
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
  var valid_611254 = header.getOrDefault("X-Amz-Signature")
  valid_611254 = validateParameter(valid_611254, JString, required = false,
                                 default = nil)
  if valid_611254 != nil:
    section.add "X-Amz-Signature", valid_611254
  var valid_611255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611255 = validateParameter(valid_611255, JString, required = false,
                                 default = nil)
  if valid_611255 != nil:
    section.add "X-Amz-Content-Sha256", valid_611255
  var valid_611256 = header.getOrDefault("X-Amz-Date")
  valid_611256 = validateParameter(valid_611256, JString, required = false,
                                 default = nil)
  if valid_611256 != nil:
    section.add "X-Amz-Date", valid_611256
  var valid_611257 = header.getOrDefault("X-Amz-Credential")
  valid_611257 = validateParameter(valid_611257, JString, required = false,
                                 default = nil)
  if valid_611257 != nil:
    section.add "X-Amz-Credential", valid_611257
  var valid_611258 = header.getOrDefault("X-Amz-Security-Token")
  valid_611258 = validateParameter(valid_611258, JString, required = false,
                                 default = nil)
  if valid_611258 != nil:
    section.add "X-Amz-Security-Token", valid_611258
  var valid_611259 = header.getOrDefault("X-Amz-Algorithm")
  valid_611259 = validateParameter(valid_611259, JString, required = false,
                                 default = nil)
  if valid_611259 != nil:
    section.add "X-Amz-Algorithm", valid_611259
  var valid_611260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611260 = validateParameter(valid_611260, JString, required = false,
                                 default = nil)
  if valid_611260 != nil:
    section.add "X-Amz-SignedHeaders", valid_611260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611262: Call_AssociateWebsiteAuthorizationProvider_611251;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a website authorization provider with a specified fleet. This is used to authorize users against associated websites in the company network.
  ## 
  let valid = call_611262.validator(path, query, header, formData, body)
  let scheme = call_611262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611262.url(scheme.get, call_611262.host, call_611262.base,
                         call_611262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611262, url, valid)

proc call*(call_611263: Call_AssociateWebsiteAuthorizationProvider_611251;
          body: JsonNode): Recallable =
  ## associateWebsiteAuthorizationProvider
  ## Associates a website authorization provider with a specified fleet. This is used to authorize users against associated websites in the company network.
  ##   body: JObject (required)
  var body_611264 = newJObject()
  if body != nil:
    body_611264 = body
  result = call_611263.call(nil, nil, nil, nil, body_611264)

var associateWebsiteAuthorizationProvider* = Call_AssociateWebsiteAuthorizationProvider_611251(
    name: "associateWebsiteAuthorizationProvider", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com",
    route: "/associateWebsiteAuthorizationProvider",
    validator: validate_AssociateWebsiteAuthorizationProvider_611252, base: "/",
    url: url_AssociateWebsiteAuthorizationProvider_611253,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateWebsiteCertificateAuthority_611265 = ref object of OpenApiRestCall_610658
proc url_AssociateWebsiteCertificateAuthority_611267(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateWebsiteCertificateAuthority_611266(path: JsonNode;
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
  var valid_611268 = header.getOrDefault("X-Amz-Signature")
  valid_611268 = validateParameter(valid_611268, JString, required = false,
                                 default = nil)
  if valid_611268 != nil:
    section.add "X-Amz-Signature", valid_611268
  var valid_611269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611269 = validateParameter(valid_611269, JString, required = false,
                                 default = nil)
  if valid_611269 != nil:
    section.add "X-Amz-Content-Sha256", valid_611269
  var valid_611270 = header.getOrDefault("X-Amz-Date")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "X-Amz-Date", valid_611270
  var valid_611271 = header.getOrDefault("X-Amz-Credential")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Credential", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-Security-Token")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Security-Token", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Algorithm")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Algorithm", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-SignedHeaders", valid_611274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611276: Call_AssociateWebsiteCertificateAuthority_611265;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Imports the root certificate of a certificate authority (CA) used to obtain TLS certificates used by associated websites within the company network.
  ## 
  let valid = call_611276.validator(path, query, header, formData, body)
  let scheme = call_611276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611276.url(scheme.get, call_611276.host, call_611276.base,
                         call_611276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611276, url, valid)

proc call*(call_611277: Call_AssociateWebsiteCertificateAuthority_611265;
          body: JsonNode): Recallable =
  ## associateWebsiteCertificateAuthority
  ## Imports the root certificate of a certificate authority (CA) used to obtain TLS certificates used by associated websites within the company network.
  ##   body: JObject (required)
  var body_611278 = newJObject()
  if body != nil:
    body_611278 = body
  result = call_611277.call(nil, nil, nil, nil, body_611278)

var associateWebsiteCertificateAuthority* = Call_AssociateWebsiteCertificateAuthority_611265(
    name: "associateWebsiteCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com",
    route: "/associateWebsiteCertificateAuthority",
    validator: validate_AssociateWebsiteCertificateAuthority_611266, base: "/",
    url: url_AssociateWebsiteCertificateAuthority_611267,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFleet_611279 = ref object of OpenApiRestCall_610658
proc url_CreateFleet_611281(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFleet_611280(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611282 = header.getOrDefault("X-Amz-Signature")
  valid_611282 = validateParameter(valid_611282, JString, required = false,
                                 default = nil)
  if valid_611282 != nil:
    section.add "X-Amz-Signature", valid_611282
  var valid_611283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611283 = validateParameter(valid_611283, JString, required = false,
                                 default = nil)
  if valid_611283 != nil:
    section.add "X-Amz-Content-Sha256", valid_611283
  var valid_611284 = header.getOrDefault("X-Amz-Date")
  valid_611284 = validateParameter(valid_611284, JString, required = false,
                                 default = nil)
  if valid_611284 != nil:
    section.add "X-Amz-Date", valid_611284
  var valid_611285 = header.getOrDefault("X-Amz-Credential")
  valid_611285 = validateParameter(valid_611285, JString, required = false,
                                 default = nil)
  if valid_611285 != nil:
    section.add "X-Amz-Credential", valid_611285
  var valid_611286 = header.getOrDefault("X-Amz-Security-Token")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-Security-Token", valid_611286
  var valid_611287 = header.getOrDefault("X-Amz-Algorithm")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Algorithm", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-SignedHeaders", valid_611288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611290: Call_CreateFleet_611279; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a fleet. A fleet consists of resources and the configuration that delivers associated websites to authorized users who download and set up the Amazon WorkLink app.
  ## 
  let valid = call_611290.validator(path, query, header, formData, body)
  let scheme = call_611290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611290.url(scheme.get, call_611290.host, call_611290.base,
                         call_611290.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611290, url, valid)

proc call*(call_611291: Call_CreateFleet_611279; body: JsonNode): Recallable =
  ## createFleet
  ## Creates a fleet. A fleet consists of resources and the configuration that delivers associated websites to authorized users who download and set up the Amazon WorkLink app.
  ##   body: JObject (required)
  var body_611292 = newJObject()
  if body != nil:
    body_611292 = body
  result = call_611291.call(nil, nil, nil, nil, body_611292)

var createFleet* = Call_CreateFleet_611279(name: "createFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "worklink.amazonaws.com",
                                        route: "/createFleet",
                                        validator: validate_CreateFleet_611280,
                                        base: "/", url: url_CreateFleet_611281,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFleet_611293 = ref object of OpenApiRestCall_610658
proc url_DeleteFleet_611295(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteFleet_611294(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611296 = header.getOrDefault("X-Amz-Signature")
  valid_611296 = validateParameter(valid_611296, JString, required = false,
                                 default = nil)
  if valid_611296 != nil:
    section.add "X-Amz-Signature", valid_611296
  var valid_611297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611297 = validateParameter(valid_611297, JString, required = false,
                                 default = nil)
  if valid_611297 != nil:
    section.add "X-Amz-Content-Sha256", valid_611297
  var valid_611298 = header.getOrDefault("X-Amz-Date")
  valid_611298 = validateParameter(valid_611298, JString, required = false,
                                 default = nil)
  if valid_611298 != nil:
    section.add "X-Amz-Date", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-Credential")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-Credential", valid_611299
  var valid_611300 = header.getOrDefault("X-Amz-Security-Token")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-Security-Token", valid_611300
  var valid_611301 = header.getOrDefault("X-Amz-Algorithm")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-Algorithm", valid_611301
  var valid_611302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-SignedHeaders", valid_611302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611304: Call_DeleteFleet_611293; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a fleet. Prevents users from accessing previously associated websites. 
  ## 
  let valid = call_611304.validator(path, query, header, formData, body)
  let scheme = call_611304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611304.url(scheme.get, call_611304.host, call_611304.base,
                         call_611304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611304, url, valid)

proc call*(call_611305: Call_DeleteFleet_611293; body: JsonNode): Recallable =
  ## deleteFleet
  ## Deletes a fleet. Prevents users from accessing previously associated websites. 
  ##   body: JObject (required)
  var body_611306 = newJObject()
  if body != nil:
    body_611306 = body
  result = call_611305.call(nil, nil, nil, nil, body_611306)

var deleteFleet* = Call_DeleteFleet_611293(name: "deleteFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "worklink.amazonaws.com",
                                        route: "/deleteFleet",
                                        validator: validate_DeleteFleet_611294,
                                        base: "/", url: url_DeleteFleet_611295,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAuditStreamConfiguration_611307 = ref object of OpenApiRestCall_610658
proc url_DescribeAuditStreamConfiguration_611309(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAuditStreamConfiguration_611308(path: JsonNode;
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
  var valid_611310 = header.getOrDefault("X-Amz-Signature")
  valid_611310 = validateParameter(valid_611310, JString, required = false,
                                 default = nil)
  if valid_611310 != nil:
    section.add "X-Amz-Signature", valid_611310
  var valid_611311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611311 = validateParameter(valid_611311, JString, required = false,
                                 default = nil)
  if valid_611311 != nil:
    section.add "X-Amz-Content-Sha256", valid_611311
  var valid_611312 = header.getOrDefault("X-Amz-Date")
  valid_611312 = validateParameter(valid_611312, JString, required = false,
                                 default = nil)
  if valid_611312 != nil:
    section.add "X-Amz-Date", valid_611312
  var valid_611313 = header.getOrDefault("X-Amz-Credential")
  valid_611313 = validateParameter(valid_611313, JString, required = false,
                                 default = nil)
  if valid_611313 != nil:
    section.add "X-Amz-Credential", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-Security-Token")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-Security-Token", valid_611314
  var valid_611315 = header.getOrDefault("X-Amz-Algorithm")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Algorithm", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-SignedHeaders", valid_611316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611318: Call_DescribeAuditStreamConfiguration_611307;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration for delivering audit streams to the customer account.
  ## 
  let valid = call_611318.validator(path, query, header, formData, body)
  let scheme = call_611318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611318.url(scheme.get, call_611318.host, call_611318.base,
                         call_611318.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611318, url, valid)

proc call*(call_611319: Call_DescribeAuditStreamConfiguration_611307;
          body: JsonNode): Recallable =
  ## describeAuditStreamConfiguration
  ## Describes the configuration for delivering audit streams to the customer account.
  ##   body: JObject (required)
  var body_611320 = newJObject()
  if body != nil:
    body_611320 = body
  result = call_611319.call(nil, nil, nil, nil, body_611320)

var describeAuditStreamConfiguration* = Call_DescribeAuditStreamConfiguration_611307(
    name: "describeAuditStreamConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/describeAuditStreamConfiguration",
    validator: validate_DescribeAuditStreamConfiguration_611308, base: "/",
    url: url_DescribeAuditStreamConfiguration_611309,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCompanyNetworkConfiguration_611321 = ref object of OpenApiRestCall_610658
proc url_DescribeCompanyNetworkConfiguration_611323(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCompanyNetworkConfiguration_611322(path: JsonNode;
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
  var valid_611324 = header.getOrDefault("X-Amz-Signature")
  valid_611324 = validateParameter(valid_611324, JString, required = false,
                                 default = nil)
  if valid_611324 != nil:
    section.add "X-Amz-Signature", valid_611324
  var valid_611325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611325 = validateParameter(valid_611325, JString, required = false,
                                 default = nil)
  if valid_611325 != nil:
    section.add "X-Amz-Content-Sha256", valid_611325
  var valid_611326 = header.getOrDefault("X-Amz-Date")
  valid_611326 = validateParameter(valid_611326, JString, required = false,
                                 default = nil)
  if valid_611326 != nil:
    section.add "X-Amz-Date", valid_611326
  var valid_611327 = header.getOrDefault("X-Amz-Credential")
  valid_611327 = validateParameter(valid_611327, JString, required = false,
                                 default = nil)
  if valid_611327 != nil:
    section.add "X-Amz-Credential", valid_611327
  var valid_611328 = header.getOrDefault("X-Amz-Security-Token")
  valid_611328 = validateParameter(valid_611328, JString, required = false,
                                 default = nil)
  if valid_611328 != nil:
    section.add "X-Amz-Security-Token", valid_611328
  var valid_611329 = header.getOrDefault("X-Amz-Algorithm")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "X-Amz-Algorithm", valid_611329
  var valid_611330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "X-Amz-SignedHeaders", valid_611330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611332: Call_DescribeCompanyNetworkConfiguration_611321;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the networking configuration to access the internal websites associated with the specified fleet.
  ## 
  let valid = call_611332.validator(path, query, header, formData, body)
  let scheme = call_611332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611332.url(scheme.get, call_611332.host, call_611332.base,
                         call_611332.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611332, url, valid)

proc call*(call_611333: Call_DescribeCompanyNetworkConfiguration_611321;
          body: JsonNode): Recallable =
  ## describeCompanyNetworkConfiguration
  ## Describes the networking configuration to access the internal websites associated with the specified fleet.
  ##   body: JObject (required)
  var body_611334 = newJObject()
  if body != nil:
    body_611334 = body
  result = call_611333.call(nil, nil, nil, nil, body_611334)

var describeCompanyNetworkConfiguration* = Call_DescribeCompanyNetworkConfiguration_611321(
    name: "describeCompanyNetworkConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/describeCompanyNetworkConfiguration",
    validator: validate_DescribeCompanyNetworkConfiguration_611322, base: "/",
    url: url_DescribeCompanyNetworkConfiguration_611323,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDevice_611335 = ref object of OpenApiRestCall_610658
proc url_DescribeDevice_611337(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDevice_611336(path: JsonNode; query: JsonNode;
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
  var valid_611338 = header.getOrDefault("X-Amz-Signature")
  valid_611338 = validateParameter(valid_611338, JString, required = false,
                                 default = nil)
  if valid_611338 != nil:
    section.add "X-Amz-Signature", valid_611338
  var valid_611339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611339 = validateParameter(valid_611339, JString, required = false,
                                 default = nil)
  if valid_611339 != nil:
    section.add "X-Amz-Content-Sha256", valid_611339
  var valid_611340 = header.getOrDefault("X-Amz-Date")
  valid_611340 = validateParameter(valid_611340, JString, required = false,
                                 default = nil)
  if valid_611340 != nil:
    section.add "X-Amz-Date", valid_611340
  var valid_611341 = header.getOrDefault("X-Amz-Credential")
  valid_611341 = validateParameter(valid_611341, JString, required = false,
                                 default = nil)
  if valid_611341 != nil:
    section.add "X-Amz-Credential", valid_611341
  var valid_611342 = header.getOrDefault("X-Amz-Security-Token")
  valid_611342 = validateParameter(valid_611342, JString, required = false,
                                 default = nil)
  if valid_611342 != nil:
    section.add "X-Amz-Security-Token", valid_611342
  var valid_611343 = header.getOrDefault("X-Amz-Algorithm")
  valid_611343 = validateParameter(valid_611343, JString, required = false,
                                 default = nil)
  if valid_611343 != nil:
    section.add "X-Amz-Algorithm", valid_611343
  var valid_611344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "X-Amz-SignedHeaders", valid_611344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611346: Call_DescribeDevice_611335; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about a user's device.
  ## 
  let valid = call_611346.validator(path, query, header, formData, body)
  let scheme = call_611346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611346.url(scheme.get, call_611346.host, call_611346.base,
                         call_611346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611346, url, valid)

proc call*(call_611347: Call_DescribeDevice_611335; body: JsonNode): Recallable =
  ## describeDevice
  ## Provides information about a user's device.
  ##   body: JObject (required)
  var body_611348 = newJObject()
  if body != nil:
    body_611348 = body
  result = call_611347.call(nil, nil, nil, nil, body_611348)

var describeDevice* = Call_DescribeDevice_611335(name: "describeDevice",
    meth: HttpMethod.HttpPost, host: "worklink.amazonaws.com",
    route: "/describeDevice", validator: validate_DescribeDevice_611336, base: "/",
    url: url_DescribeDevice_611337, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDevicePolicyConfiguration_611349 = ref object of OpenApiRestCall_610658
proc url_DescribeDevicePolicyConfiguration_611351(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDevicePolicyConfiguration_611350(path: JsonNode;
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
  var valid_611352 = header.getOrDefault("X-Amz-Signature")
  valid_611352 = validateParameter(valid_611352, JString, required = false,
                                 default = nil)
  if valid_611352 != nil:
    section.add "X-Amz-Signature", valid_611352
  var valid_611353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "X-Amz-Content-Sha256", valid_611353
  var valid_611354 = header.getOrDefault("X-Amz-Date")
  valid_611354 = validateParameter(valid_611354, JString, required = false,
                                 default = nil)
  if valid_611354 != nil:
    section.add "X-Amz-Date", valid_611354
  var valid_611355 = header.getOrDefault("X-Amz-Credential")
  valid_611355 = validateParameter(valid_611355, JString, required = false,
                                 default = nil)
  if valid_611355 != nil:
    section.add "X-Amz-Credential", valid_611355
  var valid_611356 = header.getOrDefault("X-Amz-Security-Token")
  valid_611356 = validateParameter(valid_611356, JString, required = false,
                                 default = nil)
  if valid_611356 != nil:
    section.add "X-Amz-Security-Token", valid_611356
  var valid_611357 = header.getOrDefault("X-Amz-Algorithm")
  valid_611357 = validateParameter(valid_611357, JString, required = false,
                                 default = nil)
  if valid_611357 != nil:
    section.add "X-Amz-Algorithm", valid_611357
  var valid_611358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611358 = validateParameter(valid_611358, JString, required = false,
                                 default = nil)
  if valid_611358 != nil:
    section.add "X-Amz-SignedHeaders", valid_611358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611360: Call_DescribeDevicePolicyConfiguration_611349;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the device policy configuration for the specified fleet.
  ## 
  let valid = call_611360.validator(path, query, header, formData, body)
  let scheme = call_611360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611360.url(scheme.get, call_611360.host, call_611360.base,
                         call_611360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611360, url, valid)

proc call*(call_611361: Call_DescribeDevicePolicyConfiguration_611349;
          body: JsonNode): Recallable =
  ## describeDevicePolicyConfiguration
  ## Describes the device policy configuration for the specified fleet.
  ##   body: JObject (required)
  var body_611362 = newJObject()
  if body != nil:
    body_611362 = body
  result = call_611361.call(nil, nil, nil, nil, body_611362)

var describeDevicePolicyConfiguration* = Call_DescribeDevicePolicyConfiguration_611349(
    name: "describeDevicePolicyConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/describeDevicePolicyConfiguration",
    validator: validate_DescribeDevicePolicyConfiguration_611350, base: "/",
    url: url_DescribeDevicePolicyConfiguration_611351,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDomain_611363 = ref object of OpenApiRestCall_610658
proc url_DescribeDomain_611365(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDomain_611364(path: JsonNode; query: JsonNode;
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
  var valid_611366 = header.getOrDefault("X-Amz-Signature")
  valid_611366 = validateParameter(valid_611366, JString, required = false,
                                 default = nil)
  if valid_611366 != nil:
    section.add "X-Amz-Signature", valid_611366
  var valid_611367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611367 = validateParameter(valid_611367, JString, required = false,
                                 default = nil)
  if valid_611367 != nil:
    section.add "X-Amz-Content-Sha256", valid_611367
  var valid_611368 = header.getOrDefault("X-Amz-Date")
  valid_611368 = validateParameter(valid_611368, JString, required = false,
                                 default = nil)
  if valid_611368 != nil:
    section.add "X-Amz-Date", valid_611368
  var valid_611369 = header.getOrDefault("X-Amz-Credential")
  valid_611369 = validateParameter(valid_611369, JString, required = false,
                                 default = nil)
  if valid_611369 != nil:
    section.add "X-Amz-Credential", valid_611369
  var valid_611370 = header.getOrDefault("X-Amz-Security-Token")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "X-Amz-Security-Token", valid_611370
  var valid_611371 = header.getOrDefault("X-Amz-Algorithm")
  valid_611371 = validateParameter(valid_611371, JString, required = false,
                                 default = nil)
  if valid_611371 != nil:
    section.add "X-Amz-Algorithm", valid_611371
  var valid_611372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611372 = validateParameter(valid_611372, JString, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "X-Amz-SignedHeaders", valid_611372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611374: Call_DescribeDomain_611363; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about the domain.
  ## 
  let valid = call_611374.validator(path, query, header, formData, body)
  let scheme = call_611374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611374.url(scheme.get, call_611374.host, call_611374.base,
                         call_611374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611374, url, valid)

proc call*(call_611375: Call_DescribeDomain_611363; body: JsonNode): Recallable =
  ## describeDomain
  ## Provides information about the domain.
  ##   body: JObject (required)
  var body_611376 = newJObject()
  if body != nil:
    body_611376 = body
  result = call_611375.call(nil, nil, nil, nil, body_611376)

var describeDomain* = Call_DescribeDomain_611363(name: "describeDomain",
    meth: HttpMethod.HttpPost, host: "worklink.amazonaws.com",
    route: "/describeDomain", validator: validate_DescribeDomain_611364, base: "/",
    url: url_DescribeDomain_611365, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFleetMetadata_611377 = ref object of OpenApiRestCall_610658
proc url_DescribeFleetMetadata_611379(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeFleetMetadata_611378(path: JsonNode; query: JsonNode;
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
  var valid_611380 = header.getOrDefault("X-Amz-Signature")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "X-Amz-Signature", valid_611380
  var valid_611381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611381 = validateParameter(valid_611381, JString, required = false,
                                 default = nil)
  if valid_611381 != nil:
    section.add "X-Amz-Content-Sha256", valid_611381
  var valid_611382 = header.getOrDefault("X-Amz-Date")
  valid_611382 = validateParameter(valid_611382, JString, required = false,
                                 default = nil)
  if valid_611382 != nil:
    section.add "X-Amz-Date", valid_611382
  var valid_611383 = header.getOrDefault("X-Amz-Credential")
  valid_611383 = validateParameter(valid_611383, JString, required = false,
                                 default = nil)
  if valid_611383 != nil:
    section.add "X-Amz-Credential", valid_611383
  var valid_611384 = header.getOrDefault("X-Amz-Security-Token")
  valid_611384 = validateParameter(valid_611384, JString, required = false,
                                 default = nil)
  if valid_611384 != nil:
    section.add "X-Amz-Security-Token", valid_611384
  var valid_611385 = header.getOrDefault("X-Amz-Algorithm")
  valid_611385 = validateParameter(valid_611385, JString, required = false,
                                 default = nil)
  if valid_611385 != nil:
    section.add "X-Amz-Algorithm", valid_611385
  var valid_611386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611386 = validateParameter(valid_611386, JString, required = false,
                                 default = nil)
  if valid_611386 != nil:
    section.add "X-Amz-SignedHeaders", valid_611386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611388: Call_DescribeFleetMetadata_611377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides basic information for the specified fleet, excluding identity provider, networking, and device configuration details.
  ## 
  let valid = call_611388.validator(path, query, header, formData, body)
  let scheme = call_611388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611388.url(scheme.get, call_611388.host, call_611388.base,
                         call_611388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611388, url, valid)

proc call*(call_611389: Call_DescribeFleetMetadata_611377; body: JsonNode): Recallable =
  ## describeFleetMetadata
  ## Provides basic information for the specified fleet, excluding identity provider, networking, and device configuration details.
  ##   body: JObject (required)
  var body_611390 = newJObject()
  if body != nil:
    body_611390 = body
  result = call_611389.call(nil, nil, nil, nil, body_611390)

var describeFleetMetadata* = Call_DescribeFleetMetadata_611377(
    name: "describeFleetMetadata", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/describeFleetMetadata",
    validator: validate_DescribeFleetMetadata_611378, base: "/",
    url: url_DescribeFleetMetadata_611379, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentityProviderConfiguration_611391 = ref object of OpenApiRestCall_610658
proc url_DescribeIdentityProviderConfiguration_611393(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeIdentityProviderConfiguration_611392(path: JsonNode;
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
  var valid_611394 = header.getOrDefault("X-Amz-Signature")
  valid_611394 = validateParameter(valid_611394, JString, required = false,
                                 default = nil)
  if valid_611394 != nil:
    section.add "X-Amz-Signature", valid_611394
  var valid_611395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611395 = validateParameter(valid_611395, JString, required = false,
                                 default = nil)
  if valid_611395 != nil:
    section.add "X-Amz-Content-Sha256", valid_611395
  var valid_611396 = header.getOrDefault("X-Amz-Date")
  valid_611396 = validateParameter(valid_611396, JString, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "X-Amz-Date", valid_611396
  var valid_611397 = header.getOrDefault("X-Amz-Credential")
  valid_611397 = validateParameter(valid_611397, JString, required = false,
                                 default = nil)
  if valid_611397 != nil:
    section.add "X-Amz-Credential", valid_611397
  var valid_611398 = header.getOrDefault("X-Amz-Security-Token")
  valid_611398 = validateParameter(valid_611398, JString, required = false,
                                 default = nil)
  if valid_611398 != nil:
    section.add "X-Amz-Security-Token", valid_611398
  var valid_611399 = header.getOrDefault("X-Amz-Algorithm")
  valid_611399 = validateParameter(valid_611399, JString, required = false,
                                 default = nil)
  if valid_611399 != nil:
    section.add "X-Amz-Algorithm", valid_611399
  var valid_611400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611400 = validateParameter(valid_611400, JString, required = false,
                                 default = nil)
  if valid_611400 != nil:
    section.add "X-Amz-SignedHeaders", valid_611400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611402: Call_DescribeIdentityProviderConfiguration_611391;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the identity provider configuration of the specified fleet.
  ## 
  let valid = call_611402.validator(path, query, header, formData, body)
  let scheme = call_611402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611402.url(scheme.get, call_611402.host, call_611402.base,
                         call_611402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611402, url, valid)

proc call*(call_611403: Call_DescribeIdentityProviderConfiguration_611391;
          body: JsonNode): Recallable =
  ## describeIdentityProviderConfiguration
  ## Describes the identity provider configuration of the specified fleet.
  ##   body: JObject (required)
  var body_611404 = newJObject()
  if body != nil:
    body_611404 = body
  result = call_611403.call(nil, nil, nil, nil, body_611404)

var describeIdentityProviderConfiguration* = Call_DescribeIdentityProviderConfiguration_611391(
    name: "describeIdentityProviderConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com",
    route: "/describeIdentityProviderConfiguration",
    validator: validate_DescribeIdentityProviderConfiguration_611392, base: "/",
    url: url_DescribeIdentityProviderConfiguration_611393,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWebsiteCertificateAuthority_611405 = ref object of OpenApiRestCall_610658
proc url_DescribeWebsiteCertificateAuthority_611407(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeWebsiteCertificateAuthority_611406(path: JsonNode;
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
  var valid_611408 = header.getOrDefault("X-Amz-Signature")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "X-Amz-Signature", valid_611408
  var valid_611409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "X-Amz-Content-Sha256", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-Date")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-Date", valid_611410
  var valid_611411 = header.getOrDefault("X-Amz-Credential")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "X-Amz-Credential", valid_611411
  var valid_611412 = header.getOrDefault("X-Amz-Security-Token")
  valid_611412 = validateParameter(valid_611412, JString, required = false,
                                 default = nil)
  if valid_611412 != nil:
    section.add "X-Amz-Security-Token", valid_611412
  var valid_611413 = header.getOrDefault("X-Amz-Algorithm")
  valid_611413 = validateParameter(valid_611413, JString, required = false,
                                 default = nil)
  if valid_611413 != nil:
    section.add "X-Amz-Algorithm", valid_611413
  var valid_611414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611414 = validateParameter(valid_611414, JString, required = false,
                                 default = nil)
  if valid_611414 != nil:
    section.add "X-Amz-SignedHeaders", valid_611414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611416: Call_DescribeWebsiteCertificateAuthority_611405;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Provides information about the certificate authority.
  ## 
  let valid = call_611416.validator(path, query, header, formData, body)
  let scheme = call_611416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611416.url(scheme.get, call_611416.host, call_611416.base,
                         call_611416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611416, url, valid)

proc call*(call_611417: Call_DescribeWebsiteCertificateAuthority_611405;
          body: JsonNode): Recallable =
  ## describeWebsiteCertificateAuthority
  ## Provides information about the certificate authority.
  ##   body: JObject (required)
  var body_611418 = newJObject()
  if body != nil:
    body_611418 = body
  result = call_611417.call(nil, nil, nil, nil, body_611418)

var describeWebsiteCertificateAuthority* = Call_DescribeWebsiteCertificateAuthority_611405(
    name: "describeWebsiteCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/describeWebsiteCertificateAuthority",
    validator: validate_DescribeWebsiteCertificateAuthority_611406, base: "/",
    url: url_DescribeWebsiteCertificateAuthority_611407,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateDomain_611419 = ref object of OpenApiRestCall_610658
proc url_DisassociateDomain_611421(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateDomain_611420(path: JsonNode; query: JsonNode;
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
  var valid_611422 = header.getOrDefault("X-Amz-Signature")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "X-Amz-Signature", valid_611422
  var valid_611423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "X-Amz-Content-Sha256", valid_611423
  var valid_611424 = header.getOrDefault("X-Amz-Date")
  valid_611424 = validateParameter(valid_611424, JString, required = false,
                                 default = nil)
  if valid_611424 != nil:
    section.add "X-Amz-Date", valid_611424
  var valid_611425 = header.getOrDefault("X-Amz-Credential")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "X-Amz-Credential", valid_611425
  var valid_611426 = header.getOrDefault("X-Amz-Security-Token")
  valid_611426 = validateParameter(valid_611426, JString, required = false,
                                 default = nil)
  if valid_611426 != nil:
    section.add "X-Amz-Security-Token", valid_611426
  var valid_611427 = header.getOrDefault("X-Amz-Algorithm")
  valid_611427 = validateParameter(valid_611427, JString, required = false,
                                 default = nil)
  if valid_611427 != nil:
    section.add "X-Amz-Algorithm", valid_611427
  var valid_611428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611428 = validateParameter(valid_611428, JString, required = false,
                                 default = nil)
  if valid_611428 != nil:
    section.add "X-Amz-SignedHeaders", valid_611428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611430: Call_DisassociateDomain_611419; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a domain from Amazon WorkLink. End users lose the ability to access the domain with Amazon WorkLink. 
  ## 
  let valid = call_611430.validator(path, query, header, formData, body)
  let scheme = call_611430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611430.url(scheme.get, call_611430.host, call_611430.base,
                         call_611430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611430, url, valid)

proc call*(call_611431: Call_DisassociateDomain_611419; body: JsonNode): Recallable =
  ## disassociateDomain
  ## Disassociates a domain from Amazon WorkLink. End users lose the ability to access the domain with Amazon WorkLink. 
  ##   body: JObject (required)
  var body_611432 = newJObject()
  if body != nil:
    body_611432 = body
  result = call_611431.call(nil, nil, nil, nil, body_611432)

var disassociateDomain* = Call_DisassociateDomain_611419(
    name: "disassociateDomain", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/disassociateDomain",
    validator: validate_DisassociateDomain_611420, base: "/",
    url: url_DisassociateDomain_611421, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateWebsiteAuthorizationProvider_611433 = ref object of OpenApiRestCall_610658
proc url_DisassociateWebsiteAuthorizationProvider_611435(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateWebsiteAuthorizationProvider_611434(path: JsonNode;
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
  var valid_611436 = header.getOrDefault("X-Amz-Signature")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Signature", valid_611436
  var valid_611437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-Content-Sha256", valid_611437
  var valid_611438 = header.getOrDefault("X-Amz-Date")
  valid_611438 = validateParameter(valid_611438, JString, required = false,
                                 default = nil)
  if valid_611438 != nil:
    section.add "X-Amz-Date", valid_611438
  var valid_611439 = header.getOrDefault("X-Amz-Credential")
  valid_611439 = validateParameter(valid_611439, JString, required = false,
                                 default = nil)
  if valid_611439 != nil:
    section.add "X-Amz-Credential", valid_611439
  var valid_611440 = header.getOrDefault("X-Amz-Security-Token")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "X-Amz-Security-Token", valid_611440
  var valid_611441 = header.getOrDefault("X-Amz-Algorithm")
  valid_611441 = validateParameter(valid_611441, JString, required = false,
                                 default = nil)
  if valid_611441 != nil:
    section.add "X-Amz-Algorithm", valid_611441
  var valid_611442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611442 = validateParameter(valid_611442, JString, required = false,
                                 default = nil)
  if valid_611442 != nil:
    section.add "X-Amz-SignedHeaders", valid_611442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611444: Call_DisassociateWebsiteAuthorizationProvider_611433;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a website authorization provider from a specified fleet. After the disassociation, users can't load any associated websites that require this authorization provider.
  ## 
  let valid = call_611444.validator(path, query, header, formData, body)
  let scheme = call_611444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611444.url(scheme.get, call_611444.host, call_611444.base,
                         call_611444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611444, url, valid)

proc call*(call_611445: Call_DisassociateWebsiteAuthorizationProvider_611433;
          body: JsonNode): Recallable =
  ## disassociateWebsiteAuthorizationProvider
  ## Disassociates a website authorization provider from a specified fleet. After the disassociation, users can't load any associated websites that require this authorization provider.
  ##   body: JObject (required)
  var body_611446 = newJObject()
  if body != nil:
    body_611446 = body
  result = call_611445.call(nil, nil, nil, nil, body_611446)

var disassociateWebsiteAuthorizationProvider* = Call_DisassociateWebsiteAuthorizationProvider_611433(
    name: "disassociateWebsiteAuthorizationProvider", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com",
    route: "/disassociateWebsiteAuthorizationProvider",
    validator: validate_DisassociateWebsiteAuthorizationProvider_611434,
    base: "/", url: url_DisassociateWebsiteAuthorizationProvider_611435,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateWebsiteCertificateAuthority_611447 = ref object of OpenApiRestCall_610658
proc url_DisassociateWebsiteCertificateAuthority_611449(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateWebsiteCertificateAuthority_611448(path: JsonNode;
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
  var valid_611450 = header.getOrDefault("X-Amz-Signature")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "X-Amz-Signature", valid_611450
  var valid_611451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "X-Amz-Content-Sha256", valid_611451
  var valid_611452 = header.getOrDefault("X-Amz-Date")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "X-Amz-Date", valid_611452
  var valid_611453 = header.getOrDefault("X-Amz-Credential")
  valid_611453 = validateParameter(valid_611453, JString, required = false,
                                 default = nil)
  if valid_611453 != nil:
    section.add "X-Amz-Credential", valid_611453
  var valid_611454 = header.getOrDefault("X-Amz-Security-Token")
  valid_611454 = validateParameter(valid_611454, JString, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "X-Amz-Security-Token", valid_611454
  var valid_611455 = header.getOrDefault("X-Amz-Algorithm")
  valid_611455 = validateParameter(valid_611455, JString, required = false,
                                 default = nil)
  if valid_611455 != nil:
    section.add "X-Amz-Algorithm", valid_611455
  var valid_611456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611456 = validateParameter(valid_611456, JString, required = false,
                                 default = nil)
  if valid_611456 != nil:
    section.add "X-Amz-SignedHeaders", valid_611456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611458: Call_DisassociateWebsiteCertificateAuthority_611447;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a certificate authority (CA).
  ## 
  let valid = call_611458.validator(path, query, header, formData, body)
  let scheme = call_611458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611458.url(scheme.get, call_611458.host, call_611458.base,
                         call_611458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611458, url, valid)

proc call*(call_611459: Call_DisassociateWebsiteCertificateAuthority_611447;
          body: JsonNode): Recallable =
  ## disassociateWebsiteCertificateAuthority
  ## Removes a certificate authority (CA).
  ##   body: JObject (required)
  var body_611460 = newJObject()
  if body != nil:
    body_611460 = body
  result = call_611459.call(nil, nil, nil, nil, body_611460)

var disassociateWebsiteCertificateAuthority* = Call_DisassociateWebsiteCertificateAuthority_611447(
    name: "disassociateWebsiteCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com",
    route: "/disassociateWebsiteCertificateAuthority",
    validator: validate_DisassociateWebsiteCertificateAuthority_611448, base: "/",
    url: url_DisassociateWebsiteCertificateAuthority_611449,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevices_611461 = ref object of OpenApiRestCall_610658
proc url_ListDevices_611463(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDevices_611462(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611464 = query.getOrDefault("MaxResults")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "MaxResults", valid_611464
  var valid_611465 = query.getOrDefault("NextToken")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = nil)
  if valid_611465 != nil:
    section.add "NextToken", valid_611465
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
  var valid_611466 = header.getOrDefault("X-Amz-Signature")
  valid_611466 = validateParameter(valid_611466, JString, required = false,
                                 default = nil)
  if valid_611466 != nil:
    section.add "X-Amz-Signature", valid_611466
  var valid_611467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611467 = validateParameter(valid_611467, JString, required = false,
                                 default = nil)
  if valid_611467 != nil:
    section.add "X-Amz-Content-Sha256", valid_611467
  var valid_611468 = header.getOrDefault("X-Amz-Date")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "X-Amz-Date", valid_611468
  var valid_611469 = header.getOrDefault("X-Amz-Credential")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "X-Amz-Credential", valid_611469
  var valid_611470 = header.getOrDefault("X-Amz-Security-Token")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "X-Amz-Security-Token", valid_611470
  var valid_611471 = header.getOrDefault("X-Amz-Algorithm")
  valid_611471 = validateParameter(valid_611471, JString, required = false,
                                 default = nil)
  if valid_611471 != nil:
    section.add "X-Amz-Algorithm", valid_611471
  var valid_611472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611472 = validateParameter(valid_611472, JString, required = false,
                                 default = nil)
  if valid_611472 != nil:
    section.add "X-Amz-SignedHeaders", valid_611472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611474: Call_ListDevices_611461; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of devices registered with the specified fleet.
  ## 
  let valid = call_611474.validator(path, query, header, formData, body)
  let scheme = call_611474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611474.url(scheme.get, call_611474.host, call_611474.base,
                         call_611474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611474, url, valid)

proc call*(call_611475: Call_ListDevices_611461; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDevices
  ## Retrieves a list of devices registered with the specified fleet.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611476 = newJObject()
  var body_611477 = newJObject()
  add(query_611476, "MaxResults", newJString(MaxResults))
  add(query_611476, "NextToken", newJString(NextToken))
  if body != nil:
    body_611477 = body
  result = call_611475.call(nil, query_611476, nil, nil, body_611477)

var listDevices* = Call_ListDevices_611461(name: "listDevices",
                                        meth: HttpMethod.HttpPost,
                                        host: "worklink.amazonaws.com",
                                        route: "/listDevices",
                                        validator: validate_ListDevices_611462,
                                        base: "/", url: url_ListDevices_611463,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomains_611479 = ref object of OpenApiRestCall_610658
proc url_ListDomains_611481(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDomains_611480(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611482 = query.getOrDefault("MaxResults")
  valid_611482 = validateParameter(valid_611482, JString, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "MaxResults", valid_611482
  var valid_611483 = query.getOrDefault("NextToken")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "NextToken", valid_611483
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
  var valid_611484 = header.getOrDefault("X-Amz-Signature")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "X-Amz-Signature", valid_611484
  var valid_611485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "X-Amz-Content-Sha256", valid_611485
  var valid_611486 = header.getOrDefault("X-Amz-Date")
  valid_611486 = validateParameter(valid_611486, JString, required = false,
                                 default = nil)
  if valid_611486 != nil:
    section.add "X-Amz-Date", valid_611486
  var valid_611487 = header.getOrDefault("X-Amz-Credential")
  valid_611487 = validateParameter(valid_611487, JString, required = false,
                                 default = nil)
  if valid_611487 != nil:
    section.add "X-Amz-Credential", valid_611487
  var valid_611488 = header.getOrDefault("X-Amz-Security-Token")
  valid_611488 = validateParameter(valid_611488, JString, required = false,
                                 default = nil)
  if valid_611488 != nil:
    section.add "X-Amz-Security-Token", valid_611488
  var valid_611489 = header.getOrDefault("X-Amz-Algorithm")
  valid_611489 = validateParameter(valid_611489, JString, required = false,
                                 default = nil)
  if valid_611489 != nil:
    section.add "X-Amz-Algorithm", valid_611489
  var valid_611490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611490 = validateParameter(valid_611490, JString, required = false,
                                 default = nil)
  if valid_611490 != nil:
    section.add "X-Amz-SignedHeaders", valid_611490
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611492: Call_ListDomains_611479; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of domains associated to a specified fleet.
  ## 
  let valid = call_611492.validator(path, query, header, formData, body)
  let scheme = call_611492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611492.url(scheme.get, call_611492.host, call_611492.base,
                         call_611492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611492, url, valid)

proc call*(call_611493: Call_ListDomains_611479; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDomains
  ## Retrieves a list of domains associated to a specified fleet.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611494 = newJObject()
  var body_611495 = newJObject()
  add(query_611494, "MaxResults", newJString(MaxResults))
  add(query_611494, "NextToken", newJString(NextToken))
  if body != nil:
    body_611495 = body
  result = call_611493.call(nil, query_611494, nil, nil, body_611495)

var listDomains* = Call_ListDomains_611479(name: "listDomains",
                                        meth: HttpMethod.HttpPost,
                                        host: "worklink.amazonaws.com",
                                        route: "/listDomains",
                                        validator: validate_ListDomains_611480,
                                        base: "/", url: url_ListDomains_611481,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFleets_611496 = ref object of OpenApiRestCall_610658
proc url_ListFleets_611498(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFleets_611497(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611499 = query.getOrDefault("MaxResults")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "MaxResults", valid_611499
  var valid_611500 = query.getOrDefault("NextToken")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "NextToken", valid_611500
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
  var valid_611501 = header.getOrDefault("X-Amz-Signature")
  valid_611501 = validateParameter(valid_611501, JString, required = false,
                                 default = nil)
  if valid_611501 != nil:
    section.add "X-Amz-Signature", valid_611501
  var valid_611502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611502 = validateParameter(valid_611502, JString, required = false,
                                 default = nil)
  if valid_611502 != nil:
    section.add "X-Amz-Content-Sha256", valid_611502
  var valid_611503 = header.getOrDefault("X-Amz-Date")
  valid_611503 = validateParameter(valid_611503, JString, required = false,
                                 default = nil)
  if valid_611503 != nil:
    section.add "X-Amz-Date", valid_611503
  var valid_611504 = header.getOrDefault("X-Amz-Credential")
  valid_611504 = validateParameter(valid_611504, JString, required = false,
                                 default = nil)
  if valid_611504 != nil:
    section.add "X-Amz-Credential", valid_611504
  var valid_611505 = header.getOrDefault("X-Amz-Security-Token")
  valid_611505 = validateParameter(valid_611505, JString, required = false,
                                 default = nil)
  if valid_611505 != nil:
    section.add "X-Amz-Security-Token", valid_611505
  var valid_611506 = header.getOrDefault("X-Amz-Algorithm")
  valid_611506 = validateParameter(valid_611506, JString, required = false,
                                 default = nil)
  if valid_611506 != nil:
    section.add "X-Amz-Algorithm", valid_611506
  var valid_611507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611507 = validateParameter(valid_611507, JString, required = false,
                                 default = nil)
  if valid_611507 != nil:
    section.add "X-Amz-SignedHeaders", valid_611507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611509: Call_ListFleets_611496; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of fleets for the current account and Region.
  ## 
  let valid = call_611509.validator(path, query, header, formData, body)
  let scheme = call_611509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611509.url(scheme.get, call_611509.host, call_611509.base,
                         call_611509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611509, url, valid)

proc call*(call_611510: Call_ListFleets_611496; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFleets
  ## Retrieves a list of fleets for the current account and Region.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611511 = newJObject()
  var body_611512 = newJObject()
  add(query_611511, "MaxResults", newJString(MaxResults))
  add(query_611511, "NextToken", newJString(NextToken))
  if body != nil:
    body_611512 = body
  result = call_611510.call(nil, query_611511, nil, nil, body_611512)

var listFleets* = Call_ListFleets_611496(name: "listFleets",
                                      meth: HttpMethod.HttpPost,
                                      host: "worklink.amazonaws.com",
                                      route: "/listFleets",
                                      validator: validate_ListFleets_611497,
                                      base: "/", url: url_ListFleets_611498,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWebsiteAuthorizationProviders_611513 = ref object of OpenApiRestCall_610658
proc url_ListWebsiteAuthorizationProviders_611515(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListWebsiteAuthorizationProviders_611514(path: JsonNode;
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
  var valid_611516 = query.getOrDefault("MaxResults")
  valid_611516 = validateParameter(valid_611516, JString, required = false,
                                 default = nil)
  if valid_611516 != nil:
    section.add "MaxResults", valid_611516
  var valid_611517 = query.getOrDefault("NextToken")
  valid_611517 = validateParameter(valid_611517, JString, required = false,
                                 default = nil)
  if valid_611517 != nil:
    section.add "NextToken", valid_611517
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
  var valid_611518 = header.getOrDefault("X-Amz-Signature")
  valid_611518 = validateParameter(valid_611518, JString, required = false,
                                 default = nil)
  if valid_611518 != nil:
    section.add "X-Amz-Signature", valid_611518
  var valid_611519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611519 = validateParameter(valid_611519, JString, required = false,
                                 default = nil)
  if valid_611519 != nil:
    section.add "X-Amz-Content-Sha256", valid_611519
  var valid_611520 = header.getOrDefault("X-Amz-Date")
  valid_611520 = validateParameter(valid_611520, JString, required = false,
                                 default = nil)
  if valid_611520 != nil:
    section.add "X-Amz-Date", valid_611520
  var valid_611521 = header.getOrDefault("X-Amz-Credential")
  valid_611521 = validateParameter(valid_611521, JString, required = false,
                                 default = nil)
  if valid_611521 != nil:
    section.add "X-Amz-Credential", valid_611521
  var valid_611522 = header.getOrDefault("X-Amz-Security-Token")
  valid_611522 = validateParameter(valid_611522, JString, required = false,
                                 default = nil)
  if valid_611522 != nil:
    section.add "X-Amz-Security-Token", valid_611522
  var valid_611523 = header.getOrDefault("X-Amz-Algorithm")
  valid_611523 = validateParameter(valid_611523, JString, required = false,
                                 default = nil)
  if valid_611523 != nil:
    section.add "X-Amz-Algorithm", valid_611523
  var valid_611524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611524 = validateParameter(valid_611524, JString, required = false,
                                 default = nil)
  if valid_611524 != nil:
    section.add "X-Amz-SignedHeaders", valid_611524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611526: Call_ListWebsiteAuthorizationProviders_611513;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves a list of website authorization providers associated with a specified fleet.
  ## 
  let valid = call_611526.validator(path, query, header, formData, body)
  let scheme = call_611526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611526.url(scheme.get, call_611526.host, call_611526.base,
                         call_611526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611526, url, valid)

proc call*(call_611527: Call_ListWebsiteAuthorizationProviders_611513;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listWebsiteAuthorizationProviders
  ## Retrieves a list of website authorization providers associated with a specified fleet.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611528 = newJObject()
  var body_611529 = newJObject()
  add(query_611528, "MaxResults", newJString(MaxResults))
  add(query_611528, "NextToken", newJString(NextToken))
  if body != nil:
    body_611529 = body
  result = call_611527.call(nil, query_611528, nil, nil, body_611529)

var listWebsiteAuthorizationProviders* = Call_ListWebsiteAuthorizationProviders_611513(
    name: "listWebsiteAuthorizationProviders", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/listWebsiteAuthorizationProviders",
    validator: validate_ListWebsiteAuthorizationProviders_611514, base: "/",
    url: url_ListWebsiteAuthorizationProviders_611515,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWebsiteCertificateAuthorities_611530 = ref object of OpenApiRestCall_610658
proc url_ListWebsiteCertificateAuthorities_611532(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListWebsiteCertificateAuthorities_611531(path: JsonNode;
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
  var valid_611533 = query.getOrDefault("MaxResults")
  valid_611533 = validateParameter(valid_611533, JString, required = false,
                                 default = nil)
  if valid_611533 != nil:
    section.add "MaxResults", valid_611533
  var valid_611534 = query.getOrDefault("NextToken")
  valid_611534 = validateParameter(valid_611534, JString, required = false,
                                 default = nil)
  if valid_611534 != nil:
    section.add "NextToken", valid_611534
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
  var valid_611535 = header.getOrDefault("X-Amz-Signature")
  valid_611535 = validateParameter(valid_611535, JString, required = false,
                                 default = nil)
  if valid_611535 != nil:
    section.add "X-Amz-Signature", valid_611535
  var valid_611536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611536 = validateParameter(valid_611536, JString, required = false,
                                 default = nil)
  if valid_611536 != nil:
    section.add "X-Amz-Content-Sha256", valid_611536
  var valid_611537 = header.getOrDefault("X-Amz-Date")
  valid_611537 = validateParameter(valid_611537, JString, required = false,
                                 default = nil)
  if valid_611537 != nil:
    section.add "X-Amz-Date", valid_611537
  var valid_611538 = header.getOrDefault("X-Amz-Credential")
  valid_611538 = validateParameter(valid_611538, JString, required = false,
                                 default = nil)
  if valid_611538 != nil:
    section.add "X-Amz-Credential", valid_611538
  var valid_611539 = header.getOrDefault("X-Amz-Security-Token")
  valid_611539 = validateParameter(valid_611539, JString, required = false,
                                 default = nil)
  if valid_611539 != nil:
    section.add "X-Amz-Security-Token", valid_611539
  var valid_611540 = header.getOrDefault("X-Amz-Algorithm")
  valid_611540 = validateParameter(valid_611540, JString, required = false,
                                 default = nil)
  if valid_611540 != nil:
    section.add "X-Amz-Algorithm", valid_611540
  var valid_611541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611541 = validateParameter(valid_611541, JString, required = false,
                                 default = nil)
  if valid_611541 != nil:
    section.add "X-Amz-SignedHeaders", valid_611541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611543: Call_ListWebsiteCertificateAuthorities_611530;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves a list of certificate authorities added for the current account and Region.
  ## 
  let valid = call_611543.validator(path, query, header, formData, body)
  let scheme = call_611543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611543.url(scheme.get, call_611543.host, call_611543.base,
                         call_611543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611543, url, valid)

proc call*(call_611544: Call_ListWebsiteCertificateAuthorities_611530;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listWebsiteCertificateAuthorities
  ## Retrieves a list of certificate authorities added for the current account and Region.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611545 = newJObject()
  var body_611546 = newJObject()
  add(query_611545, "MaxResults", newJString(MaxResults))
  add(query_611545, "NextToken", newJString(NextToken))
  if body != nil:
    body_611546 = body
  result = call_611544.call(nil, query_611545, nil, nil, body_611546)

var listWebsiteCertificateAuthorities* = Call_ListWebsiteCertificateAuthorities_611530(
    name: "listWebsiteCertificateAuthorities", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/listWebsiteCertificateAuthorities",
    validator: validate_ListWebsiteCertificateAuthorities_611531, base: "/",
    url: url_ListWebsiteCertificateAuthorities_611532,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreDomainAccess_611547 = ref object of OpenApiRestCall_610658
proc url_RestoreDomainAccess_611549(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RestoreDomainAccess_611548(path: JsonNode; query: JsonNode;
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
  var valid_611550 = header.getOrDefault("X-Amz-Signature")
  valid_611550 = validateParameter(valid_611550, JString, required = false,
                                 default = nil)
  if valid_611550 != nil:
    section.add "X-Amz-Signature", valid_611550
  var valid_611551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611551 = validateParameter(valid_611551, JString, required = false,
                                 default = nil)
  if valid_611551 != nil:
    section.add "X-Amz-Content-Sha256", valid_611551
  var valid_611552 = header.getOrDefault("X-Amz-Date")
  valid_611552 = validateParameter(valid_611552, JString, required = false,
                                 default = nil)
  if valid_611552 != nil:
    section.add "X-Amz-Date", valid_611552
  var valid_611553 = header.getOrDefault("X-Amz-Credential")
  valid_611553 = validateParameter(valid_611553, JString, required = false,
                                 default = nil)
  if valid_611553 != nil:
    section.add "X-Amz-Credential", valid_611553
  var valid_611554 = header.getOrDefault("X-Amz-Security-Token")
  valid_611554 = validateParameter(valid_611554, JString, required = false,
                                 default = nil)
  if valid_611554 != nil:
    section.add "X-Amz-Security-Token", valid_611554
  var valid_611555 = header.getOrDefault("X-Amz-Algorithm")
  valid_611555 = validateParameter(valid_611555, JString, required = false,
                                 default = nil)
  if valid_611555 != nil:
    section.add "X-Amz-Algorithm", valid_611555
  var valid_611556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611556 = validateParameter(valid_611556, JString, required = false,
                                 default = nil)
  if valid_611556 != nil:
    section.add "X-Amz-SignedHeaders", valid_611556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611558: Call_RestoreDomainAccess_611547; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Moves a domain to ACTIVE status if it was in the INACTIVE status.
  ## 
  let valid = call_611558.validator(path, query, header, formData, body)
  let scheme = call_611558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611558.url(scheme.get, call_611558.host, call_611558.base,
                         call_611558.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611558, url, valid)

proc call*(call_611559: Call_RestoreDomainAccess_611547; body: JsonNode): Recallable =
  ## restoreDomainAccess
  ## Moves a domain to ACTIVE status if it was in the INACTIVE status.
  ##   body: JObject (required)
  var body_611560 = newJObject()
  if body != nil:
    body_611560 = body
  result = call_611559.call(nil, nil, nil, nil, body_611560)

var restoreDomainAccess* = Call_RestoreDomainAccess_611547(
    name: "restoreDomainAccess", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/restoreDomainAccess",
    validator: validate_RestoreDomainAccess_611548, base: "/",
    url: url_RestoreDomainAccess_611549, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeDomainAccess_611561 = ref object of OpenApiRestCall_610658
proc url_RevokeDomainAccess_611563(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RevokeDomainAccess_611562(path: JsonNode; query: JsonNode;
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
  var valid_611564 = header.getOrDefault("X-Amz-Signature")
  valid_611564 = validateParameter(valid_611564, JString, required = false,
                                 default = nil)
  if valid_611564 != nil:
    section.add "X-Amz-Signature", valid_611564
  var valid_611565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611565 = validateParameter(valid_611565, JString, required = false,
                                 default = nil)
  if valid_611565 != nil:
    section.add "X-Amz-Content-Sha256", valid_611565
  var valid_611566 = header.getOrDefault("X-Amz-Date")
  valid_611566 = validateParameter(valid_611566, JString, required = false,
                                 default = nil)
  if valid_611566 != nil:
    section.add "X-Amz-Date", valid_611566
  var valid_611567 = header.getOrDefault("X-Amz-Credential")
  valid_611567 = validateParameter(valid_611567, JString, required = false,
                                 default = nil)
  if valid_611567 != nil:
    section.add "X-Amz-Credential", valid_611567
  var valid_611568 = header.getOrDefault("X-Amz-Security-Token")
  valid_611568 = validateParameter(valid_611568, JString, required = false,
                                 default = nil)
  if valid_611568 != nil:
    section.add "X-Amz-Security-Token", valid_611568
  var valid_611569 = header.getOrDefault("X-Amz-Algorithm")
  valid_611569 = validateParameter(valid_611569, JString, required = false,
                                 default = nil)
  if valid_611569 != nil:
    section.add "X-Amz-Algorithm", valid_611569
  var valid_611570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611570 = validateParameter(valid_611570, JString, required = false,
                                 default = nil)
  if valid_611570 != nil:
    section.add "X-Amz-SignedHeaders", valid_611570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611572: Call_RevokeDomainAccess_611561; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Moves a domain to INACTIVE status if it was in the ACTIVE status.
  ## 
  let valid = call_611572.validator(path, query, header, formData, body)
  let scheme = call_611572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611572.url(scheme.get, call_611572.host, call_611572.base,
                         call_611572.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611572, url, valid)

proc call*(call_611573: Call_RevokeDomainAccess_611561; body: JsonNode): Recallable =
  ## revokeDomainAccess
  ## Moves a domain to INACTIVE status if it was in the ACTIVE status.
  ##   body: JObject (required)
  var body_611574 = newJObject()
  if body != nil:
    body_611574 = body
  result = call_611573.call(nil, nil, nil, nil, body_611574)

var revokeDomainAccess* = Call_RevokeDomainAccess_611561(
    name: "revokeDomainAccess", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/revokeDomainAccess",
    validator: validate_RevokeDomainAccess_611562, base: "/",
    url: url_RevokeDomainAccess_611563, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SignOutUser_611575 = ref object of OpenApiRestCall_610658
proc url_SignOutUser_611577(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SignOutUser_611576(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611578 = header.getOrDefault("X-Amz-Signature")
  valid_611578 = validateParameter(valid_611578, JString, required = false,
                                 default = nil)
  if valid_611578 != nil:
    section.add "X-Amz-Signature", valid_611578
  var valid_611579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611579 = validateParameter(valid_611579, JString, required = false,
                                 default = nil)
  if valid_611579 != nil:
    section.add "X-Amz-Content-Sha256", valid_611579
  var valid_611580 = header.getOrDefault("X-Amz-Date")
  valid_611580 = validateParameter(valid_611580, JString, required = false,
                                 default = nil)
  if valid_611580 != nil:
    section.add "X-Amz-Date", valid_611580
  var valid_611581 = header.getOrDefault("X-Amz-Credential")
  valid_611581 = validateParameter(valid_611581, JString, required = false,
                                 default = nil)
  if valid_611581 != nil:
    section.add "X-Amz-Credential", valid_611581
  var valid_611582 = header.getOrDefault("X-Amz-Security-Token")
  valid_611582 = validateParameter(valid_611582, JString, required = false,
                                 default = nil)
  if valid_611582 != nil:
    section.add "X-Amz-Security-Token", valid_611582
  var valid_611583 = header.getOrDefault("X-Amz-Algorithm")
  valid_611583 = validateParameter(valid_611583, JString, required = false,
                                 default = nil)
  if valid_611583 != nil:
    section.add "X-Amz-Algorithm", valid_611583
  var valid_611584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611584 = validateParameter(valid_611584, JString, required = false,
                                 default = nil)
  if valid_611584 != nil:
    section.add "X-Amz-SignedHeaders", valid_611584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611586: Call_SignOutUser_611575; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Signs the user out from all of their devices. The user can sign in again if they have valid credentials.
  ## 
  let valid = call_611586.validator(path, query, header, formData, body)
  let scheme = call_611586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611586.url(scheme.get, call_611586.host, call_611586.base,
                         call_611586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611586, url, valid)

proc call*(call_611587: Call_SignOutUser_611575; body: JsonNode): Recallable =
  ## signOutUser
  ## Signs the user out from all of their devices. The user can sign in again if they have valid credentials.
  ##   body: JObject (required)
  var body_611588 = newJObject()
  if body != nil:
    body_611588 = body
  result = call_611587.call(nil, nil, nil, nil, body_611588)

var signOutUser* = Call_SignOutUser_611575(name: "signOutUser",
                                        meth: HttpMethod.HttpPost,
                                        host: "worklink.amazonaws.com",
                                        route: "/signOutUser",
                                        validator: validate_SignOutUser_611576,
                                        base: "/", url: url_SignOutUser_611577,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuditStreamConfiguration_611589 = ref object of OpenApiRestCall_610658
proc url_UpdateAuditStreamConfiguration_611591(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateAuditStreamConfiguration_611590(path: JsonNode;
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
  var valid_611592 = header.getOrDefault("X-Amz-Signature")
  valid_611592 = validateParameter(valid_611592, JString, required = false,
                                 default = nil)
  if valid_611592 != nil:
    section.add "X-Amz-Signature", valid_611592
  var valid_611593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611593 = validateParameter(valid_611593, JString, required = false,
                                 default = nil)
  if valid_611593 != nil:
    section.add "X-Amz-Content-Sha256", valid_611593
  var valid_611594 = header.getOrDefault("X-Amz-Date")
  valid_611594 = validateParameter(valid_611594, JString, required = false,
                                 default = nil)
  if valid_611594 != nil:
    section.add "X-Amz-Date", valid_611594
  var valid_611595 = header.getOrDefault("X-Amz-Credential")
  valid_611595 = validateParameter(valid_611595, JString, required = false,
                                 default = nil)
  if valid_611595 != nil:
    section.add "X-Amz-Credential", valid_611595
  var valid_611596 = header.getOrDefault("X-Amz-Security-Token")
  valid_611596 = validateParameter(valid_611596, JString, required = false,
                                 default = nil)
  if valid_611596 != nil:
    section.add "X-Amz-Security-Token", valid_611596
  var valid_611597 = header.getOrDefault("X-Amz-Algorithm")
  valid_611597 = validateParameter(valid_611597, JString, required = false,
                                 default = nil)
  if valid_611597 != nil:
    section.add "X-Amz-Algorithm", valid_611597
  var valid_611598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611598 = validateParameter(valid_611598, JString, required = false,
                                 default = nil)
  if valid_611598 != nil:
    section.add "X-Amz-SignedHeaders", valid_611598
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611600: Call_UpdateAuditStreamConfiguration_611589; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the audit stream configuration for the fleet.
  ## 
  let valid = call_611600.validator(path, query, header, formData, body)
  let scheme = call_611600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611600.url(scheme.get, call_611600.host, call_611600.base,
                         call_611600.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611600, url, valid)

proc call*(call_611601: Call_UpdateAuditStreamConfiguration_611589; body: JsonNode): Recallable =
  ## updateAuditStreamConfiguration
  ## Updates the audit stream configuration for the fleet.
  ##   body: JObject (required)
  var body_611602 = newJObject()
  if body != nil:
    body_611602 = body
  result = call_611601.call(nil, nil, nil, nil, body_611602)

var updateAuditStreamConfiguration* = Call_UpdateAuditStreamConfiguration_611589(
    name: "updateAuditStreamConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/updateAuditStreamConfiguration",
    validator: validate_UpdateAuditStreamConfiguration_611590, base: "/",
    url: url_UpdateAuditStreamConfiguration_611591,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCompanyNetworkConfiguration_611603 = ref object of OpenApiRestCall_610658
proc url_UpdateCompanyNetworkConfiguration_611605(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateCompanyNetworkConfiguration_611604(path: JsonNode;
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

proc call*(call_611614: Call_UpdateCompanyNetworkConfiguration_611603;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the company network configuration for the fleet.
  ## 
  let valid = call_611614.validator(path, query, header, formData, body)
  let scheme = call_611614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611614.url(scheme.get, call_611614.host, call_611614.base,
                         call_611614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611614, url, valid)

proc call*(call_611615: Call_UpdateCompanyNetworkConfiguration_611603;
          body: JsonNode): Recallable =
  ## updateCompanyNetworkConfiguration
  ## Updates the company network configuration for the fleet.
  ##   body: JObject (required)
  var body_611616 = newJObject()
  if body != nil:
    body_611616 = body
  result = call_611615.call(nil, nil, nil, nil, body_611616)

var updateCompanyNetworkConfiguration* = Call_UpdateCompanyNetworkConfiguration_611603(
    name: "updateCompanyNetworkConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/updateCompanyNetworkConfiguration",
    validator: validate_UpdateCompanyNetworkConfiguration_611604, base: "/",
    url: url_UpdateCompanyNetworkConfiguration_611605,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevicePolicyConfiguration_611617 = ref object of OpenApiRestCall_610658
proc url_UpdateDevicePolicyConfiguration_611619(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDevicePolicyConfiguration_611618(path: JsonNode;
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
  var valid_611620 = header.getOrDefault("X-Amz-Signature")
  valid_611620 = validateParameter(valid_611620, JString, required = false,
                                 default = nil)
  if valid_611620 != nil:
    section.add "X-Amz-Signature", valid_611620
  var valid_611621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611621 = validateParameter(valid_611621, JString, required = false,
                                 default = nil)
  if valid_611621 != nil:
    section.add "X-Amz-Content-Sha256", valid_611621
  var valid_611622 = header.getOrDefault("X-Amz-Date")
  valid_611622 = validateParameter(valid_611622, JString, required = false,
                                 default = nil)
  if valid_611622 != nil:
    section.add "X-Amz-Date", valid_611622
  var valid_611623 = header.getOrDefault("X-Amz-Credential")
  valid_611623 = validateParameter(valid_611623, JString, required = false,
                                 default = nil)
  if valid_611623 != nil:
    section.add "X-Amz-Credential", valid_611623
  var valid_611624 = header.getOrDefault("X-Amz-Security-Token")
  valid_611624 = validateParameter(valid_611624, JString, required = false,
                                 default = nil)
  if valid_611624 != nil:
    section.add "X-Amz-Security-Token", valid_611624
  var valid_611625 = header.getOrDefault("X-Amz-Algorithm")
  valid_611625 = validateParameter(valid_611625, JString, required = false,
                                 default = nil)
  if valid_611625 != nil:
    section.add "X-Amz-Algorithm", valid_611625
  var valid_611626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611626 = validateParameter(valid_611626, JString, required = false,
                                 default = nil)
  if valid_611626 != nil:
    section.add "X-Amz-SignedHeaders", valid_611626
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611628: Call_UpdateDevicePolicyConfiguration_611617;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the device policy configuration for the fleet.
  ## 
  let valid = call_611628.validator(path, query, header, formData, body)
  let scheme = call_611628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611628.url(scheme.get, call_611628.host, call_611628.base,
                         call_611628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611628, url, valid)

proc call*(call_611629: Call_UpdateDevicePolicyConfiguration_611617; body: JsonNode): Recallable =
  ## updateDevicePolicyConfiguration
  ## Updates the device policy configuration for the fleet.
  ##   body: JObject (required)
  var body_611630 = newJObject()
  if body != nil:
    body_611630 = body
  result = call_611629.call(nil, nil, nil, nil, body_611630)

var updateDevicePolicyConfiguration* = Call_UpdateDevicePolicyConfiguration_611617(
    name: "updateDevicePolicyConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/updateDevicePolicyConfiguration",
    validator: validate_UpdateDevicePolicyConfiguration_611618, base: "/",
    url: url_UpdateDevicePolicyConfiguration_611619,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainMetadata_611631 = ref object of OpenApiRestCall_610658
proc url_UpdateDomainMetadata_611633(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDomainMetadata_611632(path: JsonNode; query: JsonNode;
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
  var valid_611634 = header.getOrDefault("X-Amz-Signature")
  valid_611634 = validateParameter(valid_611634, JString, required = false,
                                 default = nil)
  if valid_611634 != nil:
    section.add "X-Amz-Signature", valid_611634
  var valid_611635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611635 = validateParameter(valid_611635, JString, required = false,
                                 default = nil)
  if valid_611635 != nil:
    section.add "X-Amz-Content-Sha256", valid_611635
  var valid_611636 = header.getOrDefault("X-Amz-Date")
  valid_611636 = validateParameter(valid_611636, JString, required = false,
                                 default = nil)
  if valid_611636 != nil:
    section.add "X-Amz-Date", valid_611636
  var valid_611637 = header.getOrDefault("X-Amz-Credential")
  valid_611637 = validateParameter(valid_611637, JString, required = false,
                                 default = nil)
  if valid_611637 != nil:
    section.add "X-Amz-Credential", valid_611637
  var valid_611638 = header.getOrDefault("X-Amz-Security-Token")
  valid_611638 = validateParameter(valid_611638, JString, required = false,
                                 default = nil)
  if valid_611638 != nil:
    section.add "X-Amz-Security-Token", valid_611638
  var valid_611639 = header.getOrDefault("X-Amz-Algorithm")
  valid_611639 = validateParameter(valid_611639, JString, required = false,
                                 default = nil)
  if valid_611639 != nil:
    section.add "X-Amz-Algorithm", valid_611639
  var valid_611640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611640 = validateParameter(valid_611640, JString, required = false,
                                 default = nil)
  if valid_611640 != nil:
    section.add "X-Amz-SignedHeaders", valid_611640
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611642: Call_UpdateDomainMetadata_611631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates domain metadata, such as DisplayName.
  ## 
  let valid = call_611642.validator(path, query, header, formData, body)
  let scheme = call_611642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611642.url(scheme.get, call_611642.host, call_611642.base,
                         call_611642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611642, url, valid)

proc call*(call_611643: Call_UpdateDomainMetadata_611631; body: JsonNode): Recallable =
  ## updateDomainMetadata
  ## Updates domain metadata, such as DisplayName.
  ##   body: JObject (required)
  var body_611644 = newJObject()
  if body != nil:
    body_611644 = body
  result = call_611643.call(nil, nil, nil, nil, body_611644)

var updateDomainMetadata* = Call_UpdateDomainMetadata_611631(
    name: "updateDomainMetadata", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/updateDomainMetadata",
    validator: validate_UpdateDomainMetadata_611632, base: "/",
    url: url_UpdateDomainMetadata_611633, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFleetMetadata_611645 = ref object of OpenApiRestCall_610658
proc url_UpdateFleetMetadata_611647(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateFleetMetadata_611646(path: JsonNode; query: JsonNode;
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
  var valid_611648 = header.getOrDefault("X-Amz-Signature")
  valid_611648 = validateParameter(valid_611648, JString, required = false,
                                 default = nil)
  if valid_611648 != nil:
    section.add "X-Amz-Signature", valid_611648
  var valid_611649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611649 = validateParameter(valid_611649, JString, required = false,
                                 default = nil)
  if valid_611649 != nil:
    section.add "X-Amz-Content-Sha256", valid_611649
  var valid_611650 = header.getOrDefault("X-Amz-Date")
  valid_611650 = validateParameter(valid_611650, JString, required = false,
                                 default = nil)
  if valid_611650 != nil:
    section.add "X-Amz-Date", valid_611650
  var valid_611651 = header.getOrDefault("X-Amz-Credential")
  valid_611651 = validateParameter(valid_611651, JString, required = false,
                                 default = nil)
  if valid_611651 != nil:
    section.add "X-Amz-Credential", valid_611651
  var valid_611652 = header.getOrDefault("X-Amz-Security-Token")
  valid_611652 = validateParameter(valid_611652, JString, required = false,
                                 default = nil)
  if valid_611652 != nil:
    section.add "X-Amz-Security-Token", valid_611652
  var valid_611653 = header.getOrDefault("X-Amz-Algorithm")
  valid_611653 = validateParameter(valid_611653, JString, required = false,
                                 default = nil)
  if valid_611653 != nil:
    section.add "X-Amz-Algorithm", valid_611653
  var valid_611654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611654 = validateParameter(valid_611654, JString, required = false,
                                 default = nil)
  if valid_611654 != nil:
    section.add "X-Amz-SignedHeaders", valid_611654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611656: Call_UpdateFleetMetadata_611645; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates fleet metadata, such as DisplayName.
  ## 
  let valid = call_611656.validator(path, query, header, formData, body)
  let scheme = call_611656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611656.url(scheme.get, call_611656.host, call_611656.base,
                         call_611656.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611656, url, valid)

proc call*(call_611657: Call_UpdateFleetMetadata_611645; body: JsonNode): Recallable =
  ## updateFleetMetadata
  ## Updates fleet metadata, such as DisplayName.
  ##   body: JObject (required)
  var body_611658 = newJObject()
  if body != nil:
    body_611658 = body
  result = call_611657.call(nil, nil, nil, nil, body_611658)

var updateFleetMetadata* = Call_UpdateFleetMetadata_611645(
    name: "updateFleetMetadata", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/UpdateFleetMetadata",
    validator: validate_UpdateFleetMetadata_611646, base: "/",
    url: url_UpdateFleetMetadata_611647, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIdentityProviderConfiguration_611659 = ref object of OpenApiRestCall_610658
proc url_UpdateIdentityProviderConfiguration_611661(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateIdentityProviderConfiguration_611660(path: JsonNode;
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
  var valid_611662 = header.getOrDefault("X-Amz-Signature")
  valid_611662 = validateParameter(valid_611662, JString, required = false,
                                 default = nil)
  if valid_611662 != nil:
    section.add "X-Amz-Signature", valid_611662
  var valid_611663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611663 = validateParameter(valid_611663, JString, required = false,
                                 default = nil)
  if valid_611663 != nil:
    section.add "X-Amz-Content-Sha256", valid_611663
  var valid_611664 = header.getOrDefault("X-Amz-Date")
  valid_611664 = validateParameter(valid_611664, JString, required = false,
                                 default = nil)
  if valid_611664 != nil:
    section.add "X-Amz-Date", valid_611664
  var valid_611665 = header.getOrDefault("X-Amz-Credential")
  valid_611665 = validateParameter(valid_611665, JString, required = false,
                                 default = nil)
  if valid_611665 != nil:
    section.add "X-Amz-Credential", valid_611665
  var valid_611666 = header.getOrDefault("X-Amz-Security-Token")
  valid_611666 = validateParameter(valid_611666, JString, required = false,
                                 default = nil)
  if valid_611666 != nil:
    section.add "X-Amz-Security-Token", valid_611666
  var valid_611667 = header.getOrDefault("X-Amz-Algorithm")
  valid_611667 = validateParameter(valid_611667, JString, required = false,
                                 default = nil)
  if valid_611667 != nil:
    section.add "X-Amz-Algorithm", valid_611667
  var valid_611668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611668 = validateParameter(valid_611668, JString, required = false,
                                 default = nil)
  if valid_611668 != nil:
    section.add "X-Amz-SignedHeaders", valid_611668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611670: Call_UpdateIdentityProviderConfiguration_611659;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the identity provider configuration for the fleet.
  ## 
  let valid = call_611670.validator(path, query, header, formData, body)
  let scheme = call_611670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611670.url(scheme.get, call_611670.host, call_611670.base,
                         call_611670.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611670, url, valid)

proc call*(call_611671: Call_UpdateIdentityProviderConfiguration_611659;
          body: JsonNode): Recallable =
  ## updateIdentityProviderConfiguration
  ## Updates the identity provider configuration for the fleet.
  ##   body: JObject (required)
  var body_611672 = newJObject()
  if body != nil:
    body_611672 = body
  result = call_611671.call(nil, nil, nil, nil, body_611672)

var updateIdentityProviderConfiguration* = Call_UpdateIdentityProviderConfiguration_611659(
    name: "updateIdentityProviderConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/updateIdentityProviderConfiguration",
    validator: validate_UpdateIdentityProviderConfiguration_611660, base: "/",
    url: url_UpdateIdentityProviderConfiguration_611661,
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
