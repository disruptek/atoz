
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
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
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AssociateDomain_772933 = ref object of OpenApiRestCall_772597
proc url_AssociateDomain_772935(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AssociateDomain_772934(path: JsonNode; query: JsonNode;
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
  var valid_773047 = header.getOrDefault("X-Amz-Date")
  valid_773047 = validateParameter(valid_773047, JString, required = false,
                                 default = nil)
  if valid_773047 != nil:
    section.add "X-Amz-Date", valid_773047
  var valid_773048 = header.getOrDefault("X-Amz-Security-Token")
  valid_773048 = validateParameter(valid_773048, JString, required = false,
                                 default = nil)
  if valid_773048 != nil:
    section.add "X-Amz-Security-Token", valid_773048
  var valid_773049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773049 = validateParameter(valid_773049, JString, required = false,
                                 default = nil)
  if valid_773049 != nil:
    section.add "X-Amz-Content-Sha256", valid_773049
  var valid_773050 = header.getOrDefault("X-Amz-Algorithm")
  valid_773050 = validateParameter(valid_773050, JString, required = false,
                                 default = nil)
  if valid_773050 != nil:
    section.add "X-Amz-Algorithm", valid_773050
  var valid_773051 = header.getOrDefault("X-Amz-Signature")
  valid_773051 = validateParameter(valid_773051, JString, required = false,
                                 default = nil)
  if valid_773051 != nil:
    section.add "X-Amz-Signature", valid_773051
  var valid_773052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773052 = validateParameter(valid_773052, JString, required = false,
                                 default = nil)
  if valid_773052 != nil:
    section.add "X-Amz-SignedHeaders", valid_773052
  var valid_773053 = header.getOrDefault("X-Amz-Credential")
  valid_773053 = validateParameter(valid_773053, JString, required = false,
                                 default = nil)
  if valid_773053 != nil:
    section.add "X-Amz-Credential", valid_773053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773077: Call_AssociateDomain_772933; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Specifies a domain to be associated to Amazon WorkLink.
  ## 
  let valid = call_773077.validator(path, query, header, formData, body)
  let scheme = call_773077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773077.url(scheme.get, call_773077.host, call_773077.base,
                         call_773077.route, valid.getOrDefault("path"))
  result = hook(call_773077, url, valid)

proc call*(call_773148: Call_AssociateDomain_772933; body: JsonNode): Recallable =
  ## associateDomain
  ## Specifies a domain to be associated to Amazon WorkLink.
  ##   body: JObject (required)
  var body_773149 = newJObject()
  if body != nil:
    body_773149 = body
  result = call_773148.call(nil, nil, nil, nil, body_773149)

var associateDomain* = Call_AssociateDomain_772933(name: "associateDomain",
    meth: HttpMethod.HttpPost, host: "worklink.amazonaws.com",
    route: "/associateDomain", validator: validate_AssociateDomain_772934,
    base: "/", url: url_AssociateDomain_772935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateWebsiteAuthorizationProvider_773188 = ref object of OpenApiRestCall_772597
proc url_AssociateWebsiteAuthorizationProvider_773190(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AssociateWebsiteAuthorizationProvider_773189(path: JsonNode;
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
  var valid_773191 = header.getOrDefault("X-Amz-Date")
  valid_773191 = validateParameter(valid_773191, JString, required = false,
                                 default = nil)
  if valid_773191 != nil:
    section.add "X-Amz-Date", valid_773191
  var valid_773192 = header.getOrDefault("X-Amz-Security-Token")
  valid_773192 = validateParameter(valid_773192, JString, required = false,
                                 default = nil)
  if valid_773192 != nil:
    section.add "X-Amz-Security-Token", valid_773192
  var valid_773193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773193 = validateParameter(valid_773193, JString, required = false,
                                 default = nil)
  if valid_773193 != nil:
    section.add "X-Amz-Content-Sha256", valid_773193
  var valid_773194 = header.getOrDefault("X-Amz-Algorithm")
  valid_773194 = validateParameter(valid_773194, JString, required = false,
                                 default = nil)
  if valid_773194 != nil:
    section.add "X-Amz-Algorithm", valid_773194
  var valid_773195 = header.getOrDefault("X-Amz-Signature")
  valid_773195 = validateParameter(valid_773195, JString, required = false,
                                 default = nil)
  if valid_773195 != nil:
    section.add "X-Amz-Signature", valid_773195
  var valid_773196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773196 = validateParameter(valid_773196, JString, required = false,
                                 default = nil)
  if valid_773196 != nil:
    section.add "X-Amz-SignedHeaders", valid_773196
  var valid_773197 = header.getOrDefault("X-Amz-Credential")
  valid_773197 = validateParameter(valid_773197, JString, required = false,
                                 default = nil)
  if valid_773197 != nil:
    section.add "X-Amz-Credential", valid_773197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773199: Call_AssociateWebsiteAuthorizationProvider_773188;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a website authorization provider with a specified fleet. This is used to authorize users against associated websites in the company network.
  ## 
  let valid = call_773199.validator(path, query, header, formData, body)
  let scheme = call_773199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773199.url(scheme.get, call_773199.host, call_773199.base,
                         call_773199.route, valid.getOrDefault("path"))
  result = hook(call_773199, url, valid)

proc call*(call_773200: Call_AssociateWebsiteAuthorizationProvider_773188;
          body: JsonNode): Recallable =
  ## associateWebsiteAuthorizationProvider
  ## Associates a website authorization provider with a specified fleet. This is used to authorize users against associated websites in the company network.
  ##   body: JObject (required)
  var body_773201 = newJObject()
  if body != nil:
    body_773201 = body
  result = call_773200.call(nil, nil, nil, nil, body_773201)

var associateWebsiteAuthorizationProvider* = Call_AssociateWebsiteAuthorizationProvider_773188(
    name: "associateWebsiteAuthorizationProvider", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com",
    route: "/associateWebsiteAuthorizationProvider",
    validator: validate_AssociateWebsiteAuthorizationProvider_773189, base: "/",
    url: url_AssociateWebsiteAuthorizationProvider_773190,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateWebsiteCertificateAuthority_773202 = ref object of OpenApiRestCall_772597
proc url_AssociateWebsiteCertificateAuthority_773204(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AssociateWebsiteCertificateAuthority_773203(path: JsonNode;
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
  var valid_773205 = header.getOrDefault("X-Amz-Date")
  valid_773205 = validateParameter(valid_773205, JString, required = false,
                                 default = nil)
  if valid_773205 != nil:
    section.add "X-Amz-Date", valid_773205
  var valid_773206 = header.getOrDefault("X-Amz-Security-Token")
  valid_773206 = validateParameter(valid_773206, JString, required = false,
                                 default = nil)
  if valid_773206 != nil:
    section.add "X-Amz-Security-Token", valid_773206
  var valid_773207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773207 = validateParameter(valid_773207, JString, required = false,
                                 default = nil)
  if valid_773207 != nil:
    section.add "X-Amz-Content-Sha256", valid_773207
  var valid_773208 = header.getOrDefault("X-Amz-Algorithm")
  valid_773208 = validateParameter(valid_773208, JString, required = false,
                                 default = nil)
  if valid_773208 != nil:
    section.add "X-Amz-Algorithm", valid_773208
  var valid_773209 = header.getOrDefault("X-Amz-Signature")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Signature", valid_773209
  var valid_773210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-SignedHeaders", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-Credential")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-Credential", valid_773211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773213: Call_AssociateWebsiteCertificateAuthority_773202;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Imports the root certificate of a certificate authority (CA) used to obtain TLS certificates used by associated websites within the company network.
  ## 
  let valid = call_773213.validator(path, query, header, formData, body)
  let scheme = call_773213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773213.url(scheme.get, call_773213.host, call_773213.base,
                         call_773213.route, valid.getOrDefault("path"))
  result = hook(call_773213, url, valid)

proc call*(call_773214: Call_AssociateWebsiteCertificateAuthority_773202;
          body: JsonNode): Recallable =
  ## associateWebsiteCertificateAuthority
  ## Imports the root certificate of a certificate authority (CA) used to obtain TLS certificates used by associated websites within the company network.
  ##   body: JObject (required)
  var body_773215 = newJObject()
  if body != nil:
    body_773215 = body
  result = call_773214.call(nil, nil, nil, nil, body_773215)

var associateWebsiteCertificateAuthority* = Call_AssociateWebsiteCertificateAuthority_773202(
    name: "associateWebsiteCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com",
    route: "/associateWebsiteCertificateAuthority",
    validator: validate_AssociateWebsiteCertificateAuthority_773203, base: "/",
    url: url_AssociateWebsiteCertificateAuthority_773204,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFleet_773216 = ref object of OpenApiRestCall_772597
proc url_CreateFleet_773218(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateFleet_773217(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773219 = header.getOrDefault("X-Amz-Date")
  valid_773219 = validateParameter(valid_773219, JString, required = false,
                                 default = nil)
  if valid_773219 != nil:
    section.add "X-Amz-Date", valid_773219
  var valid_773220 = header.getOrDefault("X-Amz-Security-Token")
  valid_773220 = validateParameter(valid_773220, JString, required = false,
                                 default = nil)
  if valid_773220 != nil:
    section.add "X-Amz-Security-Token", valid_773220
  var valid_773221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773221 = validateParameter(valid_773221, JString, required = false,
                                 default = nil)
  if valid_773221 != nil:
    section.add "X-Amz-Content-Sha256", valid_773221
  var valid_773222 = header.getOrDefault("X-Amz-Algorithm")
  valid_773222 = validateParameter(valid_773222, JString, required = false,
                                 default = nil)
  if valid_773222 != nil:
    section.add "X-Amz-Algorithm", valid_773222
  var valid_773223 = header.getOrDefault("X-Amz-Signature")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "X-Amz-Signature", valid_773223
  var valid_773224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "X-Amz-SignedHeaders", valid_773224
  var valid_773225 = header.getOrDefault("X-Amz-Credential")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-Credential", valid_773225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773227: Call_CreateFleet_773216; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a fleet. A fleet consists of resources and the configuration that delivers associated websites to authorized users who download and set up the Amazon WorkLink app.
  ## 
  let valid = call_773227.validator(path, query, header, formData, body)
  let scheme = call_773227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773227.url(scheme.get, call_773227.host, call_773227.base,
                         call_773227.route, valid.getOrDefault("path"))
  result = hook(call_773227, url, valid)

proc call*(call_773228: Call_CreateFleet_773216; body: JsonNode): Recallable =
  ## createFleet
  ## Creates a fleet. A fleet consists of resources and the configuration that delivers associated websites to authorized users who download and set up the Amazon WorkLink app.
  ##   body: JObject (required)
  var body_773229 = newJObject()
  if body != nil:
    body_773229 = body
  result = call_773228.call(nil, nil, nil, nil, body_773229)

var createFleet* = Call_CreateFleet_773216(name: "createFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "worklink.amazonaws.com",
                                        route: "/createFleet",
                                        validator: validate_CreateFleet_773217,
                                        base: "/", url: url_CreateFleet_773218,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFleet_773230 = ref object of OpenApiRestCall_772597
proc url_DeleteFleet_773232(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteFleet_773231(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773233 = header.getOrDefault("X-Amz-Date")
  valid_773233 = validateParameter(valid_773233, JString, required = false,
                                 default = nil)
  if valid_773233 != nil:
    section.add "X-Amz-Date", valid_773233
  var valid_773234 = header.getOrDefault("X-Amz-Security-Token")
  valid_773234 = validateParameter(valid_773234, JString, required = false,
                                 default = nil)
  if valid_773234 != nil:
    section.add "X-Amz-Security-Token", valid_773234
  var valid_773235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-Content-Sha256", valid_773235
  var valid_773236 = header.getOrDefault("X-Amz-Algorithm")
  valid_773236 = validateParameter(valid_773236, JString, required = false,
                                 default = nil)
  if valid_773236 != nil:
    section.add "X-Amz-Algorithm", valid_773236
  var valid_773237 = header.getOrDefault("X-Amz-Signature")
  valid_773237 = validateParameter(valid_773237, JString, required = false,
                                 default = nil)
  if valid_773237 != nil:
    section.add "X-Amz-Signature", valid_773237
  var valid_773238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773238 = validateParameter(valid_773238, JString, required = false,
                                 default = nil)
  if valid_773238 != nil:
    section.add "X-Amz-SignedHeaders", valid_773238
  var valid_773239 = header.getOrDefault("X-Amz-Credential")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "X-Amz-Credential", valid_773239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773241: Call_DeleteFleet_773230; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a fleet. Prevents users from accessing previously associated websites. 
  ## 
  let valid = call_773241.validator(path, query, header, formData, body)
  let scheme = call_773241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773241.url(scheme.get, call_773241.host, call_773241.base,
                         call_773241.route, valid.getOrDefault("path"))
  result = hook(call_773241, url, valid)

proc call*(call_773242: Call_DeleteFleet_773230; body: JsonNode): Recallable =
  ## deleteFleet
  ## Deletes a fleet. Prevents users from accessing previously associated websites. 
  ##   body: JObject (required)
  var body_773243 = newJObject()
  if body != nil:
    body_773243 = body
  result = call_773242.call(nil, nil, nil, nil, body_773243)

var deleteFleet* = Call_DeleteFleet_773230(name: "deleteFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "worklink.amazonaws.com",
                                        route: "/deleteFleet",
                                        validator: validate_DeleteFleet_773231,
                                        base: "/", url: url_DeleteFleet_773232,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAuditStreamConfiguration_773244 = ref object of OpenApiRestCall_772597
proc url_DescribeAuditStreamConfiguration_773246(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeAuditStreamConfiguration_773245(path: JsonNode;
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
  var valid_773247 = header.getOrDefault("X-Amz-Date")
  valid_773247 = validateParameter(valid_773247, JString, required = false,
                                 default = nil)
  if valid_773247 != nil:
    section.add "X-Amz-Date", valid_773247
  var valid_773248 = header.getOrDefault("X-Amz-Security-Token")
  valid_773248 = validateParameter(valid_773248, JString, required = false,
                                 default = nil)
  if valid_773248 != nil:
    section.add "X-Amz-Security-Token", valid_773248
  var valid_773249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773249 = validateParameter(valid_773249, JString, required = false,
                                 default = nil)
  if valid_773249 != nil:
    section.add "X-Amz-Content-Sha256", valid_773249
  var valid_773250 = header.getOrDefault("X-Amz-Algorithm")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-Algorithm", valid_773250
  var valid_773251 = header.getOrDefault("X-Amz-Signature")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "X-Amz-Signature", valid_773251
  var valid_773252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773252 = validateParameter(valid_773252, JString, required = false,
                                 default = nil)
  if valid_773252 != nil:
    section.add "X-Amz-SignedHeaders", valid_773252
  var valid_773253 = header.getOrDefault("X-Amz-Credential")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-Credential", valid_773253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773255: Call_DescribeAuditStreamConfiguration_773244;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration for delivering audit streams to the customer account.
  ## 
  let valid = call_773255.validator(path, query, header, formData, body)
  let scheme = call_773255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773255.url(scheme.get, call_773255.host, call_773255.base,
                         call_773255.route, valid.getOrDefault("path"))
  result = hook(call_773255, url, valid)

proc call*(call_773256: Call_DescribeAuditStreamConfiguration_773244;
          body: JsonNode): Recallable =
  ## describeAuditStreamConfiguration
  ## Describes the configuration for delivering audit streams to the customer account.
  ##   body: JObject (required)
  var body_773257 = newJObject()
  if body != nil:
    body_773257 = body
  result = call_773256.call(nil, nil, nil, nil, body_773257)

var describeAuditStreamConfiguration* = Call_DescribeAuditStreamConfiguration_773244(
    name: "describeAuditStreamConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/describeAuditStreamConfiguration",
    validator: validate_DescribeAuditStreamConfiguration_773245, base: "/",
    url: url_DescribeAuditStreamConfiguration_773246,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCompanyNetworkConfiguration_773258 = ref object of OpenApiRestCall_772597
proc url_DescribeCompanyNetworkConfiguration_773260(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeCompanyNetworkConfiguration_773259(path: JsonNode;
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
  var valid_773261 = header.getOrDefault("X-Amz-Date")
  valid_773261 = validateParameter(valid_773261, JString, required = false,
                                 default = nil)
  if valid_773261 != nil:
    section.add "X-Amz-Date", valid_773261
  var valid_773262 = header.getOrDefault("X-Amz-Security-Token")
  valid_773262 = validateParameter(valid_773262, JString, required = false,
                                 default = nil)
  if valid_773262 != nil:
    section.add "X-Amz-Security-Token", valid_773262
  var valid_773263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773263 = validateParameter(valid_773263, JString, required = false,
                                 default = nil)
  if valid_773263 != nil:
    section.add "X-Amz-Content-Sha256", valid_773263
  var valid_773264 = header.getOrDefault("X-Amz-Algorithm")
  valid_773264 = validateParameter(valid_773264, JString, required = false,
                                 default = nil)
  if valid_773264 != nil:
    section.add "X-Amz-Algorithm", valid_773264
  var valid_773265 = header.getOrDefault("X-Amz-Signature")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "X-Amz-Signature", valid_773265
  var valid_773266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773266 = validateParameter(valid_773266, JString, required = false,
                                 default = nil)
  if valid_773266 != nil:
    section.add "X-Amz-SignedHeaders", valid_773266
  var valid_773267 = header.getOrDefault("X-Amz-Credential")
  valid_773267 = validateParameter(valid_773267, JString, required = false,
                                 default = nil)
  if valid_773267 != nil:
    section.add "X-Amz-Credential", valid_773267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773269: Call_DescribeCompanyNetworkConfiguration_773258;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the networking configuration to access the internal websites associated with the specified fleet.
  ## 
  let valid = call_773269.validator(path, query, header, formData, body)
  let scheme = call_773269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773269.url(scheme.get, call_773269.host, call_773269.base,
                         call_773269.route, valid.getOrDefault("path"))
  result = hook(call_773269, url, valid)

proc call*(call_773270: Call_DescribeCompanyNetworkConfiguration_773258;
          body: JsonNode): Recallable =
  ## describeCompanyNetworkConfiguration
  ## Describes the networking configuration to access the internal websites associated with the specified fleet.
  ##   body: JObject (required)
  var body_773271 = newJObject()
  if body != nil:
    body_773271 = body
  result = call_773270.call(nil, nil, nil, nil, body_773271)

var describeCompanyNetworkConfiguration* = Call_DescribeCompanyNetworkConfiguration_773258(
    name: "describeCompanyNetworkConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/describeCompanyNetworkConfiguration",
    validator: validate_DescribeCompanyNetworkConfiguration_773259, base: "/",
    url: url_DescribeCompanyNetworkConfiguration_773260,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDevice_773272 = ref object of OpenApiRestCall_772597
proc url_DescribeDevice_773274(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeDevice_773273(path: JsonNode; query: JsonNode;
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
  var valid_773275 = header.getOrDefault("X-Amz-Date")
  valid_773275 = validateParameter(valid_773275, JString, required = false,
                                 default = nil)
  if valid_773275 != nil:
    section.add "X-Amz-Date", valid_773275
  var valid_773276 = header.getOrDefault("X-Amz-Security-Token")
  valid_773276 = validateParameter(valid_773276, JString, required = false,
                                 default = nil)
  if valid_773276 != nil:
    section.add "X-Amz-Security-Token", valid_773276
  var valid_773277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773277 = validateParameter(valid_773277, JString, required = false,
                                 default = nil)
  if valid_773277 != nil:
    section.add "X-Amz-Content-Sha256", valid_773277
  var valid_773278 = header.getOrDefault("X-Amz-Algorithm")
  valid_773278 = validateParameter(valid_773278, JString, required = false,
                                 default = nil)
  if valid_773278 != nil:
    section.add "X-Amz-Algorithm", valid_773278
  var valid_773279 = header.getOrDefault("X-Amz-Signature")
  valid_773279 = validateParameter(valid_773279, JString, required = false,
                                 default = nil)
  if valid_773279 != nil:
    section.add "X-Amz-Signature", valid_773279
  var valid_773280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = nil)
  if valid_773280 != nil:
    section.add "X-Amz-SignedHeaders", valid_773280
  var valid_773281 = header.getOrDefault("X-Amz-Credential")
  valid_773281 = validateParameter(valid_773281, JString, required = false,
                                 default = nil)
  if valid_773281 != nil:
    section.add "X-Amz-Credential", valid_773281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773283: Call_DescribeDevice_773272; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about a user's device.
  ## 
  let valid = call_773283.validator(path, query, header, formData, body)
  let scheme = call_773283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773283.url(scheme.get, call_773283.host, call_773283.base,
                         call_773283.route, valid.getOrDefault("path"))
  result = hook(call_773283, url, valid)

proc call*(call_773284: Call_DescribeDevice_773272; body: JsonNode): Recallable =
  ## describeDevice
  ## Provides information about a user's device.
  ##   body: JObject (required)
  var body_773285 = newJObject()
  if body != nil:
    body_773285 = body
  result = call_773284.call(nil, nil, nil, nil, body_773285)

var describeDevice* = Call_DescribeDevice_773272(name: "describeDevice",
    meth: HttpMethod.HttpPost, host: "worklink.amazonaws.com",
    route: "/describeDevice", validator: validate_DescribeDevice_773273, base: "/",
    url: url_DescribeDevice_773274, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDevicePolicyConfiguration_773286 = ref object of OpenApiRestCall_772597
proc url_DescribeDevicePolicyConfiguration_773288(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeDevicePolicyConfiguration_773287(path: JsonNode;
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
  var valid_773289 = header.getOrDefault("X-Amz-Date")
  valid_773289 = validateParameter(valid_773289, JString, required = false,
                                 default = nil)
  if valid_773289 != nil:
    section.add "X-Amz-Date", valid_773289
  var valid_773290 = header.getOrDefault("X-Amz-Security-Token")
  valid_773290 = validateParameter(valid_773290, JString, required = false,
                                 default = nil)
  if valid_773290 != nil:
    section.add "X-Amz-Security-Token", valid_773290
  var valid_773291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773291 = validateParameter(valid_773291, JString, required = false,
                                 default = nil)
  if valid_773291 != nil:
    section.add "X-Amz-Content-Sha256", valid_773291
  var valid_773292 = header.getOrDefault("X-Amz-Algorithm")
  valid_773292 = validateParameter(valid_773292, JString, required = false,
                                 default = nil)
  if valid_773292 != nil:
    section.add "X-Amz-Algorithm", valid_773292
  var valid_773293 = header.getOrDefault("X-Amz-Signature")
  valid_773293 = validateParameter(valid_773293, JString, required = false,
                                 default = nil)
  if valid_773293 != nil:
    section.add "X-Amz-Signature", valid_773293
  var valid_773294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773294 = validateParameter(valid_773294, JString, required = false,
                                 default = nil)
  if valid_773294 != nil:
    section.add "X-Amz-SignedHeaders", valid_773294
  var valid_773295 = header.getOrDefault("X-Amz-Credential")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "X-Amz-Credential", valid_773295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773297: Call_DescribeDevicePolicyConfiguration_773286;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the device policy configuration for the specified fleet.
  ## 
  let valid = call_773297.validator(path, query, header, formData, body)
  let scheme = call_773297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773297.url(scheme.get, call_773297.host, call_773297.base,
                         call_773297.route, valid.getOrDefault("path"))
  result = hook(call_773297, url, valid)

proc call*(call_773298: Call_DescribeDevicePolicyConfiguration_773286;
          body: JsonNode): Recallable =
  ## describeDevicePolicyConfiguration
  ## Describes the device policy configuration for the specified fleet.
  ##   body: JObject (required)
  var body_773299 = newJObject()
  if body != nil:
    body_773299 = body
  result = call_773298.call(nil, nil, nil, nil, body_773299)

var describeDevicePolicyConfiguration* = Call_DescribeDevicePolicyConfiguration_773286(
    name: "describeDevicePolicyConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/describeDevicePolicyConfiguration",
    validator: validate_DescribeDevicePolicyConfiguration_773287, base: "/",
    url: url_DescribeDevicePolicyConfiguration_773288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDomain_773300 = ref object of OpenApiRestCall_772597
proc url_DescribeDomain_773302(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeDomain_773301(path: JsonNode; query: JsonNode;
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
  var valid_773303 = header.getOrDefault("X-Amz-Date")
  valid_773303 = validateParameter(valid_773303, JString, required = false,
                                 default = nil)
  if valid_773303 != nil:
    section.add "X-Amz-Date", valid_773303
  var valid_773304 = header.getOrDefault("X-Amz-Security-Token")
  valid_773304 = validateParameter(valid_773304, JString, required = false,
                                 default = nil)
  if valid_773304 != nil:
    section.add "X-Amz-Security-Token", valid_773304
  var valid_773305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773305 = validateParameter(valid_773305, JString, required = false,
                                 default = nil)
  if valid_773305 != nil:
    section.add "X-Amz-Content-Sha256", valid_773305
  var valid_773306 = header.getOrDefault("X-Amz-Algorithm")
  valid_773306 = validateParameter(valid_773306, JString, required = false,
                                 default = nil)
  if valid_773306 != nil:
    section.add "X-Amz-Algorithm", valid_773306
  var valid_773307 = header.getOrDefault("X-Amz-Signature")
  valid_773307 = validateParameter(valid_773307, JString, required = false,
                                 default = nil)
  if valid_773307 != nil:
    section.add "X-Amz-Signature", valid_773307
  var valid_773308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773308 = validateParameter(valid_773308, JString, required = false,
                                 default = nil)
  if valid_773308 != nil:
    section.add "X-Amz-SignedHeaders", valid_773308
  var valid_773309 = header.getOrDefault("X-Amz-Credential")
  valid_773309 = validateParameter(valid_773309, JString, required = false,
                                 default = nil)
  if valid_773309 != nil:
    section.add "X-Amz-Credential", valid_773309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773311: Call_DescribeDomain_773300; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about the domain.
  ## 
  let valid = call_773311.validator(path, query, header, formData, body)
  let scheme = call_773311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773311.url(scheme.get, call_773311.host, call_773311.base,
                         call_773311.route, valid.getOrDefault("path"))
  result = hook(call_773311, url, valid)

proc call*(call_773312: Call_DescribeDomain_773300; body: JsonNode): Recallable =
  ## describeDomain
  ## Provides information about the domain.
  ##   body: JObject (required)
  var body_773313 = newJObject()
  if body != nil:
    body_773313 = body
  result = call_773312.call(nil, nil, nil, nil, body_773313)

var describeDomain* = Call_DescribeDomain_773300(name: "describeDomain",
    meth: HttpMethod.HttpPost, host: "worklink.amazonaws.com",
    route: "/describeDomain", validator: validate_DescribeDomain_773301, base: "/",
    url: url_DescribeDomain_773302, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFleetMetadata_773314 = ref object of OpenApiRestCall_772597
proc url_DescribeFleetMetadata_773316(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeFleetMetadata_773315(path: JsonNode; query: JsonNode;
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
  var valid_773317 = header.getOrDefault("X-Amz-Date")
  valid_773317 = validateParameter(valid_773317, JString, required = false,
                                 default = nil)
  if valid_773317 != nil:
    section.add "X-Amz-Date", valid_773317
  var valid_773318 = header.getOrDefault("X-Amz-Security-Token")
  valid_773318 = validateParameter(valid_773318, JString, required = false,
                                 default = nil)
  if valid_773318 != nil:
    section.add "X-Amz-Security-Token", valid_773318
  var valid_773319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773319 = validateParameter(valid_773319, JString, required = false,
                                 default = nil)
  if valid_773319 != nil:
    section.add "X-Amz-Content-Sha256", valid_773319
  var valid_773320 = header.getOrDefault("X-Amz-Algorithm")
  valid_773320 = validateParameter(valid_773320, JString, required = false,
                                 default = nil)
  if valid_773320 != nil:
    section.add "X-Amz-Algorithm", valid_773320
  var valid_773321 = header.getOrDefault("X-Amz-Signature")
  valid_773321 = validateParameter(valid_773321, JString, required = false,
                                 default = nil)
  if valid_773321 != nil:
    section.add "X-Amz-Signature", valid_773321
  var valid_773322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773322 = validateParameter(valid_773322, JString, required = false,
                                 default = nil)
  if valid_773322 != nil:
    section.add "X-Amz-SignedHeaders", valid_773322
  var valid_773323 = header.getOrDefault("X-Amz-Credential")
  valid_773323 = validateParameter(valid_773323, JString, required = false,
                                 default = nil)
  if valid_773323 != nil:
    section.add "X-Amz-Credential", valid_773323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773325: Call_DescribeFleetMetadata_773314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides basic information for the specified fleet, excluding identity provider, networking, and device configuration details.
  ## 
  let valid = call_773325.validator(path, query, header, formData, body)
  let scheme = call_773325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773325.url(scheme.get, call_773325.host, call_773325.base,
                         call_773325.route, valid.getOrDefault("path"))
  result = hook(call_773325, url, valid)

proc call*(call_773326: Call_DescribeFleetMetadata_773314; body: JsonNode): Recallable =
  ## describeFleetMetadata
  ## Provides basic information for the specified fleet, excluding identity provider, networking, and device configuration details.
  ##   body: JObject (required)
  var body_773327 = newJObject()
  if body != nil:
    body_773327 = body
  result = call_773326.call(nil, nil, nil, nil, body_773327)

var describeFleetMetadata* = Call_DescribeFleetMetadata_773314(
    name: "describeFleetMetadata", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/describeFleetMetadata",
    validator: validate_DescribeFleetMetadata_773315, base: "/",
    url: url_DescribeFleetMetadata_773316, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentityProviderConfiguration_773328 = ref object of OpenApiRestCall_772597
proc url_DescribeIdentityProviderConfiguration_773330(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeIdentityProviderConfiguration_773329(path: JsonNode;
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
  var valid_773331 = header.getOrDefault("X-Amz-Date")
  valid_773331 = validateParameter(valid_773331, JString, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "X-Amz-Date", valid_773331
  var valid_773332 = header.getOrDefault("X-Amz-Security-Token")
  valid_773332 = validateParameter(valid_773332, JString, required = false,
                                 default = nil)
  if valid_773332 != nil:
    section.add "X-Amz-Security-Token", valid_773332
  var valid_773333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773333 = validateParameter(valid_773333, JString, required = false,
                                 default = nil)
  if valid_773333 != nil:
    section.add "X-Amz-Content-Sha256", valid_773333
  var valid_773334 = header.getOrDefault("X-Amz-Algorithm")
  valid_773334 = validateParameter(valid_773334, JString, required = false,
                                 default = nil)
  if valid_773334 != nil:
    section.add "X-Amz-Algorithm", valid_773334
  var valid_773335 = header.getOrDefault("X-Amz-Signature")
  valid_773335 = validateParameter(valid_773335, JString, required = false,
                                 default = nil)
  if valid_773335 != nil:
    section.add "X-Amz-Signature", valid_773335
  var valid_773336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773336 = validateParameter(valid_773336, JString, required = false,
                                 default = nil)
  if valid_773336 != nil:
    section.add "X-Amz-SignedHeaders", valid_773336
  var valid_773337 = header.getOrDefault("X-Amz-Credential")
  valid_773337 = validateParameter(valid_773337, JString, required = false,
                                 default = nil)
  if valid_773337 != nil:
    section.add "X-Amz-Credential", valid_773337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773339: Call_DescribeIdentityProviderConfiguration_773328;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the identity provider configuration of the specified fleet.
  ## 
  let valid = call_773339.validator(path, query, header, formData, body)
  let scheme = call_773339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773339.url(scheme.get, call_773339.host, call_773339.base,
                         call_773339.route, valid.getOrDefault("path"))
  result = hook(call_773339, url, valid)

proc call*(call_773340: Call_DescribeIdentityProviderConfiguration_773328;
          body: JsonNode): Recallable =
  ## describeIdentityProviderConfiguration
  ## Describes the identity provider configuration of the specified fleet.
  ##   body: JObject (required)
  var body_773341 = newJObject()
  if body != nil:
    body_773341 = body
  result = call_773340.call(nil, nil, nil, nil, body_773341)

var describeIdentityProviderConfiguration* = Call_DescribeIdentityProviderConfiguration_773328(
    name: "describeIdentityProviderConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com",
    route: "/describeIdentityProviderConfiguration",
    validator: validate_DescribeIdentityProviderConfiguration_773329, base: "/",
    url: url_DescribeIdentityProviderConfiguration_773330,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWebsiteCertificateAuthority_773342 = ref object of OpenApiRestCall_772597
proc url_DescribeWebsiteCertificateAuthority_773344(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeWebsiteCertificateAuthority_773343(path: JsonNode;
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
  var valid_773345 = header.getOrDefault("X-Amz-Date")
  valid_773345 = validateParameter(valid_773345, JString, required = false,
                                 default = nil)
  if valid_773345 != nil:
    section.add "X-Amz-Date", valid_773345
  var valid_773346 = header.getOrDefault("X-Amz-Security-Token")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "X-Amz-Security-Token", valid_773346
  var valid_773347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773347 = validateParameter(valid_773347, JString, required = false,
                                 default = nil)
  if valid_773347 != nil:
    section.add "X-Amz-Content-Sha256", valid_773347
  var valid_773348 = header.getOrDefault("X-Amz-Algorithm")
  valid_773348 = validateParameter(valid_773348, JString, required = false,
                                 default = nil)
  if valid_773348 != nil:
    section.add "X-Amz-Algorithm", valid_773348
  var valid_773349 = header.getOrDefault("X-Amz-Signature")
  valid_773349 = validateParameter(valid_773349, JString, required = false,
                                 default = nil)
  if valid_773349 != nil:
    section.add "X-Amz-Signature", valid_773349
  var valid_773350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773350 = validateParameter(valid_773350, JString, required = false,
                                 default = nil)
  if valid_773350 != nil:
    section.add "X-Amz-SignedHeaders", valid_773350
  var valid_773351 = header.getOrDefault("X-Amz-Credential")
  valid_773351 = validateParameter(valid_773351, JString, required = false,
                                 default = nil)
  if valid_773351 != nil:
    section.add "X-Amz-Credential", valid_773351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773353: Call_DescribeWebsiteCertificateAuthority_773342;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Provides information about the certificate authority.
  ## 
  let valid = call_773353.validator(path, query, header, formData, body)
  let scheme = call_773353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773353.url(scheme.get, call_773353.host, call_773353.base,
                         call_773353.route, valid.getOrDefault("path"))
  result = hook(call_773353, url, valid)

proc call*(call_773354: Call_DescribeWebsiteCertificateAuthority_773342;
          body: JsonNode): Recallable =
  ## describeWebsiteCertificateAuthority
  ## Provides information about the certificate authority.
  ##   body: JObject (required)
  var body_773355 = newJObject()
  if body != nil:
    body_773355 = body
  result = call_773354.call(nil, nil, nil, nil, body_773355)

var describeWebsiteCertificateAuthority* = Call_DescribeWebsiteCertificateAuthority_773342(
    name: "describeWebsiteCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/describeWebsiteCertificateAuthority",
    validator: validate_DescribeWebsiteCertificateAuthority_773343, base: "/",
    url: url_DescribeWebsiteCertificateAuthority_773344,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateDomain_773356 = ref object of OpenApiRestCall_772597
proc url_DisassociateDomain_773358(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisassociateDomain_773357(path: JsonNode; query: JsonNode;
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
  var valid_773359 = header.getOrDefault("X-Amz-Date")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-Date", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-Security-Token")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-Security-Token", valid_773360
  var valid_773361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-Content-Sha256", valid_773361
  var valid_773362 = header.getOrDefault("X-Amz-Algorithm")
  valid_773362 = validateParameter(valid_773362, JString, required = false,
                                 default = nil)
  if valid_773362 != nil:
    section.add "X-Amz-Algorithm", valid_773362
  var valid_773363 = header.getOrDefault("X-Amz-Signature")
  valid_773363 = validateParameter(valid_773363, JString, required = false,
                                 default = nil)
  if valid_773363 != nil:
    section.add "X-Amz-Signature", valid_773363
  var valid_773364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773364 = validateParameter(valid_773364, JString, required = false,
                                 default = nil)
  if valid_773364 != nil:
    section.add "X-Amz-SignedHeaders", valid_773364
  var valid_773365 = header.getOrDefault("X-Amz-Credential")
  valid_773365 = validateParameter(valid_773365, JString, required = false,
                                 default = nil)
  if valid_773365 != nil:
    section.add "X-Amz-Credential", valid_773365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773367: Call_DisassociateDomain_773356; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a domain from Amazon WorkLink. End users lose the ability to access the domain with Amazon WorkLink. 
  ## 
  let valid = call_773367.validator(path, query, header, formData, body)
  let scheme = call_773367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773367.url(scheme.get, call_773367.host, call_773367.base,
                         call_773367.route, valid.getOrDefault("path"))
  result = hook(call_773367, url, valid)

proc call*(call_773368: Call_DisassociateDomain_773356; body: JsonNode): Recallable =
  ## disassociateDomain
  ## Disassociates a domain from Amazon WorkLink. End users lose the ability to access the domain with Amazon WorkLink. 
  ##   body: JObject (required)
  var body_773369 = newJObject()
  if body != nil:
    body_773369 = body
  result = call_773368.call(nil, nil, nil, nil, body_773369)

var disassociateDomain* = Call_DisassociateDomain_773356(
    name: "disassociateDomain", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/disassociateDomain",
    validator: validate_DisassociateDomain_773357, base: "/",
    url: url_DisassociateDomain_773358, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateWebsiteAuthorizationProvider_773370 = ref object of OpenApiRestCall_772597
proc url_DisassociateWebsiteAuthorizationProvider_773372(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisassociateWebsiteAuthorizationProvider_773371(path: JsonNode;
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
  var valid_773373 = header.getOrDefault("X-Amz-Date")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-Date", valid_773373
  var valid_773374 = header.getOrDefault("X-Amz-Security-Token")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-Security-Token", valid_773374
  var valid_773375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773375 = validateParameter(valid_773375, JString, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "X-Amz-Content-Sha256", valid_773375
  var valid_773376 = header.getOrDefault("X-Amz-Algorithm")
  valid_773376 = validateParameter(valid_773376, JString, required = false,
                                 default = nil)
  if valid_773376 != nil:
    section.add "X-Amz-Algorithm", valid_773376
  var valid_773377 = header.getOrDefault("X-Amz-Signature")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "X-Amz-Signature", valid_773377
  var valid_773378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773378 = validateParameter(valid_773378, JString, required = false,
                                 default = nil)
  if valid_773378 != nil:
    section.add "X-Amz-SignedHeaders", valid_773378
  var valid_773379 = header.getOrDefault("X-Amz-Credential")
  valid_773379 = validateParameter(valid_773379, JString, required = false,
                                 default = nil)
  if valid_773379 != nil:
    section.add "X-Amz-Credential", valid_773379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773381: Call_DisassociateWebsiteAuthorizationProvider_773370;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a website authorization provider from a specified fleet. After the disassociation, users can't load any associated websites that require this authorization provider.
  ## 
  let valid = call_773381.validator(path, query, header, formData, body)
  let scheme = call_773381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773381.url(scheme.get, call_773381.host, call_773381.base,
                         call_773381.route, valid.getOrDefault("path"))
  result = hook(call_773381, url, valid)

proc call*(call_773382: Call_DisassociateWebsiteAuthorizationProvider_773370;
          body: JsonNode): Recallable =
  ## disassociateWebsiteAuthorizationProvider
  ## Disassociates a website authorization provider from a specified fleet. After the disassociation, users can't load any associated websites that require this authorization provider.
  ##   body: JObject (required)
  var body_773383 = newJObject()
  if body != nil:
    body_773383 = body
  result = call_773382.call(nil, nil, nil, nil, body_773383)

var disassociateWebsiteAuthorizationProvider* = Call_DisassociateWebsiteAuthorizationProvider_773370(
    name: "disassociateWebsiteAuthorizationProvider", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com",
    route: "/disassociateWebsiteAuthorizationProvider",
    validator: validate_DisassociateWebsiteAuthorizationProvider_773371,
    base: "/", url: url_DisassociateWebsiteAuthorizationProvider_773372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateWebsiteCertificateAuthority_773384 = ref object of OpenApiRestCall_772597
proc url_DisassociateWebsiteCertificateAuthority_773386(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisassociateWebsiteCertificateAuthority_773385(path: JsonNode;
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
  var valid_773387 = header.getOrDefault("X-Amz-Date")
  valid_773387 = validateParameter(valid_773387, JString, required = false,
                                 default = nil)
  if valid_773387 != nil:
    section.add "X-Amz-Date", valid_773387
  var valid_773388 = header.getOrDefault("X-Amz-Security-Token")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "X-Amz-Security-Token", valid_773388
  var valid_773389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773389 = validateParameter(valid_773389, JString, required = false,
                                 default = nil)
  if valid_773389 != nil:
    section.add "X-Amz-Content-Sha256", valid_773389
  var valid_773390 = header.getOrDefault("X-Amz-Algorithm")
  valid_773390 = validateParameter(valid_773390, JString, required = false,
                                 default = nil)
  if valid_773390 != nil:
    section.add "X-Amz-Algorithm", valid_773390
  var valid_773391 = header.getOrDefault("X-Amz-Signature")
  valid_773391 = validateParameter(valid_773391, JString, required = false,
                                 default = nil)
  if valid_773391 != nil:
    section.add "X-Amz-Signature", valid_773391
  var valid_773392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773392 = validateParameter(valid_773392, JString, required = false,
                                 default = nil)
  if valid_773392 != nil:
    section.add "X-Amz-SignedHeaders", valid_773392
  var valid_773393 = header.getOrDefault("X-Amz-Credential")
  valid_773393 = validateParameter(valid_773393, JString, required = false,
                                 default = nil)
  if valid_773393 != nil:
    section.add "X-Amz-Credential", valid_773393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773395: Call_DisassociateWebsiteCertificateAuthority_773384;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a certificate authority (CA).
  ## 
  let valid = call_773395.validator(path, query, header, formData, body)
  let scheme = call_773395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773395.url(scheme.get, call_773395.host, call_773395.base,
                         call_773395.route, valid.getOrDefault("path"))
  result = hook(call_773395, url, valid)

proc call*(call_773396: Call_DisassociateWebsiteCertificateAuthority_773384;
          body: JsonNode): Recallable =
  ## disassociateWebsiteCertificateAuthority
  ## Removes a certificate authority (CA).
  ##   body: JObject (required)
  var body_773397 = newJObject()
  if body != nil:
    body_773397 = body
  result = call_773396.call(nil, nil, nil, nil, body_773397)

var disassociateWebsiteCertificateAuthority* = Call_DisassociateWebsiteCertificateAuthority_773384(
    name: "disassociateWebsiteCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com",
    route: "/disassociateWebsiteCertificateAuthority",
    validator: validate_DisassociateWebsiteCertificateAuthority_773385, base: "/",
    url: url_DisassociateWebsiteCertificateAuthority_773386,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevices_773398 = ref object of OpenApiRestCall_772597
proc url_ListDevices_773400(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDevices_773399(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773401 = query.getOrDefault("NextToken")
  valid_773401 = validateParameter(valid_773401, JString, required = false,
                                 default = nil)
  if valid_773401 != nil:
    section.add "NextToken", valid_773401
  var valid_773402 = query.getOrDefault("MaxResults")
  valid_773402 = validateParameter(valid_773402, JString, required = false,
                                 default = nil)
  if valid_773402 != nil:
    section.add "MaxResults", valid_773402
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
  var valid_773403 = header.getOrDefault("X-Amz-Date")
  valid_773403 = validateParameter(valid_773403, JString, required = false,
                                 default = nil)
  if valid_773403 != nil:
    section.add "X-Amz-Date", valid_773403
  var valid_773404 = header.getOrDefault("X-Amz-Security-Token")
  valid_773404 = validateParameter(valid_773404, JString, required = false,
                                 default = nil)
  if valid_773404 != nil:
    section.add "X-Amz-Security-Token", valid_773404
  var valid_773405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773405 = validateParameter(valid_773405, JString, required = false,
                                 default = nil)
  if valid_773405 != nil:
    section.add "X-Amz-Content-Sha256", valid_773405
  var valid_773406 = header.getOrDefault("X-Amz-Algorithm")
  valid_773406 = validateParameter(valid_773406, JString, required = false,
                                 default = nil)
  if valid_773406 != nil:
    section.add "X-Amz-Algorithm", valid_773406
  var valid_773407 = header.getOrDefault("X-Amz-Signature")
  valid_773407 = validateParameter(valid_773407, JString, required = false,
                                 default = nil)
  if valid_773407 != nil:
    section.add "X-Amz-Signature", valid_773407
  var valid_773408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773408 = validateParameter(valid_773408, JString, required = false,
                                 default = nil)
  if valid_773408 != nil:
    section.add "X-Amz-SignedHeaders", valid_773408
  var valid_773409 = header.getOrDefault("X-Amz-Credential")
  valid_773409 = validateParameter(valid_773409, JString, required = false,
                                 default = nil)
  if valid_773409 != nil:
    section.add "X-Amz-Credential", valid_773409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773411: Call_ListDevices_773398; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of devices registered with the specified fleet.
  ## 
  let valid = call_773411.validator(path, query, header, formData, body)
  let scheme = call_773411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773411.url(scheme.get, call_773411.host, call_773411.base,
                         call_773411.route, valid.getOrDefault("path"))
  result = hook(call_773411, url, valid)

proc call*(call_773412: Call_ListDevices_773398; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDevices
  ## Retrieves a list of devices registered with the specified fleet.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773413 = newJObject()
  var body_773414 = newJObject()
  add(query_773413, "NextToken", newJString(NextToken))
  if body != nil:
    body_773414 = body
  add(query_773413, "MaxResults", newJString(MaxResults))
  result = call_773412.call(nil, query_773413, nil, nil, body_773414)

var listDevices* = Call_ListDevices_773398(name: "listDevices",
                                        meth: HttpMethod.HttpPost,
                                        host: "worklink.amazonaws.com",
                                        route: "/listDevices",
                                        validator: validate_ListDevices_773399,
                                        base: "/", url: url_ListDevices_773400,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomains_773416 = ref object of OpenApiRestCall_772597
proc url_ListDomains_773418(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDomains_773417(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773419 = query.getOrDefault("NextToken")
  valid_773419 = validateParameter(valid_773419, JString, required = false,
                                 default = nil)
  if valid_773419 != nil:
    section.add "NextToken", valid_773419
  var valid_773420 = query.getOrDefault("MaxResults")
  valid_773420 = validateParameter(valid_773420, JString, required = false,
                                 default = nil)
  if valid_773420 != nil:
    section.add "MaxResults", valid_773420
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
  var valid_773421 = header.getOrDefault("X-Amz-Date")
  valid_773421 = validateParameter(valid_773421, JString, required = false,
                                 default = nil)
  if valid_773421 != nil:
    section.add "X-Amz-Date", valid_773421
  var valid_773422 = header.getOrDefault("X-Amz-Security-Token")
  valid_773422 = validateParameter(valid_773422, JString, required = false,
                                 default = nil)
  if valid_773422 != nil:
    section.add "X-Amz-Security-Token", valid_773422
  var valid_773423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773423 = validateParameter(valid_773423, JString, required = false,
                                 default = nil)
  if valid_773423 != nil:
    section.add "X-Amz-Content-Sha256", valid_773423
  var valid_773424 = header.getOrDefault("X-Amz-Algorithm")
  valid_773424 = validateParameter(valid_773424, JString, required = false,
                                 default = nil)
  if valid_773424 != nil:
    section.add "X-Amz-Algorithm", valid_773424
  var valid_773425 = header.getOrDefault("X-Amz-Signature")
  valid_773425 = validateParameter(valid_773425, JString, required = false,
                                 default = nil)
  if valid_773425 != nil:
    section.add "X-Amz-Signature", valid_773425
  var valid_773426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773426 = validateParameter(valid_773426, JString, required = false,
                                 default = nil)
  if valid_773426 != nil:
    section.add "X-Amz-SignedHeaders", valid_773426
  var valid_773427 = header.getOrDefault("X-Amz-Credential")
  valid_773427 = validateParameter(valid_773427, JString, required = false,
                                 default = nil)
  if valid_773427 != nil:
    section.add "X-Amz-Credential", valid_773427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773429: Call_ListDomains_773416; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of domains associated to a specified fleet.
  ## 
  let valid = call_773429.validator(path, query, header, formData, body)
  let scheme = call_773429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773429.url(scheme.get, call_773429.host, call_773429.base,
                         call_773429.route, valid.getOrDefault("path"))
  result = hook(call_773429, url, valid)

proc call*(call_773430: Call_ListDomains_773416; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDomains
  ## Retrieves a list of domains associated to a specified fleet.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773431 = newJObject()
  var body_773432 = newJObject()
  add(query_773431, "NextToken", newJString(NextToken))
  if body != nil:
    body_773432 = body
  add(query_773431, "MaxResults", newJString(MaxResults))
  result = call_773430.call(nil, query_773431, nil, nil, body_773432)

var listDomains* = Call_ListDomains_773416(name: "listDomains",
                                        meth: HttpMethod.HttpPost,
                                        host: "worklink.amazonaws.com",
                                        route: "/listDomains",
                                        validator: validate_ListDomains_773417,
                                        base: "/", url: url_ListDomains_773418,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFleets_773433 = ref object of OpenApiRestCall_772597
proc url_ListFleets_773435(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListFleets_773434(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773436 = query.getOrDefault("NextToken")
  valid_773436 = validateParameter(valid_773436, JString, required = false,
                                 default = nil)
  if valid_773436 != nil:
    section.add "NextToken", valid_773436
  var valid_773437 = query.getOrDefault("MaxResults")
  valid_773437 = validateParameter(valid_773437, JString, required = false,
                                 default = nil)
  if valid_773437 != nil:
    section.add "MaxResults", valid_773437
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
  var valid_773438 = header.getOrDefault("X-Amz-Date")
  valid_773438 = validateParameter(valid_773438, JString, required = false,
                                 default = nil)
  if valid_773438 != nil:
    section.add "X-Amz-Date", valid_773438
  var valid_773439 = header.getOrDefault("X-Amz-Security-Token")
  valid_773439 = validateParameter(valid_773439, JString, required = false,
                                 default = nil)
  if valid_773439 != nil:
    section.add "X-Amz-Security-Token", valid_773439
  var valid_773440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773440 = validateParameter(valid_773440, JString, required = false,
                                 default = nil)
  if valid_773440 != nil:
    section.add "X-Amz-Content-Sha256", valid_773440
  var valid_773441 = header.getOrDefault("X-Amz-Algorithm")
  valid_773441 = validateParameter(valid_773441, JString, required = false,
                                 default = nil)
  if valid_773441 != nil:
    section.add "X-Amz-Algorithm", valid_773441
  var valid_773442 = header.getOrDefault("X-Amz-Signature")
  valid_773442 = validateParameter(valid_773442, JString, required = false,
                                 default = nil)
  if valid_773442 != nil:
    section.add "X-Amz-Signature", valid_773442
  var valid_773443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773443 = validateParameter(valid_773443, JString, required = false,
                                 default = nil)
  if valid_773443 != nil:
    section.add "X-Amz-SignedHeaders", valid_773443
  var valid_773444 = header.getOrDefault("X-Amz-Credential")
  valid_773444 = validateParameter(valid_773444, JString, required = false,
                                 default = nil)
  if valid_773444 != nil:
    section.add "X-Amz-Credential", valid_773444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773446: Call_ListFleets_773433; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of fleets for the current account and Region.
  ## 
  let valid = call_773446.validator(path, query, header, formData, body)
  let scheme = call_773446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773446.url(scheme.get, call_773446.host, call_773446.base,
                         call_773446.route, valid.getOrDefault("path"))
  result = hook(call_773446, url, valid)

proc call*(call_773447: Call_ListFleets_773433; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listFleets
  ## Retrieves a list of fleets for the current account and Region.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773448 = newJObject()
  var body_773449 = newJObject()
  add(query_773448, "NextToken", newJString(NextToken))
  if body != nil:
    body_773449 = body
  add(query_773448, "MaxResults", newJString(MaxResults))
  result = call_773447.call(nil, query_773448, nil, nil, body_773449)

var listFleets* = Call_ListFleets_773433(name: "listFleets",
                                      meth: HttpMethod.HttpPost,
                                      host: "worklink.amazonaws.com",
                                      route: "/listFleets",
                                      validator: validate_ListFleets_773434,
                                      base: "/", url: url_ListFleets_773435,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWebsiteAuthorizationProviders_773450 = ref object of OpenApiRestCall_772597
proc url_ListWebsiteAuthorizationProviders_773452(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListWebsiteAuthorizationProviders_773451(path: JsonNode;
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
  var valid_773453 = query.getOrDefault("NextToken")
  valid_773453 = validateParameter(valid_773453, JString, required = false,
                                 default = nil)
  if valid_773453 != nil:
    section.add "NextToken", valid_773453
  var valid_773454 = query.getOrDefault("MaxResults")
  valid_773454 = validateParameter(valid_773454, JString, required = false,
                                 default = nil)
  if valid_773454 != nil:
    section.add "MaxResults", valid_773454
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
  var valid_773455 = header.getOrDefault("X-Amz-Date")
  valid_773455 = validateParameter(valid_773455, JString, required = false,
                                 default = nil)
  if valid_773455 != nil:
    section.add "X-Amz-Date", valid_773455
  var valid_773456 = header.getOrDefault("X-Amz-Security-Token")
  valid_773456 = validateParameter(valid_773456, JString, required = false,
                                 default = nil)
  if valid_773456 != nil:
    section.add "X-Amz-Security-Token", valid_773456
  var valid_773457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773457 = validateParameter(valid_773457, JString, required = false,
                                 default = nil)
  if valid_773457 != nil:
    section.add "X-Amz-Content-Sha256", valid_773457
  var valid_773458 = header.getOrDefault("X-Amz-Algorithm")
  valid_773458 = validateParameter(valid_773458, JString, required = false,
                                 default = nil)
  if valid_773458 != nil:
    section.add "X-Amz-Algorithm", valid_773458
  var valid_773459 = header.getOrDefault("X-Amz-Signature")
  valid_773459 = validateParameter(valid_773459, JString, required = false,
                                 default = nil)
  if valid_773459 != nil:
    section.add "X-Amz-Signature", valid_773459
  var valid_773460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773460 = validateParameter(valid_773460, JString, required = false,
                                 default = nil)
  if valid_773460 != nil:
    section.add "X-Amz-SignedHeaders", valid_773460
  var valid_773461 = header.getOrDefault("X-Amz-Credential")
  valid_773461 = validateParameter(valid_773461, JString, required = false,
                                 default = nil)
  if valid_773461 != nil:
    section.add "X-Amz-Credential", valid_773461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773463: Call_ListWebsiteAuthorizationProviders_773450;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves a list of website authorization providers associated with a specified fleet.
  ## 
  let valid = call_773463.validator(path, query, header, formData, body)
  let scheme = call_773463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773463.url(scheme.get, call_773463.host, call_773463.base,
                         call_773463.route, valid.getOrDefault("path"))
  result = hook(call_773463, url, valid)

proc call*(call_773464: Call_ListWebsiteAuthorizationProviders_773450;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listWebsiteAuthorizationProviders
  ## Retrieves a list of website authorization providers associated with a specified fleet.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773465 = newJObject()
  var body_773466 = newJObject()
  add(query_773465, "NextToken", newJString(NextToken))
  if body != nil:
    body_773466 = body
  add(query_773465, "MaxResults", newJString(MaxResults))
  result = call_773464.call(nil, query_773465, nil, nil, body_773466)

var listWebsiteAuthorizationProviders* = Call_ListWebsiteAuthorizationProviders_773450(
    name: "listWebsiteAuthorizationProviders", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/listWebsiteAuthorizationProviders",
    validator: validate_ListWebsiteAuthorizationProviders_773451, base: "/",
    url: url_ListWebsiteAuthorizationProviders_773452,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWebsiteCertificateAuthorities_773467 = ref object of OpenApiRestCall_772597
proc url_ListWebsiteCertificateAuthorities_773469(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListWebsiteCertificateAuthorities_773468(path: JsonNode;
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
  var valid_773470 = query.getOrDefault("NextToken")
  valid_773470 = validateParameter(valid_773470, JString, required = false,
                                 default = nil)
  if valid_773470 != nil:
    section.add "NextToken", valid_773470
  var valid_773471 = query.getOrDefault("MaxResults")
  valid_773471 = validateParameter(valid_773471, JString, required = false,
                                 default = nil)
  if valid_773471 != nil:
    section.add "MaxResults", valid_773471
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
  var valid_773472 = header.getOrDefault("X-Amz-Date")
  valid_773472 = validateParameter(valid_773472, JString, required = false,
                                 default = nil)
  if valid_773472 != nil:
    section.add "X-Amz-Date", valid_773472
  var valid_773473 = header.getOrDefault("X-Amz-Security-Token")
  valid_773473 = validateParameter(valid_773473, JString, required = false,
                                 default = nil)
  if valid_773473 != nil:
    section.add "X-Amz-Security-Token", valid_773473
  var valid_773474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773474 = validateParameter(valid_773474, JString, required = false,
                                 default = nil)
  if valid_773474 != nil:
    section.add "X-Amz-Content-Sha256", valid_773474
  var valid_773475 = header.getOrDefault("X-Amz-Algorithm")
  valid_773475 = validateParameter(valid_773475, JString, required = false,
                                 default = nil)
  if valid_773475 != nil:
    section.add "X-Amz-Algorithm", valid_773475
  var valid_773476 = header.getOrDefault("X-Amz-Signature")
  valid_773476 = validateParameter(valid_773476, JString, required = false,
                                 default = nil)
  if valid_773476 != nil:
    section.add "X-Amz-Signature", valid_773476
  var valid_773477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773477 = validateParameter(valid_773477, JString, required = false,
                                 default = nil)
  if valid_773477 != nil:
    section.add "X-Amz-SignedHeaders", valid_773477
  var valid_773478 = header.getOrDefault("X-Amz-Credential")
  valid_773478 = validateParameter(valid_773478, JString, required = false,
                                 default = nil)
  if valid_773478 != nil:
    section.add "X-Amz-Credential", valid_773478
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773480: Call_ListWebsiteCertificateAuthorities_773467;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves a list of certificate authorities added for the current account and Region.
  ## 
  let valid = call_773480.validator(path, query, header, formData, body)
  let scheme = call_773480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773480.url(scheme.get, call_773480.host, call_773480.base,
                         call_773480.route, valid.getOrDefault("path"))
  result = hook(call_773480, url, valid)

proc call*(call_773481: Call_ListWebsiteCertificateAuthorities_773467;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listWebsiteCertificateAuthorities
  ## Retrieves a list of certificate authorities added for the current account and Region.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773482 = newJObject()
  var body_773483 = newJObject()
  add(query_773482, "NextToken", newJString(NextToken))
  if body != nil:
    body_773483 = body
  add(query_773482, "MaxResults", newJString(MaxResults))
  result = call_773481.call(nil, query_773482, nil, nil, body_773483)

var listWebsiteCertificateAuthorities* = Call_ListWebsiteCertificateAuthorities_773467(
    name: "listWebsiteCertificateAuthorities", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/listWebsiteCertificateAuthorities",
    validator: validate_ListWebsiteCertificateAuthorities_773468, base: "/",
    url: url_ListWebsiteCertificateAuthorities_773469,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreDomainAccess_773484 = ref object of OpenApiRestCall_772597
proc url_RestoreDomainAccess_773486(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RestoreDomainAccess_773485(path: JsonNode; query: JsonNode;
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
  var valid_773487 = header.getOrDefault("X-Amz-Date")
  valid_773487 = validateParameter(valid_773487, JString, required = false,
                                 default = nil)
  if valid_773487 != nil:
    section.add "X-Amz-Date", valid_773487
  var valid_773488 = header.getOrDefault("X-Amz-Security-Token")
  valid_773488 = validateParameter(valid_773488, JString, required = false,
                                 default = nil)
  if valid_773488 != nil:
    section.add "X-Amz-Security-Token", valid_773488
  var valid_773489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773489 = validateParameter(valid_773489, JString, required = false,
                                 default = nil)
  if valid_773489 != nil:
    section.add "X-Amz-Content-Sha256", valid_773489
  var valid_773490 = header.getOrDefault("X-Amz-Algorithm")
  valid_773490 = validateParameter(valid_773490, JString, required = false,
                                 default = nil)
  if valid_773490 != nil:
    section.add "X-Amz-Algorithm", valid_773490
  var valid_773491 = header.getOrDefault("X-Amz-Signature")
  valid_773491 = validateParameter(valid_773491, JString, required = false,
                                 default = nil)
  if valid_773491 != nil:
    section.add "X-Amz-Signature", valid_773491
  var valid_773492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773492 = validateParameter(valid_773492, JString, required = false,
                                 default = nil)
  if valid_773492 != nil:
    section.add "X-Amz-SignedHeaders", valid_773492
  var valid_773493 = header.getOrDefault("X-Amz-Credential")
  valid_773493 = validateParameter(valid_773493, JString, required = false,
                                 default = nil)
  if valid_773493 != nil:
    section.add "X-Amz-Credential", valid_773493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773495: Call_RestoreDomainAccess_773484; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Moves a domain to ACTIVE status if it was in the INACTIVE status.
  ## 
  let valid = call_773495.validator(path, query, header, formData, body)
  let scheme = call_773495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773495.url(scheme.get, call_773495.host, call_773495.base,
                         call_773495.route, valid.getOrDefault("path"))
  result = hook(call_773495, url, valid)

proc call*(call_773496: Call_RestoreDomainAccess_773484; body: JsonNode): Recallable =
  ## restoreDomainAccess
  ## Moves a domain to ACTIVE status if it was in the INACTIVE status.
  ##   body: JObject (required)
  var body_773497 = newJObject()
  if body != nil:
    body_773497 = body
  result = call_773496.call(nil, nil, nil, nil, body_773497)

var restoreDomainAccess* = Call_RestoreDomainAccess_773484(
    name: "restoreDomainAccess", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/restoreDomainAccess",
    validator: validate_RestoreDomainAccess_773485, base: "/",
    url: url_RestoreDomainAccess_773486, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeDomainAccess_773498 = ref object of OpenApiRestCall_772597
proc url_RevokeDomainAccess_773500(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RevokeDomainAccess_773499(path: JsonNode; query: JsonNode;
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
  var valid_773501 = header.getOrDefault("X-Amz-Date")
  valid_773501 = validateParameter(valid_773501, JString, required = false,
                                 default = nil)
  if valid_773501 != nil:
    section.add "X-Amz-Date", valid_773501
  var valid_773502 = header.getOrDefault("X-Amz-Security-Token")
  valid_773502 = validateParameter(valid_773502, JString, required = false,
                                 default = nil)
  if valid_773502 != nil:
    section.add "X-Amz-Security-Token", valid_773502
  var valid_773503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773503 = validateParameter(valid_773503, JString, required = false,
                                 default = nil)
  if valid_773503 != nil:
    section.add "X-Amz-Content-Sha256", valid_773503
  var valid_773504 = header.getOrDefault("X-Amz-Algorithm")
  valid_773504 = validateParameter(valid_773504, JString, required = false,
                                 default = nil)
  if valid_773504 != nil:
    section.add "X-Amz-Algorithm", valid_773504
  var valid_773505 = header.getOrDefault("X-Amz-Signature")
  valid_773505 = validateParameter(valid_773505, JString, required = false,
                                 default = nil)
  if valid_773505 != nil:
    section.add "X-Amz-Signature", valid_773505
  var valid_773506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773506 = validateParameter(valid_773506, JString, required = false,
                                 default = nil)
  if valid_773506 != nil:
    section.add "X-Amz-SignedHeaders", valid_773506
  var valid_773507 = header.getOrDefault("X-Amz-Credential")
  valid_773507 = validateParameter(valid_773507, JString, required = false,
                                 default = nil)
  if valid_773507 != nil:
    section.add "X-Amz-Credential", valid_773507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773509: Call_RevokeDomainAccess_773498; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Moves a domain to INACTIVE status if it was in the ACTIVE status.
  ## 
  let valid = call_773509.validator(path, query, header, formData, body)
  let scheme = call_773509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773509.url(scheme.get, call_773509.host, call_773509.base,
                         call_773509.route, valid.getOrDefault("path"))
  result = hook(call_773509, url, valid)

proc call*(call_773510: Call_RevokeDomainAccess_773498; body: JsonNode): Recallable =
  ## revokeDomainAccess
  ## Moves a domain to INACTIVE status if it was in the ACTIVE status.
  ##   body: JObject (required)
  var body_773511 = newJObject()
  if body != nil:
    body_773511 = body
  result = call_773510.call(nil, nil, nil, nil, body_773511)

var revokeDomainAccess* = Call_RevokeDomainAccess_773498(
    name: "revokeDomainAccess", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/revokeDomainAccess",
    validator: validate_RevokeDomainAccess_773499, base: "/",
    url: url_RevokeDomainAccess_773500, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SignOutUser_773512 = ref object of OpenApiRestCall_772597
proc url_SignOutUser_773514(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SignOutUser_773513(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773515 = header.getOrDefault("X-Amz-Date")
  valid_773515 = validateParameter(valid_773515, JString, required = false,
                                 default = nil)
  if valid_773515 != nil:
    section.add "X-Amz-Date", valid_773515
  var valid_773516 = header.getOrDefault("X-Amz-Security-Token")
  valid_773516 = validateParameter(valid_773516, JString, required = false,
                                 default = nil)
  if valid_773516 != nil:
    section.add "X-Amz-Security-Token", valid_773516
  var valid_773517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773517 = validateParameter(valid_773517, JString, required = false,
                                 default = nil)
  if valid_773517 != nil:
    section.add "X-Amz-Content-Sha256", valid_773517
  var valid_773518 = header.getOrDefault("X-Amz-Algorithm")
  valid_773518 = validateParameter(valid_773518, JString, required = false,
                                 default = nil)
  if valid_773518 != nil:
    section.add "X-Amz-Algorithm", valid_773518
  var valid_773519 = header.getOrDefault("X-Amz-Signature")
  valid_773519 = validateParameter(valid_773519, JString, required = false,
                                 default = nil)
  if valid_773519 != nil:
    section.add "X-Amz-Signature", valid_773519
  var valid_773520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773520 = validateParameter(valid_773520, JString, required = false,
                                 default = nil)
  if valid_773520 != nil:
    section.add "X-Amz-SignedHeaders", valid_773520
  var valid_773521 = header.getOrDefault("X-Amz-Credential")
  valid_773521 = validateParameter(valid_773521, JString, required = false,
                                 default = nil)
  if valid_773521 != nil:
    section.add "X-Amz-Credential", valid_773521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773523: Call_SignOutUser_773512; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Signs the user out from all of their devices. The user can sign in again if they have valid credentials.
  ## 
  let valid = call_773523.validator(path, query, header, formData, body)
  let scheme = call_773523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773523.url(scheme.get, call_773523.host, call_773523.base,
                         call_773523.route, valid.getOrDefault("path"))
  result = hook(call_773523, url, valid)

proc call*(call_773524: Call_SignOutUser_773512; body: JsonNode): Recallable =
  ## signOutUser
  ## Signs the user out from all of their devices. The user can sign in again if they have valid credentials.
  ##   body: JObject (required)
  var body_773525 = newJObject()
  if body != nil:
    body_773525 = body
  result = call_773524.call(nil, nil, nil, nil, body_773525)

var signOutUser* = Call_SignOutUser_773512(name: "signOutUser",
                                        meth: HttpMethod.HttpPost,
                                        host: "worklink.amazonaws.com",
                                        route: "/signOutUser",
                                        validator: validate_SignOutUser_773513,
                                        base: "/", url: url_SignOutUser_773514,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuditStreamConfiguration_773526 = ref object of OpenApiRestCall_772597
proc url_UpdateAuditStreamConfiguration_773528(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateAuditStreamConfiguration_773527(path: JsonNode;
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
  var valid_773529 = header.getOrDefault("X-Amz-Date")
  valid_773529 = validateParameter(valid_773529, JString, required = false,
                                 default = nil)
  if valid_773529 != nil:
    section.add "X-Amz-Date", valid_773529
  var valid_773530 = header.getOrDefault("X-Amz-Security-Token")
  valid_773530 = validateParameter(valid_773530, JString, required = false,
                                 default = nil)
  if valid_773530 != nil:
    section.add "X-Amz-Security-Token", valid_773530
  var valid_773531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773531 = validateParameter(valid_773531, JString, required = false,
                                 default = nil)
  if valid_773531 != nil:
    section.add "X-Amz-Content-Sha256", valid_773531
  var valid_773532 = header.getOrDefault("X-Amz-Algorithm")
  valid_773532 = validateParameter(valid_773532, JString, required = false,
                                 default = nil)
  if valid_773532 != nil:
    section.add "X-Amz-Algorithm", valid_773532
  var valid_773533 = header.getOrDefault("X-Amz-Signature")
  valid_773533 = validateParameter(valid_773533, JString, required = false,
                                 default = nil)
  if valid_773533 != nil:
    section.add "X-Amz-Signature", valid_773533
  var valid_773534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773534 = validateParameter(valid_773534, JString, required = false,
                                 default = nil)
  if valid_773534 != nil:
    section.add "X-Amz-SignedHeaders", valid_773534
  var valid_773535 = header.getOrDefault("X-Amz-Credential")
  valid_773535 = validateParameter(valid_773535, JString, required = false,
                                 default = nil)
  if valid_773535 != nil:
    section.add "X-Amz-Credential", valid_773535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773537: Call_UpdateAuditStreamConfiguration_773526; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the audit stream configuration for the fleet.
  ## 
  let valid = call_773537.validator(path, query, header, formData, body)
  let scheme = call_773537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773537.url(scheme.get, call_773537.host, call_773537.base,
                         call_773537.route, valid.getOrDefault("path"))
  result = hook(call_773537, url, valid)

proc call*(call_773538: Call_UpdateAuditStreamConfiguration_773526; body: JsonNode): Recallable =
  ## updateAuditStreamConfiguration
  ## Updates the audit stream configuration for the fleet.
  ##   body: JObject (required)
  var body_773539 = newJObject()
  if body != nil:
    body_773539 = body
  result = call_773538.call(nil, nil, nil, nil, body_773539)

var updateAuditStreamConfiguration* = Call_UpdateAuditStreamConfiguration_773526(
    name: "updateAuditStreamConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/updateAuditStreamConfiguration",
    validator: validate_UpdateAuditStreamConfiguration_773527, base: "/",
    url: url_UpdateAuditStreamConfiguration_773528,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCompanyNetworkConfiguration_773540 = ref object of OpenApiRestCall_772597
proc url_UpdateCompanyNetworkConfiguration_773542(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateCompanyNetworkConfiguration_773541(path: JsonNode;
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
  var valid_773543 = header.getOrDefault("X-Amz-Date")
  valid_773543 = validateParameter(valid_773543, JString, required = false,
                                 default = nil)
  if valid_773543 != nil:
    section.add "X-Amz-Date", valid_773543
  var valid_773544 = header.getOrDefault("X-Amz-Security-Token")
  valid_773544 = validateParameter(valid_773544, JString, required = false,
                                 default = nil)
  if valid_773544 != nil:
    section.add "X-Amz-Security-Token", valid_773544
  var valid_773545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773545 = validateParameter(valid_773545, JString, required = false,
                                 default = nil)
  if valid_773545 != nil:
    section.add "X-Amz-Content-Sha256", valid_773545
  var valid_773546 = header.getOrDefault("X-Amz-Algorithm")
  valid_773546 = validateParameter(valid_773546, JString, required = false,
                                 default = nil)
  if valid_773546 != nil:
    section.add "X-Amz-Algorithm", valid_773546
  var valid_773547 = header.getOrDefault("X-Amz-Signature")
  valid_773547 = validateParameter(valid_773547, JString, required = false,
                                 default = nil)
  if valid_773547 != nil:
    section.add "X-Amz-Signature", valid_773547
  var valid_773548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773548 = validateParameter(valid_773548, JString, required = false,
                                 default = nil)
  if valid_773548 != nil:
    section.add "X-Amz-SignedHeaders", valid_773548
  var valid_773549 = header.getOrDefault("X-Amz-Credential")
  valid_773549 = validateParameter(valid_773549, JString, required = false,
                                 default = nil)
  if valid_773549 != nil:
    section.add "X-Amz-Credential", valid_773549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773551: Call_UpdateCompanyNetworkConfiguration_773540;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the company network configuration for the fleet.
  ## 
  let valid = call_773551.validator(path, query, header, formData, body)
  let scheme = call_773551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773551.url(scheme.get, call_773551.host, call_773551.base,
                         call_773551.route, valid.getOrDefault("path"))
  result = hook(call_773551, url, valid)

proc call*(call_773552: Call_UpdateCompanyNetworkConfiguration_773540;
          body: JsonNode): Recallable =
  ## updateCompanyNetworkConfiguration
  ## Updates the company network configuration for the fleet.
  ##   body: JObject (required)
  var body_773553 = newJObject()
  if body != nil:
    body_773553 = body
  result = call_773552.call(nil, nil, nil, nil, body_773553)

var updateCompanyNetworkConfiguration* = Call_UpdateCompanyNetworkConfiguration_773540(
    name: "updateCompanyNetworkConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/updateCompanyNetworkConfiguration",
    validator: validate_UpdateCompanyNetworkConfiguration_773541, base: "/",
    url: url_UpdateCompanyNetworkConfiguration_773542,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevicePolicyConfiguration_773554 = ref object of OpenApiRestCall_772597
proc url_UpdateDevicePolicyConfiguration_773556(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateDevicePolicyConfiguration_773555(path: JsonNode;
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
  var valid_773557 = header.getOrDefault("X-Amz-Date")
  valid_773557 = validateParameter(valid_773557, JString, required = false,
                                 default = nil)
  if valid_773557 != nil:
    section.add "X-Amz-Date", valid_773557
  var valid_773558 = header.getOrDefault("X-Amz-Security-Token")
  valid_773558 = validateParameter(valid_773558, JString, required = false,
                                 default = nil)
  if valid_773558 != nil:
    section.add "X-Amz-Security-Token", valid_773558
  var valid_773559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773559 = validateParameter(valid_773559, JString, required = false,
                                 default = nil)
  if valid_773559 != nil:
    section.add "X-Amz-Content-Sha256", valid_773559
  var valid_773560 = header.getOrDefault("X-Amz-Algorithm")
  valid_773560 = validateParameter(valid_773560, JString, required = false,
                                 default = nil)
  if valid_773560 != nil:
    section.add "X-Amz-Algorithm", valid_773560
  var valid_773561 = header.getOrDefault("X-Amz-Signature")
  valid_773561 = validateParameter(valid_773561, JString, required = false,
                                 default = nil)
  if valid_773561 != nil:
    section.add "X-Amz-Signature", valid_773561
  var valid_773562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773562 = validateParameter(valid_773562, JString, required = false,
                                 default = nil)
  if valid_773562 != nil:
    section.add "X-Amz-SignedHeaders", valid_773562
  var valid_773563 = header.getOrDefault("X-Amz-Credential")
  valid_773563 = validateParameter(valid_773563, JString, required = false,
                                 default = nil)
  if valid_773563 != nil:
    section.add "X-Amz-Credential", valid_773563
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773565: Call_UpdateDevicePolicyConfiguration_773554;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the device policy configuration for the fleet.
  ## 
  let valid = call_773565.validator(path, query, header, formData, body)
  let scheme = call_773565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773565.url(scheme.get, call_773565.host, call_773565.base,
                         call_773565.route, valid.getOrDefault("path"))
  result = hook(call_773565, url, valid)

proc call*(call_773566: Call_UpdateDevicePolicyConfiguration_773554; body: JsonNode): Recallable =
  ## updateDevicePolicyConfiguration
  ## Updates the device policy configuration for the fleet.
  ##   body: JObject (required)
  var body_773567 = newJObject()
  if body != nil:
    body_773567 = body
  result = call_773566.call(nil, nil, nil, nil, body_773567)

var updateDevicePolicyConfiguration* = Call_UpdateDevicePolicyConfiguration_773554(
    name: "updateDevicePolicyConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/updateDevicePolicyConfiguration",
    validator: validate_UpdateDevicePolicyConfiguration_773555, base: "/",
    url: url_UpdateDevicePolicyConfiguration_773556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainMetadata_773568 = ref object of OpenApiRestCall_772597
proc url_UpdateDomainMetadata_773570(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateDomainMetadata_773569(path: JsonNode; query: JsonNode;
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
  var valid_773571 = header.getOrDefault("X-Amz-Date")
  valid_773571 = validateParameter(valid_773571, JString, required = false,
                                 default = nil)
  if valid_773571 != nil:
    section.add "X-Amz-Date", valid_773571
  var valid_773572 = header.getOrDefault("X-Amz-Security-Token")
  valid_773572 = validateParameter(valid_773572, JString, required = false,
                                 default = nil)
  if valid_773572 != nil:
    section.add "X-Amz-Security-Token", valid_773572
  var valid_773573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773573 = validateParameter(valid_773573, JString, required = false,
                                 default = nil)
  if valid_773573 != nil:
    section.add "X-Amz-Content-Sha256", valid_773573
  var valid_773574 = header.getOrDefault("X-Amz-Algorithm")
  valid_773574 = validateParameter(valid_773574, JString, required = false,
                                 default = nil)
  if valid_773574 != nil:
    section.add "X-Amz-Algorithm", valid_773574
  var valid_773575 = header.getOrDefault("X-Amz-Signature")
  valid_773575 = validateParameter(valid_773575, JString, required = false,
                                 default = nil)
  if valid_773575 != nil:
    section.add "X-Amz-Signature", valid_773575
  var valid_773576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773576 = validateParameter(valid_773576, JString, required = false,
                                 default = nil)
  if valid_773576 != nil:
    section.add "X-Amz-SignedHeaders", valid_773576
  var valid_773577 = header.getOrDefault("X-Amz-Credential")
  valid_773577 = validateParameter(valid_773577, JString, required = false,
                                 default = nil)
  if valid_773577 != nil:
    section.add "X-Amz-Credential", valid_773577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773579: Call_UpdateDomainMetadata_773568; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates domain metadata, such as DisplayName.
  ## 
  let valid = call_773579.validator(path, query, header, formData, body)
  let scheme = call_773579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773579.url(scheme.get, call_773579.host, call_773579.base,
                         call_773579.route, valid.getOrDefault("path"))
  result = hook(call_773579, url, valid)

proc call*(call_773580: Call_UpdateDomainMetadata_773568; body: JsonNode): Recallable =
  ## updateDomainMetadata
  ## Updates domain metadata, such as DisplayName.
  ##   body: JObject (required)
  var body_773581 = newJObject()
  if body != nil:
    body_773581 = body
  result = call_773580.call(nil, nil, nil, nil, body_773581)

var updateDomainMetadata* = Call_UpdateDomainMetadata_773568(
    name: "updateDomainMetadata", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/updateDomainMetadata",
    validator: validate_UpdateDomainMetadata_773569, base: "/",
    url: url_UpdateDomainMetadata_773570, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFleetMetadata_773582 = ref object of OpenApiRestCall_772597
proc url_UpdateFleetMetadata_773584(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateFleetMetadata_773583(path: JsonNode; query: JsonNode;
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
  var valid_773585 = header.getOrDefault("X-Amz-Date")
  valid_773585 = validateParameter(valid_773585, JString, required = false,
                                 default = nil)
  if valid_773585 != nil:
    section.add "X-Amz-Date", valid_773585
  var valid_773586 = header.getOrDefault("X-Amz-Security-Token")
  valid_773586 = validateParameter(valid_773586, JString, required = false,
                                 default = nil)
  if valid_773586 != nil:
    section.add "X-Amz-Security-Token", valid_773586
  var valid_773587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773587 = validateParameter(valid_773587, JString, required = false,
                                 default = nil)
  if valid_773587 != nil:
    section.add "X-Amz-Content-Sha256", valid_773587
  var valid_773588 = header.getOrDefault("X-Amz-Algorithm")
  valid_773588 = validateParameter(valid_773588, JString, required = false,
                                 default = nil)
  if valid_773588 != nil:
    section.add "X-Amz-Algorithm", valid_773588
  var valid_773589 = header.getOrDefault("X-Amz-Signature")
  valid_773589 = validateParameter(valid_773589, JString, required = false,
                                 default = nil)
  if valid_773589 != nil:
    section.add "X-Amz-Signature", valid_773589
  var valid_773590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773590 = validateParameter(valid_773590, JString, required = false,
                                 default = nil)
  if valid_773590 != nil:
    section.add "X-Amz-SignedHeaders", valid_773590
  var valid_773591 = header.getOrDefault("X-Amz-Credential")
  valid_773591 = validateParameter(valid_773591, JString, required = false,
                                 default = nil)
  if valid_773591 != nil:
    section.add "X-Amz-Credential", valid_773591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773593: Call_UpdateFleetMetadata_773582; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates fleet metadata, such as DisplayName.
  ## 
  let valid = call_773593.validator(path, query, header, formData, body)
  let scheme = call_773593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773593.url(scheme.get, call_773593.host, call_773593.base,
                         call_773593.route, valid.getOrDefault("path"))
  result = hook(call_773593, url, valid)

proc call*(call_773594: Call_UpdateFleetMetadata_773582; body: JsonNode): Recallable =
  ## updateFleetMetadata
  ## Updates fleet metadata, such as DisplayName.
  ##   body: JObject (required)
  var body_773595 = newJObject()
  if body != nil:
    body_773595 = body
  result = call_773594.call(nil, nil, nil, nil, body_773595)

var updateFleetMetadata* = Call_UpdateFleetMetadata_773582(
    name: "updateFleetMetadata", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/UpdateFleetMetadata",
    validator: validate_UpdateFleetMetadata_773583, base: "/",
    url: url_UpdateFleetMetadata_773584, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIdentityProviderConfiguration_773596 = ref object of OpenApiRestCall_772597
proc url_UpdateIdentityProviderConfiguration_773598(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateIdentityProviderConfiguration_773597(path: JsonNode;
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
  var valid_773599 = header.getOrDefault("X-Amz-Date")
  valid_773599 = validateParameter(valid_773599, JString, required = false,
                                 default = nil)
  if valid_773599 != nil:
    section.add "X-Amz-Date", valid_773599
  var valid_773600 = header.getOrDefault("X-Amz-Security-Token")
  valid_773600 = validateParameter(valid_773600, JString, required = false,
                                 default = nil)
  if valid_773600 != nil:
    section.add "X-Amz-Security-Token", valid_773600
  var valid_773601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773601 = validateParameter(valid_773601, JString, required = false,
                                 default = nil)
  if valid_773601 != nil:
    section.add "X-Amz-Content-Sha256", valid_773601
  var valid_773602 = header.getOrDefault("X-Amz-Algorithm")
  valid_773602 = validateParameter(valid_773602, JString, required = false,
                                 default = nil)
  if valid_773602 != nil:
    section.add "X-Amz-Algorithm", valid_773602
  var valid_773603 = header.getOrDefault("X-Amz-Signature")
  valid_773603 = validateParameter(valid_773603, JString, required = false,
                                 default = nil)
  if valid_773603 != nil:
    section.add "X-Amz-Signature", valid_773603
  var valid_773604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773604 = validateParameter(valid_773604, JString, required = false,
                                 default = nil)
  if valid_773604 != nil:
    section.add "X-Amz-SignedHeaders", valid_773604
  var valid_773605 = header.getOrDefault("X-Amz-Credential")
  valid_773605 = validateParameter(valid_773605, JString, required = false,
                                 default = nil)
  if valid_773605 != nil:
    section.add "X-Amz-Credential", valid_773605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773607: Call_UpdateIdentityProviderConfiguration_773596;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the identity provider configuration for the fleet.
  ## 
  let valid = call_773607.validator(path, query, header, formData, body)
  let scheme = call_773607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773607.url(scheme.get, call_773607.host, call_773607.base,
                         call_773607.route, valid.getOrDefault("path"))
  result = hook(call_773607, url, valid)

proc call*(call_773608: Call_UpdateIdentityProviderConfiguration_773596;
          body: JsonNode): Recallable =
  ## updateIdentityProviderConfiguration
  ## Updates the identity provider configuration for the fleet.
  ##   body: JObject (required)
  var body_773609 = newJObject()
  if body != nil:
    body_773609 = body
  result = call_773608.call(nil, nil, nil, nil, body_773609)

var updateIdentityProviderConfiguration* = Call_UpdateIdentityProviderConfiguration_773596(
    name: "updateIdentityProviderConfiguration", meth: HttpMethod.HttpPost,
    host: "worklink.amazonaws.com", route: "/updateIdentityProviderConfiguration",
    validator: validate_UpdateIdentityProviderConfiguration_773597, base: "/",
    url: url_UpdateIdentityProviderConfiguration_773598,
    schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
